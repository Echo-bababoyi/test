# UI/UX 适老化审查报告

**审查日期**：2026-05-08  
**审查标准**：工信部《APP 适老化通用设计规范》+ 国际最佳实践  
**设计基准**：design_tokens.dart（AppFontSize / Spacing / AppColors）

---

## 字号参照表（design_tokens.dart）

| 常量 | 值 |
|------|----|
| tiny | 11sp |
| small | 12sp |
| caption | 13sp |
| body | 14sp |
| bodyLarge | 16sp |
| subtitle | 18sp |
| title | 20sp |
| elderBody | 18sp |
| elderTitle | 24sp |

工信部要求：适老版主要文字 ≥ 18sp；触控区主要组件 ≥ 60×60dp（适老版首页 ≥ 48×48dp）；一般文本对比度 ≥ 4.5:1；大字体（>18sp）≥ 3:1。

---

## elder_home.dart — 长辈版首页

### ✓ 合规项
- 主要内容文字使用 `AppFontSize.elderBody`（18sp）和 `AppFontSize.elderTitle`（24sp），符合适老标准
- 服务卡图标容器 56×56dp，高于 48dp 适老首页要求
- 网格项使用 `InkWell`，有水波纹反馈
- 区块间距使用 Spacing.md（12dp）～Spacing.lg（16dp），留白合理

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | AppBar "个人频道"按钮文字使用 `AppFontSize.small`（12sp），低于最小字号要求 | 12sp | ≥ 18sp | P1 | 改为 AppFontSize.elderBody（18sp）或去掉文字仅用图标 |
| 2 | AppBar 内同步图标 `size: 14`，过小；与文字组成的可点击行无 `InkWell` 包裹，无反馈且无明确触控区 | 图标 14dp，触控区不明确 | 触控区 ≥ 44×44dp | P1 | 用 `InkWell` 包裹整行并设置 `minimumSize` ≥ 44×44dp |
| 3 | _EldToolBarItem 使用 `GestureDetector` 而非 `InkWell`，无水波纹触觉反馈 | GestureDetector | InkWell（有水波纹） | P2 | 改为 InkWell |
| 4 | Tab 标签（"热门服务"/"我的常用"/"我的订阅"）使用 `AppFontSize.body`（14sp），低于适老版 18sp 要求 | 14sp | ≥ 18sp | P1 | 改为 AppFontSize.elderBody（18sp） |
| 5 | "查看全部 ›" 按钮文字 14sp，且容器仅 padding 无明确高度，触控区偏小 | 14sp，触控区 < 44dp | ≥ 44×44dp，文字 ≥ 18sp | P1 | 加 `height: 44`，字号改为 18sp |
| 6 | 政务服务热线 "去拨打" 按钮为 Container + Text，无 InkWell，无视觉反馈；文字 14sp | 14sp，无反馈 | ≥ 18sp，InkWell | P1 | 改为 `OutlinedButton`，字号改 18sp |
| 7 | 线下服务区域的 "附近有 37 家大厅" 文字、位置图标（size: 16）等辅助文字 14sp | 14sp | ≥ 18sp | P2 | 提升到 18sp 或明确定义为辅助说明并保持对比度达标 |
| 8 | _EldOfficeItem 中 "空闲" 状态标签文字使用 `AppFontSize.small`（12sp），绿色小字对白色背景对比度约 4:1 | 12sp | ≥ 18sp（适老版）；对比度 ≥ 4.5:1 | P1 | 字号改为 14sp 以上并校验对比度 |
| 9 | 页脚 "浙里办 伴你一生大小事" 使用 `AppFontSize.caption`（13sp）+ 斜体，对比度偏低（灰色文字在白底） | 13sp | 装饰性文字可豁免，但老年人可能误认为可点击 | P2 | 字号改为 14sp，去掉斜体，或明确与正文区分 |
| 10 | 蓝色系服务卡（住址变动/权益记录，Color(0xFF3B82F6) 图标色）图标在浅色背景上，无辅助文字说明，老年人难以辨识 | 无文字说明 | 国际实践：避免纯图标无文字 | P2 | 已有标签文字，合规；但图标色为蓝色系，在白背景对比度约 3.8:1（接近红线），建议加深图标底色 |

---

## login_page.dart — 登录页

