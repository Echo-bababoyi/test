# 医保缴费技术实施方案

> **作者**：architect
> **日期**：2026-05-20
> **会话**：session-11b
> **依据**：`docs/YIBAO_JIAOFEI_PM_SPEC.md`（PM 方案）+ `docs/YIBAO_JIAOFEI_FLOW_AUDIT.md`（审查报告）
> **交付对象**：frontend（可直接按行号实施）
> **基线 commit**：13779bf

---

## 目录

- §1 实施顺序（依赖图 + P0/P1 排期）
- §2 入口修正（4 处）— `文件:行号` 级别 diff
- §3 路由注册变更 — `router.dart` 完整 diff
- §4 新建页面骨架（4 个）
- §5 `YibaoJiaofeiPage` 改造（双状态脱敏 + 险种/档次联动 + 条件字段）
- §6 共用 widget / service 抽取建议
- §7 验收 checklist

---

## §1 实施顺序与依赖图

```
[A] router.dart 新增 5 个路由常量 + 5 个 GoRoute
        │
        ├──> [B] 新建 4 个空骨架页（先能跳通，再填内容）
        │        ├─ YibaoHubPage
        │        ├─ PayConfirmPage
        │        ├─ PayPasswordPage
        │        └─ PayResultPage
        │
        ├──> [C] 入口修正 4 处（依赖 A 的常量）
        │        ├─ elder_home.dart × 2
        │        ├─ search_page.dart × 1
        │        └─ search_result_page.dart × 1
        │
        ├──> [D] 改造 YibaoJiaofeiPage（去支付按钮接 [B] 的 PayConfirmPage）
        │
        └──> [E] 填充 4 个新页内容（按 §4 骨架）
```

**P0 实施顺序（不依赖 P1）**：A → B（骨架，按钮挂 SnackBar 占位）→ C → D（仅"去支付"挂 PayConfirmPage）→ E（基础版本，无双状态脱敏、无险种联动）

**P1（演示完整链路前补）**：YibaoJiaofeiPage 险种/档次联动 + 双状态脱敏 + 条件字段（§5 完整版）+ 搜索别名表扩充 + `_isMedicalQuery` 分支。

---

## §2 入口修正（4 处）

### 修正 #1 — `elder_home.dart:577` 九宫格「健康医保」

**位置**：`app/lib/pages/elder_home.dart:613-615`（onTap 三元判断分支）

**原代码**：
```dart
                  onTap: item.label == '健康医保'
                      ? () => LoginGuard.tryNavigate(context, AppRoutes.shebaoJiaona)
                      : () => _showTodo(context),
```

**新代码**：
```dart
                  onTap: item.label == '健康医保'
                      ? () => LoginGuard.tryNavigate(context, AppRoutes.yibaoHub)
                      : () => _showTodo(context),
```

**说明**：仅替换路由常量。LoginGuard 已存在，鉴权 → face_auth → verify 链路无需改。

---

### 修正 #2 — `elder_home.dart:436-442` 常用卡「浙里医保」

**位置**：`app/lib/pages/elder_home.dart:436-442`（`_EldFavoritesContent` 内）

**原代码**：
```dart
              Expanded(
                child: _EldServiceCard(
                  icon: Icons.health_and_safety,
                  iconColor: const Color(0xFF3B82F6),
                  label: '浙里医保',
                  onTap: () => _showTodo(context),
                ),
              ),
```

**新代码**：
```dart
              Expanded(
                child: _EldServiceCard(
                  icon: Icons.health_and_safety,
                  iconColor: const Color(0xFF3B82F6),
                  label: '浙里医保',
                  onTap: () => LoginGuard.tryNavigate(context, AppRoutes.yibaoHub),
                ),
              ),
```

**说明**：`LoginGuard` 已在 elder_home.dart 顶部 import（行 10 `import '../widgets/login_guard.dart';`），直接调用即可。

---

### 修正 #3 — `search_page.dart:234-240` QuickItem「医保查询」错跳 Bug

**位置**：`app/lib/pages/search_page.dart:234-240`

**原代码**：
```dart
              Expanded(
                child: _QuickItem(
                  icon: Icons.health_and_safety_outlined,
                  iconColor: AppColors.elderPrimary,
                  label: '医保查询',
                  onTap: () => LoginGuard.tryNavigate(context, AppRoutes.shebaoJiaona),
                ),
              ),
```

**新代码**：
```dart
              Expanded(
                child: _QuickItem(
                  icon: Icons.health_and_safety_outlined,
                  iconColor: AppColors.elderPrimary,
                  label: '医保查询',
                  onTap: () => LoginGuard.tryNavigate(context, AppRoutes.yibaoQuery),
                ),
              ),
```

**说明**：路由错配 Bug 修复。label 写"查询"，路由应跳 `yibaoQuery`（现有页），不是 `shebaoJiaona`（缴费 hub）。

---

### 修正 #4 — `search_result_page.dart:231-256` 医保服务 cards 路由修正

**位置**：`app/lib/pages/search_result_page.dart:231-256`（`_medicalPayServices` 方法）

