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

  static void stop() {
    _current?.pause();
    _current = null;
  }
}
