import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';
import '../../core/theme/design_tokens.dart';

class StandardHomePage extends ConsumerWidget {
  const StandardHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeroSection(
              onElderEntryTap: () {
                ref.read(modeProvider.notifier).toElder();
                context.go(AppRoutes.elderHome);
              },
              onSearchTap: () => context.go(AppRoutes.search),
            ),
            const _ServiceGridSection(),
            const _NewsBarSection(),
            const _HotServiceSection(),
            const _LoginPromptSection(),
            const _DevNavSection(),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

// ─── Hero 区（蓝色背景：顶栏 + 快捷操作 + Banner + 搜索框）──────────────────

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
      color: AppColors.standardPrimary,
      padding: const EdgeInsets.fromLTRB(
        Spacing.lg, Spacing.xl, Spacing.lg, 0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TopBarRow(),
          const SizedBox(height: Spacing.lg),
          _QuickActionsRow(onElderEntryTap: onElderEntryTap),
          const SizedBox(height: Spacing.lg),
          const _BannerPlaceholder(),
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
        // 应用 Logo 文字占位
        Container(width: 72, height: 28, color: Colors.white24),
        const Spacer(),
        // 头像图标占位
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: Colors.white24,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        // 个人 / 法人切换占位
        Container(width: 72, height: 28, color: Colors.white24),
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
        _QuickActionItem(label: '扫一扫'),
        _QuickActionItem(label: '卡包'),
        _QuickActionItem(label: '长辈版', onTap: onElderEntryTap),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuickActionItem({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(width: 48, height: 48, color: Colors.white24),
          const SizedBox(height: Spacing.xs),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _BannerPlaceholder extends StatelessWidget {
  const _BannerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      color: Colors.white12,
      alignment: Alignment.center,
      child: const Text('Banner / 城市图占位',
          style: TextStyle(color: Colors.white54)),
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
        margin: const EdgeInsets.symmetric(vertical: Spacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.md,
        ),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            const Icon(Icons.search, color: Colors.grey),
            const SizedBox(width: Spacing.sm),
            const Expanded(
              child: Text('搜索服务', style: TextStyle(color: Colors.grey)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md, vertical: Spacing.xs,
              ),
              color: AppColors.standardPrimary,
              child: const Text('搜索',
                  style: TextStyle(color: Colors.white, fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 服务网格区（2 行 × 4 列）────────────────────────────────────────────────

class _ServiceGridSection extends StatelessWidget {
  const _ServiceGridSection();

  static const _items = [
    '健康医保', '社保', '公积金', '教育就业',
    '行驶驾驶', '生活服务', '身份户籍', '全部',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(Spacing.lg),
      child: GridView.count(
        crossAxisCount: 4,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: Spacing.md,
        crossAxisSpacing: Spacing.sm,
        childAspectRatio: 0.9,
        children: [
          for (final label in _items) _ServiceGridItem(label: label),
        ],
      ),
    );
  }
}

class _ServiceGridItem extends StatelessWidget {
  final String label;

  const _ServiceGridItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 48, height: 48, color: Colors.grey[300]),
        const SizedBox(height: Spacing.xs),
        Text(label,
            style: const TextStyle(fontSize: 11),
            textAlign: TextAlign.center),
      ],
    );
  }
}

// ─── 最新消息条 ───────────────────────────────────────────────────────────────

class _NewsBarSection extends StatelessWidget {
  const _NewsBarSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg, vertical: Spacing.md,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: 2,
            ),
            color: Colors.grey[300],
            child: const Text('最新消息', style: TextStyle(fontSize: 11)),
          ),
          const SizedBox(width: Spacing.sm),
          const Expanded(
            child: Text('请您登录后查看最新消息',
                style: TextStyle(fontSize: 12, color: Colors.grey),
                overflow: TextOverflow.ellipsis),
          ),
          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        ],
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
          const Text('热门服务',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: Spacing.md),
          Container(
            height: 80,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: const Text('热门服务卡片占位',
                style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}

// ─── 底部登录引导条（未登录时可见）────────────────────────────────────────────

class _LoginPromptSection extends StatelessWidget {
  const _LoginPromptSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.lg, vertical: Spacing.md,
      ),
      color: Colors.grey[800],
      child: Row(
        children: [
          const Expanded(
            child: Text(
              '登录浙里办，享受更多服务',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm,
            ),
            color: Colors.grey[600],
            child: const Text('立即登录',
                style: TextStyle(color: Colors.white, fontSize: 13)),
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
              horizontal: Spacing.lg, vertical: Spacing.sm,
            ),
            child: Text(
              '🔧 Phase 0 开发导航面板（Phase 2 删除）',
              style: TextStyle(fontSize: 11, color: Colors.grey),
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
                  subtitle: Text(path,
                      style: const TextStyle(fontSize: 11)),
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
