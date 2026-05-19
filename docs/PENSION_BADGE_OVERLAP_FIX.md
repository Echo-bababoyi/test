# 养老金页"已认证"标签遮挡问题 — 分析与修复

> **日期**：2026-05-19 ｜ **作者**：architect
> **现象**："已认证"标签压在"个人基本信息"标题上

---

## 1. 遮挡原因（精确几何分析）

**`pension_query_page.dart:216-277`** `_buildPersonalInfoCard`：

```
Container（橙渐变卡，padding: all(20)）
└ Stack
   ├ Column （决定 Stack 尺寸，crossAxis=start）
   │   └ Text('个人基本信息', 18sp w700)   ← 占 (0,0)~(~108, ~26)
   │   └ SizedBox(14)
   │   └ Row(姓名 / *小明)
   │   └ ...
   ├ Positioned(right:0, top:0) Icon shield 64×64 alpha 8%   ← 装饰盾牌
   └ Positioned(top:-1, left:16) Container 已认证 badge
       └ padding h8 v2，文字 10sp，h ≈ 18-20px，w ≈ 40px
       → 占 Stack 内 (16, -1)~(~56, ~19)
```

**重叠**：badge 占 x∈[16, ~56]，y∈[-1, ~19]；标题占 x∈[0, ~108]，y∈[0, ~26]。
→ 几何重叠区 x∈[16, ~56]，y∈[0, ~19]，**完整盖住"基本"两字 + 部分"信"字**。

**作者意图**：badge 想做成"卡片角徽章"，hang 在卡片顶边外。但 Stack 在 Container 的 padding 内（padding=20），`top:-1` 仅是相对 padding 区域内顶部 1px 上移——**没有真正 hang 在卡片外**，反而正好压在 Column 标题上。

---

## 2. 修复方案对比

| 方案 | 改动 | 优点 | 缺点 |
|---|---|---|---|
| **B（推荐）** | badge 移到右上角 + 删 shield 盾牌装饰 | 与"个人基本信息"无冲突；右上角是政务卡常用"认证状态"位置；视觉舒展 | 需删一个装饰元素 |
| A | "个人基本信息"前加 SizedBox(18) 让位 | 改动最小（1 行） | 标题被强制下移，badge 与标题同色系（橙黄）观感糊；不符合"角徽章"意图 |
| C | badge 跨 Container 边界真正 hang 在卡片外 | 最忠实"角徽章"意图 | 需把 Stack 外移到 Container 外层，结构大改 |
| D | badge 内联到标题 Row | 实现简单 | 失去"徽章"视觉，变成普通 tag |

**推荐 B**：右上角符合"已认证"的传统位置（参考银行卡、政务卡），且和卡片右上圆角配合是常见 UI 套路；同时移除半透明 shield 盾牌（仅装饰，重叠 badge 后视觉混乱）。

---

## 3. 修复指引（方案 B，精确 文件:行号）

**`pension_query_page.dart:254-258`**（删除装饰 shield 盾牌）：

当前：
```dart
Positioned(
  right: 0,
  top: 0,
  child: Icon(Icons.shield_outlined, size: 64, color: Color(0x14FFFFFF)),
),
```
→ **整段删除**。

**`pension_query_page.dart:259-273`**（重写已认证 badge 到右上角）：

当前：
```dart
Positioned(
  top: -1,
  left: 16,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: const BoxDecoration(
      color: Color(0xFFFFAB40),
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(6),
        bottomRight: Radius.circular(6),
      ),
    ),
    child: const Text('已认证', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
  ),
),
```

改为：
```dart
Positioned(
  top: 0,
  right: 0,
  child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.white.withValues(alpha: 0.55), width: 1),
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.verified_outlined, size: 14, color: Colors.white),
        SizedBox(width: 4),
        Text('已认证',
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            )),
      ],
    ),
  ),
),
```

**关键改动**：
1. **`top:-1, left:16` → `top:0, right:0`**：从左上压标题挪到右上空位
2. **`fontSize: 10` → `fontSize: 13`**：原 10sp 严重违反适老化；右上角不挤，可放大
3. **背景从橙黄 `#FFAB40`（与卡片橙底撞色）改为半透明白 + 白描边**：视觉为"贴在橙卡上的浅色标签"，与卡片融合更好；与"已认证"语义（在橙底卡上）匹配
4. **加 `Icons.verified_outlined` 14×14 白色**：增加"已认证"语义识别度（参考银行 App 实名认证标）
5. **圆角 6（下方）→ 12（全圆角）**：不再装"hang 在卡片外"

---

## 4. 改完后视觉预览

```
┌──────────────────────────────────────────┐
│ 个人基本信息                  [✓ 已认证]  │ ← 标题在左、badge 在右，互不干扰
│                                            │
│ 姓名                              *小明    │
│                                            │
│ 证件号码           3****************3      │
└──────────────────────────────────────────┘
```

vs 当前（遮挡）：
```
┌──────────────────────────────────────────┐
│ 个[已认证]信息       (盾牌icon)          │ ← badge 压住"基本"
│ ...                                       │
```

---

## 5. 测试 checklist

- [ ] 打开养老金查询页 → 点"查询" → 个人信息卡渲染
- [ ] "个人基本信息"标题**完整可读**，没有任何遮挡
- [ ] "✓ 已认证"标签在卡片**右上角**，白色半透明背景，字号 13sp（清晰可读）
- [ ] 不再有半透明盾牌装饰图标
- [ ] 卡片整体橙渐变 + 阴影效果保留
- [ ] 标题字号 18sp、姓名 / 证件号 16sp 都不受影响

---

## 6. 工作量

5 分钟。改 1 个文件 2 处：
- 删 `pension_query_page.dart:254-258` (shield icon)
- 替换 `pension_query_page.dart:259-273` (badge 重写)

净行数 +5。
