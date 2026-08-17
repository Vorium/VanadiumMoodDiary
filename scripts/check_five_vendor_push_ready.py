#!/usr/bin/env python3
# v1.1.0+170 R124 (v1.0 长期 5 厂商 push facade 接入) — 5 厂商 push 接入
# 完整性守门员
#
# 背景 (R93 阶段 2 + 1.1.0 round 4b → R124 闭环):
# - 1.1.0 round 4b: 失联通知 100% 失效, 5 厂商 push SDK 1-2 月审核中
# - R93 阶段 2 加了 [FeatureFlags.fiveVendorPushEnabled] flag (默认 false),
#   但 FiveVendorPushService.register 早返 false 的承诺代码没写
# - R124: 写 FiveVendorPushService facade (5 通道抽象 + NoOp + 5 厂商占位
#   impl + factory + 公开 service)
#
# 守门员 (阶段 1 / 阶段 2 双 gate):
# 阶段 1 (R124 阶段 1 已做, 守门员必过):
#   - FiveVendorPushService 文件存在
#   - 5 通道 abstract 抽象 (FiveVendorPushChannel) 存在
#   - 5 厂商 impl 占位 class 全列 (MiPush / HmsPush / OppoPush /
#     VivoPush / MeizuPush) — 现阶段 throw UnimplementedError
#   - NoOpFiveVendorPushChannel 默认实现存在
#   - FiveVendorPushFactory.createChannel 公开方法
#   - 公开 facade 5 method: register / unregister / isAvailable /
#     getPushToken / 公开 vendorName getter
#   - FeatureFlags.fiveVendorPushEnabled gate (false 早返, 不影响本地通知)
# 阶段 2 (v1.0 真接 SDK 后开, 阶段 1 必失败):
#   - pubspec.yaml 含 5 厂商 SDK dependency
#   - AndroidManifest 含 5 厂商 service / receiver
#   - 5 厂商 impl 不再 throw UnimplementedError (实际调 SDK API)
#   - 工厂方法按 device brand 选 impl (不再全部 NoOp)
#
# R124 阶段 1: 阶段 1 gate 全过 + 阶段 2 gate 必 fail (5 厂商 SDK 未接),
# 用 warn 提示 v1.0 真接时再开阶段 2 gate。
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SERVICE_FILE = ROOT / "lib" / "core" / "services" / "five_vendor_push_service.dart"
ACTUAL_PATH = ROOT / "lib" / "core" / "data" / "services" / "five_vendor_push_service.dart"
PUBSPEC_FILE = ROOT / "pubspec.yaml"
ANDROID_MANIFEST = ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"

# 5 厂商 SDK 名 (R124 阶段 2 验收用)
VENDOR_SDK_PACKAGES = [
    "mipush",       # 小米
    "hms",          # 华为
    "oppo",         # OPPO HeyTap
    "vivo",         # vivo
    "meizu",        # 魅族
]


