"""Final clean verify with CORRECT simp-only set."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# CORRECT set: only chars that OpenCC s2tw maps to a DIFFERENT char in 繁
# i.e. 器/路/程/式/作/行/案/息/情 etc are SAME form in 繁 (so excluded)
# Reference: OpenCC s2tw CharMap.txt
S2T_DIFF = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟点编检队与产没预阅读隐观关联网路图档讯息讯记忆体程式码编译器资料库')

# Wait -- 网→網, 路→路 (路 is same). Let me drop '路' from S2T_DIFF
# Actually s2tw maps 路→路 (same), so drop it
# 复 → 復 (s2tw maps 复→復)
S2T_DIFF = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟点编检队与产没预阅读隐观图档网讯息讯记忆体程式码编译器资料库')

residuals = []
for k, v in hant_map.items():
    simp = [c for c in v if c in S2T_DIFF]
    if simp:
        residuals.append((k, v, simp))
print(f'修真后真简体残留: {len(residuals)}')
for k, v, simp in residuals:
    print(f'  {k}: {v!r} ({simp})')

# 修真覆盖率统计
diff = sum(1 for k in zh_map if zh_map[k] != hant_map.get(k, ''))
same = sum(1 for k in zh_map if zh_map[k] == hant_map.get(k, ''))
print()
print(f'修真后跟 zh 不一样 (真繁化): {diff} ({100*diff/len(zh_map):.1f}%)')
print(f'修真后跟 zh 一样 (同形/品牌/纯ASCII): {same} ({100*same/len(zh_map):.1f}%)')
print(f'真简体残留: {len(residuals)}')
print(f'修真覆盖率: {(1 - len(residuals)/len(zh_map))*100:.2f}%')
