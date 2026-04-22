# 技术栈评审 — Phase 3 开工前

> Reviewer：architect
> Date：2026-04-18
> 基准：PRD v2.0 + AGENT_UI_SPEC v1.1 + 现有 lib/ 代码
>
> **一句话结论**：现有技术栈整体可承载 Phase 3，需新增 **2 个 pub 依赖**、**1 个 token**、**1 个新 state 文件**；破坏性改动 **3 处**（PhoneFrame 结构变更 / VoiceInputService 接口升级 / AgentOverlayLayer 接入）；无需换框架、无需迁移路由。

---

## A. 现有技术栈适配性复核

### A.1 框架层

| 技术 | 当前状态 | Phase 3 适配性 | 结论 |
|---|---|---|---|
| Flutter 3.41.7 Web | `./bin/flutter`，稳定版 | Web Speech API 可通过 `dart:js_interop` 调用，WebSocket 有 `web_socket_channel` | ✓ 保留 |
| Riverpod v3.3.1 | `NotifierProvider` 模式，已有 `LoginNotifier` / `ModeNotifier` | `AgentNotifier` 同模式；支持跨 widget 树共享 AgentState | ✓ 保留 |
| go_router v17.2.1 | ShellRoute 包 PhoneFrame，11 条路由 | Agent UI 挂在 PhoneFrame Stack 层，不新增路由；`IntentDispatcher` 现有 `NavigateTo` intent 可扩展 | ✓ 保留，扩展 intent 种类 |
| Dart sdk ^3.11.5 | 已锁 | `dart:js_interop` / `package:web` 需 Dart ≥ 3.3（已满足）| ✓ 保留 |

### A.2 状态层

| 文件 / Provider | 当前状态 | Phase 3 需求 | 结论 |
|---|---|---|---|
| `lib/core/state/app_state.dart` | `loginProvider` / `modeProvider` / `loginBannerDismissedProvider` | 无需改动；`PersistentBanner` 新增读 `agentStateProvider` 判 idle | ✓ 保留，轻度扩展 |
| `AgentState`（不存在）| — | 需新建 `lib/core/state/agent_state.dart`，定义 `AgentPhase` + `AgentNotifier` | ⚠️ 新增文件 |
| `AppIntent` + `IntentDispatcher` | 5 个 intent（NavigateTo/GoBack/SwitchMode/DoLogin/DoLogout）| 需补 agent 相关 intent（`ActivateAgent` / `DeactivateAgent` / `FillFormField`）；additive 不破坏现有代码 | ⚠️ 扩展（不破坏）|

### A.3 UI 层

| 组件 | 当前状态 | Phase 3 需求 | 结论 |
|---|---|---|---|
| `PhoneFrame` | `child` 直接包在 `ClipRRect` 内，无 Stack | 需变为 Stack 容纳 `_AgentOverlayLayer`（层 2-3）| **⚠️ 破坏性改动 1** |
| `SystemDialog` / `InAppOverlay` | 两套组件族物理分开 | IntentProposalCard 是第三套语义（非阻塞但有蒙层，不属于现有两类）；新建独立组件，不复用现有基类 | ✓ 现有两族不动，新增 agent/ 目录 |
| `PersistentBanner` | 读 `loginProvider` + `loginBannerDismissedProvider` | 需新增读 `agentStateProvider.phase != AgentPhase.idle` 时 `return SizedBox.shrink()` | ⚠️ 轻度改动（5 行内）|
| `design_tokens.dart` | 无 `agentPrimary` | 新增 `AppColors.agentPrimary = Color(0xFF0070E0)` | ⚠️ 新增 1 token |

### A.4 服务层

