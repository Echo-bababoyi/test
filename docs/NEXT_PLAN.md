# 下一阶段开发计划（简化版）

> **版本**：v2.0（2026-05-06）
> **作者**：architect
> **目标**：手机 Chrome 浏览器可访问，语音交互可用，答辩可演示
> **技术决策**：语音识别用 Web Speech API（浏览器端，无需讯飞/录音编码）；部署用 PWA/Web，无需打 APK

---

## 语音链路（新方案）

```
用户按住麦克风
  → 启动 Web Speech API（SpeechRecognition，已在 wake_word_listener.dart 中验证可用）
  → 说话 → 浏览器识别得到文字
  → 通过 text_input 消息发后端（已实现）
  → DeepSeek 意图分类 → 工具调用
  → Edge TTS 语音回复（已验证）
```

**前端改动只有一处**：`mic_button.dart` 的 `onAudioEnd` 回调，从"发 audio_chunk"改为"启动 `SpeechRecognition`，`onResult` 得到最终文字后发 `text_input`"。`wake_word_listener.dart` 已有完整的 `SpeechRecognition` 使用示例，直接复用同一套 API。

---

## 任务清单（按优先级排序）

| # | 任务 | 归属 | 预估工时 | 前置条件 | 可并行 |
|---|---|---|---|---|---|
| **N1** | 麦克风按钮接入 Web Speech API | 开发 | 2-3 小时 | 无 | 可与 N2 并行 |
| **N2** | 云服务器购买 + 后端部署 + HTTPS | **用户** + 开发 | 用户 1h + 开发 2-3h | 用户购买服务器 | 用户操作可立即开始 |
| **N3** | Flutter Web build + 静态文件上传 | 开发 | 1 小时 | N2 | N2 完成后 |
| **N4** | 真机测试 + Bug 修复 | 开发 | 3-4 小时 | N1、N3 | — |
| **N5** | Prompt 调优 | 开发 | 2-3 小时 | N4（真机环境下测） | — |
| **N6** | 答辩演示准备 | 开发 + **用户** | 1-2 小时 | N4、N5 | — |

**总预估工时**：开发约 11-16 小时（大幅缩减自前版的 26-38 小时）

---

## 用户需要做的事

### U1 · 云服务器购买（对应 N2 前半段）

**操作步骤**：
1. 选择云厂商（推荐阿里云/腾讯云学生优惠）
   - 配置：2C2G，Ubuntu 22.04 LTS，带宽 3Mbps 以上
   - 节点：上海或杭州
   - 预算：约 ¥30-60/月，购买 1-2 个月即可
2. 购买后将**公网 IP + root 密码**发给开发团队
3. （可选）购买域名并解析到服务器 IP，用于申请免费 HTTPS 证书

**为什么必须 HTTPS**：手机 Chrome 麦克风权限在非 localhost 的 HTTP 页面上会被拒绝，HTTPS 是必须项。

---

## 开发任务详情

### N1 · 麦克风按钮接入 Web Speech API

| 属性 | 值 |
|---|---|
| **归属** | 开发 |
| **依赖** | 无（可立即开始） |
| **预估工时** | 2-3 小时 |
| **涉及文件** | `app/lib/widgets/mic_button.dart`、新建 `app/lib/services/speech_recognizer.dart` |

**改造方案**：

新建 `speech_recognizer.dart`，复用 `wake_word_listener.dart` 的 `SpeechRecognition` 模式，但面向"单次识别"（非持续监听）：

```dart
// 按住麦克风 → start()，松开 → stop()，onResult 回调返回最终文字
class SpeechRecognizer {
  html.SpeechRecognition? _recognition;
  void Function(String text)? onResult;

  void start() {
    _recognition = html.SpeechRecognition()
      ..lang = 'zh-CN'
      ..interimResults = false  // 只要最终结果
      ..continuous = false;     // 单次识别，说完自动停止

    _recognition!.onResult.listen((e) {
      final text = e.results?.item(0)?.item(0)?.transcript ?? '';
      if (text.isNotEmpty) onResult?.call(text);
    });
    _recognition!.start();
  }

  void stop() => _recognition?.stop();
}
```

`mic_button.dart` 修改：长按开始时调用 `SpeechRecognizer.start()`，松开时调用 `stop()`；`onResult` 回调中通过 `WsClient.instance.send('text_input', {'text': text, 'session_id': ...})` 发给后端。

**注意**：Web Speech API 在 Chrome 上需要 HTTPS（非 localhost）才能使用麦克风，与 N2 HTTPS 部署强绑定。

**验收**：localhost 本地开发环境下，按住麦克风说"帮我缴医保"，面板出现识别文字，小浙开始执行流程。

---

### N2 · 云服务器购买 + 后端部署 + HTTPS

| 属性 | 值 |
|---|---|
| **归属** | 用户提供服务器 + 开发配置 |
| **依赖** | 用户完成 U1 |
| **预估工时** | 开发配置约 2-3 小时 |
| **涉及文件** | `backend/.env`（服务器上）、Nginx 配置 |

**开发配置步骤**（详见 `docs/DEPLOY_PLAN.md` A1-A3）：

1. 服务器初始化：`python3.11`、`nginx`、`certbot`
2. 上传 `backend/` 代码，创建 `.env`（`DEEPSEEK_API_KEY`、`TTS_BACKEND=edge`）
3. systemd 服务启动（`uvicorn main:app --host 127.0.0.1 --port 8000`）
4. Nginx 配置：静态文件 + WebSocket 反向代理（`wss://` 升级）
5. Let's Encrypt 申请证书（需域名）；无域名则用 IP + mkcert 自签（仅 Android Chrome 可信任）

