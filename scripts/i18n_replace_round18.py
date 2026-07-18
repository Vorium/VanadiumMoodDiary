"""P1-10 i18n 字符串批量替换脚本

替换规则:
- Text('加载失败: $e') → Text(AppLocalizations.of(context).commonLoadFailed(e.toString()))
- Text('加载失败: $error') → 同上
- Text('加载失败,请检查网络或重新打开 App') → 留作后续(特殊文案)
- description: '加载失败: $e' → 留作后续(无 context,需要 l10n refactor)
- Text('删除这条？') → Text(AppLocalizations.of(context).commonConfirmDelete)
- Text('我知道了') → Text(AppLocalizations.of(context).commonGotIt)
- Text('关闭') → Text(AppLocalizations.of(context).commonClose)
- Text('我知道了') → 同上

已 import app_localizations.dart 的文件才替换,未 import 的留 hardcode。
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path("lib/presentation")
FILES = list(ROOT.rglob("*.dart"))

# 高频字符串 → l10n key
# 注:实际文案必须跟 .arb 同步
REPLACEMENTS = [
    # 加载失败(中文 + 错误变量)
    (r"Text\(\s*'加载失败:\s*\$e'\)",
     "Text(AppLocalizations.of(context).commonLoadFailed(e.toString()))"),
    (r"Text\(\s*'加载失败:\s*\$error'\)",
     "Text(AppLocalizations.of(context).commonLoadFailed(error.toString()))"),
    (r"Text\(\s*'加载失败:\s*\$\{e\}'\)",
     "Text(AppLocalizations.of(context).commonLoadFailed(e.toString()))"),
    # 加载失败(中文 + 全角冒号)
    (r"Text\(\s*'加载失败：\$e'\)",
     "Text(AppLocalizations.of(context).commonLoadFailed(e.toString()))"),
    # 删除 confirm title
    (r"title:\s*const\s+Text\(\s*'删除这条？'\)",
     "title: Text(AppLocalizations.of(context).commonConfirmDelete)"),
    (r"title:\s*Text\(\s*'删除这条？'\)",
     "title: Text(AppLocalizations.of(context).commonConfirmDelete)"),
    # 我知道了
    (r"child:\s*const\s+Text\(\s*'我知道了'\)",
     "child: Text(AppLocalizations.of(context).commonGotIt)"),
    (r"child:\s*Text\(\s*'我知道了'\)",
     "child: Text(AppLocalizations.of(context).commonGotIt)"),
    # 关闭
    (r"child:\s*const\s+Text\(\s*'关闭'\)",
     "child: Text(AppLocalizations.of(context).commonClose)"),
]

# 跳过这些文件 (description string / 没 context)
SKIP_SUBSTRINGS = [
    "description: '加载失败",
    "description: \"加载失败",
]


def process_file(path: Path) -> tuple[int, str]:
    """Process one file, return (change_count, new_content)"""
    src = path.read_text(encoding="utf-8")
    if "加载失败" not in src and "删除这条" not in src and "我知道了" not in src:
        return (0, src)

    # 检查是否已 import app_localizations.dart
    has_l10n_import = "app_localizations.dart" in src
    if not has_l10n_import:
        print(f"  SKIP (no l10n import): {path}", file=sys.stderr)
        return (0, src)

    new_src = src
    count = 0
    for pattern, replacement in REPLACEMENTS:
        new_src_after, n = re.subn(pattern, replacement, new_src)
        if n > 0:
            new_src = new_src_after
            count += n
    return (count, new_src)


def main():
    total = 0
    for f in FILES:
        n, new_src = process_file(f)
        if n > 0:
            f.write_text(new_src, encoding="utf-8")
            print(f"  {n:3d} replacements: {f}")
            total += n
    print(f"\nTotal: {total} replacements in {len(FILES)} files scanned")


if __name__ == "__main__":
    main()
