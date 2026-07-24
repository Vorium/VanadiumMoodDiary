"""Generate v3 vs v4 comparison preview image.

Layout (1800x1900):
  Header
  Section 1: v3 vs v4 direct comparison (256px)
  Section 2: master v4 vs maskable v4 (composition alignment check)
  Section 3: v4 5 polish details (additive, all unseen)
  Section 4: v4 multi-size ladder
  Section 5: v4 background swatches
  Section 6: v4 PWA + home tile
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("D:/Batch/chroniccare")
BRAND = ROOT / "assets" / "brand"
WEB = ROOT / "web"
ICONS = WEB / "icons"
OUT = BRAND / "icon_preview_v4.png"

W, H = 1800, 1900
PAD = 60
BG = (250, 250, 250)
TEXT = (26, 26, 26)
MUTED = (102, 102, 102)
LINE = (224, 224, 224)
GREEN = (107, 207, 127)
GREEN_DARK = (79, 176, 95)


def get_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
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


def rounded(img: Image.Image, radius_pct: float) -> Image.Image:
    w, h = img.size
    r = int(min(w, h) * radius_pct)
    mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, w, h), radius=r, fill=255)
    out = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    return out


def text_w(draw, text: str, font) -> int:
    bbox = draw.textbbox((0, 0), text, font=font)
    return bbox[2] - bbox[0]


def section_header(draw, y: int, num: str, title: str) -> int:
    draw.text((PAD, y), num, fill=GREEN_DARK, font=get_font(20, bold=True))
    tw = text_w(draw, num, get_font(20, bold=True))
    draw.text((PAD + tw + 12, y), title, fill=TEXT, font=get_font(20, bold=True))
    return y + 40


def main() -> None:
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    # Header
    draw.text((PAD, PAD), "慢病管家 · App 图标 v3 vs v4 (9.5/10)", fill=TEXT, font=get_font(32, bold=True))
    draw.text(
        (PAD, PAD + 44),
        "v4 在 v3 基础上加 5 个 unseen details：物理感 + 叙事性 + 整体深度",
        fill=MUTED,
        font=get_font(16),
    )

    # Section 1: v3 vs v4 direct comparison
    y = section_header(draw, PAD + 100, "1.", "v3 vs v4 直接对比（256px iOS rounded）")
    v3 = Image.open(BRAND / "app_icon_master_v3.png").convert("RGBA")
    v4 = Image.open(BRAND / "app_icon_master_v4.png").convert("RGBA")
    v3_256 = rounded(v3.resize((256, 256), Image.Resampling.LANCZOS), 0.224)
    v4_256 = rounded(v4.resize((256, 256), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(v3_256, (PAD, y), v3_256)
    canvas.paste(v4_256, (PAD + 360, y), v4_256)
    draw.text((PAD, y + 270), "v3  ·  平面感 (2D 的看着像贴纸)", fill=MUTED, font=get_font(14))
    draw.text((PAD + 360, y + 270), "v4  ·  物理感 (3D 的看着像实物)", fill=GREEN_DARK, font=get_font(14, bold=True))

    # Section 2: master v4 vs maskable v4 (alignment)
    y = section_header(draw, y + 320, "2.", "master v4 vs maskable v4（几何对齐校验）")
    maskable_v3 = Image.open(BRAND / "app_icon_maskable_v3.png").convert("RGBA")
    maskable_v4 = Image.open(BRAND / "app_icon_maskable_v4.png").convert("RGBA")
    m_v3 = rounded(maskable_v3.resize((220, 220), Image.Resampling.LANCZOS), 0.224)
    m_v4 = rounded(maskable_v4.resize((220, 220), Image.Resampling.LANCZOS), 0.224)
    master_v4_220 = rounded(v4.resize((220, 220), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(master_v4_220, (PAD, y), master_v4_220)
    canvas.paste(m_v4, (PAD + 280, y), m_v4)
    draw.text((PAD, y + 234), "master v4", fill=MUTED, font=get_font(13))
    draw.text((PAD + 280, y + 234), "maskable v4（已对齐）", fill=GREEN_DARK, font=get_font(13, bold=True))

    # Section 3: 5 unseen details
    y = y + 280
    y = section_header(draw, y, "3.", "5 个 unseen details（v4 加的，32px 下全消失）")
    details = [
        ("[1] Pill micro gradient", "white #FFFFFF -> #F2F4F2 (3%)", "top-bright/bottom-dark physical light"),
        ("[2] Top rim light", "1px white @ 90% on top edge", "light from above, plastic/sugar coat feel"),
        ("[3] Stem from seam", "stem base AT pill midpoint (seam)", "narrative: pill 'opens', plant grows out"),
        ("[4] Leaf light/shadow + rim", "#5BBE6F -> #3D9A4B + 7AE08A @ 60%", "directional sunlight on the leaf surface"),
        ("[5] Background radial gradient", "center #82D892 -> edges #5BBE6F (8%)", "eye focuses center, pill is the focus"),
    ]
    col_w = (W - 2 * PAD - 40) // 2
    for i, (k, before, after) in enumerate(details):
        col = i % 2
        row = i // 2
        cx = PAD + col * (col_w + 40)
        cy = y + row * 100
        ImageDraw.Draw(canvas).rounded_rectangle(
            (cx, cy, cx + col_w, cy + 86), radius=12, fill=(255, 255, 255), outline=LINE
        )
        draw.text((cx + 16, cy + 12), k, fill=GREEN_DARK, font=get_font(15, bold=True))
        draw.text((cx + 16, cy + 36), f"改动: {before}", fill=MUTED, font=get_font(13))
        draw.text((cx + 16, cy + 58), f"效果: {after}", fill=TEXT, font=get_font(13))

    # Section 4: v4 multi-size ladder
    y = y + 100 * 3 + 30
    y = section_header(draw, y, "4.", "v4 全尺寸（24 / 32 / 40 / 64 / 80 / 128 / 192）")
    sizes = [192, 128, 80, 64, 40, 32, 24]
    x = PAD
    for s in sizes:
        icon = rounded(v4.resize((s, s), Image.Resampling.LANCZOS), 0.224)
        canvas.paste(icon, (x, y), icon)
        label = f"{s}px"
        lw = text_w(draw, label, get_font(12))
        draw.text((x + (s - lw) // 2, y + s + 8), label, fill=MUTED, font=get_font(12))
        x += s + 36

    # Section 5: v4 background swatches
    y = y + 250
    y = section_header(draw, y, "5.", "v4 不同背景上的识别性（40px favicon）")
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

    # Section 6: PWA + home tile
    y = y + 160
    draw.text((PAD, y), "6.", fill=GREEN_DARK, font=get_font(20, bold=True))
    tw = text_w(draw, "6.", get_font(20, bold=True))
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
    icon_t = rounded(v4.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(icon_t, (tx + 10, ty + 10), icon_t)
    d2.text((tx, ty + tile_size + 10), "iOS home", fill=MUTED, font=get_font(12))

    # Android adaptive
    tx2 = tx + tile_size + 40
    d2.rounded_rectangle((tx2, ty, tx2 + tile_size, ty + tile_size), radius=22, fill=(28, 28, 30))
    icon_circle = Image.new("RGBA", (tile_size - 20, tile_size - 20), (0, 0, 0, 0))
    icon_circle.paste(v4.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), (0, 0))
    mask = Image.new("L", (tile_size - 20, tile_size - 20), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, tile_size - 20, tile_size - 20), fill=255)
    icon_circle.putalpha(mask)
    canvas.paste(icon_circle, (tx2 + 10, ty + 10), icon_circle)
    d2.text((tx2, ty + tile_size + 10), "Android adaptive", fill=MUTED, font=get_font(12))

    # Footer
    draw.text(
        (PAD, H - 40),
        "v4 源: assets/brand/app_icon_master_v4.png · app_icon_maskable_v4.png    脚本: scripts/resize_icons.py + make_icon_preview_v4.py",
        fill=MUTED,
        font=get_font(13),
    )

    canvas.save(OUT, "PNG", optimize=True)
    print(f"Saved: {OUT}  ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
