import 'dart:async';
import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AudioPlayer {
  static html.AudioElement? _current;

  static void playBase64(String? base64Audio) {
    if (base64Audio == null || base64Audio.isEmpty) return;
    stop();
    final bytes = base64Decode(base64Audio);
    final blob = html.Blob([bytes], 'audio/mp3');
    final url = html.Url.createObjectUrlFromBlob(blob);
    _current = html.AudioElement(url);
    _current!.play();
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
    _current?.pause();
    _current = null;
  }
}
