# 浙里办长辈版 — 完美复刻计划

> 主笔：PM · 技术章节由 architect 联合审核  
> 更新日期：2026-04-17  
> 适用范围：Phase 1 ～ Phase 4 全程参考

---

## 一、截图 → Flutter 资源映射表

共 32 张截图，覆盖 11 个路由页面的全部静态状态与弹窗。  
`SplashPage` 无对应截图（纯代码启动逻辑，不可截图对比）。

| # | 截图文件名 | Flutter 路由 | Flutter 页面类 | 页面状态 / 弹窗类别 | 备注 |
|---|-----------|-------------|---------------|-------------------|------|
| 1 | `主页面.jpg` | `/home` | `StandardHomePage` | 默认状态 | 标准版首页；主色 `#2D74DC`；含"长辈版"入口按钮 |
| 2 | `长辈版主页面-热门服务.jpg` | `/elder` | `ElderHomePage` | Tab=热门服务（默认）· 顶部可见区 | 主色 `#FF6D00`；Tab 索引 0 |
| 3 | `长辈版主页面-我的常用.jpg` | `/elder` | `ElderHomePage` | Tab=我的常用 · 顶部可见区 | Tab 索引 1 |
| 4 | `长辈版主页面-我的订阅.jpg` | `/elder` | `ElderHomePage` | Tab=我的订阅 · 顶部可见区 | Tab 索引 2 |
| 5 | `长辈版主页面-往下滑动一段.jpg` | `/elder` | `ElderHomePage` | Tab=热门服务 · 滚动段 1 | 热门服务 Tab 下的滚动体拼接段一 |
| 6 | `长辈版主页面-往下滑动两段.jpg` | `/elder` | `ElderHomePage` | Tab=热门服务 · 滚动段 2 | 拼接段二 |
| 7 | `长辈版主页面-往下滑动三段.jpg` | `/elder` | `ElderHomePage` | Tab=热门服务 · 滚动段 3（底部） | 拼接段三；包含页脚区域 |
| 8 | `长辈版主页面-立即登录弹窗.jpg` | `/elder` | `ElderHomePage` | **InAppOverlay** — 立即登录提示浮层 | 未登录进入 `/elder` 时触发；非阻塞，可关闭 |
| 9 | `长辈版-我的页面.jpg` | `/my` | `MyPage` | 顶部可见区（滚动初始位置） | 长辈版底部导航"我的"Tab |
| 10 | `长辈版-我的页面-往下滑动一段.jpg` | `/my` | `MyPage` | 滚动段 1 | — |
| 11 | `长辈版-我的页面-往下滑动两段.jpg` | `/my` | `MyPage` | 滚动段 2 | — |
| 12 | `长辈版-我的页面-往下滑动三段.jpg` | `/my` | `MyPage` | 滚动段 3（底部） | — |
| 13 | `登录页面.jpg` | `/login` | `LoginPage` | 默认状态（条款未勾选） | 点击登录按钮触发条款弹窗 |
| 14 | `登录页面-同意条款弹窗.jpg` | `/login` | `LoginPage` | **InAppOverlay** — 同意条款浮层 | 非阻塞；点"同意并继续"跳 FaceAuthPage |
| 15 | `刷脸身份验证页面（开始认证其他方式认证）.jpg` | `/login/face-auth` | `FaceAuthPage` | 初始状态：双按钮（开始认证 / 其他方式认证） | 两条登录分支的分叉点 |
| 16 | `刷脸身份验证页面-请求刷脸认证弹窗.jpg` | `/login/face-auth` | `FaceAuthPage` | **InAppOverlay** — 请求刷脸认证浮层 | 点"开始认证"后触发；非阻塞 |
| 17 | `刷脸身份验证页面-请求使用摄像头弹窗（手机系统弹窗）.jpg` | `/login/face-auth` | `FaceAuthPage` | **SystemDialog** — 摄像头权限弹窗（自绘 Android 样式） | 阻塞式；同意后进刷脸动效；Web 端自绘，不调真权限 API |
| 18 | `刷脸验证页面-（认证任务：眨眨眼摇摇头，屏幕变色）.jpg` | `/login/face-auth` | `FaceAuthPage` | 动效状态：眨眼/摇头 + 屏幕变色动画 | Phase 3 做动效；Phase 1/2 先用静态占位 |
| 19 | `验证码页面.jpg` | `/login/verify` | `VerifyPage` | 默认状态（手机号已填入，等待发送验证码） | 备选登录分支 |
| 20 | `验证码页面-验证码弹窗（手机弹窗）.jpg` | `/login/verify` | `VerifyPage` | **SystemDialog** — 验证码确认弹窗（自绘 Android 样式） | 阻塞式；输入确认后跳 ElderHomePage |
| 21 | `搜索页面.jpg` | `/search` | `SearchPage` | 空状态（未输入任何关键词） | 含麦克风按钮入口 |
| 22 | `搜索页面-输入医保缴费.jpg` | `/search` | `SearchPage` | 输入状态（query=医保缴费） | 键盘弹出；联想词列表 |
| 23 | `搜索页面-输入养老金查询.jpg` | `/search` | `SearchPage` | 输入状态（query=养老金查询） | 联想词列表与医保缴费不同 |
| 24 | `搜索页面-获取麦克风权限.jpg` | `/search` | `SearchPage` | **InAppOverlay** — 麦克风权限引导浮层 | 非阻塞；"去开启"触发系统弹窗 |
| 25 | `搜索页面-获取麦克风权限弹窗（手机系统弹窗）.jpg` | `/search` | `SearchPage` | **SystemDialog** — 麦克风系统权限弹窗（自绘 Android 样式） | 阻塞式 |
| 26 | `搜索页面-麦克风说话按钮弹窗.jpg` | `/search` | `SearchPage` | **InAppOverlay** — 麦克风录音浮层（说话中） | 非阻塞；麦克风权限已授予后触发 |
| 27 | `搜索结果页面-输入医保缴费.jpg` | `/search/result` | `SearchResultPage` | query=医保缴费 的结果列表 | 结果含"社保费缴纳"条目 |
| 28 | `搜索结果页面-输入养老金查询.jpg` | `/search/result` | `SearchResultPage` | query=养老金查询 的结果列表 | 结果含"社保查询"条目 |
| 29 | `社保费缴纳服务页面.jpg` | `/service/social-insurance` | `SocialInsurancePage` | 主页（服务入口列表） | 由医保缴费搜索结果进入 |
| 30 | `社保费缴纳服务-我为自己缴页面.jpg` | `/service/social-insurance` | `SocialInsurancePage` | 子状态：我为自己缴 | 页内子导航，非新路由（待 architect 确认） |
| 31 | `社保费缴纳服务-缴费记录页面.jpg` | `/service/social-insurance` | `SocialInsurancePage` | 子状态：缴费记录 | 页内子导航 |
| 32 | `社保查询服务页面.jpg` | `/service/pension-query` | `PensionQueryPage` | 默认状态 | 由养老金查询搜索结果进入 |

