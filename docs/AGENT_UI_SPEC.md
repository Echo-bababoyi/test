# Agent UI 组件规格文档

> 主笔：PM
> 日期：2026-04-18
> **v1.2 — 同步 D2-D5 决策（2026-04-18）**
> 本文件是 `docs/PRD.md §五` 界面需求的视觉落地规格。
> 命名约定与 `lib/core/theme/design_tokens.dart` 中的 AppColors / AppFontSize / Spacing / AppRadius token 体系对齐。

---

## 零、全局约定

| 维度 | 约定 |
|---|---|
| 坐标系 | 相对 PhoneFrame（405 × 880 dp）内壁 |
| 颜色引用 | 使用 `AppColors.*` token，不写 HEX 硬编码 |
| 字号引用 | 使用 `AppFontSize.*` token |
| 圆角引用 | 使用 `AppRadius.*` token |
| 间距引用 | 使用 `Spacing.*` token |
| 动效默认时长 | 入场 200ms / 退场 150ms（ease-in-out）|
| 无障碍 | 所有组件必须挂 `Semantics` 标签，label 用中文口语 |

**代理配色（助手图标色）**：新增 token `AppColors.agentPrimary = Color(0xFF0070E0)`（温暖蓝，WCAG AA 白字对比度 ≈ 5.0:1，满足 NF5）。**代理色独立于标准版蓝 / 长辈版橙，跨模式固定，作代理身份区分信号。** token 由 frontend 在 `design_tokens.dart` `AppColors` 末尾新增（见 §六 已决策 Q1）。

---

## 一、AgentSpeechBubble（代理语音气泡）

### 1.1 设计意图

代理的"发言窗口"。对应 PRD §六.4 预告-确认-执行中"预告"阶段的文字呈现，以及执行完成后的结果反馈。气泡应让用户感知"代理在说什么"，同时不遮挡页面主内容区（锚定屏幕底部，最小侵入）。

### 1.2 布局位置

```
┌─────────────── PhoneFrame ───────────────┐
│                                          │
│            [页面主内容区]                 │
│                                          │
│  ┌──────────────────────────────────┐   │
│  │  🤝  代理文字内容（最多 3 行）      │   │  ← AgentSpeechBubble
│  │       [展开历史] [×关闭]           │   │
│  └──────────────────────────────────┘   │
│  [底部导航 / BottomAppBar]               │
└──────────────────────────────────────────┘
```

- 位置：`Align(alignment: Alignment.bottomCenter)`，浮在页面内容之上，BottomAppBar 之上
- 左右边距：`Spacing.lg`（16dp）
- 距 BottomAppBar 上沿：`Spacing.sm`（8dp）

### 1.3 尺寸

| 维度 | 值 |
|---|---|
| 宽度 | PhoneFrame 内宽 - 2 × `Spacing.lg` = 405 - 32 = **373 dp** |
| 最小高度 | 56 dp（单行文字）|
| 最大高度 | 120 dp（3 行文字，超出截断 + "展开"按钮）|
| 内边距 | `Spacing.lg`（16dp）水平，`Spacing.sm`（8dp）垂直 |

### 1.4 视觉规格

| 属性 | 值 |
|---|---|
| 背景色 | `AppColors.agentPrimary`（固定温暖蓝，不随 modeProvider 变化；详见 §六 已决策 Q2）|
| 文字色 | `Colors.white` |
| 字号 | `AppFontSize.bodyLarge`（16sp）；助手图标旁标签 `AppFontSize.caption`（13sp）|
| 圆角 | `AppRadius.xlarge`（16dp），右下角 `0`（气泡尖角效果，如 Flutter 实现困难可全圆角）|
| 阴影 | `BoxShadow` offset(0,2)，blur 8，color `Colors.black.withOpacity(0.15)` |
| 助手图标 | 圆形，直径 32dp，`AppColors.agentPrimary` 背景，白色图标；左侧居中对齐 |

### 1.5 交互态

| 状态 | 表现 |
|---|---|
| 入场 | 从底部 +20dp 位移 + 透明度 0→1，200ms ease-in-out |
| 退场 | 透明度 1→0 + 向下 +20dp，150ms ease-in |
| 展开（超过 3 行时）| 高度动画展开至自然高度（最大 200dp），300ms ease-in-out |
| × 关闭按钮 | 点击后触发退场动画，代理状态归零 |
| 文字打字机效果 | 每字符以 30ms 间隔逐字显示（同步 TTS 播报节奏）|

