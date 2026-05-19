# 未登录态访问拦截 — 现状审查与方案

> **日期**：2026-05-19
> **作者**：architect
> **触发**：用户反馈未登录态仍可点搜索框 / 服务入口

---

## 1. 结论速览

**当前唯一的登录守卫**只在 `mine_page` 一处（未登录展示 `_LoginPrompt` 内嵌页）。其他长辈版入口——**搜索框**、**社保查询**、**健康医保**——都直接 `context.push`，没有任何拦截。`router.dart` **没有 redirect 守卫**，标准版搜索框已是 `_showTodo` 占位（无需改）。

**推荐方案**：**入口拦截 + 复用 SystemDialog**——新增工具方法 `LoginGuard.tryNavigate(context, route)`，未登录时弹 SystemDialog（与刷脸授权同款 UI），按"去登录 / 取消"。调用点只需 1 行替换，不改 widget 结构、不动路由器。**总改动 3 处入口 + 1 个新文件，约 50 行。**

---

## 2. 现有登录态机制盘点

| 文件:行号 | 机制 | 说明 |
|---|---|---|
| `app/lib/core/state/app_state.dart:13-27` | `LoginNotifier` + `loginProvider` | Riverpod；持 `LoginState{isLoggedIn, userName}`；登录/登出时同步写 `AuthState.instance` 单例 |
| `app/lib/services/auth_state.dart:5` | `AuthState.instance.isLoggedIn` | 单例 mirror，**可在非 ConsumerWidget 处直接读** |
| `app/lib/pages/mine_page.dart:17, 63-83` | "我的"页内嵌 `_LoginPrompt`（96px 头像 + "您还未登录" + "去登录"橙按钮） | **唯一现有的拦截 UI** |
| `app/lib/widgets/persistent_banner.dart:14-17` | 底部条幅 "登录享受更多服务" + "立即登录" | 非阻塞提示，非拦截 |
| `app/lib/router.dart` | **无** `redirect` / `refreshListenable` | 无全局守卫 |

---

## 3. 未登录可访问但不应可访问的入口清单

> ✅ = 当前已拦截 ｜ ⚠️ = **未拦截但应拦截** ｜ — = 不需拦截

### 长辈版首页 `app/lib/pages/elder_home.dart`

| 入口 | 行号 | 当前行为 | 评估 |
|---|---|---|---|
| 顶部"西湖区" / "个人频道" | 48, 76 | `_showTodo` 占位 SnackBar | — |
| 标准版切换 | 124 | `context.go(home)` + 模式切换 | — |
| 工具栏 扫一扫/消息 | 164, 165 | `_showTodo` | — |
| 工具栏 常规版 | 166 | 切到标准版 | — |
| Tab 卡片 | 256, 400, 409, 439 | `_showTodo` | — |
| **Tab "我的常用" → 社保查询** | **448** | `context.push(AppRoutes.shebaoQuery)` | **⚠️** |
| **线上一站办 → 健康医保** | **613** | `context.push(AppRoutes.shebaoJiaona)` | **⚠️** |
| 线上一站办其余项 | 614 | `_showTodo` | — |
| 线下就近办 | 736 | `_showTodo` | — |
| 授权服务 | 836, 898 | `_showTodo` | — |
| **顶部搜索框** | **942** | `context.push(AppRoutes.search)` | **⚠️** |

### 长辈版底部导航 `app/lib/widgets/elder_bottom_nav.dart`

| 入口 | 行号 | 当前行为 | 评估 |
|---|---|---|---|
| 首页 Tab | 26 | `context.go(elderHome)` | — |
| 我的 Tab | 32 | `context.go(my)` → mine_page **内嵌 _LoginPrompt** | ✅ |

### 标准版首页 `app/lib/pages/standard_home.dart`

| 入口 | 行号 | 当前行为 | 评估 |
|---|---|---|---|
| 搜索框 | 96 + 37-41 | `_showTodo`（"该功能正在建设中"） | ✅ 已是占位，无需改 |
| 扫一扫 / 卡包 | 177, 178 | `_showTodo` | — |
| 长辈版切换 | 179 | 模式切换 | — |
| 服务网格 8 项 | 287-291 | 全部 `_showTodo`（_ServiceGridItem 无 onTap 真实路由） | — |
| 底部 Nav 4 Tab | 495-499 | 全部 `_showTodo` | — |