---

## 二、完整流程图（文字版）

### 主线：刷脸登录路径

```
[SplashPage /]
  ↓ 自动跳转（~1.5s）
[StandardHomePage /home]  ← 标准版首页，主色 #2D74DC
  ↓ 点击「长辈版」入口按钮
[ElderHomePage /elder]  ← 未登录 → 触发「立即登录」InAppOverlay
  ↓ 弹窗点击「立即登录」
[LoginPage /login]  ← 条款默认未勾选
  ↓ 点击「登录」按钮（未同意条款）→ 触发「同意条款」InAppOverlay
  ↓ 弹窗点击「同意并继续」
[FaceAuthPage /login/face-auth]  ← 双按钮：开始认证 / 其他方式认证
  ↓ 点击「开始认证」→ 触发「请求刷脸认证」InAppOverlay
  ↓ 弹窗点击「同意并继续」→ 触发「摄像头权限」SystemDialog（自绘 Android 样式）
  ↓ SystemDialog 同意
  ↓ 进入刷脸动效：眨眼/摇头 → 屏幕变色 → 认证成功
[ElderHomePage /elder]  ← 已登录，立即登录弹窗不再出现
```

### 备选：验证码登录路径

```
[FaceAuthPage /login/face-auth]
  ↓ 点击「其他方式认证」（注：此处弹窗截图未收录，Phase 2 补充）
  ↓ 选择验证码方式
[VerifyPage /login/verify]  ← 手机号已预填
  ↓ 点击「发送验证码」→ 触发「验证码确认」SystemDialog（自绘 Android 样式）
  ↓ 输入验证码 → 确认
[ElderHomePage /elder]  ← 已登录
```

### 搜索分支 A：医保缴费路径

```
[ElderHomePage /elder]  ← 已登录
  ↓ 点击搜索入口
[SearchPage /search]  ← 空状态，含麦克风按钮
  ↓ 输入「医保缴费」
[SearchPage /search]  ← 输入状态（联想词列表）
  ↓ 点击搜索 / 回车
[SearchResultPage /search/result?q=医保缴费]
  ↓ 点击「社保费缴纳」结果
[SocialInsurancePage /service/social-insurance]  ← 主页
  ├─ 点击「我为自己缴」→ 子状态：我为自己缴
  └─ 点击「缴费记录」→ 子状态：缴费记录
```

### 搜索分支 B：养老金查询路径

```
[SearchPage /search]
  ↓ 输入「养老金查询」
[SearchResultPage /search/result?q=养老金查询]
  ↓ 点击「社保查询」结果
[PensionQueryPage /service/pension-query]
```

### 搜索页麦克风流程

```
[SearchPage /search]
  ↓ 点击麦克风按钮（首次）
  → 触发「麦克风权限引导」InAppOverlay（非阻塞）
  ↓ 点击「去开启」
  → 触发「麦克风系统权限」SystemDialog（自绘，阻塞）
  ├─ 同意 → 触发「麦克风录音浮层」InAppOverlay → 语音输入
  └─ 拒绝 → 回到 SearchPage 空状态
```

### 长辈版内部导航（底部 Tab）

```
[ElderHomePage /elder]  ←→  [MyPage /my]
     底部导航：首页 Tab            底部导航：我的 Tab
```

---

## 三、页面优先级与实施顺序

排序依据：**影响面**（被多少个流程路径依赖）× **视觉复杂度**（截图段数 × 弹窗数）

