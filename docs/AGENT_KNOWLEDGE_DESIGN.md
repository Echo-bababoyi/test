# 代理流程知识 + 页面感知 — 全链路技术方案

> 版本 v2.0 · 2026-05-21 · architect（会话 15）
>
> 适用范围：小浙智能代理。从"按场景硬编码 + 字符串约定"升级为"**标准操作流程写死 + LLM 智能选起点 + 单一真相源 + 实时页面感知**"。
>
> **核心设计原则**：流程受控，LLM 仅做起点决策。代理不"自由发挥"，而是按标准操作手册执行，只根据用户当前位置决定从哪一步开始。

---

## 0. 目标与非目标

### 目标
1. 让代理在执行任意场景时，**严格按预定义的标准操作流程**运行，步骤、工具、措辞全部写死
2. 让代理**实时知道用户当前页面**，据此决定从标准流程的哪一步开始
3. 引导级（guide）在用户偏离起始页时也能用语言把用户先带回轨道
4. 杜绝"prompt 字符串与前端注册名漂移"类 bug（部署期校验）
5. 知识库扩展低成本：加新场景只动一份地图 + 一份剧本

### 非目标
- 不让 LLM 自己规划步骤序列（这正是本次最大的范式转变）
- 不引入向量检索 / RAG
- 不改 WebSocket 主干协议（仅新增 1 个入站消息）
- 不动 HITL、Overlay、AgentSession 等已稳定的子系统

### 范式转变（v1.0 → v2.0）

| 维度 | v1.0（自由发挥） | v2.0（标准流程） |
|---|---|---|
| 步骤序列 | LLM 根据"目标"自己拼 | **写死在 prompt 里编号 1-N** |
| 措辞 | LLM 自己想 | **写死在每步里** |
| 工具调用 | LLM 自己挑 | **每步指定哪个工具 + 参数模板** |
| LLM 决策 | 全程都在决策 | **仅决定"从第 N 步开始"** |
| 可复现性 | 每次输出可能不同 | 同起点必同输出 |

---

## 1. 全链路视角

### 1.1 当前链路（升级前）

```
用户输入 → 意图分类 → 用户确认 → execute_task
    └─ 加载 scene_*.txt 静态文件
    └─ LLM 一步步看 prompt 自行决定按哪个步骤、说什么、调什么工具
    └─ 每步 tool call → _push_tool_results → WS → 前端 cmd_*
```

**痛点**：硬编码"假设用户从 /elder 开始"；元素名前后端字符串约定易漂移；加新场景要改 3 处不一致就 bug。

### 1.2 升级后链路

```
用户输入 → 意图分类 → 用户确认 → execute_task
    └─ build_executor_prompt(scene_id, current_page)
        ├─ _EXECUTOR_PREFIX（不变）
        ├─ 场景剧本（标准操作流程 + 起点判断规则，从 scene_*.txt 读）
        └─ 【环境信息】（程序拼装注入：地图册 + 当前页 + 导航路径）
    └─ LLM 看完后：
        1. 查【环境信息】里的 current_page
        2. 对照"起点判断规则"决定从第 N 步开始
        3. 严格按剧本中第 N、N+1、N+2…步骤的预定工具 + 参数 + 措辞执行
        4. 不允许跳步、改措辞、改工具
    └─ HITL 循环、_push_tool_results 等不变
```

**关键变化**：
- 知识 → `backend/knowledge/pages.py`（**单一真相源**）
- scene_*.txt → "标准流程 + 起点规则"（每步固定，LLM 只选起点）
- prompt 动态注入"当前页 + 路径 + 涉及页面元素清单"
- 启动期校验：所有 prompt 里出现的 element_key / route 必须在 pages.py 中，否则启动失败

### 1.3 实时页面感知

```
用户跳页 → 前端 AgentSession.bindPage → 发 page_changed { current_page }
    → 后端 ws_handler._on_page_changed → agent_core.current_page = X
    → 下次 build_executor_prompt 自动用到最新位置
```

---

## 2. 页面知识库设计

### 2.1 数据结构

**`backend/knowledge/__init__.py`**（新建空文件）
**`backend/knowledge/pages.py`**（新建）

