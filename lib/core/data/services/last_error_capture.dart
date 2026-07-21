// v0.22 round 33 (sp-en P0): 启动 / 启动后未捕获 error 捕获器
//
// 修 main.dart runZonedGuarded release 模式直接 swallow 的 P0 风险:
// release 模式之前把 error 静默丢弃, 用户看不到任何"哪里出错了"信号。
//
// 修法: error 信息存 SharedPreferences (轻量, 不进 DB 避免污染业务数据),
// 下次启动 AppRoot 检查 + 顶部 banner 提示用户截图反馈。
//
// 存什么:
// - error: 异常类名 + 简短信息 (200 字符内, 防止 OOM)
// - stack: stack trace 前 5 行 (避免 SharedPreferences 体积爆炸)
// - ts: 发生时间
// 读后自动清除, 避免下次启动重复显示。
import 'package:shared_preferences/shared_preferences.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';

/// 启动 / 启动后未捕获 error 捕获器
class LastErrorCapture {
  LastErrorCapture._();

  static const _key = 'last_startup_error';
  static const _maxErrorLen = 200;
  static const _maxStackLines = 5;

  /// 记录一次未捕获 error
  static Future<void> record(Object error, StackTrace stack) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stackLines = stack.toString().split('\n');
      final truncatedStack = stackLines.take(_maxStackLines).join('\n');
      final errorStr = error.toString();
      final truncatedError =
          errorStr.length > _maxErrorLen
              ? '${errorStr.substring(0, _maxErrorLen)}…'
              : errorStr;
      final payload = '${DateTime.now().toIso8601String()}\n'
          'ERROR: $truncatedError\n'
          'STACK:\n$truncatedStack';
      await prefs.setString(_key, payload);
    } catch (e, st) {
      // 不能 swallow 失败 (会掩盖真实问题)
      piiSafeLog(
        'LastErrorCapture.record',
        '⚠️ failed to persist error: $e',
        error: e,
        stackTrace: st,
      );
    }
  }

  /// 读取上次启动的 error, 读取后自动清除
  ///
  /// 返回 null 表示上次启动 OK 或本次读取失败 (best-effort)。
  static Future<LastError?> consume() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return null;
      // 清除 (避免下次启动重复显示)
      await prefs.remove(_key);
      return _parse(raw);
    } catch (e, st) {
      piiSafeLog(
        'LastErrorCapture.consume',
        '⚠️ failed to read error: $e',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  static LastError? _parse(String raw) {
    final lines = raw.split('\n');
    if (lines.length < 3) return null;
    final ts = DateTime.tryParse(lines[0]);
    if (ts == null) return null;
    // 找 STACK: 后的内容
    final stackIdx = lines.indexWhere((l) => l.trim() == 'STACK:');
    final error = lines.length > 1 && lines[1].startsWith('ERROR:')
        ? lines[1].substring('ERROR:'.length).trim()
        : lines[1];
    final stack = stackIdx >= 0 ? lines.sublist(stackIdx + 1).join('\n') : '';
    return LastError(timestamp: ts, error: error, stack: stack);
  }
}

/// 上次启动的 error 摘要
class LastError {
  final DateTime timestamp;
  final String error;
  final String stack;

  const LastError({
    required this.timestamp,
    required this.error,
    required this.stack,
  });
}
