#!/usr/bin/env python3
"""Check missing keys between zh and en arb files.

v0.23 (P0-14) 修: 双向检查 (zh-en + en-zh) + exit code 1 (CI 友好)
"""
import re
import sys


def keys(p):
    txt = open(p, encoding='utf-8').read()
    return set(re.findall(r'^  "([a-zA-Z][a-zA-Z0-9]+)":', txt, re.M))


zh = keys(r'lib/l10n/app_zh.arb')
en = keys(r'lib/l10n/app_en.arb')
print(f'zh total: {len(zh)} / en total: {len(en)}')

missing_in_en = sorted(zh - en)
print(f'Missing in en ({len(missing_in_en)}):')
for k in missing_in_en:
    print(f'  {k}')

missing_in_zh = sorted(en - zh)
print(f'Missing in zh ({len(missing_in_zh)}):')
for k in missing_in_zh:
    print(f'  {k}')

if missing_in_en or missing_in_zh:
    print(f'[FAIL] check_arb_keys: {len(missing_in_en)} missing in en, {len(missing_in_zh)} missing in zh')
    sys.exit(1)
print(f'[OK] check_arb_keys: zh and en synchronized')
