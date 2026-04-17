import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/state/app_state.dart';

class StandardHomePage extends ConsumerWidget {
  const StandardHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浙里办 · 标准版'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            FilledButton(
              onPressed: () {
                ref.read(modeProvider.notifier).toElder();
                context.go(AppRoutes.elderHome);
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('进入长辈版', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('🔧 Phase 0 开发导航面板（后续阶段删除）',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ),
            Expanded(
              child: ListView(
                children: [
                  for (final (label, path) in AppRoutes.all)
                    ListTile(
                      dense: true,
                      title: Text(label),
                      subtitle: Text(path,
                          style: const TextStyle(fontSize: 11)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(path),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
