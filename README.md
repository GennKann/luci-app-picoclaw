<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI web interface for managing <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> on OpenWrt</b><br>
  <sub>Full control of your AI gateway — from service management to hardware</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
  <img src="https://img.shields.io/badge/i18n-5%20Languages-purple" alt="i18n">
  <img src="https://img.shields.io/badge/Version-1.0.9-brightgreen" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="README.zh.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt.md">Português</a>
</p>

---

## 📸 Screenshots

| Dashboard | Config Editor |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| Hardware Control | Mobile View |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Features

### Service Management
- **Dashboard** — Real-time service status, PID, memory usage, and port monitoring
- **Service Control** — Start / Stop / Restart PicoClaw (with robust kill-9 stop strategy)
- **Auto-Start Toggle** — Enable or disable boot-on-start
- **System Logs** — View and refresh PicoClaw logs in real-time
- **Online Update** — Check for new versions and update from the UI

### Configuration
- **Channel Management** — View connected channels (Feishu, Telegram, Discord, WeChat, etc.)
- **WeChat Status Detection** — Automatically detects WeChat personal account session after QR scan
- **Form-based Config Editor** — UI for AI model, providers, and system settings
- **JSON Config Editor** — Direct JSON editing with validation

### Hardware & Extensions
- **Hardware Control** — System info, USB devices, GPIO pins (with toggle controls)
- **Skill Management** — View, delete, and import PicoClaw skills from the UI
- **Cron Jobs** — View scheduled tasks at a glance

### Built-in Preset Skills
Three ready-to-use AI skills are bundled — install with one click from the management page:

| Skill | Description |
|:---|:---|
| **System Diagnostics** | Automated network/DNS/gateway checks, log analysis, and troubleshooting |
| **Config Backup** | Interactive backup with environment check, options menu, and restore |
| **App Installer** | Smart app search via opkg/is-opkg, with fuzzy description matching |

> These skills are pure knowledge prompts (SKILL.md) — they enhance PicoClaw's AI responses without modifying the PicoClaw binary.

## 📋 Requirements

| Requirement | Details |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ / 22.03 / 23.05 / 24.10 / 25.xx / iStoreOS (with LuCI) |
| **PicoClaw** | **Must be installed first!** This interface does not include the PicoClaw binary |
| **Architecture** | all (pure Lua, works on x86-64 / aarch64 / armv7 / mipsle / riscv64, etc.) |

> ⚠️ **Important**: `luci-app-picoclaw` is only the **web management interface** for PicoClaw — it is NOT PicoClaw itself. If you haven't installed the PicoClaw binary yet, please complete "Step 1" below first.

## 🚀 Installation

### Step 1: Install PicoClaw (Required!)

Download from [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) matching your architecture (x86-64, aarch64, armv7, mipsle, riscv64).

```bash
# Example for x86-64 (replace version as needed)
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw

# Verify installation
picoclaw --version
```

### Step 2: Install LuCI Interface (luci-app-picoclaw)

#### Option 1: iStore App Store (Recommended)

Search `picoclaw` in the **iStore** app on your router → install directly.
> Available since v1.0.9 (PR merged into iStore official source)

#### Option 2: Download IPK

Download from [Releases](https://github.com/GennKann/luci-app-picoclaw/releases/latest):

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.0.9-1_all.ipk
opkg install luci-app-picoclaw_1.0.9-1_all.ipk
rm -rf /tmp/luci-*   # Clear LuCI cache
```

#### Option 3: Manual File Copy

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua
# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm
# Init script
cp scripts/picoclaw.init /etc/init.d/picoclaw && chmod +x /etc/init.d/picoclaw
# Clear cache
rm -rf /tmp/luci-*
```

After installation, restart the service once via the LuCI page to ensure the new init.d script takes effect:
> LuCI → Services → PicoClaw → Click **Restart**

Access: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## ❓ FAQ

### Installed luci-app-picoclaw but the page doesn't load?
This means **PicoClaw binary** is not installed. Complete Step 1 above, then refresh the page.

### Stop button doesn't actually stop the gateway?
This was a known issue in versions <= 1.0.7 where procd would auto-respawn the process. **Fixed in v1.0.8** — the stop function now uses a three-step strategy (graceful stop → pidof check + kill-9 force kill → cleanup wait). Upgrade to v1.0.8 if you're on an older version.

### "Invalid CSRF token" error when refreshing logs?
This was a known issue in versions <= 1.0.7. **Fixed in v1.0.8** — all form submissions now properly carry CSRF tokens.

### Can't find picoclaw in iStore?
Run `opkg update` in your router's terminal to refresh package sources, or download the IPK directly from GitHub Releases.

### What is the orange install banner at the top?
It means `luci-app-picoclaw` is installed but PicoClaw binary is not yet installed. Click it to install PicoClaw with one click (auto-detects architecture).

## 📁 Project Structure

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCI controller (backend logic)
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCI template (HTML/CSS/JS)
├── skills/
│   ├── openwrt-diagnostics/
│   ├── openwrt-backup/
│   └── openwrt-app-installer/
├── scripts/
│   └── picoclaw.init              # OpenWrt init.d service script
├── install.py                     # Interactive installation helper
├── Screenshots/
└── README*.md                     # Multi-language documentation
```

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Backend | Lua (LuCI) with `luci.jsonc` |
| Frontend | HTML + CSS + JavaScript (server-side rendered) |
| Service Manager | OpenWrt procd (init.d) with kill-9 safety fallback |
| Security | CSRF token protection on all forms |

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for full release history.

## 📄 License

[MIT License](LICENSE)

## 🙏 Credits

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) and [LuCI](https://github.com/openwrt/luci)
