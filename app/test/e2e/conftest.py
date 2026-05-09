"""
公共 fixtures：假 WebSocket、dispatch 封装、消息断言帮助函数。

测试不启动 HTTP 服务器，直接驱动 WSHandler._dispatch()，
通过 asyncio.Queue 捕获后端发出的所有消息。

运行方式（从项目根目录）：
    python -m pytest app/test/e2e/ -v
"""
import asyncio
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import AsyncGenerator
from unittest.mock import AsyncMock, MagicMock

import pytest
import pytest_asyncio

# 将项目根加入 sys.path，使 backend 包可导入
sys.path.insert(0, str(Path(__file__).resolve().parents[3]))

from dotenv import load_dotenv
load_dotenv(Path(__file__).resolve().parents[3] / "backend" / ".env")


# ---------------------------------------------------------------------------
# FakeWs：记录并入队所有后端发出的消息
# ---------------------------------------------------------------------------

class FakeWs:
    """伪造的 WebSocket，把后端 send_text 写入 Queue，供测试消费。"""

    def __init__(self):
        self.sent: list[dict] = []
        self._queue: asyncio.Queue[dict] = asyncio.Queue()
        mock = MagicMock()
        mock.accept = AsyncMock()

        async def _send_text(data: str):
            msg = json.loads(data)
            self.sent.append(msg)
            await self._queue.put(msg)

        mock.send_text = _send_text
        self.mock = mock

    async def wait_for(self, msg_type: str, timeout: float = 30.0) -> dict:
        """阻塞直到收到指定类型的消息（跳过其他类型）。"""
        deadline = asyncio.get_event_loop().time() + timeout
        while True:
            remaining = deadline - asyncio.get_event_loop().time()
            if remaining <= 0:
                received = [m["type"] for m in self.sent]
                raise TimeoutError(
                    f"超时：等待 '{msg_type}'，已收到: {received}"
                )
            try:
                msg = await asyncio.wait_for(self._queue.get(), timeout=min(remaining, 1.0))
            except asyncio.TimeoutError:
                continue
            if msg["type"] == msg_type:
                return msg
            # 其他类型消息打印出来便于调试，继续等

    async def drain_until(self, msg_type: str, timeout: float = 60.0) -> dict:
        """等待指定类型消息，同时把所有消息消费掉（避免 Queue 满）。"""
        return await self.wait_for(msg_type, timeout=timeout)

    def last_of(self, msg_type: str) -> dict | None:
        """从已收到的消息列表中找最后一条指定类型的消息。"""
        for m in reversed(self.sent):
            if m["type"] == msg_type:
                return m
        return None

    def types(self) -> list[str]:
        return [m["type"] for m in self.sent]


# ---------------------------------------------------------------------------
# 公共帮助函数
# ---------------------------------------------------------------------------

def ts() -> str:
    return datetime.now(timezone.utc).isoformat()


def make_handler(fake_ws: FakeWs, session_id: str):
    """创建 WSHandler（不调用 run()，避免心跳任务干扰）。"""
    from backend.ws_handler import WSHandler
    handler = WSHandler(websocket=fake_ws.mock, session_id=session_id)
    return handler


async def do_wake(handler, fake_ws: FakeWs, session_id: str,
                  current_page: str = "/elder") -> dict:
    """公共前置：发 agent_wake，等 agent_ready。"""
    await handler._dispatch({
        "type": "agent_wake",
        "payload": {
            "session_id": session_id,
            "trigger": "button",
            "current_page": current_page,
        },
        "ts": ts(),
    })
    return await fake_ws.wait_for("agent_ready", timeout=10)


async def do_text_input(handler, fake_ws: FakeWs, session_id: str,
                        text: str) -> dict:
    """发 text_input（替代 ASR），等 agent_reply。"""
    await handler._dispatch({
        "type": "text_input",
        "payload": {"session_id": session_id, "text": text},
        "ts": ts(),
    })
    await fake_ws.wait_for("asr_result", timeout=10)
    return await fake_ws.wait_for("agent_reply", timeout=30)


async def do_confirm(handler, fake_ws: FakeWs, session_id: str,
                     answer: str = "yes") -> None:
    """发 user_confirm。yes → 触发 asyncio.create_task 执行任务。"""
    await handler._dispatch({
        "type": "user_confirm",
        "payload": {
            "session_id": session_id,
            "answer": answer,
            "input_mode": "touch",
            "raw_text": "对的" if answer == "yes" else "不是",
        },
        "ts": ts(),
    })


async def do_permission_response(handler, fake_ws: FakeWs, session_id: str,
                                 permission_id: str, granted: bool) -> None:
    """发 permission_response。"""
    await handler._dispatch({
        "type": "permission_response",
        "payload": {
            "permission_id": permission_id,
            "granted": granted,
            "input_mode": "touch",
            "raw_text": "可以" if granted else "不行",
        },
        "ts": ts(),
    })


# ---------------------------------------------------------------------------
# pytest fixtures
# ---------------------------------------------------------------------------

@pytest_asyncio.fixture
async def session():
    """提供 (handler, fake_ws, session_id) 三元组，测试结束后清理。"""
    import uuid
    session_id = f"e2e-{uuid.uuid4().hex[:8]}"
    fake_ws = FakeWs()
    handler = make_handler(fake_ws, session_id)
    yield handler, fake_ws, session_id
    # 清理：关闭 permission_event，防止后台任务挂起
    if handler._agent_core:
        handler._agent_core.resolve_permission(False)
