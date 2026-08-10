#!/usr/bin/env python3
# v0.30 R108 revisit (P0-020): check_apple_health_claim 守门员
#
# 作用: 验证项目**没有**声明 / 集成 Apple Health / HealthKit 但不接的实际代码
#   (避免 Apple 5.1.3 used-but-not-declared / declared-but-not-used 抽审拒)
#
# 背景: R107 PrivacyInfo.xcprivacy 声明了 NSPrivacyCollectedDataTypeHealthAndFitness
#   但**没有**集成 HealthKit (pubspec 无 health_kit, Runner.entitlements 空,
#   Info.plist 无 NSHealthShareUsageDescription) → 5.1.3 拒审风险。
#   R108 修法: 删 HealthAndFitness 声明 + 加本守门员防回退。
#
# 规则:
#   1. PrivacyInfo.xcprivacy 不应含 NSPrivacyCollectedDataTypeHealthAndFitness
#   2. lib/ 不应含 `import 'package:health_kit/...'` / `import 'package:health/...'`
#      (等真接 HealthKit 时再加回)
#   3. Info.plist 不应含 NSHealthShareUsageDescription (除非真接)
#   4. pubspec.yaml 不应含 health_kit 依赖
#
# 例外: docs/superpowers/ + docs/audit*/ 文档可提"Apple Health"(设计意图),
#   本守门员只扫代码 + iOS 配置, 不扫文档。
#
# 退出: 0 = pass, 1 = fail
import io
import re
import sys
from pathlib import Path

# Windows GBK console: 强制 utf-8 stdout
if sys.platform == 'win32':
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

PROJECT_ROOT = Path(__file__).parent.parent
FAILURES: list[str] = []

# 规则 1: PrivacyInfo.xcprivacy 不应含 HealthAndFitness
privacy_info = PROJECT_ROOT / 'ios' / 'Runner' / 'PrivacyInfo.xcprivacy'
if privacy_info.exists():
    content = privacy_info.read_text(encoding='utf-8')
    if 'NSPrivacyCollectedDataTypeHealthAndFitness' in content:
        FAILURES.append(
            f'[FAIL] {privacy_info.relative_to(PROJECT_ROOT)}: 含 NSPrivacyCollectedDataTypeHealthAndFitness, '
            f'Apple 5.1.3 used-but-not-declared 抽审风险 (P0-020 修复方案: 删该 dict)'
        )

# 规则 2: lib/ 不应 import health_kit / health 包
lib_dir = PROJECT_ROOT / 'lib'
if lib_dir.exists():
    for dart_file in lib_dir.rglob('*.dart'):
        text = dart_file.read_text(encoding='utf-8', errors='ignore')
        for pattern in [
            r"import\s+'package:health_kit/",
            r"import\s+'package:health/",
        ]:
            if re.search(pattern, text):
                FAILURES.append(
                    f'[FAIL] {dart_file.relative_to(PROJECT_ROOT)}: 引用了 health_kit/health 库, '
                    f'但 Info.plist 无 NSHealthShareUsageDescription → Apple 5.1.3 拒审'
                )
                break

# 规则 3: Info.plist 不应含 NSHealthShareUsageDescription (除非真接)
info_plist = PROJECT_ROOT / 'ios' / 'Runner' / 'Info.plist'
if info_plist.exists():
    content = info_plist.read_text(encoding='utf-8')
    if 'NSHealthShareUsageDescription' in content:
        FAILURES.append(
            f'[FAIL] {info_plist.relative_to(PROJECT_ROOT)}: 含 NSHealthShareUsageDescription, '
            f'但 lib/ 没 import health_kit → Apple 5.1.3 declared-but-not-used 拒审'
        )

# 规则 4: pubspec.yaml 不应含 health_kit 依赖
pubspec = PROJECT_ROOT / 'pubspec.yaml'
if pubspec.exists():
    content = pubspec.read_text(encoding='utf-8')
    if re.search(r'^\s*health_kit\s*:', content, re.MULTILINE):
        FAILURES.append(
            f'[FAIL] pubspec.yaml: 含 health_kit 依赖, 但未真接 HealthKit '
            f'→ 5.1.3 拒审 (真接后再加回)'
        )

# 输出
if FAILURES:
    print('=' * 60)
    print('[check_apple_health_claim.py] FAIL')
    print('=' * 60)
    for f in FAILURES:
        print(f)
    print('=' * 60)
    print(f'共 {len(FAILURES)} 项违规。Apple 5.1.3 拒审风险。')
    print('修复方案: 真接 HealthKit (5-15d) 或保持当前 0 集成状态 (本守门员期望)。')
    sys.exit(1)
else:
    print('[check_apple_health_claim.py] OK — 项目无 Apple Health 假声明风险')
    sys.exit(0)
