import 'package:flutter/material.dart';

class PressScaleWrapper extends StatefulWidget {
  final Widget Function(bool pressed) builder;
  final double pressedScale;
  final double pressedOpacity;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;
  final Color? splashColor;
  final Color? highlightColor;

  const PressScaleWrapper({
    super.key,
    required this.builder,
    this.pressedScale = 0.95,
    this.pressedOpacity = 1.0,
    this.onTap,
    this.borderRadius,
    this.customBorder,
    this.splashColor,
    this.highlightColor,
  });

  @override
  State<PressScaleWrapper> createState() => _PressScaleWrapperState();
}

class _PressScaleWrapperState extends State<PressScaleWrapper> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _pressed ? widget.pressedOpacity : 1.0,
          duration: const Duration(milliseconds: 100),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: widget.borderRadius,
            customBorder: widget.customBorder,
            splashColor: widget.splashColor,
            highlightColor: widget.highlightColor,
            child: widget.builder(_pressed),
          ),
        ),
      ),
    );
  }
}
