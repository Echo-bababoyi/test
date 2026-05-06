import 'dart:math';
import 'package:flutter/material.dart';
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
  const AgentPanel({super.key});

  @override
  State<AgentPanel> createState() => _AgentPanelState();
}

class _AgentPanelState extends State<AgentPanel> with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;

  final _session = SessionState();
  final _ws = WsClient();
  final _scrollController = ScrollController();

  // dialog items: Map with keys 'role','text' or 'type','description' for auth cards
  final List<Map<String, dynamic>> _items = [];

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
    } catch (_) {
      setState(() => _session.websocketConnected = false);
    }
  }

  void _handleMessage(Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    final payload = msg['payload'] as Map<String, dynamic>? ?? {};
    setState(() {
      switch (type) {
        case 'agent_text':
          _session.state = 'confirming';
          final text = payload['text'] as String? ?? '';
          _session.addDialog('agent', text);
          _items.add({'role': 'agent', 'text': text});
        case 'agent_auth_request':
          _items.add({'type': 'auth', 'description': payload['description'] as String? ?? '需要您的授权'});
        case 'agent_done':
          _session.state = 'done';
        case 'agent_executing':
          _session.state = 'executing';
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

  @override
  void dispose() {
    _slideController.dispose();
    _scrollController.dispose();
    _ws.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final panelHeight = MediaQuery.of(context).size.height * 0.45;

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
              child: Container(
                height: panelHeight,
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
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
                          return AgentBubble(
                            text: item['text'] as String,
                            isAgent: item['role'] == 'agent',
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
