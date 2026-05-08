# 浙里办 UI 完整还原 — 需求文档

> **版本**：v1.2（2026-05-08，scene-canvas-v1 复用分析全部完成）
> **作者**：PM
> **目标读者**：前端开发
> **范围**：长辈版全页面对齐原版浙里办，代理核心功能不动

---

## 零、scene-canvas-v1 旧版代码概览

`archive/scene-canvas-v1/lib/` 是上一版原型代码，**已完整实现大多数我们需要补的 UI**，但采用了与当前项目不同的依赖（`flutter_riverpod` 状态管理）。迁移时需要注意：

| 依赖差异 | scene-canvas-v1 | 当前 app/ |
|---------|----------------|-----------|
| 状态管理 | `flutter_riverpod`（`ConsumerWidget`、`ref.watch`） | 无 Riverpod，用 `AuthState.instance` 单例 |
| 路由 | `GoRouter` + `AppRoutes` 常量 | `GoRouter`（同款） |
| 主题 | `design_tokens.dart`（`AppColors`、`Spacing`、`AppFontSize`） | 各页面内联颜色常量 |
| 底部导航 | `ElderBottomNav` + `FloatingActionButton` 分离 | `ElderBottomNav` 含助手按钮（代理功能，不动） |

**迁移策略**：移植时将 `ConsumerWidget` 改为 `StatefulWidget`/`StatelessWidget`，`ref.watch(loginProvider)` 改为 `AuthState.instance.isLoggedIn`，`ref.read(loginBannerDismissedProvider.notifier).dismiss()` 用本地 `setState` 替代。`design_tokens.dart` 中的颜色/间距常量可以直接复制到 `app/lib/theme/` 下复用，避免在每个页面再写内联常量。

---

## 一、总体原则

1. **代理功能冻结**：底部助手按钮（麦克风）、代理面板、WebSocket、草稿箱、操作记录保持不变。
2. **底部导航结构**：原版长辈版是"首页 / 搜索（麦克风）/ 我的"三 Tab。我们将搜索 Tab 替换为助手按钮，维持三 Tab 结构，整体样式对齐原版（橙色主色、圆形麦克风中间按钮）。
3. **适老化主题保留**：字号 ≥ 18sp、橙色主色调、高对比度不动。
4. **路由兼容**：现有路由路径不动，新增页面加新路由。
5. **Mock 数据可用**：所有页面用静态 Mock 数据演示，无需真实 API。

---

## 二、页面级差异清单

### P1 · 标准版首页（`/`，`standard_home.dart`）

| 维度 | 原版浙里办 | 当前实现 | 差距 |
|------|----------|---------|------|
| 定位 | 完整首页，有顶栏、服务分类 8 宫格、热门服务列表、消息横幅、底部五 Tab 导航 | 极简引导页：Logo + "进入长辈版"按钮 + "登录账号"文字按钮 | 差距极大 |
| 长辈版入口 | 顶部工具栏右侧"长辈版"图标按钮（爱心图标） | 大按钮"进入长辈版" | 入口形式不同 |

**结论**：标准版首页不是毕业设计演示重点，入口足够。**保持现状，不改。** 演示从长辈版首页开始。

---