| 优先级 | 页面 | 路由 | 截图数 | Phase | 优先理由 |
|-------|------|------|--------|-------|---------|
| P1 | `ElderHomePage` | `/elder` | 8 | Phase 1–2 | 核心页；3 Tab + 3 段滚动 + 立即登录弹窗；所有流程必经 |
| P2 | `StandardHomePage` | `/home` | 1 | Phase 1–2 | 应用入口；不做则无法进入长辈版 |
| P3 | `LoginPage` | `/login` | 2 | Phase 1–2 | 登录态全局影响；含同意条款弹窗 |
| P4 | `FaceAuthPage` | `/login/face-auth` | 4 | Phase 1–2 | 主登录路径；含两套弹窗（InAppOverlay + SystemDialog）；Phase 3 补动效 |
| P5 | `SearchPage` | `/search` | 6 | Phase 1–2 | 核心功能入口；3 输入状态 + 3 弹窗状态；麦克风流程分支 |
| P6 | `SearchResultPage` | `/search/result` | 2 | Phase 1–2 | 搜索分流节点；决定跳社保还是养老金 |
| P7 | `SocialInsurancePage` | `/service/social-insurance` | 3 | Phase 2 | 医保缴费路径终点；含 3 子状态 |
| P8 | `MyPage` | `/my` | 4 | Phase 2 | 底部导航第二项；3 段滚动 |
| P9 | `PensionQueryPage` | `/service/pension-query` | 1 | Phase 2 | 养老金查询终点；相对独立 |
| P10 | `VerifyPage` | `/login/verify` | 2 | Phase 2–3 | 备选登录分支；Phase 3 补完整流程 |
| P11 | `SplashPage` | `/` | 0 | Phase 1 | 启动页逻辑最简单，无截图对比要求 |

---

## 四、各页面"完美复刻"验收标准

每项标准均为**可勾选的验收条件**，Phase 2 像素级还原时逐项核对。

---

### SplashPage（`/`）

- [ ] 主色与 loading 动效符合标准版风格
- [ ] ~1.5s 后自动跳转 `/home`，不需要用户操作
- [ ] 不重复跳转（路由保护）

---

### StandardHomePage（`/home`）

- [ ] 主色 `#2D74DC`（蓝色）贯穿顶栏与主要交互元素
- [ ] 顶栏：logo、搜索框入口、通知图标
- [ ] 「长辈版」专属入口按钮可见且可点击，点击跳转 `/elder`
- [ ] 服务网格区：至少一排服务图标占位正确
- [ ] 底部导航与截图一致

**登录 Banner（PersistentBanner）**
- [ ] 底部导航上方常驻横条：深色胶囊背景 + 灰色文字「登录浙里办，享受更多服务」+ 蓝色「立即登录」胶囊按钮
- [ ] Banner 右侧有「×」关闭按钮；关闭后本次 session 不再出现
- [ ] Banner 不带蒙板，不阻塞下层任何交互
- [ ] 已登录时 Banner 不显示

**对照截图**：`主页面.jpg`（底部可见 banner 区域）

---

### ElderHomePage（`/elder`）

**AppBar**
- [ ] 右上角只有「个人频道」胶囊按钮（带刷新/同步图标）
- [ ] **无搜索 icon**（已从旧版设计中删除）

**常驻固定区域（不随 Tab 切换变化）**
- [ ] 政务服务热线卡片：独立白色卡片，位于 TabBar **上方**，常驻可见
- [ ] 「线上一站办」区域：常驻，Tab 切换不影响
- [ ] 「线下就近办」区域：常驻，Tab 切换不影响
- [ ] 「授权办」区域：常驻，Tab 切换不影响
- [ ] 页脚区域：常驻

**Tab 区（仅影响 Tab 紧邻下方的一个栏目）**
- [ ] TabBar 是一张独立白色卡片的顶部，3 个 Tab：热门服务 / 我的常用 / 我的订阅
- [ ] Tab 切换仅影响「浙里医保等」栏目内容（如「住址变动落户 / 权益记录查询 / 查看全部」）
- [ ] 默认选中「热门服务」
- [ ] 各 Tab 内容独立（不共用滚动位置）

**整页滚动（3 段拼接）**
- [ ] 全页为单一 `SingleChildScrollView`；3 段截图对应 3 个 Section Widget 顺序堆叠
- [ ] 段一 / 二 / 三无内容重叠，无分页断点

**登录 Banner（PersistentBanner）**
- [ ] 底部导航上方常驻横条（与 StandardHomePage 同规格）
- [ ] 未登录时可见；已登录时不显示；`×` 关闭后 session 内不再出现

**底部导航（3 项）**
- [ ] 左：首页（跳转 `/elder`）
- [ ] 中：特殊大圆搜索/麦克风按钮（比两侧 Tab 大一圈），跳转 `/search`
- [ ] 右：我的（跳转 `/my`）
- [ ] 主色 `#FF6D00`（橙色）

**对照截图**：`长辈版主页面-热门服务.jpg`、`-我的常用.jpg`、`-我的订阅.jpg`、`-往下滑动一/二/三段.jpg`、`-立即登录弹窗.jpg`（共 8 张）

---

### MyPage（`/my`）

- [ ] 顶部区块：头像 / 昵称 / 登录状态
- [ ] 3 段拼接滚动（同 ElderHomePage 热门服务 Tab）
- [ ] 段一～段三无内容重叠，无分页断点
- [ ] 主色 `#FF6D00`
- [ ] 底部导航显示当前选中「我的」

**对照截图**：`长辈版-我的页面.jpg`、`-往下滑动一/二/三段.jpg`（共 4 张）

---

### LoginPage（`/login`）

- [ ] 手机号输入框
- [ ] 「登录」按钮：默认不可点击状态（未输入手机号时置灰）
- [ ] 点击登录（手机号已填、条款未勾选）→ 触发同意条款 **InAppOverlay**
- [ ] 同意条款浮层：内容文字、「同意并继续」按钮、可关闭
- [ ] 点「同意并继续」→ 跳转 `/login/face-auth`

**对照截图**：`登录页面.jpg`、`登录页面-同意条款弹窗.jpg`

---

### FaceAuthPage（`/login/face-auth`）

**初始状态**
- [ ] 「开始认证」按钮
- [ ] 「其他方式认证」入口（文字链或次要按钮）

