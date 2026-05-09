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
