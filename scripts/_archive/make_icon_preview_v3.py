"""Generate v2 vs v3 comparison preview image.

Layout (1800x1500):
  Header
  Section 1: v2 vs v3 direct comparison (256px)
  Section 2: master v3 vs maskable v3 (composition alignment check)
  Section 3: v3 changelog (3 fixes from v2)
  Section 4: v3 multi-size ladder
  Section 5: v3 background swatches
  Section 6: v3 PWA + home tile
"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path("D:/Batch/chroniccare")
BRAND = ROOT / "assets" / "brand"
WEB = ROOT / "web"
ICONS = WEB / "icons"
OUT = BRAND / "icon_preview_v3.png"

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
    draw.text((PAD, PAD), "慢病管家 · App 图标 v2 vs v3", fill=TEXT, font=get_font(32, bold=True))
    draw.text(
        (PAD, PAD + 44),
        "v3 修 3 个最后的 9→10 分问题：构图、叶子立体感、master/maskable 几何对齐",
        fill=MUTED,
        font=get_font(16),
    )

    # Section 1: v2 vs v3 direct comparison
    y = section_header(draw, PAD + 100, "1.", "v2 vs v3 直接对比（256px iOS rounded）")
    v2 = Image.open(BRAND / "app_icon_master_v2.png").convert("RGBA")
    v3 = Image.open(BRAND / "app_icon_master_v3.png").convert("RGBA")
    v2_256 = rounded(v2.resize((256, 256), Image.Resampling.LANCZOS), 0.224)
    v3_256 = rounded(v3.resize((256, 256), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(v2_256, (PAD, y), v2_256)
    canvas.paste(v3_256, (PAD + 360, y), v3_256)
    draw.text((PAD, y + 270), "v2  ·  右倾构图 + 纯色叶子", fill=MUTED, font=get_font(14))
    draw.text((PAD + 360, y + 270), "v3  ·  居中构图 + 叶子光暗渐变", fill=GREEN_DARK, font=get_font(14, bold=True))

    # Section 2: master v3 vs maskable v3 (geometry alignment)
    y = section_header(draw, y + 320, "2.", "master v3 vs maskable v3（几何对齐校验）")
    maskable_v2 = Image.open(BRAND / "app_icon_maskable_v2.png").convert("RGBA")
    maskable_v3 = Image.open(BRAND / "app_icon_maskable_v3.png").convert("RGBA")
    m_v2 = rounded(maskable_v2.resize((220, 220), Image.Resampling.LANCZOS), 0.224)
    m_v3 = rounded(maskable_v3.resize((220, 220), Image.Resampling.LANCZOS), 0.224)
    master_v3_220 = rounded(v3.resize((220, 220), Image.Resampling.LANCZOS), 0.224)

    # v2 master + v2 maskable (not aligned)
    canvas.paste(master_v3_220, (PAD, y), master_v3_220)
    canvas.paste(m_v2, (PAD + 280, y), m_v2)
    canvas.paste(m_v3, (PAD + 560, y), m_v3)

    # labels
    draw.text((PAD, y + 234), "master v3", fill=MUTED, font=get_font(13))
    draw.text((PAD + 280, y + 234), "maskable v2（位置不一致）", fill=MUTED, font=get_font(13))
    draw.text((PAD + 560, y + 234), "maskable v3（已对齐）", fill=GREEN_DARK, font=get_font(13, bold=True))

    # Section 3: changelog
    y = y + 280
    y = section_header(draw, y, "3.", "3 条具体改动（v2 → v3）")
    changes = [
        ("构图", "胶囊水平居中 + 叶子在右上 → 视觉重心明显偏右", "胶囊左移到 42% + 叶子在 65% → 重心真正居中"),
        ("叶子立体感", "纯色 #4FB05F（平面感）", "光暗渐变 #5BBE6F → #3D9A4B，Linear/Notion 风格的 1px 立体感"),
        ("master/maskable 对齐", "叶子在两版图标的相对位置不一样 → Android 跟 Web 看着像两个设计", "两版 prompt 锁死同一组相对坐标，v3 视觉完全一致"),
    ]
    col_w = (W - 2 * PAD - 40) // 2
    for i, (k, before, after) in enumerate(changes):
        col = i % 2
        row = i // 2
        cx = PAD + col * (col_w + 40)
        cy = y + row * 100
        ImageDraw.Draw(canvas).rounded_rectangle(
            (cx, cy, cx + col_w, cy + 86), radius=12, fill=(255, 255, 255), outline=LINE
        )
        draw.text((cx + 16, cy + 12), f"#{i+1}  {k}", fill=GREEN_DARK, font=get_font(15, bold=True))
        draw.text((cx + 16, cy + 36), f"before: {before}", fill=MUTED, font=get_font(13))
        draw.text((cx + 16, cy + 58), f"after:  {after}", fill=TEXT, font=get_font(13))

    # Section 4: v3 multi-size ladder
    y = y + 100 * 2 + 20
    y = section_header(draw, y, "4.", "v3 全尺寸（24 / 32 / 40 / 64 / 80 / 128 / 192）")
    sizes = [192, 128, 80, 64, 40, 32, 24]
    x = PAD
    for s in sizes:
        icon = rounded(v3.resize((s, s), Image.Resampling.LANCZOS), 0.224)
        canvas.paste(icon, (x, y), icon)
        label = f"{s}px"
        lw = text_w(draw, label, get_font(12))
        draw.text((x + (s - lw) // 2, y + s + 8), label, fill=MUTED, font=get_font(12))
        x += s + 36

    # Section 5: v3 background swatches
    y = y + 250
    y = section_header(draw, y, "5.", "v3 不同背景上的识别性（40px favicon）")
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
    icon_t = rounded(v3.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), 0.224)
    canvas.paste(icon_t, (tx + 10, ty + 10), icon_t)
    d2.text((tx, ty + tile_size + 10), "iOS home", fill=MUTED, font=get_font(12))

    # Android adaptive
    tx2 = tx + tile_size + 40
    d2.rounded_rectangle((tx2, ty, tx2 + tile_size, ty + tile_size), radius=22, fill=(28, 28, 30))
    icon_circle = Image.new("RGBA", (tile_size - 20, tile_size - 20), (0, 0, 0, 0))
    icon_circle.paste(v3.resize((tile_size - 20, tile_size - 20), Image.Resampling.LANCZOS), (0, 0))
    mask = Image.new("L", (tile_size - 20, tile_size - 20), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, tile_size - 20, tile_size - 20), fill=255)
    icon_circle.putalpha(mask)
    canvas.paste(icon_circle, (tx2 + 10, ty + 10), icon_circle)
    d2.text((tx2, ty + tile_size + 10), "Android adaptive", fill=MUTED, font=get_font(12))

    # Footer
    draw.text(
        (PAD, H - 40),
        "v3 源: assets/brand/app_icon_master_v3.png · app_icon_maskable_v3.png    脚本: scripts/resize_icons.py + make_icon_preview_v3.py",
        fill=MUTED,
        font=get_font(13),
    )

    canvas.save(OUT, "PNG", optimize=True)
    print(f"Saved: {OUT}  ({OUT.stat().st_size:,} bytes)")


if __name__ == "__main__":
    main()
