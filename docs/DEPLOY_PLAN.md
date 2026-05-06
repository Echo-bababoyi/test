# 手机真实体验落地计划

> **版本**：v1.1（2026-05-06）
> **作者**：architect
> **目标**：让真实用户能在手机上体验小浙应用，用于毕业设计答辩演示
> **前置状态**：后端 FastAPI localhost:8000 正常；Flutter Web build 通过；DeepSeek 意图分类 + Edge TTS + HITL 均已验证

---

## 需要提前准备的资源

| 资源 | 获取方式 | 预计耗时 | 备注 |
|---|---|---|---|
| 云服务器（2C2G 以上） | 阿里云/腾讯云/华为云学生优惠，约 ¥30-60/月 | 1 小时 | 首选上海/杭州节点，延迟最优 |
| 域名（可选） | 阿里云注册，约 ¥10-50/年 | 1 天（备案） | 如不用自定义域名可用 IP + 自签证书（仅 Android 可行，iOS 不可） |
| HTTPS 证书 | 免费：Let's Encrypt（需域名）；或 Nginx 自签（仅 Android） | 30 分钟 | **必须有 HTTPS，否则 Chrome 不给麦克风权限** |
| 讯飞账号 | open.xfyun.cn 注册，实名认证，开通实时语音转写 + 语音合成 | 1-2 个工作日（审核） | **提前申请**；审核期间用 Edge TTS + Web Speech API 兜底 |
| DeepSeek API Key | platform.deepseek.com 注册 | 即时 | 已有可跳过 |

---

## 阶段 A — 手机可访问（部署上线）

### A1 · 服务器购买与基础环境配置

| 属性 | 值 |
|---|---|
| **归属** | 后端/全栈 |
| **依赖** | 无（起点） |
| **预估工时** | 1-2 小时 |

**内容**：
- 购买云服务器（推荐配置：2C2G，Ubuntu 22.04 LTS，带宽 3-5 Mbps）
- 安装依赖：`python3.11`、`pip`、`nginx`、`certbot`（Let's Encrypt 客户端）
- 配置防火墙：开放 80（HTTP/Let's Encrypt 验证）、443（HTTPS）、8000（可选，调试用，上线后关闭）
- 创建非 root 部署用户，避免以 root 运行服务

```bash
# 服务器初始化参考命令
apt update && apt install -y python3.11 python3.11-venv nginx certbot python3-certbot-nginx
```

---

### A2 · 后端部署

| 属性 | 值 |
|---|---|
| **归属** | 后端 |
| **依赖** | A1 |
| **预估工时** | 2-3 小时 |

**内容**：

**1. 上传代码**

```bash
# 本地执行，将 backend/ 上传到服务器
rsync -av --exclude __pycache__ --exclude .env backend/ user@server:/app/backend/
```

**2. 环境变量管理**

在服务器上创建 `/app/backend/.env`（**不要**提交到 git）：

```
DEEPSEEK_API_KEY=sk-xxx
XUNFEI_APP_ID=xxx
XUNFEI_API_KEY=xxx
XUNFEI_API_SECRET=xxx
TTS_BACKEND=edge          # 讯飞审核期间先用 edge
ALLOWED_ORIGINS=https://your-domain.com
```

**安全要求**：`.env` 文件权限设为 `chmod 600`，只有部署用户可读。

**3. 安装依赖并启动**

```bash
cd /app/backend
python3.11 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
# 以 systemd 服务运行，保证重启后自动拉起
```

**4. systemd 服务配置**（`/etc/systemd/system/xiaozhe.service`）

```ini
[Unit]
Description=Xiaozhe Backend
After=network.target

[Service]
User=deploy
WorkingDirectory=/app/backend
EnvironmentFile=/app/backend/.env
ExecStart=/app/backend/venv/bin/uvicorn main:app --host 127.0.0.1 --port 8000
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
```

```bash
systemctl enable xiaozhe && systemctl start xiaozhe
```

**5. CORS 配置**（`backend/main.py` 补充）

```python
from fastapi.middleware.cors import CORSMiddleware
import os

app.add_middleware(
    CORSMiddleware,
    allow_origins=[os.getenv("ALLOWED_ORIGINS", "http://localhost:3000")],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

### A3 · HTTPS 与 Nginx 配置

| 属性 | 值 |
|---|---|
| **归属** | 后端/全栈 |
| **依赖** | A1、A2 |
| **预估工时** | 1-2 小时 |

**内容**：

**Nginx 配置**（`/etc/nginx/sites-available/xiaozhe`）：

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate     /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;

    # Flutter Web 静态文件
    root /app/web;
    index index.html;
    location / {
        try_files $uri $uri/ /index.html;   # SPA fallback
    }

    # WebSocket 代理到后端
    location /ws/ {
        proxy_pass http://127.0.0.1:8000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_read_timeout 3600s;           # WebSocket 长连接不能超时过短
    }
}
```

