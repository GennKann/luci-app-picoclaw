<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI web interface for managing <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> on OpenWrt</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
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

| Desktop View | Mobile View |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Mobile](Screenshots/screenshot_mobile.png) |
| ![Config Editor](Screenshots/screenshot_config.png) | — |

## ✨ Features

- **Dashboard** — Service status, PID, memory usage, and port monitoring
- **Service Control** — Start / Stop / Restart PicoClaw
- **Auto-Start Toggle** — Enable or disable boot-on-start
- **Channel Management** — View connected channels (Feishu, Telegram, Discord, WeChat, etc.)
- **Form-based Config Editor** — UI for AI model, providers, and system settings
- **JSON Config Editor** — Direct JSON editing with validation
- **Hardware Control** — System info, USB devices, GPIO pins (with toggle controls)
- **Skill Management** — View, delete, and import PicoClaw skills directly from the UI
- **Cron Jobs** — View scheduled tasks at a glance
- **i18n** — English, 简体中文, 日本語, Português, Deutsch
- **Online Update** — Check for new versions and update from the UI
- **System Logs** — View PicoClaw logs in real-time
- **Responsive Design** — Desktop and mobile browsers

## 📋 Requirements

| Requirement | Details |
|---|---|
| **OpenWrt** | 24.10 / 25.xx with LuCI |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) installed and running |

## 🚀 Installation

Copy the LuCI files to your OpenWrt router:

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Clear LuCI cache
rm -rf /tmp/luci-*
```

Then access: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Backend | Lua (LuCI) |
| Frontend | HTML + CSS + JavaScript (server-side rendered) |
| Service Manager | OpenWrt procd (init.d) |

## 📄 License

[MIT License](LICENSE)

## 🙏 Credits

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) and [LuCI](https://github.com/openwrt/luci)