```python
"""Single source of truth for pages, elements, and navigation graph."""

from dataclasses import dataclass
from typing import Literal

ElementKind = Literal['button', 'input', 'checkbox', 'select', 'result_area', 'link', 'tab', 'card']


@dataclass(frozen=True)
class ElementSpec:
    key: str                       # 与前端 register() 字符串一致
    kind: ElementKind
    label: str                     # 用户在 UI 上看到的中文文字
    description: str = ''          # 给 LLM 看的语义说明
    sensitive: bool = False        # 是否敏感字段（驱动 fill_field_sensitive 选择）


@dataclass(frozen=True)
class Transition:
    """页面跳转规则：从当前页到 to_route 需要通过哪个元素操作。"""
    to_route: str
    via_element: str
    user_guidance: str             # 给用户的口播话术（标准流程会引用）


@dataclass(frozen=True)
class PageSpec:
    route: str
    page_id: str
    title: str
    description: str = ''
    elements: tuple[ElementSpec, ...] = ()
    transitions: tuple[Transition, ...] = ()


PAGES: dict[str, PageSpec] = {
    # ── 首页 ─────────────────────────────────────────────────────────────
    '/elder': PageSpec(
        route='/elder', page_id='elder_home', title='长辈版首页',
        description='浙里办长辈版主入口。无顶部登录入口，登录路径走底部"我的"Tab',
        elements=(
            ElementSpec(key='tab_my', kind='tab', label='我的',
                        description='底部导航第 2 个 Tab，进入 /my 个人页'),
            ElementSpec(key='card_yibao_hub', kind='card', label='健康医保',
                        description='首页"健康医保"网格项，进入医保枢纽页（/service/yibao-hub）'),
        ),
        transitions=(
            Transition('/my', via_element='tab_my',
                       user_guidance='请点屏幕底部"我的"按钮进入个人页'),
            Transition('/service/yibao-hub', via_element='card_yibao_hub',
                       user_guidance='请点首页"健康医保"图标进入医保服务页'),
        ),
    ),
    '/standard': PageSpec(
        route='/standard', page_id='standard_home', title='标准版首页',
        description='浙里办标准版主入口。当前仅作为品牌门面，跨版本入口为"长辈版"按钮',
        elements=(
            ElementSpec(key='btn_switch_elder', kind='button', label='长辈版',
                        description='Hero 区"长辈版"按钮，切换到长辈版首页'),
        ),
        transitions=(
            Transition('/elder', via_element='btn_switch_elder',
                       user_guidance='请点击"长辈版"按钮切换到长辈版'),
        ),
    ),

    # ── 我的页（未登录态登录引导）─────────────────────────────────────────
    '/my': PageSpec(
        route='/my', page_id='my', title='我的（未登录态）',
        description='未登录用户进入会看到橙色登录引导卡片，含"去登录"按钮跳 /login',
        elements=(
            ElementSpec(key='btn_go_login', kind='button', label='去登录',
                        description='_LoginPrompt 内橙色按钮，跳转到 /login 登录页'),
        ),
        transitions=(
            Transition('/login', via_element='btn_go_login',
                       user_guidance='请点橙色的"去登录"按钮进入登录页'),
        ),
    ),

    # ── 登录流 ───────────────────────────────────────────────────────────
    '/login': PageSpec(
        route='/login', page_id='login', title='登录页',
        description='输入手机号 / 勾选条款 / 点"登录"按钮进入刷脸认证页。'
                    '验证码登录入口在 /login/face 页的"其他方式认证"按钮',
        elements=(
            ElementSpec(key='chk_agree_terms', kind='checkbox', label='同意条款',
                        description='勾选表示同意《用户服务协议》和《隐私政策》'),
            ElementSpec(key='btn_login', kind='button', label='登录',
                        description='点击进入刷脸认证流程；未勾选条款会弹出条款浮层'),
        ),
        transitions=(
            Transition('/login/face', via_element='btn_login',
                       user_guidance='请勾选同意条款后点"登录"按钮进入刷脸页'),
        ),
    ),
    '/login/face': PageSpec(
        route='/login/face', page_id='login_face', title='刷脸认证页',
        description='打开摄像头检测人脸，完成眨眼 + 转头活体认证。'
                    '页面底部"其他方式认证"按钮可切到验证码登录页',
        elements=(
            ElementSpec(key='btn_face_login', kind='button', label='开始刷脸认证',
                        description='点击后弹出摄像头授权浮层'),
            ElementSpec(key='btn_other_auth', kind='button', label='其他方式认证',
                        description='切换到验证码登录页（/login/verify）'),
        ),
        transitions=(
            Transition('/login/verify', via_element='btn_other_auth',
                       user_guidance='请点底部"其他方式认证"按钮切到验证码登录'),
        ),
    ),
    '/login/verify': PageSpec(
        route='/login/verify', page_id='login_verify', title='验证码登录页',
        description='输入手机号 → 发送验证码 → 输入验证码 → 登录',
        elements=(
            ElementSpec(key='input_phone', kind='input', label='手机号'),
            ElementSpec(key='btn_send_code', kind='button', label='发送验证码',
                        description='点击后短信下发 6 位验证码到手机'),
            ElementSpec(key='input_verify_code', kind='input', label='验证码',
                        description='填入收到的 6 位短信验证码'),
            ElementSpec(key='btn_verify_login', kind='button', label='登录',
                        description='填完信息后点击完成登录'),
        ),
    ),

    # ── 业务枢纽页 ───────────────────────────────────────────────────────
    '/service/yibao-hub': PageSpec(
        route='/service/yibao-hub', page_id='yibao_hub', title='医保服务页',
        description='医保中间枢纽页，含"医保缴费"与"医保查询"两张入口卡片',
        elements=(
            ElementSpec(key='card_yibao_jiaofei_entry', kind='card', label='医保缴费',
                        description='进入医保缴费页（/service/yibao-jiaofei）'),
            ElementSpec(key='card_yibao_query_entry', kind='card', label='医保查询',
                        description='进入医保查询页（/service/yibao-query）'),
        ),
        transitions=(
            Transition('/service/yibao-jiaofei', via_element='card_yibao_jiaofei_entry',
                       user_guidance='请点"医保缴费"卡片进入缴费页'),
            Transition('/service/yibao-query', via_element='card_yibao_query_entry',
                       user_guidance='请点"医保查询"卡片进入查询页'),
        ),
    ),

    # ── 业务页 ───────────────────────────────────────────────────────────
    '/service/yibao-jiaofei': PageSpec(
        route='/service/yibao-jiaofei', page_id='yibao_jiaofei', title='医保缴费页',
        description='为本人或家属缴纳本年度城乡居民基本医疗保险',
        elements=(
            ElementSpec(key='select_jiaofei_duixiang', kind='select', label='缴费对象',
                        description='本人 / 家属'),
            ElementSpec(key='select_jiaofei_xianzhong', kind='select', label='险种',
                        description='默认城乡居民医疗保险'),
            ElementSpec(key='select_jiaofei_niandu', kind='select', label='缴费年度'),
            ElementSpec(key='select_jiaofei_dangci', kind='select', label='缴费档次',
                        description='一档 / 二档'),
            ElementSpec(key='input_id_card', kind='input', label='身份证号',
                        description='18 位居民身份证号', sensitive=True),
            ElementSpec(key='input_daili_name', kind='input', label='代办人姓名'),
            ElementSpec(key='input_daili_idcard', kind='input', label='代办人身份证号',
                        sensitive=True),
            ElementSpec(key='btn_go_payment', kind='button', label='去支付',
                        description='提交表单进入支付页（由用户亲手点击）'),
        ),
    ),
    '/service/pension-query': PageSpec(
        route='/service/pension-query', page_id='pension_query', title='养老金查询页',
        description='查询本月养老金发放情况。首页无入口，semi/full 级通过 cmd_navigate 直跳',
        elements=(
            ElementSpec(key='btn_query', kind='button', label='查询'),
            ElementSpec(key='result_pension_amount', kind='result_area', label='养老金金额',
                        description='查询返回的金额展示区'),
        ),
    ),
    '/service/yibao-query': PageSpec(
        route='/service/yibao-query', page_id='yibao_query', title='医保查询页',
        description='查询医保账户余额与缴费记录',
        elements=(
            ElementSpec(key='btn_query', kind='button', label='查询'),
            ElementSpec(key='result_yibao_amount', kind='result_area', label='医保信息'),
        ),
    ),
}


def page_by_route(route: str) -> PageSpec | None:
    return PAGES.get(route)


def find_path(from_route: str, to_route: str, max_hops: int = 4) -> list[Transition] | None:
    """BFS 找最短跳转路径。返回 Transition 列表（按执行顺序），或 None（不可达）。"""
    if from_route == to_route:
        return []
    visited = {from_route}
    queue: list[tuple[str, list[Transition]]] = [(from_route, [])]
    while queue:
        cur, path = queue.pop(0)
        if len(path) >= max_hops:
            continue
        page = PAGES.get(cur)
        if not page:
            continue
        for t in page.transitions:
            if t.to_route in visited:
                continue
            new_path = path + [t]
            if t.to_route == to_route:
                return new_path
            visited.add(t.to_route)
            queue.append((t.to_route, new_path))
    return None


def all_element_keys() -> set[str]:
    return {e.key for p in PAGES.values() for e in p.elements}


def all_routes() -> set[str]:
    return set(PAGES.keys())
```

