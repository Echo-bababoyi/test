import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/persistent_banner.dart';

class StandardHomePage extends ConsumerWidget {
  const StandardHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _HeroSection(
                  onElderEntryTap: () {
                    ref.read(modeProvider.notifier).toElder();
                    context.go(AppRoutes.elderHome);
                  },
                  onSearchTap: () => context.push(AppRoutes.search),
                ),
                const _ServiceGridSection(),
                const _NewsBarSection(),
                const _HotServiceSection(),
                const _DevNavSection(),
              ],
            ),
          ),
          const Align(
            alignment: Alignment.bottomCenter,
            child: PersistentBanner(),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

// ─── Hero 区（蓝紫渐变 + 城市图占位 + 搜索框）──────────────────────────────────

class _HeroSection extends StatelessWidget {
  final VoidCallback onElderEntryTap;
  final VoidCallback onSearchTap;

  const _HeroSection({
    required this.onElderEntryTap,
    required this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D74DC), // standardPrimary 蓝
            Color(0xFF0D1B6E), // 深靛蓝
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.lg, Spacing.xl, Spacing.lg, 0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBarRow(),
                const SizedBox(height: Spacing.lg),
                _QuickActionsRow(onElderEntryTap: onElderEntryTap),
              ],
            ),
          ),
          // 城市图占位（Phase 3 替换为真实图片）
          _CityImagePlaceholder(),
          // 搜索框覆盖在最底部
          _SearchBarRow(onTap: onSearchTap),
        ],
      ),
    );
  }
}

class _TopBarRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo 文字
        const Text(
          '浙里办',
          style: TextStyle(
            color: Colors.white,
            fontSize: AppFontSize.titleLarge,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        // 机器人头像
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
        ),
        const SizedBox(width: Spacing.sm),
        // 个人/法人 pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            border: Border.all(color: Colors.white38),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '个人',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.caption,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 6),
              Text(
                '法人',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: AppFontSize.caption,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionsRow extends StatelessWidget {
  final VoidCallback onElderEntryTap;

  const _QuickActionsRow({required this.onElderEntryTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _QuickActionItem(icon: Icons.qr_code_scanner, label: '扫一扫'),
        _QuickActionItem(icon: Icons.credit_card, label: '卡包'),
        _QuickActionItem(
          icon: Icons.elderly,
          label: '长辈版',
          onTap: onElderEntryTap,
        ),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _QuickActionItem({
    required this.icon,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 28),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: AppFontSize.small),
          ),
        ],
      ),
    );
  }
}

class _CityImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Phase 3 替换为真实西湖/雷峰塔图片
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 底部深渐变模拟夜景
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x00000000),
                  Color(0x60000030),
                ],
              ),
            ),
          ),
          // 塔楼剪影占位
          const Align(
            alignment: Alignment(0.4, 0.2),
            child: Opacity(
              opacity: 0.25,
              child: Icon(Icons.temple_buddhist, size: 100, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBarRow extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchBarRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: Spacing.lg,
          vertical: Spacing.md,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
            const SizedBox(width: Spacing.sm),
            const Expanded(
              child: Text(
                '搜索服务、政策、证件...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: AppFontSize.body,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              decoration: BoxDecoration(
                color: AppColors.standardPrimary,
                borderRadius: BorderRadius.circular(AppRadius.large),
              ),
              child: const Text(
                '搜索',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.small,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 服务网格区（2 行 × 4 列，带品牌色图标）────────────────────────────────────

class _ServiceGridSection extends StatelessWidget {
  const _ServiceGridSection();

  static const _items = [
    _GridItem(Icons.favorite, Color(0xFF3B82F6), '健康医保'),
    _GridItem(Icons.verified_user, Color(0xFF5B6BF5), '社保'),
    _GridItem(Icons.account_balance, Color(0xFF22C55E), '公积金'),
    _GridItem(Icons.school, Color(0xFF2563EB), '教育就业'),
    _GridItem(Icons.directions_car, Color(0xFF06B6D4), '行驶驾驶'),
    _GridItem(Icons.bolt, Color(0xFF0EA5E9), '生活服务'),
    _GridItem(Icons.badge, Color(0xFFF97316), '身份户籍'),
    _GridItem(Icons.apps, Color(0xFF7C3AED), '全部'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.lg,
      ),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: Spacing.lg,
        crossAxisSpacing: Spacing.sm,
        childAspectRatio: 0.85,
        children: [
          for (final item in _items) _ServiceGridItem(item: item),
        ],
      ),
    );
  }
}

class _GridItem {
  final IconData icon;
  final Color color;
  final String label;
  const _GridItem(this.icon, this.color, this.label);
}

class _ServiceGridItem extends StatelessWidget {
  final _GridItem item;

  const _ServiceGridItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: item.color,
            shape: BoxShape.circle,
          ),
          child: Icon(item.icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: Spacing.xs),
        Text(
          item.label,
          style: const TextStyle(
            fontSize: AppFontSize.tiny,
            color: AppColors.textPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ─── 最新消息条（浅蓝背景）────────────────────────────────────────────────────

class _NewsBarSection extends StatelessWidget {
  const _NewsBarSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg,
        vertical: Spacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(AppRadius.large),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.standardPrimary,
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: const Text(
                '最新消息',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: AppFontSize.tiny,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: Spacing.sm),
            const Expanded(
              child: Text(
                '请您登录后查看最新消息',
                style: TextStyle(
                  fontSize: AppFontSize.small,
                  color: AppColors.textSecondary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 热门服务区 ───────────────────────────────────────────────────────────────

class _HotServiceSection extends StatelessWidget {
  const _HotServiceSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '热门服务',
            style: TextStyle(
              fontSize: AppFontSize.bodyLarge,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Container(
            height: 80,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Text(
              '热门服务卡片占位',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 底部导航栏 ───────────────────────────────────────────────────────────────

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AppColors.standardPrimary,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.location_city), label: '城市'),
        BottomNavigationBarItem(icon: Icon(Icons.assignment), label: '办事'),
        BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
        BottomNavigationBarItem(icon: Icon(Icons.forum), label: '互动'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
      ],
    );
  }
}

// ─── Phase 0 开发导航面板（Phase 2 删除）──────────────────────────────────────

class _DevNavSection extends StatelessWidget {
  const _DevNavSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.xs),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(height: 1),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Spacing.lg,
              vertical: Spacing.sm,
            ),
            child: Text(
              '🔧 Phase 0 开发导航面板（Phase 2 删除）',
              style: TextStyle(fontSize: AppFontSize.tiny, color: Colors.grey),
            ),
          ),
          ListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              for (final (label, path) in AppRoutes.all)
                ListTile(
                  dense: true,
                  title: Text(label),
                  subtitle: Text(
                    path,
                    style: const TextStyle(fontSize: AppFontSize.tiny),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go(path),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
