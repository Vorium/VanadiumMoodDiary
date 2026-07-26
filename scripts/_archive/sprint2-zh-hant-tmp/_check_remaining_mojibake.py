#!/usr/bin/env python3
"""Check for any remaining mojibake in app_router.dart"""
import re
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

# Common mojibake markers from this file
markers = [
    '璺', '敱', '鍒', '囨', '崲', '鍔', '杈', '姪', '鍑', '芥', '暟', '坴', '晥', '鑽', '甯', '鍋跺皵',
    '閫氱煡', '绠楄', '閰嶇疆', '棰戝害', '鐪', '鐐', '鐢ㄨ嵂', '绐勫睆', '鐩戝惉', '杩斿洖',
    '涓嶇粡', '姝ラ', '涔嬪墠', '鍘熷垯', '缁欐槑纭', '寮曞', '涓', '浼氬厛鍖',
    '鈿狅笍', '蹇呴』', '鎸夊０鏄', '鎸夊０', '鐩存帴璺',
    '鎺ュ彈', '鐢ㄤ簬', '灏婇噸', '璋?銆',
    '缁勮', '绠＄悊', '璇勪及', '鐙', '鏃ュ巻', '瑙掔儹',
    '浜哄搱', '鎴愬姛', '涓庢垚鍔', '鎻愰啋',
    '缁', '鏍戞礊', '鍏ㄥ睆',
    '鐣岄潰', '绱', '瀹藉睆', '涓婃帹', '鎼炲埗',
    '閬', '闃', '鐐?default', '鐐?medication', '鐐', '璺?home',
    '榛戣壊', '鐧',
    '鎱㈢梾',
]

with open(r'D:\Batch\chroniccare\lib\core\routing\app_router.dart', 'rb') as f:
    data = f.read()
text = data.decode('utf-8', errors='replace')
lines = text.splitlines()

found = 0
for i, line in enumerate(lines, 1):
    for m in markers:
        if m in line:
            safe = line.encode('utf-8', errors='replace').decode('utf-8')
            print(f"L{i}: marker='{m}'")
            print(f"  LINE: {safe[:120]}")
            found += 1
            break

print(f"\nTotal suspicious lines: {found}")
