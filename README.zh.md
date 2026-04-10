<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> 的 OpenWrt LuCI 网页管理界面</b><br>
  <sub>全面掌控你的 AI 网关 — 从服务管理到硬件控制</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-21.02%20%7C%2022.03%20%7C%2023.05%20%7C%2024.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
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

## 截图预览

| 仪表盘 | 配置编辑 |
|:---:|:---:|
| ![主界面](Screenshots/screenshot_main.png) | ![配置编辑](Screenshots/screenshot_config.png) |

| 硬件控制 | 移动端 |
|:---:|:---:|
| ![硬件控制](Screenshots/screenshot_hardware.png) | ![手机端](Screenshots/screenshot_mobile.png) |

## 功能特性

### 服务管理
- **仪表盘** — 实时显示服务状态、PID、内存占用、端口监听
- **服务控制** — 一键启动 / 停止（含 kill-9 强停策略）/ 重启 PicoClaw
- **开机自启开关** — 网页上控制开机自动启动
- **系统日志** — 实时查看和刷新 PicoClaw 日志
- **在线更新** — 检查新版本并从界面直接更新

### 配置管理
- **通道管理** — 查看已连接的通道（飞书、Telegram、Discord、微信等）
- **微信状态检测** — 扫码接入后自动识别微信个人号会话状态
- **表单化配置编辑** — 直观的 UI 配置 AI 模型、供应商和系统设置
- **搜索引擎配置** — 配置网络搜索服务商（智谱搜索、百度、DuckDuckGo、Brave、Tavily、Perplexity、SearXNG），含 GFW 提示
- **JSON 配置编辑** — 直接编辑 JSON，支持验证

### 硬件与扩展
- **硬件控制** — 系统信息、USB 设备、GPIO 引脚（支持高低电平切换）
- **技能管理** — 在界面中查看、删除和导入 PicoClaw 技能
- **定时任务** — 一目了然查看已配置的 Cron 任务

### 内置预设技能
附带三个开箱即用的 AI 技能，在管理页面一键安装：

| 技能 | 说明 |
|:---|:---|
| **系统诊断** | 自动网络/DNS/网关检测、日志分析、故障排查 |
| **配置备份** | 交互式备份流程，支持环境检查、选项菜单、恢复操作 |
| **智能安装** | 通过 opkg/is-opkg 智能搜索应用，支持模糊描述匹配 |

> 这些技能是纯知识提示文件（SKILL.md）— 增强 PicoClaw 的 AI 响应能力，无需修改 PicoClaw 本体。

## 系统要求

| 要求 | 说明 |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+ / 22.03 / 23.05 / 24.10 / 25.xx / iStoreOS（需安装 LuCI） |
| **PicoClaw** | **必须先安装！** 本界面不包含 PicoClaw 主程序 |
| **架构** | all（纯 Lua，不限架构：x86-64 / aarch64 / armv7 / mipsle / riscv64 等） |

> ⚠️ **重要提醒**：`luci-app-picoclaw` 只是 PicoClaw 的**网页管理界面**，**不是** PicoClaw 本身。如果你还没安装 PicoClaw 主程序，请先完成下方「第一步」。

## 安装

### 第一步：安装 PicoClaw 主程序（必做！）

前往 [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) 下载对应架构的版本：

```bash
# 以 x86-64 为例（根据实际版本替换）
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw

# 验证安装
picoclaw --version
```

### 第二步：安装 LuCI 管理界面

#### 方式一：iStore 商店安装（推荐）

在路由器的 iStore 商店中搜索 `picoclaw` → 直接安装。
> v1.0.9 已合入 iStore 官方源，商店中可直接搜索到。

#### 方式二：下载 IPK 手动安装

