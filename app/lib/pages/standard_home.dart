import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../theme/design_tokens.dart';
import '../widgets/agent_fab.dart';
import '../widgets/press_scale_wrapper.dart';
import '../router.dart';

void _showTodo(BuildContext context) {
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('该功能正在建设中'),
      duration: Duration(seconds: 2),
    ),
  );
}


class StandardHome extends ConsumerWidget {
  const StandardHome({super.key});

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
                  onSearchTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('该功能正在建设中'), duration: Duration(seconds: 2)),
                    );
                  },
                ),
                const _ServiceGridSection(),
                const _NewsBarSection(),
                const _HotServiceSection(),
                const _DevNavSection(),
              ],
            ),
          ),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.home),
          ),
        ],
      ),
      bottomNavigationBar: const _BottomNavBar(),
    );
  }
}

// --- Hero 区（蓝紫渐变 + 城市图占位 + 搜索框）---

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
          colors: [Color(0xFF2D74DC), Color(0xFF0D1B6E)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(Spacing.lg, Spacing.xl, Spacing.lg, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBarRow(),
                const SizedBox(height: Spacing.lg),
                _QuickActionsRow(onElderEntryTap: onElderEntryTap),
              ],
            ),
          ),
          _CityImagePlaceholder(),
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
        const Text('浙里办', style: TextStyle(color: Colors.white, fontSize: AppFontSize.titleLarge, fontWeight: FontWeight.w700)),
        const Spacer(),
        Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: PressScaleWrapper(
            pressedScale: 0.88,
            onTap: () => _showTodo(context),
            customBorder: const CircleBorder(),
            splashColor: Colors.white24,
            builder: (pressed) => SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: Ink(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: pressed ? Colors.white38 : Colors.white24,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.smart_toy, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
          child: PressScaleWrapper(
            pressedScale: 0.96,
            onTap: () => _showTodo(context),
            borderRadius: BorderRadius.circular(AppRadius.xlarge),
            splashColor: Colors.white24,
            highlightColor: Colors.white12,
            builder: (pressed) => Container(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: pressed ? Colors.white60 : Colors.white24,
                borderRadius: BorderRadius.circular(AppRadius.xlarge),
                border: Border.all(color: Colors.white38),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('个人', style: TextStyle(color: Colors.white, fontSize: AppFontSize.caption, fontWeight: FontWeight.w600)),
                  SizedBox(width: 6),
                  Text('法人', style: TextStyle(color: Colors.white54, fontSize: AppFontSize.caption)),
                ],
              ),
            ),
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
        _QuickActionItem(icon: Icons.qr_code_scanner, label: '扫一扫', onTap: () => _showTodo(context)),
        _QuickActionItem(icon: Icons.credit_card, label: '卡包', onTap: () => _showTodo(context)),
        _QuickActionItem(icon: Icons.elderly, label: '长辈版', onTap: onElderEntryTap),
      ],
    );
  }
}

class _QuickActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  const _QuickActionItem({required this.icon, required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return PressScaleWrapper(
      pressedScale: 0.88,
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      splashColor: Colors.white24,
      highlightColor: Colors.white12,
      builder: (pressed) => AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.all(Spacing.sm),
        decoration: BoxDecoration(
          color: pressed ? Colors.white12 : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 28),
            const SizedBox(height: Spacing.xs),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: AppFontSize.small)),
          ],
        ),
      ),
    );
  }
}

class _CityImagePlaceholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0x00000000), Color(0x60000030)]))),
          const Align(alignment: Alignment(0.4, 0.2), child: Opacity(opacity: 0.25, child: Icon(Icons.temple_buddhist, size: 100, color: Colors.white))),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.md),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        elevation: 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.xlarge),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            child: Row(
              children: [
                const Icon(Icons.search, color: AppColors.textSecondary, size: 20),
                const SizedBox(width: Spacing.sm),
                const Expanded(child: Text('搜索服务、政策、证件...', style: TextStyle(color: AppColors.textSecondary, fontSize: AppFontSize.body))),
                Ink(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.xs),
                  decoration: BoxDecoration(color: AppColors.standardPrimary, borderRadius: BorderRadius.circular(AppRadius.large)),
                  child: const Text('搜索', style: TextStyle(color: Colors.white, fontSize: AppFontSize.small)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- 服务网格区 ---

class _ServiceGridSection extends StatelessWidget {
  const _ServiceGridSection();
  static const _items = [
    _GridItem(Icons.favorite, Color(0xFF3B82F6), '健康医保'), _GridItem(Icons.verified_user, Color(0xFF5B6BF5), '社保'),
    _GridItem(Icons.account_balance, Color(0xFF22C55E), '公积金'), _GridItem(Icons.school, Color(0xFF2563EB), '教育就业'),
    _GridItem(Icons.directions_car, Color(0xFF06B6D4), '行驶驾驶'), _GridItem(Icons.bolt, Color(0xFF0EA5E9), '生活服务'),
    _GridItem(Icons.badge, Color(0xFFF97316), '身份户籍'), _GridItem(Icons.apps, Color(0xFF7C3AED), '全部'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.lg),
      child: GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: Spacing.lg, crossAxisSpacing: Spacing.sm, childAspectRatio: 0.9,
        children: [for (final item in _items) _ServiceGridItem(item: item)],
      ),
    );
  }
}

class _GridItem { final IconData icon; final Color color; final String label; const _GridItem(this.icon, this.color, this.label); }

class _ServiceGridItem extends StatefulWidget {
  final _GridItem item;
  const _ServiceGridItem({required this.item});

  @override
  State<_ServiceGridItem> createState() => _ServiceGridItemState();
}

class _ServiceGridItemState extends State<_ServiceGridItem> {
  bool _pressed = false;

  Color get _iconColor =>
      _pressed ? Color.lerp(widget.item.color, Colors.black, 0.20)! : widget.item.color;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: InkWell(
        onTap: () => _showTodo(context),
        borderRadius: BorderRadius.circular(8),
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
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: _iconColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(widget.item.icon, color: Colors.white, size: 26),
                ),
              ),
              const SizedBox(height: Spacing.xs),
              Text(widget.item.label, style: const TextStyle(fontSize: AppFontSize.tiny, color: AppColors.textPrimary), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

// --- 最新消息条 ---

class _NewsBarSection extends StatefulWidget {
  const _NewsBarSection();
  @override
  State<_NewsBarSection> createState() => _NewsBarSectionState();
}

class _NewsBarSectionState extends State<_NewsBarSection> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm),
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: GestureDetector(
          onTap: () => _showTodo(context),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md, vertical: Spacing.sm),
            decoration: BoxDecoration(
              color: _pressed ? const Color(0xFFDDE3FF) : const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: AppColors.standardPrimary, borderRadius: BorderRadius.circular(AppRadius.small)),
                child: const Text('最新消息', style: TextStyle(color: Colors.white, fontSize: AppFontSize.tiny, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: Spacing.sm),
              const Expanded(child: Text('请您登录后查看最新消息', style: TextStyle(fontSize: AppFontSize.small, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis)),
              const Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
            ]),
          ),
        ),
      ),
    );
  }
}

