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

class ElderHome extends StatelessWidget {
  const ElderHome({super.key});

  static const _services = [
    {'label': '医保缴费', 'icon': Icons.medical_services, 'route': '/elder/yibao-jiaofei', 'color': Color(0xFFFF6D00)},
    {'label': '医保查询', 'icon': Icons.health_and_safety, 'route': '/elder/yibao-query', 'color': Color(0xFF26C6DA)},
    {'label': '养老金查询', 'icon': Icons.account_balance_wallet, 'route': '/elder/pension-query', 'color': Color(0xFF5B6BF5)},
    {'label': '搜索服务', 'icon': Icons.manage_search, 'route': '/elder/search', 'color': Color(0xFF4CAF50)},
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.month}月${now.day}日';
    final hour = now.hour;
    final greeting = hour < 12 ? '上午好' : (hour < 18 ? '下午好' : '晚上好');

    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: _kOrange,
        elevation: 0,
        title: const Text('小浙助手', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 问候栏
            Container(
              color: _kOrange,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.waving_hand, color: Colors.white, size: 28),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('您好，$greeting！', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('今天是 $dateStr', style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // 功能入口卡片网格
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('常用服务', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                  const SizedBox(height: 12),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.1,
                    children: _services.map((s) {
                      return _ServiceCard(
                        label: s['label'] as String,
                        icon: s['icon'] as IconData,
                        color: s['color'] as Color,
                        onTap: () => context.push(s['route'] as String),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // 助手提示卡
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [_kShadow],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(color: _kOrange, shape: BoxShape.circle),
                      child: const Icon(Icons.mic, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('小浙帮您办', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                          SizedBox(height: 4),
                          Text('点击底部麦克风，开口就能查询办理', style: TextStyle(fontSize: 15, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [_kShadow],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
            ],
          ),
        ),
      ),
    );
  }
}
