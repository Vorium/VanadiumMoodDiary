#!/usr/bin/env python3
# v0.25 round 56e (spen P0 #15): check_orphan_arb_keys 守门员
#
# 作用: 检测 ARB key 定义了但代码里没引用的"孤儿 key" (orphan keys)
#
# 原因: 项目有 677+ ARB key, 跨 feature 重构时容易留 orphan 键 (删了 widget
#       但 ARB 没删, 或新加 ARB key 但忘了 wire 到 UI). 39+ 个历史 orphan.
#
# 触发: CI / 每次 commit
# 退出: 0 = pass (0 orphan), 1 = fail (有 orphan 需清理)
#
# 跳过 key 规则 (这些不查 orphan):
#   - @@ 开头的元数据 (locale / author /)
#   - @ 开头的 metadata 配对键 (例如 "@homeStreak": { "placeholders": ... })
#   - 在 AppLocalizations class 生成的 getter 里有 (排除 generator 自身)
#
# 范围: lib/ + test/ 全部 Dart 文件
# ARB 范围: lib/l10n/app_zh.arb (主源), 跟 app_en.arb / app_zh_Hant.arb 交叉验证
import json
import os
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = ROOT / "lib" / "l10n"
ZH_ARB = L10N_DIR / "app_zh.arb"
EN_ARB = L10N_DIR / "app_en.arb"
ZH_HANT_ARB = L10N_DIR / "app_zh_Hant.arb"

# 跨语言同步 (跟 check_arb_keys.py 一致)
SYNC_ARBS = [ZH_ARB, EN_ARB, ZH_HANT_ARB]


def parse_arb_keys(arb_path: Path) -> set[str]:
    """从 ARB 提取 key 集合. 跳过 @@ 元数据 + @metadata 配对."""
    with arb_path.open(encoding="utf-8") as f:
        data = json.load(f)
    keys = set()
    for k in data:
        if k.startswith("@"):
            continue  # 跳过元数据 (@keyName: { placeholders })
        keys.add(k)
    return keys


def find_key_references(key: str, search_dirs: list[Path]) -> bool:
    """在 lib/ + test/ 中搜 key 是否被引用.

    模式:
    - AppLocalizations.of(context).<key>      (普通链式)
    - AppLocalizations.of(context)!.<key>     (null-assert 链式, Dart 2.12+)
    - AppLocalizations.of(context)?.<key>     (null-safe 链式)
    - 直接 .<key> 引用 (extension / helper 内)

    跳过 l10n/ 生成文件 (避免自身匹配).
    """
    # 模式 1: 严格 AppLocalizations.of(...) 后接 . / ! / ?. 再接 key
    # [^)]* 匹配 .of 括号内任意 (含 context)
    # [.!?]? 匹配可选的链式操作符
    pattern_strict = re.compile(
        r"AppLocalizations\.of\([^)]*\)[.!?]?\.?" + re.escape(key) + r"\b"
    )
    # 模式 2: 简单 .<key> 引用 (extension / helper)
    pattern_simple = re.compile(r"\." + re.escape(key) + r"\b")

    for search_dir in search_dirs:
        for dart_file in search_dir.rglob("*.dart"):
            # 跳过 l10n/ 生成文件
            if "l10n" in dart_file.parts and dart_file.name.startswith("app_localizations"):
                continue
            try:
                content = dart_file.read_text(encoding="utf-8")
            except UnicodeDecodeError:
                continue
            if pattern_strict.search(content) or pattern_simple.search(content):
                return True
    return False


def main() -> int:
    if not ZH_ARB.exists():
        print(f"[FAIL] 找不到 {ZH_ARB}")
        return 1

    zh_keys = parse_arb_keys(ZH_ARB)
    en_keys = parse_arb_keys(EN_ARB) if EN_ARB.exists() else set()
    hant_keys = parse_arb_keys(ZH_HANT_ARB) if ZH_HANT_ARB.exists() else set()

    # 跨语言同步检查 (跟 check_arb_keys.py 一致)
    missing_in_en = zh_keys - en_keys
    missing_in_hant = zh_keys - hant_keys
    if missing_in_en:
        print(f"[FAIL] en 缺失 {len(missing_in_en)} 个 zh key: {sorted(missing_in_en)[:5]}...")
        return 1
    if missing_in_hant:
        print(f"[FAIL] zh_Hant 缺失 {len(missing_in_hant)} 个 zh key: {sorted(missing_in_hant)[:5]}...")
        return 1

    # 找 orphan keys (在 zh 里有但代码没用)
    search_dirs = [ROOT / "lib", ROOT / "test"]
    orphans = []
    for key in sorted(zh_keys):
        if not find_key_references(key, search_dirs):
            orphans.append(key)

    if orphans:
        print(f"[FAIL] 发现 {len(orphans)} 个 orphan ARB key (定义但未引用):")
        for k in orphans:
            print(f"   - {k}")
        print()
        print("清理方案:")
        print("  1. 找到引用方并用上: AppLocalizations.of(context).<key>")
        print("  2. 或从 lib/l10n/app_zh.arb (en/zh_Hant 同步) 删除未用的 key")
        return 1

    print(f"[OK] check_orphan_arb_keys: {len(zh_keys)} zh ARB key, 0 orphan")
    print(f"     同步 en ({len(en_keys)}), zh_Hant ({len(hant_keys)})")
    return 0


if __name__ == "__main__":
    sys.exit(main())
