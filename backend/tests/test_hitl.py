"""
HITL 权限流程测试：医保缴费场景（yibao_jiaofei）

流程：agent_wake → text_input("帮我缴医保") → user_confirm(yes)
     → cmd_fill_field (普通字段×3) → permission_request
     → permission_response(granted=true/false) → 后续执行 → task_done / 已取消

分两个子测试：
  1. test_hitl_granted  — 授权通过，期望最终 task_done
  2. test_hitl_denied   — 拒绝授权，期望后端回复"好的，已取消"
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
    ws = MagicMock()
    ws.accept = AsyncMock()

    async def fake_send_text(data: str):
        msg = json.loads(data)
        sent_messages.append(msg)
        print(f"  OUT [{msg['type']}]", json.dumps(msg["payload"], ensure_ascii=False)[:140])

    ws.send_text = fake_send_text
    return ws


def _ts():
    return datetime.now(timezone.utc).isoformat()


async def _wake_and_text_input(handler, session_id: str, sent: list, text: str):
    """公共步骤：agent_wake + text_input + 断言到 agent_reply(requires_confirmation)。"""
    await handler._dispatch({
        "type": "agent_wake",
        "payload": {"session_id": session_id, "trigger": "user_tap", "current_page": "home"},
        "ts": _ts(),
    })
    assert any(m["type"] == "agent_ready" for m in sent), "缺少 agent_ready"
    print("  PASS: agent_ready")

    before = len(sent)
    await handler._dispatch({
        "type": "text_input",
        "payload": {"session_id": session_id, "text": text},
        "ts": _ts(),
    })
    new = sent[before:]
    assert any(m["type"] == "asr_result" for m in new), f"缺少 asr_result，实际: {[m['type'] for m in new]}"
    reply = next((m for m in new if m["type"] == "agent_reply"), None)
    assert reply and reply["payload"]["requires_confirmation"], "缺少 agent_reply(requires_confirmation)"
    print(f"  PASS: asr_result + agent_reply 收到，复述: {reply['payload']['text'][:40]}")


async def _wait_for_permission_request(sent: list, timeout: float = 90.0) -> dict | None:
    """轮询直到 permission_request 出现，返回该消息，超时返回 None。"""
    deadline = asyncio.get_event_loop().time() + timeout
    last_len = len(sent)
    elapsed = 0
    while asyncio.get_event_loop().time() < deadline:
        await asyncio.sleep(0.5)
        elapsed += 0.5
        if int(elapsed) % 10 == 0:
            print(f"  (等待中 {int(elapsed)}s，已收到 {len(sent)} 条消息...)")
        new = sent[last_len:]
        last_len = len(sent)
        for m in new:
            if m["type"] == "permission_request":
                return m
    return None


async def _wait_for_type(sent: list, msg_type: str, after_idx: int, timeout: float = 90.0) -> dict | None:
    """等待 sent[after_idx:] 中出现指定类型的消息。"""
    deadline = asyncio.get_event_loop().time() + timeout
    elapsed = 0
    while asyncio.get_event_loop().time() < deadline:
        await asyncio.sleep(0.5)
        elapsed += 0.5
        if int(elapsed) % 10 == 0:
            print(f"  (等待中 {int(elapsed)}s，当前类型: {[m['type'] for m in sent[after_idx:]]})")
        for m in sent[after_idx:]:
            if m["type"] == msg_type:
                return m
    return None


# ─── 子测试 1：授权通过 ────────────────────────────────────────────────────────

async def test_hitl_granted():
    print("\n" + "="*60)
    print("test_hitl_granted: 授权通过，期望 task_done")
    print("="*60)

    from backend.ws_handler import WSHandler

    sent: list[dict] = []
    session_id = "test-hitl-granted-001"
    handler = WSHandler(websocket=_make_ws(sent), session_id=session_id)
    await handler.ws.accept()

    print("\n--- Step 1+2: agent_wake + text_input ---")
    await _wake_and_text_input(handler, session_id, sent, "帮我缴医保")

    print("\n--- Step 3: user_confirm(yes) ---")
    confirm_before = len(sent)
    await handler._dispatch({
        "type": "user_confirm",
        "payload": {"session_id": session_id, "answer": "yes", "input_mode": "text", "raw_text": "确认"},
        "ts": _ts(),
    })
    # execute_task 以 create_task 异步运行，先让它跑一段

    print("\n--- Step 4: 等待 permission_request ---")
    perm_msg = await _wait_for_permission_request(sent, timeout=40.0)
    assert perm_msg is not None, "超时未收到 permission_request"
    p = perm_msg["payload"]
    print(f"  permission_request: type={p.get('permission_type')} desc={p.get('description')[:40]}")
    assert p.get("permission_type") == "fill_sensitive_field", \
        f"permission_type 错误: {p.get('permission_type')}"
    assert p.get("permission_id"), "permission_id 为空"
    print("  PASS: permission_request 正确推送")

    print("\n--- Step 5: permission_response(granted=true) ---")
    after_perm_idx = len(sent)
    await handler._dispatch({
        "type": "permission_response",
        "payload": {"permission_id": p["permission_id"], "granted": True, "input_mode": "text", "raw_text": "同意"},
        "ts": _ts(),
    })

    print("\n--- Step 6: 等待 task_done ---")
    task_done = await _wait_for_type(sent, "task_done", after_perm_idx, timeout=40.0)
    assert task_done is not None, \
        f"超时未收到 task_done，收到: {[m['type'] for m in sent[after_perm_idx:]]}"
    summary = task_done["payload"].get("summary", "")
    assert summary, "task_done summary 为空"
    print(f"  task_done summary: {summary[:60]}")
    print("  PASS: task_done 收到，HITL 授权流程完整")

    # 额外验证：确认出现过 cmd_fill_field
    all_types = [m["type"] for m in sent[confirm_before:]]
    fill_msgs = [m for m in sent[confirm_before:] if m["type"] == "cmd_fill_field"]
    print(f"  cmd_fill_field 共 {len(fill_msgs)} 条: {[m['payload'].get('field_key') for m in fill_msgs]}")

    print("\n[test_hitl_granted PASSED]")


# ─── 子测试 2：拒绝授权 ────────────────────────────────────────────────────────

async def test_hitl_denied():
    print("\n" + "="*60)
    print("test_hitl_denied: 拒绝授权，期望'好的，已取消'")
    print("="*60)

    from backend.ws_handler import WSHandler

    sent: list[dict] = []
    session_id = "test-hitl-denied-001"
    handler = WSHandler(websocket=_make_ws(sent), session_id=session_id)
    await handler.ws.accept()

    print("\n--- Step 1+2: agent_wake + text_input ---")
    await _wake_and_text_input(handler, session_id, sent, "帮我缴医保")

    print("\n--- Step 3: user_confirm(yes) ---")
    await handler._dispatch({
        "type": "user_confirm",
        "payload": {"session_id": session_id, "answer": "yes", "input_mode": "text", "raw_text": "确认"},
        "ts": _ts(),
    })

    print("\n--- Step 4: 等待 permission_request ---")
    perm_msg = await _wait_for_permission_request(sent, timeout=40.0)
    assert perm_msg is not None, "超时未收到 permission_request"
    p = perm_msg["payload"]
    print(f"  permission_request 收到: type={p.get('permission_type')}")

    print("\n--- Step 5: permission_response(granted=false) ---")
    after_deny_idx = len(sent)
    await handler._dispatch({
        "type": "permission_response",
        "payload": {"permission_id": p["permission_id"], "granted": False, "input_mode": "text", "raw_text": "拒绝"},
        "ts": _ts(),
    })

    print("\n--- Step 6: 等待取消回复 ---")
    # 期望收到 agent_reply(text 含"已取消")
    cancel_reply = await _wait_for_type(sent, "agent_reply", after_deny_idx, timeout=15.0)
    assert cancel_reply is not None, \
        f"超时未收到取消 agent_reply，收到: {[m['type'] for m in sent[after_deny_idx:]]}"
    cancel_text = cancel_reply["payload"].get("text", "")
    print(f"  取消回复: {cancel_text}")
    assert "取消" in cancel_text, f"取消回复文本不含'取消': {cancel_text}"
    print("  PASS: 拒绝授权后正确回复'好的，已取消'")

    print("\n[test_hitl_denied PASSED]")


# ─── 入口 ──────────────────────────────────────────────────────────────────────

async def main():
    await test_hitl_granted()
    await test_hitl_denied()
    print("\n\n=== 全部 HITL 测试通过 ===")


if __name__ == "__main__":
    asyncio.run(main())
