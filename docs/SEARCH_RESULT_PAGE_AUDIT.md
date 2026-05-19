# 搜索结果页 — 适老化审查

> **日期**：2026-05-19 ｜ **作者**：architect
> **范围**：`app/lib/pages/search_result_page.dart`（team-lead 笔误写成 `search_page.dart`，实际是结果页）

---

## 1. TL;DR

整页字号 **全线低于适老化阈值**：顶栏 14-15sp、Tab 行 15sp、结果项 title 16sp、chips/部门 12sp、空态提示 14sp。共有 **9 处字号违规**。

触控目标：顶栏 TextField 36dp、Tab 行 ~30dp 全部 **不达 44dp**。

死按钮：顶栏"西湖区" + 4 个 Tab（综合/服务/办事/政策）+ 全部 `_AffairItem` + "查看更多搜索结果"（纯 Text）= **至少 7 处骗局**。

布局结构问题：query 仅在等于 `"医保缴费"` 或 `"养老金查询"` 两个完整字符串时才展示真实卡片，**任何联想候选词点进来都是"暂无相关服务"**。

---

## 2. 元素完整清单（按视觉自上而下）

### 2.1 顶部搜索栏 `_ResultTopBar`（行 115-206）

| 元素 | 行 | 当前字号 / 触控 | onTap | 评估 |
|---|---|---|---|---|
| "西湖区"下拉 | 149 | **14sp** | `() {}` 空 | 🟠 死按钮 + 字号低 |
| TextField 容器 | 159 | height **36dp** | — | ⚠️ 触控 <44dp |
| TextField 文本 | 170 | **15sp** | autofocus + onSubmitted | ⚠️ 字号低 |
| TextField 内边距 | 173-176 | h12/v9 | — | ⚠️ 偏紧 |
| 清除 icon | 179 | size 18 | onClearTap | 🟡 icon 偏小但触控区 44×44 ✓ |
| "取消"按钮 | 199 | **15sp** + minimumSize(48,44) | onCancel | ⚠️ 字号低；触控 OK |

### 2.2 Tab 行 `_ResultTabRow`（行 210-267）

| 元素 | 行 | 当前字号 / 触控 | onTap | 评估 |
|---|---|---|---|---|
| 4 个 _TabLabel（综合 / 服务 / 办事 / 政策） | 240 | **15sp** + vertical Spacing.sm(8) ≈ 30dp 高 | **全部 `() {}` 空** | 🟠 4 个全是死按钮 + 字号低 + 触控 <44dp |
| 选中下划线 | 257-261 | width 24, height 2 | — | ✓ |

### 2.3 结果体 `_ResultBody`（行 271-311）

| 元素 | 行 | 当前 | 状态 |
|---|---|---|---|
| "暂无相关服务" 空态文字 | 290-293 | **14sp** + textSecondary | ⚠️ 字号低 |
| "查看更多搜索结果" | 295-303 | **14sp** + textSecondary | 🟠 **纯 `Text` 不能点**——看起来像 CTA 按钮 |
| `_SectionHeader('服务'/'办事')` | 396 | 18sp w700 | ✓ |

### 2.4 服务项 `_ServiceItem`（行 401-470）

| 元素 | 行 | 当前字号 / 大小 | 评估 |
|---|---|---|---|
| icon 容器 | 428 | 36×36 dp | ⚠️ 偏小（卡片整体 padding 后触控 OK，但视觉小） |
| icon | 434 | size **18** | ⚠️ 偏小 |
| title | 441 | **16sp** w600 | ⚠️ <18 |
| chips | 453 | **12sp** | ⚠️ 严重低 |
| department | 460 | **12sp** + textSecondary | ⚠️ 严重低 |
| chevron_right | 464 | 默认 24 | ✓ |

**onTap 情况**：
- 浙里医保（医保缴费组）：`null` 🟠 disabled
- 社保费缴纳：`context.push(shebaoJiaona)` ✅
- 社保查询（医保缴费组）：`null` 🟠
- 社保查询（养老金组）：`context.push(shebaoQuery)` ✅
- 退休待遇测算：`null` 🟠
- 社保证明打印：`null` 🟠

### 2.5 办事项 `_AffairItem`（行 472-489）

