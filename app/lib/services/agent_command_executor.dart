import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'agent_element_registry.dart';

class AgentCommandExecutor {
  final GoRouter router;
  final BuildContext overlayContext;

  AgentCommandExecutor({required this.router, required this.overlayContext});

  void handleMessage(Map<String, dynamic> message) {
    final type = message['type'] as String?;
    final payload = (message['payload'] as Map<String, dynamic>?) ?? {};
    switch (type) {
      case 'cmd_navigate':
        _onNavigate(payload);
      case 'cmd_highlight':
        _onHighlight(payload);
      case 'cmd_fill_field':
        _onFillField(payload);
      case 'cmd_press_button':
        _onPressButton(payload);
    }
  }

  void _onNavigate(Map<String, dynamic> payload) {
    final route = payload['target_route'] as String? ?? '/';
    final transition = payload['transition'] as String? ?? 'push';
    if (transition == 'replace') {
      router.replace(route);
    } else {
      router.push(route);
    }
  }

  void _onHighlight(Map<String, dynamic> payload) {
    final elementKey = payload['element_key'] as String?;
    final durationMs = payload['duration_ms'] as int? ?? 2000;
    if (elementKey == null) return;

    final key = AgentElementRegistry.get(elementKey);
    if (key == null) return;

    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final offset = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;
    final rect = offset & size;

    final overlay = Overlay.of(overlayContext);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _HighlightOverlay(
        rect: rect,
        onRemove: () => entry.remove(),
      ),
    );
    overlay.insert(entry);
    Future.delayed(Duration(milliseconds: durationMs), () {
      if (entry.mounted) entry.remove();
    });
  }

  Future<void> _onFillField(Map<String, dynamic> payload) async {
    final elementKey = payload['element_key'] as String?;
    final value = payload['value'] as String? ?? '';
    final isSensitive = payload['is_sensitive'] as bool? ?? false;
    if (elementKey == null) return;

    final controller = AgentElementRegistry.getController(elementKey);
    if (controller == null) return;

    final displayValue = isSensitive ? _redactValue(value) : value;
    controller.clear();
    for (var i = 0; i < displayValue.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      controller.text = displayValue.substring(0, i + 1);
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }
  }

  void _onPressButton(Map<String, dynamic> payload) {
    final elementKey = payload['element_key'] as String?;
    final isDeterministic = payload['is_deterministic'] as bool? ?? true;
    if (elementKey == null || isDeterministic) return;

    final key = AgentElementRegistry.get(elementKey);
    if (key == null) return;

    final context = key.currentContext;
    if (context == null) return;

    // 查找最近的 InkWell 或 ElevatedButton 并触发点击
    final gesture = context.findAncestorWidgetOfExactType<GestureDetector>();
    if (gesture?.onTap != null) {
      gesture!.onTap!();
    }
  }

  String _redactValue(String value) {
    if (value.length <= 7) return value;
    return '${value.substring(0, 3)}${'*' * (value.length - 7)}${value.substring(value.length - 4)}';
  }
}

class _HighlightOverlay extends StatefulWidget {
  final Rect rect;
  final VoidCallback onRemove;

  const _HighlightOverlay({required this.rect, required this.onRemove});

  @override
  State<_HighlightOverlay> createState() => _HighlightOverlayState();
}

class _HighlightOverlayState extends State<_HighlightOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 2, end: 6).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          CustomPaint(
            size: MediaQuery.of(context).size,
            painter: _HolePainter(rect: widget.rect),
          ),
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              return Positioned(
                left: widget.rect.left - _pulseAnim.value,
                top: widget.rect.top - _pulseAnim.value,
                width: widget.rect.width + _pulseAnim.value * 2,
                height: widget.rect.height + _pulseAnim.value * 2,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFFFF6D00), width: 3),
                    borderRadius: BorderRadius.circular(4 + _pulseAnim.value),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect rect;
  _HolePainter({required this.rect});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0x88000000);
    final full = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawPath(
      Path.combine(
        PathOperation.difference,
        Path()..addRect(full),
        Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4))),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_HolePainter old) => old.rect != rect;
}
