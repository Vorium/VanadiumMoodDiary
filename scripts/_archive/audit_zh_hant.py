"""Final utility: keep this for re-running zh_Hant audit / re-conversion if needed."""
"""Convert app_zh_Hant.arb from simplified to traditional using OpenCC s2tw (v2 - robust).

Usage: python scripts/audit_zh_hant.py [convert|stats]
- convert: re-runs OpenCC s2tw on app_zh_Hant.arb (writes in place)
- stats: prints coverage stats (default if no arg)

Idempotent: convert on already-converted file is safe (OpenCC handles s2tw idempotency).
"""
import re
import sys
import subprocess
import opencc

CONVERTER = opencc.OpenCC('s2tw')
ZH_PATH = r'lib/l10n/app_zh.arb'
HANT_PATH = r'lib/l10n/app_zh_Hant.arb'

# Correct set of simplified-only chars (s2tw actually changes these)
S2T_DIFF = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟点编检队与产没预阅读隐图档网讯记忆体程式码编译器资料库视讯绘图作业连结资读')
# Same-form (NOT real residue): 器/程/式/行/息/案/路/情/天/分/估/答/作/数
EXCLUDE = set('器程式行息案路情天分估答作数')
TRUE_SIMP = S2T_DIFF - EXCLUDE


def get_value_map(text):
    return {m.group(1): m.group(2)
            for m in re.finditer(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', text, re.M)}


def convert():
    zh_text = open(ZH_PATH, encoding='utf-8').read()
    hant_text = open(HANT_PATH, encoding='utf-8').read()
    zh_map = get_value_map(zh_text)
    out_lines = []
    for line in hant_text.splitlines(keepends=True):
        m = re.match(r'^(  ")([a-zA-Z][a-zA-Z0-9]+)(": ")(.*)("(?:,?)\s*)(.*)$', line.rstrip('\n'))
        if not m:
            out_lines.append(line)
            continue
        indent, key, mid, value, end, rest = m.groups()
        new_value = CONVERTER.convert(value)
        zh_value = zh_map.get(key, '')
        if '您' in zh_value and '你' in new_value and '您' not in new_value:
            new_value = new_value.replace('你', '您')
        if '／' in zh_value and '/' in new_value and '／' not in new_value:
            new_value = new_value.replace('/', '／')
        if '……' in zh_value and '...' in new_value:
            new_value = new_value.replace('...', '……')
        out_lines.append(f'{indent}{key}{mid}{new_value}{end}{rest}\n')
    with open(HANT_PATH, 'w', encoding='utf-8') as f:
        f.write(''.join(out_lines))
    print(f'Wrote {HANT_PATH}')


def stats():
    zh_text = open(ZH_PATH, encoding='utf-8').read()
    hant_text = open(HANT_PATH, encoding='utf-8').read()
    head_text = subprocess.check_output(
        ['git', 'show', 'HEAD:lib/l10n/app_zh_Hant.arb'],
        cwd=r'D:\Batch\chroniccare'
    ).decode('utf-8')

    zh_map = get_value_map(zh_text)
    hant_map = get_value_map(hant_text)
    head_map = get_value_map(head_text)
    total = len(zh_map)

    diff_now = sum(1 for k in zh_map if zh_map[k] != hant_map.get(k, ''))
    diff_head = sum(1 for k in zh_map if zh_map[k] != head_map.get(k, ''))
    same_now = total - diff_now
    same_head = total - diff_head

    residuals = [(k, hant_map[k], [c for c in hant_map[k] if c in TRUE_SIMP])
                 for k in hant_map if any(c in TRUE_SIMP for c in hant_map[k])]

    print('=' * 60)
    print('zh_Hant 修真状态')
    print('=' * 60)
    print(f'总 keys: {total}')
    print()
    print(f'HEAD (修真前): 简体副本 {same_head}, 已繁化 {diff_head}')
    print(f'当前 (修真后): 同 zh {same_now}, 真繁化 {diff_now}')
    print()
    print(f'修真覆盖率: {(diff_now - diff_head) / total * 100:.1f}%')
    print(f'真简体残留: {len(residuals)}')
    if residuals:
        for k, v, simp in residuals[:5]:
            print(f'  {k}: {v!r} ({simp})')


if __name__ == '__main__':
    cmd = sys.argv[1] if len(sys.argv) > 1 else 'stats'
    if cmd == 'convert':
        convert()
    elif cmd == 'stats':
        stats()
    else:
        print(f'Unknown command: {cmd}', file=sys.stderr)
        sys.exit(1)
