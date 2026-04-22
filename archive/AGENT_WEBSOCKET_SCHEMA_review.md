# AGENT_WEBSOCKET_SCHEMA.md v1.0 — Architect Review

> Reviewer：architect
> Date：2026-04-18
> 结论：**⚠️ 有条件通过**
> - P0 必改 4 项（均属后端代码，已在 §七 待变更中登记，本轮仅文档 review）
> - 文档层 2 处需 backend 补充说明（非代码改动）
> - 1 处产品决策需 PM 拍板（场景 C 唤醒机制，涉及 D1 受控响应原则）
> - TECH_STACK_REVIEW.md 需同步 2 处微调（AgentState 补字段 + URL 注入说明）

---

## 一、PRD / SPEC 字段对齐审查

### S2 `intent_proposal` → IntentProposalCard

| SPEC v1.2 字段需求 | Schema 对应字段 | 对齐状态 |
|---|---|---|
| IntentProposalCard 复述文字 | `description`（口语化，直接渲染）| ✓ |
| 用户回传的唯一标识 | `proposal_id`（C3 原样回传）| ✓ |
| IntentProposalCard 倒计时依据 | `timeout_sec`（文档写 5，backend 实际硬编码 30）| ⚠️ 待变更 #3 |
| 是否弹出确认卡 | `requires_auth`（当前始终 true）| ✓ |
| 执行动作类型 | `intent.action`（枚举 4 值）| ✓ |
| 导航路径 | `intent.path`（NavTo 时必填）| ✓ |
| 表单填写参数 | `intent.extra.field_name/value/field_label` | ✓ |

**结论**：字段完整，`description` 直接对应 IntentProposalCard 复述文字无需翻译层。唯一问题是 `timeout_sec` 的实际值（#3，后端代码修）。

---

### S1+S2 倒计时原卡更新（SPEC §二.2.5）

SPEC 要求超时后"原卡 AnimatedSwitcher 内容更新，不 dismiss 后重建"。

Schema §五 AE3 说明：
- 倒计时 5 秒归零 → 前端本地处理（AnimatedSwitcher）
- 无服务端消息介入
- 30 秒总超时后前端发 `user_action {abort}`

**结论**：✓ 完全对齐。AE3 是前端自洽逻辑，schema 不需要 backend 消息，设计正确。

---

### S4 `progress_update` → AgentProgressIndicator

| SPEC 需求 | Schema 字段 | 对齐状态 |
|---|---|---|
| 直接渲染的进度文字 | `text`（口语化，如"正在帮您找养老金"）| ✓ |
| 入场：从顶部滑入 | `stage: "executing"` 首条触发 | ✓ |
| 完成态：绿 ✓ + 800ms 退场 | `stage: "done", done: true` | ✓ |
| 出错态 | `stage: "error", done: true, error_message` | ⚠️ 见下文 I1 |

---

### S6 错误码 → AE1-AE5 精确对齐

| PRD AE 编号 | Schema `error_code` | 触发方式 | 前端 phase 转换 | 对齐状态 |
|---|---|---|---|---|
| AE1（未听清）| `"AE1"` | 服务端发 S6 | → `listening` | ✓ |
| AE2（意图偏差）| `"AE2"` | S6 或 S7 | → `listening` | ✓ |
| AE3（确认超时）| 无 server 消息（前端自洽）| 前端倒计时本地处理 | `proposing` 内部切 | ✓ |
| AE4（网络异常）| WS 连接断开（无消息）| 前端感知断连 | → `idle` 后重连 | ✓ |
| AE5（执行失败）| `"AE5"` | S6 + S4(error) | → `idle` | ✓ |

错误码均为字符串常量（`"AE1"` ~ `"AE5"`），前端 `switch(error_code)` 直接映射，**无需翻译层**。✓

---

### S1-S5 驱动 AgentPhase 5 态完整性验证

| `AgentPhase` | 进入触发 | 退出触发 | 覆盖消息 | 完整性 |
|---|---|---|---|---|
| `idle` | 初始/abort/done+3s/session_expired | 用户激活（本地）| S8 session_created | ✓ |
| `listening` | 用户激活/deny/AE1 | S2 到达 | C1 发出方向 | ✓ |
| `proposing` | S2 `intent_proposal` | S3 到达 / deny / abort | C3 authorize/deny | ✓ |
| `executing` | S3 `intent_execute` | S5 到达 / abort / AE4/5 | S4 进度更新 | ✓（见 I2 状态转换歧义）|
| `done` | S5 `intent_result {success:true}` | 3 秒后自动 → idle | — | ✓ |

