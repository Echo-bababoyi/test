import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.agent.agno_agent import hardcoded_dispatch
from app.schemas import (
    AgentUtterance,
    IntentProposal,
    IntentData,
    SessionControlIn,
    SessionControlOut,
    UserUtterance,
    parse_inbound,
)

logger = logging.getLogger(__name__)
router = APIRouter()


def _now() -> datetime:
    return datetime.now(timezone.utc)


async def _handle_user_utterance(ws: WebSocket, msg: UserUtterance) -> None:
    sid = msg.session_id
    result = hardcoded_dispatch(msg.text)

    if result is None:
        await ws.send_json(
            AgentUtterance(
                session_id=sid,
                ts=_now(),
                text="我暂时听不懂，换种说法试试？",
                is_partial=False,
            ).model_dump(mode="json")
        )
        return

    intent_type = result["intent_type"]
    params = result["params"]
    reason = result.get("reason", "")

    if intent_type == "ExplainTerm":
        explanation = params.get("explanation", "")
        await ws.send_json(
            AgentUtterance(
                session_id=sid,
                ts=_now(),
                text=explanation,
                is_partial=False,
            ).model_dump(mode="json")
        )
        return

    # NavigateTo / SwitchMode → 先说明，再发 intent_proposal
    await ws.send_json(
        AgentUtterance(
            session_id=sid,
            ts=_now(),
            text=f"好的，{reason}，请点确认。",
            is_partial=False,
        ).model_dump(mode="json")
    )

    # path 提取出来，其余参数放 extra
    intent_data = IntentData(
        action=intent_type,
        path=params.get("path"),
        extra={k: v for k, v in params.items() if k != "path"},
    )
    await ws.send_json(
        IntentProposal(
            session_id=sid,
            ts=_now(),
            proposal_id=str(uuid.uuid4()),
            description=reason,
            intent=intent_data,
            requires_auth=True,
            timeout_sec=30,
        ).model_dump(mode="json")
    )


@router.websocket("/ws/{session_id}")
async def ws_endpoint(ws: WebSocket, session_id: str):
    await ws.accept()
    logger.info("WS connected: session=%s", session_id)

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
                await _handle_user_utterance(ws, msg)

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
