---
name: feedback-deploy-first
description: 启动前后端服务前必须先查 docs/DEPLOY.md，不可凭印象启动
metadata:
  type: feedback
---

启动前后端服务前，必须先阅读 docs/DEPLOY.md 确认启动方式，不可凭记忆或猜测启动。

**Why:** 2026-05-22 会话 17，team-lead 凭印象用 `python -m backend.main` 和 `flutter run -d chrome` 启动，两个都错了（后端应用 uvicorn，前端必须 release build 不能 flutter run debug）。用户明确纠正。

**How to apply:** 每次需要启停服务时，先 Read docs/DEPLOY.md 对应章节，照文档命令执行。关键点：
- 后端：`backend/.venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080`（从项目根启动）
- 前端：`cd app && ../bin/flutter build web --release && cd build/web && python3 -m http.server 3080`（debug 模式会白屏）
- 参考 [[reference_ports]]：后端 8080 / 前端 3080
