#!/usr/bin/env python3
"""
v1.1.0 round 11 (R115 隐私加固): release 产物域名扫描

作用: 验证 lib/ + 平台 manifest 不引用任何外联域名 (http:// / https://),
锁住零云端架构, 防止未来 commit 偷偷引入 SaaS / 远程接口。

零外联产品定位 (1.1.0 round 4b emotion-first refactor 续作): 精神心理
数据走 SQLCipher 本地, 不应有任何外联请求 (除系统级 tel: / mailto:
一键拨打 + 发邮件)。

执行:
  python3 scripts/check_release_no_network.py
  python3 scripts/check_release_no_network.py --ci

扫描范围:
  - lib/**/*.dart: 任何 http:// 或 https:// 字符串 (非注释)
  - android/app/src/main/res/xml/network_security_config.xml: cleartext 禁止
  - ios/Runner/Info.plist: 不应出现外联 URL
"""
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

LIB_DIR = REPO_ROOT / "lib"
NETWORK_SECURITY_CONFIG = REPO_ROOT / "android/app/src/main/res/xml/network_security_config.xml"
IOS_PLIST = REPO_ROOT / "ios/Runner/Info.plist"

# 系统白名单 URL (走 url_launcher, 不需要 INTERNET 出口)
SYSTEM_URL_WHITELIST = [
    r"https?://schemas\.android\.com/",  # Android schema
    r"https?://www\.apple\.com/",  # iOS schema / privacy
    r"https?://play\.google\.com/",  # Google Play 商店
    r"https?://apps\.apple\.com/",  # App Store
    r"https?://itunes\.apple\.com/",  # iTunes 链接
    r"https?://example\.com/",  # 示例代码
    r"https?://docs\.flutter\.dev/",  # Flutter 文档
    r"https?://pub\.dev/",  # pub.dev 包管理
    r"https?://github\.com/",  # GitHub 链接 (issue tracker 等)
]

# URL 匹配模式
URL_PATTERNS = [
    (r'"https?://[^"\s]+', "https URL 字符串"),
    (r"'https?://[^'\s]+", "https URL 字符串"),
    (r"Uri\.https\(['\"][^'\"]+['\"]", "Uri.https 远程"),
]

# 注释行豁免
COMMENT_PATTERN = re.compile(r"^\s*(//|/\*|\*|#|///)")


def is_whitelisted_url(url: str) -> bool:
    return any(re.search(p, url, re.IGNORECASE) for p in SYSTEM_URL_WHITELIST)


def check_lib() -> list[str]:
    """扫描 lib/ 找外联 URL 字符串"""
    violations: list[str] = []
    for dart_file in LIB_DIR.rglob("*.dart"):
        if "/.dart_tool/" in str(dart_file):
            continue
        rel_path = dart_file.relative_to(REPO_ROOT)
        text = dart_file.read_text(encoding="utf-8")
        for line_no, line in enumerate(text.splitlines(), 1):
            if COMMENT_PATTERN.match(line):
                continue
            for pattern, desc in URL_PATTERNS:
                for m in re.finditer(pattern, line):
                    url = m.group(0).strip("\"'")
                    if is_whitelisted_url(url):
                        continue
                    violations.append(
                        f"{rel_path}:{line_no}  {desc}: {url[:60]}"
                        f"{'...' if len(url) > 60 else ''}"
                    )
    return violations


def check_network_security_config() -> list[str]:
    """检查 network_security_config.xml — cleartext 应禁用"""
    if not NETWORK_SECURITY_CONFIG.exists():
        return []
    violations: list[str] = []
    text = NETWORK_SECURITY_CONFIG.read_text(encoding="utf-8")
    # cleartext-traffic 允许就是 violation
    if re.search(r'cleartextTrafficPermitted="true"', text):
        violations.append(
            f"{NETWORK_SECURITY_CONFIG.relative_to(REPO_ROOT)}  "
            f"cleartextTrafficPermitted=true — 零外联架构应禁用明文 HTTP"
        )
    if re.search(r'<domain[^>]*cleartextTrafficPermitted="true"', text):
        violations.append(
            f"{NETWORK_SECURITY_CONFIG.relative_to(REPO_ROOT)}  "
            f"特定域名允许明文 — 零外联架构应全禁明文"
        )
    return violations


def check_ios_plist() -> list[str]:
    """检查 iOS Info.plist 不含外联 URL"""
    if not IOS_PLIST.exists():
        return []
    violations: list[str] = []
    text = IOS_PLIST.read_text(encoding="utf-8")
    for m in re.finditer(r"https?://[^\s<]+", text):
        url = m.group(0)
        if is_whitelisted_url(url):
            continue
        violations.append(
            f"{IOS_PLIST.relative_to(REPO_ROOT)}  外联 URL: {url[:60]}"
        )
    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--ci", action="store_true", help="CI mode: exit 1 on fail")
    args = parser.parse_args()

    print("=" * 60)
    print("v1.1.0 round 11 (R115) release 域名扫描")
    print("=" * 60)
    print(f"扫描: lib/ + network_security_config + iOS Info.plist")
    print()

    violations: list[str] = []
    violations.extend(check_lib())
    violations.extend(check_network_security_config())
    violations.extend(check_ios_plist())

    if violations:
        print(f"❌ 发现 {len(violations)} 处违规:")
        for v in violations:
            print(f"  - {v}")
        print()
        print("修复指引:")
        print("  1. 删除外联 URL, 改用本地处理")
        print("  2. 如必须用远程服务, 先讨论 + 更新白名单 + 同步 AGENTS.md")
        print("  3. system URL (schemas.android.com / apple.com / GitHub) 自动豁免")
        return 1

    print("✅ 0 violation — 零外联架构保持")
    return 0


if __name__ == "__main__":
    sys.exit(main())
