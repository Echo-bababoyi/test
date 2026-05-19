# 社保查询页 — 色系统一改造方案

> **日期**：2026-05-19 ｜ **作者**：architect
> **触发**：用户反馈 `shebao_query_page.dart` 色系与长辈版其他页面不统一

---

## 1. TL;DR

社保查询页**整体色系是"标准版蓝紫"**，与长辈版基线（灰底+白板块+橙强调+橙色渐变卡）严重脱节。最刺眼的两处：

- 🔴 **个人信息卡用蓝色渐变** `#6EA8E8 → #4A7FD4`（行 45）—— 同款卡在养老金/医保查询页是 **橙色渐变** `#FF9A3C → #FF6D00`
- 🔴 **_InsuranceCard 头部用深蓝紫渐变** `#5C4A9E → #3B2D8B`（行 197）—— 与橙色主调完全冲突

还有 AppBar 白底黑字（基线橙底白字）、整体背景纯白（基线灰）等结构性差异。

修完后页面会从"政务蓝紫"变回"长辈橙暖色"，与 pension_query / mine_page / yibao_query 视觉一致。

---

## 2. 当前 vs 长辈版基线 — 14 项差异

> 基线参考：`pension_query_page.dart` / `mine_page.dart` / `elder_home.dart`

| # | 维度 | 当前 | 行 | 基线 | 严重度 |
|---|---|---|---|---|---|
| 1 | 页面背景 | `Colors.white` | 15 | `AppColors.background` = `#F5F5F5` 灰 | 🔴 |
| 2 | AppBar 背景 | `Colors.white` 白底 | 17 | `AppColors.elderPrimary` 橙底 | 🔴 |
| 3 | AppBar 文字 / icon 色 | 未指定（默认黑） | 17 | `Colors.white` | 🔴 |
| 4 | AppBar 标题字号 | 16 w600 | 23 | 20-22 w600/w700 | ⚠️ |
| 5 | AppBar actions | 同时有 close + more_horiz + 左侧 BackButton（**两个返回入口**） | 25-31 | 仅 BackButton | 🟡 语义重复 |
| 6 | **个人信息卡渐变** | **蓝 `#6EA8E8 → #4A7FD4`** | 44-48 | **橙 `#FF9A3C → #FF6D00`** | 🔴 **主色错** |
| 7 | 个人信息卡标题 | 16 w700 | 59 | 18 w700 | ⚠️ |
| 8 | 个人信息卡字段 | 14/13 sp | 67-88 | 16+ sp | ⚠️ |
| 9 | "险种信息" 板块标题 | 16 w700 + 4×18 橙竖条 | 124-128 | 18-24 w600 板块标题 | ⚠️ |
| 10 | 板块容器 | 无（行内 Padding 显示） | 111-130 | 白色 `surface` Container + margin | 🟡 |
| 11 | **_InsuranceCard 头部渐变** | **深蓝紫 `#5C4A9E → #3B2D8B`** | 196-200 | 长辈版无此色系 | 🔴 **主色错** |
| 12 | _InsuranceCard 标题 | 15 w600 | 211-215 | 18 w600 | ⚠️ |
| 13 | _InsuranceCard 状态行 | 13sp | 237 | 16sp | ⚠️ |
| 14 | _InsuranceCard 操作按钮 | 14sp + Material 默认色（蓝？） | 249, 256 | 18sp + `elderPrimary` 橙 | ⚠️ |

**附加杂项**：
- 行 218-225：`_InsuranceCard` 头部右侧有一个 36×28 透明白色装饰小方块，**无语义** —— 应删
- 行 227-228：地点 icon + `-`（占位无数据），死装饰 —— 应删或填真值
- 行 95-106：右上"SI"水印 56sp w900，alpha 15%（西方政务卡常用 SocialInsurance 缩写）—— 标准版风格，可保留但与橙主色不太搭

---

## 3. 长辈版色系基线（参考 `pension_query_page.dart`）

| 元素 | 值 |
|---|---|
| 页面背景 | `AppColors.background` = `#F5F5F5` |
| AppBar | `elderPrimary` 橙 + 白字 + elevation 0 |
| 个人信息卡渐变 | `LinearGradient(colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)], begin: topLeft, end: bottomRight)` |
| 卡片阴影 | `BoxShadow(color: Color(0x33FF6D00), blurRadius: 16, offset: Offset(0, 6))` |
| 卡片圆角 | `AppRadius.large` (12) 或 16 |
| 板块容器 | 白色 surface + `margin-top: Spacing.md` |
| 板块标题 | 24sp w600 (`AppFontSize.elderTitle`) |

---

## 4. 修复方案（精确 文件:行号）

### 4.1 整体框架

