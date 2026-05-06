import logging
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.agent.agno_agent import dispatch
from app.schemas import (
    AgentUtterance,
    IntentData,
    IntentProposal,
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
    result = await dispatch(msg.text, sid)

    tool_result: dict | None = result["tool_result"]
    agent_text: str = result["agent_text"]

    if tool_result is None:
        # LLM 纯文本回复 or fallback 都没命中 → 发文本
        fallback_text = agent_text or "我暂时听不懂，换种说法试试？"
        await ws.send_json(
            AgentUtterance(
                session_id=sid,
                ts=_now(),
                text=fallback_text,
                is_partial=False,
            ).model_dump(mode="json")
        )
        return

    intent_type = tool_result["intent_type"]
    params = tool_result["params"]
    reason = tool_result.get("reason", "")

    if intent_type == "ExplainTerm":
        explanation = params.get("explanation", agent_text or reason)
        await ws.send_json(
            AgentUtterance(
                session_id=sid,
                ts=_now(),
                text=explanation,
                is_partial=False,
            ).model_dump(mode="json")
        )
        return

    # NavigateTo / SwitchMode → agent_utterance 预告 + intent_proposal
    announce = agent_text if agent_text else f"好的，{reason}，请点确认。"
    await ws.send_json(
        AgentUtterance(
            session_id=sid,
            ts=_now(),
            text=announce,
            is_partial=False,
        ).model_dump(mode="json")
    )

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
