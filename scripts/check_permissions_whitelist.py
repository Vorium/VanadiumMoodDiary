#!/usr/bin/env python3
"""
v1.1.0 round 11 (R115 隐私加固): 权限白名单守门员

作用: 验证 Android manifest + iOS Info.plist 权限**严格白名单**, 不允许
新增"敏感"权限 (通讯录 / 位置 / 短信 / 摄像头 / 蓝牙 / 账户等)。

零外联隐私合规: 精神心理 / 慢性病数据走 SQLCipher 本地加密, 不应有任何
可访问用户身份 / 通讯录 / 位置的权限入口。

执行:
  python3 scripts/check_permissions_whitelist.py
  python3 scripts/check_permissions_whitelist.py --ci  # exit 1 on fail

依据 (R115 docs/design/.../privacy-hardening):
- Android whitelist: 6 个 (INTERNET / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM
  / WAKE_LOCK / VIBRATE / RECORD_AUDIO), 任何新增触发 fail
- iOS whitelist: 4 个 usage description (NSMicrophone / NSSpeechRecognition /
  NSPhotoLibrary / NSPhotoLibraryAdd), 任何新增触发 fail
"""
import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

ANDROID_MANIFEST = REPO_ROOT / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
ANDROID_DEBUG_MANIFEST = REPO_ROOT / "android" / "app" / "src" / "debug" / "AndroidManifest.xml"
IOS_PLIST = REPO_ROOT / "ios" / "Runner" / "Info.plist"

# Android 权限白名单 (现状 6 个, R115 锁住)
ANDROID_WHITELIST = {
    "android.permission.INTERNET",  # R114 注释保留 (无实际网络出口, 未来预留)
    "android.permission.POST_NOTIFICATIONS",  # Android 13+ 通知运行时权限
    "android.permission.SCHEDULE_EXACT_ALARM",  # 精准闹钟 (服药提醒)
    "android.permission.WAKE_LOCK",  # 通知触发保持 CPU
    "android.permission.VIBRATE",  # 通知震动
    "android.permission.RECORD_AUDIO",  # vent / mood 语音录音
}

# iOS Info.plist usage description 白名单 (现状 4 个)
IOS_WHITELIST = {
    "NSMicrophoneUsageDescription",  # vent / mood 录音
    "NSSpeechRecognitionUsageDescription",  # 语音转写
    "NSPhotoLibraryUsageDescription",  # 分享 PDF 选保存位置
    "NSPhotoLibraryAddUsageDescription",  # 保存 PDF
}

# 显式黑名单 (即使不在 whitelist 也禁止, 防止误加)
ANDROID_FORBIDDEN = {
    "android.permission.READ_CONTACTS",
    "android.permission.WRITE_CONTACTS",
    "android.permission.GET_ACCOUNTS",
    "android.permission.READ_PHONE_STATE",
    "android.permission.READ_PHONE_NUMBERS",
    "android.permission.CALL_PHONE",
    "android.permission.READ_CALL_LOG",
    "android.permission.WRITE_CALL_LOG",
    "android.permission.ACCESS_FINE_LOCATION",
    "android.permission.ACCESS_COARSE_LOCATION",
    "android.permission.ACCESS_BACKGROUND_LOCATION",
    "android.permission.READ_EXTERNAL_STORAGE",
    "android.permission.WRITE_EXTERNAL_STORAGE",
    "android.permission.READ_SMS",
    "android.permission.SEND_SMS",
    "android.permission.RECEIVE_SMS",
    "android.permission.CAMERA",
    "android.permission.BODY_SENSORS",
    "android.permission.ACTIVITY_RECOGNITION",
    "android.permission.BLUETOOTH",
    "android.permission.BLUETOOTH_ADMIN",
    "android.permission.BLUETOOTH_CONNECT",
    "android.permission.BLUETOOTH_SCAN",
    "android.permission.NEARBY_WIFI_DEVICES",
    "android.permission.SYSTEM_ALERT_WINDOW",
    "android.permission.REQUEST_INSTALL_PACKAGES",
    "android.permission.USE_BIOMETRIC",
    "android.permission.USE_FINGERPRINT",
    "android.permission.MANAGE_EXTERNAL_STORAGE",
    "android.permission.PROCESS_OUTGOING_CALLS",
    "android.permission.ANSWER_PHONE_CALLS",
    "android.permission.ADD_VOICEMAIL",
    "android.permission.USE_SIP",
}

