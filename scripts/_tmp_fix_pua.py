#!/usr/bin/env python3
"""临时: 列出所有 PUA cluster 的 context, 人工判断原意"""
import re
import sys
from pathlib import Path

# Windows GBK terminal: force UTF-8 output
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

target = Path(r"D:\Batch\chroniccare\lib\core\routing\app_router.dart")
text = target.read_text(encoding="utf-8")
lines = text.split("\n")

target = Path(r"D:\Batch\chroniccare\lib\core\routing\app_router.dart")
raw = target.read_bytes()
text = raw.decode("utf-8")

# 找所有 PUA cluster + 它们的 line + context
pattern = re.compile(r"[\uE000-\uF8FF]+")
print(f"PUA clusters in {target.name}:\n")
for m in pattern.finditer(text):
    cluster = m.group(0)
    line_no = text.count("\n", 0, m.start()) + 1
    line = lines[line_no - 1]
    print(f"L{line_no:3d} | cluster={cluster!r} (len={len(cluster)})")
    print(f"     | line: {line}")
    print()
