# 浙里办 UI 还原 — 技术方案

> **版本**：v1.0（2026-05-08）
> **作者**：architect
> **目标读者**：前端开发
> **依据**：`docs/UI_RESTORE_REQUIREMENTS.md` v1.2

---

## 一、任务执行顺序总览

按照「阻塞关系 → PM 优先级」两维排序：

```
阶段 0（先决条件）：移植共享工具组件
阶段 1（P0）：长辈版首页 + 社保费缴纳服务主页（含入口调整）
阶段 2（P1）：登录流程全链路
阶段 3（P1）：搜索页 + 搜索结果页
阶段 4（P2）：社保查询服务主页
阶段 5（P2）：我的页面
阶段 6（P3）：长辈版首页补全（P3 块）+ 刷脸页视觉还原
```

---

## 二、阶段 0：共享工具组件移植（阻塞所有后续阶段）

这四个组件无 Riverpod 依赖（`PersistentBanner` 除外），但 `PersistentBanner` 需要改造。必须先移植完，后续任务才能引用。

### 0-A `InAppOverlay`

- **来源**：`archive/scene-canvas-v1/lib/core/widgets/in_app_overlay.dart`
- **目标**：新建 `app/lib/widgets/in_app_overlay.dart`
- **改动**：无 Riverpod 依赖，只修改 import 路径：
  - 删除旧版 `../../core/theme/design_tokens.dart`
  - 改为 `package:app/theme.dart`（或使用内联常量 `const Color(0xFFFFFFFF)` 和 `16.0`）
  - `AppRadius.xlarge` → `16.0`，`Spacing.lg` → `16.0`

### 0-B `SystemDialog`

- **来源**：`archive/scene-canvas-v1/lib/core/widgets/system_dialog.dart`
- **目标**：新建 `app/lib/widgets/system_dialog.dart`
- **改动**：只改 import；`AppRadius.xlarge` → `16.0`，`Spacing` 常量 → 对应数值。无 Riverpod 依赖，可直接复制。

### 0-C `PermissionFlowHelper`

- **来源**：`archive/scene-canvas-v1/lib/core/widgets/permission_flow_helper.dart`
- **目标**：新建 `app/lib/widgets/permission_flow_helper.dart`
- **改动**：修改 import 指向新的 `in_app_overlay.dart` 和 `system_dialog.dart`。无状态，可直接复制。

### 0-D `PersistentBanner`

- **来源**：`archive/scene-canvas-v1/lib/core/widgets/persistent_banner.dart`
- **目标**：新建 `app/lib/widgets/persistent_banner.dart`
- **Riverpod 改造点**（这是唯一有 Riverpod 的共享组件）：

  旧版第 13 行：`class PersistentBanner extends ConsumerWidget`
  → 改为：`class PersistentBanner extends StatefulWidget`，加 `bool _dismissed = false` 字段

  旧版第 18 行：`final isLoggedIn = ref.watch(loginProvider).isLoggedIn;`
  → 改为：`final isLoggedIn = AuthState.instance.isLoggedIn;`

  旧版第 19 行：`final isDismissed = ref.watch(loginBannerDismissedProvider);`
  → 删除，改为读本地 `_dismissed` 字段

  旧版第 46 行：`ref.read(loginBannerDismissedProvider.notifier).dismiss()`
  → 改为：`setState(() => _dismissed = true)`

  旧版第 24 行：`final buttonColor = mode == AppMode.elder ? AppColors.elderPrimary : ...`
  → 固定为 `const Color(0xFFFF6D00)`（长辈版始终橙色）

  旧版第 65 行：`context.go(AppRoutes.login)`
  → 改为：`context.go('/login')`

  需要 import：`../services/auth_state.dart`

### 0-E `design_tokens.dart` 复制

- **来源**：`archive/scene-canvas-v1/lib/core/theme/design_tokens.dart`
- **目标**：新建 `app/lib/theme/design_tokens.dart`
- **改动**：无。内容与当前项目内联常量一致（`AppColors.elderPrimary = 0xFFFF6D00` 等），但集中管理，避免后续移植文件的导入路径调整量过大。
- **注意**：当前项目各页面已有内联常量（如 `const _kOrange = Color(0xFFFF6D00)`），两者可**并存**，`design_tokens.dart` 供移植文件使用，现有页面不需要迁移到该文件。

---

