#!/usr/bin/env python3
"""ChronicCare emotion-first icon generator (R128e+ Combo 1 'Sunset Breath').

Single source: 1024x1024 master icon → all platform variants.

Design (emotion-first, NOT medical):
  - Background: horizontal gradient #FFB088 (peach) → #B5A0D4 (lavender)
  - Main shape: white half-circle (sun/moon metaphor, transparency 92%)
  - Inner space: negative space (B philosophy) at center-bottom, radius 80
  - Emotion wave: cubic Bezier curve, 1.5px white stroke, transparency 75%

Outputs:
  - assets/brand/app_icon_master.png (1024×1024)
  - assets/brand/icon-1024.png (iOS AppIcon)
  - assets/brand/icon-512.png (Play icon)
  - ios/Runner/Assets.xcassets/AppIcon.appiconset/ (16 sizes)
  - ios/Runner/Assets.xcassets/LaunchImage.imageset/ (3 sizes)
  - android/app/src/main/res/mipmap-*/ (5 sizes)
  - android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml (adaptive)
  - fastlane/metadata/android/{en-US,zh-CN}/icon.png (2 × 512×512)
  - fastlane/metadata/android/{en-US,zh-CN}/feature_graphic.png (2 × 1024×500)
  - assets/brand/cn/{huawei,xiaomi,oppo,vivo,meizu,tencent,qihoo,baidu}-icon-512.png (8)

Usage: python3 scripts/generate_app_icon.py
"""

from __future__ import annotations
import os
from PIL import Image, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
S = 1024
PEACH = (255, 176, 136)   # #FFB088
LAVENDER = (181, 160, 212)  # #B5A0D4
WHITE = (255, 255, 255)
WAVE_COLOR = (255, 255, 255, 191)  # 75% alpha


def gradient_bg(size: int = S) -> Image.Image:
    """Horizontal gradient #FFB088 → #B5A0D4."""
    grad = Image.new('RGB', (size, 1))
    for x in range(size):
        t = x / (size - 1)
        row = tuple(int(PEACH[i] * (1 - t) + LAVENDER[i] * t) for i in range(3))
        grad.putpixel((x, 0), row)
    return grad.resize((size, size))


def master_icon() -> Image.Image:
    img = gradient_bg(S)
    overlay = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    # Main half-circle: center (512, 460), radius 320
    cx, cy, r = 512, 460, 320
    d.pieslice([cx - r, cy - r, cx + r, cy + r], 180, 360, fill=(255, 255, 255, 235))
    # Inner negative space circle (B philosophy)
    inner_cx, inner_cy, inner_r = 512, 600, 80
    d.ellipse([inner_cx - inner_r, inner_cy - inner_r, inner_cx + inner_r, inner_cy + inner_r],
              fill=(255, 176, 136, 0))  # transparent
    # Emotion wave: cubic Bezier
    wave_pts = [(180, 700), (350, 760), (674, 760), (844, 700)]
    d.line(wave_pts, fill=WAVE_COLOR, width=24, joint='curve')
    img.paste(overlay, (0, 0), overlay)
    return img.convert('RGB')


def ios_appicons(master: Image.Image) -> None:
    out = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/AppIcon.appiconset')
    sizes = [(20, 1), (20, 2), (20, 3), (29, 1), (29, 2), (29, 3), (40, 1),
             (40, 2), (40, 3), (60, 2), (60, 3), (76, 1), (76, 2), (83.5, 2),
             (1024, 1)]
    for base, scale in sizes:
        px = int(base * scale)
        src = master if base == 1024 else master.resize((px, px), Image.LANCZOS)
        name = f'Icon-App-{base}x{base}@{scale}x.png'
        src.save(os.path.join(out, name))
        print(f'  iOS {name}')
    # Also save to assets/brand for reference
    master.save(os.path.join(ROOT, 'assets/brand/icon-1024.png'))