从 [Releases](https://github.com/GennKann/luci-app-picoclaw/releases/latest) 下载最新 IPK：

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*   # 清理 LuCI 缓存
```

#### 方式三：手动复制文件

```bash
# 控制器
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua
# 模板
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm
# Init 脚本
cp scripts/picoclaw.init /etc/init.d/picoclaw && chmod +x /etc/init.d/picoclaw
# 清理缓存
rm -rf /tmp/luci-*
```

安装完成后建议在 LuCI 页面点一次「重启服务」，确保新的 init.d 脚本生效：
> LuCI → 服务 → PicoClaw → 点击「重启」

访问地址：`http://<路由器IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 模型配置方法

PicoClaw 支持多家 AI 供应商。你可以通过 LuCI 网页界面（配置编辑标签页）或直接编辑 JSON 配置来设置模型。

### 通过 LuCI 网页界面（推荐）

1. 进入 **LuCI → 服务 → PicoClaw → 配置编辑**
2. 在 **模型列表** 区域，点击 **添加模型**
3. 填写以下字段：
   - **模型名称** — 唯一标识符（如 `my-glm4`、`my-deepseek`）
   - **供应商** — 从下拉列表选择（智谱、OpenRouter、DeepSeek、通义、OpenAI、Anthropic 等）
   - **模型** — 带协议前缀的模型标识（如 `zhipu://glm-4.5-air`、`deepseek://deepseek-chat`）
   - **API 地址** — 供应商 API 端点（根据供应商自动填充）
   - **API Key** — 你的 API 密钥（安全存储）
   - **启用** — 开关切换
4. 从下拉菜单设置 **默认模型**
5. 点击 **保存** 生效

### 支持的供应商

| 供应商 | 模型前缀 | API 地址 | 备注 |
|---|---|---|---|
| 智谱 (Zhipu) | `zhipu://` | `https://open.bigmodel.cn/api/paas/v4` | 国内可用，推荐 |
| DeepSeek | `deepseek://` | `https://api.deepseek.com` | 国内可用 |
| 通义千问 (Qwen) | `dashscope://` | `https://dashscope.aliyuncs.com/compatible-mode/v1` | 国内可用 |
| OpenAI | `openai://` | `https://api.openai.com/v1` | 国内需代理 |
| Anthropic | `anthropic://` | `https://api.anthropic.com` | 国内需代理 |
| OpenRouter | `openrouter://` | `https://openrouter.ai/api/v1` | 聚合平台，国内需代理 |

### 通过 JSON 配置（高级）

编辑 `/root/.picoclaw/config.json`：

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

> ⚠️ `config.json` 中的 API Key 以 SecureString 字符数组格式存储（`[NOT_HERE]` 占位符），真实密钥存储在 `/root/.picoclaw/.security.yml` 中。通过 LuCI 编辑时会自动保留安全格式。

### API Key 安全机制

PicoClaw 采用双文件安全存储体系：
- `config.json` — 包含 `[NOT_HERE]` 占位符
- `.security.yml` — 存储真实 API Key，含 provider/model 元数据

**请勿手动修改 config.json 中的 API Key。** 始终通过 LuCI 界面管理，或直接编辑 `.security.yml`。

## 🔍 搜索引擎配置

PicoClaw 可使用网络搜索获取实时信息。在 **配置编辑** 标签页中配置搜索引擎。

| 引擎 | 国内可用 | 备注 |
|---|---|---|
| **智谱搜索** (GLM Search) | ✅ | 国内用户推荐 |
| **百度搜索** | ✅ | 国内备选 |
| **DuckDuckGo** | ❌ | 被 GFW 屏蔽 |
| **Brave Search** | ❌ | 被 GFW 屏蔽 |
| **Tavily** | ❌ | 需 API Key，被 GFW 屏蔽 |
| **Perplexity** | ❌ | 被 GFW 屏蔽 |
| **SearXNG** | ⚠️ | 自建实例，取决于部署位置 |

> 💡 **国内用户提示**：启用 `glm_search` 或 `baidu_search`，禁用 DuckDuckGo/Brave，避免因 GFW 导致搜索超时。

## 常见问题

### 安装了 luci-app-picoclaw 但打不开 / 报错？
说明路由器上还没有安装 **PicoClaw 主程序**。请先完成「第一步」安装 PicoClaw，然后刷新页面。

### 点击停止按钮后进程没有真正停止？
这是 v1.0.7 及以下版本的已知问题 —— procd 会自动复活被 kill 的进程。**v1.0.8 已修复**：停止功能现在使用三步策略（优雅停止 → pidof 检查 + kill-9 强杀 → 等待清理）。如果你用的是旧版，请升级到 v1.0.8。

### 刷新日志提示 "Invalid CSRF token"？
这是 v1.0.7 及以下版本的已知问题。**v1.0.8 已修复** —— 所有表单提交均正确携带 CSRF token。升级即可解决。

### iStore 商店里搜不到 picoclaw？
请在路由器终端运行 `opkg update` 刷新软件源，或直接从 GitHub Releases 下载 IPK 安装。

### 页面顶部有橙色安装横幅是怎么回事？
说明已安装 `luci-app-picoclaw` 但尚未安装 PicoClaw 主程序，点击横幅即可一键安装（自动检测架构）。

### PicoClaw 问天气/新闻时说"没有权限访问网络"？
搜索引擎配置有误。DuckDuckGo、Brave、Google 在国内被 GFW 屏蔽。在「配置编辑」标签页中将搜索引擎切换为**智谱搜索**或**百度搜索**，然后重启 PicoClaw。

### 如何添加自定义 AI 模型？
进入「配置编辑」标签页 → 模型列表区域 → 点击「添加模型」，填写供应商、模型名称、API Key，点击保存即可。新模型会出现在默认模型下拉列表中。

### config.json 中 API Key 显示为 `[NOT_HERE]`？
这是正常的 —— PicoClaw 使用安全存储系统，真实密钥在 `.security.yml` 中。请勿手动替换 `config.json` 中的 `[NOT_HERE]`，应通过 LuCI 界面管理密钥。

## 项目结构

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCI 控制器（后端逻辑）
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCI 模板（HTML/CSS/JS）
├── skills/
│   ├── openwrt-diagnostics/
│   ├── openwrt-backup/
│   └── openwrt-app-installer/
├── scripts/
│   └── picoclaw.init              # OpenWrt init.d 服务脚本
├── install.py                     # 交互式安装助手
├── Screenshots/
└── README*.md                     # 多语言文档
```

## 技术栈

| 组件 | 技术 |
|---|---|
| 后端 | Lua (LuCI)，使用 `luci.jsonc` |
| 前端 | HTML + CSS + JavaScript（服务端渲染） |
| 服务管理 | OpenWrt procd (init.d)，含 kill-9 安全回退 |
| 安全 | 所有表单均带 CSRF token 保护 |

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)。

## 许可证

[MIT 许可证](LICENSE)

## 鸣谢

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) 和 [LuCI](https://github.com/openwrt/luci)