## 三、阶段 1：P0 — 长辈版首页 + 社保费缴纳服务主页

### 1-A 长辈版首页替换（`app/lib/pages/elder_home.dart`）

**策略**：保留现有文件框架（`ElderHome` 类名不变，继续作为 `StatefulWidget`），替换 body 区块为旧版各 Section，追加旧版 AppBar。

#### 具体改动：

**1. 文件顶部 import（追加）**
```dart
import '../theme/design_tokens.dart';
import '../widgets/persistent_banner.dart';
```

**2. `_ElderHomeState` 类：追加 `TabController`（第 22 行后）**

```dart
class _ElderHomeState extends State<ElderHome>
    with SingleTickerProviderStateMixin {
  late final TabController _tab = TabController(length: 3, vsync: this);

  @override
  void dispose() {
    _tab.dispose();
    // 保留现有 _guideOverlay 的 dispose 逻辑
    ...
  }
```

**3. `AppBar` 替换（当前第 69-75 行）**

当前：橙色 AppBar + "小浙助手" title + ConnectionIndicator
改为：旧版两行结构（AppBar 第一行 + `_EldToolBarSection` 第二行）：

```dart
appBar: AppBar(
  automaticallyImplyLeading: false,
  backgroundColor: AppColors.elderPrimary,
  titleSpacing: Spacing.lg,
  title: Row(
    children: [
      const Text('西湖区', style: TextStyle(color: Colors.white, fontSize: AppFontSize.body, fontWeight: FontWeight.w600)),
      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
    ],
  ),
  actions: [
    Container(
      margin: const EdgeInsets.only(right: Spacing.lg),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.sm, vertical: 4),
      decoration: BoxDecoration(border: Border.all(color: Colors.white54), borderRadius: BorderRadius.circular(AppRadius.xlarge)),
      child: const Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.sync, color: Colors.white, size: 14),
        SizedBox(width: 4),
        Text('个人频道', style: TextStyle(color: Colors.white, fontSize: AppFontSize.small)),
      ]),
    ),
  ],
),
```

**4. `body` 替换（当前第 78-175 行）**

整个 body 替换为：

```dart
body: Stack(
  children: [
    SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EldToolBarSection(onStandardTap: () => context.go('/')),
          const _EldGovHotlineSection(key: ValueKey('eld_hotline')),
          _EldTabCardSection(controller: _tab),
          const _EldOnlineServiceSection(key: ValueKey('eld_online')),
          const _EldOfflineServiceSection(),
          const _EldAuthorizedServiceSection(),
          const _EldFooterSection(),
        ],
      ),
    ),
    const Align(alignment: Alignment.bottomCenter, child: PersistentBanner()),
  ],
),
```

**5. 线上一站办「健康医保」入口调整**

在旧版 `_EldOnlineServiceSection._items` 列表（已复制到新文件）中，「健康医保」网格项需要响应点击：在 `_EldOnlineGridItem.build` 里为「健康医保」项加 `GestureDetector`：

```dart
GestureDetector(
  onTap: item.label == '健康医保' ? () => context.push('/elder/shebao-jiaona') : null,
  child: Container(...),  // 原有样式不变
)
```
**注意**：`_EldOnlineGridItem` 当前是 `StatelessWidget`，改造时需接收 `onTap` 参数或改为 `GestureDetector` 包裹。

**6. 从 elder_home.dart 删除的旧代码**
- 删除现有 `_services` 静态列表（第 23-28 行）
- 删除 `_hasShownGuide`、`_guideOverlay`、`_showGuideIfNeeded`、`_GuideBubble`、`_ArrowPainter`（引导气泡，旧版已有结构性导航替代）
- 删除 `_ServiceCard` 类
- 保留：`ElderBottomNav(currentIndex: 0)`

**7. 从旧版文件复制的 Section 类（追加到文件末尾）**

从 `elder_home_page.dart` 中直接复制以下私有类到 `elder_home.dart`，更新 import：

- `_EldToolBarSection` + `_EldToolBarItem`
- `_EldGovHotlineSection`
- `_EldTabCardSection` + `_EldTabBar` + `_EldTabLabel`
- `_EldHotContent` + `_EldFavoritesContent` + `_EldSubscriptionContent`
- `_EldServiceCard` + `_EldViewAllButton`
- `_EldOnlineServiceSection` + `_EldGridItem` + `_EldOnlineGridItem`
- `_EldOfflineServiceSection` + `_EldOfficeItem`
- `_EldAuthorizedServiceSection`
- `_EldFooterSection`

