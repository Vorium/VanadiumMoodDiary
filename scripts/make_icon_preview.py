"""Compose a single preview image showing the icon at multiple sizes and on
multiple background swatches. This is the deliverable preview — easy to
share in chat, README, and the design review doc.

Layout (1600x1100):
  Row 1: master icon at 512 / 192 / 96 / 64 / 32 px
  Row 2: icon on light / gray / green / dark / black backgrounds (40 px, like favicon)
  Row 3: iOS home tile mock + Android adaptive circle mask + PWA install card mock
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("D:/Batch/chroniccare")
BRAND = ROOT / "assets" / "brand"
WEB = ROOT / "web"
ICONS = WEB / "icons"
OUT = BRAND / "icon_preview.png"

W, H = 1600, 1100
PAD = 60
BG = (250, 250, 250)
TEXT = (26, 26, 26)
MUTED = (102, 102, 102)
LINE = (224, 224, 224)


def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    # .ttc files need explicit index; try YaHei (CJK + Latin) first
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
    # Latin fallback
    candidates += [
        ("C:/Windows/Fonts/segoeuib.ttf" if bold else "C:/Windows/Fonts/segoeui.ttf", 0),
        ("C:/Windows/Fonts/arialbd.ttf" if bold else "C:/Windows/Fonts/arial.ttf", 0),
    ]
    for path, idx in candidates:
        if Path(path).exists():
            try:
                return ImageFont.truetype(path, size, index=idx)
            except Exception:
                continue
    return ImageFont.load_default()


def rounded(img: Image.Image, radius_pct: float) -> Image.Image:
    w, h = img.size
    r = int(min(w, h) * radius_pct)
    mask = Image.new("L", (w, h), 0)
    d = ImageDraw.Draw(mask)
    d.rounded_rectangle((0, 0, w, h), radius=r, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def text_w(draw: ImageDraw.ImageDraw, text: str, font) -> int:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def main() -> None:
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    # Header
    draw.text((PAD, PAD), "慢病管家 · App 图标", fill=TEXT, font=get_font(36, bold=True))
    draw.text(
        (PAD, PAD + 50),
        "概念：胶囊药丸（吃药）+ 嫩芽（还在坚持）+ 嫩绿主色 #6BCF7F",
        fill=MUTED,
        font=get_font(18),
    )

    # Section 1: scale ladder
    sec1_header_y = PAD + 110
    draw.text((PAD, sec1_header_y), "1. 多尺寸缩放（iOS rounded 22.4%）", fill=TEXT, font=get_font(20, bold=True))
    y = sec1_header_y + 40

    master = Image.open(BRAND / "app_icon_master.png").convert("RGBA")
    sizes = [160, 128, 80, 64, 40, 32, 24]
    x = PAD
    for s in sizes:
        icon = master.resize((s, s), Image.Resampling.LANCZOS)
        icon = rounded(icon, 0.224)
        canvas.paste(icon, (x, y), icon)
        # size label
        label = f"{s}px"
        lw = text_w(draw, label, get_font(12))
        draw.text((x + (s - lw) // 2, y + s + 8), label, fill=MUTED, font=get_font(12))
        x += s + 36

    # Section 2: background swatches
    sec2_header_y = y + 200  # below sec1 icons + label
    draw.text((PAD, sec2_header_y), "2. 不同背景上的识别性（40px favicon）", fill=TEXT, font=get_font(20, bold=True))
    y = sec2_header_y + 40

    favicon = Image.open(WEB / "favicon.png").convert("RGBA")
    favicon = rounded(favicon, 0.224)
    swatches = [
        ("Light",    (255, 255, 255)),
        ("Gray",     (240, 240, 240)),
        ("Brand",    (107, 207, 127)),
        ("Dark",     (30, 30, 30)),
        ("Black",    (0, 0, 0)),
    ]
    sw_w, sw_h, gap = 280, 88, 20
    x = PAD
    for name, color in swatches:
        # swatch background
        d2 = ImageDraw.Draw(canvas)
        d2.rounded_rectangle((x, y, x + sw_w, y + sw_h), radius=16, fill=color)
        canvas.paste(favicon, (x + 20, y + (sw_h - 40) // 2), favicon)
        # label
        text_color = TEXT if name in ("Light", "Gray", "Brand") else (230, 230, 230)
        d2.text((x + 76, y + 18), "慢病管家", fill=text_color, font=get_font(18, bold=True))
        d2.text(
            (x + 76, y + 46),
            f"我今天吃了药 · {name}",
            fill=text_color if text_color == TEXT else (180, 180, 180),
            font=get_font(13),
        )
        x += sw_w + gap

    # Section 3: PWA install card
    sec3_header_y = y + 160  # below sec2 swatches
    draw.text((PAD, sec3_header_y), "3. PWA 安装卡片（192px）", fill=TEXT, font=get_font(20, bold=True))
    y = sec3_header_y + 40

    card_x, card_w, card_h = PAD, 560, 110
    card_y = y
    d2 = ImageDraw.Draw(canvas)
    d2.rounded_rectangle((card_x, card_y, card_x + card_w, card_y + card_h), radius=24, fill=(255, 255, 255))
    d2.rectangle((card_x, card_y, card_x + card_w, card_y + card_h), outline=LINE)

    icon192 = Image.open(ICONS / "Icon-192.png").convert("RGBA")
    icon192 = rounded(icon192, 0.224)
    canvas.paste(icon192, (card_x + 22, card_y + (card_h - 66) // 2), icon192)

    d2.text((card_x + 110, card_y + 26), "慢病管家", fill=TEXT, font=get_font(20, bold=True))
    d2.text(
        (card_x + 110, card_y + 58),
        "我今天吃了药 - 精神心理患者吃药打卡",
        fill=MUTED,
        font=get_font(14),
    )
    # install button
    btn_w, btn_h = 90, 38
    btn_x = card_x + card_w - btn_w - 22
    btn_y = card_y + (card_h - btn_h) // 2
    d2.rounded_rectangle((btn_x, btn_y, btn_x + btn_w, btn_y + btn_h), radius=btn_h // 2, fill=(107, 207, 127))
    install_text = "安装"
    iw = text_w(d2, install_text, get_font(15, bold=True))
    d2.text((btn_x + (btn_w - iw) // 2, btn_y + 10), install_text, fill=(255, 255, 255), font=get_font(15, bold=True))

    # Section 4: home tile mock + Android adaptive
    sec4_header_y = card_y + card_h + 60
    draw.text((PAD, sec4_header_y), "4. 手机主屏模拟", fill=TEXT, font=get_font(20, bold=True))
    tile_y = sec4_header_y + 40

    # iOS tile (light)
    tile_size = 96
    tx = PAD
    ty = tile_y
    d2.rounded_rectangle((tx, ty, tx + tile_size, ty + tile_size), radius=22, fill=(238, 240, 245))
    icon96 = rounded(master.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(icon96, (tx + 10, ty + 10), icon96)
    d2.text((tx, ty + tile_size + 10), "iOS home", fill=MUTED, font=get_font(12))

    # Android tile (dark adaptive circle)
    tx2 = tx + tile_size + 60
    d2.rounded_rectangle((tx2, ty, tx2 + tile_size, ty + tile_size), radius=22, fill=(28, 28, 30))
    # circle-masked icon
    icon_circle = Image.new("RGBA", (tile_size - 20, tile_size - 20), (0, 0, 0, 0))
    icon_circle.paste(master.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), (0, 0))
    mask = Image.new("L", (tile_size - 20, tile_size - 20), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, tile_size - 20, tile_size - 20), fill=255)
    icon_circle.putalpha(mask)
    canvas.paste(icon_circle, (tx2 + 10, ty + 10), icon_circle)
    d2.text((tx2, ty + tile_size + 10), "Android adaptive", fill=MUTED, font=get_font(12))

    # Footer
    draw.text(
        (PAD, H - 40),
        "源文件: assets/brand/app_icon_master.png · app_icon_maskable.png    生成脚本: scripts/resize_icons.py",
        fill=MUTED,
        font=get_font(13),
    )

    canvas.save(OUT, "PNG", optimize=True)
    print(f"Saved: {OUT}  ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
