# 修复方案：场景内提问无回传通道（医保缴费"本人/家人"流程中断）

> 作者：architect｜日期：2026-05-26｜状态：待开发实施

## 根因分析（回答 team-lead 4 问）

**Q1：为什么 cmd_say 问了"本人/家人"却没等回复？**
`scene_yibao_jiaofei.txt:52` 写"信息不足先 cmd_say 问用户，拿到真实值再填"，但 **cmd_say 是即发即忘**——它只把话播出来 + 入气泡，不暂停执行器。执行器问完后唯一能"暂停"的工具是 cmd_wait_user，而 cmd_wait_user 等的是 `_step_event`（前端 UI 手势：点高亮 / 跳页 / 输入框完成），**不是文字回复**。所以 LLM 问完后调了 cmd_wait_user，执行器卡在 `_step_event.wait()`，文字回复永远喂不进来 → 超时（日志行 249）。

**Q2：为什么"本人"被当新输入走了意图分类？**
`ws_handler._on_text_input`(155-160) **无条件**把所有文字走 `process_asr_text → intent_classify`，没有"执行器正在等回答→把这句话喂给执行器"的判断。执行中场景与新意图分类是两条完全独立的路径，缺少**场景内问答回传机制**。

**Q3：是否该用 agent_choice_request 选择卡？**
**是。** 本人/配偶/子女是有限枚举，对长辈用选择按钮远优于开放式提问（免打字、免 ASR 歧义）。但 agent_choice_request 当前只在**执行前**的 login_choose 分支用过，其答案经 `sendChoiceText → text_input → 重新分类`；执行中没法用。需要把"选择卡的答案回传给运行中的执行器"补齐。

**Q4：修复**——见下。核心是给执行器加一个"提问并等待回答"的 HITL 工具 `cmd_ask_user`（与 cmd_wait_user / 授权卡同构），并在 ws_handler 把"执行器等待回答"期间的用户输入**路由回执行器**而非重新分类。附带修一个相关的 60s 超时隐患。

---

# 修复 A（核心）：cmd_ask_user 工具 + 回答回传

## A1. 新建 `backend/tools/ask_user.py`

```python
from agno.tools import tool


@tool(stop_after_tool_call=True)
def cmd_ask_user(question: str, options: list[str] | None = None) -> dict:
    """向用户提问并暂停，等用户回答后由后端自动续传。
    options 非空时前端渲染为选择按钮（适合"本人/配偶/子女"这类有限选项）；
    为空时让用户自由输入文字（如身份证号）。question 会播报 + 入聊天气泡。"""
    return {"question": question, "options": options or []}
```
> 若 agno 对 `list[str] | None` 的 schema 生成报错，退化为 `options_csv: str = ""`（逗号分隔），执行器侧 `split(',')` 解析。

## A2. `backend/agent_core.py`

### A2.1 import 工具（第 19 行 `cmd_wait_user` import 后）
当前（13-19）末行：
```python
from backend.tools.wait_user import cmd_wait_user
```
其后加：
```python
from backend.tools.ask_user import cmd_ask_user
```

### A2.2 SCENE_TOOLS 给 yibao_jiaofei 挂 cmd_ask_user（36-37 行）
当前：
```python
    "yibao_jiaofei": [cmd_navigate, cmd_highlight, cmd_say,
                      fill_field_normal, fill_field_sensitive, cmd_wait_user],
```
改为（加 `cmd_ask_user`）：
```python
    "yibao_jiaofei": [cmd_navigate, cmd_highlight, cmd_say, cmd_ask_user,
                      fill_field_normal, fill_field_sensitive, cmd_wait_user],
```

### A2.3 _LEVEL_TOOLS 三级都放开 cmd_ask_user（44-52 行）
提问是无害的对话行为，三级都应可用。在 `guide` / `semi` / `full` 三个集合里各加 `"cmd_ask_user"`：
```python
_LEVEL_TOOLS: dict[str, set[str]] = {
    "guide": {"cmd_highlight", "cmd_say", "cmd_wait_user", "cmd_ask_user"},
    "semi":  {"cmd_navigate", "cmd_highlight", "cmd_say",
              "fill_field_normal", "cmd_press_button",
              "read_sms", "fill_field_sensitive", "cmd_wait_user", "cmd_ask_user"},
    "full":  {"cmd_navigate", "cmd_highlight", "cmd_say",
              "fill_field_normal", "cmd_press_button",
              "read_sms", "fill_field_sensitive", "cmd_wait_user", "cmd_ask_user"},
}
```

### A2.4 __init__ 加回答事件（294 行 `_step_debounce_task` 后）
当前（292-294）：
```python
        self._step_event: asyncio.Event = asyncio.Event()
        self._step_payload: dict | None = None
        self._step_debounce_task: asyncio.Task | None = None
```
其后加：
```python
        self._answer_event: asyncio.Event = asyncio.Event()
        self._answer_text: str | None = None
        self._awaiting_answer: bool = False
```

### A2.5 execute_task：每次 LLM 调用加 60s 超时（见修复 B），并新增 cmd_ask_user 分支

