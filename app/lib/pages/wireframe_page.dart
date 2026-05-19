import 'package:flutter/material.dart';

/// 低保真线框图页面 — 仅用于论文插图截图
/// 6 个关键界面：长辈版首页 / 刷脸验证 / 医保缴费 / 代理面板 / 授权卡片 / 操作记录
class WireframePage extends StatefulWidget {
  final int index; // 0-5
  const WireframePage({super.key, required this.index});

  @override
  State<WireframePage> createState() => _WireframePageState();
}

class _WireframePageState extends State<WireframePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: [
        const _WF1ElderHome(),
        const _WF5FaceAuth(),
        const _WF6YibaoJiaofei(),
        const _WF2AgentPanel(),
        const _WF3AuthCard(),
        const _WF4OperationLog(),
      ][widget.index],
    );
  }
}

// ─── 通用线框组件 ─────────────────────────────────────────────────────────────

class _WFBox extends StatelessWidget {
  final double? width;
  final double height;
  final Color color;
  final String? label;
  final double radius;
  const _WFBox({
    this.width,
    required this.height,
    this.color = const Color(0xFFCCCCCC),
    this.label,
    this.radius = 6,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      alignment: Alignment.center,
      child: label != null
          ? Text(label!, style: const TextStyle(fontSize: 11, color: Color(0xFF888888)))
          : null,
    );
  }
}

class _WFText extends StatelessWidget {
  final String text;
  final double size;
  final FontWeight weight;
  final Color color;
  const _WFText(this.text, {this.size = 13, this.weight = FontWeight.normal, this.color = const Color(0xFF444444)});

  @override
  Widget build(BuildContext context) {
    return Text(text, style: TextStyle(fontSize: size, fontWeight: weight, color: color));
  }
}

// ─── 1. 长辈版首页线框 ────────────────────────────────────────────────────────

class _WF1ElderHome extends StatelessWidget {
  const _WF1ElderHome();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar
        Container(
          height: 56,
          color: const Color(0xFFDDDDDD),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              const _WFBox(width: 80, height: 28, label: 'Logo'),
              const Spacer(),
              const _WFBox(width: 60, height: 28, label: '长辈版'),
            ],
          ),
        ),
        // 搜索框
        Container(
          color: const Color(0xFFEEEEEE),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: const _WFBox(width: double.infinity, height: 40, label: '搜索框', radius: 20),
        ),
        // 高频服务格栅
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _WFText('常用服务', size: 15, weight: FontWeight.bold),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: const [
                    _WFGridItem('医保\n缴费'),
                    _WFGridItem('养老金\n查询'),
                    _WFGridItem('社保\n查询'),
                    _WFGridItem('医保\n查询'),
                    _WFGridItem('社保费\n缴纳'),
                    _WFGridItem('搜索'),
                    _WFGridItem('草稿箱'),
                    _WFGridItem('更多'),
                  ],
                ),
                const SizedBox(height: 16),
                const _WFText('政务热线', size: 15, weight: FontWeight.bold),
                const SizedBox(height: 10),
                const _WFBox(width: double.infinity, height: 64, label: '政务热线卡片'),
                const SizedBox(height: 16),
                const _WFText('在线服务', size: 15, weight: FontWeight.bold),
                const SizedBox(height: 10),
                const _WFBox(width: double.infinity, height: 80, label: '服务列表'),
              ],
            ),
          ),
        ),
        // 底部导航
        Container(
          height: 64,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WFNavItem('首页', selected: true),
              _WFNavItem('我的', selected: false),
            ],
          ),
        ),
        // 标注
        _WFAnnotation('图1  长辈版首页线框图\n底部导航：首页 / 我的；悬浮助手按钮吸附右侧边缘'),
      ],
    );
  }
}

class _WFGridItem extends StatelessWidget {
  final String label;
  const _WFGridItem(this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const _WFBox(width: 44, height: 44, radius: 12),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(0xFF666666)), textAlign: TextAlign.center),
      ],
    );
  }
}

Widget _WFNavItem(String label, {required bool selected}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFBBBBBB) : const Color(0xFFDDDDDD),
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 11, color: selected ? const Color(0xFF444444) : const Color(0xFF999999))),
    ],
  );
}

// ─── 2. 代理面板线框 ──────────────────────────────────────────────────────────

