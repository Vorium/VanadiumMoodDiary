#!/usr/bin/env bash
# v0.30 R108: Android 截图自动生成 (4 主流程 + 7"/10" 平板 × 2 locale = 8-12 张)
#
# 背景 (R108):
# - R107 googleplay 报告 P0: Android 截图 67B 假图 (4 张 × 2 locale = 8 张)
# - 4 主流程: home / mood / vent / medication (R108 简化为 4 屏, 业务核心)
# - 7"/10" 平板: Google Play 2019-11 强制需 ≥1 张
# - 2 locale: en-US / zh-CN
# - 总计 4 × 2 + 2 (平板) = 10 张
#
# 用法 (Mac/Linux/Windows + WSL):
#   chmod +x scripts/generate_android_screenshots.sh
#   ./scripts/generate_android_screenshots.sh
#
# 输出:
#   fastlane/metadata/android/{en-US,zh-CN}/phoneScreenshots/screenshot_1..4.png
#   fastlane/metadata/android/{en-US,zh-CN}/sevenInchScreenshots/screenshot_1.png
#   fastlane/metadata/android/{en-US,zh-CN}/tenInchScreenshots/screenshot_1.png
#
# 前置:
#   1. Android Studio + Android SDK (含 emulator)
#   2. Flutter 3.41+ (本项目用 3.41.9)
#   3. Java JDK 17+ (Android Gradle)
#   4. 启动 3 个 AVD: Pixel 8 phone / 7" tablet / 10" tablet
#   5. adb 配 PATH (~/Library/Android/sdk/platform-tools/adb)
#
# ⚠️  本脚本跨平台 (Mac/Linux/WSL), 不需 Xcode
# ⚠️  截图前必须 `flutter build apk --release` 成功 (走真实 signing)
#    详见 docs/audit/2026-08-10-cleanup/R108-screenshots-automation.md

set -euo pipefail

# 0. 工具检查
for tool in adb flutter emulator; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    case "$tool" in
      adb)
        echo "[FAIL] adb 找不到。请装 Android SDK 并配 PATH:" >&2
        echo "       Mac:   export PATH=\$HOME/Library/Android/sdk/platform-tools:\$PATH" >&2
        echo "       Linux: export PATH=\$HOME/Android/Sdk/platform-tools:\$PATH" >&2
        exit 1
        ;;
      flutter)
        echo "[FAIL] flutter 找不到。请装 Flutter 3.41+ 并配 PATH。" >&2
        exit 1
        ;;
      emulator)
        echo "[FAIL] emulator 找不到。请装 Android SDK Emulator。" >&2
        exit 1
        ;;
    esac
  fi
done

# 1. 路径
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

METADATA_DIR="$PROJECT_ROOT/fastlane/metadata/android"
TMP_DIR="$PROJECT_ROOT/build/android_screenshots"
mkdir -p "$TMP_DIR"

# 2. 配置
DEVICES=(
  "Pixel_8_API_34|phoneScreenshots|1080x2400"
  "Pixel_Tablet_7_API_34|sevenInchScreenshots|1024x600"  # placeholder, 需实际 AVD 名
  "Pixel_Tablet_10_API_34|tenInchScreenshots|2560x1600"  # placeholder, 需实际 AVD 名
)
LOCALES=(en-US zh-CN)
SCREENS=(
  "home|主页"
  "mood|心情"
  "vent|树洞"
  "medication|用药"
)

# 3. 构建 APK
echo "[1/4] flutter build apk --release..."
flutter build apk --release 2>&1 | tail -10
APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
if [ ! -f "$APK_PATH" ]; then
  echo "[FAIL] APK 构建失败: $APK_PATH 不存在" >&2
  exit 1
fi
echo ""

