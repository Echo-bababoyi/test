import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'agent_command_executor.dart';
import 'audio_capture.dart';
import 'audio_player.dart';
import 'chat_history.dart';
import 'log_service.dart';
import 'agent_element_registry.dart';
import 'ws_client.dart';

/// 底部 AgentDock 4 态（S0/S1/S2/S3）
enum AgentPanelMode { closed, dialog, guide, card }

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

class AgentSession {
  static final instance = AgentSession._();
  AgentSession._() {
    currentHighlightKey.addListener(_onHighlightChangedForInput);
  }

  // WS 会话状态（跨页保持）
  String? _sessionId;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  bool get isActive => _sessionId != null && WsClient.instance.isConnected;
  String? get sessionId => _sessionId;

  // 当前绑定的页面上下文（每次跳页由 AgentFab 重新绑定）
  Object? _pageToken;
  Object? get boundToken => _pageToken;
  GoRouter? _router;
  BuildContext? _overlayContext;
  String? _currentPath;
  String? _currentPageId;
  String? _currentPageTitle;
  AgentCommandExecutor? _executor;

  // UI 重绘信号
  final _uiSignal = StreamController<void>.broadcast();
  Stream<void> get uiSignal => _uiSignal.stream;

  AgentPanelMode _panelMode = AgentPanelMode.closed;
  AgentPanelMode get panelMode => _panelMode;
  bool _closing = false; // 收尾渐隐进行中（S2→S0）
  bool get closing => _closing;
  Timer? _reEnsureTimer; // 改法 B：面板高度变化后重触发高亮滚动的调度
  Timer? _finishTimer1; // 收尾序列：停顿计时
  Timer? _finishTimer2; // 收尾序列：渐隐缩小后置 closed

  // 向后兼容：standard_home 的 AgentFab 仍用 panelOpen / setPanelOpen
  bool get panelOpen => _panelMode != AgentPanelMode.closed;
  void setPanelOpen(bool open) =>
      setPanelMode(open ? AgentPanelMode.dialog : AgentPanelMode.closed);

  void setPanelMode(AgentPanelMode m) {
    _cancelFinish(); // 真实交互中止挂起的收尾序列，避免 timer 踩掉新状态
    if (_panelMode == m) return;
    final prev = _panelMode;
    if (m == AgentPanelMode.dialog && prev == AgentPanelMode.closed) {
      _animateNextOpen = true;
      clearNewMessage();
    }
    _panelMode = m;
    _uiSignal.add(null);
    // 改法 B：面板高度变化 → 延后到动画 settle 后重触发一次高亮滚动
    if (currentHighlightKey.value != null && m != AgentPanelMode.closed) {
      _scheduleReEnsureVisible();
    }
  }

  void _scheduleReEnsureVisible() {
    _reEnsureTimer?.cancel(); // Δ去重：连续切换不叠加多次滚动
    _reEnsureTimer = Timer(const Duration(milliseconds: 320), () {
      // 动画 280~300ms + 缓冲，避免在视口缩放中途按中间态算错偏移
      if (currentHighlightKey.value == null) return;
      _executor?.reEnsureVisible();
    });
  }

  /// 中止挂起的收尾序列（新交互/新引导/跳页时调用），避免 timer 踩掉新状态。
  void _cancelFinish() {
    _finishTimer1?.cancel();
    _finishTimer2?.cancel();
    _finishTimer1 = null;
    _finishTimer2 = null;
    if (_closing) {
      _closing = false;
      _uiSignal.add(null);
    }
  }

  bool _hasNewMessage = false;
  bool get hasNewMessage => _hasNewMessage;
  void clearNewMessage() {
    _hasNewMessage = false;
    _uiSignal.add(null);
  }

  bool _isGuiding = false;
  bool get isGuiding => _isGuiding;

  final ValueNotifier<String?> currentHighlightKey = ValueNotifier<String?>(null);

  double bubbleX = -1;
  double bubbleY = -1;

  static final Map<String, bool Function(String)> _inputValidators = {
    'input_phone': (t) => t.length == 11 && t.startsWith('1') && int.tryParse(t) != null,
    'input_verify_code': (t) => t.length == 6 && int.tryParse(t) != null,
  };
  static const _inputDebounceDuration = Duration(milliseconds: 2000);

