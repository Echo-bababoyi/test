import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/elder_bottom_nav.dart';

class ElderHome extends StatelessWidget {
  const ElderHome({super.key});

  static const _services = [
    {'label': '医保缴费', 'icon': Icons.medical_services, 'route': '/elder/yibao-jiaofei'},
    {'label': '医保查询', 'icon': Icons.search, 'route': '/elder/yibao-query'},
    {'label': '养老金查询', 'icon': Icons.account_balance_wallet, 'route': '/elder/pension-query'},
    {'label': '搜索服务', 'icon': Icons.manage_search, 'route': '/elder/search'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('小浙助手')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          children: _services.map((s) {
            return _ServiceCard(
              label: s['label'] as String,
              icon: s['icon'] as IconData,
              onTap: () => context.push(s['route'] as String),
            );
          }).toList(),
        ),
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ServiceCard({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: const Color(0xFFFF6D00)),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
