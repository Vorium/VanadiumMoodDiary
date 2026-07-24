#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Scan for half-width punctuation inside Chinese UI text (v0.21 P1-16 follow-up).
Focus on:
- 错误信息文案 (throw Exception('...'))
- 用户可见的中文文案 in l10n/ (app_zh.arb) and domain strings
- AppLocalizations 生成代码 (.dart)
- 错误提示 / SnackBar / Dialog 文案
"""
import os, re, sys

roots = [
    r'D:\Batch\chroniccare\lib\l10n',
    r'D:\Batch\chroniccare\lib\core\l10n',
    r'D:\Batch\chroniccare\lib\core\shared',
    r'D:\Batch\chroniccare\lib\domain\logic',
    r'D:\Batch\chroniccare\lib\domain\usecases',
    r'D:\Batch\chroniccare\lib\core\data\services',
]
cjk = re.compile(r'[\u4e00-\u9fff]')
# Punctuation that's commonly misused in Chinese: , . : ; ? !
# Skip parens, brackets, quotes, slashes (too often used in code)
suspect = re.compile(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]')
suspect_left = re.compile(r'[,.;:?!][\u4e00-\u9fff]')
suspect_right = re.compile(r'[\u4e00-\u9fff][,.;:?!]')

# Common false positives we skip
skip_patterns = [
    re.compile(r'^\s*///\s'),  # doc comment line
    re.compile(r'^\s*//\s'),  # line comment
    re.compile(r'^\s*\*\s'),  # block comment inside
    re.compile(r'://'),  # URL
    re.compile(r'//\s*\['),  # markdown link
    re.compile(r'=".*[\u4e00-\u9fff].*"'),  # code with Chinese in string
]

for root in roots:
    if not os.path.exists(root):
        continue
    print('=== %s ===' % root)
    files = []
    for dp, _, fs in os.walk(root):
        for f in fs:
            if f.endswith('.dart') or f.endswith('.arb'):
                files.append(os.path.join(dp, f))
    for fp in sorted(files):
        with open(fp, encoding='utf-8') as fh:
            lines = fh.read().splitlines()
        for i, line in enumerate(lines, 1):
            if not cjk.search(line):
                continue
            # Skip comments
            stripped = line.lstrip()
            if stripped.startswith('//') or stripped.startswith('*') or stripped.startswith('///'):
                continue
            # Skip if line is a code line (has `class`, `=>`, etc.)
            # Heuristic: look for suspect patterns
            hits = []
            for m in re.finditer(r'[\u4e00-\u9fff][,.;:?!][\u4e00-\u9fff]', line):
                hits.append(('inner', m.group(), m.start()))
            for m in re.finditer(r'[,.;:?!][\u4e00-\u9fff]', line):
                hits.append(('left', m.group(), m.start()))
            for m in re.finditer(r'[\u4e00-\u9fff][,.;:?!]', line):
                hits.append(('right', m.group(), m.start()))
            if hits:
                rel = os.path.relpath(fp, r'D:\Batch\chroniccare')
                # De-dupe
                seen = set()
                uniq = []
                for kind, ch, pos in hits:
                    if pos not in seen:
                        seen.add(pos)
                        uniq.append((kind, ch, pos))
                print('  %s:%d [%s]' % (rel, i, line.strip()[:120]))
                for kind, ch, pos in uniq[:5]:
                    print('    [%s] pos=%d %r' % (kind, pos, ch))
