"""
v0.25 round 49 sub-task: 移除 const_eval_method_invocation 错误

emil R49 把 const Color 换成 dynamic getter 后, 20 处 `const Icon/Text/...`
里有 `AppTokens.{primary,error|warning}Color(context)`, analyzer 报
const_eval_method_invocation (const 表达式不能调 method)。

此脚本自动删 const 关键字 (单行模式)。
"""
import re
import sys
from pathlib import Path

ROOT = Path(r'D:\Batch\chroniccare\lib')

# 匹配: 行内有 `AppTokens.(primary|error|warning)Color(context)` 且行首
# 缩进后有 `const ConstructorName(`, 删 const 关键字 (保留缩进)
pattern = re.compile(
    r'^(\s*)const\s+(?=[A-Z][A-Za-z0-9<>_]*\([^)]*?AppTokens\.(?:primary|error|warning)Color\(context\))',
    re.MULTILINE,
)

fixed_files = 0
fixed_count = 0
for p in ROOT.rglob('*.dart'):
    src = p.read_text(encoding='utf-8')
    new_src, n = pattern.subn(r'\1', src)
    if n > 0:
        p.write_text(new_src, encoding='utf-8')
        fixed_files += 1
        fixed_count += n
        print(f'  {p.relative_to(ROOT.parent)}: {n} const removals')

print(f'\n=== Fixed {fixed_count} const occurrences in {fixed_files} files ===')
sys.exit(0)
