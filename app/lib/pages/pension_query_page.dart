import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../widgets/elder_bottom_nav.dart';

class PensionQueryPage extends StatefulWidget {
  const PensionQueryPage({super.key});

  @override
  State<PensionQueryPage> createState() => _PensionQueryPageState();
}

class _PensionQueryPageState extends State<PensionQueryPage> {
  bool _hasResult = false;
  String _amount = '';

  final _queryKey = AgentElementRegistry.register('pension_query_btn_query');
  final _resultKey = AgentElementRegistry.register('pension_query_result_amount');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('养老金查询')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              key: _queryKey,
              onPressed: () => setState(() {
                _hasResult = true;
                _amount = '3,200.00';
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
                      const Text('本月养老金', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      const SizedBox(height: 8),
                      Text('¥$_amount', style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFFFF6D00))),
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
