#!/usr/bin/env python3
# v1.1.0+171 R125 (R110 feature-first 阶段 1) — feature-first 迁移守门员
#
# 背景 (R110 路线图 + R125 阶段 1 样板):
# - R0.18 round 12 起 4 层架构 + 共享层 (R110 起点)
# - R110 阶段 1: 5 阶段 feature-first 重构, 1-2 周完成 5+ feature 迁移
# - 阶段 1 (本批): 1 子表样板 (daily_tracking/anxiety_agitation) 端到端
#   验证 feature 目录结构 + 跨 feature import 边界
# - 阶段 2+ (R126+): 5+ feature 完整迁移 + pub workspace 拆分
#
# 守门员 (分阶段启用):
# 阶段 1 (本批必过):
#   - lib/features/ 目录存在
#   - 至少 1 个 feature 子目录有 data/ domain/ presentation/ 3 子目录
#   - feature 子目录内 file 不引用 package:chroniccare/features/其他 feature/
#   - feature 子目录内 file 不引用 package:chroniccare/core/data/database/ (drift 共享限制, 阶段 3 处理)
# 阶段 2+ (R126 启用):
#   - 5+ feature 完整迁移
#   - 旧路径 (lib/core/data/ + lib/domain/) 删旧 file
# 阶段 3+ (R127 启用):
#   - packages/chroniccare_*/ 3 pub workspace
#   - pubspec.yaml 互依赖正确
#   - 编译依赖 < 40% (跟 baseline 对比)
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FEATURES_DIR = ROOT / "lib" / "features"
CORE_DIR = ROOT / "lib" / "core"
DOMAIN_DIR = ROOT / "lib" / "domain"

# 已知阶段 1 样板 feature (R125 验证)
PHASE1_SAMPLE_FEATURE = "daily_tracking"


def find_feature_dirs() -> list[Path]:
    """找 lib/features/ 下所有 feature 子目录"""
    if not FEATURES_DIR.exists():
        return []
    return [d for d in FEATURES_DIR.iterdir() if d.is_dir()]


def find_dart_files(feature_dir: Path) -> list[Path]:
    """找 feature_dir 下所有 .dart file"""
    return list(feature_dir.rglob("*.dart"))


def check_cross_feature_imports(feature_dir: Path) -> list[str]:
    """检查 feature_dir 内 file 是否引用其他 feature

    R110 阶段 1 gate: feature 不能 import 其他 feature (跨 feature 边界)
    跨 feature 共享走 core/ 抽公共 (阶段 4)
    """
    violations = []
    for f in find_dart_files(feature_dir):
        content = f.read_text(encoding='utf-8')
        # 找 import 'package:chroniccare/features/XXX/...' 但 XXX != 当前 feature
        for m in re.finditer(
            r"import\s+'package:chroniccare/features/(\w+)/",
            content,
        ):
            imported = m.group(1)
            if imported != feature_dir.name:
                violations.append(
                    f"{f.relative_to(ROOT)}: 跨 feature import '{imported}' "
                    f"(R110 阶段 1 gate: feature 内不能 import 其他 feature)"
                )
    return violations


def check_core_data_imports(feature_dir: Path) -> list[str]:
    """检查 feature_dir 内 file 是否引用 core/data/database (drift 共享限制)"""
    violations = []
    for f in find_dart_files(feature_dir):
        content = f.read_text(encoding='utf-8')
        # R110 阶段 1 接受 core/data/services 跟 core/shared (drift table 共享限制, 阶段 3 拆 workspace)
        # 但 core/data/database 跨包共享不可, 应该走 feature 内 table
        for m in re.finditer(
            r"import\s+'package:chroniccare/core/data/database/tables/(\w+)",
            content,
        ):
            violations.append(
                f"{f.relative_to(ROOT)}: 跨包引用 core/data/database/tables/{m.group(1)} "
                f"(R110 阶段 1: feature 内应该用 features/{feature_dir.name}/data/tables/ 引用)"
            )
    return violations


def check_feature_structure(feature_dir: Path) -> list[str]:
    """检查 feature_dir 是否有 data/ domain/ presentation/ 3 子目录 (R110 阶段 1 必过)"""
    violations = []
    required_subdirs = ["data", "domain", "presentation"]
    for sub in required_subdirs:
        sub_path = feature_dir / sub
        if not sub_path.exists() or not sub_path.is_dir():
            violations.append(
                f"feature {feature_dir.name} 缺 {sub}/ 子目录 "
                f"(R110 阶段 1 gate: data/ domain/ presentation/ 三层)"
            )
    return violations


def main() -> int:
    exit_code = 0
    phase1_violations: list[str] = []
    phase2_warnings: list[str] = []

    # 1. features/ 目录存在
    if not FEATURES_DIR.exists():
        phase1_violations.append(
            f"lib/features/ 目录不存在 (R110 阶段 1 应有 features/ 顶层目录)"
        )
        print(f"[FAIL] {phase1_violations[-1]}")
        return 1

    # 2. 找所有 feature 子目录
    feature_dirs = find_feature_dirs()
    if not feature_dirs:
        phase1_violations.append(
            f"lib/features/ 目录无 feature 子目录 "
            f"(R110 阶段 1 必过: 至少 1 个 feature)"
        )

    # 3. 检查每个 feature 结构
    for fd in feature_dirs:
        # 3a. feature 目录结构 (data/domain/presentation)
        structure_violations = check_feature_structure(fd)
        phase1_violations.extend(structure_violations)

        # 3b. 跨 feature import 边界
        cross_feature_violations = check_cross_feature_imports(fd)
        phase1_violations.extend(cross_feature_violations)

        # 3c. core/data/database 跨包引用
        core_data_violations = check_core_data_imports(fd)
        phase1_violations.extend(core_data_violations)

    # 4. 阶段 2 警告 (R126+ 启用)
    if len(feature_dirs) < 5:
        phase2_warnings.append(
            f"features/ 仅 {len(feature_dirs)} 个 feature (R110 阶段 2 必过 5+ feature)"
        )

    # 5. 阶段 3 警告 (R127+ 启用)
    packages_dir = ROOT / "packages"
    if not packages_dir.exists():
        phase2_warnings.append(
            f"packages/ 不存在 (R110 阶段 3 必过 pub workspace)"
        )

    # 输出
    if phase1_violations:
        exit_code = 1
        print(f"[FAIL] check_feature_first_migration 阶段 1: {len(phase1_violations)} 项违规")
        for v in phase1_violations:
            print(f"  - {v}")
    else:
        feature_names = [fd.name for fd in feature_dirs]
        print(
            f"[OK] check_feature_first_migration 阶段 1: {len(feature_dirs)} 个 feature ({', '.join(feature_names)}), "
            f"目录结构 + 跨 feature 边界 + drift 共享限制 全齐"
        )

    if phase2_warnings:
        print("[warn] check_feature_first_migration 阶段 2+ (R110 阶段 2+ 启用):")
        for w in phase2_warnings:
            print(f"  - {w}")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
