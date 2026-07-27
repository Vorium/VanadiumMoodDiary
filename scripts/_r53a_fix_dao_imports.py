"""v0.25 R53a: 修 7 DAO import 错误
- app_database.g.dart 是 part-of 文件,不能 import
- 改 import app_database.dart (主库 re-export 类型)
- 加 import 'package:drift/drift.dart' (OrderingTerm / OrderingMode / isBiggerOrEqualValue)
"""
import re
import sys
from pathlib import Path

ROOT = Path(r'D:\Batch\chroniccare\lib\core\data\database\daos')

fixed = 0
for p in ROOT.glob('*_dao.dart'):
    src = p.read_text(encoding='utf-8')
    orig = src
    # 1) 改 import '...app_database.g.dart' show ... → import 'app_database.dart'
    src = re.sub(
        r"import 'package:chroniccare/core/data/database/app_database\.g\.dart'\s*show\s+([^;]+);",
        lambda m: f"import 'package:chroniccare/core/data/database/app_database.dart';\nimport 'package:chroniccare/core/data/database/app_database.g.dart' show {m.group(1)};",
        src,
    )
    # 2) 如果没 import drift, 加 (看是否有 OrderingTerm 引用)
    if 'OrderingTerm' in src and "import 'package:drift/drift.dart';" not in src:
        # 在 import app_database 之后插入
        src = src.replace(
            "import 'package:chroniccare/core/data/database/app_database.dart';\n",
            "import 'package:chroniccare/core/data/database/app_database.dart';\nimport 'package:drift/drift.dart';\n",
            1,
        )
    if src != orig:
        p.write_text(src, encoding='utf-8')
        fixed += 1
        print(f'  fixed: {p.name}')

print(f'\n=== Fixed {fixed} DAO files ===')
