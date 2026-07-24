#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan app_zh.arb for half-width punctuation in Chinese strings."""
import re, os

fp = r'D:\Batch\chroniccare\lib\l10n\app_zh.arb'
with open(fp, encoding='utf-8') as f:
    content = f.read()

cjk = re.compile(r'[\u4e00-\u9fff]')
suspect_inner = re.compile(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]')
suspect_left = re.compile(r'[,.;:?!][\u4e00-\u9fff]')
suspect_right = re.compile(r'[\u4e00-\u9fff][,.;:?!]')

count = 0
for line in content.splitlines():
    if '"' not in line or not cjk.search(line) or ':' not in line:
        continue
    m = re.match(r'\s*"([^"]+)":\s*"(.*)"', line)
    if not m:
        continue
    key, val = m.group(1), m.group(2)
    h = []
    for mm in re.finditer(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]', val):
        h.append(('inner', mm.group()))
    for mm in re.finditer(r'[,.;:?!][\u4e00-\u9fff]', val):
        h.append(('left', mm.group()))
    for mm in re.finditer(r'[\u4e00-\u9fff][,.;:?!]', val):
        h.append(('right', mm.group()))
    if h:
        count += 1
        print('%s: %s -- %s' % (key, val[:80], h))
print('total keys with half-width punct: %d' % count)
