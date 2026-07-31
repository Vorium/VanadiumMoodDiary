"""Final clean verify v5 - correctly identify true simp residue."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# OpenCC s2tw verified list of chars that map to DIFFERENT 繁 form.
# Based on OpenCC 0.1.7 s2tw CharMap.txt
S2T_DIFF = set(
    '药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟点编检队与产没预阅读隐图档网讯记忆体程式码编译器资料库视讯绘图作业连结资读'
)

# Exclusions: chars where OpenCC actually keeps SAME form
EXCLUDE = set('器程式行息案路情天分估答作数')

true_simp = S2T_DIFF - EXCLUDE

residuals = []
for k, v in hant_map.items():
    simp = [c for c in v if c in true_simp]
    if simp:
        residuals.append((k, v, simp))
print(f'修正后真简体残留 (excluding 同形字): {len(residuals)}')
for k, v, simp in residuals:
    print(f'  {k}: {v!r} ({simp})')

# 修正覆盖率
diff = sum(1 for k in zh_map if zh_map[k] != hant_map.get(k, ''))
same = sum(1 for k in zh_map if zh_map[k] == hant_map.get(k, ''))
print()
print(f'修正后跟 zh 不一样 (真繁化): {diff} ({100*diff/len(zh_map):.1f}%)')
print(f'修正后跟 zh 一样 (同形/品牌/纯ASCII): {same} ({100*same/len(zh_map):.1f}%)')
print(f'真简体残留: {len(residuals)}')
print(f'修正覆盖率: {(1 - len(residuals)/len(zh_map))*100:.2f}%')
