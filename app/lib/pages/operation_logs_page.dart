import 'package:flutter/material.dart';
import '../router.dart';
import '../services/operation_log_store.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

const _sceneIconMap = <String, IconData>{
  'yibao_jiaofei': Icons.health_and_safety,
  'yibao_query':   Icons.search,
  'pension_query': Icons.account_balance,
  'shebao_query':  Icons.search,
  'face_login':    Icons.face_retouching_natural,
  'otp_login':     Icons.phone_android,
};

const _sceneTitleMap = <String, String>{
  'yibao_jiaofei': '医保缴费',
  'yibao_query':   '医保查询',
  'pension_query': '养老金查询',
  'shebao_query':  '社保查询',
  'face_login':    '刷脸登录',
  'otp_login':     '验证码登录',
};

const _fieldLabelMap = <String, String>{
  'jiaofei_niandu':       '缴费年度',
  'jiaofei_duixiang':     '缴费对象',
  'jiaofei_jine':         '缴费金额',
  'xian_zhong':           '险种',
  'dang_ci':              '档次',
  'id_card':              '证件号',
  'bei_jiaofei_xingming': '被缴费人姓名',
  'bei_jiaofei_sfz':      '被缴费人证件号',
  'query_year':           '查询年度',
  'result_status':        '查询结果',
  'bank_card':            '支付银行卡',
  'amount':               '金额',
};

class OperationLogsPage extends StatefulWidget {
  const OperationLogsPage({super.key});

  @override
  State<OperationLogsPage> createState() => _OperationLogsPageState();
}

class _OperationLogsPageState extends State<OperationLogsPage> {
  List<Map<String, dynamic>> _logs = [];
  bool _loading = true;
  final Set<String> _expanded = {};

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
    if (mounted) {
      setState(() {
        _logs = logs;
        _loading = false;
      });
    }
  }

  Future<void> _clearAll() async {
    await OperationLogStore.clearAll();
    setState(() {
      _logs = [];
      _expanded.clear();
    });
  }

  void _showClearDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('清空操作记录',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.w600)),
        content: Text(
          '确认清空全部 ${_logs.length} 条操作记录？此操作不可撤销。',
          style: const TextStyle(fontSize: 17),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('取消',
                style: TextStyle(fontSize: 17)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _clearAll();
            },
            child: const Text(
              '确认清空',
              style: TextStyle(
                  fontSize: 17, color: Color(0xFFFF6D00)),
            ),
          ),
        ],
      ),
    );
  }

  List<dynamic> _groupedItems() {
    final now = DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);
    final yesterdayDate = todayDate.subtract(const Duration(days: 1));

    final todayLogs = <Map<String, dynamic>>[];
    final yesterdayLogs = <Map<String, dynamic>>[];
    final earlierLogs = <Map<String, dynamic>>[];

    for (final log in _logs) {
      try {
        final dt =
            DateTime.parse(log['created_at'] as String? ?? '').toLocal();
        final d = DateTime(dt.year, dt.month, dt.day);
        if (d == todayDate) {
          todayLogs.add(log);
        } else if (d == yesterdayDate) {
          yesterdayLogs.add(log);
        } else {
          earlierLogs.add(log);
        }
      } catch (_) {
        earlierLogs.add(log);
      }
    }

    final items = <dynamic>[];
    if (todayLogs.isNotEmpty) {
      items.add('今天');
      items.addAll(todayLogs);
    }
    if (yesterdayLogs.isNotEmpty) {
      items.add('昨天');
      items.addAll(yesterdayLogs);
    }
    if (earlierLogs.isNotEmpty) {
      items.add('更早');
      items.addAll(earlierLogs);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('操作记录',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFFF6D00),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!_loading && _logs.isNotEmpty)
            TextButton(
              onPressed: _showClearDialog,
              child: const Text('清空',
                  style: TextStyle(color: Colors.white, fontSize: 14)),
            ),
        ],
      ),
      body: Stack(
        children: [
          _loading
              ? const Center(
                  child: CircularProgressIndicator(
                      color: Color(0xFFFF6D00)))
              : _logs.isEmpty
                  ? _buildEmpty()
                  : _buildList(),
          const Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.operationLogs),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
    );
  }

  Widget _buildEmpty() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.manage_search, size: 64, color: Color(0xFFBDBDBD)),
          SizedBox(height: 16),
          Text('暂无操作记录',
              style: TextStyle(fontSize: 20, color: Color(0xFF757575))),
          SizedBox(height: 8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              '小浙助手帮您办事后，记录会显示在这里',
              style: TextStyle(fontSize: 16, color: Color(0xFFBDBDBD)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final items = _groupedItems();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        if (item is String) {
          return _GroupHeader(label: item);
        }
        final log = item as Map<String, dynamic>;
        final logId = log['log_id'] as String? ?? '';
        return _LogCard(
          log: log,
          isExpanded: _expanded.contains(logId),
          onToggle: () => setState(() {
            if (_expanded.contains(logId)) {
              _expanded.remove(logId);
            } else {
              _expanded.add(logId);
            }
          }),
        );
      },
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final String label;
  const _GroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(label,
          style: const TextStyle(fontSize: 16, color: Color(0xFF9E9E9E))),
    );
  }
}