### P2 · 长辈版首页（`/elder`，`elder_home.dart`）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 顶栏 | 橙色背景；左上"西湖区 ▼"；右上"个人频道"胶囊；第二行：扫一扫/消息/常规版 | AppBar "小浙助手" + ConnectionIndicator | `_EldToolBarSection` + AppBar（西湖区 ▼ + 个人频道 + 扫一扫/消息/常规版）**完整实现** | 当前缺工具栏行 |
| 政务服务热线 | 橙色电话圆图标 + "政务服务热线" + "去拨打"圆角按钮 | 无 | `_EldGovHotlineSection` **完整实现** | 当前缺失 |
| 服务 Tab 区 | 三 Tab：热门服务/我的常用/我的订阅；每 Tab 2 项服务卡 + "查看全部 ›" | 2×2 网格卡片，无 Tab | `_EldTabCardSection` + `_EldTabBar`（TabController + IndexedStack）+ 三个 Tab 内容 **完整实现** | 当前无 Tab |
| 线上一站办 | 独立区块 + 2×3 图标网格（健康医保/社会保障/行驶驾驶/身份户籍/文旅体育/查看全部） | 无 | `_EldOnlineServiceSection`（2×3 GridView）**完整实现** | 当前缺失 |
| 线下就近办 | 地图横幅 + "附近 37 家大厅" + 3 条大厅列表（名称/空闲/距离/"去办事"） | 无 | `_EldOfflineServiceSection` **完整实现** | 当前缺失 |
| 授权办 | 2×2 图标网格（老年人优待证/养老保险年限/高龄津贴/法律援助申请） | 无 | `_EldAuthorizedServiceSection` **完整实现** | 当前缺失 |
| 页脚 | "浙里办伴你一生大小事"斜体 | 无 | `_EldFooterSection` **完整实现** | 当前缺失 |
| 未登录悬浮横幅 | 深色横幅"登录享受更多服务" + "立即登录"按钮，叠在内容底部 | 无 | `PersistentBanner`（Stack + Align.bottomCenter）**完整实现**，支持 × 关闭 | 当前缺失 |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/home/elder_home_page.dart`**，替换整个 `elder_home.dart` 的 body 区块。移植步骤：
1. 去掉 `ConsumerStatefulWidget`，改为现有 `StatefulWidget`
2. 保留 `ElderBottomNav(currentIndex: 0)`（当前项目的，含代理功能）
3. `_EldToolBarSection` 中"常规版"按钮改为 `context.go('/')`
4. `PersistentBanner` 中 `ref.watch(loginProvider)` 改为 `AuthState.instance.isLoggedIn`，`dismiss()` 用本地 `setState` 替代
5. `design_tokens.dart` 中的颜色/间距常量一并复制到 `app/lib/`

---

### P3 · 登录页面（`/login`，`login_page.dart`）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 结构 | 渐变蓝背景；浙里办 Logo；"欢迎使用'浙里办'"；个人/法人 Tab；手机号输入框；登录按钮（有输入时可点）；点登录 → 协议底部弹窗 → 进刷脸页 | 橙色背景；Logo；刷脸/验证码两个按钮；协议 Checkbox 在按钮下方，未勾选 disabled | `LoginPage`：蓝色背景 + 个人/法人 Tab + 手机号输入 + 条款圆点未勾 + 登录按钮（有输入可点）**完整实现** | 当前流程不同 |
| 协议弹窗 | 底部弹出"请阅读并同意以下条款"，"不同意"/"同意并继续" | 无弹窗 | `_TermsOverlayContent` + `InAppOverlay.show()` **完整实现** | 当前缺失 |
| 辅助链接 | 新用户注册 / 忘记密码 / 登录遇到问题 / 其他证件 | 无 | 已实现辅助链接行 | 当前缺失（演示可忽略） |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/login/login_page.dart`**，全量替换 `login_page.dart`。移植步骤：
1. 去掉 `flutter_riverpod` 导入，`AppColors.standardPrimary` 用 `const Color(0xFF2D74DC)` 或统一到 theme 文件
2. `context.go(AppRoutes.faceAuth)` 改为 `context.push('/login/face')`
3. `AgentElementRegistry` 相关注册逻辑从旧版 `login_page.dart` 保留（`_faceBtnKey`、`_verifyBtnKey`、`_chkKey`），追加到新页面中对应按钮的 `key:` 参数

---

