#!/usr/bin/env python3
"""Third pass: fix remaining 9 mojibake lines"""
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

FIXES_3 = {
    62: "      // 从右滑入 + 淡入（emil: 标准的 Material 风格 push 动画）",
    105: "      // v0.17 round 3: Riverpod 3.x 改名为 .value（之前 .valueOrNull）",
    115: "      // 设置流程不进 shell（全屏引导）— rare 频度 → slide-up",
    157: "          // v0.21 Round 22 (P0-2): 法律与隐私页",
    193: "          // ============== v0.15 (Round 18) 树洞 ==============",
    194: "          // 全屏深页（full-screen modal feel）— rare 频度 → slide-up",
    262: "                  '页面不存在: ${state.matchedLocation}',",
    278: "                  label: Text(l10n?.errorPageBackHome ?? '返回首页'),",
    291: "/// - 宽屏（>= 840）：左侧 NavigationRail（extended 模式，显示文字）+ 右侧 child",
}

path = r'D:\Batch\chroniccare\lib\core\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

fixed_count = 0
for ln, correct in FIXES_3.items():
    idx = ln - 1
    old = lines[idx].rstrip('\n')
    new = correct
    if old != new:
        print(f"L{ln}:")
        print(f"  OLD: {old}")
        print(f"  NEW: {new}")
        lines[idx] = new + '\n'
        fixed_count += 1
    else:
        print(f"L{ln}: (no change)")

with open(path, 'w', encoding='utf-8', newline='') as f:
    f.writelines(lines)

print(f"\nFixed {fixed_count}/{len(FIXES_3)} additional lines")
