import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'agent_command_executor.dart';
import 'audio_player.dart';
import 'chat_history.dart';
import 'log_service.dart';
import 'ws_client.dart';

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
  AgentSession._();

  // WS 会话状态（跨页保持）
  String? _sessionId;
  StreamSubscription<Map<String, dynamic>>? _wsSub;

  bool get isActive => _sessionId != null && WsClient.instance.isConnected;
  String? get sessionId => _sessionId;

  // 当前绑定的页面上下文（每次跳页由 AgentFab 重新绑定）
  Object? _pageToken;
  GoRouter? _router;
  BuildContext? _overlayContext;
  String? _currentPath;
  String? _currentPageId;
  String? _currentPageTitle;
  AgentCommandExecutor? _executor;

  // UI 重绘信号
  final _uiSignal = StreamController<void>.broadcast();
  Stream<void> get uiSignal => _uiSignal.stream;

  bool _panelOpen = false;
  bool get panelOpen => _panelOpen;
  void setPanelOpen(bool open) {
    if (_panelOpen == open) return;
    if (open) _animateNextOpen = true;
    _panelOpen = open;
    _uiSignal.add(null);
  }

  bool _hasNewMessage = false;
  bool get hasNewMessage => _hasNewMessage;
  void clearNewMessage() {
    _hasNewMessage = false;
    _uiSignal.add(null);
  }

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
    _currentPath = currentPath;
    _currentPageId = pageId;
    _currentPageTitle = pageTitle;
    _executor = AgentCommandExecutor(
      router: _router!,
      overlayContext: _overlayContext!,
      pageId: _currentPageId,
      pageTitle: _currentPageTitle,
    );
    debugPrint('[AgentSession] bindPage path=$currentPath pageId=$pageId');
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
    debugPrint('[AgentSession] unbindPage');
  }

  Future<void> ensureSession({required String trustLevel}) async {
    if (isActive) {
      debugPrint('[AgentSession] reuse session=$_sessionId');
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
  }

  void sendChoiceText(String value) {
    WsClient.instance.send('text_input', {
      'session_id': _sessionId,
      'text': value,
    });
  }

  void _dispatch(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type != null && type.startsWith('cmd_')) {
      _executor?.handleMessage(msg);
      if (type == 'cmd_say') {
        final payload = msg['payload'] as Map<String, dynamic>? ?? {};
        final voiceHint = payload['voice_hint'] as String?;
        if (voiceHint != null && voiceHint.isNotEmpty) {
          ChatHistory.instance.items.add({'role': 'agent', 'text': voiceHint});
          if (!_panelOpen) _hasNewMessage = true;
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

      case 'asr_result':
        break;

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

      case 'agent_choice_request':
        final text = payload['text'] as String? ?? '';
        final opts = (payload['options'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        items.add({'type': 'choice', 'text': text, 'options': opts});

      case 'task_done':
        LogService.saveFromTaskDone(payload);

      case 'agent_error':
        final code = payload['error_code'] as String?;
        final errText = code == 'asr_unclear'
            ? '没听清，请再说一次'
            : (payload['voice_hint'] as String? ?? '出错了，请重试');
        items.add({'role': 'agent', 'text': errText});

      case 'agent_out_of_scope':
        final hint = payload['voice_hint'] as String? ?? '浙里办没有这个服务';
        items.add({'role': 'agent', 'text': hint});
    }
    if (!_panelOpen) {
      _hasNewMessage = true;
    }
  }
}
