<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI-Weboberfläche zur Verwaltung von <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> auf OpenWrt</b><br>
  <sub>Vollständige Kontrolle über Ihr AI-Gateway — von Servicemanagement bis Hardware</sub>
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

| Dashboard | Konfigurations-Editor |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Konfiguration](Screenshots/screenshot_config.png) |

| Hardware-Steuerung | Mobilansicht |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobil](Screenshots/screenshot_mobile.png) |

## ✨ Funktionen

### Service-Verwaltung
- **Dashboard** — Echtzeit-Service-Status, PID, Speichernutzung, Port-Überwachung
- **Service-Steuerung** — PicoClaw starten / stoppen / neu starten
- **Autostart-Umschalter** — Autostart aktivieren/deaktivieren
- **Systemprotokolle** — PicoClaw-Logs in Echtzeit
- **Online-Update** — Neue Versionen prüfen und aktualisieren

### Konfiguration
- **Kanalverwaltung** — Verbundene Kanäle anzeigen (Feishu, Telegram, Discord, WeChat, etc.)
- **Formular-Konfiguration** — UI für AI-Modell, Anbieter und Systemeinstellungen
- **JSON-Editor** — Direkte JSON-Bearbeitung mit Validierung

### Hardware & Erweiterungen
- **Hardware-Steuerung** — Systeminfo, USB-Geräte, GPIO-Pins (mit H/L-Umschaltung)
- **Skill-Verwaltung** — PicoClaw-Skills anzeigen, löschen und importieren direkt in der UI
- **Cron-Jobs** — Geplante Aufgaben auf einen Blick

### 🆕 Integrierte Preset-Skills
Drei sofort verwendbare AI-Skills sind enthalten — mit einem Klick installieren:

| Skill | Beschreibung |
|:---|:---|
| 🔍 **Systemdiagnose** | Automatische Netzwerk/DNS/Gateway-Prüfung, Log-Analyse, Fehlerbehebung |
| 💾 **Konfigurations-Backup** | Interaktiver Backup-Workflow mit Umgebungsprüfung und Optionsmenü |
| 📦 **App-Installer** | Intelligente App-Suche über opkg/is-opkg mit unscharfer Beschreibungserkennung |

> Diese Skills sind reine Wissens-Prompts (SKILL.md) — sie verbessern die AI-Antworten von PicoClaw ohne Änderung am PicoClaw-Binary.

## 📋 Voraussetzungen

| Anforderung | Details |
|---|---|
| **OpenWrt** | 24.10 / 25.xx mit LuCI |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) installiert und laufend |

## 🚀 Installation

### Option 1: Manuelle Installation

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Init-Skript (optional, für Service-Steuerung)
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw

# Preset-Skills (optional)
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# LuCI-Cache leeren
rm -rf /tmp/luci-*
```

Zugriff: `http://<ROUTER-IP>/cgi-bin/luci/admin/services/picoclaw`

### Option 2: iStore (Bald verfügbar)

Dieses Paket wurde beim [iStore App Store](https://github.com/istoreos/openwrt-app-actions) eingereicht. Nach Genehmigung kann es direkt aus der iStore-App auf Ihrem Router installiert werden.

## 📁 Projektstruktur

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCI-Controller (Backend-Logik)
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCI-Template (HTML/CSS/JS, serverseitig gerendert)
├── skills/
│   ├── openwrt-diagnostics/
│   │   └── SKILL.md              # Systemdiagnose AI-Skill
│   ├── openwrt-backup/
│   │   └── SKILL.md              # Konfigurations-Backup AI-Skill
│   └── openwrt-app-installer/
│       └── SKILL.md              # App-Installer AI-Skill
├── scripts/
│   ├── picoclaw.init              # OpenWrt init.d Service-Skript
│   └── build-apk-25xx.sh          # Build-Skript für Sipeed 25xx Geräte
├── install.py                     # Interaktiver Installationshelfer
├── Screenshots/                   # README-Screenshots
└── README*.md                     # Mehrsprachige Dokumentation
```

## 🛠️ Tech-Stack

| Komponente | Technologie |
|---|---|
| Backend | Lua (LuCI) mit luci.jsonc |
| Frontend | HTML + CSS + JavaScript (serverseitig gerendert) |
| Service-Manager | OpenWrt procd (init.d) |
| Sicherheit | CSRF-Token-Schutz auf allen Formularen |

## 📄 Lizenz

[MIT-Lizenz](LICENSE)

## 🙏 Danksagungen

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) und [LuCI](https://github.com/openwrt/luci)
