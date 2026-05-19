import 'dart:async';
// ignore: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: deprecated_member_use
import 'dart:js' as js;

class FaceFrame {
  final bool hasFace;
  final double ear;
  final double yaw;
  final double cx;
  final double cy;
  final double w;
  final double h;
  final double brightness;
  const FaceFrame({
    required this.hasFace,
    this.ear = 0,
    this.yaw = 0,
    this.cx = 0,
    this.cy = 0,
    this.w = 0,
    this.h = 0,
    this.brightness = 128,
  });
}

/// MediaPipe FaceLandmarker 的 Dart 包装。
/// 依赖 web/face_detector.js — 该脚本在 index.html head 自启动，
/// 完成时设 `window.faceDetector`，失败时设 `window.faceDetectorError`。
class FaceDetectorService {
  js.JsObject? _api;
  bool _initialized = false;
  bool _disposed = false;

  bool get isReady => _initialized;

  /// 轮询等待 `window.faceDetector` 就绪。
  /// 上层用 `.timeout(8s)` 兜底超时；`dispose()` 置 `_disposed` 后循环即退出，
  /// 避免页面销毁后 Future 仍在 spin。
  Future<void> init() async {
    if (_initialized) return;
    while (!_disposed) {
      final err = js.context['faceDetectorError'];
      if (err != null) {
        throw StateError('faceDetector init failed: $err');
      }
      final api = js.context['faceDetector'];
      if (api is js.JsObject) {
        _api = api;
        _initialized = true;
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('FaceDetectorService disposed before ready');
  }

  FaceFrame? detect(html.VideoElement video) {
    final api = _api;
    if (api == null) return null;
    final ts = DateTime.now().millisecondsSinceEpoch;
    final r = api.callMethod('detect', <dynamic>[video, ts]);
    if (r == null || r is! js.JsObject) return null;
    final hasFace = r['hasFace'] == true;
    if (!hasFace) {
      return FaceFrame(
        hasFace: false,
        brightness: _asDouble(r['brightness'], 128),
      );
    }
    return FaceFrame(
      hasFace: true,
      ear: _asDouble(r['ear'], 0),
      yaw: _asDouble(r['yaw'], 0),
      cx: _asDouble(r['cx'], 0),
      cy: _asDouble(r['cy'], 0),
      w: _asDouble(r['w'], 0),
      h: _asDouble(r['h'], 0),
      brightness: _asDouble(r['brightness'], 128),
    );
  }

  double _asDouble(dynamic v, double fallback) {
    if (v is num) return v.toDouble();
    return fallback;
  }

  void dispose() {
    _disposed = true;
    final api = _api;
    if (api != null) {
      try {
        api.callMethod('dispose');
      } catch (_) {}
      _api = null;
      _initialized = false;
    }
  }
}
