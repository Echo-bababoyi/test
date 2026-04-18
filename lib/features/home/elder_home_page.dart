import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/widgets/persistent_banner.dart';

class ElderHomePage extends ConsumerStatefulWidget {
  const ElderHomePage({super.key});

  @override
  ConsumerState<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends ConsumerState<ElderHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void initState() {
    super.initState();
    // 重建 IndexedStack 时跟随 tab 变化
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // ── AppBar：地区行 + 个人频道（这两项固定，不随滚动消失）──────────────
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.elderPrimary,
        titleSpacing: Spacing.lg,
        title: Row(
          children: [
            // 地区选择占位（西湖区▼）
            Container(width: 64, height: 24, color: Colors.white24),
          ],
        ),
        actions: [
          // 个人频道 pill
          Container(
            margin: const EdgeInsets.only(right: Spacing.lg),
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.sm, vertical: 4,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white54),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
            ),
            child: const Text(
              '个人频道',
              style: TextStyle(color: Colors.white, fontSize: AppFontSize.small),
            ),
          ),
        ],
      ),
      // ── 中间大圆麦克风 FAB → /search ─────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push(AppRoutes.search),
        backgroundColor: Colors.grey[500],
        elevation: 2,
        child: const Icon(Icons.mic, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      // ── BottomAppBar（配合 FAB 凹槽）─────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _EldBottomNavItem(
              icon: Icons.star,
              label: '首页',
              selected: true,
              onTap: null, // 已在首页，保持不动
            ),
            const SizedBox(width: 64), // FAB 凹槽占位
            _EldBottomNavItem(
              icon: Icons.person,
              label: '我的',
              selected: false,
              onTap: () => context.go(AppRoutes.my),
            ),
          ],
        ),
      ),
      // ── body：滚动主体 + PersistentBanner 浮在底部 ───────────────────────
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 工具行随页面滚动（橙底延续 AppBar）
                _EldToolBarSection(),
                // 政务服务热线（白卡，常驻可见）
                const _EldGovHotlineSection(),
                // Tab 卡片（TabBar + IndexedStack，切 Tab 只变这块内容）
                _EldTabCardSection(tab: _tab),
                // 以下三块常驻，与 Tab 选择无关
                const _EldOnlineServiceSection(),
                const _EldOfflineServiceSection(),
                const _EldAuthorizedServiceSection(),
                const _EldFooterSection(),
              ],
            ),
          ),
          // 登录引导 Banner（未登录且未关闭时显示）
          const Align(
            alignment: Alignment.bottomCenter,
            child: PersistentBanner(),
          ),
        ],
      ),
    );
  }
}

// ─── AppBar 工具行（扫一扫 / 消息 / 常规版，橙色背景延续）────────────────────

class _EldToolBarSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.elderPrimary,
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: const [
          _EldToolBarItem(label: '扫一扫'),
          _EldToolBarItem(label: '消息'),
          _EldToolBarItem(label: '常规版'),
        ],
      ),
    );
  }
}

class _EldToolBarItem extends StatelessWidget {
  final String label;
  const _EldToolBarItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 24, height: 20, color: Colors.white24),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: AppFontSize.small)),
        ],
      ),
    );
  }
}

// ─── 政务服务热线条（常驻，白卡圆角）────────────────────────────────────────

class _EldGovHotlineSection extends StatelessWidget {
  const _EldGovHotlineSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md, vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      child: Row(
        children: [
          Container(width: 36, height: 36, color: Colors.grey[300]),
          const SizedBox(width: Spacing.md),
          const Expanded(
            child: Text('政务服务热线', style: TextStyle(fontSize: AppFontSize.bodyLarge)),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm,
            ),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
            ),
            child: const Text('去拨打', style: TextStyle(fontSize: AppFontSize.caption)),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 卡片（TabBar + IndexedStack）────────────────────────────────────────
// 只有这块随 Tab 切换而变化，其余区域常驻不动。

class _EldTabCardSection extends StatelessWidget {
  final TabController tab;
  const _EldTabCardSection({required this.tab});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TabBar(
            controller: tab,
            labelColor: AppColors.elderPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.elderPrimary,
            tabs: const [
              Tab(text: '热门服务'),
              Tab(text: '我的常用'),
              Tab(text: '我的订阅'),
            ],
          ),
          IndexedStack(
            index: tab.index,
            children: const [
              _EldHotContent(),
              _EldFavoritesContent(),
              _EldSubscriptionContent(),
            ],
          ),
        ],
      ),
    );
  }
}

// Tab 内容：热门服务（住址变动落户 / 权益记录查询）
class _EldHotContent extends StatelessWidget {
  const _EldHotContent();