5 态完整，与 TECH_STACK_REVIEW.md `AgentPhase` 枚举一致，不需要增删任何状态。

---

## 二、后端自挂 6 问 — 逐条答复

### #1 `agent_error` 未定义（P0，后端代码改）

**结论：文档层 ✓ 设计正确，backend 按 §三 S6 补 `AgentError(BaseMsg)` 即可。**

- `error_code` 用字符串 `"AE1"~"AE5"` ✓（简洁，前端 switch 零翻译）
- `display_text` 口语化直接渲染到 AgentSpeechBubble ✓
- `options` 数组 `{label, value}` 灵活，支持零选项（空数组=无按钮）✓
- `proposal_id` 仅 AE2 需要（回传以关联 deny 的 proposal）✓
- `"retry"` 映射到 C3 `deny`，`"cancel"` 映射到 C3 `abort` ✓

**本轮仅文档 review，`schemas.py` 的 `AgentError` 类增加属于下一轮 backend 派活。**

---

### #2 `UserAction` 收到后仅 log（P0，后端代码改）

**结论：`_handle_user_action()` 的行为规格文档已完整定义，backend 按 schema 实现即可。**

规格补充（文档未说清楚的 `deny` 语义）：

`deny` 后，schema 示例 C 中后端发 `S6 {error_code: "AE2"}`，但 `deny` 是用户主动选择，并非"意图识别出错"。语义上存在轻微歧义。

**建议**：`deny` 后 backend 应发 S1 `agent_utterance`（文字："好的，我重新听，请再说一遍"），而非 S6 AE2；S6 AE2 保留给 LLM 理解错误后后端主动纠错。两者最终效果（切回 listening）相同，但语义更精确，日志更清晰。

若 backend 坚持 deny→S6(AE2) 路径，功能可接受，但建议在文档中区分"用户主动纠错（deny）"与"LLM 识别失败（AE2）"。

**本轮仅文档 review，`ws_handler.py` 实现属下一轮 backend 派活。**

---

### #3 `timeout_sec` 硬编码 30 → 改 5（P0）

**结论：必须改为 5，不接受 30。**

原因：`timeout_sec` 是 IntentProposalCard 倒计时的直接数据源。若 backend 发 `timeout_sec: 30`，前端 IntentProposalCard 显示 30 秒倒计时，与 PRD §六.4 / SPEC §二.5 / §八 AE3 全部冲突。

混淆根源：`ws_handler.py` 把"后端连接保活超时（30s）"与"意图确认倒计时（5s）"混为一个值。两者语义完全不同：

| 超时类型 | 值 | 位置 |
|---|---|---|
| IntentProposalCard 确认倒计时 | **5 秒**（schema `timeout_sec`）| 前端 IntentProposalCard 倒计时 |
| AE3 总超时（还在吗之后）| **30 秒**（前端本地计时，不来自 schema）| 前端 AnimatedSwitcher 内部逻辑 |
| WebSocket 连接保活 | 30 秒 heartbeat | `session_control` 心跳间隔 |

**`timeout_sec: 5` 是文档权威值，backend 代码跟进。本轮仅文档确认。**

---

### #4 执行完整回路未实现（P0）

**结论：是 Phase 3 Demo 核心路径，必须实现。前端可 mock S3/S4/S5 先行联调。**

Frontend 可以在开发阶段用如下 mock 序列自测（`AgentClient` 的 `MockAgentClient` 实现）：
```
收到 authorize → 本地 timer 200ms 后发 S3 → 500ms 后发 S4(executing) → 1000ms 后发 S4(done) → 200ms 后发 S5(success)
```
这样 frontend 无需等待 backend 修复即可验证完整 AgentPhase 状态机。

**本轮仅文档确认，`ws_handler.py` 实现属下一轮 backend 派活。**

---

### #5 场景 C 代理唤醒机制（P1）

**架构意见：backend 推荐的 magic string 方案有设计缺陷，但更深层是产品决策问题，需 PM 确认。**

**问题核心**：场景 C（验证码自动填写）的代理介入方式，与 PRD D1"受控响应"原则存在张力：

| 方案 | 技术可行性 | D1 受控响应合规性 | 复杂度 |
|---|---|---|---|
| **A：用户进入 VerifyPage 后手动唤醒**（与其他场景一致）| ✓ | ✓ 完全合规（用户主动唤醒）| 最低 |
| **B：frontend 自动发 magic string `__system_otp_arrived__`**（backend 推荐）| 技术可行 | ❌ 违反 D1（用户未明确唤醒，代理自动介入）| 中 |
| **C：新增 `system_event` 消息类型**（通用系统事件通道）| 技术可行 | 取决于前端何时触发 | 高（新消息类型）|
| **D：新增 `user_action.action: "system_page_enter"`**（扩展 C3 枚举）| ✓ | 可配置（进入页面=被动触发，PRD 模糊地带）| 低 |

