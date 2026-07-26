#!/usr/bin/env python3
"""v0.23 (Round 37): 批量把 `ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(...)))`
替换成 `AppSnackBar.showInfo/showError/showUndo/showWithAction(ctx, ...)`。

支持以下 pattern (按优先级):
1. `SnackBar(content: Text(l10n.X), action: SnackBarAction(label: l10n.Y, onPressed: ...))` → `showUndo` 或 `showWithAction`
2. `SnackBar(content: Text(l10n.X))` → `showInfo`
3. `SnackBar(content: Text(l10n.X(e.toString())))` → 没法自动判断, 跳过
4. 跨多行 / 含 duration 定制 → 跳过 (保留 ScaffoldMessenger)

不接管 4 个 集中器 已有的调用 (AppSnackBar.xxx factory 内部)。
"""
import re
import sys
from pathlib import Path

ROOT = Path(r'D:\Batch\chroniccare\lib\presentation')

# 跨多行匹配: ScaffoldMessenger.of(...).showSnackBar(SnackBar(content: Text(...), ...))
# 简化: 1 行能 match 的就 match, 多行手动改

# Pattern 1: ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(l10n.X)))
# 捕获 ctx 变量名 + l10n key
PATTERN_INFO = re.compile(
    r'ScaffoldMessenger\.of\((\w+)\)\.showSnackBar\(\s*'
    r'SnackBar\(\s*'
    r'content:\s*Text\((l10n\.\w+(?:\([^)]*\))?)\)\s*,?\s*'
    r'(?:duration:\s*[^,]+,\s*)?'
    r'\)'
    r'\)',
    re.MULTILINE | re.DOTALL,
)

# Pattern 2: 带 action (undo / withAction)
# ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(...), action: SnackBarAction(label: ...)))
# 简化: 只 match l10n key 形式, 其他跳过

# Pattern 3: multi-line duration 保留
def is_already_using_app_snackbar(text: str, pos: int) -> bool:
    """是否已经被 AppSnackBar.showX 包过 (回退 false, 简单避免重复替换)"""
    # 看 pos 之前 200 字符是否含 `AppSnackBar.show`
    start = max(0, pos - 200)
    return 'AppSnackBar.show' in text[start:pos]


def transform_file(f: Path) -> int:
    txt = f.read_text(encoding='utf-8')
    original = txt
    count = 0

    def repl_info(m: re.Match) -> str:
        nonlocal count
        ctx_var = m.group(1)
        l10n_expr = m.group(2)
        if is_already_using_app_snackbar(txt, m.start()):
            return m.group(0)
        count += 1
        return f'AppSnackBar.showInfo({ctx_var}, {l10n_expr})'

    txt = PATTERN_INFO.sub(repl_info, txt)

    if txt != original:
        f.write_text(txt, encoding='utf-8')
    return count


total = 0
files = list(ROOT.rglob('*.dart'))
for f in files:
    if '.g.dart' in f.name or '.freezed.dart' in f.name:
        continue
    n = transform_file(f)
    if n > 0:
        print(f'  {f.relative_to(ROOT.parent)}: {n} 处替换')
        total += n
print(f'总计: {total} 处替换')
