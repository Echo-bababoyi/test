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
cat > backend/.env << 'EOF'
DEEPSEEK_API_KEY=sk-your-key-here
TTS_BACKEND=edge
XUNFEI_APP_ID=
XUNFEI_API_KEY=
XUNFEI_API_SECRET=
EOF

# 4. 从项目根目录启动（重要：必须从项目根启动，不是 backend/ 目录）
backend/.venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8000
```

验证：`curl http://localhost:8000/health` 应返回 `{"status":"ok"}`

## 前端启动

```bash
# 从 app/ 目录运行
cd app
../bin/flutter run -d web-server --web-port=3000 --web-hostname=0.0.0.0
```

访问：`http://localhost:3000`

## 页面路由

| 路由 | 页面 |
|------|------|
| `/` | 标准首页 |
| `/elder` | 长者模式首页 |
| `/login` | 登录页 |
| `/login/face` | 刷脸认证 |
| `/login/verify` | 验证码登录 |
| `/elder/yibao-jiaofei` | 医保缴费 |
| `/elder/yibao-query` | 医保查询 |
| `/elder/pension-query` | 养老金查询 |
| `/elder/shebao-jiaona` | 社保缴纳 |
| `/elder/shebao-query` | 社保查询 |
| `/elder/search` | 搜索 |
| `/elder/search-result` | 搜索结果 |
| `/elder/mine` | 我的 |
| `/elder/operation-logs` | 操作日志 |
| `/elder/drafts` | 草稿箱 |

## 注意事项

- 后端必须从**项目根目录**启动（`backend/main.py` 使用 `from backend.xxx` 的包导入方式）
- Flutter 必须从 **`app/` 目录**运行
- Flutter SDK 使用项目内 `./bin/flutter`，不要用系统全局 Flutter
- Web Speech API（麦克风语音识别）在非 localhost 环境需要 HTTPS
