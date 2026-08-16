#!/usr/bin/env python3
# v1.1.0 R117 (综合审视 P0-4): chroniccare.app 域名 + 4 邮箱 ICP 守门员
#
# 上架失联通道 (1.1.0 round 4b 删除 SMS/Email 业务后, 仅留法务通道):
# - 域名: chroniccare.app (主), 需 ICP 备案
# - 4 邮箱: privacy@ / legal@ / support@ / abuse@
#
# 用法: python scripts/check_domain_icp.py
# Exit 0: 全过 / Exit 1: 缺域名或邮箱

import re
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

# 域名 / 邮箱 出现位置 (法务文档 + 隐私政策 + README)
TARGETS = [
    ROOT / "assets" / "legal" / "privacy_policy.md",
    ROOT / "assets" / "legal" / "user_agreement.md",
    ROOT / "assets" / "legal" / "sensitive_data_consent.md",
    ROOT / "README.md",
    ROOT / "docs" / "PRIVACY_HARDENING.md",
]

REQUIRED_DOMAIN = "chroniccare.app"
REQUIRED_EMAILS = [
    "privacy@chroniccare.app",
    "legal@chroniccare.app",
    "support@chroniccare.app",
    "abuse@chroniccare.app",
]


def main():
    if not TARGETS[0].exists():
        print(f"[FAIL] 法务文档目录不存在: {TARGETS[0].parent}")
        return 1

    errors = []
    domain_seen = False
    email_seen = set()

    for f in TARGETS:
        if not f.exists():
            continue
        text = f.read_text(encoding="utf-8", errors="ignore")
        if REQUIRED_DOMAIN in text:
            domain_seen = True
        for email in REQUIRED_EMAILS:
            if re.search(re.escape(email), text):
                email_seen.add(email)

    if not domain_seen:
        errors.append(f"  域名 {REQUIRED_DOMAIN} 未在任何法务/隐私文档中出现")

    missing_emails = [e for e in REQUIRED_EMAILS if e not in email_seen]
    if missing_emails:
        errors.append(
            f"  邮箱缺失 ({len(missing_emails)}/4): {', '.join(missing_emails)}"
        )

    if errors:
        print(f"[FAIL] 域名 / 邮箱通道缺失 ({len(errors)} 项):")
        for e in errors:
            print(e)
        print()
        print("R117 综合审视 P0-4 阻塞: 等 chroniccare.app 域名 ICP 备案 (7-20d)")
        return 1

    print(f"[OK] 域名 + 4 邮箱通道齐全 ({REQUIRED_DOMAIN} + 4 mailboxes)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