# 4. 启动模拟器 + 截图
for device_entry in "${DEVICES[@]}"; do
  IFS='|' read -r avd_name fastlane_subdir resolution <<< "$device_entry"
  echo "[2/4] 设备: $avd_name ($resolution)"

  # 检查 AVD 存在
  if ! emulator -list-avds 2>/dev/null | grep -q "^$avd_name$"; then
    echo "      [WARN] AVD '$avd_name' 不存在, 跳过"
    echo "      实际 AVD: $(emulator -list-avds 2>/dev/null | tr '\n' ' ')"
    continue
  fi

  # 启动模拟器 (无头模式, headless 适合 CI)
  emulator -avd "$avd_name" -no-window -no-audio -no-boot-anim -no-snapshot-save &
  EMULATOR_PID=$!

  # 等 boot 完成
  adb wait-for-device
  echo "      等 boot 完成 (最多 5 分钟)..."
  timeout 300 bash -c "while [[ \"\$(adb shell getprop sys.boot_completed)\" != \"1\" ]]; do sleep 5; done" \
    || echo "      [WARN] boot 超时 5 分钟, 继续"

  for locale in "${LOCALES[@]}"; do
    echo "[3/4] locale: $locale"
    OUT_DIR="$METADATA_DIR/$locale/$fastlane_subdir"
    mkdir -p "$OUT_DIR"

    # 切语言 (Android 13+)
    adb shell "cmd locale set-app-locales app.chroniccare.patient --locales $locale" 2>/dev/null || \
    adb shell "setprop persist.sys.locale $locale; stop; sleep 5; start" 2>/dev/null || true

    # 装 APK
    adb install -r "$APK_PATH"

    # 启动 App
    adb shell monkey -p app.chroniccare.patient -c android.intent.category.LAUNCHER 1 2>/dev/null || \
    echo "      [WARN] App 启动失败, 检查 package name"

    # 等启动 + 主页加载
    sleep 8

    # 4 张截图 (按屏号)
    for screen_entry in "${SCREENS[@]}"; do
      screen_name=$(echo "$screen_entry" | cut -d'|' -f1)

      if [ "$screen_name" != "home" ]; then
        # 真实业务: 这里需用 deep link 或 UI 自动化 (UiAutomator)
        # R108 简化: 用 deep link (如果 App 注册了)
        adb shell am start -a android.intent.action.VIEW -d "chroniccare://$screen_name" 2>/dev/null || true
        sleep 4
      fi

      # 截图
      SCREENSHOT_PATH="$TMP_DIR/${avd_name}_${locale}_${screen_name}.png"
      adb exec-out screencap -p > "$SCREENSHOT_PATH"
      echo "      [OK] 截屏: $screen_name → $SCREENSHOT_PATH"

      # 复制到 fastlane 目录
      SCREEN_NUM=1
      case "$screen_name" in
        home) SCREEN_NUM=1 ;;
        mood) SCREEN_NUM=2 ;;
        vent) SCREEN_NUM=3 ;;
        medication) SCREEN_NUM=4 ;;
      esac
      cp "$SCREENSHOT_PATH" "$OUT_DIR/screenshot_$SCREEN_NUM.png"
    done

    # 卸载 App
    adb uninstall app.chroniccare.patient 2>/dev/null || true
  done

  # 关闭模拟器
  adb emu kill 2>/dev/null || kill $EMULATOR_PID 2>/dev/null || true
  sleep 2
done

# 5. 验证
echo ""
echo "[4/4] 验证截图生成..."
TOTAL=0
for locale in "${LOCALES[@]}"; do
  for subdir in phoneScreenshots sevenInchScreenshots tenInchScreenshots; do
    DIR="$METADATA_DIR/$locale/$subdir"
    if [ -d "$DIR" ]; then
      COUNT=$(ls "$DIR"/screenshot_*.png 2>/dev/null | wc -l | tr -d ' ')
      echo "      $locale/$subdir: $COUNT 张"
      TOTAL=$((TOTAL + COUNT))
    fi
  done
done

echo ""
echo "[OK] Android 截图生成完成! 总计 $TOTAL 张 (期望 10 张 = 3 设备 × 2 locale)"
echo ""
echo "下一步:"
echo "  1. 人工 review 截图质量 (是否有 PII / 错位 / 不雅)"
echo "  2. 检查 fastlane/metadata/android/*/ 目录文件大小 (期望每张 > 50KB)"
echo "  3. Google Play Console → 商店发布 → 设备目录 → 选 4-5 张"
echo "  4. 也可加 feature_graphic (1024×500) + icon (512×512) 真实图"
echo ""