**原代码（行 231-256）**：
```dart
  List<Widget> _medicalPayServices(BuildContext context) => [
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.health_and_safety_outlined,
          title: '浙里医保',
          chips: const ['医保地图', '医保个人账户', '医保'],
          department: '省医保局',
          onTap: () => context.push(AppRoutes.yibaoQuery),
        ),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.manage_search,
          title: '社保费缴纳',
          chips: const ['社保医保缴费', '城乡居民基本医'],
          department: '省税务局',
          onTap: () => context.push(AppRoutes.shebaoJiaona),
        ),
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.search,
          title: '社保查询',
          chips: const [],
          department: '省人力社保厅',
          onTap: () => context.push(AppRoutes.shebaoQuery),
        ),
      ];
```

**新代码**：
```dart
  List<Widget> _medicalPayServices(BuildContext context) => [
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.health_and_safety_outlined,
          title: '浙里医保',
          chips: const ['医保地图', '医保个人账户', '医保'],
          department: '省医保局',
          onTap: () => context.push(AppRoutes.yibaoJiaofei),  // ← 改 yibaoQuery → yibaoJiaofei
        ),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.manage_search,
          title: '社保费缴纳',
          chips: const ['社保医保缴费', '城乡居民基本医'],
          department: '省税务局',
          onTap: () => context.push(AppRoutes.shebaoJiaona),
        ),
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.search,
          title: '社保查询',
          chips: const [],
          department: '省人力社保厅',
          onTap: () => context.push(AppRoutes.shebaoQuery),
        ),
      ];
```

**说明**：用户搜「医保缴费」上下文下，「浙里医保」card 应导向缴费页而非查询页。`_isMedicalQuery` 新分支见 §2 后续 P1 子项。

---

### 修正 #4-补（P1）— `search_result_page.dart:157-179` 别名表扩充 + 新增 `_isMedicalQuery` 分支

**位置**：`app/lib/pages/search_result_page.dart:157-179`（`_ResultBody` 类内）

**原代码**：
```dart
  bool get _isMedicalPay {
    const aliases = [
      '医保缴费',
      '少儿医保缴费',
      '医保缴费记录',
      '农村医保缴费',
      '城乡居民医保缴费',
      '社保费缴纳',
    ];
    return aliases.contains(query);
  }

  bool get _isPensionQuery {
    const aliases = [
      '养老金',
      '养老金查询',
      '本月养老金',
      '养老金账单',
      '退休待遇测算',
      '养老金测算',
    ];
    return aliases.contains(query);
  }
```

**新代码**：
```dart
  bool get _isMedicalQuery {
    const aliases = [
      '医保查询', '医保余额', '医保账户', '医保余额查询',
    ];
    return aliases.contains(query);
  }

  bool get _isMedicalPay {
    const aliases = [
      // 原有
      '医保缴费', '少儿医保缴费', '医保缴费记录', '农村医保缴费',
      '城乡居民医保缴费', '社保费缴纳',
      // 新增
      '医保', '浙里医保', '健康医保', '居民医保', '城乡居民医保',
      '缴医保', '交医保',
    ];
    return aliases.contains(query);
  }

  bool get _isPensionQuery {
    const aliases = [
      '养老金', '养老金查询', '本月养老金', '养老金账单',
      '退休待遇测算', '养老金测算',
    ];
    return aliases.contains(query);
  }
```

**配套修改 `build()` 方法（行 200-203）**：
```dart
                // 原：
                if (_isMedicalPay) ..._medicalPayServices(context),
                if (_isPensionQuery) ..._pensionServices(context),
                if (!_isMedicalPay && !_isPensionQuery) const _EmptyHint(),

                // 改为（_isMedicalQuery 优先级最高，避免与 _isMedicalPay 冲突）：
                if (_isMedicalQuery) ..._medicalQueryServices(context),
                if (!_isMedicalQuery && _isMedicalPay) ..._medicalPayServices(context),
                if (_isPensionQuery) ..._pensionServices(context),
                if (!_isMedicalQuery && !_isMedicalPay && !_isPensionQuery)
                  const _EmptyHint(),
```

**新增 `_medicalQueryServices()` 方法**（紧贴 `_medicalPayServices` 下方）：
```dart
  List<Widget> _medicalQueryServices(BuildContext context) => [
        _ServiceItem(
          iconColor: AppColors.elderPrimary,
          icon: Icons.health_and_safety_outlined,
          title: '浙里医保',
          chips: const ['医保余额', '医保账户'],
          department: '省医保局',
          onTap: () => context.push(AppRoutes.yibaoQuery),
        ),
        _ServiceItem(
          iconColor: const Color(0xFFFF6D00),
          icon: Icons.manage_search,
          title: '医保缴费',
          chips: const ['城乡居民医保'],
          department: '省医保局',
          onTap: () => context.push(AppRoutes.yibaoJiaofei),
        ),
      ];
```

**配套办事区域**（行 220-221 加分支）：
```dart
                  if (_isMedicalPay) ..._medicalPayAffairs(),
                  if (_isPensionQuery) ..._pensionAffairs(),
                  if (_isMedicalQuery) ..._medicalQueryAffairs(),  // ← 新增
```

新增 `_medicalQueryAffairs()`：
```dart
  List<Widget> _medicalQueryAffairs() => [
        const _AffairItem('医保参保信息查询'),
        const _AffairItem('医保就诊记录查询'),
      ];
```

**修正 `build()` 行 206 的「办事」区显示条件**：
```dart
// 原：
if (_isMedicalPay || _isPensionQuery)

// 改为：
if (_isMedicalPay || _isPensionQuery || _isMedicalQuery)
```

