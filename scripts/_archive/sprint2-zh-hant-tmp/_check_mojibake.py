#!/usr/bin/env python3
"""Check GBK-mojibake lines in app_router.dart"""
import re
import sys

# Windows GBK terminal fix
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

with open('lib/core/routing/app_router.dart', 'rb') as f:
    data = f.read()
text = data.decode('utf-8', errors='replace')
lines = text.splitlines()
pua_char = re.compile(r'[\uE000-\uF8FF]')

# Find all PUA lines
pua_lines = []
for i, line in enumerate(lines, 1):
    if pua_char.search(line):
        pua_lines.append(i)

print(f"Total lines with PUA: {len(pua_lines)}")
print(f"Lines: {pua_lines}")
print()
print("=" * 80)

# Try GBK conversion for each PUA line
for ln in pua_lines[:30]:
    line = lines[ln-1]
    # Use repr for first part
    safe = line.encode('utf-8', errors='replace').decode('utf-8')
    print(f"Line {ln}:")
    print(f"  Mojibake: {safe[:200]}")
    try:
        gbk_bytes = line.encode('gbk')
        decoded = gbk_bytes.decode('utf-8')
        print(f"  GBK->UTF-8: {decoded[:200]}")
    except Exception as e:
        print(f"  GBK encode error: {e}")
    print()
