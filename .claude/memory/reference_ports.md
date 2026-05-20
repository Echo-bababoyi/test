---
name: reference-ports
description: 前后端本地启动/关闭标准流程 + 端口约定 — 后端 8080 / 前端 3080
metadata:
  type: reference
---

## 本地启动标准流程（从项目根目录执行）

**1. 后端**（FastAPI，端口 8080）：
```bash
source backend/.venv/bin/activate && python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080
```
- 必须从**项目根目录**执行（import 路径为 `backend.ws_handler`，在 backend/ 下执行会报 `ModuleNotFoundError`）
- 必须先激活 venv

**2. 前端**（Flutter Web，端口 3080）：
```bash
cd app && ../bin/flutter run -d web-server --web-port=3080 --web-hostname=0.0.0.0
```
- 必须从 **app/** 目录执行（pubspec.yaml 在 app/ 下）
- 必须用 `-d web-server`（服务器无 X display，`-d chrome` 会失败）
- 使用 `run_in_background` 时**不要**管道 `| head -N`，截断会导致进程退出

**3. 确认启动成功（必做，不能跳过）**：
启动命令用 `run_in_background` 后，必须用 `ss -tlnp | grep -E '3080|8080'` 确认端口在监听后才能告诉用户"已就绪"。不要说"启动中等一下"就完事——必须验证。
```bash
ss -tlnp | grep -E '3080|8080'   # 确认进程在监听
curl -s http://localhost:8080/health   # 后端应返回 {"status":"ok"}
```

**4. 先检查端口再启动**：
```bash
ss -tlnp | grep -E '3080|8080'
```
如果端口已被占用，说明服务已在运行，不需要重复启动。

## 关闭服务

```bash
# 查找进程
ss -tlnp | grep -E '3080|8080'
# 按 pid 关闭
kill <backend_pid> <frontend_pid>
```

## 端口约定

- **后端**（FastAPI）：`localhost:8080`
- **前端**（Flutter Web）：`localhost:3080`
- WS 客户端连接地址：`ws://localhost:8080/ws/session/`
