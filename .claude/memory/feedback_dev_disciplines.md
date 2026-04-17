---
name: 开发通用纪律
description: Config 保护、Search-first、Checkpoint、编辑前先查调用方等通用开发纪律
type: feedback
---

## Config 保护

绝不通过放宽 linter / formatter 配置来"修复"警告。遇到 ESLint、ruff、pyproject.toml 的规则报错，**修代码而不是改规则**。

**Why:** 规则通常有其道理，放宽会让问题在更大范围内蔓延。
**How to apply:** 看到 lint 错误先理解规则含义，再改代码。改规则前必须先和用户对齐。

## 编辑前先查调用方

修改任何 service/util 层函数（尤其是加参数、改签名）之前，必须**先 grep 该函数的所有调用点**。

**Why:** 实战踩坑：加 user_id 全链路隔离时，架构师 review 发现 5 处内部辅助函数遗漏，导致数据隔离失效。
**How to apply:** 引入全局参数（如 user_id、tenant_id、context）时必须做全量 grep 审计，列出完整修改清单，再一次性改完。不能"修到哪算哪"。

## 新增 DB 查询或 store 操作必须带全局隔离字段

新增任何 `select()`、`store.search()`、`store.upsert()` 等数据操作时，必须包含全局隔离字段（如 `user_id`、`tenant_id`）条件（admin/系统接口除外）。

**Why:** 这是多租户/多用户隔离的核心保障。遗漏一处就是数据泄露风险。
**How to apply:** code review 时专门检查数据操作的 where 条件是否包含隔离字段。

## Search-first 决策矩阵

写工具函数/新依赖之前，先查是否有现成方案：
1. **项目内** — 代码库里有没有类似实现？
2. **包生态**（PyPI / npm / cargo / maven） — 有没有成熟的包？
3. **组合** — 能用现有工具组合解决吗？
4. **自建** — 以上都不行才自己写

**Why:** 自建代码增加维护负担，重复造轮子还不如成熟库可靠。
**How to apply:** 每次动手写新工具前先停一下做这 4 步搜索。

## Checkpoint 习惯

大改动前（重构、跨模块修改）先打 checkpoint：
```bash
git tag checkpoint-<描述>
```
验证失败时可以快速回退。

**Why:** 大改动一旦出错，不打 checkpoint 只能一点点 revert，容易引入新问题。
**How to apply:** 判断"大改动"的标准：涉及 3+ 文件或涉及核心业务逻辑。

## 幂等性检测要双向

迁移脚本/数据处理脚本的幂等性检测要**双向检查**——既查"旧状态是否存在"，也查"新状态是否已完成"。

**Why:** 只检查旧状态会导致重复执行时破坏已迁移数据（PR-4 教训：config.py import 时 mkdir 旧路径会破坏迁移脚本幂等性）。
**How to apply:** 迁移脚本起手先 "if 目标已存在 then skip"，而不是 "if 源存在 then migrate"。

## 改代码必须重启服务（无热加载场景）

uvicorn / vite preview 等不热加载的服务，改代码必须重启，否则新旧代码混跑出现幽灵 bug。

**Why:** 改了代码不重启是经典踩坑，幽灵 bug 排查极其费时。
**How to apply:** 任何代码改动后，服务必须显式重启（团队模式下由 team-lead 负责）。

## 验证用实际调用，不用本地 import

后端功能验证要用 curl / HTTP 请求打真实运行的服务，不要在 REPL 里 import 模块跑。

**Why:** 本地 import 绕过了依赖注入、中间件、认证等实际请求路径，假通过。
**How to apply:** 验证 API 用 curl，不用 `python -c "from x import y; y()"`。

## 全链路字段透传检查

新增/修改 API 字段必须全链路检查透传：**前端 → api 层 → service 层 → DB**（以及反向）。

**Why:** 只改一端容易字段名不一致，前后端契约断裂导致 Bug。
**How to apply:** 每个新字段改动后，grep 该字段名在前后端各层的出现次数，确认一致。

## 同类踩坑记录到 CLAUDE.md

踩过的"关键踩坑"（尤其是新人容易再踩的）要记录到项目 CLAUDE.md，分类归档（如"开发流程"、"PR Review 教训"、"数据管理"）。

**Why:** 团队重建后新成员会再次踩同一个坑，记录下来可以让 persona 加载时读到。
**How to apply:** 每次架构师 review 发现遗漏模式时，同步落到 CLAUDE.md。
