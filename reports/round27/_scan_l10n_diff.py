#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Diff app_zh.arb vs app_en.arb keys (all keys, not just string)."""
import re

def get_keys(f):
    with open(f, encoding='utf-8') as fh:
        content = fh.read()
    return set(re.findall(r'"(@?[a-zA-Z0-9_]+)":', content))

zh = get_keys(r'D:\Batch\chroniccare\lib\l10n\app_zh.arb')
en = get_keys(r'D:\Batch\chroniccare\lib\l10n\app_en.arb')

print('zh total: %d' % len(zh))
print('en total: %d' % len(en))
print('zh only (%d):' % len(zh - en))
for k in sorted(zh - en):
    print('  -', k)
print('en only (%d):' % len(en - zh))
for k in sorted(en - zh):
    print('  -', k)
print('common: %d' % len(zh & en))
