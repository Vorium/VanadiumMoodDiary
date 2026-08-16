#!/usr/bin/env python3
"""
v1.1.0 round 11 (R115 隐私加固): lib/ 网络外联守门员

作用: 验证 lib/**/*.dart 没有任何网络外联调用, 锁住零云端架构。

零外联产品定位 (1.1.0 round 4b emotion-first refactor 续作): 所有数据
走 SQLCipher 本地加密, 不应引入 HTTP / WebSocket / Socket / Firebase / Sentry
等任何云端依赖。

执行:
  python3 scripts/check_no_network_io.py
  python3 scripts/check_no_network_io.py --ci

白名单 (允许):
  - url_launcher: 仅 tel: / mailto: 协议 (一键拨打 + 发邮件, 本地系统调用)
  - dart:io: 仅本地文件操作 (File, Directory, Platform)
  - 注释中的 http:// 字符串 (文档/示例代码, 非实际调用)
"""
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LIB_DIR = REPO_ROOT / "lib"

# 禁止 import 的网络相关 package
FORBIDDEN_PACKAGES = [
    "package:http/",  # http client
    "package:dio/",  # dio client
    "package:web_socket_channel/",  # WebSocket
    "package:firebase_",  # 任意 firebase (analytics, crashlytics, etc.)
    "package:sentry_",  # Sentry
    "package:cloud_firestore",  # Firestore
    "package:googleapis/",  # Google APIs
    "package:aws_",  # AWS
    "package:azure_",  # Azure
    "package:crypto_",  # Coinbase / crypto
]

# 禁止的 dart:io 网络调用 (排除 localhost / file scheme)
FORBIDDEN_DART_IO_NET = [
    (r"HttpClient\(\)", "HttpClient 创建"),
    (r"WebSocket\.connect\(", "WebSocket.connect"),
    (r"HttpServer\.bind\(", "HttpServer.bind (启动 server)"),
    (r"ServerSocket\.bind\(", "ServerSocket.bind"),
    (r"Socket\.connect\([^)]*(?!localhost|127\.0\.0\.1)", "Socket.connect 远程地址"),
]

# url_launcher 白名单 scheme (tel / mailto / sms — 走系统调用, 不需要 INTERNET)
URL_LAUNCHER_ALLOWED = {"tel:", "mailto:", "sms:"}

# 注释豁免正则 (文档/示例代码中出现 http 字符串不算)
COMMENT_LINE_PATTERN = re.compile(
    r"^\s*(//|/\*|\*|#|///)"
)


def collect_violations() -> list[str]:
    violations: list[str] = []
    for dart_file in LIB_DIR.rglob("*.dart"):
        if "/.dart_tool/" in str(dart_file):
            continue
        rel_path = dart_file.relative_to(REPO_ROOT)
        text = dart_file.read_text(encoding="utf-8")
        for line_no, line in enumerate(text.splitlines(), 1):
            # 注释行豁免
            if COMMENT_LINE_PATTERN.match(line):
                continue
            # 检查 forbidden package import
            for pkg in FORBIDDEN_PACKAGES:
                if f"import '{pkg}" in line or f"import \"{pkg}" in line:
                    violations.append(
                        f"{rel_path}:{line_no}  import 禁止的网络依赖 {pkg}"
                    )
            # 检查 dart:io 网络调用
            for pattern, desc in FORBIDDEN_DART_IO_NET:
                if re.search(pattern, line):
                    violations.append(
                        f"{rel_path}:{line_no}  {desc} — 零云端架构禁止"
                    )
            # 检查 url_launcher 调用的 scheme
            # 匹配 Uri.parse('...') / launchUrl(Uri.parse('...'))
            for m in re.finditer(r"Uri\.parse\(['\"]([^'\"]+)['\"]\)", line):
                scheme = m.group(1)
                if not scheme.startswith(("tel:", "mailto:", "sms:", "https://example", "https://docs.")):
                    # 系统白名单 scheme + 文档示例
                    if any(scheme.startswith(s) for s in URL_LAUNCHER_ALLOWED):
                        continue
                    # 路由路径 /push('/foo') 不是 scheme, 跳过
                    if scheme.startswith("/"):
                        continue
                    # 内部路由 push('/crisis-hotline') 等, 不算
                    violations.append(
                        f"{rel_path}:{line_no}  Uri.parse('{scheme}') "
                        f"— url_launcher 限定 tel:/mailto:/sms: 或路由路径"
                    )
    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--ci", action="store_true", help="CI mode: exit 1 on fail")
    args = parser.parse_args()

    print("=" * 60)
    print("v1.1.0 round 11 (R115) lib/ 网络外联守门员")
    print("=" * 60)
    print(f"扫描: {LIB_DIR.relative_to(REPO_ROOT)}")
    print(f"禁止 import: {len(FORBIDDEN_PACKAGES)} packages")
    print()

    violations = collect_violations()
    if violations:
        print(f"❌ 发现 {len(violations)} 处违规:")
        for v in violations:
            print(f"  - {v}")
        print()
        print("修复指引:")
        print("  1. 不引入 HTTP / WebSocket / Firebase / Sentry 等云端依赖")
        print("  2. url_launcher 仅用 tel: / mailto: / sms: (走系统调用)")
        print("  3. 如需新功能, 走本地 on-device 处理")
        return 1

    print("✅ 0 violation — lib/ 零网络外联")
    return 0


if __name__ == "__main__":
    sys.exit(main())
