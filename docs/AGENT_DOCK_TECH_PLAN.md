# 底部一体化 AgentDock — 技术实现方案

> **版本**：v1.1（2026-06-01，定稿）
> **作者**：architect
> **关联**：`docs/AGENT_DOCK_REDESIGN.md` v1.0（交互权威）、`ISSUES.md` #79
> **状态**：**定稿**（3 个开放点已拍板回填，见 §2.4/§3.2/§11）→ 交 frontend/backend 实施
> **本期范围**：仅长辈版（标准版 `standard_home` 不动，沿用 AgentFab 悬浮气泡）
> **v1.1 变更**：回填 3 开放点决策（S0→自动弹窄条 / face_auth 方案甲+回执闭环 / agent_settings 删 AgentFab）；新增 §11 刷脸回执闭环落地片段（Part A prompt 改前后对照 + Part B frontend diff）；§10 后续增强记录；OOS guard bug 修复归入实施 S5。

---

## 0 核心结论（一句话）

把 `AgentFab` 悬浮气泡从各页 body 的 `Positioned.fill` 里摘掉，新建 `AgentBottomShell` 挂到各页 `Scaffold.bottomNavigationBar` 槽位。**因为面板进了 bottomNavigationBar 槽位，Scaffold 会自动把 body 压在面板之上**——半屏/窄条/卡片长高全部天然生效，高亮让位只需改进现有自动滚动（改法 A+B），**不需要 panelHeightProvider 备选方案**（审计结论见 §2.4）。

状态载体**复用现有 `AgentSession`**，把 2 态 `_panelOpen` 升级为 4 态 `AgentPanelMode` 枚举，自动切换由现有 `cmd_*` / `permission_request` / `task_done` 信号驱动。**ASR/TTS/ChatHistory/executor/授权卡/选择卡全部保留不动**，只搬容器。

---

## 1 组件拆分

### 1.1 新建文件

**`app/lib/widgets/agent_dock.dart`**（新核心组件，约 600~700 行）

| 组件 | 职责 | 来源 |
|---|---|---|
| `AgentBottomShell`（ConsumerStatefulWidget） | 挂 `bottomNavigationBar` 槽位的容器：导航栏行 + 4 态面板宿主 + 页面绑定 | 新写；页面绑定逻辑从 `agent_fab.dart` initState/build 搬来 |
| `_DockNavRow` | 导航栏行。完整态：首页 / 小浙圆形凸起按钮 / 我的；精简态（slim）：仅居中收起/展开控制 | 合并 `elder_bottom_nav.dart` 的两 Tab + 新增中间按钮 |
| `_ZheCenterButton` | 圆形凸起小浙按钮（§8 决策1，直径 ≥56dp，凸出导航栏，内嵌"浙"字 + "小浙"标签） | 复用 `agent_fab.dart` 的 `_ZhePainter`（绘制逻辑搬来/抽共享） |
| `_DialogPanel`（S1） | 半屏对话区：消息列表 + 输入框 + 麦克风 + 各类卡片渲染 | **迁移** `agent_fab.dart` 的 `_BubbleWindow` 内核（`_buildItem` / `_sendText` / `_scrollToBottom` / `_checkPageDraft` / `MicButton` / `_close`） |
| `_GuidePanel`（S2） | 窄条：完整显示最近一条 agent 引导消息（≥18sp 不截断）+ 展开控制（⌃） | 新写，数据取 `ChatHistory.instance.items` 最后一条 `role==agent` |
| `_CardHost`（S3） | 引导态下渲染授权卡 / 选择卡（从 items 末尾取 `type==auth`/`choice`） | 复用 `AuthCard` + `agent_fab.dart` 的 `_ChoiceBtn` |

`_ConfirmBtn` / `_ChoiceBtn` / `_DraftCard` 从 `agent_fab.dart` 抽出复用（或复制进 `agent_dock.dart`，二者本期并存）。

### 1.2 改的文件

