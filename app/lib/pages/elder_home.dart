import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/elder_bottom_nav.dart';
import '../widgets/persistent_banner.dart';
import '../widgets/press_scale_wrapper.dart';

void _showTodo(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('该功能正在建设中'),
      duration: Duration(seconds: 2),
    ),
  );
}

class ElderHome extends ConsumerStatefulWidget {
  const ElderHome({super.key});

  @override
  ConsumerState<ElderHome> createState() => _ElderHomeState();
}

class _ElderHomeState extends ConsumerState<ElderHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.elderPrimary,
        titleSpacing: Spacing.lg,
        title: PressScaleWrapper(
          pressedScale: 0.92,
          onTap: () => _showTodo(context),
          borderRadius: BorderRadius.circular(AppRadius.small),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          builder: (_) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  '西湖区',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppFontSize.body,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
              ],
            ),
          ),
        ),
        actions: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            child: PressScaleWrapper(
              pressedScale: 0.96,
              onTap: () => _showTodo(context),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              splashColor: Colors.white24,
              highlightColor: Colors.white12,
              builder: (pressed) => Padding(
                padding: const EdgeInsets.only(right: Spacing.sm),
                child: Ink(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Spacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: pressed ? Colors.white60 : Colors.white24,
                    border: Border.all(color: Colors.white54),
                    borderRadius: BorderRadius.circular(AppRadius.xlarge),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sync, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text(
                        '个人频道',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: AppFontSize.small,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(right: Spacing.sm),
            child: ConnectionIndicator(),
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _EldToolBarSection(onStandardTap: () {
                  ref.read(modeProvider.notifier).toStandard();
                  context.go(AppRoutes.home);
                }),
                const _EldSearchBar(),
                const _EldGovHotlineSection(key: ValueKey('eld_hotline')),
                _EldTabCardSection(controller: _tab),
                const _EldOnlineServiceSection(key: ValueKey('eld_online')),
                const _EldOfflineServiceSection(),
                const _EldAuthorizedServiceSection(),
                const _EldFooterSection(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: PersistentBanner(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

// ─── 工具行（扫一扫 / 消息 / 常规版，橙色背景延续 AppBar）────────────────────

class _EldToolBarSection extends StatelessWidget {
  final VoidCallback? onStandardTap;

  const _EldToolBarSection({this.onStandardTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.elderPrimary,
      padding: const EdgeInsets.symmetric(
        vertical: Spacing.sm,
        horizontal: Spacing.xl,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _EldToolBarItem(icon: Icons.qr_code_scanner, label: '扫一扫', onTap: () => _showTodo(context)),
          _EldToolBarItem(icon: Icons.chat_bubble_outline, label: '消息', onTap: () => _showTodo(context)),
          _EldToolBarItem(icon: Icons.swap_horiz, label: '常规版', onTap: onStandardTap),
        ],
      ),
    );
  }
}

class _EldToolBarItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _EldToolBarItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScaleWrapper(
      pressedScale: 0.88,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      splashColor: Colors.white24,
      highlightColor: Colors.white12,
      builder: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(vertical: Spacing.xs, horizontal: Spacing.md),
        decoration: BoxDecoration(
          color: pressed ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppFontSize.body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── 政务服务热线条（白卡圆角）────────────────────────────────────────────────

class _EldGovHotlineSection extends StatelessWidget {
  const _EldGovHotlineSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(Spacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.elderPrimary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.phone, color: Colors.white, size: 20),
          ),
          const SizedBox(width: Spacing.md),
          const Expanded(
            child: Text(
              '政务服务热线',
              style: TextStyle(
                fontSize: AppFontSize.elderBody,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            child: PressScaleWrapper(
              pressedScale: 0.94,
              onTap: () => _showTodo(context),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              splashColor: Colors.white24,
              builder: (_) => Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sm,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[400]!),
                  borderRadius: BorderRadius.circular(AppRadius.xlarge),
                ),
                child: const Text(
                  '去拨打',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 卡片（TabBar + ListenableBuilder + IndexedStack）─────────────────────

class _EldTabCardSection extends StatelessWidget {
  final TabController controller;
  const _EldTabCardSection({required this.controller});

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
          _EldTabBar(controller: controller),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) => IndexedStack(
              index: controller.index,
              children: const [
                _EldHotContent(),
                _EldFavoritesContent(),
                _EldSubscriptionContent(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EldTabBar extends StatelessWidget {
  final TabController controller;
  const _EldTabBar({required this.controller});

  static const _labels = ['热门服务', '我的常用', '我的订阅'];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.md, Spacing.lg, 0),
          child: Row(
            children: [
              for (int i = 0; i < _labels.length; i++) ...[
                InkWell(
                  onTap: () => controller.animateTo(i),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  child: _EldTabLabel(
                    label: _labels[i],
                    selected: controller.index == i,
                  ),
                ),
                if (i < _labels.length - 1) const SizedBox(width: Spacing.xl),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EldTabLabel extends StatelessWidget {
  final String label;
  final bool selected;
  const _EldTabLabel({required this.label, required this.selected});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.md,
        vertical: Spacing.xs,
      ),
      decoration: selected
          ? BoxDecoration(
              color: AppColors.elderPrimary,
              borderRadius: BorderRadius.circular(AppRadius.medium),
            )
          : null,
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppFontSize.body,
          fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
          color: selected ? Colors.white : AppColors.textSecondary,
        ),
      ),
    );
  }
}

// Tab 内容：热门服务
class _EldHotContent extends StatelessWidget {
  const _EldHotContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _EldServiceCard(
                  icon: Icons.home_work,
                  iconColor: const Color(0xFF3B82F6),
                  label: '住址变动落户',
                  onTap: () => _showTodo(context),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _EldServiceCard(
                  icon: Icons.verified_user,
                  iconColor: const Color(0xFF5B6BF5),
                  label: '权益记录查询',
                  onTap: () => _showTodo(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _EldViewAllButton(),
        ],
      ),
    );
  }
}

// Tab 内容：我的常用
class _EldFavoritesContent extends StatelessWidget {
  const _EldFavoritesContent();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _EldServiceCard(
                  icon: Icons.health_and_safety,
                  iconColor: const Color(0xFF3B82F6),
                  label: '浙里医保',
                  onTap: () => _showTodo(context),
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: _EldServiceCard(
                  icon: Icons.manage_search,
                  iconColor: Color(0xFF5B6BF5),
                  label: '社保查询',
                  onTap: () => context.push(AppRoutes.shebaoQuery),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          _EldViewAllButton(),
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
      padding: EdgeInsets.symmetric(
        vertical: Spacing.xl,
        horizontal: Spacing.lg,
      ),
      child: Column(
        children: [
          SizedBox(height: Spacing.lg),
          Text(
            '您还没有订阅任何服务',
            style: TextStyle(
              fontSize: AppFontSize.elderBody,
              color: AppColors.textSecondary,
            ),
          ),
          SizedBox(height: Spacing.xl),
        ],
      ),
    );
  }
}

class _EldServiceCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback? onTap;
  const _EldServiceCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: iconColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(AppRadius.large),
      child: PressScaleWrapper(
        pressedScale: 0.96,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.large),
        splashColor: const Color(0x33FF6D00),
        builder: (_) => Padding(
          padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Ink(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                ),
                child: Icon(icon, color: iconColor, size: 30),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppFontSize.elderBody,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EldViewAllButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(AppRadius.xlarge),
      child: PressScaleWrapper(
        pressedScale: 0.94,
        onTap: () => _showTodo(context),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        splashColor: const Color(0x33FF6D00),
        builder: (_) => const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Spacing.xl,
            vertical: Spacing.xs,
          ),
          child: Text(
            '查看全部  ›',
            style: TextStyle(
              fontSize: AppFontSize.body,
              color: AppColors.elderPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 线上一站办（2×3 格栅，带品牌色）────────────────────────────────────────

class _EldOnlineServiceSection extends StatelessWidget {
  const _EldOnlineServiceSection({super.key});

  static const _items = [
    _EldGridItem(Icons.monitor_heart, Color(0xFFFF6D00), Color(0xFFFFF3E0), '健康医保'),
    _EldGridItem(Icons.shield, Color(0xFF26C6DA), Color(0xFFE0F7FA), '社会保障'),
    _EldGridItem(Icons.drive_eta, Color(0xFFB8860B), Color(0xFFFFF8E1), '行驶驾驶'),
    _EldGridItem(Icons.badge, Color(0xFFFF6D00), Color(0xFFFFF3E0), '身份户籍'),
    _EldGridItem(Icons.downhill_skiing, Color(0xFF4FC3F7), Color(0xFFE1F5FE), '文旅体育'),
    _EldGridItem(Icons.apps, Color(0xFF9E9E9E), Color(0xFFF5F5F5), '查看全部'),
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
            style: TextStyle(
              fontSize: AppFontSize.elderTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.5,
            children: [
              for (final item in _items)
                _EldOnlineGridItem(
                  item: item,
                  onTap: item.label == '健康医保'
                      ? () => context.push(AppRoutes.shebaoJiaona)
                      : () => _showTodo(context),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EldGridItem {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final String label;
  const _EldGridItem(this.icon, this.iconColor, this.bgColor, this.label);
}

class _EldOnlineGridItem extends StatefulWidget {
  final _EldGridItem item;
  final VoidCallback? onTap;
  const _EldOnlineGridItem({required this.item, this.onTap});

  @override
  State<_EldOnlineGridItem> createState() => _EldOnlineGridItemState();
}

class _EldOnlineGridItemState extends State<_EldOnlineGridItem> {
  bool _pressed = false;

  Color get _iconBg =>
      _pressed ? Color.lerp(widget.item.iconColor, Colors.black, 0.20)! : widget.item.iconColor;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: Material(
        color: widget.item.bgColor,
        borderRadius: BorderRadius.circular(AppRadius.large),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.large),
          child: AnimatedScale(
            scale: _pressed ? 0.96 : 1.0,
            duration: const Duration(milliseconds: 100),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _pressed ? 0.85 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 100),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(widget.item.icon, color: Colors.white, size: 26),
                  ),
                ),
                const SizedBox(height: Spacing.sm),
                Text(
                  widget.item.label,
                  style: const TextStyle(
                    fontSize: AppFontSize.elderBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── 线下就近办（地图 + 大厅列表）────────────────────────────────────────────

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
            style: TextStyle(
              fontSize: AppFontSize.elderTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          Container(
            height: 90,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF3E0),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            alignment: Alignment.center,
            child: Material(
              color: AppColors.elderPrimary,
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              child: PressScaleWrapper(
                pressedScale: 0.94,
                onTap: () => _showTodo(context),
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
                splashColor: Colors.white24,
                builder: (_) => const Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Spacing.xl,
                    vertical: Spacing.sm,
                  ),
                  child: Text(
                    '从地图上查找更多大厅  ›',
                    style: TextStyle(color: Colors.white, fontSize: AppFontSize.body),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          const Row(
            children: [
              Icon(Icons.my_location, size: 16, color: AppColors.textSecondary),
              SizedBox(width: 4),
              Text('附近有 ', style: TextStyle(fontSize: AppFontSize.body)),
              Text(
                '37',
                style: TextStyle(
                  fontSize: AppFontSize.body,
                  color: AppColors.elderPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(' 家大厅', style: TextStyle(fontSize: AppFontSize.body)),
            ],
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

class _EldOfficeItem extends StatelessWidget {
  final String name;
  const _EldOfficeItem({required this.name});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: AppFontSize.elderBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(AppRadius.small),
                      ),
                      child: const Text(
                        '空闲',
                        style: TextStyle(fontSize: AppFontSize.small, color: Colors.green),
                      ),
                    ),
                    const SizedBox(width: Spacing.sm),
                    const Text(
                      '距您1.5km',
                      style: TextStyle(
                        fontSize: AppFontSize.body,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Material(
            color: AppColors.elderPrimary,
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            child: PressScaleWrapper(
              pressedScale: 0.94,
              onTap: () => _showTodo(context),
              borderRadius: BorderRadius.circular(AppRadius.xlarge),
              splashColor: Colors.white24,
              builder: (_) => const Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Spacing.lg,
                  vertical: Spacing.sm,
                ),
                child: Text(
                  '去办事',
                  style: TextStyle(
                    fontSize: AppFontSize.body,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── 授权办（2×2 格栅）──────────────────────────────────────────────────────

class _EldAuthorizedServiceSection extends StatelessWidget {
  const _EldAuthorizedServiceSection();

  static const _items = [
    _EldGridItem(Icons.card_membership, Color(0xFFFF6D00), Color(0xFFFFF3E0), '老年人优待证'),
    _EldGridItem(Icons.verified_user, Color(0xFFB8860B), Color(0xFFFFF8E1), '养老保险年限'),
    _EldGridItem(Icons.receipt_long, Color(0xFF26C6DA), Color(0xFFE0F7FA), '高龄津贴'),
    _EldGridItem(Icons.gavel, Color(0xFFB8860B), Color(0xFFFFF8E1), '法律援助申请'),
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
            style: TextStyle(
              fontSize: AppFontSize.elderTitle,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: Spacing.md),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: Spacing.md,
            crossAxisSpacing: Spacing.md,
            childAspectRatio: 1.5,
            children: [
              for (final item in _items) _EldOnlineGridItem(item: item, onTap: () => _showTodo(context)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── 页脚 ──────────────────────────────────────────────────────────────────

class _EldFooterSection extends StatelessWidget {
  const _EldFooterSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xl),
      color: AppColors.surface,
      alignment: Alignment.center,
      child: const Text(
        '浙里办 伴你一生大小事',
        style: TextStyle(
          fontSize: AppFontSize.caption,
          color: AppColors.textSecondary,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}

class _EldSearchBar extends StatelessWidget {
  const _EldSearchBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.elderPrimary,
      padding: const EdgeInsets.fromLTRB(Spacing.lg, 0, Spacing.lg, Spacing.md),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        child: InkWell(
          onTap: () => context.push(AppRoutes.search),
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                const SizedBox(width: Spacing.sm),
                const Text(
                  '搜索服务、政策、证件...',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: AppFontSize.bodyLarge,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