```bash
# 申请 Let's Encrypt 证书（需域名已解析到服务器 IP）
certbot --nginx -d your-domain.com
# 证书自动续期（certbot 已自动配置 cron）
```

**若无域名（仅 Android 演示）**：使用 IP 访问，用 mkcert 生成自签证书，Android 可通过安装证书信任；iOS Safari 对自签证书限制严格，不推荐。

---

### A4 · 前端部署（Web PWA 或 Android APK 二选一）

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **依赖** | Web 路径：A1、A3；APK 路径：无 |
| **预估工时** | Web 1 小时；APK 1-2 小时 |

**方案对比**：

| 维度 | PWA（Web） | APK（Android） |
|---|---|---|
| 麦克风 | 必须 HTTPS | 原生权限，不需要 HTTPS |
| 域名/证书 | 必须 | 不需要 |
| 安装方式 | 浏览器"添加到主屏幕" | 直接安装 APK |
| 体验 | 像网页 | 像真实 APP |
| 后端访问 | 需公网地址 | 局域网 IP 也行 |
| iOS 支持 | 有（Safari） | 无（APK 仅限 Android） |

**建议策略**：
- 开发/内测阶段 → APK + 局域网后端（0 成本，最快验证）
- 答辩演示 → APK + 云服务器后端（稳定可靠）
- 备选 → PWA 保留，没有 Android 设备时用浏览器访问

---

#### A4-Web · Flutter Web 部署（PWA 路径）

**1. 配置 WebSocket 地址（生产/开发双配置）**

修改 `app/lib/services/ws_client.dart`：

```dart
// 当前硬编码 ws://localhost:8000，改为可配置
static const _baseUrl = String.fromEnvironment(
  'WS_BASE_URL',
  defaultValue: 'ws://localhost:8000/ws/session/',
);
```

**2. Build 命令**（从项目根执行）

```bash
./bin/flutter build web \
  --dart-define=WS_BASE_URL=wss://your-domain.com/ws/session/ \
  --release
```

**3. 上传静态文件**

```bash
rsync -av app/build/web/ user@server:/app/web/
```

**4. PWA 支持**（Flutter Web 默认已生成 `manifest.json` 和 `service-worker.js`）

确认 `app/web/manifest.json` 中 `display: "standalone"` 已设置，手机用户通过浏览器"添加到主屏幕"可获得类 App 体验。

---

#### A4-APK · Flutter Android APK 构建（APK 路径）

**前提检查**：`flutter create` 时若仅指定了 `--platforms web`，需先补充 Android 平台支持：

```bash
# 从项目根执行，在 app/ 目录下补充 Android 平台
cd app && ../bin/flutter create . --platforms android
```

执行后 `app/android/` 目录会自动生成。

**1. 声明麦克风权限**

编辑 `app/android/app/src/main/AndroidManifest.xml`，在 `<manifest>` 标签内添加：

```xml
<uses-permission android:name="android.permission.RECORD_AUDIO"/>
<uses-permission android:name="android.permission.INTERNET"/>
```

**2. 配置 WebSocket 地址**

与 Web 路径相同，修改 `ws_client.dart` 使用 `String.fromEnvironment`（已在 A4-Web 中完成，共用代码）。

**3. Build APK**（从项目根执行）

```bash
# 局域网测试：后端跑在本机，手机连同一 WiFi
./bin/flutter build apk --release \
  --dart-define=WS_BASE_URL=ws://192.168.x.x:8000/ws/session/

# 云服务器演示：后端已部署到服务器（ws 改 wss）
./bin/flutter build apk --release \
  --dart-define=WS_BASE_URL=wss://your-domain.com/ws/session/
```

产物路径：`app/build/app/outputs/flutter-apk/app-release.apk`

**4. 安装到 Android 手机**

```bash
# 方式一：adb 安装（手机开启 USB 调试）
adb install app/build/app/outputs/flutter-apk/app-release.apk

# 方式二：传文件安装（无需 adb）
# 将 app-release.apk 通过微信/QQ/文件传输发到手机，手机端打开安装
# 需要在手机设置中开启"允许安装未知来源应用"
```

