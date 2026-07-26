"""v0.25 R56b: emil spacing SizedBox 走 token
- SizedBox(width|height: 2)  → spacingXxxs
- SizedBox(width|height: 4)  → spacingXxs
- SizedBox(width|height: 6)  → spacingChipGap
- SizedBox(width|height: 8)  → spacingXs
- SizedBox(width|height: 16) → spacingSm
- SizedBox(width|height: 24) → spacingMd
- SizedBox(width|height: 40) → spacingLg
- SizedBox(width|height: 80) → spacingXl
- 32/48/56/64 不替换 (无对应 token, 跳过)
"""
import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(r'D:\Batch\chroniccare\lib\presentation')

REPLACEMENTS = {
    2: 'AppTokens.spacingXxxs',
    4: 'AppTokens.spacingXxs',
    6: 'AppTokens.spacingChipGap',
    8: 'AppTokens.spacingXs',
    16: 'AppTokens.spacingSm',
    24: 'AppTokens.spacingMd',
    40: 'AppTokens.spacingLg',
    80: 'AppTokens.spacingXl',
}

# 跳过 32/48/56/64 (emil 报告 4.4 未对应 token)
SKIP = {32, 48, 56, 64}

changes_per_file: dict[str, list[tuple[int, str, str]]] = defaultdict(list)
total = 0

for p in ROOT.rglob('*.dart'):
    src = p.read_text(encoding='utf-8')
    new = src
    for size, token in REPLACEMENTS.items():
        # 匹配 `SizedBox(width|height: SIZE,` 或 `SizedBox(width|height: SIZE)`
        # SIZE 后不能跟数字 (避免 2.0 / 80.0)
        pattern = r'(SizedBox\(\s*(?:width|height):\s*)' + str(size) + r'\b(?!\d|\.\d)'
        new = re.sub(pattern, rf'\g<1>{token}', new)
    if new != src:
        old_lines = src.splitlines()
        new_lines = new.splitlines()
        rel = str(p.relative_to(ROOT.parent))
        for i, (o, n) in enumerate(zip(old_lines, new_lines), 1):
            if o != n:
                changes_per_file[rel].append((i, o, n))
        p.write_text(new, encoding='utf-8')
        total += len(changes_per_file[rel])

for f in sorted(changes_per_file.keys()):
    print(f'\n{f}  ({len(changes_per_file[f])})')
    for i, o, n in changes_per_file[f][:3]:
        print(f'  L{i}: {o.strip()[:80]}')
        print(f'    -> {n.strip()[:80]}')
    if len(changes_per_file[f]) > 3:
        print(f'  ... and {len(changes_per_file[f]) - 3} more')

print(f'\n=== Total: {total} replacements in {len(changes_per_file)} files ===')
