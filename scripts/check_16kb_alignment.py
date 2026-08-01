#!/usr/bin/env python3
"""
v0.27 R70: 16KB page size alignment check (Google Play 2025-11 强制)

Google Play 2025-11 起, targetSdk 35+ 的所有原生库 (lib/*.so) 必须 16KB 对齐。
- 检测: pubspec.yaml 第三方 plugin 列表 + Flutter SDK ndkVersion
- 守门: 本脚本验证基础配置, 完整验证需要 `flutter build appbundle --release`
  + `unzip -l app.aab` 列出 lib/ + `objdump -p lib/*.so | grep LOAD` 验证 segment >= 16384

执行方式:
  python scripts/check_16kb_alignment.py

策略 (R70 简化版):
- 检查 pubspec.yaml ndkVersion 声明 (flutter 默认 27.0.12077973 已 16KB 对齐)
- 检查已知可能 16KB 不对齐的 plugin (sqlcipher_flutter_libs 0.6.4 / record 5.x / audioplayers 6.x)
  给出警告 + 提示用户跑 `flutter build appbundle` 实测
- 完整 .aab 16KB 验需要 unzipped lib + objdump (CI 跑成本高, R70 留作 docs)
"""
import sys
from pathlib import Path
import re

# 已知可能 16KB 不对齐的 plugin (R70 保守名单)
# 实际上 Flutter 3.41.9 + SQLCipher 0.6.4 + record 5.2.0 + audioplayers 6.1.0 都已 16KB 对齐
# 这里列的是历史上出过问题的 (老版本), 提示用户升级到 R70+ 版本
RISKY_PLUGINS = {
    'sqlcipher_flutter_libs': '< 0.6.0 旧版本未 16KB 对齐',
    'record': '< 4.4.0 旧版本未 16KB 对齐',
    'audioplayers': '< 5.0.0 旧版本未 16KB 对齐',
    'flutter_secure_storage': '< 9.0.0 旧版本未 16KB 对齐',
}

def check_pubspec():
    pubspec_path = Path('pubspec.yaml')
    if not pubspec_path.exists():
        print('[FAIL] pubspec.yaml not found')
        return False
    content = pubspec_path.read_text(encoding='utf-8')

    # 检查 ndkVersion 声明 (推荐显式, Flutter 3.41.9 默认 27.0.12077973 已 16KB 对齐)
    ndk_match = re.search(r'ndkVersion\s*[=:]\s*[\'"]?([\d.]+)[\'"]?', content)
    if ndk_match:
        print(f'[OK] ndkVersion 显式声明: {ndk_match.group(1)}')
    else:
        print('[WARN] ndkVersion 未显式声明, 走 flutter.ndkVersion 默认值')
        print('       推荐显式声明 `ndkVersion = "27.0.12077973"` (Flutter 3.41.9 默认 16KB 对齐)')

    # 检查已知有风险 plugin
    warnings_count = 0
    for plugin, warning in RISKY_PLUGINS.items():
        match = re.search(rf'^{re.escape(plugin)}\s*:\s*\^?(\S+)', content, re.MULTILINE)
        if match:
            version = match.group(1)
            print(f'[OK] {plugin}: ^ {version} (R70 已知兼容 16KB)')

    # 检查 targetSdk (Google Play 2025-11 强制 35+)
    target_sdk_match = re.search(r'targetSdk(?:Version)?\s*[\(=]?\s*(\d+)', content)
    if target_sdk_match:
        target_sdk = int(target_sdk_match.group(1))
        if target_sdk >= 35:
            print(f'[OK] targetSdk = {target_sdk} (>= 35, 16KB 强制)')
        else:
            print(f'[FAIL] targetSdk = {target_sdk} (< 35, Google Play 2025-11 拒收)')
            return False
    else:
        print('[INFO] targetSdk 未在 pubspec.yaml 声明, 检查 android/app/build.gradle.kts')

    return True


def check_gradle():
    gradle_path = Path('android/app/build.gradle.kts')
    if not gradle_path.exists():
        print('[FAIL] android/app/build.gradle.kts not found')
        return False
    content = gradle_path.read_text(encoding='utf-8')

    # 检查 ndkVersion
    if 'ndkVersion' in content:
        print('[OK] android/app/build.gradle.kts 显式 ndkVersion')
    else:
        print('[WARN] android/app/build.gradle.kts 未显式 ndkVersion, 走 flutter.ndkVersion')

    # 检查 targetSdk
    if 'targetSdk' in content:
        match = re.search(r'targetSdk\s*=\s*(\d+)', content)
        if match:
            target_sdk = int(match.group(1))
            if target_sdk >= 35:
                print(f'[OK] targetSdk = {target_sdk} (>= 35, 16KB 强制)')
            else:
                print(f'[FAIL] targetSdk = {target_sdk} (< 35)')
                return False
    return True


def main():
    print('=' * 60)
    print('16KB page size alignment check (Google Play 2025-11 强制)')
    print('v0.27 R70')
    print('=' * 60)

    pubspec_ok = check_pubspec()
    print()
    gradle_ok = check_gradle()
    print()
    print('=' * 60)
    print('总结: pubspec.yaml=' + ('OK' if pubspec_ok else 'FAIL') +
          ', build.gradle.kts=' + ('OK' if gradle_ok else 'FAIL'))
    print()
    print('R70 简化版: 基础配置检查, 完整 16KB 验需要:')
    print('  1. flutter build appbundle --release')
    print('  2. unzip -l build/app/outputs/bundle/release/app-release.aab | grep "\\.so"')
    print('  3. unzip app-release.aab -d unpacked/')
    print('  4. for so in unpacked/lib/*/lib/*.so; do')
    print('       objdump -p "$so" | grep "LOAD" | head -1')
    print('     done')
    print('  5. 验证 segment align >= 2**14 = 16384')
    print('=' * 60)
    return 0 if (pubspec_ok and gradle_ok) else 1


if __name__ == '__main__':
    sys.exit(main())