**注意**：使用 debug 签名即可安装测试，无需上架 Google Play，不需要正式签名证书。

**5. 局域网后端访问要求**

APK 路径下若后端跑在本机（局域网）：
- 手机与电脑连接**同一 WiFi**
- 后端 uvicorn 启动时监听 `0.0.0.0`（而非 `127.0.0.1`）：

```bash
# backend/ 本地启动命令改为
uvicorn main:app --host 0.0.0.0 --port 8000
```

- 防火墙开放 8000 端口（Windows：控制面板入站规则；Linux/Mac：`ufw allow 8000`）
- 查询本机局域网 IP：`ip addr`（Linux/Mac）或 `ipconfig`（Windows）

**6. APK 麦克风权限说明**

APK 安装后首次点击麦克风按钮，Android 系统会弹出"允许使用麦克风"权限弹窗，用户授权后即可录音。不受 HTTPS 限制，HTTP 局域网连接同样可以使用麦克风。

---

### A5 · 冒烟验证（手机访问测试）

| 属性 | 值 |
|---|---|
| **归属** | 全栈 |
| **依赖** | A3、A4 |
| **预估工时** | 30 分钟 |

**验收清单**：
- [ ] Android Chrome 打开 `https://your-domain.com` 能加载首页
- [ ] iOS Safari 打开同 URL 能加载首页
- [ ] WebSocket 连接正常（唤醒小浙，后台日志出现 `agent_wake`）
- [ ] 点击按钮跳转页面正常
- [ ] 浏览器控制台无 Mixed Content 警告（ws 必须用 wss）

---

## 阶段 B — 语音交互打通

### B1 · 前端麦克风录音实现

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **依赖** | A4 |
| **预估工时** | 3-4 小时 |

**方案选择**：

| 方案 | 兼容性 | 复杂度 | 推荐 |
|---|---|---|---|
| `getUserMedia` + `ScriptProcessorNode`（已废弃但兼容性好） | Android/iOS 均可 | 低 | 备选（iOS Safari 15 以下） |
| `getUserMedia` + `AudioWorklet`（现代标准） | Android Chrome、iOS Safari 16.4+ | 中 | **推荐** |
| Flutter 插件（`flutter_sound` / `record`） | Web 支持有限 | 低 | 不推荐（Web 支持不完整） |

**推荐实现路径**（Flutter Web 通过 `dart:js_interop` 调用 Web API）：

```dart
// app/lib/services/audio_recorder.dart
// 通过 js_interop 调用浏览器 getUserMedia + AudioWorklet
// 采样率 16000 Hz，单声道，16-bit PCM
// 每 100ms 采集一帧，base64 编码后发送 audio_chunk 消息
```

**音频参数**：

```
采样率：16000 Hz（讯飞 ASR 要求）
声道：1（单声道）
格式：PCM 16-bit little-endian
分帧：每帧 1280 字节（40ms @ 16kHz）= audio_chunk 间隔约 40ms
base64 编码后通过 WebSocket 发送
```

**iOS Safari 特殊处理**：
- iOS Safari 要求用户手势触发 `AudioContext` 初始化（不能在页面加载时自动初始化）
- 麦克风按钮的 `onTap` 回调中初始化 `AudioContext`
- iOS Safari 16.4 以下不支持 `AudioWorklet`，需降级到 `ScriptProcessorNode`

---

### B2 · 讯飞 ASR 接入前置步骤

| 属性 | 值 |
|---|---|
| **归属** | 后端 |
| **依赖** | B1（接入后才能端到端验证） |
| **预估工时** | 2-3 小时（不含审核等待） |

**前置步骤（需提前完成）**：

