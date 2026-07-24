"""Generate v4 vs v5 transition preview image.

Layout (1800x1100):
  Header: "v4 -> v5 (9.7) - 9.5/10 -> 9.7/10"
  Section 1: v4 master vs v5 master direct comparison (256px)
  Section 2: v5 multi-size ladder
  Section 3: v5 favicon on 5 backgrounds
  Section 4: PWA install card + iOS home + Android adaptive (v5)
"""
import os
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("D:/Batch/chroniccare")
BRAND = ROOT / "assets" / "brand"
WEB = ROOT / "web"
ICONS = WEB / "icons"
OUT = BRAND / "icon_preview_v5.png"

W, H = 1800, 1100
PAD = 60
BG = (250, 250, 250)
TEXT = (26, 26, 26)
MUTED = (102, 102, 102)
LINE = (224, 224, 224)
GREEN = (107, 207, 127)
GREEN_DARK = (79, 176, 95)


def get_font(size, bold=False):
    candidates = []
    if bold:
        candidates += [
            ("C:/Windows/Fonts/msyhbd.ttc", 0),
            ("C:/Windows/Fonts/msyh.ttc", 0),
            ("C:/Windows/Fonts/simhei.ttf", 0),
        ]
    else:
        candidates += [
            ("C:/Windows/Fonts/msyh.ttc", 0),
            ("C:/Windows/Fonts/simhei.ttf", 0),
            ("C:/Windows/Fonts/simsun.ttc", 0),
        ]
    candidates += [
        ("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf", 0),
    ]
    for path, idx in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size, index=idx)
            except Exception:
                continue
    return ImageFont.load_default()


def rounded(img, radius_pct):
    w, h = img.size
    r = int(min(w, h) * radius_pct)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=r, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def text_w(draw, text, font):
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def section_header(draw, y, num, title):
    draw.text((PAD, y), num, fill=GREEN_DARK, font=get_font(20, bold=True))
    tw = text_w(draw, num, get_font(20, bold=True))
    draw.text((PAD + tw + 12, y), title, fill=TEXT, font=get_font(20, bold=True))
    return y + 40


