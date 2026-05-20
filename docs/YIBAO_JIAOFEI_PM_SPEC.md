# 医保缴费流程优化方案（PM 规范）

> **作者**：PM
> **日期**：2026-05-20
> **会话**：session-11b
> **依据**：`docs/YIBAO_JIAOFEI_FLOW_AUDIT.md`（architect 审查报告）
> **交付对象**：frontend（可直接按此文件实施）

---

## 一、shebaoJiaona 定位决策

**结论：`ShebaoJiaonaPage` 保留为「社保费缴纳」hub，与「医保」场景彻底解耦。**

| 维度 | ShebaoJiaonaPage（社保费缴纳） | YibaoJiaofeiPage（医保缴费） |
|------|-------------------------------|------------------------------|
| 制度归属 | 税务局代征五险（养老/医疗/失业/工伤/生育） | 医保局受理城乡居民医保年度缴费 |
| 目标用户 | 在职职工 | 城乡居民、灵活就业、退休人员（本项目核心用户） |
| 管理部门 | 浙江省税务局（Banner 正确） | 国家医疗保障局 |
| 交互差异 | 系统自动查应缴额，用户确认扣款 | 用户主动选档次发起缴费 |

**理由**：两个页面在制度、用户群、操作逻辑上是不同产品，合并会导致老年用户在"社保"概念下迷失，违反「不带方案提需求」原则中的「减法比加法更有价值」。

**直接影响**：所有「健康医保」/「浙里医保」/「医保缴费」入口**不再**指向 `shebaoJiaona`，改为指向新建 `YibaoHubPage`。

---

## 二、完整用户路径设计

### 主路径（长辈版）

```
ElderHome · 「健康医保」九宫格（或「浙里医保」常用卡片）
  └─ YibaoHubPage（新建，/service/yibao-hub）
       ├─ [医保缴费]  → YibaoJiaofeiPage（/service/yibao-jiaofei）
       │     ├─ 填写表单（缴费对象/险种/年度/档次/身份证）
       │     └─ 「去支付」 → PayConfirmPage（/service/yibao-jiaofei/confirm）
       │                         └─ 确认摘要 + 选银行卡
       │                               └─ 「确认支付」→ PayPasswordPage（/service/yibao-jiaofei/pay）
       │                                                   └─ 输入6位密码（mock: 123456 成功）
       │                                                         └─ PayResultPage（/service/yibao-jiaofei/result）
       ├─ [医保查询]  → YibaoQueryPage（/service/yibao-query，现有）
       └─ [缴费记录]  → SnackBar「功能建设中」（占位，后续接 yibao-records 页）
```

### 搜索路径

```
SearchPage → 用户点「医保查询」QuickItem
  → YibaoQueryPage（/service/yibao-query）           ← 修正（现在错跳 shebaoJiaona）

SearchResultPage → 搜索词命中 _isMedicalPay
  → 「浙里医保」card → YibaoJiaofeiPage               ← 修正（现在错跳 yibaoQuery）
  → 「社保费缴纳」card → ShebaoJiaonaPage              ← 保持不变
  → 「社保查询」card → ShebaoQueryPage                 ← 保持不变

SearchResultPage → 搜索词命中 _isMedicalQuery（新分支）
  → 「浙里医保」card → YibaoQueryPage                 ← 新增分支
```

---

## 三、入口修正清单

| # | 文件 + 位置 | 当前错误 | 修正后 | 优先级 |
|---|------------|---------|--------|--------|
| 1 | `elder_home.dart:577` 九宫格「健康医保」 | `shebaoJiaona` | `yibaoHub`（新建） | P0 |
| 2 | `elder_home.dart:436-442` 常用卡「浙里医保」 | `_showTodo` SnackBar | `yibaoHub`（新建） | P0 |
| 3 | `search_page.dart:238` QuickItem「医保查询」 | `shebaoJiaona` ❌ | `yibaoQuery` | P0 |
| 4 | `search_result_page.dart:238` 「浙里医保」card（_isMedicalPay 上下文） | `yibaoQuery` ❌ | `yibaoJiaofei` | P0 |
| 5 | `search_result_page.dart:158-165` `_isMedicalPay` 别名表 | 仅 6 个词，缺高频词 | 扩充（见下方） | P1 |
| 6 | `search_page.dart:254,264` 推荐 pill「浙里医保」「医保查询」 | 搜索跳空状态 | 别名表扩充后自然修复 | P1 |

