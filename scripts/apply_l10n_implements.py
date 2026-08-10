#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""R96/R97 修补脚本: 给 `flutter gen-l10n` 生成的 `app_localizations.dart` 加
`implements SafetyAlertL10n` + 对应 import。

**背景**:
- `flutter pub get` / `flutter gen-l10n` 重新生成 `lib/l10n/app_localizations.dart`
- 默认 generated `abstract class AppLocalizations` 不实现 SafetyAlertL10n interface
  (R87 抽的 4 层架构 interface, 在 `lib/core/l10n/safety_alert_l10n.dart`)
- 后果: data service 接收 `SafetyAlertL10n` interface 参数时,
  `AppLocalizations` 实例不能 assign → 36 analyzer errors

**修法**: generated file 改 2 处:
1. 加 `import 'package:chroniccare/core/l10n/safety_alert_l10n.dart';`
2. `abstract class AppLocalizations` → `abstract class AppLocalizations implements SafetyAlertL10n`

**何时跑**:
- `flutter analyze` 报 36 `can't be assigned to 'SafetyAlertL10n'` 时
- `flutter pub get` 后 ARB 改动触发了 regen 时
- 改 `lib/l10n/app_*.arb` 后 `flutter pub get` 之后

**用法**:
    python scripts/apply_l10n_implements.py

**幂等**: 跑多次 OK, 已有 implements + import 时不重复加。
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
TARGET = ROOT / "lib" / "l10n" / "app_localizations.dart"

IMPORT_LINE = "import 'package:chroniccare/core/l10n/safety_alert_l10n.dart';\n"
CLASS_PATTERN = re.compile(
    r"(/// be consistent with the languages listed in the AppLocalizations\.supportedLocales\n"
    r"/// property\.\n"
    r")abstract class AppLocalizations \{",
    re.MULTILINE,
)
CLASS_REPLACEMENT = (
    r"\1///\n"
    r"/// v0.29 R96+R97 修正: 显式 implements SafetyAlertL10n (在 core/l10n/),\n"
    r"/// 让 data 层 (SafetyAlertBuilder / SafetyAlertDispatcher / SafetyWatchService)\n"
    r"/// 接收 SafetyAlertL10n interface 时能直接拿 AppLocalizations 实例。\n"
    r"/// 跑 `python scripts/apply_l10n_implements.py` 自动补回, 跑 `flutter analyze` 验证 0 error。\n"
    r"abstract class AppLocalizations implements SafetyAlertL10n {"
)

IMPORT_PATTERN = re.compile(
    r"^import 'package:chroniccare/core/l10n/safety_alert_l10n\.dart';\n",
    re.MULTILINE,
)


def main() -> int:
    if not TARGET.exists():
        print(f"[FAIL] {TARGET} 不存在, 请在项目根跑")
        return 1

    content = TARGET.read_text(encoding="utf-8")
    original = content

    # 1) 补 import (放在 `import 'app_localizations_en.dart';` 之前, 跟 R96 一致)
    if "core/l10n/safety_alert_l10n.dart" not in content:
        content = content.replace(
            "import 'app_localizations_en.dart';\n",
            f"{IMPORT_LINE}\nimport 'app_localizations_en.dart';\n",
            1,
        )
        print("[OK] import 补回")
    else:
        print("[SKIP] import 已有, 跳过")

    # 2) 补 implements
    if "abstract class AppLocalizations implements SafetyAlertL10n" not in content:
        if CLASS_PATTERN.search(content):
            content = CLASS_PATTERN.sub(CLASS_REPLACEMENT, content, count=1)
            print("[OK] implements SafetyAlertL10n 补回")
        else:
            print("[FAIL] 找不到 `abstract class AppLocalizations {` pattern, "
                  "可能 gen-l10n output 格式变了, 手动改 R96/R97 entry")
            return 1
    else:
        print("[SKIP] implements 已有, 跳过")

    if content == original:
        print("[OK] 无需改动")
        return 0

    TARGET.write_text(content, encoding="utf-8")
    print(f"[OK] 已写回 {TARGET}")
    print("下一步: `flutter analyze` 应显示 0 error")
    return 0


if __name__ == "__main__":
    sys.exit(main())