**风险**：旧版 `_EldFavoritesContent` 中「社保查询」卡需要导航到新增的 `/elder/shebao-query`；「浙里医保」点击暂时为 null。

### 1-B 新建社保费缴纳服务主页（`app/lib/pages/shebao_jiaona_page.dart`）

**来源**：`archive/scene-canvas-v1/lib/features/service/social_insurance_page.dart`
**策略**：全量复制后做以下改造。

#### 具体改动：

**1. 删除 Riverpod 相关代码**

删除（来源文件第 1-10 行）：
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/service_repository.dart';
final _selfPayItemsProvider = FutureProvider.autoDispose<List<ServiceItem>>(...);
```

**2. 类改造**

旧版第 14 行：`class SocialInsurancePage extends ConsumerStatefulWidget`
→ 改为 `class ShebaoJiaonaPage extends StatefulWidget`

旧版第 22 行：`class _SocialInsurancePageState extends ConsumerState<SocialInsurancePage>`
→ 改为 `class _ShebaoJiaonaPageState extends State<ShebaoJiaonaPage>`

**3. `_SelfPaySubPage` 改为 `StatelessWidget`**

旧版第 269 行：`class _SelfPaySubPage extends ConsumerWidget`
→ 改为 `class _SelfPaySubPage extends StatelessWidget`

删除 `WidgetRef ref` 参数，删除 `ref.watch(_selfPayItemsProvider)` 的 asyncItems 逻辑。

将内容区（旧版第 362-383 行的 `asyncItems.when(...)`）替换为：
```dart
Expanded(child: const _EmptyState(message: '您没有应缴纳的社保费记录')),
```

**4. 「我为自己缴」按钮注册 AgentElementRegistry**

旧版 `_HomeSubPage` 第 127 行，`_ServiceIcon` 的「我为自己缴」：
```dart
_ServiceIcon(
  icon: Icons.volunteer_activism,
  color: AppColors.elderPrimary,
  label: '我为自己缴',
  onTap: onSelfPay,
),
```
改为：
```dart
_ServiceIcon(
  key: AgentElementRegistry.register('btn_wo_wei_ziji_jiao'),
  icon: Icons.volunteer_activism,
  color: AppColors.elderPrimary,
  label: '我为自己缴',
  onTap: onSelfPay,
),
```
`_ServiceIcon` 需接收 `Key? key` 并传给 `InkWell`：在 `_ServiceIcon` 的 `InkWell` 上加 `key: key`。

**5. 跳转逻辑**

`_SelfPaySubPage` 中「去缴费」入口：因旧版 `_SelfPaySubPage` 是空状态展示，实际「去缴费」在现有 `yibao_jiaofei_page.dart`，此处无需改动（用户点了「我为自己缴」进入 `_SelfPaySubPage`，再通过代理或手动从缴费表单页进入）。

**6. 追加 `ElderBottomNav` + import**

Scaffold 的 `bottomNavigationBar` 加：
```dart
bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
```

Import 追加：
```dart
import '../widgets/elder_bottom_nav.dart';
import '../services/agent_element_registry.dart';
```

### 1-C `router.dart` 新增路由

在 `app/lib/router.dart` 追加：
```dart
import 'pages/shebao_jiaona_page.dart';

