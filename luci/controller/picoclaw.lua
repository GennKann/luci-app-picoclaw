module("luci.controller.picoclaw", package.seeall)

local jsonc = require("luci.jsonc")
local sys = require("luci.sys")
local http = require("luci.http")
local dispatcher = require("luci.dispatcher")
local nixio = require("nixio")

function index()
    entry({"admin", "services", "picoclaw"}, call("action_main"), _("PicoClaw"), 60)
    entry({"admin", "services", "picoclaw", "action"}, call("action_do"), nil)
    -- Chat API endpoints (no menu entry, used by XHR)
    entry({"admin", "services", "picoclaw", "chat_send"}, call("action_chat_send"), nil)
    entry({"admin", "services", "picoclaw", "chat_poll"}, call("action_chat_poll"), nil)
end

-- Parse JSON using luci.jsonc instead of manual regex
function parse_json_file(filepath)
    local f = io.open(filepath, "r")
    if not f then return nil end
    local content = f:read("*a")
    f:close()
    local ok, data = pcall(jsonc.parse, content)
    if ok then return data end
    return nil
end

-- Check if PicoClaw binary is installed
function is_picoclaw_installed()
    return nixio.fs.access("/usr/bin/picoclaw")
end

-- Get system architecture mapping for PicoClaw download
function get_picoclaw_arch()
    local m = sys.exec("uname -m"):match("^%s*(.-)%s*$") or ""
    local arch_map = {
        ["x86_64"] = "Linux_x86_64",
        ["x86"] = "Linux_x86_64",
        ["aarch64"] = "Linux_arm64",
        ["armv7l"] = "Linux_armv7",
        ["armv7"] = "Linux_armv7",
        ["mipsel"] = "Linux_mipsle",
        ["mips"] = "Linux_mipsle",
        ["riscv64"] = "Linux_riscv64",
        ["loong64"] = "Linux_loong64"
    }
    return arch_map[m] or nil, m
end

-- Get latest PicoClaw version from GitHub API
function get_latest_picoclaw_version()
    local latest_ver = ""
    local f = io.popen("curl -sL --max-time 5 'https://api.github.com/repos/sipeed/picoclaw/releases/latest' 2>/dev/null")
    if f then
        local body = f:read("*a")
        f:close()
        local ok, data = pcall(jsonc.parse, body)
        if ok and data and data.tag_name then
            latest_ver = data.tag_name:gsub("^v", "")
        end
    end
    return latest_ver
end

-- Install PicoClaw binary from GitHub
function do_install_picoclaw(arch)
    local version = get_latest_picoclaw_version()
    if version == "" then version = "0.2.6" end
    local url = "https://github.com/sipeed/picoclaw/releases/download/v" .. version .. "/picoclaw_" .. arch .. ".tar.gz"
    sys.exec("mkdir -p /tmp/picoclaw-install")
    sys.exec("curl -L -o /tmp/picoclaw-install/picoclaw.tar.gz '" .. url .. "' --max-time 120 2>&1")
    -- Verify download
    local dl_size = sys.exec("wc -c < /tmp/picoclaw-install/picoclaw.tar.gz 2>/dev/null"):match("^%s*(%d+)")
    if not dl_size or tonumber(dl_size) < 100000 then
        sys.exec("rm -rf /tmp/picoclaw-install")
        return false, "download_failed"
    end
    sys.exec("cd /tmp/picoclaw-install && tar xzf picoclaw.tar.gz 2>&1")
    sys.exec("cp /tmp/picoclaw-install/picoclaw /usr/bin/picoclaw 2>/dev/null")
    -- Verify binary
    if not is_picoclaw_installed() then
        sys.exec("rm -rf /tmp/picoclaw-install")
        return false, "extract_failed"
    end
    sys.exec("chmod +x /usr/bin/picoclaw")
    -- Install init.d script if not exists
    if not nixio.fs.access("/etc/init.d/picoclaw") then
        sys.exec("mkdir -p /etc/init.d")
        local init_content = [[#!/bin/sh /etc/rc.common
START=99
STOP=10
USE_PROCD=1
start_service() {
    procd_open_instance picoclaw
    procd_set_param command /usr/bin/picoclaw gateway
    procd_set_param env HOME=/root
    procd_set_param respawn 3600 5 5
    procd_set_param stdout 1
    procd_set_param stderr 1
    procd_set_param user root
    procd_close_instance
}
stop_service() {
    # First try graceful shutdown via procd
    killall picoclaw 2>/dev/null
    sleep 1
    # Force kill if still alive (procd may respawn)
    if [ -n "$(pidof picoclaw)" ]; then
        kill -9 $(pidof picoclaw) 2>/dev/null
        sleep 1
    fi
    # Final cleanup: ensure no zombie processes
    sleep 1
}
service_triggers() {
    procd_add_reload_trigger "picoclaw"
}
]]
        local inf = io.open("/etc/init.d/picoclaw", "w")
        if inf then
            inf:write(init_content)
            inf:close()
            sys.exec("chmod +x /etc/init.d/picoclaw")
            sys.exec("/etc/init.d/picoclaw enable")
        end
    end
    -- Create config directory if not exists
    sys.exec("mkdir -p /root/.picoclaw/workspace/skills")
    sys.exec("rm -rf /tmp/picoclaw-install")
    return true, version
end

function get_status()
    local pid = ""
    local running = false
    local memory_kb = 0
    local port_active = false
    local f = io.popen("ps | grep 'picoclaw gateway' | grep -v grep | head -1 2>/dev/null")
    if f then
        local line = f:read("*l") or ""
        f:close()
        local p = line:match("^%s*(%d+)")
        if p and p ~= "" then
            pid = p
            running = true
        end
    end
    if running and pid ~= "" then
        local mf = io.open("/proc/" .. pid .. "/status", "r")
        if mf then
            local c = mf:read("*a")
            mf:close()
            local vm = c:match("VmRSS:%s*(%d+)")
            if vm then memory_kb = tonumber(vm) or 0 end
        end
    end
    local actual_port = nil
    local port_active = false
    -- Try to read the actual gateway port from config.json
    local cfg = parse_json_file("/root/.picoclaw/config.json")
    if cfg then
        if cfg.gateway and cfg.gateway.port then
            actual_port = tonumber(cfg.gateway.port)
        elseif cfg.channel_list and cfg.channel_list.maixcam and cfg.channel_list.maixcam.settings and cfg.channel_list.maixcam.settings.port then
            actual_port = tonumber(cfg.channel_list.maixcam.settings.port)
        elseif cfg.channels and cfg.channels.maixcam and cfg.channels.maixcam.port then
            actual_port = tonumber(cfg.channels.maixcam.port)
        end
    end
    -- Default fallback ports to check
    local ports_to_check = {}
    if actual_port then
        table.insert(ports_to_check, actual_port)
    end
    -- Always check common default ports as fallback
    for _, dp in ipairs({18790, 18791}) do
        local already = false
        for _, p in ipairs(ports_to_check) do if p == dp then already = true; break end end
        if not already then table.insert(ports_to_check, dp) end
    end
    -- Check /proc/net/tcp and tcp6 for listening ports
    for _, pname in ipairs({"/proc/net/tcp", "/proc/net/tcp6"}) do
        local nf = io.open(pname, "r")
        if nf then
            local c = nf:read("*a")
            nf:close()
            for _, pt in ipairs(ports_to_check) do
                local hex_port = string.format("%04X", pt)
                if c:find(":" .. hex_port .. " ") then
                    port_active = true
                    break
                end
            end
            if port_active then break end
        end
    end
    return {running=running, pid=pid, memory_kb=memory_kb, port_active=port_active, gateway_port=actual_port}
end

function get_config()
    local f = io.open("/root/.picoclaw/config.json", "r")
    if not f then return nil, "Config file not found" end
    local c = f:read("*a")
    f:close()
    return c, nil
end

function get_version_info()
    local cur_ver = "N/A"
    local build_time = ""
    local git_commit = ""
    local output = sys.exec("HOME=/root /usr/bin/picoclaw version 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g'")
    if output and output ~= "" then
        -- Match: "picoclaw 0.2.6 (git: 5f50ae5)"
        local v, g = output:match("picoclaw%s+([%d.]+)%s*%(%s*git:%s*([a-f0-9]+)%s*%)")
        if v then cur_ver = v end
        if g then git_commit = g end
        -- Match: "Build: 2026-03-25T09:09:15Z"
        local bt = output:match("Build:%s*([%dT:Z%d%-]+)")
        if bt then build_time = bt end
    end
    return cur_ver, build_time, git_commit
end