- `app/lib/services/agent_session.dart` — 状态机升级（§3）+ 改法 B 的 `reEnsureVisible` 调度。
- `app/lib/services/agent_command_executor.dart` — 改法 A（alignment）+ 抽 `reEnsureVisible()`（§4）。
- 18 个长辈版页面 — 摘 AgentFab + 接 AgentBottomShell（§2 逐页清单）。

### 1.3 退役 / 保留

- `agent_fab.dart` — **本期不删**。`standard_home`（标准版，本期不改）仍在用。长辈版页面停止 import 它即可。
  - 其内部避让逻辑 `_scheduleAvoid` / `_pickBubbleY`（#47/#73）随之**仅在标准版残留**、长辈版彻底不触发——等同退役。
- `elder_bottom_nav.dart` — 功能并入 `_DockNavRow` 后**长辈版不再单独使用**；可保留文件直到全部页面迁完再删（避免中途编译断裂）。
- `sms_notification.dart` — 与本期无关，不动。

### 1.4 不动的文件（§9 保留清单，仅列校验）

`audio_capture.dart` / `mic_button.dart` / `audio_player.dart`（ASR/TTS）、`chat_history.dart`、`ws_client.dart`、`agent_command_executor.dart`（仅小改 §4）、`agent_element_registry.dart`、`auth_card.dart`、`agent_bubble.dart`。

---

## 2 Scaffold 接入点（逐页清单）

### 2.1 现状结构（统一模式）

每个长辈页当前都是：
```dart
Scaffold(
  body: Stack(children: [
    <可滚动内容，如 SingleChildScrollView / ListView / CustomScrollView>,
    Positioned.fill(child: AgentFab(currentPath: ...)),   // ← 摘掉
  ]),
  bottomNavigationBar: const ElderBottomNav(currentIndex: X),  // ← 换 AgentBottomShell
)
```

**改造动作（每页 2 处）**：
1. 删除 body Stack 里的 `Positioned.fill(child: AgentFab(...))` 整段（含外层 `Positioned.fill`）。Stack 余单子可保留（无害）。
2. `bottomNavigationBar:` 换成 `AgentBottomShell`。

### 2.2 主流程页（完整 4 态：首页·小浙·我的）

| 页面 | bottomNav 行 | 摘 AgentFab 行 | currentIndex |
|---|---|---|---|
| `elder_home.dart` | 221 | 216–218（AgentFab @217） | 0 |
| `yibao_jiaofei_page.dart` | 359 | @355 | 0 |
| `pension_query_page.dart` | 127 | @123 | 0 |
| `yibao_query_page.dart` | 184 | @180 | 0 |
| `yibao_hub_page.dart` | 74 | @70 | 0 |
| `shebao_jiaona_page.dart` | 67 | @63 | 0 |
| `shebao_query_page.dart` | 151 | @147 | 0 |
| `search_page.dart` | 113 | @109 | 0 |
| `search_result_page.dart` | 146 | @142 | 0 |
| `pay_result_page.dart` | 181 | @177 | 0 |
| `mine_page.dart` | 95 | @91 | 2 |
| `drafts_page.dart` | 148 | @144 | 2 |
| `operation_logs_page.dart` | 189 | @185 | 2 |

替换为：`bottomNavigationBar: const AgentBottomShell(currentIndex: <0或2>, currentPath: AppRoutes.<对应路由>)`

> currentIndex：0=首页、2=我的、1 是中间小浙按钮（永不作为"选中页"高亮）。

### 2.3 任务流页（精简底部条 slim：砍首页/我的）

| 页面 | 现状 | 摘 AgentFab 行 | 接入 |
|---|---|---|---|
| `login_page.dart` | 无 bottomNav（AgentFab 浮） | @276 | 新增 `bottomNavigationBar: AgentBottomShell(currentPath: AppRoutes.login, slim: true)` |
| `verify_page.dart` | 无 bottomNav | @310 | 同上，`AppRoutes.verify`，`slim: true` |
| `pay_confirm_page.dart` | bottomNav @218（ElderBottomNav） | @216 | **替换** @218 为 `AgentBottomShell(currentPath: AppRoutes.yibaoJiaofeiConfirm, slim: true)` |