| 元素 | 行 | 当前 | 状态 |
|---|---|---|---|
| title | 484 | **15sp** | ⚠️ <18 |
| chevron_right | 485 | size **18** | ⚠️ 偏小 |
| onTap | 479 | `() {}` 空 | 🟠 **所有 `_AffairItem` 全是死按钮** |

具体死按钮：行 374 "职工参保登记（医保）" / 行 376 "职工医保补缴" / 行 381 "退休高级职称人员增加养老金待遇"。

### 2.6 _ResultTab 内部 _TabLabel（行 232-267）

已在 2.2 列。补充：行 251 字号 15sp、行 252 w600（选中）/ normal（未选）。

---

## 3. 字号违规汇总（9 处）

| 优先级 | 文件:行 | 当前 | 建议 | 元素 |
|---|---|---|---|---|
| P0 | 149 | 14 | 18 / 或删 | "西湖区" |
| P0 | 170 | 15 | 18 | TextField 文本 |
| P0 | 199 | 15 | 20 | "取消"按钮 |
| P0 | 251 | 15 | 18 | Tab 标签 |
| P0 | 441 | 16 | 20 | _ServiceItem title |
| P0 | 484 | 15 | 18 | _AffairItem title |
| P1 | 290-293 | 14 | 16 | "暂无相关服务" |
| P1 | 295-303 | 14 | 16 | "查看更多搜索结果" |
| P1 | 460 | 12 | 14 | _ServiceItem department |
| P1 | 453 | 12 | 14 | _ServiceItem chips |

**总 10 处**。

---

## 4. 触控区违规（3 处）

| 文件:行 | 元素 | 当前 | 建议 |
|---|---|---|---|
| 159 | TextField 容器 | height 36 | height **44**（同时调 borderRadius=22） |
| 244 | _TabLabel 整体 | vertical Spacing.sm ≈ 30dp 高 | 改 vertical Spacing.md(12)：约 44dp 触控 |
| 485 | _AffairItem chevron_right | size 18 | size 28（与 _ServiceItem 的 chevron 一致） |

---

## 5. 死按钮（7 处骗局）

| # | 文件:行 | 元素 | 当前 | 建议 |
|---|---|---|---|---|
| 1 | 143-152 | "西湖区"下拉 | `onTap: () {}` | **直接删整个 InkWell** — 城市选择是首页职责，结果页不需要 |
| 2-5 | 240（×4 处 `_TabLabel`） | Tab "综合/服务/办事/政策" | `onTap: () {}` | 4 个 Tab 当前永远只显示一种 body —— **整段 `_ResultTabRow` 删掉**；若 PM 想保留视觉，把"综合"做成 disabled 静态文字 |
| 6 | 295-303 | "查看更多搜索结果" | 纯 Text 没 onTap | **删** —— 没真实"更多结果"页可去 |
| 7 | 479 | _AffairItem InkWell | `onTap: () {}` | 改 `onTap: null` + 灰化文字 + 灰化 chevron（语义"政务事项暂未开通"）；或弹 SnackBar "该事项暂未开通" |

---

## 6. 整体布局结构问题

### 6.1 query 匹配过死

**行 282-284**：
```dart
if (query == '医保缴费') ..._medicalPayServices(context),
if (query == '养老金查询') ..._pensionServices(context),
if (query != '医保缴费' && query != '养老金查询')
  // "暂无相关服务"
```

**问题**：联想列表的候选词包含"少儿医保缴费 / 医保缴费记录 / 农村医保缴费 / 本月养老金 / 退休待遇测算 / 社保查询"等（参见 search_suggestion_list.dart 重构方案），但**点这些进来全部是"暂无相关服务"**——用户被 dead-end。

**修复方向**：把硬等号改为 **关键词包含 + 派生候选词归属**，例如：
```dart
final isMedicalPay = ['医保缴费', '少儿医保缴费', '医保缴费记录', '农村医保缴费',
                      '社保费缴纳', '城乡居民医保缴费'].contains(query);
final isPensionQuery = ['养老金查询', '本月养老金', '养老金账单',
                        '退休待遇测算', '养老金测算'].contains(query);
```

或者更彻底：维护一份 `query → resultGroup` 映射表，与 `search_suggestion_list.dart` 的词库**共享**（避免词库扩了但结果页跟不上）。

