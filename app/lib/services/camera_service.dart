import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: undefined_prefixed_name
import 'dart:ui_web' as ui_web;

/// 摄像头会话：getUserMedia → VideoElement → 注册 platformView。
/// 调用 `start()` 后通过 `viewType` 在 HtmlElementView 中渲染预览，
/// 通过 `videoElement` 供 FaceDetectorService 抽帧。
class CameraService {
  html.VideoElement? _video;
  html.MediaStream? _stream;
  String? _viewType;

  String? get viewType => _viewType;
  html.VideoElement? get videoElement => _video;
  bool get isReady => _video != null && _stream != null;

  Future<void> start() async {
    final devices = html.window.navigator.mediaDevices;
    if (devices == null) {
      throw StateError('mediaDevices not available');
    }
    final stream = await devices.getUserMedia(<String, dynamic>{
      'video': <String, dynamic>{
        'facingMode': 'user',
        'width': <String, int>{'ideal': 640},
        'height': <String, int>{'ideal': 480},
      },
      'audio': false,
    });
    _stream = stream;

    final video = html.VideoElement()
      ..autoplay = true
      ..muted = true
      ..setAttribute('playsinline', 'true')
      ..srcObject = stream
      ..style.objectFit = 'cover'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.transform = 'scaleX(-1)';
    _video = video;

    final viewType =
        'face_auth_camera_${DateTime.now().microsecondsSinceEpoch}';
    _viewType = viewType;
    // ignore: undefined_prefixed_name
    ui_web.platformViewRegistry
        .registerViewFactory(viewType, (int _) => video);

    await video.onLoadedMetadata.first;
    try {
      await video.play();
    } catch (_) {
      // autoplay 被阻止时，muted+playsinline 通常仍可放，吞错让上层进检测
    }
  }

  void dispose() {
    final stream = _stream;
    if (stream != null) {
      for (final t in stream.getTracks()) {
        t.stop();
      }
    }
    _stream = null;
    _video?.srcObject = null;
    _video = null;
    _viewType = null;
  }
}
