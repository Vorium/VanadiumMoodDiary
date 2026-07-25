#!/usr/bin/env python3
"""P1-16: 检查 lib/ 下中文文案(string literal 内)是否用全角标点

ASCII 半角标点在中文字符串中视觉不专业。例:
  ❌ Text('今天吃药了吗?')   (问号应该是 ？)
  ❌ body: '加载失败: $e'    (冒号应该是 ：)
  ❌ Text('选了 PHQ-9 / GAD-7')  (斜杠应该是 ／)
  ❌ body: '加载中…'          (省略号应该是 ……)
  ✅ Text('今天吃药了吗？')
  ✅ body: '加载失败：$e'
  ✅ Text('选了 PHQ-9 ／ GAD-7')
  ✅ body: '加载中……')

只检查 string literal ('...' 或 "...") 里的中文字符,注释里的标点
(中英混排的"see commit, refactor"等)不查,避免噪音。

v0.24 round 43 (C-01 P1): ASCII_PUNCT 从 4 种 [;!?] 扩到 7 种
(+, /, (, ) 4 种新增)。+ 加 1 种独立的 省略号 (\\u2026) 检查。
总计 9 种 (4 原有 + 3 新增 + 1 已有 : + 1 新增 …)。

扫描范围 v0.24 round 43 (C-06 P2): 从仅 .dart 扩到 .dart + .arb。
ARB 是 UI 文案源, 半角/全角问题源头在 ARB, 一起扫才能闭环。
"""
import os
import re
import sys

# Windows GBK terminal 下 print 中文会乱码, force UTF-8 stdout
# Linux/macOS 默认 UTF-8, 不受影响
if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        # Python < 3.7 没 reconfigure, 走 PYTHONIOENCODING 环境变量
        pass

CJK = r"[\u4e00-\u9fff]"
# v0.24 round 43 (C-01 P1): 从 4 种扩到 7 种
# 原: , ; ! ?
# 新增: / 半角斜杠 (量表名 PHQ-9 / GAD-7, 时间窗口 7/30/90, 品牌列表 小米/华为/...)
#       ( 半角左括号
#       ) 半角右括号
ASCII_PUNCT = r"[,;!?/()]"

# 独立检查的标点 (不在 ASCII_PUNCT 里, 因为有特殊语义)
# - : 半角冒号 (保留独立 pattern, 避免在 URL / 时间格式里误报)
# - … 半角省略号 (U+2026, 1 字符) 应是全角 (……, 2 字符)
ELLIPSIS = r"\u2026"

# 文件扩展名: dart + arb
EXTENSIONS = (".dart", ".arb")

STRING_PATTERNS = [
    # ASCII 半角标点 (7 种: ,;!?/())
    (re.compile(rf"'([^']*{CJK}){ASCII_PUNCT}({CJK}[^']*)'"),
     "半角标点 (,;!?/()), 应该是全角（，；！？／（））"),
    (re.compile(rf'"([^"]*{CJK}){ASCII_PUNCT}({CJK}[^"]*)"'),
     "半角标点 (,;!?/()), 应该是全角（，；！？／（））"),
    # 半角冒号 (独立 pattern, 避免误报)
    (re.compile(rf"'([^']*{CJK}):({CJK}[^']*)'"),
     "半角冒号 :, 应该是全角 ："),
    (re.compile(rf'"([^"]*{CJK}):({CJK}[^"]*)"'),
     "半角冒号 :, 应该是全角 ："),
    # 半角省略号 … (U+2026) — 应是全角 ……
    # 模式: 中文上下文里出现 … 即可（不要求两侧都有 CJK，末尾 加载中… 也算）
    (re.compile(rf"'([^']*{CJK}[^']*){ELLIPSIS}([^']*)'"),
     "半角省略号 …, 应该是全角（……）"),
    (re.compile(rf'"([^"]*{CJK}[^"]*){ELLIPSIS}([^"]*)"'),
     "半角省略号 …, 应该是全角（……）"),
]

SKIP_DIRS = {
    ".dart_tool", "build", "ios", "android", "macos",
    "windows", "linux", "web", "test_driver", ".git",
}


def find_offenders(root: str) -> list:
    issues = []
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [d for d in dirnames if d not in SKIP_DIRS]
        for f in filenames:
            if not f.endswith(EXTENSIONS):
                continue
            full = os.path.join(dirpath, f)
            try:
                with open(full, encoding="utf-8") as fp:
                    for lineno, line in enumerate(fp, 1):
                        for pat, msg in STRING_PATTERNS:
                            for m in pat.finditer(line):
                                issues.append(
                                    (full, lineno, msg, m.group(0))
                                )
            except (UnicodeDecodeError, OSError):
                continue
    return issues


def main() -> int:
    lib_dir = os.path.join(os.getcwd(), "lib")
    if not os.path.isdir(lib_dir):
        print(f"[FAIL] lib/ not found at {lib_dir}", file=sys.stderr)
        return 1

    issues = find_offenders(lib_dir)
    if not issues:
        print("[OK] check_fullwidth_punctuation: 0 violations")
        return 0

    # v0.23 (P0-14): --ci 模式 exit 1 让 CI 强制拦截
    # 默认 (--warn-only) 仅打印提示, exit 0
    strict = "--ci" in sys.argv
    for full, lineno, msg, snippet in issues[:10]:
        rel = os.path.relpath(full, os.getcwd())
        print(f"  {rel}:{lineno}: {msg}")
    if len(issues) > 10:
        print(f"  ... and {len(issues) - 10} more")
    if strict:
        print(f"[FAIL] check_fullwidth_punctuation: {len(issues)} violations (CI strict mode)")
        return 1
    print(f"[WARN] check_fullwidth_punctuation: {len(issues)} violations (--warn-only, 不强制)")
    return 0  # 默认 --warn-only, 不强制


if __name__ == "__main__":
    sys.exit(main())
