import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';
import '../services/agent_element_registry.dart';

final _cardYibaoJiaofeiKey = AgentElementRegistry.register('card_yibao_jiaofei_entry');
final _cardYibaoQueryKey = AgentElementRegistry.register('card_yibao_query_entry');

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
              KeyedSubtree(
                key: _cardYibaoJiaofeiKey,
                child: _HubCard(
                  icon: Icons.medical_services,
                  iconColor: AppColors.elderPrimary,
                  title: '医保缴费',
                  subtitle: '城乡居民医保年度缴费',
                  primary: true,
                  onTap: () => context.push(AppRoutes.yibaoJiaofei),
                ),
              ),
              const SizedBox(height: Spacing.md),
              KeyedSubtree(
                key: _cardYibaoQueryKey,
                child: _HubCard(
                  icon: Icons.search,
                  iconColor: AppColors.elderPrimary,
                  title: '医保查询',
                  subtitle: '查询账户余额和状态',
                  onTap: () => context.push(AppRoutes.yibaoQuery),
                ),
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
