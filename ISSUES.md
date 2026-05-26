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
| 37 | 人脸验证真机测试（MediaPipe 眨眼+转头检测可靠性验证） | reviewer | 🧪 |
| 38 | AgentFab 全页面覆盖（12 页）+ 颜色自适配 modeProvider + AgentPanel 退役（删 664 行死代码） | frontend | ✅ |
| 39 | 关闭标准版登录/搜索入口 + 长辈版全页面橙色统一（10 文件 ~50 处） | frontend | ✅ |
| 40 | "我的"页面未登录态展示长辈版橙色登录引导（loginProvider watch + _LoginPrompt） | frontend | ✅ |
| 41 | 标准版底部"我的"Tab 误跳长辈版修复（1 行） | frontend | ✅ |
| 42 | 登录页交互优化（条款 checkbox 勾选 + 跳过条款浮层 + 字号适老化 + 删装饰区） | frontend / PM | ✅ |
| 43 | 人脸验证 MediaPipe 真检测实现（本地化资源 + 摄像头接入 + 状态机 S0-S9 + 异常 E1-E4 + FACE_AUTH_DESIGN.md v1.0） | frontend / PM | ✅ |
| 44 | 高亮框不跟随窗口缩放（getTransformTo + transformRect 修复） | frontend | ✅ |
| 45 | 聊天框只能左右拖动（补全 _bubbleY 读写） | frontend | ✅ |
| 46 | LLM 一次执行完就结束（多步引导阶段 1：cmd_wait_user + step_completed，login 场景） | frontend / backend | ✅ |
| 47 | 聊天框智能避让高亮区域（PhoneFrame-local 坐标 + AnimatedPositioned） | frontend | ✅ |
| 48 | 登录引导缺 input_phone 步骤（输入完成检测 + 弹窗 key 注册 + prompt 重排） | frontend / backend | ✅ |
| 49 | 弹窗蒙版遮挡聊天框（蒙版降至 15%） | frontend | ✅ |
| 50 | 活体检测无 TTS 提示（眨眼/转头阶段加语音引导） | frontend | ✅ |
| 51 | 3080 端口浏览器缓存白屏 | — | 🐛 |
| 52 | LLM response.content 仍不空（DeepSeek 输出思考过程） | backend | 🧪 |
| 53 | pop 返回时 executor 失效（unbindPage 清掉 executor） | frontend | 🧪 |
| 54 | 草稿重复追加（_checkPageDraft 反复执行重复插入 draft_prompt 卡） | frontend | 🧪 |
| 55 | AGENT_SPEC v1.1 三级信任模型对齐（§3.3 重写 + 能力矩阵 + 权限矩阵） | PM / architect | ✅ |
| 56 | 响应延迟优化 11s→1s（关遥测 + DeepSeek 参数调优 + OOS 合并 + 去 TTS 阻塞） | backend | ✅ |
| 57 | AgentFab 聊天记录跨开关/跨页面持久化（ChatHistory 内存单例） | frontend | ✅ |
| 58 | ModeNotifier F5 刷新后模式不丢失（localStorage 持久化） | frontend | ✅ |
| 59 | 登录分支选择弹窗（模糊意图弹两按钮，agent_choice_request 消息类型） | frontend / backend | ✅ |
| 60 | 验证码登录 L2 破例代填（sms_code_generated + 场景豁免 + 授权卡 + 12 步 prompt） | frontend / backend | ✅ |
| 61 | 医保缴费全委托代填（applier 机制 + 下拉框代填 + 3 步 prompt + 家属路径） | frontend / backend | 🧪 |
| 62 | 养老金查询全委托改造（2 步 prompt + 高亮引导用户点查询） | frontend / backend | 🧪 |
| 63 | 查询结果高亮 bug 修复（broadcast 按场景取 key，pension + yibao_query 同修） | frontend | 🧪 |
| 64 | trust 传播机制（trust_changed 消息 + 后端 set_trust_level + env block 按真实工具集过滤） | frontend / backend | ✅ |
| 65 | 信任选择卡登录后不弹（动画时序竞态 + firstChoiceShown 卡死） | frontend | ✅ |
| 66 | cmd_ask_user 场景内问答工具（HITL 暂停 + 回答路由回执行器 + 60s 超时只裹 arun） | backend | ✅ |
| 67 | 用户档案预填（UserProfileService + @档案占位符 + 身份证免打字） | frontend / backend | ✅ |
| 68 | 医保缴费 prompt 重写（选择卡逐项问→填交错 + 删默认值矛盾） | backend | 🧪 |
| 69 | 授权卡文案不明确（只说"敏感信息"未说具体字段名） | frontend | 🔧 |
| 70 | 医保缴费页下拉框有预设值（应为空） | frontend | 🔧 |
| 71 | 点"去支付"跳转后聊天面板消失 | frontend | 🐛 |

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

