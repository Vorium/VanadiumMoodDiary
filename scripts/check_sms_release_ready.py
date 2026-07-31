#!/usr/bin/env python3
# v0.26 round 57 (owner P1 #4 / spzh C-09): check_sms_release_ready 守门员
# v0.27 round 58 (A-01 修正): 降级为 warn-only (A-01 真接是 xlarge 外部依赖, 短期不阻塞)
# v0.27 round 62 (P0-1 修复): isProductionReady 检查改宽松,
#   接受字面 `true` 或基于字段的表达式 (修复 release 模式假成功问题)。
#   send() 仍 throw UnimplementedError 保留 warn-only (A-01 外部依赖 v1.0 才修)。
#
# 作用: 验证 `lib/core/data/services/sms_service.dart` 的 AliyunSmsProvider 真接,
#   且 [isProductionReady] 实现一致 (Mock 返 false / Aliyun/Twilio 返 true 或基于配置)
#
# 背景: spzh v0.25 round 56h P0 报告: AliyunSmsProvider.send() 仍 throw
#   UnimplementedError, release 模式失联通知不可用。
#   A-01 (R58+) 修正方向: 阿里云 SMS 真接 (依赖法务模板审核 1-2 月 + AccessKey 申请)。
#   v0.27 R58 修正: 守门员从 hard FAIL 降级为 [WARN] exit 0, 不阻塞当前 v0.x release。
#   v1.0 上 store 前必须升回 hard FAIL + 修正 AliyunSmsProvider.send() 真接。
#
# 规则 (R58 warn-only):
#   1. AliyunSmsProvider.send() 不含 `throw UnimplementedError`  → 命中 [WARN]
#   2. MockSmsProvider.isProductionReady == false                  → 否则 [WARN]
#   3. AliyunSmsProvider.isProductionReady == 字面 true OR 基于字段表达式 → 否则 [WARN]
#   退出: 0 = pass (有 [WARN] 也算 pass, 不阻塞 release)
#   v1.0 修正: 把 return 0 改 return 1, 升回 hard fail
#
# 范围: lib/core/data/services/sms_service.dart 单文件
import io
import re
import sys
from pathlib import Path

# Windows GBK console: 强制 utf-8 stdout
if sys.platform == 'win32':
    try:
        sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
        sys.stderr = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')
    except (AttributeError, OSError):
        pass

ROOT = Path(__file__).resolve().parent.parent
SMS_SERVICE = ROOT / "lib" / "core" / "data" / "services" / "sms_service.dart"


def extract_class_block(text: str, class_name: str) -> str | None:
    """返回 `class <class_name> { ... }` 完整 body"""
    m = re.search(rf'class\s+{class_name}\b[^{{]*\{{', text)
    if not m:
        return None
    start = m.end() - 1
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
    warnings = []

    # 检查 1: AliyunSmsProvider.send() 不含 throw UnimplementedError
    aliyun_block = extract_class_block(text, 'AliyunSmsProvider')
    if aliyun_block is None:
        warnings.append('AliyunSmsProvider 类不存在 (R57 应已实现)')
    else:
        send_match = re.search(
            r'Future<bool>\s+send\([^)]*\)\s*async\s*\{',
            aliyun_block,
        )
        if send_match is None:
            warnings.append('AliyunSmsProvider.send() 方法签名异常')
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
                warnings.append(
                    'AliyunSmsProvider.send() 仍 throw UnimplementedError '
                    '(A-01 真接是 xlarge 外部依赖, R58 修正后 warn-only)'
                )

    # 检查 2: MockSmsProvider.isProductionReady == false
    mock_block = extract_class_block(text, 'MockSmsProvider')
    if mock_block is None:
        warnings.append('MockSmsProvider 类不存在')
    else:
        m = re.search(
            r'bool\s+get\s+isProductionReady\s*=>\s*(\w+)',
            mock_block,
        )
        if m is None:
            warnings.append('MockSmsProvider.isProductionReady 签名异常')
        elif m.group(1) != 'false':
            warnings.append(
                f'MockSmsProvider.isProductionReady 必须是 false, 实际: {m.group(1)}'
            )

    # 检查 3: AliyunSmsProvider.isProductionReady == true OR 基于字段表达式
    # v0.27 round 62 (P0-1 修复): 改宽松 — 接受字面 `true` 或基于字段的
    # 表达式 (e.g. `accessKeyId.isNotEmpty && ...`), 因为 R62 修复"假成功"
    # 后 isProductionReady 必须根据真实配置返回, 不再硬编码 true。
    if aliyun_block is not None:
        m = re.search(
            r'bool\s+get\s+isProductionReady\s*=>\s*(.+)',
            aliyun_block,
        )
        if m is None:
            warnings.append('AliyunSmsProvider.isProductionReady 签名异常')
        else:
            body = m.group(1).strip().rstrip(';')
            # 接受 3 种实现:
            # 1. 字面 `true`
            # 2. 基于字段表达式 (含 isNotEmpty / && / || / 字段名)
            # 3. 函数调用 (e.g. `_checkConfig()`)
            is_literal_true = body == 'true'
            is_field_expr = (
                'isNotEmpty' in body
                or '&&' in body
                or '||' in body
                or 'accessKey' in body
                or 'signName' in body
            )
            is_func_call = '(' in body and ')' in body and not is_field_expr
            if not (is_literal_true or is_field_expr or is_func_call):
                warnings.append(
                    f'AliyunSmsProvider.isProductionReady 实现不规范: {body[:80]} '
                    '(期望字面 true / 基于字段表达式 / 函数调用)'
                )

    if warnings:
        # R58 修正: warn-only, 不阻塞 release
        print(f"[WARN] check_sms_release_ready: {len(warnings)} 处 A-01 修正方向 (warn-only, v1.0 升 hard fail)")
        print(f"  文件: {rel}")
        for w in warnings:
            print(f"    - {w}")
        print(f"  说明: A-01 修正依赖法务模板审核 + 阿里云 AccessKey 申请 (80-120h), v0.x 不阻塞")
        return 0  # R58 修正: warn-only 修正方向, exit 0

    print(f"[OK] check_sms_release_ready: AliyunSmsProvider 真接 + isProductionReady 一致 ({rel})")
    return 0


if __name__ == '__main__':
    sys.exit(main())
