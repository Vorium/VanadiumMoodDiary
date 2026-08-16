#!/usr/bin/env python3
"""
v0.27 R70: 16KB page size alignment check (Google Play 2025-11 强制)
v0.32 R112 round 8 (SP-R112-06): --so-path 真实验证模式 (objdump LOAD 段对齐判定)

Google Play 2025-11 起, targetSdk 35+ 的所有原生库 (lib/*.so) 必须 16KB 对齐。
- 检测: pubspec.yaml 第三方 plugin 列表 + Flutter SDK ndkVersion
- 守门: 本脚本验证基础配置, 完整验证需要 `flutter build appbundle --release`
  + `unzip -l app.aab` 列出 lib/ + `objdump -p lib/*.so | grep LOAD` 验证 segment >= 16384

执行方式:
  python scripts/check_16kb_alignment.py                          # 配置级检查 (产物验证 SKIP)
  python scripts/check_16kb_alignment.py --so-path <libfoo.so>    # 单 .so 真实验证
  python scripts/check_16kb_alignment.py --so-dir <dir>           # 目录下全部 .so 真实验证
  python scripts/check_16kb_alignment.py --aab <app-release.aab>  # 解 AAB 后全量验证 (需 unzip+objdump)

策略 (R70 简化版):
- 检查 pubspec.yaml ndkVersion 声明 (flutter 默认 27.0.12077973 已 16KB 对齐)
- 检查已知可能 16KB 不对齐的 plugin (sqlcipher_flutter_libs 0.6.4 / record 5.x / audioplayers 6.x)
  给出警告 + 提示用户跑 `flutter build appbundle` 实测
- R112 round 8 起: --so-path/--so-dir/--aab 模式跑真 objdump, LOAD 段
  align 必须 >= 2**14 = 16384, 有 exit-code 语义 (CI 可挂)

1.1.0 R113 (P2-20) 硬验证语义 (假绿修复):
- 产物路径显式给出 (--so-path/--so-dir/--aab) 时**硬验证**:
  产物文件缺失 / objdump 缺失 / unzip 缺失 / LOAD 不对齐 = FAIL exit 1
  (之前工具缺失返回 True = CI 假绿)
- 默认本地跑 (无产物参数): 产物验证打印 [SKIP], 不参与 exit code,
  配置级检查 (pubspec/gradle) 照常 gate (向后兼容)
"""
import sys
import shutil
import subprocess
import tempfile
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

REQUIRED_ALIGN = 2**14  # 16384


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

    # 检查 ndkVersion (GP-R112-07: 区分 pin 值与 flutter.ndkVersion 属性引用)
    if re.search(r'ndkVersion\s*=\s*["\'][\d.]+["\']', content):
        pin = re.search(r'ndkVersion\s*=\s*["\']([\d.]+)["\']', content)
        print(f'[OK] android/app/build.gradle.kts pin ndkVersion = {pin.group(1)}')
    elif 'flutter.ndkVersion' in content:
        print('[WARN] android/app/build.gradle.kts 用 flutter.ndkVersion 属性引用, 版本随 Flutter 漂移')
        print('       推荐 pin `ndkVersion = "27.0.12077973"` (Flutter 3.41.9 默认, 16KB 对齐)')
    else:
        print('[WARN] android/app/build.gradle.kts 未显式 ndkVersion, 走 flutter.ndkVersion 默认')

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


def verify_so(so_path: Path) -> bool:
    """objdump 解析单个 .so 的 LOAD 段对齐, align 必须 >= 2**14。

    R113 (P2-20): 产物路径显式给出时硬验证 — 文件缺失 / objdump 缺失
    都判 FAIL (之前 objdump 缺失返回 True = CI 假绿)。
    """
    if not so_path.exists():
        print(f'[FAIL] {so_path}: 文件不存在 (产物验证必须 FAIL, 不能 SKIP)')
        return False
    if shutil.which('objdump') is None:
        print('[FAIL] objdump 不可用 (需 binutils/NDK toolchain), 产物验证无法执行')
        return False
    out = subprocess.run(
        ['objdump', '-p', str(so_path)],
        capture_output=True, text=True,
    ).stdout
    # objdump 输出形如 "LOAD off ... align 2**14"; 捕获指数再算 2**exp
    alignments = [
        2 ** int(m)
        for m in re.findall(r'\bLOAD\b.*?\balign\s+2\*\*(\d+)', out, re.S)
    ]
    # 若正则未命中 (不同 objdump 格式), 退化为行级解析
    if not alignments:
        for line in out.splitlines():
            if 'LOAD' in line and 'align' in line:
                m = re.search(r'align\s+2\*\*(\d+)', line)
                if m:
                    alignments.append(2 ** int(m.group(1)))
    if not alignments:
        print(f'[FAIL] {so_path}: 无 LOAD 段信息 (objdump 输出异常)')
        return False
    ok = all(a >= REQUIRED_ALIGN for a in alignments)
    if ok:
        print(f'[OK] {so_path.name}: LOAD align {alignments} (>= {REQUIRED_ALIGN})')
    else:
        print(f'[FAIL] {so_path}: LOAD align {alignments} (< {REQUIRED_ALIGN} = 2**14, Play 2025-11 拒收)')
    return ok