### #37 人脸验证真机测试（MediaPipe 眨眼+转头检测可靠性验证）

**背景**：commit `903005b` 实现了基于 MediaPipe FaceLandmarker 的人脸姿态检测（本地化部署，零 CDN 依赖）。代码层 review 已通过，但未经真机摄像头测试。

**测试项**：
1. 摄像头能正常打开并显示实时画面（S3→S4 转场正常）
2. 面部对位 9 种实时纠正提示方向是否正确（镜像后左右是否符合直觉）
3. 眨眼检测灵敏度：正常眨眼能触发、持续闭眼不误触（EAR 阈值 0.20/0.25）
4. 转头检测灵敏度：左右转头各 ±15° 能触发，老年人幅度小是否够用
5. 超时 20 秒退回登录页 + SnackBar 正常显示
6. 成功停顿（S6 1秒 / S8 1秒 / S9 1.5秒）节奏感是否合适
7. × 退出在所有状态都可用
8. 摄像头资源释放：退出/成功后浏览器 tab 摄像头指示灯是否关闭
9. Chrome / Safari / Firefox 跨浏览器兼容性
10. 阈值调优记录（如需调整 EAR / yaw 阈值，记录最终值）

**设计文档**：`docs/FACE_AUTH_DESIGN.md` v1.0

**依赖**：需要有摄像头的设备 + HTTPS 或 localhost 环境

---

### #44–#50 本次会话（2026-05-22，会话 17）

**#44 高亮框不跟随窗口缩放**

浏览器窗口大小变化后高亮框位置不更新，偏离目标元素。将坐标计算从 `localToGlobal + size` 改为 `getTransformTo(null) + transformRect`，根治 FittedBox 缩放导致的坐标系不同步问题。完成时间：2026-05-22（commit `5355d01`）

**#45 聊天框只能左右拖动**

聊天框 `_bubbleY` 读写逻辑缺失，导致垂直方向无法拖动。补全读写后支持上下自由拖动。完成时间：2026-05-22（commit `f0f94c0`）

**#46 LLM 一次执行完就结束（多步引导）**

代理缺少"等用户操作 → 感知页面变化 → 继续下一步"的循环机制，LLM 发出所有指令后直接结束。阶段 1 实现：后端新增 `cmd_wait_user` 工具，前端新增 `step_completed` 消息，login_face / login_verify 两个场景 prompt 改造为多步模式。其余场景（医保缴费/养老金查询）留待阶段 2。完成时间（阶段 1）：2026-05-22（commit `b614a9f` + `0fd5ed5`）

**#47 聊天框智能避让高亮区域**

高亮框弹出时聊天框覆盖其上方，影响用户看清被引导的元素。聊天框监听 `currentHighlightKey` 变化，以 PhoneFrame-local 坐标计算高亮位置，自动上/下移位避让。加入 `AnimatedPositioned` 平滑过渡 + 落定脉冲形变动效，修复跨页后坐标被重置的问题。完成时间：2026-05-22（commit `d03861d` + `17daae7` + `649435f`）

**#48 登录引导缺 input_phone 步骤**

login_face 场景缺少"输入手机号"引导步骤，且条款浮层/摄像头授权弹窗未注册为可高亮元素。补充 `input_phone` 字段高亮 key 注册 + 输入完成 `step_completed` 检测、浮层与弹窗 key 注册、login_face prompt 步骤重排。完成时间：2026-05-22（commit `1c11fdd`）

**#49 弹窗蒙版遮挡聊天框**

系统弹窗弹出时全屏蒙版将聊天框完全遮盖，用户无法看到代理提示。将蒙版不透明度降至 15%，聊天框重新可见。完成时间：2026-05-22（commit `6ca173b`）

**#50 活体检测无 TTS 提示**

`face_auth_page` 眨眼（S5）和转头（S7）阶段缺少语音引导，老年用户不清楚该做什么动作。加入 TTS 语音提示，与文字提示同步播放。完成时间：2026-05-22（commit `3178870`）

---

### #51 3080 端口浏览器缓存白屏

**背景**：开发调试时浏览器缓存旧版 JS/Dart 文件，导致 3080 端口偶发白屏无法正常加载页面。