class _WF2AgentPanel extends StatelessWidget {
  const _WF2AgentPanel();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 背景页面（变暗）
        Container(
          height: 200,
          color: const Color(0xFFD8D8D8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              SizedBox(height: 8),
              _WFText('当前业务页面（可见）', size: 12, color: Color(0xFF888888)),
              SizedBox(height: 12),
              _WFBox(width: double.infinity, height: 40, label: '页面内容'),
              SizedBox(height: 8),
              _WFBox(width: double.infinity, height: 40, label: '页面内容'),
            ],
          ),
        ),
        // 气泡聊天窗
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 16, offset: Offset(0, 4))],
            ),
            child: Column(
              children: [
                // 标题栏
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFBBBBBB),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      const _WFBox(width: 24, height: 24, radius: 12, label: '浙'),
                      const SizedBox(width: 8),
                      const _WFText('小浙助手', size: 14, weight: FontWeight.bold, color: Color(0xFF555555)),
                      const Spacer(),
                      const _WFBox(width: 24, height: 24, radius: 12, label: '×'),
                    ],
                  ),
                ),
                // 对话区
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _WFBubble('您好，我是小浙，有什么可以帮您？', isAgent: true),
                        const SizedBox(height: 8),
                        _WFBubble('帮我缴医保', isAgent: false),
                        const SizedBox(height: 8),
                        _WFBubble('帮您缴医保，对吗？', isAgent: true),
                      ],
                    ),
                  ),
                ),
                // 输入区
                Container(
                  height: 52,
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    children: [
                      const Expanded(child: _WFBox(height: 36, label: '输入指令…', radius: 18)),
                      const SizedBox(width: 8),
                      const _WFBox(width: 36, height: 36, radius: 18, label: '→'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        _WFAnnotation('图2  代理气泡聊天窗线框图\n浮动于业务页面右下角，可拖动；含对话区 + 文字输入'),
      ],
    );
  }
}

Widget _WFBubble(String text, {required bool isAgent}) {
  return Align(
    alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
    child: Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isAgent ? const Color(0xFFEEEEEE) : const Color(0xFFD0D0D0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: const TextStyle(fontSize: 13, color: Color(0xFF444444))),
    ),
  );
}

// ─── 3. 授权卡片线框 ──────────────────────────────────────────────────────────

class _WF3AuthCard extends StatelessWidget {
  const _WF3AuthCard();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 背景（聊天窗 + 业务页面）
        Container(
          height: 260,
          color: const Color(0xFFD8D8D8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              _WFText('代理气泡窗（背景）', size: 11, color: Color(0xFF999999)),
              SizedBox(height: 8),
              _WFBox(width: double.infinity, height: 40, label: '对话气泡'),
              SizedBox(height: 8),
              _WFBox(width: double.infinity, height: 40, label: '对话气泡'),
              SizedBox(height: 8),
              _WFBox(width: double.infinity, height: 40, label: '对话气泡'),
            ],
          ),
        ),
        // 授权卡片
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFDDDDDD)),
            boxShadow: const [BoxShadow(color: Color(0x18000000), blurRadius: 12, offset: Offset(0, 4))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const _WFText('权限请求', size: 16, weight: FontWeight.bold),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const _WFText(
                  '小浙想帮您填写【身份证号】\n这次可以吗？',
                  size: 15,
                  color: Color(0xFF333333),
                ),
              ),
              const SizedBox(height: 8),
              const _WFText('15 秒后自动拒绝', size: 12, color: Color(0xFF999999)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFBBBBBB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const _WFText('可以', size: 16, weight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFFCCCCCC)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const _WFText('不用了', size: 16, color: Color(0xFF888888)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _WFAnnotation('图3  授权卡片线框图\n权限名称大字显示；"可以"填充色 vs "不用了"描边；间距 ≥16dp'),
      ],
    );
  }
}

// ─── 4. 操作记录线框 ──────────────────────────────────────────────────────────

class _WF4OperationLog extends StatelessWidget {
  const _WF4OperationLog();

