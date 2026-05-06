import 'package:flutter/material.dart';

class FaceAuthPage extends StatelessWidget {
  const FaceAuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('刷脸登录')),
      body: const Center(child: Text('FaceAuthPage')),
    );
  }
}