  String? _watchedInputKey;
  TextEditingController? _watchedController;
  VoidCallback? _watchedListener;
  Timer? _watchedDebounceTimer;

  bool _animateNextOpen = false;
  bool consumeAnimateOpenFlag() {
    final v = _animateNextOpen;
    _animateNextOpen = false;
    return v;
  }

  void bindPage({
    required Object token,
    required GoRouter router,
    required BuildContext overlayContext,
    required String? currentPath,
    required String? pageId,
    required String? pageTitle,
  }) {
    _pageToken = token;
    _router = router;
    _overlayContext = overlayContext;
    final oldPath = _currentPath;
    _currentPath = currentPath;
    _currentPageId = pageId;
    _currentPageTitle = pageTitle;
    _executor = AgentCommandExecutor(
      router: _router!,
      overlayContext: _overlayContext!,
      pageId: _currentPageId,
      pageTitle: _currentPageTitle,
      currentRoute: _currentPath,
    );
    debugPrint('[AgentSession] bindPage path=$currentPath pageId=$pageId');
    if (_isGuiding && _currentPath != oldPath) {
      sendStepCompleted(lastAction: 'page_changed');
    }
    if (_sessionId != null && WsClient.instance.isConnected) {
      WsClient.instance.send('page_changed', {
        'session_id': _sessionId,
        'current_page': currentPath ?? '',
      });
    }
  }

  void unbindPage(Object token) {
    if (!identical(_pageToken, token)) return;
    _pageToken = null;
    _router = null;
    _overlayContext = null;
    _executor = null;
    _reEnsureTimer?.cancel(); // 跳页时取消挂起的重滚动（R3）
    _cancelFinish(); // 跳页时中止挂起的收尾序列（R3）
    debugPrint('[AgentSession] unbindPage');
  }

  Future<void> ensureSession({required String trustLevel}) async {
    if (isActive) {
      debugPrint('[AgentSession] reuse session=$_sessionId');
      sendTrustChanged(trustLevel);
      _uiSignal.add(null);
      return;
    }
    final id = _generateSessionId();
    _sessionId = id;
    try {
      await WsClient.instance.connect(id);
      _wsSub ??= WsClient.instance.messages.listen(_dispatch);
      WsClient.instance.send('agent_wake', {
        'session_id': id,
        'trigger': 'button',
        'current_page': _currentPath ?? '',
        'trust_level': trustLevel,
      });
    } catch (e) {
      debugPrint('[AgentSession] connect error: $e');
      _sessionId = null;
    }
    _uiSignal.add(null);
  }

  void endSession() {
    _wsSub?.cancel();
    _wsSub = null;
    WsClient.instance.disconnect();
    _sessionId = null;
  }

  void sendText(String text) {
    WsClient.instance.send('text_input', {
      'session_id': _sessionId,
      'text': text,
    });
  }

  void sendAudio(Uint8List pcm) {
    if (_sessionId == null) return;
    if (pcm.isEmpty) return;
    final frames = AudioCapture.frame(pcm);
    for (int i = 0; i < frames.length; i++) {
      WsClient.instance.send('audio_chunk', {
        'session_id': _sessionId,
        'chunk_index': i,
        'is_last': i == frames.length - 1,
        'audio_base64': base64Encode(frames[i]),
      });
    }
    WsClient.instance.send('audio_end', {'session_id': _sessionId});
  }

  void sendUserConfirm(String answer, String rawText) {
    WsClient.instance.send('user_confirm', {
      'session_id': _sessionId,
      'answer': answer,
      'input_mode': 'text',
      'raw_text': rawText,
    });
  }

  void sendPermissionResponse(String permId, bool granted, String rawText) {
    WsClient.instance.send('permission_response', {
      'permission_id': permId,
      'granted': granted,
      'input_mode': 'touch',
      'raw_text': rawText,
    });
    // S3 → S2：卡片处理完缩回窄条（引导中）
    if (_isGuiding) setPanelMode(AgentPanelMode.guide);
  }

