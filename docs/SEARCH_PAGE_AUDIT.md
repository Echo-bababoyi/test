# 搜索页 — 现状审查与改进方案

> **日期**：2026-05-19 ｜ **作者**：architect
> **用户反馈**：(1) 不能点击的东西太多了，还不如没有 (2) 搜索联想机制需要调整

---

## 1. TL;DR

用户的两条吐槽都**完全合理**：

- 搜索页默认态有 **20 个看起来能点的元素，其中 19 个 `onTap` 是空函数 / `null`**。从老年用户视角，**几乎整页可视的交互元素都是骗局**。
- 搜索联想词库只有 **2 个 key、12 条候选**（`医保缴费` × 11 + `养老金查询` × 1）；其它输入全部 fallback 显示输入文本本身。匹配用 `contains` 双向判断，会出现"医保"和"医院"都被识别为"医保缴费"的问题。

**核心建议**：默认态**砍掉大部分装饰区**，只保留最有用的"我的常用 4 卡 + 真实最近搜索"，并把这些卡接上真路由；联想库扩到所有真实可达页面（5-8 个 key），匹配改前缀；结果页死按钮也清理。

---

## 2. 搜索页元素完整清单

### 2.1 顶部搜索栏（`_SearchBar` 行 120-213）

| 元素 | 行 | onTap | 字号 | 状态 |
|---|---|---|---|---|
| "西湖区"下拉 | 146 | `() {}` 空 | 14 | 🟠 **死按钮**（pretend 是定位选择器） |
| TextField 输入框 | 168 | autofocus + onSubmitted | **15** | 🟡 字号低（适老 ≥18） |
| 清除/麦克 icon | 180-192 | onClear / onMicTap | — | ✅ 真实可用 |
| "取消"按钮 | 198 | context.pop | **15** | 🟡 字号低；行为 OK |

### 2.2 默认态主体（`_DefaultBody` 行 217-336）

#### "我的常用" 区块（4 张快捷卡）

| 元素 | 行 | onTap | 状态 |
|---|---|---|---|
| 浙里医保 `_QuickItem` | 238 | **`() {}` 空** | 🟠 死按钮 |
| 社保查询 `_QuickItem` | 245 | **`() {}` 空** | 🟠 死按钮 |
| 住房公积金 `_QuickItem` | 257 | **`() {}` 空** | 🟠 死按钮 |
| 社保证明... `_QuickItem` | 265 | **`() {}` 空** | 🟠 死按钮 |

#### "最近搜索" 区块

| 元素 | 行 | onTap | 状态 |
|---|---|---|---|
| "清空"OutlinedButton | 282 | `onPressed: null` | 🟠 永久 disabled |
| `_RecentPill('医保')` | 302 | **`() {}` 空** | 🟠 死按钮 |
| `_RecentPill('养老金')` | 304 | **`() {}` 空** | 🟠 死按钮 |

**注**："最近搜索"是写死的两个值"医保 / 养老金"——**不是真实历史**，没用任何 storage / state 持久化。

#### "为你推荐" 区块

| 元素 | 行 | onTap | 状态 |
|---|---|---|---|
| 12 个 `_RecommendPill` | 317-328 | **全部 `() {}` 空** | 🟠 全部死按钮 |

涉及："办居住证 / 浙里医保 / 健康杭州 / 流动人口居住登记 / 小客车摇号 / 不动产智治 / 市场监管业务办理 / e房通 / 校园建身 / 公积金 / 入学早知道 / 医保查询"。**12 个 pill 全是死的**。

#### 字号问题
- `_QuickItem` label 14（行 370）— 适老化 ≥18 不达标
- `_RecentPill` 14（行 393）
- `_RecommendPill` 13（行 414）— **最小，最违反适老化**
- 区块标题 18 ✓
- "清空"按钮 13 — 即使可用也太小

### 2.3 联想结果态（`SearchSuggestionList` 行 47-58）

| 元素 | 行 | onTap | 字号 | 状态 |
|---|---|---|---|---|
| ListTile | 53 | `onSelect(items[i])` → `_submitSearch` | **16** | ✅ 行为通 / 🟡 字号低 |

**点击行为**：选中后跳到 `/search/result?q=<text>`。✅ 通路。

### 2.4 麦克权限 + 语音浮层（行 423-562）

