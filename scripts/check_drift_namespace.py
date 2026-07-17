"""v0.17 round 14 (P3-5): drift namespace 冲突检查

drift 在每张 table 上 @DataClassName('X') 生成单数类名 + XCompanion。
如果两个 table 用同一个 @DataClassName, drift gen 会冲突, build_runner 报错。

这个脚本是预防性检查 — 在跑 build_runner 之前先扫 lib/ 下的
@DataClassName(...) 注解,确认每个名字在 app 里唯一。

用法:
  python scripts/check_drift_namespace.py            # 默认扫描 lib/core/data/database/tables/
  python scripts/check_drift_namespace.py --strict   # 失败时 exit code 1
"""
import os
import re
import sys
from collections import Counter

ROOT = os.getcwd()
# Default tables dir relative to cwd; can be overridden by --tables-dir
# for greenfield / monorepo scenarios.
DEFAULT_DIR = os.path.join(ROOT, "lib", "core", "data", "database", "tables")


def _resolve_target() -> str:
    for arg in sys.argv[1:]:
        if arg.startswith("--tables-dir="):
            return os.path.join(ROOT, arg.split("=", 1)[1])
    return DEFAULT_DIR
ANNOTATION_RE = re.compile(r"@DataClassName\(\s*['\"]([^'\"]+)['\"]\s*\)")


def main() -> int:
    strict = "--strict" in sys.argv
    target = _resolve_target()
    if not os.path.isdir(target):
        print(f"[OK] {target} does not exist yet — nothing to check")
        return 0

    class_names: list[str] = []
    for root, _, files in os.walk(target):
        for f in files:
            if not f.endswith(".dart") or f.endswith(".g.dart"):
                continue
            full = os.path.join(root, f)
            with open(full, encoding="utf-8") as fp:
                content = fp.read()
            for m in ANNOTATION_RE.finditer(content):
                class_names.append(m.group(1))

    counts = Counter(class_names)
    duplicates = {name: c for name, c in counts.items() if c > 1}
    total_files = sum(1 for _, _, fs in os.walk(target) for f in fs if f.endswith(".dart") and not f.endswith(".g.dart"))

    if duplicates:
        print(f"[FAIL] {len(duplicates)} @DataClassName duplicates in {target}:")
        for name, c in duplicates.items():
            print(f"  {name}: {c} occurrences")
        return 1 if strict else 0

    print(
        f"[OK] check_drift_namespace: {total_files} table files, "
        f"{len(class_names)} @DataClassName annotations, 0 duplicates"
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
