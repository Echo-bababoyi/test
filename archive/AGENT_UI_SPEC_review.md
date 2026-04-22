# AGENT_UI_SPEC.md — Architect Review

> Reviewer：architect
> Date：2026-04-18
> 原文：`docs/AGENT_UI_SPEC.md` v0.1
> 结论：**有条件通过**——6 处 token 名称/值错误必须在 PM 修订后方可交 frontend 实施；颜色对比度存在 NF5 合规风险需确认；其余结构与逻辑无原则性问题。

---

## 一、逐项审查结论

| 节 | 内容 | 结论 | 备注 |
|---|---|---|---|
| §零 全局约定 | 坐标系 / token 引用 / 动效时长 / Semantics 要求 | ✓ | 方向正确；token 名称在各节中存在偏差（见§三）|
| §一 AgentSpeechBubble | 布局位置 / 尺寸 / 交互态 / Semantics | ⚠️ | 4 处 token 名称/值错误；气泡颜色随模式变化已在 §五 回答 |
| §二 IntentProposalCard | 布局 / 尺寸 / 视觉 / 倒计时 | ⚠️ | 2 处 token 名称/值错误；超时内容更新策略建议调整（见 §五）|
| §三 ProgressIndicator | 位置 / 尺寸 / 视觉 / 入退场 | ⚠️ | 1 处 token 名称错误；无 AppBar 时 fallback 见 §五；挂载点需在 PhoneFrame Stack（见 §四）|
| §四 StopButton | 位置 / 尺寸 / 视觉 / 交互 | ⚠️ | 与 PersistentBanner 共存冲突未解决（见 §五）；其余可通过 |
| §五 组件交互关系图 | 状态机流程 | ✓ | 状态转移正确，与 PRD §六.4 完全对应 |
| §六 待确认问题 | PM 挂起 5 问 | → 见下文 §五 | 全部已有确定答案 |

---

## 二、PM 挂起 5 问——逐条答复

### Q1：`AppColors.agentPrimary` 是否新增？推荐 #1A8CFF？

**答：新增，但 #1A8CFF 有 NF5 合规风险，建议改为 #0A7CFF 或 #0070E0。**

原因分析：
- PRD §六.1 明确"温暖蓝或绿色，区别于长辈版橙色"→ 必须新增专属 token，不能复用 `bannerButton`（`#2D74DC` 标准版蓝，与代理身份语义不同）。
- 对比度测算：`#1A8CFF` 白底白字对比度 ≈ **3.4:1**，低于 NF5 要求的 WCAG AA 4.5:1（白字覆盖在此蓝色背景上不合规）。
- 推荐色值：`#0070E0`（RGB 0,112,224），白字对比度 ≈ **5.0:1**，满足 WCAG AA；视觉上仍是明亮温暖蓝，与长辈版橙色无混淆风险。

**结论**：`design_tokens.dart` 在 `AppColors` 末尾新增：

```dart
// Agent 助手品牌色（温暖蓝，WCAG AA 兼容）
static const Color agentPrimary = Color(0xFF0070E0);
```

> 位置建议：`lib/core/theme/design_tokens.dart` 第 25 行末尾（`phoneBg` 后），新开注释组。

若 PM 坚持偏浅的色调（更接近 #1A8CFF），则 AgentSpeechBubble 的文字色不能用纯白，需改为深色（`AppColors.textPrimary`），同时 confirm 按钮文字颜色也要调整——成本高于直接换色值。

---

### Q2：AgentSpeechBubble 气泡颜色是否随 modeProvider 变化？

**答：固定代理蓝色（`AppColors.agentPrimary`），不随模式变化。**

原因：
- PRD §六.1 原文："颜色：温暖的蓝色或绿色，**区别于长辈版橙色主色，不产生颜色冲突**"——这是明确的产品决策，代理颜色本身就是为了与长辈版橙色区分。
- 若气泡在长辈版变橙色，用户视觉上无法区分"代理说话"与"APP 自身 UI"，信任感和可辨识度均受损（张叔叔型用户对"代理是什么"本已模糊）。
- 代理的视觉身份（蓝色助手图标 + 蓝色气泡）必须跨模式一致，才能建立用户心智模型。

**结论**：`AgentSpeechBubble` 背景色写死 `AppColors.agentPrimary`，删除 `modeProvider` 依赖。

---

### Q3：IntentProposalCard 倒计时 5 秒是否准确？超时后走新卡 vs 原卡更新？

**倒计时 5 秒：确认准确。**
- PRD §六.4 "等待超时（5 秒）：代理询问'还在吗？'"
- PRD §八 AE3 同值印证。5 秒无需修改。

