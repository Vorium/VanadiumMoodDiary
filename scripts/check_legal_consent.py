#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #3 / spzh C-09): check_legal_consent 守门员
#
# 作用: 验证 `lib/presentation/pages/setup/setup_legal_dialog.dart` 不含
#   `TODO` / `PIPL §13 单独同意` (等法务合规 token)
#
# 背景: spzh v0.25 round 56h P0 报告: PIPL §13 单独同意 0 实施 (R55 留 TODO)。
#   守门员: 扫 setup_legal_dialog.dart, 命中 TODO / "PIPL §13 单独同意" 字符串 → 报 [FAIL]
#   修真方法:
#     - TODO 去掉 (走 implemented 流程)
#     - 或 PIPL §13 单独同意 实现后, 注释里改 "✅ 已实施" 之类
#
# 范围: lib/presentation/pages/setup/setup_legal_dialog.dart 单文件
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
LEGAL_DIALOG = ROOT / "lib" / "presentation" / "pages" / "setup" / "setup_legal_dialog.dart"

# 严格匹配 (R57 时这 2 个 token 必须都已经处理掉):
#   - TODO        → 还留 TODO 注释 → 报 fail
#   - PIPL §13 单独同意 (在 setup_legal_dialog.dart 上下文里意味着还没实施)
PATTERNS = [
    (re.compile(r'\bTODO\b'), 'TODO 标记 (修真: 改 implemented 流程)'),
    (re.compile(r'PIPL\s*§13\s*单独同意'), 'PIPL §13 单独同意 TODO (修真: 实施 + 改 ✅)'),
]

# 允许豁免的行模式 (注释里写 "已实施" / "✅ done" 之类)
# 例: `// ✅ PIPL §13 单独同意已实施 (R60)`
EXEMPT_LINE_RE = re.compile(r'✅|已实施|implemented|done|R\d+')


def scan_file(path: Path) -> list[tuple[int, str, str]]:
    """返回 list of (line_no, pattern_name, snippet)"""
    try:
        text = path.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        return []
    hits = []
    for line_no, line in enumerate(text.splitlines(), 1):
        # 跳过纯注释豁免 (✅/已实施 标记)
        if EXEMPT_LINE_RE.search(line):
            continue
        for pat, name in PATTERNS:
            if pat.search(line):
                hits.append((line_no, name, line.strip()[:80]))
    return hits


def main() -> int:
    if not LEGAL_DIALOG.exists():
        print(f"[FAIL] 找不到 {LEGAL_DIALOG}")
        return 1

    hits = scan_file(LEGAL_DIALOG)
    if hits:
        print(f"[FAIL] check_legal_consent: {len(hits)} 处未实施 token")
        print(f"  文件: {LEGAL_DIALOG.relative_to(ROOT).as_posix()}")
        print(f"  修真: TODO 走 implemented, PIPL §13 单独同意实施后改 ✅ 标记")
        print(f"  详情:")
        for line_no, name, snippet in hits:
            print(f"    L{line_no}: [{name}] {snippet}")
        return 1

    print(f"[OK] check_legal_consent: {LEGAL_DIALOG.relative_to(ROOT).as_posix()} "
          f"无 TODO / 无 PIPL §13 单独同意 TODO")
    return 0


if __name__ == '__main__':
    sys.exit(main())