**技术层面结论（architect 可给）**：

magic string 方案（B）**不推荐**。原因：
1. `user_utterance` 是用户语音/文字输入通道，注入系统事件污染语义
2. LLM 收到 `__system_otp_arrived__` 需要特判路径，相当于 hidden intent 不透明
3. 若 LLM prompt 未包含此 magic string 的处理，将触发 AE2 意图识别失败

**产品层面决策（需 PM 给）**：
- 场景 C 的"代理主动提示"是否符合 PRD D1 受控响应？
- PRD §七 场景 C 原文："代理检测到验证码到达"——"检测到"暗示后端推送（主动介入），与 D1 存在矛盾
- 若 PM 确认场景 C 允许主动介入（豁免 D1）：推荐方案 D（扩展 C3 + 进入页面触发）
- 若 PM 要求严格遵守 D1：采用方案 A（用户手动唤醒，代理不主动介入）

**⚠️ 本问题挂起，等 PM 决策后由 architect 补充技术方案。在 PM 未拍板前，场景 C 前端实现暂用方案 A（手动唤醒）。**

---

### #6 音频流 Phase 4 再接

**结论：✓ 确认推迟。**

C2 `voice_input` 设计字段（`audio_b64/format/sample_rate/is_final`）合理，Phase 4 接 Baidu STT 时启用。Phase 3 前端不发此类型，`ws_handler.py` 保持不变。

---

## 三、发现的文档层问题

以下为 review 中发现的文档层问题（非代码），建议 backend 在 v1.1 中修订。

### I1：S4 `error_message` 与 S6 `display_text` 字段冗余（P1）

**问题**：AE5 执行失败时，schema §三 S4 说"切换 AgentSpeechBubble 显示 `error_message`"，同时 §五 AE5 说"backend 发 S6 + S4(error)"。两条消息同时到达，都更新 AgentSpeechBubble，前端不知道以哪个为准。

**成因**：S4 设计为进度通知，不应承载最终错误文字；错误文字应唯一来源于 S6。

**影响**：前端若同时处理 S4(error) 的 `error_message` 和 S6 的 `display_text`，气泡内容可能闪烁（先显示 S4 错误，再被 S6 覆盖）。

**修复建议**：
- `progress_update.error_message` 字段改为 `null`（即使 `stage="error"`，错误文字只走 S6 `display_text`）
- S4 `stage="error"` 的作用仅为让 AgentProgressIndicator 退场，不更新 SpeechBubble
- 前端处理：收 S4(error) → ProgressIndicator 退场；收 S6 → SpeechBubble 更新 + TTS

---

### I2：C3 与 S3 双重触发 `proposing→executing` 状态转换（P1）

**问题**：C3 `user_action {authorize}` 的"前端应这样处理"写"前端切 `proposing→executing`"；S3 `intent_execute` 的"前端应这样处理"也写"前端切 `proposing→executing`"。如果两处都触发 phase 切换，会造成 Riverpod Notifier 收到两次相同的状态写入（幂等，不崩溃，但逻辑混乱）。

**成因**：C3 的描述是乐观 UI 的意图（立即给用户反馈），S3 是实际执行的信号。

**影响**：若 AgentNotifier 不做幂等保护（`if state.phase == proposing then...`），两次触发可能导致 AgentProgressIndicator 入场动画播放两次。

**修复建议**：
- 统一规定：**前端在收到 S3 后才切 `proposing→executing`**，C3 发送时不切态（等待 S3）
- 原因：如果网络延迟 S3 较慢，乐观切态后用户看到 ProgressIndicator 但代理还未确认，反而造成误解
- C3 的"前端应这样处理"修改为："`authorize` → 前端**等待 S3 到达**后切 `proposing→executing`（通常 < 200ms）；若 S3 3 秒未到，前端发 abort 并提示用户"

---

### I3：URL 注入（--dart-define）未在文档体现（P2）

**问题**：§一.1 URL 格式说 host 固定 `localhost`，端口固定 `8000`。TECH_STACK_REVIEW.md §D.5 决策 D2 建议用 `--dart-define=WS_URL=...` 注入，schema 文档未呼应。

**影响**：答辩时指导老师在本机运行，若 backend IP 不是 localhost（如部署到局域网），前端无法连接。

**修复建议**：在 §一.1 增加一行注：

