# Changelog

All notable changes to `luci-app-picoclaw` will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [1.2.1] - 2026-11-21

### Added
- **iStore 应用注册** — 按 `istoreos-app-hub/docs/architecture/linkease-app-registration.md`，插件包持有注册清单 `/usr/share/picoclaw/picoclaw-plugin.json`、桌面图标 `/usr/share/picoclaw/www/logo.png`，标准入口 `/usr/share/linkease/apps.d/40-picoclaw.json` 是指向设备绝对路径的软链接；postinst 自动维护旧目录 `/usr/share/linkeasefull/desktop-apps.d` 兼容入口，prerm 只清理仍指向自己的链接
- **iStore 自动配置** — app-meta 的 `config.sh` 改为自包含脚本；插件包提供 `/usr/libexec/istorec/picoclaw.sh`（install/start/stop/restart/status/port/rm）供 iStore 调用

### Fixed
- **本地上传安装崩溃** — `action_do()` 在 `check_csrf()` 之前没有注册文件处理器，而 `check_csrf()` 内部调用 `http.formvalue("token")` 会触发 multipart 请求体解析，导致上传内容被丢弃；随后 `http.formvalue("picoclaw_file")` 对文件字段返回 table 而非路径，传入 `is_safe_tmp_path` 后 `path:match` 崩溃（`attempt to call method 'match' (a nil value)`）。现在在 `check_csrf()` 之前注册 `setfilehandler`，把内容流式写入 `/tmp/picoclaw-upload-<pid>.archive`，安装后清理；`is_safe_tmp_path` 增加类型守卫
- **对话面板标题显示成 `chat_title`** — `<h3>` 上多余的 `data-i18n="chat_title"` 指向不存在的键，i18n 兜底返回键名并整体覆盖标题，图标与内部 `<span>` 一起丢失；移除该属性
- **刷新硬件状态无效** — 按钮是 `<a href>` GET 请求，不带 CSRF token，`check_csrf()` 直接返回 403；改为 POST 表单携带 token，并补上 `refresh_hardware` 动作分支

### Changed
- controller 与 `main.htm` 的三处副本（`luci/`、`istore/luasrc/`、`istore/luci-app-picoclaw/luasrc/`）保持完全一致

---

## [1.2.0] - 2026-11-15

### Added
- **定时任务页** — 列出 / 新建 / 启用 / 禁用 / 删除 `workspace/cron/jobs.json` 里的任务，支持固定间隔与 cron 表达式，可指定投递通道与收件人
- **MCP 服务页** — 增删 MCP 服务器，stdio 支持启动参数与环境变量，http / sse 支持请求头，可标记延迟加载
- **技能页** — 技能卡片（名称 / 版本 / 描述）、内置技能标记、从注册表安装、粘贴导入、删除；原硬件页的技能入口迁移至此
- **模型与认证页** — `model_list` 列表、切换默认模型、启用停用、新增模型、API Key 配置状态（只显示有无与条数）、`picoclaw auth status` 只读展示
- **推理强度设置** — 模型条目支持 `thinking_level`（low / medium / high / max / adaptive），每行一个下拉，写入后自动重启
- **APK (v3/ADB) 构建脚本** `scripts/build-apk-v3.sh` — 在 OpenWrt 25.x 路由器上直接用系统 `apk mkpkg` 产出 v3 包，内置隐私扫描与 CRLF 检查；旧的 `build-apk-25xx.sh`（v2 格式，25.x 装不上）已标注废弃
- 标签栏支持换行，面板切换增加淡入位移动画

