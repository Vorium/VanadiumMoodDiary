#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan for half-width punctuation inside Chinese context (not finished).
For v0.21 P1-16 全角标点统一 check. We focus on:
- ASCII comma in Chinese context: "打卡, 你好"
- ASCII period: "hello. 你好"
- ASCII colon: "title: 标题"
- ASCII parens: "(你好)"
- ASCII semicolon: "hi; hi"
- ASCII question: "为什么?"
- ASCII exclamation: "hello!"

Define "in Chinese context" = the line has at least 1 CJK char.
"""
import os, re, sys

root = sys.argv[1] if len(sys.argv) > 1 else r'D:\Batch\chroniccare\lib'
cjk = re.compile(r'[\u4e00-\u9fff]')
# ASCII punctuation that's often misused in Chinese: , . : ; ? ! ( ) [ ] / \ ' " - _ + = * &
suspect = re.compile(r'[\u4e00-\u9fff][,.;:?!()\[\]/\'\"\-\+=*&][\u4e00-\u9fff]')
suspect_left = re.compile(r'[,.;:?!()\[\]/\'\"\-\+=*&][\u4e00-\u9fff]')
suspect_right = re.compile(r'[\u4e00-\u9fff][,.;:?!()\[\]/\'\"\-\+=*&]')

results = []
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
            # Skip pure ASCII or URL-like
            if line.strip().startswith('//'):
                # OK, this is comment
                pass
            matches = []
            for m in re.finditer(r'[\u4e00-\u9fff][,.;:?!()\[\]/\'\"\-\+=*&][\u4e00-\u9fff]', line):
                matches.append(('inner', m.group(), m.start()))
            for m in re.finditer(r'[,.;:?!()\[\]/\'\"\-\+=*&][\u4e00-\u9fff]', line):
                matches.append(('left', m.group(), m.start()))
            for m in re.finditer(r'[\u4e00-\u9fff][,.;:?!()\[\]/\'\"\-\+=*&]', line):
                matches.append(('right', m.group(), m.start()))
            if matches:
                # Dedupe by position
                seen = set()
                uniq = []
                for kind, ch, pos in matches:
                    if pos not in seen:
                        seen.add(pos)
                        uniq.append((kind, ch, pos))
                results.append((fp, i, line.strip(), uniq))

# Group by file
from collections import defaultdict
by_file = defaultdict(list)
for fp, i, line, uniq in results:
    by_file[fp].append((i, line, uniq))

total_count = 0
for fp in sorted(by_file.keys()):
    entries = by_file[fp]
    total_count += len(entries)
    rel = os.path.relpath(fp, root)
    print('---', rel, '(%d hits)' % len(entries))
    for i, line, uniq in entries[:3]:
        print('  L%d %s' % (i, line[:120]))
        for kind, ch, pos in uniq:
            print('    [%s] pos=%d char=%r' % (kind, pos, ch))

print()
print('total files with hits: %d' % len(by_file))
print('total hits: %d' % total_count)
