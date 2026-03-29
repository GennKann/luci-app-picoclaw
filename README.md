<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI web interface for managing <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> on OpenWrt</b><br>
  <sub>Full control of your AI gateway — from service management to hardware</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
  <img src="https://img.shields.io/badge/i18n-5%20Languages-purple" alt="i18n">
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
- **Service Control** — Start / Stop / Restart PicoClaw
- **Auto-Start Toggle** — Enable or disable boot-on-start
- **System Logs** — View PicoClaw logs in real-time
- **Online Update** — Check for new versions and update from the UI

### Configuration
- **Channel Management** — View connected channels (Feishu, Telegram, Discord, WeChat, etc.)
- **Form-based Config Editor** — UI for AI model, providers, and system settings
- **JSON Config Editor** — Direct JSON editing with validation

### Hardware & Extensions
- **Hardware Control** — System info, USB devices, GPIO pins (with toggle controls)
- **Skill Management** — View, delete, and import PicoClaw skills from the UI
- **Cron Jobs** — View scheduled tasks at a glance

### 🆕 Built-in Preset Skills
Three ready-to-use AI skills are bundled — install with one click from the management page:

| Skill | Description |
|:---|:---|
| 🔍 **System Diagnostics** | Automated network/DNS/gateway checks, log analysis, and troubleshooting |
| 💾 **Config Backup** | Interactive backup with environment check, options menu, and restore |
| 📦 **App Installer** | Smart app search via opkg/is-opkg, with fuzzy description matching |

> These skills are pure knowledge prompts (SKILL.md) — they enhance PicoClaw's AI responses without modifying the PicoClaw binary.

## 📋 Requirements

| Requirement | Details |
|---|---|
| **OpenWrt** | 24.10 / 25.xx with LuCI |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) installed and running |

## 🚀 Installation

### Option 1: Manual Install

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Init script (optional, for service control)
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw

# Preset skills (optional)
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# Clear LuCI cache
rm -rf /tmp/luci-*
```

Access: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

### Option 2: iStore (Coming Soon)

This package is submitted to the [iStore App Store](https://github.com/istoreos/openwrt-app-actions). Once merged, you can install it directly from the iStore app on your router.

## 📁 Project Structure

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCI controller (backend logic)
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCI template (HTML/CSS/JS, server-rendered)
├── skills/
│   ├── openwrt-diagnostics/
│   │   └── SKILL.md              # System diagnostics AI skill
│   ├── openwrt-backup/
│   │   └── SKILL.md              # Config backup/restore AI skill
│   └── openwrt-app-installer/
│       └── SKILL.md              # Smart app installer AI skill
├── scripts/
│   ├── picoclaw.init              # OpenWrt init.d service script
│   └── build-apk-25xx.sh          # Build script for Sipeed 25xx devices
├── install.py                     # Interactive installation helper
├── Screenshots/                   # README screenshots
└── README*.md                     # Multi-language documentation
```

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Backend | Lua (LuCI) with `luci.jsonc` |
| Frontend | HTML + CSS + JavaScript (server-side rendered) |
| Service Manager | OpenWrt procd (init.d) |
| Security | CSRF token protection on all forms |

## 📄 License

[MIT License](LICENSE)

## 🙏 Credits

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) and [LuCI](https://github.com/openwrt/luci)
