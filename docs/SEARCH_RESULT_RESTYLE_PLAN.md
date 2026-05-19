# 搜索结果页 — 视觉风格统一改造方案

> **日期**：2026-05-19 ｜ **作者**：architect
> **触发**：用户反馈搜索结果页风格与其他长辈版页面差别大

---

## 1. TL;DR

搜索结果页的视觉语言**还停留在标准版的"灰白扁平 + 分割线列表"**，与长辈版其余页面（elder_home / mine_page / pension_query）的"灰底 + 白板块卡片 + 橙强调"风格脱节。需要从 5 个维度统一：背景色、AppBar、板块化分组、列表项卡片化、字号阶梯。

---

## 2. 长辈版主导视觉语言（基线）

从 `elder_home.dart / mine_page.dart / pension_query_page.dart / shebao_query_page.dart` 提取：

| 维度 | 主导值 | 来源 |
|---|---|---|
| 页面背景 | `AppColors.background` = `#F5F5F5` 灰 | elder_home:41, mine_page:20 |
| **AppBar** | `AppColors.elderPrimary` 橙 + 白字 + elevation 0 | elder_home:44, mine_page:23, pension_query:45 |
| AppBar 标题 | 20-22sp w600/w700 白色 | mine_page:30, pension_query:48 |
| 板块容器 | `AppColors.surface`(白) + `margin-top: Spacing.md` 把板块分块 | elder_home 多处 |
| 板块标题 | `AppFontSize.elderTitle` = **24sp w600** | elder_home:595, 884 |
| 卡片圆角 | `AppRadius.large`(12) 或 `xlarge`(16) | 通用 |
| 卡片阴影 | `BoxShadow(Color(0x08-0x0F000000), blurRadius:8-12, offset:(0,2-4))` 浅而虚 | pension_query:134, 187 |
| icon 容器 | **44-56dp** + bg `iconColor.withValues(alpha:0.12-0.15)` + 圆形 | 各 _EldServiceCard / mine_page |
| 列表项卡片 title | **18-20sp w600** | elder_home / pension_query 各处 |
| 次级信息 | **14-16sp + textSecondary `#999999`** | 通用 |
| 强调色 | `elderPrimary` = `#FF6D00` 橙 | 全局 |

---

## 3. 搜索结果页与基线的差异（逐项对照）

`search_result_page.dart` 当前状态：

| 维度 | 当前 | 基线 | 差距 |
|---|---|---|---|
| **页面背景** | `Colors.white`（行 75） | `#F5F5F5` 灰 | 🔴 缺 "灰底白板块" 对比关系 |
| **AppBar** | **没有 AppBar**；顶栏是自绘 `_ResultTopBar`（灰圆角输入框） | 橙底 AppBar | 🔴 整体风格完全不一致 |
| 板块容器 | 无；整页平铺，仅 `Divider` 分隔 | 白板块 + margin 分隔 | 🔴 没有"卡片化分组" |
| `_SectionHeader` 字号 | **18sp w700**（行 396） | 24sp w600 | ⚠️ 字号差 6sp |
| 列表项呈现 | InkWell + 横向 padding + bottom divider | 独立卡片 / 卡片组 | 🔴 风格陈旧 |
| `_ServiceItem` icon 容器 | **36×36** + alpha 0.12 | 44-56dp + 同色 | ⚠️ 偏小 |
| `_ServiceItem` icon size | **18** | 22-30 | ⚠️ 偏小 |
| `_ServiceItem` title | **16sp w600** | 18-20sp w600 | ⚠️ |
| `_ServiceItem` chips | **12sp** | 14-16sp | ⚠️ |
| `_ServiceItem` dept | **12sp** | 14sp | ⚠️ |
| 圆角 | 容器无圆角 | large/xlarge | 🔴 缺 |
| 阴影 | 无 | 浅黑 8%/15% | 🔴 缺 |
| `_AffairItem` | 紧凑行 + 15sp + 18-size chevron | 至少 18sp + 圆角卡片 | 🔴 风格违和 |
| 强调色 | 橙 ✅ | 橙 | ✅ 唯一一致项 |

---

## 4. 重设计方案

**核心思路**：把搜索结果页"翻新"成与 elder_home 的服务区相同的视觉语言——**灰底大背景 + 多层白色圆角板块 + 卡片化列表项 + 24sp 板块标题**。

### 4.1 整体骨架（伪结构）

