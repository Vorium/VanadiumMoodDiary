"""Second pass: fix remaining / in zh_Hant to ／ (matching zh style).

After fix_zh_hant_polish.py, 8 keys still have / because their context is
digit/digit (e.g. 7/14/30) which my regex skipped. Now do a more aggressive
fix matching zh's full-width style.
"""
import re

ZH = r'lib/l10n/app_zh.arb'
HANT = r'lib/l10n/app_zh_Hant.arb'

with open(ZH, encoding='utf-8') as f:
    zh_text = f.read()
with open(HANT, encoding='utf-8') as f:
    hant_text = f.read()


def get_map(text):
    pat = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
    return {m.group(1): m.group(2) for m in pat.finditer(text)}


zh_map = get_map(zh_text)

# For each key where zh has ／ and hant has /, replace ALL / with ／
# (no path-like exceptions in this medical app l10n)
out_lines = []
fixed = []
for line in hant_text.splitlines(keepends=True):
    m = re.match(r'^(  ")([a-zA-Z][a-zA-Z0-9]+)(": )"([^"]*)("(?:,?))(.*)$', line)
    if not m:
        out_lines.append(line)
        continue
    indent, key, sep, value, end, rest = m.groups()
    zh_value = zh_map.get(key, '')
    if '／' in zh_value and '/' in value:
        # Replace all / with ／ (preserving surrounding chars)
        new_value = value.replace('/', '／')
        if new_value != value:
            fixed.append(key)
            line = f'{indent}"{key}": "{new_value}"{end}{rest}\n'
    out_lines.append(line)

new_text = ''.join(out_lines)
with open(HANT, 'w', encoding='utf-8') as f:
    f.write(new_text)

print(f'Fixed {len(fixed)} more keys with / → ／:')
for k in fixed:
    print(f'  {k}')

# Verify
print()
hant_text2 = open(HANT, encoding='utf-8').read()
print(f'新 hant 全文 "/" 计数: {hant_text2.count("/") - hant_text2.count("//") - hant_text2.count("PHQ-9") - hant_text2.count("GAD-7")}')
print(f'新 hant 全文 "／" 计数: {hant_text2.count("／")}')

# 看哪些 key 仍含 / 
print()
print('=== 仍含 / 的 key (排除 path 引用) ===')
pat2 = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
for m in pat2.finditer(hant_text2):
    k, v = m.group(1), m.group(2)
    if '/' in v and '／' not in v:
        print(f'  {k}: {v!r}')