function check_latest_version()
    local latest_ver = ""
    local latest_url = ""
    local err_msg = ""
    local cache_file = "/tmp/picoclaw_latest_ver"
    local cache_ttl = 21600 -- 6 hours

    -- Read cached version (may be stale but still useful as fallback)
    local cached_ver = ""
    local cached_url = ""
    local ts = 0
    local cf = io.open(cache_file, "r")
    if cf then
        local cached = cf:read("*a")
        cf:close()
        cached_ver = cached:match("^([%d.]+)") or ""
        cached_url = cached:match("\n(.+)$") or ""
        local tf = io.open(cache_file .. ".ts", "r")
        if tf then
            ts = tonumber(tf:read("*l")) or 0
            tf:close()
        end
    end
    local cache_age = os.time() - ts

    -- If cache is fresh, return directly
    if cached_ver ~= "" and cache_age < cache_ttl then
        return cached_ver, cached_url, ""
    end

    -- Detect architecture for download URL matching
    local arch = "linux_arm64"
    local m = sys.exec("uname -m")
    if m:find("x86") then arch = "linux_amd64"
    elseif m:find("armv7") then arch = "linux_armv7" end

    -- Method 1: HEAD request to releases/latest redirect (no API rate limit)
    local f = io.popen("curl -sI -L --max-time 8 'https://github.com/sipeed/picoclaw/releases/latest' 2>/dev/null | grep -i '^location:' | tail -1")
    if f then
        local location = f:read("*a"):match("[Ll]ocation:%s*(.+)")
        f:close()
        if location then
            location = location:match("^%s*(.-)%s*$")
            local tag = location:match("/tag/v?([%d%.%-]+[a-z]?[%d]*)$")
            if tag then
                latest_ver = tag
            end
        end
    end

    -- Method 2: Fallback to Tags API (lighter than full release API)
    if latest_ver == "" then
        local f2 = io.popen("curl -sL --max-time 5 'https://api.github.com/repos/sipeed/picoclaw/tags?per_page=1' 2>/dev/null")
        if f2 then
            local body = f2:read("*a")
            f2:close()
            local ok, data = pcall(jsonc.parse, body)
            if ok and data and type(data) == "table" and #data > 0 and data[1].name then
                latest_ver = data[1].name:gsub("^v", "")
            end
        end
    end

    -- Build download URL when we have a version
    if latest_ver ~= "" then
        latest_url = "https://github.com/sipeed/picoclaw/releases/download/v" .. latest_ver .. "/picoclaw_" .. arch .. ".tar.gz"

        -- Update cache
        local cf2 = io.open(cache_file, "w")
        if cf2 then
            cf2:write(latest_ver .. "\n" .. latest_url)
            cf2:close()
        end
        local tf = io.open(cache_file .. ".ts", "w")
        if tf then
            tf:write(tostring(os.time()))
            tf:close()
        end
    end

    -- On failure: return stale cache (if any) instead of showing "checking"
    if latest_ver == "" then
        if cached_ver ~= "" then
            return cached_ver, cached_url, "stale"
        else
            err_msg = "checking"
        end
    end

    return latest_ver, latest_url, err_msg
end

function get_logs()
    local l = sys.exec("logread 2>/dev/null | grep -i picoclaw | tail -50")
    if l == "" then
        l = sys.exec("logread 2>/dev/null | tail -30")
    end
    return l
end

-- Sync workspace memory files when model changes
-- PicoClaw reads these .md files as its "memory" on startup,
-- so stale model names there cause AI to self-identify incorrectly
function sync_workspace_memory(cfg)
    if type(cfg) ~= "table" then return end
    local defaults = cfg["agents"]
    if type(defaults) ~= "table" then defaults = cfg end
    if type(defaults) ~= "table" then return end
    defaults = defaults["defaults"] or defaults
    local new_model = defaults and defaults["model_name"]
    if not new_model or new_model == "" then return end

    local ws_dir = "/root/.picoclaw/workspace"
    local changed = false

    -- Layer 1 & 2: Update memory .md files (replace old model name)
    local mem_files = {
        { path = ws_dir .. "/MEMORY.md" },
        { path = ws_dir .. "/memory/MEMORY.md" },
        { path = ws_dir .. "/USER.md" },
    }
    for _, entry in ipairs(mem_files) do
        local f = io.open(entry.path, "r")
        if f then
            local content = f:read("*a")
            f:close()
            local updated = content:gsub("(当前默认模型:%s*)%S+", "%1" .. new_model)
            updated = updated:gsub("(Default model:%s*)%S+", "%1" .. new_model)
            if updated ~= content then
                local wf = io.open(entry.path, "w")
                if wf then wf:write(updated); wf:close() end
                changed = true
            end
        end
    end

    -- Layer 3: Clear session history only when memory files actually changed
    -- (i.e., model name was different → stale conversation context exists)
    if changed then
        local sess_dir = ws_dir .. "/sessions"
        -- Use ls glob instead of find for BusyBox compatibility & simplicity
        local handle = io.popen("ls " .. sess_dir .. "/*.jsonl " .. sess_dir .. "/*.meta.json 2>/dev/null")
        if handle then
            for filepath in handle:lines() do
                os.remove(filepath)
            end
            handle:close()
        end
    end
end

function html_escape(s)
    if not s then return "" end
    s = tostring(s)
    s = s:gsub("&", "&amp;")
    s = s:gsub("<", "&lt;")
    s = s:gsub(">", "&gt;")
    s = s:gsub('"', "&quot;")
    return s
end

-- Escape string for embedding in a JS single-quoted string
-- Only escapes: backslash, single quote, newlines, carriage returns
function js_escape(s)
    if not s then return "{}" end
    s = tostring(s)
    s = s:gsub("\\", "\\\\")
    s = s:gsub("'", "\\'")
    s = s:gsub("\n", "\\n")
    s = s:gsub("\r", "\\r")
    return s
end

-- Find the correct download filename from GitHub release assets
-- Dynamically matches architecture, so file name changes won't break updates
function find_release_asset_url(version)
    local arch, uname_m = get_picoclaw_arch()
    if not arch then
        return nil, "unsupported_arch:" .. (uname_m or "unknown")
    end

    -- Build keyword list for matching (order: most specific to least)
    local keywords = { arch }
    -- Also add uname -m based fallbacks
    if uname_m == "aarch64" then
        keywords = { arch, "Linux_arm64", "arm64", "aarch64" }
    elseif uname_m == "x86_64" then
        keywords = { arch, "Linux_x86_64", "x86_64", "amd64" }
    elseif uname_m == "armv7l" or uname_m == "armv7" then
        keywords = { arch, "Linux_armv7", "armv7" }
    elseif uname_m == "mipsel" or uname_m == "mips" then
        keywords = { arch, "Linux_mipsle", "mipsle" }
    elseif uname_m == "riscv64" then
        keywords = { arch, "Linux_riscv64", "riscv64" }
    elseif uname_m == "loong64" then
        keywords = { arch, "Linux_loong64", "loong64" }
    end

    local tag = "latest"
    if version and version ~= "" then tag = "v" .. version end
    local api_url = "https://api.github.com/repos/sipeed/picoclaw/releases/" .. tag
    local f = io.popen("curl -sL --max-time 10 '" .. api_url .. "' 2>/dev/null")
    if not f then return nil, "api_request_failed" end
    local body = f:read("*a")
    f:close()

    local ok, data = pcall(jsonc.parse, body)
    if not ok or not data or not data.assets then
        return nil, "parse_failed"
    end

    -- Prefer tar.gz, then zip, then any other archive
    local candidates = {}  -- score -> {name, url, score}
    for _, asset in ipairs(data.assets) do
        local name = asset.name or ""
        -- Must be a picoclaw file
        if name:match("^picoclaw_") and not name:match("checksum") then
            local matched_keyword = nil
            local score = 0
            for i, kw in ipairs(keywords) do
                if name:find(kw, 1, true) then
                    matched_keyword = kw
                    score = #keywords - i + 1  -- higher = better match
                    break
                end
            end
            if matched_keyword then
                -- Prefer tar.gz over other formats
                if name:match("%.tar%.gz$") then score = score + 100 end
                if name:match("%.zip$") then score = score + 50 end
                if not candidates[score] or #candidates[score].name < #name then
                    candidates[score] = { name = name, url = asset.browser_download_url, score = score }
                end
            end
        end
    end

    -- Pick highest score
    local best = nil
    for _, c in pairs(candidates) do
        if not best or c.score > best.score then best = c end
    end

    if best then
        return best.url, nil
    end
    return nil, "no_matching_asset"
end

-- Recursive directory removal using Lua (safer than rm -rf)
local function rmtree(path)
    if nixio.fs.stat(path, "type") == "dir" then
        for entry in nixio.fs.dir(path) do
            rmtree(path .. "/" .. entry)
        end
    end
    os.remove(path)
end

-- Escape single quotes for safe shell embedding
local function shell_quote(s)
    return "'" .. s:gsub("'", "'\\''") .. "'"
end

-- Verify path is under expected prefix (prevent traversal/injection)
local function is_safe_tmp_path(path)
    return path:match("^/tmp/luci%-upload") or path:match("^/tmp/")
end

-- Upload and install PicoClaw binary from local file
function do_upload_install(upload_path)
    if not upload_path or upload_path == "" then
        return false, "no_file"
    end
    -- Security: only allow LuCI temp upload paths
    if not is_safe_tmp_path(upload_path) then
        return false, "invalid_path"
    end
    -- Verify uploaded file exists
    local f = io.open(upload_path, "rb")
    if not f then return false, "file_not_found" end
    f:close()

    sys.exec("mkdir -p /tmp/picoclaw-update")

    -- Detect archive type from content (not extension)
    local head_f = io.open(upload_path, "rb")
    local magic = head_f:read(2)
    head_f:close()
    local is_zip = (magic == "PK")  -- zip starts with PK
    local extract_ok = false

    if is_zip then
        sys.exec("cp " .. shell_quote(upload_path) .. " /tmp/picoclaw-update/upload.zip")
        sys.exec("cd /tmp/picoclaw-update && unzip -o upload.zip 2>&1")
        extract_ok = nixio.fs.access("/tmp/picoclaw-update/picoclaw")
    else
        -- Assume tar.gz (or try tar anyway)
        sys.exec("cp " .. shell_quote(upload_path) .. " /tmp/picoclaw-update/upload.tar.gz")
        sys.exec("cd /tmp/picoclaw-update && tar xzf upload.tar.gz 2>&1")
        extract_ok = nixio.fs.access("/tmp/picoclaw-update/picoclaw")
    end
    -- If not at top level, search subdirectories
    if not extract_ok then
        local sf = io.popen("find /tmp/picoclaw-update -name 'picoclaw' -type f 2>/dev/null")
        if sf then
            local found = sf:read("*a"):match("[^\n]+")
            sf:close()
            if found and found:match("^/tmp/picoclaw%-update/") then
                sys.exec("cp " .. shell_quote(found) .. " /tmp/picoclaw-update/picoclaw")
                extract_ok = true
            end
        end
    end
    if not extract_ok then
        sys.exec("rm -rf /tmp/picoclaw-update")
        return false, "extract_failed"
    end

    -- Stop service, install, restart
    sys.exec("killall picoclaw 2>/dev/null")
    sys.exec("sleep 1")
    sys.exec("cp /usr/bin/picoclaw /usr/bin/picoclaw.bak 2>/dev/null")
    sys.exec("cp /tmp/picoclaw-update/picoclaw /usr/bin/picoclaw")
    sys.exec("chmod +x /usr/bin/picoclaw")
    sys.exec("rm -rf /tmp/picoclaw-update")
    sys.exec("logger -t picoclaw 'Upload install complete, restarting...'")
    sys.exec("/etc/init.d/picoclaw start 2>/dev/null || (HOME=/root /usr/bin/picoclaw gateway >/dev/null 2>&1 &)")
    return true, "ok"
