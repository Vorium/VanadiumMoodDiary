#!/usr/bin/env python3
"""ChronicCare Play feature graphic generator (emotion-first).

Output: 1024×500 PNG with gradient background + Combo 1 icon + brand title.

Usage: python3 scripts/generate_feature_graphic.py
"""

from __future__ import annotations
import os
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
W, H = 1024, 500
PEACH = (255, 176, 136)
LAVENDER = (181, 160, 212)
WHITE = (255, 255, 255)


def gradient_bg() -> Image.Image:
    grad = Image.new('RGB', (W, 1))
    for x in range(W):
        t = x / (W - 1)
        row = tuple(int(PEACH[i] * (1 - t) + LAVENDER[i] * t) for i in range(3))
        grad.putpixel((x, 0), row)
    return grad.resize((W, H))


def make_graphic(title: str, font_path: str, master_icon_path: str) -> Image.Image:
    bg = gradient_bg()
    # Load master icon, place left
    icon = Image.open(master_icon_path).convert('RGB')
    icon = icon.resize((330, 330), Image.LANCZOS)
    mask = Image.new('L', (330, 330), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, 329, 329], radius=74, fill=255)
    icon.putalpha(mask)
    bg.paste(icon, (150, (H - 330) // 2), icon)
    # Title text right
    d = ImageDraw.Draw(bg)
    font = ImageFont.truetype(font_path, 80)
    d.text((540, H // 2), title, font=font, fill=WHITE, anchor='lm')
    return bg


def main() -> None:
    master = os.path.join(ROOT, 'assets/brand/app_icon_master.png')
    configs = [
        ('en-US', 'MoodDiary', '/System/Library/Fonts/Helvetica.ttc',
         'fastlane/metadata/android/en-US/feature_graphic.png'),
        ('zh-CN', 'MoodDiary 心情日记', '/System/Library/Fonts/Hiragino Sans GB.ttc',
         'fastlane/metadata/android/zh-CN/feature_graphic.png'),
    ]
    for locale, title, font_path, rel_path in configs:
        if not os.path.exists(font_path):
            print(f'  skip {locale}: font missing {font_path}')
            continue
        img = make_graphic(title, font_path, master)
        out = os.path.join(ROOT, rel_path)
        img.save(out)
        print(f'  {locale}/feature_graphic.png ({W}x{H})')
    print('[OK] feature graphics generated')


if __name__ == '__main__':
    main()