| 元素 | onTap | 状态 |
|---|---|---|
| 麦克权限"去开启" / "暂不开启" | 工作 | ✅ |
| 语音浮层麦克按钮 | 2 秒延迟后**写死返回 '医保缴费'**（行 501） | 🟡 mock，但 demo 可用 |

---

## 3. 搜索联想机制（`search_suggestion_list.dart`）

### 数据源
**纯本地 mock**，硬编码 map（行 16-31）：
```dart
'医保缴费': [11 条派生候选],
'养老金查询': [1 条],
```

**只有 2 个 key**。

### 匹配逻辑（行 37）
```dart
entry.key.contains(query) || query.contains(entry.key)
```

测试结果：

| 输入 | 命中 key | 返回 | 评估 |
|---|---|---|---|
| "医" | `'医保缴费'.contains('医')` ✓ | 11 条候选 | OK |
| "医保" | `'医保缴费'.contains('医保')` ✓ | 11 条候选 | OK |
| "医保费用" | 两侧 contains 都 false | `['医保费用']` | 🟠 fallback 自己 |
| "医院" | `'医保缴费'.contains('医院')` false；`'医院'.contains('医保缴费')` false | `['医院']` | 🟡 OK |
| "养" | `'养老金查询'.contains('养')` ✓ | `['养老金查询']` | OK |
| "社保" | 两个 key 都不含"社保"，反之亦然 | `['社保']` | 🟠 fallback —— **"社保查询" 真实存在但联想不到** |
| "公积金" | 同上 | `['公积金']` | 🟠 fallback |

### 问题

1. **词库太窄**：只有 2 个 key，覆盖不到真实可达的 `pension_query / shebao_query / shebao_jiaona / yibao_jiaofei / yibao_query` 等多个页面
2. **匹配方向反了**：`query.contains(entry.key)` 这一支几乎用不上（用户不会输入比候选词更长的字符串然后期待匹配）；但仍存在边界——如用户输入"我想查养老金查询账户"会命中
3. **没有前缀/拼音/同义词**：输入"yanglao"或"YL"或"养老险"都不命中
4. **没有匹配高亮**：候选词不标黄/加粗匹配子串
5. **联想字号 16，长辈版偏小**

---

## 4. 搜索结果页（`search_result_page.dart` 行 271-489）

`_ResultBody` 也有 **5 个死按钮**：

| 元素 | onTap | 状态 |
|---|---|---|
| `_ServiceItem` 浙里医保（医保缴费组） | `null` | 🟠 disable |
| `_ServiceItem` 社保查询（医保缴费组） | `null` | 🟠 disable |
| `_ServiceItem` 退休待遇测算（养老金组） | `null` | 🟠 disable |
| `_ServiceItem` 社保证明打印 | `null` | 🟠 disable |
| `_AffairItem` × N | **全部 `() {}` 空** | 🟠 死按钮 |
| "查看更多搜索结果" | 是 `Text`，**根本没点击** | 🟠 看起来像按钮 |
| _ResultTab 顶部 Tab"全部/服务/办事..." | `() {}` 空 | 🟠 死按钮 |

可用入口仅 2 个：
- `_ServiceItem` "社保费缴纳" → push `shebaoJiaona` ✅
- `_ServiceItem` "社保查询"（养老金组） → push `shebaoQuery` ✅

**且 query 只支持"医保缴费"和"养老金查询"两个字符串完全相等**——其它都显示"暂无相关服务"（line 284-294）。从联想点进来的"少儿医保缴费"等候选词，**到结果页全是空**。

---

## 5. 改进方案

### P0：清理大量"骗局"按钮 — 改不了真就删

**原则**：宁可少几个装饰元素让页面看起来"空一点"，也不要让用户点了没反应。

#### 5.1 顶部"西湖区"

**`search_page.dart:146`**：`onTap: () {}` 改为 `onTap: null` + 灰化文字（让用户看出来这是只读位置标签，不是下拉）；或者**直接删掉**（这页不需要城市切换）。

**建议**：删掉整个 `InkWell`（行 146-159），位置标签是首页职责，搜索页无需。

#### 5.2 "我的常用" 4 卡片

**`search_page.dart:235-273`**：4 个 `_QuickItem` 全是空 `() {}`。

