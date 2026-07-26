"""check_no_hardcoded_utc.py — UTC 时区硬编码守门员

防 P0-4 (spen v0.24 round 48) 回归:
之前 `lib/domain/logic/email_template.dart:67-69` 硬编码 `(UTC+8 北京时间)` →
海外紧急联系人看到错误时区,被误读成"未来时间已发生",PIPL §17 数据准确性合规红线。

v0.24 round 48 (spen P0-4 fix): 用 `referenceNow.timeZoneOffset` 推断 caller 视角时区。
本守门员: 扫所有 .dart 文件,命中 `(UTC+` / `+08:00` / `(GMT` / `北京时` / `东京时` 硬编码字面量 → 报错。

用法:
  python scripts/check_no_hardcoded_utc.py            # 全检
  python scripts/check_no_hardcoded_utc.py --ci       # CI 模式, exit code 1 if violation
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.getcwd()) / "lib"

# 硬编码时区字面量
# 注意: 排除"用 caller 传入的 referenceNow.timeZoneOffset 动态推断" 的代码
PATTERNS = [
    (re.compile(r'\(UTC\+[0-9]+'), "硬编码 UTC+X"),
    (re.compile(r'\(UTC-[0-9]+'), "硬编码 UTC-X"),
    (re.compile(r'\(GMT'), "硬编码 GMT 字面量"),
    (re.compile(r'北京时间'), "硬编码 '北京时间' 字面量"),
    (re.compile(r'东京时'), "硬编码 '东京时' 字面量"),
    (re.compile(r'伦敦时'), "硬编码 '伦敦时' 字面量"),
    (re.compile(r'纽约时'), "硬编码 '纽约时' 字面量"),
    (re.compile(r'洛杉矶时'), "硬编码 '洛杉矶时' 字面量"),
]

# 白名单: 这些行号 (file:line) 已知是动态推断代码,不算硬编码
WHITELIST_LINES = [
    # email_template.dart 的 _formatDateTime 动态推断 referenceNow.timeZoneOffset
    r'lib/domain/logic/email_template\.dart:\d+',
    # 测试文件
    r'test/.*\.dart:\d+',
]


def scan_file(path: Path):
    """返回 list of (line_no, col, pattern_name, snippet) 的硬编码时区命中"""
    try:
        text = path.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError):
        return []
    hits = []
    for line_no, line in enumerate(text.splitlines(), 1):
        # 跳过注释 (简单判断: 行首 // 或 #)
        stripped = line.strip()
        if stripped.startswith('//') or stripped.startswith('#') or stripped.startswith('*'):
            continue
        for pat, name in PATTERNS:
            m = pat.search(line)
            if m:
                rel = path.relative_to(ROOT.parent).as_posix()
                # 检查白名单
                key = f"{rel}:{line_no}"
                if any(re.match(w, key) for w in WHITELIST_LINES):
                    continue
                hits.append((line_no, m.start(), name, line.strip()[:80]))
    return hits


def main():
    ci_mode = '--ci' in sys.argv

    files = sorted(ROOT.rglob('*.dart'))
    # 跳过生成文件
    files = [f for f in files if '.g.dart' not in f.name and '.freezed.dart' not in f.name]

    total = 0
    for f in files:
        hits = scan_file(f)
        if not hits:
            continue
        rel = f.relative_to(ROOT.parent)
        for line_no, col, name, snippet in hits:
            print(f"  {rel}:{line_no}:{col}  {name}")
            print(f"    {snippet}")
            total += 1

    if total == 0:
        print('[OK] check_no_hardcoded_utc: 0 硬编码时区 (lib/ 全部 .dart 干净)')
        return 0

    print(f'[FAIL] check_no_hardcoded_utc: {total} 硬编码时区命中')
    print('  修法: 用 caller 传入的 timeZoneOffset 动态推断,不要写死 UTC±X')
    print('  例子: lib/domain/logic/email_template.dart _formatDateTime(referenceNow: ...)')
    return 1


if __name__ == '__main__':
    sys.exit(main())
