import 'package:flutter/material.dart';

class AgentStatusBar extends StatefulWidget {
  final String state;
  const AgentStatusBar({super.key, required this.state});

  @override
  State<AgentStatusBar> createState() => _AgentStatusBarState();
}

class _AgentStatusBarState extends State<AgentStatusBar> with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(_label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          if (widget.state == 'confirming') ...[
            const SizedBox(width: 4),
            _BouncingDots(controller: _dotController),
          ],
        ],
      ),
    );
  }

  String get _label => switch (widget.state) {
    'listening' => '正在听您说话…',
    'confirming' => '小浙正在想',
    'executing' => '小浙正在帮您操作…',
    'done' => '已完成',
    _ => '有什么可以帮您？',
  };
}

class _BouncingDots extends StatelessWidget {
  final AnimationController controller;
  const _BouncingDots({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (i) {
        final offset = i * 0.2;
        return AnimatedBuilder(
          animation: controller,
          builder: (_, __) {
            final t = ((controller.value + offset) % 1.0);
            final dy = t < 0.5 ? -6 * (t / 0.5) : -6 * (1 - (t - 0.5) / 0.5);
            return Transform.translate(
              offset: Offset(0, dy),
              child: Container(
                width: 6, height: 6,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(color: Color(0xFFFF6D00), shape: BoxShape.circle),
              ),
            );
          },
        );
      }),
    );
  }
}
