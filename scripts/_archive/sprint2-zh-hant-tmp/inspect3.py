"""Count double-quote bug."""
import re

hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

# Find lines starting with "  ""key" (double quote bug)
lines = hant.splitlines()
bug_lines = []
for i, l in enumerate(lines):
    if re.match(r'^\s*""[a-zA-Z][a-zA-Z0-9]+":', l):
        bug_lines.append((i+1, l))

print(f'Bug lines: {len(bug_lines)}')
for i, l in bug_lines[:5]:
    print(f'  line {i}: {l!r}')