def main() -> int:
    exit_code = 0
    phase1_violations: list[str] = []
    phase2_warnings: list[str] = []

    # 1. 服务文件存在
    if not ACTUAL_PATH.exists():
        phase1_violations.append(
            f"FiveVendorPushService 文件不存在: {ACTUAL_PATH.relative_to(ROOT)}"
        )
        print(f"[FAIL] {phase1_violations[-1]}")
        return 1

    content = ACTUAL_PATH.read_text(encoding='utf-8')

    # 2. 5 通道 abstract 抽象
    if 'abstract class FiveVendorPushChannel' not in content:
        phase1_violations.append("缺 abstract class FiveVendorPushChannel (5 通道抽象)")

    # 3. 5 厂商 impl 占位 class 全列
    for vendor_class in [
        'class MiPushChannel',
        'class HmsPushChannel',
        'class OppoPushChannel',
        'class VivoPushChannel',
        'class MeizuPushChannel',
    ]:
        if vendor_class not in content:
            phase1_violations.append(f"缺 {vendor_class} (5 厂商占位 impl)")

    # 4. NoOp 默认实现
    if 'class NoOpFiveVendorPushChannel' not in content:
        phase1_violations.append("缺 NoOpFiveVendorPushChannel (默认实现)")

    # 5. Factory 公开方法
    if 'static FiveVendorPushChannel createChannel()' not in content:
        phase1_violations.append("缺 FiveVendorPushFactory.createChannel() 公开方法")

    # 6. 公开 facade 5 method (register / unregister / isAvailable /
    #    getPushToken + vendorName getter)
    public_api_checks = [
        ('static Future<bool> register()', 'register() 公开'),
        ('static Future<void> unregister()', 'unregister() 公开'),
        ('static Future<bool> isAvailable()', 'isAvailable() 公开'),
        ('static Future<String?> getPushToken()', 'getPushToken() 公开'),
    ]
    for needle, name in public_api_checks:
        if needle not in content:
            phase1_violations.append(f"缺 {name} 公开 API")

    # 7. FeatureFlags gate
    if 'FeatureFlags.fiveVendorPushEnabled' not in content:
        phase1_violations.append(
            "缺 FeatureFlags.fiveVendorPushEnabled gate "
            "(false 时应早返, 不影响本地通知)"
        )

    # 阶段 1 输出
    if phase1_violations:
        exit_code = 1
        print(f"[FAIL] check_five_vendor_push_ready 阶段 1: {len(phase1_violations)} 项违规")
        for v in phase1_violations:
            print(f"  - {v}")
    else:
        print("[OK] check_five_vendor_push_ready 阶段 1: 5 通道抽象 + NoOp + 5 厂商占位 + 公开 API + flag gate 全齐")

    # 阶段 2 警告 (R124 阶段 1 必 warn, v1.0 真接 SDK 后开)
    sdk_in_pubspec = False
    if PUBSPEC_FILE.exists():
        pubspec_content = PUBSPEC_FILE.read_text(encoding='utf-8')
        for sdk in VENDOR_SDK_PACKAGES:
            if sdk in pubspec_content:
                sdk_in_pubspec = True
                break

    if not sdk_in_pubspec:
        phase2_warnings.append(
            "pubspec.yaml 未含 5 厂商 SDK dependency (R124 阶段 1 预期, v1.0 真接后开)"
        )

    if not ANDROID_MANIFEST.exists():
        phase2_warnings.append(
            f"AndroidManifest.xml 缺失: {ANDROID_MANIFEST.relative_to(ROOT)}"
        )
    else:
        manifest_content = ANDROID_MANIFEST.read_text(encoding='utf-8')
        # 检查 5 厂商 service / receiver 是否在 manifest
        manifest_vendor_markers = [
            ('MiPush', '小米'),
            ('HmsMsgService', '华为'),
            ('HeyTap', 'OPPO'),
            ('VivoPush', 'vivo'),
            ('MeizuPush', '魅族'),
        ]
        missing_markers = [
            (marker, vendor)
            for marker, vendor in manifest_vendor_markers
            if marker not in manifest_content
        ]
        if missing_markers:
            phase2_warnings.append(
                f"AndroidManifest 缺 5 厂商 service/receiver: "
                f"{', '.join(f'{v}({m})' for m, v in missing_markers)}"
            )

    # 5 厂商 impl 是否仍 throw UnimplementedError (R124 阶段 1 预期)
    unimplemented_count = content.count('UnimplementedError(')
    if unimplemented_count == 0:
        phase2_warnings.append(
            "5 厂商 impl 都不再 throw UnimplementedError — "
            "可能是 v1.0 真接 SDK, 阶段 1 守门员不期望"
        )
    else:
        phase2_warnings.append(
            f"5 厂商 impl 仍 throw UnimplementedError (R124 阶段 1 预期, {unimplemented_count} 处)"
        )

    if phase2_warnings:
        print(f"[warn] check_five_vendor_push_ready 阶段 2 (v1.0 真接 SDK 后开):")
        for w in phase2_warnings:
            print(f"  - {w}")

    return exit_code


if __name__ == "__main__":
    sys.exit(main())
