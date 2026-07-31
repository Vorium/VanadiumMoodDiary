#!/usr/bin/env python3
"""Check missing keys between zh, en, zh-Hant arb files.

v0.23 (P0-14) 修: 双向检查 (zh-en + en-zh) + exit code 1 (CI 友好)

v0.24 round 47 (B-27) 修: 加 --staged 模式, PR 时只查修改文件
  - python check_arb_keys.py            → 全量检查 (CI / 全项目审计)
  - python check_arb_keys.py --staged   → 只查 git diff 涉及的 ARB 文件
  - python check_arb_keys.py --staged HASH  → 对比特定 commit (default HEAD)

v0.24 round 48 (sp-zh P1-21) 修: --staged 模式加 zh-Hant 同步检查
  - 之前 P0 fix 加 5 个 i18n key 时漏了 zh_Hant.arb,导致 zh_Hant 落后 6 key
  - 修正方法: 跑 flutter gen-l10n 会自动同步 zh_Hant,但需要人触发
  - 守护: --staged 模式先验 zh_Hant 是不是同步,如果不同步 fail
  - 修法: python scripts/check_arb_keys.py --staged 报缺漏 → 跑 flutter gen-l10n
"""
import re
import subprocess
import sys


def keys(p):
    txt = open(p, encoding='utf-8').read()
    return set(re.findall(r'^  "([a-zA-Z][a-zA-Z0-9]+)":', txt, re.M))


def get_modified_arb_files(base_ref='HEAD'):
    """返回 git working tree + index 中修改过的 .arb 文件列表

    Args:
        base_ref: 对比基准 (default HEAD)
    """
    try:
        # working tree 修改 + index 修改 (含未 commit)
        out = subprocess.check_output(
            ['git', 'diff', '--name-only', base_ref, '--', 'lib/l10n/'],
            stderr=subprocess.STDOUT, text=True,
        )
    except subprocess.CalledProcessError as e:
        print(f'[ERROR] git diff failed: {e.output}', file=sys.stderr)
        sys.exit(2)

    files = [f.strip() for f in out.splitlines() if f.strip().endswith('.arb')]
    return files


def check_pair(zh_path, en_path):
    """双向检查一对 ARB 文件的 key 同步"""
    zh = keys(zh_path)
    en = keys(en_path)
    print(f'zh total: {len(zh)} / en total: {len(en)}')

    missing_in_en = sorted(zh - en)
    print(f'Missing in en ({len(missing_in_en)}):')
    for k in missing_in_en:
        print(f'  {k}')

    missing_in_zh = sorted(en - zh)
    print(f'Missing in zh ({len(missing_in_zh)}):')
    for k in missing_in_zh:
        print(f'  {k}')

    if missing_in_en or missing_in_zh:
        print(
            f'[FAIL] check_arb_keys: {len(missing_in_en)} missing in en, '
            f'{len(missing_in_zh)} missing in zh'
        )
        return False
    print(f'[OK] check_arb_keys: zh and en synchronized')
    return True


def check_hant(zh_path, hant_path):
    """检查 zh_Hant.arb 跟 zh.arb 的 key 同步

    v0.24 round 48 (sp-zh P1-21) 新增:
    - zh_Hant.arb 是 OpenCC s2tw 繁化的产物,理论上跟 zh.arb 100% 同步
    - 但 P0 fix 加 5 个 i18n key 时只改了 zh.arb / en.arb,漏了 zh_Hant.arb
    - 修正方法: 跑 flutter gen-l10n 会重新生成所有 3 个 ARB 对应的 .dart 文件,
      但 arb 文件本身需要手工加 (gen-l10n 不修改 arb 源文件)
    - 守护: --staged 模式如果检测到 zh_Hant 落后,exit 1 提示修正
    """
    zh = keys(zh_path)
    hant = keys(hant_path)
    print(f'zh_Hant total: {len(hant)}')

    missing_in_hant = sorted(zh - hant)
    print(f'Missing in zh_Hant ({len(missing_in_hant)}):')
    for k in missing_in_hant:
        print(f'  {k}')

    # 反向不应该有 (zh_Hant 是从 zh 繁化来的)
    extra_in_hant = sorted(hant - zh)
    if extra_in_hant:
        print(f'[WARN] {len(extra_in_hant)} extra keys in zh_Hant (not in zh):')
        for k in extra_in_hant:
            print(f'  {k}')

    if missing_in_hant:
        print(
            f'[FAIL] check_arb_keys (hant): {len(missing_in_hant)} missing in zh_Hant. '
            f'Fix: copy missing keys from zh.arb to zh_Hant.arb '
            f'(use OpenCC s2tw to convert to Traditional Chinese), '
            f'then run `flutter gen-l10n` to regenerate .dart files.'
        )
        return False
    print(f'[OK] check_arb_keys: zh_Hant synchronized with zh')
    return True


def main():
    args = sys.argv[1:]
    if '--staged' in args:
        idx = args.index('--staged')
        base_ref = args[idx + 1] if idx + 1 < len(args) and not args[idx + 1].startswith('--') else 'HEAD'
        modified = get_modified_arb_files(base_ref)
        if not modified:
            print(f'[OK] check_arb_keys --staged ({base_ref}): no .arb files modified, skip')
            return

        print(f'--staged mode: {len(modified)} modified .arb files (base={base_ref})')
        for f in modified:
            print(f'  - {f}')

        # 只对修改过的文件做检查 (假设另一个文件未改, 走全量仍能 catch 不一致)
        # 简单做法: 任何 .arb 改动都跑全量对 (因为是双向同步)
        ok_zh_en = check_pair(r'lib/l10n/app_zh.arb', r'lib/l10n/app_en.arb')
        # v0.24 round 48 (sp-zh P1-21): 加 zh_Hant 同步检查
        ok_hant = check_hant(r'lib/l10n/app_zh.arb', r'lib/l10n/app_zh_Hant.arb')
        if not (ok_zh_en and ok_hant):
            sys.exit(1)
        return

    # default: 全量
    ok_zh_en = check_pair(r'lib/l10n/app_zh.arb', r'lib/l10n/app_en.arb')
    ok_hant = check_hant(r'lib/l10n/app_zh.arb', r'lib/l10n/app_zh_Hant.arb')
    if not (ok_zh_en and ok_hant):
        sys.exit(1)


if __name__ == '__main__':
    main()