**`shebao_query_page.dart:14-32`**（Scaffold + AppBar）整体替换为：

```dart
return Scaffold(
  backgroundColor: AppColors.background,                     // ← #F5F5F5
  appBar: AppBar(
    backgroundColor: AppColors.elderPrimary,                 // ← 橙
    foregroundColor: Colors.white,                           // ← 白字 + 白 icon
    elevation: 0,
    centerTitle: true,
    leading: BackButton(onPressed: () => context.pop()),
    title: const Text(
      '社保查询',
      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),  // 16 → 20
    ),
    // 删 actions（close 与 leading 重复；more_horiz 是死按钮）
  ),
  ...
```

**关键改动**：
- `Colors.white` → `AppColors.background`（背景）
- `Colors.white` → `AppColors.elderPrimary`（AppBar）+ 加 `foregroundColor: Colors.white`
- 删行 25-31 整个 `actions` 列表（BackButton 已是返回入口）
- 标题字号 16 → 20

### 4.2 个人信息卡渐变改橙（行 41-109）

**行 44-50**（蓝色渐变）替换为：
```dart
decoration: BoxDecoration(
  gradient: const LinearGradient(
    colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)],          // ← 蓝改橙
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  ),
  borderRadius: BorderRadius.circular(AppRadius.large),
  boxShadow: const [                                          // ← 加阴影
    BoxShadow(color: Color(0x33FF6D00), blurRadius: 16, offset: Offset(0, 6)),
  ],
),
```

**字号升档**：
- 行 59 标题 `fontSize: 16` → `18`
- 行 68/73 姓名行 `fontSize: 14` → `16`
- 行 84/88 证件号行 `fontSize: 14`/`13` → `16`/`16`

**"SI"水印**（行 95-106）：标准版风格，**建议删除**（橙底卡上的浅白水印识别度低，并与长辈版"质朴清晰"语义不符）。

### 4.3 "险种信息" 板块化（行 110-130）

当前是孤立 Padding；改为白色板块容器：

替换行 111-130 为：
```dart
Container(
  margin: const EdgeInsets.only(top: Spacing.md),
  padding: const EdgeInsets.symmetric(
    horizontal: Spacing.lg,
    vertical: Spacing.lg,
  ),
  color: AppColors.surface,                                  // ← 白板块
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: [
          Container(width: 4, height: 24, color: AppColors.elderPrimary),
          const SizedBox(width: Spacing.sm),
          const Text(
            '险种信息',
            style: TextStyle(
              fontSize: AppFontSize.elderTitle,              // 16 → 24
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: Spacing.md),
      // _InsuranceCard 列表移到这里
      _InsuranceCard(...养老保险...),
      _InsuranceCard(...失业保险...),
      _InsuranceCard(...工伤保险...),
    ],
  ),
),
```

**注**：现有 `_InsuranceCard` 在板块外（行 132-145），改造后把 3 张卡放到 Container 内；并把卡的 `margin: EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm)`（行 178-181）改为仅 `vertical: Spacing.sm`（水平边距由板块 padding 承担）。

### 4.4 `_InsuranceCard` 头部改色 + 字号升档（行 162-266）

**行 195-203**（深蓝紫渐变）替换为：
```dart
decoration: BoxDecoration(
  // 用稳重的深灰渐变（保持卡片厚重感，但去掉跟长辈橙冲突的蓝紫）
  // 备选 1：深灰 → 浅灰
  color: const Color(0xFF424242),
  // 备选 2：长辈橙渐变（与个人信息卡一致）
  // gradient: const LinearGradient(
  //   colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)],
  //   begin: Alignment.centerLeft, end: Alignment.centerRight,
  // ),
  borderRadius: BorderRadius.vertical(
    top: Radius.circular(AppRadius.large - 1),
  ),
),
```

**推荐：深灰 `#424242`**——避免和上方"个人信息卡"橙色撞色，又不引入蓝紫；浙里办原版险种卡也用深色稳重风。

**删除装饰元素**：
- 行 218-225 透明白色 36×28 小方块 —— 删
- 行 227-228 地点 icon + `-` —— 删（数据占位）

**字号升档**：
- 行 207 icon size 20 → 24
- 行 211-215 title `fontSize: 15` → `18`
- 行 237 状态行 `fontSize: 13` → `16`
- 行 249 "基本信息" `fontSize: 14` → `18`
- 行 256 "缴费信息" `fontSize: 14` → `18` + 加灰化 `style: TextButton.styleFrom(foregroundColor: Colors.grey)` 让 disabled 状态明显

操作按钮区颜色统一用 `elderPrimary` 橙：
- 行 246-250 TextButton 加 `style: TextButton.styleFrom(foregroundColor: AppColors.elderPrimary)`

