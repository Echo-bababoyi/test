import 'package:flutter/material.dart';
import '../router.dart';
import '../services/agent_element_registry.dart';
import '../services/ws_client.dart';
import '../widgets/agent_fab.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kOrangeLight = Color(0xFFFFF3E0);
const _kBg = Color(0xFFFFFBF5);
const _kSurface = Colors.white;

class PensionQueryPage extends StatefulWidget {
  const PensionQueryPage({super.key});

  @override
  State<PensionQueryPage> createState() => _PensionQueryPageState();
}

class _PensionQueryPageState extends State<PensionQueryPage> {
  bool _hasResult = false;
  String _selectedMonth = '2026年5月';
  static const _mockAmount = '3280';

  final _queryKey = AgentElementRegistry.register('btn_query');
  final _resultKey = AgentElementRegistry.register('result_pension_amount');

  void _doQuery() {
    setState(() => _hasResult = true);
    WsClient.instance.send('query_result_ready', {
      'page_id': 'pension_query',
      'result_fields': {
        'month': _selectedMonth,
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
      body: Stack(
        fit: StackFit.expand,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_hasResult) ...[
                  _buildGuideSection(),
                  const SizedBox(height: 20),
                ],
                _buildMonthSelector(),
                const SizedBox(height: 16),
                _buildQueryButton(),
                if (_hasResult) ...[
                  const SizedBox(height: 20),
                  _buildPersonalInfoCard(),
                  const SizedBox(height: 16),
                  _buildAmountCard(),
                ] else ...[
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      '点击查询获取本月养老金发放详情',
                      style: TextStyle(fontSize: 18, color: Color(0xFF999999)),
                    ),
                  ),
                ],
              ],
            ),
          ),
          Positioned.fill(
            child: AgentFab(currentPath: AppRoutes.pensionQuery),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }

  Widget _buildGuideSection() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kOrange.withValues(alpha: 0.08),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _kOrange.withValues(alpha: 0.12),
              ),
            ),
            const Icon(Icons.account_balance_wallet_rounded, size: 48, color: _kOrange),
          ],
        ),
        const SizedBox(height: 16),
        const Text(
          '查询您的养老金发放情况',
          style: TextStyle(fontSize: 20, color: Color(0xFF666666), fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.chevron_left, color: Color(0xFF999999), size: 24),
          ),
          const SizedBox(width: 20),
          Text(
            _selectedMonth,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF333333)),
          ),
          const SizedBox(width: 20),
          GestureDetector(
            onTap: () {},
            child: const Icon(Icons.chevron_right, color: Color(0xFF999999), size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildQueryButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        key: _queryKey,
        onPressed: _doQuery,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kOrange,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
          shadowColor: const Color(0x33FF6D00),
        ),
        child: const Text('查询', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildPersonalInfoCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF9A3C), Color(0xFFFF6D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x33FF6D00), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('个人基本信息', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white)),
              SizedBox(height: 14),
              Row(
                children: [
                  Text('姓名', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  Spacer(),
                  Text('*宇澄', style: TextStyle(fontSize: 20, color: Colors.white, fontWeight: FontWeight.w600)),
                ],
              ),
              SizedBox(height: 10),
              Row(
                children: [
                  Text('证件号码', style: TextStyle(fontSize: 18, color: Colors.white70)),
                  Spacer(),
                  Text('3****************3', style: TextStyle(fontSize: 18, color: Colors.white)),
                ],
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Icon(Icons.shield_outlined, size: 64, color: Color(0x14FFFFFF)),
          ),
          Positioned(
            top: -1,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: const BoxDecoration(
                color: Color(0xFFFFAB40),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(6),
                  bottomRight: Radius.circular(6),
                ),
              ),
              child: const Text('已认证', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      key: _resultKey,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('本月养老金', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
          const SizedBox(height: 4),
          Text(_selectedMonth, style: const TextStyle(fontSize: 18, color: Color(0xFF999999))),
          const SizedBox(height: 16),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('¥', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: _kOrange)),
              SizedBox(width: 2),
              Text(_mockAmount, style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: _kOrange)),
              SizedBox(width: 6),
              Padding(
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
            child: const Text('参保状态：正常', style: TextStyle(fontSize: 18, color: Color(0xFF4CAF50))),
          ),
          const Divider(color: Color(0xFFEEEEEE), height: 32),
          _buildDetailRow('发放日期', '2026年5月15日'),
          const SizedBox(height: 10),
          _buildDetailRow('发放账户', '工商银行 ****3456'),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(color: _kOrange, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontSize: 18, color: Color(0xFF999999))),
        const Spacer(),
        Text(value, style: const TextStyle(fontSize: 18, color: Color(0xFF333333), fontWeight: FontWeight.w500)),
      ],
    );
  }
}