// 在路由列表中追加：
GoRoute(path: '/elder/shebao-jiaona', pageBuilder: (c, s) => _slidePage(const ShebaoJiaonaPage(), s)),
```

### 1-D 长辈版首页「医保缴费」入口路由调整

`app/lib/pages/elder_home.dart`（待完成 1-A 后）：

`_EldOnlineServiceSection` 中「健康医保」的 `onTap` 改为 `context.push('/elder/shebao-jiaona')`（见 1-A 第 5 点）。

---

## 四、阶段 2：P1 — 登录流程全链路

### 2-A `login_page.dart` 全量替换

**来源**：`archive/scene-canvas-v1/lib/features/login/login_page.dart`
**目标**：替换 `app/lib/pages/login_page.dart`

#### 具体改动：

**1. Import 调整**

删除：`import 'package:flutter_riverpod/flutter_riverpod.dart';`
删除：`import '../../core/router/app_router.dart';`

保留/新增：
```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../theme/design_tokens.dart';
import '../widgets/in_app_overlay.dart';
import '../services/agent_element_registry.dart';
```

**2. 路由调整**

旧版第 252 行：`context.go(AppRoutes.faceAuth)`
→ 改为：`context.push('/login/face')`

**3. 颜色常量**

`AppColors.standardPrimary` → 保留（在 `design_tokens.dart` 中已定义为 `Color(0xFF2D74DC)`）

**4. 追加 AgentElementRegistry 注册**

旧版 `LoginPage` 中只有手机号输入框，但代理需要能点到「登录按钮」。在 `_LoginPageState` 中追加：

```dart
// 登录按钮 key（FilledButton 在第 173 行，改为：）
FilledButton(
  key: AgentElementRegistry.register('btn_login'),
  onPressed: canLogin ? () => _showTermsOverlay(context) : null,
  ...
)
```

保留来自现有 login_page.dart 的三个 key 注册（`btn_face_login`、`btn_verify_login`、`chk_agree_terms`），但新版登录流程中这三个 key 不再在此页面存在（它们移到 face_auth_page.dart）。**新版 login_page.dart 只需注册 `btn_login`**。

**风险**：现有 agent_core.py 的工具中如果硬编码了 `btn_face_login` 在登录页触发，需通知后端同步调整路由逻辑。开发执行前确认后端 tools/ 中没有直接引用这些 key（检查 `backend/tools/`）。

### 2-B `face_auth_page.dart` 全量替换

**来源**：`archive/scene-canvas-v1/lib/features/login/face_auth_page.dart`
**目标**：替换 `app/lib/pages/face_auth_page.dart`

#### 具体改动：

**1. Import 调整**

删除：`flutter_riverpod`、`../../core/state/app_state.dart`、`../../core/router/app_router.dart`

新增：
```dart
import '../theme/design_tokens.dart';
import '../widgets/in_app_overlay.dart';
import '../widgets/permission_flow_helper.dart';
import '../services/auth_state.dart';
import '../services/agent_element_registry.dart';
```

**2. 类改造**

旧版第 10 行：`class FaceAuthPage extends ConsumerStatefulWidget`
→ 改为 `class FaceAuthPage extends StatefulWidget`

旧版第 17 行：`ConsumerState<FaceAuthPage>`
→ 改为 `State<FaceAuthPage>`

**3. `ref` 调用替换**

旧版第 44 行：`ref.read(loginProvider.notifier).login('用户')`
→ 改为：`AuthState.instance.login(name: '用户')`

旧版第 45 行：`context.go(AppRoutes.elderHome)`
→ 改为：`context.go('/elder')`

旧版第 77 行（_showOtherAuthOverlay 内）：`context.go(AppRoutes.verify)`
→ 改为：`context.push('/login/verify')`

**4. 追加 AgentElementRegistry 注册**

将现有 login_page.dart 中的三个 key 迁移到此页面：

```dart
// _FaceAuthPageState 中：
final _faceBtnKey = AgentElementRegistry.register('btn_face_login');
final _otherBtnKey = AgentElementRegistry.register('btn_other_auth');