end

-- Update PicoClaw binary via GitHub Release (auto-detects architecture)
function do_update()
    local dl_url, err = find_release_asset_url()
    if not dl_url then
        sys.exec("logger -t picoclaw 'Update failed: cannot find release asset (" .. (err or "unknown") .. ")'")
        return
    end
    sys.exec("killall picoclaw 2>/dev/null")
    sys.exec("sleep 1")
    sys.exec("mkdir -p /tmp/picoclaw-update")
    sys.exec("curl -L -o /tmp/picoclaw-update/picoclaw.tar.gz '" .. dl_url .. "' --max-time 180 2>&1")
    local dl_size = sys.exec("wc -c < /tmp/picoclaw-update/picoclaw.tar.gz 2>/dev/null"):match("^%s*(%d+)")
    if not dl_size or tonumber(dl_size) < 5000000 then
        sys.exec("logger -t picoclaw 'Update failed: download too small (" .. (dl_size or "0") .. " bytes)'")
        sys.exec("rm -rf /tmp/picoclaw-update")
        return
    end
    local ext = dl_url:match("%.([^.]+)$")
    local extract_ok = false
    if ext == "zip" then
        sys.exec("cd /tmp/picoclaw-update && unzip -o picoclaw.tar.gz 2>&1")
        extract_ok = nixio.fs.access("/tmp/picoclaw-update/picoclaw")
    else
        sys.exec("cd /tmp/picoclaw-update && tar xzf picoclaw.tar.gz 2>&1")
        extract_ok = nixio.fs.access("/tmp/picoclaw-update/picoclaw")
    end
    if not extract_ok then
        local f = io.popen("find /tmp/picoclaw-update -name 'picoclaw' -type f 2>/dev/null")
        if f then
            local found = f:read("*a"):match("([^\n]+)")
            f:close()
            if found and found:match("^/tmp/picoclaw%-update/") then
                sys.exec("cp " .. shell_quote(found) .. " /tmp/picoclaw-update/picoclaw")
                extract_ok = true
            end
        end
    end
    if not extract_ok then
        sys.exec("logger -t picoclaw 'Update failed: extraction failed'")
        sys.exec("rm -rf /tmp/picoclaw-update")
        return
    end
    sys.exec("cp /usr/bin/picoclaw /usr/bin/picoclaw.bak 2>/dev/null")
    sys.exec("cp /tmp/picoclaw-update/picoclaw /usr/bin/picoclaw")
    sys.exec("chmod +x /usr/bin/picoclaw")
    sys.exec("rm -rf /tmp/picoclaw-update")
    sys.exec("logger -t picoclaw 'Update complete, restarting...'")
    sys.exec("/etc/init.d/picoclaw start 2>/dev/null || (HOME=/root /usr/bin/picoclaw gateway >/dev/null 2>&1 &)")
    sys.exec("sleep 3")
end

-- Validate CSRF token for POST actions
function check_csrf()
    local token = http.formvalue("token")
    if not token or token ~= dispatcher.context.authtoken then
        http.status(403, "Forbidden")
        http.write("Invalid CSRF token")
        return false
    end
    return true
end

-- ============================================================
-- Hardware: System Info
-- ============================================================
function get_sysinfo()
    local info = {
        hostname = sys.exec("cat /proc/sys/kernel/hostname 2>/dev/null"):match("^%s*(.-)%s*$") or "",
        kernel = sys.exec("uname -r 2>/dev/null"):match("^%s*(.-)%s*$") or "",
        arch = sys.exec("uname -m 2>/dev/null"):match("^%s*(.-)%s*$") or "",
        uptime = "",
        cpu_model = "",
        cpu_cores = 0,
        load_avg = "",
        mem_total = 0,
        mem_free = 0,
        mem_available = 0,
        cpu_temp = {},
        disks = {}
    }
    -- Uptime
    local up = sys.exec("cat /proc/uptime 2>/dev/null")
    local secs = tonumber(up:match("^([%d.]+)")) or 0
    local days = math.floor(secs / 86400)
    local hours = math.floor((secs % 86400) / 3600)
    local mins = math.floor((secs % 3600) / 60)
    info.uptime = string.format("%dd %dh %dm", days, hours, mins)
    -- Load average
    info.load_avg = sys.exec("cat /proc/loadavg 2>/dev/null"):match("^([%d. ]+)")
    -- CPU
    local cpuinfo = sys.exec("cat /proc/cpuinfo 2>/dev/null")
    info.cpu_model = cpuinfo:match("Hardware[%s]*:[%s]*(.-)\n") or cpuinfo:match("model name[%s]*:[%s]*(.-)\n") or ""
    for _ in cpuinfo:gmatch("processor") do info.cpu_cores = info.cpu_cores + 1 end
    -- Memory
    local meminfo = sys.exec("cat /proc/meminfo 2>/dev/null")
    local mt = meminfo:match("MemTotal:[%s]*(%d+)")
    local mf = meminfo:match("MemFree:[%s]*(%d+)")
    local ma = meminfo:match("MemAvailable:[%s]*(%d+)")
    if mt then info.mem_total = math.floor(tonumber(mt) / 1024) end
    if mf then info.mem_free = math.floor(tonumber(mf) / 1024) end
    if ma then info.mem_available = math.floor(tonumber(ma) / 1024) end
    -- CPU Temperature
    local temps = sys.exec("cat /sys/class/thermal/thermal_zone*/temp 2>/dev/null")
    local types = sys.exec("cat /sys/class/thermal/thermal_zone*/type 2>/dev/null")
    for temp, ttype in temps:gmatch("(%d+)\n") do
        local temp_c = math.floor(tonumber(temp) / 1000)
        table.insert(info.cpu_temp, temp_c)
    end
    -- Disks
    local df = sys.exec("df -h 2>/dev/null | grep -v '^Filesystem\\|^overlay\\|^tmpfs\\|^devtmpfs\\|^/dev\\|^none'")
    for line in df:gmatch("[^\n]+") do
        local parts = {}
        for p in line:gmatch("%S+") do table.insert(parts, p) end
        if #parts >= 6 then
            table.insert(info.disks, {
                filesystem = parts[1],
                size = parts[2],
                used = parts[3],
                avail = parts[4],
                use_pct = parts[5],
                mounted = parts[6]
            })
        end
    end
    return info
end

-- ============================================================
-- Hardware: GPIO
-- ============================================================
function get_gpio_info()
    local pins = {}
    local debug_out = sys.exec("cat /sys/kernel/debug/gpio 2>/dev/null")
    if debug_out == "" then return pins end
    for line in debug_out:gmatch("[^\n]+") do
        local name, dir, val, func, drive, pull = line:match("^%s*(gpio%d+)%s*:%s*(in|out)%s*(%w+)%s*func(%d+)%s*(%d+)mA%s*(.-)%s*$")
        if name then
            table.insert(pins, {
                name = name,
                direction = dir,
                value = val,
                function_num = func,
                drive = drive,
                pull = pull
            })
        end
    end
    return pins
end

function gpio_export(num)
    local f = io.open("/sys/class/gpio/export", "w")
    if f then f:write(tostring(num)); f:close() end
    sys.exec("sleep 0.1")
end

function gpio_unexport(num)
    local f = io.open("/sys/class/gpio/unexport", "w")
    if f then f:write(tostring(num)); f:close() end
end

function gpio_set(num, val)
    local base = "/sys/class/gpio/gpio" .. tostring(num)
    gpio_export(num)
    local f = io.open(base .. "/direction", "w")
    if f then f:write("out"); f:close() end
    f = io.open(base .. "/value", "w")
    if f then f:write(val == 1 and "1" or "0"); f:close() end
end

function gpio_read(num)
    local base = "/sys/class/gpio/gpio" .. tostring(num)
    local f = io.open(base .. "/value", "r")
    if f then
        local v = f:read("*l")
        f:close()
        return v
    end
    return nil
end

-- ============================================================
-- Hardware: LED
-- ============================================================
function get_leds()
    local leds = {}
    local led_dir = io.popen("ls /sys/class/leds/ 2>/dev/null")
    if not led_dir then return leds end
    for name in led_dir:lines() do
        local base = "/sys/class/leds/" .. name
        local f = io.open(base .. "/brightness", "r")
        local brightness = f and tonumber(f:read("*l")) or 0
        if f then f:close() end
        f = io.open(base .. "/max_brightness", "r")
        local max_b = f and tonumber(f:read("*l")) or 255
        if f then f:close() end
        f = io.open(base .. "/trigger", "r")
        local trigger_raw = f and f:read("*l") or "none"
        if f then f:close() end
        -- Extract current trigger (marked with [])
        local trigger = trigger_raw:match("%[(.-)%]") or "none"
        -- Extract all available triggers
        local triggers = {}
        for t in trigger_raw:gmatch("(%w+)") do
            table.insert(triggers, t)
        end
        table.insert(leds, {
            name = name,
            brightness = brightness,
            max_brightness = max_b,
            trigger = trigger,
            triggers = triggers
        })
    end
    led_dir:close()
    return leds