| 服务 | 当前状态 | Phase 3 需求 | 结论 |
|---|---|---|---|
| `VoiceInputService` | `Future<String> listen()` 单次返回 | 真 STT 需要流式：收音开始→实时文字→最终结果；接口须升级 | **⚠️ 破坏性改动 2** |
| `FaceAuthService` | `Future<FaceAuthResult> authenticate()` | Phase 3 需逐步语音引导事件流；接口需扩展（可先保持当前用于 mock，新增 stream 方法）| ⚠️ 接口扩展 |
| `ServiceRepository` | 已激活（mock 数据）| Phase 3 无变化 | ✓ 保留 |
| `InteractionLogger` | 僵尸骨架 | Phase 3 开始激活（记录代理操作历史，对应 F6 / UI7）| ⚠️ 激活 |
| `AgentClient`（不存在）| — | 需新建 `lib/services/agent_client.dart`（WebSocket 客户端）| ⚠️ 新增文件 |

---

## B. 新能力缺口清单

### B.1 WebSocket Client（agent-backend 联调）

**是什么**：Flutter 侧向 agent-backend（FastAPI + agno）建 WebSocket 长连接，发送用户语音文字、接收代理响应（意图/执行结果/语音文本）。

**为什么需要**：agent-backend 已接 DeepSeek-V3（Step 4 完工），但 Flutter 侧无 WebSocket 客户端。

| 方案 | 优劣 |
|---|---|
| `web_socket_channel ^3.0.1`（推荐）| Flutter 官方支持；Web/mobile 同一 API；pub.dev 3000+ likes；100% Flutter Web 兼容 |
| `dart:html WebSocket` 直接调用 | 仅限 Web 平台，跨平台迁移成本高 |

**推荐**：`web_socket_channel ^3.0.1`

**实施成本**：低（~200 行，`lib/services/agent_client.dart`）

**关键接口骨架**：
```dart
// lib/services/agent_client.dart
class AgentClient {
  WebSocketChannel? _channel;

  void connect(String wsUrl);
  void send(AgentMessage message);
  Stream<AgentMessage> get messageStream;
  void disconnect();
}

// 消息类型（与 backend 协议对齐）
sealed class AgentMessage { const AgentMessage(); }
class UserUtterance extends AgentMessage { final String text; ... }
class AgentIntent extends AgentMessage { final String intentType; final Map<String, dynamic> params; ... }
class AgentExecution extends AgentMessage { final String step; final String display; ... }
class AgentResult extends AgentMessage { final bool success; final String summary; ... }

final agentClientProvider = Provider<AgentClient>((ref) => AgentClient());
```

> ⚠️ **待拍板决策 D1**：WebSocket URL 格式（`ws://localhost:8000/ws`？）及消息 schema（JSON keys）需与 backend 对齐。此处只定义 Flutter 侧接口，协议由双方约定后填入。

---

### B.2 STT（语音输入）

**是什么**：用户说话 → 文字，供代理理解意图（F1 / 场景 B）。

**现有接口**：`Future<String> listen()` — 单次 800ms mock，不可用于真实 STT。

**接口升级方案**（破坏性改动 2 的具体方案）：

```dart
// lib/services/voice_input_service.dart（升级后）
abstract class VoiceInputService {
  /// 已有：单次识别（mock 仍可用）
  Future<String> listen();
  /// 新增：流式识别（实时文字 → 最终结果）
  Stream<SttEvent> listenStream();
  void stopListening();
}

sealed class SttEvent { const SttEvent(); }
class SttPartial extends SttEvent { final String text; ... }   // 实时中间结果
class SttFinal extends SttEvent { final String text; ... }     // 最终结果
class SttError extends SttEvent { final String message; ... }  // 错误/超时
```

**SearchPage 影响**：目前 `SearchPage` 调 `voiceInputServiceProvider.listen()`。升级后保持 `listen()` 不变（mock 仍返回固定文字），SearchPage **无需改动**。`listenStream()` 只在 AgentController 中使用。

| 方案 | Web 兼容 | 方言支持 | 依赖 | 推荐阶段 |
|---|---|---|---|---|
| **Web Speech API**（推荐 Phase 3）| ✓（Chrome 100%）| 普通话 zh-CN ✓；杭州话 ❌ | 零额外 pub 依赖（`dart:js_interop`）| Phase 3 |
| Baidu STT REST API | ✓（HTTP）| 普通话 ✓；杭州话 `dev_pid` 切换（P2）| `http ^1.2.1`（已考虑）| Phase 4 / 可选 |
| `flutter_sound` | ❌ Web 不支持 | — | — | 不用 |