### 别名表扩充（`_isMedicalPay` 现有 + 新增）

```dart
// 现有（保留）
'医保缴费', '少儿医保缴费', '医保缴费记录', '农村医保缴费',
'城乡居民医保缴费', '社保费缴纳',
// 新增
'医保', '浙里医保', '健康医保', '居民医保', '城乡居民医保',
'缴医保', '交医保',
```

新增 `_isMedicalQuery` 分支（独立判断，优先于 `_isMedicalPay`）：

```dart
// _isMedicalQuery 关键词
'医保查询', '医保余额', '医保账户', '医保余额查询',
```

---

## 四、YibaoHubPage 页面规范（新建）

| 属性 | 值 |
|------|-----|
| 路由 | `/service/yibao-hub`（在 `AppRoutes` 新增） |
| AppBar | 橙色底 `_kOrange` + "健康医保" + 22sp + 白色前景 |
| 背景 | `_kBg = Color(0xFFF5F5F5)` |
| AgentFab | 注册 `currentPath: AppRoutes.yibaoHub` |
| 底部导航 | `ElderBottomNav(currentIndex: 0)` |

### 卡片列表（垂直排列，全宽，间距 12px）

```
┌─────────────────────────────────────────┐
│ 💊  医保缴费                            │
│     城乡居民医保年度缴费                ▶ │  ← 橙色边框/主色卡
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ 🔍  医保查询                            │
│     查询账户余额和状态                  ▶ │  ← 白色卡，次级样式
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│ 📄  缴费记录                            │
│     查看历史缴费明细                    ▶ │  ← 白色卡，灰色文字
└─────────────────────────────────────────┘
```

- 每卡高度：72px（适老触控区）
- 标题：18sp，`#333333`
- 副标题：14sp，`#999999`
- 右箭头：`Icons.chevron_right`，`#CCCCCC`
- 「医保缴费」卡额外视觉强调：左侧 4px 橙色竖条，或卡片 `border: Border.all(color: _kOrange, width: 1.5)`

---

## 五、YibaoJiaofeiPage 字段规范（修改现有页面）

### 字段清单（从上到下）

#### 字段 1：缴费对象（普通字段，现有）
- 类型：`DropdownButtonFormField<String>`
- 选项：`['本人', '配偶', '子女']`
- 默认值：`'本人'`
- **变更**：选择「配偶」或「子女」时，下方动态展开「被缴费人信息」区块（见字段 6、7）

#### 字段 2：险种（普通字段，新增）
- 类型：`DropdownButtonFormField<String>`（插入在「缴费对象」之后）
- 选项：`['城乡居民医保', '灵活就业人员医保']`
- 默认值：`'城乡居民医保'`
- 说明文字（字段下方，14sp 灰色）：
  - 城乡居民医保：`按年缴费，截止日期每年 12 月 31 日`
  - 灵活就业人员医保：`按月缴费，次月生效`

#### 字段 3：缴费年度（普通字段，现有）
- 无变化

#### 字段 4：缴费档次（普通字段，替代原「缴费金额」自由输入）
- 类型：`DropdownButtonFormField<_JiaofeiDangci>`
- **城乡居民医保 2026年度档次（mock 数据）**：
  - 第一档 — ¥ 380 元/年
  - 第二档 — ¥ 660 元/年
  - 第三档 — ¥ 980 元/年
- **灵活就业人员医保 2026年度**：
  - 月缴标准 — ¥ 450 元/月
  - （只有一档，默认选中）
- **联动**：选定档次后，下方「缴费金额」字段自动填入对应金额（只读展示）
- AgentElementRegistry key `select_jiaofei_dangci`（新增）

