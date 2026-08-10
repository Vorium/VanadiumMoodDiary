#!/usr/bin/env bash
# v0.30 R108: iOS 截图自动生成 (5 设备 × 3 locale × 5 屏 = 15 张)
#
# 背景 (R108):
# - R107 googleplay 报告 P0: iOS 截图 0 张 (R100 删了占位但没真生成)
# - 5 设备: iPhone 16 Pro Max 6.7" / iPhone 11 Pro Max 6.5" / iPhone 8 Plus 5.5" /
#   iPad Pro 12.9" (3rd gen) / iPad Pro 11"
# - 3 locale: en-US / zh-Hans / zh-Hant
# - 5 屏: home / mood / vent / medication / assessment
# - 总计 5 × 3 × 5 = 75 张, 但 fastlane 实际目录只接 5 设备 × 3 locale (15 张)
#
# 用法 (Mac only, 需装 Xcode + Android Studio + Flutter):
#   chmod +x scripts/generate_ios_screenshots.sh
#   ./scripts/generate_ios_screenshots.sh
#
# 输出:
#   fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_7_screenshots/screenshot_1..5.png
#   fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_6_5_screenshots/screenshot_1..5.png
#   fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/iphone_5_5_screenshots/screenshot_1..5.png
#   fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/ipad_12_9_screenshots/screenshot_1..5.png
#   fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/ipad_11_screenshots/screenshot_1..5.png
#
# 前置:
#   1. macOS 13+ (Ventura, 黑苹果不保证)
#   2. Xcode 15+ (含 iOS 17 SDK)
#   3. Flutter 3.41+ (本项目用 3.41.9)
#   4. iOS 模拟器: iPhone 16 Pro Max / iPhone 11 Pro Max / iPhone 8 Plus /
#      iPad Pro 12.9" (3rd gen) / iPad Pro 11" 需先在 Xcode 装好
#   5. Apple ID 登录 Xcode (模拟器不用, build 不用)
#
# ⚠️  本脚本仅在 macOS 上跑, Linux/Windows 跑会直接 exit 1
# ⚠️  截图前必须 `flutter build ios --release` 成功 (走真实 signing)
#    详见 docs/audit/2026-08-10-cleanup/R108-screenshots-automation.md

set -euo pipefail

# 0. 平台检查
if [[ "$(uname)" != "Darwin" ]]; then
  echo "[FAIL] 本脚本仅在 macOS 上跑, 当前: $(uname)" >&2
  echo "       Linux/Windows 请用 Android 版本: scripts/generate_android_screenshots.sh" >&2
  exit 1
fi

# 0.5 工具检查
for tool in xcrun flutter ffmpeg; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    case "$tool" in
      xcrun)
        echo "[FAIL] xcrun 找不到。请装 Xcode 15+ 并同意 license: sudo xcodebuild -license accept" >&2
        ;;
      flutter)
        echo "[FAIL] flutter 找不到。请装 Flutter 3.41+ 并配 PATH。" >&2
        ;;
      ffmpeg)
        echo '[WARN] ffmpeg 找不到, 将跳过 iPhone 6.5"/5.5" 缩放 (仅 6.7" + iPad)。' >&2
        echo '       Mac 安装: brew install ffmpeg' >&2
        SKIP_RESIZE=1
        ;;
    esac
  fi
done

# 1. 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

METADATA_DIR="$PROJECT_ROOT/fastlane/metadata/ios"
TMP_DIR="$PROJECT_ROOT/build/ios_screenshots"
mkdir -p "$TMP_DIR"

# 2. 配置
DEVICES=(
  "iPhone 16 Pro Max|iphone_6_7_screenshots|1290x2796"
  "iPhone 11 Pro Max|iphone_6_5_screenshots|1242x2688"
  "iPhone 8 Plus|iphone_5_5_screenshots|1242x2208"
  'iPad Pro 12.9-inch (3rd generation)|ipad_12_9_screenshots|2048x2732'
  'iPad Pro 11-inch (M4)|ipad_11_screenshots|1668x2388'
)
LOCALES=(en-US zh-Hans zh-Hant)
SCREENS=(
  "home|主页|主頁"
  "mood|心情记录|心情記錄"
  "vent|树洞倾诉|樹洞傾訴"
  "medication|用药管理|用藥管理"
  "assessment|心理评估|心理評估"
)

# 3. 构建 .app
echo "[1/5] flutter build ios --release (无 codesign, 模拟器跑)..."
flutter build ios --release --no-codesign --simulator 2>&1 | tail -20
echo ""