### 2.2 元素清单（按实际 UI 对齐）

> **决策记录（2026-05-21）**：放弃虚构的顶部登录按钮 / 首页业务卡片 / /login 内验证码登录链接；改走实际 UI 提供的路径——底部"我的"Tab → /my 登录引导 → /login → /login/face 切验证码。

| Element key | 来源页面 | 当前前端注册 | 备注 |
|---|---|---|---|
| tab_my | /elder | **需补**（Phase 5）| 底部导航"我的"Tab；挂在 elder_bottom_nav.dart 第 28-33 行 _NavItem 外层 KeyedSubtree |
| card_yibao_hub | /elder | **需补** | 首页"健康医保"网格项；进入 /service/yibao-hub |
| btn_switch_elder | /standard | ✓ | standard_home.dart:11/182 已注册 |
| btn_go_login | /my | **需补** | _LoginPrompt 内橙色"去登录"按钮；mine_page.dart:138-160 外包 KeyedSubtree |
| chk_agree_terms | /login | ✓（login_page.dart:20 已注册）| |
| btn_login | /login | ✓ | login_page.dart:19 已注册 |
| btn_face_login | /login/face | ✓ | |
| btn_other_auth | /login/face | ✓ | 现作为切换到验证码登录页的入口 |
| input_phone | /login/verify | ✓ | |
| btn_send_code | /login/verify | ✓ | |
| input_verify_code | /login/verify | ✓ | |
| btn_verify_login | /login/verify | ✓ | |
| card_yibao_jiaofei_entry | /service/yibao-hub | **需补** | 枢纽页"医保缴费"卡片 |
| card_yibao_query_entry | /service/yibao-hub | **需补** | 枢纽页"医保查询"卡片 |
| select_jiaofei_* (4) | /service/yibao-jiaofei | ✓ | |
| input_id_card | /service/yibao-jiaofei | ✓ | |
| input_daili_name / idcard | /service/yibao-jiaofei | ✓ | |
| btn_go_payment | /service/yibao-jiaofei | ✓ | |
| btn_query | /service/pension-query + yibao-query | ✓（双注册冲突已知问题） | 见 §8.3 |
| result_pension_amount | /service/pension-query | ✓ | |
| result_yibao_amount | /service/yibao-query | ✓ | |

**已删除的虚构元素**（之前 v2.0 规划但实际 UI 不存在）：

- `btn_top_login`（/elder / /standard 都无顶部登录按钮）
- `card_yibao_jiaofei` / `card_pension_query` / `card_yibao_query`（/elder 上没有直达业务页的独立卡片）
- `link_verify_login`（/login 页无验证码登录链接，切换入口在 /login/face 的 btn_other_auth）

---

## 3. 页面感知机制

### 3.1 数据流

```
用户跳页（router push/replace/pop）
   ↓
前端：新页 AgentFab mount → initState PostFrameCallback →
       AgentSession.bindPage(...) →
       【新增】末尾发 page_changed { session_id, current_page }
   ↓
后端：ws_handler._on_page_changed → agent_core.set_current_page(...)
   ↓
后续 build_executor_prompt 拿到最新页 → 注入环境信息
```

### 3.2 后端协议扩展

**`backend/models.py`** 改动：
- `InboundMessageType` 枚举追加 `page_changed = "page_changed"`
- 新增：
  ```python
  class PageChangedPayload(BaseModel):
      session_id: str
      current_page: str
  ```
- `INBOUND_PAYLOAD_MAP` 字典追加映射

**`backend/ws_handler.py`** 改动：
- `_dispatch` 内 handler 字典追加 `InboundMessageType.page_changed: self._on_page_changed`
- 新增方法：
  ```python
  async def _on_page_changed(self, payload):
      logger.info("session=%s page_changed → %s", self.session_id, payload.current_page)
      if self._agent_core:
          self._agent_core.set_current_page(payload.current_page)
  ```
- `_on_agent_wake` 创建 AgentCore 时传入 `current_page=payload.current_page`

### 3.3 前端改动

**`app/lib/services/agent_session.dart`** bindPage 末尾追加（约 line 83 之后）：
```dart
if (_sessionId != null && WsClient.instance.isConnected) {
  WsClient.instance.send('page_changed', {
    'session_id': _sessionId,
    'current_page': currentPath ?? '',
  });
}
```

**关键守门**：只在 session 已建立 + WS 已连接时发，避免在 bindPage 早于 ensureSession 时空跑。

---

## 4. 剧本设计：标准流程 + 起点判断

### 4.1 剧本结构

每个 scene_*.txt 是三段式：

