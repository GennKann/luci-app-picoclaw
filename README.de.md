<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Machen Sie Ihren Router zum AI-Assistenten — <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> im Browser verwalten</b><br>
  <sub>Dienstverwaltung · Modellkonfiguration · Hardwaresteuerung</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Version-1.1.5-brightgreen" alt="Version">
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

## Was ist das?

**[PicoClaw](https://github.com/sipeed/picoclaw)** ist ein KI-Assistent, der auf Ihrem Router läuft. Er verbindet sich mit großen Sprachmodellen (wie ChatGPT, DeepSeek, GLM usw.) und ermöglicht Chats über Feishu, Telegram, Discord, WeChat und mehr.

Allerdings hat PicoClaw selbst keine grafische Oberfläche — die Konfiguration muss über die Kommandozeile oder durch manuelles Bearbeiten von JSON-Dateien erfolgen.

**Dieses Projekt fügt eine Web-Verwaltungsoberfläche** (ein LuCI-Plugin) für PicoClaw hinzu. Alles lässt sich im Browser erledigen: Dienst starten/stoppen, KI-Modelle wechseln, API-Keys konfigurieren, Suchmaschinen verwalten und mehr — keine Kommandozeile nötig.

> **LuCI** ist das Web-Interface-Framework von OpenWrt-Routern. Wenn Sie die Admin-Seite Ihres Routers öffnen (z.B. 192.168.1.1), ist das LuCI.

## 📸 Screenshots

| Dashboard | Konfigurationseditor |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| Hardwaresteuerung | Mobile Ansicht |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Funktionen

- **Dienststeuerung** — Ein-Klick Start / Stopp / Neustart, Autostart, Echtzeit-Logs
- **Kanalverwaltung** — Verbindungsstatus für Feishu, Telegram, Discord, WeChat usw.
- **Modellkonfiguration** — Visueller Formular-Editor für KI-Modelle mit Anbieter-Voreinstellungen (Zhipu, DeepSeek, Qwen, OpenAI usw.) — einfach API-Key eintragen
- **Suchmaschinen-Konfiguration** — KI kann das Web durchsuchen. Unterstützt GLM Search, Baidu, DuckDuckGo usw. (mit China-Verfügbarkeitshinweisen)
- **Hardwaresteuerung** — Systeminfo, USB-Geräte, GPIO-Schalter
- **Skill-Verwaltung** — PicoClaw-Skills anzeigen, löschen, importieren; 3 integrierte Voreinstellungen (Diagnose, Backup, App-Installer)
- **JSON-Editor** — Direkte Konfigurationsbearbeitung für Fortgeschrittene

## 📋 Voraussetzungen

| | Details |
|---|---|
| **Router-Betriebssystem** | OpenWrt 21.02+ oder iStoreOS (mit LuCI-Oberfläche) |
| **PicoClaw-Binary** | Muss zuerst installiert werden — dieses Plugin ist nur das Web-UI, nicht PicoClaw selbst |
| **Architektur** | Alle (reines Lua, funktioniert auf allen Architekturen) |

## 🚀 Installation

### Schritt 1: PicoClaw installieren

PicoClaw ist das Kernprogramm des KI-Assistenten — es muss zuerst installiert werden. Per SSH auf den Router verbinden und ausführen:

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version   # Versionsnummer sollte angezeigt werden
```

> ⚠️ Der obige Link ist für x86_64. Wenn Ihr Router ARM verwendet (die meisten Xiaomi-, TP-Link-Router), laden Sie das richtige Binary von [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) herunter.

### Schritt 2: LuCI-Oberfläche installieren

**Option A: iStore** (empfohlen, am einfachsten)

iStore auf dem Router öffnen → `picoclaw` suchen → Installieren klicken

**Option B: IPK über Kommandozeile installieren**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.5-1_all.ipk
opkg install luci-app-picoclaw_1.1.5-1_all.ipk
rm -rf /tmp/luci-*   # LuCI-Cache leeren
```

Nach der Installation im Browser öffnen: `http://<ROUTER_IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Modellkonfiguration

PicoClaw muss sich mit einem großen Sprachmodell verbinden, um zu funktionieren. Stellen Sie es sich als „Client" vor — es enthält keine KI selbst, sondern ruft KI-Dienste über deren APIs auf. Sie müssen einen **API-Key** (ähnlich einem Passwort) angeben, damit PicoClaw auf den Dienst zugreifen kann.

**So konfigurieren Sie:**

1. Gehen Sie zum Tab **Konfigurationseditor** → finden Sie den Bereich **Modellliste**
2. Klicken Sie auf eine Anbieter-Voreinstellung (z.B. „Zhipu GLM", „DeepSeek") — die API-Base-URL wird automatisch ausgefüllt
3. Geben Sie Ihren **API-Key** ein (auf der Anbieter-Website durch Registrierung erhältlich)
4. Wählen Sie ein **Standardmodell** aus dem Dropdown
5. Klicken Sie auf **Speichern**

**Unterstützte Anbieter:** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> 💡 **Noch keinen API-Key?** Die meisten Anbieter bieten kostenlose Credits zum Testen:
> - [Zhipu (智谱)](https://open.bigmodel.cn/) — China-basiert, kostenlose Credits bei Registrierung
> - [DeepSeek](https://platform.deepseek.com/) — China-basiert, kostenlose Credits bei Registrierung
> - [OpenRouter](https://openrouter.ai/) — Aggregiert mehrere Modelle

> 🔒 API-Keys werden über PicoClaws Dual-Datei-Sicherheitssystem gespeichert (`config.json` speichert nur einen Platzhalter, echte Keys in `.security.yml`), nie im Klartext offengelegt.

## 🔍 Suchmaschine

PicoClaw kann das Web durchsuchen, um Fragen zu beantworten. Für Nutzer in China empfehlen wir GLM Search oder Baidu:

| Engine | China | Hinweise |
|---|:---:|---|
| GLM Search | ✅ | Empfohlen, funktioniert in China |
| Baidu | ✅ | Alternative |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | GFW-blockiert, nur im Ausland |
| SearXNG | ⚠️ | Self-hosted, abhängig vom Standort |

## ❓ FAQ

| Frage | Antwort |
|---|---|
| Seite lädt nicht nach Installation? | PicoClaw-Binary zuerst installieren (Schritt 1) — dieses Plugin ist nur das Web-UI |
| KI sagt „keine Internetberechtigung"? | Suchmaschine ist blockiert — auf GLM Search oder Baidu umstellen |
| In iStore nicht gefunden? | `opkg update` ausführen oder IPK von Releases laden |
| API-Key-Feld zeigt `[NOT_HERE]`? | Normal — echte Keys in `.security.yml`, über LuCI UI verwalten |
| Was ist ein API-Key? | Ein Passwort für den Aufruf von KI-Diensten. Auf der Anbieter-Website registrieren — die meisten bieten kostenlose Credits |
| Router-Architektur prüfen? | Per SSH `uname -m` ausführen. Häufige Werte: x86_64, aarch64, mipsel |

## Changelog

Siehe [CHANGELOG.md](CHANGELOG.md).

## 📄 Lizenz

[MIT License](LICENSE)

---

Support
-------

Wenn Ihnen dieses Projekt gefällt, können Sie dem Repository einen Stern geben oder mir einen Kaffee spendieren :)

[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/gennkann)

<details>
<summary>🇨🇳 WeChat Pay</summary>
<img src="Images/wechat_pay.jpg" width="200" alt="WeChat Pay" />
</details>
