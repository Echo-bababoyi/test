import 'package:flutter/material.dart';
import '../router.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';
import '../services/agent_element_registry.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

class ShebaoQueryPage extends StatelessWidget {
  const ShebaoQueryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: BackButton(onPressed: () => context.pop()),
        title: const Text(
          '社保查询',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 个人基本信息卡（橙色渐变）
                Container(
                  margin: const EdgeInsets.all(Spacing.lg),
                  padding: const EdgeInsets.all(Spacing.lg),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.large),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x33FF6D00),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        '个人基本信息',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: Spacing.md),
                      Row(
                        children: [
                          Text('姓名',
                              style: TextStyle(fontSize: 16, color: Colors.white70)),
                          Spacer(),
                          Text(
                            '*小明',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Spacing.sm),
                      Row(
                        children: [
                          Text('证件号码',
                              style: TextStyle(fontSize: 16, color: Colors.white70)),
                          Spacer(),
                          Text(
                            '3****************3',
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // 险种信息白板块
                Container(
                  margin: const EdgeInsets.only(top: Spacing.md),
                  padding: const EdgeInsets.all(Spacing.lg),
                  color: AppColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 24,
                            color: AppColors.elderPrimary,
                          ),
                          const SizedBox(width: Spacing.sm),
                          const Text(
                            '险种信息',
                            style: TextStyle(
                              fontSize: AppFontSize.elderTitle,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: Spacing.md),
                      _InsuranceCard(
                        title: '企业职工基本养老保险',
                        icon: Icons.person_outline,
                        status: '正常参保',
                        basicInfoKey: AgentElementRegistry.register(
                            'btn_yanglao_jibenxinxi'),
                        onBasicInfoTap: () =>
                            context.push(AppRoutes.pensionQuery),
                      ),
                      const _InsuranceCard(
                        title: '失业保险',
                        icon: Icons.shield_outlined,
                        status: '正常参保',
                      ),
                      const _InsuranceCard(
                        title: '工伤保险',
                        icon: Icons.personal_injury_outlined,
                        status: '正常参保',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: Spacing.xl),
              ],
            ),
          ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.shebaoQuery),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

// ─── 险种卡片 ─────────────────────────────────────────────────────────────────

class _InsuranceCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String status;
  final Key? basicInfoKey;
  final VoidCallback? onBasicInfoTap;

  const _InsuranceCard({
    required this.title,
    required this.icon,
    required this.status,
    this.basicInfoKey,
    this.onBasicInfoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: Spacing.sm),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.large),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 深灰头部
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.md,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadius.large - 1),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 24),
                const SizedBox(width: Spacing.sm),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          // 参保状态
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.sm),
            child: Row(
              children: [
                const Text(
                  '参保状态：',
                  style: TextStyle(fontSize: 16, color: AppColors.textSecondary),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    status,
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFF4CAF50)),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // 操作按钮行
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: TextButton(
                    key: basicInfoKey,
                    onPressed: onBasicInfoTap,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.elderPrimary,
                    ),
                    child: const Text('基本信息',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
                const VerticalDivider(width: 1, indent: 8, endIndent: 8),
                Expanded(
                  child: TextButton(
                    onPressed: null,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                    child: const Text('缴费信息',
                        style: TextStyle(fontSize: 18)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
