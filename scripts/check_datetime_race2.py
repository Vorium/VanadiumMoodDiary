#!/usr/bin/env python3
"""精确扫: 同函数体内裸调 DateTime.now() 出现 >=2 次（没用 final now 缓存）

v0.23 (P0-14): 改 ROOT 为相对路径, 兼容 CI (ubuntu) 和本地 (Windows)
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.getcwd()) / "lib"
# 函数体匹配: 找 `() { ... }` 块, 统计 `DateTime.now()` 出现次数
# Dart 函数通常有返回类型, 找 `... {` 开头 + `}` 结尾 (粗略花括号匹配)

races = []

for f in ROOT.rglob('*.dart'):
    if '.g.dart' in f.name or '.freezed.dart' in f.name:
        continue
    txt = f.read_text(encoding='utf-8')
    lines = txt.splitlines()

    # 用栈模拟花括号匹配
    brace_depth = 0
    in_func_start = -1
    func_brace_level = -1
    func_now_count = 0
    func_now_lines = []

    for i, line in enumerate(lines):
        # 找函数起点: `Future<X> name(...) {` 或 `X name(...) {` 或 `=> {`
        # 简化: 检测 `{` 深度变化
        for ch_idx, ch in enumerate(line):
            if ch == '{':
                if brace_depth == 0:
                    # 进入新作用域 (可能是函数体)
                    # 检查上一行是否函数签名
                    if i > 0 and ('(' in lines[i-1] or '=>' in lines[i-1] or 'async' in lines[i]):
                        in_func_start = i
                        func_brace_level = 1
                        func_now_count = 0
                        func_now_lines = []
                else:
                    if in_func_start >= 0:
                        func_brace_level += 1
                brace_depth += 1
            elif ch == '}':
                brace_depth -= 1
                if in_func_start >= 0 and func_brace_level == 0:
                    # 函数结束
                    if func_now_count >= 2:
                        # 检查是否用了 `final now = DateTime.now()` 模式
                        # (如果函数体有 final/var now = DateTime.now() 单独一行,算 single-capture)
                        single_capture = any(
                            re.search(r'\b(?:final|var)\s+now\s*=\s*DateTime\.now\(\)', lines[l-1])
                            for l in func_now_lines
                        )
                        if not single_capture:
                            races.append((str(f.relative_to(ROOT.parent)),
                                          in_func_start + 1,
                                          func_now_count,
                                          func_now_lines))
                    in_func_start = -1
                    func_brace_level = -1
                    func_now_count = 0
                    func_now_lines = []
                if in_func_start >= 0:
                    func_brace_level -= 1
        # 在函数体内统计 DateTime.now() 调用
        if in_func_start >= 0 and 'DateTime.now()' in line:
            func_now_count += 1
            func_now_lines.append(i + 1)

print(f'真可疑 race (同函数 >=2 次 DateTime.now() 且没用 single-capture): {len(races)}')
for path, line, count, lines_list in races:
    print(f'  {path}:{line}  出现 {count} 次 (lines: {lines_list})')
