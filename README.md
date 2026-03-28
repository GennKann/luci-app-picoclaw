<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">PicoClaw LuCI — OpenWrt Web Manager</h1>

<p align="center">
  <b>A beautiful LuCI web interface to manage <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> on OpenWrt routers</b>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
  <img src="https://img.shields.io/badge/Arch-ARM64%20%7C%20AMD64%20%7C%20ARMv7-orange" alt="Architecture">
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

- 🖥️ **Modern Dashboard** — Real-time service status, PID, memory usage, and port monitoring
- 🚀 **Service Control** — Start / Stop / Restart PicoClaw with one click
- ⚡ **Auto-Start Toggle** — Enable or disable boot-on-start from the web UI
- 📡 **Channel Management** — View and manage all connected channels (Feishu, Telegram, Discord, WeChat, WeCom, Slack, QQ, LINE, DingTalk, WhatsApp, MaixCam)
- 🔧 **Form-based Config Editor** — Intuitive form UI for AI model, providers, system settings, and tools configuration
- 📝 **JSON Config Editor** — Direct JSON editing with format and validation
- 🌍 **5 Languages** — Built-in i18n: English, 简体中文, 日本語, Português, Deutsch
- 🔄 **Online Update** — Check for new versions and update directly from the UI
- 📊 **System Logs** — View PicoClaw system logs in real-time
- 💬 **WeChat Guide** — Step-by-step WeChat personal account setup guide
- 🔑 **Multi-Provider Support** — Configure API keys for Zhipu, OpenAI, ChatGPT, Claude, DeepSeek, Anthropic, Ollama, Azure OpenAI
- 🎨 **Responsive Design** — Works on both desktop and mobile browsers
- 📦 **One-Click Install** — Python installer for any OpenWrt device via SSH

## 📋 Requirements

| Requirement | Details |
|---|---|
| **OpenWrt** | 24.10 / 25.xx (with LuCI installed) |
| **Architecture** | ARM64, AMD64 (x86_64), ARMv7 |
| **LuCI** | Any standard LuCI installation |
| **SSH** | Must be enabled for the installer script |
| **Python** | 3.6+ (on your PC for the installer) |
| **PicoClaw** | Latest version from [sipeed/picoclaw](https://github.com/sipeed/picoclaw) |

## 🚀 Installation

### Method 1: One-Click Python Installer (Recommended)

Run on your PC — the script will SSH into your router and do everything automatically.

```bash
# Install dependency
pip install paramiko

# Download the installer
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/install_picoclaw_luci.py

# Run — it will guide you through setup
python install_picoclaw_luci.py
```

The installer will:
1. ✅ Detect system architecture (ARM64 / AMD64 / ARMv7)
2. ✅ Download and install the latest PicoClaw binary
3. ✅ Create procd init.d service for auto-start
4. ✅ Deploy LuCI web management interface
5. ✅ Initialize PicoClaw configuration
6. ✅ Start the service and verify

### Method 2: Manual Installation

SSH into your OpenWrt router and run:

```bash
# 1. Download and install PicoClaw
ARCH=$(uname -m)
if echo "$ARCH" | grep -q "x86"; then
    PLAT="linux_amd64"
elif echo "$ARCH" | grep -q "armv7"; then
    PLAT="linux_armv7"
else
    PLAT="linux_arm64"
fi

wget -O /tmp/picoclaw "https://github.com/sipeed/picoclaw/releases/latest/download/picoclaw_${PLAT}"
chmod +x /tmp/picoclaw
mv /tmp/picoclaw /usr/bin/picoclaw

# 2. Deploy LuCI files (copy from this repo)
# controller: luci/controller/picoclaw.lua → /usr/lib/lua/luci/controller/picoclaw.lua
# template: luci/view/picoclaw/main.htm → /usr/lib/lua/luci/view/picoclaw/main.htm

# 3. Set up init.d service
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw
/etc/init.d/picoclaw enable

# 4. Clear LuCI cache and start
rm -rf /tmp/luci-*
/etc/init.d/picoclaw start
```

### Method 3: Package Installation

> **Note:** OpenWrt 24.10 uses `.ipk` (opkg), while OpenWrt 25.xx uses `.apk` (apk-tools). They are **different** package managers.

#### OpenWrt 24.10 (opkg / .ipk)

```bash
opkg install luci-compat
wget -O /tmp/luci-app-picoclaw.ipk https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_24.10_all.ipk
opkg install /tmp/luci-app-picoclaw.ipk
```

#### OpenWrt 25.xx (apk / .apk)

Since OpenWrt 25.x switched from `opkg` to `apk-tools`, the package format has changed from `.ipk` to `.apk`. You can build the package directly on your router:

```bash
# Download the build script
wget -O /tmp/build-apk-25xx.sh https://raw.githubusercontent.com/GennKann/luci-app-picoclaw/main/scripts/build-apk-25xx.sh
chmod +x /tmp/build-apk-25xx.sh

# Run it to build the .apk package
/tmp/build-apk-25xx.sh

# Install the generated package
apk add --allow-untrusted /root/luci-app-picoclaw_1.0.0_all.apk
```

> **Why build on-device?** OpenWrt 25.xx uses APKv3 (Alpine Package Keeper) format which requires `apk-tools` to build properly. Building on the router ensures full compatibility.

## 🎯 Access

After installation, access the management interface:

```
http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw
```

For example: `http://192.168.1.1/cgi-bin/luci/admin/services/picoclaw`

## 🛠️ Tech Stack

| Component | Technology |
|---|---|
| Backend Controller | Lua (LuCI) |
| Frontend Template | HTML + CSS + JavaScript (server-side rendered) |
| Service Manager | OpenWrt procd (init.d) |
| Installer | Python + Paramiko (SSH) |
| AI Engine | [PicoClaw](https://github.com/sipeed/picoclaw) (Go) |

## ⚠️ Disclaimer

This project is a **community-driven** LuCI management interface for PicoClaw. It is **NOT** part of the official PicoClaw project.

- **PicoClaw** is developed by [Sipeed](https://github.com/sipeed) under the MIT License
- This LuCI interface is an independent open-source tool
- We respect all intellectual property rights of the original project
- "PicoClaw" and "Sipeed" are trademarks of their respective owners

## 📄 License

This project is licensed under the [MIT License](LICENSE).

## 🙏 Credits

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed — the amazing AI assistant this project manages
- [OpenWrt](https://openwrt.org/) — the foundation this runs on
- [LuCI](https://github.com/openwrt/luci) — the web interface framework

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

<p align="center">
  If you find this project useful, please consider giving it a ⭐!
</p>

<p align="center">
  <a href="https://github.com/GennKann/luci-app-picoclaw">
    <img src="https://img.shields.io/github/stars/GennKann/luci-app-picoclaw?style=social" alt="Stars">
  </a>
  <a href="https://github.com/GennKann/luci-app-picoclaw/fork">
    <img src="https://img.shields.io/github/forks/GennKann/luci-app-picoclaw?style=social" alt="Forks">
  </a>
</p>

<p align="center">
  <b>Made with ❤️ by <a href="https://github.com/GennKann">GennKann</a></b>
</p>