```
【目标】（一句话说明这个场景要完成什么）

【可用工具】（白名单 + 禁用工具警告）

【标准操作流程】（编号 1-N，每步明确：
  - 在什么页面执行（前置条件）
  - 调用哪个工具，传什么参数（element_key / target_route / value）
  - 配套的 voice_hint 措辞
）

【起点判断规则】（查表逻辑：
  - 用户当前在 X → 从第 N 步开始
  - 用户当前在 Y → 从第 M 步开始
  - 用户在其他页 → 兜底说"请先回到首页"，然后从第 1 步开始
）

【准则】（约束：不允许跳步、不允许改措辞、不允许改工具；每步之间等用户操作；结束语固定）
```

### 4.2 五个场景的完整新剧本

#### `scene_login_face.txt` （guide 级）

```
【目标】带用户完成刷脸登录准备（引导到 /login/face 并点开始刷脸）。

【可用工具】
- cmd_highlight、cmd_say
绝不能调用 cmd_navigate / fill_field_* / cmd_press_button / read_sms —— 未挂载。

【标准操作流程】

第 1 步（用户在 /elder / /standard / 其他非登录页）
  cmd_say(voice_hint="请点屏幕底部的'我的'按钮进入个人页")

第 2 步（用户在 /elder）
  cmd_highlight(element_key="tab_my", voice_hint="请点这个'我的'按钮", duration_ms=8000)

第 3 步（用户在 /my 且未登录）
  cmd_highlight(element_key="btn_go_login", voice_hint="请点橙色的'去登录'按钮进入登录页", duration_ms=8000)

第 4 步（用户在 /login）
  cmd_highlight(element_key="chk_agree_terms", voice_hint="请勾选'同意条款'", duration_ms=8000)

第 5 步（用户在 /login）
  cmd_highlight(element_key="btn_login", voice_hint="勾好后请点'登录'按钮进入刷脸", duration_ms=8000)

第 6 步（用户在 /login/face）
  cmd_highlight(element_key="btn_face_login", voice_hint="请点'开始刷脸认证'按钮", duration_ms=8000)

第 7 步（前置：摄像头授权浮层弹出）
  cmd_say(voice_hint="请点'同意'打开摄像头")

第 8 步（前置：活体检测开始）
  cmd_say(voice_hint="请正对屏幕，跟着提示眨眼、左右摇头")

【起点判断规则】
- /elder / /standard / 其他页 → 第 1 步
- /my → 第 3 步（跳过 1-2）
- /login → 第 4 步（跳过 1-3）
- /login/face → 第 6 步（跳过 1-5）
- 路径不可达 → 先 cmd_say("请先回到首页")，再从第 1 步

【准则】
- 严格按编号顺序执行
- 您不替用户点按 / 勾选 / 跳页
- 完成后回复："已引导您完成刷脸登录准备，请按提示操作"
```

#### `scene_login_verify.txt` （guide 级）

```
【目标】带用户完成验证码登录（路径需先到 /login/face 再切到 /login/verify，因为 /login 页无验证码登录链接）。

【可用工具】
- cmd_highlight、cmd_say
绝不能调用 cmd_navigate / fill_field_* / read_sms / cmd_press_button —— 未挂载。

【标准操作流程】

第 1 步（用户在 /elder / /standard / 其他非登录页）
  cmd_say(voice_hint="请点屏幕底部的'我的'按钮进入个人页")

第 2 步（用户在 /elder）
  cmd_highlight(element_key="tab_my", voice_hint="请点这个'我的'按钮", duration_ms=8000)

第 3 步（用户在 /my 且未登录）
  cmd_highlight(element_key="btn_go_login", voice_hint="请点橙色的'去登录'按钮进入登录页", duration_ms=8000)

第 4 步（用户在 /login）
  cmd_highlight(element_key="chk_agree_terms", voice_hint="请先勾选'同意条款'", duration_ms=8000)

第 5 步（用户在 /login）
  cmd_highlight(element_key="btn_login", voice_hint="勾好后请点'登录'按钮", duration_ms=8000)

第 6 步（用户在 /login/face）
  cmd_highlight(element_key="btn_other_auth", voice_hint="请点底部'其他方式认证'切到验证码登录", duration_ms=8000)

第 7 步（用户在 /login/verify）
  cmd_highlight(element_key="input_phone", voice_hint="请在这里输入您的手机号", duration_ms=8000)

第 8 步（用户在 /login/verify）
  cmd_highlight(element_key="btn_send_code", voice_hint="请点'发送验证码'按钮", duration_ms=8000)

第 9 步
  cmd_say(voice_hint="请查看您手机收到的短信，里面有 6 位数字验证码")

第 10 步（用户在 /login/verify）
  cmd_highlight(element_key="input_verify_code", voice_hint="请把验证码输入到这里", duration_ms=8000)

第 11 步（用户在 /login/verify）
  cmd_highlight(element_key="btn_verify_login", voice_hint="填好后请点这里登录", duration_ms=8000)

【起点判断规则】
- /elder / /standard / 其他页 → 第 1 步
- /my → 第 3 步
- /login → 第 4 步
- /login/face → 第 6 步（直接高亮"其他方式认证"切到验证码页）
- /login/verify → 第 7 步
- 路径不可达 → 先 cmd_say("请先回到首页")，再从第 1 步

【准则】
- 严格按编号顺序执行
- 不替用户输入手机号 / 验证码；不替用户点按钮
- 完成后回复："已引导您完成验证码登录步骤，请按提示操作"
```

#### `scene_yibao_jiaofei.txt` （semi/full 级）

