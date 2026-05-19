# 提交记录

按时间倒序。每条记录包含 commit hash、标题、改动要点。

---

### 2026-05-19（会话 9）— 前端交互全面收尾 + 人脸验证 MediaPipe 真检测

#### 人脸验证真检测（核心）

**`903005b` feat: 人脸验证真检测 — MediaPipe 本地化 + 摄像头 + 状态机 S3-S9**
- 接入 MediaPipe Tasks Vision FaceLandmarker，**本地化部署零 CDN 依赖**：`app/web/mediapipe/` 含 face_landmarker.task 模型 + wasm + vision_bundle ESM（共 ~7MB）
- 新增 `app/web/face_detector.js`（IIFE 自启动 JS wrapper，暴露 `window.faceDetector`，返回 hasFace/ear/yaw/cx/cy/w/h/brightness）
- 新增 `app/lib/services/camera_service.dart`（getUserMedia + VideoElement + platformView 注册）
- 新增 `app/lib/widgets/camera_view.dart`（HtmlElementView 套壳）
- 新增 `app/lib/services/face_detector_service.dart`（dart:js poll wait + FaceFrame 数据类）
- 新增 `app/lib/services/login_page_snackbar.dart`（跨页 SnackBar 队列）
- 改造 `app/lib/pages/face_auth_page.dart` `_AuthFlow` 完整状态机：
  - S3 摄像头初始化（8s 超时）+ S4 面部对位（9 种实时纠正：偏左右上下/太近远/光线/已对准）+ S5 眨眼检测（EAR <0.20→>0.25 先睁后闭防误判，3 级文案升级）+ S6 眨眼成功（1s 停顿 + 中央 ✓ 80dp）+ S7 转头检测（yaw ±15° 左右各一次，L0 简洁版"请左右转头"）+ S8 转头成功（1s 停顿）+ S9 全部成功（1.5s 停顿 + 大对勾 160dp 弹性 400ms）
  - E1 摄像头权限拒绝独立页 + E2 检测超时（20s）退回登录页 + E3 × 主动退出 + E4 模型加载失败
  - 资源释放（teardown = cancel timers + det.dispose + cam.dispose）覆盖所有出口
  - `_CornerBracket` 改 StatefulWidget 实现 PM 规范的脉冲呼吸（Tween 0.6→1.0 / 1200ms / easeInOut）
  - AgentFab 在 authenticating / permissionDenied 全程隐藏
- index.html 引入 `<script type="module" src="face_detector.js">`
- LoginPage initState 接入 `LoginPageSnackbar.showIfPending`，显示跨页提示（橙底白字 18sp + 4s + bottom 80）
- 配套设计文档 `docs/FACE_AUTH_DESIGN.md` v1.0（710 行，PM 出品）

#### 登录页适老化

**`00339cd` fix(login): 恢复登录页适老化改动 — checkbox 交互 + 字号 + 删除装饰区**
- 从 1da32c0 恢复 login_page.dart：条款勾选交互（_agreed 状态 + 18→44dp 触控扩展 + 勾选后跳过 Terms overlay 直接进 faceAuth）、字号统一 ≥18sp、删除"其他登录方式"+"其他证件"装饰区

**`cfa2e47` revert: 回退全页面适老化整改** + **`1da32c0` feat: 全页面适老化整改 — 字号≥18sp + 触控≥44dp + 登录页交互优化**
- 1da32c0 整改 14 页 ~110 处字号 + ~20 处 padding，含登录页交互重做
- cfa2e47 回退主体（其余页面保持原样），只保留 00339cd 中的登录页改动

#### 标准版/长辈版边界收紧

**`001caef` fix(home): 修复标准版底部"我的"Tab 误跳长辈版**
- standard_home 底部"我的"Tab 原直跳 `/my`（长辈版 MinePage，带 ElderBottomNav），误把标准版用户带入长辈版生态。改为 SnackBar"该功能正在建设中"占位
- 唯一合法跨版本跳转：Hero 区"长辈版"按钮

