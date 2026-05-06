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
      return '${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('操作记录')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _logs.isEmpty
              ? const Center(child: Text('暂无操作记录', style: TextStyle(fontSize: 18, color: Colors.grey)))
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (_, i) {
                    final log = _logs[i];
                    final steps = log['steps'] as List<dynamic>? ?? [];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ExpansionTile(
                        title: Text(log['scene'] as String? ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                        subtitle: Text(_formatTime(log['created_at'] as String?), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                        children: [
                          if (steps.isEmpty)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: Text('无明细', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            )
                          else
                            ...steps.map((s) {
                              final step = Map<String, dynamic>.from(s as Map);
                              return ListTile(
                                dense: true,
                                title: Text(step['action'] as String? ?? '', style: const TextStyle(fontSize: 16)),
                                subtitle: Text(
                                  step.entries
                                      .where((e) => e.key != 'action')
                                      .map((e) => '${e.key}: ${e.value}')
                                      .join('  '),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }
}
