import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../services/draft_service.dart';
import '../widgets/elder_bottom_nav.dart';

class YibaoJiaofeiPage extends StatefulWidget {
  const YibaoJiaofeiPage({super.key});

  @override
  State<YibaoJiaofeiPage> createState() => _YibaoJiaofeiPageState();
}

class _YibaoJiaofeiPageState extends State<YibaoJiaofeiPage> {
  String? _targetPerson = '本人';
  String? _year = '2026年度';
  final _amountController = TextEditingController();
  final _idController = TextEditingController();

  final _targetKey = AgentElementRegistry.register('select_jiaofei_duixiang');
  final _yearKey = AgentElementRegistry.register('select_jiaofei_niandu');
  final _amountKey = AgentElementRegistry.register('input_jiaofei_jine');
  final _idKey = AgentElementRegistry.register('input_id_card');
  final _submitKey = AgentElementRegistry.register('btn_go_payment');

  static const _persons = ['本人', '配偶', '子女'];
  static const _years = ['2024年度', '2025年度', '2026年度'];

  bool get _canSubmit =>
      _targetPerson != null &&
      _year != null &&
      _amountController.text.isNotEmpty &&
      _idController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    AgentElementRegistry.registerController('input_jiaofei_jine', _amountController);
    AgentElementRegistry.registerController('input_id_card', _idController);
    _amountController.addListener(() => setState(() {}));
    _idController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _autoSave();
    AgentElementRegistry.unregister('input_jiaofei_jine');
    AgentElementRegistry.unregister('input_id_card');
    _amountController.dispose();
    _idController.dispose();
    super.dispose();
  }

  void _autoSave() {
    final fields = {
      'target_person': _targetPerson,
      'year': _year,
      'amount': _amountController.text,
    };
    final hasContent = fields.values.any((v) => v != null && v.toString().isNotEmpty);
    if (!hasContent) return;
    DraftService.autoSave(
      'yibao_jiaofei',
      '医保缴费',
      fields,
      _idController.text.isNotEmpty,
    );
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
            onPressed: _canSubmit ? () {} : null,
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
