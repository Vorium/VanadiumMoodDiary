"""v0.17 round 12: check_cross_feature.py — 跨 feature import 检查

规则:
  - presentation/pages/{feature}/ 不能 import 别的 feature 的 presentation/pages/
  - hub features (home, settings) 是例外,可以 import 任何 feature
  - 允许跨 feature import 的目录:
    - core/ (共享层)
    - domain/ (entity 跨 feature 共享,layer-first 设计)
    - data/ (data layer 跨 feature 共享,repository 注入)
    - presentation/providers/ (Riverpod 跨 feature 共享 provider)
    - presentation/widgets/ (通用 widget)

用法:
  python scripts/check_cross_feature.py              # 全检
  python scripts/check_cross_feature.py --staged    # 只检 staged files
  python scripts/check_cross_feature.py --ci        # CI 模式,exit code 1 if violation
"""
import os
import re
import sys

ROOT = os.getcwd()
LIB = os.path.join(ROOT, "lib")
PAGES = os.path.join(LIB, "presentation", "pages")
IMPORT_RE = re.compile(
    r'''^\s*import\s+['"]([^'"]+)['"]''',
    re.MULTILINE,
)

# Hub features: 主页 + 设置,可以 import 任何 feature
HUB_FEATURES = {"home", "settings"}

# 跨 feature import 允许的目录 (package:chroniccare/... 前缀)
ALLOWED_CROSS_FEATURE_PREFIXES = (
    "package:chroniccare/core/",
    "package:chroniccare/domain/",
    "package:chroniccare/data/",
    "package:chroniccare/presentation/providers/",
    "package:chroniccare/presentation/widgets/",
)


def get_feature(path: str) -> str | None:
    """从 lib/presentation/pages/{feature}/foo.dart 路径提取 feature 名"""
    rel = os.path.relpath(path, PAGES)
    parts = rel.split(os.sep)
    if not parts:
        return None
    first = parts[0]
    # 如果是文件,第一段是 feature 名
    # 如果是子目录 (e.g. widgets/), parts[0] 是 feature, parts[1] 是 'widgets'
    return first


def is_cross_feature_import(source_feature: str, import_path: str) -> bool:
    """判断一个 import 是否是跨 feature 的 presentation import"""
    # 不是 package:chroniccare/... 跳过 (dart: / 第三方)
    if not import_path.startswith("package:chroniccare/"):
        return False
    # 不在 presentation/pages/ 下,跳过 (已通过 ALLOWED 检查)
    if not import_path.startswith("package:chroniccare/presentation/pages/"):
        return False
    # 提取 imported feature
    # 格式: package:chroniccare/presentation/pages/{feature}/...
    m = re.match(r"package:chroniccare/presentation/pages/(\w+)/", import_path)
    if not m:
        return False
    imported_feature = m.group(1)
    # 同 feature,不算跨
    if imported_feature == source_feature:
        return False
    # hub 可以 import 任何 feature
    if source_feature in HUB_FEATURES:
        return False
    # 否则就是跨 feature (且 source 不是 hub)
    return True


def check_file(path: str) -> list[tuple[int, str]]:
    """检查单个文件,返回 violations 列表 [(line_number, import_path), ...]"""
    if not path.startswith(PAGES):
        return []
    feature = get_feature(path)
    if feature is None:
        return []
    try:
        with open(path, encoding="utf-8", newline="") as f:
            content = f.read()
    except Exception:
        return []
    violations = []
    for i, m in enumerate(IMPORT_RE.finditer(content)):
        import_path = m.group(1)
        if is_cross_feature_import(feature, import_path):
            # 算行号
            line_num = content[:m.start()].count("\n") + 1
            violations.append((line_num, import_path))
    return violations


def main():
    ci_mode = "--ci" in sys.argv
    staged_only = "--staged" in sys.argv

    files_to_check = []
    if staged_only:
        import subprocess
        r = subprocess.run(
            ["git", "diff", "--cached", "--name-only", "--diff-filter=AM"],
            capture_output=True, text=True, encoding="utf-8"
        )
        for line in r.stdout.strip().split("\n"):
            if line.endswith(".dart") and not line.endswith(".g.dart"):
                full = os.path.join(ROOT, line.replace("/", os.sep))
                if os.path.exists(full):
                    files_to_check.append(full)
    else:
        for root, _, files in os.walk(PAGES):
            for f in files:
                if f.endswith(".dart") and not f.endswith(".g.dart"):
                    files_to_check.append(os.path.join(root, f))

    total_violations = 0
    for path in sorted(files_to_check):
        violations = check_file(path)
        if violations:
            rel = os.path.relpath(path, ROOT)
            for line_num, import_path in violations:
                print(f"  [X] {rel}:{line_num}: {import_path}")
                total_violations += 1

    if total_violations == 0:
        print(f"[OK] check_cross_feature: {len(files_to_check)} files checked, 0 violations")
        sys.exit(0)
    else:
        print(f"\n[FAIL] {total_violations} cross-feature import violations found")
        print(f"   Hubs (allowed to import all): {', '.join(sorted(HUB_FEATURES))}")
        print(f"   Allowed cross-feature dirs: core/ domain/ data/ presentation/providers/ presentation/widgets/")
        if ci_mode:
            sys.exit(1)
        else:
            sys.exit(0)  # 默认非 CI 模式,方便 dev 看


if __name__ == "__main__":
    main()
