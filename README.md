<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI web interface for <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> on OpenWrt</b><br>
  <sub>Service management · Model config · Hardware control</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Version-1.1.3-brightgreen" alt="Version">
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

- **Service Control** — Start / Stop / Restart, boot-on-start toggle, real-time logs
- **Channel Management** — Feishu, Telegram, Discord, WeChat status detection
- **Model Config** — Form-based editor with provider presets (Zhipu, DeepSeek, Qwen, OpenAI, etc.), API key secure storage
- **Search Engine Config** — GLM Search, Baidu, DuckDuckGo, Brave, Tavily, Perplexity, SearXNG (with GFW hints)
- **Hardware Control** — System info, USB devices, GPIO toggle
- **Skill Management** — View, delete, import skills; 3 built-in presets (diagnostics, backup, app installer)
- **JSON Editor** — Direct config editing with validation

## 📋 Requirements

| | Details |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ (with LuCI) |
| **PicoClaw** | Must be installed first — this is only the web UI |
| **Architecture** | all (pure Lua) |

## 🚀 Installation

### Step 1: Install PicoClaw

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version
```

### Step 2: Install LuCI Interface

**iStore** (recommended) — Search `picoclaw` → Install

**Or download IPK:**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*
```

Access: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Model Configuration

In **Config Editor** tab → **Model List** section:

1. Click **Add Model** (or use a provider preset button)
2. Fill in: model name, provider, model ID, API base (auto-filled), API key
3. Set the **Default Model** from dropdown
4. Click **Save**

**Supported providers:** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> API keys are stored securely via PicoClaw's dual-file system (`config.json` placeholder + `.security.yml` actual keys).

## 🔍 Search Engine

| Engine | China | |
|---|:---:|---|
| GLM Search | ✅ | Recommended |
| Baidu | ✅ | Alternative |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | Blocked by GFW |
| SearXNG | ⚠️ | Self-hosted, depends on instance |

## ❓ FAQ

| Question | Answer |
|---|---|
| Page doesn't load? | Install PicoClaw binary first (Step 1) |
| "No permission to access internet"? | Switch search engine to GLM Search or Baidu |
| Can't find in iStore? | Run `opkg update` or download IPK from Releases |
| API keys show `[NOT_HERE]`? | Normal — real keys are in `.security.yml`, manage via LuCI UI |

## Changelog

See [CHANGELOG.md](CHANGELOG.md).

## 📄 License

[MIT License](LICENSE)