```
Scaffold(
  backgroundColor: AppColors.background,                ← #F5F5F5 灰
  appBar: AppBar(
    backgroundColor: AppColors.elderPrimary,            ← 橙
    elevation: 0,
    foregroundColor: Colors.white,
    title: TextField(...white pill...),                 ← 搜索框嵌入 AppBar
    actions: [TextButton('取消')],
  ),
  body: ListView/SingleChildScroll(
    children: [
      // 板块 1：服务
      Container(
        margin: EdgeInsets.only(top: Spacing.md),
        padding: EdgeInsets.all(Spacing.lg),
        color: AppColors.surface,                        ← 白底
        child: Column([
          Text('服务', 24sp w600),
          SizedBox(height: Spacing.md),
          _ServiceCard(...),                             ← 卡片化
          SizedBox(height: Spacing.md),
          _ServiceCard(...),
        ])
      ),
      // 板块 2：办事
      Container(...同上...)
    ]
  )
)
```

### 4.2 关键改动 — 文件:行号

#### A. Scaffold 背景与 AppBar（`search_result_page.dart:74-89`）

当前：
```dart
return Scaffold(
  backgroundColor: Colors.white,
  body: Stack(
    children: [
      SafeArea(
        child: Column(
          children: [
            _ResultTopBar(...),     ← 自绘顶栏
            const Divider(height: 1),
            ...
```

替换为：
```dart
return Scaffold(
  backgroundColor: AppColors.background,      // ← #F5F5F5
  appBar: _buildAppBar(context),              // ← 橙底 AppBar
  body: Stack(
    children: [
      SafeArea(
        top: false,                            // ← AppBar 已占顶部
        child: Column(
          children: [
            if (_isEditing)
              Expanded(child: SearchSuggestionList(...))
            else
              Expanded(child: _ResultBody(query: q)),
            ...
```

新增 `_buildAppBar` 方法（约 25 行），把搜索框 + "取消"放进 AppBar 的 `title` 与 `actions`：

```dart
PreferredSizeWidget _buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: AppColors.elderPrimary,
    elevation: 0,
    foregroundColor: Colors.white,
    leadingWidth: 56,
    title: Container(
      height: 44,                              // ← 触控达标
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: _onSubmit,
        onTap: _onFieldTap,
        style: const TextStyle(fontSize: AppFontSize.elderBody, color: AppColors.textPrimary),  // 18sp
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
          prefixIcon: const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.cancel, size: 22, color: AppColors.textSecondary),
                  onPressed: _onClearTap,
                )
              : null,
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => context.pop(),
        style: TextButton.styleFrom(foregroundColor: Colors.white),
        child: const Text('取消',
            style: TextStyle(fontSize: AppFontSize.elderBody, color: Colors.white)),  // 18sp 白色
      ),
    ],
  );
}
```

**搜索框嵌入 AppBar** 是浙里办原版的处理方式（参见 elder_home 顶栏白色搜索条 + 橙底），与首页风格统一。

整段 `_ResultTopBar` 类（行 115-206）可以**删除**（它的功能完全被 AppBar 替代）。

#### B. 删 `_ResultTabRow`（行 96-97 + 210-267）

`_ResultBody` 包了所有内容（已在前一份审查 §6.3 说明 Tab 切换无意义）。改造后顶部直接是板块化的"服务"区。

#### C. `_ResultBody` 改为板块化（行 271-311）

整体替换为：

```dart
class _ResultBody extends StatelessWidget {
  final String query;
  const _ResultBody({required this.query});

  bool get _isMedicalPay {
    const aliases = ['医保缴费', '少儿医保缴费', '医保缴费记录',
                     '农村医保缴费', '城乡居民医保缴费', '社保费缴纳'];
    return aliases.contains(query);
  }

  bool get _isPensionQuery {
    const aliases = ['养老金查询', '本月养老金', '养老金账单',
                     '退休待遇测算', '养老金测算'];
    return aliases.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 板块 1：服务
          Container(
            margin: const EdgeInsets.only(top: Spacing.md),
            padding: const EdgeInsets.all(Spacing.lg),
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('服务',
                    style: TextStyle(
                      fontSize: AppFontSize.elderTitle,    // 24
                      fontWeight: FontWeight.w600,
                    )),
                const SizedBox(height: Spacing.md),
                if (_isMedicalPay) ..._medicalPayServices(context),
                if (_isPensionQuery) ..._pensionServices(context),
                if (!_isMedicalPay && !_isPensionQuery)
                  const _EmptyHint(),
              ],
            ),
          ),
          // 板块 2：办事
          if (_isMedicalPay || _isPensionQuery)
            Container(
              margin: const EdgeInsets.only(top: Spacing.md),
              padding: const EdgeInsets.all(Spacing.lg),
              color: AppColors.surface,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('办事',
                      style: TextStyle(
                        fontSize: AppFontSize.elderTitle,
                        fontWeight: FontWeight.w600,
                      )),
                  const SizedBox(height: Spacing.md),
                  if (_isMedicalPay) ..._medicalPayAffairs(),
                  if (_isPensionQuery) ..._pensionAffairs(),
                ],
              ),
            ),
          const SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }
  // ... _medicalPayServices / _pensionServices / ... 见下方
}
```