### 2.4 不挂底部容器（例外）+ 排除审计

| 页面 | 动作 | 说明 |
|---|---|---|
| `face_auth_page.dart` | **删 AgentFab @102**，不挂 AgentBottomShell（**方案甲已定**） | §4 例外：摄像头占满屏 + 独立活体检测 TTS。刷脸期 TTS 引导（#50）由 `face_auth_page` 自带 TTS 驱动，不依赖 dock。**但补"刷脸成功回执闭环"**（§11）——代理"退到幕后等"而非失联，刷脸一成功收到回执无缝接回引导。 |
| `pay_password_page.dart` | 已无 AgentFab（@89 注释"密码安全红线"已落实）；仅清理可能残留的 unused import | 安全红线，保持。 |
| `standard_home.dart` | **不动**（保留 AgentFab @52） | 标准版，本期范围外（§8 决策2）。 |
| `agent_settings_page.dart` | **删 AgentFab @170**（已定：小浙设置页内不挂小浙 dock） | 该页无 bottomNav、非任务流。删除后不挂任何容器（自指悖论 + 设置页无需引导）。 |

**Scaffold.body 压缩审计结论**：全部 18 个长辈页的可滚动区都直接位于 `Scaffold.body`（Stack 的另一子是即将摘除的 AgentFab 覆盖层）；**无任何页使用 `extendBody: true`**（仅 `face_auth_page` 用 `extendBodyBehindAppBar`，且该页不挂 dock）。因此 dock 进 `bottomNavigationBar` 槽位后，body 一定被压在面板上方、自动重排。**panelHeightProvider 备选方案不需要。**

---

## 3 状态管理（复用 AgentSession）

### 3.1 新增枚举与字段（`agent_session.dart`）

文件顶部加：
```dart
enum AgentPanelMode { closed, dialog, guide, card }  // S0 / S1 / S2 / S3
```

替换现有 `_panelOpen`（:55-62）为：
```dart
AgentPanelMode _panelMode = AgentPanelMode.closed;
AgentPanelMode get panelMode => _panelMode;
bool _closing = false;            // 收尾渐隐进行中
bool get closing => _closing;
Timer? _reEnsureTimer;

// 向后兼容（standard_home 的 AgentFab 仍用 panelOpen/setPanelOpen）
bool get panelOpen => _panelMode != AgentPanelMode.closed;
void setPanelOpen(bool open) =>
    setPanelMode(open ? AgentPanelMode.dialog : AgentPanelMode.closed);

void setPanelMode(AgentPanelMode m) {
  if (_panelMode == m) return;
  final prev = _panelMode;
  if (m == AgentPanelMode.dialog && prev == AgentPanelMode.closed) {
    _animateNextOpen = true;
    clearNewMessage();
  }
  _panelMode = m;
  _uiSignal.add(null);
  // 改法 B：面板高度变化 → 延后到动画 settle 后重触发一次高亮滚动
  if (currentHighlightKey.value != null &&
      m != AgentPanelMode.closed) {
    _scheduleReEnsureVisible();
  }
}

void _scheduleReEnsureVisible() {
  _reEnsureTimer?.cancel();
  _reEnsureTimer = Timer(const Duration(milliseconds: 320), () {  // 动画280ms+缓冲
    if (currentHighlightKey.value == null) return;
    _executor?.reEnsureVisible();
  });
}
```

### 3.2 自动转换的驱动信号（改 `_dispatch` / `_applyChatMessage`）

