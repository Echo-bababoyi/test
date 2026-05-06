import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../widgets/elder_bottom_nav.dart';

class YibaoQueryPage extends StatefulWidget {
  const YibaoQueryPage({super.key});

  @override
  State<YibaoQueryPage> createState() => _YibaoQueryPageState();
}

class _YibaoQueryPageState extends State<YibaoQueryPage> {
  bool _hasResult = false;
  String _balance = '';

  final _queryKey = AgentElementRegistry.register('yibao_query_btn_query');
  final _resultKey = AgentElementRegistry.register('yibao_query_result_amount');

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
              onPressed: () => setState(() {
                _hasResult = true;
                _balance = '1,234.56';
              }),
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
                      const Text('医保账户余额', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('¥$_balance', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF6D00))),
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
