"""Final audit of zh_Hant after all fixes."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# Why 226 still "same" as zh?
same_keys = [k for k in zh_map if zh_map[k] == hant_map.get(k, '')]
print(f'修正后跟 zh 完全一样: {len(same_keys)}')
print('样例:')
for k in same_keys[:20]:
    v = zh_map[k]
    print(f'  {k}: {v!r}')

# Are they truly no-simp-chars?
import unicodedata
SIMP_SURE = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟续动态观点网路通讯视讯绘图作业档案连结资读记忆体程式码编译器资料库')

# Re-identify with TRUE simp chars
simp_keys = []
for k in same_keys:
    v = zh_map[k]
    simp = [c for c in v if c in SIMP_SURE]
    if simp:
        simp_keys.append((k, v, simp))

print()
print(f'修正后"跟 zh 一样"但仍含真简体字的: {len(simp_keys)}')
for k, v, simp in simp_keys[:10]:
    print(f'  {k}: {v!r} ({simp})')
