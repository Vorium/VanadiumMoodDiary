#!/usr/bin/env python3
"""Compare current mojibake lines with 9c305ed clean lines"""
import re
import sys
import subprocess

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

# Get original clean file
result = subprocess.run(
    ['git', 'show', '9c305ed:lib/core/routing/app_router.dart'],
    cwd=r'D:\Batch\chroniccare',
    capture_output=True
)
old_text = result.stdout.decode('utf-8')
old_lines = old_text.splitlines()

# Get current mojibake file
with open(r'D:\Batch\chroniccare\lib\core\routing\app_router.dart', 'rb') as f:
    new_text = f.read().decode('utf-8')
new_lines = new_text.splitlines()

pua_lines = [31, 34, 38, 96, 98, 121, 128, 145, 151, 172, 187, 217, 218, 219, 242, 243, 290, 324, 339, 366]
pua_pattern = re.compile(r'[\uE000-\uF8FF]')

# For each PUA line, find matching line in old
# Strip PUA from new line, then search for similar
for ln in pua_lines:
    new_line = new_lines[ln - 1]
    new_clean = pua_pattern.sub('', new_line)

    # Find closest match in old_lines by checking English/code content
    best_match = None
    best_score = 0
    for old_ln, old_line in enumerate(old_lines, 1):
        # Calculate similarity: count of common non-Chinese chars
        new_ascii = ''.join(c for c in new_clean if ord(c) < 128)
        old_ascii = ''.join(c for c in old_line if ord(c) < 128)
        common = sum(1 for a, b in zip(new_ascii, old_ascii) if a == b)
        if common > best_score and abs(len(new_ascii) - len(old_ascii)) < 20:
            best_score = common
            best_match = old_ln

    print(f"NEW L{ln}: {new_line[:120]}")
    if best_match:
        print(f"  → OLD L{best_match}: {old_lines[best_match-1][:120]}")
    print()
