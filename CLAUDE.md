# CLAUDE.md

本文件为 Claude Code (claude.ai/code) 在本仓库中工作时提供指引。

## 记忆系统路径（重要）

本项目所有记忆（user/feedback/project/reference）的**读取与写入**统一使用项目内路径：

```
/home/getui/codes/liangyc/archive/test/.claude/memory/
```

**禁止**使用 Claude Code 默认的全局路径 `/home/getui/codes/liangyc/.claude/projects/-home-getui-codes-liangyc-archive-test/memory/`。

- `MEMORY.md` 索引文件位于 `.claude/memory/MEMORY.md`
- 新增记忆时写入 `.claude/memory/<memory_name>.md` 并在同目录 `MEMORY.md` 中登记
- 读取记忆时仅从此目录加载，不要回落到默认路径

## 仓库定位

本目录处于**设计/蓝图阶段**，是一个本科毕业设计项目：对 **浙里办 APP 长辈版** 的忠实复刻（只还原，不改进）。

仓库**尚未包含任何源码**——没有包管理文件、构建工具或测试。目前的产出仅为设计参考资料（截图、流程文档、蓝图、开题报告）。当开始写代码时，建议将原型源码放入新的子目录（如 `app/`），并在本文件中补充真实的工具链说明。

## 参考资料结构

- `docs/PROJECT_PLAN.md` — 当前开发计划与需求的权威依据。包含目标、范围、架构扩展点、分阶段计划、验收清单、待拍板决策。开始任何实施前必须先读。
- `docs/TODO.md` — **本项目唯一的** todolist 活文档。新增问题/任务一律写入此文件；**不要**创建并行的第二个待办文件。状态：🔲 待做 / 🧪 待验证 / ✅ 已完成。
- `docs/复刻浙里办/浙里办页面逻辑.txt` — 每一个页面跳转与弹窗的叙述性流程说明，含验证码登录的备选分支。页面跳转顺序存在歧义时以此为准。
- `docs/复刻浙里办/截图/` — 32 张权威截图。文件名与流程文档中的页面名称一一对应；还原 UI 时，截图优先于任何文字描述。
- `docs/team-personas/` — 5 份 CC Team persona 通用骨架（PM / architect / frontend / backend / reviewer）。当前未启用，启动团队协作时加载。
- `docs/信息服务APP的适老化设计与多模态交互_开题报告初稿.txt` — 毕业设计开题报告（文献综述、研究方法、进度安排）。用于论文定位，不用于实现细节。

## 实现时必须保留的核心概念

以下是蓝图中承重的区分点——略读时很容易被混为一谈。

**两种视觉模式，不是一个主题开关。** 标准版主色 `#2D74DC`（蓝色），长辈版主色 `#FF6D00`（橙色）。长辈版通过标准版首页上的专用入口按钮进入，**不是**通过设置项切换。

**两类弹窗，行为必须区别对待：**
- **系统弹窗**——阻塞式的操作系统级权限请求（摄像头、麦克风）。必须处理后流程才能继续。
- **应用内弹窗**——非阻塞式的浮层（底部登录提示、同意条款弹层、刷脸请求）。用户可关闭或忽略。
  在代码里**两者必须是两套独立的组件族**（如 `SystemDialog` / `InAppOverlay`），不共用基类传参——否则极易把非阻塞做成阻塞。

**两条登录分支**——刷脸认证是默认路径（同意条款 → 刷脸请求弹窗（应用内）→ 摄像头权限（系统）→ 眨眼/摇头动画）；另有验证码备选路径（`其他方式认证` → 验证码页面 → 验证码系统弹窗）。两条分支最终都应跳转至长辈版主页面。

**长辈版首页和"我的"页都是超长可滚动页面。** 每个页面由多张拼接截图构成（往下滑动一段/两段/三段）。应将其视为由多个片段组成的单一可滚动页面，而非多个独立路由。

## 待实现页面

页面清单与分阶段优先级见 `docs/PROJECT_PLAN.md` §六。共 11 个页面：SplashPage、HomePage、ElderHomePage（含 Tab：热门服务/我的常用/我的订阅）、LoginPage、FaceAuthPage、VerifyPage、SearchPage、SearchResultPage、SocialInsurancePage、PensionQueryPage、MyPage。

## 工作准则

- **原则是"还原，不改进"。** 即便间距、图标或流程看起来过时，也要克制现代化的冲动——对截图的还原度是本项目的评判标准。
- 截图文件名与蓝图中的页面名均为中文。在引用和提交信息中保持中文原样，**不要**转写为拼音或英文。

## 本地工具链约定

**使用项目级 Flutter SDK，不用系统级。** 所有 Flutter/Dart 命令走项目内包装脚本：

```bash
./bin/flutter <cmd>    # 不是 flutter <cmd>
./bin/dart <cmd>       # 不是 dart <cmd>
```

- SDK 位于 `tools/flutter/`（~1.5 GB，已 `.gitignore` 排除）
- 包装脚本自动设置镜像环境变量 `PUB_HOSTED_URL=https://pub.flutter-io.cn` 和 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- **不要**改 `~/.bashrc` / 不要把 `tools/flutter/bin` 加入系统 PATH——项目级隔离是刻意设计
- `flutter doctor` 会报 "binary not on PATH" 警告，这是预期的，不用修
