#!/usr/bin/env python3
# R127 stage3 (1.1.0+180): 批量生成 re-export 兼容层
#
# 跟 R126 续 step 4-7 (1.1.0+176~179) 模式一致: 旧 path 1 行 re-export
# 保持现有用户 0 改动。R127 拆包后 lib/<old>/file.dart = 1 行 re-export
# 指向 packages/<package>/lib/src/<new>/file.dart。
#
# 范围:
#   - lib/core/ (135 file) → packages/chroniccare_core/lib/src/core/
#   - lib/domain/ (92 file) → packages/chroniccare_core/lib/src/domain/
#   - lib/features/mood/ (37 file) → packages/chroniccare_features_mood/lib/src/
#
# 用法:
#   python scripts/_r127_generate_reexports.py
#
# 退出码: 0 = 成功, 1 = 错误

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PACKAGES = ROOT / "packages"
LIB = ROOT / "lib"

# (旧 path prefix, 新 package name, 新 path prefix in package)
MIGRATIONS = [
    ("lib/core", "chroniccare_core", "core"),
    ("lib/domain", "chroniccare_core", "domain"),
    ("lib/features/mood", "chroniccare_features_mood", ""),  # mood 直接在 lib/src/ 下, 不加 prefix
]

REEXPORT_TEMPLATE = """/// **R127 stage3 (1.1.0+180)**: 实际定义已迁到
/// `package:{package_name}/{import_path}`。
/// 本文件 re-export 保持旧 import path 兼容 (现有用户 0 改动)。
library;

export 'package:{package_name}/{import_path}';
"""


def generate_reexports():
    """为每个迁走的 .dart file 生成 1 行 re-export"""
    created = 0
    skipped = 0
    for old_root, package_name, new_prefix in MIGRATIONS:
        # 找实际定义 (在 packages/*/lib/src/...)
        if new_prefix:
            new_root = PACKAGES / package_name / "lib" / "src" / new_prefix
        else:
            new_root = PACKAGES / package_name / "lib" / "src"
        if not new_root.exists():
            print(f"⚠️  source not found: {new_root}")
            continue
        old_root_abs = ROOT / old_root
        if not old_root_abs.exists():
            old_root_abs.mkdir(parents=True, exist_ok=True)
        # 遍历所有 .dart file (排除 codegen)
        for src_file in sorted(new_root.rglob("*.dart")):
            if any(src_file.name.endswith(s) for s in (".g.dart", ".freezed.dart", ".mocks.dart")):
                skipped += 1
                continue
            # 计算相对路径 (相对 new_root)
            rel = src_file.relative_to(new_root)
            # 旧 path = old_root/rel
            old_file = old_root_abs / rel
            # 旧 file 已被 git mv 走, 现在需要创建新空 file
            old_file.parent.mkdir(parents=True, exist_ok=True)
            # 计算 package import path
            if new_prefix:
                import_path = f"src/{new_prefix}/{rel.as_posix()}"
            else:
                import_path = f"src/{rel.as_posix()}"
            # 生成 re-export 内容
            content = REEXPORT_TEMPLATE.format(
                package_name=package_name,
                import_path=import_path,
            )
            old_file.write_text(content, encoding="utf-8")
            created += 1
    return created, skipped


def main():
    created, skipped = generate_reexports()
    print(f"✅ re-export 兼容层生成完成: {created} 个 file 创建, {skipped} 个 codegen 跳过")
    return 0


if __name__ == "__main__":
    sys.exit(main())
