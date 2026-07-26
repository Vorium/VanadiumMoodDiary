#!/usr/bin/env python3
"""Second pass: fix remaining mojibake lines (no PUA)"""
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

# Additional fixes (non-PUA mojibake lines)
FIXES_2 = {
    173: "          // ⚠️ 必须在 :id 之前声明，否则 :id 会先匹配（GoRouter 按声明顺序匹配）",
    210: "                // v0.16 round 19C fix: 用 tryParse 替代 parse，URL 是 '/abc' 时",
    211: "                // 不会崩，回退到 0（找不到对应条目 → 详情页显示\"找不到了\"）",
    227: "          // 点 default / soft 通知 → 跳 home",
}

path = r'D:\Batch\chroniccare\lib\core\routing\app_router.dart'
with open(path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

fixed_count = 0
for ln, correct in FIXES_2.items():
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

print(f"\nFixed {fixed_count}/{len(FIXES_2)} additional lines")
