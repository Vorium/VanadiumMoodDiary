import os
root = r'd:\Batch\chroniccare\lib'
rows = []
for r, _, fs in os.walk(root):
    for f in fs:
        if not f.endswith('.dart') or 'app_localizations' in f:
            continue
        p = os.path.join(r, f)
        with open(p, encoding='utf-8', errors='ignore') as fh:
            n = sum(1 for _ in fh)
        rows.append((n, os.path.relpath(p, root)))
rows.sort(reverse=True)
for n, p in rows[:35]:
    print(f'{n:6d}  {p}')
