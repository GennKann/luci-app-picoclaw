# Changelog

All notable changes to `luci-app-picoclaw` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.0.9] - 2026-04-07

### Fixed
- **Gateway 端口显示异常** — 端口检测不再硬编码 4966/4967（18790/18791 十六进制），改为从 `config.json` 动态读取 `gateway.port`，支持任意端口配置。状态栏现在显示实际端口号
- **模型配置表单优化** — Provider 保留下拉选择（新增 Qwen / 通义百炼选项）；Model 名称从固定下拉改为手动输入框，支持任意自定义模型（如 qwen3.5-27b）；新增 API Key 密码输入字段；模型上下文提示自动匹配已知模型，未知模型显示通用建议
- **微信状态判断逻辑修复** — 修正检查路径为 `config.channels.weixin`（原错误地检查顶层 `config.weixin`）；`enabled=true` 时直接显示"已连接"状态；兼容顶层 config.weixin 向后兼容；「前往启用」按钮跳转修正为正确 Tab 索引 + 自动滚动到通道管理区域

---

## [1.0.8] - 2026-04-06

### Added
- 五语言完整 README 文档（English, 中文, 日本語, Deutsch, Português）
- iStore 商店安装状态说明（已合入官方源）
- FAQ 章节（常见问题解答）：停止按钮无效、CSRF token 错误、postinst 报错等已知问题及解决方案
- 新功能特性：kill-9 三步停止策略、CSRF 安全修复、微信个人号接入状态检测

### Changed
- README 版本号更新至 v1.0.8，PicoClaw 版本标注 v0.2.5
- Tech Stack 和项目结构章节完善

### Fixed
- IPK 打包数据截断问题（v1.0.5 遗留，v1.0.6 已修复基础上的二次验证）
- init.d 脚本停止策略升级：优雅停止 → pidof 检查 → kill-9 强杀 → 等待清理

---

## [1.0.7] - 2026-04-05

### Fixed
- **IPK 安装 Malformed 错误** — 修复打包脚本数据截断问题，所有文件大小与源文件完全一致
- **main.htm 安装后缺失** — 确保 HTML 模板正确打包进 IPK
- **API Key 读取失败** — 修复 PicoClaw 0.2.5 版本 `.security.yml` 路径和格式的兼容性
- **LuCI 页面服务异常** — 修复控制器 JSON 解析错误导致的页面渲染失败

### Added
- 完整的安装验证流程（打包前自动检查文件大小）
- GitHub Issue #1 用户反馈回复和处理记录

---

## [1.0.6] - 2026-04-05

### Fixed
- **IPK 格式问题**（重大修复）— 确认 opkg/iStoreOS 接受 tar.gz 格式（非 AR 格式）
- **IPK 数据截断** — picoclaw.lua 少 ~4.8KB，main.htm 少 ~623B；根因为打包脚本写入不完整
- 新打包脚本 `build_v106_targz.py` 带完整性校验，每个文件打包前后大小比对
- 路由器实测安装成功，opkg 不再报 Malformed

### Changed
- 打包脚本重构，增加数据完整性验证步骤
- 所有源文件（controller/view/init.d）大小验证通过后才生成 IPK

---

## [1.0.5] - 2026-04-05

### Added
- 初始 IPK 打包支持（含 init.d 服务管理脚本）
- LuCI 更新按钮：通过 GitHub API 动态查询 Release 资产列表，自动匹配 CPU 架构
- istore 目录结构初始化（用于后续提交 PR）

### Known Issues
- ⚠️ IPK 存在数据截断 BUG（此版本已废弃，请使用 v1.0.6+）

---

## [1.0.4] - 2026-04-04

### Added
- 飞书（Feishu/Lark）channel 配置支持
- WebSocket 长连接模式（无需公网 webhook）
- App ID / App Secret 直接在 config.json 中配置

### Changed
- 配置编辑器适配 PicoClaw 0.2.5 版本的新配置结构

---

## [1.0.3] - 2026-04-03

### Added
- 模型自定义配置功能：支持在 config.json 的 model_list 中添加自定义模型
- .security.yml 双文件配置体系支持
- openrouter-auto 虚拟模型内置支持

### Fixed
- 配置保存时 JSON 格式校验增强

---

## [1.0.2] - 2026-04-02

### Added
- 🎉 **初始正式发布**
- LuCI 控制器 (`picoclaw.lua`)：服务管理、配置读写、日志查看、状态检测
- LuCI 模板 (`main.htm`)：
  - 仪表盘：实时服务状态、PID、内存、端口监听
  - 配置编辑：表单化 AI 模型/供应商设置 + JSON 直接编辑
  - 通道管理：飞书、Telegram、Discord、微信等通道状态
  - 硬件控制：系统信息、USB 设备、GPIO 引脚操作
  - 技能管理：查看/删除/导入 PicoClaw 技能
  - 定时任务：Cron 任务一览
- Init.d 服务脚本 (`picoclaw.init`)：开机自启、procd 管理
- 3 个内置预设技能：
  - 系统诊断（网络/DNS/网关检测、日志分析）
  - 配置备份（交互式备份流程）
  - 智能安装（opkg/is-opkg 模糊搜索）
- 多语言界面框架（i18n）
- CSRF token 安全保护

---

## [Unreleased]

### Planned
- 更多 AI 提供商预设模板（Groq、Mistral、Cohere 等）
- 主题切换（暗色模式）
- 配置导入/导出功能
- 多用户会话管理
- 实时日志流（WebSocket）

---

[1.0.9]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.9
[1.0.8]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.8
[1.0.7]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.7
[1.0.6]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.6
[1.0.5]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.5
[1.0.4]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.4
[1.0.3]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.3
[1.0.2]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.2
