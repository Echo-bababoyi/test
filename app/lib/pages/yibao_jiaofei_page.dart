import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/agent_element_registry.dart';
import '../services/draft_service.dart';
import '../services/draft_store.dart';
import '../widgets/agent_dock.dart';

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

class _YibaoJiaofeiPageState extends State<YibaoJiaofeiPage> with WidgetsBindingObserver {
  static const _route = AppRoutes.yibaoJiaofei;
  static const _pageId = 'yibao_jiaofei';
  static const _pageTitle = '医保缴费';
  Timer? _saveTimer;
  String? _xianzhong;
  String? _year;
  _JiaofeiDangci? _dangci;
  final _idController = TextEditingController();
  final _idFocus = FocusNode();

  bool _idFocused = false;

  final _xianzhongKey = AgentElementRegistry.register(_route, 'select_jiaofei_xianzhong');
  final _yearKey = AgentElementRegistry.register(_route, 'select_jiaofei_niandu');
  final _dangciKey = AgentElementRegistry.register(_route, 'select_jiaofei_dangci');
  final _idKey = AgentElementRegistry.register(_route, 'input_id_card');
  final _submitKey = AgentElementRegistry.register(_route, 'btn_go_payment');

  static const _xianzhongs = ['城乡居民医保', '灵活就业人员医保'];
  static const _years = ['2024年度', '2025年度', '2026年度'];

  static final Map<String, List<_JiaofeiDangci>> _dangciOptions = {
    '城乡居民医保': const [
      _JiaofeiDangci('第一档', 380.00),
      _JiaofeiDangci('第二档', 660.00),
      _JiaofeiDangci('第三档', 980.00),
    ],
    '灵活就业人员医保': const [
      _JiaofeiDangci('月缴标准', 450.00),
    ],
  };

  static const _xianzhongHints = {
    '城乡居民医保': '按年缴费，截止日期每年 12 月 31 日',
    '灵活就业人员医保': '按月缴费，次月生效',
  };

  bool get _canSubmit {
    if (_xianzhong == null || _year == null || _dangci == null) return false;
    if (_idController.text.length != 18) return false;
    return true;
  }

