"""v0.17 round 10: feature-first split for presentation/

按 feature 拆 lib/presentation/pages/,domain/data 保持 layer-first 不动。

策略:
  1. git mv 移动文件 (新位置 → presentation/pages/{feature}/)
  2. 同步更新所有引用 (lib/ + test/ 共 25 处 import)
  3. 因为所有 import 都用 package:chroniccare/... 绝对路径(round 9 已转),
     只需要替换 path 字符串,不动相对深度
"""
import os
import subprocess
import sys

ROOT = os.getcwd()
PRES = os.path.join(ROOT, "lib", "presentation")
ROUTING = os.path.join(ROOT, "lib", "core", "routing")
TEST = os.path.join(ROOT, "test")

# 移动映射: 旧路径 (相对 lib/) -> 新路径 (相对 lib/)
MOVES = {
    # home/widgets/ → 各自 feature
    "lib/presentation/pages/home/widgets/check_in_button.dart":
        "lib/presentation/pages/check_in/check_in_button.dart",
    "lib/presentation/pages/home/widgets/last_med_info.dart":
        "lib/presentation/pages/medication/last_med_info.dart",
    "lib/presentation/pages/home/widgets/today_med_schedule.dart":
        "lib/presentation/pages/medication/today_med_schedule.dart",
    "lib/presentation/pages/home/widgets/temp_medication_dialog.dart":
        "lib/presentation/pages/medication/temp_medication_dialog.dart",
    "lib/presentation/pages/home/widgets/mood_dialog.dart":
        "lib/presentation/pages/mood/mood_dialog.dart",
    "lib/presentation/pages/home/widgets/mood_quick_button.dart":
        "lib/presentation/pages/mood/mood_quick_button.dart",
    # home/widgets/celebration_overlay.dart 和 home_secondary_button.dart 保持原位 (home 内部)

    # settings/refill_manage_page.dart → medication
    "lib/presentation/pages/settings/refill_manage_page.dart":
        "lib/presentation/pages/medication/refill_manage_page.dart",

    # settings/widgets/ → 各自 feature
    "lib/presentation/pages/settings/widgets/assessment_reminder_section.dart":
        "lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart",
    "lib/presentation/pages/settings/widgets/choose_window_dialog.dart":
        "lib/presentation/pages/medication/widgets/choose_window_dialog.dart",
    "lib/presentation/pages/settings/widgets/contacts_list_widget.dart":
        "lib/presentation/pages/contact/contacts_list_widget.dart",
    "lib/presentation/pages/settings/widgets/edit_medication_dialog.dart":
        "lib/presentation/pages/medication/widgets/edit_medication_dialog.dart",
    "lib/presentation/pages/settings/widgets/medications_list_widget.dart":
        "lib/presentation/pages/medication/widgets/medications_list_widget.dart",
    "lib/presentation/pages/settings/widgets/medication_report_dialog.dart":
        "lib/presentation/pages/medication/widgets/medication_report_dialog.dart",
    "lib/presentation/pages/settings/widgets/notification_status_card.dart":
        "lib/presentation/pages/settings/widgets/notification_status_card.dart",  # 不动
    "lib/presentation/pages/settings/widgets/report_history_dialog.dart":
        "lib/presentation/pages/settings/widgets/report_history_dialog.dart",  # 不动

    # settings/widgets/email_preview.dart → settings/ 根 (是 page 不是 widget)
    "lib/presentation/pages/settings/widgets/email_preview.dart":
        "lib/presentation/pages/settings/email_preview.dart",
}

# 过滤掉 source == destination 的 no-op moves
MOVES = {old: new for old, new in MOVES.items() if old != new}


def run(cmd, check=True):
    """Run shell command, return (returncode, stdout, stderr)"""
    r = subprocess.run(cmd, shell=True, capture_output=True, text=True, encoding='utf-8')
    if check and r.returncode != 0:
        print(f"FAIL: {cmd}")
        print(f"stderr: {r.stderr}")
        sys.exit(1)
    return r


def main():
    print("=== Step 1: 创建新目录 ===")
    new_dirs = set()
    for new_path in MOVES.values():
        new_dir = os.path.dirname(os.path.join(ROOT, new_path))
        if new_dir not in new_dirs:
            new_dirs.add(new_dir)
            os.makedirs(new_dir, exist_ok=True)
            print(f"  mkdir: {os.path.relpath(new_dir, ROOT)}")

    print(f"\n=== Step 2: git mv 移动 {len(MOVES)} 个文件 ===")
    for old, new in MOVES.items():
        old_abs = os.path.join(ROOT, old)
        new_abs = os.path.join(ROOT, new)
        if not os.path.exists(old_abs):
            print(f"  SKIP (not found): {old}")
            continue
        r = run(f'git mv "{old}" "{new}"')
        print(f"  moved: {os.path.relpath(old_abs, ROOT)} → {os.path.relpath(new_abs, ROOT)}")

    print(f"\n=== Step 3: 更新所有引用 ===")
    # 找出所有需要替换的 import 字符串映射
    # 旧 import 路径 → 新 import 路径
    import_map = {}
    for old, new in MOVES.items():
        # 旧 import: package:chroniccare/{old_path_under_presentation}
        # 新 import: package:chroniccare/{new_path_under_presentation}
        old_import = f"package:chroniccare/{old[len('lib/'):]}"
        new_import = f"package:chroniccare/{new[len('lib/'):]}"
        if old_import != new_import:
            import_map[old_import] = new_import

    print(f"  import 替换映射 ({len(import_map)} 条):")
    for old, new in import_map.items():
        print(f"    {old}")
        print(f"      → {new}")

    # 扫 lib/ 和 test/, 替换所有 .dart 文件中的 import 字符串
    total_replacements = 0
    total_files_changed = 0
    for scan_dir in [os.path.join(ROOT, "lib"), os.path.join(ROOT, "test")]:
        for root, _, files in os.walk(scan_dir):
            for f in files:
                if not f.endswith(".dart") or f.endswith(".g.dart"):
                    continue
                path = os.path.join(root, f)
                with open(path, encoding="utf-8", newline="") as fp:
                    content = fp.read()
                new_content = content
                file_replacements = 0
                for old_import, new_import in import_map.items():
                    if old_import in new_content:
                        file_replacements += new_content.count(old_import)
                        new_content = new_content.replace(old_import, new_import)
                if file_replacements > 0:
                    with open(path, "w", encoding="utf-8", newline="") as fp:
                        fp.write(new_content)
                    rel = os.path.relpath(path, ROOT)
                    print(f"  {rel}: {file_replacements} 处替换")
                    total_replacements += file_replacements
                    total_files_changed += 1

    print(f"\n=== Summary ===")
    print(f"Files moved: {len(MOVES)}")
    print(f"Files updated (imports): {total_files_changed}")
    print(f"Total replacements: {total_replacements}")


if __name__ == "__main__":
    main()