**超时后内容更新方式：推荐原卡片内容更新，不走 dismiss + 新卡入场。**

原因：
- 用户正在注视卡片（等待或犹豫），dismiss 动画 + 新卡入场会引起视觉突变，干扰正在犹豫的老年用户（郑阿姨型"动作太快看不清"痛点）。
- 状态机更简单：卡片有 `enum _State { waiting, timeout }` 两态，`_State.timeout` 时只更新文字和按钮内容，进度条从满到空替换为静止状态。
- 实现上：`AnimatedSwitcher` 包裹卡片内容区，child key 变化时执行淡入淡出，无需额外路由或 overlay 操作。

**结论**：PM 修改 §二.2.5 超时态描述为"原卡片内容更新（AnimatedSwitcher），不 dismiss 后重新入场"。

---

### Q4：ProgressIndicator 若 AppBar 不存在时锚定哪里？

**答：此问题在实际场景中不成立，但建议将挂载点移至 PhoneFrame 级 Stack。**

分析：
- 代理只能在 ElderHomePage（有"助手"唤醒按钮）被激活——该页有 AppBar。代理激活期间用户可能跳转到其他页，但 ProgressIndicator 应跟随代理状态存在于所有页面顶部。
- **根本解法**：ProgressIndicator 不挂在 Scaffold 内的 AppBar 下方，而是挂在 **PhoneFrame 的顶层 Stack**，置于所有路由之上。这样位置始终是 PhoneFrame 内部顶部，与当前页面是否有 AppBar 无关（见 §四 组件挂载策略）。

SplashPage 特殊情况：代理未激活，ProgressIndicator 不渲染，不存在锚定问题。

**结论**：PM 修改 §三.3.2 位置描述，将锚定描述改为"PhoneFrame Stack 顶部内壁，z 轴在所有路由之上"，删除"AppBar 正下方"表述。

---

### Q5：StopButton 与 PersistentBanner 共存时的 z 轴和位置优先级？

**答：存在真实冲突，需明确处理策略。**

冲突场景：用户未登录（PersistentBanner 显示）+ 唤醒代理（StopButton 显示）→ 两者均在 BottomAppBar 上方同区域，右下角 StopButton 与底部 Banner 在空间上重叠。

**推荐处理方案：代理激活期间，PersistentBanner 自动隐藏。**

原因：
- 代理激活是用户主动触发的前台操作。PersistentBanner 是被动提醒，优先级低于用户正在执行的代理任务。
- "登录提示"和"代理操作"不需要同时存在——用户既然在用代理，说明他在用这个 APP，登录提示在此刻是噪音。
- 实现简单：`PersistentBanner` 读 `agentActiveProvider`，若 `agentActive == true` 则 `return const SizedBox.shrink()`。

备选方案（如 PM 不接受自动隐藏）：StopButton 的 `bottom` 值改为 `BottomAppBarHeight + Spacing.sm + PersistentBannerHeight`（约 56dp），但需 StopButton 感知 banner 状态，耦合更重。推荐主方案。

**结论**：PM 补充 §四.4.2 或在 §五 关系图中注明"代理激活期间 PersistentBanner 隐藏"。

---

## 三、Token 名称/值错误清单（全部需 PM 修正）

以下错误均为"spec 中的 token 名称或括号内数值与 `design_tokens.dart` 实际定义不符"。

| # | 位置 | Spec 写法 | 实际 token 名 | 实际值 | 修正方式 |
|---|---|---|---|---|---|
| T1 | §一.2 / §一.3 内边距 | `Spacing.md`（16dp）| `Spacing.md = 12` 或 `Spacing.lg = 16` | 12 / 16 | **确认意图：若要 16dp 则改写 `Spacing.lg`（16dp）；若要 12dp 则修正括号值为 12dp** |
| T2 | §一.3 宽度公式 | "405 - 2 × `Spacing.md` = 373" | 405 - 2×12 = 381（md=12）；或 405 - 2×16 = 373（lg=16）| — | 若取 373dp，公式改为 `Spacing.lg`；若取实际 md=12，公式结果应为 381dp |
| T3 | §一.4 / §二.4 圆角 | `AppRadius.lg`（16dp）| `AppRadius.xlarge = 16`（lg 不存在）| — | 改写 `AppRadius.xlarge` |
| T4 | §二.3 内边距 | `Spacing.lg`（18dp）| `Spacing.lg = 16`，`Spacing.lgPlus = 20` | — | 若要 18dp，当前 token 体系无精确值；建议取 `Spacing.lgPlus`（20dp）或 `Spacing.lg`（16dp），并修正括号值 |
| T5 | §二.3 宽度公式 | "405 - 2 × `Spacing.xl`（32dp）= 341" | `Spacing.xl = 24`；32dp 对应 `Spacing.xxl` | — | 改写 `Spacing.xxl`（32dp），公式 405 - 2×32 = 341 ✓ |
| T6 | §一.4 / §二.4 字号 | `AppFontSize.body`（16sp）| `AppFontSize.body = 14`；16sp 对应 `AppFontSize.bodyLarge` | — | 改写 `AppFontSize.bodyLarge`；`AppFontSize.body` 仅为 14sp |
| T7 | §二.4 圆角（按钮）| `AppRadius.sm`（8dp）| `AppRadius.medium = 8`（sm 不存在，small=4）| — | 改写 `AppRadius.medium` |

