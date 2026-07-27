"""v0.25 R56: emil icon size 集中器
- size: 18 → AppTokens.iconSizeInline (24 处)
- size: 14 → AppTokens.iconSizeSmall (4 处)
- size: 64 → AppTokens.iconSizeEmpty (2 处)
- size: 56 → AppTokens.iconSizeError (2 处)

跳过 const constructor (const Icon 内的 size 仍可换, 因为 int 是 const
literal)
"""
import re
from pathlib import Path
from collections import defaultdict

ROOT = Path(r'D:\Batch\chroniccare\lib')

# 替换规则: size: N → AppTokens.<对应 token>
# 用 negative lookahead 防止误改 size: 180 / 14.0 / 24 等
SIZE_REPLACEMENTS = {
    18: 'AppTokens.iconSizeInline',
    14: 'AppTokens.iconSizeSmall',
    64: 'AppTokens.iconSizeEmpty',
    56: 'AppTokens.iconSizeError',
}

# 跳过 (iconSize=24 / 32 / 12 / 20 等已存在 token)
SKIP_FILES = {
    'lib/core/theme/app_tokens.dart',  # 定义文件
}

# 跳过 widget 中的 size 字段不是 icon size 情况 (无 — 都是 Icon.size)
# 但 report_history_dialog 等可能有 SizedBox(width/height: 18), 看 actual
# 我们 regex 用 `Icon(` + `size:` context 保险

changes_per_file: dict[str, list[tuple[int, str, str]]] = defaultdict(list)
total = 0

for p in ROOT.rglob('*.dart'):
    rel = str(p.relative_to(ROOT.parent))
    if rel in SKIP_FILES:
        continue
    src = p.read_text(encoding='utf-8')
    new = src
    for size, token in SIZE_REPLACEMENTS.items():
        # 匹配 `size: N,` 或 `size: N)` 或 `size: N)` 或 `size: N }`
        # N 后不能跟数字 (避免 180 / 140 / 64-bit)
        pattern = r'\bsize:\s*' + str(size) + r'\b(?!\d)'
        new = re.sub(pattern, f'size: {token}', new)
    if new != src:
        old_lines = src.splitlines()
        new_lines = new.splitlines()
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
