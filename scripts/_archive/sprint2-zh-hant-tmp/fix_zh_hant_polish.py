"""Apply post-OpenCC polish to zh_Hant.

Fixes:
1. 您 → 你 (back to 您, 23 keys from prior partial conversion error)
2. ／ (zh uses full-width, OpenCC didn't touch /)
3. … (zh uses full-width ……, OpenCC didn't touch ...)
4. 保留 key/metadata/placeholder 完整
5. 简化: 用 zh 的标点风格作 ground truth (跟 zh 保持一致)
"""
import re

OLD = r'lib/l10n/app_zh_Hant.arb.tmp'
NEW = r'lib/l10n/app_zh_Hant.arb'

# 1. 修正前 49 key 中 把"您"改成了"你"的部分 -- 反向修复
# (这些 key 修正前 zh 是"您",修正后应该也"您")
PAT_NIN_AS_HANT = re.compile(
    r'^(  ")([^"]+)(": )"([^"]*你[^"]*)("(?:,)?)(.*)$',
    re.M
)


def fix_nin_to_nin(text):
    """Restore 您 in known-您 keys (where zh is 您)."""
    # Easier: 修正后保留"您"在 3 个 key 里,把所有"你"为 standalone pronoun 改"您"需要逐个确认
    # 简化方案: 对修正前 49 个已繁化 key + 修正后新增繁化 key,检查 zh 是"您"而 hant 是"你"的就改回
    return text


def fix_value_against_zh(text, zh_text):
    """For each key, if zh value has 您 and hant has 你, replace 你 with 您 in hant.

    Also normalize:
    - ／ vs / (use zh's choice, prefer full-width for 繁中 style)
    - …… vs ... (use zh's choice, prefer full-width)
    """
    zh_pat = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
    hant_pat = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
    zh_map = {m.group(1): m.group(2) for m in zh_pat.finditer(zh_text)}

    fixed_keys = []
    out_lines = []
    for line in text.splitlines(keepends=True):
        m = re.match(r'^(  ")([a-zA-Z][a-zA-Z0-9]+)(": )"([^"]*)("(?:,?))(.*)$', line)
        if not m:
            out_lines.append(line)
            continue
        indent, key, sep, value, end, rest = m.groups()
        zh_value = zh_map.get(key, '')
        new_value = value
        changes = []

        # 修复 1: 您/你 对齐 zh
        if '您' in zh_value and '你' in new_value and '您' not in new_value:
            # Replace standalone 你 with 您 (but not 你好, 你们, etc — use simple replace first)
            # In our context, 修正后所有"你"都是错的(都该是"您")
            new_value = new_value.replace('你', '您')
            changes.append('您')

        # 修复 2: 标点对齐 zh (／和……)
        if '／' in zh_value and '/' in new_value:
            # In zh, ／ is used for list separator. Use ／ in hant too.
            # Don't replace / inside paths like /v1.0
            new_value = re.sub(r'(?<![\w/])/(?![\w/])', '／', new_value)
            if '／' in new_value:
                changes.append('／')

        # 修复 3: 省略号对齐
        if '……' in zh_value and '...' in new_value:
            new_value = new_value.replace('...', '……')
            changes.append('……')

        if changes:
            fixed_keys.append((key, changes))
            line = f'{indent}"{key}": "{new_value}"{end}{rest}\n'
        out_lines.append(line)
    return ''.join(out_lines), fixed_keys


def main():
    with open(OLD, encoding='utf-8') as f:
        hant_text = f.read()
    with open(r'lib/l10n/app_zh.arb', encoding='utf-8') as f:
        zh_text = f.read()

    new_text, fixes = fix_value_against_zh(hant_text, zh_text)
    with open(NEW, 'w', encoding='utf-8') as f:
        f.write(new_text)

    print(f'Wrote {NEW}')
    print(f'修复了 {len(fixes)} 个 key:')
    for k, ch in fixes:
        print(f'  {k}: {ch}')


if __name__ == '__main__':
    main()
