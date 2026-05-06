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

logger = logging.getLogger(__name__)

_PROMPTS_DIR = Path(__file__).parent / "prompts"

SCENE_TOOLS = {
    "login_face": [cmd_navigate, cmd_highlight],
    "login_verify": [cmd_navigate, cmd_highlight, fill_field_normal, read_sms],
    "yibao_jiaofei": [cmd_navigate, cmd_highlight, fill_field_normal, fill_field_sensitive],
    "pension_query": [cmd_navigate, cmd_highlight, fill_field_normal, cmd_press_button],
    "yibao_query": [cmd_navigate, cmd_highlight, fill_field_normal, cmd_press_button],
}

SCENE_PROMPTS = {
    "login_face": "scene_login_face.txt",
    "login_verify": "scene_login_verify.txt",
    "yibao_jiaofei": "scene_yibao_jiaofei.txt",
    "pension_query": "scene_pension_query.txt",
    "yibao_query": "scene_yibao_query.txt",
}

_SENSITIVE_TOOLS = {"fill_field_sensitive", "read_sms"}

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
}


def _load_scene_prompt(scene_id: str) -> str:
    filename = SCENE_PROMPTS.get(scene_id)
    if filename:
        scene_text = (_PROMPTS_DIR / filename).read_text(encoding="utf-8")
    else:
        scene_text = f"帮用户完成：{scene_id}。按步骤调用工具完成任务，不要闲聊。"
    return _EXECUTOR_PREFIX + scene_text


class AgentCore:
    def __init__(self, session_id: str, ws_handler):
        self.session_id = session_id
        self.ws = ws_handler
        self._send_fn: Callable[..., Coroutine[Any, Any, None]] = ws_handler.send
        self._current_scene: str | None = None
        self._permission_event: asyncio.Event = asyncio.Event()
        self._permission_granted: bool = False
        # Pending query results forwarded from ws_handler
        self._query_result: dict | None = None
        self._query_event: asyncio.Event = asyncio.Event()

        self._classifier = Agent(
            model=DeepSeek(id="deepseek-chat"),
            session_id=f"{session_id}_cls",
            instructions=_INTENT_PROMPT,
            markdown=False,
            add_history_to_messages=False,
        )

        self._rephraser = Agent(
            model=DeepSeek(id="deepseek-chat"),
            session_id=f"{session_id}_rph",
            instructions=_CONFIRM_PROMPT,
            markdown=False,
            add_history_to_messages=False,
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
            model=DeepSeek(id="deepseek-chat"),
            session_id=f"{self.session_id}_oos",
            instructions=_OUT_OF_SCOPE_PROMPT,
            markdown=False,
            add_history_to_messages=False,
        )
        response = await agent.arun(user_input)
        return (response.content or "抱歉，这个功能暂时帮不到您").strip()

    async def execute_task(self, intent_summary: str) -> str:
        """Execute the task for the classified scene with HITL loop for sensitive tools.

        Returns a one-line summary for task_done.
        """
        scene_id = self._current_scene
        if not scene_id or scene_id == "out_of_scope":
            logger.info("session=%s execute_task skipped: out_of_scope", self.session_id)
            return ""

        instructions = _load_scene_prompt(scene_id)
        tools = SCENE_TOOLS.get(scene_id, [cmd_navigate, cmd_highlight])
        self._executor = Agent(
            model=DeepSeek(id="deepseek-chat"),
            session_id=self.session_id,
            tools=tools,
            instructions=instructions,
            markdown=False,
            add_history_to_messages=True,
            num_history_runs=10,
        )

        input_msg = intent_summary
        last_content = ""
        while True:
            logger.info("session=%s execute_task scene=%s input=%r", self.session_id, scene_id, input_msg)
            response = await self._executor.arun(input_msg)
            last_content = response.content or ""

            await self._push_tool_results(response)

            stopped_tool = self._get_stopped_tool(response)
            if stopped_tool in _SENSITIVE_TOOLS:
                permission_id = str(uuid.uuid4())
                self._permission_event.clear()  # clear before send so resolve_permission cannot race
                await self._send_fn(
                    "permission_request",
                    self._build_permission_payload(stopped_tool, permission_id),
                )
                granted = await self.wait_for_permission()
                if not granted:
                    logger.info("session=%s permission denied for %s", self.session_id, stopped_tool)
                    await self._send_fn("agent_reply", {
                        "text": "好的，已取消",
                        "tts_audio_base64": None,
                        "tts_format": "mp3",
                        "requires_confirmation": False,
                        "confirmation_timeout_ms": None,
                    })
                    return "已取消"
                input_msg = "用户已授权，继续执行"
            else:
                logger.info("session=%s execute_task done content=%s", self.session_id, last_content)
                break

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
            model=DeepSeek(id="deepseek-chat"),
            session_id=f"{self.session_id}_broadcast",
            markdown=False,
            add_history_to_messages=False,
        )
        response = await agent.arun(prompt)
        return (response.content or result_text).strip()

    async def _push_tool_results(self, response) -> None:
        """Forward current-round tool call results to the frontend as cmd_* WebSocket messages."""
        import ast
        for msg in (response.messages or []):
            if getattr(msg, "from_history", False):
                continue
            if msg.role != "tool":
                continue
            tool_name = getattr(msg, "tool_name", None)
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
            await self._send_fn(msg_type, payload)

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
