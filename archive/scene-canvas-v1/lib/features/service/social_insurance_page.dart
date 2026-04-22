import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../services/service_repository.dart';

// 消费 serviceRepositoryProvider — "我为自己缴"子页读取用户社保应缴项
final _selfPayItemsProvider = FutureProvider.autoDispose<List<ServiceItem>>(
  (ref) => ref.read(serviceRepositoryProvider).myFrequent(),
);

enum _SubPage { home, selfPay, payRecords }

class SocialInsurancePage extends ConsumerStatefulWidget {
  const SocialInsurancePage({super.key});

  @override
  ConsumerState<SocialInsurancePage> createState() =>
      _SocialInsurancePageState();
}

class _SocialInsurancePageState extends ConsumerState<SocialInsurancePage> {
  _SubPage _sub = _SubPage.home;

  void _backToHome() => setState(() => _sub = _SubPage.home);

  @override
  Widget build(BuildContext context) {
    final title =
        _sub == _SubPage.payRecords ? '缴费记录' : '社保费缴纳';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          onPressed:
              _sub == _SubPage.home ? () => context.pop() : _backToHome,
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => context.pop(),
          ),
          IconButton(icon: const Icon(Icons.more_horiz), onPressed: null),
        ],
      ),
      body: IndexedStack(
        index: _sub.index,
        children: [
          _HomeSubPage(
            onSelfPay: () => setState(() => _sub = _SubPage.selfPay),
            onPayRecords: () => setState(() => _sub = _SubPage.payRecords),
          ),
          const _SelfPaySubPage(),
          const _PayRecordsSubPage(),
        ],
      ),
    );
  }
}

// ─── 主页子状态 ────────────────────────────────────────────────────────────────

class _HomeSubPage extends StatelessWidget {
  final VoidCallback onSelfPay;
  final VoidCallback onPayRecords;

  const _HomeSubPage({
    required this.onSelfPay,
    required this.onPayRecords,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 蓝色渐变 banner
          Container(
            height: 130,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5BA3E8), Color(0xFF2D74DC)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '社保费缴纳',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '浙江税务',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          // 服务图标 3×3 网格
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.xl,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ServiceIcon(
                      icon: Icons.volunteer_activism,
                      color: AppColors.elderPrimary,
                      label: '我为自己缴',
                      onTap: onSelfPay,
                    ),
                    _ServiceIcon(
                      icon: Icons.account_balance_wallet,
                      color: const Color(0xFF7B61FF),
                      label: '我帮他人缴',
                      onTap: null,
                    ),
                    _ServiceIcon(
                      icon: Icons.badge_outlined,
                      color: const Color(0xFFFF8C00),
                      label: '其他证件缴费',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _ServiceIcon(
                      icon: Icons.description_outlined,
                      color: const Color(0xFFE91E8C),
                      label: '银行缴费协议',
                      onTap: null,
                    ),
                    _ServiceIcon(
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF4CAF50),
                      label: '缴费记录',
                      onTap: onPayRecords,
                    ),
                    _ServiceIcon(
                      icon: Icons.verified_outlined,
                      color: const Color(0xFF2D74DC),
                      label: '缴费证明',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: const [
                    _ServiceIcon(
                      icon: Icons.keyboard_return,
                      color: Color(0xFFFFC107),
                      label: '退费申请',
                      onTap: null,
                    ),
                    _ServiceIcon(
                      icon: Icons.sync_alt,
                      color: Color(0xFFF44336),
                      label: '变更档次',
                      onTap: null,
                    ),
                    _ServiceIcon(
                      icon: Icons.calculate_outlined,
                      color: Color(0xFF5C9BD6),
                      label: '缴费基数',
                      onTap: null,
                    ),
                  ],
                ),
              ],
            ),
          ),
          // 底部说明
          Container(
            color: Colors.grey[50],
            padding: const EdgeInsets.all(Spacing.lg),
            child: const Text(
              '本服务提供浙江省内（宁波除外）灵活就业人员社保、城乡居民医保费缴纳',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback? onTap;

  const _ServiceIcon({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: Spacing.sm),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── "我为自己缴"子状态 —— 读取 serviceRepositoryProvider ────────────────────

class _SelfPaySubPage extends ConsumerWidget {
  const _SelfPaySubPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncItems = ref.watch(_selfPayItemsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 用户信息头（蓝色底）
        Container(
          color: const Color(0xFF2D74DC),
          padding: const EdgeInsets.all(Spacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: Colors.white24,
                  shape: BoxShape.circle,
                ),
                child:
                    const Icon(Icons.person, color: Colors.white, size: 28),
              ),
              const SizedBox(width: Spacing.md),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '*宇澄',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '3****************3',
                      style:
                          TextStyle(fontSize: 13, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
        // 温馨提示
        Container(
          color: const Color(0xFFFFF3E0),
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.volume_up_outlined,
                  color: AppColors.elderPrimary, size: 18),
              SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  '温馨提示：注意：缴费有延迟，支付成功后请在《缴费记录》里查询最终缴费结果。当日 16:30-次日 08:00 为银行批量扣款时间。',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.elderPrimary),
                ),
              ),
              Icon(Icons.close,
                  color: AppColors.elderPrimary, size: 16),
            ],
          ),
        ),
        // 静态 Tab 行
        Container(
          color: Colors.white,
          padding:
              const EdgeInsets.symmetric(horizontal: Spacing.lg),
          child: Row(
            children: const [
              _StaticTab('全部', selected: true),
              SizedBox(width: Spacing.xl),
              _StaticTab('城乡居民'),
              SizedBox(width: Spacing.xl),
              _StaticTab('灵活就业'),
            ],
          ),
        ),
        const Divider(height: 1),
        // 内容区 — serviceRepository 驱动
        Expanded(
          child: asyncItems.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (error, stack) =>
                const Center(child: Text('加载失败')),
            data: (items) => items.isEmpty
                ? const _EmptyState(message: '您没有应缴纳的社保费记录')
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) => ListTile(
                      title: Text(items[i].title),
                      subtitle: items[i].subtitle != null
                          ? Text(items[i].subtitle!)
                          : null,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}

class _StaticTab extends StatelessWidget {
  final String label;
  final bool selected;

  const _StaticTab(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  selected ? FontWeight.w600 : FontWeight.normal,
              color: selected
                  ? AppColors.standardPrimary
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 2,
            width: 24,
            color: selected
                ? AppColors.standardPrimary
                : Colors.transparent,
          ),
        ],
      ),
    );
  }
}

// ─── "缴费记录"子状态 ─────────────────────────────────────────────────────────

class _PayRecordsSubPage extends StatelessWidget {
  const _PayRecordsSubPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 筛选行
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: Row(
            children: const [
              _DropdownChip('2026年'),
              SizedBox(width: Spacing.xl),
              _DropdownChip('扣款类型'),
            ],
          ),
        ),
        const Divider(height: 1),
        // 空状态
        Expanded(
          child: Container(
            color: Colors.grey[100],
            child: const _EmptyState(message: '您还没有缴费记录'),
          ),
        ),
      ],
    );
  }
}

class _DropdownChip extends StatelessWidget {
  final String label;
  const _DropdownChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: const TextStyle(fontSize: 15)),
        const Icon(Icons.arrow_drop_down, size: 20),
      ],
    );
  }
}

// ─── 空状态占位 ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search, size: 80, color: Colors.grey[300]),
          const SizedBox(height: Spacing.md),
          Text(
            message,
            style: const TextStyle(
                fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
