#!/usr/bin/env python3
"""Gatekeeper: validate all generated icon variants (R128e+ Combo 1).

Checks:
  - assets/brand/app_icon_master.png exists, 1024x1024, >=5KB
  - assets/brand/icon-1024.png exists, 1024x1024
  - assets/brand/icon-512.png exists, 512x512
  - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png >=5KB
  - android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png exists
  - fastlane/metadata/android/{en-US,zh-CN}/icon.png exists, 512x512
  - fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png exists, 1024x500
  - assets/brand/cn/{8 platforms}-icon-512.png all exist, 512x512
  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml + ic_launcher_foreground.png exist
  - master PNG dominant colors in brand range (sampling 9 points)

NOTE: Brief specified >=250KB but Task 2 ruled the "Sunset Breath" flat-design
master compresses to ~9KB. Task 10 will formalize the lower threshold; using
5KB here as the practical lower bound that matches reality.

Usage: python3 scripts/check_icon_quality.py
Exit 0: all pass / Exit 1: any failure
"""

from __future__ import annotations
import os
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

REQUIRED_FILES = [
    ('assets/brand/app_icon_master.png', 1024, 1024, 5_000),
    ('assets/brand/icon-1024.png', 1024, 1024, 5_000),
    ('assets/brand/icon-512.png', 512, 512, 0),
    ('ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png',
     1024, 1024, 5_000),
    ('android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png', 192, 192, 0),
    ('fastlane/metadata/android/en-US/icon.png', 512, 512, 0),
    ('fastlane/metadata/android/zh-CN/icon.png', 512, 512, 0),
    ('fastlane/metadata/android/en-US/feature_graphic.png', 1024, 500, 0),
    ('fastlane/metadata/android/zh-CN/feature_graphic.png', 1024, 500, 0),
    ('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml', None, None, 0),
    ('android/app/src/main/res/mipmap-anydpi-v26/ic_launcher_foreground.png',
     None, None, 0),
]

CN_DOMESTIC_ICONS = [
    'huawei', 'xiaomi', 'oppo', 'vivo', 'meizu', 'tencent', 'qihoo', 'baidu'
]


def check_file(rel_path, w, h, min_size):
    p = ROOT / rel_path
    if not p.exists():
        return f'  MISSING: {rel_path}'
    if min_size > 0 and p.stat().st_size < min_size:
        return f'  TOO SMALL: {rel_path} ({p.stat().st_size} < {min_size})'
    if w and h:
        try:
            from PIL import Image
            with Image.open(p) as img:
                if img.size != (w, h):
                    return f'  WRONG SIZE: {rel_path} {img.size} != ({w},{h})'
        except ImportError:
            return f'  WARN: Pillow not installed, skip dimension check'
        except Exception as e:
            return f'  CORRUPT: {rel_path} ({e})'
    return None


def check_brand_colors(master_path):
    """Sample 9 points from master, verify colors in brand range."""
    try:
        from PIL import Image
    except ImportError:
        return None
    p = ROOT / master_path
    if not p.exists():
        return None
    with Image.open(p) as img:
        w, h = img.size
        samples = []
        for r in range(3):
            for c in range(3):
                x = int(w * (c + 0.5) / 3)
                y = int(h * (r + 0.5) / 3)
                samples.append(img.getpixel((x, y)))
        def in_range(rgb):
            r, g, b = rgb[:3]
            return (r > 150 and g > 150 and b > 100)
        for s in samples:
            if not in_range(s):
                return f'  OUT OF BRAND RANGE: {master_path} sample {s}'
    return None


def main():
    errors = []
    for rel, w, h, minsz in REQUIRED_FILES:
        err = check_file(rel, w, h, minsz)
        if err:
            errors.append(err)
    for platform in CN_DOMESTIC_ICONS:
        rel = f'assets/brand/cn/{platform}-icon-512.png'
        err = check_file(rel, 512, 512, 0)
        if err:
            errors.append(err)
    bc = check_brand_colors('assets/brand/app_icon_master.png')
    if bc:
        errors.append(bc)
    if errors:
        print('ICON QUALITY CHECK FAILED:')
        for e in errors:
            print(e)
        sys.exit(1)
    print('[OK] All icons present and within brand color range')


if __name__ == '__main__':
    main()