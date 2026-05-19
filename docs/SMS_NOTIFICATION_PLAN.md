# 模拟短信通知横幅 — 技术方案

> **范围**：VerifyPage 点击"发送"后，2.5s 后从（手机壳）顶部滑入一条短信通知；含"已读 / 复制"两按钮；6s 无操作自动收起。**验证码每次随机生成 6 位数字**。
> **作者**：architect ｜ **日期**：2026-05-19（v2，加入随机码）

---

## 1. 结论与选型（TL;DR）

**采用 自定义 Widget（`SmsNotification`） + `AnimatedSlide` 内嵌在 VerifyPage 的 Stack 里**。新建 1 个 widget 文件，VerifyPage 改 ~25 行。
不要走 `SnackBar` / `OverlayEntry` / `InAppOverlay`，三者都不合适（见 §6 选型对比）。

---

## 2. 文件清单

| # | 文件 | 操作 | 改动行数 |
|---|---|---|---|
| 1 | `app/lib/widgets/sms_notification.dart` | **新建** | ~150 行 |
| 2 | `app/lib/pages/verify_page.dart` | 修改 | ~25 行 |

---

## 3. 视觉规范

按 iOS 14+ 系统短信横幅复刻，搭配项目 design tokens：

```
┌─────────────────────────────────────────────────────┐
│  ▢  短信               刚刚                          │ ← 顶部行 18px
│                                                      │
│  【浙里办】您的验证码是 836472，5 分钟内有效，请勿     │ ← 正文 16px / 2 行（6 位随机码示例）
│  泄露。                                              │
│                                                      │
│  ┌─────────────┐  ┌─────────────┐                   │ ← 按钮行
│  │   已读       │  │  复制并填入   │                  │
│  └─────────────┘  └─────────────┘                   │
└─────────────────────────────────────────────────────┘
```

**精确尺寸 / 颜色**：

| 元素 | 值 | 备注 |
|---|---|---|
| 整体背景 | `Color(0xF2FFFFFF)`（半透明白）| 模拟系统通知毛玻璃感 |
| 圆角 | `AppRadius.xlarge`（16） | iOS 风 |
| 外边距 | 上 `Spacing.sm`(8) ＋ 左右 `Spacing.sm`(8) | 贴着虚拟手机顶部 |
| 内边距 | 全部 `Spacing.md`(12) | |
| 阴影 | `BoxShadow(blurRadius: 24, offset: Offset(0, 6), color: Color(0x33000000))` | 浮起感 |
| 应用图标 | 圆角 6 的小方块，背景 `AppColors.elderPrimary`(`#FF6D00`)，内 `Icons.chat_bubble`，22×22 | 模仿 APP icon |
| "短信"标签 | 14sp，`FontWeight.w600`，色 `#333333` | |
| "刚刚"时间戳 | 12sp，色 `AppColors.textSecondary`(`#999999`) | 右对齐 |
| 正文 | `AppFontSize.bodyLarge`(16)，色 `AppColors.textPrimary`(`#333333`)，行高 1.4 | 适老化够大；不展开为 18 因为系统通知比正文细 |
| 验证码 `123456` | 同正文，但 `FontWeight.w700` | 视觉突出 |
| 分隔细线 | 1px，色 `AppColors.divider`(`#E5E5E5`) | 按钮行上方 |
| "已读"按钮 | 文字 18sp，色 `AppColors.textSecondary` | 次要 |
| "复制并填入"按钮 | 文字 18sp，`FontWeight.w600`，色 `AppColors.elderPrimary` | 主要 / 召唤行动 |
| 按钮高度 | 44dp（触控区） | 适老化 |

**动画**：
- 入场：`AnimatedSlide`，`offset: Offset(0, -1.6) → Offset.zero`，`duration: 300ms`，`curve: Curves.easeOutCubic`
- 出场：同 widget 反向，`offset: Offset.zero → Offset(0, -1.6)`，`duration: 240ms`，`curve: Curves.easeInCubic`
- 配 `AnimatedOpacity` 同步淡入淡出（0 → 1）让感觉更接近 iOS

