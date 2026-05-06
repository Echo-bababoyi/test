import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

// mock 服务数据：(名称, 路由, 关键词)
const _allServices = [
  _Service('医保缴费', '/elder/yibao-jiaofei', ['医保', '缴费', '社保', '保险']),
  _Service('医保查询', '/elder/yibao-query',   ['医保', '查询', '余额', '账户']),
  _Service('养老金查询', '/elder/pension-query', ['养老', '养老金', '退休', '查询']),
  _Service('搜索服务', '/elder/search',         ['搜索', '查找']),
];

// 热门标签：名称 → 路由（null 表示仅展示）
const _hotTags = [
  ('医保缴费',   '/elder/yibao-jiaofei'),
  ('养老金查询', '/elder/pension-query'),
  ('公积金',     null),
  ('社保卡',     null),
  ('健康码',     null),
];

class _Service {
  final String name;
  final String route;
  final List<String> keywords;
  const _Service(this.name, this.route, this.keywords);
}

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  List<_Service> _results = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onSearch);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _controller.text.trim();
    if (q.isEmpty) {
      setState(() => _results = []);
      return;
    }
    setState(() {
      _results = _allServices.where((s) {
        return s.name.contains(q) || s.keywords.any((k) => k.contains(q) || q.contains(k));
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('搜索服务', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 搜索框区（橙色延续 AppBar）
          Container(
            color: _kOrange,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _kSurface,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 18),
                textAlignVertical: TextAlignVertical.center,
                decoration: const InputDecoration(
                  hintText: '请输入服务关键词',
                  hintStyle: TextStyle(fontSize: 16, color: Color(0xFFBBBBBB)),
                  prefixIcon: Icon(Icons.search, color: Color(0xFF999999)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 0),
                  isDense: true,
                ),
              ),
            ),
          ),

          // 内容区
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_controller.text.isEmpty) ...[
                    // 热门搜索标签
                    const Text('热门搜索', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _hotTags.map((tag) {
                        final (name, route) = tag;
                        return _HotChip(
                          label: name,
                          onTap: route != null ? () => context.push(route) : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    const Text('全部服务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                    const SizedBox(height: 12),
                    ..._allServices.map((s) => _ServiceTile(service: s)),
                  ] else if (_results.isEmpty) ...[
                    const SizedBox(height: 40),
                    const Center(
                      child: Column(
                        children: [
                          Icon(Icons.search_off, size: 64, color: Color(0xFFCCCCCC)),
                          SizedBox(height: 12),
                          Text('没有找到相关服务', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text('找到 ${_results.length} 个服务', style: const TextStyle(fontSize: 15, color: Color(0xFF999999))),
                    const SizedBox(height: 12),
                    ..._results.map((s) => _ServiceTile(service: s)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

class _HotChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _HotChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: _kSurface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [_kShadow],
          border: onTap != null ? Border.all(color: const Color(0xFFFFCC80)) : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 16,
            color: onTap != null ? _kOrange : const Color(0xFF666666),
            fontWeight: onTap != null ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _ServiceTile extends StatelessWidget {
  final _Service service;
  const _ServiceTile({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => context.push(service.route),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: _kSurface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: const [_kShadow],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3E0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment, color: _kOrange, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(service.name, style: const TextStyle(fontSize: 18, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFFCCCCCC)),
            ],
          ),
        ),
      ),
    );
  }
}
