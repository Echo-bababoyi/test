# 养老金查询场景 — 现状审查与跑通方案

> **日期**：2026-05-19
> **作者**：architect
> **触发**：用户要跑通养老金查询场景（PRD 场景 4）

---

## 1. TL;DR

**链路 80% 已搭好，但卡在 2 个具体断点**：

1. 🔴 **致命**：代理代按"查询"按钮的执行路径错——`_onPressButton` 找 `GestureDetector`，而页面用的是 `ElevatedButton`，**按不到**。
2. 🔴 **半致命**：查询结果回调 cmd_highlight 用了写死的 `element_key="result_area"`，但页面注册的是 `result_pension_amount`，**结果区不会高亮**（但 agent_reply 播报仍能通）。

修这 2 处即可跑通。**总工作量 ~30 min**（前端扩展 element_registry + 后端 2 行 + 页面 initState 注册回调）。

---

## 2. 完整链路追踪与逐步状态

按 PRD 场景 4 / UI_UX_DESIGN.md §3.4 / ARCHITECTURE.md §4.2.13 复核：

| # | 阶段 | 路径 | 状态 | 关键文件:行 |
|---|---|---|---|---|
| 1 | 用户开聊天面板 | AgentFab `_initSession()` → WS connect → `agent_wake` | ✅ | agent_fab.dart:471-491 |
| 2 | 后端建 AgentCore | `_on_agent_wake` → 新 AgentCore → 推 `agent_ready` | ✅ | ws_handler.py:108-121 |
| 3 | 用户输入"帮我查养老金" | 文本输入 `_sendText()` → `text_input` | ✅ | agent_fab.dart:587-594 |
| 4 | 意图分类 | classifier prompt **已含 pension_query** | ✅ | intent_classify.txt:7 |
| 5 | 复述确认 | rephraser → `agent_reply{ requires_confirmation=true }` | ✅ | ws_handler.py:268-277 |
| 6 | 用户确认"是" | `user_confirm{ answer: 'yes' }` → `_run_execute` | ✅ | ws_handler.py:178-186 |
| 7 | 加载场景 prompt + tools | scene_pension_query.txt + `[navigate, highlight, fill, press_button]` | ✅ | agent_core.py:25, 33 |
| 8 | LLM 调 `cmd_navigate` | `_push_tool_results` → 前端 router.push | ✅ | agent_command_executor.dart:51-63 |
| 9 | LLM 调 `cmd_press_button(btn_query)` | 前端 `_onPressButton` 查 `findAncestorWidgetOfExactType<GestureDetector>` | 🔴 **断**：page 用 ElevatedButton，**ancestor 找不到 GestureDetector**，按钮不会被按下 | agent_command_executor.dart:122-138 / pension_query_page.dart:162-174 |
| 10 | （假设手按了"查询"）`_doQuery` 触发 | `setState(_hasResult=true)` + 发 `query_result_ready` | ✅（手按可走通） | pension_query_page.dart:28-38 |
| 11 | 后端 `_on_query_result_ready` | `set_query_result` + `_broadcast_query_result` | ✅ | ws_handler.py:193-198 |
| 12 | LLM 生成播报话术 | `broadcast_query_result()` → DeepSeek 短句 | ✅ | agent_core.py:221-234 |
| 13 | 推 `agent_reply`（含 TTS） | 前端 bubble 显示 + 播音频 | ✅ | ws_handler.py:200-209 |
| 14 | 推 `cmd_highlight` 给结果区 | `element_key="result_area"` —— 页面注册的是 `result_pension_amount`，找不到 | 🟡 **断 key 不匹配** | ws_handler.py:210-216 / pension_query_page.dart:26 |
| 15 | 推 `task_done` | 前端面板 2s 后自动关闭 | ✅ | agent_fab.dart:549-557, 602-605 |

**结论**：1-8、10-13、15 全通；**步骤 9 完全卡死**（代理代按失败），**步骤 14 静默失败**（高亮无效但播报正常）。

---

## 3. 详细问题分析

