<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI-Weboberfläche zur Verwaltung von <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> auf OpenWrt</b>
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

| Desktop | Mobil |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Mobil](Screenshots/screenshot_mobile.png) |
| ![Konfiguration](Screenshots/screenshot_config.png) | — |

## ✨ Funktionen

- **Dashboard** — Echtzeit-Service-Status, PID, Speichernutzung, Port-Überwachung
- **Service-Steuerung** — PicoClaw starten / stoppen / neu starten
- **Autostart-Umschalter** — Autostart aktivieren/deaktivieren
- **Kanalverwaltung** — Verbundene Kanäle anzeigen (Feishu, Telegram, Discord, WeChat, etc.)
- **Formular-Konfiguration** — UI für AI-Modell, Anbieter und Systemeinstellungen
- **JSON-Editor** — Direkte JSON-Bearbeitung mit Validierung
- **Mehrsprachig** — English, 简体中文, 日本語, Português, Deutsch
- **Online-Update** — Neue Versionen prüfen und aktualisieren
- **Systemprotokolle** — PicoClaw-Logs in Echtzeit
- **Responsives Design** — Desktop und mobil

## 📋 Voraussetzungen

| Anforderung | Details |
|---|---|
| **OpenWrt** | 24.10 / 25.xx mit LuCI |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) installiert und laufend |

## 🚀 Installation

LuCI-Dateien auf den OpenWrt-Router kopieren:

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# LuCI-Cache leeren
rm -rf /tmp/luci-*
```

Zugriff: `http://<ROUTER-IP>/cgi-bin/luci/admin/services/picoclaw`

## 🛠️ Tech-Stack

| Komponente | Technologie |
|---|---|
| Backend | Lua (LuCI) |
| Frontend | HTML + CSS + JavaScript (serverseitig gerendert) |
| Service-Manager | OpenWrt procd (init.d) |

## 📄 Lizenz

[MIT-Lizenz](LICENSE)

## 🙏 Danksagungen

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) und [LuCI](https://github.com/openwrt/luci)
