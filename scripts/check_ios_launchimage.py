#!/usr/bin/env python3
# v1.1.0 R117 (综合审视 P0-2): iOS LaunchImage 守门员
#
# AppStore 必须 3 尺寸:
# - 1024 × 1024 (iPad Pro 12.9" portrait, Marketing)
# - 1242 × 2688 (iPhone XS Max / 11 Pro Max)
# - 2688 × 1242 (iPhone XS Max / 11 Pro Max landscape, optional)
#
# 用法: python scripts/check_ios_launchimage.py
# Exit 0: 全过 / Exit 1: 缺张

import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
LAUNCH_DIR = ROOT / "ios" / "Runner" / "Assets.xcassets" / "LaunchImage.imageset"

REQUIRED = [
    ("LaunchImage_1024x1024.png", 1024, 1024),
    ("LaunchImage_1242x2688.png", 1242, 2688),
    ("LaunchImage_2688x1242.png", 2688, 1242),
]


def main():
    if not LAUNCH_DIR.exists():
        print(f"[FAIL] iOS LaunchImage 目录不存在: {LAUNCH_DIR}")
        print("       R117 综合审视 P0-2 阻塞: 等设计师资产 (LaunchImage.storyboard 也可)")
        return 1

    errors = []
    for name, w, h in REQUIRED:
        p = LAUNCH_DIR / name
        if not p.exists():
            errors.append(f"  缺: {name} ({w}×{h})")
        else:
            sz = p.stat().st_size
            if sz < 1000:
                errors.append(f"  过小 ({sz}B, 当前 68B 是 placeholder): {name}")

    if errors:
        print(f"[FAIL] iOS LaunchImage 缺失或不合规 ({len(errors)} 项):")
        for e in errors:
            print(e)
        return 1

    print(f"[OK] iOS LaunchImage: 3 尺寸齐全 (1024×1024 / 1242×2688 / 2688×1242)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
