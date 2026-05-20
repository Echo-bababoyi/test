import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';
import '../widgets/elder_bottom_nav.dart';

class PayConfirmPage extends StatefulWidget {
  const PayConfirmPage({super.key});

  @override
  State<PayConfirmPage> createState() => _PayConfirmPageState();
}

class _PayConfirmPageState extends State<PayConfirmPage> {
  final _cardController = TextEditingController();
  final _cardFocus = FocusNode();
  bool _cardFocused = false;

  final _idController = TextEditingController();
  final _idFocus = FocusNode();
  bool _idFocused = false;

  bool get _cardValid {
    final digits = _cardController.text.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 16 && digits.length <= 19;
  }

  bool get _idValid =>
      RegExp(r'^\d{17}[\dXx]$').hasMatch(_idController.text);
  bool get _idInvalid =>
      _idController.text.isNotEmpty && !_idValid;
  bool get _canPay => _cardValid && _idValid;

  String _maskId(String id) =>
      id.length == 18 ? '${id.substring(0, 3)}****${id.substring(14)}' : id;

  @override
  void initState() {
    super.initState();
    _cardController.addListener(() => setState(() {}));
    _cardFocus.addListener(() => setState(() => _cardFocused = _cardFocus.hasFocus));
    _idController.addListener(() => setState(() {}));
    _idFocus.addListener(() => setState(() => _idFocused = _idFocus.hasFocus));
  }

  @override
  void dispose() {
    _cardController.dispose();
    _cardFocus.dispose();
    _idController.dispose();
    _idFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inExtra =
        GoRouterState.of(context).extra as Map<String, dynamic>? ?? {};
    final xianzhong = inExtra['xianzhong'] as String? ?? '城乡居民医保';
    final year = inExtra['year'] as String? ?? '2026年度';
    final target = inExtra['target'] as String? ?? '本人';
    final amount = inExtra['amount'] as String? ?? '380.00';
    final idMasked = inExtra['id_masked'] as String? ?? '330****2518';
    final dailiName = inExtra['daili_name'] as String?;
    final dailiIdMasked = inExtra['daili_id_masked'] as String?;
    final isDaili = dailiName != null && dailiName.isNotEmpty;
    final cardDigits = _cardController.text.replaceAll(RegExp(r'\D'), '');
    final bankTail = cardDigits.length >= 4 ? cardDigits.substring(cardDigits.length - 4) : '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('确认缴费',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      // 注意：本页不放 AgentFab（支付确认环节，代理不干预）
      body: ListView(
        padding: const EdgeInsets.all(Spacing.md),
        children: [
          _SectionCard(
            title: '缴费摘要',
            rows: [
              ('险种', xianzhong),
              ('缴费年度', year),
              ('缴费对象', target),
            ],
            highlight: ('缴费金额', '¥ $amount'),
          ),
          const SizedBox(height: Spacing.md),
          _SectionCard(
            title: isDaili ? '被缴费人信息' : '缴费人信息',
            rows: isDaili
                ? [
                    ('姓名', dailiName),
                    ('证件号', dailiIdMasked ?? ''),
                  ]
                : [
                    ('姓名', '*小明'),
                    ('证件号', idMasked),
                  ],
          ),
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: 4),
                  child: Text('支付人身份证',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                const Padding(
                  padding: EdgeInsets.only(bottom: Spacing.sm),
                  child: Text('为保障资金安全，请输入支付人身份证',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ),
                _MaskedIdField(
                  controller: _idController,
                  focusNode: _idFocus,
                  focused: _idFocused,
                  invalid: _idInvalid,
                  maskFn: _maskId,
                ),
                if (_idInvalid)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('请输入18位身份证号',
                        style: TextStyle(fontSize: 14, color: Color(0xFFFF3B30))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.large),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(bottom: Spacing.sm),
                  child: Text('银行卡号',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                _MaskedCardField(
                  controller: _cardController,
                  focusNode: _cardFocus,
                  focused: _cardFocused,
                  valid: _cardValid,
                ),
                if (_cardController.text.isNotEmpty && !_cardValid)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('请输入 16-19 位银行卡号',
                        style: TextStyle(fontSize: 14, color: Color(0xFFFF3B30))),
                  ),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.sm),
            child: Text('ⓘ 缴费完成后不支持退款，请确认信息无误',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
          ),
          const SizedBox(height: Spacing.md),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _canPay
                  ? () => context.push(
                        AppRoutes.yibaoJiaofeiPay,
                        extra: {
                          ...inExtra,
                          'bank_name': '银行卡',
                          'bank_tail': bankTail,
                        },
                      )
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.elderPrimary,
                disabledBackgroundColor: const Color(0xFFE0E0E0),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF999999),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text('确认支付 ¥$amount',
                  style:
                      const TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
    );
  }
}

class _MaskedIdField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool invalid;
  final String Function(String) maskFn;

  const _MaskedIdField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.invalid,
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
                  style: TextStyle(fontSize: 14, color: Color(0xFFFF6D00))),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.text,
        maxLength: 18,
        decoration: InputDecoration(
          counterText: '',
          hintText: '请输入身份证号',
          hintStyle: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
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
            borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class _MaskedCardField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool focused;
  final bool valid;

  const _MaskedCardField({
    required this.controller,
    required this.focusNode,
    required this.focused,
    required this.valid,
  });

  String _mask(String text) {
    final digits = text.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return '**** **** **** ????';
    final tail = digits.substring(digits.length - 4);
    return '**** **** **** $tail';
  }

  @override
  Widget build(BuildContext context) {
    final hasValue = controller.text.isNotEmpty;
    final showMasked = !focused && hasValue && valid;

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
                child: Text(_mask(controller.text),
                    style: const TextStyle(fontSize: 18)),
              ),
              const Text('编辑',
                  style: TextStyle(fontSize: 14, color: Color(0xFFFF6D00))),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: 56,
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: TextInputType.number,
        maxLength: 19,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          counterText: '',
          hintText: '请输入银行卡号',
          hintStyle: const TextStyle(fontSize: 18, color: Color(0xFF999999)),
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
            borderSide: const BorderSide(color: Color(0xFFFF6D00), width: 1.5),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
        ),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<(String, String)> rows;
  final (String, String)? highlight;
  const _SectionCard({required this.title, required this.rows, this.highlight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.large),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.sm),
            child: Text(title,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600)),
          ),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(row.$1,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(row.$2,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textPrimary)),
                ],
              ),
            ),
          if (highlight != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(highlight!.$1,
                      style: const TextStyle(
                          fontSize: 16, color: AppColors.textSecondary)),
                  const Spacer(),
                  Text(highlight!.$2,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.elderPrimary)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
