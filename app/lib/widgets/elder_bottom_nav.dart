import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'agent_panel.dart';

class ElderBottomNav extends StatelessWidget {
  final int currentIndex;

  const ElderBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: '首页', selected: currentIndex == 0,
            onTap: () => context.go('/elder')),
          _AssistantButton(),
          _NavItem(icon: Icons.person, label: '我的', selected: currentIndex == 2,
            onTap: () => context.go('/elder/mine')),
        ],
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
    final color = selected ? const Color(0xFFFF6D00) : Colors.grey;
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        height: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            Text(label, style: TextStyle(fontSize: 14, color: color)),
          ],
        ),
      ),
    );
  }
}

class _AssistantButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          barrierDismissible: false,
          builder: (_) => const AgentPanel(),
        );
      },
      child: Container(
        width: 56,
        height: 56,
        decoration: const BoxDecoration(
          color: Color(0xFFFF6D00),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 28),
      ),
    );
  }
}
