import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 扩展点 1：语音输入服务
/// Phase 0：mock 返回固定文字
/// 后续：接 Web Speech API / 真 STT / 方言识别
abstract class VoiceInputService {
  Future<String> listen();
}

class MockVoiceInputService implements VoiceInputService {
  @override
  Future<String> listen() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return '医保缴费';
  }
}

final voiceInputServiceProvider =
    Provider<VoiceInputService>((ref) => MockVoiceInputService());
