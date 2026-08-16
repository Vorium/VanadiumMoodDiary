#!/usr/bin/env bash
# v1.0.0: 品牌图标统一生成器 (iOS AppIcon/LaunchImage + Android 商店图标/mipmap/feature graphic)
#
# 设计见 scripts/generate_app_icon.py 头部注释 (绿色胶囊+心形+十字, R108 brief 对齐)
#
# 用法:
#   ./scripts/generate_app_icon.py    # 直接跑 python 也行
#
# 依赖: python3 + pillow (pip3 install --user pillow)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if ! python3 -c "import PIL" >/dev/null 2>&1; then
  echo "[FAIL] 缺 python3 + pillow, 先: pip3 install --user pillow" >&2
  exit 1
fi

python3 "$SCRIPT_DIR/generate_app_icon.py"
