"""删 7 DAO 的 .g.dart import (part-of, 主库已暴露类型)"""
import re
from pathlib import Path

ROOT = Path(r'D:\Batch\chroniccare/lib\core/daos' if False else r'D:\Batch\chroniccare/lib\core/data/database/daos')

for p in ROOT.glob('*_dao.dart'):
    src = p.read_text(encoding='utf-8')
    orig = src
    # 删 `import '...app_database.g.dart' show ...;` 整行
    new = re.sub(
        r"^import 'package:chroniccare/core/data/database/app_database\.g\.dart'\s*show[^;]*;\n",
        '',
        src,
        flags=re.MULTILINE,
    )
    if new != orig:
        p.write_text(new, encoding='utf-8')
        print(f'  fixed: {p.name}')
print('done')
