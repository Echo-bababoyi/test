# 修复方案：登录后 trust 不升级 + cmd_navigate 缺失

> 作者：architect｜日期：2026-05-26｜状态：待开发实施
>
> 覆盖三个根因：
> - **A**（后端 + 前端）trust 无法传播到已存在的 WS session
> - **B**（前端）登录后信任选择卡不再触发
> - **C**（后端）env block 用未过滤工具集，谎报 cmd_navigate 可用 → 工具不存在 → DeepSeek 400
>
> **最小可测组合 = A + B**（让"登录→选 semi/full→查养老金"跑通）。C 为防御硬化，建议同批做。

---

## 依赖顺序

1. **后端 A**（新增 `trust_changed` 消息类型 + `set_trust_level`）——先做，否则前端发的消息会被当 unknown type。
2. **前端 A-4**（`sendTrustChanged` 方法）——B 和 A-5 都依赖它，前端内部先加这个方法。
3. **前端 A-5 + B**——依赖 A-4。
4. **后端 C**——完全独立，可并行。

后端 A、C 之间无依赖，可并行。

---

# 后端改动

## 后端文件 1：`backend/models.py`

### 1.1 InboundMessageType 加枚举（第 16 行后）

当前（6-16）：
```python
class InboundMessageType(str, Enum):
    agent_wake = "agent_wake"
    audio_chunk = "audio_chunk"
    audio_end = "audio_end"
    user_confirm = "user_confirm"
    permission_response = "permission_response"
    query_result_ready = "query_result_ready"
    text_input = "text_input"
    page_changed = "page_changed"
    step_completed = "step_completed"
    sms_code_generated = "sms_code_generated"
```
在 `sms_code_generated` 行后加一行：
```python
    trust_changed = "trust_changed"
```

### 1.2 新增 payload 模型（第 96 行 `SmsCodeGeneratedPayload` 后）

当前（94-96）：
```python
class SmsCodeGeneratedPayload(BaseModel):
    session_id: str
    code: str
```
其后新增（`Literal` 已在第 2 行 import，无需改 import）：
```python


class TrustChangedPayload(BaseModel):
    session_id: str
    trust_level: Literal["guide", "semi", "full"]
```

### 1.3 注册到 INBOUND_PAYLOAD_MAP（第 109 行后）

当前（99-110）：
```python
INBOUND_PAYLOAD_MAP: dict[str, type] = {
    InboundMessageType.agent_wake: AgentWakePayload,
    ...
    InboundMessageType.sms_code_generated: SmsCodeGeneratedPayload,
}
```
在 `sms_code_generated` 那行后加：
```python
    InboundMessageType.trust_changed: TrustChangedPayload,
```

---

## 后端文件 2：`backend/agent_core.py`

### 2.1 新增 `set_trust_level` 方法（第 318 行 `set_current_page` 后）

当前（316-318）：
```python
    def set_current_page(self, page: str) -> None:
        self.current_page = page
        logger.info("session=%s current_page set to %s", self.session_id, page)
```
其后新增：
```python

    def set_trust_level(self, level: str) -> None:
        self.trust_level = level
        logger.info("session=%s trust_level → %s", self.session_id, level)
```

### 2.2 【C】`_build_executor_prompt` 加 `trust_level` 形参（191-194）

当前：
```python
def _build_executor_prompt(scene_id: str, current_page: str) -> str:
    base = (_PROMPTS_DIR / SCENE_PROMPTS[scene_id]).read_text(encoding='utf-8')
    env_block = _render_environment_section(scene_id, current_page)
    return _EXECUTOR_PREFIX + base + '\n\n' + env_block
```
改为：
```python
def _build_executor_prompt(scene_id: str, current_page: str, trust_level: str) -> str:
    base = (_PROMPTS_DIR / SCENE_PROMPTS[scene_id]).read_text(encoding='utf-8')
    env_block = _render_environment_section(scene_id, current_page, trust_level)
    return _EXECUTOR_PREFIX + base + '\n\n' + env_block
```

### 2.3 【C】`_render_environment_section` 加 `trust_level` 形参 + 修复 has_navigate（197 行签名 + 226-240 分支）

当前签名（197）：
```python
def _render_environment_section(scene_id: str, current_page: str) -> str:
```
改为：
```python
def _render_environment_section(scene_id: str, current_page: str, trust_level: str) -> str:
```

