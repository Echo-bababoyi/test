# 问题清单

状态标记：✅ 已完成 / 🧪 已实现待测 / 🔧 未实现 / 🐛 Bug / ❓ 待确认

## 一览表

| # | 事项 | 归属 | 状态 |
|---|------|------|------|
| 1 | AGENT_DEFINITION_QUESTIONS.md 剩余问题答完 | 用户 | ✅ |
| 2 | 产出 AGENT_SPEC.md 权威设计规范 | — | ✅ |
| 3 | 产出 PRD.md 产品需求文档 | PM | ✅ |
| 4 | 产出系统架构设计（ARCHITECTURE.md v1.2） | architect | ✅ |
| 5 | 产出 UI/UX 交互设计（UI_UX_DESIGN.md v1.0） | PM | ✅ |
| 6 | 编码实施（前端 Flutter Web + 后端 FastAPI） | frontend / backend | 🧪 |
| 7 | 实施计划修订（采纳 PM 3 条调整建议） | architect | ✅ |
| 8 | 前端流程回退（旧版闪屏页+标准首页+PhoneFrame+Riverpod+双模式主题） | frontend | ✅ |
| 9 | 路由路径统一 AppRoutes 常量（18 处硬编码替换） | frontend | ✅ |
| 10 | PersistentBanner 改 Riverpod 响应式 | frontend | ✅ |
| 11 | AgentPanel 协议对齐（agent_wake payload + permission_response + field_key/button_key） | frontend | ✅ |
| 12 | 草稿写入链路打通（DraftService.autoSave） | frontend | 🧪 |
| 13 | 语音引导 TTS（voice_hint Web Speech API） | frontend | 🧪 |
| 14 | 长辈首页搜索条入口 | frontend | ✅ |
| 15 | WakeWordListener 单例竞争修复 | frontend | ✅ |
| 16 | 后端 prompt 路由前缀同步 | backend | ✅ |
| 17 | 用户旅程图文档（docs/USER_JOURNEY.md） | PM | ✅ |
| 18 | 智能代理设计分析报告（docs/AGENT_DESIGN_REPORT.md v1.3） | PM / architect | ✅ |
| 19 | 小浙助手设置页 + AgentSettingsService | frontend | ✅ |
| 20 | AudioPlayer onEnded 回调修复 + 30s 超时兜底 | frontend | ✅ |
| 21 | _speakHint 接入设置服务（语音开关 + 动态语速） | frontend | ✅ |
| 22 | 测试用户旅程图（docs/USER_JOURNEY_TESTING.md） | PM | ✅ |
| 23 | 7 场景 E2E 测试套件（app/test/e2e/） | reviewer | ✅ |
| 24 | 全页面交互反馈优化（ripple + 路由转场统一淡入） | frontend | ✅ |
| 25 | 交互样式规范 v1.1（PM 出规范，8 类元素按下态定义） | PM | ✅ |
| 26 | 闪屏页还原浙里办原版 | frontend | ✅ |
| 27 | 标准版首页交互体验全面优化（PressScaleWrapper + 热门服务卡片） | frontend | ✅ |
| 28 | 长辈版首页交互体验全面优化 | frontend | ✅ |
| 29 | Tab 标签切换文字位移 bug | frontend | ✅ |
| 30 | Tab 选中态消失 bug（Ink→Container） | frontend | ✅ |
| 31 | AgentFab 悬浮助手组件（935 行，可拖动气泡聊天窗） | frontend | ✅ |
| 32 | 低保真线框图页面（wireframe_page.dart，6 界面，论文插图源） | frontend / PM | ✅ |
| 33 | 多页面交互重构（草稿箱 / 人脸认证 / 养老金查询 / 长辈底部导航 / 麦克风 / 气泡 / 面板） | frontend | ✅ |
| 34 | 后端健壮性加固（Agno API 适配 + 全 try/except + ASR 错误细分 + dotenv） | backend | ✅ |
| 35 | Noto Sans SC 中文字体集成（Regular + Bold） | frontend | ✅ |
| 36 | 论文草稿 v2.0 + 图表素材（截图 / 线框图 / 用户旅程图 / 信息架构图） | PM | ✅ |

---

## 详细条目

### #1 AGENT_DEFINITION_QUESTIONS.md 剩余问题答完

**背景**：代理定义的核心工作文档，用户逐条回答设计问题。组 A~E 已定稿，可能仍有未覆盖的问题。

**目标**：所有问题回答完毕，形成完整的代理设计输入。

**验收标准**：文档中所有问题均有明确回答，无遗留的 `TODO` 或 `待定` 标记。

**完成时间**：2026-04-28（会话 2）