### 🔴 P0-1：代理代按"查询"按钮失败（步骤 9）

**`app/lib/services/agent_command_executor.dart:122-138`**：

```dart
void _onPressButton(Map<String, dynamic> payload) {
  final elementKey = payload['button_key'] as String?;
  final isDeterministic = payload['is_deterministic'] as bool? ?? true;
  if (elementKey == null || isDeterministic) return;
  final key = AgentElementRegistry.get(elementKey);
  if (key == null) return;
  final context = key.currentContext;
  if (context == null) return;
  // ← 这里只找 GestureDetector
  final gesture = context.findAncestorWidgetOfExactType<GestureDetector>();
  if (gesture?.onTap != null) {
    gesture!.onTap!();
  }
}
```

**`app/lib/pages/pension_query_page.dart:159-175`**：
```dart
Widget _buildQueryButton() {
  return SizedBox(
    height: 52,
    child: ElevatedButton(            // ← 不是 GestureDetector
      key: _queryKey,
      onPressed: _doQuery,
      ...
```

`ElevatedButton` 内部用 `Material` + `InkWell`，**没有 `GestureDetector` ancestor**。`findAncestorWidgetOfExactType<GestureDetector>()` 返回 `null`，代按操作静默失败。LLM 已经发完工具调用、`task_done` 也会被后端发出，但前端**根本没触发查询**——`_hasResult` 还是 false，`query_result_ready` 也不会发，整个查询场景从用户视角是"代理说了几句话就结束了，什么都没做"。

**为什么之前没发现**：之前都是用户手动点查询按钮触发 `_doQuery`，绕过了代理代按这条路径。

### 🟡 P0-2：cmd_highlight 用错 element_key（步骤 14）

**`backend/ws_handler.py:210-216`**：
```python
await self.send("cmd_highlight", CmdHighlightPayload(
    element_key="result_area",   # ← 写死
    highlight_color="#FF6D00",
    pulse=True,
    voice_hint="",
    duration_ms=5000,
).model_dump())
```

**`app/lib/pages/pension_query_page.dart:26`**：
```dart
final _resultKey = AgentElementRegistry.register('result_pension_amount');
```

`AgentElementRegistry.get('result_area')` 返回 `null`，`_onHighlight` 直接 `return`（agent_command_executor.dart:68）。结果区不会有高亮脉冲。

**ARCHITECTURE.md:593 设计的 key 是 `result_pension_amount`**，所以是后端实现写错了。

### 🟡 P1：scene_pension_query.txt 跳过了 cmd_highlight 步骤

**`backend/prompts/scene_pension_query.txt:5-6`**：当前只 navigate + press_button，跳过了 UI_UX_DESIGN.md:249 设计的"按钮高亮橙色（1秒）后自动按下"。功能上不影响（手按场景下用户也看不到这 1 秒高亮），**优先级低**。

### 🟡 P2：月份选择器换月无效

**`pension_query_page.dart:141, 151`**：左右箭头 `onTap: () {}` 是占位。代理与用户都换不了月，固定 "2026年5月"。基础链路不依赖换月，**不影响跑通**。

### 🟢 P3：路由 / 文档一致性

- `AppRoutes.pensionQuery = '/service/pension-query'`（router.dart:36）
- prompt 用 `/service/pension-query`（scene_pension_query.txt:5）✓
- UI_UX_DESIGN.md:248 写的是 `/elder/pension-query` — **文档过期**，不影响代码

---

## 4. 跑通方案（精确到文件:行号）

### 修复 #1：扩展 AgentElementRegistry，支持回调注册

**新增** `app/lib/services/agent_element_registry.dart`（在现有 class 内）：

需要先看现有结构。基于 grep 结果 `registerController` 已存在，照其形状新增 `registerCallback` 即可。开发参照下面骨架：

```dart
// agent_element_registry.dart 内（与 _controllers / _keys 并列）
static final Map<String, VoidCallback> _callbacks = {};

static void registerCallback(String key, VoidCallback cb) {
  _callbacks[key] = cb;
}

static VoidCallback? getCallback(String key) => _callbacks[key];

static void unregisterCallback(String key) {
  _callbacks.remove(key);
}
```

