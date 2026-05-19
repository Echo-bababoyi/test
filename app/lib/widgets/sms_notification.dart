import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

/// 模拟手机系统短信通知横幅（VerifyPage 用）。
/// 由父组件控 visible；本组件只管动画 + UI + 回调。
class SmsNotification extends StatelessWidget {
  final bool visible;
  final String code;
  final VoidCallback onRead;
  final VoidCallback onCopy;

  const SmsNotification({
    super.key,
    required this.visible,
    required this.code,
    required this.onRead,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !visible,
      child: AnimatedSlide(
        offset: visible ? Offset.zero : const Offset(0, -1.6),
        duration: Duration(milliseconds: visible ? 300 : 240),
        curve: visible ? Curves.easeOutCubic : Curves.easeInCubic,
        child: AnimatedOpacity(
          opacity: visible ? 1 : 0,
          duration: Duration(milliseconds: visible ? 300 : 240),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(Spacing.sm),
              child: _Card(
                code: code,
                onRead: onRead,
                onCopy: onCopy,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final String code;
  final VoidCallback onRead;
  final VoidCallback onCopy;

  const _Card({
    required this.code,
    required this.onRead,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xF2FFFFFF),
        borderRadius: BorderRadius.circular(AppRadius.xlarge),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 24,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.elderPrimary,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(Icons.chat_bubble, color: Colors.white, size: 14),
              ),
              const SizedBox(width: Spacing.sm),
              const Text(
                '短信',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF333333),
                ),
              ),
              const Spacer(),
              const Text(
                '刚刚',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: AppFontSize.bodyLarge,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              children: [
                const TextSpan(text: '【浙里办】您的验证码是 '),
                TextSpan(
                  text: code,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '，5 分钟内有效，请勿泄露。'),
              ],
            ),
          ),
          const SizedBox(height: Spacing.md),
          const Divider(height: 1, color: AppColors.divider),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onRead,
                  child: const SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        '已读',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(width: 1, height: 24, color: AppColors.divider),
              Expanded(
                child: InkWell(
                  onTap: onCopy,
                  child: const SizedBox(
                    height: 44,
                    child: Center(
                      child: Text(
                        '复制',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.elderPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
