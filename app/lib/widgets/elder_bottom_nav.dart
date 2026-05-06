import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/wake_word_listener.dart';
import 'agent_panel.dart';

const _kOrange = Color(0xFFFF6D00);

class ElderBottomNav extends StatefulWidget {
  final int currentIndex;

  const ElderBottomNav({super.key, required this.currentIndex});

  @override
  State<ElderBottomNav> createState() => _ElderBottomNavState();
}

class _ElderBottomNavState extends State<ElderBottomNav> {
  bool _panelOpen = false;

  @override
  void initState() {
    super.initState();
    WakeWordListener.instance.onWakeWord = _onWakeWord;
    WakeWordListener.instance.start();
  }

  @override
  void dispose() {
    WakeWordListener.instance.stop();
    super.dispose();
  }

  void _onWakeWord() {
    if (_panelOpen || !mounted) return;
    _openPanel();
  }

  void _openPanel() {
    if (_panelOpen) return;
    final path = GoRouter.of(context).state.uri.path;
    setState(() => _panelOpen = true);
    showDialog<void>(
      context: context,
      barrierColor: Colors.transparent,
      barrierDismissible: false,
      builder: (_) => AgentPanel(currentPath: path),
    ).then((_) {
      if (mounted) setState(() => _panelOpen = false);
      WakeWordListener.instance.resume();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 唤醒提示
        Container(
          color: Colors.white,
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 4),
          child: const Center(
            child: Text(
              '说“小浙”即可唤醒助手',
              style: TextStyle(fontSize: 12, color: Color(0xFFBBBBBB)),
            ),
          ),
        ),
        BottomAppBar(
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
                  icon: widget.currentIndex == 0 ? Icons.home : Icons.home_outlined,
                  label: '首页',
                  selected: widget.currentIndex == 0,
                  onTap: () => context.go('/elder'),
                ),
                _AssistantButton(onTap: _openPanel),
                _NavItem(
                  icon: widget.currentIndex == 2 ? Icons.person : Icons.person_outline,
                  label: '我的',
                  selected: widget.currentIndex == 2,
                  onTap: () => context.go('/elder/mine'),
                ),
              ],
            ),
          ),
        ),
      ],
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
  final VoidCallback onTap;
  const _AssistantButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
