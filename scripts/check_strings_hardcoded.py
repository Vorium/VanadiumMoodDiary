#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #2 / spzh C-09): check_strings_hardcoded 守门员
# v0.27 round 58 (P0 #3 修正): 识别 R57 override 配对模式 (const + xxxText({override}))
#
# 作用: 检测 `lib/core/l10n/strings.dart` 里的硬编码中文 (应该是 const + 走 Strings.xxx)
#
# 背景: spzh v0.25 round 56h P0 报告: strings.dart 21 处硬编中文,14 round 0 动作
#   这些是 domain 层 fallback, 暂时合法 (domain 不能 import flutter)。
#   v0.26 R57 引入 override 模式: 每个 const 配对一个 xxxText({String? override})
#   函数版, 新 caller 可注入 i18n 字符串, 老 caller 继续走 const。
#   v0.27 R58 修正: 守门员识别 override 模式 (不需每处加 'v1.0+ i18n' 注释)
#
# 规则 (R58 修正后):
#   1. static const String = '<中文>'
#      - 配对函数版 `static String xxxText({String? override})` 存在 -> PASS (override 模式)
#      - 不配对 -> 必须带 'v1.0+ i18n' / 'TODO' / 'i18n' 注释 (前 10 行内) 否则 FAIL
#   2. static String xxx() => '<中文>' -> 同样必须带 i18n 注释
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
        sys.stderr = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

ROOT = Path(__file__).resolve().parent.parent
STRINGS_FILE = ROOT / "lib" / "core" / "l10n" / "strings.dart"

# 匹配: 包含中文字符 (CJK Unified Ideographs U+4E00 - U+9FFF)
CJK_RE = re.compile(r'[\u4e00-\u9fff]')

# 匹配 const String 声明 / 或 String xxx(...) => 形式
STRING_ASSIGN_RE = re.compile(
    r'''
    (?:static\s+const\s+(?:String\s+)?\w+\s*=|  # static const String xxx = / static const xxx =
     static\s+String\s+\w+\s*\([^)]*\)\s*=>)  # static String xxx() =>
    \s*['"]([^'"]*[\u4e00-\u9fff][^'"]*)['"]  # 字符串含中文
    ''',
    re.VERBOSE,
)

# 匹配 const 名称: `static const notifChannelMedicationName = ...` 抽 `notifChannelMedicationName`
CONST_NAME_RE = re.compile(
    r'static\s+const\s+(?:String\s+)?(\w+)\s*='
)

# 匹配配对函数版: `static String xxxText({String? override})`
# R57 约定: constName + 'Text' 后缀
OVERRIDE_PAIR_RE = re.compile(
    r'static\s+String\s+(\w+)\s*\([^)]*String\?\s+override[^)]*\)'
)


def has_i18n_todo(line: str, comment_lines: list[str]) -> bool:
    """检查本行 + 周围注释行是否含 i18n / v1.0+ 标记"""
    full = '\n'.join(comment_lines + [line])
    full_lower = full.lower()
    keywords = ['v1.0+ i18n', 'todo', 'i18n', 'l10n', 'applocalizations',
                '走 l10n', '走 applocalizations', '走 i18n']
    return any(k in full_lower for k in keywords)


def has_override_pair(name: str, all_text: str) -> bool:
    """检查 R57 配对函数版是否存在: `static String <name>Text({String? override})`"""
    pair_name = f'{name}Text'
    if pair_name in all_text:
        return bool(OVERRIDE_PAIR_RE.search(all_text))
    return False


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
    total_const_cn = 0
    total_override_pairs = 0

    for line_no, line in enumerate(lines, 1):
        if not CJK_RE.search(line):
            continue
        if not STRING_ASSIGN_RE.search(line):
            continue

        # R58 修正: 如果是 const 声明 + 有配对函数版 -> PASS
        const_match = CONST_NAME_RE.search(line)
        if const_match and has_override_pair(const_match.group(1), text):
            total_const_cn += 1
            total_override_pairs += 1
            continue

        # 否则 (无 override 配对) -> 必须带 i18n 注释
        # R58 修正: 取前 10 行注释 (R57 取 4 行太短, 漏掉 section header 注释)
        ctx_start = max(0, line_no - 11)
        ctx = lines[ctx_start:line_no]
        if has_i18n_todo(line, ctx):
            total_const_cn += 1
            continue

        snippet = line.strip()[:80]
        violations.append((line_no, snippet))

    if violations:
        print(f"[FAIL] check_strings_hardcoded: {len(violations)} 处硬编中文无 i18n 标记")
        print(f"  文件: {STRINGS_FILE.relative_to(ROOT).as_posix()}")
        print(f"  规则 (R58 修正后):")
        print(f"    1. const 配对 xxxText({{String? override}}) 函数版 -> PASS (R57 模式)")
        print(f"    2. 否则: 必须前 10 行内含 'v1.0+ i18n' / 'TODO' / '走 l10n' 等标记")
        print(f"  详情:")
        for line_no, snippet in violations:
            print(f"    L{line_no}: {snippet}")
        return 1

    total_cn = len(STRING_ASSIGN_RE.findall(text))
    print(f"[OK] check_strings_hardcoded: {total_cn} 处中文 static const/String, "
          f"{total_override_pairs} 处 R57 override 配对模式 + 其余带 i18n 标记 "
          f"({STRINGS_FILE.relative_to(ROOT).as_posix()})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