#### 字段 4b：缴费金额展示（普通字段，现有字段改为只读）
- 类型：只读 `Container`（非 TextField），展示选定档次对应金额
- 样式：`¥ 380.00`，18sp，`#333333`，橙色下划线或灰色卡片背景
- **不再允许手动输入**（原自由输入改为联动只读，消除异常输入风险）
- AgentElementRegistry key `input_jiaofei_jine` 保留（代理可选档次，金额联动）

#### 字段 5：身份证号（**敏感字段**，现有，需修改）

**展示态与输入态双状态设计：**

```
┌─────────────────────────────────────────┐
│ 身份证号                                │
│ [ 330****2518              ] [编辑]     │  ← 已填写后失焦状态
└─────────────────────────────────────────┘

┌─────────────────────────────────────────┐
│ 身份证号                                │
│ [ 330105199001012518      ___]          │  ← 输入态（TextField 聚焦）
└─────────────────────────────────────────┘
```

- **实现方式**：
  - `_idFocused` 状态变量（FocusNode + listener）
  - 聚焦时：显示 TextField，明文内容
  - 失焦且有值时：显示只读行（脱敏文本 + 「编辑」按钮）
  - 点击「编辑」按钮：清空 `_idController`，重新 requestFocus
  - 脱敏公式：`前3位 + '****' + 后4位`（共11字符，避免长度泄露实际位数）
- **键盘类型**：`TextInputType.text`（身份证末位可为 X）
- **长度限制**：`maxLength: 18`，`counterText: ''`（隐藏计数器）
- AgentElementRegistry key `input_id_card` 保留

#### 字段 6：被缴费人姓名（条件字段，普通，新增）
- **出现条件**：`_targetPerson == '配偶' || _targetPerson == '子女'`
- 类型：`TextField`，明文
- 校验：非空
- 标签：`被缴费人姓名`
- AgentElementRegistry key `input_daili_name`（新增）

#### 字段 7：被缴费人证件号（条件字段，**敏感**，新增）
- **出现条件**：同字段 6
- 规则：与字段 5 完全相同（双状态脱敏设计）
- 标签：`被缴费人证件号`
- AgentElementRegistry key `input_daili_idcard`（新增）

#### 条件区块视觉设计（字段 6 + 7 的容器）
- `AnimatedContainer` 展开/收起，高度从 0 过渡到内容高度（200ms）
- 用虚线橙色边框（`BorderStyle.dashed`）的圆角卡框住，与「本人信息」区视觉区分
- 区块标题：`被缴费人信息`（14sp 橙色）

#### 提交按钮（现有）
- 按钮文字：`_canSubmit ? '去支付' : '请先填写完整信息'`（保留现有逻辑）
- **变更**：`onPressed: _canSubmit ? () => context.push(AppRoutes.yibaoJiaofeiConfirm) : null`
- `_canSubmit` 校验需更新：
  - 加入 `_dangci != null`（档次非空）
  - 加入 `_xianzhong != null`（险种非空）
  - 若选代缴：`_dailiName.isNotEmpty && _dailiId.length == 18`

---

## 六、PayConfirmPage 页面规范（新建）

| 属性 | 值 |
|------|-----|
| 路由 | `/service/yibao-jiaofei/confirm` |
| AppBar | 橙色底 + "确认缴费" + 22sp |
| 进入方式 | `context.push()`，从 YibaoJiaofeiPage 「去支付」按钮跳入 |
| AgentFab | **不展示**（支付确认页，代理不干预） |

### 页面内容（从上到下）

```
┌── AppBar: 确认缴费 ──────────────────────┐

┌── 缴费摘要（白色圆角卡）─────────────────┐
│  险种          城乡居民医保              │
│  缴费年度      2026年度                  │
│  缴费对象      本人                      │
│  缴费金额      ¥ 380.00  ← 橙色，24sp   │
└──────────────────────────────────────────┘

┌── 缴费人信息（白色圆角卡）───────────────┐
│  姓名          *小明                     │
│  证件号        330****2518               │
└──────────────────────────────────────────┘

┌── 支付方式（白色圆角卡）─────────────────┐
│ 选择银行卡                               │
│ ○ [工行图标] 中国工商银行 尾号 1234      │
│ ● [中行图标] 中国银行 尾号 5678  ← 选中 │
│                                          │
│ + 添加银行卡（灰色文字链接）             │
└──────────────────────────────────────────┘

  ⓘ 缴费完成后不支持退款，请确认信息无误
     （14sp，灰色，居中）

┌── 确认支付 ¥380.00 ─────────────────────┐
│           橙色实心按钮，56px             │
└──────────────────────────────────────────┘
```

