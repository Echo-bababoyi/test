import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';
import '../services/agent_element_registry.dart';
import '../services/pay_record_store.dart';

enum _SubPage { home, payRecords }

class ShebaoJiaonaPage extends StatefulWidget {
  const ShebaoJiaonaPage({super.key});

  @override
  State<ShebaoJiaonaPage> createState() => _ShebaoJiaonaPageState();
}

class _ShebaoJiaonaPageState extends State<ShebaoJiaonaPage> {
  _SubPage _sub = _SubPage.home;

  void _backToHome() => setState(() => _sub = _SubPage.home);

  @override
  Widget build(BuildContext context) {
    final title = _sub == _SubPage.payRecords ? '缴费记录' : '社保费缴纳';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(
          onPressed: _sub == _SubPage.home ? () => context.pop() : _backToHome,
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
      body: Stack(
        children: [
          IndexedStack(
            index: _sub.index,
            children: [
              _HomeSubPage(
                onSelfPay: () => context.push(AppRoutes.yibaoJiaofei),
                onPayRecords: () => setState(() => _sub = _SubPage.payRecords),
              ),
              const _PayRecordsSubPage(),
            ],
          ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.shebaoJiaona),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
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
                colors: [Color(0xFFFFAA66), AppColors.elderPrimary],
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
                      key: AgentElementRegistry.register('btn_wo_wei_ziji_jiao'),
                      icon: Icons.volunteer_activism,
                      color: AppColors.elderPrimary,
                      label: '我为自己缴',
                      onTap: onSelfPay,
                    ),
                    const _ServiceIcon(
                      icon: Icons.account_balance_wallet,
                      color: Color(0xFF7B61FF),
                      label: '我帮他人缴',
                      onTap: null,
                    ),
                    const _ServiceIcon(
                      icon: Icons.badge_outlined,
                      color: Color(0xFFFF8C00),
                      label: '其他证件缴费',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const _ServiceIcon(
                      icon: Icons.description_outlined,
                      color: Color(0xFFE91E8C),
                      label: '银行缴费协议',
                      onTap: null,
                    ),
                    _ServiceIcon(
                      icon: Icons.receipt_long_outlined,
                      color: const Color(0xFF4CAF50),
                      label: '缴费记录',
                      onTap: onPayRecords,
                    ),
                    const _ServiceIcon(
                      icon: Icons.verified_outlined,
                      color: AppColors.elderPrimary,
                      label: '缴费证明',
                      onTap: null,
                    ),
                  ],
                ),
                const SizedBox(height: Spacing.xl),
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
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
    super.key,
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: key,
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
              style: const TextStyle(fontSize: 14),
              textAlign: TextAlign.center,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── "缴费记录"子状态 ──────────────────────────────────────────────────────────

class _PayRecordsSubPage extends ConsumerWidget {
  const _PayRecordsSubPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final records = ref.watch(payRecordsProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.lg,
            vertical: Spacing.md,
          ),
          child: const Row(
            children: [
              _DropdownChip('2026年'),
              SizedBox(width: Spacing.xl),
              _DropdownChip('扣款类型'),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: records.isEmpty
              ? Container(
                  color: Colors.grey[100],
                  child: const _EmptyState(message: '您还没有缴费记录'),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(Spacing.md),
                  itemCount: records.length,
                  separatorBuilder: (context, i) => const SizedBox(height: Spacing.sm),
                  itemBuilder: (_, i) => _PayRecordCard(record: records[i]),
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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(4),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 15)),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─── 缴费记录卡片 ─────────────────────────────────────────────────────────────

class _PayRecordCard extends StatelessWidget {
  final PayRecord record;
  const _PayRecordCard({required this.record});

  static String _z(int n) => n.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final timeStr =
        '${record.createdAt.year}-${_z(record.createdAt.month)}-${_z(record.createdAt.day)}'
        ' ${_z(record.createdAt.hour)}:${_z(record.createdAt.minute)}';
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.large),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.dangci.isNotEmpty
                      ? '${record.xianzhong} · ${record.dangci}'
                      : record.xianzhong,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  record.status,
                  style: const TextStyle(
                      fontSize: 12, color: Color(0xFF52C41A)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Text('缴费年度：${record.year}',
                  style: const TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
              if (record.dailiName != null) ...[
                const SizedBox(width: Spacing.md),
                Text('代缴：${record.dailiName}',
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.elderPrimary)),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  '¥ ${record.amount}',
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.elderPrimary),
                ),
              ),
              Text(timeStr,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 4),
          Text('流水号：${record.flowId}',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
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
            style: const TextStyle(fontSize: 15, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
