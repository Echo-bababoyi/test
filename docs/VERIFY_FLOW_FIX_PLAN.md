# 验证码登录流程 3 个 UI 问题 — 修复方案

> **审查日期**：2026-05-19
> **作者**：architect
> **审查输入**：用户测试反馈 + 当前代码状态（含前端已实施的部分改动）

---

## 现状速览（先说哪些已做）

- ✅ `sms_notification.dart:152` 按钮文案 **已改为"复制"**（不再是"复制并填入"）
- ✅ `verify_page.dart:104-115` `_onSmsCopyFill` **已去掉自动填入逻辑**，只剩 `Clipboard.setData` + SnackBar 提示
- ✅ `verify_page.dart:35` `_loginSuccess` 状态已加；`:117-124` `_confirmSmsCode` 已写 1.5s 延迟跳转；`:296-321` 已挂全屏白色覆盖层
- ⚠️ 但 #2 还有命名残留（`onCopyFill` / `_onSmsCopyFill`）—— 行为已改、名字未改
- ⚠️ #3 覆盖层有**实质性 bug**（淡入动画失效）+ 字号偏小

---

## 问题 1：人脸页"其他方式认证"弹窗字号

### 当前代码（`app/lib/pages/face_auth_page.dart` 行 1265-1313）

| 元素 | 行号 | 当前 | 适老化达标？ | 问题 |
|---|---|---|---|---|
| "取消" TextButton | 1284 | `fontSize: 18` | ⚠️ 卡线 | 与右侧主按钮无视觉差异；触控区也偏小 |
| "其他认证方式" 标题 | 1289 | `fontSize: 20, w700` | ⚠️ 卡线 | 作为弹层标题应当用 elderTitle=24 |
| leading 图标 | 1298 / 1305 | `size: 28` | OK | 但与 title 18sp 视觉不平衡 |
| "手机短信验证" title | 1299 | `fontSize: 18` | ⚠️ 卡线 | 列表项作为可点击主入口，字号偏小 |
| "密码登录" title | 1306 | `fontSize: 18` | ⚠️ 卡线 | 同上；且禁用态无视觉区分（颜色未变灰） |
| trailing `chevron_right` | 1300 / 1307 | 默认 size（≈24）| 边缘 | 适老化下应 ≥28 |
| ListTile contentPadding | — | 未设（默认）| 触控高度 ~56dp | 适老化建议 ≥56dp，更保险用 64-72dp |

### 问题描述
所有字号都"勉强达标"`≥18sp`，但作为"用户主动选其他认证方式"的关键决策弹层，**视觉权重不足**：标题不够大、列表项不够厚重、禁用项与可用项颜色相同——这些都会让长辈用户犹豫。

### 修复指令

**`app/lib/pages/face_auth_page.dart`**

**行 1284**：把
```dart
child: const Text('取消', style: TextStyle(fontSize: 18)),
```
改为
```dart
child: const Text('取消', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
```
并把 1279-1285 的 `TextButton` 加 `style` 中加 `padding: EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm)` 扩大触控区。

**行 1289**：
```dart
style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
```
改为
```dart
style: TextStyle(fontSize: AppFontSize.elderTitle, fontWeight: FontWeight.w700),
```
（即 24sp）

**行 1297-1302**（"手机短信验证" ListTile）整体替换为：
```dart
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
  leading: const Icon(Icons.email_outlined, size: 32, color: AppColors.elderPrimary),
  title: const Text('手机短信验证',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
  trailing: const Icon(Icons.chevron_right, size: 28, color: AppColors.textSecondary),
  onTap: onSmsVerify,
),
```

**行 1304-1309**（"密码登录" ListTile，禁用态）整体替换为：
```dart
ListTile(
  contentPadding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
  leading: Icon(Icons.lock_outline, size: 32, color: Colors.grey.shade400),
  title: Text('密码登录（暂未开放）',
      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500, color: Colors.grey.shade500)),
  trailing: Icon(Icons.chevron_right, size: 28, color: Colors.grey.shade400),
  enabled: false,
  onTap: null,
),
```
**关键改动**：`enabled: false` 让 InkWell 灰化；title 改色 + 加"暂未开放"后缀让用户知道这是禁用项而非 bug。