### 交互
- 「添加银行卡」→ `SnackBar('请前往银行柜台或银行 App 绑定银行卡')`
- 「确认支付」→ `context.push(AppRoutes.yibaoJiaofeiPay, extra: {'bank': selectedBank, 'amount': amount})`

---

## 七、PayPasswordPage 页面规范（新建）

| 属性 | 值 |
|------|-----|
| 路由 | `/service/yibao-jiaofei/pay` |
| AppBar | 橙色底 + "输入支付密码" + 22sp |
| AgentFab | **不展示**（密码页严禁代理干预，安全红线） |

### 页面内容（从上到下）

```
┌── AppBar: 输入支付密码 ──────────────────┐

  中国银行 尾号5678
  （14sp，灰色，居中）

  ¥ 380.00
  （24sp，橙色，Bold，居中）

  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐
  │● │ │● │ │  │ │  │ │  │ │  │
  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘
  （6格密码框，50×50，圆点掩码，已输入格橙色边框）

  ┌───┬───┬───┐
  │ 1 │ 2 │ 3 │
  ├───┼───┼───┤
  │ 4 │ 5 │ 6 │
  ├───┼───┼───┤
  │ 7 │ 8 │ 9 │
  ├───┼───┼───┤
  │取消│ 0 │ ⌫ │
  └───┴───┴───┘
  （数字键盘，每键 72×56，适老触控区）

  忘记密码（14sp，灰色，居中文字链接）
```

### 交互逻辑（mock）

```
密码 == '123456'
  → context.pushReplacement(AppRoutes.yibaoJiaofeiResult, extra: {success: true})

密码 != '123456'，剩余次数 > 0
  → 密码框抖动动画（shake）
  → 清空输入
  → 错误提示文字："密码错误，还可尝试 N 次"（红色，14sp）

剩余次数 == 0
  → SnackBar: '支付密码已锁定，请 24 小时后重试'
  → 按钮替换为「返回」，不允许再次输入

「取消」键
  → context.pop() 回 PayConfirmPage

「忘记密码」
  → SnackBar: '请携带身份证前往当地社保服务中心重置密码'
```

---

## 八、PayResultPage 页面规范（新建）

| 属性 | 值 |
|------|-----|
| 路由 | `/service/yibao-jiaofei/result` |
| AppBar | 橙色底 + "缴费结果" + 22sp |
| 进入方式 | `context.pushReplacement()`（不可返回到密码页） |
| AgentFab | 注册（结果页可展示"完成了！需要其他帮助吗？"） |

### 成功态

```
  ✅
  （Icon: check_circle，72px，Color(0xFF52C41A)）

  缴费成功
  （24sp，#333333，居中）

  ┌── 缴费详情（白色圆角卡）────────────────┐
  │  险种      城乡居民医保                 │
  │  缴费年度  2026年度                     │
  │  金额      ¥ 380.00                     │
  │  缴费时间  2026-05-20 14:32:05          │
  │  流水号    ZLS20260520143205            │
  └──────────────────────────────────────────┘

  ┌── 查看电子凭证 ─────────────────────────┐
  │        空心橙色按钮（次级）              │
  └──────────────────────────────────────────┘

  ┌── 返回首页 ─────────────────────────────┐
  │        橙色实心按钮                      │
  └──────────────────────────────────────────┘
```

### 交互
- 「查看电子凭证」→ `SnackBar('电子凭证生成中，请稍后在「缴费记录」中查看')`
- 「返回首页」→ `context.go(AppRoutes.elderHome)`（清空支付页栈）

---

## 九、字段敏感度统一规范（全局适用）

