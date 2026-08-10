"""R101 审计辅助: 大文件统计 + repo 根垃圾文件清单。一次性脚本。"""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

# 1. lib/ 大文件 top 25
files = []
for r, d, fs in os.walk(os.path.join(ROOT, 'lib')):
    for f in fs:
        if f.endswith('.dart'):
            p = os.path.join(r, f)
            with open(p, encoding='utf-8', errors='ignore') as fh:
                n = sum(1 for _ in fh)
            files.append((n, os.path.relpath(p, ROOT)))
files.sort(reverse=True)
print('=== lib/ top 25 by lines ===')
for n, p in files[:25]:
    print(f'{n:6d}  {p}')
print(f'lib total dart files: {len(files)}, total lines: {sum(n for n, _ in files)}')

# 2. test/ 统计
tf = []
for r, d, fs in os.walk(os.path.join(ROOT, 'test')):
    for f in fs:
        if f.endswith('.dart'):
            tf.append(os.path.join(r, f))
print(f'test total dart files: {len(tf)}')

# 3. repo 根垃圾 (非标准目录/文件)
keep = {
    'android', 'assets', 'build', 'coverage', 'docs', 'fastlane', 'ios',
    'lib', 'reports', 'scripts', 'test', 'web', 'whitePaper',
    '.github', '.idea', '.dart_tool', '.qoder', '.mimocode', '.mavis-trash',
    '.superpowers', '.r61_backup_20260731_101630', '.r61_backup_logs',
    '.git', '__pycache__',
}
keep_files = {
    '.codecov.yml', '.env', '.env.example', '.flutter-plugins-dependencies',
    '.gitignore', '.metadata', 'AGENTS.md', 'README.md',
    'analysis_options.yaml', 'chroniccare.iml', 'coverage_threshold.yaml',
    'l10n.yaml', 'pubspec.lock', 'pubspec.yaml', 'pubspec_overrides.yaml',
}
print('=== repo root junk ===')
for entry in sorted(os.listdir(ROOT)):
    if os.path.isdir(os.path.join(ROOT, entry)):
        if entry not in keep:
            print(f'  DIR   {entry}')
    else:
        if entry not in keep_files:
            sz = os.path.getsize(os.path.join(ROOT, entry))
            print(f'  FILE  {entry}  ({sz} bytes)')

# 4. reports/ 根散落的旧报告
print('=== reports/ root loose files ===')
rp = os.path.join(ROOT, 'reports')
for entry in sorted(os.listdir(rp)):
    if os.path.isfile(os.path.join(rp, entry)):
        print(f'  {entry}')

# 5. scripts/ 一次性脚本
print('=== scripts/ files ===')
sp = os.path.join(ROOT, 'scripts')
for entry in sorted(os.listdir(sp)):
    print(f'  {entry}')
