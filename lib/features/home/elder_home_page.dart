import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';

class ElderHomePage extends ConsumerStatefulWidget {
  const ElderHomePage({super.key});

  @override
  ConsumerState<ElderHomePage> createState() => _ElderHomePageState();
}

class _ElderHomePageState extends ConsumerState<ElderHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('浙里办 · 长辈版'),
        bottom: TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: '热门服务'),
            Tab(text: '我的常用'),
            Tab(text: '我的订阅'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => context.go(AppRoutes.search),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tab,
        children: const [
          Center(child: Text('热门服务（Phase 0 占位）')),
          Center(child: Text('我的常用（Phase 0 占位）')),
          Center(child: Text('我的订阅（Phase 0 占位）')),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '我的'),
        ],
        onTap: (i) {
          if (i == 1) context.go(AppRoutes.my);
        },
      ),
    );
  }
}