### #2 产出 AGENT_SPEC.md 权威设计规范

**背景**：AGENT_DEFINITION_QUESTIONS.md 答完后，将答案整理为结构化的设计规范文档。

**目标**：产出 `docs/AGENT_SPEC.md`，作为后续实施的唯一权威依据。

**依赖**：#1 完成后才能开始。

**完成时间**：2026-04-28（会话 2）

### #3 产出 PRD.md 产品需求文档

**背景**：代理规范完成后，产出产品层面的需求文档，覆盖功能清单、用户故事、验收标准。

**目标**：产出 `docs/PRD.md` v1.0。

**完成时间**：2026-04-28（会话 2）

### #4 产出系统架构设计（ARCHITECTURE.md v1.2）

**背景**：PRD 完成后，architect 产出系统架构设计，覆盖技术选型、数据模型、WebSocket 协议、核心场景时序。

**目标**：产出 `docs/ARCHITECTURE.md` v1.2。技术栈：FastAPI + 手写状态机 + DeepSeek-V3 + 讯飞 ASR/TTS。

**完成时间**：2026-04-28（会话 2）

### #5 产出 UI/UX 交互设计（UI_UX_DESIGN.md v1.0）

**背景**：架构完成后，PM 基于浙里办现有页面结构产出代理叠加的交互设计文档。

**目标**：产出 `docs/UI_UX_DESIGN.md` v1.0，覆盖 4 场景逐步剧本、适老化规范、代理面板设计、特殊状态 UI。

**完成时间**：2026-04-28（会话 2）

### #6 编码实施（前端 Flutter Web + 后端 FastAPI）

**背景**：设计阶段全部完成，下一步进入编码实施。

**目标**：按 `docs/ARCHITECTURE.md` 和 `docs/UI_UX_DESIGN.md` 实现前端 Flutter Web + 后端 FastAPI 代理服务，覆盖 4 个核心场景。

**前置条件**：先出实施计划（任务拆分 + 优先级），再开始编码。→ 实施计划初稿已出（`docs/IMPLEMENTATION_PLAN.md`），待修订后开工。

**验收标准**：4 个核心场景（登录刷脸 / 登录验证码 / 医保缴费 / 养老金查询）均可在浏览器端完整演示，三条横切原则在代码层面有保障。

### #8–#17 本次会话（2026-05-09）

**#8 前端流程回退**：将前端恢复为旧版（archive/scene-canvas-v1）的层级结构，包含闪屏页、标准首页、PhoneFrame 壳、Riverpod ProviderScope、双模式主题（AppTheme.of(mode)）。完成时间：2026-05-09

**#9 路由路径统一 AppRoutes 常量**：消除 18 处硬编码路径字符串，全部改用 `AppRoutes.xxx` 常量，防止路径拼写不一致。完成时间：2026-05-09

**#10 PersistentBanner 改 Riverpod 响应式**：登录引导横幅改为监听 `authProvider`，登录后自动消失，不再依赖静态变量。完成时间：2026-05-09

**#11 AgentPanel 协议对齐**：修复 `agent_wake` payload 字段缺失、`permission_response` 消息类型错误、`cmd_fill_field`/`cmd_press_button` 使用 `field_key`/`button_key` 与后端协议不一致等 P0 Bug。完成时间：2026-05-09

**#12 草稿写入链路打通**：补全 `DraftService.autoSave`，在表单字段变化时自动写入 IndexedDB；`AgentPanel` 在 `agent_ready` 收到 `draft_hint` 时显示草稿恢复提示。状态：已实现待真机验证。

**#13 语音引导 TTS**：`cmd_highlight`/`cmd_fill_field`/`cmd_navigate` 的 `voice_hint` 字段接入 Web Speech API (`SpeechSynthesis`)，代理操作时同步语音播报。状态：已实现待真机验证。

**#14 长辈首页搜索条入口**：在长辈首页 `_EldToolBarSection` 下方插入 `_EldSearchBar`，橙色背景圆角白色搜索框（高 52dp），点击跳 `/search`。弥补小浙助手按钮占用原搜索 FAB 后的入口缺失。完成时间：2026-05-09

**#15 WakeWordListener 单例竞争修复**：修复多页面挂载时 `WakeWordListener` 重复 `start()` 导致的竞争问题，改为引用计数模式。完成时间：2026-05-09

**#16 后端 prompt 路由前缀同步**：后端场景 prompt 中的路由路径与前端 `AppRoutes` 常量同步对齐，消除路由前缀不一致导致 `cmd_navigate` 跳转失败的问题。完成时间：2026-05-09

