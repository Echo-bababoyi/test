import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 长辈版底部导航条（BottomAppBar + 圆缺口）。
/// selectedIndex: 0=首页, 1=我的。
/// onSearchTap 供调用方绑定 FAB，不在 BottomAppBar 内使用。
class ElderBottomNav extends StatelessWidget {
  final int selectedIndex;
  final VoidCallback? onHomeTap;
  final VoidCallback? onMyTap;
  final VoidCallback? onSearchTap;

  const ElderBottomNav({
    super.key,
    required this.selectedIndex,
    this.onHomeTap,
    this.onMyTap,
    this.onSearchTap,
  });

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 6,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
            icon: selectedIndex == 0 ? Icons.star : Icons.star_border,
            label: '首页',
            selected: selectedIndex == 0,
            onTap: onHomeTap,
          ),
          const SizedBox(width: 64),
          _NavItem(
            icon: Icons.person,
            label: '我的',
            selected: selectedIndex == 1,
            onTap: onMyTap,
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  const _NavItem({
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
          horizontal: Spacing.xl,
          vertical: Spacing.sm,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            Text(
              label,
              style: TextStyle(color: color, fontSize: AppFontSize.tiny),
            ),
          ],
        ),
      ),
    );
  }
}
