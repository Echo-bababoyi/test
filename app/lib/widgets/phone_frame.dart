import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class PhoneFrame extends StatelessWidget {
  final Widget child;
  const PhoneFrame({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.phoneBg,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: DesignSize.width,
            height: DesignSize.height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.phone),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
