"""Fix the double-quote bug introduced by fix_punct_align.py.

Bug pattern: `  ""key": "value",`  should be `  "key": "value",`

Cause: regex matched closing quote + comma in group 5, but I also appended `"` in f-string.
"""
import re

PATH = r'lib/l10n/app_zh_Hant.arb'

with open(PATH, encoding='utf-8') as f:
    text = f.read()

# Fix: '  ""key": "value",'  -> '  "key": "value",'
fixed = re.sub(
    r'^(  )""([a-zA-Z][a-zA-Z0-9]+)": "([^"]*)""(,?)$',
    r'\1"\2": "\3"\4',
    text,
    flags=re.M,
)

# Count
n = len(re.findall(r'^  ""[a-zA-Z][a-zA-Z0-9]+":', fixed, re.M))
print(f'Remaining bug lines: {n}')

with open(PATH, 'w', encoding='utf-8') as f:
    f.write(fixed)
print('Fixed')
