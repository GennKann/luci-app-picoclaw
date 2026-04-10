<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>Interface web LuCI para gerenciar o <a href="https://github.com/sipeed/picoclaw">PicoClaw</a> no OpenWrt</b><br>
  <sub>Controle total do seu AI gateway — do gerenciamento de serviço ao hardware</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-21.02%20%7C%2022.03%20%7C%2023.05%20%7C%2024.10%20%7C%2025.xx-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/LuCI-Web%20Interface-green?logo=lua" alt="LuCI">
  <img src="https://img.shields.io/badge/i18n-5%20Languages-purple" alt="i18n">
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

## Capturas de Tela

| Painel | Editor de Configuração |
|:---:|:---:|
| ![Painel](Screenshots/screenshot_main.png) | ![Configuração](Screenshots/screenshot_config.png) |

| Controle de Hardware | Visualização Mobile |
|:---:|:---:|
| ![Hardware](Screenshots/screenshot_hardware.png) | ![Mobile](Screenshots/screenshot_mobile.png) |

## Funcionalidades

### Gerenciamento de Serviço
- **Painel** — Status do serviço em tempo real, PID, uso de memória e monitoramento de porta
- **Controle de Serviço** — Iniciar / Parar (com kill-9 forçado) / Reiniciar o PicoClaw
- **Alternar Auto-início** — Ativar/desativar inicialização automática
- **Logs do Sistema** — Visualizar e atualizar logs do PicoClaw em tempo real
- **Atualização Online** — Verificar novas versões e atualizar pela UI

### Configuração
- **Gerenciamento de Canais** — Visualizar canais conectados (Feishu, Telegram, Discord, WeChat, etc.)
- **Detecção de Status WeChat** — Detecta automaticamente a sessão da conta pessoal WeChat após scan de QR Code
- **Editor de Configuração** — UI para modelo AI, provedores e configurações do sistema
- **Configuração de Motor de Busca** — Configurar provedores de busca web (GLM Search, Baidu, DuckDuckGo, Brave, Tavily, Perplexity, SearXNG) com dicas GFW para usuários na China
- **Editor JSON** — Edição direta JSON com validação

### Hardware e Extensões
- **Controle de Hardware** — Informações do sistema, dispositivos USB, pinos GPIO (com alternância H/L)
- **Gerenciamento de Skills** — Visualizar, excluir e importar skills do PicoClaw diretamente pela UI
- **Tarefas Agendadas** — Visualizar jobs Cron de forma rápida

### Skills Preset Integradas

Três skills AI prontas para uso são incluídas — instale com um clique na página de gerenciamento:

| Skill | Descrição |
|:---|:---|
| **Diagnóstico do Sistema** | Verificação automática de rede/DNS/gateway, análise de logs, solução de problemas |
| **Backup de Configuração** | Fluxo de backup interativo com verificação de ambiente e menu de opções |
| **Instalador de Apps** | Busca inteligente de apps via opkg/is-opkg com correspondência fuzzy de descrição |

> Estas skills são prompts de conhecimento puro (SKILL.md) — elas melhoram as respostas AI do PicoClaw sem modificar o binário do PicoClaw.

## Requisitos

