// v0.18 round 18 (P2-P0-1) PII 安全日志
//
// 背景: 精神心理患者 App,所有日志都是 PII (姓名/电话/用药/失联状态/SMS 全文)。
// 之前 developer.log 散在 10+ 处,release 模式仍输出 logcat。
// `developer.log` 不受 `kDebugMode` 守卫,只 `print` 受。
//
// PIPL / GDPR / HIPAA 合规要求:生产构建下不打印 PII 到任何输出。
//
// 修法:
// 1. 抽 piiSafeLog helper: release 模式 swallow,debug 模式才走 developer.log
// 2. 加 maskPhone helper:138****5678 形式
// 3. 全项目替换 developer.log(敏感 PII) → piiSafeLog + maskPhone
// 4. 1 个 unit test 验证 release 模式不打印
//
// 注意:不是所有 developer.log 都是 PII。技术性 log(如"✅ 调度成功")
// 可以保持原样(无 PII)。本 helper 用于"含 PII 的 log"。
//
// P1 fix: 从 core/shared/ 移入 core/data/services/（仅 data 层使用，不满足 shared 2+ 层规则）

import 'dart:developer' as developer;

/// PII 安全日志 - release 模式自动 swallow
///
/// 用法:
/// ```dart
/// // 之前:
/// developer.log('用户: ${profile.userName}', name: 'ReminderService');
///
/// // 之后:
/// piiSafeLog('ReminderService', '用户: ${profile.userName}');
/// ```
///
/// 或配合 maskPhone:
/// ```dart
/// piiSafeLog('SmsService', 'To: ${maskPhone(to)}');
/// ```
///
/// error / stackTrace 透传给 developer.log(用于 debug 模式排查)
/// release 模式不打印,所以 error/stackTrace 也被 swallow
///
/// 注意: 使用 `bool.fromEnvironment('dart.vm.product')` 替代 `kReleaseMode`
/// 以避免在 shared 层引入 Flutter 依赖。

// release 模式下为 true，debug/profile 为 false
const bool _isProduct =
    bool.fromEnvironment('dart.vm.product', defaultValue: false);

void piiSafeLog(
  String tag,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  // release 模式 swallow — 避免 PII 进入 logcat
  if (_isProduct) return;
  developer.log(
    message,
    name: tag,
    error: error,
    stackTrace: stackTrace,
  );
}

/// 掩码手机号中间 4 位
///
/// 13800138000 → 138****8000
/// +8613800138000 → +86 138****8000 (保留国家码 +86,只掩码本体)
/// 长度 < 7 的输入直接返回(过短没有"中间"概念)
String maskPhone(String phone) {
  if (phone.length < 7) return phone;
  final hasPlus = phone.startsWith('+');
  final digits = phone.replaceAll(RegExp(r'[^\d]'), '');
  if (digits.length < 7) return phone;
  if (digits.length >= 11) {
    if (digits.length == 11) {
      final prefix = digits.substring(0, 3);
      final suffix = digits.substring(7);
      return '$prefix****$suffix';
    } else if (digits.length == 13) {
      final country = digits.substring(0, 2);
      final prefix = digits.substring(2, 5);
      final suffix = digits.substring(9);
      return '+$country $prefix****$suffix';
    } else if (digits.length == 12) {
      final country = digits.substring(0, 1);
      final prefix = digits.substring(1, 4);
      final suffix = digits.substring(8);
      return '+$country $prefix****$suffix';
    }
    final prefix = digits.substring(0, 3);
    final suffix = digits.substring(digits.length - 4);
    return hasPlus ? '+$prefix****$suffix' : '$prefix****$suffix';
  }
  final prefix = digits.substring(0, 3);
  final suffix = digits.substring(digits.length - 4);
  return hasPlus ? '+$prefix****$suffix' : '$prefix****$suffix';
}

/// 掩码姓名 — 保留第 1 字,后续用 *
///
/// 张三 → 张*
/// 张三丰 → 张**
/// John → J***
/// John Smith → J*** S****
String maskName(String name) {
  if (name.isEmpty) return '';
  if (RegExp(r'^[\u4e00-\u9fff]').hasMatch(name)) {
    if (name.length == 1) return name;
    return name[0] + ('*' * (name.length - 1));
  }
  return name
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return '';
        return word[0] + ('*' * (word.length - 1));
      })
      .join(' ');
}