### 1.6 Semantics

```dart
Semantics(
  label: '助手消息：${bubbleText}',
  liveRegion: true, // 屏幕阅读器自动播报新内容
)
```

---

## 二、IntentProposalCard（意图确认卡）

### 2.1 设计意图

对应 PRD §六.4"确认"阶段。代理理解用户意图后，弹出此卡让用户确认或纠正，是"预告-确认-执行"中最关键的授权节点。卡片需足够醒目（不让用户错过），但不应全屏遮挡（用户仍能看到下方页面）。

### 2.2 布局位置

```
┌─────────────── PhoneFrame ───────────────┐
│            [页面主内容区（半透明）]         │
│  ┌──────────────────────────────────┐   │
│  │  ❓ 代理复述文字（最多 2 行）       │   │
│  │                                  │   │  ← IntentProposalCard
│  │  [  确认，帮我做  ]  [  重说  ]   │   │
│  │  倒计时进度条（5 秒）              │   │
│  └──────────────────────────────────┘   │
│            [页面主内容区（半透明）]         │
└──────────────────────────────────────────┘
```

- 位置：`Center`，垂直居中于 PhoneFrame
- 背后蒙层：`Colors.black.withOpacity(0.3)`（轻蒙层，保持页面可见）

### 2.3 尺寸

| 维度 | 值 |
|---|---|
| 宽度 | PhoneFrame 内宽 - 2 × `Spacing.xxl`（32dp）= **341 dp** |
| 高度 | 自适应内容，最小 **140 dp**，最大 **220 dp** |
| 内边距 | `Spacing.lgPlus`（20dp）水平，`Spacing.lg`（16dp）垂直 |

### 2.4 视觉规格

| 属性 | 值 |
|---|---|
| 背景色 | `Colors.white` |
| 圆角 | `AppRadius.xlarge`（16dp）全圆角 |
| 阴影 | `BoxShadow` offset(0,4)，blur 16，color `Colors.black.withOpacity(0.2)` |
| 复述文字字号 | `AppFontSize.bodyLarge`（16sp），`FontWeight.w500` |
| 复述文字色 | `AppColors.textPrimary`（深灰）|
| **"确认"按钮** | 宽度 fill（左右各占 45%，间距 `Spacing.sm`）；高度 **52dp**（≥ NF6 10mm）；背景 `AppColors.agentPrimary`；文字白色 `AppFontSize.bodyLarge`；圆角 `AppRadius.medium`（8dp）|
| **"重说"按钮** | 同尺寸；背景 `Colors.transparent`；边框 1dp `AppColors.agentPrimary`；文字 `AppColors.agentPrimary` |
| 倒计时进度条 | 卡片底部，高度 3dp，`AppColors.agentPrimary`，从满到空 5 秒线性动画 |

### 2.5 交互态

| 状态 | 表现 |
|---|---|
| 入场 | 透明度 0→1 + 缩放 0.92→1.0，200ms |
| 按下"确认" | 按钮背景加深 10%，ripple 效果，150ms 后触发退场 |
| 按下"重说" | 同上，退场后代理重新进入收音状态 |
| **超时（5 秒后）** | 进度条走完；**原卡片内容通过 `AnimatedSwitcher` 更新**（不 dismiss 后重建入场，避免老年用户视觉突变）；文字改为"还在吗？需要我继续吗？"，双按钮改为"继续 / 结束" |
| 退场 | 透明度 1→0 + 缩放 1.0→0.92，150ms |

### 2.6 Semantics

```dart
// 等待态
Semantics(
  label: '代理请求确认：${proposalText}',
  button: false,
)
Semantics(label: '确认，让代理帮我做', button: true)
Semantics(label: '重说，代理没理解对', button: true)

// 超时态（AnimatedSwitcher 切换后同步更新 Semantics）
Semantics(label: '代理询问：还在吗，需要我继续吗', button: false)
Semantics(label: '继续，让代理继续操作', button: true)
Semantics(label: '结束，退出代理', button: true)
```

---

## 三、AgentProgressIndicator（代理进度提示）

> 注：文件名使用 `agent_progress_indicator.dart`，避免与 Flutter 内置 `ProgressIndicator` 命名冲突。

### 3.1 设计意图

