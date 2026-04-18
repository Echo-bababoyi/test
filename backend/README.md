# zlb-elder-agent · 后端服务

浙里办长辈版智能代理后端（Phase 3 FastAPI + WebSocket）。

## 快速启动

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install fastapi "uvicorn[standard]" websockets python-dotenv pydantic httpx
cp .env.example .env   # Step 4+ 才需要填 API Key
uvicorn app.main:app --reload --port 8000
```

## 验证

```bash
# Step 1：健康检查
curl http://localhost:8000/health
# → {"status":"ok","service":"zlb-elder-agent","version":"0.1.0"}

# Step 2：WebSocket echo（需要 wscat：npm i -g wscat）
wscat -c ws://localhost:8000/ws/test_session
> {"type":"user_utterance","session_id":"test_session","ts":"2026-04-18T10:00:00Z","text":"你好","source":"text"}
# ← {"type":"agent_utterance","text":"你说的是：你好",...}

# 或用 Python 客户端
python3 - <<'EOF'
import asyncio, json, websockets
async def t():
    async with websockets.connect("ws://localhost:8000/ws/test") as ws:
        await ws.recv()   # session_created
        await ws.send(json.dumps({"type":"user_utterance","session_id":"test","ts":"2026-04-18T00:00:00Z","text":"你好","source":"text"}))
        print(json.loads(await ws.recv()))
asyncio.run(t())
EOF
```

## Swagger UI

服务启动后访问 <http://localhost:8000/docs>

## 目录结构

```
backend/
├── app/
│   ├── main.py          # FastAPI 入口 + /health + CORS
│   ├── ws_handler.py    # WebSocket /ws/{session_id} + echo 逻辑
│   ├── schemas.py       # Pydantic v2 — §2.2 全部 11 种消息类型
│   └── agent/           # Step 3+ Agno Agent（待实现）
├── tests/               # Step 3+ 集成测试（待实现）
├── .env.example         # API Key 模板
├── .gitignore
└── pyproject.toml
```

## 环境变量

| 变量 | 必填 | 说明 |
|---|---|---|
| `DEEPSEEK_API_KEY` | Step 4+ | DeepSeek-V3 API Key |
| `USE_LLM` | 否 | `true`（默认）或 `false`（强制走硬编码规则） |
| `CORS_ORIGINS` | 否 | 逗号分隔的前端 origin，默认含 localhost:5000/3000 |

## 阶段进度

| Step | 状态 | 说明 |
|---|---|---|
| Step 1 | ✅ | FastAPI 骨架 + `/health` |
| Step 2 | ✅ | WebSocket + schemas + echo |
| Step 3 | ✅ | Agno 硬编码规则 Agent + 14 单元测试 |
| Step 4 | ✅ | DeepSeek-V3 LLM + fallback + token 日志 |
| Step 5 | 🔲 | 接百度 ASR |
| Step 6 | 🔲 | 接讯飞 TTS |
| Step 7 | 🔲 | CORS 精调 + 文档完善 |