> **系统性成因**：spec 起草时参考了一套"假想的 token 命名"（sm/md/lg/xl 语义化名称），而实际 `design_tokens.dart` 用 small/medium/large/xlarge + 数值后缀（xxl）体系。两套命名不同步。

---

## 四、组件挂载策略（frontend 实施指引）

### 4.1 文件结构

所有 4 个 Agent UI 组件统一放入独立目录：

```
lib/core/widgets/agent/
├── agent_speech_bubble.dart
├── intent_proposal_card.dart
├── agent_progress_indicator.dart   ← 避免与 Flutter 内置 ProgressIndicator 命名冲突
└── agent_stop_button.dart
```

理由：这 4 个组件是代理功能的视觉表达层，是跨页面共享的框架级组件（对比：`PersistentBanner` / `PermissionFlowHelper` 在 `lib/core/widgets/`），不属于任何单一 feature，应与其他 core widgets 平级但单独成目录（4 个组件值得一层分组）。

### 4.2 挂载点：PhoneFrame Stack

4 个组件均为**跨页面浮层**，不属于任何具体页面 Scaffold，必须挂在 PhoneFrame 的顶层 Stack（高于路由层）。

当前 PhoneFrame 结构（推断）：

```dart
// lib/core/widgets/phone_frame.dart
Stack(
  children: [
    // 路由器内容（当前实现）
    _RouterContent(),
    // 【新增】Agent UI 层（高于路由，低于系统弹窗）
    _AgentOverlayLayer(),
  ],
)
```

`_AgentOverlayLayer` 是一个 `ConsumerWidget`，读取 `agentStateProvider`，按需渲染 4 个组件（`Visibility` 或条件渲染）。

**z 轴层级**（由下到上）：

| 层 | 组件 | 备注 |
|---|---|---|
| 0（最底）| 页面路由内容 | Scaffold + AppBar + BottomAppBar |
| 1 | PersistentBanner | 页面级，挂在各页 body Stack |
| 2 | AgentSpeechBubble | Frame 级，底部浮层 |
| 2 | AgentProgressIndicator | Frame 级，顶部条带 |
| 2 | StopButton | Frame 级，右下角悬浮 |
| 3 | IntentProposalCard + 蒙层 | Frame 级，全屏覆盖（轻蒙层） |
| 4（最高）| SystemDialog | 阻塞式系统弹窗（现有） |

### 4.3 共享状态：agentStateProvider

4 个组件共同依赖一个 `AgentState`，建议定义：

```dart
// lib/core/state/agent_state.dart
enum AgentPhase { idle, listening, proposing, executing, done }

@immutable
class AgentState {
  final AgentPhase phase;
  final String speechText;      // AgentSpeechBubble 内容
  final String progressText;    // ProgressIndicator 内容
  final String proposalText;    // IntentProposalCard 复述内容
  final bool isExecutionDone;   // ProgressIndicator 完成态（绿√）
  // ...
}

class AgentNotifier extends Notifier<AgentState> { ... }
final agentStateProvider = NotifierProvider<AgentNotifier, AgentState>(...);
```

`PersistentBanner` 应读取 `agentStateProvider.phase != AgentPhase.idle` 决定是否隐藏（解决 Q5）。

### 4.4 动效依赖

以下动效均为 **Flutter 内置能力**，无需 `flutter-animating-apps` skill，无需新增 pub 依赖：

| 动效 | 实现方式 |
|---|---|
| AgentSpeechBubble 入/退场（滑动+透明度）| `AnimatedSlide` + `AnimatedOpacity` 或 `SlideTransition` + `FadeTransition` |
| AgentSpeechBubble 高度展开 | `AnimatedContainer` + `AnimationController` |
| 打字机效果（30ms/字）| `Timer.periodic` 驱动 `setState` 更新 `_visibleLength`，无需包 |
| IntentProposalCard 入/退场（缩放+透明度）| `ScaleTransition` + `FadeTransition` |
| 倒计时进度条（5s 线性）| `AnimationController(duration: 5s)` + `LinearProgressIndicator` value |
| 超时内容更新 | `AnimatedSwitcher`（child key 变化触发淡入淡出）|
| ProgressIndicator 入/退场（顶部滑入）| `AnimatedSlide` |
| StopButton 入/退场（右侧滑入）| `AnimatedSlide` + `AnimatedOpacity` |