**(a) 第 410 行 arun 加超时**（修复 B，详见下节）：
```python
            response = await asyncio.wait_for(self._executor.arun(input_msg), timeout=60.0)
```

**(b) 在 cmd_wait_user 分支之后、`if stopped_tool in _SENSITIVE_TOOLS:`（431 行）之前**，插入新分支：
```python
            if stopped_tool == "cmd_ask_user":
                await self._push_tool_results(response, skip_stopped="cmd_ask_user")
                question, options = self._get_ask_payload(response)
                self._answer_text = None
                self._answer_event.clear()
                self._awaiting_answer = True
                if options:
                    await self._send_fn("agent_choice_request", {
                        "text": question,
                        "options": [{"value": o, "label": o} for o in options],
                    })
                else:
                    await self._send_fn("agent_reply", {
                        "text": question,
                        "tts_audio_base64": None,
                        "tts_format": "mp3",
                        "requires_confirmation": False,
                        "confirmation_timeout_ms": None,
                    })
                try:
                    await asyncio.wait_for(self._answer_event.wait(), timeout=180.0)
                except asyncio.TimeoutError:
                    self._awaiting_answer = False
                    logger.info("session=%s ask_user wait timeout", self.session_id)
                    return SCENE_DONE_SUMMARY.get(scene_id) or "等待回答超时"
                self._awaiting_answer = False
                answer = self._answer_text or ""
                input_msg = f"用户回答：{answer}。请据此继续当前流程的下一步，不要重复提问。"
                continue
```
> 注意：先 `clear + 置 _awaiting_answer=True` 再 `_send_fn`，杜绝用户极快回答造成的竞态。`cmd_ask_user` 不在 `_TOOL_TO_MSG_TYPE` 里，`_push_tool_results` 本就不会转发它，`skip_stopped` 是双保险。

### A2.6 新增 _get_ask_payload 解析方法（第 588 行 `_get_tool_field_key` 后）
```python
    def _get_ask_payload(self, response) -> tuple[str, list]:
        """从 cmd_ask_user 的停止工具结果里取出 question / options。"""
        import ast
        for msg in (response.messages or []):
            if getattr(msg, "from_history", False):
                continue
            if msg.role != "tool":
                continue
            if not getattr(msg, "stop_after_tool_call", False):
                continue
            if getattr(msg, "tool_name", None) != "cmd_ask_user":
                continue
            content = msg.content
            if isinstance(content, dict):
                d = content
            elif isinstance(content, str):
                try:
                    d = ast.literal_eval(content)
                except Exception:
                    d = {}
            else:
                d = {}
            return (d.get("question", "") or "", d.get("options", []) or [])
        return ("", [])
```

### A2.7 新增回答回传接口（第 633 行 `resolve_step` 附近）
```python
    @property
    def is_awaiting_answer(self) -> bool:
        return self._awaiting_answer

    def resolve_answer(self, text: str) -> None:
        """ws_handler 在执行器等待回答期间，把用户输入喂回执行器。"""
        self._answer_text = text
        self._answer_event.set()
```

## A3. `backend/ws_handler.py`：把"等待回答"期间的输入路由回执行器

在 `process_asr_text`(259-262) 开头加路由判断（文字与语音都走这条公共路径，一处搞定）：
当前（259-262）：
```python
    async def process_asr_text(self, text: str) -> None:
        """Called when final ASR transcript is ready."""
        if not self._agent_core:
            return
```
改为：
```python
    async def process_asr_text(self, text: str) -> None:
        """Called when final ASR transcript is ready."""
        if not self._agent_core:
            return
        if self._agent_core.is_awaiting_answer:
            logger.info("session=%s route reply to executor: %r", self.session_id, text)
            self._agent_core.resolve_answer(text)
            return
```
> 选择卡的答案经 `sendChoiceText → text_input`、开放问题的答案经聊天输入 `sendText → text_input`，二者最终都到 `process_asr_text`，被这段统一路由回执行器，不再误入意图分类。前端无需改动（agent_choice_request 渲染按钮、agent_reply 渲染气泡均已支持）。

---

# 修复 B（companion）：60s 超时只裹 LLM 调用，不裹人工等待

## 问题
`ws_handler._run_execute`(331-334) 用 `asyncio.wait_for(execute_task(...), 60.0)` 把**整个**执行（含 cmd_wait_user 的 180s、cmd_ask_user 的 180s、授权卡的 20s 等人工等待）一起限到 60s。人一慢就被砍，这也是本 bug 里执行器在 60s 整点 timeout 的直接原因，且同样威胁 login_verify 多步流程。

## 修复
把超时从"裹整个 execute_task"挪到"裹每一次 LLM arun"。

### B1. `agent_core.py` execute_task：arun 加超时（已在 A2.5(a) 给出，第 410 行）
```python
            response = await asyncio.wait_for(self._executor.arun(input_msg), timeout=60.0)
```
> TimeoutError 会向上抛给 _run_execute 处理（下条）。人工等待分支用各自的内层 timeout（180/180/20s），不受这 60s 约束。

