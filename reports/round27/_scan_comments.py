#!/usr/bin/env python3
# -*- coding: utf-8 -*-
import os, re, sys

root = sys.argv[1] if len(sys.argv) > 1 else r'D:\Batch\chroniccare\lib'
cjk = re.compile(r'[\u4e00-\u9fff]')
en = re.compile(r'[a-zA-Z]')

cn = en_ = mix = 0
triple_cn = triple_en = triple_mix = 0
files_count = 0
line_counts = 0

for dp, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.dart'):
            continue
        fp = os.path.join(dp, f)
        files_count += 1
        with open(fp, encoding='utf-8') as fh:
            txt = fh.read()
        for line in txt.splitlines():
            line_counts += 1
            t = line.lstrip()
            if t.startswith('///'):
                body = t[3:].lstrip('/').strip()
                hcn = bool(cjk.search(body))
                hen = bool(en.search(body))
                if hcn and hen:
                    triple_mix += 1
                elif hcn:
                    triple_cn += 1
                elif hen:
                    triple_en += 1
            elif t.startswith('//'):
                body = t[2:].lstrip('/').strip()
                hcn = bool(cjk.search(body))
                hen = bool(en.search(body))
                if hcn and hen:
                    mix += 1
                elif hcn:
                    cn += 1
                elif hen:
                    en_ += 1

print('files: %d' % files_count)
print('lines: %d' % line_counts)
print('/// doc comments - cn:%d en:%d mix:%d' % (triple_cn, triple_en, triple_mix))
print('//  line comments - cn:%d en:%d mix:%d' % (cn, en_, mix))
print('total mix (cn+en in same comment): %d' % (triple_mix + mix))
