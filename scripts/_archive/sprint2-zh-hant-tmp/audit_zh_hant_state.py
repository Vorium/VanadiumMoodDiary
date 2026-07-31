"""Audit zh_Hant state vs zh - 修正前基线."""
import re

zh = open(r'lib/l10n/app_zh.arb', encoding='utf-8').read()
hant = open(r'lib/l10n/app_zh_Hant.arb', encoding='utf-8').read()

keys_zh = set(re.findall(r'^  "([a-zA-Z][a-zA-Z0-9]+)":', zh, re.M))
keys_hant = set(re.findall(r'^  "([a-zA-Z][a-zA-Z0-9]+)":', hant, re.M))

print(f'zh keys: {len(keys_zh)}')
print(f'hant keys: {len(keys_hant)}')
print(f'missing in hant: {len(keys_zh - keys_hant)}')
print(f'extra in hant: {len(keys_hant - keys_zh)}')

same_count = 0
diff_count = 0
sample_same = []
sample_diff = []

for k in keys_zh & keys_hant:
    v_zh = re.search(rf'^  "{k}":\s*"([^"]*)"', zh, re.M)
    v_hant = re.search(rf'^  "{k}":\s*"([^"]*)"', hant, re.M)
    if v_zh and v_hant:
        if v_zh.group(1) == v_hant.group(1):
            same_count += 1
            if len(sample_same) < 8:
                sample_same.append((k, v_zh.group(1)[:50]))
        else:
            diff_count += 1
            if len(sample_diff) < 15:
                sample_diff.append((k, v_zh.group(1)[:40], v_hant.group(1)[:40]))

print(f'完全相同 (简体副本): {same_count}')
print(f'已繁化 (不同): {diff_count}')
print()

print('=== 简体副本样例 (前 8 个) ===')
for k, v in sample_same:
    print(f'  {k}: {v!r}')

print()
print('=== 已繁化样例 (前 15 个) ===')
for k, vz, vh in sample_diff:
    print(f'  {k}:')
    print(f'    zh:   {vz!r}')
    print(f'    hant: {vh!r}')

# 统计简体 key 的字符总览
simplified_chars = set()
for k in keys_zh & keys_hant:
    v_zh = re.search(rf'^  "{k}":\s*"([^"]*)"', zh, re.M)
    v_hant = re.search(rf'^  "{k}":\s*"([^"]*)"', hant, re.M)
    if v_zh and v_hant and v_zh.group(1) == v_hant.group(1):
        for ch in v_zh.group(1):
            if '\u4e00' <= ch <= '\u9fff':
                simplified_chars.add(ch)
print()
print(f'简体副本中出现的简体中文字符种数: {len(simplified_chars)}')
# 简单分类: 列出最常见的 50 个
print(f'前 50 个: {sorted(simplified_chars)[:50]}')