### ✓ 合规项
- 主按钮"登录"高度通过 `padding: vertical 14`，预估 ≥ 48dp；文字 18sp
- 输入框文字 fontSize 20sp，清晰易读
- 条款弹窗按钮使用 ElevatedButton/FilledButton，有系统水波纹反馈
- 弹窗关闭逻辑通过"不同意"和"同意并继续"处理，无隐蔽关闭

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 输入框标签"手机号/用户名/身份证"使用 `AppFontSize.body`（14sp） | 14sp | ≥ 18sp | P1 | 改为 18sp |
| 2 | 辅助链接行"新用户注册"/"忘记密码"/"登录遇到问题?" 均为 fontSize 13sp，且 `tapTargetSize` 未设置，触控区极小 | 13sp，无明确触控区 | ≥ 18sp；触控区 ≥ 44×44dp | P0 | 字号改为 18sp；用 TextButton 包裹并设置 `minimumSize: Size(88, 44)` |
| 3 | "其他登录方式"分割线文字 fontSize 12sp | 12sp | 装饰性文字，但在蓝色背景上（`0xFFDEEAF8`）需确认对比度 | P2 | 提升至 14sp；计算对比度 |
| 4 | "其他证件"文字 fontSize 14sp，且无触控反馈 | 14sp | ≥ 18sp，需有可点击状态 | P1 | 改为 TextButton，字号 18sp |
| 5 | 条款勾选框为 Container 装饰圆，宽高 18×18dp，触控区不足；且没有实际状态切换逻辑（注释说"装饰性"），但视觉上看起来可操作 | 18×18dp | ≥ 44×44dp | P1 | 若为装饰性则去掉或换为 `Checkbox` 并设置触控区 ≥ 44dp；勾选状态与登录按钮联动（PRD 要求） |
| 6 | 个人/法人 Tab 字号 fontSize 15sp，点击区域无明确大小约束，未用 InkWell 包裹（直接是 Column） | 15sp | ≥ 18sp；触控区 ≥ 44dp | P1 | 改为 18sp，外层用 InkWell 并设高度 44dp |
| 7 | 登录页背景 `Color(0xFFDEEAF8)`（浅蓝色）上欢迎文字颜色 `Color(0xFF0D1B6E)`（深蓝），对比度约 9:1，合规；但标题下方白卡内蓝色文字链（standardPrimary `#2D74DC`）在白底对比度约 3.5:1，小于 4.5:1 要求 | 对比度 ~3.5:1 | ≥ 4.5:1 | P0 | 将蓝色链接文字加深（如 `#1A5BAF`）或增加下划线以降低对比依赖 |

---

## face_auth_page.dart — 刷脸页

### ✓ 合规项
- 主按钮"开始认证" minimumSize `Size.fromHeight(52)` = 52dp 高，符合 ≥ 44dp
- 认证中状态标题"拿起手机，眨眨眼" fontSize 24sp，清晰
- 双按钮（主 + 次）布局，有明确功能区分
- 弹窗内按钮使用系统 ElevatedButton/FilledButton，有反馈

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 卡片内姓名 "**澄" fontSize 16sp | 16sp | ≥ 18sp | P1 | 改为 18sp |
| 2 | "为保障您的账号隐私与信息安全…" 说明文字 fontSize 13sp，颜色 `textSecondary`（`#999999`）在白底对比度约 2.85:1 | 13sp，对比度 ~2.85:1 | ≥ 18sp；对比度 ≥ 4.5:1 | P0 | 字号改为 16sp 以上；文字颜色改为 `#666666` 或更深 |
| 3 | "眨眨眼"提示文字在人脸扫描圆形内，颜色 white + fontSize 14sp，白色文字在 `Color(0xFFD6E8F8)`（浅蓝）背景上对比度约 1.6:1，极差 | 对比度 ~1.6:1 | ≥ 4.5:1 | P0 | 改为深色文字（`#333333`）或为文字加深色背景条 |
| 4 | 页脚 "浙里办 | 伴你一生大小事" fontSize 12sp，`standardPrimary` 蓝在浅蓝背景上对比度 < 3:1 | 12sp | 装饰性可豁免，但在浅蓝背景上不可读 | P2 | 移除或增大至 14sp，改深色 |
| 5 | 按钮文字"开始认证"/"其他方式认证" fontSize 16sp，低于主要按钮 ≥ 18sp 要求 | 16sp | ≥ 18sp | P1 | 改为 18sp |
| 6 | 其他认证方式弹窗（`_OtherAuthContent`）ListTile 中 "手机短信验证"/"密码登录" 使用默认字号（Material 默认 14~16sp）；未显式设置 ≥ 18sp | 默认 ~16sp | ≥ 18sp | P1 | 显式设置 `style: TextStyle(fontSize: 18)` |

