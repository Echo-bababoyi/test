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

**当前阶段**：前端交互体验优化阶段性收尾（2026-05-19）。AgentFab 悬浮助手组件已落地（取代旧版底部代理面板入口）；多页面交互重构完成（drafts / face_auth / pension_query / elder_bottom_nav / mic_button / agent_bubble 已按 v1.1 规范统一）；6 条低保真线框图 wireframe 路由就位，配合论文素材生成；后端 Agno API 字段适配 + 异常捕获 + ASR 三类错误细分 + text_input 异步化 + TTS 按需生成 + dotenv 配置已完成加固。Noto Sans SC 字体集成。主流程可在 localhost 跑通。下一步：N1 麦克风 Web Speech API 接入 → N2 云服务器部署 → N4 真机测试 → N5 Prompt 调优 → N6 答辩准备。技术栈：FastAPI + Agno Agent + DeepSeek-V3 + Web Speech API（ASR）+ Edge TTS。

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
│   ├── main.py               # 入口 + WebSocket 端点 + dotenv 加载
│   ├── ws_handler.py          # WebSocket 状态机（ASR 三类错误细分 + text_input 异步化）
│   ├── agent_core.py          # Agno Agent 核心（API 字段适配 + 异常捕获加固）
│   ├── models.py              # Pydantic 消息模型
│   ├── deepseek_client.py     # DeepSeek API 客户端
│   ├── asr_adapter.py         # 讯飞 ASR 适配器（备用）
│   ├── tts_adapter.py         # 讯飞 TTS + Edge TTS（按需生成）
│   ├── xunfei_auth.py         # 讯飞签名公共模块
│   ├── tools/                 # 5 个 Agno 工具函数
│   ├── prompts/               # 场景 prompt（8 个：6 场景 + intent_classify + confirm_rephrase）
│   └── tests/                 # E2E + HITL 测试
├── app/                       # Flutter Web 前端
│   ├── fonts/                 # Noto Sans SC（Regular + Bold）
│   ├── lib/
│   │   ├── main.dart
│   │   ├── router.dart        # GoRouter 24 条路由（含 6 条 wireframe）
│   │   ├── theme.dart         # 适老化主题
│   │   ├── pages/             # 18 个页面（含 wireframe_page）
│   │   ├── widgets/           # AgentFab 悬浮助手、代理面板/气泡、麦克风、PressScaleWrapper 等
│   │   └── services/          # WS 客户端、会话状态、草稿箱等
│   └── pubspec.yaml
├── docs/
│   ├── PRD.md                 # 【权威】产品需求文档（v1.0）
│   ├── AGENT_SPEC.md          # 【权威】代理设计规范（v1.0）
│   ├── ARCHITECTURE.md        # 【权威】系统架构设计（v1.2）
│   ├── UI_UX_DESIGN.md        # 【权威】UI/UX 交互设计（v1.0）
│   ├── NEXT_PLAN.md           # 【当前】下一阶段计划（v2.0）
│   ├── DEPLOY.md              # 云服务器部署手册
│   ├── AGENT_DESIGN_REPORT.md # 智能代理设计分析报告（v1.3）
│   ├── INTERACTION_REVIEW.md  # 交互审查报告（三轮审查记录）
│   ├── USER_JOURNEY.md        # 4 场景用户旅程图 + 情感曲线
│   ├── USER_JOURNEY_TESTING.md # 7 场景操作级测试旅程图
│   ├── UI_UX_AUDIT.md         # 适老化审查（工信部规范 + 国际最佳实践）
│   ├── UI_RESTORE_REQUIREMENTS.md  # UI 还原需求
│   ├── UI_RESTORE_TECH_PLAN.md     # UI 还原技术方案
│   ├── 毕业设计论文草稿.md       # 论文初稿（持续更新）
│   ├── 信息服务APP的适老化设计与多模态交互_开题报告初稿.txt  # 【北极星】开题报告
│   ├── diagrams/              # 论文图表素材（IA 图、用户旅程图、wireframe、截图脚本）
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
- `docs/DEPLOY.md` — 云服务器部署手册（N2 任务参考）。
- `docs/AGENT_DESIGN_REPORT.md` — 智能代理设计分析报告（v1.3，8 节 + 附录），论文章节素材。
- `docs/INTERACTION_REVIEW.md` — 交互审查报告，三轮 architect 审查的完整记录与改造对照。
- `docs/USER_JOURNEY.md` — 4 场景用户旅程图、情感曲线、前端支撑评估。
- `docs/USER_JOURNEY_TESTING.md` — 7 场景操作级测试旅程图，E2E 测试输入来源。
- `docs/UI_UX_AUDIT.md` — 适老化审查报告（工信部规范 + 国际最佳实践）。
- `docs/UI_RESTORE_REQUIREMENTS.md` / `docs/UI_RESTORE_TECH_PLAN.md` — UI 还原需求与技术方案。
- `docs/毕业设计论文草稿.md` — **论文初稿**（持续更新，配 `docs/diagrams/` 图表素材）。
- `docs/diagrams/` — 论文图表素材（IA 图、用户旅程图、wireframe、截图脚本）。
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

