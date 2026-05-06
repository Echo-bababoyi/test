import 'package:flutter/material.dart';

class ElderHome extends StatelessWidget {
  const ElderHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('长辈版首页')),
      body: const Center(child: Text('ElderHome')),
    );
  }
}
