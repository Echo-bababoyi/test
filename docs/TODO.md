# 项目 Todolist

本项目唯一的活待办文件。新增问题/任务统一写入此文件。

**状态图例：** 🔲 待做 · 🧪 已做完待用户验证 · ✅ 用户已确认完成

---

## 当前待办

### 终极目标对齐阶段（2026-04-18 启动，进行中）

> 背景：Phase 1 完工 + Phase 2 部分完工 + 后端 Step 4 完工后，切入"从当前状态 → 毕业设计终极交付物"的对齐阶段。核心是把开题报告的目标落到可执行需求。

**已做**
- ✅ 技能装载第二轮：装 `flutter-animating-apps`（官方，Phase 3 刷脸动效需要）。FastAPI 官方仓库 clone 超时跳过（后端已有充分架构文档）。`.claude/skills/` 现有 8 个技能
- ✅ 发现 4 份用户已有的权威设计文档：`docs/用户调研报告(1).docx` / `用户需求文档(1).docx` / `核心场景流程设计文档(1).docx` / `交互逻辑设计文档(1).docx`（已用 zipfile 提取到 `/tmp/*.txt` 读过）
- ✅ 新记忆写入：`.claude/memory/feedback_no_timeline_pressure.md`（用户指示"不考虑时间问题"，做计划/PRD 时不按时间线约束，按依赖关系 + P0/P1/P2 排）
- ✅ 技能装载第三轮（2026-04-18 中期汇报需要）：`anthropics/skills@pptx`（72K installs，核心）+ `jwynia/agent-skills@presentation-design`（版式）+ `refoundai/lenny-skills@giving-presentations`（演讲），`.claude/skills/` 现有 11 个技能
- 🧪 中期进度汇报 PPT 交付（2026-04-18；`docs/midterm_report/中期进度汇报.pptx` 2.1MB / 9 页 / Teal Trust 色板 / 4 张截图 2×2 嵌入橙边框；讲稿 `outline.md`；用 pptxgenjs 脚本 `scripts/build_pptx.mjs` 可重跑；待用户观看后升 ✅）
- ✅ 新记忆写入：`.claude/memory/feedback_team_collaboration.md` 扩展"文档→代码边界要等命令"条款（2026-04-18）

**当前状态**
- ✅ `docs/PRD.md` v1.0（已废弃，3 处错误已在 v2.0 修正）
- 🧪 `docs/PRD.md` v2.0 已完成（2026-04-18；基于 4 份权威源文档完整重写；待用户验收）

**4 份源文档对 PRD 的修正（v2.0 重写时必须吸收）**
- 核心场景应是 **3 个**（语音查养老金/医保 / 验证码自动填写 / 刷脸语音引导），非 v1.0 的 5 个
- 用户调研"补充深度访谈"已做（阶段一 7 人 + 阶段二 6 人含陈伯伯等），v1.0 的"缺失"质疑错误
- 代理形象文档已定"**不设虚拟人物，用助手图标**"（温暖蓝/绿色），决策 5 已有答案
- 权限模型采纳 **L1/L2/L3 完整三级**（原架构文档"L3 不做"的说法作废）
- 需吸收：3 类用户画像 / F1-F8 功能需求 / UI1-UI7 / NF1-NF7 具体指标 / 对话风格术语替换表 / 5 种异常处理框架 / 3 种中断方式

**待拍板决策**
- ✅ 运行模式：Team（5 人长期团队，已启动）
- ✅ 用户测试分几轮：**双轮**（第一轮 Phase 1 灰块线框聚焦流程通顺；第二轮 Phase 2 贴皮完成后聚焦视觉+信任度；每轮 5-8 人，3 类画像各至少一人）
- ✅ 方言 STT：**P2 做，仅杭州话可选**（Baidu STT `dev_pid` 切换，默认普通话，不作验收硬指标）
- 🔲 P2-终 32 张对照截图交付时间（属执行排期，待 Phase 2 完工后定）

---

### Phase 1：主线黑白线框版（进行中）

按 `docs/archive/REPRODUCTION_PLAN.md` §五.4 分 5 批：

- ✅ 批次 1：SplashPage + StandardHomePage 灰块线框（2026-04-18 用户验收通过）
- ✅ 批次 2：ElderHomePage 回炉 + PersistentBanner 第三类 UI 元素（2026-04-18 用户 12 步验收通过，5 个事实错误全修）
- ✅ 批次 3：LoginPage + FaceAuthPage + VerifyPage（2026-04-18 用户 14 步验收通过，VerifyPage 路由歧义 bug 彻底修复）
- ✅ 批次 4：SearchPage + SearchResultPage（2026-04-18 用户 4 模块 14 步验收通过，VoiceInputService 首次激活脱僵尸）
- ✅ 批次 5：SocialInsurancePage + PensionQueryPage + MyPage（2026-04-18 用户验收通过，含 2 个 hotfix：服务页 push 导航 + SearchResult 搜索框可编辑态；ServiceRepository 首次激活脱僵尸）
- ✅ **Phase 1 终验收**（2026-04-18 端到端主线通过；含导航全量审查 + 4 处修正 + `/elder ↔ /my` NoTransitionPage + MyPage AppBar 橙底 hotfix）
### Phase 2：逐页像素级还原（进行中）

