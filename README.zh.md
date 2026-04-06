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
  <img src="https://img.shields.io/badge/Version-1.0.8-brightgreen" alt="Version">
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
> v1.0.8 已合入 iStore 官方源，商店中可直接搜索到。

#### 方式二：下载 IPK 手动安装

从 [Releases](https://github.com/GennKann/luci-app-picoclaw/releases/latest) 下载最新 IPK：

```bash
cd /tmp
wget https://github.com/GennKann/luci-app-picoclaw/releases/latest/download/luci-app-picoclaw_1.0.8-1_all.ipk
opkg install luci-app-picoclaw_1.0.8-1_all.ipk
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
