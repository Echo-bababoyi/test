import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/state/app_state.dart';
import '../core/theme/app_theme.dart';
import '../theme/design_tokens.dart';
import '../services/agent_command_executor.dart';
import '../services/audio_player.dart';
import '../services/draft_service.dart';
import '../services/draft_store.dart';
import '../services/log_service.dart';
import '../services/page_meta.dart';
import '../services/ws_client.dart';
import '../services/session_state.dart';
import '../services/agent_settings_service.dart';
import '../services/chat_history.dart';
import '../services/auth_state.dart';
import 'agent_bubble.dart';
import 'auth_card.dart';

const _kFabSize = 52.0;

String _generateSessionId() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  return '${bytes.sublist(0, 4).map(hex).join()}-'
      '${bytes.sublist(4, 6).map(hex).join()}-'
      '${bytes.sublist(6, 8).map(hex).join()}-'
      '${bytes.sublist(8, 10).map(hex).join()}-'
      '${bytes.sublist(10).map(hex).join()}';
}

const _kDemoMode = bool.fromEnvironment('DEMO_MODE');

/// 悬浮助手：右下角小图标 + 悬浮气泡聊天窗
class AgentFab extends ConsumerStatefulWidget {
  final String? currentPath;
  const AgentFab({super.key, this.currentPath});

  @override
  ConsumerState<AgentFab> createState() => _AgentFabState();
}

class _AgentFabState extends ConsumerState<AgentFab> {
  bool _panelOpen = _kDemoMode;
  bool _hasUnread = false;

  // FAB 位置
  double _fabX = -1;
  double _fabY = -1;
  bool _fabDragging = false;
  bool _fabHovering = false;
  bool _initialized = false;

  // 气泡窗位置（可拖动标题栏）
  double _bubbleX = -1;
  double _bubbleY = 9999;

  static const double _fabSize = _kFabSize;
  static const double _peekOffset = 18.0;
  static const double _bubbleW = 300.0;
  static const double _bubbleH = 340.0;

  void _openPanel() {
    setState(() {
      _panelOpen = true;
      _hasUnread = false;
    });
  }

  void _closePanel() => setState(() => _panelOpen = false);
  void _onNewMessage() => setState(() { if (!_panelOpen) _hasUnread = true; });

  void _snapFabToEdge(double maxW) {
    final center = _fabX + _fabSize / 2;
    setState(() {
      _fabX = center < maxW / 2
          ? -(_fabSize - _peekOffset)
          : maxW - _peekOffset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mode = ref.watch(modeProvider);
    final primary = mode == AppMode.elder
        ? AppColors.elderPrimary
        : AppColors.standardPrimary;
    return LayoutBuilder(builder: (context, constraints) {
      final maxW = constraints.maxWidth;
      final maxH = constraints.maxHeight;

      if (!_initialized && maxW > 0 && maxH > 0) {
        if (_kDemoMode) {
          _fabX = maxW - _peekOffset;
          _fabY = maxH * 0.55;
          _bubbleX = maxW - _bubbleW - 12;
          _bubbleY = maxH - _bubbleH - 10;
          _initialized = true;
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && !_initialized) {
              setState(() {
                _fabX = maxW - _peekOffset;
                _fabY = maxH * 0.55;
                _bubbleX = maxW - _bubbleW - 12;
                _bubbleY = maxH - _bubbleH - 10;
                _initialized = true;
              });
            }
          });
        }
      }

      final fabDisplayX = !_initialized
          ? maxW + _fabSize
          : (_fabHovering || _fabDragging)
              ? _fabX.clamp(0.0, maxW - _fabSize)
              : _fabX;

      return Stack(
        clipBehavior: Clip.none,
        children: [
          // ── 气泡聊天窗 ──────────────────────────────────────
          if (_panelOpen && _initialized)
            Positioned(
              left: _bubbleX.clamp(0.0, maxW - _bubbleW),
              bottom: 10,
              child: _BubbleWindow(
                width: _bubbleW,
                height: _bubbleH,
                currentPath: widget.currentPath,
                primary: primary,
                onClose: _closePanel,
                onNewMessage: _onNewMessage,
                onDragUpdate: (dx, dy) {
                  setState(() {
                    _bubbleX = (_bubbleX + dx).clamp(0.0, maxW - _bubbleW);
                  });
                },
              ),
            ),

          // ── 悬浮图标（气泡窗收起时显示）──────────────────────
          if (!_panelOpen)
            AnimatedPositioned(
              duration: _fabDragging ? Duration.zero : const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              left: fabDisplayX,
              top: _fabY.clamp(0.0, maxH - _fabSize),
              child: MouseRegion(
                onEnter: (_) => setState(() => _fabHovering = true),
                onExit: (_) => setState(() => _fabHovering = false),
                child: GestureDetector(
                  onTap: () { if (!_fabDragging) _openPanel(); },
                  onPanStart: (_) => setState(() => _fabDragging = true),
                  onPanUpdate: (d) => setState(() {
                    _fabX = (_fabX + d.delta.dx).clamp(-_fabSize / 2, maxW - _fabSize / 2);
                    _fabY = (_fabY + d.delta.dy).clamp(0.0, maxH - _fabSize);
                  }),
                  onPanEnd: (_) {
                    setState(() => _fabDragging = false);
                    _snapFabToEdge(maxW);
                  },
                  child: _FabIcon(
                    hasUnread: _hasUnread,
                    hovering: _fabHovering || _fabDragging,
                    primary: primary,
                  ),
                ),
              ),
            ),
        ],
      );
    });
  }
}