按 `docs/archive/REPRODUCTION_PLAN.md` §七 拆 7 批：

- ✅ P2-A：Token 补齐 + 全项目魔数替换（2026-04-18；纯重构无视觉改变；新增 `AppFontSize.tiny/caption`、`Spacing.lgPlus`、`AppRadius.phone`、`AppColors.phoneBg` 4 类 5 个 token；6 文件魔数替换；architect 1 处命名问题已修）
- ✅ P2-B：通用组件抽取 + 代码清理（2026-04-18；新建 `PermissionFlowHelper`、ElderHome IndexedStack 用 ListenableBuilder 局部重建、7 Section const、3 页面降级回 Stateless/Stateful）
- 🧪 P2-C：Noto Sans SC 字体引入 + StandardHomePage / ElderHomePage 贴皮（a6500df）
- 🧪 P2-D：LoginPage / FaceAuthPage / VerifyPage 贴皮（8758c61）
- 🧪 P2-E：SearchPage / SearchResultPage 贴皮（acbdcc6）
- 🧪 P2-F：SocialInsurancePage / PensionQueryPage / MyPage 贴皮（0e7c7b0）
- 🧪 P2-终（1/3）：测试补齐 — 6 个模块 33 测试已提交（f53f1be；本地环境无 GUI 暂无法独立核实，用户确认后升 ✅）
- 🔲 P2-终（2/3）：32 张对照截图（原图 vs 复刻，每页一张）
- 🔲 P2-终（3/3）：打 `v1.0-baseline` tag

### Agent UI 规格与组件

- 🧪 `docs/AGENT_UI_SPEC.md` v0.1 PM 初稿已完成（2026-04-18；4 组件：AgentSpeechBubble / IntentProposalCard / ProgressIndicator / StopButton）
- 🔲 Agent UI 规格文档 architect review（review 后升 🧪，批准后方可交 frontend 实施）
- 🔲 frontend 实施 Agent UI 4 组件（依赖：architect review 通过）

### agent-backend：智能代理后端（进行中）

- 🧪 Step 1+2：FastAPI 骨架 + WebSocket echo（5f6ebcd）
- 🧪 Step 3：Agno 最小 Agent + 硬编码规则调度（3ef9cc8）
- 🧪 Step 4：接 DeepSeek-V3 真 LLM，替代硬编码（488e503）
- 🔲 Step 5：前后端联调（Flutter WebSocket ↔ FastAPI agent）
- 🔲 Step 6：验收 + 文档

### Phase 3：智能代理 UI 与联调

- 🧪 backend 出 WebSocket schema 草案（architect review 完成）
- 🧪 architect review schema（有条件通过）
- 🔲 frontend 实施 AgentState + agentStateProvider
- 🔲 frontend 实施 StopButton + AgentProgressIndicator（可并行）
- 🔲 frontend 实施 AgentSpeechBubble
- 🔲 frontend 实施 IntentProposalCard
- 🔲 PhoneFrame 接入 `_AgentOverlayLayer`
- 🔲 PersistentBanner 接入 agentStateProvider
- 🔲 场景 A/B/C 串联端到端 demo

### Phase 1 小修（低优，批次 3-5 哪次顺手哪次做）

- 🔲 `StandardHomePage._TopBarRow` 右侧加**通知铃铛**灰块占位（batch 1 reviewer 发现）

### 收尾测试待补（不在批次 3–5 做，Phase 1 终验收前一次性补）

- 🔲 **P0** `PersistentBanner` 四种状态 widget test：未登录+未关 / 已登录 / dismiss / dismiss 后登出
- 🔲 **P0** `loginProvider` + `loginBannerDismissedProvider` 状态流转 unit test（两者独立，dismiss 不随 logout 重置）
- 🔲 **P1** `ElderHomePage` Tab 切换触发 `IndexedStack.index` 正确，非 Tab 区块不重建 widget test
- 🔲 **P1** `SplashPage` 1500ms 后自动跳 `/home`、`_navigated` 防重复 widget test + fake timer
- 🔲 **P2** `AppRouter` 11 条路由全部可导航 + ShellRoute 包 PhoneFrame integration test
- 🔲 **P2** `AppTheme.of(mode)` 主色切换 unit test（`#2D74DC` / `#FF6D00`）