  bool get _idInvalid =>
      _idController.text.isNotEmpty && _idController.text.length != 18;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    DraftService.clearCompleted(_pageId);
    AgentElementRegistry.registerController(_route, 'input_id_card', _idController);
    AgentElementRegistry.registerApplier(_route, 'select_jiaofei_xianzhong', (v) {
      final m = _xianzhongs.firstWhere((x) => v.contains(x) || x.contains(v), orElse: () => '');
      if (m.isNotEmpty) _onXianzhongChanged(m);
    });
    AgentElementRegistry.registerApplier(_route, 'select_jiaofei_niandu', (v) {
      final m = _years.firstWhere((y) => y.contains(v) || v.contains(y.replaceAll('年度', '')), orElse: () => '');
      if (m.isNotEmpty) { setState(() => _year = m); _scheduleAutoSave(); }
    });
    AgentElementRegistry.registerApplier(_route, 'select_jiaofei_dangci', (v) {
      final opts = _xianzhong == null ? const <_JiaofeiDangci>[] : (_dangciOptions[_xianzhong] ?? const <_JiaofeiDangci>[]);
      final hit = opts.where((d) => v.contains(d.label) || d.label.contains(v));
      if (hit.isNotEmpty) { setState(() => _dangci = hit.first); _scheduleAutoSave(); }
    });
    _idController.addListener(() {
      setState(() {});
      _scheduleAutoSave();
    });
    _idFocus.addListener(() => setState(() => _idFocused = _idFocus.hasFocus));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (GoRouterState.of(context).uri.queryParameters['restore'] == '1') {
        _restoreDraft();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.hidden) {
      _saveTimer?.cancel();
      if (!DraftService.isCompleted(_pageId)) _flushAutoSave();
    }
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    if (!DraftService.isCompleted(_pageId)) _flushAutoSave();
    WidgetsBinding.instance.removeObserver(this);
    AgentElementRegistry.unregister(_route, 'input_id_card');
    AgentElementRegistry.unregisterPage(_route);
    _idController.dispose();
    _idFocus.dispose();
    super.dispose();
  }

  Future<void> _restoreDraft() async {
    final draft = await DraftStore.getDraft(_pageId);
    if (!mounted || draft == null) return;
    final fields = (draft['fields'] as Map?)?.cast<String, dynamic>() ?? {};
    final sensitive = draft['sensitive_filled'] as bool? ?? false;
    setState(() {
      _xianzhong = fields['xianzhong'] as String?;
      _year = fields['year'] as String?;
      final dangciLabel = fields['dangci'] as String?;
      if (_xianzhong != null && dangciLabel != null) {
        final opts = _dangciOptions[_xianzhong];
        if (opts != null) {
          for (final d in opts) {
            if (d.label == dangciLabel) { _dangci = d; break; }
          }
        }
      }
    });
    if (sensitive && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('为安全起见，身份证号需要您重新输入',
              style: TextStyle(fontSize: 18)),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  void _scheduleAutoSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 500), _flushAutoSave);
  }

  void _flushAutoSave() {
    final fields = <String, dynamic>{
      'xianzhong': _xianzhong,
      'year': _year,
      'dangci': _dangci?.label,
    };
    fields.removeWhere((k, v) => v == null || v.toString().isEmpty);
    if (fields.isEmpty) return;
    DraftService.autoSave(
      _pageId,
      _pageTitle,
      fields,
      _idController.text.isNotEmpty,
    );
  }

  void _onXianzhongChanged(String? v) {
    setState(() {
      _xianzhong = v;
      _dangci = null;
    });
    _scheduleAutoSave();
  }

  String _maskId(String id) =>
      id.length == 18 ? '${id.substring(0, 3)}****${id.substring(14)}' : id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: AppBar(
        backgroundColor: _kOrange,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('医保缴费', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          ListView(
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
                    _FieldLabel('险种'),
                    DropdownButtonFormField<String>(
                      key: _xianzhongKey,
                      initialValue: _xianzhong,
                      hint: const Text('请选择险种', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                      items: _xianzhongs.map((x) => DropdownMenuItem(
                        value: x,
                        child: Text(x, style: const TextStyle(fontSize: 18)),
                      )).toList(),
                      onChanged: _onXianzhongChanged,
                      decoration: _inputDecoration(),
                      style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                    ),
                    if (_xianzhong != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(_xianzhongHints[_xianzhong] ?? '',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF999999))),
                      ),
                    const SizedBox(height: 20),

                    _FieldLabel('缴费年度'),
                    DropdownButtonFormField<String>(
                      key: _yearKey,
                      initialValue: _year,
                      hint: const Text('请选择缴费年度', style: TextStyle(fontSize: 18, color: Color(0xFF999999))),
                      items: _years.map((y) => DropdownMenuItem(
                        value: y,
                        child: Text(y, style: const TextStyle(fontSize: 18)),
                      )).toList(),
                      onChanged: (v) {
                        setState(() => _year = v);
                        _scheduleAutoSave();
                      },
                      decoration: _inputDecoration(),
                      style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 20),

                    _FieldLabel('缴费档次'),
                    DropdownButtonFormField<_JiaofeiDangci>(
                      key: _dangciKey,
                      initialValue: _dangci,
                      hint: Text(
                        _xianzhong == null ? '请先选择险种' : '请选择缴费档次',
                        style: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
                      ),
                      items: (_xianzhong == null
                              ? <_JiaofeiDangci>[]
                              : _dangciOptions[_xianzhong]!)
                          .map((d) => DropdownMenuItem(
                                value: d,
                                child: Text(
                                  '${d.label}  ¥ ${d.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        setState(() => _dangci = v);
                        _scheduleAutoSave();
                      },
                      decoration: _inputDecoration(),
                      style: const TextStyle(fontSize: 18, color: Color(0xFF333333)),
                    ),
                    const SizedBox(height: 20),

                    _FieldLabel('缴费金额'),
                    Container(
                      height: 56,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFAFAFA),
                        border: Border.all(color: const Color(0xFFE5E5E5)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _dangci == null ? '请先选择档次' : '¥ ${_dangci!.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: _dangci == null ? FontWeight.normal : FontWeight.w600,
                          color: _dangci == null ? const Color(0xFF999999) : _kOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    _FieldLabel('身份证号'),
                    _MaskedIdField(
                      fieldKey: _idKey,
                      controller: _idController,
                      focusNode: _idFocus,
                      focused: _idFocused,
                      invalid: _idInvalid,
                      decoration: _inputDecoration(),
                      maskFn: _maskId,
                    ),
                    if (_idInvalid)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text('请输入18位身份证号',
                            style: TextStyle(fontSize: 15, color: Color(0xFFFF3B30))),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  key: _submitKey,
                  onPressed: _canSubmit
                      ? () => context.push(
                            AppRoutes.yibaoJiaofeiConfirm,
                            extra: {
                              'xianzhong': _xianzhong,
                              'year': _year,
                              'dangci_label': _dangci!.label,
                              'amount': _dangci!.amount.toStringAsFixed(2),
                              'id_masked': _maskId(_idController.text),
                            },
                          )
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kOrange,
                    disabledBackgroundColor: const Color(0xFFE0E0E0),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: const Color(0xFF999999),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Text(
                    _canSubmit ? '去支付' : '请先填写完整信息',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      bottomNavigationBar: const AgentBottomShell(currentIndex: 0, currentPath: AppRoutes.yibaoJiaofei),
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

class _JiaofeiDangci {
  final String label;
  final double amount;
  const _JiaofeiDangci(this.label, this.amount);
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

class _MaskedIdField extends StatelessWidget {
  final Key fieldKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool invalid;
  final InputDecoration decoration;
  final String Function(String) maskFn;

  const _MaskedIdField({
    required this.fieldKey,
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.invalid,
    required this.decoration,
    required this.maskFn,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;
    final showMasked = !focused && hasValue && !invalid;

    if (showMasked) {
      return InkWell(
        onTap: () => focusNode.requestFocus(),
        child: Container(
          height: 56,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFFAFAFA),
            border: Border.all(color: const Color(0xFFE5E5E5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(maskFn(controller.text),
                    style: const TextStyle(fontSize: 18)),
              ),
              const Text('编辑',
                  style: TextStyle(fontSize: 14, color: _kOrange)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: TextField(
        key: fieldKey,
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.text,
        maxLength: 18,
        decoration: decoration.copyWith(counterText: ''),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