| 转换 | 触发位置 | 改动 |
|---|---|---|
| **S0→S1**（仅用户） | `_DockNavRow` 中间按钮 onTap | 调 `AgentSession.instance.setPanelMode(AgentPanelMode.dialog)`。**绝不自动**，守原则1。 |
| **S1→S2**（自动） | `_dispatch` :315-317（cmd_say/cmd_highlight 置 `_isGuiding=true` 处） | 置 guiding 后追加：`if (_panelMode == AgentPanelMode.dialog \|\| _panelMode == AgentPanelMode.closed) setPanelMode(AgentPanelMode.guide);` |
| **S2→S3**（自动） | `_applyChatMessage` :362-377（permission_request / agent_choice_request） | 追加：`if (_isGuiding) setPanelMode(AgentPanelMode.card);` |
| **S3→S2**（用户处理完） | `sendPermissionResponse`（:203）/ `sendChoiceText`（:212）末尾 | 追加：`if (_isGuiding) setPanelMode(AgentPanelMode.guide);` |
| **S2→S1**（用户展开看历史） | `_GuidePanel` 展开控制 onTap | `setPanelMode(AgentPanelMode.dialog)`（`_isGuiding` 不变） |
| **S1→S2**（用户收起，引导中） | `_DockNavRow` 收起按钮 onTap | `setPanelMode(_isGuiding ? AgentPanelMode.guide : AgentPanelMode.closed)` |
| **S2→S0**（自动收尾） | `_applyChatMessage` `task_done`（:379-383） | 改为调 `_finishAndClose(payload)`（§6） |

> **边界（已定）**：引导首条指令到达时若面板处于 S0（用户手动收起过）—— **自动弹窄条（closed→guide）**。理由：引导是用户已发起任务的延续，窄条非侵入，不违反原则1（"代理不主动"约束的是"未唤醒时不自挑事"，此处用户早已唤醒并发起任务）。上表 S1→S2 行的 `_dispatch` 改动已含 `|| _panelMode == AgentPanelMode.closed` 分支，无需额外代码。

### 3.3 插话不打断引导（§5.3 关键，含一处现存 bug 修复）

用户 S2→S1 展开打字问一句 → `_DialogPanel._sendText` → `sendText`（text_input）。后端按 `cmd_ask_user` 场景内问答 / OOS 应答处理（现有 #66 通道），**不重置执行器步进**。前端侧需保证两点：

1. `sendText` / `setPanelMode(dialog)` **不触碰** `_isGuiding`、`currentHighlightKey`、`_executor` —— 现状已满足（这些只在 task_done/agent_error/OOS 里被清）。

2. **现存 bug 必修**：`_applyChatMessage` 的 `agent_out_of_scope`（:397-403）现在无条件 `_isGuiding=false; currentHighlightKey.value=null` —— 引导中途插一句无关问题被判 OOS 时，**会误清引导进度**，违反 §5.3。修复：
```dart
case 'agent_out_of_scope':
  // 引导中插话被判 OOS：仅作答，不打断引导
  if (!_isGuiding) {
    _unwatchInput();
    currentHighlightKey.value = null;
  }
  final hint = payload['voice_hint'] as String? ?? '浙里办没有这个服务';
  items.add({'role': 'agent', 'text': hint});
  AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
```
（`agent_error` :385-395 同理可考虑——但 ASR 没听清属正常打断，保持现状即可；仅 OOS 需 guard。）

---

## 4 高亮自动滚动改造（改法 A + B）

### 4.1 改法 A（1 行）

`agent_command_executor.dart:100`：`alignment: 0.85` → `alignment: 0.5`。
理由：0.85 把目标顶到（压缩后）视口最底沿、紧贴面板顶；0.5 落在剩余可见区正中，动画期不擦边。

### 4.2 改法 B（抽方法 + AgentSession 调度）

`agent_command_executor.dart`：把 `_onHighlight` 里的滚动块（:97-104）抽成可复用私有方法，并新增公开 `reEnsureVisible()`：
```dart
void _scrollIntoView(BuildContext ctx) {
  Scrollable.ensureVisible(ctx,
    alignment: 0.5,
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut);
}

/// 面板高度变化后由 AgentSession 调度重触发（改法 B）
void reEnsureVisible() {
  if (currentRoute == null) return;
  final elementKey = AgentSession.instance.currentHighlightKey.value;
  if (elementKey == null) return;
  final key = AgentElementRegistry.get(currentRoute!, elementKey);
  final ctx = key?.currentContext;
  if (ctx != null) _scrollIntoView(ctx);
}
```
`_onHighlight` 里 :99-104 替换为 `_scrollIntoView(ctx);`。

