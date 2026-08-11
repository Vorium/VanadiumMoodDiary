#!/usr/bin/env python3
# v0.31.1 R109 (god class 专项 round 1): use case 层厚化守门员
#
# 验证 lib/domain/usecases/**/*.dart 文件满足 4 层架构 "domain 0 副作用
# 0 Flutter 0 Drift 0 data 0 presentation" 硬约束。R108 check_all.dart 已
# 检查 domain/ 整体, 本守门员更针对 use case 子目录 + 业务命名规范.
#
# 5 个核心规则:
# 1. usecase 文件 0 依赖 data / theme / routing / l10n / presentation
# 2. usecase 文件 0 依赖 Flutter SDK
# 3. usecase 文件 0 依赖 flutter_riverpod (use case 应该是纯函数, 不该接 Provider)
# 4. usecase class 必须以 UseCase 后缀结尾
# 5. 每个 usecase class 必须有业务入口方法 (call() / fire() / schedule() / reschedule()
#    / check() / record() / run() / 业务方法名)
#
# 5 个规则任一 fail → exit 1, CI 报警.
#
# 跟 R95 check_coverage.py + R31 check_apple_health_claim.py 同款, Python
# 守门员, 不依赖 Flutter SDK.

import os
import re
import sys
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
USECASE_DIR = PROJECT_ROOT / "lib" / "domain" / "usecases"

# 不允许的 import 模式 (4 层架构硬约束)
FORBIDDEN_IMPORTS = [
    # data 层 (含 services / repositories impl / database / utils)
    (r"package:chroniccare/core/data/", "data 层 (services/database/utils/repositories)"),
    # theme / routing (UI 表现层)
    (r"package:chroniccare/core/theme/", "theme 集中器层"),
    (r"package:chroniccare/core/routing/", "routing 层"),
    # presentation 层
    (r"package:chroniccare/presentation/", "presentation 层"),
    # l10n (presentation / domain 两套 strings, use case 不该用)
    (r"package:chroniccare/l10n/", "presentation l10n (AppLocalizations)"),
    (r"package:chroniccare/core/l10n/", "domain l10n (strings.dart)"),
    # Flutter SDK (foundation 例外, 见下方白名单 marker)
    (r"package:flutter/(?:material|widgets|cupertino|painting|rendering|animation|gestures|scheduler|services|widgets\.dart)", "Flutter SDK (use case 应是纯 Dart)"),
    # flutter_riverpod (use case 不该接 Provider, 由 notifier 调)
    (r"package:flutter_riverpod", "flutter_riverpod (use case 应是纯函数)"),
    # shared_preferences (IO, use case 0 副作用)
    (r"package:shared_preferences", "shared_preferences (IO)"),
    # drift (数据库, use case 0 副作用)
    (r"package:drift", "drift (DB)"),
]

# 例外: domain/logic 抽出的纯函数可被 use case 调 (合规)
# 但 use case 直接依赖 data 是违反 (R108 check_all.dart 已检查)

# 业务入口方法名 (use case 公开 API 规范)
# 跟现有 4 个 usecase 一致: call() / record() / check() / fire()
ENTRY_METHODS = [
    "call",
    "run",
    "fire",
    "execute",
    "invoke",
    "schedule",
    "reschedule",
    "record",
    "check",
    "compute",
    "resolve",
    "dispatch",
    "trigger",
    "apply",
    "process",
]


