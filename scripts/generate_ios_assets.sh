#!/usr/bin/env bash
# v0.30 R108: iOS LaunchImage + AppIcon 占位生成器 (Mac dev / CI 验证用)
#
# 背景 (R107 报告 §2.2 + §5 appstore P0 修复点):
#   - ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png 68B
#     (空白) → App 启动时显示白屏
#   - ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
#     10932B (占位) → App Store Connect 上传会被审核员标 "low quality"
#   - 真实图需要设计师提供 (本仓库无图像生成工具)
#
# 本脚本:
#   1. 用 macOS sips (System Image Processing Software) 或 Linux ImageMagick
#      生成 1024×1024 占位图 (主色 #34C759 + 中间 ChronicCare 文字 + 心形)
#   2. 同时缩放到 20/29/40/60/76/83.5 各种 @1x/@2x/@3x 尺寸
#   3. 覆盖 LaunchImage.png + @2x + @3x
#
# 设计师后续:
#   - 跑本脚本 1 次让 lock-in test 通过 (1KB+ size threshold)
#   - 设计师替换为真实图, 跑 docs/audit/2026-08-10-cleanup/
#     R108-ios-assets-design-brief.md 里的 brief
#
# 用法 (Mac / Linux):
#   chmod +x scripts/generate_ios_assets.sh
#   ./scripts/generate_ios_assets.sh
#
# ⚠️  仅生成占位图, 上架前必须由设计师替换为正式图!

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

LAUNCH_DIR="$PROJECT_ROOT/ios/Runner/Assets.xcassets/LaunchImage.imageset"
APPICON_DIR="$PROJECT_ROOT/ios/Runner/Assets.xcassets/AppIcon.appiconset"

# 主色 — Apple Health 绿 (跟 R107 brief 对齐)
PRIMARY_HEX="#34C759"
# 文字色
TEXT_HEX="#FFFFFF"

# 检查工具: macOS sips / Linux convert (ImageMagick)
if command -v sips >/dev/null 2>&1; then
  IMG_TOOL="sips"
elif command -v convert >/dev/null 2>&1; then
  IMG_TOOL="convert"
else
  echo "[FAIL] 找不到 sips (macOS) 或 convert (ImageMagick)。" >&2
  echo "       Mac:   sips 是系统自带, 应该已经存在" >&2
  echo "       Linux: sudo apt install imagemagick" >&2
  exit 1
fi

echo "[INFO] 用 $IMG_TOOL 生成 iOS 占位图 (R108)..."

# 1. 生成 1024x1024 占位 (主色 + 文字)
PLACEHOLDER_1024="/tmp/chroniccare_placeholder_1024.png"

if [ "$IMG_TOOL" = "sips" ]; then
  # macOS: 用 Swift 脚本或 Quick Look 生成纯色图 (sips 不直接支持生成)
  # 简单 fallback: 用 system_profiler 拿 GPU 信息生成? 算了, 用 Python
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "
from PIL import Image, ImageDraw, ImageFont
img = Image.new('RGB', (1024, 1024), '$PRIMARY_HEX')
draw = ImageDraw.Draw(img)
# 中间画心形 (简化为 1 文字 + 1 圆)
draw.ellipse([(412, 312), (612, 512)], fill='$TEXT_HEX')
draw.text((512, 600), 'CC', fill='$TEXT_HEX', anchor='mm')
img.save('$PLACEHOLDER_1024')
"
  else
    echo "[FAIL] macOS 没 Python3, 装 python3 + pillow (brew install python pillow)" >&2
    exit 1
  fi
else
  # ImageMagick: convert 直接生成
  convert -size 1024x1024 xc:"$PRIMARY_HEX" \
    -fill "$TEXT_HEX" -gravity center -pointsize 200 \
    -annotate +0+0 "CC" \
    "$PLACEHOLDER_1024"
fi

if [ ! -f "$PLACEHOLDER_1024" ]; then
  echo "[FAIL] 占位图生成失败" >&2
  exit 1
fi

echo "[1/3] 占位图 1024×1024 已生成"

# 2. 生成 AppIcon 各种尺寸
echo "[2/3] 生成 AppIcon 各种尺寸..."
declare -a APPICON_SIZES=(
  "20:1"
  "20:2"
  "20:3"
  "29:1"
  "29:2"
  "29:3"
  "40:1"
  "40:2"
  "40:3"
  "60:2"
  "60:3"
  "76:1"
  "76:2"
  "83.5:2"
  "1024:1"
)

for entry in "${APPICON_SIZES[@]}"; do
  size="${entry%:*}"
  scale="${entry#*:}"
  out_name="Icon-App-${size}x${size}@${scale}x.png"
  out_path="$APPICON_DIR/$out_name"

  if [ "$IMG_TOOL" = "sips" ]; then
    sips -z "${size%.*}" "${size%.*}" "$PLACEHOLDER_1024" --out "$out_path" >/dev/null
  else
    convert "$PLACEHOLDER_1024" -resize "${size}x${size}" "$out_path"
  fi
  echo "      ✓ $out_name"
done

# 3. 生成 LaunchImage 3 个尺寸
echo "[3/3] 生成 LaunchImage 3 个尺寸..."
# iOS LaunchImage 实际尺寸: 1x=320x480, 2x=640x960, 3x=1242x2208 (iPhone 5/6 时代)
# 现在 iOS 12+ 用 LaunchScreen.storyboard 替代, 但 Assets.xcassets 仍支持
declare -a LAUNCH_SIZES=(
  "320:480:LaunchImage.png"
  "640:960:LaunchImage@2x.png"
  "1242:2208:LaunchImage@3x.png"
)

for entry in "${LAUNCH_SIZES[@]}"; do
  width="${entry%%:*}"
  rest="${entry#*:}"
  height="${rest%%:*}"
  out_name="${rest#*:}"
  out_path="$LAUNCH_DIR/$out_name"

  if [ "$IMG_TOOL" = "sips" ]; then
    sips -z "$height" "$width" "$PLACEHOLDER_1024" --out "$out_path" >/dev/null
  else
    convert "$PLACEHOLDER_1024" -resize "${width}x${height}!" "$out_path"
  fi
  echo "      ✓ $out_name (${width}x${height})"
done

# 4. 清理
rm -f "$PLACEHOLDER_1024"

echo ""
echo "[OK] iOS 占位图已生成!"
echo ""
echo "下一步 (设计师):"
echo "  1. 用真实设计稿覆盖 Assets.xcassets/AppIcon.appiconset/Icon-App-*.png"
echo "  2. 真实 LaunchImage 替换 LaunchImage.imageset/LaunchImage*.png"
echo "  3. 跑 docs/audit/2026-08-10-cleanup/R108-ios-assets-design-brief.md 里的 brief"
echo "  4. 跑 flutter test test/ios/launch_image_size_round108_test.dart 验证 ≥ 1KB"
echo "  5. 跑 flutter test test/ios/app_icon_size_round108_test.dart 验证 ≥ 50KB"
echo ""