**推荐**：Phase 3 用 Web Speech API（`SpeechRecognition`），通过 `dart:js_interop` 封装；杭州话 P2 阶段切 Baidu。

**实施要点**：`WebSpeechSttService implements VoiceInputService`，`listenStream()` 内部用 `SpeechRecognition.onresult` 事件转 Stream。Chrome 不需要额外权限页（Web Speech API 自带浏览器权限提示，但我们的 SystemDialog 是自绘 Android 样式，需确认：自绘弹窗显示后再调 `SpeechRecognition.start()`，浏览器权限弹窗会叠在上方 — 这是 Web 平台的已知限制，不破坏还原度，只是视觉上有两层弹窗）。

**降级策略**：`SpeechRecognition` 不可用（Firefox / 网络断）时，`listenStream()` 发 `SttError`，AgentNotifier 切换到文字输入 fallback（UI2 显示输入框）。

---

### B.3 TTS（语音播报）

**是什么**：代理文字 → 语音（F1/F2/F3 全场景的语音反馈）。

| 方案 | Web 兼容 | 音质 | 依赖 | 推荐 |
|---|---|---|---|---|
| **Web Speech Synthesis**（推荐）| ✓（Chrome/Edge/Safari）| 一般（系统 TTS 音色）| 零额外依赖 | Phase 3 |
| Baidu TTS REST API | ✓（HTTP + Audio）| 好（可选慢速音色）| `http` 包 | Phase 4 / 可选 |

**推荐**：Phase 3 用 `SpeechSynthesis`，`dart:js_interop` 封装。语速通过 `SpeechSynthesisUtterance.rate` 控制（默认 0.8，对应 PRD 慢速 ~120 字/分）；NF3 语速调节在"助手设置"页通过 Provider 值传入。

**新建文件**：`lib/services/tts_service.dart`

```dart
abstract class TtsService {
  Future<void> speak(String text, {double rate = 0.8});
  Future<void> stop();
}
```

**依赖**：零额外 pub 包（`dart:js_interop` 已内置）。

---

### B.4 AgentState 状态机

**是什么**：驱动 4 个 Agent UI 组件显示/隐藏/内容的核心状态，也是 WebSocket 消息流的处理中枢。

**新建文件**：`lib/core/state/agent_state.dart`

```dart
enum AgentPhase { idle, listening, proposing, executing, done }

/// S7 clarification_request 的选项条目（label=展示文字，value=回传给 backend 的值）
@immutable
class ClarificationOption {
  final String label;
  final String value;
  const ClarificationOption({required this.label, required this.value});
}

@immutable
class AgentState {
  final AgentPhase phase;
  final String speechText;                          // AgentSpeechBubble 内容
  final String progressText;                        // AgentProgressIndicator 内容
  final String proposalText;                        // IntentProposalCard 复述文字
  final bool executionDone;                         // ProgressIndicator 绿√ 态
  final AgentPermissionLevel permissionLevel;       // L1/L2/L3
  final String? currentProposalId;                  // ← 新增：S2 收到的 proposal_id，C3 authorize/deny 时原样回传
  final List<ClarificationOption>? clarificationOptions; // ← 新增：S7 options，非空时 SpeechBubble 下方渲染快捷按钮
  const AgentState({...});
  static const idle = AgentState(phase: AgentPhase.idle, ...);
}

class AgentNotifier extends Notifier<AgentState> {
  @override
  AgentState build() => AgentState.idle;

  void startListening();                                         // 唤醒 → listening
  void onUtteranceReceived(String text);                         // 发给 backend
  void onIntentProposed(String proposalId, String summary);      // listening → proposing（存 proposalId）
  void onExecuteReceived();                                      // proposing → executing（收到 S3 后切态，不在 C3 发出时切）
  void onUserRejected();                                         // proposing → listening
  void onClarificationReceived(List<ClarificationOption> opts);  // 更新 clarificationOptions，保持 listening
  void onExecutionStep(String display);                          // 更新 progressText
  void onExecutionDone(String result);                           // executing → done
  void stop();                                                   // 任意 → idle
}

final agentStateProvider = NotifierProvider<AgentNotifier, AgentState>(AgentNotifier.new);
```

