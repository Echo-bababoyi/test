import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/agent_element_registry.dart';
import 'press_scale_wrapper.dart';

final _tabMyKey = AgentElementRegistry.register('tab_my');

const _kOrange = Color(0xFFFF6D00);

class ElderBottomNav extends StatelessWidget {
  final int currentIndex;
  const ElderBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: currentIndex == 0 ? Icons.home : Icons.home_outlined,
              label: '首页',
              selected: currentIndex == 0,
              onTap: () => context.go(AppRoutes.elderHome),
            ),
            KeyedSubtree(
              key: _tabMyKey,
              child: _NavItem(
                icon: currentIndex == 2 ? Icons.person : Icons.person_outline,
                label: '我的',
                selected: currentIndex == 2,
                onTap: () => context.go(AppRoutes.my),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? _kOrange : const Color(0xFF999999);
    return PressScaleWrapper(
      pressedScale: 0.88,
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      builder: (_) => SizedBox(
        width: 100,
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 14, color: color, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