// ─── 悬浮图标 ─────────────────────────────────────────────────────────────────

class _FabIcon extends StatefulWidget {
  final bool hasUnread;
  final bool hovering;
  final Color primary;
  const _FabIcon({
    required this.hasUnread,
    required this.hovering,
    required this.primary,
  });

  @override
  State<_FabIcon> createState() => _FabIconState();
}

class _FabIconState extends State<_FabIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1000),
  )..repeat(reverse: true);

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        final scale = widget.hasUnread ? (1.0 + _pulse.value * 0.10) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: _kFabSize,
        height: _kFabSize,
        decoration: BoxDecoration(
          color: widget.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: widget.primary.withValues(alpha: widget.hovering ? 0.5 : 0.3),
              blurRadius: widget.hovering ? 16 : 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // 艺术图标：渐变 + 高光 + 立体"浙"字
            CustomPaint(
              size: const Size(_kFabSize, _kFabSize),
              painter: _ZhePainter(primary: widget.primary),
            ),
            if (widget.hasUnread)
              Positioned(
                top: 7, right: 7,
                child: Container(
                  width: 9, height: 9,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF1744),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── 小浙图标自定义绘制 ────────────────────────────────────────────────────────

/// 绘制渐变背景圆 + 光泽高光 + 白色"浙"字，取代纯色平面文字
class _ZhePainter extends CustomPainter {
  final Color primary;
  const _ZhePainter({required this.primary});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // ── 径向渐变背景（亮→主→深，营造立体球感；颜色随当前模式自适配）─────────
    final bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 1.1,
        colors: [
          Color.lerp(primary, Colors.white, 0.3)!,
          primary,
          Color.lerp(primary, Colors.black, 0.1)!,
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: r));
    canvas.drawCircle(Offset(cx, cy), r, bgPaint);

    // ── 顶部光泽高光（椭圆形半透明白色）────────────────────────────────────
    final glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.45),
          Colors.white.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(cx * 0.3, cy * 0.08, cx * 1.4, cy * 0.85));
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, cy * 0.38), width: r * 1.25, height: r * 0.72),
      glossPaint,
    );

    // ── "浙"字（白色 + 微阴影营造凸起感）────────────────────────────────────
    // 阴影层
    final shadowPainter = TextPainter(
      text: const TextSpan(
        text: '浙',
        style: TextStyle(
          color: Color(0x40882200),
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    shadowPainter.paint(
      canvas,
      Offset(cx - shadowPainter.width / 2 + 0.8, cy - shadowPainter.height / 2 + 1.2),
    );

    // 主字层
    final textPainter = TextPainter(
      text: const TextSpan(
        text: '浙',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w900,
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    textPainter.paint(
      canvas,
      Offset(cx - textPainter.width / 2, cy - textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant _ZhePainter oldDelegate) =>
      oldDelegate.primary != primary;
}

// ─── 气泡聊天窗 ───────────────────────────────────────────────────────────────

class _BubbleWindow extends StatefulWidget {
  final double width;
  final double height;
  final String? currentPath;
  final Color primary;
  final VoidCallback onClose;
  final VoidCallback onNewMessage;
  final void Function(double dx, double dy) onDragUpdate;

  const _BubbleWindow({
    required this.width,
    required this.height,
    required this.currentPath,
    required this.primary,
    required this.onClose,
    required this.onNewMessage,
    required this.onDragUpdate,
  });

  @override
  State<_BubbleWindow> createState() => _BubbleWindowState();
}

class _BubbleWindowState extends State<_BubbleWindow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 220),
  );
  late final Animation<double> _scaleAnim = CurvedAnimation(
    parent: _animCtrl, curve: Curves.easeOutBack,
  );

  final _session = SessionState();
  final _ws = WsClient.instance;
  final _scrollCtrl = ScrollController();
  final _textCtrl = TextEditingController();
  AgentCommandExecutor? _executor;
  StreamSubscription<Map<String, dynamic>>? _wsSub;
  final List<Map<String, dynamic>> _items = ChatHistory.instance.items;

  @override
  void initState() {
    super.initState();
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final meta = metaForRoute(widget.currentPath ?? '');
      _executor = AgentCommandExecutor(
        router: GoRouter.of(context),
        overlayContext: context,
        pageId: meta?.pageId,
        pageTitle: meta?.pageTitle,
      );
    });
    if (_kDemoMode) {
      _initDemoData();
    } else {
      _initSession();
    }
  }

  void _initDemoData() {
    _session.websocketConnected = true;
    _session.state = 'listening';
    if (_items.isEmpty) {
      final path = widget.currentPath ?? '';
      _items.addAll(_demoDialogFor(path));
    }
  }

  List<Map<String, dynamic>> _demoDialogFor(String path) {
    if (path == '/login/face') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙，我陪您完成刷脸登录。'},
        {'role': 'agent', 'text': '请把手机举到眼前，看着摄像头。'},
        {'role': 'agent', 'text': '马上会弹出一个用摄像头的提示，是正常的，请您点"同意"。'},
        {'role': 'user', 'text': '好的'},
        {'role': 'agent', 'text': '请缓慢左右摇头，再眨一眨眼,认证一会儿就好~'},
      ];
    }
    if (path == '/service/pension-query') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙,有什么可以帮您?'},
        {'role': 'user', 'text': '帮我查一下这个月的养老金'},
        {'role': 'agent', 'text': '好的，帮您查 5 月份的养老金，对吗？'},
        {'role': 'user', 'text': '对的'},
        {'role': 'agent', 'text': '已经帮您选好月份了，我帮您点查询~'},
        {'role': 'agent', 'text': '查到啦！您 5 月的养老金 3280 元，已经到账了。'},
      ];
    }
    if (path == '/elder/drafts') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙~'},
        {'role': 'agent', 'text': '我看到您还有 2 份没办完的草稿，要接着办吗?'},
        {'role': 'user', 'text': '先看看医保缴费那个'},
        {'role': 'agent', 'text': '好的,您点"继续"就能接着上次填到一半的地方,不用重新填~'},
      ];
    }
    if (path == '/service/yibao-jiaofei') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙，有什么可以帮您?'},
        {'role': 'user', 'text': '帮我交今年的医保'},
        {'role': 'agent', 'text': '好的，帮您缴 2026 年度的医保，对吗?'},
        {'role': 'user', 'text': '对'},
        {'role': 'agent', 'text': '正在帮您填写,身份证号需要您单独同意一下。'},
      ];
    }
    if (path == '/service/yibao-query') {
      return [
        {'role': 'agent', 'text': '您好，我是小浙，有什么可以帮您?'},
        {'role': 'user', 'text': '查一下我的医保缴费记录'},
        {'role': 'agent', 'text': '好的，帮您查近一年的医保缴费记录~'},
      ];
    }
    // 默认：长辈版首页等
    return [
      {'role': 'agent', 'text': '您好，我是小浙，有什么可以帮您？'},
      {'role': 'user', 'text': '帮我查一下养老金'},
      {'role': 'agent', 'text': '帮您查养老金，对吗？'},
      {'role': 'user', 'text': '对的'},
      {'role': 'agent', 'text': '好的，正在为您查询本月养老金发放情况…'},
    ];
  }

  Future<void> _initSession() async {
    final id = _generateSessionId();
    _session.sessionId = id;
    try {
      await _ws.connect(id);
      setState(() {
        _session.websocketConnected = true;
        _session.state = 'listening';
      });
      final isLoggedIn = AuthState.instance.isLoggedIn;
      final effectiveTrust = isLoggedIn
          ? AgentSettingsService.instance.trustLevel
          : 'guide';
      _wsSub = _ws.messages.listen(_handleMessage);
      _ws.send('agent_wake', {
        'session_id': id,
        'trigger': 'button',
        'current_page': widget.currentPath ?? '',
        'trust_level': effectiveTrust,
      });
      await _checkPageDraft();
    } catch (e) {
      debugPrint('[BubbleWindow] connect error: $e');
      setState(() => _session.websocketConnected = false);
    }
  }

  Future<void> _checkPageDraft() async {
    if (!mounted) return;
    final meta = metaForRoute(widget.currentPath ?? '');
    if (meta == null) return;
    final draft = await DraftService.checkDraft(meta.pageId);
    if (!mounted || draft == null) return;
    setState(() => _items.add({
      'type': 'draft_prompt', 'draft': draft,
      'pageId': meta.pageId, 'pageTitle': meta.pageTitle,
    }));
    _scrollToBottom();
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final payload = msg['payload'] as Map<String, dynamic>? ?? {};

    if (type != null && type.startsWith('cmd_')) {
      _executor?.handleMessage(msg);
      return;
    }
    widget.onNewMessage();

    setState(() {
      _items.removeWhere((e) => e['type'] == 'thinking');
      switch (type) {
        case 'agent_ready':
          final greeting = payload['greeting'] as String? ?? '您好，有什么可以帮您？';
          _session.state = 'listening';
          if (_items.isEmpty) {
            _items.add({'role': 'agent', 'text': greeting});
          }

        case 'asr_result':
          break;

        case 'agent_thinking':
          _session.state = 'confirming';
          _items.add({'type': 'thinking'});

        case 'agent_reply':
        case 'agent_text':
          final text = payload['text'] as String? ?? '';
          final needsConfirm = payload['requires_confirmation'] as bool? ?? false;
          _session.state = needsConfirm ? 'confirming' : 'executing';
          _items.add({'role': 'agent', 'text': text, if (needsConfirm) 'showConfirm': true});
          AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);

        case 'permission_request':
        case 'agent_auth_request':
          _items.add({
            'type': 'auth',
            'permission_id': payload['permission_id'] as String? ?? '',
            'description': payload['description'] as String? ?? '需要您的授权',
          });

        case 'task_done':
          _session.state = 'done';
          LogService.saveFromTaskDone(payload);
          final summary = payload['summary'] as String?;
          if (summary != null && summary.isNotEmpty) {
            _items.add({'role': 'agent', 'text': summary});
          }
          _scheduleAutoDismiss();

        case 'agent_error':
          final code = payload['error_code'] as String?;
          final errText = code == 'asr_unclear'
              ? '没听清，请再说一次'
              : (payload['voice_hint'] as String? ?? '出错了，请重试');
          _session.state = code == 'asr_unclear' ? 'listening' : 'idle';
          _items.add({'role': 'agent', 'text': errText});

        case 'agent_out_of_scope':
          _session.state = 'idle';
          final hint = payload['voice_hint'] as String? ?? '浙里办没有这个服务';
          _items.add({'role': 'agent', 'text': hint});
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _items.add({'role': 'user', 'text': text}));
    _ws.send('text_input', {'session_id': _session.sessionId, 'text': text});
    _textCtrl.clear();
    _scrollToBottom();
  }

  Future<void> _close() async {
    await _animCtrl.reverse();
    _ws.disconnect();
    widget.onClose();
  }

  Future<void> _scheduleAutoDismiss() async {
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) _close();
  }

  @override
  void dispose() {
    _wsSub?.cancel();
    _animCtrl.dispose();
    _scrollCtrl.dispose();
    _textCtrl.dispose();
    AudioPlayer.stop();
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      alignment: Alignment.bottomRight,
      child: SizedBox(
        width: widget.width,
        height: widget.height,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFFCF8).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withValues(alpha: 0.7), width: 1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 40,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: widget.primary.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // 标题栏（可拖动）
                  GestureDetector(
                    onPanUpdate: (d) => widget.onDragUpdate(d.delta.dx, d.delta.dy),
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color.lerp(widget.primary, Colors.white, 0.2)!,
                            widget.primary,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: Row(
                        children: [
                          Container(
                            width: 26, height: 26,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.25),
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: const Text('浙',
                                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(width: 8),
                          const Text('小浙助手',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          if (!_session.websocketConnected) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red.withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('未连接',
                                  style: TextStyle(color: Colors.white, fontSize: 11)),
                            ),
                          ],
                          const Spacer(),
                          GestureDetector(
                            onTap: _close,
                            child: Container(
                              width: 28, height: 28,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // 对话区
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _items.length,
                      itemBuilder: (_, i) => _buildItem(i),
                    ),
                  ),
                  // 输入区
                  Container(
                    decoration: BoxDecoration(
                      border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textCtrl,
                            style: const TextStyle(fontSize: 15),
                            textInputAction: TextInputAction.send,
                            onSubmitted: (_) => _sendText(),
                            decoration: InputDecoration(
                              hintText: '输入指令…',
                              hintStyle: TextStyle(fontSize: 15, color: Colors.grey.shade400),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide(color: widget.primary, width: 1.5),
                              ),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: _sendText,
                          child: Container(
                            width: 36, height: 36,
                            decoration: BoxDecoration(color: widget.primary, shape: BoxShape.circle),
                            child: const Icon(Icons.send, color: Colors.white, size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItem(int i) {
    final item = _items[i];

    if (item['type'] == 'auth') {
      final permId = item['permission_id'] as String? ?? '';
      return AuthCard(
        description: item['description'] as String,
        onApprove: () {
          setState(() => _items.removeAt(i));
          _session.grantPermission('granted');
          _ws.send('permission_response', {
            'permission_id': permId, 'granted': true,
            'input_mode': 'touch', 'raw_text': '可以',
          });
        },
        onReject: () {
          setState(() => _items.removeAt(i));
          _ws.send('permission_response', {
            'permission_id': permId, 'granted': false,
            'input_mode': 'touch', 'raw_text': '不行',
          });
        },
      );
    }

    if (item['type'] == 'thinking') {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text('小浙正在想…',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
          ),
        ]),
      );
    }

    if (item['type'] == 'draft_prompt') {
      final pageTitle = item['pageTitle'] as String;
      final draft = item['draft'] as Map<String, dynamic>;
      return _DraftCard(
        pageTitle: pageTitle,
        primary: widget.primary,
        onContinue: () {
          setState(() => _items.removeAt(i));
          final route = metaForPageId(item['pageId'] as String)?.route;
          if (route != null) {
            _close().then((_) { if (mounted) GoRouter.of(context).go(route); });
          }
        },
        onDismiss: () {
          setState(() => _items.removeAt(i));
          DraftStore.deleteDraft(draft['draft_id'] as String);
        },
      );
    }

    final showConfirm = item['showConfirm'] as bool? ?? false;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AgentBubble(text: item['text'] as String, isAgent: item['role'] == 'agent'),
        if (showConfirm)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
            child: Row(children: [
              _ConfirmBtn(label: '对的', isPrimary: true, primary: widget.primary, onTap: () {
                setState(() { item.remove('showConfirm'); _items.add({'role': 'user', 'text': '对的'}); });
                _ws.send('user_confirm', {
                  'session_id': _session.sessionId, 'answer': 'yes',
                  'input_mode': 'text', 'raw_text': '对的',
                });
                _scrollToBottom();
              }),
              const SizedBox(width: 8),
              _ConfirmBtn(label: '不是', isPrimary: false, primary: widget.primary, onTap: () {
                setState(() { item.remove('showConfirm'); _items.add({'role': 'user', 'text': '不是'}); });
                _ws.send('user_confirm', {
                  'session_id': _session.sessionId, 'answer': 'no',
                  'input_mode': 'text', 'raw_text': '不是',
                });
                _scrollToBottom();
              }),
            ]),
          ),
      ],
    );
  }
}

// ─── 确认按钮 ─────────────────────────────────────────────────────────────────

class _ConfirmBtn extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final Color primary;
  final VoidCallback onTap;
  const _ConfirmBtn({
    required this.label,
    required this.isPrimary,
    required this.primary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isPrimary ? primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isPrimary ? primary : Colors.grey.shade300),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 14, fontWeight: FontWeight.w500,
              color: isPrimary ? Colors.white : Colors.grey.shade700,
            )),
      ),
    );
  }
}

// ─── 草稿提示卡 ───────────────────────────────────────────────────────────────

class _DraftCard extends StatelessWidget {
  final String pageTitle;
  final Color primary;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;
  const _DraftCard({
    required this.pageTitle,
    required this.primary,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final tint = Color.lerp(primary, Colors.white, 0.88)!;
    final border = Color.lerp(primary, Colors.white, 0.55)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.edit_note, color: primary, size: 16),
            const SizedBox(width: 4),
            Text('草稿提醒', style: TextStyle(fontSize: 13, color: primary, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 6),
          Text('上次有个未完成的$pageTitle，要继续吗？',
              style: const TextStyle(fontSize: 14, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: onDismiss,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text('不用了', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(child: GestureDetector(
              onTap: onContinue,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text('继续', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}
