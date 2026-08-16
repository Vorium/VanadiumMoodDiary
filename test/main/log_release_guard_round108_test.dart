// v0.30 R108 (P0#12, spen V-01): main.dart developer.log release 模式守卫
//
// 背景 (R107 报告 §9 bottom-up-bugs V-01):
//   lib/main.dart:91,105 直接调 `developer.log('FlutterError', ...)` /
//   `developer.log('FATAL UNCAUGHT', ...)`。`developer.log` 不受 `kReleaseMode`
//   守卫 (只有 `print` 受), release 模式仍把 error/stack 写到 Xcode Console。
//   精神心理患者 stack 含文件路径 / 状态 / medication 名 → PII 风险 (PIPL §38 /
//   Apple Guideline 5.1.1)。
//
// 修法 (R108):
//   1) lib/main.dart FlutterError.onError 回调: `if (!kReleaseMode) developer.log(...)`
//   2) lib/main.dart runZonedGuarded onError: 同款守卫
//   3) release 模式失败 → 走 LastErrorCapture.record (已 R22 round 33 实现)
//
// 锁住: 防御未来 refactor 误删守卫。
// 本测试用文件级 grep 模式 (R95 sub-spec 4 task 17 模式: 文件层 lock-in),
// 不真正运行 main() (R22 已有 onError 集成测试)。

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R108 Fix #8: main.dart developer.log release 守卫', () {
    test('main.dart import 了 flutter/foundation (kReleaseMode 来源)', () {
      // kReleaseMode / kDebugMode 来自 package:flutter/foundation.dart
      // 防御未来有人误删 import 导致守卫静默失效
      final mainDart = File('lib/main.dart');
      expect(mainDart.existsSync(), isTrue);
      final content = mainDart.readAsStringSync();
      expect(
        content.contains("import 'package:flutter/foundation.dart';"),
        isTrue,
        reason: 'main.dart 必须 import flutter/foundation (kReleaseMode 来源)',
      );
    });

    test('main.dart 含 kReleaseMode 守卫 (release 模式不写 console)', () {
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      // FlutterError.onError 守卫: 找 "developer.log(" 之前必须有 !kReleaseMode
      // 模式: `if (!kReleaseMode) { developer.log(...) }` 或 `if (kDebugMode) ...`
      // 简单 grep: 文件里应出现 kReleaseMode 字眼
      expect(
        content.contains('kReleaseMode'),
        isTrue,
        reason: 'main.dart 必须用 kReleaseMode 守卫 developer.log',
      );
    });

    test('FlutterError.onError 回调体内有 kReleaseMode 守卫', () {
      // 找到 FlutterError.onError = (details) { ... }; 段
      // 验证段内出现 `if (!kReleaseMode)` 或 `if (kDebugMode)`
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      final idx = content.indexOf('FlutterError.onError');
      expect(idx, greaterThan(-1));
      // 找下一个 } 段 (回调体, 简化为找 2000 字符范围)
      final body = content.substring(idx, idx + 2000);
      expect(
        body.contains('!kReleaseMode') || body.contains('kDebugMode'),
        isTrue,
        reason: 'FlutterError.onError 回调体应有 kReleaseMode 守卫',
      );
      // 验证回调体内有 developer.log
      expect(
        body.contains('developer.log'),
        isTrue,
        reason: 'FlutterError.onError 回调体应仍调 developer.log (debug 模式)',
      );
    });

    test('runZonedGuarded onError 回调体内有 kReleaseMode 守卫', () {
      // 找 runZonedGuarded<...>(..., (error, stack) { ... })
      // 简化: 找第二处 developer.log 之前 500 字符
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      // 找第二处 developer.log (runZonedGuarded onError)
      final firstIdx = content.indexOf('developer.log');
      expect(firstIdx, greaterThan(-1));
      final secondIdx = content.indexOf('developer.log', firstIdx + 1);
      expect(secondIdx, greaterThan(-1), reason: '应有第二处 developer.log');
      // 第二处之前 600 字符范围, 必有 kReleaseMode / kDebugMode
      final body = content.substring(
        (secondIdx - 600).clamp(0, content.length),
        secondIdx,
      );
      expect(
        body.contains('!kReleaseMode') || body.contains('kDebugMode'),
        isTrue,
        reason: 'runZonedGuarded onError 回调体应有 kReleaseMode 守卫',
      );
    });

    test('release 模式走 LastErrorCapture.record 兜底', () {
      // runZonedGuarded onError 内 release 模式失败应写 LastErrorCapture
      // (R22 round 33 已实现), 防御未来误删
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      expect(
        content.contains('LastErrorCapture.record'),
        isTrue,
        reason: 'runZonedGuarded onError 应仍调 LastErrorCapture.record',
      );
    });

    test('main.dart 顶层 developer.log 调用总次数 = 3 (不再多)', () {
      // 防御未来在守卫外多加裸 developer.log
      // R108 修后应有 3 处:
      //   - line ~98: FlutterError.onError, !kReleaseMode 守卫
      //   - line ~118: runZonedGuarded onError, !kReleaseMode 守卫
      //   - line ~532: markAppDocsExcluded, kDebugMode 守卫 (R108 之前已加)
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      final matches = RegExp(r'developer\.log\s*\(').allMatches(content);
      expect(
        matches.length,
        lessThanOrEqualTo(3),
        reason:
            'main.dart 顶层 developer.log 调用应 ≤ 3 处 (R108 修后), 实际 ${matches.length}',
      );
    });

    test('每处 developer.log 都在 kReleaseMode / kDebugMode 守卫内', () {
      // 防御未来 refactor 误移出守卫
      final mainDart = File('lib/main.dart');
      final content = mainDart.readAsStringSync();
      final matches = RegExp(r'developer\.log\s*\(').allMatches(content);
      expect(matches.length, greaterThan(0));
      for (final match in matches) {
        // 找 developer.log 之前 500 字符, 应有 !kReleaseMode 或 kDebugMode
        final before = content.substring(
          (match.start - 500).clamp(0, match.start),
          match.start,
        );
        // 注释里提到 kReleaseMode / kDebugMode 不算守卫
        // 简单方法: 找最近的 if 语句 (含 !kReleaseMode / kDebugMode)
        // 用行级 grep: match 所在行应含 if 块守卫
        // 简化: 检查 before 里有 `if (!kReleaseMode)` 或 `if (kDebugMode)`
        final hasReleaseGuard = before.contains('!kReleaseMode');
        final hasDebugGuard = before.contains('kDebugMode');
        expect(
          hasReleaseGuard || hasDebugGuard,
          isTrue,
          reason: 'developer.log 在 offset=${match.start} 处, 之前 500 字符内应含 '
              '!kReleaseMode 或 kDebugMode 守卫',
        );
      }
    });
  });
}
