import asyncio
import json
import logging
import uuid
from pathlib import Path
from typing import Callable, Coroutine, Any

from agno.agent import Agent
from agno.models.deepseek import DeepSeek

from backend.tools.navigate import cmd_navigate
from backend.tools.highlight import cmd_highlight
from backend.tools.fill_field import fill_field_normal, fill_field_sensitive
from backend.tools.press_button import cmd_press_button
from backend.tools.read_sms import read_sms
from backend.tools.say import cmd_say

logger = logging.getLogger(__name__)

_PROMPTS_DIR = Path(__file__).parent / "prompts"

SCENE_TOOLS = {
    "login_face":    [cmd_highlight, cmd_say],
    "login_verify":  [cmd_highlight, cmd_say],
    "yibao_jiaofei": [cmd_navigate, cmd_highlight, cmd_say,
                      fill_field_normal, fill_field_sensitive],
    "pension_query": [cmd_navigate, cmd_highlight, cmd_say,
                      fill_field_normal, cmd_press_button],
    "yibao_query":   [cmd_navigate, cmd_highlight, cmd_say,
                      fill_field_normal, cmd_press_button],
}

# read_sms 为 AGENT_SPEC.md §5 能力矩阵预留（L2/L3 代读短信），当前五个场景的 SCENE_TOOLS 均未挂载，三道 AND 取交集后不会被实际调用；新增短信相关场景时需在对应 SCENE_TOOLS 列表中加入。
_LEVEL_TOOLS: dict[str, set[str]] = {
    "guide": {"cmd_highlight", "cmd_say"},
    "semi":  {"cmd_navigate", "cmd_highlight", "cmd_say",
              "fill_field_normal", "cmd_press_button",
              "read_sms", "fill_field_sensitive"},
    "full":  {"cmd_navigate", "cmd_highlight", "cmd_say",
              "fill_field_normal", "cmd_press_button",
              "read_sms", "fill_field_sensitive"},
}


def get_scene_tools(scene_id: str, trust_level: str) -> list:
    """场景集 ∩ 用户级别集；级别非法时兜底 guide（最保守）。"""
    scene_max = SCENE_TOOLS.get(scene_id, [cmd_navigate, cmd_highlight])
    user_max = _LEVEL_TOOLS.get(trust_level, _LEVEL_TOOLS["guide"])
    return [t for t in scene_max if t.name in user_max]


SCENE_PROMPTS = {
    "login_face": "scene_login_face.txt",
    "login_verify": "scene_login_verify.txt",
    "yibao_jiaofei": "scene_yibao_jiaofei.txt",
    "pension_query": "scene_pension_query.txt",
    "yibao_query": "scene_yibao_query.txt",
}

_SENSITIVE_TOOLS = {"fill_field_sensitive", "read_sms"}

_PASSWORD_FIELDS = {
    "input_pay_password", "input_login_password",
    "input_old_password", "input_new_password",
}


def _is_password_field(field_key: str) -> bool:
    """密码字段全级别硬拒（v0.6 决策 5）。"""
    if not field_key:
        return False
    if field_key in _PASSWORD_FIELDS:
        return True
    lower = field_key.lower()
    return "password" in lower or "pwd" in lower


_PERMISSION_META = {
    "fill_field_sensitive": {
        "permission_type": "fill_sensitive_field",
        "field_label": "敏感字段",
        "description": "小浙需要帮您填写敏感信息，是否授权？",
    },
    "read_sms": {
        "permission_type": "read_sms",
        "field_label": "短信验证码",
        "description": "小浙需要读取您的短信验证码，是否授权？",
    },
}

_INTENT_PROMPT = (_PROMPTS_DIR / "intent_classify.txt").read_text(encoding="utf-8")
_CONFIRM_PROMPT = (_PROMPTS_DIR / "confirm_rephrase.txt").read_text(encoding="utf-8")
_OUT_OF_SCOPE_PROMPT = (_PROMPTS_DIR / "scene_out_of_scope.txt").read_text(encoding="utf-8")

