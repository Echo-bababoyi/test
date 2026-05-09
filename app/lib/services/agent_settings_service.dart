// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AgentSettingsService {
  AgentSettingsService._();
  static final instance = AgentSettingsService._();

  static const _keyVoice = 'xiaozhe_voice_enabled';
  static const _keyRate  = 'xiaozhe_speech_rate';

  bool get voiceEnabled {
    final v = html.window.localStorage[_keyVoice];
    return v == null || v == 'true';
  }
  set voiceEnabled(bool v) => html.window.localStorage[_keyVoice] = v.toString();

  String get speedMode => html.window.localStorage[_keyRate] ?? 'slow';
  set speedMode(String m) => html.window.localStorage[_keyRate] = m;

  double get speechRate => speedMode == 'slow' ? 0.85 : 1.0;
}