对应 PRD §六.4"执行"阶段的实时透明机制（PRD §六.8.1）。让用户随时知道代理正在做什么。应足够显眼但不遮挡交互区域，选择锚定顶部条带而非全屏弹窗。

### 3.2 布局位置与挂载点

**挂载点：PhoneFrame 顶层 Stack（高于所有路由层）**，而非 Scaffold 内 AppBar 下方。这样无论当前路由是否有 AppBar，进度条始终位于 PhoneFrame 内部顶部（代理在无 AppBar 页面不会被激活，此场景实际不存在）。

```
PhoneFrame Stack 层级（由下到上）：

  层 0  路由内容（Scaffold + AppBar + BottomAppBar）
  层 1  PersistentBanner（各页面级，代理激活时自动隐藏）
  层 2  AgentSpeechBubble / AgentProgressIndicator / StopButton
  层 3  IntentProposalCard + 蒙层
  层 4  SystemDialog（阻塞式系统弹窗，现有）
```

```
┌─────────────── PhoneFrame ───────────────┐
│  ┌──────────────────────────────────┐   │
│  │  ⟳  正在打开养老金查询页面...      │   │  ← AgentProgressIndicator（层 2，顶部）
│  └──────────────────────────────────┘   │
│            [页面主内容区]                 │
└──────────────────────────────────────────┘
```

- 位置：PhoneFrame Stack 顶部内壁，`SafeArea` 之内，z 轴在所有路由之上
- 宽度全满，不留边距

### 3.3 尺寸

| 维度 | 值 |
|---|---|
| 宽度 | 全宽（PhoneFrame 内宽）|
| 高度 | **44 dp** |
| 内边距 | `Spacing.lg`（16dp）水平，`Spacing.xs`（4dp）垂直 |

### 3.4 视觉规格

| 属性 | 值 |
|---|---|
| 背景色 | `AppColors.agentPrimary.withOpacity(0.12)`（浅蓝底）|
| 左侧图标 | `CircularProgressIndicator`，直径 18dp，`strokeWidth` 2dp，`AppColors.agentPrimary` |
| 进度文字 | `AppFontSize.caption`（13sp），`AppColors.agentPrimary`，`FontWeight.w500` |
| 底部线条 | 1dp，`AppColors.agentPrimary.withOpacity(0.3)` |

### 3.5 交互态

| 状态 | 表现 |
|---|---|
| 入场 | 从顶部 -44dp → 0，200ms ease-out |
| 文字更新 | 淡出旧文字 → 淡入新文字，100ms |
| 执行完成 | 图标变绿色 ✓，文字变为"完成"，保持 800ms 后退场 |
| 退场 | 向上 -44dp + 透明度→0，150ms |

### 3.6 Semantics

```dart
Semantics(
  label: progressText, // 如"正在打开养老金查询页面"
  liveRegion: true,
)
```

---

## 四、StopButton（代理停止按钮）

### 4.1 设计意图

对应 PRD §六.7.1 三种中断方式中的"按键中断"（UI6）。用户调研中李阿姨明确要求"有个红红的'停止'按钮"；王阿姨要求"屏幕上有个'停'字可以按"。按钮必须：**固定位置、始终可见（代理激活期间）、颜色醒目（红色）、尺寸够大**。

### 4.2 布局位置

```
┌─────────────── PhoneFrame ───────────────┐
│            [页面主内容区]                 │
│                          ┌──────────┐   │
│                          │  ⬛ 停止  │   │  ← StopButton（右下角悬浮）
│                          └──────────┘   │
│  [底部导航 / BottomAppBar]               │
└──────────────────────────────────────────┘
```

- 位置：`Positioned(right: Spacing.lg, bottom: BottomAppBarHeight + Spacing.sm)`
- 即：BottomAppBar 上方 `Spacing.sm`（8dp），右对齐 `Spacing.lg`（16dp）
- **代理未激活时隐藏**（`Visibility` 或 `AnimatedOpacity(opacity: 0)`），代理激活时显示

**与 PersistentBanner 共存策略（已决策）**：代理激活期间（`agentStateProvider.phase != AgentPhase.idle`），`PersistentBanner` 自动隐藏（`return const SizedBox.shrink()`），消除空间冲突。代理退出后 Banner 恢复显示。理由：代理激活是用户主动触发的前台操作，优先级高于被动登录提示（详见 §六 已决策 Q5）。

