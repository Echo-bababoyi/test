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

**当前阶段**：设计阶段全部完成（2026-04-28），进入编码实施阶段。设计文档体系：`docs/PRD.md`（产品需求）→ `docs/AGENT_SPEC.md`（代理规范）→ `docs/ARCHITECTURE.md`（系统架构 v1.2，Agno + DeepSeek-V3 + 讯飞 ASR/TTS）→ `docs/UI_UX_DESIGN.md`（交互设计 + 适老化规范）。

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
├── docs/
│   ├── PRD.md                                 # 【权威】产品需求文档（v1.0）
│   ├── AGENT_SPEC.md                          # 【权威】代理设计规范（v1.0）
│   ├── ARCHITECTURE.md                        # 【权威】系统架构设计（v1.2）
│   ├── UI_UX_DESIGN.md                        # 【权威】UI/UX 交互设计（v1.0）
│   ├── IMPLEMENTATION_PLAN.md                 # 编码实施计划（初稿，待修订）
│   ├── AGENT_DEFINITION_QUESTIONS.md          # 设计问答记录（决策追溯）
│   ├── 信息服务APP的适老化设计与多模态交互_开题报告初稿.txt  # 【北极星】开题报告
│   ├── 复刻浙里办/
│   │   ├── 浙里办页面逻辑.txt                  # 页面跳转与弹窗流程说明
│   │   └── 截图/                              # 32 张浙里办截图（场景参考）
│   └── team-personas/                         # CC Team persona 骨架（未启用）
└── archive/                                   # 已清空
```

## 参考资料说明

- `docs/PRD.md` — **产品需求文档**。产品定位、目标用户、功能清单（含优先级与毕设范围标注）、4 个核心场景用户故事与验收标准、非功能需求、产品边界。
- `docs/AGENT_SPEC.md` — **代理设计规范**。代理的原则、能力矩阵、业务场景、UI 形态、三项机制、错误恢复等全部定义。
- `docs/IMPLEMENTATION_PLAN.md` — **编码实施计划**（初稿）。10 个子任务、4 个 Phase、技术风险。PM 已审阅，有 3 条调整建议待采纳修订。
- `docs/AGENT_DEFINITION_QUESTIONS.md` — 设计定义阶段的问答工作文档（7 组全部定稿）。保留用于决策追溯，不作为设计依据——以 AGENT_SPEC.md 为准。
- `docs/信息服务APP的适老化设计与多模态交互_开题报告初稿.txt` — 毕业设计开题报告（文献综述、研究方法）。**论文北极星**，所有设计决策需与此对齐。
- `docs/复刻浙里办/` — 浙里办页面逻辑说明 + 32 张截图。**场景参考**，非设计依据。
- `ISSUES.md` — **本项目唯一的**问题清单。新增问题/任务一律写入此文件。状态：✅ 已完成 / 🧪 已实现待测 / 🔧 未实现 / 🐛 Bug / ❓ 待确认。

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

