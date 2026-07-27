#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #2 / spzh C-09): check_strings_hardcoded 守门员
#
# 作用: 检测 `lib/core/l10n/strings.dart` 里的硬编码中文 (应该是 const + 走 Strings.xxx)
#
# 背景: spzh v0.25 round 56h P0 报告: strings.dart 21 处硬编中文,14 round 0 动作
#   这些是 domain 层 fallback, 暂时合法 (domain 不能 import flutter),
#   但必须每个都加 "v1.0+ 走 i18n" 注释做 TODO 标记, 不允许无注释裸硬编。
#
# 规则:
#   - static const String = '<中文>'  → 必须带 'v1.0+ i18n' 注释
#   - static String xxx() => '<中文>'  → 同样
#   - 否则 → 报 [FAIL]
#
# 范围: lib/core/l10n/strings.dart 单文件
# 退出: 0 = pass, 1 = fail
import io
import re
import sys
from pathlib import Path

# Windows GBK console: 强制 utf-8 stdout 避免中文乱码
if sys.platform == 'win32':
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

ROOT = Path(__file__).resolve().parent.parent
STRINGS_FILE = ROOT / "lib" / "core" / "l10n" / "strings.dart"

# 匹配: 包含中文字符 (CJK Unified Ideographs U+4E00 - U+9FFF)
CJK_RE = re.compile(r'[\u4e00-\u9fff]')

# 匹配 const String 声明 / 或 String xxx(...) => 形式
# 实际代码风格:
#   - static const xxx = '<中文>';   (无显式 String 类型, 类型推断)
#   - static String xxx(...) => '<中文>';
#   - static String xxx(...) { return '<中文>'; }
#   - static const xxx = '<中文>'\n  '<中文>'  (多行 const 拼接)
# 简化匹配: 单引号或双引号包裹的字符串, 跟 = 关联
STRING_ASSIGN_RE = re.compile(
    r'''
    (?:static\s+const\s+(?:String\s+)?\w+\s*=|  # static const String xxx = / static const xxx =
     static\s+String\s+\w+\s*\([^)]*\)\s*=>)  # static String xxx() =>
    \s*['"]([^'"]*[\u4e00-\u9fff][^'"]*)['"]  # 字符串含中文
    ''',
    re.VERBOSE,
)


def has_i18n_todo(line: str, comment_lines: list[str]) -> bool:
    """检查本行 + 周围注释行是否含 i18n / v1.0+ 标记"""
    full = '\n'.join(comment_lines + [line])
    full_lower = full.lower()
    # 允许: "v1.0+ i18n" / "TODO" / "i18n" / "走 l10n" / "走 AppLocalizations"
    keywords = ['v1.0+ i18n', 'todo', 'i18n', 'l10n', 'applocalizations',
                '走 l10n', '走 applocalizations', '走 i18n']
    return any(k in full_lower for k in keywords)


def main() -> int:
    if not STRINGS_FILE.exists():
        print(f"[FAIL] 找不到 {STRINGS_FILE}")
        return 1

    try:
        text = STRINGS_FILE.read_text(encoding='utf-8')
    except UnicodeDecodeError as e:
        print(f"[FAIL] 读取 {STRINGS_FILE} 失败: {e}")
        return 1

    violations = []
    lines = text.splitlines()
    for line_no, line in enumerate(lines, 1):
        if not CJK_RE.search(line):
            continue
        if not STRING_ASSIGN_RE.search(line):
            # 中文注释 / 字符串拼接里的中文 / throw 里的中文 → 跳过
            # 只关心 STRING_ASSIGN_RE 命中的硬编
            continue
        # 检查本行 + 前 3 行注释 (function / class 头注释)
        # 简单: 取 line_no-3 到 line_no+1
        ctx_start = max(0, line_no - 4)
        ctx = lines[ctx_start:line_no]
        if not has_i18n_todo(line, ctx):
            snippet = line.strip()[:80]
            violations.append((line_no, snippet))

    if violations:
        print(f"[FAIL] check_strings_hardcoded: {len(violations)} 处硬编中文无 i18n 标记")
        print(f"  文件: {STRINGS_FILE.relative_to(ROOT).as_posix()}")
        print(f"  规则: 每个中文 static const/String 必须带 'v1.0+ i18n' / 'TODO' / '走 l10n' 注释")
        print(f"  详情:")
        for line_no, snippet in violations:
            print(f"    L{line_no}: {snippet}")
        return 1

    # 统计
    total_cn = len(STRING_ASSIGN_RE.findall(text))
    print(f"[OK] check_strings_hardcoded: {total_cn} 处中文 static const/String, "
          f"全部带 i18n 标记 ({STRINGS_FILE.relative_to(ROOT).as_posix()})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
