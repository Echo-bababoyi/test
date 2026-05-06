import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'agent_panel.dart';

const _kOrange = Color(0xFFFF6D00);

class ElderBottomNav extends StatelessWidget {
  final int currentIndex;

  const ElderBottomNav({super.key, required this.currentIndex});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
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
              onTap: () => context.go('/elder'),
            ),
            _AssistantButton(),
            _NavItem(
              icon: currentIndex == 2 ? Icons.person : Icons.person_outline,
              label: '我的',
              selected: currentIndex == 2,
              onTap: () => context.go('/elder/mine'),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 80,
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
      child: Transform.translate(
        offset: const Offset(0, -12),
        child: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: _kOrange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kOrange.withValues(alpha: 0.45),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(Icons.mic, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}