**WebSocket 绑定方式**：`AgentNotifier.build()` 中通过 `ref.listen(agentClientProvider)` 订阅 `messageStream`，将 `AgentMessage` 转换为状态变更。`AgentClient` 不持有状态，只负责传输。

---

### B.5 验证码自动填写（F2）

**是什么**：代理帮用户将 SMS 验证码填入 OTP 输入框（场景 C）。

**Web 平台限制**：浏览器 JS 无法读取手机短信。PRD §七 场景 C 已明确：**使用固定 mock 验证码 `123456`**，用户测试前口头告知被试。

**结论**：无需 OCR，无需额外依赖。`AgentNotifier` 有一个 `mockSmsCode = '123456'` 常量；`IntentProposalCard` 弹出后用户确认，代理逐位填入 `VerifyPage` OTP 框（通过 `TextEditingController` 注入，由 AgentController 持有引用或通过 GlobalKey 定位）。

**实施细节**：OTP Controller 注册到 `agentStateProvider` 可读的 Riverpod Provider，或通过 `GlobalKey<VerifyPageState>` 传递（后者耦合较重，推荐前者）。

**场景 C 介入模式（已决策：B-半主动，PRD §九豁免 D1）**：
VerifyPage 进入时由前端路由感知自动触发代理提议，无需用户手动唤醒。实施方式：`agentClient` 在路由切换到 `/login/verify` 时发送触发消息，backend 收到后推送 S1 提议 + S2 IntentProposal（FillFormField）。
```dart
// lib/features/agent/agent_controller.dart 内
ref.listen(routerProvider, (previous, next) {
  if (next.location == AppRoutes.verify &&
      previous?.location != AppRoutes.verify) {
    agentClient.sendSystemPageEnter(page: AppRoutes.verify);
    // 对应 WebSocket C3 action: "system_page_enter", extra: {"page": "/login/verify"}
  }
});
```
触发后 `AgentPhase` 从 `idle → listening`，backend 随即推 S1("您收到一条验证码，需要我帮您填上去吗？") + S2(FillFormField) — 之后走正常"预告-确认-执行"三阶段。

---

### B.6 刷脸语音引导（F3）

**是什么**：FaceAuthPage 进入认证时，代理语音说明动作（"眨眼"/"摇头"），并在失败时安抚（场景 A）。

**当前 FaceAuthService**：`Future<FaceAuthResult> authenticate()` — 单次返回，无法发出中间步骤事件。

**扩展方案**（最小破坏）：

```dart
// lib/services/face_auth_service.dart（扩展，不删现有接口）
abstract class FaceAuthService {
  Future<FaceAuthResult> authenticate(); // 保留现有
  // 新增：流式认证事件（Phase 3）
  Stream<FaceAuthEvent> authenticateWithGuidance();
}

sealed class FaceAuthEvent { const FaceAuthEvent(); }
class FaceAuthInstruction extends FaceAuthEvent { final String voiceText; final String animationType; ... }
class FaceAuthProgress extends FaceAuthEvent { final String step; ... }
class FaceAuthComplete extends FaceAuthEvent { final FaceAuthResult result; ... }
```

`MockFaceAuthService.authenticateWithGuidance()` 返回预设事件序列（眨眼指令→等待→成功/失败）。`FaceAuthPage` 的 `_AuthenticatingView` 消费此 stream，触发 `TtsService.speak()` 和动画。

**成本**：中（约 100 行新增，FaceAuthPage 消费层需改动）。

---

### B.7 草稿自动保存（F8）

**是什么**：表单填写中途，误触返回键时询问是否保存草稿；下次进入同一表单提示恢复（场景：辅助场景）。

