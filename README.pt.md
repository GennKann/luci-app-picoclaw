<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Interface web LuCI para gerenciar o <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> no OpenWrt</b>
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

## 📸 Capturas de Tela

| Desktop | Mobile |
|:---:|:---:|
| ![Painel](Screenshots/screenshot_main.png) | ![Mobile](Screenshots/screenshot_mobile.png) |
| ![Configuração](Screenshots/screenshot_config.png) | — |

## ✨ Funcionalidades

- **Painel** — Status do serviço em tempo real, PID, uso de memória e monitoramento de porta
- **Controle de Serviço** — Iniciar / Parar / Reiniciar o PicoClaw
- **Alternar Auto-início** — Ativar/desativar inicialização automática
- **Gerenciamento de Canais** — Visualizar canais conectados (Feishu, Telegram, Discord, WeChat, etc.)
- **Editor de Configuração** — UI para modelo AI, provedores e configurações do sistema
- **Editor JSON** — Edição direta JSON com validação
- **Multi-idioma** — English, 简体中文, 日本語, Português, Deutsch
- **Atualização Online** — Verificar novas versões e atualizar
- **Logs do Sistema** — Visualizar logs do PicoClaw em tempo real
- **Design Responsivo** — Desktop e mobile

## 📋 Requisitos

| Requisito | Detalhes |
|---|---|
| **OpenWrt** | 24.10 / 25.xx com LuCI |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) instalado e em execução |

## 🚀 Instalação

Copie os arquivos LuCI para o roteador OpenWrt:

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Limpar cache LuCI
rm -rf /tmp/luci-*
```

Acesse: `http://<IP_DO_ROTEADOR>/cgi-bin/luci/admin/services/picoclaw`

## 🛠️ Stack de Tecnologias

| Componente | Tecnologia |
|---|---|
| Backend | Lua (LuCI) |
| Frontend | HTML + CSS + JavaScript (renderizado no servidor) |
| Gerenciador de Serviço | OpenWrt procd (init.d) |

## 📄 Licença

[Licença MIT](LICENSE)

## 🙏 Créditos

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) e [LuCI](https://github.com/openwrt/luci)