# iOS 黑名单
IOS_FORBIDDEN = {
    "NSContactsUsageDescription",  # 联系人 — 已随外联业务删除
    "NSCalendarsUsageDescription",  # 日历
    "NSCalendarsFullAccessUsageDescription",  # 日历全访问
    "NSRemindersUsageDescription",  # 提醒事项
    "NSLocationWhenInUseUsageDescription",  # 位置 (使用时)
    "NSLocationAlwaysAndWhenInUseUsageDescription",  # 位置 (始终)
    "NSLocationAlwaysUsageDescription",  # 位置 (始终)
    "NSAppleMusicUsageDescription",  # 媒体库
    "NSMotionUsageDescription",  # 运动 / 健康
    "NSHealthShareUsageDescription",  # HealthKit 共享
    "NSHealthUpdateUsageDescription",  # HealthKit 更新
    "NSCameraUsageDescription",  # 相机
    "NSBluetoothAlwaysUsageDescription",  # 蓝牙
    "NSBluetoothPeripheralUsageDescription",  # 蓝牙 (旧)
    "NSSiriUsageDescription",  # Siri
    "NSFaceIDUsageDescription",  # Face ID
    "NSUserTrackingUsageDescription",  # 跟踪 (IDFA)
    "NSNearbyInteractionUsageDescription",  # 近场
}


def collect_violations() -> list[str]:
    violations: list[str] = []
    violations.extend(_check_android_manifest(ANDROID_MANIFEST, "main"))
    debug_manifest = ANDROID_DEBUG_MANIFEST
    if debug_manifest.exists():
        # debug 构建的额外 INTERNET 由 Flutter 工具链用, 走 src/debug
        # 独立声明。debug 不算 main 业务, 只 check 名单内的非 INTERNET 权限
        violations.extend(_check_android_manifest(debug_manifest, "debug"))
    violations.extend(_check_ios_plist())
    return violations


def _check_android_manifest(path: Path, label: str) -> list[str]:
    """检查 Android manifest 的 uses-permission 列表"""
    out: list[str] = []
    if not path.exists():
        out.append(f"AndroidManifest.xml ({label}) 不存在: {path}")
        return out
    tree = ET.parse(path)
    root = tree.getroot()
    for perm in root.findall("uses-permission"):
        name = perm.get("{http://schemas.android.com/apk/res/android}name", "")
        if not name:
            continue
        rel_path = path.relative_to(REPO_ROOT)
        if name in ANDROID_FORBIDDEN:
            out.append(
                f"{rel_path}  使用 {name} 在白名单**外且显式黑名单内 — "
                f"精神心理数据不应有该权限入口"
            )
        elif name not in ANDROID_WHITELIST:
            out.append(
                f"{rel_path}  使用 {name} 不在白名单内 — "
                f"白名单仅 6 项: {', '.join(sorted(ANDROID_WHITELIST))}"
            )
    return out


def _check_ios_plist() -> list[str]:
    """检查 iOS Info.plist 的 usage description 列表"""
    out: list[str] = []
    if not IOS_PLIST.exists():
        out.append(f"Info.plist 不存在: {IOS_PLIST}")
        return out
    tree = ET.parse(IOS_PLIST)
    root = tree.getroot()
    for key_el in root.findall("key"):
        key_text = (key_el.text or "").strip()
        if not key_text.endswith("UsageDescription"):
            continue
        rel_path = IOS_PLIST.relative_to(REPO_ROOT)
        if key_text in IOS_FORBIDDEN:
            out.append(
                f"{rel_path}  使用 {key_text} 在白名单**外且显式黑名单内 — "
                f"已随外联业务删除, 不应复活"
            )
        elif key_text not in IOS_WHITELIST:
            out.append(
                f"{rel_path}  使用 {key_text} 不在白名单内 — "
                f"白名单仅 4 项: {', '.join(sorted(IOS_WHITELIST))}"
            )
    return out


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--ci", action="store_true", help="CI mode: exit 1 on fail")
    args = parser.parse_args()

    print("=" * 60)
    print("v1.1.0 round 11 (R115) 权限白名单守门员")
    print("=" * 60)
    print(f"Android whitelist: {len(ANDROID_WHITELIST)} permissions")
    print(f"iOS whitelist: {len(IOS_WHITELIST)} usage descriptions")
    print()

    violations = collect_violations()
    if violations:
        print(f"❌ 发现 {len(violations)} 处违规:")
        for v in violations:
            print(f"  - {v}")
        print()
        print("修复指引:")
        print("  1. 不要新增白名单外的权限 — 精神心理数据不应有通讯录/位置/短信等入口")
        print("  2. 如需新权限 (例如健康数据), 先讨论 + 更新白名单 + 同步 AGENTS.md")
        print("  3. 删除已废弃的 FORBIDDEN 权限 (复活黑名单会拒)")
        return 1 if args.ci else 1

    print("✅ 0 violation — 权限严格白名单保持")
    return 0


if __name__ == "__main__":
    sys.exit(main())