---

## verify_page.dart — 验证码页

### ✓ 合规项
- 主按钮"确认" fontSize 18sp，高度通过 `padding: vertical 14`，满足触控要求
- 输入框高度明确设 56dp（SizedBox height: 56）
- 错误提示使用红色文字（非仅颜色，有文字内容说明），符合无障碍原则
- 倒计时提示有文字说明，不仅依靠颜色

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 副标题"输入手机号并获取验证码完成登录" 使用 `AppFontSize.body`（14sp） | 14sp | ≥ 18sp | P1 | 改为 18sp |
| 2 | 错误提示"请输入11位手机号" 使用 `AppFontSize.caption`（13sp），颜色 `#FF3B30`（红）在白底对比度约 4.5:1，刚好达标，但字号不足 | 13sp | ≥ 18sp（适老版重要信息） | P1 | 改为 16sp 以上 |
| 3 | 倒计时辅助提示（"重新发送 N 秒"）fontSize `AppFontSize.body`（14sp），图标 size 14dp | 14sp | ≥ 18sp | P2 | 改为 16sp，图标改为 18dp |
| 4 | 发送验证码按钮（OutlinedButton）文字 `AppFontSize.bodyLarge`（16sp）；宽度随输入框右侧动态，最窄时触控区可能 < 44dp | 16sp | ≥ 18sp；触控区 ≥ 44×44dp | P1 | 改为 18sp；设置 `minimumSize: Size(88, 44)` |

---

## search_page.dart — 搜索页

### ✓ 合规项
- 语音输入浮层麦克风按钮 64×64dp（Container width/height: 64），超过 60dp 适老标准
- 快捷服务图标容器 44×44dp，符合 ≥ 44dp

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 搜索框高度仅 36dp（Container height: 36），文字 fontSize 15sp | 36dp，15sp | 触控区 ≥ 44dp；文字 ≥ 18sp | P0 | 高度改为 44dp；字号改为 18sp |
| 2 | 搜索框内 suffixIcon（mic/cancel）图标 size 18dp，触控热区极小（仅 18×18dp 的 GestureDetector） | 18dp，触控区约 18×18dp | 触控区 ≥ 44×44dp | P0 | 用 `IconButton` 替代 `GestureDetector`，默认触控区 48×48dp |
| 3 | 取消按钮设置了 `tapTargetSize: MaterialTapTargetSize.shrinkWrap` 和 `minimumSize: Size.zero`，主动压缩了触控区 | 触控区约为文字大小 | ≥ 44×44dp | P0 | 去掉 shrinkWrap 限制，或设置 `minimumSize: Size(60, 44)` |
| 4 | "最近搜索" 右侧"清空"按钮同样设置了 shrinkWrap，触控区极小 | 同上 | ≥ 44×44dp | P1 | 改为标准 OutlinedButton 触控区 |
| 5 | 推荐 Pill 标签 `_RecommendPill` 文字 `AppFontSize.caption`（13sp） | 13sp | ≥ 18sp | P1 | 改为 AppFontSize.body（14sp）最低，建议 16sp |
| 6 | "我的常用" 标题下快捷项文字使用 `AppFontSize.body`（14sp），但适老版应用 ≥ 18sp | 14sp | ≥ 18sp | P1 | 改为 18sp |
| 7 | 语音输入浮层"您可以这样说："文字 `AppFontSize.subtitle`（18sp）合规；但示例文字 `AppFontSize.bodyLarge`（16sp）低于适老要求 | 16sp | ≥ 18sp | P2 | 改为 18sp |

---

## search_result_page.dart — 搜索结果页

