import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/draft_store.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kOrangeLight = Color(0xFFFFF3E0);
const _kBg = Color(0xFFF5F5F5);

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

  static const _fieldCounts = {
    'yibao_jiaofei': (3, 5),
    'yibao_query': (1, 3),
    'pension_query': (1, 2),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        title: const Text('草稿箱', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(child: CircularProgressIndicator(color: _kOrange))
              : _drafts.isEmpty
                  ? _buildEmptyState()
                  : _buildDraftList(),
          Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.drafts),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: _kOrangeLight,
                ),
              ),
              Positioned(
                top: 10,
                right: 20,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kOrange.withValues(alpha: 0.2),
                  ),
                ),
              ),
              Positioned(
                bottom: 20,
                left: 15,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _kOrange.withValues(alpha: 0.3),
                  ),
                ),
              ),
              const Icon(Icons.folder_open_rounded, size: 56, color: Color(0xFFFFAB40)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('还没有草稿', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
          const SizedBox(height: 8),
          const Text(
            '办事过程中的未完成表单\n会保存在这里',
            style: TextStyle(fontSize: 18, color: Color(0xFF999999), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: () => context.go('/elder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kOrange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              elevation: 0,
            ),
            child: const Text('去办事', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Widget _buildDraftList() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          color: Colors.white,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(color: _kOrange, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Text(
                '共 ${_drafts.length} 份草稿待完成',
                style: const TextStyle(fontSize: 18, color: Color(0xFF666666), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            itemCount: _drafts.length,
            itemBuilder: (_, i) => _buildDraftCard(_drafts[i]),
          ),
        ),
      ],
    );
  }

  Widget _buildDraftCard(Map<String, dynamic> d) {
    final pageId = d['page_id'] as String? ?? '';
    final pageTitle = d['page_title'] as String? ?? '';
    final timeStr = _formatTime(d['updated_at'] as String?);
    final icon = _pageIcons[pageId] ?? Icons.edit_outlined;
    final route = _routeForPageId(pageId);
    final counts = _fieldCounts[pageId] ?? (1, 3);
    final progress = counts.$1 / counts.$2;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: const [
              BoxShadow(color: Color(0x0AFF6D00), blurRadius: 12, offset: Offset(0, 4)),
              BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
            ],
          ),
          child: InkWell(
            onTap: route.isEmpty ? null : () => context.push(route),
            borderRadius: BorderRadius.circular(14),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    decoration: const BoxDecoration(
                      color: _kOrange,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(14),
                        bottomLeft: Radius.circular(14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFFF8F0), _kOrangeLight],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(icon, color: _kOrange, size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  pageTitle,
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
                                ),
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: SizedBox(
                                    height: 4,
                                    child: LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: const Color(0xFFEEEEEE),
                                      valueColor: const AlwaysStoppedAnimation<Color>(_kOrange),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '已填写 ${counts.$1}/${counts.$2} 项 · $timeStr',
                                  style: const TextStyle(fontSize: 14, color: Color(0xFF999999)),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            decoration: BoxDecoration(
                              color: _kOrange,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: const [
                                BoxShadow(color: Color(0x33FF6D00), blurRadius: 8, offset: Offset(0, 2)),
                              ],
                            ),
                            child: const Text('继续', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _routeForPageId(String pageId) {
    return switch (pageId) {
      'yibao_jiaofei' => '/service/yibao-jiaofei',
      'yibao_query' => '/service/yibao-query',
      'pension_query' => '/service/pension-query',
      _ => '',
    };
  }
}