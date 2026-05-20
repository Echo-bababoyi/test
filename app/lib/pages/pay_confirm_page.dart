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
    final inExtra =
        GoRouterState.of(context).extra as Map<String, dynamic>? ?? {};
    final xianzhong = inExtra['xianzhong'] as String? ?? '城乡居民医保';
    final year = inExtra['year'] as String? ?? '2026年度';
    final target = inExtra['target'] as String? ?? '本人';
    final amount = inExtra['amount'] as String? ?? '380.00';
    final idMasked = inExtra['id_masked'] as String? ?? '330****2518';
    final dailiName = inExtra['daili_name'] as String?;
    final dailiIdMasked = inExtra['daili_id_masked'] as String?;
    final isDaili = dailiName != null && dailiName.isNotEmpty;

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
            rows: [
              ('险种', xianzhong),
              ('缴费年度', year),
              ('缴费对象', target),
            ],
            highlight: ('缴费金额', '¥ $amount'),
          ),
          const SizedBox(height: Spacing.md),
          _SectionCard(
            title: isDaili ? '被缴费人信息' : '缴费人信息',
            rows: isDaili
                ? [
                    ('姓名', dailiName),
                    ('证件号', dailiIdMasked ?? ''),
                  ]
                : [
                    ('姓名', '*小明'),
                    ('证件号', idMasked),
                  ],
          ),
          const SizedBox(height: Spacing.md),
          // 银行卡选择（R1：迁移到 RadioGroup）
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
                RadioGroup<int>(
                  groupValue: _selectedBank,
                  onChanged: (v) => setState(() => _selectedBank = v!),
                  child: Column(
                    children: [
                      for (int i = 0; i < _banks.length; i++)
                        RadioListTile<int>(
                          contentPadding: EdgeInsets.zero,
                          value: i,
                          title: Text('${_banks[i].$2} 尾号 ${_banks[i].$3}',
                              style: const TextStyle(fontSize: 16)),
                        ),
                    ],
                  ),
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
                  ...inExtra,
                  'bank_name': bank.$2,
                  'bank_tail': bank.$3,
                },
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.elderPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('确认支付 ¥$amount',
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
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
