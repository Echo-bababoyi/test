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
        description='浙里办长辈版主入口。无顶部登录入口，登录路径走底部"我的"Tab。'
                    '常见服务通过"健康医保"网格项进入医保枢纽页（/service/yibao-hub）',
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
                       user_guidance='请点首页"健康医保"图标进入医保服务页（需登录态，未登录会被重定向到登录页）'),
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


def find_path(from_route: str, to_route: str, max_hops: int = 5) -> list[Transition] | None:
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
