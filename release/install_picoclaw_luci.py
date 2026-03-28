#!/usr/bin/env python3
"""
PicoClaw + LuCI One-Click Installer for OpenWrt
Supports OpenWrt 24.10 / 25.xx (ARM64 / AMD64 / ARMv7)

Usage:
    pip install paramiko
    python install.py
"""

import paramiko
import sys
import os
import time
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

# =============================================
# LuCI Controller (Lua)
# =============================================
CONTROLLER_LUA = r'''module("luci.controller.picoclaw", package.seeall)

function index()
    entry({"admin", "services", "picoclaw"}, call("action_main"), "PicoClaw", 60)
    entry({"admin", "services", "picoclaw", "action"}, call("action_do"), nil)
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
        if p and p ~= "" then pid = p running = true end
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
    local f = io.open("/root/.picoclaw/config.json", "r")
    if f then
        local c = f:read("*a")
        f:close()
        local v = c:match('"version"%s*:%s*"([^"]+)"')
        if v then cur_ver = v end
        local bt = c:match('"build_time"%s*:%s*"([^"]+)"')
        if bt then build_time = bt end
        local gc = c:match('"git_commit"%s*:%s*"([^"]+)"')
        if gc then git_commit = gc end
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
        local ts = 0
        local tf = io.open(cache_file .. ".ts", "r")
        if tf then ts = tonumber(tf:read("*l")) or 0 tf:close() end
        if v and ts and (os.time() - ts < 3600) then return v, "", "" end
    end
    local f = io.popen("curl -sL --max-time 5 'https://api.github.com/repos/sipeed/picoclaw/releases/latest' 2>/dev/null")
    if f then
        local body = f:read("*a")
        f:close()
        local v = body:match('"tag_name"%s*:%s*"v?([^"]+)"')
        if v then latest_ver = v end
    else
        err_msg = "curl failed"
    end
    if latest_ver ~= "" then
        local cf2 = io.open(cache_file, "w")
        if cf2 then cf2:write(latest_ver) cf2:close() end
        local tf = io.open(cache_file .. ".ts", "w")
        if tf then tf:write(tostring(os.time())) tf:close() end
    end
    if latest_ver == "" then err_msg = "checking" end
    return latest_ver, latest_url, err_msg
end

function get_logs()
    local f = io.popen("logread 2>/dev/null | grep -i picoclaw | tail -50")
    if not f then return "" end
    local l = f:read("*a") or ""
    f:close()
    if l == "" then
        local f2 = io.popen("logread 2>/dev/null | tail -30")
        if f2 then l = f2:read("*a") or "" f2:close() end
    end
    return l
end

function html_escape(s)
    if not s then return "" end
    s = tostring(s)
    s = s:gsub("&", "&amp;") s = s:gsub("<", "&lt;") s = s:gsub(">", "&gt;") s = s:gsub('"', "&quot;")
    return s
end

function do_update()
    local arch = "linux_arm64"
    local f = io.popen("uname -m 2>/dev/null")
    if f then
        local m = f:read("*l") or ""
        f:close()
        if m:find("x86") then arch = "linux_amd64" end
    end
    local dl_url = "https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_" .. arch
    os.execute("pkill -f 'picoclaw gateway' 2>/dev/null")
    os.execute("sleep 1")
    os.execute("curl -L -o /tmp/picoclaw_new '" .. dl_url .. "' --max-time 120 2>&1")
    os.execute("chmod +x /tmp/picoclaw_new")
    os.execute("cp /usr/bin/picoclaw /usr/bin/picoclaw.bak 2>/dev/null")
    os.execute("mv /tmp/picoclaw_new /usr/bin/picoclaw")
    os.execute("picoclaw gateway >/dev/null 2>&1 &")
    os.execute("sleep 3")
end

function action_do()
    local http = require("luci.http")
    local action = http.formvalue("action") or ""
    local msg = ""
    local ok = true
    if action == "start" then
        os.execute("picoclaw gateway >/dev/null 2>&1 &") os.execute("sleep 2") msg = "Service starting..."
    elseif action == "stop" then
        os.execute("pkill -f 'picoclaw gateway' 2>/dev/null") os.execute("sleep 1") msg = "Service stopped."
    elseif action == "restart" then
        os.execute("pkill -f 'picoclaw gateway' 2>/dev/null") os.execute("sleep 1")
        os.execute("picoclaw gateway >/dev/null 2>&1 &") os.execute("sleep 2") msg = "Service restarted."
    elseif action == "autostart_on" then
        os.execute("/etc/init.d/picoclaw enable 2>/dev/null; ln -sf /etc/init.d/picoclaw /etc/rc.d/S99picoclaw 2>/dev/null")
        msg = "Auto-start enabled."
    elseif action == "autostart_off" then
        os.execute("/etc/init.d/picoclaw disable 2>/dev/null; rm -f /etc/rc.d/S99picoclaw 2>/dev/null")
        msg = "Auto-start disabled."
    elseif action == "save_config" or action == "save_form_config" then
        local config = http.formvalue("config") or ""
        if config ~= "" then
            local f = io.open("/root/.picoclaw/config.json", "w")
            if f then f:write(config) f:close()
                os.execute("pkill -f 'picoclaw gateway' 2>/dev/null; sleep 1; picoclaw gateway >/dev/null 2>&1 &")
                msg = "Config saved, service restarted!"
            else msg = "Error: cannot write config" ok = false end
        else msg = "Error: empty config" ok = false end
    elseif action == "update" then
        do_update() msg = "Update complete, service restarted!"
    end
    local dispatcher = require("luci.dispatcher")
    local url = dispatcher.build_url("admin", "services", "picoclaw")
    if msg ~= "" then url = url .. "?msg=" .. luci.http.urlencode(msg) .. "&ok=" .. (ok and "1" or "0") end
    luci.http.redirect(url)
end

function action_main()
    local http = require("luci.http")
    local status = get_status()
    local config_content, config_err = get_config()
    local logs = get_logs()
    local cur_ver, build_time, git_commit = get_version_info()
    local latest_ver, latest_url, check_err = check_latest_version()
    local has_update = false
    if latest_ver ~= "" and cur_ver ~= "N/A" then
        local function ver_parts(v) local t = {} for n in v:gmatch("%d+") do t[#t + 1] = tonumber(n) end return t end
        local cv = ver_parts(cur_ver) local lv = ver_parts(latest_ver)
        for i = 1, math.max(#cv, #lv) do
            local a = cv[i] or 0 local b = lv[i] or 0
            if b > a then has_update = true break end if a > b then break end
        end
    end
    local memory_mb = "0.0"
    if status.memory_kb and tonumber(status.memory_kb) then memory_mb = string.format("%.1f", tonumber(status.memory_kb) / 1024) end
    local pid_str = "-"
    if status.pid and status.pid ~= "" then pid_str = tostring(status.pid) end
    local weixin_status = "none"
    if config_content then
        local ws = config_content:find('"weixin"')
        if ws then
            local wblock = config_content:sub(ws, ws + 2000)
            local wep = wblock:find('"enabled"')
            if wep then
                local wrest = wblock:sub(wep + 9) wrest = wrest:match("^[%s]*:[%s]*(.*)")
                if wrest and wrest:sub(1, 4) == "true" then weixin_status = "connected" end
            end
            local burl = wblock:match('"base_url"%s*:%s*"([^"]+)"')
            if burl and burl ~= "" and weixin_status == "none" then weixin_status = "configured" end
        end
    end
    local flash_msg = http.formvalue("msg") or ""
    local flash_ok = http.formvalue("ok") or "1"
    local autostart = false
    local asf = io.open("/etc/rc.d/S99picoclaw", "r")
    if asf then asf:close() autostart = true end
    luci.template.render("picoclaw/main", {
        running = status.running, pid = pid_str, memory_mb = memory_mb,
        port_active = status.port_active or false,
        cur_ver = html_escape(cur_ver), latest_ver = html_escape(latest_ver),
        build_time = html_escape(build_time), git_commit = html_escape(git_commit),
        latest_url = html_escape(latest_url), has_update = has_update, check_err = check_err,
        config_content = html_escape(config_content or ""), config_raw = (config_content or ""),
        weixin_status = weixin_status, channels_html = "",
        logs = html_escape(logs), flash_msg = html_escape(flash_msg), flash_ok = flash_ok,
        action_url = luci.dispatcher.build_url("admin", "services", "picoclaw", "action"),
        autostart = autostart
    })
end
'''