// _DefaultView 的「开始认证」FilledButton：
FilledButton(
  key: widget.startAuthKey,   // 通过构造传入，或在 _FaceAuthPageState 中直接赋值 GlobalKey
  onPressed: onStartAuth,
  ...
)
```

**简化方案**：在 `_DefaultView` 构造中传入 `startAuthKey`：
```dart
class _DefaultView extends StatelessWidget {
  final VoidCallback onStartAuth;
  final VoidCallback onOtherMethod;
  final GlobalKey? startAuthKey;   // 新增
  final GlobalKey? otherMethodKey; // 新增
  ...
}
```

### 2-C `verify_page.dart` 改造

**来源**：`archive/scene-canvas-v1/lib/features/login/verify_page.dart`
**目标**：改造 `app/lib/pages/verify_page.dart`（旧版已基本符合，仅做 Riverpod 删除）

#### 具体改动：

旧版第 1 行：删除 `flutter_riverpod` import，删除 `../../core/state/app_state.dart`

旧版第 12 行：`class VerifyPage extends ConsumerWidget`
→ 改为 `class VerifyPage extends StatefulWidget`（因为 `_confirmSmsCode` 需要访问 ref，改为 StatefulWidget 后直接调 AuthState）

旧版第 85 行：`void _confirmSmsCode(BuildContext context, WidgetRef ref)`
→ `void _confirmSmsCode(BuildContext context)`

旧版第 93 行：`ref.read(loginProvider.notifier).login('用户')`
→ `AuthState.instance.login(name: '用户')`

旧版第 94 行：`context.go(AppRoutes.elderHome)`
→ `context.go('/elder')`

Import 新增：
```dart
import '../theme/design_tokens.dart';
import '../widgets/system_dialog.dart';
import '../services/auth_state.dart';
```

**注意**：`SystemDialog` 需已在阶段 0 完成移植。

---

## 五、阶段 3：P1 — 搜索页 + 搜索结果页

### 3-A `search_page.dart` 全量替换

**来源**：`archive/scene-canvas-v1/lib/features/search/search_page.dart`
**目标**：替换 `app/lib/pages/search_page.dart`

#### 具体改动：

**1. Import 调整**

删除：`flutter_riverpod`、`../../core/state/app_state.dart`、`../../services/voice_input_service.dart`

新增：
```dart
import '../theme/design_tokens.dart';
import '../widgets/in_app_overlay.dart';
import '../widgets/permission_flow_helper.dart';
import '../widgets/search_suggestion_list.dart';
import '../widgets/elder_bottom_nav.dart';
```

**2. 类改造**

旧版第 13 行：`ConsumerStatefulWidget` → `StatefulWidget`
旧版第 20 行：`ConsumerState<SearchPage>` → `State<SearchPage>`

**3. `_VoiceInputContent` 改造（Riverpod 最重的部分）**

`_VoiceInputContent` 旧版是 `ConsumerStatefulWidget`，使用 `ref.read(voiceInputServiceProvider).listen()` 和 `ref.watch(modeProvider)`。

改造方案：
- 改为 `StatefulWidget`
- `ref.read(voiceInputServiceProvider).listen()` → 替换为内联 mock：
  ```dart
  Future<String> _mockListen() => Future.delayed(const Duration(seconds: 2), () => '医保缴费');
  ```
- `ref.watch(modeProvider)` → 固定为长辈版颜色：`const Color(0xFFFF6D00)`

**4. 路由调整**

旧版第 42 行：`context.push('${AppRoutes.searchResult}?q=...')`
→ `context.push('/elder/search-result?q=${Uri.encodeComponent(trimmed)}')`

**5. 追加 `ElderBottomNav`**

旧版搜索页无底部导航，Scaffold 末尾加：
```dart
bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
```

### 3-B 新建搜索结果页（`app/lib/pages/search_result_page.dart`）

**来源**：`archive/scene-canvas-v1/lib/features/search/search_result_page.dart`
**策略**：无 Riverpod 依赖，直接复制后修改 import 和路由常量。

#### 具体改动：

**1. Import 调整**

删除：`../../core/router/app_router.dart`

新增：
```dart
import '../theme/design_tokens.dart';
import '../widgets/search_suggestion_list.dart';
```

**2. 路由常量替换**（全文替换）

- `AppRoutes.searchResult` → `'/elder/search-result'`
- `AppRoutes.socialInsurance` → `'/elder/shebao-jiaona'`
- `AppRoutes.pensionQuery` → `'/elder/shebao-query'`

旧版第 65 行：
```dart
context.replace('${AppRoutes.searchResult}?q=${Uri.encodeComponent(trimmed)}');
```
→
```dart
context.replace('/elder/search-result?q=${Uri.encodeComponent(trimmed)}');
```

**3. 追加 `ElderBottomNav`**

```dart
bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
```

### 3-C 新建 `search_suggestion_list.dart`

**来源**：`archive/scene-canvas-v1/lib/features/search/suggestion_list.dart`
**目标**：新建 `app/lib/widgets/search_suggestion_list.dart`

**改动**：只改 import（`design_tokens.dart` → `../theme/design_tokens.dart`）。无 Riverpod，直接复制。

### 3-D `router.dart` 追加路由

```dart
import 'pages/search_result_page.dart';

