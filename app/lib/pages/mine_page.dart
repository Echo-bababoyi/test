import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/auth_state.dart';
import '../services/draft_store.dart';
import '../widgets/connection_indicator.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  int _draftCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDraftCount();
  }

  Future<void> _loadDraftCount() async {
    final drafts = await DraftStore.getAllDrafts();
    if (mounted) setState(() => _draftCount = drafts.length);
  }

  void _showAbout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('关于小浙', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('版本：1.0.0', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
            SizedBox(height: 12),
            Text(
              '小浙是浙里办的智能助手，帮助老年用户完成常用操作。',
              style: TextStyle(fontSize: 18, color: Color(0xFF333333), height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了', style: TextStyle(fontSize: 18, color: _kOrange)),
          ),
        ],
      ),
    );
  }

  void _logout() {
    AuthState.instance.logout();
    setState(() {});
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = AuthState.instance.isLoggedIn;
    final userName = AuthState.instance.userName ?? '张大爷';

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('我的', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: const [ConnectionIndicator()],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 用户信息卡片
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [_kShadow],
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(color: Color(0xFFFFF3E0), shape: BoxShape.circle),
                  child: const Icon(Icons.person, size: 40, color: _kOrange),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoggedIn ? userName : '未登录',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 4),
                    if (!isLoggedIn)
                      GestureDetector(
                        onTap: () => context.push('/login'),
                        child: const Text('点击登录 ›', style: TextStyle(fontSize: 16, color: _kOrange)),
                      )
                    else
                      const Text('已登录', style: TextStyle(fontSize: 15, color: Color(0xFF4CAF50))),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 功能菜单卡片
          Container(
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [_kShadow],
            ),
            child: Column(
              children: [
                _MenuTile(
                  icon: Icons.edit_document,
                  label: '草稿箱',
                  badge: _draftCount,
                  onTap: () => context.push('/elder/drafts'),
                  isFirst: true,
                ),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                  icon: Icons.history,
                  label: '操作记录',
                  onTap: () => context.push('/elder/operation-logs'),
                ),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                  icon: Icons.format_size,
                  label: '字体大小',
                  trailing: const Text('大字', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                  onTap: null,
                ),
                const Divider(height: 1, indent: 60),
                _MenuTile(
                  icon: Icons.info_outline,
                  label: '关于小浙',
                  onTap: _showAbout,
                  isLast: true,
                ),
              ],
            ),
          ),

          // 退出登录（仅已登录时显示）
          if (isLoggedIn) ...[
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: OutlinedButton(
                onPressed: _logout,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF3B30),
                  side: const BorderSide(color: Color(0xFFFF3B30)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('退出登录', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }
}

class _MenuTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badge;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isFirst;
  final bool isLast;

  const _MenuTile({
    required this.icon,
    required this.label,
    this.badge = 0,
    this.trailing,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.vertical(
        top: isFirst ? const Radius.circular(16) : Radius.zero,
        bottom: isLast ? const Radius.circular(16) : Radius.zero,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: _kOrange, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 18, color: Color(0xFF333333)))),
            if (badge > 0)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF3B30),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$badge', style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            if (trailing != null) trailing!,
            if (onTap != null)
              const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC), size: 22),
          ],
        ),
      ),
    );
  }
}
