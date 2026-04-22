# Agent WebSocket 消息 Schema

> 主笔：backend
> 日期：2026-04-18 v1.1（architect review 有条件通过）
> **权威依据**：PRD v2.0 §六/§七/§八 + AGENT_UI_SPEC v1.1 + 现有 `backend/app/schemas.py`
> architect review 通过后为前后端联调唯一协议依据。

---

## 零、设计原则

1. **信封统一**：所有消息共享 `{type, session_id, ts}` 三字段信封。
2. **单向职责**：客户端（Flutter）只发用户行为；服务端只发代理状态。
3. **TTS 策略**：服务端发文字，**前端自行合成语音**（Web Speech Synthesis API）。`tts_audio_b64` 字段保留为可选，供后续 Baidu TTS 升级；Phase 3 前端忽略此字段即可。
4. **错误不静默**：所有 AE 异常必须发显式消息，禁止无声降级。
5. **schema 与代码同源**：`backend/app/schemas.py` 是此文档的 Python 实现；两者如有冲突以本文档为准，后端代码跟进（变更项见 §七）。

---

## 一、连接与握手

### 1.1 URL 格式

```
ws://<host>:<port>/ws/<session_id>
```

| 参数 | 说明 |
|---|---|
| `host` | 开发阶段固定 `localhost` |
| `port` | 固定 `8000`（FastAPI 默认）|
| `session_id` | 前端生成的 UUID v4 字符串（每次打开代理新建，刷新页面重置）|

**完整示例**：`ws://localhost:8000/ws/550e8400-e29b-41d4-a716-446655440000`

> **I3**：实际 URL 由前端通过 `--dart-define=WS_BASE_URL=ws://localhost:8000` 注入（D2 决策，详见 TECH_STACK_REVIEW §B.1）。上方示例仅作参考，不硬编码在源码中。

### 1.2 握手流程

```
Frontend                          Backend
   │                                │
   ├──── TCP + WS Upgrade ─────────→│
   │                                │
   │←─── session_control            │
   │     action: "session_created"  │  ← 连接成功标志，含服务端分配的 server_session_id
   │                                │
   │  （正常业务消息交换）              │
   │                                │
   ├──── session_control ──────────→│  heartbeat，每 30 秒发一次
   │←─── session_control            │  heartbeat_ack
```

**前端应处理**：
- 若 3 次 heartbeat 无响应，前端展示"连接已断开"提示并触发重连。
- 重连时使用同一 `session_id`，并发送 `session_control {action: "resume", last_ts: <上次收到消息的时间戳>}`，后端恢复上下文（已实现，见 `ws_handler.py`）。

### 1.3 鉴权

当前阶段（毕设 demo）：**无鉴权**。若后续接入真实用户身份，在 URL 追加 `?token=<jwt>` 参数。

### 1.4 重连策略（前端指引）

```
初次连接失败 → 立即重试 1 次
首次重试失败 → 等 2s 重试
再次失败     → 等 4s 重试（指数退避，最长 30s 上限）
重试期间前端 AgentProgressIndicator 显示"网络不稳，正在重连..."
连接恢复后   → 发 resume 消息，恢复 agentStateProvider 至 listening/proposing 态（视上一个有效消息而定）
```

---

## 二、消息信封

所有消息（双向）均为 **UTF-8 编码 JSON 文本帧**，结构如下：

