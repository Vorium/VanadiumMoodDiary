#!/usr/bin/env python3
import re
import sys
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

with open('lib/core/routing/app_router.dart', 'rb') as f:
    data = f.read()
text = data.decode('utf-8', errors='replace')
lines = text.splitlines()
pua = re.compile(r'[\uE000-\uF8FF]')
for i in [33, 35, 36, 37, 38, 39]:
    line = lines[i-1]
    safe = line.encode('utf-8', errors='replace').decode('utf-8')
    print(f'L{i}: {safe}')
    print(f'  Has PUA: {bool(pua.search(line))}')
