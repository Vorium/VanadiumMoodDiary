#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #2 / spzh C-09): check_strings_hardcoded 守门员
# v0.27 round 58 (P0 #3 修正): 识别 R57 override 配对模式 (const + xxxText({override}))
# v0.32 R110 round 3 (SP-zh-16): 扩 inline 字面量规则 — 原来只扫 strings.dart
#   的 static const, 漏 `title: '中文'` / `Text('中文')` 这类 widget inline
#   硬编码 (SP-zh-15 报告 add_medication_page 等 4 文件 12 处)。
# 1.1.0 round 7c (P2 gatekeeper): 加规则 3 — 规则 1 只扫 strings.dart、
#   规则 2 只扫 widget inline 模式, domain 层 `static const List<String> =
#   ['家庭',...]` 和 `return '中文'` 静默通过。规则 3 扫 lib/domain/ +
#   lib/core/ (排除 strings.dart / *.g.dart / 注释) 的 CJK 字面量。
#
# 作用: 检测 lib/ 下的硬编码中文 (应该走 ARB key / Strings.xxx)
#
# 规则 1 (strings.dart, R58 修正后):
#   1. static const String = '<中文>'
#      - 配对函数版 `static String xxxText({String? override})` 存在 -> PASS (override 模式)
#      - 不配对 -> 必须带 'v1.0+ i18n' / 'TODO' / 'i18n' 注释 (前 10 行内) 否则 FAIL
#   2. static String xxx() => '<中文>' -> 同样必须带 i18n 注释
#
# 规则 2 (R110 round 3 新增, lib/**/*.dart):
#   `(title|label|hintText|tooltip|subtitle|description|actionLabel|statusText|
#    message): '<中文>'` 或 `Text('<中文>')` — widget inline 硬编码
#   - 本行行尾带 '走 ARB' / 'TODO' / 'i18n' 注释 -> PASS (显式标记的 Phase 5 遗留)
#   - 否则 FAIL
#
# 规则 3 (1.1.0 round 7c 新增, lib/domain/ + lib/core/):
#   源码行 (去注释后) 含 CJK 字面量 — 量表 items / 预设标签 / fallback 文案
#   - 放行条件 (跟规则 1 同哲学): 本行或前 10 行注释含 'i18n' / '走 l10n' /
#     'canonical fallback' / 'v1.0+ i18n' 标记, 或文件头前 20 行有同款标记
#   - 否则 FAIL
#
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