当前末段分支（226-240）：
```python
    if target and current_page != target_route:
        path = find_path(current_page, target_route)
        if path:
            lines.append('')
            lines.append('导航路径（当前页 → 目标页）：')
            for i, t in enumerate(path, 1):
                lines.append(f'  第{i}跳：{t.user_guidance}（到达 {t.to_route}）')
        else:
            lines.append('')
            scene_tools = SCENE_TOOLS.get(scene_id, [])
            has_navigate = any(getattr(t, 'name', '') == 'cmd_navigate' for t in scene_tools)
            if has_navigate:
                lines.append(f'导航路径：可通过 cmd_navigate 直接跳转到目标页 {target_route}')
            else:
                lines.append('导航路径：当前位置不可达目标页（可能用户在偏远页面）')
```
改为（用**级别过滤后**的真实工具集判定，并在无权限时显式禁止调用）：
```python
    if target and current_page != target_route:
        path = find_path(current_page, target_route)
        if path:
            lines.append('')
            lines.append('导航路径（当前页 → 目标页）：')
            for i, t in enumerate(path, 1):
                lines.append(f'  第{i}跳：{t.user_guidance}（到达 {t.to_route}）')
        else:
            lines.append('')
            available = {getattr(t, 'name', '') for t in get_scene_tools(scene_id, trust_level)}
            if 'cmd_navigate' in available:
                lines.append(f'导航路径：可通过 cmd_navigate 直接跳转到目标页 {target_route}')
            else:
                lines.append(
                    f'导航路径：你当前是引导级、没有跳页权限。'
                    f'【重要】禁止调用 cmd_navigate（你没有这个工具）。'
                    f'请用 cmd_say 引导用户自己打开「{target.title}」。'
                )
```
> 说明：`get_scene_tools` 定义在第 66 行，早于本函数，可直接调用。`path` 分支（有确定性路径）走 `user_guidance` 口头引导，不依赖 cmd_navigate，guide 级也安全，无需改。

### 2.4 【C】execute_task 调用处传 trust（386 行）

当前（385-388）：
```python
        if scene_id in SCENE_PROMPTS:
            instructions = _build_executor_prompt(scene_id, self.current_page)
        else:
            instructions = _load_scene_prompt(scene_id)
```
第 386 行改为：
```python
            instructions = _build_executor_prompt(scene_id, self.current_page, self.trust_level)
```

---

## 后端文件 3：`backend/ws_handler.py`

### 3.1 dispatch map 注册 handler（第 107 行后）

当前（97-108）：
```python
            handler = {
                InboundMessageType.agent_wake: self._on_agent_wake,
                ...
                InboundMessageType.sms_code_generated: self._on_sms_code_generated,
            }.get(msg_type)
```
在 `sms_code_generated` 那行后加：
```python
                InboundMessageType.trust_changed: self._on_trust_changed,
```

### 3.2 新增 handler 方法（第 153 行 `_on_sms_code_generated` 后）

当前（150-153）：
```python
    async def _on_sms_code_generated(self, payload):
        logger.info("session=%s sms_code_generated received", self.session_id)
        if self._agent_core:
            self._agent_core.set_sms_code(payload.code)
```
其后新增：
```python

    async def _on_trust_changed(self, payload):
        logger.info("session=%s trust_changed → %s", self.session_id, payload.trust_level)
        if self._agent_core:
            self._agent_core.set_trust_level(payload.trust_level)
```

---

# 前端改动

## 前端文件 1：`app/lib/services/agent_session.dart`

### F1.1【A-4】新增 `sendTrustChanged` 方法（第 282 行 `sendSmsCode` 后）

当前（276-282）：
```dart
  void sendSmsCode(String code) {
    if (!isActive) return;
    WsClient.instance.send('sms_code_generated', {
      'session_id': _sessionId,
      'code': code,
    });
  }
```
其后新增：
```dart

  void sendTrustChanged(String level) {
    if (!isActive) return;
    WsClient.instance.send('trust_changed', {
      'session_id': _sessionId,
      'trust_level': level,
    });
  }
```

### F1.2【A-5】ensureSession 复用分支同步 trust（138-142）

当前：
```dart
  Future<void> ensureSession({required String trustLevel}) async {
    if (isActive) {
      debugPrint('[AgentSession] reuse session=$_sessionId');
      _uiSignal.add(null);
      return;
    }
```
改为（复用已有 session 时，把当前 trust 同步给后端，覆盖"面板关闭期间改了 trust 再重开"的场景）：
```dart
  Future<void> ensureSession({required String trustLevel}) async {
    if (isActive) {
      debugPrint('[AgentSession] reuse session=$_sessionId');
      sendTrustChanged(trustLevel);
      _uiSignal.add(null);
      return;
    }
```

---

## 前端文件 2：`app/lib/pages/elder_home.dart`

### F2.1【A-5】import AgentSession（第 13 行后）

当前 import 段含（13）`import '../services/agent_settings_service.dart';`。在其后加：
```dart
import '../services/agent_session.dart';
```

### F2.2【B】新增 pending 成员（第 34 行 `_tab` 后）

