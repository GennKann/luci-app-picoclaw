<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b>PicoClaw 的 OpenWrt LuCI 网页管理界面</b><br>
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

## 📸 截图

| 仪表盘 | 配置编辑 |
|:---:|:---:|
| ![主界面](Screenshots/screenshot_main.png) | ![配置](Screenshots/screenshot_config.png) |

| 硬件控制 | 移动端 |
|:---:|:---:|
| ![硬件](Screenshots/screenshot_hardware.png) | ![手机](Screenshots/screenshot_mobile.png) |

## ✨ 功能

- **服务控制** — 启动 / 停止 / 重启，开机自启开关，实时日志
- **通道管理** — 飞书、Telegram、Discord、微信状态检测
- **模型配置** — 表单化编辑器，内置供应商预设（智谱、DeepSeek、通义、OpenAI 等），API Key 安全存储
- **搜索引擎配置** — 智谱搜索、百度、DuckDuckGo、Brave、Tavily、Perplexity、SearXNG（含 GFW 提示）
- **硬件控制** — 系统信息、USB 设备、GPIO 切换
- **技能管理** — 查看、删除、导入技能；3 个内置预设（系统诊断、配置备份、智能安装）
- **JSON 编辑器** — 直接编辑配置，支持验证

## 📋 系统要求

| | 说明 |
|---|---|
| **OpenWrt / iStoreOS** | 21.02+（需安装 LuCI） |
| **PicoClaw** | 必须先安装 — 本界面只是 Web 管理页 |
| **架构** | all（纯 Lua，不限架构） |

## 🚀 安装

### 第一步：安装 PicoClaw 主程序

```bash
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.5/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw && chmod +x /usr/bin/picoclaw
picoclaw --version
```

### 第二步：安装 LuCI 管理界面

**iStore 商店**（推荐）— 搜索 `picoclaw` → 安装

**或下载 IPK：**

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.1.3-1_all.ipk
opkg install luci-app-picoclaw_1.1.3-1_all.ipk
rm -rf /tmp/luci-*
```

访问：`http://<路由器IP>/cgi-bin/luci/admin/services/picoclaw`

## 🤖 模型配置

在**配置编辑**标签页 → **模型列表**区域：

1. 点击**添加模型**（或使用供应商预设按钮）
2. 填写：模型名称、供应商、模型 ID、API 地址（自动填充）、API Key
3. 从下拉菜单设置**默认模型**
4. 点击**保存**

**支持供应商：** 智谱 · DeepSeek · 通义千问 · OpenAI · Anthropic · OpenRouter · Ollama

> API Key 通过 PicoClaw 双文件安全体系存储（`config.json` 占位符 + `.security.yml` 真实密钥）。

## 🔍 搜索引擎

| 引擎 | 国内 | |
|---|:---:|---|
| 智谱搜索 | ✅ | 推荐 |
| 百度 | ✅ | 备选 |
| DuckDuckGo / Brave / Tavily / Perplexity | ❌ | 被 GFW 屏蔽 |
| SearXNG | ⚠️ | 自建实例，取决于部署位置 |

## ❓ 常见问题

| 问题 | 解答 |
|---|---|
| 页面打不开？ | 先安装 PicoClaw 主程序（第一步） |
| 提示"没有权限访问网络"？ | 搜索引擎切换为智谱搜索或百度 |
| iStore 搜不到？ | 运行 `opkg update` 或从 Releases 下载 IPK |
| API Key 显示 `[NOT_HERE]`？ | 正常 — 真实密钥在 `.security.yml`，通过 LuCI 管理 |

## 更新日志

详见 [CHANGELOG.md](CHANGELOG.md)。

## 📄 许可证

[MIT 许可证](LICENSE)
