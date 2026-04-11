<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Interface Web LuCI para <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> no OpenWrt</b><br>
  <sub>Gerenciamento de serviço · Configuração de modelo · Controle de hardware</sub>
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
  Português
</p>

---

## 📸 Capturas de Tela

| Painel | Editor de Config |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| Controle de Hardware | Visualização Móvel |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Funcionalidades

- **Controle de Serviço** — Iniciar / Parar / Reiniciar, auto-inicialização, logs em tempo real
- **Gerenciamento de Canais** — Feishu, Telegram, Discord, detecção de status WeChat
- **Configuração de Modelo** — Editor de formulário com presets de provedores (Zhipu, DeepSeek, Qwen, OpenAI etc.), armazenamento seguro de API Key
- **Configuração de Motor de Busca** — GLM Search, Baidu, DuckDuckGo, Brave, Tavily, Perplexity, SearXNG (com avisos GFW)
- **Controle de Hardware** — Informações do sistema, dispositivos USB, toggle GPIO
- **Gerenciamento de Skills** — Visualizar, deletar, importar; 3 presets integrados (diagnóstico, backup, instalador de apps)
- **Editor JSON** — Edição direta de configuração com validação

## 📋 Requisitos

| | Detalhes |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ (com LuCI) |
| **PicoClaw** | Deve ser instalado primeiro — esta é apenas a interface Web |
| **Arquitetura** | all (Lua puro) |

## 🚀 Instalação

### Passo 1: Instalar PicoClaw

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version
```

### Passo 2: Instalar Interface LuCI

**iStore** (recomendado) — Pesquisar `picoclaw` → Instalar

**Ou baixar IPK:**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*
```

Acesso: `http://<IP_DO_ROTEADOR>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Configuração de Modelo

Na aba **Editor de Config** → seção **Lista de Modelos**:

1. Clique em **Adicionar Modelo** (ou use um preset de provedor)
2. Preencha: nome do modelo, provedor, ID do modelo, API base (auto-preenchido), API key
3. Defina o **Modelo Padrão** no dropdown
4. Clique em **Salvar**

**Provedores suportados:** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> API keys são armazenadas com segurança via sistema dual do PicoClaw (`config.json` placeholder + `.security.yml` keys reais).

## 🔍 Motor de Busca

| Motor | China | |
|---|:---:|---|
| GLM Search | ✅ | Recomendado |
| Baidu | ✅ | Alternativa |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | Bloqueado pelo GFW |
| SearXNG | ⚠️ | Self-hosted, depende da instância |

## ❓ FAQ

| Pergunta | Resposta |
|---|---|
| Página não carrega? | Instale o binário PicoClaw primeiro (Passo 1) |
| "Sem permissão para acessar a internet"? | Mude o motor de busca para GLM Search ou Baidu |
| Não encontra no iStore? | Execute `opkg update` ou baixe o IPK do Releases |
| API keys mostram `[NOT_HERE]`? | Normal — keys reais estão em `.security.yml`, gerencie via LuCI UI |

## Registro de Mudanças

Veja [CHANGELOG.md](CHANGELOG.md).

## 📄 Licença

[Licença MIT](LICENSE)