| 字段类型 | 脱敏格式 | 是否可展开 | 编辑方式 | 适用页面 |
|---------|---------|-----------|---------|---------|
| 姓名 | `*小明`（首字打码） | 否（只读） | 不可编辑 | 查询/确认页 |
| 身份证号（展示） | `330****2518`（前3+4星+后4） | 临时展开（点「编辑」清空重填） | 点击→清空→明文输入 | 缴费表单 |
| 身份证号（查询结果） | `3****************3`（首尾各1位） | 否（只读） | 不可编辑 | 查询页（现有） |
| 银行卡号 | `中行 尾号5678` | 否（只读） | 不可编辑 | 支付确认/结果页 |
| 手机号 | `138****5678`（前3+4星+后4） | 否 | 不可编辑 | （预留） |
| 支付密码 | 圆点 ● | **绝不展示** | 6位数字键盘，无「显示」切换 | 支付密码页 |
| 缴费金额 | `¥ 380.00`（明文） | — | 档次联动只读 | 全链路 |

> **注**：yibaoQuery 的身份证脱敏格式（首尾各1位）沿用现有，不强制统一，两者在不同场景（只读查询 vs 填写表单）语义不同，差异合理。

---

## 十、shebaoJiaona 视觉修复（P2，最小改动）

| 属性 | 当前 | 修正 |
|------|------|------|
| `AppBar.backgroundColor` | `Colors.white` | `_kOrange`（橙色，对齐全局规范） |
| `AppBar.title` fontSize | `16` | `22`（对齐全局规范） |
| `AppBar.foregroundColor` | （默认暗色） | `Colors.white` |
| Banner 文案「浙江税务」 | 保留 | 不改（正确，社保由税务代征） |
| 9 宫格死按钮 | `onTap: null` × 7 | 改为 `onTap: () => _showTodo(context)` SnackBar 占位（消除灰色视觉混乱） |
| selfPay Tab 死按钮 | `onTap: () {}` | 改为 `onTap: () => _showTodo(context)` |

---

## 十一、路由变更汇总（供 frontend 对照 router.dart）

| 操作 | 路由 | 常量名 | 页面类 |
|------|------|--------|--------|
| 新增 | `/service/yibao-hub` | `AppRoutes.yibaoHub` | `YibaoHubPage`（新建文件） |
| 新增 | `/service/yibao-jiaofei/confirm` | `AppRoutes.yibaoJiaofeiConfirm` | `PayConfirmPage`（新建文件） |
| 新增 | `/service/yibao-jiaofei/pay` | `AppRoutes.yibaoJiaofeiPay` | `PayPasswordPage`（新建文件） |
| 新增 | `/service/yibao-jiaofei/result` | `AppRoutes.yibaoJiaofeiResult` | `PayResultPage`（新建文件） |
| 现有 | `/service/yibao-jiaofei` | `AppRoutes.yibaoJiaofei` | `YibaoJiaofeiPage`（修改） |
| 现有 | `/service/shebao-jiaona` | `AppRoutes.shebaoJiaona` | `ShebaoJiaonaPage`（视觉修复） |

---

## 十二、优先级建议（供 frontend 排期）

### P0（本会话必修，支撑演示）
1. 新建 `YibaoHubPage`，串联 elderHome 「健康医保」和「浙里医保」入口
2. `elder_home.dart` 两处入口改跳 `yibaoHub`
3. `search_page.dart:238` 「医保查询」改跳 `yibaoQuery`
4. `search_result_page.dart:238` 「浙里医保」card 改跳 `yibaoJiaofei`
5. `YibaoJiaofeiPage` 「去支付」接 `PayConfirmPage`（新建）
6. 新建 `PayPasswordPage` + `PayResultPage`（mock 密码 123456）

### P1（答辩前修）
7. 扩充 `_isMedicalPay` 别名表，新增 `_isMedicalQuery` 分支
8. `YibaoJiaofeiPage` 新增险种 Dropdown + 档次 Dropdown（替代自由输入金额）
9. 身份证号双状态脱敏（输入态明文 + 失焦脱敏）
10. 缴费对象选配偶/子女时展开被缴费人字段

### P2（时间允许修）
11. `shebaoJiaona` AppBar 配色修复
12. `shebaoJiaona` 死按钮改 SnackBar 占位
13. `YibaoHubPage` 缴费记录卡接实际 yibao-records 页
