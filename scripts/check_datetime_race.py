#!/usr/bin/env python3
"""扫描所有 .dart 文件，找出 '同函数多次 DateTime.now()' 的潜在 race。"""
import re
import sys
from pathlib import Path

ROOT = Path(r'D:\Batch\chroniccare\lib')

# 粗略找同函数多次调
# 思路: 用花括号匹配数函数体，统计 DateTime.now() 出现次数 >=2
race_files = []

for f in ROOT.rglob('*.dart'):
    if '.g.dart' in f.name or '.freezed.dart' in f.name:
        continue
    txt = f.read_text(encoding='utf-8')
    # 按行扫描, 找连续 5 行内出现 >=2 次 DateTime.now() 的"局部"
    lines = txt.splitlines()
    for i in range(len(lines)):
        if 'DateTime.now()' in lines[i]:
            # 前后 5 行窗口内计数
            window = lines[max(0, i - 5):min(len(lines), i + 6)]
            count = sum(1 for w in window if 'DateTime.now()' in w)
            if count >= 2:
                race_files.append((str(f.relative_to(ROOT.parent)), i + 1, count))
                break  # 一个文件只报一次

print(f'可疑同函数多次 DateTime.now() 文件数: {len(race_files)}')
for path, line, count in race_files:
    print(f'  {path}:{line}  窗口内 {count} 次')