### Phase 2 必修项（已登记，贴皮阶段必做）

- 🔲 `_EldTabCardSection` IndexedStack 改用 `ListenableBuilder(listenable: tab)` 局部重建（当前 `_tab.addListener(setState)` 每帧全页重建，虽不影响正确性但开销冗余）
- 🔲 `PersistentBanner.bannerButton` 在长辈模式下读 `modeProvider` 改用 `elderPrimary`（截图里长辈版 banner 按钮是橙色而非蓝色）
- 🔲 Banner 文字颜色从 `Colors.white` 改为灰色（对齐截图）
- 🔲 长辈版 AppBar「个人频道」pill 加刷新/同步图标（对齐截图）
- 🔲 长辈版底部 FAB 颜色从 `Colors.grey[500]` 改为 `AppColors.elderPrimary`（对齐截图）
- 🔲 `LoginPage` 登录按钮 guard：手机号空时置灰不可点（batch 3 reviewer 发现）
- 🔲 `FaceAuthPage._AuthenticatingView` "模拟认证成功 → 长辈版首页"按钮文案替换为正式占位（batch 3 architect 发现）
- 🔲 `VerifyPage` 补"发送验证码"按钮（当前跳过该步直接展示 OTP 输入态；batch 3 reviewer 发现）
- 🔲 `LoginPage` 底部"其他证件 / 新用户注册 / 忘记密码 / 登录遇到问题 / 其他登录方式"辅助链接目前纯静态文字，Phase 2 按需决定是否联通
- 🔲 `search_page.dart _VoiceInputContent` 升级 StatefulWidget，`listen()` 期间显示"说话中..."占位（消除 800ms 空窗）
- 🔲 `search_page.dart _VoiceInputContent` 麦克风按钮颜色读 `modeProvider`（标准版进入时当前是橙色会冲突）
- 🔲 `SearchPage` 联想词精确匹配改为前缀/模糊匹配（输入"医保"应也能出现联想）
- 🔲 `search_page.dart / search_result_page.dart` 多处 `Color(0xFF...)` 硬编码改用 `AppColors` 常量；搜索框 `borderRadius(18)` 走 token
- 🔲 `_ResultTabRow` 加 `const` 构造器
- 🔲 考虑把 `SearchPage` 麦克风 chain 和 `FaceAuthPage` 刷脸 chain 抽共用的 `PermissionFlowHelper`（三段式 Overlay→SystemDialog→Overlay）
- ✅ Phase 1 终验收时补 `CLAUDE.md` 导航约定（go/push/replace/NoTransitionPage/PersistentBanner/URL 同步 全部落地）
- 🔲 `MyPage` FAB 颜色 `Colors.grey[700]` —— 截图里像灰，但 reviewer 批次 5 建议改 `elderPrimary`，Phase 2 上真机再定
- ✅ Phase 1 终验收时修 SearchResult URL 脱同步（改用 `context.replace` + 从 URL 读 q）
- 🔲 `_MyActivitySection` / `_MyCertSection` / `_MyManagementSection` / `_MyRecommendSection` / `_MySettingsSection` 加 const 构造器
- ✅ `AppFontSize` 补 `tiny=11` / `caption=13`（P2-A 完成）
- ✅ `Spacing` 补 `lgPlus=20`（P2-A 完成；原叫 `xl2` 被 architect 纠错改名）
- ✅ `AppRadius` 补 `phone=24`（P2-A 完成）
- ✅ `AppColors` 补 `phoneBg=0xFF1E1E1E`（P2-A 完成）
- ✅ `system_dialog.dart` / `in_app_overlay.dart` / `persistent_banner.dart` 里所有魔数替换为 token 引用（P2-A 完成）
- 🔲 `_EldToolBarSection` 加 `const` 构造器（build 体是纯 const Widget 树）
- 🔲 Phase 1 终验收前复查 6 个 `ConsumerWidget` 页面（`LoginPage` / `FaceAuthPage` / `SearchPage` / `SearchResultPage` / `SocialInsurancePage` / `PensionQueryPage`）是否还需要 `ref`，未用的降级回 `StatelessWidget`

---

## 代码状态登记

> 以下文件**当前未被任何页面调用**，但属**刻意保留的扩展接口骨架**，Phase 2 代码清理时**禁止误删**。

