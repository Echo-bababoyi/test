import 'package:flutter/material.dart';
import '../../core/theme/design_tokens.dart';

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

  List<String> _suggestions() {
    if (query.isEmpty) return [];
    if (query == '医保缴费') {
      return [
        '医保缴费',
        '少儿医保缴费',
        '医保缴费记录',
        '农村医保缴费',
        '医保缴费查询',
        '浙里医保缴费',
        '个人医保缴费',
        '儿童医保缴费',
        '子女医保缴费',
        '农医保缴费',
        '浙江医保缴费',
      ];
    }
    if (query == '养老金查询') return ['养老金查询'];
    return [query];
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
        title: Text(items[i], style: const TextStyle(fontSize: 16)),
        onTap: () => onSelect(items[i]),
      ),
    );
  }
}