  static const _items = [
    ('医保缴费', '小浙帮您完成了 2026 年度医保缴费', '5月14日 14:30'),
    ('养老金查询', '查询到 5 月养老金 3280 元，已到账', '5月13日 09:15'),
    ('医保查询', '查询到近 3 个月医保缴费记录', '5月10日 16:42'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar
        Container(
          height: 56,
          color: const Color(0xFFDDDDDD),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const _WFText('操作记录', size: 18, weight: FontWeight.bold),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
            itemCount: _items.length,
            itemBuilder: (_, i) {
              final (scene, summary, time) = _items[i];
              final isLast = i == _items.length - 1;
              return IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 时间线
                    SizedBox(
                      width: 28,
                      child: Column(
                        children: [
                          Container(
                            width: 12, height: 12,
                            decoration: const BoxDecoration(
                              color: Color(0xFFAAAAAA),
                              shape: BoxShape.circle,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Center(
                                child: Container(width: 2, color: const Color(0xFFCCCCCC)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // 卡片
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const _WFBox(width: 36, height: 36, radius: 8),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _WFText(scene, size: 15, weight: FontWeight.bold),
                                      _WFText(time, size: 12, color: const Color(0xFF999999)),
                                    ],
                                  ),
                                ),
                                const _WFBox(width: 16, height: 16, radius: 3),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _WFText(summary, size: 13, color: const Color(0xFF666666)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        // 底部导航
        Container(
          height: 64,
          color: Colors.white,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _WFNavItem('首页', selected: false),
              _WFNavItem('我的', selected: true),
            ],
          ),
        ),
        _WFAnnotation('图4  操作记录页线框图\n时间线布局；场景图标 + 摘要 + 时间戳；可展开查看操作明细'),
      ],
    );
  }
}

// ─── 底部标注条 ───────────────────────────────────────────────────────────────

Widget _WFAnnotation(String text) {
  return Container(
    width: double.infinity,
    color: const Color(0xFFE8E8E8),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Text(
      text,
      style: const TextStyle(fontSize: 11, color: Color(0xFF666666), height: 1.5),
    ),
  );
}

// ─── 5. 刷脸验证页 + 气泡窗引导 ──────────────────────────────────────────────

class _WF5FaceAuth extends StatelessWidget {
  const _WF5FaceAuth();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar
        Container(
          height: 56,
          color: const Color(0xFFDDDDDD),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const _WFText('身份验证', size: 16, weight: FontWeight.bold),
        ),
        // 页面主体
        Expanded(
          child: Stack(
            children: [
              // 背景：刷脸页内容
              Positioned.fill(
                child: Container(
                  color: const Color(0xFFF5F5F5),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 12),
                      // 白卡
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFEEEEEE)),
                        ),
                        child: Column(
                          children: [
                            const _WFText('**明', size: 14),
                            const SizedBox(height: 16),
                            // 人脸扫描框
                            Container(
                              width: 160,
                              height: 160,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEEEEEE),
                                shape: BoxShape.circle,
                                border: Border.all(color: const Color(0xFFCCCCCC), width: 2),
                              ),
                              alignment: Alignment.center,
                              child: const _WFText('人脸区域', size: 12, color: Color(0xFF999999)),
                            ),
                            const SizedBox(height: 16),
                            const _WFText('请进行刷脸认证', size: 16, weight: FontWeight.bold),
                            const SizedBox(height: 8),
                            const _WFText('获取人脸信息进行实人验证', size: 12, color: Color(0xFF999999)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      const _WFBox(width: double.infinity, height: 48, label: '开始认证', radius: 24),
                      const SizedBox(height: 12),
                      const _WFBox(width: double.infinity, height: 48, label: '其他方式认证', radius: 24, color: Color(0xFFE8E8E8)),
                    ],
                  ),
                ),
              ),
              // 气泡窗（右下角）
              Positioned(
                right: 8,
                bottom: 8,
                child: _WFMiniPanel(
                  messages: const [
                    (true, '我陪您完成刷脸登录'),
                    (true, '请把手机举到眼前，看着摄像头'),
                    (false, '好的'),
                    (true, '马上会弹出摄像头请求，请点同意'),
                    (true, '请缓慢左右摇头，再眨一眨眼~'),
                  ],
                ),
              ),
            ],
          ),
        ),
        _WFAnnotation('图2  刷脸验证页线框图（场景1：L1纯引导）\n气泡窗叠加于页面右下角；代理语音引导每步操作，不代按任何按钮'),
      ],
    );
  }
}

// ─── 6. 医保缴费页 + 气泡窗代填 ──────────────────────────────────────────────