**结论**：标准版当前是"品牌门面"——所有真实业务入口都被 `_showTodo` 占位（与 ISSUES.md #39 一致），**这次只改长辈版**。

### 搜索 / 服务详情页

| 页面 | 路由 | 当前 | 评估 |
|---|---|---|---|
| `search_page.dart` | `/search` | 无登录检查 | 由入口（elder_home:942）拦截后即可，本身不需改 |
| `search_result_page.dart` | `/search/result` | 无登录检查 | 同上 |
| `shebao_query_page.dart` | `/service/shebao-query` | 无登录检查 | 同上 |
| `shebao_jiaona_page.dart` | `/service/shebao-jiaona` | 无登录检查 | 同上 |
| `pension_query_page.dart` | `/service/pension-query` | 无登录检查 | **无入口直接到达**，但 Web 端可粘 URL；接受为已知限制 |
| `yibao_jiaofei_page.dart` | `/service/yibao-jiaofei` | 无登录检查 | 同上 |
| `yibao_query_page.dart` | `/service/yibao-query` | 无登录检查 | 同上 |

**未拦截入口共 3 处**：长辈版搜索框、社保查询、健康医保。

---

## 4. 方案对比

| 方案 | 改动量 | 代理 cmd_navigate 友好 | UX | 推荐 |
|---|---|---|---|---|
| **A. 入口拦截 + SystemDialog（推荐）** | 3 处入口 + 1 新文件 ~50 行 | 不直接覆盖代理，但代理 PRD 设定不会绕过登录 | 弹窗"请先登录 / 去登录" 用户感知强 | ⭐ |
| B. GoRouter `redirect` 全局守卫 | router.dart + 维护"受保护路由"列表 | ✅ 全覆盖 | 直接重定向 /login，"突然跳转"没提示 |  |
| C. 服务页 build 时包 `LoginRequiredGate`（5 页 + 新组件） | 5 页 + 1 新文件 | 部分（仍能进入页，再被拦） | 进入后才看到拦截，二段反馈 |  |
| **A+B（保底完美）** | A 的改动 + 5 行 redirect | ✅ | 入口先弹窗，URL 直接访问被 redirect | demo 后可选升级 |

**选 A**：与当前架构（SystemDialog 已用于刷脸授权）一致，UI 复用、改动最小、提示清晰，适合答辩演示。**B 作为后续可选升级**，论文里可说"轻量级入口守卫 + 全局路由守卫两层"，加分。但首轮先做 A。

---

## 5. 详细修复指引

### 5.1 新建 `app/lib/widgets/login_guard.dart`（约 35 行）

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../router.dart';
import '../services/auth_state.dart';
import 'system_dialog.dart';

