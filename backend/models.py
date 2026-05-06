from enum import Enum
from typing import Any
from pydantic import BaseModel


class InboundMessageType(str, Enum):
    agent_wake = "agent_wake"
    audio_chunk = "audio_chunk"
    audio_end = "audio_end"
    user_confirm = "user_confirm"
    permission_response = "permission_response"
    query_result_ready = "query_result_ready"
    text_input = "text_input"


class OutboundMessageType(str, Enum):
    agent_ready = "agent_ready"
    asr_result = "asr_result"
    agent_thinking = "agent_thinking"
    agent_reply = "agent_reply"
    cmd_navigate = "cmd_navigate"
    cmd_highlight = "cmd_highlight"
    cmd_fill_field = "cmd_fill_field"
    permission_request = "permission_request"
    task_done = "task_done"
    agent_error = "agent_error"
    agent_out_of_scope = "agent_out_of_scope"
    asr_listening_ack = "asr_listening_ack"
    cmd_press_button = "cmd_press_button"


# Inbound payload models

class AgentWakePayload(BaseModel):
    session_id: str
    trigger: str
    current_page: str


class AudioChunkPayload(BaseModel):
    session_id: str
    chunk_index: int
    is_last: bool
    audio_base64: str


class AudioEndPayload(BaseModel):
    session_id: str


class UserConfirmPayload(BaseModel):
    session_id: str
    answer: str  # "yes" | "no"
    input_mode: str
    raw_text: str


class PermissionResponsePayload(BaseModel):
    permission_id: str
    granted: bool
    input_mode: str
    raw_text: str


class QueryResultReadyPayload(BaseModel):
    page_id: str
    result_fields: dict


class TextInputPayload(BaseModel):
    session_id: str
    text: str


INBOUND_PAYLOAD_MAP: dict[str, type] = {
    InboundMessageType.agent_wake: AgentWakePayload,
    InboundMessageType.audio_chunk: AudioChunkPayload,
    InboundMessageType.audio_end: AudioEndPayload,
    InboundMessageType.user_confirm: UserConfirmPayload,
    InboundMessageType.permission_response: PermissionResponsePayload,
    InboundMessageType.query_result_ready: QueryResultReadyPayload,
    InboundMessageType.text_input: TextInputPayload,
}


# Outbound payload models

class AgentReadyPayload(BaseModel):
    greeting: str
    draft_hint: str | None
    has_draft: bool
    draft_id: str | None


class AsrResultPayload(BaseModel):
    text: str
    is_final: bool
    confidence: float


class AgentThinkingPayload(BaseModel):
    hint_text: str
    estimated_wait_ms: int


class AgentReplyPayload(BaseModel):
    text: str
    tts_audio_base64: str | None
    tts_format: str
    requires_confirmation: bool
    confirmation_timeout_ms: int | None


class CmdNavigatePayload(BaseModel):
    target_route: str
    transition: str  # "push" | "replace"
    voice_hint: str


class CmdHighlightPayload(BaseModel):
    element_key: str
    highlight_color: str
    pulse: bool
    voice_hint: str
    duration_ms: int


class CmdFillFieldPayload(BaseModel):
    field_key: str
    field_label: str
    value: str
    is_sensitive: bool
    voice_hint: str


class PermissionRequestPayload(BaseModel):
    permission_id: str
    permission_type: str
    field_label: str
    description: str
    tts_audio_base64: str | None
    expires_in_ms: int


class TaskDonePayload(BaseModel):
    scene: str
    summary: str
    voice_hint: str
    tts_audio_base64: str | None
    log_id: str


class AgentErrorPayload(BaseModel):
    error_code: str
    retry_count: int
    max_retries: int
    voice_hint: str
    tts_audio_base64: str | None


class AgentOutOfScopePayload(BaseModel):
    user_intent: str
    scope_type: str
    voice_hint: str
    tts_audio_base64: str | None


class AsrListeningAckPayload(BaseModel):
    session_id: str


class CmdPressButtonPayload(BaseModel):
    button_key: str
    button_label: str
    is_deterministic: bool
    voice_hint: str


# Envelope

class InboundMessage(BaseModel):
    type: str
    payload: dict[str, Any]
    ts: str


class OutboundMessage(BaseModel):
    type: str
    payload: Any
    ts: str