**用户已拍板**：LocalStorage（`shared_preferences`）。

**推荐**：`shared_preferences ^2.3.2`（Flutter Web 自动用 `localStorage`，无需额外配置）。

**Key 命名约定**：
```
draft_<route_path>_<field_name>
// 例：draft_/login/verify_otp
```

**清理策略**：写入时同存 `draft_<route>_ts`（时间戳），读取时检查是否 > **30 天**，过期自动清除。（D5 已拍板：30 天与 UI7 操作记录保留策略对齐；7 天过短，老年用户一周不用一次可能丢失草稿）用户手动清空：`SharedPreferences.getInstance().then((p) => p.clear())`（仅清 draft_ 前缀 key，不清其他）。

**依赖新增**：`shared_preferences: ^2.3.2`

---

## C. 代码结构演进建议

### C.1 Agent UI 4 组件位置

**推荐**：`lib/core/widgets/agent/`（独立子目录）

```
lib/core/widgets/
├── agent/
│   ├── agent_speech_bubble.dart
│   ├── intent_proposal_card.dart
│   ├── agent_progress_indicator.dart
│   └── agent_stop_button.dart
├── elder_bottom_nav.dart
├── in_app_overlay.dart
├── permission_flow_helper.dart
├── persistent_banner.dart
├── phone_frame.dart         ← 需改造（破坏性改动 1）
└── system_dialog.dart
```

理由：4 个组件是跨页面框架级组件，不属于任何 feature，放 `core/widgets/` 与 `PersistentBanner` 一致；4 个独立文件值得分子目录（与将来可能的 `agent_overlay_layer.dart` / `agent_activation_button.dart` 同组）。

---

### C.2 Agent 场景逻辑的 features/ 组织

**推荐**：新建 `lib/features/agent/` 目录

```
lib/features/agent/
├── agent_controller.dart    ← AgentNotifier 的业务逻辑层（场景 A/B/C 路由分发）
└── agent_history_page.dart  ← F6/UI7 操作记录页（Phase 4）
```

**不要**把场景 A/B/C 的逻辑散到 `login/` / `search/` / `service/` feature 里——代理是横切关注点，内嵌会导致各 feature 互相知晓代理状态，耦合过重。

`AgentController`（位于 `lib/features/agent/agent_controller.dart`）持有：
- `AgentClient` 引用（WebSocket）
- `TtsService` 引用
- `VoiceInputService` 引用
- `IntentDispatcher` 引用（执行 NavigateTo 等意图）

实际上 `AgentController` 和 `AgentNotifier` 可合并为一个文件（`AgentNotifier` 就是业务层），`features/agent/` 主要承载 `agent_history_page.dart` 等页面级产物。

---

### C.3 L1/L2/L3 权限模型

**推荐**：独立 Provider，存于 `lib/core/state/agent_state.dart`（与 `AgentState` 同文件）

```dart
enum AgentPermissionLevel { l1, l2, l3 }

class AgentPermissionNotifier extends Notifier<AgentPermissionLevel> {
  @override
  AgentPermissionLevel build() => AgentPermissionLevel.l1; // 默认最低权限
  void upgradeTo(AgentPermissionLevel level);
  void temporaryDowngrade(); // "这次我自己来"，单次不永久
}

final agentPermissionProvider =
    NotifierProvider<AgentPermissionNotifier, AgentPermissionLevel>(
        AgentPermissionNotifier.new);
```

**使用方式**：`AgentNotifier` 在收到 `AgentIntent` 时先查 `agentPermissionProvider`，判断是否需要弹 `IntentProposalCard`（L1：只引导，不执行；L2：非敏感自动执行；L3：敏感操作每次弹确认）。

**入口**：助手设置页（Phase 4 AgentHistoryPage 旁边，或 MyPage Settings Section 的"助手设置"行）。

---

### C.4 AgentClient WebSocket 位置

**推荐**：`lib/services/agent_client.dart`

