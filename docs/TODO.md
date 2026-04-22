# 项目 Todolist

本项目唯一的活待办文件。新增问题/任务统一写入此文件。

**状态图例：** 🔲 待做 · 🧪 已做完待用户验证 · ✅ 用户已确认完成

---

## 当前阶段：重新定义「受控响应型智能代理」（2026-04-22 启动）

> **背景**：Phase 1/2（浙里办长辈版像素级复刻）已**封存为"场景画布 v1"**，作为未来代理演示的载体保留，不再追求像素级还原。项目方向转为以"受控响应型智能代理"为核心的设计研究，直接对齐开题报告的学术定位。

### 进行中

- 🔲 `docs/AGENT_DEFINITION_QUESTIONS.md` 逐条答题（用户逐条答）
  - 组 A 代理 UI 形态 · 3 问
  - 组 B 代理能力边界 · 3 问
  - 组 C L1/L2/L3 可执行定义 · 3 问
  - 组 D 草稿箱 + 操作记录 · 5 问
  - 组 E **结构性矛盾·关键·先答** · 1 问
  - 组 F 错误恢复 · 2 问
  - 组 G 开放补充 · 任意
- 🔲 基于答案产出 `docs/AGENT_SPEC.md`（权威设计规范，替代旧 PRD）
- 🔲 制定新实施计划（依赖新 SPEC 完成）

### 已归档（见 `docs/archive/pre-redefinition/`）

- PRD.md（v2.0，基于旧方向的产品需求）
- PROJECT_PLAN.md（最早期蓝图）
- TECH_STACK_REVIEW.md（技术栈评审）
- AGENT_ARCHITECTURE.md（代理架构）
- AGENT_UI_SPEC.md（基于旧设计的 4 组件规格）
- AGENT_WEBSOCKET_SCHEMA.md（WebSocket 协议草案）
- TODO.md（Phase 1/2 时代的待办）

### 封存为"场景画布 v1"（2026-04-22 整体归档到 `archive/scene-canvas-v1/`，未来二次利用）

归档目录结构：
```
archive/scene-canvas-v1/
├── lib/                  Flutter Web 浙里办长辈版 UI（11 页 + 组件 + 服务骨架）
├── backend/              FastAPI + Agno + DeepSeek-V3（Step 1-4 已完成，未接前端）
├── test/                 33 个测试
├── assets/               字体资源（Noto Sans SC）
├── web/                  Flutter Web 入口
├── pubspec.yaml / .lock  Flutter 依赖清单
├── analysis_options.yaml
└── .metadata
```

留在根目录不动的基础设施（都可复用，不随代码归档）：
- `tools/flutter/`（Flutter SDK，gitignored）
- `bin/flutter` `bin/dart`（包装脚本，运行画布时需 `cd archive/scene-canvas-v1/` 后用 `../../bin/flutter <cmd>`）

**原则**：新定义确定前，不对归档目录下的代码做功能性改动。若新设计要求引入组件/路径，届时再决定是"原地解冻修改"还是"按需从归档取组件到新目录"。

---

## 已完成

### 项目整理（2026-04-22 · `f65a1fa`）

- 文档重组（旧设计归档）
- 记忆系统精简（4 份旧 feedback → 3 份合并）
- skill 清单对齐 .claude/skills/ 实际状态
- .gitignore 精细化（settings.local.json 不入库，其余 .claude/ 保留跟踪）

### Phase 1/2（2026-04-18 · 已封存）

11 页灰块线框 + 像素级贴皮 + 导航约定 + Noto 字体 + 33 测试。以"场景画布 v1"角色保留，完整提交记录见 `git log`。