---

## 五、实施顺序

```
阶段 0（前置）：定义 AgentState 模型 + agentStateProvider
         │
         ├─ 阶段 1（可并行）
         │    ├── agent_stop_button.dart         （最简，纯 UI + 一个 bool 判显示）
         │    └── agent_progress_indicator.dart  （文字 + CircularIndicator + 3 态动画）
         │
         └─ 阶段 2（依阶段 0 完成）
              ├── agent_speech_bubble.dart       （打字机 + 展开 + 入退场）
              └── intent_proposal_card.dart      （倒计时 + 超时态更新 + 蒙层）

阶段 3：PhoneFrame Stack 中接入 _AgentOverlayLayer
阶段 4：PersistentBanner 接入 agentStateProvider（解决 Q5 冲突）
```

**关键路径**：AgentState 模型 → （StopButton ∥ ProgressIndicator）→ AgentSpeechBubble → IntentProposalCard → PhoneFrame 接入。

预计最小可测试单元（StopButton + ProgressIndicator）在阶段 1 完成后即可挂入 PhoneFrame 验证层叠效果。

---

## 六、新增 token 清单（frontend 实施前 PM 确认后由 frontend 写入 design_tokens.dart）

| Token 名 | 类 | 值 | 位置建议 |
|---|---|---|---|
| `agentPrimary` | `AppColors` | `Color(0xFF0070E0)` | `design_tokens.dart` 第 25 行后，新注释组"Agent 助手品牌色" |

> 无需新增 Spacing / AppRadius / AppFontSize token——所有 spec 中引用的数值均可映射到现有 token，只是 spec 文档中的 token 名称写错了（见 §三 T1-T7）。

---

## 七、Semantics 完备性审查

| 组件 | liveRegion | button 标注 | label 中文 | 结论 |
|---|---|---|---|---|
| AgentSpeechBubble | ✓ `liveRegion: true` | — | ✓ '助手消息：...' | ✓ |
| IntentProposalCard（卡片） | — | `button: false` ✓ | ✓ '代理请求确认：...' | ✓ |
| IntentProposalCard（确认按钮） | — | `button: true` ✓ | ✓ | ✓ |
| IntentProposalCard（重说按钮） | — | `button: true` ✓ | ✓ | ✓ |
| ProgressIndicator | ✓ `liveRegion: true` | — | ✓ 动态 progressText | ✓ |
| StopButton | — | `button: true` ✓ | ✓ '停止代理操作' | ✓ |

Semantics 覆盖完备。补充建议：IntentProposalCard 超时态（"继续/结束"双按钮）也需补 Semantics（spec 当前缺超时态的 Semantics 定义）。

---

## 八、NF5 对比度合规小结

| 色对 | 对比度 | 是否合规（WCAG AA 4.5:1）|
|---|---|---|
| `Colors.white` 字 / `#1A8CFF` 背景（原 spec）| ≈ 3.4:1 | ❌ 不合规 |
| `Colors.white` 字 / `#0070E0` 背景（本 review 推荐）| ≈ 5.0:1 | ✓ 合规 |
| `AppColors.agentPrimary` 字 / `Colors.white` 背景 | ≈ 5.0:1 | ✓ 合规 |
| `AppColors.textPrimary` 字 / `Colors.white` 背景（IntentProposalCard 内容区）| ≈ 14.7:1 | ✓ 合规 |

---

## 九、Review 结论与 PM 待办

**有条件通过**。以下 4 项 PM 修正后即可交 frontend 实施：

1. **【必改】** §零 / §一-§四 所有 token 引用按 §三 清单 T1-T7 修正名称和括号数值
2. **【必改】** §零 `agentPrimary` 推荐色值改为 `#0070E0`（NF5 合规）
3. **【必改】** §一.4 删除"由 modeProvider 决定"说明，改为"固定 `AppColors.agentPrimary`"
4. **【建议改】** §二.2.5 超时态改为"原卡片内容更新"；补超时态 Semantics 定义
5. **【建议补】** 新增 §三.3.2 ProgressIndicator 挂载点说明（PhoneFrame Stack）；注明无 AppBar 页面的行为（不适用，代理不在该页激活）
6. **【建议补】** §四 或 §五 补充"代理激活时 PersistentBanner 隐藏"策略

修正完成后，文档版本升为 v0.2，architect 无需重新全量 review，仅确认上述 6 条。