### 修复 #2：`agent_command_executor.dart:122-138` _onPressButton 改用回调

整体替换为：
```dart
void _onPressButton(Map<String, dynamic> payload) {
  final elementKey = payload['button_key'] as String?;
  final isDeterministic = payload['is_deterministic'] as bool? ?? true;
  if (elementKey == null || isDeterministic) return;
  final cb = AgentElementRegistry.getCallback(elementKey);
  if (cb == null) {
    debugPrint('[AgentExec] no callback registered for $elementKey');
    return;
  }
  cb();
  final voiceHint = payload['voice_hint'] as String?;
  if (voiceHint != null && voiceHint.isNotEmpty) {
    _speakHint(voiceHint);
  }
}
```

**关键**：放弃 widget tree ancestor 探测——无法适配 `ElevatedButton` / `FilledButton` / `InkWell` 各种结构。直接让业务页面**显式注册回调**，可靠且不依赖 widget 实现细节。

### 修复 #3：`pension_query_page.dart` 注册查询回调

**新增 initState / dispose**（pension_query_page.dart：当前 class 没有 initState/dispose，直接加）：

```dart
@override
void initState() {
  super.initState();
  AgentElementRegistry.registerCallback('btn_query', _doQuery);
}

@override
void dispose() {
  AgentElementRegistry.unregisterCallback('btn_query');
  super.dispose();
}
```

**位置**：插入到 `_PensionQueryPageState` 类内（约第 27 行 `_resultKey` 之后、`_doQuery` 之前）。

### 修复 #4：`backend/ws_handler.py:210-216` cmd_highlight 用正确 element_key

把硬编码 `"result_area"` 改成按场景映射：

**第 1 步**：在 `ws_handler.py` 顶部加常量（约第 25 行 logger 之后）：
```python
_RESULT_KEY_MAP = {
    "pension_query": "result_pension_amount",
    "yibao_query": "result_area",  # TODO 真值待对齐 yibao_query_page.dart 注册名
}
```

**第 2 步**：替换 `_broadcast_query_result` 行 210-216：
```python
scene_id = self._pending_intent.get("scene_id", "") if self._pending_intent else ""
result_key = _RESULT_KEY_MAP.get(scene_id)
if result_key:
    await self.send("cmd_highlight", CmdHighlightPayload(
        element_key=result_key,
        highlight_color="#FF6D00",
        pulse=True,
        voice_hint="",
        duration_ms=5000,
    ).model_dump())
```

如果 scene 没在 map 里，**安全降级**——跳过高亮（agent_reply 已经能完成播报）。

### 修复 #5（可选 P1）：补 cmd_highlight 步骤

**`backend/prompts/scene_pension_query.txt`** 整体替换为：
```
帮用户查询养老金。你必须通过 function call 调用工具来执行每一步，绝不允许用文字描述操作。

按顺序调用以下工具：

第1步：cmd_navigate(target_route="/service/pension-query", voice_hint="好的，帮您打开养老金查询页面")
第2步：cmd_highlight(element_key="btn_query", voice_hint="帮您查一下", duration_ms=1000)
第3步：cmd_press_button(button_key="btn_query", button_label="查询", voice_hint="正在为您查询养老金信息")

规则：
- 每步必须调用对应工具，绝不跳过
- 查询按钮是非确定性操作，可以代按
- 工具调用完成后回复"已帮您发起养老金查询，请稍候"
```

---

## 5. 改动清单与优先级

