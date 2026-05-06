import 'package:flutter/material.dart';
import '../services/agent_element_registry.dart';
import '../services/draft_service.dart';
import '../widgets/elder_bottom_nav.dart';

const _kOrange = Color(0xFFFF6D00);
const _kBg = Color(0xFFF5F5F5);
const _kSurface = Colors.white;
const _kShadow = BoxShadow(
  color: Color(0x0D000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

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
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('医保缴费', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _kSurface,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [_kShadow],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('缴费对象'),
                DropdownButtonFormField<String>(
                  key: _targetKey,
                  value: _targetPerson,
                  items: _persons.map((p) => DropdownMenuItem(
                    value: p,
                    child: Text(p, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: (v) => setState(() => _targetPerson = v),
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 20),
                _FieldLabel('缴费年度'),
                DropdownButtonFormField<String>(
                  key: _yearKey,
                  value: _year,
                  items: _years.map((y) => DropdownMenuItem(
                    value: y,
                    child: Text(y, style: const TextStyle(fontSize: 18)),
                  )).toList(),
                  onChanged: (v) => setState(() => _year = v),
                  decoration: _inputDecoration(),
                  style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                ),
                const SizedBox(height: 20),
                _FieldLabel('缴费金额'),
                SizedBox(
                  height: 56,
                  child: TextField(
                    key: _amountKey,
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(suffixText: '元'),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
                const SizedBox(height: 20),
                _FieldLabel('身份证号'),
                SizedBox(
                  height: 56,
                  child: TextField(
                    key: _idKey,
                    controller: _idController,
                    decoration: _inputDecoration(),
                    style: const TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              key: _submitKey,
              onPressed: _canSubmit ? () {} : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kOrange,
                disabledBackgroundColor: const Color(0xFFFFB07A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text('去支付', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }

  InputDecoration _inputDecoration({String? suffixText}) {
    return InputDecoration(
      suffixText: suffixText,
      suffixStyle: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E5E5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: _kOrange, width: 1.5),
      ),
      filled: true,
      fillColor: const Color(0xFFFAFAFA),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(fontSize: 18, color: Color(0xFF999999), fontWeight: FontWeight.w500)),
    );
  }
}
