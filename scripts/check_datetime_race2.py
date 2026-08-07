# R99 (BUG-4) rewrite: strip // comments; per-scope brace stack;
# single hit merges upward only across non-function blocks;
# exempt: single-capture (final now = ...) + branch-dup (same stmt).
import os
import re
from pathlib import Path
ROOT = Path(os.getcwd()) / 'lib'
races = []
CAP = re.compile(r'\b(?:final|var)\s+now\s*=\s*DateTime\.now\(\)')
def check_scope(rel, start, hits, code):
    single = False
    for l in hits:
        if CAP.search(code[l - 1]):
            single = True
    if single:
        return
    texts = set(code[l - 1].strip() for l in hits)
    if len(texts) in range(0, 2):
        return
    races.append((rel, start, len(hits), hits))
for f in ROOT.rglob('*.dart'):
    if '.g.dart' in f.name or '.freezed.dart' in f.name:
        continue
    lines = f.read_text(encoding='utf-8').splitlines()
    code = []
    for ln in lines:
        code.append(ln.split('//')[0].rstrip())
    stack = []
    rel = str(f.relative_to(ROOT.parent))
    for i, c in enumerate(code):
        for ch in c:
            if ch == '{':
                sig = c
                for k in range(1, 6):
                    if i - k not in range(0, len(code)):
                        break
                    prev = code[i - k]
                    sig = prev + ' ' + sig
                    if prev.endswith(';') or prev.endswith('{') or prev.endswith('}'):
                        break
                ctrl = ('if (' in sig) or ('if(' in sig) or ('for (' in sig) or ('while (' in sig) or ('switch (' in sig) or ('catch (' in sig) or ('catch(' in sig) or ('else' in sig)
                kw = ('class ' in sig) or ('enum ' in sig) or ('mixin ' in sig) or ('extension ' in sig)
                isf = ('(' in sig) and not ctrl and not kw
                stack.append([i + 1, [], isf])
            elif ch == '}':
                if len(stack) != 0:
                    start, hits, isf = stack.pop()
                    if len(hits) in range(2, 100):
                        check_scope(rel, start, hits, code)
                    elif len(hits) == 1 and len(stack) != 0 and not isf:
                        stack[-1][1].append(hits[0])
        if 'DateTime.now()' in c and len(stack) != 0:
            stack[-1][1].append(i + 1)
print('\u771f\u53ef\u7591 race (\u540c\u51fd\u6570\u4f53 >=2 \u6b21 DateTime.now() \u4e14\u65e0 single-capture/\u5206\u652f\u590d\u5236): ' + str(len(races)))
for path, line, count, hit_lines in races:
    print('  ' + path + ':' + str(line) + ' \u51fa\u73b0 ' + str(count) + ' \u6b21 (lines: ' + str(hit_lines) + ')')