**刷脸主路径**
- [ ] 点「开始认证」→ 触发请求刷脸认证 **InAppOverlay**（非阻塞）
- [ ] InAppOverlay：说明文字 + 「同意并继续」按钮
- [ ] 点「同意并继续」→ 触发摄像头权限 **SystemDialog**（自绘 Android 圆角对话框，阻塞）
- [ ] SystemDialog 同意 → 进入动效状态
- [ ] 动效状态（Phase 1 静态占位，Phase 3 实现）：眨眼/摇头提示 → 屏幕变色动画
- [ ] 认证成功 → 跳转 `/elder`（已登录）

**备选路径**
- [ ] 点「其他方式认证」→ 弹出选择弹窗（截图未收录，Phase 2 补全） → 跳转 `/login/verify`

**对照截图**：`刷脸身份验证页面（开始认证其他方式认证）.jpg`、`-请求刷脸认证弹窗.jpg`、`-请求使用摄像头弹窗.jpg`、`刷脸验证页面.jpg`

---

### VerifyPage（`/login/verify`）

- [ ] 手机号输入区（或已预填）
- [ ] 「发送验证码」按钮
- [ ] 点击发送 → 触发验证码确认 **SystemDialog**（自绘 Android 样式，阻塞）
- [ ] 输入验证码 + 确认 → 跳转 `/elder`（已登录）

**对照截图**：`验证码页面.jpg`、`验证码页面-验证码弹窗（手机弹窗）.jpg`

---

### SearchPage（`/search`）

**三种输入状态**
- [ ] 空状态：搜索框为空，热门搜索词展示，麦克风按钮可见
- [ ] 输入状态（医保缴费）：联想词列表与截图一致
- [ ] 输入状态（养老金查询）：联想词列表与截图一致

**麦克风流程（3 弹窗）**
- [ ] 点击麦克风（首次）→ 触发权限引导 **InAppOverlay**（非阻塞底部浮层）
- [ ] 点「去开启」→ 触发麦克风 **SystemDialog**（自绘，阻塞）
- [ ] 同意权限 → 触发录音 **InAppOverlay**（说话中浮层，非阻塞）
- [ ] 拒绝权限 → 回到空状态，不崩溃

**跳转**
- [ ] 点击搜索（医保缴费）→ `/search/result?q=医保缴费`
- [ ] 点击搜索（养老金查询）→ `/search/result?q=养老金查询`

**对照截图**：`搜索页面.jpg`、`-输入医保缴费.jpg`、`-输入养老金查询.jpg`、`-获取麦克风权限.jpg`、`-获取麦克风权限弹窗.jpg`、`-麦克风说话按钮弹窗.jpg`

---

### SearchResultPage（`/search/result`）

- [ ] query=医保缴费：结果列表含「社保费缴纳」类条目，点击跳 `/service/social-insurance`
- [ ] query=养老金查询：结果列表含「社保查询」类条目，点击跳 `/service/pension-query`
- [ ] 两种 query 的结果列表样式一致，内容不同

**对照截图**：`搜索结果页面-输入医保缴费.jpg`、`搜索结果页面-输入养老金查询.jpg`

---

### SocialInsurancePage（`/service/social-insurance`）

- [ ] 主页面：服务入口列表（至少「我为自己缴」「缴费记录」两个可见入口）
- [ ] 「我为自己缴」子状态：内容与截图一致
- [ ] 「缴费记录」子状态：内容与截图一致
- [ ] 三个状态间切换不触发路由跳转（页内导航，见技术章节 Q1）
- [ ] 返回按钮可回到 SearchResultPage

**对照截图**：`社保费缴纳服务页面.jpg`、`-我为自己缴页面.jpg`、`-缴费记录页面.jpg`

---

### PensionQueryPage（`/service/pension-query`）

- [ ] 页面布局与截图一致（查询表单或结果展示区）
- [ ] 返回按钮可回到 SearchResultPage

**对照截图**：`社保查询服务页面.jpg`

---

## 五、技术章节（架构决策 + 实施顺序原因）

> 本章由 architect 联合确认。✅ 技术三问已由 architect 回复，本节为最终结论。

### 5.1 三个关键架构问题的结论（architect 确认）

#### Q1：SocialInsurancePage 三子状态 → 页面内部 `IndexedStack`，不用子路由

**结论：** 使用页面内部状态（`IndexedStack`），不拆子路由。

- 三个子状态（主页 / 我为自己缴 / 缴费记录）是同一页面内的 Tab/底部标签切换，不是用户可书签/分享的独立目的地。
- 拆子路由会使 go_router 配置膨胀，且 URL 变化对 Web demo 无实际价值。
- `IndexedStack` 保持各子页面 Widget 树不被销毁，切换无闪烁，符合原版行为。
- **后续风险：** 如需深链直达「缴费记录」，届时补路由参数。Phase 复刻阶段不需要。

#### Q2：ElderHomePage Tab + 滚动并存 → 两个维度物理隔离，不需要 `NestedScrollView`

**结论：** `Scaffold > AppBar(bottom: TabBar) + TabBarView`，每个 Tab 内部独立 `SingleChildScrollView > Column`。

- **水平维度**：`TabController` 管理 Tab 切换，事件由 `TabBar` 消费。
- **垂直维度**：每个 Tab 内容区的 `SingleChildScrollView` 独立处理，互不影响。
- **不需要 `NestedScrollView`**：该组件用于"AppBar 随滚动折叠"场景；截图显示长辈首页 AppBar 和 TabBar 是常驻固定的，不折叠。
- 3 段截图 = 同一 Tab body 内 3 个 Section Widget（`_TopBannerSection` / `_HotServiceGridSection` 等）顺序堆叠，不是 3 个路由。
- Flutter 手势竞技场（gesture arena）对横向/纵向手势天然分离，无需额外处理。

