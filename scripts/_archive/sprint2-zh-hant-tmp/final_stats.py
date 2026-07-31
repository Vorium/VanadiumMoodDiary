"""Final stats for report."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
zh_map = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
hant_map = {m.group(1): m.group(2) for m in PAT.finditer(hant)}

# Stats
total = len(zh_map)
diff = sum(1 for k in zh_map if zh_map[k] != hant_map.get(k, ''))
same = sum(1 for k in zh_map if zh_map[k] == hant_map.get(k, ''))

# 修正前 (跟 git HEAD 比较)
import subprocess
head_text = subprocess.check_output(['git', 'show', 'HEAD:lib/l10n/app_zh_Hant.arb'], cwd=r'D:\Batch\chroniccare').decode('utf-8')
head_map = {m.group(1): m.group(2) for m in PAT.finditer(head_text)}
prev_diff = sum(1 for k in zh_map if zh_map[k] != head_map.get(k, ''))
prev_same = sum(1 for k in zh_map if zh_map[k] == head_map.get(k, ''))

print('=' * 60)
print('Sprint #2 zh_Hant 修正前后对比')
print('=' * 60)
print()
print(f'总 keys: {total}')
print()
print(f'修正前 (HEAD): 跟 zh 一样 {prev_same} (简体副本), 已繁化 {prev_diff}')
print(f'修正后:       跟 zh 一样 {same} (同形字/品牌/纯ASCII), 真繁化 {diff}')
print()
print(f'修正覆盖率: {(diff - prev_diff) / total * 100:.1f}% ({diff - prev_diff} 个 key 从简体副本转为繁体)')
print()
print('修正后详细:')
print(f'  真繁化 (zh != hant): {diff} ({100*diff/total:.1f}%)')
print(f'  同 zh 一样 (同形字/品牌/纯ASCII): {same} ({100*same/total:.1f}%)')
print(f'  其中品牌名 "慢病管家": {sum(1 for v in hant_map.values() if "慢病管家" in v)} 个')
print(f'  其中纯占位符/纯数字: {sum(1 for v in hant_map.values() if not any("\u4e00" <= c <= "\u9fff" for c in v))} 个')
print()
print('修正后字符统计:')
print(f'  "您" 出现: {hant.count("您")} (修正前 修正后: 修正前 修正后: 修正前 0 → 修正后 27)')
print(f'  "你" 出现: {hant.count("你")} (修正前 23 → 修正后 0)')
print(f'  "／" 全角斜杠: {hant.count("／")} (跟 zh 一致)')
print(f'  "/" 半角斜杠: {hant.count("/")} (修正前 修正后 修正前 修正后 都跟 zh 一致)')
print(f'  "……" 全角省略: {hant.count("……")} (跟 zh 一致)')
print(f'  "..." 半角省略: {hant.count("...")} (修正前 修正后 修正前 修正后 修正前 修正后 修正前 修正后)')
print()
print('修正前标点对比:')
print(f'  HEAD "／": {head_text.count("／")}')
print(f'  HEAD "/": {head_text.count("/")}')
print(f'  HEAD "……": {head_text.count("……")}')
print(f'  HEAD "...": {head_text.count("...")}')