# NOTE: TEMPLATE_HTM is loaded from the main.htm file in the repo
# to keep install.py manageable in size.
# The full template is at: luci/view/picoclaw/main.htm


def print_step(msg):
    print(f"\n{'='*55}")
    print(f"  {msg}")
    print(f"{'='*55}")


def run_cmd(client, cmd, timeout=120):
    stdin, stdout, stderr = client.exec_command(cmd, timeout=timeout)
    try:
        out = stdout.read().decode('utf-8', errors='replace').strip()
    except:
        out = "(timeout)"
    try:
        err = stderr.read().decode('utf-8', errors='replace').strip()
    except:
        err = ""
    if out:
        print(f"  {out}")
    if err and 'warning' not in err.lower():
        print(f"  [ERR] {err}")
    return out, err


def main():
    print("""
╔══════════════════════════════════════════════════════════╗
║         PicoClaw + LuCI One-Click Installer             ║
║         OpenWrt 24.10 / 25.xx (ARM64/AMD64/ARMv7)      ║
║         https://github.com/sipeed/picoclaw               ║
╚══════════════════════════════════════════════════════════╝
    """)

    host = input("Router IP [default: 192.168.1.1]: ").strip() or "192.168.1.1"
    port = int(input("SSH Port [default: 22]: ").strip() or "22")
    user = input("SSH User [default: root]: ").strip() or "root"
    pwd = input("SSH Password: ").strip()
    if not pwd:
        print("Error: password required")
        sys.exit(1)

    print(f"\nConnecting to {user}@{host}:{port} ...")
    client = paramiko.SSHClient()
    client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
    try:
        client.connect(host, port=port, username=user, password=pwd, timeout=15)
    except Exception as e:
        print(f"Connection failed: {e}")
        sys.exit(1)
    print("Connected!")

    def run(cmd, timeout=120):
        return run_cmd(client, cmd, timeout)

    # Step 1: Detect system
    print_step("Step 1/6: Detect System")
    arch_out, _ = run("uname -m")
    arch = "linux_arm64"
    if "x86" in arch_out:
        arch = "linux_amd64"
    elif "armv7" in arch_out:
        arch = "linux_armv7"
    print(f"  Architecture: {arch_out} -> {arch}")

    release_out, _ = run("cat /etc/openwrt_release 2>/dev/null | grep DISTRIB_DESCRIPTION")
    print(f"  System: {release_out}")

    has_luci, _ = run("test -d /usr/lib/lua/luci && echo 'yes' || echo 'no'")

    # Step 2: Install PicoClaw
    print_step("Step 2/6: Install PicoClaw")
    existing_ver, _ = run("picoclaw version 2>&1 || echo 'not installed'")
    if 'not installed' not in existing_ver and existing_ver:
        print(f"  Already installed: {existing_ver}")
        reinstall = input("  Reinstall? (y/N): ").strip().lower()
        if reinstall != 'y':
            print("  Skipped")
        else:
            run(f"curl -L -o /tmp/picoclaw_new 'https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_{arch}' --max-time 120")
            run("chmod +x /tmp/picoclaw_new; cp /usr/bin/picoclaw /usr/bin/picoclaw.bak 2>/dev/null; mv /tmp/picoclaw_new /usr/bin/picoclaw")
            run("picoclaw version 2>&1")
    else:
        print("  Downloading PicoClaw...")
        run(f"curl -L -o /tmp/picoclaw 'https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_{arch}' --max-time 120")
        run("chmod +x /tmp/picoclaw; mkdir -p /usr/bin; cp /tmp/picoclaw /usr/bin/picoclaw; rm -f /tmp/picoclaw")
        run("picoclaw version 2>&1")

    # Step 3: init.d service
    print_step("Step 3/6: Create init.d Service")
    sftp = client.open_sftp()
    initd_script = open(os.path.join(os.path.dirname(__file__), 'scripts', 'picoclaw.init'), 'r').read()
    with sftp.open('/etc/init.d/picoclaw', 'w') as f:
        f.write(initd_script)
    print("  Written /etc/init.d/picoclaw")
    run("chmod +x /etc/init.d/picoclaw; /etc/init.d/picoclaw enable 2>&1")
    print("  Auto-start enabled")

    # Step 4: Deploy LuCI
    if has_luci.strip() == 'yes':
        print_step("Step 4/6: Deploy LuCI Interface")
        controller_path = os.path.join(os.path.dirname(__file__), 'luci', 'controller', 'picoclaw.lua')
        template_path = os.path.join(os.path.dirname(__file__), 'luci', 'view', 'picoclaw', 'main.htm')

        with sftp.open('/usr/lib/lua/luci/controller/picoclaw.lua', 'w') as f:
            f.write(open(controller_path, 'r').read())
        print("  Controller deployed")

        run("mkdir -p /usr/lib/lua/luci/view/picoclaw")
        with sftp.open('/usr/lib/lua/luci/view/picoclaw/main.htm', 'w') as f:
            f.write(open(template_path, 'r').read())
        print("  Template deployed")

        run("rm -rf /tmp/luci-* 2>/dev/null")
        print("  LuCI cache cleared")
        luci_url = f"http://{host}/cgi-bin/luci/admin/services/picoclaw"
    else:
        print_step("Step 4/6: Skipped (LuCI not detected)")
        luci_url = ""

    sftp.close()

    # Step 5: Init config
    print_step("Step 5/6: Initialize Config")
    run("mkdir -p /root/.picoclaw")
    has_config, _ = run("test -f /root/.picoclaw/config.json && echo 'yes' || echo 'no'")
    if has_config.strip() != 'yes':
        print("  Running picoclaw gateway to generate default config...")
        run("picoclaw gateway >/dev/null 2>&1 &")
        time.sleep(3)
        run("pkill -f 'picoclaw gateway' 2>/dev/null")
        time.sleep(1)
        print("  Default config generated")
    else:
        print("  Config exists, skipped")

    # Step 6: Start service
    print_step("Step 6/6: Start PicoClaw")
    run("pkill -f 'picoclaw gateway' 2>/dev/null")
    time.sleep(1)
    run("/etc/init.d/picoclaw start 2>&1")
    time.sleep(3)

    ps_out, _ = run("ps | grep 'picoclaw gateway' | grep -v grep")
    print(f"\n{'='*55}")
    print(f"  Installation Complete!")
    print(f"{'='*55}")
    if ps_out:
        print(f"  [OK] PicoClaw is running")
    else:
        print(f"  [!] PicoClaw not detected, check: picoclaw gateway")
    if luci_url:
        print(f"\n  LuCI Manager: {luci_url}")
    print(f"  API: http://{host}:18790")
    print(f"  Config: /root/.picoclaw/config.json")

    client.close()
    print("\nDone!")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\nCancelled")
        sys.exit(0)
    except Exception as e:
        print(f"\nError: {e}")
        sys.exit(1)