---

## 4. 新文件详细规范

**新建 `app/lib/widgets/sms_notification.dart`**（参考骨架，约 150 行）：

```dart
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 模拟手机系统短信通知横幅（VerifyPage 用）。
/// 由父组件控 visible；本组件只管动画 + UI + 回调。
class SmsNotification extends StatelessWidget {
  final bool visible;
  final String code;             // 用于正文显示
  final VoidCallback onRead;     // "已读" 点击
  final VoidCallback onCopyFill; // "复制并填入" 点击

  const SmsNotification({
    super.key,
    required this.visible,
    required this.code,
    required this.onRead,
    required this.onCopyFill,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,        // 隐藏时不拦截点击
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1.6),
        duration: Duration(milliseconds: visible ? 300 : 240),
        curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 300 : 240),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: _Card(
                code: code,
                onRead: onRead,
                onCopyFill: onCopyFill,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String code;
  final VoidCallback onRead;
  final VoidCallback onCopyFill;
  const _Card({required this.code, required this.onRead, required this.onCopyFill});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部行：图标 + "短信" + "刚刚"
          Row(
            children: [
              Container(
                width: 22, height: 22,
                decoration: BoxDecoration(
                  color: AppColors.elderPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                '短信',
                style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              const Text(
                '刚刚',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          // 正文（验证码用 w700 突出）
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: AppFontSize.bodyLarge,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: '【浙里办】您的验证码是 '),
                TextSpan(
                  text: code,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '，5 分钟内有效，请勿泄露。'),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          const Divider(height: 1, color: AppColors.divider),
          // 按钮行
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onRead,
                  child: const SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        '已读',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.divider),
              Expanded(
                child: InkWell(
                  onTap: onCopyFill,
                  child: const SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        '复制并填入',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.elderPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
```

---

## 5. VerifyPage 改动清单（精确行号）

**`app/lib/pages/verify_page.dart`**

### 5.1 imports（行 1-10 区间增加）

第 1 行后插入（紧邻已有 `import 'dart:async';`）：
```dart
import 'dart:math';                        // for Random（生成随机验证码）
```
第 2 行后插入：
```dart
import 'package:flutter/services.dart';   // for Clipboard
```
第 10 行后插入：
```dart
import '../widgets/sms_notification.dart';
```

### 5.2 新增 state 字段（在第 30 行 `Timer? _timer;` 之后）

```dart
bool _showSms = false;
Timer? _smsArriveTimer;
Timer? _smsAutoCloseTimer;
String? _mockCode;                          // 当前未发码时为 null；发一次更新一次
final _random = Random();
```

**`_mockCode` 用 `String?` 不用 `String`**：避免初始 `''` 与用户输入 `''` 相等导致按钮误亮。

### 5.3 修改 `dispose()`（行 50-59）— 取消两个新 Timer

第 52 行 `_timer?.cancel();` 之后追加 2 行：
```dart
_smsArriveTimer?.cancel();
_smsAutoCloseTimer?.cancel();
```

### 5.3.1 修改 `_canLogin` getter（行 39）— 改为对比 `_mockCode`

原行 39：
```dart
bool get _canLogin => _codeController.text == '123456';
```
改为：
```dart
bool get _canLogin =>
    _mockCode != null && _codeController.text == _mockCode;
```

### 5.4 修改 `_sendCode()`（行 61-74）— 生成随机码 + 启动短信到达定时器

第 63 行 `setState(() => _countdown = 60);` 改为：
```dart
final code = (100000 + _random.nextInt(900000)).toString();  // 6 位数字
setState(() {
  _countdown = 60;
  _mockCode = code;
});
```