**`7294a78` feat: 关闭标准版登录/搜索入口 + 长辈版全页面橙色统一**
- standard_home 删除"立即登录"横幅 + 搜索条改 SnackBar 占位（标准版仅保留品牌门面）
- 10 文件清除蓝色残留：login / verify / face_auth / search / search_result / mine / shebao_jiaona / shebao_query / persistent_banner / system_dialog 全部 standardPrimary → elderPrimary（或 lerp 派生）
- splash + standard_home 保留浙里办原版蓝色作为品牌还原标识

**`6d419ea` feat(mine): 未登录态展示长辈版橙色登录引导**
- MinePage 改 ConsumerWidget，watch loginProvider 替代 AuthState 单例
- 未登录时仅显示 `_LoginPrompt`（96 圆形头像 + 引导文字 + 橙色"去登录"胶囊按钮）
- PersistentBanner 同步用 `if (isLoggedIn)` 条件渲染，避免双登录入口重复
- _LogoutSection 走 loginProvider.notifier.logout()，保证响应式刷新
- _MyHeaderSection ConsumerWidget 化，移除死代码"游客"分支

#### AgentFab 全覆盖 + 模式色自适配

**`f8f7b20` feat: AgentFab 全页面覆盖 + 模式色自适配 + AgentPanel 死代码清理**
- AgentFab 改 ConsumerStatefulWidget，watch modeProvider 自动派生 primary 色（标准版 `#2D74DC` / 长辈版 `#FF6D00`），_FabIcon/_BubbleWindow/_ZhePainter/_ConfirmBtn/_DraftCard 全链路透传 primary
- 12 个新页面接入 AgentFab（Stack + Positioned.fill 统一模板）：standard_home / login / verify / search / search_result / mine / agent_settings / operation_logs / shebao_jiaona / shebao_query / yibao_jiaofei / yibao_query
- 删除 664 行 AgentPanel 死代码（无业务挂载，唯一引用为 wireframe 本地草图）

#### 杂项

**`a3a17b1` fix(ws): 客户端地址端口对齐后端 8080**
- 后端服务端口由 8000 调整为 8080，前端 WsClient._baseUrl 同步更新

**`59e088c` chore: 清理论文图表生成脚本及临时截图素材**

---

### 2026-05-17（会话 8）— AgentFab 悬浮助手 + 多页面重构 + 后端加固 + 论文素材

**`e07f0d8` feat: session-8 interactive polish, thesis draft, wireframes, user journey diagrams**

前端 · 新增组件
- 新增 AgentFab 悬浮助手组件（935 行）— 取代旧版底部代理面板入口，全局可拖拽 FAB + 长按唤起 + 状态指示
- 新增 wireframe_page.dart 低保真线框图页面（814 行），用于论文素材生成
- router.dart 新增 6 条 wireframe 路由（首页/刷脸/医保缴费/代理面板/授权卡/操作日志），总路由数 12 → 24

前端 · 多页面交互重构（v1.1 规范延伸到首页之外）
- drafts_page（310 行改动）— 草稿箱页面交互优化
- face_auth_page（269 行改动）— 刷脸授权页面
- pension_query_page（364 行改动）— 养老金查询页面
- elder_bottom_nav（138 行改动）— 长辈版底部导航重构
- mic_button（63 行改动）+ agent_bubble（81 行改动）+ agent_panel（31 行改动）— 代理 UI 元件统一打磨
- auth_card / theme / ws_client / wake_word_listener 小幅调整

前端 · 字体
- 集成 Noto Sans SC（Regular + Bold），pubspec.yaml 注册字体族

后端加固
- agent_core.py — Agno API 字段适配 + 异常捕获加固
- ws_handler.py（142 行改动）— ASR 三种错误细分（识别失败/超时/服务异常）+ text_input 异步化
- deepseek_client.py — 调用层异常捕获
- tts_adapter — TTS 按需生成（避免无意义占用）
- main.py — dotenv 加载，配置外部化

