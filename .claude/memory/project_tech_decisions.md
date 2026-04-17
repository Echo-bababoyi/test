---
name: 项目技术决策
description: 毕设浙里办复刻项目的核心技术选型与平台决策（Flutter Web / Riverpod / go_router / 自绘系统弹窗）
type: project
---

## 技术栈

- **框架**：Flutter（稳定版）+ Dart
- **状态管理**：Riverpod
- **路由**：go_router
- **目标平台**：**Flutter Web（Chrome）只**——不出 Android/iOS 安装包，不装模拟器

**Why:** 毕设交付物是浏览器可运行 demo 而非应用市场上架。用户明确"只要浏览器网页端测试通过就可以"，并且开发机是 KVM 虚拟机（嵌套虚拟化跑 AVD 性能差）。
**How to apply:** 所有页面/组件优先保证 Web 下行为正确；不引入只在 mobile 平台可用的包（如 `camera`、`permission_handler` 的 mobile-only API）。若后期需引入，先评估是否有 Web 兼容的替代方案。

## 系统弹窗在 Web 上的还原策略

原版"手机系统弹窗"（摄像头/麦克风权限）在 Web 上不能直接用浏览器自带权限提示——浏览器权限 UI 与 Android 原生样式完全不同，破坏还原度。

**决策：自绘组件模拟 Android 系统弹窗外观**，不调用真 `navigator.mediaDevices.getUserMedia()`。

**Why:** 本阶段目标是视觉与交互还原，不是真实权限请求。后续多模态能力接入时再决定是否在"自绘弹窗确认后"追加真权限请求。
**How to apply:** `SystemDialog` 组件族自行绘制 Android 原生对话框外观（圆角、阴影、按钮样式）；不要引入 `permission_handler` 等包。

## 设计基准分辨率

**基准：405 × 880 dp**（逻辑像素）。

- 32 张截图统一为 **1216 × 2640** 物理像素
- 按 DPR = 3 反推：1216/3 = 405.33，2640/3 = 880
- 纵横比 ≈ 19.5:9，典型中高端国产 Android 形态
- **实践意义：** 从截图量任何尺寸除以 3 直接得到 Flutter dp 值（按钮宽 180px → `width: 60`）
- **Web 渲染：** 根组件用固定 `SizedBox(width: 405, height: 880)` 手机画框居中，窗口缩放靠 `FittedBox` 或 `Transform.scale` 等比缩

## Flutter SDK 项目级安装（已完成）

**位置：** `tools/flutter/`（Flutter 3.41.7 stable + Dart 3.11.5），通过 `./bin/flutter` / `./bin/dart` 调用。

**镜像环境：** 包装脚本自动设置 `PUB_HOSTED_URL=https://pub.flutter-io.cn` 与 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`（flutter-io.cn 是唯一稳定可用的镜像；TUNA/SJTUG/USTC/阿里云全部 404，华为云有但限速极严）。

**Why:** 项目级隔离，不污染 `~/.bashrc`，迁移/删除都干净；毕设结束后 `rm -rf tools/ bin/ .dart_tool/` 一把清零。
**How to apply:** 任何调 flutter/dart 的脚本或文档都写 `./bin/flutter xxx`，不要假设系统 PATH 里有 flutter。`flutter doctor` 会报 "binary not on PATH" 警告，这是预期的。