GoRoute(path: '/elder/search-result', pageBuilder: (c, s) => _slidePage(const SearchResultPage(), s)),
```

---

## 六、阶段 4：P2 — 社保查询服务主页

### 4-A 新建 `shebao_query_page.dart`

**来源**：`archive/scene-canvas-v1/lib/features/service/pension_query_page.dart`
**目标**：新建 `app/lib/pages/shebao_query_page.dart`

**注意**：旧版文件已命名为 `pension_query_page.dart`，当前项目中**已有** `app/lib/pages/pension_query_page.dart`（养老金查询结果页）。新文件命名为 `shebao_query_page.dart`，不要覆盖现有文件。

#### 具体改动：

**1. 类改名**

`class PensionQueryPage` → `class ShebaoQueryPage`（避免与现有 `pension_query_page.dart` 冲突）

**2. Import 调整**

删除：`package:go_router/go_router.dart`（保留） + 更新 design_tokens 路径
新增：
```dart
import '../theme/design_tokens.dart';
import '../services/agent_element_registry.dart';
import '../widgets/elder_bottom_nav.dart';
```

**3. 「企业职工基本养老保险」卡「基本信息」按钮注册**

旧版 `_InsuranceCard` 的「基本信息」按钮（第 241 行）：
```dart
TextButton(onPressed: null, child: const Text('基本信息', ...))
```
改为（仅针对养老保险卡）：
```dart
TextButton(
  key: AgentElementRegistry.register('btn_yanglao_jibenxinxi'),
  onPressed: () => context.push('/elder/pension-query'),
  child: const Text('基本信息', ...),
)
```

`_InsuranceCard` 需增加可选参数 `onBasicInfoTap`、`basicInfoKey`，在 `PensionQueryPage.build` 中只对「企业职工基本养老保险」卡传入这两个参数。

**4. 追加 `ElderBottomNav`**

```dart
bottomNavigationBar: const ElderBottomNav(currentIndex: 0),
```

**5. `router.dart` 追加路由**

```dart
import 'pages/shebao_query_page.dart';

GoRoute(path: '/elder/shebao-query', pageBuilder: (c, s) => _slidePage(const ShebaoQueryPage(), s)),
```

**6. 长辈版首页「养老金查询」入口调整**

`elder_home.dart`（阶段 1-A 完成后）中「我的常用」Tab 的「社保查询」卡改为跳 `/elder/shebao-query`：

`_EldFavoritesContent` 中「社保查询」`_EldServiceCard` 包上 `GestureDetector`，onTap 为 `context.push('/elder/shebao-query')`。

---

## 七、阶段 5：P2 — 我的页面

### 5-A `mine_page.dart` 全量替换

**来源**：`archive/scene-canvas-v1/lib/features/my/my_page.dart`
**目标**：替换 `app/lib/pages/mine_page.dart`

#### 具体改动：

**1. Import 调整**

删除：`flutter_riverpod`、`../../core/state/app_state.dart`、`../../core/router/app_router.dart`

新增：
```dart
import '../theme/design_tokens.dart';
import '../widgets/elder_bottom_nav.dart';
import '../widgets/persistent_banner.dart';
import '../services/auth_state.dart';
```

**2. 类改造**

旧版第 10 行：`class MyPage extends ConsumerWidget`
→ `class MyPage extends StatefulWidget`（需要 setState 给 PersistentBanner 的 dismiss 联动，但 PersistentBanner 已在内部管理 dismiss 状态，可改为 `StatelessWidget`）

**最简方案**：改为 `StatelessWidget`，直接读 `AuthState.instance`：

```dart
class MyPage extends StatelessWidget {
  const MyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authState = AuthState.instance;
    ...
  }
}
```

**3. `ref.watch(loginProvider)` 替换**

旧版第 15 行：`final login = ref.watch(loginProvider);`
→ 删除，后续用 `authState` 替代

旧版第 137 行：`login.isLoggedIn ? (login.userName ?? '*宇澄') : '游客'`
→ `authState.isLoggedIn ? (authState.userName ?? '*宇澄') : '游客'`

**4. 替换底部导航**

旧版第 87-99 行（FloatingActionButton + 旧版 ElderBottomNav）：
全部删除，改为：
```dart
bottomNavigationBar: const ElderBottomNav(currentIndex: 2),
```

（当前项目的 `ElderBottomNav` 已包含助手按钮，不需要额外的 FloatingActionButton。）

**5. `_MyActivitySection` 跳转逻辑**

旧版「我的草稿」和「办事记录」无跳转（`_ActivityIcon` 没有 onTap）。改造 `_ActivityIcon` 接受可选 `onTap`，在 `_MyActivitySection._items` 中对应项补充跳转：

```dart
// _MyActivitySection 改造：
static const _items = [
  (Icons.work_outline, '办事记录', '/elder/operation-logs'),
  (Icons.edit_note_outlined, '我的草稿', '/elder/drafts'),
  (Icons.history, '我的足迹', null),
  (Icons.bookmark_add_outlined, '我的订阅', null),
  (Icons.chat_bubble_outline, '诉求记录', null),
  (Icons.star_rate_outlined, '评价记录', null),
  (Icons.feedback_outlined, '反馈记录', null),
];