end

function led_set(name, brightness, trigger)
    local base = "/sys/class/leds/" .. name
    if trigger then
        local f = io.open(base .. "/trigger", "w")
        if f then f:write(trigger); f:close() end
    end
    if brightness then
        local f = io.open(base .. "/brightness", "w")
        if f then f:write(tostring(math.max(0, math.min(255, tonumber(brightness) or 0)))); f:close() end
    end
end

-- ============================================================
-- Hardware: USB
-- ============================================================
function get_usb_devices()
    local devices = {}
    local lsusb = sys.exec("lsusb 2>/dev/null")
    if lsusb == "" then
        -- Fallback: read from sysfs
        local product = sys.exec("for d in /sys/bus/usb/devices/*/; do name=$(basename $d); if [ -f $d/product ]; then prod=$(cat $d/product 2>/dev/null); vid=$(cat $d/idVendor 2>/dev/null); pid=$(cat $d/idProduct 2>/dev/null); echo \"$name|$prod|$vid|$pid\"; fi; done")
        for line in product:gmatch("[^\n]+") do
            local parts = {}
            for p in line:gmatch("[^|]+") do table.insert(parts, p) end
            if #parts >= 4 then
                table.insert(devices, {
                    bus_dev = parts[1],
                    product = parts[2],
                    vid = parts[3],
                    pid = parts[4]
                })
            end
        end
    else
        for line in lsusb:gmatch("[^\n]+") do
            local bus, dev, rest = line:match("Bus (%d+) Device (%d+): (.+)")
            if bus then
                table.insert(devices, {
                    bus_dev = "Bus " .. bus .. " Dev " .. dev,
                    product = rest
                })
            end
        end
    end
    return devices
end

-- ============================================================
-- Hardware: PicoClaw Tools (cron, skills)
-- ============================================================
function get_picoclaw_tools()
    local tools = {
        cron_jobs = {},
        skills = {}
    }
    -- Cron jobs
    local cron_out = sys.exec("HOME=/root /usr/bin/picoclaw cron list 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | grep -v 'PicoClaw\\|^$\\|████'")
    if cron_out and cron_out ~= "" and not cron_out:find("No scheduled") then
        for line in cron_out:gmatch("[^\n]+") do
            line = line:match("^%s*(.-)%s*$")
            if line and line ~= "" then
                table.insert(tools.cron_jobs, line)
            end
        end
    end
    -- Skills
    local skill_dir = io.popen("ls /root/.picoclaw/workspace/skills/ 2>/dev/null")
    if skill_dir then
        for name in skill_dir:lines() do
            local desc = ""
            local f = io.open("/root/.picoclaw/workspace/skills/" .. name .. "/SKILL.md", "r")
            if f then
                local content = f:read("*a")
                f:close()
                desc = content:match("description:%s*\"(.-)\"") or content:match("description:%s*(.-)\n") or ""
            end
            table.insert(tools.skills, { name = name, description = desc })
        end
        skill_dir:close()
    end
    return tools
end

-- ============================================================
-- Chat: Send message via picoclaw agent --message
-- ============================================================
local CHAT_DIR = "/tmp/picoclaw-chat"
local CHAT_HISTORY_FILE = CHAT_DIR .. "/history.json"

-- Ensure chat directory exists
local function ensure_chat_dir()
    sys.exec("mkdir -p '" .. CHAT_DIR .. "'")
end

-- Read chat history from file
local function read_chat_history()
    ensure_chat_dir()
    local f = io.open(CHAT_HISTORY_FILE, "r")
    if not f then return {} end
    local content = f:read("*a")
    f:close()
    if content == "" then return {} end
    local ok, data = pcall(jsonc.parse, content)
    if ok and type(data) == "table" then return data end
    return {}
end

-- Write chat history to file
local function write_chat_history(history)
    ensure_chat_dir()
    local f = io.open(CHAT_HISTORY_FILE, "w")
    if f then
        f:write(require("luci.jsonc").stringify(history))
        f:close()
    end
end

-- Sanitize user input (prevent command injection)
local function sanitize_input(s)
    if not s then return "" end
    s = tostring(s)
    -- Remove shell metacharacters that could be dangerous
    s = s:gsub("[`$]", "")
    -- Limit length
    if #s > 2000 then s = s:sub(1, 2000) end
    return s
end

function action_chat_send()
    http.prepare_content("application/json")
    local msg = http.formvalue("message") or ""
    if msg == "" then
        http.write_json({error = "empty message"})
        return
    end

    -- Check picoclaw is running
    local st = get_status()
    if not st.running then
        http.write_json({error = "picoclaw not running"})
        return
    end

    msg = sanitize_input(msg)

    -- Read existing history
    local history = read_chat_history()

    -- Add user message to history
    table.insert(history, {role = "user", content = msg, time = os.time()})
    write_chat_history(history)

    -- Create a unique task file
    local task_id = tostring(os.time()) .. tostring(math.random(1000, 9999))
    local result_file = CHAT_DIR .. "/result_" .. task_id
    local status_file = CHAT_DIR .. "/status_" .. task_id

    -- Write "running" status
    local sf = io.open(status_file, "w")
    if sf then sf:write("running"); sf:close() end

    -- Launch picoclaw agent in background (must run from /root to find config)
    local escaped_msg = msg:gsub("'", "'\\''")
    local cmd = "HOME=/root picoclaw agent --message '" .. escaped_msg .. "' > '" .. result_file .. "' 2>&1 &"
    os.execute(cmd)

    http.write_json({ok = true, task_id = task_id})
end

function action_chat_poll()
    http.prepare_content("application/json")
    local task_id = http.formvalue("task_id") or ""
    if task_id == "" then
        http.write_json({error = "no task_id"})
        return
    end

    -- Sanitize task_id (only digits)
    task_id = task_id:gsub("[^%d]", "")
    if task_id == "" then
        http.write_json({error = "invalid task_id"})
        return
    end

    local status_file = CHAT_DIR .. "/status_" .. task_id
    local result_file = CHAT_DIR .. "/result_" .. task_id

    -- Check status
    local sf = io.open(status_file, "r")
    if not sf then
        http.write_json({status = "not_found"})
        return
    end
    local status = sf:read("*l") or ""
    sf:close()

    if status == "running" then
        -- Check if the process is still alive
        local ps_out = sys.exec("ps | grep 'picoclaw agent' | grep -v grep")
        if ps_out == "" then
            -- Process finished but status file wasn't updated
            local rf = io.open(result_file, "r")
            local reply = ""
            if rf then
                reply = rf:read("*a")
                rf:close()
            end
            -- Update status
            local wf = io.open(status_file, "w")
            if wf then wf:write("done"); wf:close() end

            -- Add assistant reply to history
            if reply ~= "" then
                local history = read_chat_history()
                -- Strip ANSI escape codes using pure Lua (safer than echo+sed shell injection)
                reply = reply:gsub("\x1b%[[0-9;]*m", "")
                -- Also strip carriage returns and the banner
                reply = reply:gsub("\r", "")
                -- Remove empty lines and the banner lines
                local clean_lines = {}
                for line in reply:gmatch("[^\n]+") do
                    -- Skip banner lines (contain only block characters)
                    if not line:match("^[%s█╗╔═║╚╝╠╣╦╩╬]*$") then
                        table.insert(clean_lines, line)
                    end
                end
                reply = table.concat(clean_lines, "\n"):match("^%s*(.-)%s*$") or ""
                table.insert(history, {role = "assistant", content = reply, time = os.time()})
                write_chat_history(history)
            end

            http.write_json({status = "done", reply = reply})
        else
            http.write_json({status = "running"})
        end
    else
        -- Done or error
        local rf = io.open(result_file, "r")
        local reply = ""
        if rf then
            reply = rf:read("*a")
            rf:close()
        end
        reply = reply:gsub("\x1b%[[0-9;]*m", "")
        reply = reply:match("^%s*(.-)%s*$") or ""
        http.write_json({status = status, reply = reply})
    end
end

