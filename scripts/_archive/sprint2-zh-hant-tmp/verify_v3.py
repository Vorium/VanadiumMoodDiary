"""Refined audit: distinguish real simp residue from same-form chars."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# Tighter set of TRUE simplified-only characters (those with distinct 繁 form)
# Based on OpenCC's s2tw char mapping
TRUE_SIMP = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟点编检队与产没预阅读隐复观关联网路图档案资记忆体程式码编译器资料库视讯绘图作业连结档案')

residuals = []
for k, v in hant_map.items():
    simp = [c for c in v if c in TRUE_SIMP]
    if simp:
        residuals.append((k, v, simp))
print(f'修正后真简体残留: {len(residuals)}')
for k, v, simp in residuals[:20]:
    print(f'  {k}: {v!r} ({simp})')

# Same-form 残留 (即 OpenCC 不动)
# These are 同形字 (天/分/情/息/作/案/式/路/程/行/器/...)
# 全部都正确
print()
print('=== 修正后跟 zh 完全一样的 key (无真简体字) ===')
same = [k for k in zh_map if zh_map[k] == hant_map.get(k, '')]
print(f'共 {len(same)} 个, 占总 {100*len(same)/len(zh_map):.1f}%')
for k in same[:15]:
    print(f'  {k}: {zh_map[k]!r}')

# 修正后 hant 跟 zh 不一样 (即真繁化)
diff = [k for k in zh_map if zh_map[k] != hant_map.get(k, '')]
print()
print(f'修正后真繁化: {len(diff)} 个, 占总 {100*len(diff)/len(zh_map):.1f}%')
for k in diff[:5]:
    print(f'  {k}:')
    print(f'    zh:   {zh_map[k]!r}')
    print(f'    hant: {hant_map[k]!r}')
