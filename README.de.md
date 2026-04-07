<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>LuCI-Weboberfläche zur Verwaltung von <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> auf OpenWrt</b><br>
  <sub>Vollständige Kontrolle über Ihr AI-Gateway — von Servicemanagement bis Hardware</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-21.02%20%7C%2022.03%20%7C%2023.05%20%7C%2024.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
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

## Screenshots

| Dashboard | Konfigurations-Editor |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Konfiguration](Screenshots/screenshot_config.png) |

| Hardware-Steuerung | Mobilansicht |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobil](Screenshots/screenshot_mobile.png) |

## Funktionen

### Service-Verwaltung
- **Dashboard** — Echtzeit-Service-Status, PID, Speichernutzung, Port-Überwachung
- **Service-Steuerung** — PicoClaw starten / stoppen (mit kill-9 Zwangsstopp) / neu starten
- **Autostart-Umschalter** — Autostart aktivieren/deaktivieren
- **Systemprotokolle** — PicoClaw-Logs in Echtzeit anzeigen und aktualisieren
- **Online-Update** — Neue Versionen prüfen und aus der UI aktualisieren

### Konfiguration
- **Kanalverwaltung** — Verbundene Kanäle anzeigen (Feishu, Telegram, Discord, WeChat, etc.)
- **WeChat-Status-Erkennung** — Automatische Erkennung der WeChat-Personalaccount-Sitzung nach QR-Code-Scan
- **Formular-Konfiguration** — UI für AI-Modell, Anbieter und Systemeinstellungen
- **JSON-Editor** — Direkte JSON-Bearbeitung mit Validierung

### Hardware & Erweiterungen
- **Hardware-Steuerung** — Systeminfo, USB-Geräte, GPIO-Pins (mit H/L-Umschaltung)
- **Skill-Verwaltung** — PicoClaw-Skills anzeigen, löschen und importieren direkt in der UI
- **Cron-Jobs** — Geplante Aufgaben auf einen Blick

### Integrierte Preset-Skills
Drei sofort verwendbare AI-Skills sind enthalten — mit einem Klick installieren:

| Skill | Beschreibung |
|:---|:---|
| **Systemdiagnose** | Automatische Netzwerk/DNS/Gateway-Prüfung, Log-Analyse, Fehlerbehebung |
| **Konfigurations-Backup** | Interaktiver Backup-Workflow mit Umgebungsprüfung und Optionsmenü |
| **App-Installer** | Intelligente App-Suche über opkg/is-opkg mit unscharfer Beschreibungserkennung |

> Diese Skills sind reine Wissens-Prompts (SKILL.md) — sie verbessern die AI-Antworten von PicoClaw ohne Änderung am PicoClaw-Binary.

## Voraussetzungen

| Anforderung | Details |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ / 22.03 / 23.05 / 24.10 / 25.xx / iStoreOS (mit LuCI) |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) muss installiert und ausgeführt werden |
| **Architektur** | all (reines Lua, x86-64 / aarch64 / armv7 / mipsle / riscv64, etc.) |

> ⚠️ **Wichtig**: `luci-app-picoclaw` ist nur die **Web-Oberfläche** für PicoClaw — es ist NICHT PicoClaw selbst. Wenn Sie PicoClaw noch nicht installiert haben, führen Sie bitte zuerst "Schritt 1" unten durch.

## Installation

### Schritt 1: PicoClaw installieren (Erforderlich!)

Laden Sie von [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) die passende Version für Ihre Architektur herunter:

```bash
# Beispiel für x86-64 (Passen Sie die Version an)
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw

# Installation prüfen
picoclaw --version
```

### Schritt 2: LuCI-Oberfläche installieren (luci-app-picoclaw)

#### Option 1: iStore App Store (Empfohlen)

Suchen Sie nach `picoclaw` in der iStore-App auf Ihrem Router → direkt installieren.
> Ab v1.0.8 in der offiziellen iStore-Quelle verfügbar.

#### Option 2: IPK herunterladen

Laden Sie von [Releases](https://github.com/GennKann/luci-app-picoclaw/releases/latest) herunter:

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.0.9-1_all.ipk
opkg install luci-app-picoclaw_1.0.9-1_all.ipk
rm -rf /tmp/luci-*   # LuCI-Cache leeren
```

#### Option 3: Manuelle Dateikopie

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua
# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm
# Init-Skript
cp scripts/picoclaw.init /etc/init.d/picoclaw && chmod +x /etc/init.d/picoclaw
# Cache leeren
rm -rf /tmp/luci-*
```

Nach der Installation wird empfohlen, einmal "Neustart" in der LuCI-Seite zu klicken:
> LuCI → Dienste → PicoClaw → **Neustart** klicken

Zugriff: `http:<ROUTER-IP>/cgi-bin/luci/admin/services/picoclaw`

## FAQ

### luci-app-picoclaw installiert, aber Seite lädt nicht?
Das bedeutet, das **PicoClaw-Binary** nicht installiert ist. Führen Sie "Schritt 1" oben aus und laden Sie dann die Seite neu.

### Stoptaste stoppt den Gateway nicht wirklich?
Ein bekanntes Problem in Versionen <= 1.0.7, bei dem procd den Prozess automatisch wiederhergestellt hat. **In v1.0.8 behoben** — Die Stop-Funktion verwendet nun eine 3-Stufen-Strategie (sanfter Stopp → pidof-Prüfung + kill-9-Zwangsstopp → Bereinigungswartezeit). Upgraden Sie auf v1.0.8.

### "Invalid CSRF token" Fehler beim Aktualisieren der Logs?
Bekanntes Problem in Versionen <= 1.0.7. **In v1.0.8 behoben** — Alle Formularübertragungen tragen nun korrekt CSRF-Token.

### picoclaw im iStore nicht gefunden?
Führen Sie `opkg update` im Router-Terminal aus oder laden Sie das IPK direkt von GitHub Releases herunter.

### Was ist der orangefarbene Installationsbanner oben?
luci-app-picoclaw ist installiert, aber PicoClaw-Binary fehlt. Klicken Sie den Banner zur One-Click-Installation (automatische Architektur-Erkennung).

## Projektstruktur

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCI-Controller (Backend-Logik)
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCI-Template (HTML/CSS/JS)
├── skills/
│   ├── openwrt-diagnostics/
│   ├── openwrt-backup/
│   └── openwrt-app-installer/
├── scripts/
│   └── picoclaw.init              # OpenWrt init.d Service-Skript
├── install.py                     # Interaktiver Installationshelfer
├── Screenshots/
└── README*.md                     # Mehrsprachige Dokumentation
```

## Tech-Stack

| Komponente | Technologie |
|---|---|
| Backend | Lua (LuCI) mit luci.jsonc |
| Frontend | HTML + CSS + JavaScript (serverseitig gerendert) |
| Service-Manager | OpenWrt procd (init.d), mit kill-9 Sicherheits-Fallback |
| Sicherheit | CSRF-Token-Schutz auf allen Formularen |

## Änderungsprotokoll

Siehe [CHANGELOG.md](CHANGELOG.md).

## Lizenz

[MIT-Lizenz](LICENSE)

## Danksagungen

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) und [LuCI](https://github.com/openwrt/luci)