  static const _items = ['住址变动落户', '权益记录查询'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in _items)
                Expanded(
                  child: Column(
                    children: [
                      Container(width: 56, height: 56, color: Colors.grey[200]),
                      const SizedBox(height: Spacing.sm),
                      Text(label, style: const TextStyle(fontSize: AppFontSize.body)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Text(
            '查看全部 ›',
            style: TextStyle(fontSize: AppFontSize.body, color: AppColors.elderPrimary),
          ),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}

// Tab 内容：我的常用（浙里医保 / 社保查询）
class _EldFavoritesContent extends StatelessWidget {
  const _EldFavoritesContent();

  static const _items = ['浙里医保', '社保查询'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        children: [
          Row(
            children: [
              for (final label in _items)
                Expanded(
                  child: Column(
                    children: [
                      Container(width: 56, height: 56, color: Colors.grey[200]),
                      const SizedBox(height: Spacing.sm),
                      Text(label, style: const TextStyle(fontSize: AppFontSize.body)),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          const Text(
            '查看全部 ›',
            style: TextStyle(fontSize: AppFontSize.body, color: AppColors.elderPrimary),
          ),
          const SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}

// Tab 内容：我的订阅（空状态）
class _EldSubscriptionContent extends StatelessWidget {
  const _EldSubscriptionContent();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: Spacing.xl, horizontal: Spacing.lg),
      child: Column(
        children: [
          SizedBox(height: Spacing.lg),
          Text(
            '您还没有订阅任何服务',
            style: TextStyle(fontSize: AppFontSize.bodyLarge, color: AppColors.textSecondary),
          ),
          SizedBox(height: Spacing.xl),
          Text(
            '查看全部 ›',
            style: TextStyle(fontSize: AppFontSize.body, color: AppColors.elderPrimary),
          ),
          SizedBox(height: Spacing.sm),
        ],
      ),
    );
  }
}

// ─── 线上一站办（常驻，2×3 格栅）────────────────────────────────────────────

class _EldOnlineServiceSection extends StatelessWidget {
  const _EldOnlineServiceSection();

  static const _items = [
    '健康医保', '社会保障',
    '行驶驾驶', '身份户籍',
    '文旅体育', '查看全部',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '线上一站办',
            style: TextStyle(fontSize: AppFontSize.subtitle, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.8,
            children: [
              for (final label in _items) _EldServiceGridItem(label: label),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 线下就近办（常驻）───────────────────────────────────────────────────────

class _EldOfflineServiceSection extends StatelessWidget {
  const _EldOfflineServiceSection();

  static const _officeItems = [
    '杭州市西湖区三墩镇…',
    '杭州联合农村商业银…',
    '杭州市西湖区三墩镇…',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '线下就近办',
            style: TextStyle(fontSize: AppFontSize.subtitle, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          // 地图占位
          Container(
            height: 80,
            color: Colors.grey[200],
            alignment: Alignment.center,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.xl, vertical: Spacing.sm,
              ),
              color: Colors.grey[400],
              child: const Text(
                '从地图上查找更多大厅 ›',
                style: TextStyle(fontSize: AppFontSize.caption),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const Text(
            '附近有 37 家大厅',
            style: TextStyle(fontSize: AppFontSize.caption, color: Colors.grey),
          ),
          const SizedBox(height: Spacing.sm),
          for (final name in _officeItems) ...[
            _EldOfficeItem(name: name),
            const Divider(height: 1),
          ],
        ],
      ),
    );
  }
}

// ─── 授权办（常驻，2×2 格栅）─────────────────────────────────────────────────

class _EldAuthorizedServiceSection extends StatelessWidget {
  const _EldAuthorizedServiceSection();

  static const _items = [
    '老年人优待证', '养老保险年限',
    '高龄津贴', '法律援助申请',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: Spacing.md),
      padding: const EdgeInsets.all(Spacing.lg),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '授权办',
            style: TextStyle(fontSize: AppFontSize.subtitle, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.8,
            children: [
              for (final label in _items) _EldServiceGridItem(label: label),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 页脚（常驻）─────────────────────────────────────────────────────────────

class _EldFooterSection extends StatelessWidget {
  const _EldFooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Text(
        '浙里办伴你一生大小事',
        style: TextStyle(fontSize: AppFontSize.caption, color: AppColors.textSecondary),
      ),
    );
  }
}

// ─── 底部导航项（BottomAppBar 内使用）───────────────────────────────────────

class _EldBottomNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _EldBottomNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.elderPrimary : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.xl, vertical: Spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(label, style: TextStyle(color: color, fontSize: AppFontSize.tiny)),
          ],
        ),
      ),
    );
  }
}

// ─── 共用服务格栅单元格 ────────────────────────────────────────────────────────

class _EldServiceGridItem extends StatelessWidget {
  final String label;
  const _EldServiceGridItem({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.grey[100],
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 40, height: 40, color: Colors.grey[300]),
          const SizedBox(height: Spacing.xs),
          Text(label, style: const TextStyle(fontSize: AppFontSize.body)),
        ],
      ),
    );
  }
}

// ─── 大厅列表条目 ──────────────────────────────────────────────────────────────

class _EldOfficeItem extends StatelessWidget {
  final String name;
  const _EldOfficeItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontSize: AppFontSize.body)),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm, vertical: 2,
                      ),
                      color: Colors.grey[200],
                      child: const Text(
                        '空闲',
                        style: TextStyle(fontSize: AppFontSize.tiny, color: Colors.green),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    const Text(
                      '距您1.5km',
                      style: TextStyle(fontSize: AppFontSize.small, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md, vertical: Spacing.sm,
            ),
            color: Colors.grey[300],
            child: const Text('去办事', style: TextStyle(fontSize: AppFontSize.caption)),
          ),
        ],
      ),
    );
  }
}
