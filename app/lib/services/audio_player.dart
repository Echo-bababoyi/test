import 'dart:async';
import 'dart:collection';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AudioPlayer {
  static html.AudioElement? _current;
  static final Queue<String> _queue = Queue();
  static bool _isPlaying = false;

  static void playBase64(String? base64Audio) {
    if (base64Audio == null || base64Audio.isEmpty) return;
    _queue.add(base64Audio);
    _playNext();
  }

  static void _playNext() {
    if (_isPlaying || _queue.isEmpty) return;
    _isPlaying = true;
    final b64 = _queue.removeFirst();
    print('[AudioPlayer] _playNext: queue=${_queue.length + 1}, b64=${b64.length} chars');
    final bytes = base64Decode(b64);
    final blob = html.Blob([bytes], 'audio/mp3');
    final url = html.Url.createObjectUrlFromBlob(blob);
    _current = html.AudioElement(url);
    _current!.onEnded.listen((_) {
      print('[AudioPlayer] play ended');
      _isPlaying = false;
      _playNext();
    });
    _current!.onError.listen((e) {
      print('[AudioPlayer] play error: $e');
      _isPlaying = false;
      _playNext();
    });
    _current!.play().catchError((e) {
      print('[AudioPlayer] play() promise rejected: $e');
      _isPlaying = false;
      _playNext();
    });
  }

  static Future<void> playBase64AndWait(String? base64Audio) async {
    if (base64Audio == null || base64Audio.isEmpty) return;
    stop();
    final bytes = base64Decode(base64Audio);
    final blob = html.Blob([bytes], 'audio/mp3');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final audio = html.AudioElement(url);
    _current = audio;
    final completer = Completer<void>();
    audio.onEnded.listen((_) { if (!completer.isCompleted) completer.complete(); });
    audio.onError.listen((_) { if (!completer.isCompleted) completer.complete(); });
    Future.delayed(const Duration(seconds: 30), () {
      if (!completer.isCompleted) completer.complete();
    });
    audio.play();
    return completer.future;
  }

  static void stop() {
    _queue.clear();
    _current?.pause();
    _current = null;
    _isPlaying = false;
  }
}
