"""P2-P0-1 批量替换 developer.log → piiSafeLog

只对含 PII 的 service 文件:
- reminder_scheduler.dart
- sms_service.dart
- email_service.dart
- notification_service.dart
- notification_navigation.dart
- snooze_manager.dart

策略:
1. 加 import 'package:chroniccare/core/shared/pii_safe_log.dart'
2. 删 import 'dart:developer' as developer;(如果文件无其他 developer.* 用法)
3. developer.log( → piiSafeLog(
4. 保留 name: 'XxxService' 参数风格

maskPhone / maskName 替换:
- 'To (phone): $to' → 'To (phone): ${maskPhone(to)}'
- 'To: $to' → 'To: ${maskPhone(to)}'
- '  用户: ${profile.userName}' → '  用户: ${maskName(profile.userName)}'
- '→ ${c.name} (${c.phone})' → '→ ${maskName(c.name)} (${maskPhone(c.phone)})'
"""
import re
import os
import shutil
from pathlib import Path

ROOT = Path("lib/core/data/services")
EXTRA = Path("lib/core/data/services/notification_navigation.dart")

FILES = [
    ROOT / "reminder_scheduler.dart",
    ROOT / "sms_service.dart",
    ROOT / "email_service.dart",
    ROOT / "notification_service.dart",
    ROOT / "snooze_manager.dart",
    EXTRA,
]

PII_IMPORT = "import 'package:chroniccare/core/shared/pii_safe_log.dart';"
DEV_IMPORT = "import 'dart:developer' as developer;"

# 替换 rules (顺序敏感)
REPLACEMENTS = [
    # 1. To (phone): $to → To (phone): ${maskPhone(to)}
    (r"'  To \(phone\): \$to'", r"'  To (phone): \${maskPhone(to)}'"),
    # 2. To: $to → To: ${maskPhone(to)}
    (r"'  To: \$to'", r"'  To: \${maskPhone(to)}'"),
    # 3. 联系人姓名 + 电话
    (r"'→ \$\{c\.name\} \(\$\{c\.phone\}\): '", r"'→ \${maskName(c.name)} (\${maskPhone(c.phone)}): '"),
    # 4. 用户名
    (r"'  用户: \$\{profile\.userName\}'", r"'  用户: \${maskName(profile.userName)}'"),
    # 5. body 直接 print
    (r"developer\.log\(body, name: 'EmailService'\);",
     r"piiSafeLog('EmailService', body);"),
    # 6. developer.log( → piiSafeLog(  (通用)
    (r"developer\.log\(", r"piiSafeLog("),
]


def process_file(path: Path) -> int:
    src = path.read_text(encoding="utf-8")
    if "developer.log" not in src and "developer(" not in src:
        return 0
    if "pii_safe_log" in src:
        return 0  # 已处理

    new_src = src
    count = 0
    for pat, repl in REPLACEMENTS:
        new_src_after, n = re.subn(pat, repl, new_src)
        if n > 0:
            new_src = new_src_after
            count += n

    if count == 0:
        return 0

    # 1. 加 pii_safe_log import(在 developer 之前)
    if PII_IMPORT not in new_src:
        new_src = new_src.replace(DEV_IMPORT, f"{PII_IMPORT}\n{DEV_IMPORT}", 1)

    # 2. 如果文件没有其他 developer.* 用法,删 developer import
    if "developer." not in re.sub(r"piiSafeLog\([^)]*\)", "", new_src):
        new_src = new_src.replace(f"{DEV_IMPORT}\n", "", 1)

    path.write_text(new_src, encoding="utf-8")
    return count


def main():
    total = 0
    for f in FILES:
        if not f.exists():
            print(f"  SKIP: {f} not found")
            continue
        n = process_file(f)
        if n > 0:
            print(f"  {n:3d} replacements: {f}")
            total += n
    print(f"\nTotal: {total} replacements in {len(FILES)} files")


if __name__ == "__main__":
    main()