### Fixed
- **CLI 读错配置目录** — LuCI 进程 CWD 为 `/www` 且未设置 `HOME`，直接调用 `picoclaw` 会让 CLI 在错误位置读写配置，导致新建定时任务 / 改模型全部无效；现在所有调用统一前缀 `HOME=/root /usr/bin/picoclaw`
- **硬件页定时任务列表恒为空** — 同上原因，`picoclaw cron list` 读到了不存在的配置目录
- **配置编辑表单会写坏配置** — `steering_mode` / `media_cleanup.enabled` 少了 `agents.defaults.` / `tools.` 前缀，`listen`、`providers.*` 在 0.3.1 里已不存在；表单保存会往顶层写未知字段，严格校验下 PicoClaw 直接拒绝加载
- **保存配置加校验与回滚** — 写盘前备份，写后跑 `picoclaw model` 试解析，遇到 unknown field 自动回滚并提示具体字段
- **模型指南与示例适配 0.3.1** — provider 列改为真实取值（zhipu / moonshot / openrouter…），新增 23 项 provider 矩阵，示例改成 0.3.1 实际字段，补上「max_tokens 只能写在 agents.defaults」警告，删掉已移除的 `picoclaw config security`
- **模型清单更新到 2026-11** — DeepSeek V4.1 Flash / Claude Fable 5.2 / Sonnet 5.5 / GPT-5.5 / Gemini 4 Carbon / GLM-5.3 / Kimi K3 / Qwen3.8 Max 等 16 条，上下文按厂商口径显示；默认模型改为按当前配置动态高亮
- **内置预设技能目录是空的** — 三个 `openwrt-*` 目录只建了目录没装 `SKILL.md`，点「预设技能」或安装都没反应
- **预设技能 frontmatter 缺开头的 `---`** — 即使装上也没有 name/description，PicoClaw 无法识别
- **删除技能不消失** — 原实现只 `rmtree` 目录，不走 CLI，`skills store` 里的记录残留；现在先 `picoclaw skills remove`，再兜底删目录，并自动清理指向已消失目录的 store 条目
- 删除确认弹窗删的是列表最后一项（按钮 selectors 取错了目标），已按卡片定位
- BusyBox 下 `cp -r src/. dst/` 不生效，改成 `cp -r src skills_dir/`
- `gateway_port` 指标缺少中英文文案

### Changed
- 硬件页的「已安装技能」「定时任务」卡片改为一行入口，指向新的独立标签页
- 定时任务与配置类修改保存后重启服务（网关不监听 jobs.json / config 变化，实测进程内不重载）
- 配置编辑的 providers 区块改为指向「模型与认证」的提示（0.3.1 用 model_list 管模型）
- 技能页拆成「已安装」与「可安装的内置技能」两组，内置技能卡片新增单个「安装」按钮（`install_preset_one`）
- README 五种语言补充 APK 安装方式（`apk add --allow-untrusted`）并把 IPK 版本号更新到 1.2.0

### Packaging
- IPK：`luci-app-picoclaw_1.2.0-1_all.ipk`（tar.gz 三层嵌套，非 AR 格式）
- APK：`luci-app-picoclaw-1.2.0-r1.apk`（v3/ADB 格式，未签名，需 `--allow-untrusted`）
- 两者均包含 3 个内置技能的 `SKILL.md`（此前 IPK 里只有空目录）
- 打包脚本内置隐私扫描：命中 `sk-` 密钥、硬编码凭据或本机路径即中止，不写盘

## [1.1.6] - 2026-04-28

### Added
- **PicoClaw v0.2.7 兼容** — 适配 `channel_list` + `settings` 新配置格式（旧版 `channels` 自动兼容）
- **新增通道支持** — IRC、Matrix、OneBot、Pico、Pico Client、VK（i18n 5语言翻译）
- **微信绑定增强** — 新增"已授权但未启用"中间状态检测（通过 security.yml 判断）

### Fixed
- **通道列表空白** — v0.2.7 配置格式破坏性变更：`channels` → `channel_list`，子字段移入 `settings`，LuCI 模板未适配导致页面空白
- **通道开关写入错误路径** — `buildChannelsForm()` 中 toggle 的 `data-path` 硬编码 `channels.xxx.enabled`，v0.2.7 下应写 `channel_list.xxx.enabled`
- **服务启动绕过 procd** — 上传安装/在线更新后用 `os.execute("picoclaw gateway &")` 直接启动，改为 `/etc/init.d/picoclaw start`（procd 管理）
- **BusyBox pkill 不存在** — `pkill -f` 替换为 `killall`（OpenWrt BusyBox 无 pkill）
- **i18n 残留** — 删除废弃的 `wechat_work` / `tl_wechat_work` 翻译

### Changed
- PicoClaw 推荐版本更新至 v0.2.7
- README 5语言版本号徽章和下载链接更新至 v1.1.6

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

[1.1.6]: https://github.com/GennKann/luci-app-picoclaw/releases/tag/v1.1.6
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
