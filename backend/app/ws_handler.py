import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.schemas import (
    AgentUtterance,
    SessionControlOut,
    UserUtterance,
    SessionControlIn,
    parse_inbound,
)

logger = logging.getLogger(__name__)
router = APIRouter()


def _now() -> datetime:
    return datetime.now(timezone.utc)


@router.websocket("/ws/{session_id}")
async def ws_endpoint(ws: WebSocket, session_id: str):
    await ws.accept()
    logger.info("WS connected: session=%s", session_id)

    # 发 session_created 确认
    await ws.send_json(
        SessionControlOut(
            session_id=session_id,
            ts=_now(),
            action="session_created",
            payload={"server_session_id": str(uuid.uuid4())},
        ).model_dump(mode="json")
    )

    try:
        while True:
            raw = await ws.receive_json()

            try:
                msg = parse_inbound(raw)
            except Exception as exc:
                logger.warning("unrecognised message: %s — %s", raw.get("type"), exc)
                continue

            if isinstance(msg, UserUtterance):
                reply = AgentUtterance(
                    session_id=session_id,
                    ts=_now(),
                    text=f"你说的是：{msg.text}",
                    is_partial=False,
                )
                await ws.send_json(reply.model_dump(mode="json"))

            elif isinstance(msg, SessionControlIn) and msg.action == "heartbeat":
                await ws.send_json(
                    SessionControlOut(
                        session_id=session_id,
                        ts=_now(),
                        action="heartbeat_ack",
                    ).model_dump(mode="json")
                )

            else:
                logger.info("unhandled type=%s (session=%s)", msg.type, session_id)

    except WebSocketDisconnect:
        logger.info("WS disconnected: session=%s", session_id)
