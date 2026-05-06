import 'package:flutter/material.dart';
import '../widgets/elder_bottom_nav.dart';

class OperationLogsPage extends StatelessWidget {
  const OperationLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('操作记录')),
      body: const Center(
        child: Text('暂无操作记录', style: TextStyle(fontSize: 18, color: Colors.grey)),
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }
}
