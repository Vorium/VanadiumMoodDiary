"""v0.17 round 11: drift tables 和 mappers 按 feature 拆

当前:
  core/data/database/tables/{check_ins,contacts,medications,...}.dart   (7 个表)
  core/data/database/{check_in,contact,medication,mood_entry,vent}_mapper.dart  (5 mapper)
  core/data/database/medication_times.dart                                (value class)

目标:
  core/data/database/tables/{check_in,medication,contact,user_profile,report,mood,vent}/{name}.dart
  core/data/database/mappers/{check_in,medication,contact,mood,vent}/{name}.dart
  medication_times.dart 跟 medication_mapper 一起放 mappers/medication/
"""
import os
import subprocess
import sys

ROOT = os.getcwd()

# 移动映射: 旧路径 (相对 ROOT) -> 新路径 (相对 ROOT)
MOVES = {
    # Tables
    "lib/core/data/database/tables/check_ins.dart":
        "lib/core/data/database/tables/check_in/check_ins.dart",
    "lib/core/data/database/tables/contacts.dart":
        "lib/core/data/database/tables/contact/contacts.dart",
    "lib/core/data/database/tables/medications.dart":
        "lib/core/data/database/tables/medication/medications.dart",
    "lib/core/data/database/tables/mood_entries.dart":
        "lib/core/data/database/tables/mood/mood_entries.dart",
    "lib/core/data/database/tables/report_histories.dart":
        "lib/core/data/database/tables/report/report_histories.dart",
    "lib/core/data/database/tables/user_profiles.dart":
        "lib/core/data/database/tables/user_profile/user_profiles.dart",
    "lib/core/data/database/tables/vent_entries.dart":
        "lib/core/data/database/tables/vent/vent_entries.dart",

    # Mappers
    "lib/core/data/database/check_in_mapper.dart":
        "lib/core/data/database/mappers/check_in/check_in_mapper.dart",
    "lib/core/data/database/contact_mapper.dart":
        "lib/core/data/database/mappers/contact/contact_mapper.dart",
    "lib/core/data/database/medication_mapper.dart":
        "lib/core/data/database/mappers/medication/medication_mapper.dart",
    "lib/core/data/database/mood_entry_mapper.dart":
        "lib/core/data/database/mappers/mood/mood_entry_mapper.dart",
    "lib/core/data/database/vent_mapper.dart":
        "lib/core/data/database/mappers/vent/vent_mapper.dart",

    # Value class (medication Times 解析)
    "lib/core/data/database/medication_times.dart":
        "lib/core/data/database/mappers/medication/medication_times.dart",
}


def run(cmd):
    r = subprocess.run(cmd, shell=True, capture_output=True, text=True, encoding='utf-8')
    if r.returncode != 0:
        print(f"FAIL: {cmd}\nstderr: {r.stderr}")
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
        run(f'git mv "{old}" "{new}"')
        print(f"  moved: {old} → {new}")

    print(f"\n=== Step 3: 同步所有 import ===")
    import_map = {}
    for old, new in MOVES.items():
        old_import = f"package:chroniccare/{old[len('lib/'):]}"
        new_import = f"package:chroniccare/{new[len('lib/'):]}"
        if old_import != new_import:
            import_map[old_import] = new_import

    print(f"  import 替换 ({len(import_map)} 条)")
    for old, new in import_map.items():
        print(f"    {old}")
        print(f"      → {new}")

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
                    print(f"  {os.path.relpath(path, ROOT)}: {file_replacements}")
                    total_replacements += file_replacements
                    total_files_changed += 1

    print(f"\n=== Summary ===")
    print(f"Files moved: {len(MOVES)}")
    print(f"Files updated (imports): {total_files_changed}")
    print(f"Total replacements: {total_replacements}")


if __name__ == "__main__":
    main()
