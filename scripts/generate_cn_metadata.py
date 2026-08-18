#!/usr/bin/env python3
"""ChronicCare 8 CN domestic platform metadata generator (R128e+).

Generates: fastlane/metadata/cn_domestic/{platform}/*.txt (~70 files)
Each platform has 8-10 fields: app_intro, app_tags, app_category, screenshots_spec,
icon_spec, privacy_url, developer_verified, content_rating, soft_copyright.

Usage: python3 scripts/generate_cn_metadata.py
"""

from __future__ import annotations
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# Common brand content
APP_NAME = 'MoodDiary 心情日记'
TAGLINE = '情绪日记 + 树洞倾诉 · 永久免费 · 100% 本地加密零云端'

# Per-platform intro (80-200 字, 适配各商店字数限制)
APP_INTROS = {
    'huawei': '''MoodDiary 心情日记 — 一个只属于你的情绪日记和树洞。

每个人都有说不出口的时刻。把想说的写下来、说出来,看到自己一点一点变好的轨迹。

【核心功能】
• 树洞倾诉: 完全私密,加密存储在手机里,支持语音
• 情绪日记: 4 个维度评分(情绪/能量/睡眠/压力)+ 影响因素 + CBT 思维记录
• 烦恼闭环: 记下烦恼,时间线追踪,直到"不再烦恼"
• 趋势回顾: 跨情绪/树洞的图表
• 自我测评: 可选的自助反思问卷
• 危机热线: 内置多地区心理援助热线,一键拨打

【承诺】100% 本地加密 · 零云端 · 零广告 · 永久免费 · 数据可导出

非医疗工具,不提供诊断治疗。''',
    'xiaomi': '''MoodDiary 心情日记 — 你的私人情绪日记和树洞。

把想说的写下来,看到自己一点一点变好的轨迹。

• 树洞倾诉: 私密加密,语音支持
• 情绪日记: 4 维度评分 + CBT 思维记录
• 烦恼闭环: 追踪直到"不再烦恼"
• 趋势图表 + 自我测评 + 危机热线

100% 本地加密 · 零云端 · 零广告 · 永久免费 · 数据可导出

非医疗工具。''',
    'oppo': '''MoodDiary 心情日记,你的私人情绪日记和树洞。

每个人都有说不出口的时刻。MoodDiary 给你一个完全私密的角落: 树洞倾诉 + 情绪日记 + CBT 思维记录 + 趋势图表 + 危机热线。

100% 本地加密 · 零云端 · 零广告 · 永久免费 · 数据可导出。

非医疗工具,不提供诊断治疗。''',
    'vivo': '''MoodDiary 心情日记 — 情绪日记 + 树洞倾诉优先。

核心: 树洞倾诉(加密+语音) · 情绪日记(4 维度+CBT) · 烦恼闭环 · 趋势图表 · 危机热线。

100% 本地加密 · 零云端 · 零广告 · 永久免费。

非医疗工具。''',
    'meizu': '''MoodDiary 心情日记,私人情绪日记和树洞倾诉 app。

树洞倾诉 + 情绪日记 + 趋势图表 + 危机热线。100% 本地加密,零云端,零广告,永久免费。

非医疗工具。''',
    'tencent': '''MoodDiary 心情日记 — 情绪日记 + 树洞倾诉优先。

每个人都有说不出口的时刻。MoodDiary 给你一个完全私密的角落,把想说的写下来、说出来,看到自己一点一点变好的轨迹。

核心功能: 树洞倾诉(加密+语音)、情绪日记(4 维度+CBT 思维记录)、烦恼闭环、趋势回顾、危机热线。

承诺: 100% 本地加密(SQLCipher AES-256) · 零云端 · 零广告 · 永久免费 · 数据可导出 JSON / 一键删除。

非医疗工具,不提供医疗建议、诊断或治疗。''',
    'qihoo': '''MoodDiary 心情日记 — 情绪日记 + 树洞倾诉。

树洞倾诉 · 情绪日记 · 烦恼闭环 · 趋势图表 · 危机热线。
100% 本地加密 · 零云端 · 零广告 · 永久免费。
非医疗工具。''',
    'baidu': '''MoodDiary 心情日记,你的私人情绪日记和树洞倾诉 app。

情绪日记 + 树洞倾诉 + CBT 思维记录 + 趋势图表 + 危机热线。

100% 本地加密,零云端,零广告,永久免费,数据可导出。

非医疗工具。''',
}

APP_TAGS = {
    'huawei': '情绪日记,树洞,心情,倾诉,CBT,心理健康,日记本,本地加密,免费',
    'xiaomi': '情绪,树洞,日记,心情,心理健康,CBT,加密,免费',
    'oppo': '情绪日记,树洞倾诉,心情,心理健康,CBT,本地加密',
    'vivo': '情绪日记,树洞,心情,心理健康,加密',
    'meizu': '情绪日记,树洞,心情,心理健康,日记本',
    'tencent': '情绪日记,树洞倾诉,心情,心理健康,CBT,本地加密,免费',
    'qihoo': '情绪,树洞,日记,心情,心理健康,加密',
    'baidu': '情绪日记,树洞,心情,心理健康,日记本,加密',
}