function action_do()
    if not check_csrf() then return end

    local action = http.formvalue("action") or ""
    local msg = ""
    local ok = true

    if action == "start" then
        sys.exec("/etc/init.d/picoclaw start")
        msg = "服务正在启动..."
    elseif action == "stop" then
        sys.exec("/etc/init.d/picoclaw stop; killall picoclaw 2>/dev/null")
        msg = "服务已停止。"
    elseif action == "restart" then
        sys.exec("/etc/init.d/picoclaw stop; killall picoclaw 2>/dev/null; sleep 1; /etc/init.d/picoclaw start")
        msg = "服务已重启。"
    elseif action == "install_picoclaw" then
        local arch, raw_arch = get_picoclaw_arch()
        if not arch then
            msg = "错误：不支持的架构 (" .. (raw_arch or "unknown") .. ")"
            ok = false
        else
            local success, result = do_install_picoclaw(arch)
            if success then
                msg = "PicoClaw v" .. tostring(result) .. " 安装成功！正在启动服务..."
                sys.exec("/etc/init.d/picoclaw start")
            elseif result == "download_failed" then
                msg = "错误：下载失败，请检查网络连接（可能无法访问 GitHub）"
                ok = false
            elseif result == "extract_failed" then
                msg = "错误：解压失败，文件可能已损坏"
                ok = false
            else
                msg = "错误：安装失败"
                ok = false
            end
        end
    elseif action == "autostart_on" then
        sys.exec("/etc/init.d/picoclaw enable 2>/dev/null")
        msg = "已启用开机自动启动。"
    elseif action == "autostart_off" then
        sys.exec("/etc/init.d/picoclaw disable 2>/dev/null")
        msg = "已关闭开机自动启动。"
    elseif action == "save_config" or action == "save_form_config" then
        local config = http.formvalue("config") or ""
        if config ~= "" then
            -- Validate JSON before saving
            local valid, cfg_obj = pcall(jsonc.parse, config)
            if not valid then
                msg = "错误：JSON 格式无效"
                ok = false
            else
                -- 0.3.1 起严格校验字段：先备份，写盘后用 CLI 试解析，失败就回滚
                sys.exec("cp /root/.picoclaw/config.json /tmp/picoclaw-config.prev 2>/dev/null")
                local f = io.open("/root/.picoclaw/config.json", "w")
                if f then
                    f:write(config)
                    f:close()
                    local probe = strip_ansi(sys.exec("HOME=/root /usr/bin/picoclaw model 2>&1"))
                    if probe:find("Failed to load config", 1, true) or probe:find("unknown field", 1, true) then
                        sys.exec("cp /tmp/picoclaw-config.prev /root/.picoclaw/config.json 2>/dev/null")
                        local detail = ""
                        local m = probe:match("unknown field%(s%):%s*([^\n]+)")
                        if m then detail = "：" .. m end
                        msg = "错误：PicoClaw 拒绝了这份配置" .. detail .. "，已回滚到上一版"
                        ok = false
                    else
                        -- Sync workspace memory files so PicoClaw's AI context reflects the new model
                        sync_workspace_memory(cfg_obj)
                        sys.exec("/etc/init.d/picoclaw stop; killall picoclaw 2>/dev/null; sleep 1; /etc/init.d/picoclaw start")
                        msg = "配置已保存，服务已重启！"
                    end
                else
                    msg = "错误：无法写入配置文件"
                    ok = false
                end
            end
        else
            msg = "错误：配置内容为空"
            ok = false
        end
    elseif action == "update" then
        do_update()
        msg = "更新完成，服务已重启！"
    elseif action == "upload_install" then
        -- LuCI file upload: http.formvalue returns temp path for file inputs
        local upload_path = http.formvalue("picoclaw_file") or ""
        if upload_path == "" then
            msg = "错误：未选择文件"
            ok = false
        else
            local success, result = do_upload_install(upload_path)
            if success then
                msg = "上传安装成功！服务已重启。"
            elseif result == "invalid_path" then
                msg = "错误：上传路径无效"
                ok = false
            elseif result == "file_not_found" then
                msg = "错误：上传文件不存在"
                ok = false
            elseif result == "extract_failed" then
                msg = "错误：解压失败，请确认文件是有效的 picoclaw 安装包（tar.gz 或 zip）"
                ok = false
            else
                msg = "错误：安装失败"
                ok = false
            end
        end
    elseif action == "refresh_logs" then
        -- Just redirect to main page to refresh logs (GET with CSRF already validated)
        msg = ""
    -- Hardware actions
    elseif action == "led_set" then
        local led_name = http.formvalue("led") or ""
        local brightness = http.formvalue("brightness") or ""
        local trigger = http.formvalue("trigger") or ""
        if led_name ~= "" then
            led_set(led_name, tonumber(brightness) or 0, trigger ~= "" and trigger or nil)
            msg = "LED 已更新: " .. led_name
        else
            msg = "错误：未指定 LED"; ok = false
        end
    elseif action == "gpio_set" then
        local gpio_num = http.formvalue("gpio") or ""
        local gpio_val = http.formvalue("value") or "0"
        if gpio_num ~= "" then
            gpio_set(tonumber(gpio_num) or 0, tonumber(gpio_val) or 0)
            msg = "GPIO " .. gpio_num .. " = " .. gpio_val
        else
            msg = "错误：未指定 GPIO"; ok = false
        end
    elseif action == "usb_power_toggle" then
        local f = io.open("/sys/class/gpio/usb_power/value", "r")
        if f then
            local cur = f:read("*l")
            f:close()
            local new_val = (cur == "1") and "0" or "1"
            local fw = io.open("/sys/class/gpio/usb_power/value", "w")
            if fw then fw:write(new_val); fw:close() end
            msg = "USB 电源已" .. (new_val == "1" and "开启" or "关闭")
        else
            msg = "错误：USB 电源 GPIO 不存在"; ok = false
        end
    elseif action == "delete_skill" then
        local skill_name = http.formvalue("skill_name") or ""
        if skill_name ~= "" then
            -- Sanitize: only allow alphanumeric, underscore, hyphen
            if skill_name:match("^[%w_%-%.]+$") then
                local skill_path = PC_SKILLS_DIR .. "/" .. skill_name
                -- 先走 CLI，能同步 skills store；CLI 说找不到就直接删目录
                sys.exec("HOME=/root /usr/bin/picoclaw skills remove " .. shell_quote(skill_name) .. " >/dev/null 2>&1")
                if nixio.fs.access(skill_path .. "/SKILL.md") then
                    rmtree(skill_path)
                end
                prune_skills_store()
                if nixio.fs.access(skill_path .. "/SKILL.md") then
                    msg = "错误：删除失败"; ok = false
                else
                    msg = "技能已删除: " .. skill_name
                end
            else
                msg = "错误：技能名称无效"; ok = false
            end
        else
            msg = "错误：未指定技能"; ok = false
        end
    elseif action == "install_preset_one" then
        local skill_name = trim(http.formvalue("skill_name"))
        local src = PC_PRESET_DIR .. "/" .. skill_name
        local dst = PC_SKILLS_DIR .. "/" .. skill_name
        if not skill_name:match("^[%w_%-%.]+$") then
            msg = "错误：技能名称无效"; ok = false
        elseif not nixio.fs.access(src .. "/SKILL.md") then
            msg = "错误：没有这个内置技能"; ok = false
        else
            sys.exec("mkdir -p " .. shell_quote(PC_SKILLS_DIR) .. " && cp -r " .. shell_quote(src) .. " " .. shell_quote(PC_SKILLS_DIR) .. "/")
            if nixio.fs.access(dst .. "/SKILL.md") then
                msg = "已安装内置技能: " .. skill_name
            else
                msg = "错误：复制失败"; ok = false
            end
        end
    elseif action == "import_skill" then
        local skill_name = http.formvalue("skill_name") or ""
        local skill_content = http.formvalue("skill_content") or ""
        if skill_name ~= "" and skill_content ~= "" then
            if skill_name:match("^[%w_%-]+$") then
                local skill_dir = "/root/.picoclaw/workspace/skills/" .. skill_name
                sys.exec("mkdir -p '" .. skill_dir .. "'")
                local f = io.open(skill_dir .. "/SKILL.md", "w")
                if f then
                    f:write(skill_content)
                    f:close()
                    msg = "技能已导入: " .. skill_name
                else
                    msg = "错误：无法写入文件"; ok = false
                end
            else
                msg = "错误：技能名称仅允许字母、数字、下划线和连字符"; ok = false
            end
        else
            msg = "错误：请填写技能名称和内容"; ok = false
        end
    elseif action == "install_preset_skills" then
        -- Install built-in preset skills
        local preset_skills_dir = "/usr/lib/lua/luci/picoclaw-skills/"
        local target_dir = "/root/.picoclaw/workspace/skills/"
        local installed = {}
        local found = io.popen("ls '" .. preset_skills_dir .. "' 2>/dev/null")
        if found then
            for name in found:lines() do
                name = name:match("^%s*(.-)%s*$")
                if name and name ~= "" and name:match("^[%w_%-]+$") then
                    local src = preset_skills_dir .. name .. "/SKILL.md"
                    local src_f = io.open(src, "r")
                    if src_f then
                        local content = src_f:read("*a")
                        src_f:close()
                        sys.exec("mkdir -p '" .. target_dir .. name .. "'")
                        local dst_f = io.open(target_dir .. name .. "/SKILL.md", "w")
                        if dst_f then
                            dst_f:write(content)
                            dst_f:close()
                            table.insert(installed, name)
                        end
                    end
                end
            end
            found:close()
        end
        if #installed > 0 then
            msg = "已安装预设技能: " .. table.concat(installed, ", ")
        else
            msg = "未找到预设技能（可能未安装 luci-app-picoclaw 的完整包）"; ok = false
        end
    -- ===== 定时任务 =====
    elseif action == "cron_add" then
        local name = trim(http.formvalue("job_name"))
        local mode = http.formvalue("sched_mode") or "every"
        local every = tonumber(http.formvalue("every_sec") or "") or 0
        local expr = trim(http.formvalue("cron_expr"))
        local message = trim(http.formvalue("job_message"))
        local channel = trim(http.formvalue("job_channel"))
        local to = trim(http.formvalue("job_to"))
        if name == "" or message == "" then
            msg = "错误：任务名称和消息不能为空"; ok = false
        elseif not name:match("^[%w_%-%.%s]+$") then
            msg = "错误：任务名称只能包含字母、数字、空格、下划线、连字符和点"; ok = false
        elseif mode == "cron" and select(2, expr:gsub("%S+", "")) ~= 5 then
            msg = "错误：cron 表达式需要 5 个字段（分 时 日 月 周）"; ok = false
        elseif mode == "every" and (every < 10 or every > 2592000) then
            msg = "错误：间隔需在 10 秒到 30 天之间"; ok = false
        else
            local cmd = "HOME=/root /usr/bin/picoclaw cron add --name " .. shell_quote(name)
                    .. " --message " .. shell_quote(message)
            if mode == "cron" then
                cmd = cmd .. " --cron " .. shell_quote(expr)
            else
                cmd = cmd .. " --every " .. tostring(math.floor(every))
            end
            if channel ~= "" then cmd = cmd .. " --channel " .. shell_quote(channel) end
            if to ~= "" then cmd = cmd .. " --to " .. shell_quote(to) end
            local out = sys.exec(cmd .. " 2>&1")
            if strip_ansi(out):find("✓", 1, true) then
                restart_picoclaw()
                msg = "定时任务「" .. name .. "」已添加，PicoClaw 已重启"
            else
                msg = "错误：" .. last_line(out); ok = false
            end
        end
    elseif action == "cron_toggle" then
        local id = trim(http.formvalue("job_id"))
        local want = (http.formvalue("want") == "1")
        if not id:match("^[%w]+$") then
            msg = "错误：任务 ID 无效"; ok = false
        else
            local out = sys.exec("HOME=/root /usr/bin/picoclaw cron " .. (want and "enable" or "disable") .. " " .. id .. " 2>&1")
            if strip_ansi(out):find("✓", 1, true) then
                restart_picoclaw()
                msg = (want and "任务已启用" or "任务已禁用") .. "，PicoClaw 已重启"
            else
                msg = "错误：" .. last_line(out); ok = false
            end
        end
    elseif action == "cron_delete" then
        local id = trim(http.formvalue("job_id"))
        if not id:match("^[%w]+$") then
            msg = "错误：任务 ID 无效"; ok = false
        else
            local out = sys.exec("HOME=/root /usr/bin/picoclaw cron remove " .. id .. " 2>&1")
            if strip_ansi(out):find("✓", 1, true) then
                restart_picoclaw()
                msg = "任务已删除，PicoClaw 已重启"
            else
                msg = "错误：" .. last_line(out); ok = false
            end
        end
    -- ===== MCP 服务器 =====
    elseif action == "mcp_add" then
        local name = trim(http.formvalue("mcp_name"))
        local transport = http.formvalue("mcp_transport") or "stdio"
        local target = trim(http.formvalue("mcp_target"))
        local arg_txt = trim(http.formvalue("mcp_args"))
        local env_txt = http.formvalue("mcp_env") or ""
        local hdr_txt = http.formvalue("mcp_headers") or ""
        local deferred = (http.formvalue("mcp_deferred") == "1")
        if not name:match("^[%w_%-%.]+$") then
            msg = "错误：名称只能包含字母、数字、下划线、连字符和点"; ok = false
        elseif target == "" then
            msg = "错误：请填写命令或 URL"; ok = false
        elseif transport ~= "stdio" and not target:match("^https?://") then
            msg = "错误：http/sse 传输需要 http(s):// 开头的 URL"; ok = false
        else
            local cmd = "HOME=/root /usr/bin/picoclaw mcp add " .. shell_quote(name) .. " " .. shell_quote(target)
            if transport == "stdio" then
                for a in arg_txt:gmatch("%S+") do
                    cmd = cmd .. " " .. shell_quote(a)
                end
                for line in env_txt:gmatch("[^\n]+") do
                    line = trim(line)
                    if line:match("^[%w_]+=") then cmd = cmd .. " -e " .. shell_quote(line) end
                end
                if deferred then cmd = cmd .. " --deferred" end
            else
                cmd = cmd .. " -t " .. shell_quote(transport)
                for line in hdr_txt:gmatch("[^\n]+") do
                    line = trim(line)
                    if line:find(":", 1, true) or line:find("=", 1, true) then
                        cmd = cmd .. " -H " .. shell_quote(line)
                    end
                end
            end
            local out = sys.exec(cmd .. " --force 2>&1")
            if strip_ansi(out):find("✓", 1, true) then
                restart_picoclaw()
                msg = "MCP 服务器「" .. name .. "」已保存，PicoClaw 已重启"
            else
                msg = "错误：" .. last_line(out); ok = false
            end
        end
    elseif action == "mcp_delete" then
        local name = trim(http.formvalue("mcp_name"))
        if not name:match("^[%w_%-%.]+$") then
            msg = "错误：名称无效"; ok = false
        else
            local out = sys.exec("HOME=/root /usr/bin/picoclaw mcp remove " .. shell_quote(name) .. " 2>&1")
            if strip_ansi(out):find("✓", 1, true) or strip_ansi(out):find("removed", 1, true) then
                restart_picoclaw()
                msg = "MCP 服务器「" .. name .. "」已删除，PicoClaw 已重启"
            else
                msg = "错误：" .. last_line(out); ok = false
            end
        end
    -- ===== 技能 =====
    elseif action == "skill_install" then
        local spec = trim(http.formvalue("skill_spec"))
        local registry = trim(http.formvalue("skill_registry"))
        if spec == "" or not spec:match("^[%w_%-%./:]+$") then
            msg = "错误：请填写 作者/仓库/技能 或注册表中的 slug（只允许字母数字和 . _ - / :）"; ok = false
        else
            local cmd = "timeout 45 env HOME=/root /usr/bin/picoclaw skills install "
            if registry ~= "" then cmd = cmd .. "--registry " .. shell_quote(registry) .. " " end
            local out = sys.exec(cmd .. shell_quote(spec) .. " 2>&1")
            local has_dir = nixio.fs.access(PC_SKILLS_DIR .. "/" .. (spec:match("([^/]+)$") or spec) .. "/SKILL.md")
            if strip_ansi(out):find("✓", 1, true) or has_dir then
                msg = "技能「" .. spec .. "」安装完成"
            else
                msg = "错误：" .. (last_line(out) ~= "" and last_line(out) or "安装失败（可能无法访问 GitHub / clawhub）"); ok = false
            end
        end
    -- ===== 模型 =====
    elseif action == "model_set_default" then
        local name = trim(http.formvalue("model_name"))
        if not name:match("^[%w_%-%.]+$") then
            msg = "错误：模型名无效"; ok = false
        else
            local out = sys.exec("HOME=/root /usr/bin/picoclaw model " .. shell_quote(name) .. " 2>&1")
            local line = last_line(out)
            if strip_ansi(out):find("default", 1, true) or strip_ansi(out):find("✓", 1, true) then
                restart_picoclaw()
                msg = "默认模型已切换为 " .. name .. "，PicoClaw 已重启"
            else
                msg = "错误：" .. line; ok = false
            end
        end
    elseif action == "model_toggle" then
        local name = trim(http.formvalue("model_name"))
        local want = (http.formvalue("want") == "1")
        if not name:match("^[%w_%-%.]+$") then
            msg = "错误：模型名无效"; ok = false
        else
            local done, res = flip_model_enabled(name, want)
            if done then
                restart_picoclaw()
                msg = res == "unchanged" and "状态未变化" or ("模型 " .. name .. (want and " 已启用" or " 已停用"))
            else
                msg = "错误：" .. tostring(res); ok = false
            end
        end
    elseif action == "model_set_thinking" then
        local name = trim(http.formvalue("model_name"))
        local level = trim(http.formvalue("level"))
        if not name:match("^[%w_%-%.]+$") then
            msg = "错误：模型名无效"; ok = false
        else
            local done, res = set_model_thinking(name, level)
            if done then
                restart_picoclaw()
                msg = (level == "" and ("模型 " .. name .. " 已恢复默认推理强度")
                    or ("模型 " .. name .. " 推理强度设为 " .. level)) .. "，PicoClaw 已重启"
            else
                msg = "错误：" .. tostring(res); ok = false
            end
        end
    elseif action == "model_add" then
        local name = trim(http.formvalue("new_model_name"))
        local base = trim(http.formvalue("new_model_base"))
        local key = trim(http.formvalue("new_model_key"))
        local mid = trim(http.formvalue("new_model_id"))
        if not name:match("^[%w_%-%.]+$") then
            msg = "错误：别名只能包含字母、数字、下划线、连字符和点"; ok = false
        elseif base == "" or key == "" or mid == "" then
            msg = "错误：API Base、API Key、模型 ID 都要填"; ok = false
        elseif not base:match("^https?://") then
            msg = "错误：API Base 需要 http(s):// 开头"; ok = false
        else
            local cmd = "HOME=/root /usr/bin/picoclaw model add -b " .. shell_quote(base)
                    .. " -k " .. shell_quote(key)
                    .. " -m " .. shell_quote(mid)
                    .. " -n " .. shell_quote(name) .. " 2>&1"
            local out = sys.exec(cmd)
            if strip_ansi(out):find("✓", 1, true) or strip_ansi(out):find("Saved", 1, true) then
                restart_picoclaw()
                msg = "模型「" .. name .. "」已添加并设为默认，PicoClaw 已重启"
            else
                msg = "错误：" .. last_line(out); ok = false
            end
        end
    end

    local url = dispatcher.build_url("admin", "services", "picoclaw")
    if msg ~= "" then
        url = url .. "?msg=" .. http.urlencode(msg) .. "&ok=" .. (ok and "1" or "0")
    end
    http.redirect(url)
