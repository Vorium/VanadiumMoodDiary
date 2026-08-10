import io
lines = io.open(r'reports/r100/verify_full_test.log', encoding='utf-8', errors='replace').readlines()
fails = [i for i, l in enumerate(lines) if '[E]' in l]
out = []
for i in fails:
    out.append('=== line %d ===' % (i + 1))
    out.extend(lines[i:i + 40])
io.open(r'reports/r100/verify_fails.txt', 'w', encoding='utf-8').write('\n'.join(out))
print('fail_lines=%d' % len(fails))