去掉了 `_SectionHeader`（板块标题已内联）+ "查看更多"文字 + 跨板块 Divider。

新增 `_EmptyHint`（小组件）：
```dart
class _EmptyHint extends StatelessWidget {
  const _EmptyHint();
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.lg),
      child: Center(
        child: Text('暂无相关服务',
            style: TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            )),
      ),
    );
  }
}
```

#### D. `_ServiceItem` 卡片化（行 401-470）

整体替换为**白底独立卡片**（与 pension_query 的金额卡 / 个人信息卡同款）：

```dart
class _ServiceItem extends StatelessWidget {
  final Color iconColor;
  final IconData icon;
  final String title;
  final List<String> chips;
  final String department;
  final VoidCallback? onTap;

  const _ServiceItem({
    required this.iconColor,
    required this.icon,
    required this.title,
    required this.chips,
    required this.department,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.md),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.large),
              border: Border.all(color: AppColors.divider),
              boxShadow: disabled
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x08000000),
                        blurRadius: 8,
                        offset: Offset(0, 2),
                      ),
                    ],
            ),
            padding: const EdgeInsets.all(Spacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: (disabled ? Colors.grey : iconColor).withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon,
                      color: disabled ? Colors.grey : iconColor,
                      size: 26),
                ),
                const SizedBox(width: Spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: disabled
                                ? Colors.grey
                                : AppColors.textPrimary,
                          )),
                      if (chips.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: chips.map((c) => Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(c,
                                    style: const TextStyle(
                                        fontSize: 14,
                                        color: AppColors.textSecondary)),
                              )).toList(),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(department,
                          style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    size: 24,
                    color: disabled ? Colors.grey.shade300 : AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

**关键改动**：
- 卡片化（圆角 12 + 浅边框 + 阴影 0x08）
- icon 容器 36→**48**, icon size 18→**26**
- title 16→**20** w600
- chips 12→**14**, chip 用淡灰填充背景代替边框
- department 12→**14**
- chevron 默认→**24**, 与 disabled 状态同步灰化
- disabled 状态：所有元素改 grey；阴影去除

#### E. `_AffairItem` 卡片化（行 472-489）

整体替换为：
```dart
class _AffairItem extends StatelessWidget {
  final String title;
  const _AffairItem(this.title);

