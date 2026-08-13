#!/usr/bin/env python3
# v0.32 round 8 (R111 AS-16 fix): check_review_information_todo 守门员
#
# 作用: 验证 fastlane/metadata/ios/review_information/ 无未标记的 TODO /
#   placeholder 回退 + notes.txt 版本号跟 pubspec.yaml 同步。
#
# 背景: R108 P0-004 / SUBMISSION_INFO.md:34 计划本守门员 (防 AS-01 回退:
#   review_information 曾出现 4 TODO 占位被 Apple 拒)。R32 hotfix P0-01
#   修了 4 占位, 但无防回退机制。AS-16: 未建本脚本 = 回归风险。
#
# 规则:
#   1. 4 个联系人文件不允许出现**未标记**占位符
#      (TODO / TBD / PLACEHOLDER / xxx / 待填 / XXXX / example.com 等)。
#      唯一豁免: 以 "[REPLACE_BEFORE_APPLE_REVIEW:" 开头的**有标记**占位
#      (SUBMISSION_INFO.md 登记在案的外部依赖, warn-only)。
#   2. 版本号: notes.txt 第 1 行 "App Reviewer Guide — ChronicCare X"
#      必须等于 pubspec.yaml 的 version 字段。
#   3. 文件存在性 (AS-24): 4 个联系人文件缺任一 = FAIL;
#      notes.txt / demo_user.txt 必须非空 (删文件/清空会静默回退)。
#
# 退出: 0 = pass, 1 = fail (未标记占位 = fail, 有标记占位 = warn 不 fail)
import io
import re
import sys
from pathlib import Path

if sys.platform == 'win32':
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

PROJECT_ROOT = Path(__file__).parent.parent
FAILURES: list[str] = []
WARNINGS: list[str] = []

REVIEW_DIR = PROJECT_ROOT / 'fastlane' / 'metadata' / 'ios' / 'review_information'

# 未标记占位符黑名单 (有标记的 [REPLACE_BEFORE_APPLE_REVIEW: ...] 豁免)
UNMARKED_PATTERNS = [
    (re.compile(r'\bTODO\b', re.IGNORECASE), 'TODO'),
    (re.compile(r'\bTBD\b', re.IGNORECASE), 'TBD'),
    (re.compile(r'\bPLACEHOLDER\b', re.IGNORECASE), 'PLACEHOLDER'),
    (re.compile(r'\bxxx\b', re.IGNORECASE), 'xxx'),
    (re.compile(r'待填'), '待填'),
    (re.compile(r'\bX{4,}\b'), 'XXXX'),
    (re.compile(r'example\.com', re.IGNORECASE), 'example.com 占位邮箱'),
]
SANCTIONED_MARKER = '[REPLACE_BEFORE_APPLE_REVIEW:'

if REVIEW_DIR.exists():
    for txt in sorted(REVIEW_DIR.glob('*.txt')):
        content = txt.read_text(encoding='utf-8', errors='ignore')
        rel = txt.relative_to(PROJECT_ROOT)
        for line_no, line in enumerate(content.splitlines(), 1):
            # 有标记占位: warn-only (外部依赖, SUBMISSION_INFO.md 登记)
            if line.strip().startswith(SANCTIONED_MARKER):
                WARNINGS.append(
                    f'[warn] {rel}:{line_no} 有标记占位未填 (外部依赖) — '
                    f'{line.strip()[:60]}...'
                )
                continue
            for pattern, name in UNMARKED_PATTERNS:
                if pattern.search(line):
                    FAILURES.append(
                        f'[FAIL] {rel}:{line_no} 未标记占位符 `{name}` — '
                        f'会被 Apple 拒 (AS-01 回归)'
                    )
                    break
else:
    FAILURES.append('[FAIL] fastlane/metadata/ios/review_information/ 不存在')

# 规则 3 (AS-24): 4 联系人文件存在性 + notes.txt / demo_user.txt 非空断言
REQUIRED_FILES = ['first_name.txt', 'last_name.txt', 'email_address.txt', 'phone_number.txt']
NON_EMPTY_FILES = ['notes.txt', 'demo_user.txt']
for name in REQUIRED_FILES:
    if not (REVIEW_DIR / name).exists():
        FAILURES.append(
            f'[FAIL] fastlane/metadata/ios/review_information/{name} 缺失 — '
            f'fastlane 上传时会跳过该字段 (AS-01 回归)'
        )
for name in NON_EMPTY_FILES:
    path = REVIEW_DIR / name
    if not path.exists():
        FAILURES.append(f'[FAIL] fastlane/metadata/ios/review_information/{name} 缺失')
    elif not path.read_text(encoding='utf-8', errors='ignore').strip():
        FAILURES.append(
            f'[FAIL] fastlane/metadata/ios/review_information/{name} 为空 — '
            f'上传空白 reviewer 说明会被 Apple 拒'
        )

# 规则 2: notes.txt 版本号 = pubspec.yaml version
pubspec = PROJECT_ROOT / 'pubspec.yaml'
notes = REVIEW_DIR / 'notes.txt'
if pubspec.exists() and notes.exists():
    pubspec_text = pubspec.read_text(encoding='utf-8')
    m = re.search(r'^version:\s*(\S+)', pubspec_text, re.MULTILINE)
    pubspec_version = m.group(1) if m else None
    first_line = notes.read_text(encoding='utf-8', errors='ignore').splitlines()[0]
    m2 = re.search(r'ChronicCare\s+(.+)$', first_line)
    notes_version = m2.group(1).strip() if m2 else None
    if pubspec_version is None:
        FAILURES.append('[FAIL] pubspec.yaml 无 version 字段')
    elif notes_version != pubspec_version:
        FAILURES.append(
            f'[FAIL] notes.txt 版本 {notes_version!r} != pubspec '
            f'{pubspec_version!r} (R32 P0-02 回归)'
        )
    else:
        print(f'[ok] notes.txt 版本 {notes_version} 与 pubspec 同步')

if FAILURES:
    print('=' * 60)
    print('[check_review_information_todo.py] FAIL')
    print('=' * 60)
    for f in FAILURES:
        print(f)
    for w in WARNINGS:
        print(w)
    print('=' * 60)
    print(f'共 {len(FAILURES)} 项违规 (未标记占位 = Apple 拒风险)。')
    print('修复: 填真实信息, 或改用有标记 [REPLACE_BEFORE_APPLE_REVIEW: ...] '
          '占位并在 SUBMISSION_INFO.md 登记。')
    sys.exit(1)
else:
    print('[check_review_information_todo.py] OK — review_information 0 未标记占位')
    for w in WARNINGS:
        print(w)
    sys.exit(0)
