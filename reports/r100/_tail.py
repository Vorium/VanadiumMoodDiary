import io
lines = io.open(r'reports/r100/verify_full_test.log', encoding='utf-8', errors='replace').readlines()
io.open(r'reports/r100/verify_tail.txt', 'w', encoding='utf-8').write(''.join(lines[-6:]))