/// 入口级登录守卫：未登录时弹 SystemDialog 引导去登录。
/// 直接读 AuthState.instance.isLoggedIn（与 loginProvider 同步），
/// 调用方无需 WidgetRef，可在 StatelessWidget 中一行替换 context.push。
class LoginGuard {
  /// 已登录 → push 目标路由；未登录 → 弹"请先登录"对话框。
  static void tryNavigate(BuildContext context, String route) {
    if (AuthState.instance.isLoggedIn) {
      context.push(route);
      return;
    }
    SystemDialog.show(
      context,
      title: '请先登录',
      message: '该功能需要登录后才能使用，是否前往登录？',
      confirmLabel: '去登录',
      denyLabel: '取消',
      onConfirm: () => context.go(AppRoutes.login),
    );
  }
}
```

**关键设计**：
- 用 `AuthState.instance.isLoggedIn`（不用 `ref.read(loginProvider)`），**调用点不需要 WidgetRef**——这让无需把 `_EldFavoritesContent` / `_EldOnlineServiceSection` 等 `StatelessWidget` 改成 `ConsumerWidget`，**改动量最小**。
- `AuthState.instance` 在 `LoginNotifier.login/logout`（app_state.dart:18, 22）已同步更新，单例与 provider 永不漂移。
- 复用 `SystemDialog.show`（widgets/system_dialog.dart:72）—— UI 风格与刷脸授权对话框一致。
- 文案在一处定义，未来可调；"去登录"按钮 `context.go`（不是 push）避免回退到拦截前页面的副作用。

### 5.2 修改 `app/lib/pages/elder_home.dart`（3 处）

**新增 import**（约第 7 行后）：
```dart
import '../widgets/login_guard.dart';
```

**第 448 行**：
```dart
onTap: () => context.push(AppRoutes.shebaoQuery),
```
改为：
```dart
onTap: () => LoginGuard.tryNavigate(context, AppRoutes.shebaoQuery),
```

**第 613 行**：
```dart
? () => context.push(AppRoutes.shebaoJiaona)
```
改为：
```dart
? () => LoginGuard.tryNavigate(context, AppRoutes.shebaoJiaona)
```

**第 942 行**：
```dart
onTap: () => context.push(AppRoutes.search),
```
改为：
```dart
onTap: () => LoginGuard.tryNavigate(context, AppRoutes.search),
```

### 5.3 不动文件

- `app/lib/router.dart` — 不加 redirect
- `app/lib/pages/standard_home.dart` — 入口已是 `_showTodo`
- `app/lib/pages/search_page.dart` 及 5 个服务页 — 入口拦截后即可达成视觉目标

---

## 6. 视觉效果（SystemDialog 风格，复用现有组件）

```
┌─────────────────────────────────────┐
│  请先登录                            │  ← 18sp w600
│                                      │
│  该功能需要登录后才能使用，是否前往    │  ← 14sp（SystemDialog 内置）
│  登录？                              │
│                                      │
│                  取消    去登录       │  ← 橙色 TextButton
└─────────────────────────────────────┘
```

适老化考量：SystemDialog 当前内置字号偏小（标题 18 / 正文 14）。**建议同步把 SystemDialog 字号上调**，但这会影响所有用 SystemDialog 的地方（刷脸授权、麦克风授权）。**这次先用现状字号**，作为单独议题再处理（避免改动外溢）。

---

## 7. 边界 case

| 场景 | 行为 | OK? |
|---|---|---|
| 已登录用户点搜索 / 社保查询 / 健康医保 | 直接 `context.push` 正常进入 | ✓ |
| 未登录用户点上述任一入口 | 弹 SystemDialog "请先登录" | ✓ |
| 弹窗后点"去登录" | `context.go(AppRoutes.login)` → 登录页 | ✓ |
| 弹窗后点"取消" | dialog 关闭，留在长辈首页 | ✓ |
| 登录页登录成功 → AuthState 同步 → 用户再点入口 | 直接进入（不再弹窗） | ✓ |
| 登出后 → AuthState 同步 → 再点入口 | 重新弹窗 | ✓ |
| Web 端直接粘贴 `/service/shebao-query` URL | **不被拦截**（已知限制） | ⚠️ 接受 / 后续 A+B |
| 代理 cmd_navigate 到服务页 | **不被拦截**（代理走 GoRouter 直接 push） | ⚠️ 由代理 prompt 自行保证；当前 PRD 场景 2 代理本就是引导用户登录后再进 |

---

## 8. 工作量与测试 checklist

**工作量** ~20 min（1 新建 + 3 行替换 + 1 行 import）

**自测**：
- [ ] 未登录态进入长辈首页
- [ ] 点"搜索框" → 弹"请先登录" → 取消 → 留在首页
- [ ] 点"搜索框" → 弹 → 去登录 → 跳到 /login
- [ ] 点"社保查询" → 弹
- [ ] 点"健康医保" → 弹
- [ ] 完成登录后回到首页 → 上述三处可直接进入
- [ ] "我的"Tab 仍展示 `_LoginPrompt`（未受影响）
- [ ] 登出后再点入口 → 重新弹窗

---

## 9. 后续可选升级（不在本轮）

1. **GoRouter redirect 兜底**：在 `router.dart` 加 redirect，未登录访问受保护路由直接重定向 /login。覆盖 Web 端 URL 直访 + 代理 cmd_navigate 路径。改动 ~10 行。
2. **SystemDialog 适老化字号统一**：标题 18→24sp、正文 14→18sp，按钮 14→20sp。影响 4 处现有调用。
3. **`_LoginPrompt` 提取为通用 widget**：mine_page 与未来"页面级 guard" 共用。
4. **代理引导整合**：登录提示弹窗中加"让小浙帮我登录"按钮，触发 `scene_login_face` / `scene_login_verify` prompt。
