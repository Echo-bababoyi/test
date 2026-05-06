import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/agent_command_executor.dart';
import '../services/audio_player.dart';
import '../services/draft_service.dart';
import '../services/draft_store.dart';
import '../services/log_service.dart';
import '../services/ws_client.dart';
import '../services/session_state.dart';
import 'agent_bubble.dart';
import 'auth_card.dart';
import 'mic_button.dart';
import 'network_banner.dart';
import 'status_bar.dart';

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

class AgentPanel extends StatefulWidget {
  final String? currentPath;
  const AgentPanel({super.key, this.currentPath});

  @override
  State<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends State<AgentPanel> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  final _session = SessionState();
  final _ws = WsClient.instance;
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  AgentCommandExecutor? _executor;

  final List<Map<String, dynamic>> _items = [];
  Timer? _autoDismissTimer;
  bool _isMinimized = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _slideController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executor = AgentCommandExecutor(
        router: GoRouter.of(context),
        overlayContext: context,
      );
    });
    _initSession();
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
      _ws.send('agent_wake', {});
      _ws.messages.listen(_handleMessage);
      await _checkPageDraft();
    } catch (_) {
      setState(() => _session.websocketConnected = false);
    }
  }

  static const _pageIdMap = {
    '/elder/yibao-jiaofei': ('yibao_jiaofei', '医保缴费'),
    '/elder/yibao-query':   ('yibao_query',   '医保查询'),
    '/elder/pension-query': ('pension_query',  '养老金查询'),
  };

  Future<void> _checkPageDraft() async {
    if (!mounted) return;
    final location = widget.currentPath ?? '';
    final entry = _pageIdMap[location];
    if (entry == null) return;
    final (pageId, pageTitle) = entry;
    final draft = await DraftService.checkDraft(pageId);
    if (!mounted || draft == null) return;
    setState(() {
      _items.add({
        'type': 'draft_prompt',
        'draft': draft,
        'pageId': pageId,
        'pageTitle': pageTitle,
      });
    });
    _scrollToBottom();
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final payload = msg['payload'] as Map<String, dynamic>? ?? {};

    // 指令类消息直接分发给 executor，不进对话列表
    if (type != null && type.startsWith('cmd_')) {
      _executor?.handleMessage(msg);
      return;
    }

    setState(() {
      // 移除思考中占位（如果有）
      _items.removeWhere((item) => item['type'] == 'thinking');
      switch (type) {
        case 'agent_thinking':
          _session.state = 'confirming';
          _items.add({'type': 'thinking'});

        case 'agent_reply':
        case 'agent_text':
          final text = payload['text'] as String? ?? '';
          final requiresConfirmation = payload['requires_confirmation'] as bool? ?? false;
          _session.state = requiresConfirmation ? 'confirming' : 'executing';
          _isMinimized = !requiresConfirmation;
          _session.addDialog('agent', text);
          _items.add({
            'role': 'agent',
            'text': text,
            if (requiresConfirmation) 'showConfirm': true,
          });
          AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);

        case 'permission_request':
        case 'agent_auth_request':
          _isMinimized = false;
          _items.add({'type': 'auth', 'description': payload['description'] as String? ?? '需要您的授权'});

        case 'task_done':
          _session.state = 'done';
          _isMinimized = false;
          LogService.saveFromTaskDone(payload);
          final summary = payload['summary'] as String?;
          if (summary != null && summary.isNotEmpty) {
            _session.addDialog('agent', summary);
            _items.add({'role': 'agent', 'text': summary});
          }
          AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
          _autoDismissTimer = Timer(const Duration(seconds: 2), () {
            if (mounted) _close();
          });

        case 'agent_executing':
          _session.state = 'executing';
          _isMinimized = true;

        case 'agent_done':
          _session.state = 'done';

        case 'agent_error':
          final errorCode = payload['error_code'] as String?;
          final errText = errorCode == 'asr_unclear' ? '没听清，请再说一次' : (payload['text'] as String? ?? '出错了，请重试');
          _session.state = errorCode == 'asr_unclear' ? 'listening' : 'idle';
          _session.addDialog('agent', errText);
          _items.add({'role': 'agent', 'text': errText});
          AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);

        case 'agent_out_of_scope':
          _session.state = 'idle';
          final hint = payload['voice_hint'] as String? ?? payload['text'] as String? ?? '浙里办没有这个服务';
          _session.addDialog('agent', hint);
          _items.add({'role': 'agent', 'text': hint});
          AudioPlayer.playBase64(payload['tts_audio_base64'] as String?);
      }
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onAudioEnd() {
    setState(() => _session.state = 'confirming');
    _ws.send('audio_end', {});
  }

  Future<void> _close() async {
    await _slideController.reverse();
    _ws.disconnect();
    if (mounted) Navigator.of(context).pop();
  }

  void _sendText() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _session.addDialog('user', text);
    setState(() {
      _items.add({'role': 'user', 'text': text});
    });
    _ws.send('text_input', {
      'session_id': _session.sessionId,
      'text': text,
    });
    _textController.clear();
    _scrollToBottom();
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _slideController.dispose();
    _scrollController.dispose();
    _textController.dispose();
    AudioPlayer.stop();
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fullHeight = MediaQuery.of(context).size.height * 0.55;
    const miniHeight = 80.0;
    final targetHeight = _isMinimized ? miniHeight : fullHeight;

    return GestureDetector(
      onTap: _close,
      child: ColoredBox(
        color: const Color(0x66000000),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: GestureDetector(
            onTap: () {},
            child: SlideTransition(
              position: _slideAnim,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                height: targetHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: _isMinimized ? _buildMiniBar() : _buildFullPanel(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMiniBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(Icons.sync, color: Color(0xFFFF6D00), size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              '小浙正在帮您操作…',
              style: TextStyle(fontSize: 16, color: Color(0xFF333333), fontWeight: FontWeight.w500),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_up, color: Color(0xFF999999)),
            onPressed: () => setState(() => _isMinimized = false),
            tooltip: '展开',
          ),
        ],
      ),
    );
  }

  Widget _buildFullPanel() {
    return Column(
      children: [
        NetworkBanner(visible: !_session.websocketConnected),
        const SizedBox(height: 8),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        AgentStatusBar(state: _session.state),
        const Divider(height: 1),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(top: 8, bottom: 8),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final item = _items[i];
              if (item['type'] == 'auth') {
                return AuthCard(
                  description: item['description'] as String,
                  onApprove: () {
                    setState(() => _items.removeAt(i));
                    _session.grantPermission('granted');
                    _ws.send('user_confirm', {'approved': true});
                  },
                  onReject: () {
                    setState(() => _items.removeAt(i));
                    _ws.send('user_confirm', {'approved': false});
                  },
                );
              }
              if (item['type'] == 'thinking') {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text('小浙正在想…', style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
                      ),
                    ],
                  ),
                );
              }
              if (item['type'] == 'draft_prompt') {
                final pageTitle = item['pageTitle'] as String;
                final draft = item['draft'] as Map<String, dynamic>;
                return _DraftPromptCard(
                  pageTitle: pageTitle,
                  onContinue: () {
                    setState(() => _items.removeAt(i));
                    // 跳转到对应页面，草稿仍在 IndexedDB 可供恢复
                    final pageId = item['pageId'] as String;
                    final routeMap = {
                      'yibao_jiaofei': '/elder/yibao-jiaofei',
                      'yibao_query':   '/elder/yibao-query',
                      'pension_query': '/elder/pension-query',
                    };
                    final route = routeMap[pageId];
                    if (route != null) {
                      _close().then((_) {
                        if (mounted) GoRouter.of(context).go(route);
                      });
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
                  AgentBubble(
                    text: item['text'] as String,
                    isAgent: item['role'] == 'agent',
                  ),
                  if (showConfirm)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Row(
                        children: [
                          _ConfirmButton(
                            label: '对的',
                            isPrimary: true,
                            onTap: () {
                              setState(() => item.remove('showConfirm'));
                              _session.addDialog('user', '对的');
                              setState(() => _items.add({'role': 'user', 'text': '对的'}));
                              _ws.send('user_confirm', {
                                'session_id': _session.sessionId,
                                'answer': 'yes',
                                'input_mode': 'text',
                                'raw_text': '对的',
                              });
                              _scrollToBottom();
                            },
                          ),
                          const SizedBox(width: 10),
                          _ConfirmButton(
                            label: '不是',
                            isPrimary: false,
                            onTap: () {
                              setState(() => item.remove('showConfirm'));
                              _session.addDialog('user', '不是');
                              setState(() => _items.add({'role': 'user', 'text': '不是'}));
                              _ws.send('user_confirm', {
                                'session_id': _session.sessionId,
                                'answer': 'no',
                                'input_mode': 'text',
                                'raw_text': '不是',
                              });
                              _scrollToBottom();
                            },
                          ),
                        ],
                      ),
                    ),
                ],
              );
            },
          ),
        ),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(fontSize: 18),
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendText(),
                    decoration: InputDecoration(
                      hintText: '输入文字指令…',
                      hintStyle: const TextStyle(fontSize: 18, color: Color(0xFFBBBBBB)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
                      ),
                      filled: true,
                      fillColor: const Color(0xFFFAFAFA),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 48,
                height: 48,
                child: Material(
                  color: const Color(0xFFFF6D00),
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: _sendText,
                    child: const Icon(Icons.send, color: Colors.white, size: 22),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: const [
              Expanded(child: Divider(indent: 24, endIndent: 8)),
              Text('或', style: TextStyle(fontSize: 13, color: Color(0xFFBBBBBB))),
              Expanded(child: Divider(indent: 8, endIndent: 24)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Column(
            children: [
              MicButton(onAudioEnd: _onAudioEnd),
              const SizedBox(height: 4),
              Text(
                _session.state == 'listening' ? '按住说话' : '',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ConfirmButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _ConfirmButton({required this.label, required this.isPrimary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? const Color(0xFFFF6D00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isPrimary ? const Color(0xFFFF6D00) : const Color(0xFFE5E5E5)),
          boxShadow: const [BoxShadow(color: Color(0x0D000000), blurRadius: 4, offset: Offset(0, 1))],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isPrimary ? Colors.white : const Color(0xFF666666),
          ),
        ),
      ),
    );
  }
}

class _DraftPromptCard extends StatelessWidget {
  final String pageTitle;
  final VoidCallback onContinue;
  final VoidCallback onDismiss;

  const _DraftPromptCard({
    required this.pageTitle,
    required this.onContinue,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF3E0),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCC80)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.edit_note, color: Color(0xFFFF6D00), size: 20),
                SizedBox(width: 6),
                Text('草稿提醒', style: TextStyle(fontSize: 14, color: Color(0xFFFF6D00), fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '上次有个未完成的$pageTitle，要继续吗？',
              style: const TextStyle(fontSize: 16, color: Color(0xFF333333)),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDismiss,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF999999),
                      side: const BorderSide(color: Color(0xFFE5E5E5)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('不用了', style: TextStyle(fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onContinue,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6D00),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                    ),
                    child: const Text('继续', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
