"""P1-1 fix 第二步: 加 LoadingSkeleton import + 去掉 const
(const LoadingSkeleton() 不行,因 LoadingSkeleton 不是 const constructor)
"""
import os
import re

ROOT = "lib"

# 包含 LoadingSkeleton 用法的 file (从上一轮替换的 19 处)
TARGETS = [
    "lib/main.dart",
    "lib/presentation/pages/assessment/assessment_history_page.dart",
    "lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart",
    "lib/presentation/pages/home/home_page.dart",
    "lib/presentation/pages/medication/medication_calendar_page.dart",
    "lib/presentation/pages/medication/refill_manage_page.dart",
    "lib/presentation/pages/medication/temp_medication_dialog.dart",
    "lib/presentation/pages/settings/email_preview.dart",
    "lib/presentation/pages/settings/settings_page.dart",
    "lib/presentation/pages/settings/widgets/report_history_dialog.dart",
    "lib/presentation/pages/setup/setup_page.dart",
    "lib/presentation/pages/trend/trend_page.dart",
    "lib/presentation/pages/vent/vent_detail_page.dart",
    "lib/presentation/pages/vent/vent_list_page.dart",
]

def add_import(path: str) -> bool:
    with open(path, encoding="utf-8") as f:
        content = f.read()
    if "LoadingSkeleton" not in content:
        return False
    if "loading_skeleton.dart" in content:
        # 已经有 import
        new_content = re.sub(
            r"const\s+LoadingSkeleton\.fullScreen\(\)",
            "LoadingSkeleton.fullScreen()",
            content,
        )
    else:
        # 加 import (按 app_tokens 已有顺序)
        new_content = re.sub(
            r"(import 'package:chroniccare/core/theme/app_tokens\.dart';)",
            r"\1\nimport 'package:chroniccare/presentation/widgets/loading_skeleton.dart';",
            content,
            count=1,
        )
        # 去 const
        new_content = re.sub(
            r"const\s+LoadingSkeleton\.fullScreen\(\)",
            "LoadingSkeleton.fullScreen()",
            new_content,
        )
    if new_content != content:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
        return True
    return False


for t in TARGETS:
    full = t
    if os.path.exists(full):
        if add_import(full):
            print(f"  {full}: fixed")
        else:
            print(f"  {full}: no change needed")
    else:
        print(f"  {full}: NOT FOUND")
