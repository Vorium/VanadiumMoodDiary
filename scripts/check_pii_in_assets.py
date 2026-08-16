#!/usr/bin/env python3
"""
v1.1.0 round 11 (R115 隐私加固): assets/ PII 扫描

作用: 验证 assets/ 目录下没有真实 PII (电话号码 / 邮箱 / 身份证 / IP),
防止 demo 数据意外混进 release 包。

零外联隐私合规 (PIPL §28): 即使是 demo / fixture, 也不应包含真实
可识别用户信息。

执行:
  python3 scripts/check_pii_in_assets.py
  python3 scripts/check_pii_in_assets.py --ci

范围 (R115):
  - 扫描: assets/ (二进制图标 / 着色器 / 文案等)
  - 不扫: test/ (test 里的 PII 100% 是 fake fixture, 测 PII 脱敏用,
    已经有白名单豁免 + 多种 placeholder 模式)
  - 行级豁免: `// @pii-ok` 标记行 (用于 demo 用例的明确标注)
"""
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

ASSETS_DIR = REPO_ROOT / "assets"

# PII 检测正则
PII_PATTERNS = [
    # 中国大陆手机号
    (r"\b1[3-9]\d{9}\b", "中国大陆手机号"),
    # 18 位身份证号
    (r"\b\d{17}[\dXx]\b", "身份证号"),
    # 邮箱 (基础, 不区分真伪)
    (r"\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}\b", "邮箱地址"),
    # IPv4 (内网/公网), 真实 IP 不应在 demo
    (r"\b(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(?:\.(?:25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}\b", "IPv4 地址"),
]

# 假数据豁免 (明显是 fake / 占位)
PLACEHOLDER_PATTERNS = [
    r"example\.com",
    r"@example",
    r"127\.0\.0\.1",  # localhost
    r"0\.0\.0\.0",  # 任意地址
    r"192\.168\.",  # 私网段 (测试用)
    r"10\.0\.",  # 私网段
    r"172\.16\.",  # 私网段
    r"test\.com",
    r"placeholder",
    r"fake",
    r"xxx",
    r"000",
    r"test_user",
    r"testuser",
]

# 文件白名单 (已知合规)
ALLOWED_FILES = [
    "assets/icons/",  # 纯图标
    "assets/shaders/",  # 着色器
    "assets/legal/",  # 法务文档, 引用的号码是公开热线
]

# 行级豁免标记: `// @pii-ok` (在该行加注释可豁免)
PII_OK_MARKER = "@pii-ok"


def is_placeholder(text: str) -> bool:
    return any(re.search(p, text, re.IGNORECASE) for p in PLACEHOLDER_PATTERNS)


def collect_violations() -> list[str]:
    violations: list[str] = []
    if not ASSETS_DIR.exists():
        return violations
    for f in ASSETS_DIR.rglob("*"):
        if not f.is_file():
            continue
        if f.suffix not in {".dart", ".json", ".yaml", ".md", ".txt", ".arb"}:
            continue
        rel_path = f.relative_to(REPO_ROOT)
        if any(str(rel_path).startswith(a) for a in ALLOWED_FILES):
            continue
        try:
            text = f.read_text(encoding="utf-8", errors="ignore")
        except Exception:
            continue
        for line_no, line in enumerate(text.splitlines(), 1):
            if is_placeholder(line):
                continue
            # 注释行豁免
            if line.strip().startswith(("#", "//", "/*", "*", "///")):
                continue
            # 行级豁免标记
            if PII_OK_MARKER in line:
                continue
            for pattern, desc in PII_PATTERNS:
                for m in re.finditer(pattern, line):
                    matched = m.group(0)
                    if is_placeholder(matched):
                        continue
                    violations.append(
                        f"{rel_path}:{line_no}  检测到 {desc}: {matched[:30]}"
                        f"{'...' if len(matched) > 30 else ''}"
                    )
    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--ci", action="store_true", help="CI mode: exit 1 on fail")
    args = parser.parse_args()

    print("=" * 60)
    print("v1.1.0 round 11 (R115) assets/ PII 扫描")
    print("=" * 60)
    print(f"扫描: {ASSETS_DIR.relative_to(REPO_ROOT)}")
    print(f"模式: {len(PII_PATTERNS)} PII 类型")
    print(f"行级豁免: `// {PII_OK_MARKER}` 标记该行 (用于 demo fixture)")
    print()

    violations = collect_violations()
    if violations:
        print(f"❌ 发现 {len(violations)} 处 PII:")
        for v in violations:
            print(f"  - {v}")
        print()
        print("修复指引:")
        print("  1. 删除真实 PII, 改用 example.com / 000 / placeholder")
        print("  2. demo 数据用假号: 13800138000 / test@test.com")
        print(f"  3. 真实 PII 测试场景加 `// {PII_OK_MARKER}` 行级豁免")
        return 1

    print("✅ 0 PII found — assets/ 合规")
    return 0


if __name__ == "__main__":
    sys.exit(main())