  @override
  Widget build(BuildContext context) {
    // 暂未开通：disabled 灰化样式
    return Padding(
      padding: const EdgeInsets.only(bottom: Spacing.sm),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.medium),
          border: Border.all(color: AppColors.divider),
        ),
        padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md, vertical: Spacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(title,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey.shade500,
                  )),
            ),
            Icon(Icons.chevron_right, size: 24, color: Colors.grey.shade300),
          ],
        ),
      ),
    );
  }
}
```

**关键改动**：
- 字号 15→18
- 单卡呈现（小圆角 8 + 浅边框）
- 永久灰化（既无 onTap，视觉上明示禁用）
- chevron size 18→24，灰化

---

## 5. 改动文件清单

| # | 文件:行 | 改动 | 行数 |
|---|---|---|---|
| 1 | search_result_page.dart:74 | `backgroundColor: Colors.white` → `AppColors.background` | 1 |
| 2 | search_result_page.dart:74-89 | 用 `_buildAppBar` 替换自绘 _ResultTopBar | ~30 |
| 3 | search_result_page.dart:115-206 | **删除整个 `_ResultTopBar` 类**（约 92 行） | -92 |
| 4 | search_result_page.dart:96-97 | 删 `_ResultTabRow` 调用 + Divider | -2 |
| 5 | search_result_page.dart:210-267 | **删除整个 `_ResultTabRow` 与 `_TabLabel` 类** | -58 |
| 6 | search_result_page.dart:271-311 `_ResultBody` | 用板块化结构重写 | ~50 |
| 7 | search_result_page.dart:388-399 `_SectionHeader` | **删除**（板块标题已内联） | -12 |
| 8 | search_result_page.dart:401-470 `_ServiceItem` | 卡片化重写（圆角 + 阴影 + 字号升档 + disabled 状态） | ~80 |
| 9 | search_result_page.dart:472-489 `_AffairItem` | 卡片化 + 18sp + disabled 灰化 | ~25 |
| 10 | search_result_page.dart 顶部 | 加 `_EmptyHint` 小组件 | ~13 |
| 11 | search_result_page.dart 行 282-294 / 343-371 | 把 query 等号判断改为 `_isMedicalPay` / `_isPensionQuery` getter，包含派生关键词 | ~10 |

**净行数变化**：-89 → +208 ≈ +120 行；**实际工作量**：~1.5h。

---

## 6. 改完后视觉预览

```
┌──────────────────────────────────────────┐
│ ▢ [🔍 医保缴费             ⊗]     取消   │ ← AppBar 橙底，白色 pill 搜索框
├──────────────────────────────────────────┤
│                                           │ ← 灰底 #F5F5F5
│ ┌────────────────────────────────────┐   │ ← 白板块 1（边到边）
│ │ 服务                                │   │ ← 24sp w600
│ │                                     │   │
│ │ ┌──────────────────────────────┐   │   │ ← 卡片化
│ │ │ [💊] 浙里医保（灰）        ›   │   │   │ ← title 20sp 灰
│ │ │      [医保地图] [医保账户]    │   │   │ ← chips 14sp
│ │ │      省医保局                 │   │   │ ← dept 14sp
│ │ └──────────────────────────────┘   │   │
│ │ ┌──────────────────────────────┐   │   │
│ │ │ [📋] 社保费缴纳            ›   │   │   │ ← 可点，黑字
│ │ │      [社保医保缴费]            │   │   │
│ │ │      省税务局                  │   │   │
│ │ └──────────────────────────────┘   │   │
│ └────────────────────────────────────┘   │
│                                           │ ← 板块间灰间隙
│ ┌────────────────────────────────────┐   │
│ │ 办事                                │   │ ← 白板块 2
│ │ ┌──────────────────────────────┐   │   │
│ │ │ 职工参保登记（医保）       ›   │   │   │ ← 18sp 灰 disabled
│ │ └──────────────────────────────┘   │   │
│ └────────────────────────────────────┘   │
└──────────────────────────────────────────┘
```

视觉与 elder_home / pension_query 的"灰底 + 多板块 + 圆角卡片 + 24sp 标题"完全一致。

---

## 7. 测试 checklist

- [ ] 背景色是 `#F5F5F5`（不是纯白）
- [ ] 顶部有橙色 AppBar，白色 pill 搜索框嵌入，"取消"按钮在右侧白字
- [ ] "服务"和"办事"是两个独立白板块，板块标题 24sp
- [ ] _ServiceItem 是有圆角 + 浅阴影的独立卡片
- [ ] _ServiceItem 可点项黑字、不可点项灰字
- [ ] _AffairItem 是浅边框卡片，永久灰色字体，无 onTap
- [ ] 不再有"西湖区"、4 个 Tab、"查看更多搜索结果"
- [ ] 从联想"少儿医保缴费"点进来能看到 _medicalPayServices 卡片（修 #11 后）
- [ ] 整体看起来"和长辈版首页是同一个应用"

---

## 8. 与前份审查的关系

本份 (`SEARCH_RESULT_RESTYLE_PLAN.md`) 与 (`SEARCH_RESULT_PAGE_AUDIT.md`) **互补**：

- 前份关注**单项指标修复**（字号、触控、死按钮逐条改）
- 本份关注**整体风格统一**（重塑骨架：背景 + AppBar + 板块化 + 卡片化）

**建议合并实施**：开发可按本份的"完整重写方案"直接做，前份的字号/触控/死按钮修复**自然包含在本方案内**（板块化时一并升档）。前份当作 P0 修复清单的备份。
