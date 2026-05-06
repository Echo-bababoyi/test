import 'package:flutter/material.dart';
import '../widgets/elder_bottom_nav.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  static const int _draftCount = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('我的')),
      body: ListView(
        children: [
          const _UserHeader(),
          const Divider(),
          _MenuTile(
            icon: Icons.edit_document,
            label: '草稿箱',
            badge: _draftCount,
            onTap: () {},
          ),
          _MenuTile(
            icon: Icons.history,
            label: '操作记录',
            onTap: () {},
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }
}

class _UserHeader extends StatelessWidget {
  const _UserHeader();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: Colors.orange.shade100,
            child: const Icon(Icons.person, size: 40, color: Color(0xFFFF6D00)),
          ),
          const SizedBox(width: 16),
          const Text('未登录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final VoidCallback onTap;

  const _MenuTile({required this.icon, required this.label, this.badge = 0, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xFFFF6D00), size: 28),
      title: Text(label, style: const TextStyle(fontSize: 18)),
      trailing: badge > 0
          ? Badge(label: Text('$badge'), child: const Icon(Icons.chevron_right))
          : const Icon(Icons.chevron_right),
      onTap: onTap,
      minVerticalPadding: 16,
    );
  }
}
