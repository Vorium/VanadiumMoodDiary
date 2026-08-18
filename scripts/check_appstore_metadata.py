#!/usr/bin/env python3
# v1.1.0 R117 (综合审视 P0-5 配套): AppStore metadata 守门员
#
# 检查 AppStore Connect metadata:
# - description.txt 5.1.1 (敏感 App 抽审) 声明
# - review_information 4 TODO 占位 (邮箱 / 截图 / 备注 / 版本)
# - notes.txt 版本号跟 pubspec 同步
#
# 用法: python scripts/check_appstore_metadata.py
# Exit 0: 全过 / Exit 1: TODO 占位未替换

import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

PUBSPEC = ROOT / "pubspec.yaml"
REVIEW_INFO = ROOT / "ios" / "review_information.txt"
NOTES = ROOT / "ios" / "notes.txt"
DESCRIPTION = ROOT / "ios" / "description.txt"

TODO_PATTERNS = [
    r"\bTODO\b",
    r"\bFIXME\b",
    r"\bXXX\b",
    r"<[^>]+>",  # placeholder like <email>, <version>
    r"占位",
    r"待填",
    r"placeholder",
]

# R128e+ round 10 emotion-first: 项目定位改为"情绪日记 + 树洞倾诉优先",
# description.txt 必须含 ≥2 个以下关键词,以确保 AppStore 文案契合 emotion-first
EMOTION_KEYWORDS = ["mood", "vent", "journal", "tree hole", "树洞", "情绪"]


def has_todo(text: str) -> bool:
    for pat in TODO_PATTERNS:
        if re.search(pat, text, re.IGNORECASE):
            return True
    return False


def check_emotion_first(description: str, locale: str) -> list[str]:
    """emotion-first keyword check: ≥2 of 6 keywords must appear.

    Keywords: mood / vent / journal / tree hole / 树洞 / 情绪
    中文 locale 用中文关键词,英文 locale 用英文关键词,大小写不敏感。
    """
    errors: list[str] = []
    text_lower = description.lower()
    matches = sum(1 for kw in EMOTION_KEYWORDS if kw.lower() in text_lower)
    if matches < 2:
        errors.append(
            f"  [{locale}] emotion-first: only {matches} keyword(s), expected ≥2 of "
            f"{EMOTION_KEYWORDS}"
        )
    return errors


def main():
    errors = []

    # pubspec version
    if not PUBSPEC.exists():
        errors.append(f"  pubspec.yaml 不存在")
        return 1
    pubspec_text = PUBSPEC.read_text(encoding="utf-8")
    m = re.search(r"^version:\s*([\d.]+\+\d+)", pubspec_text, re.MULTILINE)
    if not m:
        errors.append("  pubspec.yaml 无 version 字段")
        return 1
    pubspec_ver = m.group(1)

    # review_information
    if not REVIEW_INFO.exists():
        errors.append(f"  review_information.txt 缺失: {REVIEW_INFO}")
    else:
        text = REVIEW_INFO.read_text(encoding="utf-8")
        if has_todo(text):
            errors.append(f"  review_information.txt 仍含 TODO / 占位")

    # notes.txt
    if not NOTES.exists():
        errors.append(f"  notes.txt 缺失: {NOTES}")
    else:
        text = NOTES.read_text(encoding="utf-8")
        if pubspec_ver not in text:
            errors.append(
                f"  notes.txt 版本号 ({text.strip()[:50]}) 跟 pubspec ({pubspec_ver}) 不一致"
            )

    # description.txt
    if not DESCRIPTION.exists():
        errors.append(f"  description.txt 缺失: {DESCRIPTION}")
    else:
        text = DESCRIPTION.read_text(encoding="utf-8")
        # 5.1.1 敏感 App 抽审声明应该存在
        if "5.1.1" not in text and "5.1.3" not in text:
            errors.append(
                f"  description.txt 缺 5.1.1 / 5.1.3 敏感 App 抽审声明"
            )
        # R128e+ round 10 emotion-first: description 需含 ≥2 emotion-first 关键词
        errors.extend(check_emotion_first(text, locale="zh-Hans"))

    if errors:
        print(f"[FAIL] AppStore metadata 不合规 ({len(errors)} 项):")
        for e in errors:
            print(e)
        return 1

    print(f"[OK] AppStore metadata: description + review_information + notes 齐全")
    print(f"     pubspec version: {pubspec_ver}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