// _ActivityIcon 增加 onTap 参数
class _ActivityIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? route;
  ...
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: route != null ? () => context.push(route!) : null,
      child: Column(...),
    );
  }
}
```

**6. 退出登录按钮**

在 `_MySettingsSection` 最后（旧版第 690 行 `const SizedBox(height: Spacing.lg)` 之前）追加：

```dart
const Divider(height: 1, indent: 16),
ListTile(
  leading: Container(
    width: 32, height: 32,
    decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.12), shape: BoxShape.circle),
    child: const Icon(Icons.logout, color: Colors.red, size: 18),
  ),
  title: const Text('退出登录', style: TextStyle(fontSize: 15, color: Colors.red)),
  onTap: () {
    AuthState.instance.logout();
    context.go('/elder');
  },
),
```

---

## 八、阶段 6：P3 — 其他完善（低优先级）

### 6-A `face_auth_page.dart` 视觉还原（P3）

阶段 2-B 已完成全量替换，蓝色渐变背景和四角 L 形定位框在旧版已实现，随 2-B 一并完成，无额外工作。

### 6-B 长辈版首页 P3 区块（线下就近办/授权办/页脚）

这些区块在阶段 1-A 的 `Column` 中已包含（`_EldOfflineServiceSection`、`_EldAuthorizedServiceSection`、`_EldFooterSection`），随阶段 1 一并完成，无额外工作。

---

## 九、依赖关系图

```
阶段 0（共享组件）
├── 0-A InAppOverlay
├── 0-B SystemDialog
├── 0-C PermissionFlowHelper（依赖 0-A、0-B）
├── 0-D PersistentBanner（依赖 auth_state）
└── 0-E design_tokens（无依赖）
    │
    ├── 阶段 1（P0）
    │   ├── 1-A 长辈版首页（依赖 0-D、0-E）
    │   └── 1-B 社保费缴纳服务主页（依赖 0-E）
    │       └── 1-C router 更新
    │
    ├── 阶段 2（P1 登录链路）
    │   ├── 2-A login_page（依赖 0-A、0-E）
    │   ├── 2-B face_auth_page（依赖 0-A、0-C、0-E）
    │   └── 2-C verify_page（依赖 0-B、0-E）
    │
    ├── 阶段 3（P1 搜索链路）
    │   ├── 3-A search_page（依赖 0-A、0-C、0-E）
    │   ├── 3-B search_result_page（依赖 0-E，依赖 1-B 的路由存在）
    │   └── 3-C search_suggestion_list（无额外依赖）
    │
    ├── 阶段 4（P2 社保查询，依赖 1-C 路由）
    │   └── 4-A shebao_query_page（依赖 0-E）
    │
    └── 阶段 5（P2 我的页面）
        └── 5-A mine_page（依赖 0-D、0-E）