### 4.3 尺寸

| 维度 | 值 |
|---|---|
| 宽度 | **72 dp** |
| 高度 | **44 dp**（≥ NF6 10mm）|
| 内边距 | `Spacing.sm`（8dp）水平，`Spacing.xs`（4dp）垂直 |

### 4.4 视觉规格

| 属性 | 值 |
|---|---|
| 背景色 | `Colors.red[600]`（#E53935）—— **不使用 AppColors token**，红色是停止的语义色，不受主题影响 |
| 文字 | "停止"，`AppFontSize.caption`（13sp），`Colors.white`，`FontWeight.w600` |
| 左侧图标 | `Icons.stop_rounded`，18dp，`Colors.white` |
| 圆角 | `AppRadius.medium`（8dp）|
| 阴影 | `BoxShadow` offset(0,2)，blur 6，`Colors.red.withOpacity(0.4)` |

### 4.5 交互态

| 状态 | 表现 |
|---|---|
| 代理激活：入场 | 从右侧 +72dp 滑入 + 透明度 0→1，200ms |
| 代理退出：退场 | 向右 +72dp + 透明度→0，150ms |
| 按下 | 背景色加深（`Colors.red[800]`），缩放 0.95，ripple；150ms 后触发代理中断逻辑 |
| Hover（Web 端）| 背景色 `Colors.red[700]`，光标 `SystemMouseCursors.click` |

### 4.6 Semantics

```dart
Semantics(
  label: '停止代理操作',
  button: true,
  enabled: agentIsActive,
)
```

---

## 五、组件交互关系图

```
用户唤醒代理
    │
    ▼
[PersistentBanner 自动隐藏]（agentStateProvider.phase != idle）
[AgentSpeechBubble] 入场 ─── 代理说"我在，请说"
    │
    ▼（用户发出指令，代理理解意图）
[AgentSpeechBubble] 更新 ─── 代理复述意图
[IntentProposalCard] 入场 ─── 等待用户确认（5 秒倒计时）
[StopButton] 入场 ─────────── 始终可见
    │                           │
    │ 用户点"确认"              │ 用户点"停止"
    ▼                           ▼
[IntentProposalCard] 退场    代理中断（phase → idle）
[AgentProgressIndicator] 入场 [StopButton] 退场
代理执行操作                  [AgentProgressIndicator] 退场（若存在）
    │                          [PersistentBanner 恢复显示]
    ▼（执行完成）
[AgentProgressIndicator] 完成态 → 退场
[AgentSpeechBubble] 更新 ─── 代理播报结果
[StopButton] 退场
[PersistentBanner 恢复显示]（phase → idle）
```

**倒计时超时分支**：
```
IntentProposalCard 倒计时 5 秒耗尽
    │
    ▼（AnimatedSwitcher 原卡内容更新，不 dismiss）
内容变为"还在吗？需要我继续吗？"+ "继续 / 结束"按钮
    │
    ├── 用户点"继续" → 恢复等待态，重启倒计时
    └── 用户点"结束" / 30 秒无响应 → 代理退出（phase → idle）
```

---

## 六、已决策（原"待 architect 确认问题"）

> 以下 5 问已在 `docs/archive/AGENT_UI_SPEC_review.md` 中由 architect 给出明确答复，此处记录结论供追溯。

### Q1：`AppColors.agentPrimary` 是否新增，色值？
**结论**：新增，色值 `Color(0xFF0070E0)`（温暖蓝，WCAG AA 白字对比度 ≈ 5.0:1）。
原推荐 `#1A8CFF` 对比度 ≈ 3.4:1，不满足 NF5。
由 frontend 在实施阶段写入 `design_tokens.dart`。
（参见 review §二 Q1，§八 对比度表）

### Q2：AgentSpeechBubble 气泡颜色是否随 modeProvider 变化？
**结论**：固定 `AppColors.agentPrimary`（温暖蓝），不随模式变化。
代理的视觉身份（蓝色）必须跨标准版 / 长辈版一致，才能建立用户心智模型；若在长辈版变橙色，无法区分"代理说话"与"APP 自身 UI"。
（参见 review §二 Q2）

### Q3：IntentProposalCard 倒计时 5 秒是否准确？超时走新卡还是原卡更新？
**结论**：5 秒准确（与 PRD §六.4 / §八 AE3 一致）。超时走**原卡片内容更新**（`AnimatedSwitcher`），不 dismiss 后重建，避免老年用户视觉突变。
（参见 review §二 Q3）