### ✓ 合规项
- 搜索结果区 `_SectionHeader` 字号 18sp，合规
- ServiceItem 有 InkWell 水波纹反馈

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 搜索框同 search_page（height: 36dp，fontSize: 15sp），见搜索页 #1 | 36dp，15sp | ≥ 44dp；≥ 18sp | P0 | 同 search_page 修复 |
| 2 | Tab 行（综合/服务/办事/政策）fontSize 15sp，点击区高度仅 Spacing.sm × 2 + 文字高度，约 30dp | 15sp，~30dp | ≥ 18sp；触控区 ≥ 44dp | P1 | 字号改 18sp，`padding: symmetric(vertical: 12)` 确保 44dp |
| 3 | 服务结果图标 36×36dp（Container width/height: 36），低于适老标准 | 36dp | 适老版首页 ≥ 48dp；一般 ≥ 44dp | P1 | 改为 44×44dp |
| 4 | 服务 tag 芯片 fontSize 12sp，`textSecondary`（#999999）对白底对比度约 2.85:1 | 12sp，对比度 ~2.85:1 | ≥ 18sp；对比度 ≥ 4.5:1 | P1 | 字号改 14sp，颜色改深（#666666） |
| 5 | 部门名称 fontSize 12sp，同上色彩问题 | 12sp | ≥ 18sp | P1 | 改为 14sp 以上 |
| 6 | `_AffairItem` 文字 fontSize 15sp，且无 InkWell 包裹（纯 Padding+Text），不可点击状态不明确 | 15sp，无反馈 | ≥ 18sp；可点击元素需有反馈 | P1 | 改为 ListTile 或 InkWell，字号 18sp |
| 7 | "查看更多搜索结果" 文字 fontSize 14sp，`textSecondary` 色，无 InkWell | 14sp，无反馈 | ≥ 18sp | P2 | 改为 TextButton，字号 18sp |

---

## shebao_jiaona_page.dart — 社保费缴纳主页

### ✓ 合规项
- Banner 标题"社保费缴纳" fontSize 28sp，大于适老要求
- 服务图标容器 56×56dp（width/height: 56），符合 ≥ 48dp
- 有 InkWell 包裹服务图标，有反馈

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | AppBar 标题文字 fontSize 16sp | 16sp | ≥ 18sp | P1 | 改为 18sp |
| 2 | "浙江税务" 副标题 fontSize 16sp，颜色 `Colors.white70`，在蓝色渐变（`#2D74DC`）背景上对比度约 3.8:1，低于 4.5:1 | 16sp，对比度 ~3.8:1 | 对比度 ≥ 4.5:1（字号 < 18sp）；≥ 3:1（≥ 18sp） | P1 | 将文字颜色改为纯白（`Colors.white`），对比度可达 ~4.6:1 |
| 3 | 服务图标标签文字 fontSize 12sp（`style: TextStyle(fontSize: 12)`） | 12sp | ≥ 18sp | P0 | 改为 AppFontSize.elderBody（18sp） |
| 4 | 底部说明文字 fontSize 13sp，`textSecondary` 色 | 13sp | 说明性文字：建议 ≥ 14sp；对比度 ≥ 4.5:1 | P2 | 改为 14sp，颜色加深至 #666666 |
| 5 | "我为自己缴" 子页用户信息栏中证件号 fontSize 13sp，白色字在蓝色（#2D74DC）背景：对比度 ~4.5:1，刚好达标，但字号不足 | 13sp | ≥ 18sp | P1 | 改为 16sp 以上 |
| 6 | 温馨提示区关闭图标 `Icons.close`（size 16dp），触控区约 16×16dp | 16dp | ≥ 44×44dp | P0 | 改为 `IconButton`，padding 保证 44dp |
| 7 | 温馨提示文字 fontSize 12sp | 12sp | ≥ 18sp（适老版）；即便为提示也应 ≥ 14sp | P1 | 改为 16sp |
| 8 | Tab 行（"全部"/"城乡居民"/"灵活就业"）fontSize 15sp | 15sp | ≥ 18sp | P1 | 改为 18sp |
| 9 | 缴费记录页下拉筛选 `_DropdownChip` 文字 fontSize 15sp，触控区无明确约束 | 15sp | ≥ 18sp | P1 | 改为 18sp；用 DropdownButton 标准组件确保触控区 |

---

## shebao_query_page.dart — 社保查询主页