> "完整 URL 通过 `--dart-define=WS_BASE_URL=ws://localhost:8000` 注入（`agent_client.dart` 读取 `const String.fromEnvironment('WS_BASE_URL', defaultValue: 'ws://localhost:8000')`），不在代码中硬编码。"

---

## 四、TECH_STACK_REVIEW.md 同步更新（2 处）

本轮 review 发现需在 TECH_STACK_REVIEW.md 中补充，记录如下，frontend 实施时一并执行：

### T1：`AgentState` 需补 2 个字段

```dart
// lib/core/state/agent_state.dart 的 AgentState 类需新增：
@immutable
class AgentState {
  // ... 现有字段 ...
  final String? currentProposalId;       // ← 新增：C3 authorize/deny 回传用
  final List<AgentOption>? clarificationOptions; // ← 新增：S7 选项按钮渲染用
}

class AgentOption {
  final String label;
  final String value;
  const AgentOption({required this.label, required this.value});
}
```

**`currentProposalId` 必要性**：Frontend 在用户点"确认"时需发 `C3 {proposal_id: ...}`，此值来自 S2，必须在 AgentState 中持有。TECH_STACK_REVIEW 的骨架中漏掉了此字段。

**`clarificationOptions` 必要性**：S7 `clarification_request.options` 需在 AgentSpeechBubble 下方渲染快捷选项按钮（目前 TECH_STACK_REVIEW 未定义此渲染位置）。Phase 3 先做 `options=[]` 的情况（重说），有选项的情况 Phase 4 补全。

### T2：WebSocket 重连策略兼容性

Schema §一.4 定义的指数退避（1 次立即 → 2s → 4s → 最长 30s）与 TECH_STACK_REVIEW 建议的 `web_socket_channel` 兼容。`web_socket_channel` 本身不含自动重连，需在 `AgentClient` 中手动实现指数退避 Timer。这是预期的（schema 文档本来就把重连逻辑交给前端）。无需修改 TECH_STACK_REVIEW，但 frontend 实施时要注意 `AgentClient` 自行管理重连 Timer，不能依赖包自动重连。

---

## 五、综合结论

### 总打标

| 维度 | 结论 |
|---|---|
| S2→IntentProposalCard 字段对齐 | ✓ |
| S4→ProgressIndicator 字段对齐 | ⚠️（I1 需修文档）|
| S6 错误码 AE1-AE5 精确对齐 | ✓ |
| S1-S5 驱动 AgentPhase 5 态完整性 | ✓（I2 状态转换需统一规定）|
| #1 agent_error schema 设计 | ✓（文档设计正确，代码待实现）|
| #2 UserAction 处理规格 | ✓（含 deny 语义建议）|
| #3 timeout_sec=5 确认 | ⚠️ P0，backend 代码必须改 |
| #4 执行回路完整性 | ⚠️ P0，frontend 可 mock 先行 |
| #5 场景 C 唤醒机制 | ⚠️ 产品决策挂起，等 PM |
| #6 音频流 Phase 4 | ✓ 推迟确认 |

### 后端代码改动（属下一轮 backend 派活，本轮不执行）

1. `schemas.py`：新增 `AgentError(BaseMsg)` 类
2. `ws_handler.py`：实现 `_handle_user_action()` 完整三分支
3. `ws_handler.py`：`IntentProposal.timeout_sec` 改为 `5`
4. `ws_handler.py`：实现 `authorize` → S3 → S4(executing) → S4(done) → S5 完整回路

### 文档修订建议（backend 在 schema v1.1 中更新）

1. I1：删除 S4 `error_message` 的 SpeechBubble 更新说明，错误文字统一来源于 S6
2. I2：C3 描述改为"等待 S3 后切 executing"，删除乐观 UI 描述
3. I3：§一.1 补 `--dart-define=WS_BASE_URL` 注入说明

### 对 frontend 的指引

- **现在可以开始实施**：4 个 Agent UI 组件 + `AgentState` + `AgentClient`（含 `MockAgentClient`）
- **MockAgentClient** 应能模拟完整 S3/S4/S5 序列（后端 #4 未修复前的前端独立测试用）
- **`AgentState` 补 `currentProposalId` 和 `clarificationOptions` 字段**（见 T1）
- **I2 状态转换**：在 `AgentNotifier` 中，`proposing→executing` 仅在收到 S3 时触发，C3 发出时**不切态**

---

## 变更记录

| 日期 | 版本 | 变更摘要 |
|---|---|---|
| 2026-04-18 | v1.0 | 初版 review；基于 AGENT_WEBSOCKET_SCHEMA v1.0 + PRD v2.0 + SPEC v1.1 + TECH_STACK_REVIEW v1.0 |
