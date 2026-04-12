<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Turn your router into an AI assistant — manage <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> from your browser</b><br>
  <sub>Service management · Model config · Hardware control</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Version-1.1.3-brightgreen" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

<p align="center">
  English ·
  <a href="README.zh.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt.md">Português</a>
</p>

---

## What is this?

**[PicoClaw](https://github.com/sipeed/picoclaw)** is an AI assistant that runs on your router. It connects to large language models (like ChatGPT, DeepSeek, GLM, etc.) and lets you chat via Feishu, Telegram, Discord, WeChat, and more.

However, PicoClaw itself has no graphical interface — you have to configure it via command line or by manually editing JSON files.

**This project adds a web management interface** (a LuCI plugin) for PicoClaw, so you can do everything in your browser: start/stop the service, switch AI models, configure API keys, manage search engines, and more — no command line needed.

> **LuCI** is the web interface framework used by OpenWrt routers. When you open your router's admin page (e.g. 192.168.1.1), that's LuCI.

## 📸 Screenshots

| Dashboard | Config Editor |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| Hardware Control | Mobile View |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Features

- **Service Control** — One-click start / stop / restart PicoClaw, set boot-on-start, view real-time logs
- **Channel Management** — View connection status for Feishu, Telegram, Discord, WeChat, etc.
- **Model Config** — Visual form editor for AI models, with built-in provider presets (Zhipu, DeepSeek, Qwen, OpenAI, etc.) — just fill in your API key
- **Search Engine Config** — Let the AI search the web for answers. Supports GLM Search, Baidu, DuckDuckGo, etc. (with China availability hints)
- **Hardware Control** — View system info, USB devices, toggle GPIO pins
- **Skill Management** — View, delete, import PicoClaw skills; 3 built-in presets (diagnostics, backup, app installer)
- **JSON Editor** — Direct config file editing for advanced users

## 📋 Requirements

| | Details |
|---|---|
| **Router OS** | OpenWrt 21.02+ or iStoreOS (with LuCI interface) |
| **PicoClaw binary** | Must be installed first — this plugin is only the web UI, not PicoClaw itself |
| **Architecture** | Any (pure Lua, works on all architectures) |

## 🚀 Installation

### Step 1: Install PicoClaw

PicoClaw is the core AI assistant program — you need to install it first. SSH into your router and run:

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version   # Should display the version number
```

> ⚠️ The link above is for x86_64. If your router uses ARM (most Xiaomi, TP-Link routers), download the correct binary from [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases).

### Step 2: Install LuCI Interface

**Option A: iStore** (recommended, easiest)

Open iStore on your router → search `picoclaw` → click Install

**Option B: Install IPK via command line**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*   # Clear LuCI cache
```

After installation, open your browser and visit: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Model Configuration

PicoClaw needs to connect to a large language model to work. Think of it as a "client" — it doesn't include AI itself, but calls AI services via their APIs. You need to provide an **API Key** (like a password) so PicoClaw can access the service.

**How to configure:**

1. Go to **Config Editor** tab → find the **Model List** section
2. Click a provider preset button (e.g. "Zhipu GLM", "DeepSeek") — it will auto-fill the API base URL
3. Enter your **API Key** (obtained by registering on the provider's website)
4. Select a **Default Model** from the dropdown
5. Click **Save**

**Supported providers:** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> 💡 **Don't have an API Key?** Most providers offer free credits to try:
> - [Zhipu (智谱)](https://open.bigmodel.cn/) — China-based, free credits on signup
> - [DeepSeek](https://platform.deepseek.com/) — China-based, free credits on signup
> - [OpenRouter](https://openrouter.ai/) — Aggregates multiple models

> 🔒 API keys are stored securely via PicoClaw's dual-file system (`config.json` stores only a placeholder, actual keys are in `.security.yml`), never exposed in plaintext.

## 🔍 Search Engine

PicoClaw can search the web to answer questions. For users in China, we recommend GLM Search or Baidu:

| Engine | China | Notes |
|---|:---:|---|
| GLM Search | ✅ | Recommended, works in China |
| Baidu | ✅ | Alternative |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | Blocked by GFW, works overseas |
| SearXNG | ⚠️ | Self-hosted, depends on where it's deployed |

## ❓ FAQ

| Question | Answer |
|---|---|
| Page doesn't load after install? | Install the PicoClaw binary first (Step 1) — this plugin is just the web UI |
| AI says "no permission to access internet"? | Search engine is blocked — switch to GLM Search or Baidu |
| Can't find in iStore? | Run `opkg update` to refresh, or download the IPK from Releases |
| API key field shows `[NOT_HERE]`? | That's normal — real keys are in `.security.yml`, managed via the LuCI UI |
| What is an API Key? | It's like a password for calling AI services. Register on the provider's site to get one — most offer free credits |
| How to check router architecture? | SSH in and run `uname -m`. Common values: x86_64, aarch64, mipsel |

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## 📜 License

This project is licensed under the **MIT License** — free to use, modify, and distribute, but please retain the author attribution.

Issues and Pull Requests are welcome! 💡

---

> ☕ This project is completely open-source and free. If you like it, you can buy me a coffee~
>
> ![Buy me a coffee](Screenshots/0412_1.jpg)