| 文件 | 接入时机 | 用途 |
|------|---------|------|
| ~~`lib/services/voice_input_service.dart`~~ | ~~批次 4 SearchPage 升级时~~ | ✅ **已激活**（batch 4，SearchPage I4 浮层点 mic 后调 `listen()`） |
| `lib/services/face_auth_service.dart` | Phase 2 FaceAuthPage 接真逻辑时 | 刷脸认证扩展点（FaceAuthService mock）；batch 3 未接（仅 setState 假通过），Phase 2 激活 |
| ~~`lib/services/service_repository.dart`~~ | ~~批次 4–5 服务页升级时~~ | ✅ **已激活**（batch 5，SocialInsurancePage `_selfPayItemsProvider` via `myFrequent()`） |
| `lib/core/intent/app_intent.dart` | Phase 4 后 | 智能代理操作 UI 扩展点（AppIntent + Dispatcher） |
| `lib/core/logging/interaction_logger.dart` | Phase 4 后 | 行为日志扩展点（InteractionLogger） |

---

## Phase 3 已决策（2026-04-18）

> 来源：architect 技术栈评审（`docs/TECH_STACK_REVIEW.md §D.5`，D1-D5 共 5 项）。D1（WebSocket schema）已单独派给 backend，状态见 Phase 3 区块。

| 编号 | 决策 | 备注 |
|---|---|---|
| **D2** | backend URL 用 `--dart-define=WS_URL=...` 注入，frontend 用 `String.fromEnvironment('WS_URL')` 读取，不硬编码 | `TECH_STACK_REVIEW.md §D.5` 第 2 行 |
| **D3** | `InteractionLogger` Phase 3 仅写 LocalStorage，不出 UI；操作记录列表页（F6/UI7）留 Phase 4 实施 | `TECH_STACK_REVIEW.md §D.5` 第 3 行 |
| **D4** | L3 权限（身份证级敏感操作）Phase 3 不做，留 Phase 4；答辩场景 A/B/C 不依赖 L3 | `TECH_STACK_REVIEW.md §D.5` 第 4 行 |
| **D5** | 草稿保存（F8）TTL **30 天**，与 UI7 操作记录保留策略对齐（替换原草案 7 天）| `TECH_STACK_REVIEW.md §D.5` 第 5 行 |
| **场景C** | 介入模式：**B-半主动**；D1 豁免边界 ① 当前页为验证码输入页 ② 非阻塞 InAppOverlay ③ 用户显式点"帮填"才执行 | PRD §九 D1 豁免 + §七 场景 C（v2.1，2026-04-18）|

---

## 已提交待验证

<!-- 新记录插入最上方 -->

_（暂无——批次 2 已被打回，5 个事实错误详见当前待办「批次 2 回炉」）_

---

## 已完成

<!-- 用户确认后从"已提交待验证"迁移到这里 -->

### Phase 1：主线黑白线框版 — ✅ 整体通过（2026-04-18）

**11 页面全部灰块线框完成，主线端到端验收通过，Phase 2 开工就绪。**

关键里程碑：
- 两类弹窗 + PersistentBanner 三类 UI 元素体系建立
- 刷脸登录 + SMS 验证码两条分支全线打通
- 搜索 → 结果 → 服务三级 drill-down 含麦克风权限流程
- `/elder ↔ /my` tab 级无动画切换
- 导航约定权威定稿（`CLAUDE.md > 导航决策约定`）
- 3 个扩展接口首次激活（VoiceInput / ServiceRepo），2 个仍僵尸（FaceAuth / AppIntent / Logger 保留到后续阶段）

#### 批次 5：SocialInsurancePage + PensionQueryPage + MyPage（2026-04-18）

- ✅ SocialInsurancePage：ConsumerStatefulWidget + `enum _SubPage` + IndexedStack 三子状态（主页 / 我为自己缴 / 缴费记录），URL 保持 `/service/social-insurance`；back 按钮智能（子页回主页，主页 pop 回 Search）
- ✅ PensionQueryPage：个人基本信息卡（蓝色渐变）+ 3 张险种卡（深蓝紫渐变）
- ✅ MyPage：7 Section（头像 / 活动记录 / 证照 / 信息 / 管理 / 推荐 / 设置）+ BottomAppBar + FAB centerDocked + PersistentBanner；AppBar 橙底（hotfix）
- ✅ ServiceRepository 首次激活（social_insurance_page.dart 的 `_selfPayItemsProvider` via `myFrequent()`，脱僵尸）
- ✅ **Hotfix 1**：SearchResultPage → 服务页导航由 `go` 改 `push`（之前 `go` 替换栈导致服务页 back 无效）
- ✅ **Hotfix 2**：SearchResultPage 搜索框升级为可编辑状态机（× 清空 + 进入编辑态 + 显联想词 + 回车/点联想词退出编辑态展示结果）；提取 `SearchSuggestionList` 为公共组件供 SearchPage + SearchResultPage 共用
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过 / reviewer 预审通过 / 用户 12+ 步验收通过

#### 批次 4：SearchPage + SearchResultPage（2026-04-18）

