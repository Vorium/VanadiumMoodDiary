"""Re-convert zh_Hant from scratch using tmp as the source.

This time:
- Apply OpenCC s2tw to ALL values (no is_simplified filter)
- Re-apply the 您/你 fix
- Re-apply the ／ fix
- Be careful with quote consumption
"""
import opencc
import re

CONVERTER = opencc.OpenCC('s2tw')
ZH_PATH = r'lib/l10n/app_zh.arb'
SRC = r'lib/l10n/app_zh_Hant.arb.tmp'
OUT = r'lib/l10n/app_zh_Hant.arb'

with open(ZH_PATH, encoding='utf-8') as f:
    zh_text = f.read()
with open(SRC, encoding='utf-8') as f:
    hant_text = f.read()

zh_pat = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in zh_pat.finditer(zh_text)}

# Use a more robust line parser. A value line:
#   "key": "value",    (no embedded escaped quotes in our ARB so this is safe)
# Parse the line manually.
out_lines = []
for line in hant_text.splitlines(keepends=True):
    m = re.match(r'^(  ")([a-zA-Z][a-zA-Z0-9]+)(": ")(.*)("(?:,?)\s*)(.*)$', line.rstrip('\n'))
    if not m:
        out_lines.append(line)
        continue
    indent, key, mid, value, end_with_comma_or_quote, rest = m.groups()
    new_value = CONVERTER.convert(value)
    zh_value = zh_map.get(key, '')

    # 修复 您/你 (zh 是"您"而 new 是"你" -> 改回"您")
    if '您' in zh_value and new_value.count('你') > 0 and '您' not in new_value:
        new_value = new_value.replace('你', '您')

    # 修复 ／ (zh 是"／"而 new 是"/" -> 改"／")
    if '／' in zh_value and '/' in new_value and '／' not in new_value:
        new_value = new_value.replace('/', '／')

    # 修复 …… (zh 是"……"而 new 是"..." -> 改"……")
    if '……' in zh_value and '...' in new_value:
        new_value = new_value.replace('...', '……')

    new_line = f'{indent}{key}{mid}{new_value}{end_with_comma_or_quote}{rest}\n'
    out_lines.append(new_line)

new_text = ''.join(out_lines)
with open(OUT, 'w', encoding='utf-8') as f:
    f.write(new_text)
print(f'Wrote {OUT}')