APP_CATEGORIES = {
    'huawei': ('健康', '心理健康'),
    'xiaomi': ('健康', '健康工具'),
    'oppo': ('健康', '健康工具'),
    'vivo': ('健康', '心理健康'),
    'meizu': ('健康', '心理健康'),
    'tencent': ('健康医疗', '心理健康'),
    'qihoo': ('健康', '心理健康'),
    'baidu': ('健康', '心理健康'),
}

SCREENSHOTS_SPEC = '''# 截图规格占位 (R128e+)
# 用户上架前由设计师出图后填入以下 5 张:
#   01_home.png         — 主页 (mood 横滑 + vent 入口)
#   02_mood.png         — 情绪日记评分页 (4 维度)
#   03_vent.png         — 树洞倾诉页
#   04_medication.png   — 用药日历
#   05_assessment.png   — 心理评估问卷
# 规格: 1080×1920 PNG (各商店通用)
# 命名: screenshot_1.png ... screenshot_5.png
'''

ICON_SPEC = '''# 应用图标规格占位
# 当前已生成: assets/brand/cn/{platform}-icon-512.png (脚本 generate_app_icon.py 产物)
# 用户上架前:
#   - 华为: 上传 216×216 PNG (从 512 等比缩放)
#   - 小米: 上传 512×512 PNG (已生成)
#   - OPPO/vivo/魅族/应用宝/360/百度: 上传 512×512 PNG (已生成)
'''

PRIVACY_URL = '[PENDING_DOMAIN: https://chroniccare.app/privacy]'
DEVELOPER_VERIFIED = '[PENDING_DEVELOPER_VERIFIED: 上架前填开发者实名认证信息]'
CONTENT_RATING_12 = '12+ (含轻度心理情绪内容,无暴力/色情)'
CONTENT_RATING_17 = '17+ (含心理情绪内容)'
SOFT_COPYRIGHT = '[PENDING_SOFT_COPYRIGHT: 软件著作权证书 PDF, 用户上架前提交]'

# Per-platform metadata fields
PLATFORM_FIELDS = {
    'huawei': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
               'icon_spec', 'privacy_url', 'developer_verified', 'content_rating',
               'soft_copyright'],
    'xiaomi': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
               'icon_spec', 'privacy_url', 'developer_verified', 'soft_copyright'],
    'oppo': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
             'icon_spec', 'privacy_url', 'developer_verified', 'content_rating',
             'soft_copyright'],
    'vivo': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
             'icon_spec', 'privacy_url', 'developer_verified', 'content_rating',
             'soft_copyright'],
    'meizu': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
              'icon_spec', 'privacy_url', 'soft_copyright'],
    'tencent': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
                'icon_spec', 'privacy_url', 'developer_verified', 'soft_copyright'],
    'qihoo': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
              'icon_spec', 'privacy_url', 'developer_verified', 'soft_copyright'],
    'baidu': ['app_intro', 'app_tags', 'app_category', 'screenshots_spec',
              'icon_spec', 'privacy_url', 'developer_verified', 'soft_copyright'],
}


def write_field(platform: str, field: str, content: str) -> None:
    out_dir = os.path.join(ROOT, f'fastlane/metadata/cn_domestic/{platform}')
    os.makedirs(out_dir, exist_ok=True)
    out_path = os.path.join(out_dir, f'{field}.txt')
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f'  cn_domestic/{platform}/{field}.txt')


def generate_platform(platform: str) -> None:
    for field in PLATFORM_FIELDS[platform]:
        if field == 'app_intro':
            content = APP_INTROS[platform]
        elif field == 'app_tags':
            content = APP_TAGS[platform]
        elif field == 'app_category':
            cat, sub = APP_CATEGORIES[platform]
            content = f'{cat}\n{sub}\n'
        elif field == 'screenshots_spec':
            content = SCREENSHOTS_SPEC
        elif field == 'icon_spec':
            content = ICON_SPEC.replace('{platform}', platform)
        elif field == 'privacy_url':
            content = PRIVACY_URL + '\n'
        elif field == 'developer_verified':
            content = DEVELOPER_VERIFIED + '\n'
        elif field == 'content_rating':
            content = CONTENT_RATING_12 + '\n'  # default 12+, user can change
        elif field == 'soft_copyright':
            content = SOFT_COPYRIGHT + '\n'
        write_field(platform, field, content)


def main() -> None:
    print('[1/2] Generating 8 CN domestic platform metadata ...')
    for platform in PLATFORM_FIELDS:
        generate_platform(platform)
    print('[OK] CN domestic metadata generated')


if __name__ == '__main__':
    main()