// --- 热门服务区 ---

class _HotServiceSection extends StatelessWidget {
  const _HotServiceSection();

  static const _services = [
    _HotServiceItem(Icons.people, '人才服务', Color(0xFF3B82F6), Color(0xFF60A5FA)),
    _HotServiceItem(Icons.home_work, '住房服务', Color(0xFF0EA5E9), Color(0xFF38BDF8)),
    _HotServiceItem(Icons.directions_bus, '交通出行', Color(0xFF22C55E), Color(0xFF4ADE80)),
    _HotServiceItem(Icons.park, '文旅消费', Color(0xFFF97316), Color(0xFFFB923C)),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      margin: const EdgeInsets.only(top: Spacing.xs),
      padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.lg),
            child: Text('热门服务',
                style: TextStyle(fontSize: AppFontSize.bodyLarge, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 90,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
              itemCount: _services.length,
              separatorBuilder: (_, _) => const SizedBox(width: Spacing.md),
              itemBuilder: (context, i) {
                final s = _services[i];
                return PressScaleWrapper(
                  pressedScale: 0.96,
                  onTap: () => _showTodo(context),
                  borderRadius: BorderRadius.circular(16),
                  builder: (pressed) => AnimatedContainer(
                    duration: const Duration(milliseconds: 80),
                    width: 160,
                    padding: const EdgeInsets.all(Spacing.md),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          pressed ? Color.lerp(s.color1, Colors.black, 0.1)! : s.color1,
                          pressed ? Color.lerp(s.color2, Colors.black, 0.1)! : s.color2,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(s.icon, color: Colors.white, size: 28),
                        Text(s.label,
                            style: const TextStyle(
                                color: Colors.white, fontSize: AppFontSize.body, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _HotServiceItem {
  final IconData icon;
  final String label;
  final Color color1;
  final Color color2;
  const _HotServiceItem(this.icon, this.label, this.color1, this.color2);
}

// --- 底部导航栏 ---

class _BottomNavBar extends StatelessWidget {
  const _BottomNavBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _NavTab(icon: Icons.location_city, label: '城市', onTap: () => _showTodo(context)),
          _NavTab(icon: Icons.assignment, label: '办事', onTap: () => _showTodo(context)),
          const _NavTab(icon: Icons.home, label: '首页', selected: true),
          _NavTab(icon: Icons.forum, label: '互动', onTap: () => _showTodo(context)),
          _NavTab(icon: Icons.person, label: '我的', onTap: () => _showTodo(context)),
        ],
      ),
    );
  }
}

class _NavTab extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavTab({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  @override
  State<_NavTab> createState() => _NavTabState();
}

class _NavTabState extends State<_NavTab> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 600),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.80).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeIn,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    _ctrl.forward().then((_) => _ctrl.reverse());
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.selected ? AppColors.standardPrimary : Colors.grey;
    return Expanded(
      child: GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedBuilder(
          animation: _scale,
          builder: (ctx, child) => Transform.scale(
            scale: _scale.value,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.icon, color: color, size: 24),
                  const SizedBox(height: 2),
                  Text(
                    widget.label,
                    style: TextStyle(fontSize: AppFontSize.tiny, color: color),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// --- 开发导航面板 ---

class _DevNavSection extends StatelessWidget {
  const _DevNavSection();
  @override
  Widget build(BuildContext context) {
    return Container(margin: const EdgeInsets.only(top: Spacing.xs), color: AppColors.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Divider(height: 1),
        const Padding(padding: EdgeInsets.symmetric(horizontal: Spacing.lg, vertical: Spacing.sm), child: Text('开发导航面板', style: TextStyle(fontSize: AppFontSize.tiny, color: Colors.grey))),
        ListView(shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), children: [
          for (final (label, path) in AppRoutes.all)
            ListTile(dense: true, title: Text(label), subtitle: Text(path, style: const TextStyle(fontSize: AppFontSize.tiny)), trailing: const Icon(Icons.chevron_right), onTap: () => context.go(path)),
        ]),
      ]),
    );
  }
}
