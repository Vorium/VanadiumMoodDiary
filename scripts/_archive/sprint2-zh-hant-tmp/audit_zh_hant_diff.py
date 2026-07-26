"""Compare zh_Hant before/after conversion."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
old = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()
new = open(r'lib/l10n/app_zh_Hant.arb.tmp', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)


def get_value_map(text):
    return {m.group(1): m.group(2) for m in PAT.finditer(text)}


v_zh = get_value_map(zh)
v_old = get_value_map(old)
v_new = get_value_map(new)

old_still_simp = 0
new_still_simp = 0
old_done = 0
new_done = 0
samples = []

for k in v_zh:
    if v_zh[k] == v_new.get(k, ''):
        new_done += 1
    else:
        new_still_simp += 1
        if len(samples) < 25:
            samples.append((k, v_zh[k][:35], v_new.get(k, '')[:35]))

    if v_zh[k] == v_old.get(k, ''):
        old_still_simp += 1
    else:
        old_done += 1

print(f'修真前 zh_Hant 跟 zh 完全一样: {old_still_simp}')
print(f'修真前 zh_Hant 已繁化: {old_done}')
print(f'修真后 zh_Hant 跟 zh 完全一样: {new_still_simp}')
print(f'修真后 zh_Hant 已繁化: {new_done}')
print()
print(f'=== 修真后剩余 {new_still_simp} 个 key 还有差异 (前 25 个) ===')
for k, vz, vn in samples:
    print(f'  {k}:')
    print(f'    zh:   {vz!r}')
    print(f'    hant: {vn!r}')
