"""
信息架构图生成脚本
树形布局，橙色主色调，新增页面用绿色标注
"""
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.patches import FancyBboxPatch
import numpy as np

plt.rcParams['font.family'] = ['Microsoft YaHei', 'SimHei', 'sans-serif']
plt.rcParams['axes.unicode_minus'] = False

# ── 节点定义 ──────────────────────────────────────────────────────────────────
# (label, x, y, type)
# type: 'root' | 'section' | 'page' | 'new'

nodes = [
    # 根
    ('浙里办 APP', 0, 0, 'root'),

    # 一级
    ('闪屏页', -7.5, -1.8, 'page'),
    ('标准版首页', -4.5, -1.8, 'page'),
    ('长辈版', 1.5, -1.8, 'section'),

    # 长辈版下的二级分组
    ('长辈版首页', -2.5, -3.6, 'page'),
    ('登录流程', 0.5, -3.6, 'section'),
    ('政务服务', 4.0, -3.6, 'section'),
    ('搜索', 7.5, -3.6, 'section'),
    ('我的', 10.0, -3.6, 'section'),

    # 登录流程
    ('登录页', -0.5, -5.4, 'page'),
    ('刷脸验证页', 0.5, -5.4, 'page'),
    ('验证码页', 1.5, -5.4, 'page'),

    # 政务服务
    ('医保缴费', 2.5, -5.4, 'page'),
    ('医保查询', 3.5, -5.4, 'page'),
    ('养老金查询', 4.5, -5.4, 'page'),
    ('社保费缴纳', 5.5, -5.4, 'page'),
    ('社保查询', 6.5, -5.4, 'page'),

    # 搜索
    ('搜索页', 7.0, -5.4, 'page'),
    ('搜索结果页', 8.0, -5.4, 'page'),

    # 我的（新增）
    ('草稿箱', 9.2, -5.4, 'new'),
    ('操作记录', 10.2, -5.4, 'new'),
    ('小浙设置', 11.2, -5.4, 'new'),
]

# ── 连线定义 (parent_label → child_label) ────────────────────────────────────
edges = [
    ('浙里办 APP', '闪屏页'),
    ('浙里办 APP', '标准版首页'),
    ('浙里办 APP', '长辈版'),

    ('长辈版', '长辈版首页'),
    ('长辈版', '登录流程'),
    ('长辈版', '政务服务'),
    ('长辈版', '搜索'),
    ('长辈版', '我的'),

    ('登录流程', '登录页'),
    ('登录流程', '刷脸验证页'),
    ('登录流程', '验证码页'),

    ('政务服务', '医保缴费'),
    ('政务服务', '医保查询'),
    ('政务服务', '养老金查询'),
    ('政务服务', '社保费缴纳'),
    ('政务服务', '社保查询'),

    ('搜索', '搜索页'),
    ('搜索', '搜索结果页'),

    ('我的', '草稿箱'),
    ('我的', '操作记录'),
    ('我的', '小浙设置'),
]

# ── 颜色方案 ──────────────────────────────────────────────────────────────────
COLORS = {
    'root':    {'bg': '#FF6D00', 'fg': 'white',       'ec': '#E65100'},
    'section': {'bg': '#FFF3E0', 'fg': '#E65100',     'ec': '#FF8A3C'},
    'page':    {'bg': '#FFFFFF', 'fg': '#333333',     'ec': '#CCCCCC'},
    'new':     {'bg': '#E8F5E9', 'fg': '#2E7D32',     'ec': '#66BB6A'},
}

NODE_W = {'root': 2.2, 'section': 1.8, 'page': 1.6, 'new': 1.6}
NODE_H = 0.55

# ── 构建坐标字典 ──────────────────────────────────────────────────────────────
pos = {n[0]: (n[1], n[2]) for n in nodes}
ntype = {n[0]: n[3] for n in nodes}

# ── 绘图 ──────────────────────────────────────────────────────────────────────
fig, ax = plt.subplots(figsize=(18, 8))
ax.set_xlim(-9.5, 13)
ax.set_ylim(-6.8, 1.2)
ax.axis('off')
fig.patch.set_facecolor('#FAFAFA')

# 连线
for parent, child in edges:
    px, py = pos[parent]
    cx, cy = pos[child]
    # 折线：从父节点底部 → 水平 → 子节点顶部
    mid_y = (py - NODE_H/2 + cy + NODE_H/2) / 2
    ax.plot([px, px, cx, cx],
            [py - NODE_H/2, mid_y, mid_y, cy + NODE_H/2],
            color='#CCCCCC', linewidth=1.2, zorder=1)

# 节点
for label, x, y, t in nodes:
    c = COLORS[t]
    w = NODE_W[t]
    box = FancyBboxPatch(
        (x - w/2, y - NODE_H/2), w, NODE_H,
        boxstyle='round,pad=0.06',
        facecolor=c['bg'], edgecolor=c['ec'], linewidth=1.5, zorder=2
    )
    ax.add_patch(box)
    fontsize = 11 if t == 'root' else 9
    fontweight = 'bold' if t in ('root', 'section') else 'normal'
    ax.text(x, y, label, ha='center', va='center',
            fontsize=fontsize, fontweight=fontweight,
            color=c['fg'], zorder=3)

# 图例
legend_items = [
    mpatches.Patch(facecolor='#FF6D00', edgecolor='#E65100', label='根节点'),
    mpatches.Patch(facecolor='#FFF3E0', edgecolor='#FF8A3C', label='功能分组'),
    mpatches.Patch(facecolor='#FFFFFF', edgecolor='#CCCCCC', label='已有页面'),
    mpatches.Patch(facecolor='#E8F5E9', edgecolor='#66BB6A', label='新增页面'),
]
ax.legend(handles=legend_items, loc='lower left', fontsize=9,
          framealpha=0.9, edgecolor='#DDDDDD')

# 标题
ax.text(0, 0.85, '浙里办长辈版信息架构图',
        ha='center', va='center', fontsize=14, fontweight='bold',
        color='#333333', transform=ax.transAxes)
ax.text(0, 0.78, '共 17 个页面 · 绿色为本研究新增页面',
        ha='center', va='center', fontsize=9, color='#888888',
        transform=ax.transAxes)

out = r'D:\Code\bs\docs\diagrams\ia_diagram.png'
plt.tight_layout(pad=0.5)
plt.savefig(out, dpi=150, bbox_inches='tight', facecolor='#FAFAFA')
plt.close()
print(f'saved: {out}')
