import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../services/ws_client.dart';
import '../widgets/elder_bottom_nav.dart';

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
      appBar: AppBar(title: const Text('医保查询')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              key: _queryKey,
              onPressed: _doQuery,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF6D00),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 56),
              ),
              child: const Text('查询', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(height: 24),
            if (_hasResult)
              Card(
                key: _resultKey,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('医保账户余额（状态：正常）', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('¥$_mockBalance 元', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF6D00))),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}
