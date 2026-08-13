// v0.32 R112 (AR-23): swallowError 全局 sink 分簇 — error_sinks 单元测试
//
// AR-23 背景: swallowError 在 lib/ 有 77+ 处调用点跨 40 文件, 分 3 个
// 功能簇 (audio / notification-safety / export) 各留 1 个带 scope 的
// wrapper, 以后加 Sentry/Firebase 只改 error_sinks.dart 3 处。
//
// 行为约束 (AR-23 spec):
// 1. wrapper 行为 100% 不变 — 内部仍调 swallowError, 只是 where 加
//    scope 前缀 (audio. / notification. / export.)
// 2. wrapper 签名与 swallowError 一致 (where / error / stack / note)
// 3. 不抛 — 失败路径不向上传播 (跟 swallowError 同语义)
//
// 覆盖:
// - 3 个 wrapper 各自: 最小参数不抛 / stack + note 全参数不抛
// - scope 前缀转发正确 (源码 lock-in: _swallowScoped 统一走
//   _scopedWhere(scope, where), 3 个 wrapper 传各自 scope 常量)
// - swallow_error.dart 不动 (仍导出 swallowError 原始入口)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/shared/error_sinks.dart';

void main() {
  StackTrace captureStack() {
    try {
      throw StateError('inner');
    } catch (_, st) {
      return st;
    }
  }

  group('audioErrorSink (AR-23 audio 簇)', () {
    test('最小参数 (where + error) 不抛', () {
      expect(
        () => audioErrorSink(
          where: 'audio_lifecycle.dispose',
          error: Exception('boom'),
        ),
        returnsNormally,
      );
    });

    test('全参数 (stack + note) 不抛', () {
      expect(
        () => audioErrorSink(
          where: 'mood_audio_service.start',
          error: Exception('outer'),
          stack: captureStack(),
          note: 'context',
        ),
        returnsNormally,
      );
    });
  });

  group('notificationErrorSink (AR-23 notification-safety 簇)', () {
    test('最小参数 (where + error) 不抛', () {
      expect(
        () => notificationErrorSink(
          where: 'badge_sync_service.sync',
          error: 'string error',
        ),
        returnsNormally,
      );
    });

    test('全参数 (stack + note) 不抛', () {
      expect(
        () => notificationErrorSink(
          where: 'reminder_dispatcher.dispatch',
          error: Exception('outer'),
          stack: captureStack(),
          note: 'context',
        ),
        returnsNormally,
      );
    });
  });

  group('exportErrorSink (AR-23 export 簇)', () {
    test('最小参数 (where + error) 不抛', () {
      expect(
        () => exportErrorSink(
          where: 'export_crypto_service.decrypt',
          error: Exception('boom'),
        ),
        returnsNormally,
      );
    });

    test('全参数 (stack + note) 不抛', () {
      expect(
        () => exportErrorSink(
          where: 'export_schema_service.build',
          error: Exception('outer'),
          stack: captureStack(),
          note: 'context',
        ),
        returnsNormally,
      );
    });
  });

  group('scope 前缀转发 lock-in (AR-23 核心不变量)', () {
    late String source;

    setUpAll(() {
      source = File('lib/core/shared/error_sinks.dart').readAsStringSync();
    });

    test('3 个 wrapper 内部仍调 swallowError (行为 100% 不变)', () {
      // wrapper → _swallowScoped → swallowError 转发链
      final swallowForward = RegExp(
        r'swallowError\s*\(\s*where:\s*_scopedWhere\(scope,\s*where\)',
      );
      expect(
        swallowForward.hasMatch(source),
        isTrue,
        reason: '_swallowScoped 必须仍调 swallowError (wrapper 是转发不是替代)',
      );
    });

    test(r'_scopedWhere 加 `$scope.` 前缀 (where 组合逻辑集中 1 处)', () {
      final scopedWhere = RegExp(
        r"String\s+_scopedWhere\(String\s+scope,\s*String\s+where\)"
        r"\s*=>\s*'\$scope\.\$where'",
      );
      expect(
        scopedWhere.hasMatch(source),
        isTrue,
        reason: '_scopedWhere 必须实现 `scope.where` 组合 (以后改 sink 只动这 1 处)',
      );
    });

    test('3 个 wrapper 各传自己的 scope 常量', () {
      final audioScope = RegExp(r"_swallowScoped\(\s*'audio'");
      final notificationScope = RegExp(r"_swallowScoped\(\s*'notification'");
      final exportScope = RegExp(r"_swallowScoped\(\s*'export'");
      expect(
        audioScope.hasMatch(source),
        isTrue,
        reason: 'audioErrorSink 必须走 _swallowScoped(scope: audio)',
      );
      expect(
        notificationScope.hasMatch(source),
        isTrue,
        reason: 'notificationErrorSink 必须走 _swallowScoped(scope: notification)',
      );
      expect(
        exportScope.hasMatch(source),
        isTrue,
        reason: 'exportErrorSink 必须走 _swallowScoped(scope: export)',
      );
    });

    test('wrapper 签名与 swallowError 一致 (where / error / stack / note)', () {
      final wrapperSig = RegExp(
        r'void\s+(audio|notification|export)ErrorSink\s*\(\s*\{[\s\S]*?'
        r'required\s+String\s+where[\s\S]*?'
        r'required\s+Object\s+error[\s\S]*?'
        r'StackTrace\?\s+stack[\s\S]*?'
        r'String\?\s+note[\s\S]*?\}\s*\)\s*\{',
      );
      expect(
        wrapperSig.allMatches(source).length,
        3,
        reason: '3 个 wrapper 都必须带 where / error / stack / note 4 参数',
      );
    });
  });
}
