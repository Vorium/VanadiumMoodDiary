"""Compare zh and hant punctuation for inconsistency."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
new = open(r'lib/l10n/app_zh_Hant.arb.tmp', encoding='utf-8').read()

PAT = re.compile(r'^  "([a-zA-Z][a-zA-Z0-9]+)":\s*"([^"]*)"', re.M)
v_zh = {m.group(1): m.group(2) for m in PAT.finditer(zh)}
v_new = {m.group(1): m.group(2) for m in PAT.finditer(new)}

# 对比 zh 和 new 的标点
def find_punct(text):
    return {
        '／': text.count('／'),
        '/': text.count('/') - text.count('//'),
        '……': text.count('……'),
        '...': text.count('...'),
        '—': text.count('—'),
        '--': text.count('--'),
        '，': text.count('，'),
        ',': text.count(','),
        '（': text.count('（'),
        '(': text.count('('),
        '）': text.count('）'),
        ')': text.count(')'),
        '：': text.count('：'),
        ':': text.count(':'),
        '？': text.count('？'),
        '?': text.count('?'),
        '！': text.count('！'),
        '!': text.count('!'),
        '「': text.count('「'),
        '」': text.count('」'),
    }

zh_punct = find_punct(zh)
new_punct = find_punct(new)

print('=== zh vs new 标点对比 ===')
print(f'{"":10s} {"zh":>8s} {"new":>8s} {"diff":>8s}')
for k in zh_punct:
    z = zh_punct[k]
    n = new_punct[k]
    if z != n:
        print(f'  {k:<8s} {z:>8d} {n:>8d} {n-z:>+8d}')

# 标点不一致的 key
print()
print('=== 标点不一致的 key (zh vs new) ===')
for k in v_zh:
    if k not in v_new:
        continue
    zh_v = v_zh[k]
    new_v = v_new[k]
    # 标点检查
    for p_zh, p_new in [('／', '/'), ('……', '...'), ('，', ','), ('（', '('), ('）', ')'), ('：', ':'), ('？', '?'), ('！', '!')]:
        if p_zh in zh_v and p_new in new_v:
            print(f'  {k}: zh={zh_v!r}')
            print(f'         new={new_v!r}')
            break

# 找您 vs 你 不一致
print()
print('=== 您/你 不一致 ===')
for k in v_zh:
    if k not in v_new:
        continue
    if ('您' in v_zh[k] and '你' in v_new[k]) or ('你' in v_zh[k] and '您' in v_new[k]):
        print(f'  {k}:')
        print(f'    zh:   {v_zh[k]!r}')
        print(f'    new:  {v_new[k]!r}')
