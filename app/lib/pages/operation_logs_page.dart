import 'package:flutter/material.dart';
import '../services/operation_log_store.dart';
import '../widgets/elder_bottom_nav.dart';

class OperationLogsPage extends StatefulWidget {
  const OperationLogsPage({super.key});

  @override
  State<OperationLogsPage> createState() => _OperationLogsPageState();
}

class _OperationLogsPageState extends State<OperationLogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final logs = await OperationLogStore.getAllLogs();
    logs.sort((a, b) {
      final ta = a['created_at'] as String? ?? '';
      final tb = b['created_at'] as String? ?? '';
      return tb.compareTo(ta);
    });
    setState(() {
      _logs = logs;
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

  static const _sceneIcons = {
    'yibao_jiaofei': Icons.medical_services_outlined,
    'yibao_query': Icons.search_outlined,
    'pension_query': Icons.account_balance_outlined,
  };

  static const _sceneNames = {
    'yibao_jiaofei': '医保缴费',
    'yibao_query': '医保查询',
    'pension_query': '养老金查询',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('操作记录', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF6D00)))
          : _logs.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.history_outlined, size: 72, color: Color(0xFFCCCCCC)),
                      SizedBox(height: 16),
                      Text('暂无操作记录', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                  itemCount: _logs.length,
                  itemBuilder: (_, i) => _TimelineItem(
                    log: _logs[i],
                    isLast: i == _logs.length - 1,
                    isExpanded: _expanded.contains(i),
                    onToggle: () => setState(() {
                      if (_expanded.contains(i)) {
                        _expanded.remove(i);
                      } else {
                        _expanded.add(i);
                      }
                    }),
                    formatTime: _formatTime,
                    sceneIcons: _sceneIcons,
                    sceneNames: _sceneNames,
                  ),
                ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isLast;
  final bool isExpanded;
  final VoidCallback onToggle;
  final String Function(String?) formatTime;
  final Map<String, IconData> sceneIcons;
  final Map<String, String> sceneNames;

  const _TimelineItem({
    required this.log,
    required this.isLast,
    required this.isExpanded,
    required this.onToggle,
    required this.formatTime,
    required this.sceneIcons,
    required this.sceneNames,
  });

  @override
  Widget build(BuildContext context) {
    final scene = log['scene'] as String? ?? '';
    final timeStr = formatTime(log['created_at'] as String?);
    final summary = log['summary'] as String? ?? '';
    final steps = log['steps'] as List<dynamic>? ?? [];
    final icon = sceneIcons[scene] ?? Icons.task_outlined;
    final sceneName = sceneNames[scene] ?? scene;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 左侧时间线
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF6D00),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: isLast
                      ? const SizedBox()
                      : Center(
                          child: Container(
                            width: 2,
                            color: const Color(0xFFFFCC80),
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // 右侧卡片
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: steps.isEmpty ? null : onToggle,
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF3E0),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(icon, color: const Color(0xFFFF6D00), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(sceneName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                                  const SizedBox(height: 2),
                                  Text(timeStr, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                                ],
                              ),
                            ),
                            if (steps.isNotEmpty)
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                                color: const Color(0xFF999999),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                      if (summary.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                          child: Text(
                            summary,
                            style: const TextStyle(fontSize: 15, color: Color(0xFF666666)),
                            maxLines: isExpanded ? null : 2,
                            overflow: isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                          ),
                        ),
                      if (isExpanded && steps.isNotEmpty) ...[
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('操作明细', style: TextStyle(fontSize: 13, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              ...steps.map((s) {
                                final step = Map<String, dynamic>.from(s as Map);
                                final action = step['action'] as String? ?? '';
                                final details = step.entries
                                    .where((e) => e.key != 'action')
                                    .map((e) => '${e.key}: ${e.value}')
                                    .join('  ');
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 5),
                                        child: Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF4CAF50)),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(action, style: const TextStyle(fontSize: 15, color: Color(0xFF333333))),
                                            if (details.isNotEmpty)
                                              Text(details, style: const TextStyle(fontSize: 13, color: Color(0xFF999999))),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
