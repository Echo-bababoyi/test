import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../theme/design_tokens.dart';

class PayPasswordPage extends StatefulWidget {
  const PayPasswordPage({super.key});

  @override
  State<PayPasswordPage> createState() => _PayPasswordPageState();
}

class _PayPasswordPageState extends State<PayPasswordPage>
    with SingleTickerProviderStateMixin {
  static const _kCorrectPwd = '123456';
  static const _kMaxAttempts = 3;

  String _input = '';
  int _remainingAttempts = _kMaxAttempts;
  String? _errorText;
  bool _locked = false;
  Map<String, dynamic>? _incomingExtra;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(_shakeCtrl);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _incomingExtra ??= GoRouterState.of(context).extra as Map<String, dynamic>?;
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _onDigit(String d) {
    if (_locked || _input.length >= 6) return;
    setState(() {
      _input += d;
      _errorText = null;
    });
    if (_input.length == 6) {
      _onSubmit();
    }
  }

  void _onDelete() {
    if (_locked || _input.isEmpty) return;
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  void _onCancel() => context.pop();

  void _onSubmit() {
    if (_input == _kCorrectPwd) {
      context.pushReplacement(
        AppRoutes.yibaoJiaofeiResult,
        extra: {
          ...?_incomingExtra,
          'success': true,
        },
      );
      return;
    }
    setState(() {
      _remainingAttempts -= 1;
      _input = '';
      if (_remainingAttempts <= 0) {
        _locked = true;
        _errorText = '支付密码已锁定，请 24 小时后重试';
      } else {
        _errorText = '密码错误，还可尝试 $_remainingAttempts 次';
      }
    });
    _shakeCtrl.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    final extra = GoRouterState.of(context).extra as Map<String, dynamic>?;
    final bankName = extra?['bank_name'] as String? ?? '中国银行';
    final bankTail = extra?['bank_tail'] as String? ?? '5678';
    final amount = extra?['amount'] as String? ?? '0.00';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.elderPrimary,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('输入支付密码',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      // 注意：本页严禁放 AgentFab（密码安全红线）
      body: Padding(
        padding: const EdgeInsets.all(Spacing.lg),
        child: Column(
          children: [
            const SizedBox(height: Spacing.xl),
            Text('$bankName 尾号$bankTail',
                style: const TextStyle(
                    fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: Spacing.sm),
            Text('¥ $amount',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.elderPrimary)),
            const SizedBox(height: Spacing.xl),
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (ctx, child) {
                final dx = _shakeAnim.value == 0
                    ? 0.0
                    : 8 * (1 - _shakeAnim.value) *
                        (((_shakeAnim.value * 1000).toInt() % 4) < 2 ? 1 : -1);
                return Transform.translate(
                    offset: Offset(dx, 0), child: child);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, (i) {
                  final filled = i < _input.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 44,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(
                          color: filled
                              ? AppColors.elderPrimary
                              : AppColors.divider,
                          width: filled ? 1.5 : 1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: filled
                        ? const Center(
                            child: Icon(Icons.circle,
                                size: 12, color: AppColors.textPrimary))
                        : null,
                  );
                }),
              ),
            ),
            const SizedBox(height: Spacing.md),
            SizedBox(
              height: 22,
              child: _errorText != null
                  ? Text(_errorText!,
                      style: const TextStyle(
                          fontSize: 14, color: Color(0xFFFF3B30)))
                  : null,
            ),
            const SizedBox(height: Spacing.lg),
            _NumPad(
              onDigit: _onDigit,
              onDelete: _onDelete,
              onCancel: _onCancel,
              disabled: _locked,
            ),
            const Spacer(),
            TextButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('请携带身份证前往当地社保服务中心重置密码'),
                  duration: Duration(seconds: 3),
                ),
              ),
              child: const Text('忘记密码',
                  style: TextStyle(
                      fontSize: 14, color: AppColors.textSecondary)),
            ),
          ],
        ),
      ),
    );
  }
}

class _NumPad extends StatelessWidget {
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final bool disabled;
  const _NumPad({
    required this.onDigit,
    required this.onDelete,
    required this.onCancel,
    this.disabled = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cell(Widget child, {VoidCallback? onTap}) => Expanded(
          child: SizedBox(
            height: 56,
            child: InkWell(
              onTap: disabled ? null : onTap,
              child: Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Center(child: child),
              ),
            ),
          ),
        );

    Widget digit(String d) => cell(
          Text(d,
              style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
          onTap: () => onDigit(d),
        );

    return Column(
      children: [
        Row(children: [digit('1'), digit('2'), digit('3')]),
        Row(children: [digit('4'), digit('5'), digit('6')]),
        Row(children: [digit('7'), digit('8'), digit('9')]),
        Row(children: [
          cell(
            const Text('取消',
                style: TextStyle(
                    fontSize: 16, color: AppColors.textSecondary)),
            onTap: onCancel,
          ),
          digit('0'),
          cell(
            const Icon(Icons.backspace_outlined,
                color: AppColors.textPrimary, size: 22),
            onTap: onDelete,
          ),
        ]),
      ],
    );
  }
}
