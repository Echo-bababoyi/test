import 'dart:async';
import 'dart:html' as html; // ignore: avoid_web_libraries_in_flutter
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'agent_element_registry.dart';
import 'draft_service.dart';
import 'agent_settings_service.dart';

class AgentCommandExecutor {
  final GoRouter router;
  final BuildContext overlayContext;
  final String? pageId;
  final String? pageTitle;
  final String? currentRoute;

  OverlayEntry? _currentHighlightEntry;

  AgentCommandExecutor({
    required this.router,
    required this.overlayContext,
    this.pageId,
    this.pageTitle,
    this.currentRoute,
  });

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
      case 'cmd_say':
        _speakHint(payload['voice_hint'] as String? ?? '');
    }
  }

  void _speakHint(String text) {
    final settings = AgentSettingsService.instance;
    if (!settings.voiceEnabled) return;
    try {
      final synth = html.window.speechSynthesis;
      if (synth == null) return;
      synth.cancel();
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.lang = 'zh-CN';
      utterance.rate = settings.speechRate;
      synth.speak(utterance);
    } catch (_) {}
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
    if (elementKey == null) {
      debugPrint('[cmd_highlight] missing element_key');
      return;
    }

    if (currentRoute == null) {
      debugPrint('[cmd_highlight] no currentRoute, skipping');
      return;
    }
    final key = AgentElementRegistry.get(currentRoute!, elementKey);
    if (key == null) {
      debugPrint('[cmd_highlight] no registered key for "$elementKey"');
      return;
    }

    if (key.currentContext == null) {
      debugPrint('[cmd_highlight] key "$elementKey" has no mounted context (page not on top?)');
      return;
    }

    _currentHighlightEntry?.remove();
    _currentHighlightEntry = null;

    final overlay = Overlay.of(overlayContext, rootOverlay: true);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _HighlightBorderOverlay(
        targetKey: key,
        onDismiss: () {
          if (entry.mounted) entry.remove();
          if (identical(_currentHighlightEntry, entry)) {
            _currentHighlightEntry = null;
          }
        },
      ),
    );
    overlay.insert(entry);
    _currentHighlightEntry = entry;
  }

  Future<void> _onFillField(Map<String, dynamic> payload) async {
    final elementKey = payload['field_key'] as String?;
    final value = payload['value'] as String? ?? '';
    final isSensitive = payload['is_sensitive'] as bool? ?? false;
    if (elementKey == null) return;

    if (currentRoute == null) return;
    final controller = AgentElementRegistry.getController(currentRoute!, elementKey);
    if (controller == null) return;

    final displayValue = isSensitive ? _redactValue(value) : value;
    controller.clear();
    for (var i = 0; i < displayValue.length; i++) {
      await Future.delayed(const Duration(milliseconds: 100));
      controller.text = displayValue.substring(0, i + 1);
      controller.selection = TextSelection.collapsed(offset: controller.text.length);
    }

    if (pageId != null && pageTitle != null) {
      final fields = {elementKey: isSensitive ? '[已脱敏]' : value};
      DraftService.autoSave(pageId!, pageTitle!, fields, isSensitive);
    }
  }

  void _onPressButton(Map<String, dynamic> payload) {
    final elementKey = payload['button_key'] as String?;
    final isDeterministic = payload['is_deterministic'] as bool? ?? true;
    if (elementKey == null || isDeterministic) return;

    if (currentRoute == null) return;
    final key = AgentElementRegistry.get(currentRoute!, elementKey);
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

class _HighlightBorderOverlay extends StatefulWidget {
  final GlobalKey targetKey;
  final VoidCallback onDismiss;

  const _HighlightBorderOverlay({required this.targetKey, required this.onDismiss});

  @override
  State<_HighlightBorderOverlay> createState() => _HighlightBorderOverlayState();
}

class _HighlightBorderOverlayState extends State<_HighlightBorderOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;
  bool _dismissScheduled = false;

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

  Rect? _computeTargetRect() {
    final ctx = widget.targetKey.currentContext;
    if (ctx == null) return null;
    final rb = ctx.findRenderObject() as RenderBox?;
    if (rb == null || !rb.attached) return null;
    final transform = rb.getTransformTo(null);
    return MatrixUtils.transformRect(transform, Offset.zero & rb.size);
  }

  void _onPointerDown(PointerDownEvent event) {
    final rect = _computeTargetRect();
    if (rect != null && rect.contains(event.position)) {
      widget.onDismiss();
    }
  }

  void _scheduleAutoDismiss() {
    if (_dismissScheduled) return;
    _dismissScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _pulseAnim,
            builder: (_, __) {
              final rect = _computeTargetRect();
              if (rect == null) {
                _scheduleAutoDismiss();
                return const SizedBox.expand();
              }
              final v = _pulseAnim.value;
              return Stack(
                children: [
                  Positioned(
                    left: rect.left - v,
                    top: rect.top - v,
                    width: rect.width + v * 2,
                    height: rect.height + v * 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFFF6D00), width: 3),
                        borderRadius: BorderRadius.circular(4 + v),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