- ✅ SearchPage：顶栏搜索框 + 麦克风按钮；三态内容（空/医保缴费/养老金查询）；联想词列表 11/1 条
- ✅ 麦克风三级链路（I3→S3→I4）按类别正确；I4 内调用 `voiceInputServiceProvider.listen()` 首次激活（脱僵尸），mock 返回"医保缴费"
- ✅ SearchResultPage：读 `?q=...` query 参数，中文自动编解码；医保缴费→社保费缴纳→`/service/social-insurance`；养老金查询→社保查询→`/service/pension-query`；空 query 优雅降级"暂无相关服务"
- ✅ 导航纪律：搜索链走 `context.push`（保返回栈），服务页跳走 `context.go`（栈替换）
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect review ✅ / reviewer 14 步脚本 / 用户分 4 模块验收全通过

#### 批次 3：LoginPage + FaceAuthPage + VerifyPage 重对齐（2026-04-18）

- ✅ LoginPage 全量重写：淡蓝底 + 手机号输入 + 个人/法人切换占位 + 条款 InAppOverlay 链路
- ✅ FaceAuthPage 全量重写（升级 ConsumerStatefulWidget）：默认双按钮 → 请求刷脸 InAppOverlay → 摄像头 SystemDialog → `setState(_isAuthenticating=true)` **留在本页**（彻底修复误跳 verify 路由的 bug）；另"其他方式认证"→ InAppOverlay → 跳 /login/verify
- ✅ VerifyPage 彻底重对齐为 SMS 验证码页：标题"请输入验证码"、6 格 OTP 占位、55s 倒计时、确认 → SystemDialog → 登录成功跳 /elder；**所有刷脸残留字样已删除**
- ✅ 两类弹窗链路首次完整拉通（5 个弹窗：I1 / I2 / S1 / I5 / S2）
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过 / reviewer 14 步脚本 / §四 / §六 全部通过 / 用户 14 步验收通过
- 2 个 Phase 2 小修已登记（登录按钮 guard + 模拟认证按钮文案）

#### 批次 2：ElderHomePage 回炉 + PersistentBanner（2026-04-18）

- ✅ 新增第三类 UI 元素 `PersistentBanner`（常驻横条，非阻塞，× 关闭 session 内不重现，跨页共享 dismiss 态）
- ✅ 立即登录从 InAppOverlay 升级为 PersistentBanner，标准版 + 长辈版都挂
- ✅ ElderHomePage 结构大改：工具行 / 政务热线 / Tab 卡片 / 各常驻栏目按截图分层（工具行随滚、AppBar 固定只留地区+个人频道）
- ✅ Tab 降级为 IndexedStack 嵌入式切换器，只影响"浙里医保"那一小块；其他区块全常驻
- ✅ 长辈版底部导航改为 BottomAppBar + FAB centerDocked（中间大圆麦克风按钮跳 `/search`）
- ✅ 删 ElderHomePage AppBar 右上搜索 icon
- ✅ REPRODUCTION_PLAN §四 + §六 同步修订（PM 主笔）
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过（1 处路由硬编码已修）/ reviewer 对照验收条通过 / 用户 12 步验收通过
- 5 个 Phase 2 小修已登记到「当前待办 > Phase 2 必修项」

#### 批次 1：SplashPage + StandardHomePage 灰块线框（2026-04-18）

- ✅ SplashPage：1.5s 自动跳 `/home`，双重防护（`mounted` + `_navigated`）
- ✅ StandardHomePage：6 个语义 Section + 5 Tab 底部导航；蓝色 `#2D74DC` Hero 区 + 2×4 服务网格 + 长辈版入口按钮 + 搜索框入口
- ✅ 质量：`flutter analyze` 0 issues / `flutter build web` 通过 / architect code review 通过 / reviewer 对照 §四 验收条通过 / 用户 7 步点击路径通过
- 已知轻度问题（留到后续批次顺手改）：`_TopBarRow` 右侧缺通知铃铛占位（见当前待办「Phase 1 小修」）

### Phase 0：项目骨架（2026-04-17）

- ✅ 前置决策 5 项：Riverpod / go_router / Flutter Web 目标 / SDK 项目级安装（`tools/flutter/` 3.41.7）/ 基准分辨率 405 × 880 dp
- ✅ Flutter 项目初始化 + feature-based 目录结构
- ✅ Riverpod + go_router 集成（`flutter_riverpod ^3.3.1` / `go_router ^17.2.1`）
- ✅ 双主题 + 设计 token 文件（`lib/core/theme/`）
- ✅ 两套弹窗组件族骨架（`SystemDialog` 阻塞 / `InAppOverlay` 非阻塞，物理分开）
- ✅ 11 个页面占位 Scaffold + 路由全连通
- ✅ 6 个扩展接口骨架：`VoiceInputService` / `FaceAuthService` / `AppIntent + Dispatcher` / `InteractionLogger` / `ServiceRepository`（Semantics 留到 Phase 2 贴皮时按页面添加）
- ✅ PhoneFrame：Web 端 405×880 dp 固定画框 + FittedBox 等比缩放
- ✅ 验收通过：`flutter analyze` 0 issues / `flutter build web` 30 秒构建 / 用户浏览器端跑通 7 步点击路径