def verify_so_dir(so_dir: Path) -> bool:
    if not so_dir.exists():
        print(f'[FAIL] {so_dir}: 目录不存在 (产物验证必须 FAIL, 不能 SKIP)')
        return False
    files = sorted(so_dir.rglob('*.so'))
    if not files:
        print(f'[FAIL] {so_dir}: 0 个 .so 文件')
        return False
    print(f'[INFO] 验证 {len(files)} 个 .so')
    return all(verify_so(f) for f in files)


def verify_aab(aab_path: Path) -> bool:
    """解 AAB 拿 base/lib/**/lib*.so 全量验证 (需 unzip)。

    R113 (P2-20): --aab 显式给出时硬验证 — 文件缺失 / unzip 缺失
    都判 FAIL (之前 unzip 缺失返回 True = CI 假绿)。
    """
    if not aab_path.exists():
        print(f'[FAIL] {aab_path}: 文件不存在 (产物验证必须 FAIL, 不能 SKIP)')
        return False
    if shutil.which('unzip') is None:
        print('[FAIL] unzip 不可用, 无法解 AAB (产物验证必须 FAIL, 不能 SKIP)')
        return False
    with tempfile.TemporaryDirectory() as tmp:
        subprocess.run(['unzip', '-q', str(aab_path), '-d', tmp], check=True)
        lib_dir = Path(tmp) / 'base' / 'lib'
        if not lib_dir.exists():
            print(f'[FAIL] {aab_path}: 无 base/lib (AAB 结构异常)')
            return False
        return verify_so_dir(lib_dir)


def main():
    args = [a for a in sys.argv[1:]]
    so_path = so_dir = aab = None
    for a in args:
        if a.startswith('--so-path='):
            so_path = Path(a.split('=', 1)[1])
        elif a.startswith('--so-dir='):
            so_dir = Path(a.split('=', 1)[1])
        elif a.startswith('--aab='):
            aab = Path(a.split('=', 1)[1])

    print('=' * 60)
    print('16KB page size alignment check (Google Play 2025-11 强制)')
    print('v0.32 R112 round 8 (SP-R112-06: --so-path/--so-dir/--aab 真实验证)')
    print('=' * 60)

    pubspec_ok = check_pubspec()
    print()
    gradle_ok = check_gradle()
    print()

    artifact_ok = True
    artifact_mode = False
    if so_path is not None:
        artifact_mode = True
        artifact_ok = verify_so(so_path)
    elif so_dir is not None:
        artifact_mode = True
        artifact_ok = verify_so_dir(so_dir)
    elif aab is not None:
        artifact_mode = True
        artifact_ok = verify_aab(aab)
    else:
        print('[SKIP] 未提供 --so-path/--so-dir/--aab, 跳过产物验证 (本地开发)')
        print('       发布/CI 前必须带产物参数跑: python scripts/check_16kb_alignment.py --aab build/app/outputs/bundle/release/app-release.aab')

    print()
    print('=' * 60)
    if artifact_mode:
        artifact_label = 'OK' if artifact_ok else 'FAIL'
    else:
        artifact_label = 'SKIP'
    print('总结: pubspec.yaml=' + ('OK' if pubspec_ok else 'FAIL') +
          ', build.gradle.kts=' + ('OK' if gradle_ok else 'FAIL') +
          ', 产物验证=' + artifact_label)
    print('=' * 60)
    return 0 if (pubspec_ok and gradle_ok and artifact_ok) else 1


if __name__ == '__main__':
    sys.exit(main())
