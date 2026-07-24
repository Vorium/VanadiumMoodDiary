#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan for half-width punctuation in Chinese UI text - more comprehensive.
Include presentation/ and look at all string literals with Chinese.
"""
import os, re, sys

roots = [
    r'D:\Batch\chroniccare\lib\presentation',
    r'D:\Batch\chroniccare\lib\domain\logic',
    r'D:\Batch\chroniccare\lib\domain\usecases',
    r'D:\Batch\chroniccare\lib\core\data\services',
    r'D:\Batch\chroniccare\lib\core\data\repositories',
    r'D:\Batch\chroniccare\lib\core\data\utils',
    r'D:\Batch\chroniccare\lib\core\data\database\tables',
    r'D:\Batch\chroniccare\lib\core\data\database\mappers',
    r'D:\Batch\chroniccare\lib\core\data\database\connection',
]
cjk = re.compile(r'[\u4e00-\u9fff]')
suspect_inner = re.compile(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]')
suspect_left = re.compile(r'[,.;:?!][\u4e00-\u9fff]')
suspect_right = re.compile(r'[\u4e00-\u9fff][,.;:?!]')

# Heuristic: a line is "UI text" if it has a Chinese char AND is in a string literal
# (i.e., inside single or double quotes containing Chinese)
ui_line = re.compile(r"""(['"`])[^'"`\n]*[\u4e00-\u9fff]""")

results = []
for root in roots:
    if not os.path.exists(root):
        continue
    for dp, _, fs in os.walk(root):
        for f in fs:
            if not f.endswith('.dart'):
                continue
            fp = os.path.join(dp, f)
            with open(fp, encoding='utf-8') as fh:
                lines = fh.read().splitlines()
            for i, line in enumerate(lines, 1):
                if not cjk.search(line):
                    continue
                stripped = line.lstrip()
                if stripped.startswith('//') or stripped.startswith('*') or stripped.startswith('///'):
                    continue
                # Skip pure import / package line
                if stripped.startswith('import ') or stripped.startswith('export ') or stripped.startswith('part '):
                    continue
                # Check for string literal containing Chinese
                has_chinese_string = bool(re.search(r"""(['"`])[^'"`\n]*[\u4e00-\u9fff][^'"`\n]*\1""", line))
                if not has_chinese_string:
                    continue
                hits = []
                for m in re.finditer(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]', line):
                    hits.append(('inner', m.group(), m.start()))
                for m in re.finditer(r'[,.;:?!][\u4e00-\u9fff]', line):
                    hits.append(('left', m.group(), m.start()))
                for m in re.finditer(r'[\u4e00-\u9fff][,.;:?!]', line):
                    hits.append(('right', m.group(), m.start()))
                if hits:
                    rel = os.path.relpath(fp, r'D:\Batch\chroniccare')
                    seen = set()
                    uniq = []
                    for kind, ch, pos in hits:
                        if pos not in seen:
                            seen.add(pos)
                            uniq.append((kind, ch, pos))
                    results.append((rel, i, line.strip(), uniq))

# Group by file
from collections import defaultdict
by_file = defaultdict(list)
for rel, i, line, uniq in results:
    by_file[rel].append((i, line, uniq))

total = 0
for fp in sorted(by_file.keys()):
    entries = by_file[fp]
    total += len(entries)
    print('--- %s (%d hits) ---' % (fp, len(entries)))
    for i, line, uniq in entries:
        print('  L%d %s' % (i, line[:130]))
        for kind, ch, pos in uniq[:4]:
            print('      [%s] %r @%d' % (kind, ch, pos))
print()
print('total files: %d, total hits: %d' % (len(by_file), total))