```
【目标】帮用户填写医保缴费表单到"去支付"按钮前。

【可用工具】
- cmd_navigate（跳页）
- cmd_highlight、cmd_say
- fill_field_normal（普通字段代填）
- fill_field_sensitive（敏感字段代填，会触发授权暂停）
绝不能调用 cmd_press_button（去支付必须由用户亲手点击）。

【标准操作流程】

第 1 步（用户不在 /service/yibao-jiaofei）
  cmd_navigate(target_route="/service/yibao-jiaofei", voice_hint="好的，帮您打开医保缴费页面")

第 2 步（用户在 /service/yibao-jiaofei）
  fill_field_normal(field_key="select_jiaofei_duixiang", field_label="缴费对象", value=<用户原话中的"本人"或"家属"，必须取真实值>, voice_hint="已选择缴费对象")

第 3 步
  fill_field_normal(field_key="select_jiaofei_xianzhong", field_label="险种", value="城乡居民医疗保险", voice_hint="已选择险种")

第 4 步
  fill_field_normal(field_key="select_jiaofei_niandu", field_label="缴费年度", value=<用户原话中的年份；用户未指定则用当年>, voice_hint="已选择缴费年度")

第 5 步
  fill_field_normal(field_key="select_jiaofei_dangci", field_label="缴费档次", value=<用户原话中的"一档"或"二档"；未指定则用"一档">, voice_hint="已选择缴费档次")

第 6 步
  fill_field_sensitive(field_key="input_id_card", field_label="身份证号", value=<用户已授权的实际身份证号>, voice_hint="需要您授权填入身份证号")
  （注：本步会暂停等待用户授权，系统自动处理，您不必关心）

第 7 步
  cmd_highlight(element_key="btn_go_payment", voice_hint="请您点击'去支付'按钮", duration_ms=8000)

【起点判断规则】
- 用户不在 /service/yibao-jiaofei → 从第 1 步开始
- 用户已在 /service/yibao-jiaofei → 从第 2 步开始

【准则】
- 严格按编号顺序执行；只能在【起点判断规则】允许的位置开始，不能跳到中间随意步骤
- value 必须是真实数据，绝不允许使用方括号占位字符串（如 "[来自用户意图]"）
- 任何字段的 value 若不能确定，先 cmd_say 询问用户，拿到答案后再调对应的 fill_field 工具
- "去支付"按钮由用户亲手点击，您不代按
- 完成后回复："已帮您填好缴费表单，请点击'去支付'"
```

#### `scene_pension_query.txt` （semi/full 级）

```
【目标】帮用户查询本月养老金。

【可用工具】
- cmd_navigate、cmd_press_button、cmd_say

【标准操作流程】

第 1 步（用户不在 /service/pension-query）
  cmd_navigate(target_route="/service/pension-query", voice_hint="好的，帮您打开养老金查询页面")

第 2 步（用户在 /service/pension-query）
  cmd_press_button(button_key="btn_query", button_label="查询", voice_hint="正在为您查询养老金信息")

【起点判断规则】
- 用户不在 /service/pension-query → 从第 1 步
- 用户已在 /service/pension-query → 从第 2 步

【准则】
- 不允许跳步、不允许改措辞
- 完成后回复："已帮您发起养老金查询，请稍候"
- 查询结果由前端推送 query_result_ready，由系统自动播报，您不参与
```

#### `scene_yibao_query.txt` （semi/full 级）

```
【目标】帮用户查询医保信息。

【可用工具】
- cmd_navigate、cmd_press_button、cmd_say

【标准操作流程】

第 1 步（用户不在 /service/yibao-query）
  cmd_navigate(target_route="/service/yibao-query", voice_hint="好的，帮您打开医保查询页面")

第 2 步（用户在 /service/yibao-query）
  cmd_press_button(button_key="btn_query", button_label="查询", voice_hint="正在为您查询医保信息")

【起点判断规则】
- 用户不在 /service/yibao-query → 从第 1 步
- 用户已在 /service/yibao-query → 从第 2 步

【准则】
- 不允许跳步、不允许改措辞
- 完成后回复："已帮您发起医保查询，请稍候"
- 查询结果由系统自动播报
```

### 4.3 环境信息块（程序自动注入）

每次 `_build_executor_prompt` 时，自动拼出如下文本，附在场景剧本之后：

```
【环境信息】
用户当前在：{current_page}（{当前页标题}）
本场景目标页：{target_route}（{目标页标题}）— {目标页 description}

当前页可交互元素：
  {element_key}（{label}）— {description}  [敏感] / （无敏感）
  ...

目标页可交互元素：
  ...

导航路径（当前页 → 目标页）：
  第 1 跳：{user_guidance}（到达 {to_route}）
  第 2 跳：...
  （或："路径不可达"）
```

LLM 拿到这段信息后只做一件事：**查"起点判断规则"，确定从第 N 步开始**。

---

## 5. agent_core 改造

### 5.1 新增字段与方法

**`backend/agent_core.py`** 改动：

```python
class AgentCore:
    def __init__(self, session_id, ws_handler, trust_level='guide', current_page=''):
        ...
        self.current_page: str = current_page         # 新增字段
        ...

    def set_current_page(self, page: str) -> None:    # 新增方法
        self.current_page = page
        logger.info("session=%s current_page set to %s", self.session_id, page)

    async def execute_task(self, intent_summary: str) -> str:
        ...
        instructions = _build_executor_prompt(scene_id, self.current_page)   # 替换原 _load_scene_prompt 调用
        ...
```

### 5.2 prompt 拼装代码

新增模块级函数：

