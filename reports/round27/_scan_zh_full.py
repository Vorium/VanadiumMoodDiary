#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Full scan of all l10n keys for half-width punctuation."""
import re

with open(r'D:\Batch\chroniccare\lib\l10n\app_zh.arb', encoding='utf-8') as fh:
    content = fh.read()

# Match all string values
cjk = re.compile(r'[\u4e00-\u9fff]')
count = 0
for m in re.finditer(r'"([^"]+)":\s*"([^"]+)"', content):
    key, val = m.group(1), m.group(2)
    if not cjk.search(val):
        continue
    # Skip keys starting with @ (metadata)
    if key.startswith('@'):
        continue
    hits = []
    for mm in re.finditer(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]', val):
        hits.append(('inner', mm.group(), mm.start()))
    for mm in re.finditer(r'[,.;:?!][\u4e00-\u9fff]', val):
        hits.append(('left', mm.group(), mm.start()))
    for mm in re.finditer(r'[\u4e00-\u9fff][,.;:?!]', val):
        hits.append(('right', mm.group(), mm.start()))
    if hits:
        count += 1
        # De-dupe
        seen = set()
        uniq = []
        for kind, ch, pos in hits:
            if pos not in seen:
                seen.add(pos)
                uniq.append((kind, ch, pos))
        print('%s: %s' % (key, val[:80]))
        for kind, ch, pos in uniq[:3]:
            print('  [%s] %r @%d' % (kind, ch, pos))
print('total: %d' % count)