### B2. `ws_handler.py` _run_execute：去掉外层 wait_for，保留 TimeoutError 处理
当前（329-345）：
```python
    async def _run_execute(self, intent_summary: str) -> None:
        try:
            try:
                summary = await asyncio.wait_for(
                    self._agent_core.execute_task(intent_summary), timeout=60.0
                )
            except asyncio.TimeoutError:
                logger.error("session=%s execute_task timeout", self.session_id)
                self.state = SessionState.idle
                await self.send("agent_error", AgentErrorPayload(
                    error_code="llm_timeout",
                    retry_count=0,
                    max_retries=1,
                    voice_hint="网络有点慢，请您稍后再试",
                    tts_audio_base64=None,
                ).model_dump())
                return
            if summary and summary != "已取消":
```
把 `asyncio.wait_for(self._agent_core.execute_task(intent_summary), timeout=60.0)` 改为直接 await（其余不变）：
```python
                summary = await self._agent_core.execute_task(intent_summary)
```
> 这样 TimeoutError 只在某次 LLM 调用真的超 60s 时由 execute_task 抛出，仍落到这里的 `except asyncio.TimeoutError` 分支，文案不变。人工等待不再被误杀。

---

# 修复 C：prompt 改用 cmd_ask_user

## `backend/prompts/scene_yibao_jiaofei.txt`

### C1. 可用工具列表（3-10 行）加 cmd_ask_user
在工具清单里加：
```
- cmd_ask_user（向用户提问并等回答：options 非空渲染为选择按钮，适合"本人/配偶/子女"；为空让用户自由输入，如身份证号。问完会自动暂停等回答，不要再叠 cmd_wait_user）
```

### C2. 第 2 步开头：缴费对象未知时先问（28-30 行附近）
在"第 2 步 代填表单"开头、填 select_jiaofei_duixiang 之前加一段：
```
  【信息收集】开始填表前，凡【字段取值规范】要求的值用户没明确给出，必须用 cmd_ask_user 问清后再填，绝不臆测、绝不用占位符：
  - 缴费对象未知：cmd_ask_user(question="请问是帮您本人缴费，还是帮家人缴？", options=["本人","配偶","子女"])
  - 本人身份证号未知：cmd_ask_user(question="请告诉我您的18位身份证号", options=[])
  - （家人路径）被缴费人姓名 / 证件号未知：分别用 cmd_ask_user 开放式提问
  拿到回答后按回答取值，再继续 fill_field_*。
```

### C3. 准则（52 行）改写
当前：
```
- value 必须用【字段取值规范】里的精确选项，**绝不用方括号占位**；信息不足先 cmd_say 问用户，拿到真实值再填。
```
改为：
```
- value 必须用【字段取值规范】里的精确选项，**绝不用方括号占位**；信息不足必须用 cmd_ask_user 问用户（有限选项带 options，自由文本不带），拿到真实值再填。绝不能用 cmd_say 问问题——cmd_say 不会等回答。
```

> 启动校验 `_validate_prompts_against_knowledge` 只校验 element_key / target_route，不涉及工具名，C 改动不影响启动。

---

# 验证步骤

### 用例 1【本人路径，选择卡】
1. 登录到 full 级，对小浙说"帮我缴医保"（不给缴费对象）。
2. 预告 + cmd_navigate 到缴费页后，**预期**：弹出**选择卡**「本人 / 配偶 / 子女」（不再是开放问句卡死）。点"本人"。
3. 若身份证号未知，**预期**：弹开放问句"请告诉我您的18位身份证号"，聊天框输入后流程继续。后端日志该输入应是 `route reply to executor`，**不**出现 `classified scene=out_of_scope`。
4. 续填险种/年度/档次（默认值）→ 身份证敏感字段弹一次授权卡 → 高亮"去支付"。无 `execute_task timeout`。

### 用例 2【家人路径】
1. 第 2 步选"配偶/子女"→ 预期额外追问被缴费人姓名、证件号（cmd_ask_user 开放式），均能回传续传。

### 用例 3【超时隔离回归（修复 B）】
1. 走任意多步引导（如 login_verify），在某一步**故意慢 ~90s**再操作。
2. **预期**：流程不再在 60s 处被砍（人工等待不受 LLM 超时约束）；仅当某次 LLM 响应真的 >60s 才提示"网络有点慢"。

### 回归
- 养老金 / 查询类场景（无 cmd_ask_user）行为不变。
- 执行器**未**在等待回答时，正常文字输入仍走意图分类（is_awaiting_answer=False）。
- login_choose 等执行前的选择卡行为不变（那时 is_awaiting_answer=False，答案照常走分类路由到对应场景）。

---

## 关联产品问题（flag 给 PM，不在本次代码范围）
全委托缴费要求填**本人真实 18 位身份证号**，但代理无数据源、只能问用户——让长辈手打 18 位身份证体验差。建议后续引入 mock 用户档案，登录后身份证等可由档案带出，代理无需逐位询问。