### P4 · 刷脸验证页面（`/login/face`，`face_auth_page.dart`）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 背景/标题 | "身份验证"，浅蓝渐变背景 | "刷脸登录"，橙色 AppBar | 浅蓝渐变 + "身份验证" AppBar **完整实现** | 当前标题/颜色不同 |
| 人脸框 | 蓝色四角 L 形定位框 + 圆形头像 + 旋转虚线动效 | 灰色圆形 + face 图标 | `_FaceScanFrame`（四角 `_CornerBracket` + `_FaceAvatar`）**完整实现** | 当前样式简陋 |
| 按钮组 | "开始认证"主按钮 + "其他方式认证"次要按钮 | 仅"开始识别" | `_DefaultView` 两按钮 **完整实现** | 当前缺次要按钮 |
| 请求刷脸认证弹窗 | 点"开始认证" → InAppOverlay 弹出协议确认弹窗（退出/同意并继续）| 无 | `_FaceAuthRequestContent` + `PermissionFlowHelper.request()` **完整实现**（含摄像头系统弹窗模拟） | 当前缺弹窗 |
| 其他方式认证弹窗 | 底部弹出：手机短信验证 / 密码登录 | 无 | `_OtherAuthContent` **完整实现** | 当前缺失 |
| 认证中状态 | 眨眼/摇头动效，屏幕变色 | 2s 延迟 → 直接登录 | `_AuthenticatingView`（眨眨眼提示 + 圆形动效）**已实现骨架，点按钮跳转** | 当前无中间态 |
| 页脚 | "浙里办 \| 伴你一生大小事" | 无 | 已实现 | 当前缺失 |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/login/face_auth_page.dart`**，全量替换 `face_auth_page.dart`。移植步骤：
1. 去掉 `flutter_riverpod`；登录成功回调改为 `AuthState.instance.login(); context.go('/elder')`
2. `PermissionFlowHelper` 和 `InAppOverlay` 一并移植到 `app/lib/widgets/`（纯 Widget，无 Riverpod 依赖，可直接复用）
3. `SystemDialog` 也一并移植（`core/widgets/system_dialog.dart`）

---

### P5 · 验证码登录页面（`/login/verify`，`verify_page.dart`）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 来源入口 | 从刷脸页点"其他方式认证" → 底部弹窗 → 点"手机短信验证" | 从登录页直接跳转 | 入口已通过 `_OtherAuthContent` 弹窗跳转 | 入口不同（流程重构后自然解决） |
| 背景 | 浅蓝渐变（`0xFFDEEAF8`） | 橙色 AppBar | `VerifyPage` 浅蓝渐变背景 **完整实现** | 当前颜色不同 |
| 页面布局 | "请输入验证码"大标题 + 说明文字 + 6格 OTP 输入框 + "重新发送 55秒"倒计时 + "确认"按钮 | 手机号输入框 + 验证码输入框 + 发送按钮 + 登录按钮 | `_OtpInputRow`（6格格子）+ 倒计时行 **完整实现**，样式精良 | 当前 OTP 格子式输入缺失 |
| 确认后操作 | 确认 → 弹 SystemDialog 确认 → 登录成功 → 跳 `/elder` | 直接跳 `/elder` | `SystemDialog.show()` + `loginProvider.login()` **完整实现** | 当前无确认弹窗 |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/login/verify_page.dart`**，全量替换 `verify_page.dart`。移植步骤：
1. 去掉 `flutter_riverpod`，`ref.read(loginProvider.notifier).login('用户')` 改为 `AuthState.instance.login()`
2. `context.go(AppRoutes.elderHome)` 改为 `context.go('/elder')`
3. `SystemDialog` 一并移植到 `app/lib/widgets/`（无 Riverpod 依赖）

---

### P6 · 搜索页面（`/elder/search`，`search_page.dart`）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 顶栏 | 无独立 AppBar；顶部行：西湖区 ▼ + 灰色搜索输入框 + "取消"文字按钮 | 橙色 AppBar + 搜索框在下方 | `_SearchBar`（西湖区 ▼ + 灰色搜索框 + 麦克风/清除 icon + 取消按钮）**完整实现** | 样式不同 |
| 空状态：我的常用 | 4 项图标+文字（浙里医保/社保查询/住房公积金/社保证明…） | 热门搜索胶囊 | `_DefaultBody` 的"我的常用"区块（2 行 2 列，图标+文字）**完整实现** | 当前分区结构不同 |
| 空状态：最近搜索 | 胶囊标签 + "清空"按钮 | 无 | `_DefaultBody` 的"最近搜索"区块 **完整实现** | 当前缺失 |
| 空状态：为你推荐 | 多行胶囊标签 Wrap | 无 | `_DefaultBody` 的"为你推荐"区块（12 个胶囊）**完整实现** | 当前缺失 |
| 输入中补全建议 | 实时列表（每条一行文字）| 无 | `SearchSuggestionList`（可复用 widget）**完整实现** | 当前缺失 |
| 搜索结果页 | 独立结果页；四 Tab；综合 Tab 展示服务卡+子标签+办事列表 | 无独立结果页 | `SearchResultPage` + `_ResultTabRow` + `_ResultBody`（按 query 分支，医保缴费/养老金查询）**完整实现** | 当前缺结果页 |
| 麦克风权限流程 | 三段式：应用引导弹窗 → 系统权限弹窗 → 语音输入弹窗 | 无 | `PermissionFlowHelper` + `_MicPermissionContent` + `_VoiceInputContent` **完整实现** | 演示可酌情保留 |