  void sendChoiceText(String value) {
    WsClient.instance.send('text_input', {
      'session_id': _sessionId,
      'text': value,
    });
    // S3 → S2：选择卡处理完缩回窄条（引导中）
    if (_isGuiding) setPanelMode(AgentPanelMode.guide);
  }

  void notifyHighlight(String? elementKey) {
    currentHighlightKey.value = elementKey;
  }

  void _onHighlightChangedForInput() {
    final key = currentHighlightKey.value;
    if (key == null) {
      _unwatchInput();
    } else {
      _watchInputIfApplicable(key);
    }
  }

  void _watchInputIfApplicable(String elementKey) {
    _unwatchInput();
    final validator = _inputValidators[elementKey];
    if (validator == null) return;

    final route = _currentPath;
    if (route == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = AgentElementRegistry.getController(route, elementKey);
      if (controller == null) return;

      _watchedInputKey = elementKey;
      _watchedController = controller;
      _watchedListener = () {
        _onWatchedInputChanged(elementKey, controller.text, validator);
      };
      controller.addListener(_watchedListener!);
      _onWatchedInputChanged(elementKey, controller.text, validator);
    });
  }

  void _onWatchedInputChanged(
    String key,
    String text,
    bool Function(String) validator,
  ) {
    _watchedDebounceTimer?.cancel();
    _watchedDebounceTimer = null;
    if (!validator(text)) return;
    _watchedDebounceTimer = Timer(_inputDebounceDuration, () {
      if (!_isGuiding) return;
      if (currentHighlightKey.value != key) return;
      sendStepCompleted(lastAction: 'input_complete', elementKey: key);
    });
  }

  void _unwatchInput() {
    _watchedDebounceTimer?.cancel();
    _watchedDebounceTimer = null;
    if (_watchedController != null && _watchedListener != null) {
      _watchedController!.removeListener(_watchedListener!);
    }
    _watchedController = null;
    _watchedListener = null;
    _watchedInputKey = null;
  }

  void sendStepCompleted({
    required String lastAction,
    String? elementKey,
    String? notes,
  }) {
    if (!_isGuiding) return;
    WsClient.instance.send('step_completed', {
      'session_id': _sessionId,
      'current_page': _currentPath ?? '',
      'last_action': lastAction,
      'element_key': elementKey,
      'notes': notes,
    });
  }

  void sendSmsCode(String code) {
    if (!isActive) return;
    WsClient.instance.send('sms_code_generated', {
      'session_id': _sessionId,
      'code': code,
    });
  }

  void sendTrustChanged(String level) {
    if (!isActive) return;
    WsClient.instance.send('trust_changed', {
      'session_id': _sessionId,
      'trust_level': level,
    });
  }

  void _dispatch(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type != null && type.startsWith('cmd_')) {
      _executor?.handleMessage(msg);
      if (type == 'cmd_say' || type == 'cmd_highlight') {
        _isGuiding = true;
        _cancelFinish(); // 新引导到来，中止上一任务的收尾序列
        // S1/S0 → S2：进入引导流自动缩成窄条（用户已唤醒，不违反原则1）
        if (_panelMode == AgentPanelMode.dialog ||
            _panelMode == AgentPanelMode.closed) {
          setPanelMode(AgentPanelMode.guide);
        }
      }
      if (type == 'cmd_say') {
        final payload = msg['payload'] as Map<String, dynamic>? ?? {};
        final voiceHint = payload['voice_hint'] as String?;
        if (voiceHint != null && voiceHint.isNotEmpty) {
          ChatHistory.instance.items.add({'role': 'agent', 'text': voiceHint});
          if (!panelOpen) _hasNewMessage = true;
          _uiSignal.add(null);
        }
      }
      return;
    }
    _applyChatMessage(type, msg['payload'] as Map<String, dynamic>? ?? {});
    _uiSignal.add(null);
  }

  void _applyChatMessage(String? type, Map<String, dynamic> payload) {
    final items = ChatHistory.instance.items;
    items.removeWhere((e) => e['type'] == 'thinking');

    switch (type) {
      case 'agent_ready':
        final greeting = payload['greeting'] as String? ?? '您好，有什么可以帮您？';
        if (items.isEmpty) {
          items.add({'role': 'agent', 'text': greeting});
        }
        AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);

      case 'asr_result':
        items.removeWhere((e) => e['type'] == 'asr_placeholder');
        final asrText = payload['text'] as String? ?? '';
        if (asrText.isNotEmpty) {
          items.add({'role': 'user', 'text': asrText});
        }

      case 'agent_thinking':
        items.add({'type': 'thinking'});

      case 'agent_reply':
      case 'agent_text':
        final text = payload['text'] as String? ?? '';
        final needsConfirm = payload['requires_confirmation'] as bool? ?? false;
        items.add({'role': 'agent', 'text': text, if (needsConfirm) 'showConfirm': true});
        AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);

      case 'permission_request':
      case 'agent_auth_request':
        items.add({
          'type': 'auth',
          'permission_id': payload['permission_id'] as String? ?? '',
          'description': payload['description'] as String? ?? '需要您的授权',
        });
        AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
        // S2 → S3：引导态推授权卡，面板临时长高容纳卡片
        if (_isGuiding) setPanelMode(AgentPanelMode.card);

      case 'agent_choice_request':
        final text = payload['text'] as String? ?? '';
        final opts = (payload['options'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        items.add({'type': 'choice', 'text': text, 'options': opts});
        AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
        // S2 → S3：引导态推选择卡，面板临时长高容纳卡片
        if (_isGuiding) setPanelMode(AgentPanelMode.card);

      case 'task_done':
        _finishAndClose(payload);

      case 'agent_error':
        items.removeWhere((e) => e['type'] == 'asr_placeholder');
        _isGuiding = false;
        _unwatchInput();
        currentHighlightKey.value = null;
        final code = payload['error_code'] as String?;
        final errText = code == 'asr_unclear'
            ? '没听清，请再说一次'
            : (payload['voice_hint'] as String? ?? '出错了，请重试');
        items.add({'role': 'agent', 'text': errText});
        AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);

      case 'agent_out_of_scope':
        // 引导中插一句无关话被判 OOS：仅作答，不打断引导（§5.3 受控响应）。
        // 仅非引导态才清进度，避免误清"走到第几步/在等点哪个高亮"。
        if (!_isGuiding) {
          _unwatchInput();
          currentHighlightKey.value = null;
        }
        final hint = payload['voice_hint'] as String? ?? '浙里办没有这个服务';
        items.add({'role': 'agent', 'text': hint});
        AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
    }
    if (!panelOpen) {
      _hasNewMessage = true;
    }
  }

  /// 引导收尾（S2 → S0）：窄条原地播报收尾语 → 停顿 1.5s → 渐隐缩小收起。
  /// 视觉本质为渐隐缩小（opacity↓ + height↓ 同步缓动），**不是弹出放大**（§5.4）。
  void _finishAndClose(Map<String, dynamic> payload) {
    _unwatchInput();
    currentHighlightKey.value = null;
    // 收尾语进窄条（口语收尾语，§6.1；task_done 现不 append text，这里补）
    final hint = payload['voice_hint'] as String?;
    final summary = (hint != null && hint.isNotEmpty)
        ? hint
        : (payload['summary'] as String? ?? '已经帮您办好啦');
    ChatHistory.instance.items.add({'role': 'agent', 'text': summary});
    AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
    _panelMode = AgentPanelMode.guide; // 原地停在窄条播报，不放大
    _uiSignal.add(null);
    LogService.saveFromTaskDone(payload);
    // 停顿 1.5s 给老人读/听完 → 渐隐缩小收起（timer 存字段，可被真实交互中止）
    _finishTimer1 = Timer(const Duration(milliseconds: 1500), () {
      _closing = true; // 触发 opacity↓ + height↓ 同步缓动
      _uiSignal.add(null);
      _finishTimer2 = Timer(const Duration(milliseconds: 320), () {
        _closing = false;
        _isGuiding = false;
        _panelMode = AgentPanelMode.closed;
        _uiSignal.add(null);
      });
    });
  }
}