### 6.2 缺统计与定位

- 没有"找到 N 个结果"的提示头（一般搜索引擎都有）
- 没有顶部 query echo（用户看不到自己搜了什么——只能从 TextField 里读）

### 6.3 _ResultTabRow 与 query 解耦

当前 Tab 即使可点也没意义（4 个 Tab 切换显示同一个 _ResultBody），所以 **整段 `_ResultTabRow` + `Divider`（search_result_page.dart:96-97）应当删除**。如果论文里要保留"分类切换"的视觉概念，**等真有"服务/办事/政策"分组数据时再加**。

---

## 7. 修复清单（按优先级）

| # | 改动 | 文件:行 | 工作量 | 优先级 |
|---|---|---|---|---|
| 1 | 删"西湖区" InkWell + 删"查看更多搜索结果" + 删 `_ResultTabRow` 调用与 Divider | 143-153, 295-303, 96-97 | 10 min | P0 |
| 2 | _AffairItem `onTap: () {}` → `onTap: null` + 灰化 title/chevron color → grey.shade400 | 479-486 | 10 min | P0 |
| 3 | 顶栏字号 / 触控升档：TextField height 36→44、字号 15→18；"取消" 15→20 | 159, 170, 199 | 5 min | P0 |
| 4 | 结果项字号升档：_ServiceItem title 16→20、chips 12→14、department 12→14；_AffairItem title 15→18、chevron 18→28 | 441, 453, 460, 484, 485 | 10 min | P0 |
| 5 | 空态文字 14→16 | 290-293 | 2 min | P1 |
| 6 | _ServiceItem icon 容器 36→44、icon size 18→24 | 428, 429, 434 | 5 min | P1 |
| 7 | query 匹配改为 contains 派生关键词（与联想词库联动） | 282-284 | 20 min | P1 |
| 8 | 加"找到 N 项相关服务"统计头 | _ResultBody 顶部 | 10 min | P2 |

**总工作量** ~1h。**P0 必修**（字号/死按钮直接影响用户感受），P1 论文/答辩前必修，P2 锦上添花。

---

## 8. 改完后的页面预览

```
┌────────────────────────────────────────┐
│ [医保缴费                ⊗]  [取消]    │ ← 顶栏（删"西湖区"，字号 18，h 44）
├────────────────────────────────────────┤
│                                         │
│  服务                                    │ ← 18sp 区段标题
│  ┌─┐ 浙里医保                       ›  │ ← title 20sp，icon 44，禁用灰
│  └─┘ [医保地图][医保个人账户][医保]    │   chips 14sp
│      省医保局                            │   dept 14sp
│  ────────                              │
│  ┌─┐ 社保费缴纳                     ›  │ ← 可点，title 20sp 黑
│  └─┘ [社保医保缴费][城乡居民...]       │
│      省税务局                            │
│  ────────                              │
│  ┌─┐ 社保查询                       ›  │ ← 禁用灰
│  └─┘                                    │
│      省人力社保厅                        │
│                                          │
│  办事                                    │
│  ──────                                │
│  职工参保登记（医保）                  ›│ ← 18sp，灰化（disabled）
│  职工医保补缴                          ›│ ← 18sp，灰化
└────────────────────────────────────────┘
```

视觉上：所有字 ≥14sp（chips/dept），主要文字 ≥18，可点的明确黑色，不可点的明确灰色。

---

## 9. 测试 checklist

- [ ] 顶部不再有"西湖区"按钮
- [ ] 不再有 Tab 行（综合/服务/办事/政策）
- [ ] 顶部 TextField 高度 ≥44dp，字号 18
- [ ] "取消"字号 20sp
- [ ] _ServiceItem title 20sp，chips 14sp，department 14sp
- [ ] _AffairItem 视觉是灰色 disabled 状态，点击无响应
- [ ] 不再有"查看更多搜索结果"文字
- [ ] 用户从联想"少儿医保缴费"点进来，能看到 _medicalPayServices 卡片（修 #7 后）

---

## 10. 范围声明

本审查仅覆盖 `search_result_page.dart`。前置的搜索页（`search_page.dart` 默认态）按 team-lead 反馈已 OK，未重审。搜索联想机制扩展见 `docs/SEARCH_PAGE_AUDIT.md` §5 P1 项。
