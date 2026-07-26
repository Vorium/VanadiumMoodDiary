"""Find remaining issues in converted zh_Hant.

Look for:
1. 简体 chars still in hant (any of the 49 prior partial-conversion samples)
2. 您/你 inconsistency
3. Full-width vs half-width punctuation inconsistencies (/, —, —, …, ...)
4. Words that OpenCC may have wrong for medical app context
"""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
new = open(r'lib/l10n/app_zh_Hant.arb.tmp', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
v_zh = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
v_new = {m.group(1): m.group(2) for m in PAT.finditer(new)}

# 简体特征字 (常见简体形式)
SIMP = set('药医疗护卫评测记录软应实现显确号码备异请谢视听体关处结终继续长间为会动开个个们众仅余样这那运行响听亲爱经营统种类节将导带专达发户办让认议论语词请谢报员岁岁时天情绪焦虑抑郁睡眠疲惫紧张评估答卷分级组给简复关联网路图档软体讯息作业')

# 已知需要"您"而不是"你"的 key (医疗 app 保持正式)
MUST_YOU = set()  # we'll detect

print('=== 1. 含简体字但 OpenCC 未转 (简体残留) ===')
residuals = []
for k, v in v_new.items():
    simp = [c for c in v if c in SIMP]
    if simp:
        residuals.append((k, v, simp))
print(f'共 {len(residuals)} 个 key 含简体残留:')
for k, v, simp in residuals:
    print(f'  {k}: {v!r} ({simp})')

print()
print('=== 2. 您 vs 你 统计 ===')
nin_count = 0
you_count = 0
for k, v in v_new.items():
    if '您' in v:
        you_count += 1
    if '你' in v:
        nin_count += 1
print(f'含"您": {you_count}')
print(f'含"你": {nin_count}')

print()
print('=== 3. 全角／半角标点统计 ===')
fw_slash = sum(1 for v in v_new.values() if '／' in v)
hw_slash = sum(1 for v in v_new.values() if '/' in v and '／' not in v and '//' not in v and '/ 1' not in v)  # exclude paths
fw_ellipsis = sum(1 for v in v_new.values() if '……' in v)
hw_ellipsis = sum(1 for v in v_new.values() if '...' in v)
fw_dash = sum(1 for v in v_new.values() if '—' in v)
hw_dash = sum(1 for v in v_new.values() if '--' in v or ' - ' in v)
print(f'含"／" (全角斜杠): {fw_slash}')
print(f'含"/" (半角斜杠, 非路径): {hw_slash}')
print(f'含"……" (全角省略): {fw_ellipsis}')
print(f'含"..." (半角省略): {hw_ellipsis}')
print(f'含"—" (em dash): {fw_dash}')
print(f'含"--"/" - " (双连字符/半角): {hw_dash}')
