<p align="center">
  <img src="Screenshots/logo.svg" alt="PicoClaw LuCI" width="120">
</p>

<h1 align="center">luci-app-picoclaw</h1>

<p align="center">
  <b><a href="https://github.com/sipeed/picoclaw">PicoClaw</a> 的 OpenWrt LuCI 网页管理界面</b>
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

## 📸 截图预览

| 桌面端 | 移动端 |
|:---:|:---:|
| ![主界面](Screenshots/screenshot_main.png) | ![手机端](Screenshots/screenshot_mobile.png) |
| ![配置编辑](Screenshots/screenshot_config.png) | — |

## ✨ 功能特性

- **仪表盘** — 实时显示服务状态、PID、内存占用、端口监听
- **服务控制** — 一键启动 / 停止 / 重启 PicoClaw
- **开机自启开关** — 网页上控制开机自动启动
- **通道管理** — 查看已连接的通道（飞书、Telegram、Discord、微信等）
- **表单化配置编辑** — 直观的 UI 配置 AI 模型、供应商和系统设置
- **JSON 配置编辑** — 直接编辑 JSON，支持验证
- **多语言** — 简体中文、English、日本語、Português、Deutsch
- **在线更新** — 检查新版本并从界面直接更新
- **系统日志** — 实时查看 PicoClaw 日志
- **响应式设计** — 适配桌面和手机浏览器

## 📋 系统要求

| 要求 | 说明 |
|---|---|
| **OpenWrt** | 24.10 / 25.xx（需安装 LuCI） |
| **PicoClaw** | 已安装并运行 [sipeed/picoclaw](https://github.com/sipeed/picoclaw) |

## 🚀 安装

将 LuCI 文件复制到 OpenWrt 路由器：

```bash
# 控制器
cp luci/controller/picoclaw.lua /usr/lib/lua/luci/controller/picoclaw.lua

# 模板
cp luci/view/picoclaw/main.htm /usr/lib/lua/luci/view/picoclaw/main.htm

# 清理 LuCI 缓存
rm -rf /tmp/luci-*
```

然后访问：`http://<路由器IP>/cgi-bin/luci/admin/services/picoclaw`

## 🛠️ 技术栈

| 组件 | 技术 |
|---|---|
| 后端 | Lua (LuCI) |
| 前端 | HTML + CSS + JavaScript（服务端渲染） |
| 服务管理 | OpenWrt procd (init.d) |

## 📄 许可证

[MIT 许可证](LICENSE)

## 🙏 鸣谢

- [PicoClaw](https://github.com/sipeed/picoclaw) by Sipeed
- [OpenWrt](https://openwrt.org/) 和 [LuCI](https://github.com/openwrt/luci)
