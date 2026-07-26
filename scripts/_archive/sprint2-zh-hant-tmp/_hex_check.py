#!/usr/bin/env python3
"""Check raw bytes around PUA in app_router.dart"""
import sys

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

with open('lib/core/routing/app_router.dart', 'rb') as f:
    data = f.read()

# Find all PUA characters and their positions (in bytes)
pua_positions = []
i = 0
while i < len(data):
    # PUA 3-byte UTF-8: E0 xx xx  (E0-EF range) but specifically 0xEE 0x80-0xBF 0x80-0xBF
    # U+E000-U+F8FF in UTF-8 = 0xEE 0x80 0x80 to 0xEE 0xA3 0xBF
    if i + 2 < len(data):
        b1, b2, b3 = data[i], data[i+1], data[i+2]
        if b1 == 0xEE and 0x80 <= b2 <= 0xBF and 0x80 <= b3 <= 0xBF:
            cp = ((b1 & 0x0F) << 12) | ((b2 & 0x3F) << 6) | (b3 & 0x3F)
            if 0xE000 <= cp <= 0xF8FF:
                pua_positions.append((i, cp))
    i += 1

print(f"PUA characters: {len(pua_positions)}")
# Show a few
for pos, cp in pua_positions[:30]:
    # Show context
    start = max(0, pos - 20)
    end = min(len(data), pos + 23)
    ctx = data[start:end]
    print(f"  pos={pos} U+{cp:04X}: {ctx!r}")
