# 本地开发部署指南

## 前置条件

- Python 3.12+
- Flutter SDK（项目自带，位于 `flutter/`，通过 `./bin/flutter` 调用）
- DeepSeek API Key（写入 `backend/.env`）

## 后端启动

```bash
# 1. 创建虚拟环境（首次）
python3 -m venv backend/.venv

# 2. 安装依赖
backend/.venv/bin/pip install -r backend/requirements.txt

# 3. 配置环境变量
cp backend/.env.example backend/.env
# 编辑 backend/.env 填入 DEEPSEEK_API_KEY 等

# 4. 从项目根目录启动（重要：必须从项目根启动，不是 backend/ 目录）
backend/.venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080
```

验证：`curl http://localhost:8080/health` 应返回 `{"status":"ok"}`

## 前端启动

```bash
# 从 app/ 目录运行
cd app

# 首次：拉取依赖
../bin/flutter pub get

../bin/flutter run -d web-server --web-port=3080 --web-hostname=0.0.0.0
```

访问：`http://localhost:3080`

## 页面路由

| 路由 | 页面 |
|------|------|
| `/` | 闪屏页 |
| `/home` | 标准首页 |
| `/elder` | 长辈首页 |
| `/login` | 登录页 |
| `/login/face` | 刷脸认证 |
| `/login/verify` | 验证码登录 |
| `/search` | 搜索 |
| `/search/result` | 搜索结果 |
| `/my` | 我的 |
| `/service/shebao-jiaona` | 社保费缴纳 |
| `/service/shebao-query` | 社保查询 |
| `/service/pension-query` | 养老金查询 |
| `/service/yibao-hub` | 医保 Hub |
| `/service/yibao-jiaofei` | 医保缴费 |
| `/service/yibao-query` | 医保查询 |
| `/service/yibao-jiaofei/confirm` | 缴费确认 |
| `/service/yibao-jiaofei/pay` | 支付密码 |
| `/service/yibao-jiaofei/result` | 缴费结果 |
| `/elder/operation-logs` | 操作日志 |
| `/elder/drafts` | 草稿箱 |
| `/elder/agent-settings` | 小浙助手设置 |
| `/wireframe/0` ~ `/wireframe/5` | 线框图（论文插图，6 个界面） |

## 注意事项

- 后端必须从**项目根目录**启动（`backend/main.py` 使用 `from backend.xxx` 的包导入方式）
- Flutter 必须从 **`app/` 目录**运行
- Flutter SDK 使用项目内 `./bin/flutter`，不要用系统全局 Flutter
- TTS 默认走 Edge TTS；若配齐 `XUNFEI_APP_ID` / `API_KEY` / `API_SECRET` 自动切换讯飞
- Web Speech API（麦克风语音识别）在非 localhost 环境需要 HTTPS。当前阶段麦克风功能尚未接入（N1 任务），主要走文本输入

### 跨机访问

前端 WS 地址从浏览器当前 URL 的 `hostname` 动态推导。若前后端跑在同一台机器、浏览器在**另一台机器**上访问时：

- **必须用后端机器的内网 IP** 访问前端（如 `http://192.168.x.x:3080`），**不能用 `localhost:3080`**
- 原因：`localhost` 在浏览器里指向用户自己的机器，会导致 WS 连不到后端
- 查看后端机器 IP：`ip a` 或 `hostname -I`

## 人脸验证（MediaPipe）

- 资源已本地化在 `app/web/mediapipe/`（`face_landmarker.task` + `vision_bundle.mjs` + `wasm/`）
- 部署 / 复制项目时确保该目录完整保留，否则刷脸登录页会失败