class _LogCard extends StatelessWidget {
  final Map<String, dynamic> log;
  final bool isExpanded;
  final VoidCallback onToggle;

  const _LogCard({
    required this.log,
    required this.isExpanded,
    required this.onToggle,
  });

  static String _formatTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.month.toString().padLeft(2, '0')}月'
          '${dt.day.toString().padLeft(2, '0')}日 '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }

  static String _stepText(Map<String, dynamic> step) {
    const meta = {'action', 'target', 'seq', 'by'};
    final parts = <String>[];
    // Stage 1: action + target
    if (step.containsKey('action')) {
      final action = step['action'] as String? ?? '';
      final target = step['target'] as String? ?? '';
      if (action.isNotEmpty || target.isNotEmpty) {
        parts.add(target.isNotEmpty ? '$action：$target' : action);
      }
    }
    // Stage 2: remaining non-meta fields via _fieldLabelMap
    for (final entry in step.entries) {
      if (meta.contains(entry.key)) continue;
      final label = _fieldLabelMap[entry.key] ?? entry.key;
      parts.add('$label：${entry.value}');
    }
    return parts.join('  ');
  }

  @override
  Widget build(BuildContext context) {
    final scene = log['scene'] as String? ?? '';
    final sceneTitle = (log['scene_title'] as String?)?.isNotEmpty == true
        ? log['scene_title'] as String
        : _sceneTitleMap[scene] ?? scene;
    final trigger = log['trigger'] as String? ?? 'manual';
    final status = log['status'] as String? ?? 'completed';
    final summary = log['summary'] as String? ?? '';
    final steps = log['steps'] as List<dynamic>? ?? [];
    final icon = _sceneIconMap[scene] ?? Icons.task_alt;
    final timeStr = _formatTime(log['created_at'] as String?);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: steps.isEmpty ? null : onToggle,
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon,
                          color: const Color(0xFFFF6D00), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(sceneTitle,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF333333))),
                              const SizedBox(width: 8),
                              _TriggerBadge(trigger: trigger),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(timeStr,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                    if (steps.isNotEmpty)
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up
                            : Icons.keyboard_arrow_down,
                        color: const Color(0xFF999999),
                        size: 20,
                      ),
                  ],
                ),
              ),
              if (summary.isNotEmpty || status != 'completed')
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (status == 'failed')
                        const Text('✕ 失败  ',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFFFF3B30))),
                      if (status == 'cancelled')
                        const Text('⊘ 已取消  ',
                            style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF9E9E9E))),
                      Expanded(
                        child: Text(
                          summary,
                          style: const TextStyle(
                              fontSize: 18, color: Color(0xFF666666)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              if (steps.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    isExpanded ? '收起 ▲' : '查看步骤详情 ▼',
                    style: const TextStyle(
                        fontSize: 14, color: Color(0xFFFF6D00)),
                  ),
                ),
              if (isExpanded && steps.isNotEmpty) ...[
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: steps.asMap().entries.map((entry) {
                      final step = Map<String, dynamic>.from(
                          entry.value as Map);
                      final seq =
                          step['seq'] as int? ?? (entry.key + 1);
                      final by = step['by'] as String? ?? 'user';
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '$seq. ${_stepText(step)}',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Color(0xFF333333)),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _ByBadge(by: by),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              const SizedBox(height: 14),
            ],
          ),
        ),
      ),
    );
  }
}

class _TriggerBadge extends StatelessWidget {
  final String trigger;
  const _TriggerBadge({required this.trigger});

  @override
  Widget build(BuildContext context) {
    final isVoice = trigger == 'voice';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isVoice
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isVoice ? '小浙代办' : '自行操作',
        style: TextStyle(
          fontSize: 11,
          color: isVoice
              ? const Color(0xFFFF6D00)
              : const Color(0xFF757575),
        ),
      ),
    );
  }
}

class _ByBadge extends StatelessWidget {
  final String by;
  const _ByBadge({required this.by});

  @override
  Widget build(BuildContext context) {
    final isAgent = by == 'agent';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: isAgent
            ? const Color(0xFFFFF3E0)
            : const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        isAgent ? '小浙' : '您',
        style: TextStyle(
          fontSize: 11,
          color: isAgent
              ? const Color(0xFFFF6D00)
              : const Color(0xFF9E9E9E),
        ),
      ),
    );
  }
}
