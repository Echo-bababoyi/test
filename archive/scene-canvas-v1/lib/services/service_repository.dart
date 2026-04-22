import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 扩展点 6：业务数据仓库
/// Phase 0：返回假数据
/// 后续：接真接口 / 由智能代理生成内容
class ServiceItem {
  final String id;
  final String title;
  final String? subtitle;
  final String? icon;
  const ServiceItem({
    required this.id,
    required this.title,
    this.subtitle,
    this.icon,
  });
}

abstract class ServiceRepository {
  Future<List<ServiceItem>> hotServices();
  Future<List<ServiceItem>> myFrequent();
  Future<List<ServiceItem>> mySubscriptions();
}

class MockServiceRepository implements ServiceRepository {
  @override
  Future<List<ServiceItem>> hotServices() async => const [
        ServiceItem(id: 'social', title: '社保缴费'),
        ServiceItem(id: 'pension', title: '养老金查询'),
        ServiceItem(id: 'medicare', title: '医保电子凭证'),
        ServiceItem(id: 'health_code', title: '健康码'),
      ];
  @override
  Future<List<ServiceItem>> myFrequent() async => const [];
  @override
  Future<List<ServiceItem>> mySubscriptions() async => const [];
}

final serviceRepositoryProvider =
    Provider<ServiceRepository>((ref) => MockServiceRepository());
