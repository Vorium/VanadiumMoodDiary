"""v0.17 round 8a: 批量改 import 路径 (lib/ → lib/core/)"""
import os

MAPPING = [
    # package: 绝对路径
    ("package:chroniccare/data/database/", "package:chroniccare/core/database/"),
    ("package:chroniccare/theme/", "package:chroniccare/core/theme/"),
    ("package:chroniccare/l10n/", "package:chroniccare/core/l10n/"),
    ("package:chroniccare/shared/", "package:chroniccare/core/shared/"),
    ("package:chroniccare/routing/", "package:chroniccare/core/routing/"),
    # 3 层相对 (lib/data/... ← lib/...)
    ("'../../../data/database/", "'../../../core/database/"),
    ("'../../../theme/", "'../../../core/theme/"),
    ("'../../../l10n/", "'../../../core/l10n/"),
    ("'../../../shared/", "'../../../core/shared/"),
    ("'../../../routing/", "'../../../core/routing/"),
    # 2 层相对 (lib/data/services/... ← lib/...)
    ("'../../data/database/", "'../../core/database/"),
    ("'../../theme/", "'../../core/theme/"),
    ("'../../l10n/", "'../../core/l10n/"),
    ("'../../shared/", "'../../core/shared/"),
    ("'../../routing/", "'../../core/routing/"),
    # 1 层相对
    ("'../data/database/", "'../core/database/"),
    ("'../theme/", "'../core/theme/"),
    ("'../l10n/", "'../core/l10n/"),
    ("'../shared/", "'../core/shared/"),
    ("'../routing/", "'../core/routing/"),
]

count = 0
for root, dirs, files in os.walk("lib"):
    for f in files:
        if not f.endswith(".dart"):
            continue
        p = os.path.join(root, f)
        with open(p, encoding="utf-8") as fh:
            content = fh.read()
        new = content
        for old, nu in MAPPING:
            new = new.replace(old, nu)
        if new != content:
            with open(p, "w", encoding="utf-8") as fh:
                fh.write(new)
            count += 1
            print(f"  updated: {p}")
print(f"Total: {count} files updated")
