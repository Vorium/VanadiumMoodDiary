"""P1-1 fix: 把 lib/ 下 30+ 处裸 `CircularProgressIndicator()` 替换成
`LoadingSpinner()` / `LoadingSkeleton.fullScreen()`。

模式:
- Center(child: CircularProgressIndicator()) -> LoadingSkeleton.fullScreen()
- SizedBox + CircularProgressIndicator (with strokeWidth) -> LoadingSpinner(size: N)
- 独立 CircularProgressIndicator() -> LoadingSpinner()

每个替换前先看上下文,只改简单模式。
"""
import os
import re
import sys

ROOT = "lib"

# 模式 1: Center(child: CircularProgressIndicator())
#  → LoadingSkeleton.fullScreen()
PATTERN_FULLSCREEN = re.compile(
    r"Center\(child:\s*const\s*Center\(child:\s*CircularProgressIndicator\(\)\)\)"
)
REPL_FULLSCREEN = "LoadingSkeleton.fullScreen()"

# 模式 2: Center(child: CircularProgressIndicator())
PATTERN_CENTER = re.compile(
    r"Center\(child:\s*CircularProgressIndicator\(\)\)"
)
REPL_CENTER = "LoadingSkeleton.fullScreen()"

# 模式 3: SizedBox(尺寸) + CircularProgressIndicator(strokeWidth: N)
# 太复杂,留作手动

def fix_file(path: str) -> int:
    with open(path, encoding="utf-8") as f:
        content = f.read()
    new_content = content
    count = 0
    for pat, repl in [(PATTERN_CENTER, REPL_CENTER), (PATTERN_FULLSCREEN, REPL_FULLSCREEN)]:
        new_content, n = pat.subn(repl, new_content)
        count += n
    if count > 0:
        with open(path, "w", encoding="utf-8") as f:
            f.write(new_content)
    return count


def main() -> int:
    total = 0
    for dirpath, dirnames, filenames in os.walk(ROOT):
        for f in filenames:
            if not f.endswith(".dart"):
                continue
            full = os.path.join(dirpath, f)
            n = fix_file(full)
            if n > 0:
                print(f"  {full}: {n} replacements")
                total += n
    print(f"Total: {total} replacements")
    return 0


if __name__ == "__main__":
    sys.exit(main())
