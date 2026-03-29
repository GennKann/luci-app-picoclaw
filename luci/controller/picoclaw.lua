module("luci.controller.picoclaw", package.seeall)

local jsonc = require("luci.jsonc")
local sys = require("luci.sys")
local http = require("luci.http")
local dispatcher = require("luci.dispatcher")

function index()
    entry({"admin", "services", "picoclaw"}, call("action_main"), _("PicoClaw"), 60)
    entry({"admin", "services", "picoclaw", "action"}, call("action_do"), nil)
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
    local nf = io.open("/proc/net/tcp6", "r")
    if not nf then nf = io.open("/proc/net/tcp", "r") end
    if nf then
        local c = nf:read("*a")
        nf:close()
        -- 4966 is hex for port 18790
        if c:find(":4966") then port_active = true end
    end
    return {running=running, pid=pid, memory_kb=memory_kb, port_active=port_active}
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
    local cf = io.open(cache_file, "r")
    if cf then
        local cached = cf:read("*a")
        cf:close()
        local v = cached:match("^([%d.]+)")
        local u = cached:match("\n(.+)$")
        local ts = 0
        local tf = io.open(cache_file .. ".ts", "r")
        if tf then
            ts = tonumber(tf:read("*l")) or 0
            tf:close()
        end
        if v and ts and (os.time() - ts < 3600) then
            return v, u or "", ""
        end
    end
    local f = io.popen("curl -sL --max-time 5 'https://api.github.com/repos/sipeed/picoclaw/releases/latest' 2>/dev/null")
    if f then
        local body = f:read("*a")
        f:close()
        local ok, data = pcall(jsonc.parse, body)
        if ok and data then
            if data.tag_name then
                latest_ver = data.tag_name:gsub("^v", "")
            end
            if data.assets then
                for _, asset in ipairs(data.assets) do
                    if asset.browser_download_url and asset.browser_download_url:find("linux_arm64") then
                        latest_url = asset.browser_download_url
                        break
                    end
                end
            end
        end
    else
        err_msg = "curl failed"
    end
    if latest_ver ~= "" then
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
    if latest_ver == "" then err_msg = "checking" end
    return latest_ver, latest_url, err_msg
end

function get_logs()
    local l = sys.exec("logread 2>/dev/null | grep -i picoclaw | tail -50")
    if l == "" then
        l = sys.exec("logread 2>/dev/null | tail -30")
    end
    return l
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

function do_update()
    local arch = "linux_arm64"
    local m = sys.exec("uname -m")
    if m:find("x86") then arch = "linux_amd64" end
    local dl_url = "https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_" .. arch
    sys.exec("pkill -f 'picoclaw gateway' 2>/dev/null")
    sys.exec("sleep 1")
    sys.exec("curl -L -o /tmp/picoclaw_new '" .. dl_url .. "' --max-time 120 2>&1")
    sys.exec("chmod +x /tmp/picoclaw_new")
    sys.exec("cp /usr/bin/picoclaw /usr/bin/picoclaw.bak 2>/dev/null")
    sys.exec("mv /tmp/picoclaw_new /usr/bin/picoclaw")
    sys.exec("picoclaw gateway >/dev/null 2>&1 &")
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

function action_do()
    if not check_csrf() then return end

    local action = http.formvalue("action") or ""
    local msg = ""
    local ok = true

    if action == "start" then
        sys.exec("picoclaw gateway >/dev/null 2>&1 &")
        sys.exec("sleep 2")
        msg = "服务正在启动..."
    elseif action == "stop" then
        sys.exec("pkill -f 'picoclaw gateway' 2>/dev/null")
        sys.exec("sleep 1")
        msg = "服务已停止。"
    elseif action == "restart" then
        sys.exec("pkill -f 'picoclaw gateway' 2>/dev/null")
        sys.exec("sleep 1")
        sys.exec("picoclaw gateway >/dev/null 2>&1 &")
        sys.exec("sleep 2")
        msg = "服务已重启。"
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
            local valid, _ = pcall(jsonc.parse, config)
            if not valid then
                msg = "错误：JSON 格式无效"
                ok = false
            else
                local f = io.open("/root/.picoclaw/config.json", "w")
                if f then
                    f:write(config)
                    f:close()
                    sys.exec("pkill -f 'picoclaw gateway' 2>/dev/null; sleep 1; picoclaw gateway >/dev/null 2>&1 &")
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
    local weixin_status = "none"
    local weixin_configured = false
    local config = parse_json_file("/root/.picoclaw/config.json")
    if config then
        local weixin = config.weixin
        if weixin and type(weixin) == "table" then
            if weixin.enabled == true then
                weixin_status = "connected"
            end
            if weixin.base_url and weixin.base_url ~= "" then
                weixin_configured = true
                if weixin_status == "none" then
                    weixin_status = "configured"
                end
            end
        end
    end

    local flash_msg = http.formvalue("msg") or ""
    local flash_ok = http.formvalue("ok") or "1"

    local autostart = false
    local asf = io.open("/etc/rc.d/S99picoclaw", "r")
    if asf then asf:close() autostart = true end

    luci.template.render("picoclaw/main", {
        running = status.running,
        pid = pid_str,
        memory_mb = memory_mb,
        port_active = status.port_active or false,
        cur_ver = html_escape(cur_ver),
        latest_ver = html_escape(latest_ver),
        build_time = html_escape(build_time),
        git_commit = html_escape(git_commit),
        latest_url = html_escape(latest_url),
        has_update = has_update,
        check_err = check_err,
        config_content = html_escape(config_content or ""),
        config_raw = (config_content or ""),
        weixin_status = weixin_status,
        weixin_configured = weixin_configured,
        channels_html = "",
        logs = html_escape(logs),
        flash_msg = html_escape(flash_msg),
        flash_ok = flash_ok,
        action_url = dispatcher.build_url("admin", "services", "picoclaw", "action"),
        csrf_token = dispatcher.context.authtoken,
        autostart = autostart
    })
end