### 影响范围
仅 `_OtherAuthContent` 一个类（face_auth_page.dart 行 1265-1313）。约改 12 行。

---

## 问题 2：短信通知"复制并填入"改"复制"

### 当前代码状态

**`app/lib/widgets/sms_notification.dart`**
- 行 152：按钮文案 = `'复制'` ✅ **已做**
- 行 10, 17, 38, 51, 56, 147：参数 / 回调名仍是 `onCopyFill` ⚠️ **命名残留**

**`app/lib/pages/verify_page.dart`**
- 行 104-115 `_onSmsCopyFill`：
  - 行 106：`Clipboard.setData(ClipboardData(text: _mockCode))` ✅
  - **已删除**自动写入 `_codeController.text` 的代码 ✅
  - 行 110：SnackBar 文案 = `'验证码已复制'` ✅

### 问题描述
**行为已正确**——按钮文案是"复制"，行为只复制不填入，SnackBar 文案也对。**唯一遗留问题是命名：方法名和参数名仍是 `Fill` 字样，与行为不符**，会让后续开发者疑惑"为什么叫 fill 但不 fill"。

### 修复指令（rename，纯 cosmetic 但建议做）

**`app/lib/widgets/sms_notification.dart`**：把 `onCopyFill` 全文替换为 `onCopy`
- 行 10：`final VoidCallback onCopyFill;` → `final VoidCallback onCopy;`
- 行 17：`required this.onCopyFill,` → `required this.onCopy,`
- 行 38：`onCopyFill: onCopyFill,` → `onCopy: onCopy,`
- 行 51：`final VoidCallback onCopyFill;` → `final VoidCallback onCopy;`
- 行 56：`required this.onCopyFill,` → `required this.onCopy,`
- 行 147：`onTap: onCopyFill,` → `onTap: onCopy,`

**`app/lib/pages/verify_page.dart`**：
- 行 104：`void _onSmsCopyFill() {` → `void _onSmsCopy() {`
- 行 293：`onCopyFill: _onSmsCopyFill,` → `onCopy: _onSmsCopy,`

### 影响范围
2 个文件，共 8 处。机械替换，不改逻辑。

---

## 问题 3：验证码确认后过渡页

### 当前代码（`app/lib/pages/verify_page.dart`）

**已做：**
- 行 35：`bool _loginSuccess = false;` 状态
- 行 117-124：`_confirmSmsCode` 设 `_loginSuccess = true` + 1500ms 延迟 `context.go(elderHome)`
- 行 296-321：`if (_loginSuccess)` 全屏白底 + check 图标 + "验证成功" + "正在跳转..."

**缺/有问题：**

#### 🐛 Bug A：`AnimatedOpacity` 淡入动画失效（行 298-300）

```dart
if (_loginSuccess)
  Positioned.fill(
    child: AnimatedOpacity(
      opacity: _loginSuccess ? 1 : 0,          // ← 永远是 1
      duration: const Duration(milliseconds: 300),
      ...
```

**问题**：外层 `if (_loginSuccess)` 决定 widget 是否插入 Stack。`_loginSuccess == false` 时整个 widget 树根本不存在；`_loginSuccess == true` 时 widget 第一帧就创建，`AnimatedOpacity` 的 `opacity` 初值已经是 1，**没有动画**就直接到位。视觉效果 = 突然出现（与用户希望的"过渡"相反）。

**修复**：去掉外层 `if`，让 widget 一直存在，靠 `AnimatedOpacity` 控显隐 + `IgnorePointer` 阻止背景点击。

#### 🟡 Bug B：字号不够大（行 310, 315）

| 元素 | 行号 | 当前 | 建议 |
|---|---|---|---|
| "验证成功" | 310 | `fontSize: 24, w700` | `fontSize: AppFontSize.elderLarge (32), w700` |
| "正在跳转..." | 315 | `fontSize: 16, color: grey` | `fontSize: 20, color: AppColors.textSecondary` |

#### 🟡 Bug C：色系与项目脱节（行 306）

`Icons.check_circle, color: Colors.green` —— 用了 Material 默认绿。其他长辈版页面（如 face_auth S9 成功态）用 `Color(0xFF4CAF50)` 一致绿色 + 项目橙色主题。建议统一。

