# Changelog

All notable changes to `luci-app-picoclaw` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.1.5] - 2026-04-24

### Fixed
- **Shell 注入修复** — 上传安装路径 `upload_path` 添加白名单校验 (`is_safe_tmp_path`) 和 `shell_quote` 转义，防止路径遍历注入
- **find 结果注入修复** — `do_upload_install` 和 `do_update` 中 `find` 返回路径添加前缀校验，防止恶意文件名注入
- **rm -rf 替换** — 技能删除改用 Lua 原生 `rmtree()` 递归删除，避免 shell `rm -rf` 静默风险
- **ANSI 剥离修复** — 聊天回复去 ANSI 码改用纯 Lua `gsub`，消除 `echo | sed` shell 注入风险
- **XSS 修复** — 技能删除确认框 `confirm()` 中的 `sk.name` 改用 `data-confirm` 属性，防止单引号注入

---

## [1.1.3] - 2026-04-10

### Added
- **搜索引擎配置区域** — 在配置编辑标签页中可直接配置搜索引擎（GLM Search、百度搜索、DuckDuckGo、Brave、Tavily、Perplexity、SearXNG）
- **GFW 提示** — 为国内用户标注哪些搜索引擎被 GFW 屏蔽
- **5语言 i18n 翻译** — 搜索引擎相关标签的完整多语言支持（中文、英文、日文、葡萄牙文、德文）

### Changed
- README 5语言版本新增「模型配置方法」和「搜索引擎配置」章节
- 版本号徽章更新至 v1.1.3
- IPK 下载链接更新至 v1.1.3

---

## [1.1.2] - 2026-04-10

### Fixed
- **IPK 打包格式规范化** — control 文件严格对齐 istore-repo 参考格式
- **control.tar.gz** 添加 `.` 目录条目、postinst（OpenWrt 标准 160 bytes）、prerm（117 bytes）
- **data.tar.gz** 添加 `.` 目录条目和中间目录（./usr/, ./usr/lib/ 等）
- **Description 双空格** — 冒号后双空格（OpenWrt 规范）
- **Installed-Size** — 改为 data.tar.gz 实际字节数（非硬编码）
- **Source/Depends 字段** — Source 改为 `feeds/packages/luci/applications/luci-app-picoclaw`，Depends 添加 `libc`

### Added
- 新打包脚本 `build_v112_targz.py`，含完整验证（MD5 对比、格式校验）

---

## [1.1.0] - 2026-04-10

### Fixed
- **标签切换 Bug** — i18n 字典键名含 `-`（如 `mg_prov_glm-4.5-air`）导致 JS 语法错误，所有标签无法切换。修复：给含特殊字符的键名加引号
- **默认模型选择器** — 页面加载后默认模型不匹配配置文件值。修复：批量添加行时抑制 refreshDefaultModelSelect 调用
- **SecureString 字符数组** — `glm-4.5-air` 的 api_keys 是字符数组 `["[","N","O","T","_","H","E","R","E","]"]`，原代码只取 `key[0]`。修复：检测并 join 拼接

### Changed
- i18n 键名引号包裹（5语言版本）
- 模型列表渲染逻辑优化

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

[1.1.5]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.1.5
[1.1.3]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.1.3
[1.1.2]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.1.2
[1.1.0]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.1.0
[1.0.9]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.9
[1.0.8]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.8
[1.0.7]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.7
[1.0.6]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.6
[1.0.5]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.5
[1.0.4]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.4
[1.0.3]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.3
[1.0.2]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.0.2
