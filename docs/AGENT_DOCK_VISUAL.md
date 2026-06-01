# AgentDock 聊天面板视觉细化方案（仅限 dock 内部）

> **版本**：v1.0（2026-06-01）—— 方向已选定 **B 适老亲和暖卡**，本稿给可直接落地的精确参数 + 落点
> **作者**：PM
> **范围铁律**：**只改 `app/lib/widgets/agent_dock.dart` 面板内部视觉，绝不动任何其它页面/组件 UI**。
> ⚠️ **共享组件不动**：`agent_bubble.dart`(AgentBubble) 与 `auth_card.dart`(AuthCard) 仍被待退役的 `agent_fab.dart` 引用——**不得编辑这两个文件**，本稿改用 dock 内私有组件替换 dock 内的调用。
> **关联**：交互稿 `docs/AGENT_DOCK_REDESIGN.md`、`ISSUES.md` #79
> **状态**：待 frontend 实施

---

## 1 当前问题诊断（基于 4 张截图）

| # | 问题 | 落点（agent_dock.dart） |
|---|---|---|
| P1 | 面板无边界：对话态从导航行下方裂出白地，无顶圆角/上描边/投影，跟页面糊一起 | `_DialogPanel` build 的 Container decoration（L581） |
| P2 | 缺头部栏：无"聊天窗"识别，无小浙头像/名/收起 | `_DialogPanel` 顶部（需新增 header） |
| P3 | 气泡偏素：飘在空背景、字号仅 15sp（< 18sp 适老底线）；输入框素 | 气泡走共享 `AgentBubble`（15sp）；输入栏 L617 |
| P4 | 引导态结构错：S2/S3 仍带完整导航行 | shell `build()` L108-159 恒挂 `_DockNavRow` |

---

## 2 选定方向 B：暖卡色板（dock 内新增 const，勿动全局主题）

```dart
// 在 agent_dock.dart 顶部追加（_kPrimary 已存在 = AppColors.elderPrimary = #FF6D00）
const _kPanelBg     = Color(0xFFFFF8F2); // 暖米面板底（与白色页面拉开层次，治 P1）
const _kHeaderBg    = Color(0xFFFFF1E6); // 浅橙头部栏底
const _kAgentBubble = Colors.white;      // 小浙气泡白底
const _kUserBubble  = _kPrimary;         // 用户气泡橙底
const _kTextMain    = Color(0xFF333333); // 正文深灰
```
适老底线（全程守）：对话/引导正文 ≥18sp、点击区 ≥48dp、橙底必白字（对比 ≥4.5:1）。

---

## 3 面板容器（_DialogPanel）— 治 P1

**落点**：`_DialogPanelState.build` 的最外层 `Container`（当前 L581-595）。

⚠️ **Flutter 坑**：`Border(top:…)` 非均匀边 + `borderRadius` 会触发 assertion。改用 `ShapeDecoration`（其阴影字段是 `shadows` 不是 `boxShadow`），并在 Container 上加 `clipBehavior: Clip.antiAlias` 让子组件裁进圆角。

```dart
Container(
  width: double.infinity,
  clipBehavior: Clip.antiAlias,                 // 让 header 方角裁进 28dp 圆角
  decoration: ShapeDecoration(
    color: _kPanelBg,                           // 暖米（原 #FFFCF8）
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)), // 顶 28dp 大圆角（原无）
      side: BorderSide(color: _kPrimary, width: 1.5),                // 橙边 1.5px（原 0.25α 1px）
    ),
    shadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.12),  // 12%（原 0.06）
        blurRadius: 20,                                // 原 8
        offset: const Offset(0, -6),                   // 原 -2
      ),
    ],
  ),
  child: Column(children: [ /* ① header ② 连接条 ③ 消息区 ④ 输入区 */ ]),
)
```
内部 Column 顺序调整为：**① 头部栏 → ② "小浙未连接"提示条（原 L598）→ ③ 消息 ListView → ④ 输入区**。

---

## 4 头部栏（_DialogPanel 新增，置于 Column 最顶）— 治 P2

```dart
Container(
  height: 60,
  decoration: const BoxDecoration(color: _kHeaderBg),  // 被外层 clip 裁出顶圆角
  padding: const EdgeInsets.fromLTRB(16, 0, 8, 0),
  child: Row(children: [
    _ZheAvatar(size: 40),                               // ← 见 §7：复用 _ZhePainter 的圆头像
    const SizedBox(width: 12),
    const Text('小浙助手',
      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _kTextMain)),
    const Spacer(),
    Semantics(
      button: true, label: '收起小浙对话',
      child: PressScaleWrapper(
        pressedScale: 0.9,
        borderRadius: BorderRadius.circular(24),
        onTap: () {
          final s = AgentSession.instance;
          s.setPanelMode(s.isGuiding ? AgentPanelMode.guide : AgentPanelMode.closed);
        },
        builder: (_) => const SizedBox(
          width: 48, height: 48,                         // 点击区 ≥48dp
          child: Icon(Icons.keyboard_arrow_down, size: 30, color: _kPrimary),
        ),
      ),
    ),
  ]),
)
```
收起 ⌄ 行为：引导中→回窄条(guide)，否则→收起(closed)，与原中间键逻辑一致（§9 已把收起职责从导航行迁到这里）。

