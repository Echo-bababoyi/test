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
      return '${dt.month}月${dt.day}日 ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  static const _pageIcons = {
    'yibao_jiaofei': Icons.medical_services_outlined,
    'yibao_query': Icons.search_outlined,
    'pension_query': Icons.account_balance_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('草稿箱', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
          : _drafts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.inbox_outlined, size: 72, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 16),
                      Text('暂无草稿', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                  itemCount: _drafts.length,
                  itemBuilder: (_, i) {
                    final d = _drafts[i];
                    final pageId = d['page_id'] as String? ?? '';
                    final pageTitle = d['page_title'] as String? ?? '';
                    final timeStr = _formatTime(d['updated_at'] as String?);
                    final icon = _pageIcons[pageId] ?? Icons.edit_outlined;
                    final route = _routeForPageId(pageId);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x0D000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(icon, color: const Color(0xFFFF6D00), size: 26),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pageTitle,
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '上次编辑：$timeStr',
                                    style: const TextStyle(fontSize: 13, color: Color(0xFF999999)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: route.isEmpty ? null : () => context.push(route),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFF6D00),
                                foregroundColor: Colors.white,
                                minimumSize: const Size(88, 44),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                              ),
                              child: const Text('继续填写', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
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
