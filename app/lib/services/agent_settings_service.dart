// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AgentSettingsService {
  AgentSettingsService._();
  static final instance = AgentSettingsService._();

  static const _keyVoice = 'xiaozhe_voice_enabled';
  static const _keyRate  = 'xiaozhe_speech_rate';
  static const _keyTrust = 'xiaozhe_trust_level';
  static const _keyFirstChoice = 'xiaozhe_first_choice_shown';

  bool get voiceEnabled {
    final v = html.window.localStorage[_keyVoice];
    return v == null || v == 'true';
  }
  set voiceEnabled(bool v) => html.window.localStorage[_keyVoice] = v.toString();

  String get speedMode => html.window.localStorage[_keyRate] ?? 'slow';
  set speedMode(String m) => html.window.localStorage[_keyRate] = m;

  double get speechRate => speedMode == 'slow' ? 0.85 : 1.0;

  String get trustLevel => html.window.localStorage[_keyTrust] ?? 'guide';
  set trustLevel(String v) => html.window.localStorage[_keyTrust] = v;

  bool get firstChoiceShown => html.window.localStorage[_keyFirstChoice] == 'true';
  set firstChoiceShown(bool v) => html.window.localStorage[_keyFirstChoice] = v.toString();
}