---

## 5. 改动清单与优先级

| # | 文件:行 | 改动 | 优先级 |
|---|---|---|---|
| 1 | 15, 17, 23 | Scaffold/AppBar 改橙底 + 灰背景 + 20sp 标题 + 白字 | P0 |
| 2 | 25-31 | 删 AppBar actions（close + more_horiz） | P0 |
| 3 | 44-50 | 个人信息卡渐变蓝→橙 + 加橙阴影 | P0 🔴 |
| 4 | 59, 67-90 | 个人信息卡字号升档 14-16 → 16-18 | P1 |
| 5 | 95-106 | 删"SI"水印 | P2 |
| 6 | 110-130 | "险种信息" 改板块化容器 | P1 |
| 7 | 124-128 | "险种信息"标题 16 → 24sp | P1 |
| 8 | 195-203 | _InsuranceCard 头部深蓝紫 → 深灰 `#424242` | P0 🔴 |
| 9 | 207, 211-215, 237, 249, 256 | _InsuranceCard 内部字号升档 13-15 → 16-18 | P1 |
| 10 | 218-228 | 删装饰小方块 + 死占位 icon `-` | P2 |
| 11 | 246-258 | 操作按钮加 `elderPrimary` 橙色 + "缴费信息" disabled 灰化 | P1 |

**P0（必修，主色系错误）**：#1 #2 #3 #8 —— ~30min
**P1（论文必修，字号 + 结构）**：#4 #6 #7 #9 #11 —— ~30min
**P2（锦上添花）**：#5 #10 —— ~10min

**总工作量 ~1h**。

---

## 6. 改完后预览

```
┌────────────────────────────────────────┐
│ ← 社保查询                  ⋮          │ ← 橙底白字 AppBar 20sp（删 close/more）
├────────────────────────────────────────┤ ← 灰底 #F5F5F5
│                                         │
│ ┌──────────────────────────────────┐  │ ← 橙渐变个人信息卡（橙阴影）
│ │ 个人基本信息                       │  │   标题 18sp w700
│ │ 姓名                       *小明   │  │   字段 16sp
│ │ 证件号码    3****************3     │  │
│ └──────────────────────────────────┘  │
│                                         │
│ ┌──────────────────────────────────┐  │ ← 白板块"险种信息"
│ │ │ 险种信息                          │  │   24sp w600 + 橙竖条
│ │                                    │  │
│ │ ┌──────────────────────────────┐ │  │ ← _InsuranceCard
│ │ │ ▓ 企业职工基本养老保险           │ │  │   深灰头部 18sp
│ │ │ 参保状态：未在浙江省内参保         │ │  │   状态 16sp
│ │ │ [基本信息]   │   [缴费信息（灰）]│ │  │   按钮橙色 18sp
│ │ └──────────────────────────────┘ │  │
│ │ ┌──────────────────────────────┐ │  │
│ │ │ ▓ 失业保险                       │ │  │
│ │ │ ...                              │ │  │
│ │ └──────────────────────────────┘ │  │
│ │ ┌──────────────────────────────┐ │  │
│ │ │ ▓ 工伤保险                       │ │  │
│ │ │ ...                              │ │  │
│ │ └──────────────────────────────┘ │  │
│ └──────────────────────────────────┘  │
└────────────────────────────────────────┘
```

---

## 7. 测试 checklist

- [ ] 顶部 AppBar 是橙色，标题"社保查询"白色 20sp，无 close / more_horiz 按钮
- [ ] 页面背景灰色 `#F5F5F5`
- [ ] 个人信息卡是**橙色渐变**，标题 18sp，字段 16sp
- [ ] "SI"水印已移除
- [ ] "险种信息" 是独立白色板块，标题 24sp + 橙竖条
- [ ] _InsuranceCard 头部是**深灰**（不是蓝紫）
- [ ] _InsuranceCard 标题 18sp、状态 16sp、按钮 18sp 橙色
- [ ] "缴费信息"按钮视觉为灰色 disabled
- [ ] 整体看起来"和养老金查询、医保查询是同一个 App"

---

## 8. 与其他改造的关系

本改造与 `pension_query_page.dart` 的视觉风格**应当一致**（橙渐变个人信息卡 + 浅阴影 + 适老化字号）。改完后两个页面互为对照，论文里可一起截图作为"长辈版统一视觉语言"的案例。

`yibao_query_page.dart` 也有相同的"蓝色个人信息卡"问题（行 90-114 区域）—— 建议在同一轮改造里**一并修**：把 `yibao_query_page.dart:88-90` 附近的渐变改成同款橙色，保持三页面（社保查询 / 养老金查询 / 医保查询）色系一致。如需，可另起一份小修复单。
