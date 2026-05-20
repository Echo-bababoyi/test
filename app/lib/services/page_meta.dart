import 'package:flutter/material.dart';

class PageMeta {
  final String pageId;
  final String pageTitle;
  final String route;
  final IconData icon;
  final int requiredFields;
  final List<String> fieldKeys;

  const PageMeta({
    required this.pageId,
    required this.pageTitle,
    required this.route,
    required this.icon,
    required this.requiredFields,
    required this.fieldKeys,
  });
}

const _registry = <String, PageMeta>{
  'yibao_jiaofei': PageMeta(
    pageId: 'yibao_jiaofei',
    pageTitle: '医保缴费',
    route: '/service/yibao-jiaofei',
    icon: Icons.medical_services_outlined,
    requiredFields: 4,
    fieldKeys: ['target_person', 'xianzhong', 'year', 'dangci'],
  ),
};

PageMeta? metaForPageId(String pageId) => _registry[pageId];

PageMeta? metaForRoute(String route) {
  for (final m in _registry.values) {
    if (m.route == route) return m;
  }
  return null;
}