**改造**：
- 把 4 张卡的 `_QuickItem` 接受 `onTap` 回调，并在 `_DefaultBody.build` 里传入真实路由：
  - 浙里医保 → 当前没"浙里医保"页，可暂时改为 push `AppRoutes.yibaoQuery`（医保查询）或删掉
  - 社保查询 → `context.push(AppRoutes.shebaoQuery)` ✅
  - 住房公积金 → 没真实页，**删**
  - 社保证明... → 没真实页，**删**
- 重新组合为 2 张真实可点的卡：**社保查询 + 医保查询**，与 elder_home 一致

**`_QuickItem` 改造**（行 338-377）：把 `onTap: () {}` 改成接受外部 `VoidCallback? onTap`，构造方传入。

#### 5.3 "最近搜索"

**改造选项**：
- **选项 A（推荐）**：接入真实历史。新建 `SearchHistoryService`，用 `SharedPreferences` 或现有 `draft_store` 模式存最近 5 条；`_submitSearch` 时写入；这里读出来展示。点击 pill 即提交搜索（不再是空函数）。"清空"按钮变可用。
- **选项 B（极简）**：**直接删整个"最近搜索"区**——避免 mock 显得真，又永远死。

**建议**：演示 demo 阶段先选 B（删），后续如有时间再选 A。

#### 5.4 "为你推荐" 12 pill

**改造选项**：
- **选项 A**：把 pill 接到对应路由（已能识别的：浙里医保 → yibaoQuery；公积金 → 无；医保查询 → yibaoQuery；其它 8 个都无对应页）；不能识别的也 `_submitSearch(label)` 至少能跳到结果页
- **选项 B（推荐）**：让所有 pill `onTap: () => _submitSearch(label)`——既然每个 pill 都是"搜索这个词"，**最低成本可用化**

**最小修复**：`_RecommendPill` 加 `onTap` 参数，`_DefaultBody` 里全部传 `() => _submitSearch(label)`。**12 个 pill 一行改造全可用**。

#### 5.5 适老化字号升档

| 行 | 当前 | 改为 | 元素 |
|---|---|---|---|
| 154 | 14 | 18 / 删 | "西湖区" |
| 173 | 15 | 18 | TextField |
| 206 | 15 | 18 | "取消"按钮 |
| 295 | 13 | 16 | "清空"按钮（如保留） |
| 370 | 14 | 18 | _QuickItem label |
| 393 | 14 | 18 | _RecentPill |
| 414 | 13 | 16 | _RecommendPill |
| 414 | 内边距 8/12 | 12/16 | _RecommendPill 触控区扩大 |
| 54（widget） | 16 | 18 | SuggestionList ListTile |

### P1：扩展联想词库 + 改匹配逻辑

**`search_suggestion_list.dart` 重构方案**：

```dart
// 扩展到所有可达页面
static const _suggestionDict = {
  '医保缴费': ['医保缴费', '少儿医保缴费', '医保缴费记录', '城乡居民医保缴费'],
  '医保查询': ['医保查询', '医保账户余额', '医保消费记录'],
  '社保查询': ['社保查询', '社保缴费记录', '社保参保信息'],
  '社保费缴纳': ['社保费缴纳', '社保缴费'],
  '养老金查询': ['养老金查询', '本月养老金', '养老金账单'],
  '退休待遇测算': ['退休待遇测算', '养老金测算'],
  '公积金': ['公积金查询', '公积金缴存'],
};

// 同义词扩展（可选）
static const _synonyms = {
  '医保': ['医保查询', '医保缴费'],
  '社保': ['社保查询', '社保费缴纳'],
  '养老': ['养老金查询', '退休待遇测算'],
};

List<String> _suggestions() {
  if (query.isEmpty) return [];
  final q = query.trim();
  final results = <String>{};
  
  // 1. 前缀 / contains 匹配 dict 的 key
  for (final entry in _suggestionDict.entries) {
    if (entry.key.contains(q)) {
      results.addAll(entry.value);
    }
  }
  // 2. 候选词模糊匹配（用户输入"养老金"应命中"本月养老金"）
  for (final values in _suggestionDict.values) {
    for (final v in values) {
      if (v.contains(q)) results.add(v);
    }
  }
  // 3. 同义词
  for (final syn in _synonyms.entries) {
    if (q.contains(syn.key)) {
      for (final hit in syn.value) {
        results.addAll(_suggestionDict[hit] ?? []);
      }
    }
  }
  
  // fallback
  if (results.isEmpty) return [q];
  return results.take(8).toList();
}
```

