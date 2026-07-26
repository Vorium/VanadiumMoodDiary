"""
v0.25 round 49: dark mode 颜色 token 化

emil P0 #1: 60+ 处 `color: AppTokens.{primary|error|warning}` 裸用 → dark mode
silent bug。已加 3 个 dynamic getter (`primaryColor(context)` / `errorColor(context)` /
`warningColor(context)`), 此脚本批量替换。

负向 lookahead 防止误改 (AppTokens.primaryContainer / AppTokens.primaryColor 等)
"""
import re
import sys
from pathlib import Path
from collections import defaultdict

ROOT = Path(r'D:\Batch\chroniccare\lib')

# 替换规则: token 名 → dynamic getter 后缀
TOKENS = {
    'primary': 'primaryColor(context)',
    'error': 'errorColor(context)',
    'warning': 'warningColor(context)',
}

# 跳过: 定义文件 / doc 注释包含示例
SKIP = {
    'lib/core/theme/app_tokens.dart',
    'lib/core/theme/app_theme.dart',
    'lib/presentation/widgets/app_list_tile.dart',  # :26 doc 注释示例
}

# AppTokens 内部不动的 getter 命名空间（防止 lookahead 漏判）
PRESERVE_SUFFIX = (
    'Color', 'Light', 'Dark', 'Container', 'Soft', 'Deep', 'LightD',
    'Mid', 'High', 'Border', 'Strong', 'Muted', 'Failed',
)

changes_per_file: dict[str, list[tuple[int, str, str]]] = defaultdict(list)
total = 0

for p in ROOT.rglob('*.dart'):
    rel = str(p.relative_to(ROOT.parent)).replace('\\', '/')
    if rel in SKIP:
        continue
    src = p.read_text(encoding='utf-8')
    new = src
    for token, getter_suffix in TOKENS.items():
        # 匹配 `AppTokens.{token}` 后面不是 [a-zA-Z0-9_(] 的（避免误改 primaryColor 等）
        pattern = r'\bAppTokens\.' + token + r'\b(?![A-Za-z0-9_(])'
        new = re.sub(pattern, 'AppTokens.' + getter_suffix, new)
    if new != src:
        old_lines = src.splitlines()
        new_lines = new.splitlines()
        for i, (old_line, new_line) in enumerate(zip(old_lines, new_lines), 1):
            if old_line != new_line:
                changes_per_file[rel].append((i, old_line, new_line))
        p.write_text(new, encoding='utf-8')
        total += len(changes_per_file[rel])

# 报告
for f in sorted(changes_per_file.keys()):
    print(f'\n{f}  ({len(changes_per_file[f])} changes)')
    for i, old, new in changes_per_file[f]:
        old_short = old.strip()[:100]
        new_short = new.strip()[:100]
        print(f'  L{i}: {old_short}')
        print(f'    -> {new_short}')

print(f'\n=== Total: {total} replacements in {len(changes_per_file)} files ===')
sys.exit(0)
