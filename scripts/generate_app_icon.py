#!/usr/bin/env python3
"""ChronicCare 品牌图标统一生成器 (v1.0.0+ 设计优化).

单一事实来源: 1024x1024 主图标 (iOS AppIcon) 生成:
  1. iOS AppIcon 15 尺寸 -> ios/Runner/Assets.xcassets/AppIcon.appiconset/
  2. iOS LaunchImage 3 尺寸 -> ios/Runner/Assets.xcassets/LaunchImage.imageset/
  3. Google Play 商店图标 512x512 -> fastlane/metadata/android/{en-US,zh-CN}/icon.png
  4. Android mipmap 5 尺寸 -> android/app/src/main/res/mipmap-*/
  5. Play feature graphic 1024x500 -> fastlane/metadata/android/{en-US,zh-CN}/

设计 (与 android adaptive icon XML + R108 设计 brief 对齐):
  - 品牌色: Apple Health 绿 #34C759 系 (渐变 #6BCF7F -> #2F9E44)
  - 图形: 白色胶囊 (吃药) + 右下心形 (关怀) + 左上医疗十字
  - iOS: 满幅方形 (Apple 自动裁圆角); 无 alpha; 无文字
  - Launch: 白底 + 居中圆角图标 (与浅色 App 主题呼应)

依赖: python3 + pillow  (pip3 install --user pillow)

用法:
  python3 scripts/generate_app_icon.py
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

S = 1024
TOP = (107, 207, 127)    # #6BCF7F
BOTTOM = (47, 158, 68)   # #2F9E44
WHITE = (255, 255, 255)
SHADOW = (20, 100, 50, 90)


def gradient_bg(size: int) -> Image.Image:
    grad = Image.new('RGB', (1, size))
    for y in range(size):
        t = y / (size - 1)
        row = tuple(int(TOP[i] * (1 - t) + BOTTOM[i] * t) for i in range(3))
        grad.putpixel((0, y), row)
    return grad.resize((size, size))


def draw_glyphs(d: ImageDraw.ImageDraw, scale: float = 1.0, center=(512, 512),
                fill=WHITE) -> None:
    """胶囊 + 心形 + 十字 (几何与 Android adaptive icon vector 同构图)."""
    k = scale
    cx, cy = center

    # 胶囊: Android viewport 108 -> 1024 (k=9.48), 48x24 @ (30,42)
    cap_x0 = cx - 227.5 * k
    cap_y0 = cy - 113.5 * k
    cap_x1 = cx + 227.5 * k
    cap_y1 = cy + 113.5 * k
    d.rounded_rectangle([cap_x0, cap_y0, cap_x1, cap_y1], radius=113 * k, fill=fill)

    # 心形: 中心 Android (71,66) -> 相对胶囊中心 (17,12)*9.48 = (161,114)
    hx = cx + 161 * k
    hy = cy + 114 * k
    r = 48 * k
    d.ellipse([hx - 2 * r, hy - r, hx, hy + r], fill=fill)
    d.ellipse([hx, hy - r, hx + 2 * r, hy + r], fill=fill)
    d.polygon([(hx - 2 * r, hy), (hx + 2 * r, hy), (hx, hy + 2 * r)], fill=fill)

    # 十字: 中心 Android (51,39) -> 相对胶囊中心 (-3,-15)*9.48 = (-28,-142)
    rx = cx - 28 * k
    ry = cy - 142 * k
    ahw = 19 * k   # arm half-width
    ahl = 47.5 * k  # arm half-length
    d.rectangle([rx - ahw, ry - ahl, rx + ahw, ry + ahl], fill=fill)
    d.rectangle([rx - ahl, ry - ahw, rx + ahl, ry + ahw], fill=fill)


def master_icon() -> Image.Image:
    img = gradient_bg(S)
    shadow = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    draw_glyphs(sd, fill=SHADOW)
    shadow = shadow.filter(ImageFilter.GaussianBlur(28))
    offset = Image.new('RGBA', (S, S), (0, 0, 0, 0))
    offset.paste(shadow, (0, 24), shadow)
    img.paste(Image.new('RGB', (S, S)), (0, 0), offset) if False else None
    # 合成阴影
    flat = img.convert('RGBA')
    flat.alpha_composite(offset)
    img = flat.convert('RGB')
    d = ImageDraw.Draw(img)
    draw_glyphs(d)
    return img


def rounded_icon(master: Image.Image, size: int) -> Image.Image:
    """master 缩放后裁圆角 (iOS squircle 近似 22.5%)."""
    icon = master.resize((size, size), Image.LANCZOS)
    mask = Image.new('L', (size, size), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle([0, 0, size - 1, size - 1], radius=int(size * 0.225),
                         fill=255)
    icon.putalpha(mask)
    return icon


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
        print(f'  {name}')


def launch_images(master: Image.Image) -> None:
    out = os.path.join(ROOT, 'ios/Runner/Assets.xcassets/LaunchImage.imageset')
    for scale, w, h in [(1, 320, 568), (2, 640, 1136), (3, 960, 1704)]:
        bg = Image.new('RGB', (w, h), (255, 255, 255))
        iw = int(w * 0.30)
        icon = rounded_icon(master, iw)
        bg.paste(icon, ((w - iw) // 2, (h - iw) // 2), icon)
        name = 'LaunchImage.png' if scale == 1 else f'LaunchImage@{scale}x.png'
        bg.save(os.path.join(out, name))
        print(f'  {name} ({w}x{h})')


def android_listing_icons(master: Image.Image) -> None:
    icon = master.resize((512, 512), Image.LANCZOS)
    for locale in ('en-US', 'zh-CN'):
        path = os.path.join(ROOT, f'fastlane/metadata/android/{locale}/icon.png')
        icon.save(path)
        print(f'  {locale}/icon.png (512x512)')


def android_mipmaps(master: Image.Image) -> None:
    specs = {'mdpi': 48, 'hdpi': 72, 'xhdpi': 96, 'xxhdpi': 144, 'xxxhdpi': 192}
    for dpi, px in specs.items():
        path = os.path.join(ROOT, f'android/app/src/main/res/mipmap-{dpi}/ic_launcher.png')
        master.resize((px, px), Image.LANCZOS).save(path)
        print(f'  mipmap-{dpi}/ic_launcher.png ({px}x{px})')


def feature_graphic(master: Image.Image) -> None:
    w, h = 1024, 500
    bg = gradient_bg(500).resize((w, h))
    logo = rounded_icon(master, 330)
    bg.paste(logo, (150, (h - 330) // 2), logo)
    fonts = [
        ('en-US', 'ChronicCare', '/System/Library/Fonts/Helvetica.ttc'),
        ('zh-CN', '慢病管家', '/System/Library/Fonts/Hiragino Sans GB.ttc'),
    ]
    for locale, title, font_path in fonts:
        canvas = bg.copy()
        d = ImageDraw.Draw(canvas)
        font = ImageFont.truetype(font_path, 110)
        d.text((540, h // 2), title, font=font, fill=WHITE, anchor='lm')
        path = os.path.join(
            ROOT, f'fastlane/metadata/android/{locale}/feature_graphic.png')
        canvas.save(path)
        print(f'  {locale}/feature_graphic.png ({w}x{h})')


def main() -> None:
    print('[1/5] 生成 1024x1024 主图标 ...')
    master = master_icon()
    print('[2/5] iOS AppIcon 15 尺寸 ...')
    ios_appicons(master)
    print('[3/5] iOS LaunchImage 3 尺寸 ...')
    launch_images(master)
    print('[4/5] Android 商店图标 + mipmap ...')
    android_listing_icons(master)
    android_mipmaps(master)
    print('[5/5] Play feature graphic ...')
    feature_graphic(master)
    print('[OK] 全部品牌资产已生成')


if __name__ == '__main__':
    main()