理由：与现有 `VoiceInputService` / `FaceAuthService` / `ServiceRepository` 同层级；都是"对外部系统的抽象封装"。

```dart
// lib/services/agent_client.dart
class AgentClient {
  // URL 通过 --dart-define=WS_BASE_URL=ws://localhost:8000 注入，不硬编码
  // 默认值 fallback 仅供本地开发，正式 demo 用 --dart-define 覆盖
  static const _wsBaseUrl = String.fromEnvironment(
    'WS_BASE_URL',
    defaultValue: 'ws://localhost:8000',
  );

  WebSocketChannel? _channel;
  Timer? _reconnectTimer;      // 指数退避重连 Timer
  int _reconnectAttempts = 0;  // 当前重试次数

  void connect(String sessionId); // URL = '$_wsBaseUrl/ws/$sessionId'
  void send(AgentMessage message);
  Stream<AgentMessage> get messageStream;
  void disconnect();
  bool get isConnected;

  // 重连策略：web_socket_channel 不含自动重连，须自实现
  // 退避序列：1s → 2s → 4s → 8s → 16s → 30s（上限）
  // 触发条件：messageStream onError / onDone（非主动 disconnect）
  void _scheduleReconnect(String sessionId) {
    final delay = _backoffDelay(_reconnectAttempts);
    _reconnectTimer = Timer(delay, () {
      _reconnectAttempts++;
      connect(sessionId); // 重连时复用同一 sessionId（支持 session resume）
    });
  }
  Duration _backoffDelay(int attempt) =>
      Duration(seconds: min(30, pow(2, attempt).toInt())); // 1→2→4→8→16→30
}

final agentClientProvider = Provider<AgentClient>((ref) {
  final client = AgentClient();
  ref.onDispose(client.disconnect);
  return client;
});
```

**重连注意事项**：
- `web_socket_channel ^3.0.1` 本身**不含自动重连**（连接断开后 `messageStream` 直接 close），frontend 必须在 `AgentClient` 内自实现 Timer 驱动的指数退避重连
- 重连时发 `C4 session_control {action: "resume", last_ts: ...}`，backend 可恢复会话上下文
- 重连期间 `AgentProgressIndicator` 应显示"网络不太稳，正在重连..."（由 AgentNotifier 在感知断连时更新 `progressText`）

---

### C.5 PhoneFrame 破坏性改动（改造方案）

当前 `phone_frame.dart`：`ClipRRect(child: child)`

改造后：

```dart
class PhoneFrame extends ConsumerWidget {
  final Widget child;
  const PhoneFrame({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ColoredBox(
      color: AppColors.phoneBg,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: DesignSize.width,
            height: DesignSize.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.phone),
              child: Stack(   // ← 新增 Stack
                children: [
                  child,                          // 层 0：路由内容（不变）
                  const _AgentOverlayLayer(),     // 层 2-3：4 个 Agent UI 组件
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// 同文件，读 agentStateProvider 按需渲染 4 个组件
class _AgentOverlayLayer extends ConsumerWidget {
  const _AgentOverlayLayer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agent = ref.watch(agentStateProvider);
    return Stack(
      children: [
        if (agent.phase != AgentPhase.idle) ...[
          const AgentProgressIndicatorWrapper(),  // 顶部条带
          const AgentSpeechBubbleWrapper(),       // 底部气泡
          const AgentStopButtonWrapper(),         // 右下角悬浮
        ],
        if (agent.phase == AgentPhase.proposing)
          const IntentProposalCardWrapper(),      // 层 3：含蒙层
      ],
    );
  }
}
```

**ShellRoute 兼容**：`app_router.dart` 的 `ShellRoute.builder` 已是 `(context, state, child) => PhoneFrame(child: child)`，`PhoneFrame` 从 `StatelessWidget` 改为 `ConsumerWidget` 后 ShellRoute 用法不变，无需改 `app_router.dart`。

> **注意**：`StatelessWidget` → `ConsumerWidget` 是改造的唯一类型变更。`build` 方法签名从 `(BuildContext)` 改为 `(BuildContext, WidgetRef)`，其他不变。