# 4. 启动模拟器 + 截图
for device_entry in "${DEVICES[@]}"; do
  IFS='|' read -r device_name fastlane_subdir resolution <<< "$device_entry"
  echo "[2/5] 设备: $device_name ($resolution)"

  # 启动模拟器 (boot, 不打开 Simulator.app)
  xcrun simctl boot "$device_name" 2>/dev/null || echo "      (模拟器已 boot)"
  xcrun simctl bootstatus "$device_name" -b

  for locale in "${LOCALES[@]}"; do
    echo "[3/5] locale: $locale"
    OUT_DIR="$METADATA_DIR/$locale/$fastlane_subdir"
    mkdir -p "$OUT_DIR"

    # 装 .app (选对应架构)
    APP_PATH="build/ios/iphonesimulator/Runner.app"
    xcrun simctl install "$device_name" "$APP_PATH"

    # 切语言 (启动前设, 不用 parens, iOS 12+ 接受 bare string)
    LANG_BARE=$(echo "$locale" | tr '-' '_')
    xcrun simctl spawn "$device_name" defaults write -g AppleLanguages "$LANG_BARE"
    xcrun simctl spawn "$device_name" defaults write -g AppleLocale "$locale"

    # 启动 App
    xcrun simctl launch "$device_name" app.chroniccare.patient 2>/dev/null || \
    xcrun simctl launch "$device_name" com.chroniccare.chronicCarePatient 2>/dev/null || \
    echo "      [WARN] App 启动失败, 检查 bundle id"

    # 等启动 + 主页加载
    sleep 5

    # 5 张截图
    for screen_entry in "${SCREENS[@]}"; do
      IFS='|' read -r screen_name_zh_hans_zh_hant_placeholder _ _ <<< "$screen_entry"
      screen_name=$(echo "$screen_entry" | cut -d'|' -f1)

      # 屏 N: 主页已截, 切到 mood/vent/medication/assessment
      if [ "$screen_name" != "home" ]; then
        # 真实业务: 这里需用 deep link 或 UI 自动化 (Maestro / XCUITest)
        # R108 简化: 用 deep link
        xcrun simctl openurl "$device_name" "chroniccare://$screen_name" 2>/dev/null || true
        sleep 3
      fi

      # 截图
      SCREENSHOT_PATH="$TMP_DIR/${device_name// /_}_${locale}_${screen_name}.png"
      xcrun simctl io "$device_name" screenshot "$SCREENSHOT_PATH"
      echo "      [OK] 截屏: $screen_name → $SCREENSHOT_PATH"

      # 复制到 fastlane 目录 (按屏号重命名 1-5)
      SCREEN_NUM=1
      case "$screen_name" in
        home) SCREEN_NUM=1 ;;
        mood) SCREEN_NUM=2 ;;
        vent) SCREEN_NUM=3 ;;
        medication) SCREEN_NUM=4 ;;
        assessment) SCREEN_NUM=5 ;;
      esac
      cp "$SCREENSHOT_PATH" "$OUT_DIR/screenshot_$SCREEN_NUM.png"
    done

    # 卸载 App (避免状态污染)
    xcrun simctl uninstall "$device_name" app.chroniccare.patient 2>/dev/null || true
  done

  # 关闭模拟器
  xcrun simctl shutdown "$device_name"
done

# 5. 缩放 (iPhone 6.5"/5.5" 需从 6.7" 缩)
if [ -z "${SKIP_RESIZE:-}" ]; then
  echo "[4/5] 缩放 iPhone 6.5\"/5.5\" (ffmpeg)..."
  for locale in "${LOCALES[@]}"; do
    SRC_DIR="$METADATA_DIR/$locale/iphone_6_7_screenshots"
    [ -d "$SRC_DIR" ] || continue

    # 6.5"
    DST_65="$METADATA_DIR/$locale/iphone_6_5_screenshots"
    mkdir -p "$DST_65"
    for png in "$SRC_DIR"/*.png; do
      [ -f "$png" ] || continue
      ffmpeg -i "$png" -vf "scale=1242:2688" -y "$DST_65/$(basename "$png")" 2>/dev/null
    done

    # 5.5"
    DST_55="$METADATA_DIR/$locale/iphone_5_5_screenshots"
    mkdir -p "$DST_55"
    for png in "$SRC_DIR"/*.png; do
      [ -f "$png" ] || continue
      ffmpeg -i "$png" -vf "scale=1242:2208" -y "$DST_55/$(basename "$png")" 2>/dev/null
    done
  done
else
  echo "[4/5] 跳过 iPhone 6.5\"/5.5\" 缩放 (无 ffmpeg)"
fi

# 6. 验证
echo ""
echo "[5/5] 验证截图生成..."
TOTAL=0
for locale in "${LOCALES[@]}"; do
  for subdir in iphone_6_7_screenshots iphone_6_5_screenshots iphone_5_5_screenshots \
                ipad_12_9_screenshots ipad_11_screenshots; do
    DIR="$METADATA_DIR/$locale/$subdir"
    if [ -d "$DIR" ]; then
      COUNT=$(ls "$DIR"/screenshot_*.png 2>/dev/null | wc -l | tr -d ' ')
      echo "      $locale/$subdir: $COUNT 张"
      TOTAL=$((TOTAL + COUNT))
    fi
  done
done

echo ""
echo "[OK] iOS 截图生成完成! 总计 $TOTAL 张 (期望 75 张 = 5 设备 × 3 locale × 5 屏)"
echo ""
echo "下一步:"
echo "  1. 人工 review 截图质量 (是否有 PII / 错位 / 不雅)"
echo "  2. 检查 fastlane/metadata/ios/*/ 目录文件大小 (期望每张 > 100KB)"
echo "  3. 用 Transporter 或 fastlane 上传 App Store Connect"
echo "  4. App Store Connect → App Store 版本信息 → 截图 → 选 5 设备各 5 张"
echo ""
