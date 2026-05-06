import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../services/ws_client.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class YibaoQueryPage extends StatefulWidget {
  const YibaoQueryPage({super.key});

  @override
  State<YibaoQueryPage> createState() => _YibaoQueryPageState();
}

class _YibaoQueryPageState extends State<YibaoQueryPage> {
  bool _hasResult = false;
  static const _mockBalance = '12560';

  final _queryKey = AgentElementRegistry.register('btn_query');
  final _resultKey = AgentElementRegistry.register('result_yibao_amount');

  void _doQuery() {
    setState(() => _hasResult = true);
    WsClient.instance.send('query_result_ready', {
      'page_id': 'yibao_query',
      'result_fields': {
        'balance': _mockBalance,
        'unit': '元',
        'status': '正常',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('医保查询', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: const [ConnectionIndicator()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: ElevatedButton(
                key: _queryKey,
                onPressed: _doQuery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('查询', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
            if (_hasResult) ...[
              // 个人信息头卡
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF26C6DA), Color(0xFF00838F)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [_kShadow],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('医保账户信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text('姓名', style: TextStyle(fontSize: 15, color: Colors.white70)),
                            Spacer(),
                            Text('*宇澄', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text('证件号码', style: TextStyle(fontSize: 15, color: Colors.white70)),
                            Spacer(),
                            Text('3****************3', style: TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Text(
                        'YB',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 余额结果卡
              Container(
                key: _resultKey,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [_kShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('医保账户余额', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                    const SizedBox(height: 4),
                    Row(
                      children: const [
                        Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 18),
                        SizedBox(width: 6),
                        Text('状态：正常', style: TextStyle(fontSize: 16, color: Color(0xFF4CAF50))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('¥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kOrange)),
                        const SizedBox(width: 2),
                        const Text(_mockBalance, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _kOrange)),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('元', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}
