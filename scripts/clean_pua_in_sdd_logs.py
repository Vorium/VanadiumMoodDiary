"""Clean Unicode PUA (Private Use Area) characters in sdd-logs/*.md files.

History: R84-R88 sdd-logs had PUA characters (mostly from subagent's early
brief templates). R89+ is clean. This script backfills R84-R88 to keep
check_no_pua.py guard green.

Strategy: replace PUA chars (U+E000-U+F8FF) with `?` (visible marker) so
the text is no longer PUA but the position is preserved.
"""
import os
import re

pua_re = re.compile(r'[\uE000-\uF8FF]')

root = 'docs/superpowers/sdd-logs'
total_files = 0
total_replacements = 0
for dirpath, dirnames, filenames in os.walk(root):
    for fn in filenames:
        if not fn.endswith('.md'):
            continue
        path = os.path.join(dirpath, fn)
        with open(path, 'r', encoding='utf-8') as fp:
            content = fp.read()
        new_content, n = pua_re.subn('?', content)
        if n > 0:
            with open(path, 'w', encoding='utf-8') as fp:
                fp.write(new_content)
            total_files += 1
            total_replacements += n
            print(f'  {path}: {n} PUA replaced')

print(f'Total: {total_files} files, {total_replacements} PUA replaced')
