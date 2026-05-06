import asyncio
import base64
import logging
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

    async def run(self):
        await self.ws.accept()
        logger.info("session=%s connected", self.session_id)
        try:
            while True:
                raw = await self.ws.receive_json()
                await self._dispatch(raw)
        except Exception as exc:
            logger.info("session=%s disconnected: %s", self.session_id, exc)
        finally:
            if self._agent_core:
                self._agent_core.resolve_permission(False)  # 释放可能挂起的 HITL
                self._agent_core = None

    async def _dispatch(self, raw: dict):
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
        }.get(msg_type)

        if handler:
            await handler(payload)
        else:
            logger.warning("session=%s unknown message type: %s", self.session_id, msg_type)

    async def _on_agent_wake(self, payload):
        logger.info("session=%s agent_wake trigger=%s page=%s", self.session_id, payload.trigger, payload.current_page)

        from backend.agent_core import AgentCore
        self._agent_core = AgentCore(session_id=self.session_id, ws_handler=self)
        self._audio_buf = []
        self.state = SessionState.listening

        await self.send("agent_ready", AgentReadyPayload(
            greeting="您好，我是小浙，有什么可以帮您？",
            draft_hint=None,
            has_draft=False,
            draft_id=None,
        ).model_dump())

    async def _on_text_input(self, payload):
        """直接文本输入（跳过 ASR，用于演示/测试）"""
        logger.info("session=%s text_input text=%r", self.session_id, payload.text)
        self.state = SessionState.confirming
        await self.send("asr_result", AsrResultPayload(
            text=payload.text,
            is_final=True,
            confidence=1.0,
        ).model_dump())
        await self.process_asr_text(payload.text)

    async def _on_audio_chunk(self, payload):
        logger.info("session=%s audio_chunk index=%d is_last=%s", self.session_id, payload.chunk_index, payload.is_last)
        raw_bytes = base64.b64decode(payload.audio_base64)
        self._audio_buf.append(raw_bytes)

    async def _on_audio_end(self, payload):
        logger.info("session=%s audio_end chunks=%d", self.session_id, len(self._audio_buf))
        self.state = SessionState.confirming

        chunks = list(self._audio_buf)
        self._audio_buf = []

        from backend.asr_adapter import get_asr_adapter
        asr = get_asr_adapter()
        if asr and chunks:
            try:
                text = await asr.recognize(chunks)
                logger.info("session=%s asr_result text=%r", self.session_id, text)
            except Exception as exc:
                logger.error("session=%s asr error: %s", self.session_id, exc)
                text = ""
        else:
            text = ""

        if text:
            await self.process_asr_text(text)
        else:
            logger.warning("session=%s asr returned empty text", self.session_id)
            self.state = SessionState.listening
            await self.send("agent_error", AgentErrorPayload(
                error_code="asr_unclear",
                retry_count=0,
                max_retries=3,
                voice_hint="不好意思没听清，您再说一遍",
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
            tts_b64 = await self._tts_to_b64(summary_text)
            await self.send("agent_reply", AgentReplyPayload(
                text=summary_text,
                tts_audio_base64=tts_b64,
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
                await self.send("agent_thinking", AgentThinkingPayload(
                    hint_text="小浙正在想…",
                    estimated_wait_ms=2000,
                ).model_dump())
                reply_text = await self._agent_core.handle_out_of_scope(intent["intent_summary"])
                tts_b64 = await self._tts_to_b64(reply_text)
                await self.send("agent_out_of_scope", AgentOutOfScopePayload(
                    user_intent=intent["intent_summary"],
                    scope_type="not_supported",
                    voice_hint=reply_text,
                    tts_audio_base64=tts_b64,
                ).model_dump())
                return

            self.state = SessionState.confirming
            confirm_text = intent["confirm_text"]
            tts_b64 = await self._tts_to_b64(confirm_text)
            await self.send("agent_reply", AgentReplyPayload(
                text=confirm_text,
                tts_audio_base64=tts_b64,
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
        tts_b64 = await self._tts_to_b64(summary)
        await self.send("task_done", TaskDonePayload(
            scene=scene,
            summary=summary,
            voice_hint=summary,
            tts_audio_base64=tts_b64,
            log_id=str(uuid.uuid4()),
        ).model_dump())

    async def _tts_to_b64(self, text: str) -> str | None:
        """Synthesize text and return base64-encoded mp3, or None on failure."""
        from backend.tts_adapter import get_tts_adapter
        try:
            tts = get_tts_adapter()
            audio_bytes = await tts.synthesize(text)
            return base64.b64encode(audio_bytes).decode() if audio_bytes else None
        except Exception as exc:
            logger.error("session=%s tts error: %s", self.session_id, exc)
            return None

    async def send(self, msg_type: str, payload):
        out = OutboundMessage(
            type=msg_type,
            payload=payload,
            ts=datetime.now(timezone.utc).isoformat(),
        )
        await self.ws.send_text(out.model_dump_json())