调度方在 `AgentSession.setPanelMode` → `_scheduleReEnsureVisible()`（§3.1）：
- **延后到动画 settle**：`Timer(320ms)`（AnimatedSize 280ms + 40ms 缓冲），避免在视口缩放中途按中间态算错偏移。
- **Δ去重**：`setPanelMode` 已做 `if (_panelMode == m) return;`，同态不重复；`_reEnsureTimer?.cancel()` 防连续切换叠加多次滚动。
- **closed 不触发**：收起态无高亮需求。

### 4.3 为什么够用

面板在 `bottomNavigationBar` 槽位 → body 视口高度已自动 = 屏高 − 导航栏 − 面板。`ensureVisible(0.5)` 的"视口"天然排除面板。S1/S2/S3 各态、卡片临时长高，全部命中。高亮框 overlay（`_HighlightBorderOverlay`，root overlay，每脉冲帧 `getTransformTo(null)` 重算，:265）会平滑跟随目标，无残留旧框。

---

## 5 AgentFab 退役与逻辑搬家

| 逻辑 | 去向 |
|---|---|
| `_BubbleWindow` 对话渲染（`_buildItem`、auth/choice/thinking/draft 分支、`_sendText`、`_scrollToBottom`、`_checkPageDraft`） | **搬** → `_DialogPanel` |
| `MicButton` + `sendAudio` 占位气泡（:793-802） | **搬**（原样） → `_DialogPanel` 输入行 |
| `_ZhePainter`（浙字绘制） | **搬/共享** → `_ZheCenterButton` |
| `_ConfirmBtn` / `_ChoiceBtn` / `_DraftCard` | **搬/复用** → `agent_dock.dart` |
| 页面绑定（initState/build 的 `bindPage`，:149-189） | **搬** → `AgentBottomShell`（initState `_bindPage` + build 内幂等补绑，逻辑同 #53 修复） |
| 气泡拖动 `_fabX/_fabY/_bubbleX/_bubbleY` / `_snapFabToEdge` / `onPanUpdate` | **删**（底部固定槽位不可拖动，§7 位置稳定） |
| 避让 `_scheduleAvoid` / `_pickBubbleY` / `_onHighlightChanged`（:79-137） | **不搬**（退役）。文件本身因 standard_home 保留 |
| `AgentSession.bubbleX/bubbleY`（:76-77） | 长辈版不再用；standard_home AgentFab 仍引用，**保留** |

多页面挂载点切换见 §2（18 页）。

---

## 6 收尾动效（S2→S0 渐隐缩小）

### 6.1 时序编排（`AgentSession._finishAndClose`）

```dart
void _finishAndClose(Map<String, dynamic> payload) {
  _unwatchInput();
  currentHighlightKey.value = null;
  // 收尾语进窄条（§6.1 文案，task_done 当前不 append text，需补）
  final summary = (payload['voice_hint'] as String?)?.isNotEmpty == true
      ? payload['voice_hint'] as String
      : (payload['summary'] as String? ?? '已经帮您办好啦');
  ChatHistory.instance.items.add({'role': 'agent', 'text': summary});
  AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
  _panelMode = AgentPanelMode.guide;   // 原地停在窄条播报，不放大
  _uiSignal.add(null);
  LogService.saveFromTaskDone(payload);
  // 停顿 1.5s 给老人读/听完 → 渐隐缩小
  Timer(const Duration(milliseconds: 1500), () {
    _closing = true;            // 触发 opacity↓ + height↓ 同步缓动
    _uiSignal.add(null);
    Timer(const Duration(milliseconds: 320), () {
      _closing = false;
      _isGuiding = false;
      _panelMode = AgentPanelMode.closed;
      _uiSignal.add(null);
    });
  });
}
```
`task_done`（:379-383）原 4 行 reset 改为 `_finishAndClose(payload);`。

