#!/usr/bin/env python3
# v0.30 R108 revisit (P0-020): check_apple_health_claim 守门员
# v1.1.0+183 R128c (R110 阶段 4): 加 5 规则 — lib/core/platform/health_kit/
#   stub 占位声明, 但 stub 不 import health_kit 包 (跟 5 厂商 push NoOp 同模式)
#
# 作用: 验证项目**没有**声明 / 集成 Apple Health / HealthKit 但不接的实际代码
#   (避免 Apple 5.1.3 used-but-not-declared / declared-but-not-used 抽审拒)
#
# 背景: R107 PrivacyInfo.xcprivacy 声明了 NSPrivacyCollectedDataTypeHealthAndFitness
#   但**没有**集成 HealthKit (pubspec 无 health_kit, Runner.entitlements 空,
#   Info.plist 无 NSHealthShareUsageDescription) → 5.1.3 拒审风险。
#   R108 修法: 删 HealthAndFitness 声明 + 加本守门员防回退。
#   R128c 阶段 1: 加 lib/core/platform/health_kit/health_kit_service.dart stub
#   骨架 (NoOp default + flag 短路), 5-6 月后真接时只换 impl + 加 pub 依赖 +
#   iOS entitlement, 修真 R128d 阶段 5 守门员规则。
#
# 规则:
#   1. PrivacyInfo.xcprivacy 不应含 NSPrivacyCollectedDataTypeHealthAndFitness
#   2. lib/ 不应含 `import 'package:health_kit/...'` / `import 'package:health/...'`
#      (等真接 HealthKit 时再加回)
#   3. Info.plist 不应含 NSHealthShareUsageDescription (除非真接)
#   4. pubspec.yaml 不应含 health_kit 依赖
#   5. R128c stub 占位声明 — lib/core/platform/health_kit/health_kit_service.dart
#      存在 + 是 pure NoOp (不 import health_kit 包) + flag 默认 false
#      (修真 5-6 月后真接时, 同步加 pub 依赖 + iOS entitlement + 修真 stub 为真接 impl)
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

# 规则 5: R128c stub 占位声明 + 不 import health_kit 包 + flag 默认 false
health_kit_stub = PROJECT_ROOT / 'lib' / 'core' / 'platform' / 'health_kit' / 'health_kit_service.dart'
if health_kit_stub.exists():
    content = health_kit_stub.read_text(encoding='utf-8', errors='ignore')
    # 修真 1: stub 不应 import health_kit / health 包 (NoOp 阶段 0 依赖)
    for pattern in [
        r"import\s+'package:health_kit/",
        r"import\s+'package:health/",
    ]:
        if re.search(pattern, content):
            FAILURES.append(
                f'[FAIL] {health_kit_stub.relative_to(PROJECT_ROOT)}: stub 阶段 import 了 health_kit/health 库, '
                f'但 pubspec.yaml 未加 health_kit 依赖 + Info.plist 无 NSHealthShareUsageDescription '
                f'→ Apple 5.1.3 拒审 (修真 5-6 月后真接时同步加 pub 依赖 + iOS entitlement)'
            )
            break
    # 修真 2: stub 应含 NoOp 默认实现 (防未来有人改掉 NoOp 但没真接 SDK)
    if 'class NoOpHealthKitChannel' not in content:
        FAILURES.append(
            f'[FAIL] {health_kit_stub.relative_to(PROJECT_ROOT)}: stub 缺 NoOpHealthKitChannel 默认实现, '
            f'R128c 阶段 1 设计意图是 NoOp default + flag 短路, 5-6 月后真接时只换 impl 保留 NoOp 兜底'
        )
    # 修真 3: stub 应含 HealthKitService facade (跟 R124 5 厂商 push facade 同模式)
    if 'class HealthKitService' not in content:
        FAILURES.append(
            f'[FAIL] {health_kit_stub.relative_to(PROJECT_ROOT)}: stub 缺 HealthKitService 公开 facade, '
            f'R128c 阶段 1 设计意图是 abstract + NoOp + factory + facade 4 段式, '
            f'跟 R124 5 厂商 push facade 完整一致'
        )
else:
    FAILURES.append(
        f'[FAIL] lib/core/platform/health_kit/health_kit_service.dart: R128c 阶段 1 stub 不存在, '
        f'需建 NoOp stub + flag=false 默认短路 (跟 R124 5 厂商 push NoOp 同模式)。'
        f'修真: 写 stub (5-10L NoOp + abstract + facade), commit 后本守门员绿'
    )

# 规则 5b: FeatureFlags.healthKitEnabled 默认 false (修真 5-6 月后真接时翻 true)
feature_flags = PROJECT_ROOT / 'lib' / 'core' / 'data' / 'feature_flags.dart'
if feature_flags.exists():
    content = feature_flags.read_text(encoding='utf-8', errors='ignore')
    if '_prodHealthKitEnabled = false' not in content:
        FAILURES.append(
            f'[FAIL] {feature_flags.relative_to(PROJECT_ROOT)}: 缺 _prodHealthKitEnabled = false 默认值, '
            f'R128c 阶段 1 设计意图是 flag 默认 false (跟 _prodFiveVendorPushEnabled = false 同模式)。'
            f'修真: 加 _prodHealthKitEnabled 静态字段 + healthKitEnabled getter + setHealthKitEnabledForTest 方法'
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
    print('R128c 阶段 1 stub 占位声明: 修真 stub 文件 / flag 默认值 / NoOp 默认实现 (5-10L)。')
    sys.exit(1)
else:
    print('[check_apple_health_claim.py] OK — 项目无 Apple Health 假声明风险')
    sys.exit(0)
