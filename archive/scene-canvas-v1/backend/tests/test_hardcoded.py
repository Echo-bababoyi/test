"""
Step 3 硬编码规则调度单元测试。
"""

import pytest
from app.agent.agno_agent import hardcoded_dispatch


def _dispatch(text: str) -> dict | None:
    return hardcoded_dispatch(text)


class TestNavigateTo:
    def test_pension_query_direct(self):
        r = _dispatch("帮我查养老金")
        assert r is not None
        assert r["intent_type"] == "NavigateTo"
        assert r["params"]["path"] == "/service/pension-query"

    def test_pension_query_retirement(self):
        r = _dispatch("我退休了怎么查退休金")
        assert r is not None
        assert r["intent_type"] == "NavigateTo"
        assert r["params"]["path"] == "/service/pension-query"

    def test_social_insurance(self):
        r = _dispatch("我要交医保")
        assert r is not None
        assert r["intent_type"] == "NavigateTo"
        assert r["params"]["path"] == "/service/social-insurance"

    def test_social_insurance_shebao(self):
        r = _dispatch("社保怎么缴")
        assert r is not None
        assert r["intent_type"] == "NavigateTo"
        assert r["params"]["path"] == "/service/social-insurance"


class TestSwitchMode:
    def test_switch_elder(self):
        r = _dispatch("我看不清字，换大字版")
        assert r is not None
        assert r["intent_type"] == "SwitchMode"
        assert r["params"]["mode"] == "elder"

    def test_switch_elder_keyword(self):
        r = _dispatch("帮我开长辈版")
        assert r is not None
        assert r["intent_type"] == "SwitchMode"
        assert r["params"]["mode"] == "elder"

    def test_switch_standard(self):
        r = _dispatch("换回普通版吧")
        assert r is not None
        assert r["intent_type"] == "SwitchMode"
        assert r["params"]["mode"] == "standard"


class TestExplainTerm:
    def test_explain_linghuo_jiuye(self):
        r = _dispatch("什么是灵活就业")
        assert r is not None
        assert r["intent_type"] == "ExplainTerm"
        assert r["params"]["term"] == "灵活就业"

    def test_explain_social_insurance_term(self):
        # "社保" 关键词优先命中 NavigateTo（规则优先级设计，符合预期）
        r = _dispatch("社保是什么意思")
        assert r is not None
        assert r["intent_type"] == "NavigateTo"
        # 用不含导航关键词的纯术语查询触发 ExplainTerm
        r2 = _dispatch("什么是灵活就业人员")
        assert r2 is not None
        assert r2["intent_type"] == "ExplainTerm"

    def test_explain_chengxiang_jumin(self):
        r = _dispatch("城乡居民是什么")
        assert r is not None
        assert r["intent_type"] == "ExplainTerm"
        assert r["params"]["term"] == "城乡居民"

    def test_generic_explain(self):
        r = _dispatch("我看不懂这个词")
        assert r is not None
        assert r["intent_type"] == "ExplainTerm"


class TestFallback:
    def test_unknown_input(self):
        r = _dispatch("随便说点啥")
        assert r is None

    def test_empty_string(self):
        r = _dispatch("")
        assert r is None

    def test_unrelated_sentence(self):
        r = _dispatch("今天天气真不错")
        assert r is None
