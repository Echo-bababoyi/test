import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class PensionQueryPage extends ConsumerWidget {
  const PensionQueryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('养老金查询')),
      body: const Center(child: Text('PensionQueryPage（Phase 0 占位）')),
    );
  }
}