_EXECUTOR_PREFIX = """\
你是小浙智能助手的执行引擎。你的唯一职责是通过调用工具（function call）来完成用户任务。

【关键规则】：
1. 你必须通过调用工具来执行操作，绝不允许仅用文字描述你会做什么
2. 每次只调用一个工具，等待返回结果后再调用下一个
3. 不要在回复中解释你在做什么，直接调用工具
4. 如果所有步骤执行完毕，回复一句简短总结即可

以下是你要完成的具体任务：
"""

# Tool names that map to WebSocket cmd_* message types
_TOOL_TO_MSG_TYPE: dict[str, str] = {
    "cmd_navigate": "cmd_navigate",
    "cmd_highlight": "cmd_highlight",
    "cmd_press_button": "cmd_press_button",
    "fill_field_normal": "cmd_fill_field",
    "fill_field_sensitive": "cmd_fill_field",
    "cmd_say": "cmd_say",
}


def _load_scene_prompt(scene_id: str) -> str:
    filename = SCENE_PROMPTS.get(scene_id)
    if filename:
        scene_text = (_PROMPTS_DIR / filename).read_text(encoding="utf-8")
    else:
        scene_text = f"帮用户完成：{scene_id}。按步骤调用工具完成任务，不要闲聊。"
    return _EXECUTOR_PREFIX + scene_text