**验收**：`curl https://your-domain.com/health` 返回正常；手机 Chrome 打开页面不报安全警告。

---

### N3 · Flutter Web Build + 上传

| 属性 | 值 |
|---|---|
| **归属** | 开发 |
| **依赖** | N2（服务器和域名确定后才能写死 WS 地址） |
| **预估工时** | 1 小时 |

**步骤**：

1. 确认 `ws_client.dart` 使用 `String.fromEnvironment`（如未改，同步修改）
2. 构建并上传：

```bash
# 从项目根执行
./bin/flutter build web \
  --dart-define=WS_BASE_URL=wss://your-domain.com/ws/session/ \
  --release

rsync -av app/build/web/ user@server:/app/web/
```

**验收**：手机 Chrome 打开 `https://your-domain.com`，首页正常加载，WebSocket 连接正常（唤醒小浙后端日志出现 `agent_wake`）。

---

### N4 · 真机测试 + Bug 修复

| 属性 | 值 |
|---|---|
| **归属** | 开发 |
| **依赖** | N1、N3 |
| **预估工时** | 3-4 小时（含修复） |

**测试设备**：Android 手机 Chrome（主力）；iPhone Safari（备用，Web Speech API 在 iOS Safari 16+ 可用）

**测试用例**（7 条，覆盖全部场景）：

| 编号 | 场景 | 关注点 |
|---|---|---|
| TC01 | 登录刷脸 | 语音"帮我登录" → 复述确认 → 跳转 → 高亮引导 |
| TC02 | 登录验证码 | "验证码登录" → 代填 → 授权弹窗 → 高亮登录按钮 |
| TC03 | 医保缴费 | "帮我缴医保" → 逐字段代填 → 身份证号授权 → 高亮去支付 |
| TC04 | 养老金查询 | "查养老金" → 代按查询 → 结果语音 + 屏幕双通道 |
| TC05 | 超出能力 | "帮我订火车票" → 小浙拒绝话术简洁准确 |
| TC06 | 断线重连 | 飞行模式 5 秒后恢复，面板自动重连提示 |
| TC07 | 草稿箱恢复 | 缴费填到一半关面板 → 再次唤醒 → 小浙提示草稿 |

**Web Speech API 特殊测试点**：
- 首次访问页面：浏览器弹出麦克风权限请求，确认授权后可用
- 识别精度：对 4 个场景各说 2-3 种表达方式，确认意图分类准确

**Bug 记录**：发现问题记录到 `ISSUES.md`，标注 `🐛 Bug`，优先修复影响主演示路径的问题。

---

### N5 · Prompt 调优

| 属性 | 值 |
|---|---|
| **归属** | 开发 |
| **依赖** | N4（真机环境下测试才有代表性） |
| **预估工时** | 2-3 小时 |

**调优方向**：
1. 意图分类 few-shot：每个 scene_id 补充 3 个口语变体（"缴医保" / "医保缴费" / "帮我交医保"）
2. 复述话术简洁化：不超过 20 字，"帮您"开头，不用书面语
3. 工具逐步调用约束：system prompt 中明确"每次只执行一个操作，操作后等待，再执行下一步"
4. 超出能力兜底：不道歉不解释，直接给推荐渠道

**方法**：修改 `backend/prompts/` 下 prompt 文件，用 10 句测试语料验证，准确率 ≥ 80% 为合格。

---

### N6 · 答辩演示准备

| 属性 | 值 |
|---|---|
| **归属** | 开发整理 + 用户熟悉 |
| **依赖** | N4、N5 |
| **预估工时** | 1-2 小时 |

**主演示路径（约 3 分钟）**：

```
唤醒小浙（语音"小浙"或点按钮）
  → 按住麦克风说"帮我缴医保"
  → 复述确认，说"对"
  → 跳转医保缴费页 → 逐字段代填
  → 身份证号授权弹窗，说"可以"
  → 脱敏填入 → 高亮"去支付" → 用户亲手点击
```

**备用路径（约 1 分钟，网络不好时切换）**：

```
唤醒小浙 → 说"帮我查养老金" → 代按查询 → 结果语音 + 屏幕呈现
```

**答辩当天检查清单**（用户执行）：

```
□ 手机充电满格，关闭不必要 APP
□ 连接稳定热点（不依赖答辩现场 WiFi）
□ 提前打开页面，点一次麦克风授权（避免权限弹窗打断演示）
□ 确认小浙可以唤醒并回复（预先跑一遍）
□ 手机静音（避免来电打断）
```

**应急预案**：

| 情况 | 应对 |
|---|---|
| Web Speech API 识别不准 | 切换面板文本输入框手动输入（已实现） |
| DeepSeek 超时 | 切换养老金查询备用路径（最短） |
| 后端服务宕机 | 准备录屏视频兜底 |

---

## 并行执行建议

```
立即可以同时开始：
  ├── N1  麦克风接入 Web Speech API（开发）
  └── U1  云服务器购买（用户）——不阻塞 N1，可同步进行

N1 + U1 完成后：
  └── N2  后端部署 + HTTPS（开发）

N2 完成后：
  └── N3  Flutter Web Build + 上传（开发）

N1 + N3 完成后（串行）：
  N4 真机测试 → N5 Prompt 调优 → N6 答辩准备
```
