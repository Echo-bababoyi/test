"""
端到端测试：agent_wake → text_input → user_confirm(yes) → cmd_navigate/cmd_press_button

使用 Edge TTS（无需讯飞 Key）。不启动 HTTP 服务器，直接驱动 WSHandler。
"""
import asyncio
import json
import sys
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock

sys.path.insert(0, ".")

from dotenv import load_dotenv
load_dotenv("backend/.env")


def _make_ws(sent_messages: list):
    """构造一个记录所有发出消息的假 WebSocket。"""
    ws = MagicMock()
    ws.accept = AsyncMock()

    async def fake_send_text(data: str):
        msg = json.loads(data)
        sent_messages.append(msg)
        print(f"  OUT [{msg['type']}]", json.dumps(msg["payload"], ensure_ascii=False)[:120])

    ws.send_text = fake_send_text
    return ws


def _ts():
    return datetime.now(timezone.utc).isoformat()


async def run_e2e():
    from backend.ws_handler import WSHandler

    sent: list[dict] = []
    ws = _make_ws(sent)
    session_id = "test-e2e-001"
    handler = WSHandler(websocket=ws, session_id=session_id)
    await ws.accept()

    print("\n=== Step 1: agent_wake ===")
    await handler._dispatch({
        "type": "agent_wake",
        "payload": {"session_id": session_id, "trigger": "user_tap", "current_page": "home"},
        "ts": _ts(),
    })
    types_so_far = [m["type"] for m in sent]
    assert "agent_ready" in types_so_far, f"期望 agent_ready，实际: {types_so_far}"
    print("  PASS: agent_ready 收到")

    print("\n=== Step 2: text_input ===")
    before = len(sent)
    await handler._dispatch({
        "type": "text_input",
        "payload": {"session_id": session_id, "text": "帮我查养老金"},
        "ts": _ts(),
    })
    new_msgs = sent[before:]
    new_types = [m["type"] for m in new_msgs]
    assert "asr_result" in new_types, f"期望 asr_result，实际: {new_types}"
    asr_msg = next(m for m in new_msgs if m["type"] == "asr_result")
    assert asr_msg["payload"]["text"] == "帮我查养老金", "asr_result text 不匹配"
    assert asr_msg["payload"]["confidence"] == 1.0, "asr_result confidence 不匹配"
    assert "agent_reply" in new_types, f"期望 agent_reply，实际: {new_types}"
    agent_reply = next(m for m in new_msgs if m["type"] == "agent_reply")
    assert agent_reply["payload"]["requires_confirmation"] is True, "agent_reply 应要求确认"
    tts_b64 = agent_reply["payload"].get("tts_audio_base64")
    assert tts_b64 and len(tts_b64) > 100, "agent_reply 缺少 TTS 音频"
    print("  PASS: asr_result + agent_reply(含TTS) 收到")

    print("\n=== Step 3: user_confirm(yes) ===")
    before = len(sent)
    await handler._dispatch({
        "type": "user_confirm",
        "payload": {"session_id": session_id, "answer": "yes", "input_mode": "text", "raw_text": "确认"},
        "ts": _ts(),
    })
    # execute_task 是 asyncio.create_task，等它完成
    await asyncio.sleep(15)
    new_msgs = sent[before:]
    new_types = [m["type"] for m in new_msgs]
    print(f"  收到消息类型: {new_types}")
    nav_or_btn = [t for t in new_types if t in ("cmd_navigate", "cmd_press_button", "task_done", "agent_error")]
    assert nav_or_btn, f"期望 cmd_navigate/cmd_press_button/task_done，实际: {new_types}"
    print(f"  PASS: 执行阶段消息收到 {nav_or_btn}")

    print("\n=== 全部通过 ===")


if __name__ == "__main__":
    asyncio.run(run_e2e())
