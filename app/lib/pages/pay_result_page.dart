import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/pay_record_store.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

class PayResultPage extends ConsumerStatefulWidget {
  const PayResultPage({super.key});

  @override
  ConsumerState<PayResultPage> createState() => _PayResultPageState();
}

class _PayResultPageState extends ConsumerState<PayResultPage> {
  late final DateTime _createdAt;
  late final String _flowId;
  bool _recordWritten = false;

  @override
  void initState() {
    super.initState();
    _createdAt = DateTime.now();
    _flowId =
        'ZLS${_z(_createdAt.year)}${_z(_createdAt.month)}${_z(_createdAt.day)}'
        '${_z(_createdAt.hour)}${_z(_createdAt.minute)}${_z(_createdAt.second)}';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_recordWritten) return;
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final success = extra?['success'] as bool? ?? true;
    if (!success) return;
    _recordWritten = true;
    final record = PayRecord(
      xianzhong: extra?['xianzhong'] as String? ?? '城乡居民医保',
      dangci: extra?['dangci_label'] as String? ?? '',
      year: extra?['year'] as String? ?? '',
      amount: extra?['amount'] as String? ?? '0.00',
      target: extra?['target'] as String? ?? '本人',
      dailiName: extra?['daili_name'] as String?,
      status: '缴费成功',
      createdAt: _createdAt,
      flowId: _flowId,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(payRecordsProvider.notifier).add(record);
    });
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final success = extra?['success'] as bool? ?? true;
    final xianzhong = extra?['xianzhong'] as String? ?? '城乡居民医保';
    final year = extra?['year'] as String? ?? '2026年度';
    final amount = extra?['amount'] as String? ?? '380.00';

    final timeStr =
        '${_createdAt.year}-${_z(_createdAt.month)}-${_z(_createdAt.day)}'
        ' ${_z(_createdAt.hour)}:${_z(_createdAt.minute)}:${_z(_createdAt.second)}';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('缴费结果',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
        automaticallyImplyLeading: false,
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
                    _Row('流水号', _flowId),
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
                  onPressed: () => context.go(AppRoutes.shebaoJiaona),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.elderPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text('返回',
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
