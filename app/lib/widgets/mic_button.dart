import 'dart:async';
import 'dart:html' as html;
import 'package:flutter/material.dart';

typedef AudioReadyCallback = void Function(List<String> base64Chunks);

class MicButton extends StatefulWidget {
  final AudioReadyCallback onAudioReady;
  const MicButton({super.key, required this.onAudioReady});

  @override
  State<MicButton> createState() => _MicButtonState();
}

class _MicButtonState extends State<MicButton> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;
  bool _pressing = false;

  html.MediaRecorder? _recorder;
  final List<html.Blob> _chunks = [];

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
    _recorder?.stop();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({'audio': true});
      _chunks.clear();
      _recorder = html.MediaRecorder(stream);
      _recorder!.addEventListener('dataavailable', (event) {
        final blob = (event as html.BlobEvent).data;
        if (blob != null && blob.size > 0) _chunks.add(blob);
      });
      _recorder!.start(200); // 每 200ms 一个 chunk
    } catch (e) {
      debugPrint('[MicButton] getUserMedia error: $e');
    }
  }

  Future<void> _stopRecording() async {
    if (_recorder == null) return;
    final completer = Completer<void>();
    _recorder!.addEventListener('stop', (_) => completer.complete());
    _recorder!.stop();
    await completer.future;

    // 把所有 blob 转为 base64
    final base64Chunks = <String>[];
    for (final blob in _chunks) {
      final reader = html.FileReader();
      final c = Completer<String>();
      reader.onLoadEnd.listen((_) {
        final result = reader.result as String;
        // result 是 "data:audio/webm;base64,XXXX"
        final b64 = result.split(',').last;
        c.complete(b64);
      });
      reader.readAsDataUrl(blob);
      base64Chunks.add(await c.future);
    }

    _recorder = null;
    _chunks.clear();
    if (base64Chunks.isNotEmpty) {
      widget.onAudioReady(base64Chunks);
    }
  }

  void _onPressStart(LongPressStartDetails _) {
    setState(() => _pressing = true);
    _pulseController.forward(from: 0);
    _startRecording();
  }

  void _onPressEnd(LongPressEndDetails _) {
    setState(() => _pressing = false);
    _pulseController.stop();
    _stopRecording();
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
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF6D00),
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