当前（32-34）：
```dart
class _ElderHomeState extends ConsumerState<ElderHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);
```
其后加成员：
```dart
  bool _trustChoicePending = false;
```

### F2.3【B】build() 顶部加登录态监听 + pending 消费（第 88 行 `return Scaffold` 前）

当前（86-88）：
```dart
  @override
  Widget build(BuildContext context) {
    return Scaffold(
```
改为：
```dart
  @override
  Widget build(BuildContext context) {
    ref.listen<LoginState>(loginProvider, (prev, next) {
      if (next.isLoggedIn && !(prev?.isLoggedIn ?? false)) {
        _trustChoicePending = true;
      }
    });
    if (_trustChoicePending && (ModalRoute.of(context)?.isCurrent ?? false)) {
      _trustChoicePending = false;
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowFirstTrustChoice());
    }
    return Scaffold(
```
> 原理：login() 翻转 loginProvider 时，栈底存活的 ElderHome 的 listener 触发置 pending（此刻 verify/face 页在栈顶，先不弹）；`router.go(/elder)` 弹回后 ElderHome 重新 current 并 rebuild → 满足 isCurrent → 弹卡。`initState`(39) 老路径保留，覆盖"已登录态直接进首页"。`LoginState`/`loginProvider` 已由 `import '../core/state/app_state.dart'`(第 4 行) 提供，无需新 import。

### F2.4【A-5】选完 trust 后通知后端（第 60 行后）

当前（59-67）：
```dart
    if (picked != null && mounted) {
      AgentSettingsService.instance.trustLevel = picked;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已设为「${_trustTitleFor(picked)}」'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
```
在 `AgentSettingsService.instance.trustLevel = picked;`（第 60 行）后加：
```dart
      AgentSession.instance.sendTrustChanged(picked);
```

---

## 前端文件 3：`app/lib/pages/agent_settings_page.dart`

### F3.1【A-5】import AgentSession（第 6 行后）

当前 import 段含（6）`import '../services/agent_settings_service.dart';`。在其后加：
```dart
import '../services/agent_session.dart';
```

### F3.2【A-5】设置页改 trust 后通知后端（第 43 行后）

当前（42-50）：
```dart
  void _applyTrust(String level, String title) {
    setState(() => _svc.trustLevel = level);
    ScaffoldMessenger.of(context).showSnackBar(
```
在 `setState(() => _svc.trustLevel = level);`（第 43 行）后加：
```dart
    AgentSession.instance.sendTrustChanged(level);
```

---

# 验证步骤

> 后端：`./bin`... 无关，用项目既有方式起 `backend`；前端 `./bin/flutter run`（localhost）。

### 用例 1：登录后弹信任卡 + trust 升级（A + B 核心）
1. 登出态进长辈版首页，**不要**先选信任级别。
2. 打开小浙聊天窗（此时后端 `agent_wake trust=guide`）。
3. 通过聊天走验证码登录（或刷脸）至成功，自动 `go(/elder)`。
4. **预期**：回到首页后**弹出信任选择卡**（根因 2 修复）。选「小浙帮我填」(semi) 或「全程代办」(full)。
5. 看后端日志：应出现 `trust_changed → semi/full`（A 生效）。
6. 对小浙说"查一下我的养老金"。
7. **预期**：后端日志 `execute_task scene=pension_query trust=semi/full`（**不再是 guide**），代理成功 `cmd_navigate` 到养老金查询页并高亮"查询"按钮，无 `cmd_navigate not found`、无 400。

### 用例 2：设置页改 trust 实时同步（A-5）
1. 已登录、聊天窗保持打开。
2. 进"小浙设置"页切换信任级别。
3. **预期**：后端日志即时出现 `trust_changed → <新级别>`，无需重开聊天窗。

### 用例 3：面板重开同步（A-5 / ensureSession）
1. 已登录，关闭聊天窗，在设置页改 trust。
2. 重新打开聊天窗。
3. **预期**：后端日志出现 `trust_changed → <当前级别>`（reuse 分支补发）。

### 用例 4：guide 级优雅降级（C）
1. 登录后在信任卡选「我自己做，小浙提醒我」(guide)。
2. 对小浙说"查养老金"。
3. **预期**：代理**不**调用 cmd_navigate（无 `not found`、无 400），改用 cmd_say 口头引导用户自己打开页面（养老金页"首页无入口"属已知产品限制，guide 级本就无法代跳，能优雅引导即达标）。

### 回归
- 已登录用户冷启动直接进首页（initState 路径）→ 信任卡仍能弹（用例 1 的老路径不被 B 破坏）。
- 医保缴费 / 验证码登录等其他场景在 semi/full 下行为不变。
