"""v0.17 round 9: 8a redo — shared layer → lib/core/"""
import os
import re
import shutil
import sys

ROOT = os.getcwd()
LIB = os.path.join(ROOT, "lib")
TEST = os.path.join(ROOT, "test")
CORE = os.path.join(LIB, "core")
DRY_RUN = "--dry-run" in sys.argv

SHARED_DIRS = ["data", "theme", "l10n", "shared", "routing"]
SKIP_FILES = {os.path.join(TEST, "scripts", "check_all_test.dart")}
IMPORT_RE = re.compile(
    r'''^\s*(import|export|part)\s+['"]([^'"]+)['"]''',
    re.MULTILINE,
)


def is_third_party_or_internal(uri):
    if uri.startswith("dart:"):
        return True
    if uri.startswith("package:") and not uri.startswith("package:chroniccare/"):
        return True
    return False


def is_chroniccare_absolute(uri):
    return uri.startswith("package:chroniccare/")


def needs_prefix_update(uri):
    if not is_chroniccare_absolute(uri):
        return False
    for d in SHARED_DIRS:
        if uri == f"package:chroniccare/{d}" or uri.startswith(f"package:chroniccare/{d}/"):
            return True
    return False


def update_absolute_uri(uri):
    for d in SHARED_DIRS:
        prefix = f"package:chroniccare/{d}"
        if uri == prefix:
            return f"package:chroniccare/core/{d}"
        if uri.startswith(prefix + "/"):
            return f"package:chroniccare/core/{d}/" + uri[len(prefix) + 1:]
    return uri


def resolve_relative(from_file, rel):
    from_dir = os.path.dirname(from_file)
    return os.path.normpath(os.path.join(from_dir, rel.replace("/", os.sep)))


def to_package_uri(abs_path):
    return f"package:chroniccare/{os.path.relpath(abs_path, LIB).replace(os.sep, '/')}"


def process_file(path):
    if path in SKIP_FILES:
        return (False, 0)
    with open(path, encoding="utf-8", newline="") as f:
        content = f.read()
    new_content = content
    count = 0
    for m in IMPORT_RE.finditer(content):
        uri = m.group(2)
        if needs_prefix_update(uri):
            new_uri = update_absolute_uri(uri)
            if new_uri != uri:
                old_full = m.group(0)
                new_full = old_full.replace(uri, new_uri)
                new_content = new_content.replace(old_full, new_full, 1)
                count += 1
            continue
        if is_third_party_or_internal(uri) or is_chroniccare_absolute(uri):
            continue
        try:
            abs_target = resolve_relative(path, uri)
        except Exception as e:
            print(f"  WARN: {path} 内 {uri} 解析失败: {e}")
            continue
        if not abs_target.startswith(LIB):
            if uri.startswith("../"):
                alt_uri = uri[3:]
                alt_target = resolve_relative(path, alt_uri)
                if alt_target.startswith(LIB) and os.path.exists(alt_target):
                    abs_target = alt_target
                else:
                    print(f"  WARN: {path} 内 {uri} 解析到 {abs_target} (lib 外, alt {alt_target} 也不存在), skip")
                    continue
            else:
                print(f"  WARN: {path} 内 {uri} 解析到 {abs_target} (lib 外), skip")
                continue
        if not os.path.exists(abs_target):
            if not abs_target.endswith(".g.dart"):
                print(f"  WARN: {path} 内 {uri} 解析到 {abs_target} 不存在")
            continue
        new_uri = to_package_uri(abs_target)
        # Bug 9 修复: 相对路径解析到的目标如果在 moved 目录里,也要加 core/ 前缀
        if needs_prefix_update(new_uri):
            new_uri = update_absolute_uri(new_uri)
        old_full = m.group(0)
        new_full = old_full.replace(uri, new_uri)
        new_content = new_content.replace(old_full, new_full, 1)
        count += 1
    if count > 0 and not DRY_RUN:
        with open(path, "w", encoding="utf-8", newline="") as f:
            f.write(new_content)
    return (count > 0, count)


def do_imports():
    total_files = 0
    total_imports = 0
    for scan_dir in (LIB, TEST):
        if not os.path.isdir(scan_dir):
            continue
        for root, _, files in os.walk(scan_dir):
            for f in files:
                if not f.endswith(".dart") or f.endswith(".g.dart"):
                    continue
                path = os.path.join(root, f)
                changed, n = process_file(path)
                if changed:
                    total_files += 1
                    total_imports += n
                    print(f"  {n:2d}  {os.path.relpath(path, ROOT)}")
    return total_files, total_imports


def do_move():
    if os.path.isdir(CORE):
        existing = [d for d in SHARED_DIRS if os.path.isdir(os.path.join(CORE, d))]
        if existing:
            print(f"  !! ABORT: {CORE} 已存在")
            sys.exit(1)
        os.rmdir(CORE)
    for d in SHARED_DIRS:
        if not os.path.isdir(os.path.join(LIB, d)):
            print(f"  !! ABORT: lib/{d}/ 不存在")
            sys.exit(1)
    if not DRY_RUN:
        os.makedirs(CORE)
    moved = 0
    for d in SHARED_DIRS:
        src = os.path.join(LIB, d)
        dst = os.path.join(CORE, d)
        if not DRY_RUN:
            shutil.move(src, dst)
        print(f"  moved: lib/{d}/ → lib/core/{d}/")
        moved += 1
    return moved


def main():
    print(f"ROOT: {ROOT}  DRY_RUN: {DRY_RUN}\n")
    print("Step 1: 重写 import")
    files_changed, imports_changed = do_imports()
    print(f"  Total: {files_changed} files, {imports_changed} imports\n")
    print("Step 2: 搬目录")
    moved = do_move()
    print(f"\n=== Summary ===")
    print(f"Dirs moved: {moved}  Files updated: {files_changed}  Imports rewritten: {imports_changed}")
    if DRY_RUN:
        print(f"\n[DRY RUN] 加 --dry-run 不写文件")


if __name__ == "__main__":
    main()
