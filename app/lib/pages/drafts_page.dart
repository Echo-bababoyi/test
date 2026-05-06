import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../services/draft_store.dart';
import '../widgets/elder_bottom_nav.dart';

class DraftsPage extends StatefulWidget {
  const DraftsPage({super.key});

  @override
  State<DraftsPage> createState() => _DraftsPageState();
}

class _DraftsPageState extends State<DraftsPage> {
  List<Map<String, dynamic>> _drafts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final drafts = await DraftStore.getAllDrafts();
    drafts.sort((a, b) {
      final ta = a['updated_at'] as String? ?? '';
      final tb = b['updated_at'] as String? ?? '';
      return tb.compareTo(ta);
    });
    setState(() {
      _drafts = drafts;
      _loading = false;
    });
  }

  String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('草稿箱')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _drafts.isEmpty
              ? const Center(child: Text('暂无草稿', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.separated(
                  itemCount: _drafts.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final d = _drafts[i];
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      title: Text(d['page_title'] as String? ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      subtitle: Text(_formatTime(d['updated_at'] as String?), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                      trailing: ElevatedButton(
                        onPressed: () {
                          final route = _routeForPageId(d['page_id'] as String? ?? '');
                          if (route.isNotEmpty) context.push(route);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6D00),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(80, 44),
                        ),
                        child: const Text('继续', style: TextStyle(fontSize: 16)),
                      ),
                    );
                  },
                ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }

  String _routeForPageId(String pageId) {
    return switch (pageId) {
      'yibao_jiaofei' => '/elder/yibao-jiaofei',
      'yibao_query' => '/elder/yibao-query',
      'pension_query' => '/elder/pension-query',
      _ => '',
    };
  }
}
