import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/audio_capture.dart';

typedef AudioReadyCallback = void Function(Uint8List pcm);

class MicButton extends StatefulWidget {
  final AudioReadyCallback onAudioReady;
  final void Function(String reason)? onError;
  final double size;
  const MicButton({super.key, required this.onAudioReady, this.onError, this.size = 100});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  bool _pressing = false;

  AudioCapture? _capture;
  Timer? _maxTimer;

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
    _maxTimer?.cancel();
    _pulseController.dispose();
    _capture?.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      _capture = AudioCapture();
      await _capture!.start();
    } catch (e) {
      debugPrint('[MicButton] start error: $e');
      if (mounted) {
        setState(() => _pressing = false);
        _pulseController.stop();
      }
      final reason = e.toString().contains('NotAllowed')
          ? '麦克风权限被拒，请在浏览器地址栏开启'
          : '录音启动失败：$e';
      widget.onError?.call(reason);
    }
  }

  Future<void> _stopRecording() async {
    if (_capture == null) return;
    try {
      final pcm = await _capture!.stop();
      _capture = null;
      widget.onAudioReady(pcm);
    } catch (e) {
      debugPrint('[MicButton] stop error: $e');
      _capture = null;
    }
  }

  void _onPressStart() {
    setState(() => _pressing = true);
    _pulseController.forward(from: 0);
    _startRecording();
    _maxTimer = Timer(const Duration(seconds: 30), () {
      if (!mounted) return;
      setState(() => _pressing = false);
      _pulseController.stop();
      _stopRecording();
    });
  }

  void _onPressEnd() {
    _maxTimer?.cancel();
    _maxTimer = null;
    setState(() => _pressing = false);
    _pulseController.stop();
    _stopRecording();
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.size;
    final circleSize = s * 0.72;
    final iconSize = s * 0.36;
    return Listener(
      onPointerDown: (_) => _onPressStart(),
      onPointerUp: (_) => _onPressEnd(),
      onPointerCancel: (_) => _onPressEnd(),
      child: SizedBox(
        width: s,
        height: s,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (_pressing)
              AnimatedBuilder(
                animation: _pulseController,
                builder: (_, __) => Opacity(
                  opacity: _opacityAnim.value,
                  child: Container(
                    width: circleSize * _scaleAnim.value,
                    height: circleSize * _scaleAnim.value,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6D00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            Container(
              width: circleSize,
              height: circleSize,
              decoration: const BoxDecoration(
                color: Color(0xFFFF6D00),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _pressing ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: iconSize,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