| # | 文件 | 改动 | 行数 | 优先级 | 是否跑通必需 |
|---|---|---|---|---|---|
| 1 | `app/lib/services/agent_element_registry.dart` | 加 `_callbacks` map + `registerCallback` / `getCallback` / `unregisterCallback` | ~10 | P0 | ✅ |
| 2 | `app/lib/services/agent_command_executor.dart` 122-138 | `_onPressButton` 改为读 callback | ~15 | P0 | ✅ |
| 3 | `app/lib/pages/pension_query_page.dart` | 加 initState/dispose 注册 `btn_query` 回调 | ~10 | P0 | ✅ |
| 4 | `backend/ws_handler.py` 顶部 + 210-216 | 加 `_RESULT_KEY_MAP` + 替换 cmd_highlight 逻辑 | ~10 | P0 | 🟡（不修则结果不高亮，但播报正常） |
| 5 | `backend/prompts/scene_pension_query.txt` | 加 cmd_highlight 步骤 | ~3 | P1 | ❌（功能上不必需） |

**核心跑通**：#1、#2、#3 必修；#4 强烈建议（要符合 PRD"双通道呈现"）；#5 锦上添花。

---

## 6. 测试 checklist

部署本地：

```bash
cd backend && python -m uvicorn backend.main:app --port 8080 --reload
cd app && ../bin/flutter run -d chrome
```

测试步骤：
- [ ] 长辈首页点 FAB → 面板打开，bubble 显示"您好，我是小浙，有什么可以帮您？"
- [ ] 输入框输入"帮我查养老金" → 看到 "小浙正在想…" → 收到 "帮您查养老金，对吗？" + 是/否按钮
- [ ] 点"是" → 看到页面跳转到 `/service/pension-query`
- [ ] **代理代按"查询"按钮成功**，看到结果卡片渲染（_hasResult=true）
- [ ] **小浙气泡说出**类似"您的养老金本月发放了 3280 元"的播报
- [ ] **结果区出现橙色脉冲高亮**（修复 #4 后）
- [ ] 2 秒后面板自动关闭

附加：
- [ ] 后端日志 `session=xxx push tool result: cmd_press_button {...}` 与前端 `[AgentExec] no callback registered` 应**不再出现**
- [ ] 直接手动点"查询"按钮也应正常工作（未破坏原有交互）

---

## 7. 与设计文档的对齐情况

| 设计要求 | 来源 | 现状 |
|---|---|---|
| 代理 L1-L2 全链路 | PRD §场景 4 | 修复后 ✅ |
| 双通道呈现（语音 + 屏幕） | PRD §场景 4 验收 | agent_reply 播报已有 ✅；结果高亮修复 #4 后 ✅ |
| 查询按钮代理代按 | PRD §场景 4 验收 | 修复 #2/#3 后 ✅ |
| 按钮高亮 1s 后自动按下 | UI_UX_DESIGN §3.4 步骤 6 | 修复 #5 后 ✅（可选） |
| query_result_ready 消息 | ARCHITECTURE §4.2.13 | ✅ 已实现 |
| cmd_highlight(result_pension_amount) | ARCHITECTURE §4.2.13 | 修复 #4 后 ✅ |
| 面板 3000ms 后自动关闭 | UI_UX_DESIGN §3.4 步骤 8 | 当前是 2000ms（agent_fab.dart:603）——与文档差 1s，**不阻塞**，论文里可二选一注脚 |

---

## 8. 风险与边界

- **修复 #2 影响范围**：`_onPressButton` 改为读 callback，**所有"代按"场景的页面都需要类似注册**。当前只有 `btn_query` 一处真实代按，所以风险可控。如果未来 yibao_query 等也要代按，同模式注册即可。
- **修复 #4 影响范围**：只动 `_broadcast_query_result` 一处；其他用 `CmdHighlightPayload` 的地方（`_push_tool_results` 路径）不受影响——那条路径用的是 LLM tool call 里的 element_key，不是后端硬编码。
- **跨页面 callback 残留**：如果用户在 pension 页 dispose 前**没等 dispose**就用代理跳到别页，pension 的 callback 会被新 widget 覆盖（registerCallback 同 key 覆盖）。属于正常行为，不需特殊处理。
- **demo mode 不受影响**：DEMO_MODE 走的是 `_initDemoData` 路径（agent_fab.dart:410-415），不连后端，本次修复不动该路径。