**#17 用户旅程图文档**：产出 `docs/USER_JOURNEY.md` v1.0，覆盖 4 场景完整旅程图、情感曲线、前端支撑评估、3 条调整建议（含 PM + architect 联合定稿）。完成时间：2026-05-09

---

### #7 实施计划修订（采纳 PM 3 条调整建议）

**背景**：architect 产出 `docs/IMPLEMENTATION_PLAN.md` 初稿后，PM 审阅发现 3 处需调整。

**目标**：architect 修订实施计划，采纳以下调整：
1. T4 主题全局最小字号改为 18sp（PRD §4.1 适老化要求）
2. T9 显式补充"场景 4b（医保查询）"，Phase 4 验收表同步补充
3. Phase 4 验收表"草稿箱恢复"行补注演示前置步骤

**额外**：考虑 PM 补充的风险项——T9 加入 ASR 识别率底线测试验收项。

**依赖**：用户确认采纳后执行。

**完成时间**：2026-04-29（会话 3）

**修订内容**：
1. T4 全局最小字号 14sp → 18sp（对齐 PRD §4.1）
2. T9 显式补充"场景 4b（医保查询）"
3. Phase 4 验收表补充医保查询行 + 草稿箱恢复补注演示前置步骤
4. Phase 4 验收表新增 ASR 识别率底线测试验收项（≥ 80%）

---

### #31–#36 本次会话（2026-05-17，会话 8 — 从 GitHub 同步）

> 用户在外部独立完成 commit `e07f0d8`（4345 行新增 / 872 行删除，63 个文件），本会话仅做事后文档登记。团队成员未参与该次提交。

**#31 AgentFab 悬浮助手组件**

新增 `app/lib/widgets/agent_fab.dart`（935 行），实现右下角可拖动气泡形态聊天窗，内置 WS 连接 + 文本输入 + 语音输入 + 授权卡片渲染。提供独立于底部 Tab 的常驻代理入口，与中央"小浙"按钮形成两条入口并存。完成时间：2026-05-17

**#32 低保真线框图页面（论文插图源）**

新增 `app/lib/pages/wireframe_page.dart`（814 行），覆盖 6 个核心界面线框：长辈首页 / 人脸认证 / 医保缴费 / 代理面板 / 授权卡片 / 操作记录。`router.dart` +6 条线框路由。`docs/diagrams/wireframes/` 下产出 6 张 PNG + `wireframes_combined.png` 合图。作为论文插图直接渲染源（避免另起 Figma/Sketch 工作流）。完成时间：2026-05-17

**#33 多页面交互重构**

涉及多个页面与组件的大幅改写：
- `drafts_page.dart` 草稿箱（+310 行）
- `face_auth_page.dart` 人脸认证（±269 行）
- `pension_query_page.dart` 养老金查询（+364 行）
- `elder_bottom_nav.dart` 长辈底部导航（-缩减约一半，更适老化）
- `mic_button.dart` 麦克风按钮重构
- `agent_bubble.dart` 气泡样式调整 + `agent_panel.dart` 同步更新

完成时间：2026-05-17

**#34 后端健壮性加固**

向真机部署前的稳定性靠拢：
- `agent_core.py`：Agno API 字段适配（`add_history_to_messages` → `add_history_to_context`），`send` 异常捕获
- `ws_handler.py`：消息处理重构 — `_dispatch` 全包 try/except、`text_input` 改 `asyncio.create_task` 异步、ASR 三种错误细分、TTS 按需生成
- `deepseek_client.py`：错误处理加固
- `main.py`：新增 `dotenv` 加载

完成时间：2026-05-17

**#35 Noto Sans SC 中文字体集成**

新增 `app/fonts/NotoSansSC-Regular.ttf` + `Bold.ttf`，`pubspec.yaml` 注册字体族，统一中文显示效果。完成时间：2026-05-17

**#36 论文草稿 v2.0 + 图表素材**

- `docs/论文草稿.md` ±871 行（v1.0 → v2.0），大幅扩写答辩材料
- 图表素材：
  - `docs/diagrams/screenshots/` 4 张页面截图 + `screenshots_combined.png`
  - `docs/diagrams/brochure_shots/` 4 张组合大图 + `combined.png`
  - `docs/diagrams/wireframes/` 6 张线框图 + 合图
  - `docs/diagrams/user_journey-1~4.png` + `user_journey_full.png` + `user_journey.md`
  - `docs/diagrams/ia_diagram.png` 信息架构图
- 配套渲染脚本 5 个（`render_ia.py` / `render_user_journey.py` / `screenshot_pages.py` / `screenshot_wireframes.py` / `combine_*.py`）

**注**：部分图表素材已被用户手动删除（与原 commit 相比），不阻塞登记。

完成时间：2026-05-17