def main():
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    # Header
    draw.text((PAD, PAD), "慢病管家 · v4 (9.5) -> v5 (9.7) 替换完成", fill=TEXT, font=get_font(30, bold=True))
    draw.text(
        (PAD, PAD + 42),
        "从「医药类目通用 (胶囊+嫩芽)」切到「独有品牌 logo (two-leaf sprout)」",
        fill=MUTED,
        font=get_font(16),
    )

    # Section 1: v4 vs v5
    y = section_header(draw, PAD + 100, "1.", "v4 vs v5 直接对比（256px iOS rounded）")
    v4 = Image.open(BRAND / "app_icon_master_v4.png").convert("RGBA")
    v5 = Image.open(BRAND / "app_icon_master_v5.png").convert("RGBA")
    v4_256 = rounded(v4.resize((256, 256), Image.Resampling.LANCZOS), 0.224)
    v5_256 = rounded(v5.resize((256, 256), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(v4_256, (PAD, y), v4_256)
    canvas.paste(v5_256, (PAD + 360, y), v5_256)
    draw.text((PAD, y + 270), "v4  ·  医药类目通用 (Medisafe/Pillo 也能用)", fill=MUTED, font=get_font(14))
    draw.text((PAD + 360, y + 270), "v5  ·  独有品牌 (只有慢病管家能这么画)", fill=GREEN_DARK, font=get_font(14, bold=True))

    # Section 2: v5 multi-size ladder
    y = y + 320
    y = section_header(draw, y, "2.", "v5 全尺寸（24 / 32 / 40 / 64 / 80 / 128 / 192）")
    sizes = [192, 128, 80, 64, 40, 32, 24]
    x = PAD
    for s in sizes:
        icon = rounded(v5.resize((s, s), Image.Resampling.LANCZOS), 0.224)
        canvas.paste(icon, (x, y), icon)
        label = f"{s}px"
        lw = text_w(draw, label, get_font(12))
        draw.text((x + (s - lw) // 2, y + s + 8), label, fill=MUTED, font=get_font(12))
        x += s + 36

    # Section 3: v5 background swatches
    y = y + 250
    y = section_header(draw, y, "3.", "v5 不同背景上的识别性（40px favicon）")
    favicon = Image.open(WEB / "favicon.png").convert("RGBA")
    favicon = rounded(favicon, 0.224)
    swatches = [
        ("Light", (255, 255, 255)),
        ("Gray", (240, 240, 240)),
        ("Brand", GREEN),
        ("Dark", (30, 30, 30)),
        ("Black", (0, 0, 0)),
    ]
    sw_w, sw_h, gap = 320, 88, 20
    x = PAD
    for name, color in swatches:
        d2 = ImageDraw.Draw(canvas)
        d2.rounded_rectangle((x, y, x + sw_w, y + sw_h), radius=16, fill=color)
        canvas.paste(favicon, (x + 20, y + (sw_h - 40) // 2), favicon)
        text_color = TEXT if name in ("Light", "Gray", "Brand") else (230, 230, 230)
        d2.text((x + 76, y + 18), "慢病管家", fill=text_color, font=get_font(18, bold=True))
        d2.text(
            (x + 76, y + 46),
            f"我今天吃了药 · {name}",
            fill=text_color if text_color == TEXT else (180, 180, 180),
            font=get_font(13),
        )
        x += sw_w + gap

    # Section 4: PWA + home tile
    y = y + 160
    draw.text((PAD, y), "4.", fill=GREEN_DARK, font=get_font(20, bold=True))
    tw = text_w(draw, "4.", get_font(20, bold=True))
    draw.text((PAD + tw + 12, y), "PWA 安装卡片 + 手机主屏模拟", fill=TEXT, font=get_font(20, bold=True))
    y += 40

    card_x, card_y, card_w, card_h = PAD, y, 560, 110
    d2 = ImageDraw.Draw(canvas)
    d2.rounded_rectangle((card_x, card_y, card_x + card_w, card_y + card_h), radius=24, fill=(255, 255, 255))
    d2.rectangle((card_x, card_y, card_x + card_w, card_y + card_h), outline=LINE)
    icon192 = rounded(
        Image.open(ICONS / "Icon-192.png").convert("RGBA").resize((66, 66), Image.Resampling.LANCZOS),
        0.224,
    )
    canvas.paste(icon192, (card_x + 22, card_y + (card_h - 66) // 2), icon192)
    d2.text((card_x + 110, card_y + 26), "慢病管家", fill=TEXT, font=get_font(20, bold=True))
    d2.text((card_x + 110, card_y + 58), "我今天吃了药 - 精神心理患者吃药打卡", fill=MUTED, font=get_font(14))
    btn_w, btn_h = 90, 38
    btn_x = card_x + card_w - btn_w - 22
    btn_y = card_y + (card_h - btn_h) // 2
    d2.rounded_rectangle((btn_x, btn_y, btn_x + btn_w, btn_y + btn_h), radius=btn_h // 2, fill=GREEN)
    install_text = "安装"
    iw = text_w(d2, install_text, get_font(15, bold=True))
    d2.text((btn_x + (btn_w - iw) // 2, btn_y + 10), install_text, fill=(255, 255, 255), font=get_font(15, bold=True))

    # iOS tile
    tile_size = 96
    tx = card_x + card_w + 40
    ty = card_y
    d2.rounded_rectangle((tx, ty, tx + tile_size, ty + tile_size), radius=22, fill=(238, 240, 245))
    icon_t = rounded(v5.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(icon_t, (tx + 10, ty + 10), icon_t)
    d2.text((tx, ty + tile_size + 10), "iOS home", fill=MUTED, font=get_font(12))

    # Android adaptive
    tx2 = tx + tile_size + 40
    d2.rounded_rectangle((tx2, ty, tx2 + tile_size, ty + tile_size), radius=22, fill=(28, 28, 30))
    icon_circle = Image.new("RGBA", (tile_size - 20, tile_size - 20), (0, 0, 0, 0))
    icon_circle.paste(v5.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), (0, 0))
    mask = Image.new("L", (tile_size - 20, tile_size - 20), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, tile_size - 20, tile_size - 20), fill=255)
    icon_circle.putalpha(mask)
    canvas.paste(icon_circle, (tx2 + 10, ty + 10), icon_circle)
    d2.text((tx2, ty + tile_size + 10), "Android adaptive", fill=MUTED, font=get_font(12))

    # Footer
    draw.text(
        (PAD, H - 40),
        "v5 源: assets/brand/app_icon_master_v5.png · app_icon_maskable_v5.png  (v5 = #4 two-leaf sprout from 100 variations)",
        fill=MUTED,
        font=get_font(13),
    )

    canvas.save(OUT, "PNG", optimize=True)
    print(f"Saved: {OUT}  ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