#### 🟡 Bug D：SmsNotification 应同步隐藏（视觉细节）

`_confirmSmsCode` 时若 SMS 横幅还可见（用户没点已读、6s 内确认），覆盖层会盖在它上面 — 但白底之上看不见，反而显得叠层混乱。应同步 `_showSms = false`。

### 修复指令

**`app/lib/pages/verify_page.dart`**

**行 117-124**（`_confirmSmsCode`）替换为：
```dart
void _confirmSmsCode(BuildContext context) {
  _smsArriveTimer?.cancel();
  _smsAutoCloseTimer?.cancel();
  setState(() {
    _loginSuccess = true;
    _showSms = false;
  });
  ref.read(loginProvider.notifier).login('用户');
  Future.delayed(const Duration(milliseconds: 1500), () {
    if (!mounted) return;
    context.go(AppRoutes.elderHome);
  });
}
```
**改动点**：增加两个 timer cancel（避免延迟期间 SMS 又弹出）；同步关掉 `_showSms`。

**行 296-321**（覆盖层）整体替换为：
```dart
// 验证成功过渡层（始终存在，靠 AnimatedOpacity 控显隐）
Positioned.fill(
  child: IgnorePointer(
    ignoring: !_loginSuccess,
    child: AnimatedOpacity(
      opacity: _loginSuccess ? 1 : 0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: Container(
        color: Colors.white,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.5, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutBack,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Container(
                width: 120, height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check, size: 84, color: Colors.white),
              ),
            ),
            const SizedBox(height: Spacing.xl),
            const Text(
              '验证成功',
              style: TextStyle(
                fontSize: AppFontSize.elderLarge,   // 32
                fontWeight: FontWeight.w700,
                color: Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(height: Spacing.sm),
            const Text(
              '正在为您登录…',
              style: TextStyle(
                fontSize: 20,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),
```

**关键改动**：
1. 去掉 `if (_loginSuccess)`，widget 始终挂载 → `AnimatedOpacity` 的 0→1 动画**真正会播放**
2. 加 `IgnorePointer(ignoring: !_loginSuccess)` 阻止隐藏时拦截点击
3. 字号升到 elderLarge（32）+ 20，与项目其他成功态一致
4. 图标改为绿色圆盘 + 白对勾，配 `TweenAnimationBuilder` 做 `easeOutBack` 弹性放大（与 face_auth_page S9 成功态视觉一致，行 1021-1042）
5. 颜色用 `Color(0xFF4CAF50)`（与 face_auth_page `_kGreen` 一致）
6. 文案 "正在跳转..." → "正在为您登录…"（更贴合"已登录成功"的语义，且与 face_auth_page 行 1056 一致）

### 影响范围
仅 `verify_page.dart`，约改 35 行。视觉与 face_auth_page S9 成功态对齐，建立 APP 内一致的"操作成功"视觉模式。

---

## 总修改清单

| 文件 | 改动 |
|---|---|
| `app/lib/pages/face_auth_page.dart` | `_OtherAuthContent` 字号 / icon size / 禁用态（行 1284-1309 约 12 行） |
| `app/lib/widgets/sms_notification.dart` | `onCopyFill` → `onCopy` rename（6 处） |
| `app/lib/pages/verify_page.dart` | `_onSmsCopyFill` → `_onSmsCopy` rename（2 处）；`_confirmSmsCode` 重写（行 117-124）；成功过渡层重写（行 296-321） |

**总工作量**：~45 分钟（含自测）。

## 测试要点

- [ ] 弹层在 PhoneFrame 405×880 虚拟手机里，标题"其他认证方式"24sp 视觉够大
- [ ] "密码登录"显示灰色 + "暂未开放"后缀；点击无响应
- [ ] 短信按钮"复制"点一下 → 剪贴板内容是当前 `_mockCode`；SnackBar "验证码已复制"
- [ ] 输入验证码→点"确认" → **看到淡入过渡（不是瞬移）** + 绿色对勾弹性出现 + "验证成功" 32sp + "正在为您登录…" 20sp → 1.5s 后跳 elderHome
- [ ] 确认时若 SMS 横幅还在 → 立刻消失，不与成功层叠加
- [ ] 确认后 1.5s 内如再点屏幕 → `IgnorePointer` 阻挡，不响应
