<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> 的 OpenWrt LuCI 网页管理界面</b><br>
  <sub>全面掌控你的 AI 网关 — 从服务管理到硬件控制</sub>
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

## 📸 截图预览

| 仪表盘 | 配置编辑 |
|:---:|:---:|
| ![主界面](Screenshots/screenshot_main.png) | ![配置编辑](Screenshots/screenshot_config.png) |

| 硬件控制 | 移动端 |
|:---:|:---:|
| ![硬件控制](Screenshots/screenshot_hardware.png) | ![手机端](Screenshots/screenshot_mobile.png) |

## ✨ 功能特性

### 服务管理
- **仪表盘** — 实时显示服务状态、PID、内存占用、端口监听
- **服务控制** — 一键启动 / 停止 / 重启 PicoClaw
- **开机自启开关** — 网页上控制开机自动启动
- **系统日志** — 实时查看 PicoClaw 日志
- **在线更新** — 检查新版本并从界面直接更新

### 配置管理
- **通道管理** — 查看已连接的通道（飞书、Telegram、Discord、微信等）
- **表单化配置编辑** — 直观的 UI 配置 AI 模型、供应商和系统设置
- **JSON 配置编辑** — 直接编辑 JSON，支持验证

### 硬件与扩展
- **硬件控制** — 系统信息、USB 设备、GPIO 引脚（支持高低电平切换）
- **技能管理** — 在界面中查看、删除和导入 PicoClaw 技能
- **定时任务** — 一目了然查看已配置的 Cron 任务

### 🆕 内置预设技能
附带三个开箱即用的 AI 技能，在管理页面一键安装：

| 技能 | 说明 |
|:---|:---|
| 🔍 **系统诊断** | 自动网络/DNS/网关检测、日志分析、故障排查 |
| 💾 **配置备份** | 交互式备份流程，支持环境检查、选项菜单、恢复操作 |
| 📦 **智能安装** | 通过 opkg/is-opkg 智能搜索应用，支持模糊描述匹配 |

> 这些技能是纯知识提示文件（SKILL.md）— 增强 PicoClaw 的 AI 响应能力，无需修改 PicoClaw 本体。

## 📋 系统要求

| 要求 | 说明 |
|---|---|
| **OpenWrt / iStoreOS** | 24.10 / 25.xx（需安装 LuCI） |
| **PicoClaw** | **必须先安装！** 本界面不包含 PicoClaw 主程序 |
| **架构** | all（纯 Lua，不限架构，x86-64 / aarch64 / armv7 等均可） |

> ⚠️ **重要提醒**：`luci-app-picoclaw` 只是 PicoClaw 的**网页管理界面**，**不是** PicoClaw 本身。如果你还没安装 PicoClaw 主程序，请先完成下方「第一步」的安装，否则管理界面无法正常工作。

## 🚀 安装

### 第一步：安装 PicoClaw 主程序（必做！）