class _WF6YibaoJiaofei extends StatelessWidget {
  const _WF6YibaoJiaofei();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // AppBar
        Container(
          height: 56,
          color: const Color(0xFFDDDDDD),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: const _WFText('医保缴费', size: 16, weight: FontWeight.bold),
        ),
        Expanded(
          child: Stack(
            children: [
              // 背景：医保缴费表单
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _WFText('缴费信息', size: 14, weight: FontWeight.bold),
                      const SizedBox(height: 12),
                      _WFFormRow('缴费对象', '本人', filled: true),
                      const SizedBox(height: 10),
                      _WFFormRow('缴费年度', '2026', filled: true),
                      const SizedBox(height: 10),
                      _WFFormRow('缴费金额', '4800 元', filled: true),
                      const SizedBox(height: 10),
                      _WFFormRow('身份证号', '330…**…6', filled: true, sensitive: true),
                      const SizedBox(height: 10),
                      _WFFormRow('手机号码', '138****8888', filled: true),
                      const SizedBox(height: 20),
                      // 高亮提示：去支付按钮
                      Container(
                        width: double.infinity,
                        height: 52,
                        decoration: BoxDecoration(
                          color: const Color(0xFFCCCCCC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF888888), width: 2, style: BorderStyle.solid),
                        ),
                        alignment: Alignment.center,
                        child: const _WFText('去支付（用户亲手点击）', size: 13, weight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const _WFText('↑ 代理止步于此，不代按支付按钮', size: 11, color: Color(0xFF888888)),
                    ],
                  ),
                ),
              ),
              // 气泡窗
              Positioned(
                right: 8,
                bottom: 8,
                child: _WFMiniPanel(
                  messages: const [
                    (false, '帮我缴今年的医保'),
                    (true, '帮您缴2026年度医保，对吗？'),
                    (false, '对'),
                    (true, '正在帮您填写表单…'),
                    (true, '身份证号需要您单独同意'),
                  ],
                ),
              ),
            ],
          ),
        ),
        _WFAnnotation('图3  医保缴费页线框图（场景3：L2-L3代填）\n普通字段直接代填；身份证号需单独授权；"去支付"代理止步'),
      ],
    );
  }
}

Widget _WFFormRow(String label, String value, {bool filled = false, bool sensitive = false}) {
  return Row(
    children: [
      SizedBox(
        width: 80,
        child: _WFText(label, size: 13, color: const Color(0xFF666666)),
      ),
      Expanded(
        child: Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: filled
                ? (sensitive ? const Color(0xFFFFF8E1) : const Color(0xFFF0F0F0))
                : Colors.white,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: sensitive ? const Color(0xFFBBBBBB) : const Color(0xFFDDDDDD),
              width: sensitive ? 1.5 : 1,
            ),
          ),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Expanded(child: _WFText(value, size: 13)),
              if (sensitive)
                const _WFText('★ 已授权', size: 10, color: Color(0xFF888888)),
            ],
          ),
        ),
      ),
    ],
  );
}

// ─── 迷你气泡窗（叠加用）────────────────────────────────────────────────────

class _WFMiniPanel extends StatelessWidget {
  final List<(bool isAgent, String text)> messages;
  const _WFMiniPanel({required this.messages});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [BoxShadow(color: Color(0x28000000), blurRadius: 12, offset: Offset(0, 4))],
        border: Border.all(color: const Color(0xFFEEEEEE)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题栏
          Container(
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFBBBBBB),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                const _WFBox(width: 18, height: 18, radius: 9),
                const SizedBox(width: 6),
                const _WFText('小浙助手', size: 11, weight: FontWeight.bold, color: Color(0xFF555555)),
                const Spacer(),
                const _WFBox(width: 18, height: 18, radius: 9),
              ],
            ),
          ),
          // 消息列表
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: messages.map((m) {
                final (isAgent, text) = m;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Align(
                    alignment: isAgent ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      constraints: const BoxConstraints(maxWidth: 160),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: isAgent ? const Color(0xFFEEEEEE) : const Color(0xFFD8D8D8),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(text, style: const TextStyle(fontSize: 10, color: Color(0xFF444444))),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // 输入区
          Container(
            height: 32,
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            child: Row(
              children: [
                const Expanded(child: _WFBox(height: 22, label: '输入…', radius: 11)),
                const SizedBox(width: 6),
                const _WFBox(width: 22, height: 22, radius: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
