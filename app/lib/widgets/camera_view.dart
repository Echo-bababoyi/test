import 'package:flutter/material.dart';

/// 摄像头预览：直接套 HtmlElementView。viewType 由 CameraService.start() 注册。
class CameraView extends StatelessWidget {
  final String viewType;
  const CameraView({super.key, required this.viewType});

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: viewType);
  }
}