---

## §3 路由注册变更（router.dart）

**文件**：`app/lib/router.dart`

### Step 3.1 — import 4 个新页面（行 4-22 区间）

在现有 import 列表追加：
```dart
import 'pages/yibao_hub_page.dart';
import 'pages/pay_confirm_page.dart';
import 'pages/pay_password_page.dart';
import 'pages/pay_result_page.dart';
```

### Step 3.2 — `AppRoutes` 类新增常量（行 24-67）

在 `static const yibaoQuery = '/service/yibao-query';`（行 38）之后插入：
```dart
  static const yibaoHub = '/service/yibao-hub';
  static const yibaoJiaofeiConfirm = '/service/yibao-jiaofei/confirm';
  static const yibaoJiaofeiPay = '/service/yibao-jiaofei/pay';
  static const yibaoJiaofeiResult = '/service/yibao-jiaofei/result';
```

`AppRoutes.all` 列表新增一条（在 `('医保缴费', yibaoJiaofei),` 行 62 之前）：
```dart
    ('医保 hub', yibaoHub),
```

（PayConfirm/PayPassword/PayResult 不加入 `all` — 不在 wireframe 索引里展示，避免误入）

### Step 3.3 — `ShellRoute.routes` 新增 4 个 `GoRoute`（行 80-156）

在 `GoRoute(path: AppRoutes.yibaoQuery, ...)`（行 135-137）之后插入：
```dart
        GoRoute(
          path: AppRoutes.yibaoHub,
          pageBuilder: (ctx, st) => _fadePage(const YibaoHubPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofeiConfirm,
          pageBuilder: (ctx, st) => _fadePage(const PayConfirmPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofeiPay,
          pageBuilder: (ctx, st) => _fadePage(const PayPasswordPage()),
        ),
        GoRoute(
          path: AppRoutes.yibaoJiaofeiResult,
          pageBuilder: (ctx, st) => _fadePage(const PayResultPage()),
        ),
```

---

## §4 新建页面骨架（4 个完整文件）

> 颜色统一：`AppColors.elderPrimary = Color(0xFFFF6D00)`、`background = 0xFFF5F5F5`、`surface = 0xFFFFFFFF`、`textPrimary = 0xFF333333`、`textSecondary = 0xFF999999`、`divider = 0xFFE5E5E5`。
>
> 已存在 import 路径：
> - `import 'package:flutter/material.dart';`
> - `import 'package:go_router/go_router.dart';`
> - `import '../router.dart';`
> - `import '../theme/design_tokens.dart';`
> - `import '../widgets/agent_fab.dart';`
> - `import '../widgets/elder_bottom_nav.dart';`

---

### §4.1 新建 `app/lib/pages/yibao_hub_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

class YibaoHubPage extends StatelessWidget {
  const YibaoHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('健康医保',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              _HubCard(
                icon: Icons.medical_services,
                iconColor: AppColors.elderPrimary,
                title: '医保缴费',
                subtitle: '城乡居民医保年度缴费',
                primary: true,
                onTap: () => context.push(AppRoutes.yibaoJiaofei),
              ),
              const SizedBox(height: Spacing.md),
              _HubCard(
                icon: Icons.search,
                iconColor: AppColors.elderPrimary,
                title: '医保查询',
                subtitle: '查询账户余额和状态',
                onTap: () => context.push(AppRoutes.yibaoQuery),
              ),
              const SizedBox(height: Spacing.md),
              _HubCard(
                icon: Icons.receipt_long_outlined,
                iconColor: AppColors.textSecondary,
                title: '缴费记录',
                subtitle: '查看历史缴费明细',
                disabled: true,
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('该功能正在建设中'),
                    duration: Duration(seconds: 2),
                  ),
                ),
              ),
            ],
          ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.yibaoHub),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

class _HubCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool primary;
  final bool disabled;
  final VoidCallback onTap;

  const _HubCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: Container(
          padding: const EdgeInsets.all(Spacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.large),
            border: primary
                ? Border.all(color: AppColors.elderPrimary, width: 1.5)
                : Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 26),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: disabled
                              ? AppColors.textSecondary
                              : AppColors.textPrimary,
                        )),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 14, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 24, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}
```

---

### §4.2 新建 `app/lib/pages/pay_confirm_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/elder_bottom_nav.dart';

class PayConfirmPage extends StatefulWidget {
  const PayConfirmPage({super.key});

  @override
  State<PayConfirmPage> createState() => _PayConfirmPageState();
}

class _PayConfirmPageState extends State<PayConfirmPage> {
  // 银行卡选择（mock，默认选中尾号 5678）
  int _selectedBank = 1;
  static const _banks = [
    ('icbc', '中国工商银行', '1234'),
    ('boc', '中国银行', '5678'),
  ];

