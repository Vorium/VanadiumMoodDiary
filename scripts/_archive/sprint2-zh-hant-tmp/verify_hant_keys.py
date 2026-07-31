"""Final verification: key parity, value comparison."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()
old = open(r'lib/l10n/app_zh_Hant.arb.tmp', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# key parity
print(f'zh keys: {len(zh_map)}')
print(f'hant keys: {len(hant_map)}')
print(f'key 一致: {set(zh_map) == set(hant_map)}')

# 修正前/后对比
same_zh = sum(1 for k in zh_map if zh_map[k] == hant_map.get(k, ''))
print(f'修正后 hant 跟 zh 完全一样 (即简体副本残留): {same_zh}')
print(f'修正后 hant 跟 zh 不一样 (即真正的繁体): {len(zh_map) - same_zh}')

# 跟修正前 tmp 比
same_tmp = sum(1 for k in hant_map if hant_map[k] == old_map.get(k, '') if k in (old_map := {m.group(1): m.group(2) for m in PAT.finditer(old)}))
print(f'修正后 hant 跟修正前 tmp 完全一样: {same_tmp}')

# 标点
print()
print(f'修正后 hant "／" 计数: {hant.count("／")}')
print(f'修正后 hant "/" 计数: {hant.count("/")}')
print(f'修正后 hant "……" 计数: {hant.count("……")}')
print(f'修正后 hant "..." 计数: {hant.count("...")}')
print(f'修正后 hant "—" 计数: {hant.count("—")}')
print(f'修正后 hant "--" 计数: {hant.count("--")}')
print(f'修正后 hant "您" 计数: {hant.count("您")}')
print(f'修正后 hant "你" 计数: {hant.count("你")}')
