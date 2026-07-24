import sys
sys.stdout.reconfigure(encoding='utf-8')
with open('lib/core/routing/app_router.dart', 'rb') as f:
    data = f.read()
# Find the comment block by searching for '/// '
i = data.find(b'/// ')
while i < len(data):
    # Check if this is the comment block (followed by non-ASCII)
    if i + 10 < len(data) and data[i+4] > 0x7F:
        chunk = data[i:i+300]
        print(f'Found at offset {i}')
        print('Hex:', chunk[:80].hex())
        print('UTF-8 decode:', chunk.decode('utf-8', errors='replace')[:200])
        try:
            print('GBK decode:', chunk.decode('gbk', errors='replace')[:200])
        except:
            pass
        print('---')
        break
    i = data.find(b'/// ', i+1)