PicoClaw 主程序支持多种架构（x86-64、aarch64、armv7、mipsle、riscv64 等），前往 [Releases](https://github.com/sipeed/picoclaw/releases) 下载对应版本。

#### 方式 A：命令行手动安装

**iStoreOS (x86-64) 示例：**

```bash
# 下载 PicoClaw（以 v0.2.4 为例，根据实际版本替换）
cd /tmp
wget https://github.com/sipeed/picoclaw/releases/download/v0.2.4/picoclaw_Linux_x86_64.tar.gz
tar xzf picoclaw_Linux_x86_64.tar.gz
cp picoclaw /usr/bin/picoclaw
chmod +x /usr/bin/picoclaw

# 安装 init.d 服务脚本（可选，用于开机自启和 procd 管理）
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw
/etc/init.d/picoclaw enable
```

> 💡 **其他架构**：arm64 设备下载 `picoclaw_Linux_arm64.tar.gz`，mipsle 设备下载 `picoclaw_Linux_mipsle.tar.gz`，以此类推。完整列表请查看 [PicoClaw Releases](https://github.com/sipeed/picoclaw/releases)。

**验证 PicoClaw 已安装：**

```bash
picoclaw --version
```

#### 方式 B：一键安装脚本（推荐新手使用）

本项目提供了一个 Python 脚本，可以**自动检测架构、下载 PicoClaw、部署 LuCI 界面、配置服务**，一条命令搞定所有事。

**在你的电脑上运行（需要 Python 3 和 paramiko）：**

```bash
# 1. 克隆本仓库
git clone https://github.com/GennKann/luci-app-picoclaw.git
cd luci-app-picoclaw

# 2. 安装依赖
pip install paramiko

# 3. 运行一键安装
python install.py
```

脚本会自动完成：
- ✅ 检测路由器架构（x86-64 / arm64 / armv7）
- ✅ 下载并安装 PicoClaw 主程序
- ✅ 创建 init.d 开机自启服务
- ✅ 部署 LuCI 管理界面
- ✅ 初始化 PicoClaw 配置文件
- ✅ 启动 PicoClaw 服务

#### 方式 C：LuCI 页面内一键安装

如果你已经安装了 `luci-app-picoclaw`（通过 iStore 商店或 IPK），但还没装 PicoClaw 主程序，LuCI 页面顶部会自动显示**橙色安装横幅**，点击即可直接从网页上安装 PicoClaw（自动检测架构并下载）。

> 💡 如果你想先装管理界面再装主程序，可以使用这个方式——先装 `luci-app-picoclaw`，然后从页面上点一键安装。

### 第二步：安装 LuCI 管理界面（luci-app-picoclaw）

> 如果你已经通过上方「一键安装脚本」安装，此步骤**已自动完成**，可以跳过。

#### 方式一：iStore 商店安装（推荐）

在路由器的 iStore 商店中搜索 `picoclaw` 即可直接安装。

#### 方式二：手动下载 IPK 安装

从 [Releases](https://github.com/GennKann/luci-app-picoclaw/releases) 下载 IPK 包（`_all` 表示全架构通用，不限 CPU 架构）：

```bash
# 下载 IPK（以下载最新版 v1.0.5 为例）
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/download/v1.0.5/luci-app-picoclaw_1.0.5-1_all.ipk

# 安装依赖
opkg update
opkg install luci-lib-jsonc curl

# 安装 IPK
opkg install luci-app-picoclaw_1.0.5-1_all.ipk

# 清理 LuCI 缓存
rm -rf /tmp/luci-*
```

#### 方式三：手动复制文件安装

```bash
# 控制器
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# 模板
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# 预设技能（可选）
mkdir -p /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# 清理 LuCI 缓存
rm -rf /tmp/luci-*
```

安装完成后访问：`http://<路由器IP>/cgi-bin/luci/admin/services/picoclaw`

## ❓ 常见问题

### 安装了 luci-app-picoclaw 但打不开 / 报错？
这说明你的路由器上还没有安装 **PicoClaw 主程序**。请先完成「第一步」安装 PicoClaw，然后再刷新页面。

### iStore 商店里搜不到 picoclaw？
请确保你的 iStore 商店软件源已更新（`opkg update`），或者尝试直接从 GitHub 下载 IPK 安装。

### 页面顶部有橙色安装横幅是怎么回事？
这说明已安装 `luci-app-picoclaw` 但尚未安装 PicoClaw 主程序，点击横幅即可一键安装。

## 📁 项目结构

```
luci-app-picoclaw/
├── luci/
│   ├── controller/
│   │   └── picoclaw.lua          # LuCI 控制器（后端逻辑）
│   └── view/
│       └── picoclaw/
│           └── main.htm           # LuCI 模板（HTML/CSS/JS，服务端渲染）
├── skills/
│   ├── openwrt-diagnostics/
│   │   └── SKILL.md              # 系统诊断 AI 技能
│   ├── openwrt-backup/
│   │   └── SKILL.md              # 配置备份/恢复 AI 技能
│   └── openwrt-app-installer/
│       └── SKILL.md              # 智能应用安装 AI 技能
├── scripts/
│   ├── picoclaw.init              # OpenWrt init.d 服务脚本
│   └── build-apk-25xx.sh          # Sipeed 25xx 设备构建脚本
├── install.py                     # 交互式安装助手
├── Screenshots/                   # README 截图
└── README*.md                     # 多语言文档
```

## 🛠️ 技术栈

| 组件 | 技术 |
|---|---|
| 后端 | Lua (LuCI)，使用 `luci.jsonc` |
| 前端 | HTML + CSS + JavaScript（服务端渲染） |
| 服务管理 | OpenWrt procd (init.d) |
| 安全 | 所有表单均带 CSRF token 保护 |

## 📄 许可证

[MIT 许可证](LICENSE)

## 🙏 鸣谢

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) 和 [LuCI](https://github.com/openwrt/luci)
