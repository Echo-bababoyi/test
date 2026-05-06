import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../services/ws_client.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class PensionQueryPage extends StatefulWidget {
  const PensionQueryPage({super.key});

  @override
  State<PensionQueryPage> createState() => _PensionQueryPageState();
}

class _PensionQueryPageState extends State<PensionQueryPage> {
  bool _hasResult = false;
  static const _mockAmount = '3280';

  final _queryKey = AgentElementRegistry.register('btn_query');
  final _resultKey = AgentElementRegistry.register('result_pension_amount');

  void _doQuery() {
    setState(() => _hasResult = true);
    WsClient.instance.send('query_result_ready', {
      'page_id': 'pension_query',
      'result_fields': {
        'month': '2026年5月',
        'amount': _mockAmount,
        'unit': '元',
      },
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('养老金查询', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 56,
              child: ElevatedButton(
                key: _queryKey,
                onPressed: _doQuery,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('查询', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 20),
            if (_hasResult) ...[
              // 个人信息卡（橙色渐变，参考 v1 蓝色渐变头）
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [_kShadow],
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('个人基本信息', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(height: 12),
                        Row(
                          children: [
                            Text('姓名', style: TextStyle(fontSize: 15, color: Colors.white70)),
                            Spacer(),
                            Text('*宇澄', style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Text('证件号码', style: TextStyle(fontSize: 15, color: Colors.white70)),
                            Spacer(),
                            Text('3****************3', style: TextStyle(fontSize: 14, color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Text(
                        'SI',
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white.withValues(alpha: 0.12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 金额结果卡
              Container(
                key: _resultKey,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [_kShadow],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('本月养老金', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                    const SizedBox(height: 4),
                    const Text('2026年5月', style: TextStyle(fontSize: 16, color: Color(0xFF999999))),
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('¥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kOrange)),
                        const SizedBox(width: 2),
                        const Text(_mockAmount, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _kOrange)),
                        const SizedBox(width: 6),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4),
                          child: Text('元', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('参保状态：正常', style: TextStyle(fontSize: 14, color: Color(0xFF4CAF50))),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}