**临时方案**：改用 3081 端口绕过缓存，不作代码层修复。需要在每次代码变更后注意端口切换。

**状态**：🐛（已知问题，开发阶段接受现状）

---

### #52 LLM response.content 仍不空（DeepSeek 输出思考过程）

**背景**：DeepSeek-V3 在流式输出时 `response.content` 字段仍包含思考过程文本（会话 15 遗留），导致代理气泡可能出现多余内容。

**修复**：新增 `_strip_thinking()` 函数，正则过滤 `<think>...</think>` 块，返回前裁剪干净。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

---

### #53 pop 返回时 executor 失效

**背景**：用户按浏览器返回键时，`unbindPage` 清掉当前页面的 `executor`，导致后续代理指令无法执行（会话 15 遗留）。

**修复**：在 `build()` 内幂等补绑 executor，页面重建时自动重新注册，不依赖 `initState` 时序。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

---

### #54 草稿重复追加

**背景**：`_checkPageDraft` 每次页面刷新/状态变化时反复执行，向聊天框重复插入 `draft_prompt` 卡片（会话 15 遗留）。

**修复**：草稿插入时以 `pageId` 作去重 key，同一页面草稿只插入一次。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

---

### #55–#59 本次补录（Sessions 13/14，2026-05-20～2026-05-21）

> 以下条目为事后补登，工作在会话 13/14 已实际完成，因文档疏漏未及时记录。

**#55 AGENT_SPEC v1.1 三级信任模型对齐**

PM × architect 联合起草三级权限方案 v0.6（6 项决策拍板），随后更新 `docs/AGENT_SPEC.md` v1.0 → v1.1：§3.3 重写为三级信任模型 + 任务级一次性授权；§5 能力矩阵更新（引导级不可跳页 + 密码硬底线）；§5.2 新增权限矩阵对照；§6.1 登录场景统一 L1 + 三道 AND 机制；§7.4 首次主动询问机制。完成时间：2026-05-20（commits `68d8ebe`→`9d09441`→`66b6cb3`→`fdcf19d`）

**#56 响应延迟优化 11s→1s**

实测 OOS 路径延迟 11.2s，排查后多头优化：① 5 处 Agent 构造加 `telemetry=False` 关闭 agno 遥测；② DeepSeek 参数调优（分类 max_tokens=256/temperature=0.3，执行 1024/0.5）；③ `intent_classify` prompt 新增 `reply_text` 字段，OOS 路径省掉第二次 LLM 调用；④ OOS + scene 分支去掉同步 TTS 阻塞。实测 OOS 降至 1.0s，scene 确认降至 1.65s。完成时间：2026-05-21（commit `e8f0b7f`）

**#57 AgentFab 聊天记录跨开关/跨页面持久化**

新增 `ChatHistory` 内存单例，`_items` 指向共享列表。关闭聊天窗重开不丢历史，跨页面保留对话记录；F5 刷新清空（内存级持久化，不写 IndexedDB）。完成时间：2026-05-21（commit `97e94c2`）

**#58 ModeNotifier F5 刷新后模式不丢失**

刷新长辈版页面后 AgentFab 颜色恢复默认蓝色（标准版），因 ModeNotifier 状态未持久化。改为从 `localStorage` 读写 mode，F5 后保留长辈版橙色。完成时间：2026-05-21（commit `24e4fce`）

**#59 登录分支选择弹窗**

用户说"帮我登录"等模糊意图时，代理过去直接进入刷脸引导，未给用户选择权。新增 `login_choose` 意图分支：弹出两按钮（"刷脸登录"/"验证码登录"）让用户选；明确说具体方式则直接进场景。后端新增 `agent_choice_request` 消息类型，前端渲染选择卡片。完成时间：2026-05-21（commit `a9332ba`）

---

### #60–#63 本次会话（2026-05-25，会话 18）

**#60 验证码登录 L2 破例代填**

验证码登录场景需要代理在用户未完成登录时代填敏感字段（验证码），而三级权限默认在登录前仅有 L0/L1 工具。解决方案：① 前端新增 `sms_code_generated` WS 消息，点击"获取验证码"后将随机 mock 验证码回传后端上下文；② 后端新增 `_SCENE_FORCE_TOOLS` 场景豁免机制，`login_verify` 场景强制获得 L2 工具权限；③ 授权卡 `permission_request: read_sms` 一事一授保证安全性；④ prompt 改为 12 步多步引导，含用户拒绝授权的回退路径（代理停止代填，引导用户自行输入）。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