### 6.2 widget 侧（`AgentBottomShell.build` 面板宿主）

```dart
final mode = session.panelMode;
final closing = session.closing;
final panelH = closing ? 0.0 : _heightFor(mode, context);   // S1≈50%截断400, S2窄条, S3按卡片
// 渐隐 + 缩小同步
AnimatedOpacity(
  duration: const Duration(milliseconds: 300),
  opacity: closing ? 0.0 : 1.0,
  child: AnimatedSize(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOutCubic,
    alignment: Alignment.topCenter,
    child: SizedBox(height: panelH, width: double.infinity, child: panelH == 0 ? null : _buildPanel(mode)),
  ),
)
```
`AnimatedSize`（height↓）+ `AnimatedOpacity`（opacity↓）同 300ms 并行 = **渐隐缩小**，非弹出放大（§5.4 硬要求）。其余态切换（S1↔S2↔S3）共用同一 `AnimatedSize`，自动平滑（250~350ms ease，§7）。

---

## 7 风险点

| # | 风险 | 应对 |
|---|---|---|
| R1 | **软键盘遮挡 S1 输入框**（移动端 Web）。branch 旧版选择"键盘弹出即关面板"，但本设计要 S1 内打字。 | 保留 `Scaffold.resizeToAvoidBottomInset=true`（默认），让面板随键盘上推；**不要**照搬 branch 的 `didChangeMetrics` 自动关面板。桌面 Web `viewInsets.bottom` 多为 0，无影响。真机移动浏览器需联调验证（V12 旁路）。 |
| R2 | **body 压缩重排打断阅读**：S0→S1 时页面内容上移。 | 设计已接受（V2「body 真压缩」）；缓动 280ms 减轻。 |
| R3 | **收尾 `_finishAndClose` 期间用户点导航/跳页** | `_closing` 期间若 `unbindPage`/跳页，Timer 回调里判 `_panelMode`/mounted 前已 setMode(closed)；Timer 仅改 session 字段不持页面引用，安全。建议跳页时 `_reEnsureTimer?.cancel()`。 |
| R4 | **double scroll**：初次高亮滚一次 + 面板态变重滚一次。 | `_reEnsureTimer?.cancel()` 去重；改法 B 仅在 setPanelMode 真变态时调度。 |
| R5 | **face_auth / agent_settings 删 AgentFab 的行为变化** | 已定：两处均删（§2.4）。刷脸 TTS 由页面自带不依赖 dock；刷脸代理断流由"成功回执闭环"（§11）补齐——代理退到幕后等、成功即接回。 |
| R6 | **task_done 无 text 字段**：现状 task_done 只有 summary/voice_hint，收尾语需后端确保填 voice_hint（§6.1 文案）。 | 与 backend 对齐：task_done 的 `voice_hint` 填 §6.1 口语收尾语 + `tts_audio_base64`。 |
| R7 | **`elder_bottom_nav.dart` 中途删除导致编译断裂** | 全部页面迁完（Step 6）后再删该文件；迁移过程中保留。 |

---

## 8 分步实施建议（每步可独立联调）