**复用策略：建议直接移植以下两个文件**：
- `archive/scene-canvas-v1/lib/features/search/search_page.dart` → 替换 `app/lib/pages/search_page.dart`
- `archive/scene-canvas-v1/lib/features/search/search_result_page.dart` → 新建 `app/lib/pages/search_result_page.dart`
- `archive/scene-canvas-v1/lib/features/search/suggestion_list.dart` → 新建 `app/lib/widgets/search_suggestion_list.dart`

移植步骤：
1. 去掉 Riverpod（`voiceInputService` 是 mock，直接内联一个 `Future.delayed` 返回固定字符串即可）
2. `AppRoutes.searchResult` 改为 `'/elder/search-result'`；在 `router.dart` 补路由
3. 搜索结果页中 `context.push(AppRoutes.socialInsurance)` 改为 `context.push('/elder/shebao-jiaona')`；`context.push(AppRoutes.pensionQuery)` 改为 `context.push('/elder/shebao-query')`
4. 页面底部保留 `ElderBottomNav(currentIndex: 0)`（注意旧版搜索页无底部导航，需补充）

---

### P7 · 社保费缴纳服务主页（新增）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 页面整体 | 蓝色渐变 Banner + 9 宫格菜单 + 底部说明 | 无此页面，直接是缴费表单 | `SocialInsurancePage`（含 `_HomeSubPage`：Banner + 3×3 `_ServiceIcon` 网格）**完整实现**，还含"我为自己缴"子页（用户信息头卡/温馨提示/全部|城乡居民|灵活就业 Tab）和"缴费记录"子页 | 当前缺整个中间层 |
| 代理交互 | 导航至此 → 自动点"我为自己缴" | 直接跳表单 | `_HomeSubPage` 中 `onSelfPay` 回调切换子页 | 代理工具路由需调整 |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/service/social_insurance_page.dart`** → 新建 `app/lib/pages/shebao_jiaona_page.dart`。移植步骤：
1. 去掉 `flutter_riverpod`（`_selfPayItemsProvider` 改为直接显示空状态，无需异步加载）
2. `_SelfPaySubPage` 中用户信息头卡保留；表单字段点击"去缴费"跳 `/elder/yibao-jiaofei`（当前表单页）
3. 在 `router.dart` 新增路由 `/elder/shebao-jiaona`
4. 为"我为自己缴"按钮注册 `AgentElementRegistry.register('btn_wo_wei_ziji_jiao')`，使代理可点击

---

### P8 · 医保缴费表单页（`/elder/yibao-jiaofei`，`yibao_jiaofei_page.dart`）

| 维度 | 原版浙里办（"我为自己缴"页面） | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 用户信息头卡 | 蓝色头卡：头像 + 姓名脱敏 + 证件号脱敏 + 右箭头 | 无 | `_SocialInsurancePage._SelfPaySubPage` 顶部蓝色用户头卡 **完整实现** | 当前缺失 |
| 表单字段 | 全部/城乡居民/灵活就业 Tab + 空状态提示 | 下拉+输入表单（代理功能已完整）| 旧版只有空状态，没有填写表单 | **当前表单字段保留**，仅补用户信息头卡 |

**复用策略：参考改写**。从 `social_insurance_page.dart` 的 `_SelfPaySubPage` 中提取蓝色用户信息头卡代码，插入到 `yibao_jiaofei_page.dart` 的 `ListView` 最顶部，现有表单字段和 `AgentElementRegistry` key 全部保留不动。

---

### P9 · 社保查询服务主页（新增）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| 页面整体 | 蓝色渐变"个人基本信息"头卡 + "险种信息"标题 + 多张险种卡（企业职工基本养老保险/失业保险/工伤保险），每卡有险种名/参保状态/基本信息/缴费信息按钮 | 无此页面 | `PensionQueryPage`：**完整实现**，含蓝色渐变头卡（SI 水印）+ 三张险种卡（`_InsuranceCard`，深蓝紫渐变头 + 按钮行）| 当前缺整个中间层 |
| 代理交互 | 导航至此 → 代理自动点击"基本信息"等 | 直接跳养老金结果 | 旧版养老保险卡按钮均为 `onPressed: null` | 需补 AgentElementRegistry 注册 |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/service/pension_query_page.dart`** → 新建 `app/lib/pages/shebao_query_page.dart`。移植步骤：
1. 无 Riverpod 依赖，可直接复制
2. 在 `router.dart` 新增路由 `/elder/shebao-query`
3. "企业职工基本养老保险"卡的"基本信息"按钮注册 `AgentElementRegistry.register('btn_yanglao_jibenxinxi')`，onTap 改为 `context.push('/elder/pension-query')`（现有养老金结果页）

