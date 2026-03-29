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
| **OpenWrt** | 24.10 / 25.xx（需安装 LuCI） |
| **PicoClaw** | 已安装并运行 [sipeed/picoclaw](https://github.com/sipeed/picoclaw) |

## 🚀 安装

### 方式一：手动安装

```bash
# 控制器
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# 模板
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# Init 脚本（可选，用于服务控制）
cp scripts/picoclaw.init /etc/init.d/picoclaw
chmod +x /etc/init.d/picoclaw

# 预设技能（可选）
cp -r skills/openwrt-diagnostics /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-backup /usr/lib/lua/luci/picoclaw-skills/
cp -r skills/openwrt-app-installer /usr/lib/lua/luci/picoclaw-skills/

# 清理 LuCI 缓存
rm -rf /tmp/luci-*
```

然后访问：`http://<路由器IP>/cgi-bin/luci/admin/services/picoclaw`

### 方式二：iStore 商店（即将上线）

已提交至 [iStore 应用商店](https://github.com/istoreos/openwrt-app-actions)，审核通过后可直接在路由器的 iStore 中安装。

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
