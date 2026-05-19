import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 搜索联想词列表 — SearchPage 与 SearchResultPage 共用。
/// query 为空时不显示任何条目（返回空列表）。
class SearchSuggestionList extends StatelessWidget {
  final String query;
  final ValueChanged<String> onSelect;

  const SearchSuggestionList({
    super.key,
    required this.query,
    required this.onSelect,
  });

  static const _suggestionDict = {
    '养老金查询': ['养老金查询', '本月养老金', '养老金账单'],
    '医保缴费': ['医保缴费', '少儿医保缴费', '医保缴费记录', '城乡居民医保缴费'],
    '社保查询': ['社保查询', '社保缴费记录', '参保信息查询'],
    '社会保障': ['社保卡办理', '社保转移', '社保缴费基数'],
    '公积金': ['公积金查询', '公积金提取', '公积金贷款'],
    '养老保险': ['养老保险缴费', '养老金领取资格', '退休金查询'],
    '健康医保': ['医保报销', '医保定点医院', '异地就医备案'],
  };

  static const _synonyms = {
    '退休金': '养老金查询',
    '退休': '养老金查询',
    '医疗保险': '医保缴费',
    '社会保险': '社保查询',
    '住房公积金': '公积金',
  };

  List<String> _suggestions() {
    if (query.isEmpty) return [];
    final q = query.trim();
    final results = <String>{};

    // 1. key 层面 contains 匹配
    for (final entry in _suggestionDict.entries) {
      if (entry.key.contains(q)) {
        results.addAll(entry.value);
      }
    }
    // 2. 候选词层面 contains 匹配（"养老金"能命中"本月养老金"）
    for (final values in _suggestionDict.values) {
      for (final v in values) {
        if (v.contains(q)) results.add(v);
      }
    }
    // 3. 同义词映射
    for (final entry in _synonyms.entries) {
      if (q.contains(entry.key)) {
        results.addAll(_suggestionDict[entry.value] ?? []);
      }
    }

    if (results.isEmpty) return [q];
    return results.take(8).toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _suggestions();
    if (items.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) =>
          const Divider(height: 1, indent: Spacing.lg),
      itemBuilder: (context, i) => ListTile(
        title: Text(items[i], style: const TextStyle(fontSize: AppFontSize.elderBody)),
        onTap: () => onSelect(items[i]),
      ),
    );
  }
}
