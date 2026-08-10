"""R101 审计: 扫描 lib/ + test/ 的 mojibake / U+FFFD / PUA 字符。"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
bad = []
for sub in ('lib', 'test', 'scripts'):
    base = os.path.join(ROOT, sub)
    for r, d, fs in os.walk(base):
        for f in fs:
            if not f.endswith(('.dart', '.py')):
                continue
            p = os.path.join(r, f)
            try:
                with open(p, encoding='utf-8') as fh:
                    for i, line in enumerate(fh, 1):
                        hits = []
                        if '\ufffd' in line:
                            hits.append('U+FFFD')
                        for ch in line:
                            cp = ord(ch)
                            if 0xE000 <= cp <= 0xF8FF or 0xF0000 <= cp <= 0xFFFFD:
                                hits.append(f'PUA U+{cp:04X}')
                        if hits:
                            bad.append((os.path.relpath(p, ROOT), i, sorted(set(hits)), line.strip()[:80]))
            except UnicodeDecodeError:
                bad.append((os.path.relpath(p, ROOT), 0, ['NOT-UTF8'], ''))

out = os.path.join(ROOT, 'reports', 'r101', 'mojibake.log')
with open(out, 'w', encoding='utf-8') as fh:
    fh.write(f'total bad: {len(bad)}\n')
    for p, i, kinds, snippet in bad:
        fh.write(f'  {p}:{i}  {",".join(kinds)}  | {snippet}\n')
print(f'total bad: {len(bad)}, see reports/r101/mojibake.log')
