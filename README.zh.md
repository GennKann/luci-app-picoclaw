<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>让你的路由器变成 AI 助手 — 在浏览器里管理 PicoClaw</b><br>
  <sub>服务管理 · 模型配置 · 硬件控制</sub>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/OpenWrt-24.10%20%7C%2025.xx%20%7C%20iStoreOS-blue?logo=openwrt" alt="OpenWrt">
  <img src="https://img.shields.io/badge/Version-1.1.3-brightgreen" alt="Version">
  <img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License">
</p>

<p align="center">
  <a href="README.md">English</a> ·
  简体中文 ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.pt.md">Português</a>
</p>

---

## 这是什么？

**[PicoClaw](https://github.com/sipeed/picoclaw)** 是一个运行在路由器上的 AI 助手程序，它可以让你的路由器接入大语言模型（如智谱 GLM、DeepSeek、ChatGPT 等），并通过飞书、Telegram、Discord、微信等通道与你对话。

但 PicoClaw 本身没有图形界面，只能通过命令行或手动编辑 JSON 文件来配置，对普通用户不太友好。

**本项目就是给 PicoClaw 加一个网页管理界面**（LuCI 插件），让你在浏览器里就能完成所有操作——启动服务、切换模型、配置 API Key、管理搜索引擎等，不需要敲命令行。

> **LuCI** 是 OpenWrt 路由器的 Web 管理界面框架，你平时进路由器后台（如 192.168.1.1）看到的就是 LuCI。

## 📸 截图

| 仪表盘 | 配置编辑 |
|:---:|:---:|
| ![主界面](Screenshots/screenshot_main.png) | ![配置](Screenshots/screenshot_config.png) |

| 硬件控制 | 移动端 |
|:---:|:---:|
| ![硬件](Screenshots/screenshot_hardware.png) | ![手机](Screenshots/screenshot_mobile.png) |

## ✨ 功能

- **服务控制** — 一键启动 / 停止 / 重启 PicoClaw，设置开机自启，查看实时运行日志
- **通道管理** — 查看飞书、Telegram、Discord、微信等通道的连接状态
- **模型配置** — 可视化表单配置 AI 模型，内置供应商预设（智谱、DeepSeek、通义、OpenAI 等），填入 API Key 即可使用
- **搜索引擎配置** — 让 AI 能联网搜索信息，支持智谱搜索、百度、DuckDuckGo 等（含国内可用性提示）
- **硬件控制** — 查看路由器系统信息、USB 设备，控制 GPIO 开关
- **技能管理** — 查看、删除、导入 PicoClaw 技能；内置 3 个预设（系统诊断、配置备份、智能安装）
- **JSON 编辑器** — 直接编辑底层配置文件，适合高级用户

## 📋 系统要求

| | 说明 |
|---|---|
| **路由器系统** | OpenWrt 21.02+ 或 iStoreOS（需有 LuCI 界面） |
| **PicoClaw 主程序** | 必须先安装 — 本插件只是网页管理界面，不包含 PicoClaw 本体 |
| **路由器架构** | 不限（纯 Lua，所有架构通用） |

## 🚀 安装

### 第一步：安装 PicoClaw 主程序

PicoClaw 是 AI 助手的核心程序，需要先装好它。通过 SSH 登录路由器，执行：

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version   # 确认安装成功，应显示版本号
```

> ⚠️ 上面是 x86_64 架构的下载链接。如果你的路由器是 ARM 架构（如大多数小米、TP-Link 路由器），请到 [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases) 下载对应架构的版本。

### 第二步：安装 LuCI 管理界面

**方式一：iStore 商店**（推荐，最简单）

在路由器后台打开 iStore → 搜索 `picoclaw` → 点击安装

**方式二：命令行安装 IPK**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*   # 清除 LuCI 缓存
```

安装完成后，打开浏览器访问：`http://<路由器IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 模型配置

PicoClaw 需要接入大语言模型才能工作。你可以把它理解为一个"客户端"——它本身不包含 AI，而是调用各家 AI 服务的接口。你需要提供 **API Key**（类似密码），让 PicoClaw 有权调用对应的服务。

**配置步骤：**

1. 在**配置编辑**标签页 → 找到**模型列表**区域
2. 点击供应商预设按钮（如"智谱 GLM"、"DeepSeek"），会自动填入 API 地址
3. 填入你的 **API Key**（在各 AI 供应商官网注册后获取）
4. 从下拉菜单选择**默认模型**
5. 点击**保存**

**支持供应商：** 智谱 · DeepSeek · 通义千问 · OpenAI · Anthropic · OpenRouter · Ollama

> 💡 **没有 API Key？** 大部分供应商都提供免费额度，注册即可试用：
> - [智谱开放平台](https://open.bigmodel.cn/) — 国内，注册送免费额度
> - [DeepSeek](https://platform.deepseek.com/) — 国内，注册送免费额度
> - [OpenRouter](https://openrouter.ai/) — 海外，聚合多家模型

> 🔒 API Key 通过 PicoClaw 双文件安全体系存储（`config.json` 只存占位符，真实密钥在 `.security.yml` 中），不会明文暴露。

## 🔍 搜索引擎

PicoClaw 可以联网搜索信息来回答问题。国内用户建议选择智谱搜索或百度：

| 引擎 | 国内可用 | 说明 |
|---|:---:|---|
| 智谱搜索 | ✅ | 推荐，国内直连 |
| 百度 | ✅ | 备选 |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | 被 GFW 屏蔽，海外可用 |
| SearXNG | ⚠️ | 需自己搭建，取决于部署位置 |

## ❓ 常见问题

| 问题 | 解答 |
|---|---|
| 安装后页面打不开？ | 需要先安装 PicoClaw 主程序（见第一步），本插件只是管理界面 |
| AI 回复"没有权限访问网络"？ | 搜索引擎被墙了，切换为智谱搜索或百度 |
| iStore 里搜不到？ | 运行 `opkg update` 刷新软件源，或直接下载 IPK 安装 |
| API Key 那栏显示 `[NOT_HERE]`？ | 这是正常的，真实密钥存在 `.security.yml` 里，通过 LuCI 界面管理即可 |
| 不清楚什么是 API Key？ | 简单说就是你调用 AI 服务的密码，去对应供应商官网注册获取，大部分有免费额度 |
| 路由器架构怎么看？ | SSH 登录后执行 `uname -m`，常见有 x86_64、aarch64、mipsel |

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)。

## 📜 开源协议

本项目遵循 **MIT License**，可自由使用、修改与分发，但请保留作者署名。

欢迎提交 Issue / Pull Request 一起完善项目 💡

---

Support
-------

如果你喜欢这个项目，可以给仓库点个 Star，或者请我喝一杯咖啡 :)

[![Ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/gennkann)

<details>
<summary>🇨🇳 微信赞赏</summary>
<img src="Images/wechat_pay.jpg" width="200" alt="微信收款码" />
</details>
