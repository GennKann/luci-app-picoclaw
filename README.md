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
| **OpenWrt / iStoreOS** | 24.10 / 25.xx with LuCI |
| **PicoClaw** | **Must be installed first!** This interface does not include the PicoClaw binary |
| **Architecture** | all (pure Lua, works on x86-64 / aarch64 / armv7 / etc.) |

> ⚠️ **Important**: `luci-app-picoclaw` is only the **web management interface** for PicoClaw — it is NOT PicoClaw itself. If you haven't installed the PicoClaw binary yet, please complete "Step 1" below first, otherwise the management page will not work properly.

## 🚀 Installation

### Step 1: Install PicoClaw (Required!)

PicoClaw supports multiple architectures (x86-64, aarch64, armv7, mipsle, riscv64, etc.). Download from [Releases](https://github.com/sipeed/picoclaw/releases).

#### Option A: Manual CLI Installation

**iStoreOS (x86-64) example:**

```bash
# Download PicoClaw (replace version as needed)
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.4/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw
chmod +x /usr/bin/picoclaw

# Install init.d service script (optional, for procd management and auto-start)
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw
/etc/init.d/picoclaw enable
```

> 💡 **Other architectures**: arm64 devices use `picoclaw_Linux_arm64.tar.gz`, mipsle devices use `picoclaw_Linux_mipsle.tar.gz`, etc. See [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) for the full list.

**Verify PicoClaw is installed:**

```bash
picoclaw --version
```

#### Option B: One-Click Install Script (Recommended for beginners)

This project includes a Python script that **automatically detects your architecture, downloads PicoClaw, deploys the LuCI interface, and configures the service** — all in one go.

**Run on your computer (requires Python 3 and paramiko):**

```bash
# 1. Clone this repository
git clone https://github.com/GennKann/luci-app-picoclaw.git
cd luci-app-picoclaw

# 2. Install dependency
pip install paramiko

# 3. Run the one-click installer
python install.py
```

The script automatically:
- ✅ Detects router architecture (x86-64 / arm64 / armv7)
- ✅ Downloads and installs PicoClaw binary
- ✅ Creates init.d auto-start service
- ✅ Deploys LuCI management interface
- ✅ Initializes PicoClaw config
- ✅ Starts PicoClaw service

#### Option C: In-Page One-Click Install

If you've already installed `luci-app-picoclaw` (via iStore or IPK) but haven't installed the PicoClaw binary yet, an **orange install banner** will appear at the top of the LuCI page. Click it to install PicoClaw directly from the web UI (automatically detects architecture and downloads the correct binary).

> 💡 Use this option if you want to install the management interface first, then install PicoClaw from the page itself.

### Step 2: Install LuCI Interface (luci-app-picoclaw)

> If you already used the "One-Click Install Script" above, this step is **already done** — you can skip it.

#### Option 1: iStore App Store (Recommended)

Search for `picoclaw` in the iStore app on your router and install directly.

#### Option 2: Download IPK

Download the IPK from [Releases](https://github.com/GennKann/luci-app-picoclaw/releases) (`_all` means architecture-independent):

```bash
# Download IPK (v1.0.5 example)
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/download/v1.0.5/luci-app-picoclaw_1.0.5-1_all.ipk

# Install dependencies
opkg update
opkg install luci-lib-jsonc curl

# Install IPK
opkg install luci-app-picoclaw_1.0.5-1_all.ipk

# Clear LuCI cache
rm -rf /tmp/luci-*
```

#### Option 3: Manual File Copy

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Preset skills (optional)
mkdir -p /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# Clear LuCI cache
rm -rf /tmp/luci-*
```

Access: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## ❓ FAQ

### Installed luci-app-picoclaw but the page doesn't load / shows errors?
This means **PicoClaw binary** is not installed on your router. Please complete "Step 1" to install PicoClaw first, then refresh the page.

### Can't find picoclaw in the iStore app?
Make sure your iStore package sources are up to date (`opkg update`), or download the IPK directly from GitHub Releases.

### What is the orange install banner at the top of the page?
This means `luci-app-picoclaw` is installed but PicoClaw binary is not yet installed. Click the banner to install PicoClaw with one click.

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
