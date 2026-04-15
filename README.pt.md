<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Transforme seu roteador em um assistente de IA — gerencie o <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> pelo navegador</b><br>
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

## O que é isso?

**[PicoClaw](https://github.com/sipeed/picoclaw)** é um assistente de IA que roda no seu roteador. Ele se conecta a grandes modelos de linguagem (como ChatGPT, DeepSeek, GLM, etc.) e permite conversar via Feishu, Telegram, Discord, WeChat e mais.

Porém, o PicoClaw em si não tem interface gráfica — a configuração precisa ser feita via linha de comando ou editando manualmente arquivos JSON.

**Este projeto adiciona uma interface web de gerenciamento** (um plugin LuCI) para o PicoClaw, permitindo fazer tudo no navegador: iniciar/parar o serviço, trocar modelos de IA, configurar API keys, gerenciar motores de busca e mais — sem linha de comando.

> **LuCI** é o framework de interface web usado por roteadores OpenWrt. Quando você abre a página de administração do roteador (ex: 192.168.1.1), isso é LuCI.

## 📸 Capturas de Tela

| Painel | Editor de Config |
|:---:|:---:|
| ![Dashboard](Screenshots/screenshot_main.png) | ![Config](Screenshots/screenshot_config.png) |

| Controle de Hardware | Visualização Móvel |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## ✨ Funcionalidades

- **Controle de Serviço** — Iniciar / Parar / Reiniciar com um clique, auto-inicialização, logs em tempo real
- **Gerenciamento de Canais** — Status de conexão para Feishu, Telegram, Discord, WeChat etc.
- **Configuração de Modelo** — Editor visual de formulário para modelos de IA, com presets de provedores (Zhipu, DeepSeek, Qwen, OpenAI etc.) — basta preencher sua API key
- **Configuração de Motor de Busca** — A IA pode pesquisar na web para responder. Suporta GLM Search, Baidu, DuckDuckGo etc. (com dicas de disponibilidade na China)
- **Controle de Hardware** — Informações do sistema, dispositivos USB, toggle GPIO
- **Gerenciamento de Skills** — Visualizar, deletar, importar skills do PicoClaw; 3 presets integrados (diagnóstico, backup, instalador de apps)
- **Editor JSON** — Edição direta de configuração para usuários avançados

## 📋 Requisitos

| | Detalhes |
|---|---|
| **Sistema do Roteador** | OpenWrt 21.02+ ou iStoreOS (com interface LuCI) |
| **Binário PicoClaw** | Deve ser instalado primeiro — este plugin é apenas a interface Web, não o PicoClaw em si |
| **Arquitetura** | Qualquer uma (Lua puro, funciona em todas as arquiteturas) |

## 🚀 Instalação

### Passo 1: Instalar PicoClaw

PicoClaw é o programa principal do assistente de IA — você precisa instalá-lo primeiro. Conecte-se ao roteador via SSH e execute:

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version   # Deve exibir o número da versão
```

> ⚠️ O link acima é para x86_64. Se seu roteador usa ARM (a maioria dos roteadores Xiaomi, TP-Link), baixe o binário correto em [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases).

### Passo 2: Instalar Interface LuCI

**Opção A: iStore** (recomendado, mais fácil)

Abra o iStore no roteador → pesquise `picoclaw` → clique em Instalar

**Opção B: Instalar IPK via linha de comando**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*   # Limpar cache do LuCI
```

Após a instalação, acesse no navegador: `http://<IP_DO_ROTEADOR>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Configuração de Modelo

O PicoClaw precisa se conectar a um grande modelo de linguagem para funcionar. Pense nele como um "cliente" — ele não inclui IA em si, mas chama serviços de IA via suas APIs. Você precisa fornecer uma **API Key** (como uma senha) para que o PicoClaw possa acessar o serviço.

**Como configurar:**

1. Vá para a aba **Editor de Config** → encontre a seção **Lista de Modelos**
2. Clique em um botão de preset de provedor (ex: "Zhipu GLM", "DeepSeek") — a URL da API base será preenchida automaticamente
3. Digite sua **API Key** (obtida registrando-se no site do provedor)
4. Selecione um **Modelo Padrão** no dropdown
5. Clique em **Salvar**

**Provedores suportados:** Zhipu · DeepSeek · Qwen · OpenAI · Anthropic · OpenRouter · Ollama

> 💡 **Não tem uma API Key?** A maioria dos provedores oferece créditos gratuitos para experimentar:
> - [Zhipu (智谱)](https://open.bigmodel.cn/) — Baseado na China, créditos grátis no registro
> - [DeepSeek](https://platform.deepseek.com/) — Baseado na China, créditos grátis no registro
> - [OpenRouter](https://openrouter.ai/) — Agrega múltiplos modelos

> 🔒 API keys são armazenadas com segurança via sistema dual do PicoClaw (`config.json` armazena apenas um placeholder, keys reais em `.security.yml`), nunca expostas em texto plano.

## 🔍 Motor de Busca

O PicoClaw pode pesquisar na web para responder perguntas. Para usuários na China, recomendamos GLM Search ou Baidu:

| Motor | China | Observações |
|---|:---:|---|
| GLM Search | ✅ | Recomendado, funciona na China |
| Baidu | ✅ | Alternativa |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | Bloqueado pelo GFW, funciona apenas no exterior |
| SearXNG | ⚠️ | Self-hosted, depende de onde está implantado |

## ❓ FAQ

| Pergunta | Resposta |
|---|---|
| Página não carrega após instalar? | Instale o binário PicoClaw primeiro (Passo 1) — este plugin é apenas a interface Web |
| IA diz "sem permissão para acessar a internet"? | Motor de busca bloqueado — mude para GLM Search ou Baidu |
| Não encontra no iStore? | Execute `opkg update` ou baixe o IPK do Releases |
| Campo de API key mostra `[NOT_HERE]`? | Normal — keys reais estão em `.security.yml`, gerencie pela LuCI UI |
| O que é uma API Key? | É como uma senha para chamar serviços de IA. Registre-se no site do provedor — a maioria oferece créditos grátis |
| Como verificar a arquitetura do roteador? | Conecte via SSH e execute `uname -m`. Valores comuns: x86_64, aarch64, mipsel |

## Registro de Mudanças

Veja [CHANGELOG.md](CHANGELOG.md).

## 📄 Licença

[Licença MIT](LICENSE)

---

Support
-------

Se você gosta deste projeto, pode dar uma estrela ao repositório ou me pagar um café :)

[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/gennkann)

<details>
<summary>🇨🇳 WeChat Pay</summary>
<img src="Images/wechat_pay.jpg" width="200" alt="WeChat Pay" />
</details>
