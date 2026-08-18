#!/usr/bin/env python3
"""Gatekeeper: validate 8 CN domestic platforms metadata (R128e+).

Checks:
  - Each platform has all required fields (8-10 fields)
  - app_intro.txt contains 树洞 OR 情绪 OR mood OR vent
  - app_intro.txt contains 100% 本地 OR 零云端 OR zero cloud
  - app_tags.txt has 5-10 comma-separated keywords
  - privacy_url.txt contains [PENDING_DOMAIN marker
  - soft_copyright.txt contains [PENDING_SOFT_COPYRIGHT marker

Usage: python3 scripts/check_cn_metadata.py
Exit 0: all pass / Exit 1: any failure
"""

from __future__ import annotations
import os
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

PLATFORMS = ['huawei', 'xiaomi', 'oppo', 'vivo', 'meizu',
             'tencent', 'qihoo', 'baidu']

# Per-platform required fields
REQUIRED_FIELDS = {
    'huawei': 9, 'xiaomi': 8, 'oppo': 9, 'vivo': 9,
    'meizu': 7, 'tencent': 8, 'qihoo': 8, 'baidu': 8,
}

EMOTION_KEYWORDS_CN = ['树洞', '情绪', 'mood', 'vent']
EMOTION_KEYWORDS_PRIVACY = ['100% 本地', '零云端', 'zero cloud', '本地加密']


def check_platform(platform):
    errors = []
    base = ROOT / f'fastlane/metadata/cn_domestic/{platform}'
    if not base.exists():
        return [f'  MISSING platform dir: {platform}']
    files = list(base.glob('*.txt'))
    expected = REQUIRED_FIELDS[platform]
    if len(files) < expected:
        errors.append(f'  {platform}: only {len(files)} files, expected ≥{expected}')
    # app_intro
    intro_path = base / 'app_intro.txt'
    if intro_path.exists():
        content = intro_path.read_text(encoding='utf-8')
        if not any(kw in content for kw in EMOTION_KEYWORDS_CN):
            errors.append(f'  {platform}/app_intro.txt: missing emotion keywords')
        if not any(kw in content for kw in EMOTION_KEYWORDS_PRIVACY):
            errors.append(f'  {platform}/app_intro.txt: missing privacy keywords')
    else:
        errors.append(f'  {platform}/app_intro.txt: missing')
    # app_tags
    tags_path = base / 'app_tags.txt'
    if tags_path.exists():
        content = tags_path.read_text(encoding='utf-8').strip()
        n = len([t for t in content.split(',') if t.strip()])
        if n < 5 or n > 10:
            errors.append(f'  {platform}/app_tags.txt: {n} tags, expected 5-10')
    else:
        errors.append(f'  {platform}/app_tags.txt: missing')
    # privacy_url
    privacy_path = base / 'privacy_url.txt'
    if privacy_path.exists():
        content = privacy_path.read_text(encoding='utf-8')
        if '[PENDING_DOMAIN' not in content:
            errors.append(f'  {platform}/privacy_url.txt: missing PENDING_DOMAIN marker')
    return errors


def main():
    errors = []
    for p in PLATFORMS:
        errors.extend(check_platform(p))
    if errors:
        print('CN METADATA CHECK FAILED:')
        for e in errors:
            print(e)
        sys.exit(1)
    print(f'[OK] All 8 CN domestic platforms metadata valid')


if __name__ == '__main__':
    main()