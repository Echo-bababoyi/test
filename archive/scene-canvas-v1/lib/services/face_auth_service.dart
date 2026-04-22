import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 扩展点 2：刷脸认证服务
/// Phase 0：mock 延迟后返回 success
/// 后续：接 ML Kit 活体检测 / 代理跳过 / 浏览器摄像头 API
enum FaceAuthResult { success, failed, cancelled }

abstract class FaceAuthService {
  Future<FaceAuthResult> authenticate();
}

class MockFaceAuthService implements FaceAuthService {
  @override
  Future<FaceAuthResult> authenticate() async {
    await Future.delayed(const Duration(seconds: 2));
    return FaceAuthResult.success;
  }
}

final faceAuthServiceProvider =
    Provider<FaceAuthService>((ref) => MockFaceAuthService());
