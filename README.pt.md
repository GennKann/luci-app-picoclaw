<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Interface web LuCI para gerenciar o <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> no OpenWrt</b><br>
  <sub>Controle total do seu AI gateway — do gerenciamento de serviço ao hardware</sub>
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

## 📸 Capturas de Tela

| Painel | Editor de Configuração |
|:---:|:---:|
| ![Painel](Screenshots/screenshot_main.png) | ![Configuração](Screenshots/screenshot_config.png) |

| Controle de Hardware | Visualização Mobile |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Funcionalidades

### Gerenciamento de Serviço
- **Painel** — Status do serviço em tempo real, PID, uso de memória e monitoramento de porta
- **Controle de Serviço** — Iniciar / Parar / Reiniciar o PicoClaw
- **Alternar Auto-início** — Ativar/desativar inicialização automática
- **Logs do Sistema** — Visualizar logs do PicoClaw em tempo real
- **Atualização Online** — Verificar novas versões e atualizar

### Configuração
- **Gerenciamento de Canais** — Visualizar canais conectados (Feishu, Telegram, Discord, WeChat, etc.)
- **Editor de Configuração** — UI para modelo AI, provedores e configurações do sistema
- **Editor JSON** — Edição direta JSON com validação

### Hardware e Extensões
- **Controle de Hardware** — Informações do sistema, dispositivos USB, pinos GPIO (com alternância H/L)
- **Gerenciamento de Skills** — Visualizar, excluir e importar skills do PicoClaw diretamente pela UI
- **Tarefas Agendadas** — Visualizar jobs Cron de forma rápida

### 🆕 Skills Preset Integradas
Três skills AI prontas para uso são incluídas — instale com um clique na página de gerenciamento:

| Skill | Descrição |
|:---|:---|
| 🔍 **Diagnóstico do Sistema** | Verificação automática de rede/DNS/gateway, análise de logs, solução de problemas |
| 💾 **Backup de Configuração** | Fluxo de backup interativo com verificação de ambiente e menu de opções |
| 📦 **Instalador de Apps** | Busca inteligente de apps via opkg/is-opkg com correspondência fuzzy de descrição |

> Estas skills são prompts de conhecimento puro (SKILL.md) — elas melhoram as respostas AI do PicoClaw sem modificar o binário do PicoClaw.

## 📋 Requisitos

| Requisito | Detalhes |
|---|---|
| **OpenWrt** | 24.10 / 25.xx com LuCI |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) instalado e em execução |

## 🚀 Instalação

### Opção 1: Instalação Manual

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Script Init (opcional, para controle de serviço)
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw

# Skills Preset (opcional)
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# Limpar cache LuCI
rm -rf /tmp/luci-*
```

Acesse: `http://<IP_DO_ROTEADOR>/cgi-bin/luci/admin/services/picoclaw`

### Opção 2: iStore (Em Breve)

Este pacote foi submetido ao [iStore App Store](https://github.com/istoreos/openwrt-app-actions). Após aprovação, poderá ser instalado diretamente pelo iStore no seu roteador.

## 📁 Estrutura do Projeto

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # Controlador LuCI (lógica do backend)
│   └── view/
│       └── picoclaw/
│           └── main.htm           # Template LuCI (HTML/CSS/JS, renderizado no servidor)
├── skills/
│   ├── openwrt-diagnostics/
│   │   └── SKILL.md              # Skill AI de diagnóstico do sistema
│   ├── openwrt-backup/
│   │   └── SKILL.md              # Skill AI de backup de configuração
│   └── openwrt-app-installer/
│       └── SKILL.md              # Skill AI de instalador de apps
├── scripts/
│   ├── picoclaw.init              # Script de serviço OpenWrt init.d
│   └── build-apk-25xx.sh          # Script de build para dispositivos Sipeed 25xx
├── install.py                     # Assistente de instalação interativo
├── Screenshots/                   # Capturas de tela do README
└── README*.md                     # Documentação multilíngue
```

## 🛠️ Stack de Tecnologias

| Componente | Tecnologia |
|---|---|
| Backend | Lua (LuCI) com luci.jsonc |
| Frontend | HTML + CSS + JavaScript (renderizado no servidor) |
| Gerenciador de Serviço | OpenWrt procd (init.d) |
| Segurança | Proteção CSRF token em todos os formulários |

## 📄 Licença

[Licença MIT](LICENSE)

## 🙏 Créditos

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) e [LuCI](https://github.com/openwrt/luci)