#### Q3：立即登录弹窗触发时机 → `addPostFrameCallback` + `ref.read`（一次性检查）

**结论：** 在 `initState` 里注册 `WidgetsBinding.addPostFrameCallback`，回调中用 `ref.read` 一次性检查登录态。

```dart
// initState 内：
WidgetsBinding.instance.addPostFrameCallback((_) {
  if (!ref.read(loginProvider).isLoggedIn) {
    // show InAppOverlay
  }
});
```

- **不用 `initState` 直接调用**：首帧未完成时 `context` 未就绪，直接 `showDialog` 会报错。
- **不用 `ref.listen`**：`listen` 用于响应状态变化；此处是"进入时检查一次"，误用 `listen` 会在登录态后续变化时重复触发弹窗。

---

### 5.2 长页滚动 Widget 组织规范

**结论：** 每个语义区块拆成私有 Widget，内联在 `SingleChildScrollView > Column` 下。不用 Sliver，不用固定高度占位。

| 规范 | 说明 |
|------|------|
| Section 命名 | 按截图语义命名，如 `_TopBannerSection` / `_HotServiceGridSection` / `_ActivityCardSection` |
| 适用页面 | `ElderHomePage` 各 Tab 内容 + `MyPage`（各 3 段截图 = 3 个 Section Widget） |
| 不用 Sliver | 长辈首页是固定数量的语义区块，非无限列表，Sliver 复杂性无收益 |
| 不用固定高度占位 | Phase 1 能用，Phase 2 贴皮时全部要拆，迁移成本高 |

---

### 5.3 全局状态 Provider 粒度

**结论：** 维持 2 个独立 Provider，Tab 和搜索词不上全局。

| 状态 | 方案 | 理由 |
|------|------|------|
| 登录态 | `loginProvider`（已有） | 跨页读写，需全局 |
| 当前模式（标准/长辈） | `modeProvider`（已有） | 影响主题 + 路由入口，需全局 |
| Tab 选中项 | 局部 `TabController` | 不需跨页持久，导航离开后重置符合原版行为 |
| 搜索关键词 | 路由参数传递 | `SearchPage → SearchResultPage` 是单次跳转，不需 Provider |

不合并为一个 `AppStateNotifier`：合并会导致任何子状态变化触发全页面重绘，Phase 2 帧率损耗明显。

---

### 5.4 11 页实施顺序与依赖关系

```
SplashPage（无依赖，最先）
  └─→ StandardHomePage（路由起点，入口关键）
        └─→ ElderHomePage（依赖 modeProvider + TabController 结构）
              └─→ LoginPage（依赖 loginProvider）
                    ├─→ FaceAuthPage（主分支，依赖 LoginPage）
                    └─→ VerifyPage（备选分支，可与 FaceAuthPage 并行）
SearchPage（可独立推进，依赖 VoiceInputService mock）
  └─→ SearchResultPage（依赖 SearchPage 路由参数）
SocialInsurancePage（依赖 ServiceRepository mock）
PensionQueryPage（与 SocialInsurancePage 并行，同依赖 ServiceRepository）
MyPage（依赖 loginProvider，可与搜索线并行）
```

| 阶段 | 页面（批次） | 技术先决条件 |
|------|------------|------------|
| Phase 1（第 1 批） | `SplashPage` → `StandardHomePage` | 最简单，验证路由基础通路 |
| Phase 1（第 2 批） | `ElderHomePage`（骨架 + 弹窗） | `loginProvider` 就绪；`TabController` + `SingleChildScrollView` 架构确定 |
| Phase 1（第 3 批） | `LoginPage` → `FaceAuthPage`（静态） | 依赖 `InAppOverlay` + `SystemDialog` 组件族骨架（Phase 0 已建） |
| Phase 1（第 4 批） | `SearchPage` → `SearchResultPage` | 依赖路由 query 参数传递；`VoiceInputService` mock 就绪 |
| Phase 1（第 5 批） | `SocialInsurancePage` + `PensionQueryPage` + `MyPage` | 依赖 SearchResultPage 分流逻辑；`ServiceRepository` mock 就绪 |
| Phase 2 | 全部 11 页像素级还原 | Phase 1 路由全通；按 P1→P11 优先级顺序逐页贴皮 |
| Phase 3 | `FaceAuthPage` 动效 + `VerifyPage` 完整 + 长辈版动效 | Phase 2 贴皮完成；动效最后做，不影响 Widget 结构 |

---

### 5.5 复刻完美度技术瓶颈（提前暴露）

| 风险点 | 影响 | 建议决策 |
|--------|------|---------|
| **中文字体字重** | Flutter Web 默认不加载 Noto Sans SC，中文字重会有偏差 | Phase 2 引入项目级字体文件（`assets/fonts/`），~2MB 字体资源，需用户确认是否接受 |
| **系统弹窗自绘精度** | Android 原生对话框有精确圆角（8dp）、阴影层级、按钮分割线，是 Phase 2 最大工作量黑洞 | Phase 2 优先对齐圆角和按钮样式，阴影可近似 |
| **长辈版大字号** | 长辈版字号比标准版大约 20–30%，不是 `textScaleFactor`，需在 design token 里单独定义 `AppTextStyle.elder*` | 当前 `design_tokens.dart` 已有结构，Phase 2 补全 |
| **底部安全区** | 截图含 Android 虚拟键区域，Flutter Web 无此区域，底部导航栏位置会偏低 | Web 端给 `BottomNavigationBar` 显式加固定 `padding` 补偿 |
| **手势兼容性** | 下拉刷新在 Web 鼠标模式下不可触发；长按手势无法鼠标模拟 | 原版截图无下拉刷新，可不实现；如有长按则加鼠标右键适配 |