---

## D. 风险与决策

### D.1 新增 pub 依赖清单

| 包 | 版本范围 | 用途 | 必须 / 可选 |
|---|---|---|---|
| `web_socket_channel` | `^3.0.1` | agent-backend WebSocket 联调 | **必须**（Phase 3）|
| `shared_preferences` | `^2.3.2` | F8 草稿保存（LocalStorage）| **必须**（Phase 3）|
| `http` | `^1.2.1` | Baidu STT/TTS API（备选升级路径）| 可选（P2 方言阶段）|

> Web Speech API（STT/TTS）和 `dart:js_interop` 是 Dart/Flutter SDK 内置，**不需要 pub 包**。

**pubspec.yaml 改动量**：仅 `dependencies` 块增 2-3 行，无破坏性。

---

### D.2 明确放弃的能力（避免 PM 误理解为待实现）

| 能力 | 放弃原因 |
|---|---|
| 真实 SMS 读取（OTP 自动感知）| Web 浏览器沙箱无此权限；使用 mock `123456` |
| 真实生物识别 / ML Kit 活体检测 | Web 平台不支持；mock 动画 + 预设事件流 |
| 跨 session 代理记忆 / 个性化推荐 | PRD §三"明确不做"，单次会话不持久化 |
| 支付操作委托 | PRD §三"明确不做"，用户调研普遍拒绝 |
| 体感中断（手机晃动）| P2 可选，毕设不纳入验收范围 |
| 语音唤醒（唤醒词"你好助手"）| P2 可选，默认关闭，不进 Phase 3 |
| 多设备草稿同步 | PRD §三 F8 明确：仅 LocalStorage 单设备持久化 |
| 原生 Android/iOS 安装包 | 项目定位 Flutter Web only |

---

### D.3 破坏性改动汇总（3 处）

| # | 改动 | 涉及文件 | 影响范围 | 解法 |
|---|---|---|---|---|
| 1 | `PhoneFrame` 增加 Stack + `_AgentOverlayLayer` | `phone_frame.dart` | ShellRoute（go_router）消费端无需改；`StatelessWidget` → `ConsumerWidget` 签名变 | 见 §C.5 骨架 |
| 2 | `VoiceInputService` 新增 `listenStream()` / `stopListening()` | `voice_input_service.dart` | `SearchPage` 调用 `listen()` 不受影响；`MockVoiceInputService` 需补实现空 stream | 见 §B.2 接口骨架 |
| 3 | `PersistentBanner` 新增 `agentStateProvider` 依赖 | `persistent_banner.dart` | 5 行内改动（build 方法头部加 idle 判断）；无视觉变化，只在代理激活时隐藏 | 见 §A.3 |

> **无需重构路由、无需迁移状态管理框架、无需换构建工具。**

---

### D.4 FastCheck 清单（frontend 动手前对照）

1. `pubspec.yaml` 已加 `web_socket_channel` + `shared_preferences`，已运行 `./bin/flutter pub get`（确认无版本冲突）
2. `lib/core/theme/design_tokens.dart` 已在 `AppColors` 末尾新增 `agentPrimary = Color(0xFF0070E0)`
3. `lib/core/state/agent_state.dart` 存在，`AgentPhase` 枚举包含 5 个值（idle/listening/proposing/executing/done），`agentStateProvider` 可从任意 `ConsumerWidget` 读取
4. `PhoneFrame` 已改为 `ConsumerWidget`，`build(context, ref)` 返回的 widget 树中有 `Stack`，第二层是 `_AgentOverlayLayer`
5. `PersistentBanner` 的 `build()` 方法中，第一个判断是 `if (ref.watch(agentStateProvider).phase != AgentPhase.idle) return const SizedBox.shrink()`（在 login/dismiss 判断之前）
6. 4 个 agent UI 文件均位于 `lib/core/widgets/agent/` 目录，各自可独立运行 `flutter analyze` 无 issues
7. `AgentClient` 有 `connect()` / `send()` / `messageStream` / `disconnect()`，且 `messageStream` 是 `Stream<AgentMessage>`（非 `dynamic`）
8. `VoiceInputService` 接口新增了 `Stream<SttEvent> listenStream()` 和 `void stopListening()`，`MockVoiceInputService` 对两个新方法有空实现（返回 `const Stream.empty()`），`SearchPage` 调用路径不受影响
9. `lib/core/state/agent_state.dart` 中 `AgentState.idle` 是 `const` 常量（避免每次 build 新建对象触发 Riverpod 无效 rebuild）
10. `./bin/flutter analyze` 全项目 0 issues；`./bin/flutter build web` 构建通过

