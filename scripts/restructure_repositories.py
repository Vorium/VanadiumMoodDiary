"""P1-26 fix: 把 lib/core/data/repositories/*.dart 移到子目录 {feature}/

操作:
1. mkdir repositories/{check_in,contact,medication,mood,report_history,user_profile,vent}
2. git mv 每个 *_repository_impl.dart 到子目录
3. 全文替换所有 import 路径

import 模式:
- 'package:chroniccare/core/data/repositories/X_repository_impl.dart'
  → 'package:chroniccare/core/data/repositories/{feature}/X_repository_impl.dart'
"""
import os
import re
import subprocess

ROOT = "lib"
REPOS_DIR = "lib/core/data/repositories"

# feature 名字映射 (跟 file prefix 对应)
MAPPING = {
    "check_in_repository_impl.dart": "check_in",
    "contact_repository_impl.dart": "contact",
    "medication_repository_impl.dart": "medication",
    "mood_repository_impl.dart": "mood",
    "report_history_repository_impl.dart": "report_history",
    "user_profile_repository_impl.dart": "user_profile",
    "vent_repository_impl.dart": "vent",
}


def main() -> int:
    # Step 1: 创建子目录 + git mv
    for fname, feature in MAPPING.items():
        target_dir = os.path.join(REPOS_DIR, feature)
        os.makedirs(target_dir, exist_ok=True)
        src = os.path.join(REPOS_DIR, fname)
        dst = os.path.join(target_dir, fname)
        if os.path.exists(src):
            # 用 git mv 保留 history
            subprocess.run(
                ["git", "mv", src, dst],
                cwd=os.getcwd(),
                check=True,
            )
            print(f"  [mv] {src} -> {dst}")

    # Step 2: 全文替换 import 路径 (lib/ + test/)
    for fname, feature in MAPPING.items():
        old_import = (
            f"package:chroniccare/core/data/repositories/{fname}"
        )
        new_import = (
            f"package:chroniccare/core/data/repositories/{feature}/{fname}"
        )
        for scan_root in ["lib", "test", "scripts"]:
            if not os.path.isdir(scan_root):
                continue
            for dirpath, dirnames, filenames in os.walk(scan_root):
                for f in filenames:
                    if not f.endswith(".dart"):
                        continue
                    full = os.path.join(dirpath, f)
                    try:
                        with open(full, encoding="utf-8") as fp:
                            content = fp.read()
                    except (UnicodeDecodeError, OSError):
                        continue
                    if old_import not in content:
                        continue
                    new_content = content.replace(old_import, new_import)
                    with open(full, "w", encoding="utf-8") as fp:
                        fp.write(new_content)
                    print(f"  [replaced] {full}")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
