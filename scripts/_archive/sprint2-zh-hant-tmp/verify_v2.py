"""Verify v2 conversion."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# key parity
print(f'zh keys: {len(zh_map)}')
print(f'hant keys: {len(hant_map)}')
print(f'key 一致: {set(zh_map) == set(hant_map)}')

# 真简体残留 (用更准的 set)
TRUE_SIMP = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词报员岁岁时钟点编检队与产没预阅读隐复观关联网路图档案阅软体讯息作业讯记忆体程式码编译器资料库')
residuals = []
for k, v in hant_map.items():
    simp = [c for c in v if c in TRUE_SIMP]
    if simp:
        residuals.append((k, v, simp))
print(f'修正后真简体残留: {len(residuals)}')
for k, v, simp in residuals[:30]:
    print(f'  {k}: {v!r} ({simp})')

# 修正后跟 zh 完全一样 (这些是 OpenCC 不动的 value: 纯数字/英文/品牌/标点/同形字)
same = [k for k in zh_map if zh_map[k] == hant_map.get(k, '')]
print()
print(f'修正后跟 zh 完全一样 (同形字 / 品牌名 / 占位符等): {len(same)}')

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
