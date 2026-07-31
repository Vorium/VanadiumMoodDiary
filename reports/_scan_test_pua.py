#!/usr/bin/env python3
"""scan test/ for PUA characters (check_no_pua.py 修正盲点验证)"""
from pathlib import Path
import re
import sys

PUA_RE = re.compile(r'[\uE000-\uF8FF]')
test_files = list(Path('test').rglob('*.dart'))
total = 0
hits = []
for f in test_files:
    try:
        text = f.read_text(encoding='utf-8')
    except UnicodeDecodeError:
        continue
    for line_no, line in enumerate(text.splitlines(), 1):
        for col, ch in enumerate(line, 1):
            if PUA_RE.match(ch):
                hits.append((f, line_no, col, ord(ch)))
                total += 1
print(f'Total PUA hits in test/: {total}')
for f, ln, col, cp in hits[:30]:
    print(f'  {f}:{ln}:{col}  U+{cp:04X}')
sys.exit(0 if total == 0 else 1)
