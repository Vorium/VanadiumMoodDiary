"""check_changelog.py — CHANGELOG.md 完整性守门员

防 v0.24 round 45 漏更 (spzh 报告 P0-2):
v0.24 发布 30 commit 仍 CHANGELOG.md 没补 [0.24.0] 段 + pubspec 没 bump。
本守门员: 验证 CHANGELOG.md 跟 pubspec.yaml version 一致。

策略:
1. 读 pubspec.yaml 拿当前 version
2. 读 CHANGELOG.md 找 `## [X.Y.Z]` 段
3. 检查 CHANGELOG 是否有 pubspec version 的段
4. 检查段顺序是否按 version 倒序（防 v0.24 发现的时间倒置）
5. 检查 [0.X.0+1] build 号段是否在 [0.X.0] 之前（patch 应该排在 minor 之后）

用法:
  python scripts/check_changelog.py            # 全检
  python scripts/check_changelog.py --ci       # CI 模式
"""
import os
import re
import sys
from pathlib import Path

ROOT = Path(os.getcwd())
PUBSPEC = ROOT / "pubspec.yaml"
CHANGELOG = ROOT / "docs/CHANGELOG.md"


def get_pubspec_version():
    """从 pubspec.yaml 读 version 行"""
    try:
        text = PUBSPEC.read_text(encoding='utf-8')
    except OSError:
        return None
    m = re.search(r'^version:\s*([\d.]+\+\d+)', text, re.MULTILINE)
    return m.group(1) if m else None


def get_changelog_versions():
    """从 CHANGELOG.md 找所有 `## [X.Y.Z]` 段"""
    try:
        text = CHANGELOG.read_text(encoding='utf-8')
    except OSError:
        return []
    versions = []
    for m in re.finditer(r'^##\s+\[([\d.]+\+?\d*)\]', text, re.MULTILINE):
        versions.append(m.group(1))
    return versions


def version_key(v):
    """version 排序 key (支持 X.Y.Z+N 形式)"""
    base = v.split('+')[0]
    parts = [int(p) for p in base.split('.')]
    suffix = int(v.split('+')[1]) if '+' in v else 0
    return tuple(parts) + (suffix,)


def main():
    ci_mode = '--ci' in sys.argv

    pubspec_v = get_pubspec_version()
    changelog_vs = get_changelog_versions()

    errors = []

    # 1. pubspec 跟 CHANGELOG 一致性
    if pubspec_v and changelog_vs:
        # CHANGELOG 第一段应该是 pubspec version
        if changelog_vs[0] != pubspec_v:
            # 但允许 [0.X.0+1] 在 [0.X.0] 之前 (build 号)
            if not changelog_vs[0].startswith(pubspec_v.split('+')[0]):
                errors.append(
                    f"CHANGELOG 第一段 [{changelog_vs[0]}] 跟 pubspec version [{pubspec_v}] 不一致"
                )

    # 2. 段顺序: 必须按 version 倒序
    for i in range(len(changelog_vs) - 1):
        cur = changelog_vs[i]
        nxt = changelog_vs[i + 1]
        if version_key(cur) < version_key(nxt):
            errors.append(
                f"CHANGELOG 段顺序错: [{cur}] (line {i+1}) < [{nxt}] (line {i+2}) — 应按 version 倒序"
            )

    # 3. 报告
    if not errors:
        print(f'[OK] check_changelog: pubspec=[{pubspec_v}] CHANGELOG 顺序正确 ({len(changelog_vs)} 段)')
        return 0

    print(f'[FAIL] check_changelog: {len(errors)} 问题:')
    for err in errors:
        print(f'  {err}')
    print('  修法: 见 docs/review/FINAL_REPORT.md §3.1 [P0-2]')
    return 1


if __name__ == '__main__':
    sys.exit(main())