第 73 行 `_codeFocusNode.requestFocus();` 之前插入：
```dart
// 模拟短信 2.5s 后到达
_smsArriveTimer?.cancel();
_smsAutoCloseTimer?.cancel();
setState(() => _showSms = false); // 重置（重复点击发送时）
_smsArriveTimer = Timer(const Duration(milliseconds: 2500), () {
  if (!mounted) return;
  setState(() => _showSms = true);
  // 6s 无操作自动收起
  _smsAutoCloseTimer = Timer(const Duration(seconds: 6), () {
    if (!mounted) return;
    setState(() => _showSms = false);
  });
});
```

**注意**：随机码 `code` 在 `_sendCode` 函数作用域内定义；同步写入 `_mockCode` state 后，2.5s 后 `SmsNotification` 通过 `_mockCode` 读取——**不会过期**（每次发送都覆盖，且只用最新值）。

### 5.5 新增两个回调方法（紧跟 `_sendCode()` 之后，约第 75 行）

```dart
void _onSmsRead() {
  _smsAutoCloseTimer?.cancel();
  setState(() => _showSms = false);
}

void _onSmsCopyFill() {
  final code = _mockCode;
  if (code == null) return;            // 防御：没有码就不动作（按钮也不会被点到）
  _smsAutoCloseTimer?.cancel();
  Clipboard.setData(ClipboardData(text: code));
  _codeController.text = code;
  _codeController.selection = TextSelection.collapsed(
    offset: _codeController.text.length,
  );
  setState(() => _showSms = false);
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('验证码已复制并填入', style: TextStyle(fontSize: 18, color: Colors.white)),
      backgroundColor: AppColors.elderPrimary,
      duration: Duration(milliseconds: 1500),
    ),
  );
}
```

### 5.6 在 Stack 中挂载 SmsNotification（行 248-251 区间）

当前结构：
```dart
body: Stack(
  children: [
    Padding(...),                                              // 行 125-247 主内容
    const Positioned.fill(child: AgentFab(...)),              // 行 248-250
  ],
),
```

在 `Positioned.fill(child: AgentFab(...))` 之后追加：
```dart
Positioned(
  top: 0, left: 0, right: 0,
  child: SmsNotification(
    visible: _showSms,
    code: _mockCode ?? '',           // visible=false 时不显示，空串不会被渲染
    onRead: _onSmsRead,
    onCopyFill: _onSmsCopyFill,
  ),
),
```

**层级顺序很重要**：SmsNotification 必须在 AgentFab 之后，确保它盖在 AgentFab 之上（短信通知是系统级，不应被悬浮球遮挡）。

---

## 6. 选型对比（为什么不用其他方案）

| 方案 | ✓ / ✗ | 原因 |
|---|---|---|
| **自定义 Widget + AnimatedSlide** ★推荐 | ✓ | 在 PhoneFrame 裁剪范围内；与现有 Stack 结构兼容；可控延迟 / 自动收起 / 重复点击 |
| `SnackBar` (top via margin) | ✗ | SnackBar 默认队列化，连点"发送"会排队；样式不像通知（圆角、按钮位置受限）；强制 top 需要 hack margin |
| `OverlayEntry`（顶层 Overlay） | ✗ | Overlay 脱离 PhoneFrame 的 `ClipRRect`，会浮到物理屏顶部，破坏"模拟手机"世界观 |
| `InAppOverlay`（现有底部弹层） | ✗ | 它是 `showModalBottomSheet`，从底部出现且模态，行为完全不符 |
| `AnimatedPositioned`（top 数值变化） | ✓ 可用但次选 | 需要精确知道 widget 高度；`AnimatedSlide` 用相对偏移更鲁棒 |
| Riverpod provider 全局化 | ✗（暂不需要）| 当前只有 VerifyPage 用；引入 provider 是过度设计 |

---

## 7. 边界 case 与处理