---

## 六、UI 元素类型定义与完整清单

### 三类 UI 元素定义

| 类型 | 特征 | 阻塞？ | 关闭方式 | 跨页存在？ |
|------|------|-------|---------|----------|
| `SystemDialog` | 全屏遮罩 + 自绘 Android 原生对话框外观 | **是** | 必须点按钮选择 | 否 |
| `InAppOverlay` | 底部/中部浮层，有半透明蒙板 | **否** | 手势下滑或点「×」 | 否 |
| `PersistentBanner` | 常驻横条，**无蒙板**，不遮挡下层交互 | **否** | 点「×」，关闭后 session 内不再出现 | **是**（贯穿所有页面） |

三类在代码中必须是**三套独立组件族**，不共用基类。

---

### 弹窗 / Banner 完整清单（共 10 条）

**SystemDialog（3 条）**

| # | 名称 | 触发页面 | 对应截图 |
|---|------|---------|---------|
| S1 | 摄像头系统权限 | `FaceAuthPage` | `刷脸身份验证页面-请求使用摄像头弹窗.jpg` |
| S2 | 验证码确认 | `VerifyPage` | `验证码页面-验证码弹窗.jpg` |
| S3 | 麦克风系统权限 | `SearchPage` | `搜索页面-获取麦克风权限弹窗.jpg` |

**InAppOverlay（5 条）**

| # | 名称 | 触发页面 | 对应截图 |
|---|------|---------|---------|
| I1 | 同意条款 | `LoginPage` | `登录页面-同意条款弹窗.jpg` |
| I2 | 请求刷脸认证 | `FaceAuthPage` | `刷脸身份验证页面-请求刷脸认证弹窗.jpg` |
| I3 | 麦克风权限引导 | `SearchPage` | `搜索页面-获取麦克风权限.jpg` |
| I4 | 麦克风录音浮层 | `SearchPage` | `搜索页面-麦克风说话按钮弹窗.jpg` |
| I5 | 其他认证方式选择 | `FaceAuthPage` | 无（截图未收录，Phase 2 补全） |

**PersistentBanner（1 条）**

| # | 名称 | 出现页面 | 对应截图 |
|---|------|---------|---------|
| P1 | 立即登录 Banner | `StandardHomePage` + `ElderHomePage`（及所有未登录页面） | `主页面.jpg`（底部）、`长辈版主页面-立即登录弹窗.jpg` |

**注：** I5「其他认证方式选择」无对应截图，页面逻辑文档仅提及存在此弹窗，Phase 2 时根据原版 App 观察补全样式。

---

## 七、Phase 2 实施计划

> Phase 1 完成 11 页灰块线框结构，Phase 2 目标：按 32 张截图逐页像素级贴皮。  
> 本节按**依赖顺序**拆批次——地基先行，通用组件次之，逐页贴皮在后，验收收尾。

---

### P2-A · Token 补齐 + 全项目魔数替换

**工作量：** `xs`（无视觉改变，纯定义 + 替换）

**目的：** 贴皮阶段所有颜色/字号/间距/圆角必须走 token，否则后续多处重复手写魔数、Phase 3 修一处漏十处。

**涉及文件：**
- `lib/core/theme/design_tokens.dart`（新增 token）
- `lib/core/widgets/system_dialog.dart`
- `lib/core/widgets/in_app_overlay.dart`
- `lib/core/widgets/persistent_banner.dart`
- `lib/core/widgets/phone_frame.dart`

**TODO 条目（原文引自 `docs/TODO.md`）：**
- `AppFontSize` 补 `tiny=11` / `caption=13` 两个 token（`standard_home_page.dart` / `elder_home_page.dart` / `persistent_banner.dart` 共 8+ 处散落硬编码）
- `Spacing` 补 `xl2=20`（`system_dialog.dart` 里用了，当前无 token）
- `AppRadius` 补 `phone=24`（`phone_frame.dart` 用，当前裸数字）
- `AppColors` 补 `phoneBg=0xFF1E1E1E`（`phone_frame.dart` 用）
- `system_dialog.dart` / `in_app_overlay.dart` / `persistent_banner.dart` 里所有魔数替换为 token 引用

**依赖：** 无（第一批，不依赖任何其他 Phase 2 产出）

**验收标准：**
- [ ] `flutter analyze` 0 issues
- [ ] `grep -r "Color(0x" lib/core/widgets/` 结果为空（弹窗组件族无裸颜色）
- [ ] `design_tokens.dart` 新增 4 个 token，名称与值与 TODO 一致

---

### P2-B · 通用组件抽取 + 代码结构清理

**工作量：** `s`

**目的：** 减少后续贴皮时重复代码；`PermissionFlowHelper` 一次抽取，`SearchPage` 和 `FaceAuthPage` 贴皮时直接复用三段式流程，不重写两遍。

**涉及文件：**
- `lib/core/widgets/permission_flow_helper.dart`（新建）
- `lib/features/home/elder_home_page.dart`
- `lib/features/search/search_page.dart`
- `lib/features/search/search_result_page.dart`
- `lib/features/my/my_page.dart`
- `lib/features/login/login_page.dart`、`face_auth_page.dart`、`search_result_page.dart`、`social_insurance_page.dart`、`pension_query_page.dart`（ConsumerWidget 降级复查）