---

### D.5 决策项状态

| # | 问题 | 状态 | 结论 |
|---|---|---|---|
| **D1** | WebSocket 通信协议 schema（JSON key 命名）| ✅ 已拍板（PRD §九）| Backend 产出 `AGENT_WEBSOCKET_SCHEMA.md`，architect review 通过（有条件）；`AgentMessage` 字段对齐 schema 定义 |
| **D2** | Phase 3 backend URL 注入方式 | 🔲 待定 | 推荐 `--dart-define=WS_BASE_URL=ws://localhost:8000`，已在 §C.4 骨架中体现；等 backend 确认 |
| **D3** | `InteractionLogger` Phase 3 激活 vs Phase 4 | 🔲 待定 | 推荐 Phase 3 激活写入，Phase 4 做展示 UI；等 team-lead 确认 |
| **D4** | L3 权限（身份证填写）Phase 3 范围 | ✅ 已拍板（PRD §九）| Phase 3 仅实现 L1/L2；L3 推 Phase 4；答辩演示场景 B/C 不依赖 L3 |
| **D5** | 草稿保存 TTL | ✅ 已拍板（PRD §九）| **30 天**（B.7 已同步）|

---

## 附：新建文件清单（Phase 3 全量）

```
lib/
├── core/
│   ├── state/
│   │   └── agent_state.dart          ← 新建（AgentPhase + AgentState + AgentNotifier + AgentPermissionNotifier）
│   ├── theme/
│   │   └── design_tokens.dart        ← 改动（新增 agentPrimary token，+1 行）
│   └── widgets/
│       ├── agent/                    ← 新建目录
│       │   ├── agent_speech_bubble.dart
│       │   ├── intent_proposal_card.dart
│       │   ├── agent_progress_indicator.dart
│       │   └── agent_stop_button.dart
│       ├── persistent_banner.dart    ← 改动（+5 行 agentStateProvider 判断）
│       └── phone_frame.dart          ← 改动（StatelessWidget→ConsumerWidget + Stack）
├── features/
│   └── agent/
│       └── agent_controller.dart     ← 新建（可选；若 AgentNotifier 本身足够薄则暂不建）
└── services/
    ├── agent_client.dart             ← 新建（WebSocket 客户端）
    ├── tts_service.dart              ← 新建（TTS 抽象 + WebSpeechTtsService 实现）
    └── voice_input_service.dart      ← 改动（接口扩展，+15 行）
```

**变更记录**：

| 日期 | 版本 | 变更摘要 |
|---|---|---|
| 2026-04-18 | v1.1 | 后接 schema review 反馈 + 场景 C 决策同步：①AgentState 补 `currentProposalId` + `clarificationOptions` 字段 + `ClarificationOption` 类；②AgentNotifier `onIntentProposed` 签名加 `proposalId` 参数，`onUserConfirmed` 改名 `onExecuteReceived`（收 S3 时切态），新增 `onClarificationReceived`；③AgentClient 骨架补 `--dart-define=WS_BASE_URL` 注入 + 指数退避重连 Timer 说明；④B.5 场景 C 补路由感知触发方案（B-半主动）；⑤D.5 D1/D4/D5 标记已拍板，B.7 TTL 改 30 天 |
| 2026-04-18 | v1.0 | 初版，基于 PRD v2.0 + SPEC v1.1 + 现有 lib/ 代码 |
