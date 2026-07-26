#!/usr/bin/env python3
"""Count PUA lines more carefully"""
import re
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

with open('lib/core/routing/app_router.dart', 'rb') as f:
    data = f.read()

# Find all PUA positions
pua_positions = []
i = 0
while i < len(data):
    if i + 2 < len(data):
        b1, b2, b3 = data[i], data[i+1], data[i+2]
        if b1 == 0xEE and 0x80 <= b2 <= 0xBF and 0x80 <= b3 <= 0xBF:
            cp = ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
            if 0xE000 <= cp <= 0xF8FF:
                pua_positions.append((i, cp))
    i += 1

print(f"Total PUA characters: {len(pua_positions)}")

# Decode text
text = data.decode('utf-8', errors='replace')
lines = text.splitlines(keepends=False)

# Find which lines have PUA
pua_lines = set()
for pos, cp in pua_positions:
    # Convert byte position to line number
    line_idx = data[:pos].decode('utf-8', errors='replace').count('\n')
    pua_lines.add(line_idx + 1)  # 1-indexed

print(f"Total lines with PUA: {len(pua_lines)}")
print(f"Line numbers: {sorted(pua_lines)}")