# R110 round 3: widget inline 硬编码 — field: '中文' 或 Text('中文')
# 只匹配单行字面量 (不匹配模板字符串 / 变量拼接)
INLINE_CJK_FIELD_RE = re.compile(
    r'''(?:title|label|hintText|tooltip|subtitle|description|actionLabel|statusText|message)\s*:\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''
)
INLINE_CJK_TEXT_RE = re.compile(
    r'''\bText\s*\(\s*['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''
)

# 行尾显式标记 (Phase 5 遗留): 走 ARB / TODO / i18n
INLINE_ANNOTATION_RE = re.compile(
    r'走\s*(?:ARB|l10n|i18n)|TODO|i18n|R110', re.IGNORECASE
)

# 规则 3 (round 7c): 放行标记 — 注释内出现任一词即放行
RULE3_MARKER_RE = re.compile(
    r'i18n|走\s*l10n|canonical fallback|v1\.0\+ i18n', re.IGNORECASE
)

# 规则 3 (1.1.0 R113 BUG A 修正): 精确行号豁免 token
# `// rule3-whitelist: 70,92` 或 `// rule3-whitelist: 70-92,100-120`
# — 只豁免显式列出的行, 新增行必须自带标记, 杜绝"文件头提 i18n = 整文件
# 豁免"盲区 (修前 cbt_thought_record_pdf_layout.dart 头注释提 "i18n keys"
# → 第 92 行硬编码中文 PDF 头静默通过)。
RULE3_WHITELIST_RE = re.compile(
    r'rule3-whitelist\s*:\s*((?:\d+\s*(?:-\s*\d+)?\s*,?\s*)+)',
    re.IGNORECASE,
)

# 规则 3 (round 7c): CJK 字符串字面量 (单行, 含引号内中文)
RULE3_STR_LIT_RE = re.compile(
    r'''['"][^'"]*[\u4e00-\u9fff][^'"]*['"]'''
)


def parse_rule3_whitelist(lines: list[str]) -> set[int]:
    """解析 `// rule3-whitelist: <行号/区间>` token → 豁免行号集合

    支持: `70`, `70-92`, `70 - 92`, 逗号分隔多个。token 出现在任何
    comment 行都有效 (惯例放文件头, 注明缘由)。未知格式 → 抛 ValueError
    (fail-fast, 防手滑写错 token 静默失效)。
    """
    exempt: set[int] = set()
    for line in lines:
        m = RULE3_WHITELIST_RE.search(comment_part(line))
        if m is None:
            continue
        for part in m.group(1).split(','):
            part = part.strip()
            if not part:
                continue
            if '-' in part:
                a, b = (s.strip() for s in part.split('-', 1))
                if not a.isdigit() or not b.isdigit():
                    raise ValueError(
                        f'rule3-whitelist 区间格式错误: "{part}" (期望 "70-92")'
                    )
                start, end = int(a), int(b)
                if start > end:
                    raise ValueError(
                        f'rule3-whitelist 区间倒置: "{part}" (start > end)'
                    )
                exempt.update(range(start, end + 1))
            else:
                if not part.isdigit():
                    raise ValueError(
                        f'rule3-whitelist 行号格式错误: "{part}" (期望数字)'
                    )
                exempt.add(int(part))
    return exempt


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


def is_comment_line(line: str) -> bool:
    """跳过注释行 (// 或 块注释内)"""
    stripped = line.lstrip()
    return stripped.startswith('//') or stripped.startswith('*') or stripped.startswith('/*')


def strip_comments(line: str) -> str:
    """去掉 // 行注释 + 同行内 /* */ 块注释 (规则 3 用, 防注释里中文误报)"""
    line = re.sub(r'/\*.*?\*/', '', line)
    idx = line.find('//')
    return line[:idx] if idx >= 0 else line


def comment_part(line: str) -> str:
    """抽出本行注释部分 (行注释 // 之后; 整行注释原样返回)"""
    idx = line.find('//')
    return line[idx:] if idx >= 0 else ''


def scan_inline_cjk(lib_dir: Path) -> list[tuple[str, int, str]]:
    """R110 round 3: 扫 lib/**/*.dart 的 widget inline 硬编码中文"""
    violations: list[tuple[str, int, str]] = []
    for p in sorted(lib_dir.rglob('*.dart')):
        if 'generated' in p.as_posix():
            continue
        try:
            lines = p.read_text(encoding='utf-8').splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        for line_no, line in enumerate(lines, 1):
            if not CJK_RE.search(line):
                continue
            if is_comment_line(line):
                continue
            hit = (INLINE_CJK_FIELD_RE.search(line) or
                   INLINE_CJK_TEXT_RE.search(line))
            if not hit:
                continue
            # 行尾显式标记 -> 放行 (Phase 5 遗留, 跟规则 1 同哲学)
            if INLINE_ANNOTATION_RE.search(line):
                continue
            violations.append((p, line_no, line.strip()[:100]))
    return violations


def scan_rule3_cjk() -> list[tuple[str, int, str]]:
    """1.1.0 round 7c: 扫 lib/domain/ + lib/core/ 的 CJK 字面量源码行

    排除: strings.dart (规则 1 覆盖) / *.g.dart / 注释行。
    放行 (v1.1.0 R113 BUG A 修正后, 精确到行):
    1. `// rule3-whitelist: <行号/区间>` token 显式列出的行 (token 可
       在文件任何 comment 行, 惯例放文件头)
    2. 文件头 (前 20 行) 有标记时只豁免头 20 行本身 — 不再整文件豁免
    3. 本行或前 10 行注释含规则 3 标记
    """
    violations: list[tuple[str, int, str]] = []
    for sub in ('lib/domain', 'lib/core'):
        dir_path = ROOT / sub
        if not dir_path.exists():
            continue
        for p in sorted(dir_path.rglob('*.dart')):
            if p.name == 'strings.dart' or p.name.endswith('.g.dart'):
                continue
            try:
                lines = p.read_text(encoding='utf-8').splitlines()
            except (UnicodeDecodeError, OSError):
                continue
            # R113 BUG A: 精确豁免 token (显式行号) — 修前这里 header_marked
            # 整文件放行, 头注释提 "i18n keys" 的文件里任何行都漏网
            try:
                whitelisted = parse_rule3_whitelist(lines)
            except ValueError as e:
                violations.append((p, 1, f'rule3-whitelist 解析失败: {e}'))
                continue
            # 文件头前 20 行有标记 → 只豁免头 20 行 (本身几乎全是注释)
            header_marked = any(
                RULE3_MARKER_RE.search(comment_part(l)) for l in lines[:20]
            )
            for line_no, line in enumerate(lines, 1):
                if not CJK_RE.search(line):
                    continue
                if is_comment_line(line):
                    continue
                code = strip_comments(line)
                if not RULE3_STR_LIT_RE.search(code):
                    continue
                if line_no <= 20 and header_marked:
                    continue
                if line_no in whitelisted:
                    continue
                # 本行 + 前 10 行注释标记
                ctx = lines[max(0, line_no - 11):line_no]
                if RULE3_MARKER_RE.search(comment_part(line)):
                    continue
                if any(RULE3_MARKER_RE.search(comment_part(l)) for l in ctx):
                    continue
                violations.append((p, line_no, line.strip()[:100]))
    return violations


def main() -> int:
    exit_code = 0

    # ---- 规则 1: strings.dart static const ----
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
        print(f"[FAIL] check_strings_hardcoded (规则 1): {len(violations)} 处硬编中文无 i18n 标记")
        print(f"  文件: {STRINGS_FILE.relative_to(ROOT).as_posix()}")
        print(f"  规则 (R58 修正后):")
        print(f"    1. const 配对 xxxText({{String? override}}) 函数版 -> PASS (R57 模式)")
        print(f"    2. 否则: 必须前 10 行内含 'v1.0+ i18n' / 'TODO' / '走 l10n' 等标记")
        print(f"  详情:")
        for line_no, snippet in violations:
            print(f"    L{line_no}: {snippet}")
        exit_code = 1

    # ---- 规则 2 (R110 round 3): lib/** inline 硬编码 ----
    inline = scan_inline_cjk(ROOT / "lib")
    if inline:
        print(f"[FAIL] check_strings_hardcoded (规则 2, R110 round 3 新增): "
              f"{len(inline)} 处 widget inline 硬编码中文")
        print(f"  规则: `title/label/hintText/... : '中文'` 或 `Text('中文')`")
        print(f"    必须走 ARB key; 行尾带 '走 ARB' / 'TODO' / 'i18n' 注释可放行")
        for path, line_no, snippet in inline[:40]:
            print(f"    {path.relative_to(ROOT).as_posix()}:{line_no}: {snippet}")
        if len(inline) > 40:
            print(f"    ... 还有 {len(inline) - 40} 处")
        exit_code = 1

    # ---- 规则 3 (1.1.0 round 7c): domain/core CJK 字面量 ----
    rule3 = scan_rule3_cjk()
    if rule3:
        print(f"[FAIL] check_strings_hardcoded (规则 3, round 7c 新增): "
              f"{len(rule3)} 处 domain/core CJK 字面量无标记")
        print(f"  规则: lib/domain/ + lib/core/ 源码行 (去注释后) 含 CJK 字面量")
        print(f"    必须: 本行/前 10 行注释含 'i18n' / '走 l10n' / 'canonical fallback' /")
        print(f"    'v1.0+ i18n' 标记, 或文件头前 20 行有同款标记 (只豁免头 20 行, 修前整文件豁免),")
        print(f"    或行号精确豁免 token '// rule3-whitelist: 70,92' / '70-92' (R113 BUG A)")
        for path, line_no, snippet in rule3[:40]:
            print(f"    {path.relative_to(ROOT).as_posix()}:{line_no}: {snippet}")
        if len(rule3) > 40:
            print(f"    ... 还有 {len(rule3) - 40} 处")
        exit_code = 1

    if exit_code == 0:
        total_cn = len(STRING_ASSIGN_RE.findall(text))
        print(f"[OK] check_strings_hardcoded: 规则 1 = {total_cn} 处中文 static const/String "
              f"({total_override_pairs} 处 R57 override 配对 + 其余带 i18n 标记); "
              f"规则 2 (inline) = 0 处; 规则 3 (domain/core) = 0 处")
    return exit_code


if __name__ == '__main__':
    sys.exit(main())
