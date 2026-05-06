import logging

from fastapi import FastAPI, WebSocket
from fastapi.middleware.cors import CORSMiddleware

from backend.ws_handler import WSHandler

logging.basicConfig(level=logging.INFO)

app = FastAPI(title="xiaozhe-backend")

app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"http://localhost(:\d+)?",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

_active_sessions: set[str] = set()


@app.get("/health")
async def health():
    return {"status": "ok"}


@app.get("/api/status")
async def status():
    return {
        "status": "ok",
        "active_sessions": len(_active_sessions),
        "session_ids": list(_active_sessions),
    }


@app.websocket("/ws/session/{session_id}")
async def ws_session(websocket: WebSocket, session_id: str):
    _active_sessions.add(session_id)
    try:
        handler = WSHandler(websocket, session_id)
        await handler.run()
    finally:
        _active_sessions.discard(session_id)