```python
SCENE_TARGET_ROUTE = {
    'login_face': '/login/face',
    'login_verify': '/login/verify',
    'yibao_jiaofei': '/service/yibao-jiaofei',
    'pension_query': '/service/pension-query',
    'yibao_query': '/service/yibao-query',
}


def _build_executor_prompt(scene_id: str, current_page: str) -> str:
    base = (_PROMPTS_DIR / SCENE_PROMPTS[scene_id]).read_text(encoding='utf-8')
    env_block = _render_environment_section(scene_id, current_page)
    return _EXECUTOR_PREFIX + base + '\n\n' + env_block


def _render_environment_section(scene_id: str, current_page: str) -> str:
    from backend.knowledge.pages import PAGES, page_by_route, find_path
    target_route = SCENE_TARGET_ROUTE.get(scene_id, '')
    target = page_by_route(target_route)
    cur = page_by_route(current_page)
    lines = ['【环境信息】']

    # 当前位置
    cur_label = f'（{cur.title}）' if cur else '（未知页面，建议先回首页）'
    lines.append(f'用户当前在：{current_page}{cur_label}')

    # 目标页
    if target:
        lines.append(f'本场景目标页：{target.route}（{target.title}）— {target.description}')

    # 当前页元素清单
    if cur and cur.elements:
        lines.append('')
        lines.append('当前页可交互元素：')
        for e in cur.elements:
            sens = '  [敏感]' if e.sensitive else ''
            desc = f' — {e.description}' if e.description else ''
            lines.append(f'  {e.key}（{e.label}）{desc}{sens}')

    # 目标页元素清单（如果不是同一页）
    if target and target.route != current_page and target.elements:
        lines.append('')
        lines.append('目标页可交互元素：')
        for e in target.elements:
            sens = '  [敏感]' if e.sensitive else ''
            desc = f' — {e.description}' if e.description else ''
            lines.append(f'  {e.key}（{e.label}）{desc}{sens}')

    # 导航路径
    if target and current_page != target_route:
        path = find_path(current_page, target_route)
        if path:
            lines.append('')
            lines.append('导航路径（当前页 → 目标页）：')
            for i, t in enumerate(path, 1):
                lines.append(f'  第{i}跳：{t.user_guidance}（到达 {t.to_route}）')
        else:
            lines.append('')
            lines.append('导航路径：当前位置不可达目标页（可能用户在偏远页面）')

    return '\n'.join(lines)
```

### 5.3 ws_handler 改动

`backend/ws_handler.py` `_on_agent_wake`：
```python
async def _on_agent_wake(self, payload):
    ...
    self._agent_core = AgentCore(
        session_id=self.session_id,
        ws_handler=self,
        trust_level=payload.trust_level,
        current_page=payload.current_page,    # 新增：传入初始 current_page
    )
    ...
```

`_dispatch` handler 字典追加 page_changed 映射（见 §3.2）。

---

## 6. 启动期校验

**`backend/agent_core.py`** 模块顶层（import 完之后、类定义之前）加：

```python
def _validate_prompts_against_knowledge() -> None:
    """启动期扫描所有 scene prompt，校验引用的 element_key / target_route 在 PAGES 中存在。"""
    import re
    from backend.knowledge.pages import all_element_keys, all_routes
    valid_keys = all_element_keys()
    valid_routes = all_routes()
    errors: list[str] = []
    for scene_id, filename in SCENE_PROMPTS.items():
        path = _PROMPTS_DIR / filename
        text = path.read_text(encoding='utf-8')
        for m in re.finditer(r'element_key\s*=\s*["\']([^"\']+)["\']', text):
            key = m.group(1)
            if key not in valid_keys:
                errors.append(f'{filename}: element_key="{key}" 未在 PAGES 中定义')
        for m in re.finditer(r'target_route\s*=\s*["\']([^"\']+)["\']', text):
            route = m.group(1)
            if route not in valid_routes:
                errors.append(f'{filename}: target_route="{route}" 未在 PAGES 中定义')
        # 校验 SCENE_TARGET_ROUTE 中的 route 都存在
    for scene_id, route in SCENE_TARGET_ROUTE.items():
        if route not in valid_routes:
            errors.append(f'SCENE_TARGET_ROUTE[{scene_id}]="{route}" 未在 PAGES 中定义')
    if errors:
        raise RuntimeError(
            'Prompt 与知识库不一致（请先同步 backend/knowledge/pages.py）：\n  '
            + '\n  '.join(errors)
        )


_validate_prompts_against_knowledge()   # 模块加载时执行
```

**效果**：服务启动 / pytest 启动 / 任何 import agent_core 的地方都会触发，错配在不到 1 秒内暴露。

---

## 7. 前端改动

### 7.1 必做：page_changed 上报（Phase 3）

**`app/lib/services/agent_session.dart`** `bindPage` 末尾（约 line 83 之后，debugPrint 之前/之后均可）：
```dart
if (_sessionId != null && WsClient.instance.isConnected) {
  WsClient.instance.send('page_changed', {
    'session_id': _sessionId,
    'current_page': currentPath ?? '',
  });
}
```

### 7.2 必做：补缺失的 element 注册（Phase 5）

> **决策（2026-05-21）**：按实际 UI 注册 element_key，不再新增虚构的顶部登录按钮、首页业务卡片、/login 验证码登录链接。登录走"底部'我的'Tab → /my → /login"路径，业务走"健康医保 → /service/yibao-hub → 子页"路径。

新增 register 调用并把 GlobalKey 挂到对应 widget：

| 文件 | 新增 register | 挂到哪个 widget |
|---|---|---|
| `app/lib/widgets/elder_bottom_nav.dart` | `tab_my` | "我的" `_NavItem`（line 28-33）外包 `KeyedSubtree`；需将 `ElderBottomNav` 改为 Stateful 以持有 GlobalKey |
| `app/lib/pages/elder_home.dart` | `card_yibao_hub` | "健康医保" 网格项（line 658 区域，跳 /service/yibao-hub）外包 `KeyedSubtree` |
| `app/lib/pages/mine_page.dart` | `btn_go_login` | `_LoginPrompt` 内"去登录" `PressScaleWrapper`（line 138-160）外包 `KeyedSubtree`；需将 `_LoginPrompt` 改为 Stateful |
| `app/lib/pages/yibao_hub_page.dart` | `card_yibao_jiaofei_entry` + `card_yibao_query_entry` | 枢纽页两张 `_HubCard`（line 28-43） |

**已不再补的元素**（实际 UI 不存在，已从 PAGES 中删除）：

- ~~`btn_top_login`（/elder + /standard）~~ — 两版首页都没有顶部登录按钮
- ~~`card_yibao_jiaofei` / `card_pension_query` / `card_yibao_query`（/elder）~~ — /elder 上没有直达业务页的独立卡片，统一走 /service/yibao-hub 枢纽
- ~~`link_verify_login`（/login）~~ — /login 页无此链接，验证码登录入口在 /login/face 的 `btn_other_auth`

### 7.3 可推迟：ElementKeys 常量化 + page_meta 代码生成（Phase 4）

**新建 `backend/tools/sync_element_keys.py`**（脚本）：从 PAGES 生成两份 Dart 文件：
- `app/lib/services/agent_element_keys.dart`（常量类 `ElementKeys`）
- `app/lib/services/page_meta.g.dart`（PageMeta 常量字典）