end

-- ============================================================
-- v0.3.1 新增管理页：定时任务 / MCP / 技能 / 模型与认证
-- 数据源全部直接读文件（比每次起 picoclaw 快），写操作走 CLI
-- ============================================================
PC_CONFIG_FILE = "/root/.picoclaw/config.json"
PC_CRON_FILE = "/root/.picoclaw/workspace/cron/jobs.json"
PC_SKILLS_DIR = "/root/.picoclaw/workspace/skills"
PC_PRESET_DIR = "/usr/lib/lua/luci/picoclaw-skills"
PC_SEC_FILE = "/root/.picoclaw/.security.yml"

function trim(s)
    return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", ""))
end

-- 去掉 ANSI 颜色与控制字符
function strip_ansi(s)
    return (tostring(s or ""):gsub("\27%[[%d;]*m", ""))
end

-- 取输出里最后一行有内容的文本（给错误提示用）
function last_line(s)
    local last = ""
    for line in strip_ansi(s):gmatch("[^\n]+") do
        line = trim(line)
        if line ~= "" then last = line end
    end
    return last
end

-- 转义 Lua 模式里的魔法字符
function esc_pat(s)
    return (tostring(s or ""):gsub("([%-%.%+%[%]%(%)%$%^%?%*%%])", "%%%1"))
end