class AgentCore:
    def __init__(self, session_id: str, ws_handler, trust_level: str = "guide"):
        self.session_id = session_id
        self.ws = ws_handler
        self._send_fn: Callable[..., Coroutine[Any, Any, None]] = ws_handler.send
        self._current_scene: str | None = None
        self._permission_event: asyncio.Event = asyncio.Event()
        self._permission_granted: bool = False
        self.trust_level: str = trust_level
        self._task_sensitive_authorized: bool = False
        # Pending query results forwarded from ws_handler
        self._query_result: dict | None = None
        self._query_event: asyncio.Event = asyncio.Event()

        self._classifier = Agent(
            model=DeepSeek(id="deepseek-chat", max_tokens=256, temperature=0.3),
            session_id=f"{session_id}_cls",
            instructions=_INTENT_PROMPT,
            markdown=False,
            add_history_to_messages=False,
            telemetry=False,
        )

        self._rephraser = Agent(
            model=DeepSeek(id="deepseek-chat", max_tokens=256, temperature=0.3),
            session_id=f"{session_id}_rph",
            instructions=_CONFIRM_PROMPT,
            markdown=False,
            add_history_to_messages=False,
            telemetry=False,
        )

        self._executor: Agent | None = None

    async def process_text(self, text: str) -> dict:
        """Classify intent and return rephrase for confirmation."""
        cls_response = await self._classifier.arun(text)
        raw = cls_response.content or ""
        try:
            intent = json.loads(raw)
        except json.JSONDecodeError:
            start = raw.find("{")
            end = raw.rfind("}") + 1
            intent = json.loads(raw[start:end]) if start >= 0 else {"scene_id": "out_of_scope", "intent_summary": text}

        scene_id = intent.get("scene_id", "out_of_scope")
        intent_summary = intent.get("intent_summary", text)
        self._current_scene = scene_id

        logger.info("session=%s classified scene=%s summary=%s", self.session_id, scene_id, intent_summary)

        if scene_id == "out_of_scope":
            oos_reply = (intent.get("reply_text") or "").strip()
            return {
                "scene_id": scene_id,
                "intent_summary": intent_summary,
                "confirm_text": oos_reply or "抱歉，这个功能暂时帮不到您",
            }

        rph_response = await self._rephraser.arun(intent_summary)
        confirm_text = (rph_response.content or intent_summary).strip()

        return {
            "scene_id": scene_id,
            "intent_summary": intent_summary,
            "confirm_text": confirm_text,
        }

    async def handle_out_of_scope(self, user_input: str) -> str:
        """Generate a polite out-of-scope reply using the scene_out_of_scope prompt."""
        agent = Agent(
            model=DeepSeek(id="deepseek-chat", max_tokens=256, temperature=0.3),
            session_id=f"{self.session_id}_oos",
            instructions=_OUT_OF_SCOPE_PROMPT,
            markdown=False,
            add_history_to_messages=False,
            telemetry=False,
        )
        response = await agent.arun(user_input)
        return (response.content or "抱歉，这个功能暂时帮不到您").strip()

    async def execute_task(self, intent_summary: str) -> str:
        """Execute the task for the classified scene with HITL loop for sensitive tools."""
        scene_id = self._current_scene
        if not scene_id or scene_id == "out_of_scope":
            logger.info("session=%s execute_task skipped: out_of_scope", self.session_id)
            return ""

        self._task_sensitive_authorized = False

        instructions = _load_scene_prompt(scene_id)
        tools = get_scene_tools(scene_id, self.trust_level)
        self._executor = Agent(
            model=DeepSeek(id="deepseek-chat", max_tokens=1024, temperature=0.5),
            session_id=self.session_id,
            tools=tools,
            instructions=instructions,
            markdown=False,
            add_history_to_messages=True,
            num_history_runs=10,
            telemetry=False,
        )

        input_msg = intent_summary
        while True:
            logger.info("session=%s execute_task scene=%s trust=%s input=%r",
                        self.session_id, scene_id, self.trust_level, input_msg)
            response = await self._executor.arun(input_msg)
            last_content = response.content or ""
            stopped_tool = self._get_stopped_tool(response)

            if stopped_tool in _SENSITIVE_TOOLS:
                await self._push_tool_results(response, skip_stopped=stopped_tool)

                field_key = self._get_tool_field_key(response, stopped_tool)

                if stopped_tool == "fill_field_sensitive" and _is_password_field(field_key):
                    logger.info("session=%s password field hard-rejected: %s",
                                self.session_id, field_key)
                    await self._send_fn("agent_reply", {
                        "text": "这步需要您亲手输入密码",
                        "tts_audio_base64": None,
                        "tts_format": "mp3",
                        "requires_confirmation": False,
                        "confirmation_timeout_ms": None,
                    })
                    input_msg = "用户必须自己输入密码，请用 cmd_say 提示后继续后续步骤"
                    continue

                if self.trust_level == "full" and self._task_sensitive_authorized:
                    await self._push_stopped_tool(response, stopped_tool)
                    input_msg = "用户已授权，继续执行"
                    continue

                permission_id = str(uuid.uuid4())
                self._permission_event.clear()
                try:
                    await self._send_fn(
                        "permission_request",
                        self._build_permission_payload(stopped_tool, permission_id),
                    )
                except Exception as exc:
                    logger.error("session=%s permission_request send error: %s",
                                 self.session_id, exc)
                    return ""
                granted = await self.wait_for_permission()
                if granted:
                    await self._push_stopped_tool(response, stopped_tool)
                    if self.trust_level == "full":
                        self._task_sensitive_authorized = True
                    input_msg = "用户已授权，继续执行"
                else:
                    logger.info("session=%s permission denied for %s, skipping field",
                                self.session_id, stopped_tool)
                    input_msg = ("用户拒绝代填该字段，请用 cmd_say 提示用户自己填写，"
                                 "然后继续后续步骤")
                continue

            await self._push_tool_results(response)
            logger.info("session=%s execute_task done content=%s", self.session_id, last_content)
            return last_content or intent_summary

    def set_query_result(self, page_id: str, result_fields: dict) -> None:
        """Called by ws_handler when query_result_ready arrives from frontend."""
        self._query_result = {"page_id": page_id, "result_fields": result_fields}
        self._query_event.set()

    async def broadcast_query_result(self) -> str:
        """Generate an oral summary of the query result via LLM and return the text."""
        result = self._query_result or {}
        result_text = json.dumps(result.get("result_fields", {}), ensure_ascii=False)
        prompt = f"请用口语化方式，简短播报以下查询结果（不超过30字）：{result_text}"

        agent = Agent(
            model=DeepSeek(id="deepseek-chat", max_tokens=256, temperature=0.5),
            session_id=f"{self.session_id}_broadcast",
            markdown=False,
            add_history_to_messages=False,
            telemetry=False,
        )
        response = await agent.arun(prompt)
        return (response.content or result_text).strip()

    async def _push_tool_results(self, response, skip_stopped: str | None = None) -> None:
        """Forward current-round tool call results to the frontend as cmd_* WebSocket messages."""
        import ast
        for msg in (response.messages or []):
            if getattr(msg, "from_history", False):
                continue
            if msg.role != "tool":
                continue
            tool_name = getattr(msg, "tool_name", None)
            if skip_stopped and tool_name == skip_stopped \
                    and getattr(msg, "stop_after_tool_call", False):
                continue
            msg_type = _TOOL_TO_MSG_TYPE.get(tool_name)
            if not msg_type:
                continue
            content = msg.content
            if isinstance(content, dict):
                payload = content
            elif isinstance(content, str):
                try:
                    payload = ast.literal_eval(content)
                except Exception:
                    payload = {}
            else:
                payload = {}
            logger.info("session=%s push tool result: %s %s", self.session_id, msg_type, payload)
            try:
                await self._send_fn(msg_type, payload)
            except Exception as exc:
                logger.error("session=%s push tool result send error: %s", self.session_id, exc)

    async def _push_stopped_tool(self, response, stopped_tool: str) -> None:
        """Push the stopped sensitive tool's result to the frontend (after user authorizes)."""
        import ast
        for msg in (response.messages or []):
            if getattr(msg, "from_history", False):
                continue
            if msg.role != "tool":
                continue
            if not getattr(msg, "stop_after_tool_call", False):
                continue
            if getattr(msg, "tool_name", None) != stopped_tool:
                continue
            msg_type = _TOOL_TO_MSG_TYPE.get(stopped_tool)
            if not msg_type:
                return
            content = msg.content
            if isinstance(content, dict):
                payload = content
            elif isinstance(content, str):
                try:
                    payload = ast.literal_eval(content)
                except Exception:
                    payload = {}
            else:
                payload = {}
            logger.info("session=%s push stopped tool: %s %s", self.session_id, msg_type, payload)
            try:
                await self._send_fn(msg_type, payload)
            except Exception as exc:
                logger.error("session=%s push stopped tool send error: %s", self.session_id, exc)
            return

    def _get_tool_field_key(self, response, tool_name: str) -> str:
        """Extract field_key from a stopped tool's content (used for password detection)."""
        import ast
        for msg in (response.messages or []):
            if getattr(msg, "from_history", False):
                continue
            if msg.role != "tool":
                continue
            if not getattr(msg, "stop_after_tool_call", False):
                continue
            if getattr(msg, "tool_name", None) != tool_name:
                continue
            content = msg.content
            if isinstance(content, dict):
                return content.get("field_key", "") or ""
            if isinstance(content, str):
                try:
                    d = ast.literal_eval(content)
                    return d.get("field_key", "") or ""
                except Exception:
                    return ""
        return ""

    def _get_stopped_tool(self, response) -> str | None:
        """Return the tool_name of the message that caused stop_after_tool_call, or None.

        Only checks current-round messages (from_history=False) to avoid re-triggering
        on historical tool calls that also have stop_after_tool_call=True.
        """
        messages = response.messages or []
        for msg in messages:
            if getattr(msg, "from_history", False):
                continue
            if getattr(msg, "stop_after_tool_call", False):
                tool_name = getattr(msg, "tool_name", None)
                if tool_name:
                    return tool_name
        return None

    def _build_permission_payload(self, tool_name: str, permission_id: str) -> dict:
        meta = _PERMISSION_META.get(tool_name, {
            "permission_type": tool_name,
            "field_label": tool_name,
            "description": f"小浙需要执行 {tool_name}，是否授权？",
        })
        return {
            "permission_id": permission_id,
            "permission_type": meta["permission_type"],
            "field_label": meta["field_label"],
            "description": meta["description"],
            "tts_audio_base64": None,
            "expires_in_ms": 20000,
        }

    def resolve_permission(self, granted: bool) -> None:
        """Called by ws_handler when frontend permission_response arrives."""
        self._permission_granted = granted
        self._permission_event.set()

    async def wait_for_permission(self, timeout: float = 20.0) -> bool:
        """Suspend until frontend responds to a permission_request, with timeout."""
        try:
            await asyncio.wait_for(self._permission_event.wait(), timeout=timeout)
        except asyncio.TimeoutError:
            logger.warning("session=%s permission wait timed out", self.session_id)
            return False
        return self._permission_granted