---

## 5 消息气泡（dock 私有 `_DockBubble`，替换 dock 内 3 处 AgentBubble）— 治 P3

**落点**：把 `agent_dock.dart` 内 3 处 `AgentBubble(...)`（L706 choice、L777 普通、L979 卡片态）替换为新私有 `_DockBubble`。**不编辑 `agent_bubble.dart`**（AgentFab 仍用它）。

```dart
class _DockBubble extends StatelessWidget {
  final String text;
  final bool isAgent;
  const _DockBubble({required this.text, required this.isAgent});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.72;       // 最大宽 72%
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      child: Row(
        mainAxisAlignment: isAgent ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAgent) ...[ _ZheAvatar(size: 28), const SizedBox(width: 8) ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16), // 大内距
              decoration: BoxDecoration(
                color: isAgent ? _kAgentBubble : _kUserBubble,    // 白 / 橙
                borderRadius: BorderRadius.circular(20),          // 大圆角 20dp
                boxShadow: isAgent
                  ? const [BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2))] // 8% 柔投影，无硬描边
                  : null,
              ),
              child: Text(text, style: TextStyle(
                fontSize: 18, height: 1.45,                        // ≥18sp（原 15sp）
                color: isAgent ? _kTextMain : Colors.white)),      // 橙底白字
            ),
          ),
        ],
      ),
    );
  }
}
```
- 小浙气泡：白底 + 28dp 头像 + 8% 柔投影（无硬描边，更亲和）。
- 用户气泡：橙底白字、右对齐、无头像。
- "小浙正在想…"占位（L736-751）字号 15→16sp，灰底保留（次要态，不强制 18sp）。

---

## 6 输入栏（_DialogPanel 输入区）

**落点**：L617-674。

| 项 | 现状 | 改为 |
|---|---|---|
| 输入框 fill | grey.shade50 | `Colors.white`（暖米底上白胶囊更跳） |
| 输入框圆角/边 | 24dp / grey300 | 保留 24dp 胶囊 + grey300 1px，聚焦橙 1.5px（保留） |
| 输入框文字 | 18sp ✓ | 保留 18sp；contentPadding vertical 10→12 |
| 顶分隔线 | grey 0.2 | 改 `_kPrimary.withValues(alpha:0.12)` 暖色细线 |
| 麦克风 | size 50 ✓ | 保留（≥48dp） |
| 发送键 | 44×44 ✗ | **48×48**（≥48dp），橙圆 + 白 send 图标 size 22 |

---

## 7 小浙圆头像私有组件 `_ZheAvatar`（头部 40dp / 气泡·窄条 28dp 复用）

复用现有 `_ZhePainter`（L354，已用于 `_ZheCenterButton` 画"浙"字小人）：

```dart
class _ZheAvatar extends StatelessWidget {
  final double size;
  const _ZheAvatar({required this.size});
  @override
  Widget build(BuildContext context) => Container(
    width: size, height: size,
    decoration: const BoxDecoration(color: _kPrimary, shape: BoxShape.circle),
    child: CustomPaint(painter: _ZhePainter(/* 传白色，参照 _ZheCenterButton 现有用法 */)),
  );
}
```
> 若 `_ZhePainter` 构造签名与此不符，frontend 按其现有调用方式适配，保持白色"浙"字小人 on 橙圆。

---

## 8 S2 引导态窄条（_GuidePanel）

**落点**：`_GuidePanelState.build`（L838-892）。

1. **容器对齐暖卡**（同 §3 参数）：bg→`_kPanelBg`、顶 28dp 圆角（用 ShapeDecoration + clipBehavior）、橙边 1.5、阴影 blur20/y-6/12%。`minHeight: 60` 保留。
2. **左侧改头像**：把原"小浙："文字标签（L859-864）换成 `_ZheAvatar(size: 28)` + `SizedBox(width: 8)`。
3. **消息**：`Expanded` 内 18sp、完整不截断（保留 L866-871，文字色统一 `_kTextMain`）。
4. **展开 ⌃**：48×48 + `Semantics(label:'展开小浙对话')`（保留 L873-888，已达标）。

窄条形态：`[浙头像] 最近一条引导消息（≥18sp 不截断）            [⌃]`

---

## 9 S3 卡片态（_CardHost）+ 结构修正（P4 / 收起入口归属）