-- cron jobs 和配置都只在进程启动时读取，改完必须重启才生效
function restart_picoclaw()
    sys.exec("/etc/init.d/picoclaw stop >/dev/null 2>&1; killall picoclaw >/dev/null 2>&1; sleep 1; /etc/init.d/picoclaw start >/dev/null 2>&1")
end

local function fmt_ts(ms)
    local n = tonumber(ms)
    if not n or n <= 0 then return "-" end
    return os.date("%m-%d %H:%M", math.floor(n / 1000))
end

function get_cron_jobs_info()
    local jobs = {}
    local data = parse_json_file(PC_CRON_FILE)
    if not data or type(data.jobs) ~= "table" then return jobs end
    for _, j in ipairs(data.jobs) do
        if type(j) == "table" then
            local sched = j.schedule or {}
            local sched_txt = tostring(sched.kind or "?")
            if sched.kind == "every" then
                sched_txt = string.format("every %ds", math.floor((tonumber(sched.everyMs) or 0) / 1000))
            elseif sched.kind == "cron" then
                sched_txt = "cron " .. tostring(sched.expr or "")
            end
            local payload = j.payload or {}
            jobs[#jobs + 1] = {
                id = html_escape(tostring(j.id or "")),
                name = html_escape(tostring(j.name or "")),
                enabled = (j.enabled == true),
                sched = html_escape(sched_txt),
                message = html_escape(tostring(payload.message or "")),
                channel = html_escape(tostring(payload.channel or "")),
                to = html_escape(tostring(payload.to or "")),
                next_run = fmt_ts(j.state and j.state.nextRunAtMs)
            }
        end
    end
    return jobs
end

