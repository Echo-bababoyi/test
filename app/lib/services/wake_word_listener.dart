import 'dart:html' as html;

class WakeWordListener {
  static final WakeWordListener instance = WakeWordListener._();
  WakeWordListener._();

  html.SpeechRecognition? _recognition;
  void Function()? onWakeWord;
  bool _isListening = false;
  // Prevent re-entrant starts while the panel is open
  bool _paused = false;

  void start() {
    if (_isListening || _paused) return;
    _isListening = true;
    _recognition = html.SpeechRecognition();
    _recognition!
      ..continuous = true
      ..interimResults = true
      ..lang = 'zh-CN';

    _recognition!.onResult.listen((event) {
      final results = event.results;
      if (results == null) return;
      final startIdx = event.resultIndex ?? 0;
      for (int i = startIdx; i < results.length; i++) {
        final transcript = results[i].item(0)?.transcript ?? '';
        if (transcript.contains('小浙')) {
          pause();
          onWakeWord?.call();
          break;
        }
      }
    });

    _recognition!.onEnd.listen((_) {
      // Web Speech API stops automatically; restart unless paused/stopped
      if (_isListening && !_paused) {
        try {
          _recognition?.start();
        } catch (_) {}
      }
    });

    _recognition!.onError.listen((_) {
      // On permission denied or network error, stop silently
      _isListening = false;
    });

    try {
      _recognition!.start();
    } catch (_) {
      _isListening = false;
    }
  }

  // Pause while panel is open; resume when panel closes
  void pause() {
    _paused = true;
    _isListening = false;
    _recognition?.stop();
  }

  void resume() {
    _paused = false;
    start();
  }

  void stop() {
    _paused = false;
    _isListening = false;
    _recognition?.stop();
    _recognition = null;
  }
}