论文 + 素材
- 毕业设计论文草稿.md 大幅更新（871 行改动）
- docs/diagrams/ 新增图表素材：IA 图、4 张用户旅程图（+ 合成图）、6 张 wireframe（+ 合成图）、4 张实机截图（+ 合成图）
- 配套 Python 脚本：render_ia / render_user_journey / screenshot_pages / screenshot_wireframes / combine_*

---

### 2026-05-11（会话 7）— 前端交互体验全面优化

**`07d9e25` fix: 全页面交互反馈优化 — 48 处可交互元素补齐 ripple + 路由转场统一淡入**
- 三轮 architect 审查，48 个问题、约 100 个可交互元素补齐 ripple 反馈
- GestureDetector → Material+InkWell 统一模式，修复 ripple 被 Container 颜色遮挡
- 触控目标 <48dp 的元素扩大到 ≥44dp（IconButton constraints）
- 14 条路由转场从默认滑动改为统一 180ms FadeTransition
- onTap:null → onTap:(){} 补全所有占位交互

**`a811fa9` feat: 标准版首页交互体验全面优化**
- 闪屏页还原浙里办原版（"伴你一生大小事" slogan + 浙里办 logo）
- 新建 PressScaleWrapper 通用按下态组件（Listener+AnimatedScale+AnimatedOpacity+InkWell）
- ThemeData 集中配置 splashColor/highlightColor/hoverColor（标准版蓝/长辈版橙）
- 圆形图标按钮按下缩放 0.88 + 背景变色（white24→white38）
- 胶囊按钮按下背景 white24→white60 + 缩放 0.96
- 服务网格双层缩放（cell 0.96 + 图标圆 0.85）+ 圆底颜色加深 20%
- 底部导航栏自定义实现（_NavTab + Curves.elasticOut 弹性回弹）
- 搜索栏/消息条去掉缩放，搜索栏保留 ripple 直接跳转，消息条只保留按下变色
- 热门服务区从灰色占位改为横向滚动渐变卡片（人才服务/住房服务/交通出行/文旅消费）
- 占位功能统一弹 SnackBar "该功能正在建设中"
- PersistentBanner 加宽 + "立即登录"按钮改标准版蓝色

**`d4d853f` feat: 长辈版首页交互体验全面优化 + Tab 位移 bug 修复**
- 35 个可交互元素全部加 PressScaleWrapper 按下缩放+变色反馈
- 工具行/服务卡/网格图标/按钮统一 v1.1 交互规范
- 空操作统一弹 SnackBar "该功能正在建设中"
- 修复 Tab 标签切换文字位移 bug（选中/未选中态 padding 统一为 Spacing.md）
- 修复 Tab 选中态消失 bug（Ink 改 Container，不依赖 Material 祖先渲染背景）
- 底部导航栏首页/我的/小浙按钮加按下缩放
- 产出 docs/INTERACTION_REVIEW.md（交互审查报告，三轮审查记录）

---

### 2026-05-09（会话 6）— 代理设计报告 + 设置页 + E2E 测试

**`9fc73d9` feat: 小浙助手设置页 + AudioPlayer 播完回调 + 代理设计文档**
- 新增 AgentSettingsService（localStorage 持久化语音开关/语速两档）
- 新增小浙助手设置页（语音设置/操作记录/草稿箱/使用说明）
- mine_page 新增"小浙助手"入口，router 新增路由
- _speakHint 接入设置服务（语音开关 + 动态语速，替代硬编码 rate=0.9）
- AudioPlayer 新增 playBase64AndWait（onEnded 回调 + 30s 超时兜底）
- agent_panel task_done 改为等 TTS 播完再关闭面板
- 产出 AGENT_DESIGN_REPORT.md v1.3（代理设计分析报告，8 节 + 附录）
- 产出 USER_JOURNEY_TESTING.md v1.0（7 场景操作级测试旅程图）

**`4a88363` test: 7 场景 E2E 测试套件（按用户旅程图）**
- 7 个场景端到端测试（FakeWs + asyncio.Queue 驱动 WSHandler）
- 语音用 text_input 替代，TTS 用气泡文字验证替代
- 覆盖主路径 + 分支路径（拒绝确认/拒绝授权）+ 异常路径（ASR 没听清/超时）
- Flutter/IndexedDB 侧已标注 @pytest.mark.skip，留待 N4 真机验证