function get_mcp_servers_info()
    local out = {}
    local cfg = parse_json_file(PC_CONFIG_FILE)
    local servers = cfg and cfg.tools and cfg.tools.mcp and cfg.tools.mcp.servers
    if type(servers) ~= "table" then return out end
    for name, s in pairs(servers) do
        if type(s) == "table" then
            local target = tostring(s.url or "")
            if target == "" then
                target = tostring(s.command or "")
                if type(s.args) == "table" and #s.args > 0 then
                    local args = {}
                    for _, a in ipairs(s.args) do args[#args + 1] = tostring(a) end
                    target = target .. " " .. table.concat(args, " ")
                end
            end
            local nenv, nheader = 0, 0
            if type(s.env) == "table" then for _ in pairs(s.env) do nenv = nenv + 1 end end
            if type(s.headers) == "table" then for _ in pairs(s.headers) do nheader = nheader + 1 end end
            out[#out + 1] = {
                name = html_escape(tostring(name)),
                type = html_escape(tostring(s.type or "stdio")),
                target = html_escape(target),
                enabled = (s.enabled == true),
                env = nenv,
                headers = nheader,
                deferred = (s.deferred == true)
            }
        end
    end
    table.sort(out, function(a, b) return a.name < b.name end)
    return out
end

-- 读 SKILL.md 的 frontmatter，只取需要的三个字段
local function read_skill_meta(dir)
    local name, desc = "", ""
    local f = io.open(dir .. "/SKILL.md", "r")
    if f then
        local content = f:read("*a")
        f:close()
        local head = content:match("^%-%-%-\n(.-)\n%-%-%-") or ""
        name = head:match("\nname:%s*\"(.-)\"") or head:match("^name:%s*\"(.-)\"")
            or head:match("\nname:%s*([^\n]+)") or head:match("^name:%s*([^\n]+)") or ""
        desc = head:match("\ndescription:%s*\"(.-)\"") or head:match("^description:%s*\"(.-)\"")
            or head:match("\ndescription:%s*([^\n]+)") or head:match("^description:%s*([^\n]+)") or ""
        name = trim(name)
        desc = trim(desc)
        if #desc > 160 then desc = desc:sub(1, 160) .. "..." end
    end
    local ver = ""
    local mf = parse_json_file(dir .. "/_meta.json")
    if mf and mf.version then ver = tostring(mf.version) end
    return name, desc, ver
end

-- 删掉 skills store 里目录已经不存在的条目（CLI 的 remove 对已消失的目录会报 not found）
function prune_skills_store()
    local store = PC_SKILLS_DIR .. "/.skills_store_lock.json"
    local data = parse_json_file(store)
    if not data or type(data.skills) ~= "table" then return end
    local changed = false
    for name in pairs(data.skills) do
        if not nixio.fs.access(PC_SKILLS_DIR .. "/" .. name .. "/SKILL.md") then
            data.skills[name] = nil
            changed = true
        end
    end
    if changed then
        local ok, out = pcall(jsonc.stringify, data)
        if ok and out then
            local f = io.open(store, "w")
            if f then f:write(out) f:close() end
        end
    end
end

function get_skills_info()
    local out = {}
    local listed = io.popen("ls " .. PC_SKILLS_DIR .. " 2>/dev/null")
    if listed then
        for entry in listed:lines() do
            entry = trim(entry)
            if entry ~= "" and entry:match("^[%w_%-%.]+$") then
                local name, desc, ver = read_skill_meta(PC_SKILLS_DIR .. "/" .. entry)
                out[#out + 1] = {
                    dir = html_escape(entry),
                    name = html_escape(name ~= "" and name or entry),
                    description = html_escape(desc),
                    version = html_escape(ver),
                    builtin = false
                }
            end
        end
        listed:close()
    end
    -- 包内自带的预设技能（可通过“安装预设”复制到 workspace）
    local presets = io.popen("ls " .. PC_PRESET_DIR .. " 2>/dev/null")
    if presets then
        for entry in presets:lines() do
            entry = trim(entry)
            if entry ~= "" and entry:match("^[%w_%-%.]+$")
               and nixio.fs.access(PC_PRESET_DIR .. "/" .. entry .. "/SKILL.md") then
                local name, desc = read_skill_meta(PC_PRESET_DIR .. "/" .. entry)
                out[#out + 1] = {
                    dir = html_escape(entry),
                    name = html_escape(name ~= "" and name or entry),
                    description = html_escape(desc),
                    version = "",
                    builtin = true
                }
            end
        end
        presets:close()
    end
    table.sort(out, function(a, b)
        if a.builtin ~= b.builtin then return not a.builtin end
        return a.dir < b.dir
    end)
    return out
end

-- 从 .security.yml 里统计每个模型配了几个 api_keys（只数条数，不取值）
-- 注意：文件里条目的写法可能是 "  glm-4.5-air:0:" 这种非标准形式，不能按行尾匹配
function get_security_model_keys()
    local res = {}
    local f = io.open(PC_SEC_FILE, "r")
    if not f then return res end
    local in_models, cur, in_keys = false, nil, false
    for line in f:lines() do
        local top = line:match("^(%S[^:]*):")
        if top then
            in_models = (top == "model_list")
            cur, in_keys = nil, false
        elseif in_models then
            local ind, key = line:match("^( +)([%w_%._%-]+):")
            if ind and #ind == 2 then
                cur, in_keys = key, false
                res[cur] = res[cur] or 0
            elseif line:match("^ +api_keys:%s*$") then
                in_keys = true
            elseif in_keys and cur and line:match("^ +%-") then
                res[cur] = (res[cur] or 0) + 1
            end
        end
    end
    f:close()
    return res
end

function get_models_info()
    local info = { list = {}, default_name = "", provider = "", max_tokens = "" }
    local cfg = parse_json_file(PC_CONFIG_FILE)
    if not cfg then return info end
    local defaults = (cfg.agents and cfg.agents.defaults) or {}
    info.default_name = tostring(defaults.model_name or "")
    info.provider = tostring(defaults.provider or "")
    info.max_tokens = tostring(defaults.max_tokens or "")
    info.default_base = ""
    info.default_thinking = ""
    local keys = get_security_model_keys()
    if type(cfg.model_list) == "table" then
        for _, m in ipairs(cfg.model_list) do
            if type(m) == "table" then
                local mn = tostring(m.model_name or "")
                if mn == info.default_name then
                    info.default_base = html_escape(tostring(m.api_base or ""))
                    info.default_thinking = html_escape(tostring(m.thinking_level or ""))
                end
                info.list[#info.list + 1] = {
                    name = html_escape(mn),
                    model = html_escape(tostring(m.model or "")),
                    base = html_escape(tostring(m.api_base or "")),
                    enabled = (m.enabled == true),
                    has_key = ((keys[mn] or 0) > 0),
                    key_count = (keys[mn] or 0),
                    thinking = tostring(m.thinking_level or ""),
                    is_default = (mn == info.default_name)
                }
            end
        end
    end
    return info
end

-- auth 状态要起一次二进制，缓存 60 秒
function get_auth_summary()
    local cache = "/tmp/picoclaw_auth_cache.txt"
    local st = nixio.fs.stat(cache)
    if st and st.mtime and (os.time() - st.mtime) < 60 then
        local f = io.open(cache, "r")
        if f then
            local t = f:read("*a")
            f:close()
            return t
        end
    end
    local raw = sys.exec("HOME=/root /usr/bin/picoclaw auth status 2>&1")
    local keep = {}
    for line in strip_ansi(raw):gmatch("[^\n]+") do
        local bad = false
        for _, ch in ipairs({ "█", "╔", "╚", "║", "╗", "╝", "🦞" }) do
            if line:find(ch, 1, true) then bad = true break end
        end
        line = trim(line)
        if not bad and line ~= "" then keep[#keep + 1] = line end
    end
    local text = table.concat(keep, "\n")
    local f = io.open(cache, "w")
    if f then f:write(text) f:close() end
    return text
end

-- 只翻转 model_list 里某一项的 enabled，其余字节原样保留
function flip_model_enabled(name, want)
    local f = io.open(PC_CONFIG_FILE, "r")
    if not f then return false, "读取配置失败" end
    local txt = f:read("*a")
    f:close()
    local pos = txt:find('"model_name"%s*:%s*"' .. esc_pat(name) .. '"')
    if not pos then return false, "配置里没有模型 " .. name end
    local nxt = txt:find('"model_name"%s*:%s*"', pos + 1)
    local seg_end = nxt or #txt
    local e1, e2 = txt:find('"enabled"%s*:%s*%a+', pos)
    if not e1 or e1 > seg_end then return false, "该模型没有 enabled 字段" end
    local cur = txt:sub(e1, e2):match(":%s*(%a+)$")
    local target = want and "true" or "false"
    if cur == target then return true, "unchanged" end
    local new_txt = txt:sub(1, e1 - 1) .. '"enabled": ' .. target .. txt:sub(e2 + 1)
    local ok, parsed = pcall(jsonc.parse, new_txt)
    if not ok or type(parsed) ~= "table" then return false, "改写后 JSON 无效，已取消" end
    sys.exec("cp " .. PC_CONFIG_FILE .. " " .. PC_CONFIG_FILE .. ".luci.bak")
    local w = io.open(PC_CONFIG_FILE, "w")
    if not w then return false, "无法写入配置" end
    w:write(new_txt)
    w:close()
    return true, target
end

-- 0.3.1 支持在 model_list 条目上写 thinking_level（推理强度，provider 各自映射）
function set_model_thinking(name, value)
    local allowed = { ["low"] = 1, ["medium"] = 1, ["high"] = 1, ["max"] = 1, ["adaptive"] = 1, [""] = 1 }
    if not allowed[value] then return false, "取值不支持" end
    local f = io.open(PC_CONFIG_FILE, "r")
    if not f then return false, "读取配置失败" end
    local txt = f:read("*a")
    f:close()
    local pos = txt:find('"model_name"%s*:%s*"' .. esc_pat(name) .. '"')
    if not pos then return false, "配置里没有模型 " .. name end
    local nxt = txt:find('"model_name"%s*:%s*"', pos + 1)
    local seg_end = nxt or #txt
    local e1, e2 = txt:find('"thinking_level"%s*:%s*"[^"]*"', pos)
    local new_txt
    if e1 and e1 < seg_end then
        new_txt = txt:sub(1, e1 - 1) .. '"thinking_level": "' .. value .. '"' .. txt:sub(e2 + 1)
    elseif value == "" then
        return true, "unchanged"
    else
        local en1 = txt:find('"enabled"%s*:%s*%a+', pos)
        if not en1 or en1 > seg_end then return false, "条目结构异常，请手动编辑" end
        local before = txt:sub(1, en1 - 1)
        local indent = before:match("([ \t]*)$") or "    "
        new_txt = before .. '"thinking_level": "' .. value .. '",\n' .. indent .. txt:sub(en1)
    end
    local ok, parsed = pcall(jsonc.parse, new_txt)
    if not ok or type(parsed) ~= "table" then return false, "改写后 JSON 无效，已取消" end
    sys.exec("cp " .. PC_CONFIG_FILE .. " " .. PC_CONFIG_FILE .. ".luci.bak")
    local w = io.open(PC_CONFIG_FILE, "w")
    if not w then return false, "无法写入配置" end
    w:write(new_txt)
    w:close()
    return true, value
end

function action_main()
    local status = get_status()
    local config_content, config_err = get_config()
    local logs = get_logs()

    -- Check if PicoClaw binary is installed
    local picoclaw_installed = is_picoclaw_installed()
    local picoclaw_arch, picoclaw_raw_arch = get_picoclaw_arch()
    local picoclaw_arch_supported = (picoclaw_arch ~= nil)

    local cur_ver, build_time, git_commit = get_version_info()
    local latest_ver, latest_url, check_err = check_latest_version()

    local has_update = false
    if latest_ver ~= "" and cur_ver ~= "N/A" then
        local function ver_parts(v)
            local t = {}
            for n in v:gmatch("%d+") do
                t[#t + 1] = tonumber(n)
            end
            return t
        end
        local cv = ver_parts(cur_ver)
        local lv = ver_parts(latest_ver)
        for i = 1, math.max(#cv, #lv) do
            local a = cv[i] or 0
            local b = lv[i] or 0
            if b > a then
                has_update = true
                break
            end
            if a > b then
                break
            end
        end
    end

    local memory_mb = "0.0"
    if status.memory_kb and tonumber(status.memory_kb) then
        memory_mb = string.format("%.1f", tonumber(status.memory_kb) / 1024)
    end
    local pid_str = "-"
    if status.pid and status.pid ~= "" then
        pid_str = tostring(status.pid)
    end

    -- Parse weixin status using proper JSON parser
    -- v0.2.7+: channel_list.weixin.enabled + channel_list.weixin.settings.{base_url,...}
    -- Older:    channels.weixin.enabled + channels.weixin.{base_url,...}
    -- States: "none" = not authorized, "configured" = authorized but disabled, "connected" = enabled
    -- Note: v0.2.7 creates default entries for ALL channels with enabled=false,
    -- so mere existence of channel_list.weixin does NOT mean the user ran auth.
    -- We check security.yml for weixin auth token to detect "configured" state.
    local weixin_status = "none"
    local weixin_configured = false
    local config = parse_json_file("/root/.picoclaw/config.json")
    if config then
        -- v0.2.7+: config.channel_list.weixin; older: config.channels.weixin
        local channels = config.channel_list or config.channels or {}
        local weixin = nil
        if type(channels) == "table" then
            weixin = channels.weixin
        end
        -- Also check top-level for backward compatibility
        if not weixin or type(weixin) ~= "table" then
            weixin = config.weixin
        end
        if weixin and type(weixin) == "table" then
            if weixin.enabled == true then
                weixin_status = "connected"
                weixin_configured = true
            else
                -- Check if weixin has been authenticated by looking for auth data in security.yml
                -- After `picoclaw auth weixin`, security.yml will have weixin.settings with token
                local sec_file = io.open("/root/.picoclaw/.security.yml", "r")
                if sec_file then
                    local sec_content = sec_file:read("*a")
                    sec_file:close()
                    -- Look for weixin section in channel_list with non-empty settings
                    -- Pattern: "weixin:\n    settings:\n      <key>: <value>" (not just "settings: {}")
                    if sec_content:match("weixin:%s*\n%s+settings:%s*\n%s+%S")
                       or sec_content:match("weixin:%s*\n%s+settings:%s*[^{}%s]")
                    then
                        weixin_status = "configured"
                        weixin_configured = true
                    end
                end
            end
        end
    end

    local flash_msg = http.formvalue("msg") or ""
    local flash_ok = http.formvalue("ok") or "1"

    local autostart = false
    local asf = io.open("/etc/rc.d/S99picoclaw", "r")
    if asf then asf:close() autostart = true end

    -- Hardware data
    local hw_sysinfo = get_sysinfo()
    local hw_gpio = get_gpio_info()
    local hw_leds = get_leds()
    local hw_usb = get_usb_devices()
    local hw_tools = get_picoclaw_tools()

    -- Chat history
    local chat_history = read_chat_history()
    -- Escape for JS
    local chat_history_json = "{}"
    if #chat_history > 0 then
        local ok, encoded = pcall(jsonc.stringify, chat_history)
        if ok and encoded then
            chat_history_json = js_escape(encoded)
        end
    end

    -- v0.3.1 新增页面数据
    local cron_jobs = get_cron_jobs_info()
    local mcp_servers = get_mcp_servers_info()
    local skills_list = get_skills_info()
    local skills_installed, skills_preset = 0, 0
    for _, sk in ipairs(skills_list) do
        if sk.builtin then skills_preset = skills_preset + 1 else skills_installed = skills_installed + 1 end
    end
    local models_info = get_models_info()
    local auth_summary = get_auth_summary()

    luci.template.render("picoclaw/main", {
        running = status.running,
        pid = pid_str,
        memory_mb = memory_mb,
        port_active = status.port_active or false,
        gateway_port = html_escape(tostring(status.gateway_port or "")),
        cur_ver = html_escape(cur_ver),
        latest_ver = html_escape(latest_ver),
        build_time = html_escape(build_time),
        git_commit = html_escape(git_commit),
        latest_url = html_escape(latest_url),
        has_update = has_update,
        check_err = check_err,
        config_content = html_escape(config_content or ""),
        config_json_safe = js_escape(config_content or "{}"),
        weixin_status = weixin_status,
        weixin_configured = weixin_configured,
        channels_html = "",
        logs = html_escape(logs),
        flash_msg = html_escape(flash_msg),
        flash_ok = flash_ok,
        action_url = dispatcher.build_url("admin", "services", "picoclaw", "action"),
        csrf_token = dispatcher.context.authtoken,
        autostart = autostart,
        hw_sysinfo = hw_sysinfo,
        hw_gpio = hw_gpio,
        hw_leds = hw_leds,
        hw_usb = hw_usb,
        hw_tools = hw_tools,
        chat_history_json = chat_history_json,
        chat_send_url = dispatcher.build_url("admin", "services", "picoclaw", "chat_send"),
        chat_poll_url = dispatcher.build_url("admin", "services", "picoclaw", "chat_poll"),
        picoclaw_installed = picoclaw_installed,
        picoclaw_arch = html_escape(picoclaw_arch or ""),
        picoclaw_raw_arch = html_escape(picoclaw_raw_arch or ""),
        picoclaw_arch_supported = picoclaw_arch_supported,
        cron_jobs = cron_jobs,
        mcp_servers = mcp_servers,
        skills_list = skills_list,
        skills_installed = skills_installed,
        skills_preset = skills_preset,
        models_info = models_info,
        default_model_name = js_escape(models_info.default_name or ""),
        default_model_base = models_info.default_base or "",
        default_model_thinking = models_info.default_thinking or "",
        max_tokens_now = html_escape(models_info.max_tokens ~= "" and models_info.max_tokens or "-"),
        auth_summary = html_escape(auth_summary)
    })
end
