#!/usr/bin/env python3
"""Try GBK decode of the file"""
import sys
import re

if sys.platform == "win32":
    try:
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    except (AttributeError, OSError):
        pass

with open('lib/core/routing/app_router.dart', 'rb') as f:
    data = f.read()

# Try GBK decode
try:
    gbk_text = data.decode('gbk')
    print("GBK decoded successfully")
    print("Sample first 2000 chars:")
    print(gbk_text[:2000])
except UnicodeDecodeError as e:
    print(f"GBK decode failed: {e}")
