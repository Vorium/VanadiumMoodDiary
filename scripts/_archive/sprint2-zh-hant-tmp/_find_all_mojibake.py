#!/usr/bin/env python3
"""Find all PUA lines and pair with original"""
import re
import sys
import subprocess

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
        sys.stderr.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

# Get original clean file
result = subprocess.run(
    ['git', 'show', '9c305ed:lib/core/routing/app_router.dart'],
    cwd=r'D:\Batch\chroniccare',
    capture_output=True
)
old_text = result.stdout.decode('utf-8')
old_lines = old_text.splitlines()

# Get current mojibake file
with open(r'D:\Batch\chroniccare\lib\core\routing\app_router.dart', 'rb') as f:
    new_text = f.read().decode('utf-8')
new_lines = new_text.splitlines()

pua_pattern = re.compile(r'[\uE000-\uF8FF]')

# All PUA line numbers
pua_lines = []
for i, line in enumerate(new_lines, 1):
    if pua_pattern.search(line):
        pua_lines.append(i)

# For each PUA line, find best match
print("=" * 80)
print(f"Total PUA lines: {len(pua_lines)}")
print("=" * 80)
for ln in pua_lines:
    new_line = new_lines[ln - 1]

    # Strategy: extract code/identifier portions (no CJK), and use as anchor
    new_ascii_words = re.findall(r'[A-Za-z0-9_/.]+', new_line)

    best_match = None
    best_score = 0
    for old_ln, old_line in enumerate(old_lines, 1):
        old_ascii_words = re.findall(r'[A-Za-z0-9_/.]+', old_line)
        # Count common words
        common = sum(1 for w in new_ascii_words if w in old_ascii_words)
        if common > best_score:
            best_score = common
            best_match = old_ln

    if best_match and best_score >= 1:
        print(f"NEW L{ln:3d} → OLD L{best_match:3d} (score={best_score})")
        # Use safe encoding for print
        safe_new = new_line.encode('utf-8', errors='replace').decode('utf-8')
        safe_old = old_lines[best_match-1]
        print(f"  NEW: {safe_new[:120]}")
        print(f"  OLD: {safe_old[:120]}")
        print()
    else:
        print(f"NEW L{ln:3d} → NO MATCH (best_score={best_score})")
        safe_new = new_line.encode('utf-8', errors='replace').decode('utf-8')
        print(f"  NEW: {safe_new[:120]}")
        print()