| Requisito | Detalhes |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ / 22.03 / 23.05 / 24.10 / 25.xx / iStoreOS (com LuCI) |
| **PicoClaw** | [sipeed/picoclaw](https://github.com/sipeed/picoclaw) instalado e em execução |
| **Arquitetura** | all (Lua pura: x86-64 / aarch64 / armv7 / mipsle / riscv64, etc.) |

> ⚠️ **Importante**: `luci-app-picoclaw` é apenas a **interface web** para PicoClaw — não é o PicoClaw em si. Se você ainda não instalou o binário PicoClaw, complete o "Passo 1" abaixo primeiro.

## Instalação

### Passo 1: Instalar PicoClaw (Obrigatório!)

Baixe de [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) compatível com sua arquitetura:

```bash
# Exemplo para x86-64 (substitua a versão conforme necessário)
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw

# Verificar instalação
picoclaw --version
```

### Passo 2: Instalar Interface LuCI (luci-app-picoclaw)

#### Opção 1: iStore App Store (Recomendado)

Pesquise `picoclaw` no app iStore do seu roteador → instale diretamente.
> Disponível desde v1.0.8 (PR mesclado na fonte oficial iStore).

#### Opção 2: Baixar IPK

Baixe de [Releases](https://github.com/GennKann/luci-app-picoclaw/releases/latest):

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*   # Limpar cache LuCI
```

#### Opão 3: Cópia Manual de Arquivos

```bash
# Controller
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua
# Template
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm
# Script Init
cp scripts/picoclaw.init /etc/init.d/picoclaw && chmod +x /etc/init.d/picoclaw
# Limpar cache
rm -rf /tmp/luci-*
```

Após a instalação, recomenda-se clicar "Reiniciar" uma vez na página LuCI para garantir que o novo init.d script entre em vigor:
> LuCI → Serviços → PicoClaw → Clique **Reiniciar**

Acesse: `http://<IP_DO_ROTEADOR>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 Configuração de Modelo

PicoClaw suporta múltiplos provedores de AI. Você pode configurar modelos via interface web LuCI (aba Editor de Configuração) ou editando o JSON diretamente.

### Via LuCI Web UI (Recomendado)

1. Navegue até **LuCI → Serviços → PicoClaw → Editor de Configuração**
2. Na seção **Lista de Modelos**, clique em **Adicionar Modelo**
3. Preencha os campos:
   - **Nome do Modelo** — Identificador único (ex: `my-glm4`, `my-deepseek`)
   - **Provedor** — Selecione no dropdown (Zhipu, OpenRouter, DeepSeek, Qwen, OpenAI, Anthropic, etc.)
   - **Modelo** — Identificador do modelo com prefixo de protocolo (ex: `zhipu://glm-4.5-air`, `deepseek://deepseek-chat`)
   - **API Base** — Endpoint da API do provedor (preenchido automaticamente)
   - **API Key** — Sua chave de API (armazenada com segurança)
   - **Ativado** — Alternar ligar/desligar
4. Selecione o **Modelo Padrão** no dropdown
5. Clique em **Salvar** para aplicar

### Provedores Suportados

| Provedor | Prefixo do Modelo | API Base | Observações |
|---|---|---|---|
| Zhipu (智谱) | `zhipu://` | `https://open.bigmodel.cn/api/paas/v4` | Disponível na China, recomendado |
| DeepSeek | `deepseek://` | `https://api.deepseek.com` | Disponível na China |
| Qwen (通义) | `dashscope://` | `https://dashscope.aliyuncs.com/compatible-mode/v1` | Disponível na China |
| OpenAI | `openai://` | `https://api.openai.com/v1` | Requer proxy na China |
| Anthropic | `anthropic://` | `https://api.anthropic.com` | Requer proxy na China |
| OpenRouter | `openrouter://` | `https://openrouter.ai/api/v1` | Agregador, requer proxy na China |

### Via Config JSON (Avançado)

Edite `/root/.picoclaw/config.json`:

```json
{
  "model_list": [
    {
      "model_name": "glm-4.5-air",
      "model": "zhipu://glm-4.5-air",
      "api_base": "https://open.bigmodel.cn/api/paas/v4",
      "api_keys": [["[","N","O","T","_","H","E","R","E","]"]],
      "enabled": true
    }
  ]
}
```

> ⚠️ As chaves API em `config.json` são armazenadas como array de caracteres SecureString (placeholder `[NOT_HERE]`). As chaves reais estão em `/root/.picoclaw/.security.yml`. Ao editar via LuCI, o formato seguro é preservado automaticamente.

## 🔍 Configuração de Motor de Busca

PicoClaw pode usar busca web para fornecer informações atualizadas. Configure motores de busca na aba **Editor de Configuração**.

| Motor | Disponível na China | Observações |
|---|---|---|
| **GLM Search** (智谱搜索) | ✅ | Recomendado para usuários na China |
| **Baidu Search** | ✅ | Alternativa para usuários na China |
| **DuckDuckGo** | ❌ | Bloqueado pelo GFW |
| **Brave Search** | ❌ | Bloqueado pelo GFW |
| **Tavily** | ❌ | Requer API Key, bloqueado pelo GFW |
| **Perplexity** | ❌ | Bloqueado pelo GFW |
| **SearXNG** | ⚠️ | Auto-hospedado, depende da localização da instância |

## FAQ

### Instalei luci-app-picoclaw mas a página não carrega?
O **binário PicoClaw** não está instalado. Complete o "Passo 1" acima e recarregue a página.

### O botão Parar não realmente para o gateway?
Problema conhecido em versões <= 1.07 onde o prodc reativava o processo automaticamente. **Corrigido em v1.0.8** — A função parar agora usa estratégia de 3 etapas (parada suave -> verificação pidof + kill-9 força bruta -> espera limpeza). Atualize para v1.0.8.

### Erro "Invalid CSRF token" ao atualizar logs?
Problema conhecido em versoes <= 1.07. **Corrigido em v1.0.8** — Todos os envios de formulário agora carregam tokens CSRF corretamente.

### Não encontro picoclaw no iStore?
Execute `opkg update` no terminal do roteador ou baixe o IPK diretamente do GitHub Releases.

### O que é o banner laranja de instalação no topo?
Significa que luci-app-picoclaw está instalado mas o binário PicoClaw não. Clique no banner para instalar com um clique (detecta arquitetura automaticamente).

### PicoClaw diz "sem permissão para acessar a internet" ao perguntar sobre tempo/notícias?
O motor de busca está mal configurado. DuckDuckGo, Brave e Google são bloqueados na China pelo GFW. Alterne para **GLM Search** ou **Baidu Search** na aba Editor de Configuração e reinicie o PicoClaw.

### Como adiciono um modelo AI personalizado?
Vá para a aba Editor de Configuração → seção Lista de Modelos → clique "Adicionar Modelo". Preencha provedor, nome do modelo e API Key, depois clique Salvar.

### API keys aparecem como `[NOT_HERE]` no config.json?
Isso é normal — PicoClaw usa um sistema de armazenamento seguro. As chaves reais estão em `.security.yml`. NÃO substitua `[NOT_HERE]` manualmente no config.json; use a UI LuCI para gerenciar.

## Estrutura do Projeto

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # Controlador LuCI (lógica do backend)
│   └── view/
│       └── picoclaw/
│           └── main.htm           # Template LuCI (HTML/CSS/JS)
├── skills/
│   ├── openwrt-diagnostics/
│   ├── openwrt-backup/
│   └── openwrt-app-installer/
├── scripts/
│   └── picoclaw.init              # Script de serviço OpenWrt init.d
├── install.py                     # Assistente de instalação interativo
├── Screenshots/
└── README*.md                     # Documentacao multilingue
```

## Stack de Tecnologias

| Componente | Tecnologia |
|---|---|
| Backend | Lua (LuCI) com luci.jsonc |
| Frontend | HTML + CSS + JavaScript (renderizado no servidor) |
| Gerenciador de Servico | OpenWrt procd (init.d), com kill-9 de seguranca |
| Seguranca | Protecao CSRF token em todos os formularios |

## Historico de Alteracoes

Veja [CHANGELOG.md](CHANGELOG.md).

## Licenca

[Licenca MIT](LICENSE)

## Creditos

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) e [LuCI](https://github.com/openwrt/luci)
