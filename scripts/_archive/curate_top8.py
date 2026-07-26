"""Curate the top 8 candidates from 100 generated variations."""
import os
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

VARIATIONS = Path("D:/Batch/chroniccare/assets/brand/variations")
OUT = VARIATIONS / "top_8_curated.png"

candidates = [
    ("03_bottle_i",  "leaf-shaped bottle",         "surreal + brand-cohesive: the bottle IS a leaf"),
    ("10_wild_f",    "pebble + sprout",            "poetic: life finds a way through cracks"),
    ("05_sunrise_c", "sun + leaf-shadow pill",     "concept cleverness: shadow becomes the pill"),
    ("09_seed_d",    "two-leaf sprout",            "strong, brandable, minimal -- could be 9.8"),
    ("10_wild_e",    "spiral unfurling",           "narrative: growth as movement"),
    ("08_clock_e",   "leaf-shaped clock face",     "visual pun: time IS a leaf"),
    ("10_wild_i",    "feather + leaf",             "poetic: lightness, gentle flight"),
    ("05_sunrise_g", "sunrise + pill on ground",   "poetic: pill watching the dawn"),
]

CELL = 320
COLS = 2
ROWS = (len(candidates) + COLS - 1) // COLS
PAD = 24
LABEL_H = 80
GUTTER = 30

W = COLS * CELL + (COLS + 1) * PAD
H = ROWS * (CELL + LABEL_H + GUTTER) + (ROWS + 1) * PAD + 100

canvas = Image.new("RGB", (W, H), (250, 250, 250))
draw = ImageDraw.Draw(canvas)


def get_font(size, bold=False):
    paths = [
        ("C:/Windows/Fonts/msyhbd.ttc", 0) if bold else ("C:/Windows/Fonts/msyh.ttc", 0),
        ("C:/Windows/Fonts/simhei.ttf", 0),
    ]
    for p, i in paths:
        if Path(p).exists():
            try:
                return ImageFont.truetype(p, size, index=i)
            except Exception:
                pass
    return ImageFont.load_default()


font_h = get_font(28, bold=True)
font_sub = get_font(14)
font_t = get_font(16, bold=True)
font_d = get_font(13)

draw.text((PAD, 24), "Top 8 candidates (9.5 - 9.8 range)", fill=(26, 26, 26), font=font_h)
draw.text(
    (PAD, 60),
    "Picked the ones with 'could not have imagined it differently' quality from 100 variations",
    fill=(102, 102, 102),
    font=font_sub,
)

for i, (key, title, why) in enumerate(candidates):
    row = i // COLS
    col = i % COLS
    x = PAD + col * (CELL + PAD)
    y = 100 + PAD + row * (CELL + LABEL_H + GUTTER)

    src = VARIATIONS / f"{key}.png"
    if not src.exists():
        continue
    img = Image.open(src).convert("RGBA").resize((CELL, CELL), Image.Resampling.LANCZOS)
    mask = Image.new("L", (CELL, CELL), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, CELL, CELL), radius=int(CELL * 0.18), fill=255)
    rounded = Image.new("RGBA", (CELL, CELL), (0, 0, 0, 0))
    rounded.paste(img, (0, 0), mask)
    canvas.paste(rounded, (x, y), rounded)

    draw.text((x, y + CELL + 8), f"#{i+1}  {title}", fill=(79, 176, 95), font=font_t)
    draw.text((x, y + CELL + 34), why, fill=(102, 102, 102), font=font_d)

canvas.save(OUT, "PNG", optimize=True)
print(f"Saved: {OUT} ({OUT.stat().st_size:,} bytes)")