### Q4：ProgressIndicator 若 AppBar 不存在时锚定哪里？
**结论**：此问题实际不成立（代理只在 ElderHomePage 被激活，该页有 AppBar）。根本解法：挂载点改为 **PhoneFrame Stack 顶层**，与当前页面是否有 AppBar 无关。
（参见 review §二 Q4，§四 挂载策略）

### Q5：StopButton 与 PersistentBanner 共存冲突如何处理？
**结论**：代理激活期间，`PersistentBanner` 读 `agentStateProvider.phase != AgentPhase.idle`，phase 非 idle 时 `return const SizedBox.shrink()` 自动隐藏；代理退出后恢复显示。
（参见 review §二 Q5，§四 agentStateProvider 定义）

### Phase 3 范围决策（2026-04-18，同步自 architect 技术栈评审）

> 来源：`docs/TECH_STACK_REVIEW.md §D.5`（D2-D5，D1 已单独派 backend）。

| 决策 | 结论 | 影响组件 |
|---|---|---|
| **D2** WS_URL 注入 | `--dart-define=WS_URL=...`；frontend 用 `const String.fromEnvironment('WS_URL', defaultValue: 'ws://localhost:8000/ws')` 读取，不硬编码 | §七 实施指引 |
| **D3** InteractionLogger | Phase 3 仅写 LocalStorage，不出 UI（`agent_history_page.dart` 留 Phase 4）| 不直接影响 4 组件 |
| **D4** L3 权限 | Phase 3 不实施 L3（身份证级授权确认）；`IntentProposalCard` 仅承接 L1/L2 确认卡样式；L3 留 Phase 4 | §二 IntentProposalCard |
| **D5** 草稿 TTL | 30 天（由 7 天调整，与 PRD §六.8.2 / UI7 操作记录保留策略对齐）| 不直接影响 4 组件 |

---

## 七、frontend 实施指引摘要

> 详细实施顺序和 PhoneFrame 挂载结构见 `docs/archive/AGENT_UI_SPEC_review.md §四`。

**文件结构**：
```
lib/core/widgets/agent/
├── agent_speech_bubble.dart
├── intent_proposal_card.dart
├── agent_progress_indicator.dart
└── agent_stop_button.dart
```

**共享状态**：`agentStateProvider`（`AgentPhase { idle, listening, proposing, executing, done }`），定义于 `lib/core/state/agent_state.dart`。

**新增 token**（frontend 实施时写入 `design_tokens.dart`）：
```dart
// Agent 助手品牌色（WCAG AA 兼容）
static const Color agentPrimary = Color(0xFF0070E0);
```

**WebSocket URL（D2）**：frontend 用 `const String.fromEnvironment('WS_URL', defaultValue: 'ws://localhost:8000/ws')` 读取 backend URL；构建时传 `--dart-define=WS_URL=wss://...`，不硬编码。`AgentClient.connect()` 调用此常量。

**动效实现**：均为 Flutter 内置能力，无需新增 pub 依赖（详见 review §四.4 动效依赖表）。

---

## 八、变更记录

| 日期 | 版本 | 变更人 | 变更摘要 |
|---|---|---|---|
| 2026-04-18 | v0.1 | PM | 初稿，4 组件规格完成 |
| 2026-04-18 | v1.1 | PM | architect review 修订。必改：7 处 token 名称统一（Spacing.lg/lgPlus/xxl / AppRadius.xlarge/medium / AppFontSize.bodyLarge）；agentPrimary 色值 #1A8CFF→#0070E0；气泡颜色固定（删除 modeProvider 依赖）；StopButton×PersistentBanner 共存策略补入。建议补：IntentProposalCard 超时态改 AnimatedSwitcher 原卡更新 + 超时态 Semantics；ProgressIndicator 挂载点改 PhoneFrame Stack 顶层 + 层级关系图。§六 由"待确认问题"改为"已决策"结论记录 |
| 2026-04-18 | v1.2 | PM | 同步 architect 技术栈评审 D2-D5 决策：§六末新增 Phase 3 范围决策表（D2 WS_URL / D3 InteractionLogger / D4 L3 权限 / D5 草稿 TTL）；§七补 D2 WS_URL 注入具体写法；文档头更新至 v1.2 |