---

## 提交记录

> 新记录插入最上方。完整 diff 看 `git log`；本区只概括每个 commit 做了什么。

### 2026-04-18 · `<pending>` · refactor(phase-2/B): 通用组件抽取 + 代码结构清理
- 新建 `lib/core/widgets/permission_flow_helper.dart`（三段式权限请求 helper；API 用 `Widget Function(VoidCallback onProceed) guideContentBuilder` 传 onProceed 回调注入给浮层）
- `search_page.dart` / `face_auth_page.dart` 改用 helper（删除内联三段式、删除 `_showMicSystemDialog` / `_showCameraSystemDialog`、移除 `system_dialog.dart` import）
- `elder_home_page.dart` 删 `_tab.addListener(setState)`，改 `ListenableBuilder(listenable: tab)` 包 IndexedStack，局部重建替代全页 rebuild
- 7 Section Widget const 构造器：_EldToolBarSection / _ResultTabRow / _MyActivity/Cert/Management/Recommend/Settings Section
- 3 页面 ConsumerWidget 降级：LoginPage / SearchResultPage → StatefulWidget；PensionQueryPage → StatelessWidget（各自 ref 零使用，`flutter_riverpod` import 已移除）
- 无视觉改变，纯重构
- architect review ✅（FastCheck 全部通过）
- 附带：P2-A commit `<pending>` 回填为 `f211fed`

### 2026-04-18 · `f211fed` · refactor(phase-2/A): Token 补齐 + 全项目魔数替换
- `lib/core/theme/design_tokens.dart`：新增 `AppFontSize.tiny/caption`、`Spacing.lgPlus`、`AppRadius.phone`、`AppColors.phoneBg`
- 6 文件魔数替换：`system_dialog.dart` / `in_app_overlay.dart` / `phone_frame.dart` / `standard_home_page.dart` / `elder_home_page.dart` / `search_page.dart`
- 纯重构无视觉变化（所有替换 literal→token 等价）
- architect 1 处命名纠错（xl2→lgPlus）
- Phase 2 7 批次的第一块地基
- 附带：PM §七 Phase 2 计划 commit `<pending>` 回填为 `59733e1`

### 2026-04-18 · `59733e1` · docs(phase-2): PM 新增 §七 Phase 2 实施计划（7 批次）
- `docs/archive/REPRODUCTION_PLAN.md` 484–700 行：Phase 2 拆 7 批（A 地基 / B 通用组件 / C 首页 / D 登录 / E 搜索 / F 服务+我的 / 终 验收打 tag）
- 每批含：涉及文件、TODO 引用、依赖关系、可勾选视觉检查点、工作量估计
- P2-D/E/F 可在 P2-B 后并行
- 用户审阅通过，按串行推进，先派 P2-A
- 附带：Phase 1 终验收 commit `<pending>` 回填为 `7d55ed1`

### 2026-04-18 · `7d55ed1` · chore(phase-1): 导航全量审查 + 4 处修正 + NoTransitionPage + CLAUDE.md 约定落地（Phase 1 正式收尾）
- architect 出权威导航原则（`go/push/pop/replace` 决策矩阵 + NoTransitionPage 适用 + PersistentBanner 挂载 + URL 同步策略）
- reviewer 全项目 grep 34 处 navigation 调用点事实清单（`context.go × 13 / push × 3 / pop × 6 / Navigator.pop × 12`）
- 4 处违规修正：
    `standard_home_page.dart` / `elder_home_page.dart` / `my_page.dart` 的 `go(search)` → `push(search)`
    `search_result_page.dart` 删 `_query` 缓存字段，改用 `context.replace` + `GoRouterState.of(context).uri.queryParameters['q']`
- `app_router.dart`：`/elder` 和 `/my` 改用 `NoTransitionPage`（tab 级切换瞬时无动画）
- `my_page.dart` AppBar 橙底 hotfix（个人账号白字 / 切换 pill 白底黑字 / 白色铃铛）
- `CLAUDE.md` 新增「导航决策约定」整节落入
- 用户端到端验收：a/b/c 三路搜索入口取消返回正确、d 搜索结果 URL 同步、e 后退不出现历史替换态、`/elder ↔ /my` 无动画
- 附带：批次 5 commit 记录 `<pending>` 回填为 `1f02627`

