import 'package:flutter/material.dart';

class OperationLogsPage extends StatelessWidget {
  const OperationLogsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('操作记录')),
      body: const Center(child: Text('OperationLogsPage')),
    );
  }
}
