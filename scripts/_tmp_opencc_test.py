import opencc
import sys

c = opencc.OpenCC('s2tw')
# Read zh (the source from ARB file)
with open('lib/l10n/app_zh.arb', 'r', encoding='utf-8') as f:
    text = f.read()

# Extract contactConsentBody value
import json
data = json.loads(text.replace('\n', ' '))
zh = data.get('contactConsentBody', '')

# OpenCC s2tw
hant = c.convert(zh)

# Write to file
with open('scripts/_tmp_opencc_out.txt', 'w', encoding='utf-8') as f:
    f.write('=== OpenCC s2tw 期望 ===\n')
    f.write(hant)
    f.write('\n=== 当前 zh_Hant ===\n')
    # Read zh_Hant
    with open('lib/l10n/app_zh_Hant.arb', 'r', encoding='utf-8') as f2:
        text2 = f2.read()
    data2 = json.loads(text2.replace('\n', ' '))
    hant_actual = data2.get('contactConsentBody', '')
    f.write(hant_actual)
    f.write('\n=== 差异 ===\n')
    for i, (a, b) in enumerate(zip(hant, hant_actual)):
        if a != b:
            f.write(f'pos={i} 期望={repr(a)} 实际={repr(b)}\n')
            f.write(f'  期望上下文: {repr(hant[max(0,i-10):i+10])}\n')
            f.write(f'  实际上下文: {repr(hant_actual[max(0,i-10):i+10])}\n')
            break