```

---

## 十、代理功能保护清单

以下 AgentElementRegistry key 在移植过程中**必须不被破坏**：

| key | 所在文件 | 绑定元素 | 移植阶段 | 保护策略 |
|-----|----------|---------|---------|---------|
| `select_jiaofei_duixiang` | `yibao_jiaofei_page.dart` | 缴费对象 Dropdown | **不改** | 文件不动 |
| `select_jiaofei_niandu` | `yibao_jiaofei_page.dart` | 缴费年度 Dropdown | **不改** | 文件不动 |
| `input_jiaofei_jine` | `yibao_jiaofei_page.dart` | 缴费金额 TextField | **不改** | 文件不动 |
| `input_id_card` | `yibao_jiaofei_page.dart` | 身份证号 TextField | **不改** | 文件不动 |
| `btn_go_payment` | `yibao_jiaofei_page.dart` | 去支付按钮 | **不改** | 文件不动 |
| `chk_agree_terms` | 当前 `login_page.dart` | 协议 Checkbox | **删除**（新版登录流程无此 checkbox） | 确认 agent_core.py/tools 中无引用 |
| `btn_face_login` | 当前 `login_page.dart` | 刷脸登录按钮 | **迁移**到 `face_auth_page.dart` 的「开始认证」按钮 | 阶段 2-B 时注册 |
| `btn_verify_login` | 当前 `login_page.dart` | 验证码登录按钮 | **迁移**到 `face_auth_page.dart` 的「其他方式认证」按钮 | 阶段 2-B 时注册 |
| `btn_wo_wei_ziji_jiao` | 新建 `shebao_jiaona_page.dart` | 「我为自己缴」按钮 | **新增** | 阶段 1-B 时注册 |
| `btn_yanglao_jibenxinxi` | 新建 `shebao_query_page.dart` | 「基本信息」按钮（养老保险卡） | **新增** | 阶段 4-A 时注册 |

**动作要求**：在阶段 2-A、2-B 执行前，确认 `backend/tools/` 目录中引用 `btn_face_login`、`btn_verify_login`、`chk_agree_terms` 的代码，更新或保留这些 key 使代理逻辑不断裂。

---

## 十一、风险点

### R1 命名冲突：`PensionQueryPage` 重复

当前 `app/lib/pages/pension_query_page.dart` 已存在且是养老金**结果**页。旧版 `pension_query_page.dart` 是社保查询**服务主页**。

**处置**：新文件命名为 `shebao_query_page.dart`，类名为 `ShebaoQueryPage`，避开冲突。不要用旧版文件名直接覆盖。

### R2 `design_tokens.dart` import 路径

旧版所有 Section 类都 import `../../core/theme/design_tokens.dart`。移植后改为 `../theme/design_tokens.dart`（或 `package:app/theme/design_tokens.dart`）。批量替换时注意不要遗漏内嵌子组件。

### R3 `PersistentBanner` 状态刷新

`PersistentBanner` 改为 `StatefulWidget` 后，其 `_dismissed` 状态是局部的。每次页面（`elder_home.dart`、`mine_page.dart`）重建时，`PersistentBanner` 会**重新初始化 `_dismissed = false`**。如果用户已关闭横幅然后切 Tab，横幅会重新出现。

**处置方案**：将 `_dismissed` 提升到静态变量或 `AuthState` 中：
```dart
// PersistentBanner 内部：
static bool _dismissed = false;  // 静态，整个 App 生命周期内保持
```
这样即使组件重建也记住关闭状态。

### R4 `AuthState` 无变更通知

`AuthState.instance` 是纯 Dart 单例，没有 `ChangeNotifier`。`PersistentBanner`（StatefulWidget）和 `MyPage`（StatelessWidget）读取 `AuthState.instance.isLoggedIn` 时，如果登录状态在 Widget 构建后改变，UI 不会自动刷新。

**当前可接受范围**：登录后 `context.go('/elder')` 触发页面重建，`isLoggedIn` 读到最新值。横幅刷新可能有延迟，但演示路径（登录 → 跳转首页 → 横幅消失）是页面重建触发的，正常工作。如需精确，可在 `AuthState` 加 `ChangeNotifier`，但超出当前任务范围。

### R5 旧版 `suggestion_list.dart` import 的 `app_theme.dart`

`search_page.dart` 旧版第 6 行 import 了 `../../core/theme/app_theme.dart`，但实际未使用（只在 `_VoiceInputContent` 的 `modeProvider` 处用到，该段已删除）。移植后删除此 import 即可。

### R6 `_EldOnlineGridItem` 点击区域改造

旧版 `_EldOnlineGridItem` 是纯展示组件，无点击回调。加入 `onTap` 后需要选择改造方式：
- 方案 A：外套 `GestureDetector`（最简，但点击区域是整个 Container）
- 方案 B：改为 `InkWell`（有水波纹反馈，UX 更好，推荐）

建议方案 B。

### R7 旧版 `LoginPage` 按钮行为差异

旧版 `login_page.dart`（`archive/`）中登录按钮**有输入时才可点**（`canLogin ? () => _showTermsOverlay(context) : null`），需求文档 F1 中说「登录按钮始终可点击」（点了才弹协议）。

**处置**：将 `onPressed: canLogin ? ...` 改为 `onPressed: () => _showTermsOverlay(context)`（始终可点，不管是否有输入）。

---

*方案结束。所有改动精确到文件路径和行号。开发执行时按阶段顺序推进，不要跨阶段并行（共享组件必须先于业务页面完成）。*
