import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SocialInsurancePage extends ConsumerWidget {
  const SocialInsurancePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('社保缴费')),
      body: const Center(child: Text('SocialInsurancePage（Phase 0 占位）')),
    );
  }
}
