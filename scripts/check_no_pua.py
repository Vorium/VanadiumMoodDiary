"""check_no_pua.py — Unicode PUA 字符守门员

PUA = Unicode Private Use Area (U+E000 - U+F8FF)
通常是 GBK 字节错误解读为 UTF-8 生成的乱码 (mojibake) 落在 PUA 范围内。

v0.22 round 31 修过 app_router.dart mojibake (commit 023d6ef?)。
v0.23 P0 评审(spen-1)发现无守护,本脚本加 CI 守门员防止重新引入。
v0.24 round 48 (spzh P1-15): 扩到 docs/ + scripts/ 目录
(v0.22 round 31 修过 app_router mojibake,但 docs/CHANGELOG.md 修真历史还有残留)

用法:
  python scripts/check_no_pua.py            # 全检 (lib/ + docs/ + scripts/)
  python scripts/check_no_pua.py --ci       # CI 模式, exit code 1 if violation
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.getcwd())

# v0.24 round 48 (spzh P1-15): 扩到 3 个目录
SCAN_DIRS = ["lib", "docs", "scripts"]

# PUA 范围: U+E000 - U+F8FF (Private Use Area)
# 包含 Supplementary Private Use Area-A 部分 (U+F0000+) 暂不检
# (Flutter 源码基本不用扩展 PUA,过宽会误报 emoji 等)
PUA_RE = re.compile(r'[\uE000-\uF8FF]')

# 跳过文件 (生成文件 / binary / 历史修真档案)
SKIP_PATTERNS = ['.g.dart', '.freezed.dart', '.png', '.jpg', '.ico', '.jar']

# v0.24 round 48 (spzh P1-15): 历史修真档案豁免
# docs/reviews/ 和 docs/archive/reviews/ 故意记录 mojibake 现象作为"修真前状态"
# 修真历史档案保留原样（"实际看到的 mojibake" 反引号块 + 对照正确字符）
# v0.24 round 48 (spzh P1-20): docs/decisions/ 也豁免 — mojibake 修真历史归档
SKIP_PATHS = [
    re.compile(r'docs[\\/]reviews[\\/].*\.md$'),
    re.compile(r'docs[\\/]archive[\\/].*\.md$'),
    re.compile(r'docs[\\/]decisions[\\/].*\.md$'),
]

# 扫的扩展名
SCAN_EXTS = ['.dart', '.md', '.py', '.yaml', '.yml', '.json', '.arb', '.sh', '.bat', '.ps1']


def scan_file(path: Path):
    """返回 list of (line_no, col, char) 的 PUA 命中"""
    try:
        text = path.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        return []
    hits = []
    for line_no, line in enumerate(text.splitlines(), 1):
        for col, ch in enumerate(line, 1):
            if PUA_RE.match(ch):
                hits.append((line_no, col, ch))
    return hits


def main():
    ci_mode = '--ci' in sys.argv

    all_files = []
    for scan_dir in SCAN_DIRS:
        dir_path = ROOT / scan_dir
        if not dir_path.exists():
            continue
        for ext in SCAN_EXTS:
            all_files.extend(dir_path.rglob(f"*{ext}"))
    # 跳过生成文件 + 历史修真档案
    all_files = [f for f in all_files if not any(pat in f.name for pat in SKIP_PATTERNS)]
    all_files = [
        f for f in all_files
        if not any(skip_p.search(f.relative_to(ROOT).as_posix()) for skip_p in SKIP_PATHS)
    ]

    total_pua = 0
    for f in all_files:
        hits = scan_file(f)
        if not hits:
            continue
        rel = f.relative_to(ROOT)
        for line_no, col, ch in hits:
            print(f'  {rel}:{line_no}:{col}  PUA U+{ord(ch):04X}')
            total_pua += 1

    if total_pua == 0:
        print(f'[OK] check_no_pua: 0 PUA characters ({"/".join(SCAN_DIRS)}/ 全部干净)')
        return 0

    print(f'[FAIL] check_no_pua: {total_pua} PUA 字符命中 (通常是 mojibake 残留)')
    print('  修法: 用 sed/python 把 PUA 字符替换成正确 UTF-8 中文')
    if ci_mode:
        return 1
    return 1


if __name__ == '__main__':
    sys.exit(main())
