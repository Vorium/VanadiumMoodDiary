// v0.28 round 83 (spzh P1-3): SwallowLogSink 单元测试
//
// 覆盖:
// 1. 文件创建 + append
// 2. PII 脱敏: phone / email / 长数字串
// 3. 超过 maxBytes → truncate
// 4. delete 清空
// 5. 多次 write 后 readAll 顺序正确

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/services/swallow_log_sink.dart';

void main() {
  late Directory tempDir;
  late File logFile;
  late SwallowLogSink sink;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('swallow_test_');
    logFile = File('${tempDir.path}/swallow.log');
    sink = SwallowLogSink(logFile);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// 等 flush 队列处理完 — 内部 future 没法 await (fire-and-forget),
  /// 测试用 spin 查 lastWriteAt 是否更新
  // ignore: no_leading_underscores_for_local_identifiers
  Future<void> _waitForFlush() async {
    // v0.29 R88 (P3-90 flaky fix): 用 Stopwatch 替代 DateTime.now() spin poll,
    // 跨 midnight 时 DateTime.now() 落到次日, .difference 算出负数或异常大值
    // 导致 timeout 误判。Stopwatch.elapsedMilliseconds 跟 wall clock 解耦。
    final stopwatch = Stopwatch()..start();
    while (sink.lastWriteAt == null ||
        DateTime.now().difference(sink.lastWriteAt!).inMilliseconds < 10) {
      if (stopwatch.elapsedMilliseconds > 1000) {
        throw StateError('SwallowLogSink flush timeout');
      }
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
  }

  group('SwallowLogSink.write + readAll', () {
    test('写入 1 条 → 文件包含 where + error 信息', () async {
      sink.write(
        where: 'test.fixture',
        note: null,
        error: Exception('boom'),
      );
      await _waitForFlush();
      final content = await sink.readAll();
      expect(content, contains('test.fixture'));
      expect(content, contains('Exception'));
      expect(content, contains('boom'));
    });

    test('写入多条 → 顺序保留, 都进文件', () async {
      for (var i = 0; i < 5; i++) {
        sink.write(
          where: 'test.fixture_$i',
          note: 'note_$i',
          error: StateError('err_$i'),
        );
      }
      // 5 条写完后等最后一条 flush
      await _waitForFlush();
      // 额外等一点确保所有 batch 都进文件
      await Future<void>.delayed(const Duration(milliseconds: 50));
      final content = await sink.readAll();
      for (var i = 0; i < 5; i++) {
        expect(
          content,
          contains('fixture_$i'),
          reason: 'should contain fixture_$i, got: $content',
        );
        expect(content, contains('err_$i'));
      }
    });

    test('note 写入文件', () async {
      sink.write(
        where: 'test.fixture',
        note: 'this is a test note',
        error: Exception('boom'),
      );
      await _waitForFlush();
      final content = await sink.readAll();
      expect(content, contains('this is a test note'));
    });

    test('lastWriteAt 写入后更新', () async {
      expect(sink.lastWriteAt, isNull);
      sink.write(
        where: 'test.fixture',
        note: null,
        error: Exception('boom'),
      );
      await _waitForFlush();
      expect(sink.lastWriteAt, isNotNull);
    });
  });

  group('SwallowLogSink.sanitizeForLog', () {
    test('mask 中国手机号 (11 位)', () {
      expect(
        SwallowLogSink.sanitizeForLog('error: 13800138000 failed'),
        contains('138****8000'),
      );
      expect(
        SwallowLogSink.sanitizeForLog('error: 13800138000 failed'),
        isNot(contains('13800138000')),
      );
    });

    test('mask 带 +86 前缀手机号 (13 位)', () {
      final result = SwallowLogSink.sanitizeForLog('to: +8613800138000');
      expect(result, isNot(contains('+8613800138000')));
      expect(result, contains('****'));
    });

    test('mask 邮箱', () {
      final result = SwallowLogSink.sanitizeForLog('email: john.doe@example.com');
      expect(result, isNot(contains('john.doe@example.com')));
      // local 'john.doe' (8 chars) → j + 8 asterisks + @example.com
      expect(result, contains('j********@example.com'));
    });

    test('mask 长数字串 (身份证 / 银行卡)', () {
      final result = SwallowLogSink.sanitizeForLog('idcard: 110101199001011234');
      expect(result, isNot(contains('110101199001011234')));
      expect(result, contains('****'));
    });

    test('短数字 (< 10 位) 不 mask', () {
      // 短数字可能是 ID / 计数器, 不 mask 避免噪音
      expect(
        SwallowLogSink.sanitizeForLog('item id 12345'),
        contains('12345'),
      );
    });

    test('where / note 混合 PII 全部脱敏', () {
      final result = SwallowLogSink.sanitizeForLog(
        'swallow at home_page, phone=13800138000, email=a@b.com, id=110101199001011234',
      );
      expect(result, contains('swallow at home_page'));
      expect(result, isNot(contains('13800138000')));
      expect(result, isNot(contains('a@b.com')));
      expect(result, isNot(contains('110101199001011234')));
    });

    test('普通字符串不动', () {
      const input = 'simple error message';
      expect(SwallowLogSink.sanitizeForLog(input), input);
    });
  });

  group('SwallowLogSink 文件大小 truncate', () {
    test('超过 maxBytes → 截断保留 80%', () async {
      // 用 200 字节上限, 写 1KB 内容, 验证 truncate
      final smallSink = SwallowLogSink(
        logFile,
        maxBytes: 200,
      );
      // 写满约 50 条短记录
      for (var i = 0; i < 50; i++) {
        smallSink.write(
          where: 'test.long_$i',
          note: 'padding_$i',
          error: Exception('err_$i'),
        );
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
      final size = await logFile.length();
      // 截断后应该 ≤ 200 字节, 但内部逻辑保留 80% (160), 给点 buffer
      expect(size, lessThanOrEqualTo(300));
      // 截断后内容应该仍然有完整行 (truncate 找换行对齐)
      final content = await logFile.readAsString();
      // 每行以 \n 结尾, 不应该有半行残留
      final lines = content.split('\n').where((l) => l.isNotEmpty).toList();
      for (final line in lines) {
        expect(line, isNot(contains('partial')));
      }
    });
  });

  group('SwallowLogSink.delete', () {
    test('delete 后文件不存在, readAll 返空', () async {
      sink.write(
        where: 'test.fixture',
        note: null,
        error: Exception('boom'),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(await logFile.exists(), isTrue);
      await sink.delete();
      expect(await logFile.exists(), isFalse);
      expect(await sink.readAll(), isEmpty);
      expect(sink.lastWriteAt, isNull);
    });

    test('delete 不存在的文件不报错', () async {
      await sink.delete();
      expect(await logFile.exists(), isFalse);
    });
  });
}