然后批量改 18 个业务页：
- `register('xxx')` → `register(ElementKeys.xxx)`
- 删除手写的 `page_meta.dart`，改用 `.g.dart`

**收益**：编译期约束 element_key 拼写，根除字符串漂移。
**代价**：触及 18 个文件，工作量较散。可放到论文答辩后再做。

---

## 8. 改动清单（按实施顺序）

### Phase 1：后端基础设施（**首先做，零业务风险**）

| # | 文件 | 操作 |
|---|---|---|
| 1.1 | `backend/knowledge/__init__.py` | 新建（空 + 注释） |
| 1.2 | `backend/knowledge/pages.py` | 新建（约 220 行，§2.1 完整内容） |
| 1.3 | `backend/models.py` | `InboundMessageType` 加 `page_changed`；新增 `PageChangedPayload`；`INBOUND_PAYLOAD_MAP` 加映射 |
| 1.4 | `backend/ws_handler.py:92-100` | `_dispatch` 字典加 `page_changed: self._on_page_changed` |
| 1.5 | `backend/ws_handler.py` | 新增 `_on_page_changed` 方法 |
| 1.6 | `backend/ws_handler.py:113-118` | `_on_agent_wake` 创建 AgentCore 时传 `current_page=payload.current_page` |
| 1.7 | `backend/agent_core.py:128-159` | `__init__` 加 `current_page` 参数 + 字段；加 `set_current_page` 方法 |
| 1.8 | `backend/agent_core.py:118-124` | 替换 `_load_scene_prompt` 为 `_build_executor_prompt`；新增 `_render_environment_section`；新增 `SCENE_TARGET_ROUTE` |
| 1.9 | `backend/agent_core.py:222` | `instructions = _build_executor_prompt(scene_id, self.current_page)` |
| 1.10 | `backend/agent_core.py` 模块顶层 | 加 `_validate_prompts_against_knowledge()` 启动校验 |
| 1.11 | `backend/tests/test_knowledge_consistency.py` | 新建：测试 find_path / 启动校验对错误 prompt 报错 / 各 scene_id 都有 target_route |

**验收**：服务启动不报错；现有 5 个 prompt（旧格式）跑现有场景仍能通过（环境信息块向后兼容）。

### Phase 2：5 个 scene prompt 改造（**LLM 行为变化，灰度**）

| # | 文件 | 操作 | 验证 |
|---|---|---|---|
| 2.1 | `backend/prompts/scene_login_face.txt` | 整文件重写为 §4.2 新格式 | 跑 3 个起点：/elder / /login / /login/face |
| 2.2 | `backend/prompts/scene_login_verify.txt` | 重写 | 跑 3 个起点：/elder / /login / /login/verify |
| 2.3 | `backend/prompts/scene_yibao_jiaofei.txt` | 重写 | 跑 2 个起点：/elder / /service/yibao-jiaofei |
| 2.4 | `backend/prompts/scene_pension_query.txt` | 重写 | 跑 2 个起点 |
| 2.5 | `backend/prompts/scene_yibao_query.txt` | 重写 | 跑 2 个起点 |

**建议灰度**：先只改 scene_login_face（最简单的 guide 级，2 个工具），跑通三种起点都正确再推广其余 4 个。每改一个跑一次手工测试。

### Phase 3：前端 page_changed 上报

| # | 文件 | 操作 |
|---|---|---|
| 3.1 | `app/lib/services/agent_session.dart:~83` | bindPage 末尾追加 page_changed 发送（§7.1） |

**验收**：手工跳页后看后端 log 出现 `page_changed → /xxx`。

### Phase 4：前端 ElementKeys 常量化（**可推迟**）

| # | 文件 | 操作 |
|---|---|---|
| 4.1 | `backend/tools/sync_element_keys.py` | 新建脚本 |
| 4.2 | `app/lib/services/agent_element_keys.dart` | 由 4.1 生成 |
| 4.3 | `app/lib/services/page_meta.g.dart` | 由 4.1 生成（覆盖现 page_meta.dart） |
| 4.4 | 18 个业务页 | `register('xxx')` 改为 `register(ElementKeys.xxx)` |
| 4.5 | CI 配置 | 加 step：`python -m backend.tools.sync_element_keys && git diff --exit-code` |

### Phase 5：补缺失的元素注册（**配合 Phase 2 验证**）

| # | 文件 | 操作 |
|---|---|---|
| 5.1 | `app/lib/widgets/elder_bottom_nav.dart` | register `tab_my` 挂到"我的" _NavItem |
| 5.2 | `app/lib/pages/elder_home.dart` | register `card_yibao_hub` 挂到"健康医保"网格项 |
| 5.3 | `app/lib/pages/mine_page.dart` | register `btn_go_login` 挂到 _LoginPrompt 的"去登录"按钮 |
| 5.4 | `app/lib/pages/yibao_hub_page.dart` | register `card_yibao_jiaofei_entry` + `card_yibao_query_entry` 挂到两个 _HubCard |

---

## 9. 风险与边界

### 9.1 风险清单

| 风险 | 影响 | 缓解 |
|---|---|---|
| LLM 不按写死的步骤来（自由发挥跳措辞） | 体验回到自由发挥级别 | prompt 里反复强调"不得改措辞、不得跳步"；启动期可加测试用例输入固定 mock，验证 LLM 输出包含特定关键词 |
| LLM 起点判断错 | 跳过该执行的步骤 / 念无关步骤 | 起点规则写得越简单越好（已采用"路由 → 步骤号"直接映射）；测试覆盖所有起点 |
| 用户在偏远页（不在 PAGES 中） | 环境信息说"未知页面"、find_path 返回 None | prompt 里写"路径不可达时先 cmd_say 引导回首页"；后续逐步把所有 18 个 AgentFab 挂载页录入 PAGES |
| Prompt 长度增加 | 上下文 token 翻倍 | 实测：标准流程 + 起点 + 环境信息约 800 token，DeepSeek 上限 64K，绰绰有余 |
| 启动期校验过严 | 开发期改 prompt 后必须同步 pages.py，否则启动失败 | 校验报错信息明确："prompt X 用了 Y，PAGES 缺该 key"；开发者照说明补即可 |
| Phase 4 推迟时 element_key 仍是魔法字符串 | 仍可能漂移 | Phase 1.10 启动校验是兜底，部署期就会拦下 |
| find_path 多解时返回最短 BFS | 可能不是最语义化的路径 | 当前场景最长 2 跳，不存在多路径问题；未来若有可加权重 |