| 步 | 内容 | 回归验证点 |
|---|---|---|
| **S1 骨架** | `AgentSession` 加 `AgentPanelMode` + `setPanelMode` + `panelOpen` 兼容层；新建 `agent_dock.dart` 含 `AgentBottomShell` + `_DockNavRow`（首页/小浙/我的）+ 空 4 态切换（dialog 占位文本）。**仅 `elder_home` 单页接入**。 | 点小浙按钮 S0↔S1↔（收起回 S0）；body 可见被压缩；首页/我的 Tab 跳转正常（V1、V2） |
| **S2 迁对话** | 把 `_BubbleWindow` 内核迁入 `_DialogPanel`（消息列表 / 输入框 / MicButton / auth / choice / draft / confirm）；`_GuidePanel` 显示最近一条；`_CardHost` 渲染 auth/choice。 | ASR 录音→识别、TTS 播放、授权卡同意/拒绝、选择卡、草稿卡、文字发送全部如旧（V12、V6、V7 静态形态） |
| **S3 自动状态机 + 收尾** | `_dispatch` / `_applyChatMessage` 接 `setPanelMode` 自动切换（S1→S2→S3→S2）；`_finishAndClose` 渐隐收尾。 | 医保引导全流程：自动缩窄（V3）、推卡自动长高（V6）、处理完缩回（V7）、走完原地播报→停顿→渐隐收起（V8） |
| **S4 高亮滚动** | 改法 A（alignment 0.5）+ 改法 B（`reEnsureVisible` + 调度）。 | 高亮"去支付"在底部不被面板遮挡、自动滚到可见；卡片长高后重滚（V4） |
| **S5 插话不打断**（含 bug 修复） | **修复现存 bug**：`agent_out_of_scope`（agent_session.dart:397-403）无条件清 `_isGuiding`+`currentHighlightKey`，引导中插无关话被判 OOS 会误清进度 → 加 `if (!_isGuiding)` guard（§3.3 完整代码）。 | S2 展开打字问无关问题→作答→收回→引导进度/高亮不变，续原步骤（V5） |
| **S6 全页面接入 + 刷脸回执** | ① 13 主流程页接 full dock；3 任务流页接 slim dock；face_auth/agent_settings 删 AgentFab；pay_password 清 import；删 `elder_bottom_nav.dart`。② **刷脸成功回执闭环（§11）**：Part A 改 `scene_login_face.txt` 第 9/10 步（backend）+ Part B 改 `face_auth_page.dart._onAllSuccess`（frontend）。 | 逐页底部形态正确（V9 slim、V10 face_auth 无 dock、V11 密码页无 dock）；登录刷脸全流程：活体成功后代理无缝续接说"登录成功"→收尾收起；全场景回归 |

---

## 9 与文档/真相同步

实施落地后需更新：
- `ISSUES.md` #79 状态（🔧→🧪）。
- `docs/ARCHITECTURE.md` §1.2「代理 UI 层」描述（底部面板替代悬浮气泡）+ 附录（如涉及新消息类型，本方案未新增 WS 消息）。
- 本方案与 `docs/AGENT_DOCK_REDESIGN.md` 配套：前者管"怎么实现"，后者管"长什么样"。

> **未新增任何 WebSocket 消息类型** —— 4 态切换全部由现有信号（cmd_say/cmd_highlight/permission_request/agent_choice_request/task_done/agent_out_of_scope）驱动，后端仅需保证 task_done 带口语 voice_hint（R6）。

---

## 10 后续增强（记录，本期不做）

- **刷脸失败/退出路径回执**：本期只做"刷脸成功→接回引导"的闭环（§11）。失败（活体不过）/ 用户中途退出（`face_auth_page._exitToLogin` → `context.pop`）时，代理仍停在第 9 步 `cmd_wait_user`，靠 180s 超时收尾——体验不够顺。后续增强：
  - 前端 `_exitToLogin` / 活体失败回调里发 `AgentSession.instance.sendStepCompleted(lastAction: 'face_auth_failed', notes: 'liveness_failed_or_exit')`。
  - prompt `scene_login_face.txt` 第 10 步加分支：若回执为 failed，cmd_say("这次没认出来，要不要再试一次？") 并引导回刷脸入口。
- **标准版 AgentDock**：本期只做长辈版（§8 决策2）。标准版若追求一致性，需为 `standard_home`（无底部导航页）补一套底部容器并对齐 4 态。

---

## 11 刷脸成功回执闭环（本期纳入，落地片段）

