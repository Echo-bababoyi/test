import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../widgets/elder_bottom_nav.dart';

class YibaoJiaofeiPage extends StatefulWidget {
  const YibaoJiaofeiPage({super.key});

  @override
  State<YibaoJiaofeiPage> createState() => _YibaoJiaofeiPageState();
}

class _YibaoJiaofeiPageState extends State<YibaoJiaofeiPage> {
  String? _targetPerson;
  String? _year;
  final _amountController = TextEditingController();
  final _idController = TextEditingController();

  final _targetKey = AgentElementRegistry.register('yibao_jiaofei_target');
  final _yearKey = AgentElementRegistry.register('yibao_jiaofei_year');
  final _amountKey = AgentElementRegistry.register('yibao_jiaofei_amount');
  final _idKey = AgentElementRegistry.register('yibao_jiaofei_id');
  final _submitKey = AgentElementRegistry.register('yibao_jiaofei_submit');

  static const _persons = ['本人', '配偶', '子女'];
  static const _years = ['2024年度', '2025年度', '2026年度'];

  @override
  void dispose() {
    _amountController.dispose();
    _idController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('医保缴费')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _label('缴费对象'),
          DropdownButtonFormField<String>(
            key: _targetKey,
            value: _targetPerson,
            items: _persons.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 18)))).toList(),
            onChanged: (v) => setState(() => _targetPerson = v),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _label('缴费年度'),
          DropdownButtonFormField<String>(
            key: _yearKey,
            value: _year,
            items: _years.map((y) => DropdownMenuItem(value: y, child: Text(y, style: const TextStyle(fontSize: 18)))).toList(),
            onChanged: (v) => setState(() => _year = v),
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          _label('缴费金额'),
          TextField(
            key: _amountKey,
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(border: OutlineInputBorder(), suffixText: '元'),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _label('身份证号'),
          TextField(
            key: _idKey,
            controller: _idController,
            decoration: const InputDecoration(border: OutlineInputBorder()),
            style: const TextStyle(fontSize: 18),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            key: _submitKey,
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6D00),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 56),
            ),
            child: const Text('去支付', style: TextStyle(fontSize: 20)),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 16, color: Colors.grey)),
    );
  }
}
