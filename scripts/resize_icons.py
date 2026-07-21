"""Resize the generated brand icons to required sizes.

Source: assets/brand/app_icon_master.png     (1024x1024, square iOS/Android; latest version)
        assets/brand/app_icon_maskable.png   (1024x1024, Android adaptive safe zone; latest version)

历史版本: app_icon_master_v1..v5.png / app_icon_maskable_v1..v5.png 保留作为设计稿存档
最新版本同步流程: 把新生成的 v5.png 覆盖到 master.png / maskable.png，再跑本脚本重新派生 web/icons

Outputs:
  web/favicon.png                     — 32x32 (browser tab + PWA default)
  web/icons/Icon-192.png              — 192x192 (PWA)
  web/icons/Icon-512.png              — 512x512 (PWA)
  web/icons/Icon-maskable-192.png     — 192x192 (PWA maskable)
  web/icons/Icon-maskable-512.png     — 512x512 (PWA maskable)

Resampling: LANCZOS (best for shrinking sharp edges + flat areas).
"""
from pathlib import Path
from PIL import Image

ROOT = Path("D:/Batch/chroniccare")
BRAND = ROOT / "assets" / "brand"
WEB = ROOT / "web"
ICONS = WEB / "icons"


def resize(src: Path, dst: Path, size: int) -> None:
    img = Image.open(src).convert("RGBA")
    img = img.resize((size, size), Image.Resampling.LANCZOS)
    dst.parent.mkdir(parents=True, exist_ok=True)
    img.save(dst, "PNG", optimize=True)
    print(f"  -> {dst.relative_to(ROOT)}  ({size}x{size}, {dst.stat().st_size:,} bytes)")


def main() -> None:
    print("Master (iOS/Android) ->")
    master = BRAND / "app_icon_master.png"
    resize(master, WEB / "favicon.png", 32)
    resize(master, ICONS / "Icon-192.png", 192)
    resize(master, ICONS / "Icon-512.png", 512)

    print("Maskable (Android adaptive) ->")
    maskable = BRAND / "app_icon_maskable.png"
    resize(maskable, ICONS / "Icon-maskable-192.png", 192)
    resize(maskable, ICONS / "Icon-maskable-512.png", 512)


if __name__ == "__main__":
    main()
