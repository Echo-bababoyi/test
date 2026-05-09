# E2E 旅程图测试（用户旅程级别）

基于 `docs/USER_JOURNEY_TESTING.md` 编写，模拟真实用户操作的完整路径。

## 测试策略

| 测试层 | 内容 | 工具 |
|--------|------|------|
| **本目录（WS 协议层）** | 后端消息序列、HITL 授权流程、状态机流转、超时/拒绝分支 | pytest + 假 WebSocket |
| **前端集成测试（待补）** | 页面导航、元素高亮动画、表单填充、草稿箱 IndexedDB、网络横幅 | Flutter integration_test |
| **真机验证（N4 项）** | cmd_press_button 实际触发、TTS 播放时序、IndexedDB 竞态 | 手工 + 真机 |

## 测试文件

| 文件 | 场景 | 主路径 | 分支 | 异常 |
|------|------|--------|------|------|
| `test_s1a_face_login.py` | 场景 1a：刷脸登录 | ✅ | ✅ 分支 A（拒绝确认） | ✅ ASR 没听清 |
| `test_s1b_verify_login.py` | 场景 1b：验证码登录 | ✅ | ✅ 分支 B（拒绝授权） | ✅ 授权超时 |
| `test_s2_yibao_jiaofei.py` | 场景 2：医保缴费 | ✅ | ✅ 分支 C（拒绝身份证授权） | — |
| `test_s3_pension_query.py` | 场景 3：养老金查询 | ✅ | — | ⚠️ N4-1 须真机 |
| `test_s4_out_of_scope.py` | 场景 4：超出范围 | ✅ | ✅ 次路径（改头像） | — |
| `test_s5_draft_restore.py` | 场景 5：草稿箱恢复 | ⚠️ 前端限制 | — | — |
| `test_s6_network_disconnect.py` | 场景 6：网络断线重连 | ✅ | ✅ 执行中断线 | ⚠️ 前端 UI 限制 |

## 无法在 WS 协议层验证的步骤

以下步骤须 Flutter 集成测试或真机验证，本测试中以 `@pytest.mark.skip` 或注释标注：

1. **GoRouter 跳转**（`cmd_navigate` 触发）：仅能验证后端发出正确路由，实际页面跳转须 Flutter
2. **元素橙色高亮动画**（`cmd_highlight`）：仅能验证消息格式，动画效果须 Flutter
3. **表单字段填充动画**（`cmd_fill_field`）：仅能验证字段值，渲染须 Flutter
4. **is_sensitive=True 脱敏渲染**（N4-3）：仅验证字段标记，打码显示须 Flutter
5. **草稿箱 IndexedDB 读写**（场景 5 / N4-4）：纯前端行为
6. **网络断线红色横幅**（场景 6）：纯前端 UI
7. **TTS 音频播放时序**（N4-2 / N4-5）：仅验证 tts_audio_base64 非空，播放时序须真机

## 运行方式

```bash
# 从项目根目录运行（需要 DEEPSEEK_API_KEY 已配置在 backend/.env）
cd /home/getui/codes/liangyc/archive/test
python -m pytest app/test/e2e/ -v

# 跳过慢速测试（授权超时 case 需要等 22s）
python -m pytest app/test/e2e/ -v -k "not timeout"

# 只跑某个场景
python -m pytest app/test/e2e/test_s3_pension_query.py -v
```

## 依赖

```
pytest
pytest-asyncio
python-dotenv
```

（已包含在 backend/requirements_test.txt 的 websockets/fastapi/agno 依赖链中）