---

### P10 · 我的页面（`/elder/mine`，`mine_page.dart`）

| 维度 | 原版浙里办 | 当前实现 | scene-canvas-v1 已有实现 | 差距 |
|------|----------|---------|------------------------|------|
| AppBar | "个人账号" + "切换"胶囊按钮 + 右侧铃铛通知图标 | "我的" AppBar（橙色，居中标题）+ ConnectionIndicator | `MyPage` AppBar："个人账号" + 切换 OutlinedButton + 铃铛 IconButton **完整实现** | 样式不同 |
| 用户信息卡 | 圆形头像（灰蓝渐变）+ 姓名脱敏（\*宇澄）+ "高级实名 ›"徽章 + "编辑资料"链接 | 圆形图标 + 姓名 + "已登录"/"点击登录 ›" | `_MyHeaderSection`：蓝色渐变头像 + 姓名 + 金色"高级实名"徽章 + "编辑资料"行 **完整实现** | 当前缺徽章和编辑链接 |
| 功能网格区（7项） | 2 列大图标网格：办事记录 / 我的草稿 / 我的足迹 / 我的订阅 / 诉求记录 / 评价记录 / 反馈记录（圆形橙底图标+文字，间距宽松） | 列表菜单：草稿箱 / 操作记录 / 字体大小 / 关于小浙 | `_MyActivitySection`（7项，2列 Row 循环，`_ActivityIcon` 圆形橙底）**完整实现** | 差距大：原版网格，旧版已实现 |
| 我的证照（横滑） | 老年人优待证 / 医保电子凭证 / 住房公积金 渐变色卡片 + "全部 ›" | 无 | `_MyCertSection`（`SizedBox h:80` + 横向 ListView + `_CertCard` 渐变卡片）**完整实现** | 当前缺失 |
| 我的信息（3-col） | 社保 / 公积金 / 票据 + "全部 ›" | 无 | `_MyInfoSection`（3列 `_InfoIcon`）**完整实现** | 当前缺失 |
| 我的管理（3图标） | 亲友联系人 / 我的授权 / 我的印章 | 无 | `_MyManagementSection`（2行 Row + `_ManageIcon`）**完整实现** | 当前缺失 |
| 服务推荐（2×2） | 社保医保税… / 社保查询 / 个人权益记 / 住房公积金 + "全部 ›" | 无 | `_MyRecommendSection`（2行 Row + `_RecommendIcon` 蓝底圆圈）**完整实现** | 当前缺失 |
| 设置/关于浙里办 | 底部两个列表行（设置 / 关于浙里办），带右箭头 | "关于小浙"在功能菜单里 | `_MySettingsSection`（两 ListTile，圆形橙底图标）**完整实现** | 样式不同 |
| 退出登录 | 无独立退出按钮（通过"切换"入口处理）| 有独立"退出登录"红色按钮 | 无退出按钮 | 可保留，适老化合理 |