**TODO 条目（原文引自 `docs/TODO.md`）：**
- `_EldTabCardSection` IndexedStack 改用 `ListenableBuilder(listenable: tab)` 局部重建（当前 `_tab.addListener(setState)` 每帧全页重建，虽不影响正确性但开销冗余）
- `_EldToolBarSection` 加 `const` 构造器（build 体是纯 const Widget 树）
- `_ResultTabRow` 加 `const` 构造器
- `_MyActivitySection` / `_MyCertSection` / `_MyManagementSection` / `_MyRecommendSection` / `_MySettingsSection` 加 const 构造器
- 考虑把 `SearchPage` 麦克风 chain 和 `FaceAuthPage` 刷脸 chain 抽共用的 `PermissionFlowHelper`（三段式 Overlay→SystemDialog→Overlay）
- Phase 1 终验收前复查 6 个 `ConsumerWidget` 页面（`LoginPage` / `FaceAuthPage` / `SearchPage` / `SearchResultPage` / `SocialInsurancePage` / `PensionQueryPage`）是否还需要 `ref`，未用的降级回 `StatelessWidget`

**依赖：** P2-A（token 补齐后代码里无魔数，结构更清晰）

**验收标准：**
- [ ] `flutter analyze` 0 issues
- [ ] `PermissionFlowHelper` 存在，并被 SearchPage + FaceAuthPage 引用
- [ ] `_EldTabCardSection` 使用 `ListenableBuilder` 而非 `addListener(setState)`
- [ ] 6 个复查页面无多余 `ref` 引用

---

### P2-C · 字体引入 + StandardHomePage / ElderHomePage 贴皮

**工作量：** `l`（截图 9 张，ElderHomePage 结构复杂，字体引入有配置成本）

**对照截图（9 张）：**
- `主页面.jpg`
- `长辈版主页面-热门服务.jpg`、`-我的常用.jpg`、`-我的订阅.jpg`
- `长辈版主页面-往下滑动一段.jpg`、`-往下滑动两段.jpg`、`-往下滑动三段.jpg`
- `长辈版主页面-立即登录弹窗.jpg`

**TODO 条目（原文引自 `docs/TODO.md`）：**
- `PersistentBanner.bannerButton` 在长辈模式下读 `modeProvider` 改用 `elderPrimary`（截图里长辈版 banner 按钮是橙色而非蓝色）
- Banner 文字颜色从 `Colors.white` 改为灰色（对齐截图）
- 长辈版 AppBar「个人频道」pill 加刷新/同步图标（对齐截图）
- 长辈版底部 FAB 颜色从 `Colors.grey[500]` 改为 `AppColors.elderPrimary`（对齐截图）

**额外必做（PROJECT_PLAN §五.5 技术瓶颈）：**
- 引入 Noto Sans SC 字体文件到 `assets/fonts/`，在 `pubspec.yaml` 注册（~2MB，用户已接受）
- 长辈版大字号常量补入 design token（`AppTextStyle.elder*`，比标准版大 20–30%）

**依赖：** P2-A（token 就绪）、P2-B（ListenableBuilder 优化就绪）

**视觉检查点：**
- [ ] 标准版顶栏主色 `#2D74DC`
- [ ] 长辈版主色全面替换为 `#FF6D00`（顶栏、FAB、banner 按钮、Tab 选中指示器）
- [ ] Banner 按钮：标准版蓝色胶囊 / 长辈版橙色胶囊
- [ ] Banner 文字颜色为灰色（非白色）
- [ ] 「个人频道」pill 右侧有刷新/同步图标
- [ ] 中文字体渲染为 Noto Sans SC（无系统字体 fallback 锯齿）
- [ ] 3 段拼接截图区块位置与原图无明显错位（对比侧放）

---

### P2-D · LoginPage / FaceAuthPage / VerifyPage 贴皮

**工作量：** `m`（截图 8 张，含弹窗 4 个）

**对照截图（8 张）：**
- `登录页面.jpg`、`登录页面-同意条款弹窗.jpg`
- `刷脸身份验证页面（开始认证其他方式认证）.jpg`、`-请求刷脸认证弹窗.jpg`、`-请求使用摄像头弹窗.jpg`、`刷脸验证页面.jpg`
- `验证码页面.jpg`、`验证码页面-验证码弹窗.jpg`

**TODO 条目（原文引自 `docs/TODO.md`）：**
- `LoginPage` 登录按钮 guard：手机号空时置灰不可点（batch 3 reviewer 发现）
- `FaceAuthPage._AuthenticatingView` "模拟认证成功 → 长辈版首页"按钮文案替换为正式占位（batch 3 architect 发现）
- `VerifyPage` 补"发送验证码"按钮（当前跳过该步直接展示 OTP 输入态；batch 3 reviewer 发现）
- `LoginPage` 底部"其他证件 / 新用户注册 / 忘记密码 / 登录遇到问题 / 其他登录方式"辅助链接目前纯静态文字，Phase 2 按需决定是否联通

**依赖：** P2-A（token）、P2-B（PermissionFlowHelper，供 FaceAuthPage 刷脸 chain 复用）

**视觉检查点：**
- [ ] 登录页背景色、输入框圆角与截图一致；手机号空时按钮置灰
- [ ] 同意条款 InAppOverlay 圆角、遮罩透明度与截图一致
- [ ] FaceAuthPage 刷脸请求 InAppOverlay 样式对齐
- [ ] SystemDialog（摄像头 / 验证码）圆角 8dp、按钮分割线、文字样式对齐 Android 原生风格
- [ ] VerifyPage 有"发送验证码"按钮，输入框布局与截图一致

