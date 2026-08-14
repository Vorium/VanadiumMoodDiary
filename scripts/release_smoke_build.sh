#!/usr/bin/env bash
# v0.32 round 8g: release 冒烟循环一键脚本
#
# 用法:
#   ./scripts/release_smoke_build.sh "<修复标题>"
#
# 每轮修复后执行, 自动完成:
#   1. pubspec build 号 +1 (0.32.0+143 → +144), 语义版本不动
#   2. docs/CHANGELOG.md 顶部插新版本段 (含标题)
#   3. fastlane notes.txt 首行版本同步 (check_review_information_todo 守门)
#   4. README.md 头部状态行版本同步
#   5. flutter analyze 快检 (0 error/0 warning 才继续; info 级放行)
#   6. gradle assembleRelease --no-daemon 构建
#   7. apksigner 验证 + 16KB objdump 实测
#   8. 拷到 ~/Desktop/chroniccare-<版本>-release.apk
#   9. 守门员 check_changelog + check_review_information_todo 复跑
#
# commit 仍由主 agent 做 (round 8g/8h/... 风格)。
set -euo pipefail

TITLE="${1:-release 冒烟修复}"
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

export ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
SDK="$ANDROID_HOME"
DATE=$(date +%F)

# ---- 1-4. 版本 bump (纯 python, 无 sed 移植性问题) ----
echo "[1/4] 版本 bump + CHANGELOG/notes.txt/README/local.properties 同步..."
NEW=$(python3 - "$TITLE" "$DATE" <<'PYEOF'
import re, sys
title, date = sys.argv[1], sys.argv[2]

p = 'pubspec.yaml'
s = open(p).read()
m = re.search(r'^version:\s*([\d.]+)\+(\d+)', s, re.M)
assert m, 'pubspec version 未找到'
new = f'{m.group(1)}+{int(m.group(2)) + 1}'
open(p, 'w').write(s[:m.start()] + f'version: {new}' + s[m.end():])

p = 'docs/CHANGELOG.md'
s = open(p).read()
anchor = '# 变更日志\n'
sec = (f'## [{new}] - {date} (R112 release 冒烟: {title})\n\n'
       f'- **{title}** (release 冒烟实测修复, 版本 {new})\n\n')
assert anchor in s
open(p, 'w').write(s.replace(anchor, anchor + sec, 1))

p = 'fastlane/metadata/ios/review_information/notes.txt'
s = open(p).read()
s = re.sub(r'ChronicCare\s+[\d.]+\+\d+', f'ChronicCare {new}', s, count=1)
open(p, 'w').write(s)

p = 'README.md'
s = open(p).read()
s = re.sub(r'v[\d.]+\+\d+ \(2026', f'v{new} (2026', s, count=1)
open(p, 'w').write(s)

# 裸 gradlew 不刷新 flutter.versionCode (flutter 工具才写 local.properties),
# 必须手动同步, 否则 APK versionCode 停在旧值装不上去
p = 'android/local.properties'
s = open(p).read()
base, build = new.split('+')
s = re.sub(r'flutter\.versionCode=\d+', f'flutter.versionCode={build}', s)
s = re.sub(r'flutter\.versionName=.*', f'flutter.versionName={base}', s)
open(p, 'w').write(s)

print(new)
PYEOF
)
echo "  新版本: $NEW"

# ---- 5. analyze ----
echo "[2/4] flutter analyze 快检..."
ANALYZE_FULL="$(flutter analyze 2>&1 || true)"
ERR_COUNT=$(printf '%s\n' "$ANALYZE_FULL" | grep -cE '• (error|warning)' || true)
if [ "$ERR_COUNT" != "0" ]; then
  echo "[FAIL] analyze 有 $ERR_COUNT 个 error/warning, 修完再跑:"
  printf '%s\n' "$ANALYZE_FULL" | grep -E '• (error|warning)' | head -8
  exit 1
fi
printf '%s\n' "$ANALYZE_FULL" | tail -1

# ---- 6. build ----
echo "[3/4] gradle assembleRelease --no-daemon ..."
(cd android && ./gradlew assembleRelease --no-daemon)

APK="build/app/outputs/flutter-apk/app-release.apk"
[ -f "$APK" ] || { echo "[FAIL] APK 未生成"; exit 1; }

# ---- 7. verify ----
echo "[4/4] apksigner + 16KB objdump 实测 + 拷桌面 + 守门员..."
"$SDK/build-tools/36.0.0/apksigner" verify "$APK" > /dev/null \
  && echo "  apksigner OK" || { echo "[FAIL] 签名验证失败"; exit 1; }
TMP=$(mktemp -d)
unzip -qo "$APK" -d "$TMP" 2>/dev/null || true
SO_OK=$(python3 scripts/check_16kb_alignment.py --so-dir="$TMP/lib" 2>&1 | grep -cE '^\[OK\]' || true)
SO_FAIL=$(python3 scripts/check_16kb_alignment.py --so-dir="$TMP/lib" 2>&1 | grep -cE '^\[FAIL\]' || true)
rm -rf "$TMP"
echo "  16KB .so: OK=$SO_OK FAIL=$SO_FAIL"
[ "$SO_FAIL" = "0" ] || { echo "[FAIL] 16KB 验证不过"; exit 1; }

DEST="$HOME/Desktop/chroniccare-$NEW-release.apk"
cp "$APK" "$DEST"
echo "  桌面 APK: $DEST ($(du -h "$DEST" | cut -f1))"

python3 scripts/check_changelog.py | tail -1
python3 scripts/check_review_information_todo.py | tail -1

echo ""
echo "✅ 完成: $NEW 已构建并放桌面。commit 建议:"
echo "   git add -A && git commit -m \"0.32.0 round 8h: $TITLE (release 冒烟 $NEW)\""
