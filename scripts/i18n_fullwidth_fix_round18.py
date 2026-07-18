"""P1-16 批量修复中英文混排半角标点 → 全角

替换规则:
- `中文,中文` (中文之间半角逗号) → `中文，中文`
- `中文!` `中文?` `中文;` `中文:` → 全角
- 保留数字 / 英文内部的半角(,;/:!?)
- 保留 `(中文, 中文)` 括号内 (要全角)

仅改中文字符前后的标点。
"""
import os
import re
import sys

ROOT = Path = __import__("pathlib").Path

# 中文字符范围
CN = r"[\u4e00-\u9fff]"

# pattern: 中文字符 + 半角标点
# - 中文,中文 → 中文，中文
# - 中文, 空格+英文 → 中文, 空格+英文 (保留,英文上下文是半角)
# - 中文! → 中文！

# 简化:仅替换 [中][,!?;:][中] 或 [中][,!?;:]$
PATTERNS = [
    (re.compile(rf"({CN}),({CN})"), r"\1，\2"),  # 中文,中文
    (re.compile(rf"({CN})!({CN})"), r"\1！\2"),  # 中文!中文
    (re.compile(rf"({CN})\?({CN})"), r"\1？\2"),  # 中文?中文
    (re.compile(rf"({CN});({CN})"), r"\1；\2"),  # 中文;中文
    (re.compile(rf"({CN}):({CN})"), r"\1：\2"),  # 中文:中文
]


def process_file(path):
    src = path.read_text(encoding="utf-8")
    new_src = src
    count = 0
    for pat, repl in PATTERNS:
        new_src_after, n = pat.subn(repl, new_src)
        if n > 0:
            new_src = new_src_after
            count += n
    if count > 0:
        path.write_text(new_src, encoding="utf-8")
    return count


def main():
    total = 0
    files = list(ROOT("lib").rglob("*.dart"))
    for f in files:
        n = process_file(f)
        if n > 0:
            print(f"  {n:3d} fixes: {f}")
            total += n
    print(f"\nTotal: {total} fixes in {len(files)} files")


if __name__ == "__main__":
    main()