### ✓ 合规项
- 个人信息卡渐变头（蓝色）上文字使用纯白色，主要字段 fontSize 14sp 在深蓝渐变上对比度 > 7:1，合规
- 险种卡操作按钮为 TextButton，触控区由 Flutter 保证 ≥ 48dp

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | AppBar 标题 fontSize 16sp | 16sp | ≥ 18sp | P1 | 改为 18sp |
| 2 | 个人信息卡内"姓名"/"证件号码" 标签 fontSize 14sp；数值 fontSize 14sp/13sp | 14sp/13sp | ≥ 18sp | P0 | 改为 18sp（标签）和 16sp 以上（值） |
| 3 | 险种信息标题 fontSize 16sp | 16sp | ≥ 18sp | P1 | 改为 18sp |
| 4 | 险种卡头（深蓝紫渐变 #5C4A9E→#3B2D8B）险种名称 fontSize 15sp；白色文字在深紫背景对比度 > 7:1 合规，但字号不足 | 15sp | ≥ 18sp | P1 | 改为 18sp |
| 5 | 险种卡参保状态文字 fontSize 13sp，`textSecondary`（#999999）在白底对比度约 2.85:1 | 13sp，对比度 ~2.85:1 | ≥ 18sp；对比度 ≥ 4.5:1 | P0 | 字号改 16sp；颜色改为 #666666 |
| 6 | 险种卡操作按钮文字"基本信息"/"缴费信息" fontSize 14sp | 14sp | ≥ 18sp | P1 | 改为 18sp |

---

## mine_page.dart — 我的页面

### ✓ 合规项
- 用户名 fontSize 18sp，合规
- 退出登录按钮 height: 52dp，fontSize 18sp，合规
- ListTile（设置/关于）系统组件，触控区由 Flutter 保证

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | "高级实名"标签 fontSize 11sp，颜色 `#FFB300`（橙黄）在浅黄（#FFF3E0）背景对比度约 1.8:1，极差 | 11sp，对比度 ~1.8:1 | ≥ 18sp；对比度 ≥ 4.5:1 | P0 | 字号改为 14sp+；背景颜色加深或文字加深至 #8A6000 以达标 |
| 2 | "编辑资料" 行 fontSize 12sp，颜色 `textSecondary`（#999999）在白底约 2.85:1 | 12sp | ≥ 18sp；对比度 ≥ 4.5:1 | P0 | 字号改 16sp；颜色改 #666666 |
| 3 | 活动图标区（办事记录/我的草稿等）图标容器 52×52dp（符合），但标签文字 fontSize 13sp | 13sp | ≥ 18sp | P1 | 改为 16sp 以上 |
| 4 | 证照卡片内文字 fontSize 13sp，白色在渐变绿/蓝背景上（较浅渐变起点）对比度最低约 3.5:1（浅绿渐变 #A5D6A7 背景） | 13sp，对比度 ~3.5:1 | 字号 ≥ 18sp；对比度 ≥ 3:1（大字）/ ≥ 4.5:1（小字） | P1 | 字号改 16sp；加深卡片渐变起始色或为文字加阴影 |
| 5 | "我的证照"/"我的信息"/"服务推荐"/"我的管理" 区块标题 fontSize 16sp | 16sp | ≥ 18sp | P1 | 改为 18sp |
| 6 | "全部 ›" 辅助链接 fontSize 13sp，触控区极小（仅文字区域） | 13sp | ≥ 18sp；触控区 ≥ 44dp | P1 | 改为 TextButton，字号 16sp，minimumSize 设 44dp |
| 7 | 管理/推荐图标文字（_ManageIcon/_RecommendIcon/_InfoIcon/_ActivityIcon）fontSize 13sp | 13sp | ≥ 18sp | P1 | 统一改为 14sp（辅助标签可豁免），建议 16sp |
| 8 | AppBar "切换" 按钮 fontSize 13sp，tapTargetSize: shrinkWrap，触控区极小 | 13sp，shrinkWrap | ≥ 44dp；文字 ≥ 18sp | P1 | 去掉 shrinkWrap，改为标准按钮触控区 |

---

## yibao_jiaofei_page.dart — 医保缴费表单

