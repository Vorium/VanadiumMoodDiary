#!/usr/bin/env python3
"""扫描所有 .dart 文件，找出 '同函数多次 DateTime.now()' 的潜在 race。

v0.23 (Round 37) 修: 之前脚本把 `// 之前 3 次 DateTime.now()` 注释里的字面量
也算上,5 个文件误报。改成"strip 注释后 5 行窗口内字面量 ≥ 2 次"。

v0.23 (P0-14) 修: ROOT 改相对路径, 兼容 CI (ubuntu) 和本地 (Windows)

修法:
1) 先去掉 // 之后内容
2) 多行 /// 块注释简单按行算 (/// 开头的)
3) 字面量匹配用 regex (DateTime 点 now 括号) 替代 in
"""
import os
import re
from pathlib import Path

ROOT = Path(os.getcwd()) / "lib"

# 字面量匹配: `DateTime.now()` (空格无关)
LITERAL_RE = re.compile(r'DateTime\.now\s*\(\s*\)')

# 单行注释前缀
LINE_COMMENT_PREFIXES = ('///', '//')


def strip_comment(line: str) -> str:
    """去掉 // / /// 之后内容 (粗略处理: 不解析字符串内的 //)"""
    for prefix in LINE_COMMENT_PREFIXES:
        idx = line.find(prefix)
        if idx >= 0:
            line = line[:idx]
    return line


race_files = []

for f in ROOT.rglob('*.dart'):
    if '.g.dart' in f.name or '.freezed.dart' in f.name:
        continue
    txt = f.read_text(encoding='utf-8')
    lines = txt.splitlines()
    for i, raw in enumerate(lines):
        # 跳过纯注释行 (但保留 inline 注释的代码部分)
        stripped = strip_comment(raw)
        if not LITERAL_RE.search(stripped):
            continue
        # 5 行窗口: 排除注释行后字面量 ≥ 2 次
        window = lines[max(0, i - 5):min(len(lines), i + 6)]
        count = sum(1 for w in window if LITERAL_RE.search(strip_comment(w)))
        if count >= 2:
            race_files.append((str(f.relative_to(ROOT.parent)), i + 1, count))
            break  # 一个文件只报一次

print(f'可疑同函数多次 DateTime.now() 文件数: {len(race_files)}')
for path, line, count in race_files:
    print(f'  {path}:{line}  窗口内 {count} 次')