  @override
  Widget build(BuildContext context) {
    // TODO: 从路由 extra 取真实金额/险种/对象；当前 mock
    const xianzhong = '城乡居民医保';
    const year = '2026年度';
    const target = '本人';
    const amount = '380.00';
    const userName = '*小明';
    const idMasked = '330****2518';

    final bank = _banks[_selectedBank];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('确认缴费',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      // 注意：本页不放 AgentFab（支付确认环节，代理不干预）
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _SectionCard(
            title: '缴费摘要',
            rows: const [
              ('险种', xianzhong),
              ('缴费年度', year),
              ('缴费对象', target),
            ],
            highlight: ('缴费金额', '¥ $amount'),
          ),
          const SizedBox(height: Spacing.md),
          _SectionCard(
            title: '缴费人信息',
            rows: const [
              ('姓名', userName),
              ('证件号', idMasked),
            ],
          ),
          const SizedBox(height: Spacing.md),
          // 银行卡选择
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: Spacing.sm),
                  child: Text('选择银行卡',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                for (int i = 0; i < _banks.length; i++)
                  RadioListTile<int>(
                    contentPadding: EdgeInsets.zero,
                    value: i,
                    groupValue: _selectedBank,
                    activeColor: AppColors.elderPrimary,
                    title: Text('${_banks[i].$2} 尾号 ${_banks[i].$3}',
                        style: const TextStyle(fontSize: 16)),
                    onChanged: (v) => setState(() => _selectedBank = v!),
                  ),
                TextButton.icon(
                  onPressed: () =>
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('请前往银行柜台或银行 App 绑定银行卡'),
                    duration: Duration(seconds: 2),
                  )),
                  icon: const Icon(Icons.add,
                      color: AppColors.textSecondary, size: 18),
                  label: const Text('添加银行卡',
                      style: TextStyle(
                          fontSize: 14, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text('ⓘ 缴费完成后不支持退款，请确认信息无误',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () => context.push(
                AppRoutes.yibaoJiaofeiPay,
                extra: {
                  'bank_name': bank.$2,
                  'bank_tail': bank.$3,
                  'amount': amount,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.elderPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('确认支付 ¥$amount',
                  style:
                      TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  final (String, String)? highlight;
  const _SectionCard({required this.title, required this.rows, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(row.$1,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(row.$2,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textPrimary)),
                ],
              ),
            ),
          if (highlight != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(highlight!.$1,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(highlight!.$2,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.elderPrimary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
```

---

### §4.3 新建 `app/lib/pages/pay_password_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';

class PayPasswordPage extends StatefulWidget {
  const PayPasswordPage({super.key});

  @override
  State<PayPasswordPage> createState() => _PayPasswordPageState();
}

class _PayPasswordPageState extends State<PayPasswordPage>
    with SingleTickerProviderStateMixin {
  static const _kCorrectPwd = '123456';
  static const _kMaxAttempts = 3;

  String _input = '';
  int _remainingAttempts = _kMaxAttempts;
  String? _errorText;
  bool _locked = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_locked || _input.length >= 6) return;
    setState(() {
      _input += d;
      _errorText = null;
    });
    if (_input.length == 6) {
      _onSubmit();
    }
  }

  void _onDelete() {
    if (_locked || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onCancel() => context.pop();

  void _onSubmit() {
    if (_input == _kCorrectPwd) {
      context.pushReplacement(
        AppRoutes.yibaoJiaofeiResult,
        extra: {'success': true},
      );
      return;
    }
    setState(() {
      _remainingAttempts -= 1;
      _input = '';
      if (_remainingAttempts <= 0) {
        _locked = true;
        _errorText = '支付密码已锁定，请 24 小时后重试';
      } else {
        _errorText = '密码错误，还可尝试 $_remainingAttempts 次';
      }
    });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final bankName = extra?['bank_name'] as String? ?? '中国银行';
    final bankTail = extra?['bank_tail'] as String? ?? '5678';
    final amount = extra?['amount'] as String? ?? '0.00';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('输入支付密码',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      // 注意：本页严禁放 AgentFab（密码安全红线）
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.xl),
            Text('$bankName 尾号$bankTail',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: Spacing.sm),
            Text('¥ $amount',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.elderPrimary)),
            const SizedBox(height: Spacing.xl),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (ctx, child) {
                final dx = _shakeAnim.value == 0
                    ? 0.0
                    : 8 * (1 - _shakeAnim.value) *
                        (((_shakeAnim.value * 1000).toInt() % 4) < 2 ? 1 : -1);
                return Transform.translate(
                    offset: Offset(dx, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _input.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 44,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                          color: filled
                              ? AppColors.elderPrimary
                              : AppColors.divider,
                          width: filled ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: filled
                        ? const Center(
                            child: Icon(Icons.circle,
                                size: 12, color: AppColors.textPrimary))
                        : null,
                  );
                }),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 22,
              child: _errorText != null
                  ? Text(_errorText!,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFFFF3B30)))
                  : null,
            ),
            const SizedBox(height: Spacing.lg),
            _NumPad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              onCancel: _onCancel,
              disabled: _locked,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请携带身份证前往当地社保服务中心重置密码'),
                  duration: Duration(seconds: 3),
                ),
              ),
              child: const Text('忘记密码',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final bool disabled;
  const _NumPad({
    required this.onDigit,
    required this.onDelete,
    required this.onCancel,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child, {VoidCallback? onTap}) => Expanded(
          child: SizedBox(
            height: 56,
            child: InkWell(
              onTap: disabled ? null : onTap,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );

    Widget digit(String d) => cell(
          Text(d,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          onTap: () => onDigit(d),
        );

    return Column(
      children: [
        Row(children: [digit('1'), digit('2'), digit('3')]),
        Row(children: [digit('4'), digit('5'), digit('6')]),
        Row(children: [digit('7'), digit('8'), digit('9')]),
        Row(children: [
          cell(
            const Text('取消',
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary)),
            onTap: onCancel,
          ),
          digit('0'),
          cell(
            const Icon(Icons.backspace_outlined,
                color: AppColors.textPrimary, size: 22),
            onTap: onDelete,
          ),
        ]),
      ],
    );
  }
}
```

---

### §4.4 新建 `app/lib/pages/pay_result_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

class PayResultPage extends StatelessWidget {
  const PayResultPage({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: 从 extra 取实际信息；当前 mock
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final success = extra?['success'] as bool? ?? true;

    const xianzhong = '城乡居民医保';
    const year = '2026年度';
    const amount = '380.00';
    final now = DateTime.now();
    final timeStr =
        '${now.year}-${_z(now.month)}-${_z(now.day)} ${_z(now.hour)}:${_z(now.minute)}:${_z(now.second)}';
    final flowId =
        'ZLS${now.year}${_z(now.month)}${_z(now.day)}${_z(now.hour)}${_z(now.minute)}${_z(now.second)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('缴费结果',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
        automaticallyImplyLeading: false, // pushReplacement 进入，禁返
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(Spacing.md),
            children: [
              const SizedBox(height: Spacing.xl),
              Icon(
                success ? Icons.check_circle : Icons.cancel,
                size: 72,
                color: success
                    ? const Color(0xFF52C41A)
                    : const Color(0xFFFF3B30),
              ),
              const SizedBox(height: Spacing.md),
              Text(
                success ? '缴费成功' : '缴费失败',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: Spacing.xl),
              Container(
                padding: const EdgeInsets.all(Spacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.large),
                ),
                child: Column(
                  children: [
                    _Row('险种', xianzhong),
                    _Row('缴费年度', year),
                    _Row('金额', '¥ $amount'),
                    _Row('缴费时间', timeStr),
                    _Row('流水号', flowId),
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),
              SizedBox(
                height: 56,
                child: OutlinedButton(
                  onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('电子凭证生成中，请稍后在「缴费记录」中查看'),
                      duration: Duration(seconds: 2),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(
                        color: AppColors.elderPrimary, width: 1.5),
                    foregroundColor: AppColors.elderPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('查看电子凭证',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: Spacing.md),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: () => context.go(AppRoutes.elderHome),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.elderPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('返回首页',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.yibaoJiaofeiResult),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }

  static String _z(int n) => n.toString().padLeft(2, '0');
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  const _Row(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 16, color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 16, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
```

---

## §5 改造现有页面 `YibaoJiaofeiPage`

**文件**：`app/lib/pages/yibao_jiaofei_page.dart`

### §5.1 State 字段变更（行 24-54 整段重写）

**新字段**：
```dart
class _YibaoJiaofeiPageState extends State<YibaoJiaofeiPage> {
  String? _targetPerson = '本人';
  String? _xianzhong = '城乡居民医保';            // 新增：险种
  String? _year = '2026年度';
  _JiaofeiDangci? _dangci = _dangciOptions['城乡居民医保']!.first; // 新增：档次
  final _idController = TextEditingController();
  final _idFocus = FocusNode();                  // 新增：身份证 FocusNode
  final _dailiNameController = TextEditingController(); // 新增：代缴姓名
  final _dailiIdController = TextEditingController();   // 新增：代缴证件
  final _dailiIdFocus = FocusNode();              // 新增

  bool _idFocused = false;        // 新增：控制双状态展示
  bool _dailiIdFocused = false;

  final _targetKey = AgentElementRegistry.register('select_jiaofei_duixiang');
  final _xianzhongKey = AgentElementRegistry.register('select_jiaofei_xianzhong'); // 新增
  final _yearKey = AgentElementRegistry.register('select_jiaofei_niandu');
  final _dangciKey = AgentElementRegistry.register('select_jiaofei_dangci');       // 新增
  final _idKey = AgentElementRegistry.register('input_id_card');
  final _dailiNameKey = AgentElementRegistry.register('input_daili_name');         // 新增
  final _dailiIdKey = AgentElementRegistry.register('input_daili_idcard');         // 新增
  final _submitKey = AgentElementRegistry.register('btn_go_payment');

  static const _persons = ['本人', '配偶', '子女'];
  static const _xianzhongs = ['城乡居民医保', '灵活就业人员医保'];
  static const _years = ['2024年度', '2025年度', '2026年度'];

  // 档次联动 mock 数据
  static final Map<String, List<_JiaofeiDangci>> _dangciOptions = {
    '城乡居民医保': const [
      _JiaofeiDangci('第一档', 380.00),
      _JiaofeiDangci('第二档', 660.00),
      _JiaofeiDangci('第三档', 980.00),
    ],
    '灵活就业人员医保': const [
      _JiaofeiDangci('月缴标准', 450.00),
    ],
  };
  // 险种说明文案
  static const _xianzhongHints = {
    '城乡居民医保': '按年缴费，截止日期每年 12 月 31 日',
    '灵活就业人员医保': '按月缴费，次月生效',
  };

  bool get _needDaili => _targetPerson != null && _targetPerson != '本人';

  bool get _canSubmit {
    if (_targetPerson == null || _xianzhong == null ||
        _year == null || _dangci == null) return false;
    if (_idController.text.length != 18) return false;
    if (_needDaili) {
      if (_dailiNameController.text.isEmpty) return false;
      if (_dailiIdController.text.length != 18) return false;
    }
    return true;
  }

  bool get _idInvalid =>
      _idController.text.isNotEmpty && _idController.text.length != 18;
  bool get _dailiIdInvalid =>
      _dailiIdController.text.isNotEmpty &&
      _dailiIdController.text.length != 18;

  @override
  void initState() {
    super.initState();
    AgentElementRegistry.registerController('input_id_card', _idController);
    AgentElementRegistry.registerController(
        'input_daili_idcard', _dailiIdController);
    _idController.addListener(() => setState(() {}));
    _dailiIdController.addListener(() => setState(() {}));
    _dailiNameController.addListener(() => setState(() {}));
    _idFocus.addListener(() => setState(() => _idFocused = _idFocus.hasFocus));
    _dailiIdFocus.addListener(
        () => setState(() => _dailiIdFocused = _dailiIdFocus.hasFocus));
  }

  @override
  void dispose() {
    _autoSave();
    AgentElementRegistry.unregister('input_id_card');
    AgentElementRegistry.unregister('input_daili_idcard');
    _idController.dispose();
    _idFocus.dispose();
    _dailiNameController.dispose();
    _dailiIdController.dispose();
    _dailiIdFocus.dispose();
    super.dispose();
  }

  void _autoSave() {
    final fields = {
      'target_person': _targetPerson,
      'xianzhong': _xianzhong,
      'year': _year,
      'dangci': _dangci?.label,
      'amount': _dangci?.amount.toStringAsFixed(2),
      'daili_name': _dailiNameController.text,
    };
    final hasContent = fields.values.any((v) => v != null && v.toString().isNotEmpty);
    if (!hasContent) return;
    DraftService.autoSave(
      'yibao_jiaofei',
      '医保缴费',
      fields,
      _idController.text.isNotEmpty || _dailiIdController.text.isNotEmpty,
    );
  }

  void _onXianzhongChanged(String? v) {
    setState(() {
      _xianzhong = v;
      _dangci = v == null ? null : _dangciOptions[v]!.first;
    });
  }

  String _maskId(String id) =>
      id.length == 18 ? '${id.substring(0, 3)}****${id.substring(14)}' : id;
}

// 缴费档次值对象
class _JiaofeiDangci {
  final String label;
  final double amount;
  const _JiaofeiDangci(this.label, this.amount);
}
```

**关键改动点解释**：
- `_amountController` **删除**（金额改为档次联动，不再手动输入）。
- `select_jiaofei_dangci` / `select_jiaofei_xianzhong` / `input_daili_name` / `input_daili_idcard` 4 个新 AgentElementRegistry key。
- `_idFocus` listener 控制 `_idFocused`，配合 `_maskId()` 实现失焦自动脱敏。

### §5.2 build() 改造（行 82-216 整段重写）

将 `ListView` 内的 `Container > Column.children` 替换为：

```dart
                _FieldLabel('缴费对象'),
                DropdownButtonFormField<String>(
                  key: _targetKey,
                  value: _targetPerson,
                  items: _persons.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: (v) => setState(() => _targetPerson = v),
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 20),

                _FieldLabel('险种'),
                DropdownButtonFormField<String>(
                  key: _xianzhongKey,
                  value: _xianzhong,
                  items: _xianzhongs.map((x) => DropdownMenuItem(
                    value: x,
                    child: Text(x, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: _onXianzhongChanged,
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                ),
                if (_xianzhong != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(_xianzhongHints[_xianzhong] ?? '',
                        style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                  ),
                const SizedBox(height: 20),

                _FieldLabel('缴费年度'),
                DropdownButtonFormField<String>(
                  key: _yearKey,
                  value: _year,
                  items: _years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: (v) => setState(() => _year = v),
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 20),

                _FieldLabel('缴费档次'),
                DropdownButtonFormField<_JiaofeiDangci>(
                  key: _dangciKey,
                  value: _dangci,
                  items: (_xianzhong == null
                          ? <_JiaofeiDangci>[]
                          : _dangciOptions[_xianzhong]!)
                      .map((d) => DropdownMenuItem(
                            value: d,
                            child: Text(
                              '${d.label}  ¥ ${d.amount.toStringAsFixed(2)}',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _dangci = v),
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 20),

                _FieldLabel('缴费金额'),
                Container(
                  height: 56,
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    border: Border.all(color: const Color(0xFFE5E5E5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _dangci == null ? '请先选择档次' : '¥ ${_dangci!.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: _dangci == null ? FontWeight.normal : FontWeight.w600,
                      color: _dangci == null ? const Color(0xFF999999) : _kOrange,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                _FieldLabel('身份证号'),
                _MaskedIdField(
                  fieldKey: _idKey,
                  controller: _idController,
                  focusNode: _idFocus,
                  focused: _idFocused,
                  invalid: _idInvalid,
                  decoration: _inputDecoration(),
                  maskFn: _maskId,
                ),
                if (_idInvalid)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('请输入18位身份证号',
                        style: TextStyle(fontSize: 15, color: Color(0xFFFF3B30))),
                  ),

                // 条件区块：被缴费人信息（_needDaili 才展开）
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  child: _needDaili
                      ? Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _kOrange.withValues(alpha: 0.5),
                                width: 1.5,
                              ),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Text('被缴费人信息',
                                      style: TextStyle(fontSize: 14, color: _kOrange)),
                                ),
                                _FieldLabel('被缴费人姓名'),
                                SizedBox(
                                  height: 56,
                                  child: TextField(
                                    key: _dailiNameKey,
                                    controller: _dailiNameController,
                                    decoration: _inputDecoration(),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                _FieldLabel('被缴费人证件号'),
                                _MaskedIdField(
                                  fieldKey: _dailiIdKey,
                                  controller: _dailiIdController,
                                  focusNode: _dailiIdFocus,
                                  focused: _dailiIdFocused,
                                  invalid: _dailiIdInvalid,
                                  decoration: _inputDecoration(),
                                  maskFn: _maskId,
                                ),
                                if (_dailiIdInvalid)
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text('请输入18位身份证号',
                                        style: TextStyle(
                                            fontSize: 15, color: Color(0xFFFF3B30))),
                                  ),
                              ],
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
```

### §5.3「去支付」按钮跳转改造（行 165-183）

**原代码**：
```dart
          SizedBox(
            height: 56,
            child: ElevatedButton(
              key: _submitKey,
              onPressed: _canSubmit ? () {} : null,
              ...
```

**新代码**：
```dart
          SizedBox(
            height: 56,
            child: ElevatedButton(
              key: _submitKey,
              onPressed: _canSubmit
                  ? () => context.push(
                        AppRoutes.yibaoJiaofeiConfirm,
                        extra: {
                          'xianzhong': _xianzhong,
                          'year': _year,
                          'target': _targetPerson,
                          'dangci_label': _dangci!.label,
                          'amount': _dangci!.amount.toStringAsFixed(2),
                          'id_masked': _maskId(_idController.text),
                          if (_needDaili) ...{
                            'daili_name': _dailiNameController.text,
                            'daili_id_masked': _maskId(_dailiIdController.text),
                          },
                        },
                      )
                  : null,
              ...
```

需在文件顶部新增 import：
```dart
import 'package:go_router/go_router.dart';
```

### §5.4 新增私有 widget `_MaskedIdField`

在文件末尾追加：
```dart
class _MaskedIdField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool invalid;
  final InputDecoration decoration;
  final String Function(String) maskFn;

  const _MaskedIdField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.invalid,
    required this.decoration,
    required this.maskFn,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;
    final showMasked = !focused && hasValue && !invalid;

    if (showMasked) {
      return InkWell(
        onTap: () => focusNode.requestFocus(),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(maskFn(controller.text),
                    style: const TextStyle(fontSize: 18)),
              ),
              const Text('编辑',
                  style: TextStyle(fontSize: 14, color: _kOrange)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.text,
        maxLength: 18,
        decoration: decoration.copyWith(counterText: ''),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
```

---

## §6 共用 widget / service 建议

### §6.1 不抽取的部分（保持简单）
- `_SectionCard`（PayConfirmPage 内）— 只本页用，不必抽。
- `_NumPad`（PayPasswordPage 内）— 同上。
- `_HubCard`（YibaoHubPage 内）— 同上。

### §6.2 可选抽取（P2，时间允许）
- 双状态脱敏 `_MaskedIdField` 已是独立 widget，若后续 PayConfirm 或其他表单要复用，可移到 `app/lib/widgets/masked_id_field.dart`。当前只有 1 处使用（YibaoJiaofeiPage 内 2 处实例），不必先抽。
- 脱敏函数 `_maskId()` 若超过 2 处使用，可挪到 `app/lib/services/mask_util.dart`。

### §6.3 AgentFab 不展示策略
PayConfirmPage / PayPasswordPage 直接**不在 Stack 内放 `AgentFab`**。AgentFab 是每个页面手动 mount 的 widget（非全局 overlay），不放即不显示。无需修改 AgentFab 本身。

> ⚠️ frontend 注意：`AgentFab` 在 `agent_fab.dart:385` 维护了 `_pageIdMap`，里面注册了 `/service/yibao-jiaofei` 等路径。新增的 4 个路径暂不需要加入该 map（因为 PayConfirm/PayPassword 不挂 AgentFab，YibaoHub/PayResult 挂的 AgentFab 在不识别路径时不会崩，最多缺少代理快捷操作建议）。后续若希望代理在 Hub 页主动建议「医保缴费」，再补 `_pageIdMap`。

### §6.4 LoginGuard 行为
`yibaoHub` 是登录后才能进入的路由，已通过 `LoginGuard.tryNavigate` 包裹（修正 #1、#2）。从 hub 内进入 `yibaoJiaofei` 时不再二次 LoginGuard — 因为已登录态，`context.push` 即可。**frontend 注意保持**：hub 内的 3 个卡片直接 `context.push`，不再走 LoginGuard。

---

## §7 验收 checklist（frontend 自测 + architect 复审用）

### 路由通达性
- [ ] elder_home「健康医保」九宫格 → yibaoHub ✓
- [ ] elder_home「浙里医保」常用卡 → yibaoHub ✓
- [ ] search_page QuickItem「医保查询」→ yibaoQuery（不再误跳 shebaoJiaona）✓
- [ ] search_result_page 搜「医保缴费」→「浙里医保」card → yibaoJiaofei ✓
- [ ] yibaoHub「医保缴费」→ yibaoJiaofei → 去支付 → PayConfirm → 确认支付 → PayPassword（输 123456）→ PayResult → 返回首页 ✓
- [ ] PayPassword 输错 3 次锁定 → 显示「支付密码已锁定」文案 ✓
- [ ] 路径栈：PayResult 不能 back 回 PayPassword（automaticallyImplyLeading: false + pushReplacement）✓

### 字段敏感度
- [ ] YibaoJiaofeiPage 身份证 TextField 失焦后变 `330****2518` + 「编辑」按钮 ✓
- [ ] 点「编辑」 → 字段清空 + requestFocus + 重新展示 TextField ✓
- [ ] 缴费档次选完，金额行只读展示 `¥ 380.00`（无 TextField）✓
- [ ] PayPasswordPage 输入框 6 格圆点掩码，无「显示密码」开关 ✓
- [ ] PayConfirmPage 银行卡只显示 `中行 尾号5678`，不显示完整卡号 ✓

### 条件字段
- [ ] 缴费对象选「本人」→ 「被缴费人信息」卡不展示 ✓
- [ ] 切到「配偶」/「子女」→ AnimatedSize 200ms 展开 ✓
- [ ] 被缴费人字段未填完 → 「去支付」按钮 disabled ✓

### 代理元素注册
- [ ] AgentElementRegistry 注册新增的 4 个 key：`select_jiaofei_xianzhong` / `select_jiaofei_dangci` / `input_daili_name` / `input_daili_idcard` ✓
- [ ] dispose 时 unregister `input_id_card` 和 `input_daili_idcard` ✓

### 视觉规范
- [ ] 4 个新页 AppBar 都是橙底 + 白前景 + 22sp 标题 ✓
- [ ] PayConfirm / PayPassword 页**没有** AgentFab ✓
- [ ] YibaoHub / PayResult 页**有** AgentFab ✓

### 搜索别名（P1）
- [ ] 搜「医保查询」→ _isMedicalQuery → 渲染 `_medicalQueryServices` ✓
- [ ] 搜「健康医保」/「浙里医保」/「医保」→ _isMedicalPay → 渲染 `_medicalPayServices` ✓
- [ ] 搜「医保缴费」→ _isMedicalPay → 「浙里医保」card 跳 yibaoJiaofei ✓

---

## §8 风险与备注

1. **路由参数传递**：本方案在 yibao_jiaofei → PayConfirm → PayPassword 间用 `extra: {...}` 传 Map，简单可靠但**不可序列化**（GoRouter `extra` 不参与 URL/restoration）。如果未来需要支持深链或会话恢复，要改用 `pathParameters` / `queryParameters`。当前演示阶段 Map 即可。

2. **mock 数据集中点**：PayConfirm / PayResult 的用户姓名 / 证件目前 hardcode，与 yibaoQuery 的 `*小明` 一致。建议 frontend 若有空，把 `('*小明', '330****2518')` 抽到 `app/lib/services/mock_user.dart` 一处定义，避免散落。**非阻塞**。

3. **AnimatedSize 与 Dropdown 焦点**：被缴费人区块用 AnimatedSize 展开时，若上方 Dropdown 处于焦点态可能闪烁。frontend 实测后若出现，将 `_onXianzhongChanged` / `setState(() => _targetPerson = v)` 时附带 `FocusScope.of(context).unfocus()`。

4. **`_dangciOptions` 的 const 限制**：因 `_JiaofeiDangci` 是 const 构造，Map 内层 List 用 `const [...]` 即可。frontend 若改 mock 数据为动态获取，需去掉 const 修饰。

5. **PayPasswordPage 抖动动画**：当前实现用 `AnimatedBuilder` + 余数控制方向，足够演示，效果略 jerky。如不满意可换 `flutter_animate` 包或写一个 `ShakeWidget`。**非阻塞**。

6. **search_result_page `_isMedicalQuery` 判定顺序**：本方案放在 `_isMedicalPay` 前判断（互斥优先），因为「医保查询」也匹配 `'医保'` 子串场景。**别名表里不要让两个分支重叠**（已避免）。

---

## §9 frontend 落地顺序（建议）

1. router.dart 加 5 路由 + 4 import（5 分钟）
2. 4 个新页骨架文件（占位 Scaffold + AppBar + Text，先让路由通）（10 分钟）
3. 4 处入口修正（5 分钟）
4. yibaoJiaofei「去支付」改为跳 PayConfirm（2 分钟）
5. 跑一遍主链路（手动 ElderHome → 健康医保 → 医保缴费 → 去支付 → 确认 → 密码 → 结果）→ 验证 P0 通了
6. 填充 PayConfirm / PayPassword / PayResult 完整内容
7. 改造 YibaoJiaofei 字段（险种/档次/双状态脱敏/条件字段）
8. 扩搜索别名表 + _isMedicalQuery 分支

若时间紧张，6/7/8 步骤可分别属于 P0(基础) / P1(完整) / P1(搜索)。

---

**完。** 全文涉及变更：
- 修改文件 4 个：`router.dart` / `elder_home.dart` / `search_page.dart` / `search_result_page.dart` / `yibao_jiaofei_page.dart`（共 5 个，含 yibao_jiaofei）
- 新建文件 4 个：`yibao_hub_page.dart` / `pay_confirm_page.dart` / `pay_password_page.dart` / `pay_result_page.dart`
- 不修改：AgentFab、LoginGuard、design_tokens、ShebaoJiaona（PM 标 P2，本任务未要求）。