### ✓ 合规项
- 表单字段标签 `_FieldLabel` fontSize 18sp，合规
- 输入框 / 下拉框 fontSize 18sp，合规
- 主按钮高度 56dp，fontSize 20sp，显著满足适老要求
- 错误提示"请输入18位身份证号" fontSize 15sp（接近合规，颜色红色对比度足）

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | AppBar 标题 fontSize 22sp 合规；但 AppBar 本体背景橙色（#FF6D00）上无 back 按钮，用户无法返回（无 leading） | 无返回按钮 | 导航一致性：每个非首页页面应有返回 | P1 | 添加 `leading: BackButton(...)` |
| 2 | 错误提示字号 fontSize 15sp，比适老建议（18sp）偏小 | 15sp | ≥ 18sp | P2 | 改为 16sp 以上 |

---

## pension_query_page.dart — 养老金查询

### ✓ 合规项
- 主按钮"查询" 高度 56dp，fontSize 20sp，合规
- 金额数字 fontSize 36sp，高于最大字体 ≥ 30sp 要求，合规
- 参保状态标签有文字说明（"参保状态：正常"），不仅依赖颜色

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | AppBar 同 yibao_jiaofei，无返回按钮 | 无返回 | P1 | 同上 |
| 2 | 个人信息卡（橙色渐变）内"姓名"/"证件号码"标签 fontSize 15sp，值 fontSize 15sp/14sp | 15sp/14sp | ≥ 18sp | P0 | 改为 18sp |
| 3 | "本月养老金"标签 fontSize 18sp 合规；"2026年5月" 日期 fontSize 16sp，颜色 `#999999` 在白底对比度约 2.85:1 | 16sp，对比度 ~2.85:1 | 对比度 ≥ 4.5:1 | P1 | 颜色改为 #666666，字号改 18sp |
| 4 | "参保状态：正常" 标签 fontSize 14sp，`#4CAF50`（绿）在浅绿（#E8F5E9）背景对比度约 2.2:1 | 14sp，对比度 ~2.2:1 | ≥ 4.5:1（字号 < 18sp）；≥ 3:1（≥ 18sp） | P1 | 字号改 16sp；文字颜色改为深绿 #2E7D32（对比度在浅绿背景约 4.8:1） |
| 5 | "¥" 符号 fontSize 20sp，但紧接 36sp 数字，视觉重心失衡；单位"元" fontSize 18sp，`#999999` 对白底约 2.85:1 | 元：18sp，#999999 | 对比度 ≥ 4.5:1 | P2 | "元" 颜色改为 #666666 |

---

## elder_bottom_nav.dart — 底部导航

### ✓ 合规项
- 导航项 `_NavItem` 宽 80dp × 高 64dp，超过 60×60dp 适老标准
- 中央助手按钮 60×60dp，符合适老首页 ≥ 48dp 要求；实际 translate(-12) 凸起，视觉面积更大
- 导航文字 fontSize 14sp（可接受，导航标签为辅助说明，图标+文字组合使用）

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 唤醒提示文字"说'小浙'即可唤醒助手" fontSize 12sp，颜色 `#BBBBBB` 在白底对比度约 1.8:1，不可读 | 12sp，对比度 ~1.8:1 | 对比度 ≥ 4.5:1 | P1 | 颜色改为 #888888（对比度约 3.5:1）；字号改 14sp；或整合为导航栏 tooltip |
| 2 | 中央助手按钮使用 `GestureDetector` 而非 `InkWell`/`Material`，无系统级水波纹反馈 | GestureDetector | 可交互元素需有视觉反馈 | P2 | 改为 Material + InkWell 包裹，customBorder: CircleBorder |
| 3 | 导航标签文字 fontSize 14sp，低于适老版 ≥ 18sp 要求 | 14sp | ≥ 18sp | P1 | 改为 16sp（导航标签辅助性，18sp 可能过大挤压图标，建议 16sp）|

---

## agent_panel.dart — 代理面板

