"""Find all dart files with potentially mojibake'd Chinese in comments."""
import os
import sys
sys.stdout.reconfigure(encoding='utf-8')

# Mojibake markers: characters from PUA or rare CJK that come from double-encoding
# A safer heuristic: look for high codepoints that match double-encoding pattern
# (i.e., characters in 0xE2xx range or PUA)

results = []
for root, dirs, files in os.walk('lib'):
    for f in files:
        if not f.endswith('.dart'):
            continue
        path = os.path.join(root, f)
        with open(path, 'rb') as fh:
            data = fh.read()
        try:
            text = data.decode('utf-8')
        except UnicodeDecodeError:
            results.append((path, 'NOT_UTF8'))
            continue
        # Heuristic: if text contains many chars in unusual CJK range
        # The double-encoded chars tend to be in U+6790-6FFF and U+E000+
        suspicious = sum(1 for c in text if c in '\u6799\u6B40\u6B58\u6790\u679A\u69B8\u73BA\u6B20\u6B50\u73AF\u91D1\u904D' or
                        0xE000 <= ord(c) <= 0xF8FF)
        if suspicious >= 3:
            results.append((path, suspicious))

results.sort(key=lambda x: -x[1])
print(f'Total files with mojibake: {len(results)}')
for path, count in results:
    print(f'  {count:4d}  {path}')
