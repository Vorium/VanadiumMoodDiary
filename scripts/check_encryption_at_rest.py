#!/usr/bin/env python3
"""
v1.1.0 round 11 (R115 隐私加固): 落盘加密守门员

作用: 验证 lib/**/*.dart 写入 app docs 目录的文件**必须**走加密, 防止
明文 PII (精神心理数据) 落盘被备份 / 设备 root 偷取。

零外联隐私合规 (PIPL §28 / HIPAA field-level encryption): DB 走
SQLCipher (database), audio 走 .m4a.enc (encrypted_audio_storage),
swallow log 走加密。其他明文文件 (config, pref, .json, .txt) 不应
落 app docs。

执行:
  python3 scripts/check_encryption_at_rest.py
  python3 scripts/check_encryption_at_rest.py --ci

依据 (R115 docs/privacy-hardening):
- 加密白名单: database (SQLCipher) / .m4a.enc (EncryptionService) /
  .m4a.enc.m4a (intermediate) / swallow.log (加密 audit log)
- 严禁: .txt / .json / .csv / .log / .pref / 任意明文后缀写 app docs
"""
import argparse
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
LIB_DIR = REPO_ROOT / "lib"

# 检测到在 app docs / cache / temp 目录写文件, 必须加密
APP_DIRS = [
    "getApplicationDocumentsDirectory",
    "getApplicationSupportDirectory",
    "getTemporaryDirectory",
    "getApplicationCacheDirectory",
    "getExternalStorageDirectory",
    "getDownloadsDirectory",
]

# 允许的写文件模式 (白名单, 全部加密)
ALLOWED_WRITE_PATTERNS = [
    # SQLCipher DB — 由 drift 管理, 内部 AES-256
    (r"AppDatabase\(", "SQLCipher DB (drift 内部加密)"),
    # Encrypted audio 走 .m4a.enc 后缀
    (r"\.m4a\.enc", "EncryptedFileStorage AES-256"),
    # Audit log 走 swallow.log (内部加密)
    (r"swallow\.log", "Audit log (encryption 加密)"),
    # Key file 走 flutter_secure_storage (Keychain/Keystore)
    (r"flutter_secure_storage", "Keychain/Keystore (系统级加密)"),
]

# 禁止的明文写文件模式
FORBIDDEN_WRITE_PATTERNS = [
    (r"\.writeAsStringSync\([^)]*(?!encrypt)", "明文 writeAsStringSync (未走加密)"),
    (r"\.writeAsBytesSync\([^)]*(?!encrypt)", "明文 writeAsBytesSync (未走加密)"),
    (r"\.writeAsString\([^)]*(?!encrypt)", "明文 writeAsString async"),
    (r"\.writeAsBytes\([^)]*(?!encrypt)", "明文 writeAsBytes async"),
]

# 禁止的明文后缀
FORBIDDEN_SUFFIXES = [
    ".json", ".txt", ".csv", ".log", ".pref", ".xml", ".yaml", ".yml",
]

# 例外: 测试 fixture / debug 标记 / 注释
EXCEPTION_CONTEXTS = [
    "// ", "/* ", "/// ", "* ",
    "test/fixtures",  # 测试 fixture 路径
    "test/",  # 测试文件
    "debugPrint",  # debug 日志 (不落盘)
    "print(",  # 控制台输出
]


def is_in_app_dir_context(line: str) -> bool:
    """检查这一行是否在 app docs 目录上下文 (有 getApplicationDocuments 等)"""
    return any(d in line for d in APP_DIRS)


def is_exception_context(line: str) -> bool:
    return any(exc in line for exc in EXCEPTION_CONTEXTS)


def is_allowed_pattern(line: str) -> bool:
    return any(re.search(p, line) for p, _ in ALLOWED_WRITE_PATTERNS)


def collect_violations() -> list[str]:
    violations: list[str] = []
    for dart_file in LIB_DIR.rglob("*.dart"):
        if "/.dart_tool/" in str(dart_file):
            continue
        rel_path = dart_file.relative_to(REPO_ROOT)
        text = dart_file.read_text(encoding="utf-8")
        for line_no, line in enumerate(text.splitlines(), 1):
            if is_exception_context(line):
                continue
            if not is_in_app_dir_context(line):
                continue
            if is_allowed_pattern(line):
                continue
            # 检查 forbidden write pattern
            for pattern, desc in FORBIDDEN_WRITE_PATTERNS:
                if re.search(pattern, line):
                    violations.append(
                        f"{rel_path}:{line_no}  {desc}\n"
                        f"      上下文: {line.strip()[:120]}"
                    )
            # 检查 forbidden suffix
            for suffix in FORBIDDEN_SUFFIXES:
                # 找含 suffix 的字符串字面量
                if re.search(rf"['\"][^'\"]*{re.escape(suffix)}['\"]", line):
                    if "join(" not in line and "path." not in line:
                        violations.append(
                            f"{rel_path}:{line_no}  app docs 写 {suffix} 明文文件"
                        )
    return violations


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n", 1)[0])
    parser.add_argument("--ci", action="store_true", help="CI mode: exit 1 on fail")
    args = parser.parse_args()

    print("=" * 60)
    print("v1.1.0 round 11 (R115) 落盘加密守门员")
    print("=" * 60)
    print(f"扫描: {LIB_DIR.relative_to(REPO_ROOT)}")
    print(f"加密白名单: SQLCipher / .m4a.enc / swallow.log / Keychain")
    print()

    violations = collect_violations()
    if violations:
        print(f"❌ 发现 {len(violations)} 处违规:")
        for v in violations:
            print(f"  - {v}")
        print()
        print("修复指引:")
        print("  1. app docs 写文件**必须**走 EncryptionService 或 EncryptedFileStorage")
        print("  2. .json/.txt/.csv/.log 等明文后缀不允许, 改用加密 .m4a.enc")
        print("  3. 配置走 SharedPreferences (系统加密) 或 Keychain")
        return 1

    print("✅ 0 violation — app docs 落盘全部加密")
    return 0


if __name__ == "__main__":
    sys.exit(main())