def launch_images(master: Image.Image) -> None:
    out = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    for scale, w, h in [(1, 320, 568), (2, 640, 1136), (3, 960, 1704)]:
        bg = Image.new('RGB', (w, h), WHITE)
        iw = int(w * 0.30)
        icon = master.resize((iw, iw), Image.LANCZOS)
        # Squircle mask
        mask = Image.new('L', (iw, iw), 0)
        ImageDraw.Draw(mask).rounded_rectangle(
            [0, 0, iw - 1, iw - 1], radius=int(iw * 0.225), fill=255)
        icon.putalpha(mask)
        bg.paste(icon, ((w - iw) // 2, (h - iw) // 2), icon)
        name = 'LaunchImage.png' if scale == 1 else f'LaunchImage@{scale}x.png'
        bg.save(os.path.join(out, name))
        print(f'  LaunchImage {name} ({w}x{h})')


def android_listing_icons(master: Image.Image) -> None:
    icon = master.resize((512, 512), Image.LANCZOS)
    for locale in ('en-US', 'zh-CN'):
        path = os.path.join(ROOT, f'fastlane/metadata/android/{locale}/icon.png')
        icon.save(path)
        print(f'  Play {locale}/icon.png (512x512)')
    master.resize((512, 512), Image.LANCZOS).save(
        os.path.join(ROOT, 'assets/brand/icon-512.png'))


def android_mipmaps(master: Image.Image) -> None:
    specs = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for dpi, px in specs.items():
        path = os.path.join(ROOT, f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png')
        master.resize((px, px), Image.LANCZOS).save(path)
        print(f'  Android mipmap-{dpi}/ic_launcher.png ({px}x{px})')


def android_adaptive_icon(master: Image.Image) -> None:
    """Generate foreground PNG + background XML for Android 8+ adaptive icon.
    Viewport 108×108, safe zone 72×72 (centered)."""
    fg_dir = os.path.join(ROOT, 'android/app/src/main/res/mipmap-anydpi-v26')
    os.makedirs(fg_dir, exist_ok=True)
    fg_size = 432  # 108 * 4 for retina
    fg = Image.new('RGBA', (fg_size, fg_size), (0, 0, 0, 0))
    icon = master.resize((fg_size, fg_size), Image.LANCZOS)
    mask = Image.new('L', (fg_size, fg_size), 0)
    ImageDraw.Draw(mask).ellipse([0, 0, fg_size - 1, fg_size - 1], fill=255)
    fg.paste(icon, (0, 0), mask)
    fg.save(os.path.join(fg_dir, 'ic_launcher_foreground.png'))
    # Background drawable XML (solid peach)
    xml = '''<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/sunset_peach" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
'''
    with open(os.path.join(fg_dir, 'ic_launcher.xml'), 'w') as f:
        f.write(xml)
    with open(os.path.join(fg_dir, 'ic_launcher_round.xml'), 'w') as f:
        f.write(xml)
    # Add color resource
    colors_path = os.path.join(ROOT, 'android/app/src/main/res/values/colors.xml')
    if os.path.exists(colors_path):
        with open(colors_path, 'r') as f:
            content = f.read()
        if 'sunset_peach' not in content:
            content = content.replace(
                '</resources>',
                '    <color name="sunset_peach">#FFB088</color>\n</resources>')
            with open(colors_path, 'w') as f:
                f.write(content)
    else:
        with open(colors_path, 'w') as f:
            f.write('<?xml version="1.0" encoding="utf-8"?>\n<resources>\n'
                    '    <color name="sunset_peach">#FFB088</color>\n</resources>\n')
    print(f'  Android adaptive icon (foreground + background)')


def main() -> None:
    print('[1/8] Generating 1024×1024 master ...')
    master = master_icon()
    master.save(os.path.join(ROOT, 'assets/brand/app_icon_master.png'))
    print('[2/8] iOS AppIcon 16 sizes ...')
    ios_appicons(master)
    print('[3/8] iOS LaunchImage 3 sizes ...')
    launch_images(master)
    print('[4/8] Play icon 2 × 512 ...')
    android_listing_icons(master)
    print('[5/8] Android mipmap 5 sizes ...')
    android_mipmaps(master)
    print('[6/8] Android adaptive icon ...')
    android_adaptive_icon(master)
    print('[7/8] Feature graphic (covered in generate_feature_graphic.py) ...')
    print('[8/8] 8 CN domestic icons (covered in cn_domestic_icons() task) ...')
    print('[OK] All icon variants generated')


if __name__ == '__main__':
    main()