**复用策略：建议直接移植 `archive/scene-canvas-v1/lib/features/my/my_page.dart`**，全量替换 `mine_page.dart`。移植步骤：
1. 去掉 `flutter_riverpod`；`ref.watch(loginProvider)` 改为 `AuthState.instance` 读取登录状态
2. 替换 `ElderBottomNav`：去掉旧版 `FloatingActionButton` + 旧版 `ElderBottomNav`，改为当前项目的 `ElderBottomNav(currentIndex: 2)`（含代理功能）
3. `_MyActivitySection` 的"我的草稿"改为 `context.push('/elder/drafts')`，"办事记录"改为 `context.push('/elder/operation-logs')`
4. 退出登录按钮：在 `_MySettingsSection` 最后补一个红色 TextButton，调用 `AuthState.instance.logout(); context.go('/elder')`
5. `PersistentBanner` 的 dismiss 逻辑用本地 `setState` 替代（同 P2）

---

## 三、流程级差异清单

### F1 · 登录流程

**原版流程**：
```
长辈版首页（未登录）→ 悬浮"登录享受更多服务"横幅 → 点"立即登录"
  → 登录页（手机号输入框，协议未勾选，登录按钮始终可点）
  → 点"登录" → 弹出"请阅读并同意以下条款"底部弹窗
  → 点"同意并继续" → 刷脸验证页（"开始认证" + "其他方式认证"）
  → 点"开始认证" → 弹"请求刷脸认证"确认弹窗 → "同意并继续" → 刷脸 → 登录成功
  → 另一路：点"其他方式认证" → 底部弹窗选"手机短信验证" → 验证码登录页
```

**当前流程**：
```
任意页面 → 点"登录账号" / 我的页面点"点击登录"
  → 登录页（刷脸/验证码按钮，协议 Checkbox 在下方，未勾选时按钮 disabled）
  → 勾选协议 → 点"刷脸登录" → 刷脸页（"开始识别"单按钮）
  → 点"开始识别" → 2s 延迟 → 登录成功
```

**需对齐的改动**：
- 登录页改为手机号/用户名输入框 + 协议未勾选 + 登录按钮始终可点击
- 点登录按钮时（不管是否勾选协议）弹出协议确认底部弹窗
- 刷脸页补"其他方式认证"按钮 → 底部弹窗选验证码/密码登录
- 刷脸页补"请求刷脸认证"确认弹窗

---

### F2 · 医保缴费场景流程

**原版流程**：
```
长辈版首页 → 底部Tab点"搜索" → 搜索页 → 输入"医保缴费" → 搜索结果页
  → 点"社保费缴纳"服务卡 → 社保费缴纳服务主页（9宫格）
  → 点"我为自己缴" → 缴费表单页
```

**当前流程**：
```
长辈版首页 → 点"医保缴费"网格卡 → 直接进缴费表单页
（小浙代理触发：搜索场景 → 直接跳 /elder/yibao-jiaofei）
```

**需对齐的改动**：
- 新增"社保费缴纳服务主页"（`/elder/shebao-jiaona`），9宫格，点"我为自己缴"跳缴费表单
- 长辈版首页"医保缴费"卡改为跳新的服务主页，非直接跳表单
- 小浙代理工具路由：`navigate_to` 目标从 `/elder/yibao-jiaofei` 改为 `/elder/shebao-jiaona`，到达后调用 `tap_element('btn_wo_wei_ziji_jiao')` 再到表单

---

### F3 · 养老金查询场景流程

**原版流程**：
```
长辈版首页 → 搜索"养老金查询" → 搜索结果页 → 点"社保查询"服务卡
  → 社保查询服务主页（险种卡列表）→ 养老保险卡"基本信息"/"缴费信息"
```

**当前流程**：
```
长辈版首页 → 点"养老金查询"网格卡 → 直接进养老金查询结果页
```

**需对齐的改动**：
- 新增"社保查询服务主页"（`/elder/shebao-query`），展示险种卡，点养老保险行跳养老金查询页
- 长辈版首页"养老金查询"卡改为跳新的服务主页

---

### F4 · 搜索流程

**原版**：底部 Tab"搜索"（麦克风图标）→ 独立搜索页（我的常用/最近搜索/为你推荐）→ 输入时实时补全 → 搜索结果页（四 Tab）

**当前**：底部导航中间是"助手"麦克风按钮，搜索通过长辈版首页"搜索服务"卡片进入 `/elder/search`

**约束**：助手按钮保留不动，不改为搜索入口。搜索页改版对齐原版结构，通过首页的搜索卡片或我的页面入口进入。