```json
{
  "type": "<消息类型>",
  "session_id": "<UUID string>",
  "ts": "<ISO 8601 UTC 时间戳，如 2026-04-18T12:34:56.789Z>",
  ... // 具体消息的 payload 字段
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `type` | `string` | ✓ | 消息类型标识，见 §三 枚举表 |
| `session_id` | `string (UUID)` | ✓ | 会话 ID，前端生成并在整个会话中保持一致 |
| `ts` | `string (ISO8601 UTC)` | ✓ | 消息生成时间戳（客户端用本地时间，服务端用 UTC）|

> **注**：前端发送时 `ts` 填客户端本地 UTC 时间（`DateTime.now().toUtc().toIso8601String()`）。

---

## 三、消息类型枚举表

### 3.1 客户端 → 服务端（4 种）

#### C1 `user_utterance` — 用户语音输入（文字形式）

用户通过 STT 说话后，前端将识别到的文字发给后端。**这是代理的主要输入通道**。

```json
{
  "type": "user_utterance",
  "session_id": "550e8400-e29b-41d4-a716-446655440000",
  "ts": "2026-04-18T12:34:56.789Z",
  "text": "帮我查一下养老金",
  "source": "voice"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `text` | `string` | ✓ | STT 识别结果（最终文字，非中间结果）|
| `source` | `"voice" \| "text"` | ✓ | `voice`=语音输入；`text`=键盘输入（fallback 输入框）|

**前端应这样处理**：STT 识别到 `SttFinal` 事件后立即发此消息；中间结果（`SttPartial`）不发送，只更新 UI2 语音条实时文字显示。

**与中断逻辑的关系**：若用户在 `proposing` 阶段说"停""不办了"，前端 STT 识别到这些关键词后**不发** `user_utterance`，而是发 `user_action {action: "abort"}`（见 C3）。

#### C2 `voice_input` — 用户音频流（原始 PCM，可选）

> **当前阶段（Phase 3）前端不发此类型**。前端使用 Web Speech API 在浏览器内完成 STT，只发 C1 文字结果。此类型保留供 Phase 4 切 Baidu STT（服务端 STT）时使用。

```json
{
  "type": "voice_input",
  "session_id": "...",
  "ts": "...",
  "audio_b64": "<base64 encoded PCM data>",
  "format": "pcm",
  "sample_rate": 16000,
  "is_final": false
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `audio_b64` | `string (base64)` | ✓ | 音频数据，Base64 编码 |
| `format` | `"pcm" \| "wav"` | ✓ | 音频格式，Phase 4 用 PCM |
| `sample_rate` | `integer` | ✓ | 采样率，固定 16000 Hz |
| `is_final` | `boolean` | ✓ | `false`=中间帧；`true`=最后一帧（用户停止说话）|

#### C3 `user_action` — 用户对意图确认卡的应答

用户在 `IntentProposalCard` 上点击"确认"/"重说"，或点 StopButton，或语音说"停"，均通过此消息传达。

```json
{
  "type": "user_action",
  "session_id": "...",
  "ts": "...",
  "action": "authorize",
  "proposal_id": "7f3a9c21-1234-5678-abcd-ef0123456789"
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `action` | `"authorize" \| "deny" \| "abort"` | ✓ | 见下表 |
| `proposal_id` | `string (UUID) \| null` | 条件必填 | `authorize`/`deny` 时必填（来自服务端 `intent_proposal.proposal_id`）；`abort` 时可为 `null` |

| `action` 值 | 触发条件 | 代理语义 | 对应 PRD |
|---|---|---|---|
| `authorize` | 用户点"确认"或语音说"对/好的/行" | 同意执行意图 | §六.4 确认阶段 |
| `deny` | 用户点"重说"或语音说"不对/不对/重说" | 拒绝当前意图，重新收音 | §六.4 确认阶段 / AE2 |
| `abort` | 用户点 StopButton 或语音说"停/停下/不办了/取消" | 立即中断代理，归 idle | §六.7.1 三种中断 |

**前端应这样处理**：
- `authorize` → 前端**仅发送此消息，不切态**；等收到服务端 S3 `intent_execute` 后再切 `proposing → executing`（见 S3 说明）；> **I2**：禁止在此处乐观预判切态，双重触发会导致 AgentProgressIndicator 提前入场。
- `deny` → 前端切 `proposing → listening`，AgentProgressIndicator 不出现；
- `abort` → 前端立即切 `任意→idle`，隐藏所有 Agent UI 层（不等服务端确认，乐观 UI；abort 是用户主动叫停，无需等服务端 ack）。

#### C4 `session_control` — 会话控制（心跳 / 恢复）

```json
{
  "type": "session_control",
  "session_id": "...",
  "ts": "...",
  "action": "heartbeat",
  "last_ts": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `action` | `"heartbeat" \| "resume"` | ✓ | `heartbeat`=保活；`resume`=断线重连后恢复 |
| `last_ts` | `string (ISO8601) \| null` | 条件必填 | `resume` 时必填，填写前端上次收到服务端消息的 ts |

---

### 3.2 服务端 → 客户端（8 种）

#### S1 `agent_utterance` — 代理语音回复

代理在预告/确认/执行完成/异常安抚阶段通过此消息发送文字，前端渲染到 AgentSpeechBubble 并触发 TTS 播报。

```json
{
  "type": "agent_utterance",
  "session_id": "...",
  "ts": "...",
  "text": "好的，您是要查医保缴费记录，对吗？",
  "tts_audio_b64": null,
  "is_partial": false
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `text` | `string` | ✓ | 代理说的话（严格按 PRD §六.9 对话风格；前端直接显示在 AgentSpeechBubble）|
| `tts_audio_b64` | `string (base64) \| null` | 否 | Phase 3 始终为 `null`；Phase 4 Baidu TTS 时填 MP3/WAV |
| `is_partial` | `boolean` | ✓ | `false`=完整句子；`true`=流式片段（当前后端不使用，保留扩展）|

**前端应这样处理**：
- `is_partial=false`：替换 AgentSpeechBubble 全部文字，触发打字机动效（30ms/字），同时调 `ttsService.speak(text)`；
- `is_partial=true`：追加到 AgentSpeechBubble 末尾（不触发 TTS，等 `is_partial=false` 时一次播报）。

#### S2 `intent_proposal` — 意图识别结果（IntentProposalCard 数据）

代理理解意图后，先发 S1 预告文字，随即发此消息驱动 IntentProposalCard 弹出。

```json
{
  "type": "intent_proposal",
  "session_id": "...",
  "ts": "...",
  "proposal_id": "7f3a9c21-1234-5678-abcd-ef0123456789",
  "description": "帮您打开养老金查询页面",
  "intent": {
    "action": "NavigateTo",
    "path": "/service/pension-query",
    "extra": {}
  },
  "requires_auth": true,
  "timeout_sec": 5
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `proposal_id` | `string (UUID)` | ✓ | 前端在 `user_action` 中原样回传 |
| `description` | `string` | ✓ | 意图的用户友好描述，**直接渲染到 IntentProposalCard 复述文字**（§六.9 口语化，如"帮您打开养老金查询页面"，不用"NavigateTo"）|
| `intent.action` | `string` | ✓ | 意图类型，见下表 |
| `intent.path` | `string \| null` | 条件必填 | `NavigateTo` 时必填（go_router 路径，如 `/service/pension-query`）|
| `intent.extra` | `object` | ✓ | 额外参数（表单填写时含字段名/值；默认空对象）|
| `requires_auth` | `boolean` | ✓ | `true`=显示确认卡；`false`=代理直接执行（当前实现始终为 `true`）|
| `timeout_sec` | `integer` | ✓ | **确认等待时间（秒）**，前端 IntentProposalCard 倒计时依据；**必须为 5**（见 §七 待变更 #3）|

**`intent.action` 取值枚举**：

| 值 | 含义 | 相关 `intent.extra` 字段 |
|---|---|---|
| `NavigateTo` | 跳转至指定路由页面 | 无 |
| `SwitchMode` | 切换标准版/长辈版 | `mode: "elder" \| "standard"` |
| `FillFormField` | 填写表单字段（L2/L3 权限）；**仅在当前页为 VerifyPage 时由后端发出**（场景 C B-半主动触发，D1 豁免，见 §七 #5）| `field_name: string, value: string, field_label: string` |
| `ExplainTerm` | 解释词汇（不跳页，纯语音/文字回复）| 无（回复走 S1 `agent_utterance` 而非此消息）|

**前端应这样处理**：
- 收到此消息 → 前端切 `listening → proposing`，弹出 IntentProposalCard；
- 倒计时从 `timeout_sec`（即 5）开始倒数，归零时触发 AE3 流程（前端自行处理，切换卡片内容为"还在吗"）；
- 用户点"确认" → 发 C3 `user_action {action: "authorize", proposal_id}`；
- 用户点"重说" → 发 C3 `user_action {action: "deny", proposal_id}`。

#### S3 `intent_execute` — 代理开始执行通知

服务端收到 `user_action {action: "authorize"}` 后立即发此消息，告知前端代理已进入执行阶段。

```json
{
  "type": "intent_execute",
  "session_id": "...",
  "ts": "...",
  "proposal_id": "7f3a9c21-1234-5678-abcd-ef0123456789",
  "intent": {
    "action": "NavigateTo",
    "path": "/service/pension-query",
    "extra": {}
  }
}
```

**前端应这样处理**：
- 收到此消息 → 前端切 `proposing → executing`，显示 AgentProgressIndicator；
- **同时在前端本地执行意图**（如 `context.go(intent.path)`），不等服务端二次通知；
- 意图执行结果（页面是否成功打开）由前端判断，不依赖服务端。

#### S4 `progress_update` — 执行进度事件

代理执行多步骤任务（如填写表单、多跳页面）时，逐步推送进度文字，驱动 AgentProgressIndicator 内容更新。

```json
{
  "type": "progress_update",
  "session_id": "...",
  "ts": "...",
  "text": "正在打开养老金查询页面...",
  "stage": "executing",
  "done": false
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `text` | `string` | ✓ | 进度描述文字，直接渲染到 AgentProgressIndicator（口语化，如"正在帮您找养老金"，非"NavigateTo executed"）|
| `stage` | `"executing" \| "done" \| "error"` | ✓ | 阶段标识 |
| `done` | `boolean` | ✓ | `true`=此条是最终进度消息（完成或出错）|

> **I1**：原 `error_message` 字段已移除。`stage="error"` 时 S4 只负责驱动 AgentProgressIndicator 退场；错误文案**统一由 S6 `agent_error.display_text` 承载**，避免 AgentSpeechBubble 因两条消息先后到达而闪烁。

**前端应这样处理**：
- `stage="executing", done=false`：更新 AgentProgressIndicator 文字（淡出旧→淡入新）；
- `stage="done", done=true`：ProgressIndicator 切绿色 ✓ + "完成"，保持 800ms 后退场；
- `stage="error", done=true`：AgentProgressIndicator 直接退场（**不更新 SpeechBubble**）；等待随后到达的 S6 `agent_error` 更新 SpeechBubble 错误文案 + TTS 播报。

#### S5 `intent_result` — 执行完成事件

意图执行完成（成功或失败），发送最终结果，驱动 AgentSpeechBubble 更新结果播报。

```json
{
  "type": "intent_result",
  "session_id": "...",
  "ts": "...",
  "proposal_id": "7f3a9c21-1234-5678-abcd-ef0123456789",
  "success": true,
  "summary": "已打开养老金查询页面，您可以看到三张险种卡片",
  "undo_available": false,
  "undo_expires_at": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `proposal_id` | `string (UUID)` | ✓ | 对应 `intent_proposal.proposal_id` |
| `success` | `boolean` | ✓ | 执行成功/失败 |
| `summary` | `string` | ✓ | 结果说明（口语化），渲染到 AgentSpeechBubble 并触发 TTS |
| `undo_available` | `boolean` | ✓ | 此操作是否可撤销（F6 操作记录，当前始终 `false`，F6 激活时启用）|
| `undo_expires_at` | `string (ISO8601) \| null` | 否 | 撤销过期时间（`undo_available=true` 时填）|

**前端应这样处理**：
- `success=true` → 前端切 `executing → done`，AgentSpeechBubble 更新 summary 文字 + TTS 播报；
- `success=false` → 见 S6 `agent_error`（后端 `success=false` 与 AE 同步发）；
- `done` 态在 3 秒后前端自动切回 `idle`。

#### S6 `agent_error` — 异常事件（AE1-AE5）

> **此消息类型在现有 `schemas.py` 中尚未定义**（见 §七 待变更 #1）。

```json
{
  "type": "agent_error",
  "session_id": "...",
  "ts": "...",
  "error_code": "AE1",
  "display_text": "没听清，请再说一遍",
  "options": [
    { "label": "重说", "value": "retry" },
    { "label": "取消", "value": "cancel" }
  ],
  "proposal_id": null
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `error_code` | `string` | ✓ | AE1-AE5，见 §五 错误码表 |
| `display_text` | `string` | ✓ | 用户友好说明（§六.9 口语化），渲染到 AgentSpeechBubble + TTS 播报 |
| `options` | `array` | ✓ | 用户可选操作列表（空数组=无选项）；前端渲染为按钮，用户点击后发 C3 `user_action` |
| `proposal_id` | `string \| null` | 否 | AE2（意图偏差）时填，其余为 `null` |

**前端应这样处理**：
- 收到此消息 → 前端更新 AgentSpeechBubble 显示 `display_text` + TTS；
- `options` 非空时，在 AgentSpeechBubble 下方渲染操作按钮（"重说" / "取消" 等）；
- 按钮点击映射：`"retry"` → 发 `user_action {action: "deny"}`；`"cancel"` → 发 `user_action {action: "abort"}`。

#### S7 `clarification_request` — 澄清请求

代理无法判断用户意图时，主动请求澄清（AE2 意图偏差的另一分支：代理有多个候选意图时供用户选择）。

```json
{
  "type": "clarification_request",
  "session_id": "...",
  "ts": "...",
  "text": "您是想查养老金余额，还是查缴费记录？",
  "options": [
    { "label": "查余额", "value": "pension_balance" },
    { "label": "查缴费记录", "value": "pension_history" }
  ]
}
```

| 字段 | 类型 | 必填 | 说明 |
|---|---|---|---|
| `text` | `string` | ✓ | 澄清问题文字（渲染到 AgentSpeechBubble + TTS）|
| `options` | `array` | ✓ | 候选选项（空数组=让用户重说）；非空时前端渲染选项按钮 |

**前端应这样处理**：
- `options` 非空 → 在 AgentSpeechBubble 下方渲染快捷选项按钮；用户点击后将 `value` 包装为新的 `user_utterance` 发送（即 `text=options[i].value`，`source="text"`）；
- `options` 为空 → 前端切回 `listening` 态，等待用户重新说话。

#### S8 `session_control` — 会话生命周期控制

```json
{
  "type": "session_control",
  "session_id": "...",
  "ts": "...",
  "action": "heartbeat_ack",
  "payload": {}
}
```

| `action` 值 | 触发时机 | `payload` 内容 |
|---|---|---|
| `session_created` | 连接建立后立即发 | `{"server_session_id": "<UUID>"}` |
| `heartbeat_ack` | 响应客户端 heartbeat | `{}` |
| `session_expired` | 会话 30 分钟无消息自动过期 | `{"reason": "timeout"}` |
| `rate_limited` | 请求过于频繁 | `{"retry_after_sec": 5}` |

**前端应这样处理**：
- `session_created`：保存 `server_session_id` 备查；切到 `idle` 态；
- `session_expired`：前端重新建立连接（新 UUID session_id）；
- `rate_limited`：延迟 `retry_after_sec` 秒后重发被限流的消息。

---

## 四、状态转换图

对应 AGENT_UI_SPEC §五 组件交互关系图 + PRD §六.4 三阶段 + AE1-AE5。

```
                         ┌──────────────────────────────────────────────┐
                         ▼                                              │
               ┌─────────────────┐                                      │
         ┌────→│   idle          │←────────────────────────────────┐    │
         │     └────────┬────────┘                                 │    │
         │              │ 用户点助手按钮                             │    │
         │              │（前端本地切态，不发消息）                  │    │
         │              ▼                                          │    │
         │     ┌─────────────────┐                                 │    │
 abort   │     │  listening      │ ←─── S7 clarification_request   │    │
(C3)     │     └────────┬────────┘      (options=[])               │    │
         │              │ STT 收到最终文字                          │    │
         │              │ → 发 C1 user_utterance                    │    │
         │              ▼                                          │    │
         │     ┌─────────────────┐   S6 agent_error(AE1)          │    │
         │     │  (backend处理)  │ ────────────────────────────→   │    │
         │     │  等待服务端响应  │   AgentSpeechBubble "没听清"    │    │
         │     └────────┬────────┘   → 前端切回 listening          │    │
         │              │                                          │    │
         │      ┌───────┴──────────┐                              │    │
         │      │                  │                              │    │
         │      ▼                  ▼                              │    │
         │  S1(预告) +         S6 AE1/AE2                         │    │
         │  S2 intent_proposal    → listening                     │    │
         │      │                                                 │    │
         │      ▼                                                 │    │
         │     ┌─────────────────┐                                │    │
         │     │  proposing      │ ─── 倒计时耗尽(AE3) ───────────│────┘
 abort   │     └────────┬────────┘      前端处理(换卡内容)         │
(C3)     │              │                                          │
         │      ┌───────┴────────────┐                            │
         │      │                    │                            │
         │      ▼                    ▼                            │
         │  C3(authorize)        C3(deny)                         │
         │  ↓ 发消息，等服务端     → listening                    │
         │  ↓ 不切态（I2）                                        │
         │  S3 intent_execute                                      │
         │  ↓ 收到后才切态                                        │
         │      ▼                                                 │
         │     ┌─────────────────┐                                │
 abort   │     │  executing      │ ─── S6 AE4/AE5 ──────────────→│
(C3)     │     └────────┬────────┘                                │
         │              │ S4(done) + S5(success)                  │
         │              ▼                                         │
         │     ┌─────────────────┐                                │
         └─────│  done           │ ──── 3秒后自动 ───────────────→│
               └─────────────────┘                                │
                                                                  ▼
                                                              idle
```

**前端 AgentPhase 状态枚举（对应 AGENT_UI_SPEC §七）**：

| `AgentPhase` | 触发条件 | 显示的 Agent UI 层 |
|---|---|---|
| `idle` | 初始态 / abort / 30s 超时 / done 后3秒 | 无（全隐藏）|
| `listening` | 用户唤醒 / deny / AE1重试 | AgentSpeechBubble（"我在，请说"）+ StopButton |
| `proposing` | 收到 S2 `intent_proposal` | AgentSpeechBubble + IntentProposalCard + StopButton |
| `executing` | 收到 S3 `intent_execute` | AgentSpeechBubble + AgentProgressIndicator + StopButton |
| `done` | 收到 S5 `intent_result {success:true}` | AgentSpeechBubble（结果）|

---

## 五、错误码表

对应 PRD §八 AE1-AE5 异常处理框架。

| 错误码 | 异常类型 | 触发条件 | 服务端发送的消息 | `display_text` 示例 | 前端 AgentPhase |
|---|---|---|---|---|---|
| `AE1` | 未听清指令 | STT 置信度低 / 空字符串 | `agent_error` | "没听清，请再说一遍" | `→ listening` |
| `AE2` | 意图识别错误 | LLM 返回意图用户纠正（deny）后仍错 | `agent_error` 或 `clarification_request` | "好的，我重新理解。您是想查…" | `→ listening` |
| `AE3` | 确认超时 | 用户在 `proposing` 阶段 5 秒无响应 | **前端本地处理**，无服务端消息（卡片内容更新为"还在吗"）；30秒后前端发 `user_action {action: "abort"}` | — | `proposing`（前端 AnimatedSwitcher） |
| `AE4` | 网络异常 | WebSocket 断开 / 发送超时 | WebSocket 连接断开（无消息），前端感知 | 前端本地显示："网络不太稳，正在重试" | `→ idle` 后重连 |
| `AE5` | 执行失败 | 代理操作失败（路由不存在/刷脸失败/页面改版）| `progress_update {stage:"error"}` 驱动 ProgressIndicator 退场 + `agent_error {error_code:"AE5"}` 承载错误文案（两条消息顺序发送，I1）| "没成功，可能页面换地方了。需要我帮您找别的方式吗？" | `→ idle` |

**AE3 完整流程说明（前端自洽，无需服务端消息）**：
```
proposing 阶段 → 倒计时 5 秒归零
  → AnimatedSwitcher 更新卡片内容："还在吗？需要我继续吗？"
  → 重置倒计时（再给 25 秒）
  → 用户点"继续" → 重启 5 秒倒计时，回到等待态
  → 用户点"结束" → 发 C3 {action: "abort"}
  → 30 秒总超时 → 发 C3 {action: "abort"}
```

---

## 六、典型会话流程示例

### 示例 A：场景 B 成功 — 语音查养老金

```
前端                                    后端
 │                                       │
 │  ← S8 session_control(session_created)│  连接建立
 │                                       │
 │  [用户点助手按钮]                      │
 │  Phase: idle → listening              │
 │                                       │
 │  [STT 返回 "帮我查一下养老金"]         │
 │  C1 user_utterance("帮我查一下养老金") │
 │ ─────────────────────────────────────→│
 │                                       │  dispatch → LLM → NavigateTo intent
 │  ← S1 agent_utterance                 │
 │    text: "好的，您是要查养老金到账记录，对吗？"
 │  Phase: listening（气泡更新）          │
 │                                       │
 │  ← S2 intent_proposal                 │
 │    proposal_id: "abc-123"             │
 │    description: "帮您打开养老金查询页面"│
 │    intent: {action: "NavigateTo",     │
 │             path: "/service/pension-query"}
 │    timeout_sec: 5                     │
 │  Phase: listening → proposing         │
 │  IntentProposalCard 弹出，倒计时 5s   │
 │                                       │
 │  [用户点"确认，帮我做"]               │
 │  C3 user_action(authorize, "abc-123") │
 │ ─────────────────────────────────────→│
 │                                       │
 │  ← S3 intent_execute                  │
 │    proposal_id: "abc-123"             │
 │    intent: {NavigateTo, /service/pension-query}
 │  Phase: proposing → executing         │
 │  前端执行: context.go("/service/pension-query")
 │  AgentProgressIndicator 显示          │
 │                                       │
 │  ← S4 progress_update                 │
 │    text: "正在打开养老金查询页面..."   │
 │    stage: "executing", done: false    │
 │                                       │
 │  ← S4 progress_update                 │
 │    text: "已打开"                     │
 │    stage: "done", done: true          │
 │  ProgressIndicator 绿色 ✓ → 退场      │
 │                                       │
 │  ← S5 intent_result                   │
 │    success: true                      │
 │    summary: "这是您的养老金查询页面，您可以看到三张险种卡片"
 │  Phase: executing → done              │
 │  AgentSpeechBubble 更新 + TTS 播报    │
 │  3 秒后 Phase: done → idle            │
```

---

### 示例 B：场景 C 成功 — 验证码自动填写

```
前端                                    后端
 │                                       │
 │  [VerifyPage 出现]                     │
 │  前端发 C1 {text:"__system_otp__",    │  触发方式（B-半主动，D1 豁免，
 │            source:"text"}             │  详见 PRD §九 场景 C 豁免）：
 │  Phase: idle → listening              │  仅限当前页为 VerifyPage 时触发；
 │ ─────────────────────────────────────→│  前端检测页面进入后自动发此 magic 消息
 │  ← S1 agent_utterance                 │
 │    text: "您收到一条验证码，需要我帮您填上去吗？"
 │                                       │
 │  ← S2 intent_proposal                 │
 │    description: "帮您填写验证码 123456"│
 │    intent: {action: "FillFormField",  │
 │     extra: {field_name: "otp",        │
 │             value: "123456",          │
 │             field_label: "验证码输入框"}}
 │    requires_auth: true, timeout_sec: 5│
 │  IntentProposalCard 弹出              │
 │                                       │
 │  [用户点"帮填"]（= 确认）             │
 │  C3 user_action(authorize, proposal_id)│
 │ ─────────────────────────────────────→│
 │                                       │
 │  ← S3 intent_execute                  │
 │  前端执行: 逐位填入 OTP 输入框         │
 │  （动画：每位 300ms 间隔）             │
 │                                       │
 │  ← S5 intent_result                   │
 │    success: true                      │
 │    summary: "填好了，您确认一下对不对" │
 │  AgentSpeechBubble 更新 + TTS         │
 │  高亮 OTP 输入框（UI4 效果）          │
 │                                       │
 │  [用户自行点"登录"按钮]               │
 │  （代理不自动提交，L2 权限边界）       │
```

---

### 示例 C：场景 B with AE2 — 识别错误分支

```
前端                                    后端
 │                                       │
 │  [用户说"帮我交一下东西"]（语义模糊） │
 │  C1 user_utterance("帮我交一下东西")  │
 │ ─────────────────────────────────────→│
 │                                       │  LLM 推测为医保缴费
 │  ← S1 agent_utterance                 │
 │    text: "好的，您是要查医保缴费记录，对吗？"
 │                                       │
 │  ← S2 intent_proposal                 │
 │    description: "帮您打开社保缴费页面" │
 │  IntentProposalCard 弹出              │
 │                                       │
 │  [用户点"重说"（识别错误）]           │
 │  C3 user_action(deny, proposal_id)    │
 │ ─────────────────────────────────────→│
 │  Phase: proposing → listening         │
 │                                       │  后端处理 deny，重新等待
 │  ← S6 agent_error                     │
 │    error_code: "AE2"                  │
 │    display_text: "好的，我重新听。您说的是要帮您做什么？"
 │    options: []                        │
 │  AgentSpeechBubble 更新 + TTS         │
 │  Phase: listening（等待重说）          │
 │                                       │
 │  [用户重说 "帮我查医保交了没有"]       │
 │  C1 user_utterance("帮我查医保交了没有")│
 │ ─────────────────────────────────────→│
 │                                       │  正确识别为社保缴费查询
 │  ← S1 + S2（正确意图）                │
 │  （后续同示例 A 成功流程）             │
```

---

## 七、待变更项（后端代码与此 schema 的差距）

> 本节列出 `backend/app/` 当前代码与本文档 schema 的所有不一致项。团队确认后由 backend 跟进修改，frontend **不依赖这些未实现项**开始联调（frontend 可先 mock 服务端消息）。

| # | 位置 | 当前状态 | 应改为 | 优先级 |
|---|---|---|---|---|
| **#1** | `schemas.py` | 无 `agent_error` 类型 | 新增 `AgentError(BaseMsg)` 含 `error_code / display_text / options / proposal_id` 字段 | P0（AE1/AE2/AE5 必须）|
| **#2** | `ws_handler.py` | `UserAction` 消息收到后仅 log "unhandled"，不做任何处理 | 实现 `_handle_user_action()`：`authorize` → 发 S3+S4+S5；`deny` → 发 S6(AE2)；`abort` → 发 S1("已停止") + 中断当前任务 | P0（确认-执行流程核心）|
| **#3** | `ws_handler.py` | `IntentProposal.timeout_sec=30`（硬编码）| 改为 `timeout_sec=5`（与 PRD §六.4 / §八 AE3 一致；AE3 由前端本地计时，30s 是后端连接保活超时，语义不同）| P0 |
| **#4** | `ws_handler.py` | 收到 `user_action {authorize}` 后不发 `intent_execute` / `progress_update` / `intent_result` | 实现完整执行回路：发 S3 → 执行 mock → 发 S4(executing) → 发 S4(done) → 发 S5 | P0 |
| **#5** | `ws_handler.py` | 验证码自动填写（场景 C）触发方式已定（B-半主动 + D1 豁免，详见 PRD §九）：前端检测进入 VerifyPage 后自动发 `user_utterance {text: "__system_otp__", source: "text"}`；后端识别此 magic string → 发 S1 预告 + S2 IntentProposal（FillFormField）。当前 `ws_handler.py` 尚未识别该 magic string | 在 `_handle_user_utterance` 中新增 `__system_otp__` 分支，直接构造 FillFormField IntentProposal 发出 | P1 |
| **#6** | `schemas.py` | `VoiceInput` 定义了但 `ws_handler.py` 中 `parse_inbound` 虽有注册，ws_handler 的 dispatch 逻辑未处理 | Phase 3 前端不发此消息，可先保持不变；Phase 4 接 Baidu STT 时一并处理 | P2 |

---

## 附录：消息类型速查表

| 方向 | type | 编号 | 对应 UI 组件 / PRD |
|---|---|---|---|
| C→S | `user_utterance` | C1 | STT 结果 → 场景 B/C 触发 |
| C→S | `voice_input` | C2 | Phase 4 扩展 |
| C→S | `user_action` | C3 | IntentProposalCard / StopButton / §六.7 中断 |
| C→S | `session_control` | C4 | 连接保活 |
| S→C | `agent_utterance` | S1 | AgentSpeechBubble + TTS / §六.4 预告 |
| S→C | `intent_proposal` | S2 | IntentProposalCard / §六.4 确认 |
| S→C | `intent_execute` | S3 | AgentProgressIndicator 触发 / §六.4 执行 |
| S→C | `progress_update` | S4 | AgentProgressIndicator 文字更新 / UI5 |
| S→C | `intent_result` | S5 | AgentSpeechBubble 结果 / §六.4 执行完成 |
| S→C | `agent_error` | S6 | AgentSpeechBubble / §八 AE1-AE5 |
| S→C | `clarification_request` | S7 | AgentSpeechBubble + 选项按钮 / AE2 多候选 |
| S→C | `session_control` | S8 | 连接生命周期 |

---

## 变更记录

| 日期 | 版本 | 变更人 | 变更摘要 |
|---|---|---|---|
| 2026-04-18 | v1.1 | backend | architect review 有条件通过，3 处文档修订：I1 S4 删 error_message 字段，错误文案统一走 S6 避免 SpeechBubble 闪烁；I2 C3 authorize 去乐观切态，改为等 S3 才切 proposing→executing，状态图箭头同步修正；I3 §一.1 补 --dart-define WS_BASE_URL 注入说明。附：场景 C 触发机制落定（B-半主动，magic string），更新示例 B 注释 + S2 FillFormField 触发条件 + §七 #5 |
| 2026-04-18 | v1.0 | backend | 初稿，基于现有 schemas.py + ws_handler.py + PRD v2.0 + AGENT_UI_SPEC v1.1 |
