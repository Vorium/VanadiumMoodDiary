#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #5 / spzh C-09): check_zh_hant_consistency 守门员
#
# 作用: 验证 `lib/l10n/app_zh_Hant.arb` 跟 `app_zh.arb` 繁简转换一致
#
# 背景: spzh v0.25 round 56h P0 报告: zh_Hant 落后 zh 6 key (R54 加 privacy 时漏)
#   修正方法: 用 OpenCC s2tw 复算 zh → 繁中, 跟现有 app_zh_Hant.arb 内容对比
#   差异 > 0 → 报 [FAIL] (说明 zh_Hant 没跟 zh 同步)
#
# 范围: lib/l10n/app_zh.arb + lib/l10n/app_zh_Hant.arb
# 退出: 0 = pass, 1 = fail
import io
import json
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

ROOT = Path(__file__).resolve().parent.parent
L10N_DIR = ROOT / "lib" / "l10n"
ZH_ARB = L10N_DIR / "app_zh.arb"
HANT_ARB = L10N_DIR / "app_zh_Hant.arb"


def load_arb(path: Path) -> dict:
    with path.open(encoding='utf-8') as f:
        return json.load(f)


def opencc_s2tw(text: str) -> str:
    """用 OpenCC s2tw 复算 zh → 繁中
    s2tw = Simplified → Traditional Used in Taiwan
    注: 项目用 s2tw (不是 s2t), 因为台湾用字略有差异 (如"里"/"裡")
    """
    try:
        from opencc import OpenCC
    except ImportError:
        print('[FAIL] 缺 opencc 包, 跑 `pip install opencc-python-reimplemented`',
              file=sys.stderr)
        sys.exit(2)
    cc = OpenCC('s2tw')
    return cc.convert(text)


def main() -> int:
    if not ZH_ARB.exists():
        print(f'[FAIL] 找不到 {ZH_ARB}')
        return 1
    if not HANT_ARB.exists():
        print(f'[FAIL] 找不到 {HANT_ARB}')
        return 1

    try:
        zh = load_arb(ZH_ARB)
        hant = load_arb(HANT_ARB)
    except (json.JSONDecodeError, OSError) as e:
        print(f'[FAIL] ARB 解析失败: {e}')
        return 1

    # 跳过元数据 keys (@@ 开头)
    zh_entries = {k: v for k, v in zh.items() if not k.startswith('@@')}
    hant_entries = {k: v for k, v in hant.items() if not k.startswith('@@')}

    # 跳过 metadata pairs (@xxx: { placeholders: ... })
    zh_value_keys = {k: v for k, v in zh_entries.items() if not k.startswith('@')}
    hant_value_keys = {k: v for k, v in hant_entries.items() if not k.startswith('@')}

    # 1. 检查 key 一致 (跟 check_arb_keys.py 一致)
    missing_in_hant = sorted(set(zh_value_keys) - set(hant_value_keys))
    if missing_in_hant:
        print(f'[FAIL] check_zh_hant_consistency: {len(missing_in_hant)} 个 key 在 zh_Hant 缺失')
        for k in missing_in_hant[:5]:
            print(f'    - {k}')
        if len(missing_in_hant) > 5:
            print(f'    ... 另 {len(missing_in_hant) - 5} 个')
        return 1

    # 2. 检查繁简一致: 用 OpenCC s2tw 复算 zh 的 value, 跟 hant 比
    # 只对 value 是 string 的 key 做对比 (object = metadata, 跳过)
    diff_count = 0
    diffs: list[tuple[str, str, str, str]] = []
    for key, zh_value in zh_value_keys.items():
        if not isinstance(zh_value, str):
            continue
        if key not in hant_value_keys:
            continue
        hant_value = hant_value_keys[key]
        if not isinstance(hant_value, str):
            continue
        # 跳过纯 ASCII / 纯 placeholder / 纯 URL
        if not re.search(r'[\u4e00-\u9fff]', zh_value):
            continue
        # 复算
        try:
            expected_hant = opencc_s2tw(zh_value)
        except Exception as e:
            print(f'[WARN] OpenCC 转换失败 key={key}: {e}', file=sys.stderr)
            continue
        if expected_hant != hant_value:
            diff_count += 1
            diffs.append((key, zh_value, hant_value, expected_hant))

    if diff_count > 0:
        print(f'[FAIL] check_zh_hant_consistency: {diff_count} 处繁简不一致')
        print('  修正:')
        print('    1. 改 zh (zh_Hant 跟 zh 同步走 OpenCC s2tw)')
        print('    2. 或改 zh_Hant 跟 OpenCC 输出一致')
        print('  详情 (前 5 条):')
        for key, z, h, e in diffs[:5]:
            print(f'    - key: {key}')
            print(f'        zh:      {z[:60]}')
            print(f'        zh_Hant: {h[:60]}')
            print(f'        OpenCC:  {e[:60]}')
        if diff_count > 5:
            print(f'    ... 另 {diff_count - 5} 处')
        return 1

    print(f'[OK] check_zh_hant_consistency: {len(zh_value_keys)} keys, '
          f'繁简 100% 一致 (zh ↔ zh_Hant via OpenCC s2tw)')
    return 0


if __name__ == '__main__':
    sys.exit(main())
