#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Check l10n key naming style."""
import re

for f in [r'D:\Batch\chroniccare\lib\l10n\app_zh.arb', r'D:\Batch\chroniccare\lib\l10n\app_en.arb']:
    with open(f, encoding='utf-8') as fh:
        content = fh.read()
    keys = re.findall(r'"([a-zA-Z0-9_]+)":\s*"', content)
    camel = [k for k in keys if re.match(r'^[a-z][a-zA-Z0-9]*$', k) and '_' not in k]
    snake = [k for k in keys if '_' in k]
    print(f)
    print('  total keys: %d' % len(keys))
    print('  camelCase: %d' % len(camel))
    print('  snake_case: %d' % len(snake))
    print('  examples camel: %s' % camel[:8])
    print('  examples snake: %s' % snake[:8])
