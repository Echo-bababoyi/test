import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

class SearchResultPage extends ConsumerWidget {
  const SearchResultPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('搜索结果')),
      body: ListView(
        children: [
          ListTile(
            title: const Text('社保缴费'),
            subtitle: const Text('社保费缴纳服务'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.socialInsurance),
          ),
          ListTile(
            title: const Text('养老金查询'),
            subtitle: const Text('社保查询服务'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(AppRoutes.pensionQuery),
          ),
        ],
      ),
    );
  }
}
