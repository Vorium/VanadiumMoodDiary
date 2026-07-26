"""Diagnose key count."""
import re

hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()
zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()

# Find lines like  "key": that don't match value pattern
PAT_VAL = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
PAT_KEY = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":', re.M)

zh_pat = set(m.group(1) for m in PAT_KEY.finditer(zh))
hant_pat = set(m.group(1) for m in PAT_KEY.finditer(hant))
print(f'zh PAT_KEY: {len(zh_pat)}')
print(f'hant PAT_KEY: {len(hant_pat)}')

# Find keys in hant whose value is multiline (no closing quote on same line)
hant_lines = hant.splitlines()
multiline = []
for i, line in enumerate(hant_lines):
    if re.match(r'^  "[a-zA-Z][a-zA-Z0-9]+":', line) and line.rstrip().rstrip(',').count('"') == 2:
        # Has "key":  but no closing quote
        multiline.append((i+1, line))
print(f'多行 value 开始行数: {len(multiline)}')
for i, line in multiline[:5]:
    print(f'  line {i}: {line!r}')

# So this is expected -- some values are multiline
# Let me look for missing keys
missing = zh_pat - hant_pat
print(f'missing in hant (zh has, hant does not): {len(missing)}')
for k in sorted(missing)[:5]:
    print(f'  {k}')