### ✓ 合规项
- 文本输入框 height: 48dp，fontSize 18sp，合规
- 发送按钮 48×48dp，合规
- 确认按钮"对的"/"不是" fontSize 16sp，有 padding，触控区充足
- 面板滑出动画 300ms（slideController duration: 300ms），符合 ≤ 300ms 要求

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | "小浙正在想…" 占位文字 fontSize 15sp，颜色 `#999999` 在 `#F5F5F5`（浅灰）背景对比度约 3.1:1 | 15sp，对比度 ~3.1:1 | 对比度 ≥ 4.5:1 | P1 | 字号改 16sp；颜色改 #666666 |
| 2 | mini bar（执行态缩小版）"小浙正在帮您操作…" fontSize 16sp 合规；但展开按钮 `IconButton`（keyboard_arrow_up）无文字说明，老年用户可能不知如何展开 | 无文字说明 | 可操作元素需有可辨识的视觉提示 | P2 | 在图标旁增加 "展开" 小标签（10sp 可接受，作为辅助） |
| 3 | 草稿提醒卡片"草稿提醒"标签 fontSize 14sp；正文"上次有个未完成的…" fontSize 16sp | 14sp/16sp | ≥ 18sp | P1 | 字号统一改为 18sp |
| 4 | 草稿卡片"不用了"/"继续"按钮 fontSize 15sp | 15sp | ≥ 18sp | P1 | 改为 18sp |
| 5 | "或" 分隔符文字 fontSize 13sp，颜色 `#BBBBBB` 在白底对比度极低 | 13sp，对比度 ~1.8:1 | 装饰性文字可豁免，但应不误导用户 | P2 | 颜色改 #888888，或去掉文字用虚线代替 |
| 6 | "按住说话" 状态文字 fontSize 14sp，颜色 grey，在白底对比度偏低 | 14sp，颜色 grey | ≥ 18sp | P2 | 改为 16sp，颜色 #666666 |

---

## persistent_banner.dart — 登录横幅

### ✓ 合规项
- 有关闭（×）按钮，`constraints: BoxConstraints(minWidth: 32, minHeight: 32)`，触控区偏小但仍可接受
- 流程上允许关闭，不强制引导

### ⚠️ 需优化项

| # | 问题 | 当前值 | 标准要求 | 优先级 | 修复建议 |
|---|------|--------|---------|--------|---------|
| 1 | 横幅文字"登录享受更多服务" fontSize `AppFontSize.caption`（13sp），颜色 `#D0D0D0` 在深灰背景（`#333333`）上对比度约 5.3:1，颜色对比合规，但字号不足 | 13sp | ≥ 18sp | P1 | 改为 AppFontSize.body（14sp）最低；建议 18sp |
| 2 | "立即登录" 按钮 fontSize `AppFontSize.caption`（13sp），padding minimal，触控区偏小 | 13sp，触控区约 28dp 高 | ≥ 18sp；触控区 ≥ 44dp | P0 | 字号改 16sp；padding 改为 vertical: Spacing.sm（8dp）确保 ≥ 44dp 高 |
| 3 | 关闭按钮 × `constraints: minWidth: 32, minHeight: 32`，低于 44dp | 32×32dp | ≥ 44×44dp | P1 | 改为 `BoxConstraints(minWidth: 44, minHeight: 44)` |

---

## 总优化清单（优先级排序）

### P0 — 必须修复（严重阻碍使用，违反强制性规范）

| 编号 | 页面 | 问题 | 影响 |
|------|------|------|------|
| P0-1 | login_page | 辅助链接（注册/忘记密码）字号 13sp + 触控区极小 | 老人无法点击核心入口 |
| P0-2 | login_page | 蓝色链接文字在白底对比度 ~3.5:1，低于 4.5:1 | 老人无法识别文字 |
| P0-3 | face_auth_page | "眨眨眼"提示白色文字在浅蓝背景对比度 ~1.6:1 | 完全不可读 |
| P0-4 | face_auth_page | 说明文字 13sp + 对比度 ~2.85:1（#999999 在白底） | 关键安全说明不可读 |
| P0-5 | search_page | 搜索框高度 36dp（低于 44dp）+ 字号 15sp | 核心交互入口不达标 |
| P0-6 | search_page | 取消按钮 shrinkWrap 压缩触控区至文字大小 | 老人无法点击取消 |
| P0-7 | search_page | 搜索框内 mic/cancel 图标触控区约 18×18dp | 核心功能入口无法触达 |
| P0-8 | shebao_jiaona | 服务图标标签文字 fontSize 12sp | 主要功能入口字号不足 |
| P0-9 | shebao_jiaona | 温馨提示关闭图标 size 16dp，触控区约 16dp | 无法关闭提示 |
| P0-10 | shebao_query | 个人信息卡字段字号 13~14sp | 关键身份信息不可读 |
| P0-11 | shebao_query | 险种参保状态文字 13sp + 对比度 ~2.85:1 | 核心状态信息不可读 |
| P0-12 | mine_page | "高级实名"标签 11sp + 对比度 ~1.8:1 | 实名等级标识不可读 |
| P0-13 | mine_page | "编辑资料"文字 12sp + 对比度 ~2.85:1 | 操作入口字号+对比双不达标 |
| P0-14 | pension_query | 个人信息卡字段 15sp | 关键身份信息不达标 |
| P0-15 | persistent_banner | "立即登录"按钮 13sp + 触控区约 28dp | 登录引导主按钮无法点击 |
| P0-16 | search_result | 搜索框同 search_page 问题 | 同上 |

