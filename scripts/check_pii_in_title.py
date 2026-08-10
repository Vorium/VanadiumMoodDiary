#!/usr/bin/env python3
# v0.30 R108 revisit (P0-012): check_pii_in_title 守门员
#
# 作用: 验证通知 title (锁屏可见) 不含 PII (药名 / 剂量 / 紧急联系人 / 病名)
#
# 背景: 精神心理 / 慢性病患者用 App, 通知在 iOS / Android 锁屏横幅
#   可见。title 含药名 = 路人瞥一眼知道用户吃的什么药, 触发病耻感
#   + 隐私侵犯。R108 P0-3 修了 body, R108 revisit P0-012 修了 title
#   (6 视角共识)。
#
# 规则:
#   1. lib/core/l10n/strings.dart 的 notif*Title 函数**不应**有 medName
#      / medicationName / patientName / contactName 等 PII 字段参数
#      (签名不收 PII 数据 = 编译期防泄漏)
#   2. 已有 title 字符串不直接含 "药名" / "<name>" / "$medName" 等动态注入
#   3. lib/presentation/ 调用 notif*Title() 不传 med.name (defence in depth)
#
# 退出: 0 = pass, 1 = fail
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

# 规则 1: lib/core/l10n/strings.dart notif*Title 函数**不应**有 medName 参数
strings_file = PROJECT_ROOT / 'lib' / 'core' / 'l10n' / 'strings.dart'
if strings_file.exists():
    content = strings_file.read_text(encoding='utf-8')

    # 找所有 notif*Title 函数签名 + body
    title_func_pattern = re.compile(
        r'static\s+String\s+(notif\w*Title)\s*\(([^)]*)\)\s*=>\s*\n?\s*override\s*\?\?\s*[\'"]([^\'"]*)[\'"]',
        re.MULTILINE,
    )
    for match in title_func_pattern.finditer(content):
        func_name = match.group(1)
        params = match.group(2)
        body = match.group(3)

        # PII 字段名黑名单
        pii_fields = ['medName', 'medicationName', 'patientName',
                      'contactName', 'name', 'diseaseName']
        for pii in pii_fields:
            # 形参: `String medName,` 或 `String? medName,` 等
            if re.search(rf'String\s+{pii}\b', params):
                FAILURES.append(
                    f'[FAIL] {strings_file.relative_to(PROJECT_ROOT)} '
                    f':: {func_name}() 接收 PII 参数 `{pii}`, 锁屏 title 会泄漏 PII'
                )
            # body 模板里直接拼了 PII 字段 (例如 "💊 该吃药了：$medName")
            if f'${pii}' in body:
                FAILURES.append(
                    f'[FAIL] {strings_file.relative_to(PROJECT_ROOT)} '
                    f':: {func_name}() body 含 `${pii}`, 锁屏 title 会泄漏 PII'
                )

# 规则 2: lib/ 调 notif*Title() 不传 med.name (defence in depth)
lib_dir = PROJECT_ROOT / 'lib'
title_func_names = ['notifMedicationTitle', 'notifRefillTitle']
if lib_dir.exists():
    for dart_file in lib_dir.rglob('*.dart'):
        # 跳过 strings.dart 自己
        if dart_file.name == 'strings.dart':
            continue
        text = dart_file.read_text(encoding='utf-8', errors='ignore')
        for func_name in title_func_names:
            # 找所有调 `funcName(...)` 位置, 检查参数列表里是否有 PII 字段
            call_pattern = re.compile(rf'\b{func_name}\s*\(([^)]*)\)')
            for call_match in call_pattern.finditer(text):
                args = call_match.group(1).strip()
                if not args:
                    continue
                # 检查参数列表里 PII 字段名 (简化: 包含 "name" 子串的实参)
                if re.search(r'\b\w*[Nn]ame\b', args):
                    FAILURES.append(
                        f'[FAIL] {dart_file.relative_to(PROJECT_ROOT)} '
                        f':: 调 `{func_name}({args})`, 传了含 "name" 的实参, '
                        f'锁屏 title 会泄漏 PII'
                    )

# 输出
if FAILURES:
    print('=' * 60)
    print('[check_pii_in_title.py] FAIL')
    print('=' * 60)
    for f in FAILURES:
        print(f)
    print('=' * 60)
    print(f'共 {len(FAILURES)} 项违规。锁屏 PII 泄漏风险。')
    print('修复: notif*Title() 签名去掉 PII 参数, body 不再拼 PII 字段。')
    sys.exit(1)
else:
    print('[check_pii_in_title.py] OK — 锁屏通知 title 0 PII 泄漏')
    sys.exit(0)
