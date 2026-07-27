"""v0.25 R53a: 删 7 DAO 重复 import
"""
import re
from pathlib import Path
from collections import OrderedDict

ROOT = Path(r'D:\Batch\chroniccare/lib\core\data/database/daos')

for p in ROOT.glob('*_dao.dart'):
    src = p.read_text(encoding='utf-8')
    orig = src
    lines = src.splitlines(keepends=True)
    seen = set()
    new_lines = []
    for line in lines:
        stripped = line.strip()
        # 只对 import 行去重
        m = re.match(r"^(import\s+['\"][^'\"]+['\"];?)\s*$", stripped)
        if m:
            import_path = re.search(r"['\"]([^'\"]+)['\"]", m.group(1)).group(1)
            if import_path in seen:
                continue  # skip duplicate
            seen.add(import_path)
        new_lines.append(line)
    new = ''.join(new_lines)
    if new != orig:
        p.write_text(new, encoding='utf-8')
        print(f'  dedup: {p.name}')
print('done')