### 2026-04-18 · `1f02627` · feat(phase-1): 批次 5 — SocialInsurance + PensionQuery + MyPage（含 2 hotfix，Phase 1 结构收尾）
- `lib/features/service/social_insurance_page.dart`：ConsumerStatefulWidget + enum _SubPage + IndexedStack 三子状态；首次落地 §5.1 Q1 IndexedStack 规范；URL 保持不变只切 state
- `lib/features/service/pension_query_page.dart`：个人基本信息卡 + 3 险种卡（简单单页）
- `lib/features/my/my_page.dart`：7 Section 拼接 + BottomAppBar + FAB + PersistentBanner；AppBar 橙底（hotfix: 原白底不符合长辈版身份标识）
- ServiceRepository 首次激活：`social_insurance_page.dart` 的 `_selfPayItemsProvider` via `FutureProvider.autoDispose` + `myFrequent()` 脱僵尸
- **Hotfix 1**（`lib/features/search/search_result_page.dart`）：跳服务页 `context.go` → `context.push`（之前 go 替换栈导致服务页 back 无效；batch 4 architect 判断错误已纠正）
- **Hotfix 2**（`lib/features/search/search_result_page.dart` + 新建 `suggestion_list.dart` + 改 `search_page.dart`）：搜索框从只读展示升级为可编辑状态机（× 清空 + 显联想词 + 提交退出编辑态）；提取 `SearchSuggestionList` 公共组件 SearchPage/SearchResult 共用
- architect batch 5 review ✅ + reviewer 预审 ✅ + 用户分段验收全过（2 轮 hotfix 迭代，最终全通）
- 附带：批次 4 commit 记录 `<pending>` 回填为 `afba16c`

### 2026-04-18 · `afba16c` · feat(phase-1): 批次 4 — SearchPage + SearchResultPage
- `lib/features/search/search_page.dart`：ConsumerStatefulWidget，搜索框 + 麦克风三态；麦克风三级链路 I3→S3→I4；I4 内 `voiceInputServiceProvider.listen()` 首次激活（mock 返回"医保缴费"）；搜索结果用 `context.push` 保返回栈
- `lib/features/search/search_result_page.dart`：读 `?q` query；医保缴费→社保费缴纳→`/service/social-insurance`；养老金查询→社保查询→`/service/pension-query`；空 query 降级"暂无相关服务"；服务页跳用 `context.go`（栈替换）
- `VoiceInputService` 从僵尸升级为已激活
- architect + reviewer 双 review 通过，用户 4 模块 14 步验收通过
- 附带：批次 3 commit 记录 `<pending>` 回填为 `24603e2`

### 2026-04-18 · `24603e2` · feat(phase-1): 批次 3 — LoginPage + FaceAuthPage + VerifyPage 重对齐
- `lib/features/login/login_page.dart`：ConsumerStatefulWidget，手机号输入 + 条款 InAppOverlay → 跳 FaceAuthPage
- `lib/features/login/face_auth_page.dart`：升级 ConsumerStatefulWidget 管 `_isAuthenticating` 子状态；双按钮 → 请求刷脸 InAppOverlay → 摄像头 SystemDialog → setState 进认证中占位（URL 保持不动，修复批次 2 遗留的误跳 verify 路由 bug）；其他方式认证 → InAppOverlay → 跳 /login/verify
- `lib/features/login/verify_page.dart`：全量重写为 SMS 验证码页（标题/OTP/倒计时/确认 SystemDialog）；彻底清除刷脸残留
- 两类弹窗链路首次完整拉通：I1 / I2 / S1 / I5 / S2
- architect + reviewer 双 review 通过，用户 14 步验收通过
- 附带：批次 2 回炉的提交记录 `<pending>` 由本次 commit 时回填为 `d3717e3`