| 场景 | 现行设计 | 说明 |
|---|---|---|
| 用户在 2.5s 内连按"发送" | `_sendCode()` 开头 cancel 旧 timer 并 `_showSms = false`，重新启动 | 防多通知重叠 |
| 用户在通知滑入过程中（300ms 内）点"已读" | InkWell 通过 `IgnorePointer(ignoring: !visible)` 拦截；`visible` 已为 true 此时能点 | OK |
| 用户在通知滑出过程中（240ms）再点"发送" | 出场动画期间 `visible=false`，IgnorePointer 屏蔽按钮点击；2.5s 后新通知正常滑入 | OK |
| 用户切走 VerifyPage（push 别的页） | `dispose()` 已 cancel `_smsArriveTimer / _smsAutoCloseTimer`，无 setState after unmount 风险 | 安全 |
| 用户点"复制并填入"后 `_canLogin` 立即变 true（因为 `_codeController.text == _mockCode`） | 触发 `setState`（listener 行 47）→"确认"按钮立刻可点 | 符合预期，UX 流畅 |
| 用户没点"发送"直接手动输 6 位数字 | `_mockCode == null` → `_canLogin == false` → "确认"按钮始终灰 | 不会误判通过；用户必须先发码 |
| 用户点过 2 次"发送"（先后 2 个不同随机码） | 第二次 `_sendCode()` 覆盖 `_mockCode`；旧码作废，只第二次的码能通过校验 | 符合直觉，与真实短信相同 |
| 随机码可能撞上"用户已输入但还没发码"的内容 | 因为 `_mockCode == null` 时按钮一直灰，撞码概率为 0 | 不存在 |
| Web 端 `Clipboard.setData` 失败（浏览器权限） | `Clipboard.setData` 返回 Future，但我们不 await，且文本已自动填入 controller，**复制失败不影响主流程** | 容错 OK，无需 try/catch |
| AgentFab 是否会遮挡？ | 短信通知 Z-order 在 AgentFab 之上（见 §5.6 层级说明） | OK |

---

## 8. 与 PRD/ARCH 的契合度

- 这是**前端纯演示能力**，不破坏"代理不代按确定性操作"原则。
- 与 PRD 场景 2（代理代读代填验证码）兼容：未来代理调用 `read_sms` 工具时，可直接走 `_onSmsCopyFill` 路径自动填入；不冲突。
- **不需要后端改动**。

---

## 9. 实施工作量评估

| 子项 | 预计耗时 |
|---|---|
| 新建 `sms_notification.dart` | 25 min |
| 改 verify_page.dart | 10 min |
| 自测（点发送→等2.5s→见通知→已读/复制/6s 自动收起） | 10 min |
| **合计** | **~45 min** |

---

## 10. 开发交付物 checklist

- [ ] 新建 `app/lib/widgets/sms_notification.dart`
- [ ] verify_page.dart 行 1 后 import `dart:math`
- [ ] verify_page.dart 行 2 后 import `flutter/services.dart`
- [ ] verify_page.dart 行 10 后 import `sms_notification.dart`
- [ ] 新增 5 个 state 字段（`_showSms`、`_smsArriveTimer`、`_smsAutoCloseTimer`、`_mockCode`、`_random`）
- [ ] **行 39 `_canLogin` 改对比 `_mockCode`**（`_mockCode != null && text == _mockCode`）
- [ ] `dispose()` cancel 两个新 timer
- [ ] **`_sendCode()` 生成 6 位随机码写入 `_mockCode`** + 启动 2.5s 到达 + 6s 自动收起
- [ ] 新增 `_onSmsRead()` / `_onSmsCopyFill()` 方法（**用 `_mockCode` 而非硬编码**）
- [ ] Stack 末尾挂 `SmsNotification(code: _mockCode ?? '', ...)`（AgentFab 之上）
- [ ] 手动测试 8 个边界 case（见 §7）：
  - 未发送时直接输 `123456` → 按钮应保持灰
  - 发送后输错码 → 灰
  - 发送后输对码 → 亮
  - 二次发送后用第一次的码 → 灰
  - 二次发送后用第二次的码 → 亮
