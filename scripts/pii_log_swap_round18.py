"""把 piiSafeLog('msg', name: 'X') 转成 piiSafeLog('X', 'msg')"""
import re
import sys
from pathlib import Path

ROOT = Path("lib/core/data/services")
FILES = list(ROOT.glob("*.dart")) + [Path("lib/core/data/services/notification_navigation.dart")]


def fix_file(path: Path) -> int:
    src = path.read_text(encoding="utf-8")
    # piiSafeLog('msg', name: 'X', ...) → piiSafeLog('X', 'msg', ...)
    # 多行匹配
    pattern = re.compile(
        r"piiSafeLog\(\s*((?:'[^']*'|\"[^']*\"|\\$\\{[^}]*\\})*?),(\s*name:\s*'([^']+)')(,?)",
        re.MULTILINE | re.DOTALL,
    )

    def repl(m):
        msg = m.group(1)
        name_with_colon = m.group(2)
        name = m.group(3)
        trailing_comma = m.group(4) or ""
        return f"piiSafeLog('{name}', {msg}{trailing_comma}"

    new_src, count = pattern.subn(repl, src)
    if count > 0:
        path.write_text(new_src, encoding="utf-8")
    return count


total = 0
for f in FILES:
    if not f.exists():
        continue
    n = fix_file(f)
    if n > 0:
        print(f"  {n:3d} swaps: {f}")
        total += n
print(f"\nTotal: {total} swaps")
