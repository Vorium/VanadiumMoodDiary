"""v0.17 round 8a v2: 把所有 .dart 文件的相对 import 转成 package: 绝对路径

逻辑:
1. 扫 lib/ 和 test/ 下所有 .dart
2. 解析 import 里的相对路径 (../)
3. 解析成 OS 绝对路径
4. 转成 package:chroniccare/<rel> 绝对路径
5. 跳过 .g.dart (生成文件,gitignore)
6. 跳过已经是 package: 绝对路径 / dart: 内部 / 第三方包

为什么:
- 8a 移完共享层后,大量相对路径深度变了 (lib/data/services/... → lib/core/... 之类)
- 手动维护 mapping 容易错 (e.g. `'../presentation/'` 没改,因为 presentation 还在 lib/ 下)
- package: 绝对路径 100% 正确,不依赖文件位置
- 项目已有混用 (v0.16 之前大部分用 package:,最近 8a 引入了相对路径 bug)
"""
import os
import re

ROOT = os.getcwd()
LIB = os.path.join(ROOT, "lib")
TEST = os.path.join(ROOT, "test")

# 匹配 import 'X' 或 import "X"
IMPORT_RE = re.compile(r'''^\s*import\s+['"]([^'"]+)['"]''', re.MULTILINE)

def to_package_uri(abs_path: str) -> str:
    """OS 绝对路径 → package:chroniccare/<rel>"""
    rel = os.path.relpath(abs_path, LIB).replace(os.sep, "/")
    return f"package:chroniccare/{rel}"

def resolve_relative(from_file: str, rel: str) -> str:
    """from_file 内 import 'rel' 解析为 OS 绝对路径"""
    from_dir = os.path.dirname(from_file)
    # import 路径用 /,先转 OS
    rel_os = rel.replace("/", os.sep)
    return os.path.normpath(os.path.join(from_dir, rel_os))

def is_third_party(uri: str) -> bool:
    """判断是不是第三方包 / dart: 内部"""
    if uri.startswith("dart:"):
        return True
    if uri.startswith("package:") and not uri.startswith("package:chroniccare/"):
        return True
    return False

def should_skip(uri: str) -> bool:
    """跳过绝对路径 / dart: / 第三方包"""
    if uri.startswith("package:"):
        return True  # 已经是 package: 绝对路径
    if uri.startswith("dart:"):
        return True
    if not "/" in uri:
        return True  # 单段 import 不可能相对
    return False

def process_file(path: str) -> tuple[bool, int]:
    """处理单个文件,返回 (是否改动, 改了几处)"""
    with open(path, encoding="utf-8") as f:
        content = f.read()
    new_content = content
    count = 0
    for m in IMPORT_RE.finditer(content):
        uri = m.group(1)
        if should_skip(uri):
            continue
        # 相对路径 — 解析成绝对
        try:
            abs_target = resolve_relative(path, uri)
        except Exception:
            continue
        # 必须在 lib/ 下 (project 内部)
        if not abs_target.startswith(LIB):
            # 引用了 lib/ 外的文件 (一般是 .g.dart 或不存在的路径) — 跳过
            continue
        new_uri = to_package_uri(abs_target)
        # 替换 (注意: '或" 都得考虑)
        old_full = m.group(0)
        new_full = old_full.replace(uri, new_uri)
        new_content = new_content.replace(old_full, new_full, 1)
        count += 1
    if count > 0:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
    return (count > 0, count)

total_files = 0
total_imports = 0
for scan_dir in (LIB, TEST):
    if not os.path.isdir(scan_dir):
        continue
    for root, _, files in os.walk(scan_dir):
        for f in files:
            if not f.endswith(".dart"):
                continue
            if f.endswith(".g.dart"):
                continue
            path = os.path.join(root, f)
            changed, n = process_file(path)
            if changed:
                total_files += 1
                total_imports += n
                print(f"  {n:2d}  {os.path.relpath(path, ROOT)}")

print(f"\nTotal: {total_files} files updated, {total_imports} imports rewritten")
