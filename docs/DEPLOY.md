# 本地开发部署指南

## 前置条件

### 操作系统

- ✅ Linux（推荐 Ubuntu 22.04+）
- ✅ macOS（Intel / Apple Silicon）
- ⚠️ Windows：推荐 WSL2，原生不支持（`bin/flutter` 是 bash 脚本）

### 依赖

- **Python 3.10+**（项目验证用 3.12）：`python3 --version  # 应 ≥ 3.10，推荐 3.12`
- **DeepSeek API Key**（见后端启动第 3 步获取方式）

### Flutter SDK（首次须自行获取）

SDK 约 2.3 GB，体积过大未提交至 git。首次 clone 后须将 SDK 放至项目根 `flutter/` 目录（与 `backend/`、`app/` 并列）。

**方式 A — 官方下载（国内镜像）**

前往 `https://flutter.cn/docs/get-started/install` 选择对应系统，下载 stable 最新 3.x 版本，解压后将 `flutter/` 目录移到本项目根目录。

**方式 B — 从团队共享盘复制**

将共享盘中的 `flutter/` 目录直接复制到项目根即可。

**验证**

```bash
./bin/flutter --version  # 应输出 Flutter 3.x.x stable
```

> macOS / Windows(WSL2)：若提示权限不足，先运行 `chmod +x flutter/bin/flutter flutter/bin/dart`

## 后端启动

```bash
# 1. 创建虚拟环境（首次）
python3 -m venv backend/.venv

# 2. 安装依赖
backend/.venv/bin/pip install -r backend/requirements.txt

# 3. 配置环境变量
cp backend/.env.example backend/.env
# 编辑 backend/.env 填入 DEEPSEEK_API_KEY 等
#
# 获取 DeepSeek API Key：
#   1. 前往 https://platform.deepseek.com 注册
#   2. 控制台 → API Keys → 创建新 Key
#   3. 免费额度对本地开发足够
#   注意：服务偶有过载，遇 503 等几分钟重试

# 4. 从项目根目录启动（重要：必须从项目根启动，不是 backend/ 目录）
backend/.venv/bin/python -m uvicorn backend.main:app --host 0.0.0.0 --port 8080
```

验证：`curl http://localhost:8080/health` 应返回 `{"status":"ok"}`

## 启动方式（两个终端并行）

前后端各占一个终端，同时运行：

- **终端 1**：后端 uvicorn（见上一节）
- **终端 2**：前端 flutter run / 静态服务（见本节）
- **终端 3**（可选）：日志观察 / curl 验证

---

## 前端启动

```bash
# 从 app/ 目录运行
cd app

# 首次：拉取依赖
../bin/flutter pub get

# 构建 release 产物
../bin/flutter build web --release

# 启动静态服务
cd build/web
python3 -m http.server 3080
```

访问：`http://localhost:3080`

> **注意**：debug 模式（`flutter run`）在本项目会白屏，必须用 release build。开发时改完代码需重新 `flutter build web --release`。

## 跑通验证

启动前后端后，按以下步骤确认全链路通：

1. **后端 HTTP**：`curl http://localhost:8080/health` → 返回 `{"status":"ok"}`
2. **前端打开**：浏览器访问 `http://localhost:3080`，看到浙里办闪屏 → 跳标准首页
3. **WS 连通**：进入长辈版，点右下角橙色悬浮助手（AgentFab），聊天窗正常展开，无"未连接"提示
4. **LLM 通**：在输入框输入"你好"，1-2 秒内收到小浙回复（若出现 503 说明 DeepSeek 过载，等几分钟重试）
5. **跨页面**：切到标准版观察 FAB 为蓝色，再切长辈版变橙色；F5 刷新后颜色仍保持

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

## 常见问题

**pip install 很慢**

```bash
backend/.venv/bin/pip install -i https://pypi.tuna.tsinghua.edu.cn/simple -r backend/requirements.txt
```

**flutter pub get 卡住 / 超时**

确认 `PUB_HOSTED_URL` 和 `FLUTTER_STORAGE_BASE_URL` 未被环境变量覆盖；`./bin/flutter` 包装脚本已内置国内镜像，直接用包装脚本不要调用系统 flutter。

**端口被占用**

```bash
# 查看占用
lsof -i :8080   # 后端
lsof -i :3080   # 前端
# 换端口：修改启动命令的 --port 参数，两端保持一致
```

**DeepSeek 返回 503 / 过载**

等 5-10 分钟后重试；免费额度不影响，是服务端临时过载。

**AgentFab 显示"未连接"**

- 确认后端已启动且 `/health` 正常
- 若在另一台机器访问，参考"跨机访问"小节，必须用内网 IP 而非 localhost
