"""v0.25 R59: 修 app_routes.dart 4 个 transitionsBuilder 的 _ 重复定义
- transitionsBuilder: (_, anim, _, child) → (_, anim, __, child)
- 唯一改 4 个 transition helper 函数
"""
import re
from pathlib import Path

p = Path(r'D:\Batch\chroniccare\lib\core\routing\app_routes.dart')
src = p.read_text(encoding='utf-8')
orig = src
# 把 `(_, anim, _,` 改成 `(_, anim, __,`
new = src.replace('transitionsBuilder: (_, anim, _, child)', 'transitionsBuilder: (_, anim, __, child)')
if new != orig:
    p.write_text(new, encoding='utf-8')
    print(f'fixed')
else:
    print('no change')