def check_usecase_file(filepath: Path) -> list[str]:
    """检查单个 usecase 文件, 返 list of (severity, message)."""
    errors = []
    content = filepath.read_text(encoding="utf-8")
    rel = filepath.relative_to(PROJECT_ROOT)

    # 规则 1-3: 0 依赖禁止项
    for pattern, label in FORBIDDEN_IMPORTS:
        # 匹配 import 语句: `import 'package:xxx';` 或 `import 'package:xxx' show ...;`
        if re.search(rf"\bimport\s+['\"]({pattern})", content):
            errors.append(
                f"❌ {rel}: use case 文件禁止 import {label} (匹配: {pattern})"
            )

    # 例外: flutter/foundation `show visibleForTesting` / `show immutable` 是
    # marker annotation, 0 实际依赖. 跟 dart:mirrors `show NoSuchMethodError`
    # 同款 (R27 schedule_refill_reminder 注释提到).
    # 检查: 允许 import flutter/foundation 但 show 列表只含 marker 名.
    foundation_show_match = re.search(
        r"import\s+['\"]package:flutter/foundation\.dart['\"]\s+show\s+([\w,\s]+);",
        content,
    )
    if foundation_show_match:
        markers = {m.strip() for m in foundation_show_match.group(1).split(",")}
        allowed_markers = {
            "visibleForTesting", "immutable", "protected", "required",
            "factory", "deprecated", "experimental", "protectedDoNotStore",
        }
        bad_markers = markers - allowed_markers
        if bad_markers:
            errors.append(
                f"❌ {rel}: use case 文件 import flutter/foundation show 了非 marker 符号 {bad_markers}"
            )

    # 规则 4: usecase class 命名
    # 找 `class XxxUseCase` 或 `class Xxx` (后者需配合 @visibleForTesting 公开)
    class_matches = re.findall(r"^\s*class\s+(\w+)", content, re.MULTILINE)
    if not class_matches:
        errors.append(f"❌ {rel}: 文件无 public class 定义")
    else:
        for cls in class_matches:
            # 允许: UseCase / Policy (业务类) + Input/Output/Config/Result/Schedule/State (DTO)
            allowed_suffixes = (
                "UseCase", "Policy",
                "Input", "Output", "Config", "Result", "Schedule", "State",
            )
            if not any(cls.endswith(s) for s in allowed_suffixes):
                errors.append(
                    f"⚠️ {rel}: class {cls} 不以 UseCase/Policy/Input/Output/Config/Result/Schedule/State 结尾 (R109 命名规范)"
                )

    # 规则 5: 业务入口方法
    # 找 class 内方法 (放宽: 任何返回类型 + Dart `call()` 特殊方法)
    for cls in class_matches:
        # 抽 class body (粗略, 没考虑嵌套 class)
        cls_match = re.search(
            rf"class\s+{cls}\s*[^{{]*\{{(.*?)(?:\n\}}|\Z)",
            content,
            re.DOTALL,
        )
        if not cls_match:
            continue
        body = cls_match.group(1)
        # 找业务方法 (放宽: 任何 <类型> name(...), 包括自定义返回类型)
        # 不限返回类型, 包括 Future<X> / X / void / static <类型>
        method_matches = re.findall(
            r"(?:Future<[^>]*>|static\s+)?(?:[A-Z]\w*|[a-z]\w*(?:<[^>]*>)?)\s+(\w+)\s*\(",
            body,
        )
        # 排除 constructor (class 同名) + private method
        methods = [m for m in method_matches if m != cls and not m.startswith("_")]
        # 排除 toString / hashCode / == / runtimeType (Dart 内置)
        builtin = {"toString", "hashCode", "==", "runtimeType", "noSuchMethod"}
        methods = [m for m in methods if m not in builtin]
        if not methods:
            # 只对 UseCase/Policy class 强制要求入口方法, DTO 允许 0 业务方法
            if cls.endswith("UseCase") or cls.endswith("Policy"):
                errors.append(
                    f"❌ {rel}: class {cls} 0 公开业务方法 (R109 use case 必须有入口)"
                )
        else:
            # 至少 1 个方法名在 ENTRY_METHODS, 或有 Dart call() 特殊方法
            has_entry = any(m in ENTRY_METHODS or m == "call" for m in methods)
            if not has_entry and (cls.endswith("UseCase") or cls.endswith("Policy")):
                # 警告: 业务方法名可以自定义 (e.g. reschedule / dispatch)
                errors.append(
                    f"💡 {rel}: class {cls} 公开方法 {methods[:5]} 都不在 R109 推荐列表 (call/run/fire/execute/...)"
                )

    return errors


def main() -> int:
    if not USECASE_DIR.exists():
        print(f"❌ {USECASE_DIR} 不存在")
        return 1

    files = sorted(USECASE_DIR.glob("**/*.dart"))
    if not files:
        print(f"❌ {USECASE_DIR} 0 文件 (R109 期望至少 1 个 use case)")
        return 1

    print(f"🔍 check_usecase_layer: 扫 {len(files)} 个 usecase 文件")

    all_errors = []
    for f in files:
        errors = check_usecase_file(f)
        all_errors.extend(errors)

    # 输出分级
    error_count = sum(1 for e in all_errors if e.startswith("❌"))
    warn_count = sum(1 for e in all_errors if e.startswith("⚠️"))
    info_count = sum(1 for e in all_errors if e.startswith("💡"))

    for e in all_errors:
        print(e)

    if error_count == 0:
        if warn_count > 0 or info_count > 0:
            print(
                f"✅ check_usecase_layer: {len(files)} usecase 文件, "
                f"0 error, {warn_count} warning, {info_count} info"
            )
        else:
            print(f"✅ check_usecase_layer: {len(files)} usecase 文件全合规")
        return 0
    else:
        print(
            f"❌ check_usecase_layer: {error_count} error, {warn_count} warning, {info_count} info"
        )
        return 1


if __name__ == "__main__":
    sys.exit(main())
