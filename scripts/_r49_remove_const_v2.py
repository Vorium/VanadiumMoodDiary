"""v2: 行内 const 关键字移除（处理 leading: const Icon / icon: const Icon 模式）"""
import re
import sys
from pathlib import Path

ROOT = Path(r'D:\Batch\chroniccare\lib')

# 匹配: 行内任意位置，前面是 `:` `,` `(` 或空白，后面是大写 ConstructorName( 且括号内含 AppTokens.xxxColor(context)
pattern = re.compile(
    r'(?:[:,(\s])const\s+(?=[A-Z][A-Za-z0-9<>_]*\([^)]*?AppTokens\.(?:primary|error|warning)Color\(context\))',
)

fixed_files = 0
fixed_count = 0
for p in ROOT.rglob('*.dart'):
    src = p.read_text(encoding='utf-8')
    new_src, n = pattern.subn('', src)
    if n > 0:
        p.write_text(new_src, encoding='utf-8')
        fixed_files += 1
        fixed_count += n
        print(f'  {p.relative_to(ROOT.parent)}: {n} const removals')

print(f'\n=== Fixed {fixed_count} inline const occurrences in {fixed_files} files ===')
