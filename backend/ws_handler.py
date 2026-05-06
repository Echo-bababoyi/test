import logging
from enum import Enum
from datetime import datetime, timezone

from fastapi import WebSocket

from backend.models import (
    InboundMessage,
    InboundMessageType,
    INBOUND_PAYLOAD_MAP,
    OutboundMessage,
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

    async def run(self):
        await self.ws.accept()
        logger.info("session=%s connected", self.session_id)
        try:
            while True:
                raw = await self.ws.receive_json()
                await self._dispatch(raw)
        except Exception as exc:
            logger.info("session=%s disconnected: %s", self.session_id, exc)

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
        }.get(msg_type)

        if handler:
            await handler(payload)
        else:
            logger.warning("session=%s unknown message type: %s", self.session_id, msg_type)

    async def _on_agent_wake(self, payload):
        logger.info("session=%s agent_wake trigger=%s page=%s", self.session_id, payload.trigger, payload.current_page)
        self.state = SessionState.listening

    async def _on_audio_chunk(self, payload):
        logger.info("session=%s audio_chunk index=%d is_last=%s", self.session_id, payload.chunk_index, payload.is_last)

    async def _on_audio_end(self, payload):
        logger.info("session=%s audio_end", self.session_id)
        self.state = SessionState.confirming

    async def _on_user_confirm(self, payload):
        logger.info("session=%s user_confirm answer=%s mode=%s", self.session_id, payload.answer, payload.input_mode)
        self.state = SessionState.executing if payload.answer == "yes" else SessionState.idle

    async def _on_permission_response(self, payload):
        logger.info("session=%s permission_response id=%s granted=%s", self.session_id, payload.permission_id, payload.granted)

    async def _on_query_result_ready(self, payload):
        logger.info("session=%s query_result_ready page=%s", self.session_id, payload.page_id)

    async def send(self, msg_type: str, payload):
        out = OutboundMessage(
            type=msg_type,
            payload=payload,
            ts=datetime.now(timezone.utc).isoformat(),
        )
        await self.ws.send_text(out.model_dump_json())
