#!/usr/bin/env python3
# v0.30 R108 revisit (P0-012): check_pii_in_title 守门员
#
# 作用: 验证通知 title (锁屏可见) 不含 PII (药名 / 剂量 / 患者名 / 病名)
#
# 背景: 精神心理 / 慢性病患者用 App, 通知在 iOS / Android 锁屏横幅
#   可见。title 含药名 = 路人瞥一眼知道用户吃的什么药, 触发病耻感
#   + 隐私侵犯。R108 P0-3 修了 body, R108 revisit P0-012 修了 title
#   (6 视角共识)。
#
# 1.1.0 round 4c: 外联通知 (safety/contact) 随业务删除, 黑名单同步收窄。
#
# 1.1.0 round 7c (P2 gatekeeper): title_func_names 硬编码只含
#   notifMedicationTitle / notifRefillTitle, 漏 notifDailyCheckInTitle /
#   notifAssessmentTitle / notifMoodReminderTitle — 改成动态扫描
#   strings.dart 所有 `notif*Title` 声明 (const 版 + override 函数版,
#   body 正则同时放宽: `override ?? (字面量|constRef)` 两种都匹配)。
#
# 规则:
#   1. lib/core/l10n/strings.dart 的 notif*Title 函数**不应**有 medName
#      / medicationName / patientName / name / diseaseName 等 PII 字段参数
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

# PII 字段名黑名单 (形参 + body 插值两处检查)
PII_FIELDS = ['medName', 'medicationName', 'patientName',
              'name', 'diseaseName']

strings_file = PROJECT_ROOT / 'lib' / 'core' / 'l10n' / 'strings.dart'
detected_titles: set[str] = set()

if strings_file.exists():
    content = strings_file.read_text(encoding='utf-8')

    # 1a. const 声明版: `static const notifDailyCheckInTitle = '...'`
    const_decl_re = re.compile(
        r'static\s+const\s+(notif\w*Title)\s*=\s*[\'"]([^\'"]*)[\'"]',
    )
    for match in const_decl_re.finditer(content):
        const_name = match.group(1)
        literal = match.group(2)
        detected_titles.add(const_name)
        for pii in PII_FIELDS:
            if f'${pii}' in literal:
                FAILURES.append(
                    f'[FAIL] {strings_file.relative_to(PROJECT_ROOT)} '
                    f':: {const_name} 字面量含 `${pii}`, 锁屏 title 会泄漏 PII'
                )

    # 1b. override 函数版 (round 7c 放宽: 字面量 | constRef 两种 body 都匹配)
    #     `static String notifXxxTitle({String? override}) =>
    #        override ?? '字面量'  |  override ?? notifXxxTitle`
    title_func_re = re.compile(
        r'static\s+String\s+(notif\w*Title)\s*\(([^)]*)\)\s*=>\s*'
        r'override\s*\?\?\s*(?:[\'"]([^\'"]*)[\'"]|(\w+))',
    )
    for match in title_func_re.finditer(content):
        func_name = match.group(1)
        params = match.group(2)
        literal = match.group(3) or ''
        detected_titles.add(func_name)
        for pii in PII_FIELDS:
            # 形参: `String medName,` 或 `String? medName,` 等
            if re.search(rf'String\s+{pii}\b', params):
                FAILURES.append(
                    f'[FAIL] {strings_file.relative_to(PROJECT_ROOT)} '
                    f':: {func_name}() 接收 PII 参数 `{pii}`, 锁屏 title 会泄漏 PII'
                )
            # body 模板里直接拼了 PII 字段 (例如 "💊 该吃药了：$medName")
            if f'${pii}' in literal:
                FAILURES.append(
                    f'[FAIL] {strings_file.relative_to(PROJECT_ROOT)} '
                    f':: {func_name}() body 含 `${pii}`, 锁屏 title 会泄漏 PII'
                )

# 规则 2: lib/ 调 notif*Title() 不传 med.name (defence in depth)
# round 7c: 检测名单动态来自 strings.dart 扫描结果 (const 名 + 函数名,
# const 名无 () 调用所以无害, 覆盖 5/5 title 而不是硬编码 2/5)
title_func_names = sorted(detected_titles)
lib_dir = PROJECT_ROOT / 'lib'
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
    print(f'[check_pii_in_title.py] OK — 检测 {len(title_func_names)} 个通知 title 定义, 0 PII 泄漏')
    for name in title_func_names:
        print(f'  - {name}')
    sys.exit(0)