### P1 — 重要修复（影响使用流畅度，应在下个迭代内修复）

| 编号 | 页面 | 问题 |
|------|------|------|
| P1-1 | elder_home | "个人频道"字号 12sp；Tab 标签 14sp；工具行无 InkWell；"查看全部"触控区不足 |
| P1-2 | elder_home | "去拨打"按钮无 InkWell 且字号 14sp |
| P1-3 | elder_home | 办事大厅列表 "空闲" 标签 12sp |
| P1-4 | login_page | 输入框标签 14sp；"个人/法人" Tab 字号 15sp + 无明确触控区；"其他证件" 14sp |
| P1-5 | login_page | 条款勾选框触控区 18×18dp（应 ≥ 44dp） |
| P1-6 | face_auth_page | 姓名 16sp；按钮文字 16sp；弹窗列表未显式设字号 |
| P1-7 | face_auth_page | "浙江税务" 副标题对比度不足（改为纯白可达标） |
| P1-8 | verify_page | 副标题 14sp；错误提示 13sp；发送按钮 16sp |
| P1-9 | search_page | 推荐 Pill 13sp；常用 14sp；"最近搜索"清空按钮 shrinkWrap |
| P1-10 | search_result | Tab 行 15sp + 高约 30dp；图标 36dp；服务 tag 12sp；部门名 12sp；AffairItem 无 InkWell |
| P1-11 | shebao_jiaona | AppBar 16sp；证件号 13sp；提示文字 12sp；Tab 15sp；筛选 15sp |
| P1-12 | shebao_query | AppBar 16sp；险种名 15sp；操作按钮 14sp |
| P1-13 | mine_page | 活动标签 13sp；区块标题 16sp；"全部›" 13sp + 触控区小；AppBar 切换按钮 shrinkWrap |
| P1-14 | yibao_jiaofei | 无返回按钮 |
| P1-15 | pension_query | 无返回按钮；日期文字 16sp + 对比度不足；参保状态颜色不达标 |
| P1-16 | elder_bottom_nav | 唤醒提示对比度 ~1.8:1；导航标签 14sp |
| P1-17 | agent_panel | 占位文字对比度不足；草稿卡字号 14/15sp；发送按钮反馈 |
| P1-18 | persistent_banner | 横幅文字 13sp；关闭按钮 32dp |

### P2 — 体验优化（锦上添花，可在后续版本处理）

| 编号 | 页面 | 问题 |
|------|------|------|
| P2-1 | elder_home | 工具行改 InkWell；页脚去斜体；服务卡图标底色稍加深 |
| P2-2 | login_page | "其他登录方式"分割线文字 12sp 提至 14sp |
| P2-3 | face_auth_page | 页脚文字 12sp 在浅蓝背景不可读 |
| P2-4 | verify_page | 倒计时提示 14sp；图标 14dp |
| P2-5 | search_page | 语音输入示例文字 16sp |
| P2-6 | search_result | "查看更多" 14sp 无 InkWell |
| P2-7 | shebao_jiaona | 底部说明 13sp |
| P2-8 | mine_page | 证照卡片文字 13sp + 浅渐变对比度偏低 |
| P2-9 | pension_query | "元" 字颜色 #999999 对比度约 2.85:1 |
| P2-10 | elder_bottom_nav | 助手按钮改 InkWell 水波纹 |
| P2-11 | agent_panel | mini bar 展开按钮增加文字说明；"或"分隔符改色；"按住说话"字号/颜色 |

---

*共识别 P0 问题 16 个、P1 问题 18 组、P2 问题 11 组。字号不足（< 18sp）和对比度不达标是两类最普遍问题，集中在辅助文字、标签、Toast 类提示区域。*
