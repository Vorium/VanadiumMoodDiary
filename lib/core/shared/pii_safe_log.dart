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

import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

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
void piiSafeLog(
  String tag,
  String message, {
  Object? error,
  StackTrace? stackTrace,
}) {
  // release 模式 swallow — 避免 PII 进入 logcat
  if (kReleaseMode) return;
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
  // 检测是否有国家码(开头 1-3 位数字 + 后续明显是本体)
  // 简化:如果 digits 长度 >= 11 视作"有国家码",前 1-3 位是国家码
  // 大陆 11 位 + 86 = 13 位,前 2 位是国家码
  // HK 8 位 + 852 = 11 位,前 3 位是国家码
  // 实际:按 digits 长度推断 — 11 位 = 86 + 11,13 位 = + 1 + 12 位手机号(国际)
  // 简化:11 位 = 大陆无 prefix,12 位 = + 大陆,13 位 = 86 + 大陆,...
  if (digits.length >= 11) {
    // 检测大陆 11 位(无 prefix)/ 12-13 位(有 prefix)
    // 简化:13 位 = 86 (2 位 country code) + 11 位
    //      12 位 = 1 位 country code + 11 位
    //      11 位 = 11 位本体
    if (digits.length == 11) {
      // 大陆 11 位,prefix = 138
      final prefix = digits.substring(0, 3);
      final suffix = digits.substring(7);
      return '$prefix****$suffix';
    } else if (digits.length == 13) {
      // 86 + 11 位,prefix = 86 138
      final country = digits.substring(0, 2);
      final prefix = digits.substring(2, 5);
      final suffix = digits.substring(9);
      return '+$country $prefix****$suffix';
    } else if (digits.length == 12) {
      // 1 位 country code + 11 位
      final country = digits.substring(0, 1);
      final prefix = digits.substring(1, 4);
      final suffix = digits.substring(8);
      return '+$country $prefix****$suffix';
    }
    // 兜底
    final prefix = digits.substring(0, 3);
    final suffix = digits.substring(digits.length - 4);
    return hasPlus ? '+$prefix****$suffix' : '$prefix****$suffix';
  }
  // 短号(8/9 位港澳台)prefix 取前 3,suffix 取后 4
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
  // 中文:保留第 1 字,后续每字 1 个 *
  if (RegExp(r'^[\u4e00-\u9fff]').hasMatch(name)) {
    if (name.length == 1) return name;
    return name[0] + ('*' * (name.length - 1));
  }
  // 英文/其他:按 space 分词,每词保留首字母 + 后续每字符 1 个 *
  return name
      .split(RegExp(r'\s+'))
      .map((word) {
        if (word.isEmpty) return '';
        return word[0] + ('*' * (word.length - 1));
      })
      .join(' ');
}
