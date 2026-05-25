---
name: reference-ports
description: 前后端本地启动标准流程 + 端口约定 — 后端 8080 / 前端 3081（3080 有浏览器缓存污染）
metadata:
  type: reference
---

## 端口约定

- **后端**（FastAPI）：`localhost:8080`
- **前端**（Flutter Web）：`localhost:3081`（3080 有浏览器 Service Worker 缓存污染，已弃用）
- WS 客户端连接地址：`ws://localhost:8080/ws/session/`

## 本地启动标准流程

**重要**：启动前必须先阅读 docs/DEPLOY.md 确认命令。参考 [[feedback-deploy-first]]

**1. 后端**（从项目根目录执行）：
```bash
backend/.venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080
```

**2. 前端**（必须用 release build，debug 模式会白屏）：
```bash
cd app && ../bin/flutter build web --release
cd build/web && python3 -m http.server 3081
```

**3. 确认启动成功**：
```bash
curl -s http://localhost:8080/health   # 后端应返回 {"status":"ok"}
curl -s -o /dev/null -w "%{http_code}" http://localhost:3081/   # 前端应返回 200
```

## 关闭服务

只关自己本次启动的进程，不宽泛 grep kill。参考 [[feedback_coding]] "关闭服务只杀自己启动的进程"。
```bash
lsof -i :8080 -i :3081 2>/dev/null | grep LISTEN | awk '{print $2}' | sort -u | xargs -r kill
```