### 9.2 边界 case

1. **route 带参数**（当前无）：`page_by_route` 用精确匹配；若未来有 `/user/:id` 之类，可改前缀匹配
2. **用户中途改变意图**（"算了不查养老金了，帮我缴医保"）：当前架构是单 scene 执行循环，需要用户取消后重启；本方案不涉及
3. **跨页 session 中执行循环里跳页**：会话 15 修复让 WS 不断，agent_core.current_page 由 page_changed 实时更新，下一轮 LLM 拿到的就是新位置 ✓
4. **HITL 暂停期间用户跳页**：fill_field_sensitive 暂停时，用户若误操作跳到别处，授权完成后 LLM 继续按既定流程操作 → 可能 fill 到错的页面。**建议**：fill_field 在前端找不到 field_key 控制器时 silently 失败 + 后端 task_done 时基于 `_executor.handleMessage` 收到的实际操作日志确认。本方案不修，作为 P3 跟进
5. **scene_login_face 第 5 / 第 6 步是被动等待事件**：摄像头授权浮层弹出 / 活体检测开始这两个"前置条件"前端目前没回报机制；当前 prompt 只是写死 cmd_say 顺序播报，**对实际事件不感知**。可工作但话术可能提前 / 滞后。后续可加事件回报，本方案不涉及

### 9.3 与会话 15 已规划修复的关系

| 已规划 | 关系 |
|---|---|
| Bug 1（_scheduleAutoDismiss 删除）| 正交 |
| Bug 2 修复 A（chk_agree_terms 注册）| 本方案 Phase 5.1 涵盖，且 register 形式仍是字符串（Phase 4 后才用 ElementKeys 常量） |
| Bug 2 修复 B（prompt 元素名对齐）| Phase 2 重写时自动对齐 + Phase 1.10 启动校验兜底 |
| Bug 2 修复 C（debugPrint 告警）| 正交，建议做 |
| 跨页 session 不断 | Phase 3 的页面感知是其延伸 |
| O-2（pop 返回 executor 失效）| 本方案不涉及 |
| btn_query 双注册 | pension_query 和 yibao_query 两页都 register('btn_query') → 同一 GlobalKey；本方案 PAGES 里允许同名 key 出现在两个 PageSpec 中（前端 register 时复用同 GlobalKey）；只要两页不同时 mount 就 OK。**建议**长期改为 `btn_pension_query` / `btn_yibao_query` 区分 |

---

## 10. 决策点（需 team-lead / 用户确认）

1. **是否在 PAGES 中收录所有 18 个 AgentFab 挂载页**？  当前候选稿 8 个核心页够覆盖现有场景。其他页（drafts / search / 操作日志等）可后续扩。**建议**：第一版只录 8 个，逐步扩展。
2. **是否要 Phase 4 ElementKeys 常量化**？  建议先做 Phase 1-3+5（核心机制 + 补缺），Phase 4 视答辩节奏。
3. **scene_out_of_scope 是否注入环境信息**？  建议第一版不做，避免引入波动。
4. **fill_field 的 value 填错怎么办**？  本方案 prompt 已要求"value 必须真实、占位字符串禁止；未知则先 cmd_say 问"。LLM 仍可能填错，**建议**后续在 `_push_tool_results` 加 value 合法性检查（如身份证号必须 18 位）。本方案不涉及。
5. **Phase 2 灰度从哪个场景开始**？  推荐 scene_login_face（guide 级最简，2 个工具）；跑通后再推广。

---

## 11. 工程化收益（论文素材）

"受控响应型智能代理"的"受控"在本方案下具体化为五重控制：

| 受控维度 | 实现 |
|---|---|
| 工具受控 | SCENE_TOOLS × _LEVEL_TOOLS 双重门控（已有） |
| 行为受控 | HITL 暂停 + 用户确认 + 敏感字段授权（已有） |
| **流程受控（新）** | 业务步骤序列由人工枚举写死，LLM 不能编新步骤 |
| **知识源受控（新）** | PAGES 单一真相源 + 启动期校验 |
| **感知受控（新）** | current_page 由前端主动上报，不靠 LLM 推理 |

代理的"智能"仅体现在"看用户位置选起点"这一个决策点上。**这是答辩讲"代理可控性"的关键论据**——LLM 在我们精心设计的轨道上运行，行为可枚举、可复现、可调试。

可写入论文章节：
- 流程枚举法 vs 端到端 LLM 自主规划：可控性 / 可维护性对比
- 启动期一致性校验：代理系统的"编译期"保障
- find_path 自动路径计算：图论在代理任务中的最简实践
- 知识库 + 动态注入：代理"感知 × 决策"解耦的工程化方法

---

## 12. 实施起点建议（MVP）

最小可行步骤（**1 天可完成**）：

1. **Phase 1.1-1.2**：建 knowledge/pages.py（8 个页面完整内容）
2. **Phase 1.7**：AgentCore 加 current_page 字段
3. **Phase 1.8**：实现 `_build_executor_prompt` 和 `_render_environment_section`
4. **Phase 1.10**：启动校验
5. **Phase 3**：前端 page_changed
6. **Phase 2.1**：重写 scene_login_face.txt
7. **Phase 5.1**：补 chk_agree_terms 注册

跑通"在 /elder / /login / /login/face 三个起点说'刷脸登录'，代理都从对应步骤开始"。验证有效后再推 Phase 2.2-2.5（剩余 4 个场景）+ Phase 5.2-5.3（其他页元素注册）。

Phase 4（前端常量化）可推迟到答辩准备末段或答辩后再做。

完。等团队决策实施顺序。