### 9.1 _CardHost 容器
**落点**：`_CardHostState.build`（L933-949）。容器 decoration 对齐暖卡（§3 参数）。卡片与窄条间加 `padding: EdgeInsets.fromLTRB(12, 10, 12, 12)` 让卡片"浮"出呼吸感。
> AuthCard 是共享组件（agent_fab 也用），**不改其内部样式**，仅由 _CardHost 暖卡容器托底。选择卡 `_ChoiceBtn`、确认 `_ConfirmBtn` 是 dock 私有，可顺手把圆角统一到 14-18dp、保证按钮高 ≥48dp（如未达标）。

### 9.2 P4 结构修正 + 收起入口归属（PM 拍板）

**单一规则：`_DockNavRow` 仅在 S0（closed）态渲染；S1/S2/S3 都不挂。**

**落点**：shell `build()`（L108-159），把 `_DockNavRow(...)`（L112-129）包条件：
```dart
if (mode == AgentPanelMode.closed && !closing) _DockNavRow(...),
```
（closing=S2→S0 渐隐期间也不显示导航行，使收尾窄条干净渐隐。）

**各态收起/展开入口（去导航行后控制不丢）**：
| 态 | 顶部控制 | 来源 |
|---|---|---|
| S0 收起 | 首页 · **小浙圆按钮(开对话)** · 我的 | _DockNavRow（onCenterTap 简化为仅 closed→dialog） |
| S1 对话 | 头部栏右侧 **收起 ⌄** | §4 |
| S2 引导 | 窄条右侧 **展开 ⌃** | §8 |
| S3 卡片 | 无（卡片态禁收起，用卡片按钮答复，沿用现 L118） | — |

**为何 S1 也去掉导航行（自洽理由）**：
1. 避免双栏占高：导航行 64dp + 头部栏 60dp = 124dp，吃掉 ~400dp 面板的 31%。
2. 避免双收起入口（中间键 ⌄ + 头部 ⌄）冗余，老人易困惑（选择焦虑）。
3. 对话态定位"重对话"，导航非重点；想去首页/我的 → 收起一下即回 S0 全导航，仅多一次点击。
4. 规则统一好记好实现：导航行只属于 S0。

**备选（若用户坚持对话态内可直接导航）**：S1 头部栏下方保留一行 slim 导航（仅"首页/我的"，无中间键，收起仍靠头部 ⌄），代价 +56dp 占高。列为备选，不进 v1.0。

---

## 10 frontend 实施清单（全部在 agent_dock.dart 内）

- [ ] §2 顶部追加 5 个 dock 私有 const 色值。
- [ ] §3 `_DialogPanel` 外层 Container → ShapeDecoration（28dp 顶圆角 + 橙边 1.5 + 暖米底 + 强投影）+ `clipBehavior: Clip.antiAlias`；内部 Column 顺序：头部→连接条→消息→输入。
- [ ] §4 `_DialogPanel` 顶部新增头部栏（浅橙底 60dp + 40dp _ZheAvatar + "小浙助手"18sp粗 + 收起⌄ 48dp）。
- [ ] §5 新增 `_DockBubble`，替换 dock 内 3 处 `AgentBubble`（L706/L777/L979）。**勿动 agent_bubble.dart**。
- [ ] §6 输入栏：fill 白、发送键 48×48、分隔线暖色、contentPadding 调整。
- [ ] §7 新增 `_ZheAvatar`（复用 _ZhePainter）。
- [ ] §8 `_GuidePanel` 容器暖卡化 + 左侧改 28dp 头像。
- [ ] §9.1 `_CardHost` 容器暖卡化 + 卡片留白。
- [ ] §9.2 shell `build()` 把 `_DockNavRow` 包 `if (mode==closed && !closing)`；`onCenterTap` 简化为仅 closed→dialog。
- [ ] 自测：S0/S1/S2/S3 四态切换 + 收尾渐隐（不放大）+ 跨页不丢；所有正文 ≥18sp、控制 ≥48dp。
- [ ] 回归：确认 agent_fab.dart 外观未受影响（AgentBubble/AuthCard 未改）。

---

## 11 适老化验收底线（实施后逐项核对）

| 维度 | 要求 | 本稿落实 |
|---|---|---|
| 字号 | 对话/引导正文 ≥18sp | _DockBubble 18sp、_GuidePanel 18sp、头部名 18sp |
| 点击区 | 收起⌄/展开⌃/麦克风/发送/卡片按钮 ≥48dp | 全部 48dp（发送由 44→48） |
| 主色 | 长辈橙 #FF6D00 | _kPrimary，橙边/橙圆头像/用户气泡 |
| 对比度 | 文字对背景 ≥4.5:1 | 橙底白字、白底深灰字 #333 |
| 边界感 | 面板"浮起"可辨 | 暖米底 + 28dp 圆角 + 橙边 + 强投影 |
| 动效 | 渐隐不放大（沿用交互稿，本稿不改动效逻辑） | closing 动画 L133 保留 |
