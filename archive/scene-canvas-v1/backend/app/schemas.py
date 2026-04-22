from __future__ import annotations

from datetime import datetime
from typing import Any, Literal, Union

from pydantic import BaseModel, Field


# ── 公共基类 ──────────────────────────────────────────────────────────────────

class BaseMsg(BaseModel):
    type: str
    session_id: str
    ts: datetime


# ── 前端 → 服务端 ─────────────────────────────────────────────────────────────

class UserUtterance(BaseMsg):
    type: Literal["user_utterance"] = "user_utterance"
    text: str
    source: Literal["text", "voice"] = "text"


class VoiceInput(BaseMsg):
    type: Literal["voice_input"] = "voice_input"
    audio_b64: str
    format: Literal["pcm", "wav"] = "pcm"
    sample_rate: int = 16000
    is_final: bool


class UserAction(BaseMsg):
    type: Literal["user_action"] = "user_action"
    action: Literal["authorize", "deny", "abort"]
    proposal_id: str | None = None


class SessionControlIn(BaseMsg):
    type: Literal["session_control"] = "session_control"
    action: Literal["heartbeat", "resume"]
    last_ts: datetime | None = None


# ── 服务端 → 前端 ─────────────────────────────────────────────────────────────

class AgentUtterance(BaseMsg):
    type: Literal["agent_utterance"] = "agent_utterance"
    text: str
    tts_audio_b64: str | None = None
    is_partial: bool = False


class IntentData(BaseModel):
    action: str
    path: str | None = None
    extra: dict[str, Any] = Field(default_factory=dict)


class IntentProposal(BaseMsg):
    type: Literal["intent_proposal"] = "intent_proposal"
    proposal_id: str
    description: str
    intent: IntentData
    requires_auth: bool = True
    timeout_sec: int = 30


class IntentExecute(BaseMsg):
    type: Literal["intent_execute"] = "intent_execute"
    proposal_id: str
    intent: IntentData


class ProgressUpdate(BaseMsg):
    type: Literal["progress_update"] = "progress_update"
    text: str
    stage: Literal["executing", "done", "error"]
    done: bool = False
    error_message: str | None = None


class IntentResult(BaseMsg):
    type: Literal["intent_result"] = "intent_result"
    proposal_id: str
    success: bool
    summary: str
    undo_available: bool = False
    undo_expires_at: datetime | None = None


class ClarificationOption(BaseModel):
    label: str
    value: str


class ClarificationRequest(BaseMsg):
    type: Literal["clarification_request"] = "clarification_request"
    text: str
    options: list[ClarificationOption] = Field(default_factory=list)


class SessionControlOut(BaseMsg):
    type: Literal["session_control"] = "session_control"
    action: Literal["session_created", "heartbeat_ack", "session_expired", "rate_limited"]
    payload: dict[str, Any] = Field(default_factory=dict)


# ── 解析入口 ──────────────────────────────────────────────────────────────────

InboundMsg = Union[UserUtterance, VoiceInput, UserAction, SessionControlIn]


def parse_inbound(raw: dict[str, Any]) -> InboundMsg:
    msg_type = raw.get("type", "")
    mapping: dict[str, type[InboundMsg]] = {
        "user_utterance": UserUtterance,
        "voice_input": VoiceInput,
        "user_action": UserAction,
        "session_control": SessionControlIn,
    }
    cls = mapping.get(msg_type)
    if cls is None:
        raise ValueError(f"unknown message type: {msg_type!r}")
    return cls.model_validate(raw)
