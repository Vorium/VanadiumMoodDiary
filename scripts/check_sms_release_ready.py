#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #4 / spzh C-09): check_sms_release_ready 守门员
#
# 作用: 验证 `lib/core/data/services/sms_service.dart` 的 AliyunSmsProvider 真接,
#   且 [isProductionReady] 实现一致 (Mock 返 false / Aliyun/Twilio 返 true)
#
# 背景: spzh v0.25 round 56h P0 报告: AliyunSmsProvider.send() 仍 throw
#   UnimplementedError, release 模式失联通知不可用。
#   v0.26 round 57 真接后, 守门员保证: 未来不能再退回到 throw UnimplementedError。
#
# 规则:
#   1. AliyunSmsProvider.send() 不含 `throw UnimplementedError`  → 报 [FAIL] 如果命中
#   2. MockSmsProvider.isProductionReady == false                  → 否则 [FAIL]
#   3. AliyunSmsProvider.isProductionReady == true                 → 否则 [FAIL]
#
# 范围: lib/core/data/services/sms_service.dart 单文件
# 退出: 0 = pass, 1 = fail
import io
import re
import sys
from pathlib import Path

# Windows GBK console: 强制 utf-8 stdout
if sys.platform == 'win32':
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

ROOT = Path(__file__).resolve().parent.parent
SMS_SERVICE = ROOT / "lib" / "core" / "services" / "data" / "sms_service.dart"
SMS_SERVICE_CANDIDATE = ROOT / "lib" / "core" / "data" / "services" / "sms_service.dart"

# 容错: 兼容 core/data/services/ 和 core/services/data/ 两种目录结构
SMS_SERVICE = SMS_SERVICE_CANDIDATE if SMS_SERVICE_CANDIDATE.exists() else SMS_SERVICE


def extract_class_block(text: str, class_name: str) -> str | None:
    """返回 `class <class_name> { ... }` 完整 body, 简单大括号匹配 (假设 1 层嵌套)"""
    m = re.search(rf'class\s+{class_name}\b[^{{]*\{{', text)
    if not m:
        return None
    start = m.end() - 1  # '{' 位置
    depth = 0
    end = start
    for i in range(start, len(text)):
        if text[i] == '{':
            depth += 1
        elif text[i] == '}':
            depth -= 1
            if depth == 0:
                end = i
                break
    return text[start:end + 1]


def main() -> int:
    if not SMS_SERVICE.exists():
        print(f"[FAIL] 找不到 {SMS_SERVICE}")
        return 1

    try:
        text = SMS_SERVICE.read_text(encoding='utf-8')
    except (UnicodeDecodeError, OSError) as e:
        print(f"[FAIL] 读取失败: {e}")
        return 1

    rel = SMS_SERVICE.relative_to(ROOT).as_posix()
    failures = []

    # 检查 1: AliyunSmsProvider.send() 不含 throw UnimplementedError
    aliyun_block = extract_class_block(text, 'AliyunSmsProvider')
    if aliyun_block is None:
        failures.append('AliyunSmsProvider 类不存在 (R57 应已实现)')
    else:
        # 找 send() 方法 (粗匹配: `send(...) async {` 到下一个 `}`)
        send_match = re.search(
            r'Future<bool>\s+send\([^)]*\)\s*async\s*\{',
            aliyun_block,
        )
        if send_match is None:
            failures.append('AliyunSmsProvider.send() 方法签名异常')
        else:
            start = send_match.end() - 1
            depth = 0
            end = start
            for i in range(start, len(aliyun_block)):
                if aliyun_block[i] == '{':
                    depth += 1
                elif aliyun_block[i] == '}':
                    depth -= 1
                    if depth == 0:
                        end = i
                        break
            send_body = aliyun_block[start:end + 1]
            if 'throw UnimplementedError' in send_body:
                failures.append(
                    'AliyunSmsProvider.send() 仍 throw UnimplementedError (R57 真接, 不应再 throw)'
                )

    # 检查 2: MockSmsProvider.isProductionReady == false
    mock_block = extract_class_block(text, 'MockSmsProvider')
    if mock_block is None:
        failures.append('MockSmsProvider 类不存在')
    else:
        m = re.search(
            r'bool\s+get\s+isProductionReady\s*=>\s*(\w+)',
            mock_block,
        )
        if m is None:
            failures.append('MockSmsProvider.isProductionReady 签名异常')
        elif m.group(1) != 'false':
            failures.append(
                f'MockSmsProvider.isProductionReady 必须是 false, 实际: {m.group(1)}'
            )

    # 检查 3: AliyunSmsProvider.isProductionReady == true
    if aliyun_block is not None:
        m = re.search(
            r'bool\s+get\s+isProductionReady\s*=>\s*(\w+)',
            aliyun_block,
        )
        if m is None:
            failures.append('AliyunSmsProvider.isProductionReady 签名异常')
        elif m.group(1) != 'true':
            failures.append(
                f'AliyunSmsProvider.isProductionReady 必须是 true, 实际: {m.group(1)}'
            )

    if failures:
        print(f"[FAIL] check_sms_release_ready: {len(failures)} 处不合规")
        print(f"  文件: {rel}")
        for f in failures:
            print(f"    - {f}")
        return 1

    print(f"[OK] check_sms_release_ready: AliyunSmsProvider 真接 + isProductionReady 一致 ({rel})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