---

### P2-E · SearchPage / SearchResultPage 贴皮

**工作量：** `m`（截图 8 张，6 种状态 + 麦克风 chain）

**对照截图（8 张）：**
- `搜索页面.jpg`、`-输入医保缴费.jpg`、`-输入养老金查询.jpg`
- `搜索页面-获取麦克风权限.jpg`、`-获取麦克风权限弹窗.jpg`、`-麦克风说话按钮弹窗.jpg`
- `搜索结果页面-输入医保缴费.jpg`、`搜索结果页面-输入养老金查询.jpg`

**TODO 条目（原文引自 `docs/TODO.md`）：**
- `search_page.dart _VoiceInputContent` 升级 StatefulWidget，`listen()` 期间显示"说话中..."占位（消除 800ms 空窗）
- `search_page.dart _VoiceInputContent` 麦克风按钮颜色读 `modeProvider`（标准版进入时当前是橙色会冲突）
- `SearchPage` 联想词精确匹配改为前缀/模糊匹配（输入"医保"应也能出现联想）
- `search_page.dart / search_result_page.dart` 多处 `Color(0xFF...)` 硬编码改用 `AppColors` 常量；搜索框 `borderRadius(18)` 走 token

**依赖：** P2-A（token）、P2-B（PermissionFlowHelper，供麦克风 chain 复用）

**视觉检查点：**
- [ ] 搜索框圆角、背景色对齐截图；输入状态下联想词列表样式正确
- [ ] 麦克风按钮颜色：标准版蓝色 / 长辈版橙色
- [ ] 三个弹窗（权限引导 / 系统权限 / 录音浮层）样式对齐对应截图
- [ ] 搜索结果页两种 query 列表内容不同，条目样式一致
- [ ] 联想词输入"医保"可出现含"医保"词的联想结果

---

### P2-F · SocialInsurancePage / PensionQueryPage / MyPage 贴皮

**工作量：** `m`（截图 8 张，含 3 段长页滚动）

**对照截图（8 张）：**
- `社保费缴纳服务页面.jpg`、`-我为自己缴页面.jpg`、`-缴费记录页面.jpg`
- `社保查询服务页面.jpg`
- `长辈版-我的页面.jpg`、`-往下滑动一段.jpg`、`-往下滑动两段.jpg`、`-往下滑动三段.jpg`

**TODO 条目（原文引自 `docs/TODO.md`）：**
- `MyPage` FAB 颜色 `Colors.grey[700]` —— 截图里像灰，但 reviewer 批次 5 建议改 `elderPrimary`，Phase 2 上真机再定

**依赖：** P2-A（token）、P2-C（字体、长辈版大字号 token 就绪，MyPage 会用）

**视觉检查点：**
- [ ] 社保费缴纳主页样式对齐，IndexedStack 三子状态（主页 / 我为自己缴 / 缴费记录）各自对齐对应截图
- [ ] 社保查询页布局与截图一致
- [ ] MyPage 3 段拼接与截图无明显错位
- [ ] MyPage FAB 颜色经浏览器对照截图后定色（灰 or 橙）

---

### P2-终 · 验收专项 + 低优清理 + 打 tag

**工作量：** `s`

**内容：**

**测试补齐**（引自 `docs/TODO.md` 「收尾测试待补」）：
- P0：`PersistentBanner` 四种状态 widget test（未登录+未关 / 已登录 / dismiss / dismiss 后登出）
- P0：`loginProvider` + `loginBannerDismissedProvider` 状态流转 unit test
- P1：`ElderHomePage` Tab 切换 `IndexedStack.index` 正确、非 Tab 区块不重建 widget test
- P1：`SplashPage` 1500ms 自动跳 + `_navigated` 防重复 widget test + fake timer
- P2：`AppRouter` 11 条路由全部可导航 + ShellRoute 包 PhoneFrame integration test
- P2：`AppTheme.of(mode)` 主色切换 unit test

**对照材料生成：**
- [ ] 32 张「原图 vs 复刻」对比截图生成并存档（`docs/复刻对照/`）
- [ ] 每张对比截图通过还原度检查清单（PROJECT_PLAN §七 全部勾选）

**低优清理：**
- [ ] 删除各页面 `_DevNavSection`（Phase 1 开发导航面板，Phase 2 不再需要）
- [ ] `flutter analyze` 0 issues 最终确认

**收尾动作：**
- [ ] 打 `v1.0-baseline` tag（后续创新底座）

**依赖：** P2-A ~ P2-F 全部通过

---

### 批次汇总表

| 批次 | 核心内容 | 工作量 | 对照截图数 | 前置依赖 |
|------|---------|-------|----------|---------|
| P2-A | Token 补齐 + 魔数替换 | `xs` | 0 | 无 |
| P2-B | 通用组件 + 代码清理 | `s` | 0 | P2-A |
| P2-C | 字体引入 + 标准版/长辈版首页贴皮 | `l` | 9 | P2-A, P2-B |
| P2-D | 登录流程 3 页贴皮 | `m` | 8 | P2-A, P2-B |
| P2-E | 搜索流程 2 页贴皮 | `m` | 8 | P2-A, P2-B |
| P2-F | 服务页 + 我的页贴皮 | `m` | 8 | P2-A, P2-C |
| P2-终 | 测试补齐 + 对照材料 + tag | `s` | 32（全量） | P2-C ~ P2-F |

**注：** P2-D / P2-E / P2-F 三批无相互依赖，可在 P2-B 完成后并行推进（由 team-lead 决定是否并行）。

---

*技术章节（§五）已由 architect 联合确认，2026-04-17。*