**关键改动**：
- 删除 `query.contains(entry.key)` 反向匹配（用处小且容易出意外）
- 加候选词层面的 contains（用户输入"养老金"命中"本月养老金"）
- 加同义词映射
- 限制返回前 8 条（避免列表太长）
- 字号 16 → 18

**进阶（可选 P2）**：候选词列表里 RichText 高亮 query 子串（黄底或橙字）。

### P2：搜索结果页清理死按钮

**`search_result_page.dart`**：
- Affair 区 `_AffairItem.onTap: () {}` → 改为 `onTap: null` + 灰色（语义"政务办事项暂未上线"）；或直接 push 一个统一的"该事项未开通"SnackBar
- "查看更多搜索结果"是纯 Text → **要么删，要么改为 onTap → 显示更多 mock 数据**
- ResultTab "全部/服务/办事" `() {}` → 既然只有一种内容布局，删掉 Tab 行
- 字号：`_ServiceItem.title` 16 → 18；`chips` 12 → 14；`department` 12 → 14；`_AffairItem.title` 15 → 18

---

## 6. 改动清单与优先级

| # | 文件 | 改动 | 工作量 | 优先级 |
|---|---|---|---|---|
| 1 | `search_page.dart` 默认体 | 删"西湖区" + 删"住房公积金/社保证明..." 2 死卡 + "最近搜索"整段删 | 30 min | P0 |
| 2 | `search_page.dart` `_QuickItem` / `_RecommendPill` | 加 `onTap` 参数，"我的常用" 2 张真路由，"为你推荐" 12 个 `_submitSearch(label)` | 20 min | P0 |
| 3 | `search_page.dart` 字号升档 8 处 | 15→18 / 14→18 / 13→16 | 10 min | P1 |
| 4 | `search_suggestion_list.dart` | 词库扩展（7 个 key），匹配逻辑加同义词，字号 16→18 | 30 min | P1 |
| 5 | `search_result_page.dart` | _AffairItem onTap 改 null 灰化 + 删"查看更多" + 删 ResultTab + 字号升档 | 30 min | P2 |

**总工作量**：~2 小时。**P0 必修**（用户感受最大），P1 论文/答辩前必修，P2 锦上添花。

---

## 7. 推荐"瘦身后"默认态

按上述方案 #1 + #2 改完，默认态会从 ~20 个元素瘦到约 6 个区块、14 个真实可点元素：

```
┌─────────────────────────────────────────┐
│ [TextField "搜索服务、政策..."]    [取消] │ ← 顶栏（删"西湖区"）
├─────────────────────────────────────────┤
│ 我的常用                                  │
│  ┌─社保查询─┐   ┌─医保查询─┐             │ ← 2 真路由
│                                          │
│ 为你推荐                                  │
│  [浙里医保] [社保查询] [医保查询]         │
│  [养老金查询] [社保费缴纳] [公积金]       │ ← 全部 onTap → _submitSearch
│  ...                                      │
└─────────────────────────────────────────┘
```

**视觉感受**：内容少了一半，但**每个元素都能点**，符合用户"宁少不假"的要求。

---

## 8. 测试 checklist

- [ ] 进入搜索页，看不到"西湖区""住房公积金""社保证明..."等死按钮
- [ ] 点"社保查询"快捷卡 → 跳 `/service/shebao-query`
- [ ] 点"医保查询"快捷卡 → 跳 `/service/yibao-query`
- [ ] 点任一推荐 pill → 跳 `/search/result?q=<pill 名>`
- [ ] 输入"养" → 联想列表出现"养老金查询 / 本月养老金 / 养老金账单 / 退休待遇测算 / 养老金测算"等
- [ ] 输入"社保" → 联想列表出现"社保查询 / 社保缴费记录 / 社保费缴纳"等
- [ ] 输入"医保" → 联想列表出现"医保缴费 / 医保查询 / 医保账户余额"等
- [ ] 联想 ListTile 字号 ≥18，触控目标 ≥48dp
- [ ] 结果页 _AffairItem 视觉是灰色禁用态，点击无响应也不显示反馈错觉
- [ ] 所有可点元素字号 ≥18sp（适老化）
