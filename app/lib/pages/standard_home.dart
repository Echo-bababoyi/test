import 'package:flutter/material.dart';

class StandardHome extends StatelessWidget {
  const StandardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('标准版首页')),
      body: const Center(child: Text('StandardHome')),
    );
  }
}