> **问题**：登录刷脸引导走到「活体检测开始」就断头——`scene_login_face.txt` 第 9 步无 `cmd_wait_user`，代理 run 终止（`_isGuiding=false`）；且 `face_auth_page` 刷脸成功不发任何回执。代理无法感知"刷脸通过"，流程断流。
> **修法**：前后端 interlock，缺一不可。Part A 让代理 run 停在第 9 步 `cmd_wait_user`（保持 `_isGuiding=true`，"退到幕后等"）；Part B 在刷脸成功瞬间发 `step_completed` 回执唤醒 run，续走第 10 步收尾。
> **与"刷脸页不挂 dock"兼容**：`AgentSession` 是单例，WS session 与 `_isGuiding` 是**会话级**（非页面级），`sendStepCompleted` 只依赖 `_sessionId`+`WsClient`+`_isGuiding`，无需页面绑定/dock。

### 11.1 Part A — backend prompt（`backend/prompts/scene_login_face.txt`）

**改前（:50-52，第 9 步为最后一步，无等待）**：
```
第 9 步（活体检测开始）
  cmd_say(voice_hint="请正对屏幕，跟着提示眨眼、左右摇头")
```
（随后第 67 行【完成回复】直接结束 → run 终止）

**改后（第 9 步补 `cmd_wait_user` + 新增第 10 步收尾）**：
```
第 9 步（活体检测开始）
  cmd_say(voice_hint="请正对屏幕，跟着提示眨眼、左右摇头")
  cmd_wait_user(reason="等用户完成刷脸活体检测")

第 10 步（刷脸活体检测通过后，系统自动续传 face_auth_success）
  cmd_say(voice_hint="刷脸通过啦，已经帮您登录成功~")
```
**配套**：
- 第 67 行【完成回复】文本相应改为登录成功语义（如"已帮您完成刷脸登录"），保持在第 10 步之后输出。
- `login_face` 工具集已含 `cmd_wait_user`（`agent_core.py:35`），**无需改工具注册**。
- 第 9 步 `cmd_wait_user` 超时 180s（`agent_core.py:426`），活体检测远小于此，安全。

### 11.2 Part B — frontend（`app/lib/pages/face_auth_page.dart`）

**文件头补 import**（若未引入）：
```dart
import '../services/agent_session.dart';
```

**`_onAllSuccess`（:52-67）在 `context.go(AppRoutes.elderHome)`（:66）之前插一行**：
```dart
  void _onAllSuccess() {
    ref.read(loginProvider.notifier).login('用户');
    UserProfileService.instance.setProfile(
      phone: '13800138000',
      idCard: '330102194505061234',
    );
    LogService.saveManual(
      scene: 'face_login',
      summary: '通过刷脸验证完成登录',
      steps: [
        {'action': '人脸检测', 'target': '眨眼 + 转头验证通过'},
        {'action': '登录', 'target': '验证成功'},
      ],
    );
+   // 刷脸成功回执：唤醒幕后等待的引导流，无缝接回（§11）
+   AgentSession.instance.sendStepCompleted(
+     lastAction: 'face_auth_success', notes: 'liveness_passed');
    context.go(AppRoutes.elderHome);
  }
```

### 11.3 链路时序（验证用）

```
... 第8步 cmd_wait_user(等摄像头授权) → 用户授权
→ 第9步 cmd_say("眨眼摇头") + cmd_wait_user(等活体)   ← run 停在此，_isGuiding=true
→ [face_auth_page 活体检测：S5眨眼/S7转头/S9成功(1.5s停顿)]
→ _onAllSuccess: sendStepCompleted('face_auth_success')  ← Part B 回执
   ↘ (并 context.go(elderHome) → bindPage 自动再发 page_changed)
→ ws_handler._on_step_completed → agent_core.resolve_step（0.3s debounce 合并两信号）
→ _step_event.set() → 第9步 cmd_wait_user 唤醒
→ 第10步 cmd_say("刷脸通过啦，登录成功~") → 【完成回复】→ task_done
→ elderHome 上的 AgentDock 走 S2 窄条原地播报 → 渐隐收起（§6）  ← 无缝接回
```

**回归验证点**：刷脸活体成功后，代理在 elderHome 上接着说"刷脸通过啦，登录成功"并走收尾收起（而非到刷脸就静默断流）。归入实施 **S6** 步。
