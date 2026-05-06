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

## 仓库定位（2026-04-28 更新）

本项目为本科毕业设计，学术定位见开题报告：**《信息服务 APP 的适老化设计与多模态交互》**。

**核心创新点**：**受控响应型智能代理"小浙"**（权限受控 + 行为受控 + 不主动挑事，只在用户有需求时介入）。围绕该代理设计展开适老化交互与多模态交互研究。

**当前阶段**：编码实施完成（2026-05-06），进入部署与真机测试阶段。技术栈：FastAPI + Agno Agent + DeepSeek-V3 + Web Speech API（ASR）+ Edge TTS。

## 项目结构

```
.
├── CLAUDE.md                 # 本文件（项目指引）
├── COMMITS.md                # git commit 记录
├── ISSUES.md                 # 问题/任务清单（唯一）
├── SESSION-LOG.md            # 会话日志
├── bin/                      # Flutter/Dart 包装脚本
│   ├── flutter
│   └── dart
├── flutter/                  # 项目级 Flutter SDK（.gitignore 排除）
├── backend/                  # FastAPI 后端
│   ├── main.py               # 入口 + WebSocket 端点
│   ├── ws_handler.py          # WebSocket 状态机
│   ├── agent_core.py          # Agno Agent 核心
│   ├── models.py              # Pydantic 消息模型
│   ├── deepseek_client.py     # DeepSeek API 客户端
│   ├── asr_adapter.py         # 讯飞 ASR 适配器（备用）
│   ├── tts_adapter.py         # 讯飞 TTS + Edge TTS
│   ├── xunfei_auth.py         # 讯飞签名公共模块
│   ├── tools/                 # 5 个 Agno 工具函数
│   ├── prompts/               # 场景 prompt（6 个）
│   └── tests/                 # E2E + HITL 测试
├── app/                       # Flutter Web 前端
│   ├── lib/
│   │   ├── main.dart
│   │   ├── router.dart        # GoRouter 12 条路由
│   │   ├── theme.dart         # 适老化主题
│   │   ├── pages/             # 12 个页面
│   │   ├── widgets/           # 代理面板、气泡、麦克风等
│   │   └── services/          # WS 客户端、会话状态、草稿箱等
│   └── pubspec.yaml
├── docs/
│   ├── PRD.md                 # 【权威】产品需求文档（v1.0）
│   ├── AGENT_SPEC.md          # 【权威】代理设计规范（v1.0）
│   ├── ARCHITECTURE.md        # 【权威】系统架构设计（v1.2）
│   ├── UI_UX_DESIGN.md        # 【权威】UI/UX 交互设计（v1.0）
│   ├── NEXT_PLAN.md           # 【当前】下一阶段计划（v2.0）
│   ├── 信息服务APP的适老化设计与多模态交互_开题报告初稿.txt  # 【北极星】开题报告
│   ├── 复刻浙里办/             # 浙里办截图参考
│   └── team-personas/         # CC Team persona 文件
└── archive/
    └── scene-canvas-v1/       # 旧版场景画布（UI 参考）
```

## 参考资料说明

- `docs/PRD.md` — **产品需求文档**。产品定位、目标用户、功能清单、4 个核心场景用户故事与验收标准。
- `docs/AGENT_SPEC.md` — **代理设计规范**。代理的原则、能力矩阵、业务场景、UI 形态、三项机制。
- `docs/ARCHITECTURE.md` — **系统架构设计**。技术选型、数据模型、WebSocket 协议、核心场景时序。
- `docs/UI_UX_DESIGN.md` — **UI/UX 交互设计**。4 场景剧本、适老化规范、代理面板设计。
- `docs/NEXT_PLAN.md` — **下一阶段计划**（v2.0）。6 个任务，Web Speech API + PWA 简化方案。
- `docs/信息服务APP的适老化设计与多模态交互_开题报告初稿.txt` — **论文北极星**。
- `docs/复刻浙里办/` — 浙里办页面逻辑 + 截图。**场景参考**。
- `ISSUES.md` — **本项目唯一的**问题清单。状态：✅ 已完成 / 🧪 已实现待测 / 🔧 未实现 / 🐛 Bug / ❓ 待确认。

## 工作准则

- 截图文件名与文档中的页面名均为中文。在引用和提交信息中保持中文原样，**不要**转写为拼音或英文。
- 设计决策以 `docs/AGENT_SPEC.md` 为权威依据。

## 本地工具链约定

**使用项目级 Flutter SDK，不用系统级。** 所有 Flutter/Dart 命令走项目内包装脚本：

```bash
./bin/flutter <cmd>    # 从项目根调用
./bin/dart <cmd>
```

- SDK 位于 `flutter/`（2.3 GB，已被根 `.gitignore` 排除）
- 包装脚本自动设置镜像环境变量 `PUB_HOSTED_URL=https://pub.flutter-io.cn` 和 `FLUTTER_STORAGE_BASE_URL=https://storage.flutter-io.cn`
- **不要**改 `~/.bashrc` / 不要把 `flutter/bin` 加入系统 PATH——项目级隔离是刻意设计
- `flutter doctor` 会报 "binary not on PATH" 警告，这是预期的，不用修

