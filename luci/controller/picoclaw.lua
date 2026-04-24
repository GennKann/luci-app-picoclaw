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
    if version == "" then version = "0.2.4" end
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
    local output = sys.exec("picoclaw version 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g'")
    if output and output ~= "" then
        -- Match: "picoclaw 0.2.4 (git: 5f50ae5)"
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
    sys.exec("pkill -f 'picoclaw gateway' 2>/dev/null")
    sys.exec("sleep 1")
    sys.exec("cp /usr/bin/picoclaw /usr/bin/picoclaw.bak 2>/dev/null")
    sys.exec("cp /tmp/picoclaw-update/picoclaw /usr/bin/picoclaw")
    sys.exec("chmod +x /usr/bin/picoclaw")
    sys.exec("rm -rf /tmp/picoclaw-update")
    sys.exec("logger -t picoclaw 'Upload install complete, restarting...'")
    os.execute("picoclaw gateway >/dev/null 2>&1 &")
    return true, "ok"
end

-- Update PicoClaw binary via GitHub Release (auto-detects architecture)
function do_update()
    local dl_url, err = find_release_asset_url()
    if not dl_url then
        sys.exec("logger -t picoclaw 'Update failed: cannot find release asset (" .. (err or "unknown") .. ")'")
        return
    end
    sys.exec("pkill -f 'picoclaw gateway' 2>/dev/null")
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
    os.execute("picoclaw gateway >/dev/null 2>&1 &")
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
    local cron_out = sys.exec("picoclaw cron list 2>/dev/null | sed 's/\\x1b\\[[0-9;]*m//g' | grep -v 'PicoClaw\\|^$\\|████'")
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
                local f = io.open("/root/.picoclaw/config.json", "w")
                if f then
                    f:write(config)
                    f:close()
                    -- Sync workspace memory files so PicoClaw's AI context reflects the new model
                    sync_workspace_memory(cfg_obj)
                    sys.exec("/etc/init.d/picoclaw stop; killall picoclaw 2>/dev/null; sleep 1; /etc/init.d/picoclaw start")
                    msg = "配置已保存，服务已重启！"
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
            if skill_name:match("^[%w_%-]+$") then
                local skill_path = "/root/.picoclaw/workspace/skills/" .. skill_name
                rmtree(skill_path)
                -- Verify deleted
                local check = io.open(skill_path .. "/SKILL.md", "r")
                if check then check:close() msg = "错误：删除失败"; ok = false
                else msg = "技能已删除: " .. skill_name end
            else
                msg = "错误：技能名称无效"; ok = false
            end
        else
            msg = "错误：未指定技能"; ok = false
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
    end

    local url = dispatcher.build_url("admin", "services", "picoclaw")
    if msg ~= "" then
        url = url .. "?msg=" .. http.urlencode(msg) .. "&ok=" .. (ok and "1" or "0")
    end
    http.redirect(url)
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
    -- Check multiple indicators: enabled flag, base_url, session files
    local weixin_status = "none"
    local weixin_configured = false
    local config = parse_json_file("/root/.picoclaw/config.json")
    if config then
        -- WeChat config is under config.channels.weixin (not config.weixin)
        local channels = config.channels
        local weixin = nil
        if type(channels) == "table" then
            weixin = channels.weixin
        end
        -- Also check top-level for backward compatibility
        if not weixin or type(weixin) ~= "table" then
            weixin = config.weixin
        end
        if weixin and type(weixin) == "table" then
            -- WeChat status: only enabled=true means fully connected
            -- base_url/cdn_base_url are default values set by PicoClaw on init,
            -- they do NOT indicate QR authorization was completed
            if weixin.enabled == true then
                weixin_status = "connected"
                weixin_configured = true
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
        picoclaw_arch_supported = picoclaw_arch_supported
    })
end
