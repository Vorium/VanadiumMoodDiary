// v0.30 round 95 (sub-spec 2 task 25): vent_compose dispose 异步未 await lock-in
//
// **关键发现**: R95 增量综合审视报告 §3.2 提 "vent_compose dispose 异步未 await
// (R72 P2-1 → R75 → R76 → R77 → R93 仍未修)" — **实际 R79 (cf3db24) 已修**:
//
// - R79 修法: 抽 _asyncDispose() helper 内部顺序释放 (cancel stream sub →
//   stop recorder if recording → dispose recorder → dispose player →
//   delete temp file), 用 unawaited() 包装避免 State.dispose() 强制
//   sync 签名要求。每步 catch 走 swallowError 集中器, 防止 stop/dispose
//   异常时整条链中断, 后续资源漏释放。
//
// 跟 R95 sub-spec 2 task 8 (catch (_) → swallowError) 模式一致:
// stale audit → 0 改动需要, 加 lock-in test 防御未来 refactor 退回
// sync 调 `_recorder.dispose()` / `_player.dispose()` 不用 await。
//
// 5 case 静态源码 grep 守门 (跟 R93 vent_compose_page_r93_hide_test 一样
// 风格, 不依赖 audioplayers / record platform channel mock):
// 1. dispose() 调 unawaited(_asyncDispose()) — R79 修法存在
// 2. _asyncDispose() 内部 await _playerCompleteSub?.cancel() — stream sub 释放
// 3. _asyncDispose() 内部 await _recorder.dispose() — recorder native 句柄释放
// 4. _asyncDispose() 内部 await _player.dispose() — player native 句柄释放
// 5. _asyncDispose() 内部 4 个 try/catch + swallowError — R17 模式防御
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('vent_compose dispose 异步 lock-in (R95 sub-spec 2 task 25)', () {
    late String source;

    setUpAll(() {
      // 静态读源文件 (跟 R93 vent_compose_page_r93_hide_test 风格一致)
      final file = File(
        'lib/presentation/pages/vent/vent_compose_page.dart',
      );
      source = file.readAsStringSync();
    });

    test('R79 fix 1: dispose() 调 unawaited(_asyncDispose())', () {
      // 验证 R79 修法: 用 unawaited 包装 _asyncDispose() helper,
      // 而不是直接 sync 调 _recorder.dispose() / _player.dispose()
      expect(
        source.contains('unawaited(_asyncDispose())'),
        isTrue,
        reason: 'dispose() 必须用 unawaited(_asyncDispose()) 包装 (R79 修法), '
            '防止 sync 调 future 释放不完整 → OOM / audio session 异常',
      );
    });

    test('R79 fix 2: _asyncDispose() 内部 await _playerCompleteSub?.cancel()', () {
      // 验证 stream subscription 在 _asyncDispose 内部被 await cancel
      // (line 95 实际位置, R22 P1-3 + R79 续)
      expect(
        source.contains('await _playerCompleteSub?.cancel()'),
        isTrue,
        reason: 'dispose 时 stream subscription 必须 await cancel, '
            '否则反复进/出 page 累积 listener 泄漏',
      );
    });

    test('R79 fix 3: _asyncDispose() 内部 await _recorder.dispose()', () {
      // 验证 recorder native 句柄在 _asyncDispose 内部被 await dispose
      expect(
        source.contains('await _recorder.dispose()'),
        isTrue,
        reason: 'recorder native handle (iOS AudioRecorderImpl / Android '
            'AudioRecord) 必须 await dispose, 否则反复进/出 page 累积 '
            'native 句柄 → OOM',
      );
    });

    test('R79 fix 4: _asyncDispose() 内部 await _player.dispose()', () {
      // 验证 player native 句柄在 _asyncDispose 内部被 await dispose
      expect(
        source.contains('await _player.dispose()'),
        isTrue,
        reason: 'player native handle (audioplayers 5.0+ dispose 释放 '
            'native handle) 必须 await dispose, 跟 recorder 同',
      );
    });

    test('R79 fix 5: _asyncDispose() 内部 4 个 try/catch + swallowError', () {
      // 验证每步 await 都在 try/catch + swallowError 里, 防止 stop/dispose
      // 异常时整条链中断, 后续资源漏释放 (R17 模式)
      final swallowErrorCount = 'swallowError('.allMatches(source).length;
      expect(
        swallowErrorCount,
        greaterThanOrEqualTo(4),
        reason: 'dispose 链至少 4 个 catch + swallowError (recorder.stop / '
            'recorder.dispose / player.dispose / temp.delete) — 防御 '
            '单步异常阻断后续资源释放',
      );

      // 验证 _asyncDispose() 内部 await 链模式: 抽 helper 行号范围
      final lines = source.split('\n');
      final startIdx =
          lines.indexWhere((l) => l.contains('Future<void> _asyncDispose()'));
      expect(
        startIdx,
        greaterThanOrEqualTo(0),
        reason: '应能找到 _asyncDispose() helper 定义',
      );
      // 找 _asyncDispose 下一个 member (2 spaces 缩进的 `  Future<` 或 `  }`)
      // 或下一个 class member (2 spaces 缩进)
      var endIdx = startIdx + 1;
      for (var i = startIdx + 1; i < lines.length; i++) {
        final line = lines[i];
        // 2 spaces 缩进 = 下一个 class member 起点
        if (line.startsWith('  ') &&
            !line.startsWith('   ') &&
            line.trim().isNotEmpty &&
            !line.contains('//')) {
          endIdx = i;
          break;
        }
      }
      final body = lines.sublist(startIdx, endIdx).join('\n');
      final awaitCount = 'await '.allMatches(body).length;
      final tryCount = 'try {'.allMatches(body).length;
      // cancel (await _playerCompleteSub?.cancel()) 跟 _isRecording 分支 stop
      // 不在 try 里, 所以 try 数 < await 数是合理的 (cancel 是 sync 收尾
      // 不抛异常, _isRecording false 时不调 recorder.stop)。但 recorder.dispose
      // / player.dispose / temp.delete 3 个 await 必须在 try 里。
      expect(
        tryCount,
        greaterThanOrEqualTo(3),
        reason: '_asyncDispose() 内部 recorder.dispose / player.dispose / '
            'temp.delete 3 个 await 必须在 try { ... } 里, 实际 try=$tryCount',
      );
      expect(
        awaitCount,
        greaterThanOrEqualTo(4),
        reason: '_asyncDispose() 内部至少有 cancel + 3 个 try-await = 4+ await, '
            '实际 await=$awaitCount',
      );
    });
  });
}