### 2026-04-18 · `d3717e3` · feat(phase-1): 批次 2 回炉 — PersistentBanner + ElderHomePage 重构
- **文档层（PM 主笔修订）：** `docs/archive/REPRODUCTION_PLAN.md` §四 StandardHomePage 新增登录 Banner 验收条；§四 ElderHomePage 全节重写（AppBar 只留地区+个人频道、工具行移入 body、政务热线到 TabBar 上方独立白卡、Tab 只管紧邻一块、其他区块全常驻、底部导航改 3 项含中间大圆搜索）；§六 新增三类 UI 元素定义表（SystemDialog / InAppOverlay / PersistentBanner）+ 弹窗清单按类型重分组（S3 / I5 / P1）
- **新建组件：** `lib/core/widgets/persistent_banner.dart`（第三类 UI 元素骨架：声明式 ConsumerWidget，读 `loginProvider` + `loginBannerDismissedProvider` 双条件控制显示；内含深色胶囊 + × 关闭 + "立即登录"按钮 → `AppRoutes.login`）
- **新增状态：** `lib/core/state/app_state.dart` 加 `LoginBannerDismissedNotifier` + `loginBannerDismissedProvider`（Riverpod v3 无 StateProvider，用 NotifierProvider<bool>）
- **设计 token：** `lib/core/theme/design_tokens.dart` 加 `AppColors.bannerBg` / `bannerButton`
- **StandardHomePage：** 删 `_LoginPromptSection`，body 改 `Stack + Align(bottomCenter) PersistentBanner`
- **ElderHomePage 整页重构：** 全量重写；AppBar 去搜索 icon；工具行 / 政务热线 / Tab 卡片 / 线上一站办 / 线下就近办 / 授权办 / 页脚 全部移入 body `SingleChildScrollView > Column`；Tab 内容走 `IndexedStack` 只包含"浙里医保"那一块；底部 `BottomAppBar + FAB.centerDocked`（麦克风大圆 → `/search`）；body `Stack + PersistentBanner`；彻底删除 `addPostFrameCallback + InAppOverlay.show + _LoginPromptContent`
- 回炉背景：用户 12 步验收发现 5 个事实错误，这轮全部修复
- architect review：⚠️→ ✅（1 处路由硬编码 `/login` 已改为 `AppRoutes.login`）
- 顺带修：批次 1 提交记录的 `<pending>` 回填为 `4504f06`

### 2026-04-18 · `4504f06` · feat(phase-1): 批次 1 — SplashPage + StandardHomePage 灰块线框
- `lib/features/splash/splash_page.dart`：`ConsumerWidget` → `StatefulWidget`，`initState` delay 1.5s 自动跳 `/home`，双重防护（`mounted` + `_navigated`）
- `lib/features/home/standard_home_page.dart`：拆 6 个语义 Section（Hero / ServiceGrid / NewsBar / HotService / LoginPrompt / DevNav）+ `_BottomNavBar`；Hero 区蓝底含顶栏 logo 占位、3 快捷操作（含「长辈版」入口）、Banner 占位、搜索框；服务网格 2×4；保留 `_DevNavSection` 开发导航面板（Phase 2 删）
- frontend 自验 + architect review 双通过
- Phase 1 分 5 批实施计划同步落入 `docs/TODO.md`

### 2026-04-18 · `3dc1d9e` · docs: Phase 1-4 完美复刻计划（PM 主笔 + architect 技术章节）
- 新增 `docs/archive/REPRODUCTION_PLAN.md`（443 行）——团队产出的完美复刻计划
- 含 32 张截图→Flutter 资源映射、主线 + 4 分支流程图、11 页 P1-P11 优先级、每页可勾选验收标准、5 个技术决策、10 个弹窗清单、5 个复刻瓶颈预警

### 2026-04-18 · `6c60c2e` · docs(memory): 团队成员默认用 Sonnet 模型
- `.claude/memory/feedback_team_collaboration.md` 新增一节
- 启动团队时 5 个成员默认用 sonnet，team-lead 保持当前模型（opus）做协调

### 2026-04-18 · `4c2daad` · chore: 装 7 个 Claude Code skill 协助 Phase 1-2 开发
- `.claude/skills/` 新增 7 个纯 markdown skill（合计 <60 KB）
- find-skills（元技能）+ flutter 官方 5 件套（accessibility / layouts / state / theming / navigation）+ arvindrk/extract-design-system
- `skills-lock.json` 入库

### 2026-04-17 · `41b3be3` · feat(phase-0): Flutter 骨架 — 11 页 + Riverpod + go_router + 两套弹窗 + 6 扩展接口
- `lib/` 完整骨架（core + features + services）
- 11 页面占位 Scaffold + 路由全连通 + 双主题 + 双弹窗组件族（SystemDialog / InAppOverlay）+ 6 扩展接口 mock（VoiceInput / FaceAuth / ServiceRepository / AppIntent / InteractionLogger / PhoneFrame）
- `flutter analyze` 0 issues / `flutter build web` 30 秒通过

### 2026-04-17 · `9ce9842` · chore: 安装项目级 Flutter SDK + 包装脚本
- `bin/flutter` / `bin/dart` 包装脚本（自动走 flutter-io.cn 镜像）
- Flutter 3.41.7 装在 `tools/flutter/`（gitignored，不入库）

### 2026-04-17 · `d90606a` · chore: 立项 — 项目蓝图、文档结构、记忆系统
- `CLAUDE.md` / `docs/` / `.claude/memory/` / `.gitignore`
- 32 张截图 + 页面逻辑 + 开题报告 + 5 份 persona 骨架
