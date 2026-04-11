<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI-Weboberfläche für <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> auf OpenWrt</b><br>
  <sub>Dienstverwaltung · Modellkonfiguration · Hardwaresteuerung</sub>
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
  Deutsch ·
  <a href="README.pt.md">Português</a>
</p>

---

## 📸 Screenshots

| Dashboard | Konfigurationseditor |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| Hardwaresteuerung | Mobile Ansicht |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Funktionen

- **Dienststeuerung** — Start / Stopp / Neustart, Autostart, Echtzeit-Logs
- **Kanalverwaltung** — Feishu, Telegram, Discord, WeChat-Statuserkennung
- **Modellkonfiguration** — Formular-Editor mit Anbieter-Voreinstellungen (Zhipu, DeepSeek, Qwen, OpenAI usw.), API-Key sichere Speicherung
- **Suchmaschinen-Konfiguration** — GLM Search, Baidu, DuckDuckGo, Brave, Tavily, Perplexity, SearXNG (mit GFW-Hinweisen)
- **Hardwaresteuerung** — Systeminfo, USB-Geräte, GPIO-Schalter
- **Skill-Verwaltung** — Anzeigen, Löschen, Importieren; 3 integrierte Voreinstellungen (Diagnose, Backup, App-Installer)
- **JSON-Editor** — Direkte Konfigurationsbearbeitung mit Validierung

## 📋 Voraussetzungen

| | Details |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ (mit LuCI) |
| **PicoClaw** | Muss zuerst installiert werden — dies ist nur das Web-UI |
| **Architektur** | all (reines Lua) |

## 🚀 Installation

### Schritt 1: PicoClaw installieren

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version
```

### Schritt 2: LuCI-Oberfläche installieren

**iStore** (empfohlen) — `picoclaw` suchen → Installieren

**Oder IPK herunterladen:**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*
```

Zugriff: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Modellkonfiguration

Im Tab **Konfigurationseditor** → Bereich **Modellliste**:

1. **Modell hinzufügen** klicken (oder Anbieter-Voreinstellung nutzen)
2. Ausfüllen: Modellname, Anbieter, Modell-ID, API-Base (auto-ausgefüllt), API-Key
3. **Standardmodell** im Dropdown festlegen
4. **Speichern** klicken

**Unterstützte Anbieter:** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> API-Keys werden über PicoClaws Dual-Datei-Sicherheitssystem gespeichert (`config.json` Platzhalter + `.security.yml` echte Keys).

## 🔍 Suchmaschine

| Engine | China | |
|---|:---:|---|
| GLM Search | ✅ | Empfohlen |
| Baidu | ✅ | Alternative |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | GFW-blockiert |
| SearXNG | ⚠️ | Self-hosted, instanzabhängig |

## ❓ FAQ

| Frage | Antwort |
|---|---|
| Seite lädt nicht? | PicoClaw-Binary zuerst installieren (Schritt 1) |
| „Keine Internetberechtigung"? | Suchmaschine auf GLM Search oder Baidu umstellen |
| In iStore nicht gefunden? | `opkg update` ausführen oder IPK von Releases laden |
| API-Keys zeigen `[NOT_HERE]`? | Normal — echte Keys in `.security.yml`, über LuCI UI verwalten |

## Changelog

Siehe [CHANGELOG.md](CHANGELOG.md).

## 📄 Lizenz

[MIT License](LICENSE)
