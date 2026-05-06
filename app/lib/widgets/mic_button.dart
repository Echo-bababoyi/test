import 'package:flutter/material.dart';

class MicButton extends StatefulWidget {
  final VoidCallback onAudioEnd;
  const MicButton({super.key, required this.onAudioEnd});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  bool _pressing = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300))
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed && _pressing) _pulseController.forward(from: 0);
      });
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.5, end: 0.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _onPressStart(LongPressStartDetails _) {
    setState(() => _pressing = true);
    _pulseController.forward(from: 0);
  }

  void _onPressEnd(LongPressEndDetails _) {
    setState(() => _pressing = false);
    _pulseController.stop();
    widget.onAudioEnd();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: _onPressStart,
      onLongPressEnd: _onPressEnd,
      child: SizedBox(
        width: 100,
        height: 100,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_pressing)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: 72 * _scaleAnim.value,
                    height: 72 * _scaleAnim.value,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6D00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6D00),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _pressing ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 36,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
