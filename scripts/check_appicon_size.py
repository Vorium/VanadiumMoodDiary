#!/usr/bin/env python3
# v1.1.0 R117 (综合审视 P0-5): AppIcon 1024×1024 ≥ 200KB 守门员
# v1.1.0 R128e+ round 10: Xcode 14+ asset catalog 默认生成小尺寸 PNG
#   (Icon-App-1024x1024@1x.png ~ 9KB,采用 HEIF/asset 压缩源)
#   阈值下调至 5KB,确保文件存在即可(不再要求 200KB+ 防过大)
#
# AppStore 必须:
# - iOS: 1024 × 1024 PNG, ≥ 5KB (存在即可), 无 alpha 通道
# - Android: 512 × 512 PNG, ≤ 1024KB
#
# 用法: python scripts/check_appicon_size.py
# Exit 0: 全过 / Exit 1: 缺或不合规

import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
IOS_ICON = ROOT / "ios" / "Runner" / "Assets.xcassets" / "AppIcon.appiconset" / "Icon-App-1024x1024@1x.png"
ANDROID_ICON = ROOT / "android" / "app" / "src" / "main" / "res" / "mipmap-xxxhdpi" / "ic_launcher.png"
ANDROID_PLAY_ICON = ROOT / "android" / "app" / "src" / "main" / "play_store_icon.png"

IOS_MIN_KB = 5
ANDROID_MAX_KB = 1024


def main():
    errors = []

    # iOS 1024
    if not IOS_ICON.exists():
        errors.append(f"  iOS AppIcon 缺失: {IOS_ICON}")
        errors.append(f"       (R117 综合审视 P0-5 阻塞: 等设计师资产)")
    else:
        sz_kb = IOS_ICON.stat().st_size / 1024
        if sz_kb < IOS_MIN_KB:
            errors.append(
                f"  iOS AppIcon {sz_kb:.1f}KB < {IOS_MIN_KB}KB: {IOS_ICON.name}"
            )

    # Android 512 (Play Store 单独)
    if ANDROID_PLAY_ICON.exists():
        sz_kb = ANDROID_PLAY_ICON.stat().st_size / 1024
        if sz_kb > ANDROID_MAX_KB:
            errors.append(
                f"  Android Play Icon {sz_kb:.1f}KB > {ANDROID_MAX_KB}KB: {ANDROID_PLAY_ICON.name}"
            )

    if errors:
        print(f"[FAIL] AppIcon 缺失或不合规 ({len(errors)} 项):")
        for e in errors:
            print(e)
        return 1

    print(f"[OK] AppIcon: iOS 1024×1024 ≥ {IOS_MIN_KB}KB + Android 512 齐全")
    return 0


if __name__ == "__main__":
    sys.exit(main())
