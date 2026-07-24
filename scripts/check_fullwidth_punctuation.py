#!/usr/bin/env python3
"""P1-16: 检查 lib/ 下中文文案(string literal 内)是否用全角标点

ASCII 半角标点在中文字符串中视觉不专业。例:
  ❌ Text('今天吃药了吗?')   (问号应该是 ？)
  ❌ body: '加载失败: $e'    (冒号应该是 ：)
  ✅ Text('今天吃药了吗？')
  ✅ body: '加载失败：$e'

只检查 string literal ('...' 或 "...") 里的中文字符,注释里的标点
(中英混排的"see commit, refactor"等)不查,避免噪音。
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
ASCII_PUNCT = r"[,;!?]"

STRING_PATTERNS = [
    (re.compile(rf"'([^']*{CJK}){ASCII_PUNCT}({CJK}[^']*)'"),
     "半角标点 (,;!?), 应该是全角(，；！？)"),
    (re.compile(rf'"([^"]*{CJK}){ASCII_PUNCT}({CJK}[^"]*)"'),
     "半角标点 (,;!?), 应该是全角(，；！？)"),
    (re.compile(rf"'([^']*{CJK}):({CJK}[^']*)'"),
     "半角冒号 :, 应该是全角 ："),
    (re.compile(rf'"([^"]*{CJK}):({CJK}[^"]*)"'),
     "半角冒号 :, 应该是全角 ："),
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
            if not f.endswith(".dart"):
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