---

## 四、新增页面/组件清单

| # | 名称 | 路由 | 目标文件 | scene-canvas-v1 来源 | 说明 |
|---|------|------|------|------|------|
| N1 | 社保费缴纳服务主页 | `/elder/shebao-jiaona` | `shebao_jiaona_page.dart` | `features/service/social_insurance_page.dart` → **直接移植** | Banner + 9宫格，点"我为自己缴"→缴费表单 |
| N2 | 社保查询服务主页 | `/elder/shebao-query` | `shebao_query_page.dart` | `features/service/pension_query_page.dart` → **直接移植** | 个人信息头卡 + 险种卡列表，点养老保险→养老金查询 |
| N3 | 搜索结果页 | `/elder/search-result` | `search_result_page.dart` | `features/search/search_result_page.dart` → **直接移植** | 四 Tab（综合/服务/办事/政策），综合 Tab 展示服务卡+办事列表 |
| C1 | 协议底部弹窗 | — | 内联于 `login_page.dart` | `features/login/login_page.dart` 的 `_TermsOverlayContent` → **直接移植** | "请阅读并同意以下条款" + 不同意/同意并继续 |
| C2 | 刷脸"其他方式认证"底部弹窗 | — | 内联于 `face_auth_page.dart` | `features/login/face_auth_page.dart` 的 `_OtherAuthContent` → **直接移植** | 手机短信验证 / 密码登录两选项 |
| C3 | 刷脸"请求刷脸认证"确认弹窗 | — | 内联于 `face_auth_page.dart` | `features/login/face_auth_page.dart` 的 `_FaceAuthRequestContent` → **直接移植** | 人脸识别协议确认 + 退出/同意并继续 |

**共享工具组件**（需一并移植到 `app/lib/widgets/`）：

| 组件 | scene-canvas-v1 来源 | 被哪些页面依赖 |
|------|------|------|
| `InAppOverlay` | `core/widgets/in_app_overlay.dart` | P3 登录页（C1）、P4 刷脸页（C2/C3）、P6 搜索页（语音输入弹窗） |
| `SystemDialog` | `core/widgets/system_dialog.dart` | P5 验证码页（确认弹窗）、P4 刷脸页（权限弹窗） |
| `PersistentBanner` | `core/widgets/persistent_banner.dart` | P2 长辈版首页、P10 我的页面 |
| `PermissionFlowHelper` | `core/widgets/permission_flow_helper.dart` | P4 刷脸页、P6 搜索页（麦克风权限） |

---

## 五、保留不动的部分

以下内容**无需改动**，保持现有实现：

| 模块 | 理由 |
|------|------|
| `agent_panel.dart` 代理面板 | 核心交互，冻结 |
| `elder_bottom_nav.dart` 底部导航结构 | 助手按钮逻辑不动，样式可微调 |
| `ws_client.dart` WebSocket 客户端 | 通信层不动 |
| `draft_service.dart` / `draft_store.dart` 草稿箱 | 功能完整 |
| `operation_logs_page.dart` 操作记录 | 功能完整 |
| `drafts_page.dart` 草稿箱页 | 功能完整 |
| `yibao_jiaofei_page.dart` 缴费表单核心字段 | 代理注册 key 不动，仅补用户信息头卡 |
| `pension_query_page.dart` 养老金查询 | 保持 |
| `yibao_query_page.dart` 医保查询 | 保持 |
| `verify_page.dart` 验证码页 | 基本符合原版，入口流程调整后自然对齐 |
| `agent_element_registry.dart` | 代理元素注册机制不动 |
| `auth_state.dart` | 认证状态不动 |

---

## 六、改动优先级排序

按"答辩演示影响"从高到低：

