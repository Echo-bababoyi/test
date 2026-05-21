import asyncio
import logging
import time
import uuid
from enum import Enum
from datetime import datetime, timezone

from fastapi import WebSocket

from backend.models import (
    InboundMessage,
    InboundMessageType,
    INBOUND_PAYLOAD_MAP,
    OutboundMessage,
    AgentReadyPayload,
    AgentReplyPayload,
    AgentOutOfScopePayload,
    AgentErrorPayload,
    AgentThinkingPayload,
    CmdHighlightPayload,
    TaskDonePayload,
    AsrResultPayload,
    AgentChoiceRequestPayload,
)

logger = logging.getLogger(__name__)


class SessionState(str, Enum):
    idle = "idle"
    listening = "listening"
    confirming = "confirming"
    executing = "executing"
    done = "done"


class WSHandler:
    def __init__(self, websocket: WebSocket, session_id: str):
        self.ws = websocket
        self.session_id = session_id
        self.state = SessionState.idle
        self._agent_core = None
        self._pending_intent: dict | None = None
        self._audio_buf: list[bytes] = []
        self._last_activity: float = time.time()

    async def _heartbeat(self):
        """每 30 秒发 ping，并检查空闲超时（5 分钟无操作则关闭连接）。"""
        try:
            while True:
                await asyncio.sleep(30)
                if time.time() - self._last_activity > 300:
                    logger.info("session=%s idle timeout", self.session_id)
                    await self.ws.close(1000, "idle timeout")
                    return
                await self.ws.send_json({
                    "type": "ping",
                    "payload": {},
                    "ts": datetime.now(timezone.utc).isoformat(),
                })
        except Exception:
            pass  # 连接已断开，静默退出

    async def run(self):
        await self.ws.accept()
        logger.info("session=%s connected", self.session_id)
        hb_task = asyncio.create_task(self._heartbeat())
        try:
            while True:
                raw = await self.ws.receive_json()
                if raw.get("type") == "pong":
                    self._last_activity = time.time()
                    continue
                await self._dispatch(raw)
        except Exception as exc:
            logger.info("session=%s disconnected: %s", self.session_id, exc)
        finally:
            hb_task.cancel()
            if self._agent_core:
                self._agent_core.resolve_permission(False)
                self._agent_core = None

    async def _dispatch(self, raw: dict):
        self._last_activity = time.time()
        try:
            msg = InboundMessage(**raw)
            msg_type = msg.type

            payload_cls = INBOUND_PAYLOAD_MAP.get(msg_type)
            payload = payload_cls(**msg.payload) if payload_cls else msg.payload

            handler = {
                InboundMessageType.agent_wake: self._on_agent_wake,
                InboundMessageType.audio_chunk: self._on_audio_chunk,
                InboundMessageType.audio_end: self._on_audio_end,
                InboundMessageType.user_confirm: self._on_user_confirm,
                InboundMessageType.permission_response: self._on_permission_response,
                InboundMessageType.query_result_ready: self._on_query_result_ready,
                InboundMessageType.text_input: self._on_text_input,
                InboundMessageType.page_changed: self._on_page_changed,
            }.get(msg_type)

            if handler:
                await handler(payload)
            else:
                logger.warning("session=%s unknown message type: %s", self.session_id, msg_type)
        except Exception as exc:
            logger.error("session=%s _dispatch error: %s raw=%s", self.session_id, exc, raw)

    async def _on_agent_wake(self, payload):
        logger.info("session=%s agent_wake trigger=%s page=%s trust=%s",
                    self.session_id, payload.trigger, payload.current_page, payload.trust_level)

        from backend.agent_core import AgentCore
        self._agent_core = AgentCore(
            session_id=self.session_id,
            ws_handler=self,
            trust_level=payload.trust_level,
            current_page=payload.current_page,
        )
        self._audio_buf = []
        self.state = SessionState.listening

        await self.send("agent_ready", AgentReadyPayload(
            greeting="您好，我是小浙，有什么可以帮您？",
            draft_hint=None,
            has_draft=False,
            draft_id=None,
        ).model_dump())

    async def _on_page_changed(self, payload):
        logger.info("session=%s page_changed → %s", self.session_id, payload.current_page)
        if self._agent_core:
            self._agent_core.set_current_page(payload.current_page)

    async def _on_text_input(self, payload):
        """直接文本输入（跳过 ASR，用于演示/测试）"""
        logger.info("session=%s text_input text=%r", self.session_id, payload.text)
        self.state = SessionState.confirming
        # 先立即回显用户输入，再异步处理（确保 agent_thinking 能及时推送）
        asyncio.create_task(self.process_asr_text(payload.text))

    async def _on_audio_chunk(self, payload):
        import base64
        self._audio_buf.append(base64.b64decode(payload.audio_base64))

    async def _on_audio_end(self, payload):
        if not self._audio_buf:
            return
        chunks = self._audio_buf[:]
        self._audio_buf = []
        try:
            from backend.asr_adapter import get_asr_adapter
            asr = get_asr_adapter()
            if asr is None:
                await self.send("agent_error", AgentErrorPayload(
                    error_code="asr_not_configured",
                    retry_count=0,
                    max_retries=0,
                    voice_hint="语音识别未配置，请使用文字输入",
                    tts_audio_base64=None,
                ).model_dump())
                return
            text = await asr.recognize(chunks)
            if not text:
                await self.send("agent_error", AgentErrorPayload(
                    error_code="asr_unclear",
                    retry_count=0,
                    max_retries=3,
                    voice_hint="没听清，请再说一遍",
                    tts_audio_base64=None,
                ).model_dump())
                return
            await self.send("asr_result", AsrResultPayload(
                text=text,
                is_final=True,
                confidence=1.0,
            ).model_dump())
            self.state = SessionState.confirming
            asyncio.create_task(self.process_asr_text(text))
        except Exception as exc:
            logger.error("session=%s ASR error: %s", self.session_id, exc)
            await self.send("agent_error", AgentErrorPayload(
                error_code="asr_failed",
                retry_count=0,
                max_retries=1,
                voice_hint="语音识别出错，请再试一次",
                tts_audio_base64=None,
            ).model_dump())

    async def _on_user_confirm(self, payload):
        logger.info("session=%s user_confirm answer=%s mode=%s", self.session_id, payload.answer, payload.input_mode)
        if payload.answer == "yes":
            self.state = SessionState.executing
            if self._agent_core and self._pending_intent:
                asyncio.create_task(self._run_execute(self._pending_intent["intent_summary"]))
        else:
            self.state = SessionState.idle
            self._pending_intent = None

    async def _on_permission_response(self, payload):
        logger.info("session=%s permission_response id=%s granted=%s", self.session_id, payload.permission_id, payload.granted)
        if self._agent_core:
            self._agent_core.resolve_permission(payload.granted)

    async def _on_query_result_ready(self, payload):
        logger.info("session=%s query_result_ready page=%s", self.session_id, payload.page_id)
        if not self._agent_core:
            return
        self._agent_core.set_query_result(payload.page_id, payload.result_fields)
        asyncio.create_task(self._broadcast_query_result())

    async def _broadcast_query_result(self) -> None:
        try:
            summary_text = await self._agent_core.broadcast_query_result()
            await self.send("agent_reply", AgentReplyPayload(
                text=summary_text,
                tts_audio_base64=None,
                tts_format="mp3",
                requires_confirmation=False,
                confirmation_timeout_ms=None,
            ).model_dump())
            await self.send("cmd_highlight", CmdHighlightPayload(
                element_key="result_area",
                highlight_color="#FF6D00",
                pulse=True,
                voice_hint="",
                duration_ms=5000,
            ).model_dump())
            await self._push_task_done(
                scene=self._pending_intent.get("scene_id", "") if self._pending_intent else "",
                summary=summary_text,
            )
            self.state = SessionState.done
        except Exception as exc:
            logger.error("session=%s broadcast_query_result error: %s", self.session_id, exc)

    async def process_asr_text(self, text: str) -> None:
        """Called when final ASR transcript is ready."""
        if not self._agent_core:
            return
        try:
            await self.send("agent_thinking", AgentThinkingPayload(
                hint_text="小浙正在想…",
                estimated_wait_ms=3000,
            ).model_dump())
            try:
                intent = await asyncio.wait_for(
                    self._agent_core.process_text(text), timeout=30.0
                )
            except asyncio.TimeoutError:
                logger.error("session=%s LLM timeout for text=%r", self.session_id, text)
                await self.send("agent_error", AgentErrorPayload(
                    error_code="llm_timeout",
                    retry_count=0,
                    max_retries=1,
                    voice_hint="网络有点慢，请您稍后再试",
                    tts_audio_base64=None,
                ).model_dump())
                self.state = SessionState.listening
                return
            self._pending_intent = intent
            scene_id = intent["scene_id"]

            if scene_id == "out_of_scope":
                self.state = SessionState.idle
                reply_text = intent.get("confirm_text") or "抱歉，这个功能暂时帮不到您"
                await self.send("agent_out_of_scope", AgentOutOfScopePayload(
                    user_intent=intent["intent_summary"],
                    scope_type="not_supported",
                    voice_hint=reply_text,
                    tts_audio_base64=None,
                ).model_dump())
                return

            if scene_id == "login_choose":
                self.state = SessionState.listening
                self._pending_intent = None
                prompt_text = intent.get("confirm_text") or "您想用刷脸登录还是验证码登录？"
                await self.send("agent_choice_request", AgentChoiceRequestPayload(
                    text=prompt_text,
                    options=[
                        {"value": "刷脸登录", "label": "刷脸登录"},
                        {"value": "验证码登录", "label": "验证码登录"},
                    ],
                ).model_dump())
                return

            self.state = SessionState.confirming
            confirm_text = intent["confirm_text"]
            await self.send("agent_reply", AgentReplyPayload(
                text=confirm_text,
                tts_audio_base64=None,
                tts_format="mp3",
                requires_confirmation=True,
                confirmation_timeout_ms=15000,
            ).model_dump())
        except Exception as exc:
            logger.error("session=%s process_asr_text error: %s", self.session_id, exc)
            await self.send("agent_error", AgentErrorPayload(
                error_code="AGENT_PROCESS_FAILED",
                retry_count=0,
                max_retries=2,
                voice_hint="处理失败，请再试一次",
                tts_audio_base64=None,
            ).model_dump())

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
                await self._push_task_done(
                    scene=self._pending_intent.get("scene_id", "") if self._pending_intent else "",
                    summary=summary,
                )
            self.state = SessionState.done
        except Exception as exc:
            logger.error("session=%s execute_task error: %s", self.session_id, exc)
            self.state = SessionState.idle
            await self.send("agent_error", AgentErrorPayload(
                error_code="AGENT_EXECUTE_FAILED",
                retry_count=0,
                max_retries=2,
                voice_hint="执行失败，请再试一次",
                tts_audio_base64=None,
            ).model_dump())

    async def _push_task_done(self, scene: str, summary: str) -> None:
        await self.send("task_done", TaskDonePayload(
            scene=scene,
            summary=summary,
            voice_hint=summary,
            tts_audio_base64=None,
            log_id=str(uuid.uuid4()),
        ).model_dump())

    async def _tts_to_b64(self, text: str) -> str | None:
        if not text:
            return None
        try:
            from backend.tts_adapter import get_tts_adapter
            adapter = get_tts_adapter()
            audio_bytes = await adapter.synthesize(text)
            if audio_bytes:
                import base64
                return base64.b64encode(audio_bytes).decode()
        except Exception as exc:
            logger.warning("session=%s TTS failed: %s", self.session_id, exc)
        return None

    async def send(self, msg_type: str, payload):
        out = OutboundMessage(
            type=msg_type,
            payload=payload,
            ts=datetime.now(timezone.utc).isoformat(),
        )
        await self.ws.send_text(out.model_dump_json())