1. 访问 [open.xfyun.cn](https://open.xfyun.cn) 注册账号并实名认证
2. 创建应用，开通"实时语音转写"服务
3. 获取 `APPID`、`APIKey`、`APISecret`，写入服务器 `.env`
4. 免费额度：500 小时/年，毕设用量远低于此

**后端 ASR 适配器接入要点**（已在 `backend/asr_adapter.py` 中实现，需配置 Key）：

- 讯飞 ASR 使用服务端 WebSocket 协议（前端不直连讯飞，音频流经后端转发）
- 鉴权方式：HMAC-SHA256 签名，在请求 URL 中携带（避免 Key 暴露到前端）
- 讯飞返回中间结果和最终结果，后端转发 `asr_result`（`is_final=false/true`）到前端

**B2 备选方案（审核期间）**：

| 备选 | 说明 |
|---|---|
| **Web Speech API**（浏览器原生） | Chrome 内置，无需 Key，识别率中等；HTTPS 必须；用于演示期紧急兜底 |
| **阿里云 ASR** | 接口类似讯飞，注册即可用（无审核），准确率接近讯飞；`XUNFEI_*` 环境变量改名即可切换 |

---

### B3 · HTTPS 对麦克风权限的要求

| 属性 | 值 |
|---|---|
| **归属** | 全栈 |
| **依赖** | A3 |
| **预估工时** | 已在 A3 覆盖，此处为核查清单 |

**Chrome 麦克风权限规则**：
- `localhost`：**允许**麦克风（开发环境可用）
- `http://非localhost`：**拒绝**麦克风（页面提示"不安全连接"）
- `https://任意域名`：**允许**麦克风（必须有有效 SSL 证书）

**行动项**：
- [ ] 确认 A3 中 Let's Encrypt 证书已正确配置
- [ ] 确认 `wss://`（WebSocket over TLS）而非 `ws://` 用于生产环境（已在 A4 的 build 命令中设置）
- [ ] iOS Safari：需用户在设置中手动允许麦克风权限，第一次访问会弹权限弹窗

---

### B4 · TTS 音频播放（前端）

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **依赖** | A4、B1 |
| **预估工时** | 1 小时 |

**内容**：
- 后端返回的 `agent_reply` 含 `tts_audio_base64`（mp3 格式）
- 前端通过 `dart:html` 的 `AudioElement` 解码 base64 → Blob URL → 播放
- iOS Safari：`AudioElement.play()` 必须在用户手势回调中调用（同 B1 中 AudioContext 限制）；收到 `agent_reply` 时检查是否有挂起的播放请求

```dart
// 伪代码
final blob = Blob([base64Decode(audioBase64)], 'audio/mp3');
final url = Url.createObjectUrl(blob);
final audio = AudioElement()..src = url;
await audio.play();
```

---

### B5 · 端到端语音验证

| 属性 | 值 |
|---|---|
| **归属** | 全栈 |
| **依赖** | B1、B2、B4 |
| **预估工时** | 2 小时 |

**验收清单**：
- [ ] Android Chrome 手机上：按住麦克风说"帮我缴医保"，面板显示 ASR 识别文字，小浙回复"帮您缴医保，对吗？"并播放语音
- [ ] iOS Safari 手机上：同上流程可走通（注意 AudioContext 手势初始化）
- [ ] 语音延迟（说完 → 小浙回复）< 3 秒（局域网）/ < 5 秒（公网）

---

## 阶段 C — 体验打磨

### C1 · LLM Prompt 调优

| 属性 | 值 |
|---|---|
| **归属** | 后端 |
| **依赖** | B5（需端到端语音可用才能测 prompt） |
| **预估工时** | 3-5 小时（迭代性任务） |

**当前问题**：DeepSeek 可能在单次回复中一次性描述所有步骤，而非逐步调用工具执行。

**调优方向**：

1. **System prompt 强化逐步执行约束**

```
你是小浙，每次只执行一个操作，操作后等待用户反馈或系统回执，再执行下一步。
禁止在一条回复中描述多个步骤或提前预告后续操作。
```

2. **工具调用 prompt 增加 few-shot 示例**

意图分类 prompt 中为 4 个 scene_id 各提供 3 个触发词变体：

```
"帮我缴医保" / "医保缴费" / "缴一下医保" → yibao_jiaofei
"查我的养老金" / "看看养老金" / "养老金查询" → pension_query
```

3. **复述话术简洁化**

复述 prompt 要求：不超过 20 字，不用书面语，用"帮您"开头：

```
正确：帮您缴医保，对吗？
错误：我将帮助您完成医疗保险缴费操作，请问您确认吗？
```

4. **超出能力 fallback prompt**

当 intent 不在 4 个 scene_id 内时，生成简短引导语，不道歉不解释：

```
"浙里办没有[用户意图]的服务，您可以试试[推荐渠道]"
```

**调优方法**：在 `backend/prompts/` 下维护 prompt 文件，通过修改文件迭代（无需改代码），每次改动后在 `backend/tests/` 中用 5-10 句测试语料验证意图分类准确率。

---

### C2 · 前端动画与过渡效果完善

| 属性 | 值 |
|---|---|
| **归属** | 前端 |
| **依赖** | A4 |
| **预估工时** | 3-4 小时 |

**待完善清单**：

| 效果 | 组件 | 说明 |
|---|---|---|
| 代理面板滑入 | `agent_panel.dart` | 300ms easeOutCubic，从屏幕底部滑上 45% |
| 思考动画（三个跳动点） | `agent_panel.dart` | 收到 `agent_thinking` 时展示，`agent_reply` 到达后 100ms 内消失 |
| 麦克风声波扩散 | `mic_button.dart` | 按住时橙色圆圈向外扩散，振幅跟随音量（Web Audio API `getByteTimeDomainData`） |
| 字段填充动画 | `agent_command_executor.dart` | 文字逐字符填入（每字 50ms）；敏感字段填入后立即替换为 `***` |
| 元素高亮脉冲 | `agent_command_executor.dart` | 橙色 3dp 边框，1000ms 循环呼吸动画；蒙层对应位置挖空 |
| 授权卡片弹入 | `auth_card.dart` | 从面板内部弹起，带弹性曲线（easeOutBack） |
| 超时自动拒绝 | `auth_card.dart` | 15 秒倒计时进度条，归零后自动触发拒绝 |
| 网络断开横幅 | `ws_client.dart` | WebSocket 断开后顶部出现红色横幅；重连成功后自动消失 |

---

### C3 · 断线重连与超时处理

| 属性 | 值 |
|---|---|
| **归属** | 前端/后端 |
| **依赖** | A4 |
| **预估工时** | 2 小时 |

**前端断线重连**（修改 `ws_client.dart`）：

```dart
// 断线后指数退避重连：1s → 2s → 4s → 8s，最多 4 次
// 4 次失败后展示 NetworkBanner "网络连接失败，请检查网络"
// 重连期间新的 send() 调用放入队列，重连成功后重放
void _scheduleReconnect(String sessionId, int attempt) {
  final delay = Duration(seconds: math.pow(2, attempt).toInt());
  Future.delayed(delay, () => connect(sessionId));
}
```

**超时处理清单**：

| 场景 | 超时时间 | 前端行为 |
|---|---|---|
| 等待 ASR 结果 | 10 秒 | 提示"没有收到识别结果，请重试" |
| 等待 `agent_reply`（`agent_thinking` 后） | `estimated_wait_ms × 2` | 提示"网络较慢，请稍等" |
| 等待用户授权（`permission_request`） | 15 秒 | 自动发送 `permission_response(granted=false)` |
| 等待整体任务完成（`task_done`） | 120 秒 | 提示"任务超时，请重新说一遍" |

**后端 WebSocket keepalive**（`backend/ws_handler.py` 补充）：

```python
# 每 30 秒发送 ping，60 秒无响应关闭连接
await websocket.send_json({"type": "ping", "payload": {}, "ts": now_iso()})
```

---

### C4 · 真机测试要点

| 属性 | 值 |
|---|---|
| **归属** | 全栈 |
| **依赖** | B5、C2、C3 |
| **预估工时** | 3-4 小时（含问题修复） |

**测试设备矩阵**：

| 设备 | 浏览器 | 重点测试项 |
|---|---|---|
| Android 手机（主力测试） | Chrome 最新版 | 全功能（麦克风、TTS、WebSocket、UI 动画） |
| iPhone（iOS 16+） | Safari | AudioContext 手势限制、麦克风权限弹窗、TTS 播放 |
| iPhone（iOS 15 及以下） | Safari | 降级到 ScriptProcessorNode 录音；确认能跑通 |
| 平板（可选） | Chrome/Safari | 布局在大屏上不变形（45% 面板高度适当调整） |

**iOS Safari 已知兼容性问题清单**：

| 问题 | 解决方案 |
|---|---|
| `AudioWorklet` iOS 16.4 以下不支持 | 运行时检测 `AudioWorklet` 支持，降级到 `ScriptProcessorNode` |
| `audio.play()` 非用户手势调用被拦截 | 在 mic 按钮 `onTap` 中播放首个 0ms 音频"解锁" AudioContext |
| WebSocket 后台切换 APP 断连 | 前台时重连；面板顶部提示"已重新连接" |
| 屏幕底部 safe area 遮挡麦克风按钮 | 代理面板 padding-bottom 加 `MediaQuery.of(context).viewPadding.bottom` |

**测试脚本（覆盖 4 大场景）**：

```
TC01 登录刷脸：说"帮我登录" → 确认 → 页面跳转 → 高亮 → 语音引导刷脸
TC02 登录验证码：说"验证码登录" → 代填验证码（需授权弹窗）→ 高亮登录按钮
TC03 医保缴费：说"帮我缴医保" → 逐字段代填 → 身份证号授权弹窗 → 高亮去支付
TC04 养老金查询：说"查养老金" → 代按查询 → 结果语音 + 屏幕双通道呈现
TC05 超出能力：说"帮我订火车票" → 小浙回复拒绝话术
TC06 断线重连：关飞行模式 5 秒后恢复 → 前端自动重连 → 面板提示恢复
TC07 草稿箱恢复：医保缴费填一半关闭面板 → 再次唤醒 → 小浙提示草稿 → 确认恢复
```

---

### C5 · 用户测试计划

| 属性 | 值 |
|---|---|
| **归属** | 全栈 |
| **依赖** | C4 |
| **预估工时** | 1 天（含招募、测试、整理） |

**目标用户招募**：

| 用户类型 | 人数 | 招募方式 |
|---|---|---|
| 60 岁以上老年用户（核心目标） | 3-5 人 | 家人或社区，优先找不熟悉智能手机的 |
| 子女/家属（辅助用户） | 2-3 人 | 家人，测试操作记录查看功能 |
| 同学/导师（评审观察） | 2-3 人 | 用于答辩演示预演 |

**测试任务设计**（给用户的任务说明，用口语）：

```
1. 请您打开这个 APP，试着用语音跟小浙说"帮我缴医保"，看看它能帮您做什么
2. 有一个地方小浙会问您"帮您填身份证号可以吗"，您随意说"可以"或者"不用了"都行
3. 用完以后，点"我的"→"操作记录"，看看里面有没有刚才做的事情
```

**反馈收集方式**：

| 维度 | 方法 |
|---|---|
| 可用性 | 5 分制单题问卷（操作容不容易、语音听不听得懂、字够不够大） |
| 情感反应 | 录屏 + 观察（是否犹豫、是否误触）；访谈后记录 |
| 问题汇总 | 记录到 `ISSUES.md`，标注 `🐛 Bug` 或 `❓ 待确认` |

**答辩演示预案**：

- 主演示路径：**医保缴费场景**（最复杂，覆盖代填 + HITL 授权 + 止步确定性按钮）
- 备用路径：**养老金查询**（最短，约 30 秒，网络不好时切换）
- 提前准备：演示前确认 DeepSeek API 连通（`curl` 测试）；演示时手机关闭其他 APP；备好热点以防 WiFi 不稳定

---

## 技术风险汇总

| 风险 | 影响阶段 | 概率 | 应对方案 |
|---|---|---|---|
| 讯飞 ASR 审核超过 2 个工作日 | B2 | 中 | 阶段 B 期间用阿里云 ASR（注册即用）或 Web Speech API 兜底；讯飞通过后切换 |
| iOS Safari 麦克风录音兼容问题 | B1、B5 | 中 | 提前在 iOS 设备上单独验证 AudioContext 手势解锁；准备 Android 设备作为主演示机 |
| 云服务器带宽不足导致 TTS 音频传输慢 | A2 | 低 | 选 3Mbps 以上带宽；TTS 音频 < 50KB（5 秒语音 mp3），3Mbps 传输 < 150ms |
| DeepSeek API 高延迟或不可用 | C1、演示 | 低 | 缓存 4 个场景意图的固定 mock 回复；演示前预热 API 连接（发一条测试请求） |
| Let's Encrypt 证书申请失败（域名未备案） | A3 | 中 | 若域名备案时间超过演示时间，改用 Cloudflare 隧道（无需备案，HTTPS 免费） |
| Flutter Web PWA 在 iOS 主屏幕模式下 AudioContext 异常 | B1 | 低 | 演示时用浏览器模式而非主屏幕 APP 模式 |

---

## 阶段总结

| 阶段 | 目标 | 总预估工时 | 关键依赖 |
|---|---|---|---|
| **A — 手机可访问** | 任意手机浏览器能打开并使用（无语音） | 6-9 小时 | 云服务器、域名/证书 |
| **B — 语音交互打通** | 手机上语音说话 → 小浙语音回复全链路 | 8-11 小时 | HTTPS（A3）、讯飞 Key |
| **C — 体验打磨** | 动画流畅、超时处理健壮、真机测试通过、用户测试完成 | 12-18 小时 | B 阶段全部完成 |
| **合计** | | **26-38 小时** | |
