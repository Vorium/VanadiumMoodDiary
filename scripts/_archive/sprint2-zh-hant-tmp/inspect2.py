"""Find assessmentAnsweredProgress in hant."""
import re

hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()
lines = hant.splitlines()
target = 'assessmentAnsweredProgress'
for i, l in enumerate(lines):
    if target in l:
        print(f'{target} @ line {i+1}: {l!r}')
        for j in range(max(0, i-1), min(len(lines), i+4)):
            print(f'  line {j+1}: {lines[j]!r}')
        print('---')
        break

# All keys that are 'lost' (i.e. not found in hant with standard pattern)
# The reason might be that my fix_punct_align.py / fix_zh_hant_polish.py
# emitted the value with the closing quote but failed to consume
# rest of the line.
# Let me grep "assessmentAnsweredProgress" with rg
print('=== rg for assessmentAnsweredProgress ===')
import subprocess
res = subprocess.run(['rg', '-n', 'assessmentAnsweredProgress', r'lib/l10n/app_zh_Hant.arb'], capture_output=True, text=True)
print(res.stdout)
print(res.stderr)
