#!/usr/bin/env python3
"""Check missing keys between zh and en arb files."""
import re
import sys


def keys(p):
    txt = open(p, encoding='utf-8').read()
    return set(re.findall(r'^  "([a-zA-Z][a-zA-Z0-9]+)":', txt, re.M))


zh = keys(r'lib/l10n/app_zh.arb')
en = keys(r'lib/l10n/app_en.arb')
print(f'zh total: {len(zh)} / en total: {len(en)}')
missing = sorted(zh - en)
print(f'Missing in en ({len(missing)}):')
for k in missing:
    print(f'  {k}')