---

### 2026-05-09（会话 5）— 前端 P0 修复 + 功能补全 + 产品文档

**前端流程回退 + P0 Bug 修复**
- 还原旧版层级结构：闪屏页（1.5s）→ 标准首页 → 长辈首页，PhoneFrame 壳包裹所有路由
- main.dart 恢复 Riverpod ProviderScope + 双模式主题（AppTheme.of(mode)）
- 路由路径全部改用 AppRoutes 常量（消除 18 处硬编码）
- PersistentBanner 改为 Riverpod authProvider 响应式，登录后自动消失
- AgentPanel 协议对齐：修复 agent_wake payload、permission_response 消息类型、field_key/button_key 字段名与后端协议不一致等 P0 Bug
- WakeWordListener 单例竞争修复（引用计数模式）

**功能补全（待测）**
- 草稿写入链路：DraftService.autoSave 补全，字段变化自动写 IndexedDB；AgentPanel 收到 draft_hint 显示恢复提示
- 语音引导 TTS：cmd_highlight/cmd_fill_field/cmd_navigate 的 voice_hint 接入 Web Speech API SpeechSynthesis

**产品侧**
- 长辈首页插入搜索条入口（_EldSearchBar，橙底白框 52dp），弥补小浙助手占用搜索 FAB 后的入口缺失
- 后端 scene prompt 路由前缀与 AppRoutes 同步
- 产出 docs/USER_JOURNEY.md v1.0（4 场景用户旅程图 + 情感曲线 + 前端支撑评估 + 3 条 PM/architect 联合调整建议）

---

### c7e1d55 refactor: 项目重构 — 设计阶段全部完成，进入实施准备
- 项目结构重构，设计阶段收尾
- 更新 CLAUDE.md 当前阶段描述
- 标记进入编码实施阶段

### 5f82ef1 docs(agent-def): 组 C 完整定稿 + 新增横切原则 3 "权限一事一授"
- 组 C（代理能力矩阵与权限控制）完整定稿
- 新增横切原则 3：权限一事一授

### 9ca5b6b docs(agent-def): 组 C 能力矩阵定稿 + C2/C3 派生消解
- 能力矩阵定稿
- C2/C3 派生问题消解

### b499525 docs(agent-def): 组 B3 定稿 — 执行前必先复述确认
- 组 B3 定稿：代理执行操作前必须先复述确认

### d878f0c docs(agent-def): 组 B2 定稿 — 区分情景应答
- 组 B2 定稿：区分不同情景下的应答策略

### 627c2cf docs(agent-def): 组 B1 定稿 + 横切原则 2 "确定性操作代理止步"
- 组 B1 定稿
- 新增横切原则 2：确定性操作代理止步

### 3680289 docs(agent-def): 组 A 粗线条通过 — 底部对话区，细节留待原型
- 组 A（代理入口与交互形态）粗线条通过
- 底部对话区方案，细节留待原型阶段确定

### 653e5e1 docs(agent-def): 组 E 定稿 — 代理永远不主动
- 组 E 定稿：代理永远不主动发起交互

### 8fbd627 chore: 项目结构扁平化 — archive/ 一级承载所有冻结资产
- 将 tools/ bin/ 等移入 archive/ 目录
- archive/ 统一承载所有冻结资产（SDK、场景画布、脚本）

### 82a449a chore: 场景画布 v1 整体归档到 archive/scene-canvas-v1/
- Phase 1/2 的 Flutter Web 原型 + FastAPI 后端整体归档
- 不再追求像素级还原，作为未来演示背景载体保留

### 23e29af chore: 项目重新定义 — 旧设计归档 + 代理定义工作文档启动
- 旧设计文档（PRD/PROJECT_PLAN 等）归档至 docs/archive/pre-redefinition/
- 新建 AGENT_DEFINITION_QUESTIONS.md 工作文档
- CLAUDE.md 重写，确立"受控响应型智能代理"为核心创新点