**#61 医保缴费全委托代填 + applier 机制**

医保缴费页含 `DropdownButtonFormField` 下拉字段（缴费对象、缴费年度），无 `TextEditingController`，原有 `cmd_fill_field` 通过 controller 代填的方式失效。新增 `applier` 机制：`AgentElementRegistry` 支持注册值应用器回调（`ValueChanged<String>`），代填时调用回调触发 `setState`，而非写 controller。医保缴费 prompt 3 步重写（navigate → 依次代填字段 → 高亮去支付），支持家属路径（代填"家属"后额外提示输入姓名）。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

**#62 养老金查询全委托改造**

养老金查询场景原 prompt 过于冗长且含 `cmd_press_button` 指令（`ElevatedButton` 上静默失效）。重写为 2 步：① navigate 到养老金查询页 + cmd_say 说明；② cmd_highlight 查询按钮 + cmd_say 引导用户亲手点。去掉所有 `cmd_press_button`，符合"确定性操作止步"原则。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

**#63 查询结果高亮 bug 修复**

broadcast 流广播模式下，多个场景（pension_query / yibao_query）共用同一 `currentHighlightKey` provider，导致高亮信号按错场景取 key、目标元素找不到。修复：广播时携带场景标识，订阅方按当前页面路由筛选，pension 和 yibao_query 同步修复。完成时间：2026-05-25（会话 18）

**状态**：🧪（已实现待真机验证）

---

### #64–#68 本次会话（2026-05-26，会话 19）

**#64 trust 传播机制**

登录后 trust 级别无法同步到已有 WS session（agent_wake 一次性写死）。新增 `trust_changed` 消息类型（models + ws_handler + agent_core），前端 3 处发送（elder_home 信任卡选择后 / agent_settings_page 设置页 / agent_session ensureSession 复用分支）。附带 env block 按 `get_scene_tools(scene_id, trust_level)` 真实工具集过滤，guide 级禁调 cmd_navigate 不再 400。完成时间：2026-05-26

**#65 信任选择卡登录后不弹**

根因：登录页淡出动画期间 ElderHome 的 isCurrent=false，一次性判定错过弹卡时机；次要：firstChoiceShown 弹前置 true 导致卡死。修复：ref.listen(loginProvider) 触发逐帧轮询 isCurrent（240 帧上限）；firstChoiceShown 改为选择成功后才持久化 + _trustSheetShowing 防重入。完成时间：2026-05-26

**#66 cmd_ask_user 场景内问答工具**

医保缴费代理问"本人/家人"后用户回答被当新意图分类（out_of_scope）。新增 `cmd_ask_user` HITL 工具（stop_after_tool_call），执行器发 agent_choice_request / agent_reply 后 await _answer_event；ws_handler process_asr_text 开头判 is_awaiting_answer 路由回执行器。附带 60s 超时改为只裹 LLM arun，人工等待不被误杀。完成时间：2026-05-26

**#67 用户档案预填**

登录后手机号+身份证号存 localStorage（UserProfileService），代理代填身份证时用 `value="@档案"` 占位符，前端 _onFillField 按 field_key 从档案取真实值替换。真实身份证不经 LLM。完成时间：2026-05-26

**#68 医保缴费 prompt 重写**

多轮迭代：① 新增 cmd_ask_user 选择卡收集缴费对象 ② 4 下拉框全填（页面无预设） ③ 删字段取值规范"默认值"矛盾措辞 ④ 改问→填交错结构 + 铁律。完成时间：2026-05-26

**状态**：🧪

---

### #69 授权卡文案不明确

**背景**：fill_field_sensitive 弹授权卡时只显示"想帮您填写敏感信息"，未说明具体是什么字段（如"身份证号"）。

**目标**：授权卡文案带上具体字段名，如"小浙想帮您填写【身份证号】"。

**状态**：🔧

---

### #70 医保缴费页下拉框有预设值

**背景**：进入医保缴费页时，4 个下拉框已显示预设值（城乡居民医保/2026年度/第一档等），应为空。

**目标**：页面初始状态所有下拉框为空，等代理代填或用户手选。

**状态**：🔧

---

### #71 点"去支付"跳转后聊天面板消失

**背景**：医保缴费流程完成后，用户按引导点"去支付"跳转到下一页面时，聊天面板消失。下一页面并非密码输入页，面板不该关闭。

**目标**：跳转后聊天面板保持显示。

**状态**：🐛