| 优先级 | 改动项 | 影响的演示路径 |
|--------|--------|--------------|
| P0 | 长辈版首页（P2）：补服务 Tab 区、线上一站办 2×2 网格 | 演示开场第一屏，视觉还原度直接影响答辩评分 |
| P0 | 新增社保费缴纳服务主页（N1）+ 调整医保缴费入口（F2） | 医保缴费主演示路径的中间层 |
| P1 | 登录流程（F1）：协议弹窗 + 刷脸页双按钮 + 其他方式弹窗 | 登录场景演示路径 |
| P1 | 搜索页（P6）：补"我的常用"图标区 + "最近搜索"+ 搜索结果页（N3） | 搜索触发的演示路径 |
| P2 | 新增社保查询服务主页（N2）| 养老金查询路径 |
| P2 | 我的页面（P10）：改为网格布局，补各功能区块 | 展示完整度，非主路径 |
| P3 | 长辈版首页补全（线下就近办/授权办/页脚）| 滑动展示的完整度 |
| P3 | 刷脸页视觉还原（蓝色渐变背景/四角定位框） | 细节质感 |

---

## 七、验收标准

每条格式：**输入 → 操作 → 期望结果**

### 长辈版首页

- **AC-P2-1**：进入 `/elder` → 查看页面 → 顶部有地区行（西湖区 + 个人频道）和扫一扫/消息/常规版快捷按钮
- **AC-P2-2**：进入 `/elder` → 查看页面 → 政务服务热线横幅卡片可见
- **AC-P2-3**：进入 `/elder` → 查看服务 Tab 区 → 三个 Tab（热门服务/我的常用/我的订阅）可点击切换，内容区随之变化
- **AC-P2-4**：进入 `/elder` → 向下滚动 → 依次可见"线上一站办"2×2 网格、"线下就近办"大厅列表、"授权办"2×2 网格
- **AC-P2-5**：未登录状态进入 `/elder` → 页面显示"登录享受更多服务"悬浮横幅，点"立即登录"跳转到登录页

### 登录流程

- **AC-F1-1**：进入登录页 → 不输入任何内容直接点"登录" → 弹出协议确认弹窗（标题"请阅读并同意以下条款"，两按钮"不同意"/"同意并继续"）
- **AC-F1-2**：协议弹窗 → 点"不同意" → 弹窗关闭，停留在登录页
- **AC-F1-3**：协议弹窗 → 点"同意并继续" → 跳转刷脸验证页，页面有"开始认证"和"其他方式认证"两个按钮
- **AC-F1-4**：刷脸验证页 → 点"其他方式认证" → 从底部弹出包含"手机短信验证"和"密码登录"两个选项的弹窗
- **AC-F1-5**：其他认证方式弹窗 → 点"手机短信验证" → 跳转到验证码登录页

### 医保缴费场景

- **AC-F2-1**：长辈版首页 → 点"医保缴费"（或线上一站办"健康医保"） → 跳转社保费缴纳服务主页，显示 9 宫格菜单
- **AC-F2-2**：社保费缴纳服务主页 → 点"我为自己缴" → 跳转缴费表单页，表单字段与现有实现一致
- **AC-F2-3**：小浙代理执行医保缴费场景 → 代理最终落在缴费表单页并填写字段（路由经过新服务主页）

### 搜索流程

- **AC-F4-1**：进入搜索页（`/elder/search`）→ 空状态显示"我的常用"（4 个图标服务）、"最近搜索"（含"清空"按钮）、"为你推荐"（多个胶囊标签）三个区块
- **AC-F4-2**：搜索页输入"医保缴费" → 显示实时补全建议列表（至少 3 条）
- **AC-F4-3**：点击补全建议或按回车 → 跳转搜索结果页，结果页顶部有四个 Tab（综合/服务/办事/政策），综合 Tab 下可见"社保费缴纳"服务卡

### 我的页面

- **AC-P10-1**：进入 `/elder/mine` → 登录态下，用户信息卡显示头像、脱敏姓名、"高级实名"标签
- **AC-P10-2**：进入 `/elder/mine` → 功能区以 2 列大图标网格展示（办事记录/我的草稿/我的足迹/我的订阅/诉求记录/评价记录）
- **AC-P10-3**：进入 `/elder/mine` → 向下滚动 → 可见"我的证照"横向滚动区（老年人优待证/医保电子凭证）、"我的信息"（社保/公积金/票据）、"我的管理"（亲友联系人/我的授权/我的印章）、"服务推荐"区块

---

*文档结束。代理功能相关路由键值（AgentElementRegistry 注册 key）在改动中保持不变，具体 key 列表见 `agent_element_registry.dart`。*
