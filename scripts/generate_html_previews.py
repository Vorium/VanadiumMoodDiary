#!/usr/bin/env python3
"""Generate HTML preview pages for icons + CN metadata.

Output:
  - assets/brand/icon_showcase.html
  - assets/brand/cn_domestic_preview.html

Usage: python3 scripts/generate_html_previews.py
"""

from __future__ import annotations
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


ICON_SHOWCASE_HTML = '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>MoodDiary Icon Showcase</title>
<style>
body { font-family: -apple-system, sans-serif; background: #fafafa; padding: 40px; }
h1 { color: #333; }
.grid { display: grid; grid-template-columns: repeat(4, 1fr); gap: 30px; margin: 20px 0; }
.card { background: white; padding: 20px; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
.card h3 { margin: 0 0 10px; font-size: 14px; color: #666; }
.card img { width: 100%; max-width: 200px; height: auto; display: block; }
</style></head><body>
<h1>MoodDiary Icon — Combo 1 Sunset Breath</h1>
<p>Brand: #FFB088 sunset peach → #B5A0D4 lavender · emotion-first</p>
<div class="grid">
  <div class="card"><h3>Master 1024×1024</h3><img src="app_icon_master.png"></div>
  <div class="card"><h3>iOS AppIcon 1024</h3><img src="icon-1024.png"></div>
  <div class="card"><h3>Play 512</h3><img src="icon-512.png"></div>
  <div class="card"><h3>Android xxxhdpi 192</h3><img src="../android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png"></div>
  <div class="card"><h3>Huawei 512</h3><img src="cn/huawei-icon-512.png"></div>
  <div class="card"><h3>Xiaomi 512</h3><img src="cn/xiaomi-icon-512.png"></div>
  <div class="card"><h3>OPPO 512</h3><img src="cn/oppo-icon-512.png"></div>
  <div class="card"><h3>vivo 512</h3><img src="cn/vivo-icon-512.png"></div>
  <div class="card"><h3>Meizu 512</h3><img src="cn/meizu-icon-512.png"></div>
  <div class="card"><h3>Tencent 512</h3><img src="cn/tencent-icon-512.png"></div>
  <div class="card"><h3>360 512</h3><img src="cn/qihoo-icon-512.png"></div>
  <div class="card"><h3>Baidu 512</h3><img src="cn/baidu-icon-512.png"></div>
</div>
</body></html>
'''

CN_PREVIEW_HTML = '''<!DOCTYPE html>
<html><head><meta charset="utf-8"><title>8 CN Domestic Platforms</title>
<style>
body { font-family: -apple-system, sans-serif; background: #fafafa; padding: 40px; }
h1 { color: #333; }
.platform { background: white; padding: 20px; margin: 15px 0; border-radius: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.06); }
.platform h2 { margin: 0 0 10px; }
.platform .icon { width: 80px; height: 80px; float: right; border-radius: 12px; }
.field { padding: 8px 0; border-bottom: 1px solid #eee; }
.field .label { font-weight: 600; color: #888; font-size: 12px; }
.field .value { white-space: pre-wrap; font-size: 14px; }
</style></head><body>
<h1>MoodDiary 8 CN Domestic Platforms</h1>
__PLATFORMS__
</body></html>
'''


def main() -> None:
    out1 = os.path.join(ROOT, 'assets/brand/icon_showcase.html')
    with open(out1, 'w') as f:
        f.write(ICON_SHOWCASE_HTML)
    print(f'  icon_showcase.html')
    platforms_html = ''
    for platform in ('huawei', 'xiaomi', 'oppo', 'vivo', 'meizu', 'tencent', 'qihoo', 'baidu'):
        intro_path = os.path.join(ROOT, f'fastlane/metadata/cn_domestic/{platform}/app_intro.txt')
        tags_path = os.path.join(ROOT, f'fastlane/metadata/cn_domestic/{platform}/app_tags.txt')
        cat_path = os.path.join(ROOT, f'fastlane/metadata/cn_domestic/{platform}/app_category.txt')
        icon_path = f'cn/{platform}-icon-512.png'
        with open(intro_path) as f:
            intro = f.read()
        with open(tags_path) as f:
            tags = f.read()
        try:
            with open(cat_path) as f:
                cat = f.read()
        except FileNotFoundError:
            cat = '—'
        platforms_html += f'''
<div class="platform">
  <h2>{platform}</h2>
  <img class="icon" src="{icon_path}">
  <div class="field"><div class="label">app_intro</div><div class="value">{intro[:300]}...</div></div>
  <div class="field"><div class="label">app_tags</div><div class="value">{tags}</div></div>
  <div class="field"><div class="label">app_category</div><div class="value">{cat}</div></div>
</div>
'''
    out2 = os.path.join(ROOT, 'assets/brand/cn_domestic_preview.html')
    with open(out2, 'w') as f:
        f.write(CN_PREVIEW_HTML.replace('__PLATFORMS__', platforms_html))
    print(f'  cn_domestic_preview.html')
    print('[OK] HTML previews generated')


if __name__ == '__main__':
    main()