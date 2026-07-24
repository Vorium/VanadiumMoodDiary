// v0.23 (Round 31 P0-6): last_error_capture 单元测试
//
// 之前 v0.22 round 33 加 P0 启动 error 捕获器 (record + consume 走
// SharedPreferences) 但 0 测试覆盖。补 5 个 case:
//   1. record + consume round trip
//   2. consume 后再 consume → null (auto-clear)
//   3. malformed payload → null (不 throw)
//   4. 错误消息超 200 字符 → 截断带省略号
//   5. stack 截到 5 行
import 'package:chroniccare/core/data/services/last_error_capture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LastErrorCapture round trip', () {
    test('record error → consume 拿得到', () async {
      final error = Exception('boom');
      final stack = StackTrace.fromString(
        'frame1\nframe2\nframe3',
      );
      await LastErrorCapture.record(error, stack);

      final result = await LastErrorCapture.consume();
      expect(result, isNotNull);
      expect(result!.error, contains('boom'));
      expect(result.stack, contains('frame1'));
    });

    test('consume 后再 consume → 返 null (auto-clear 行为)', () async {
      await LastErrorCapture.record(
        Exception('boom'),
        StackTrace.fromString('frame1'),
      );

      final first = await LastErrorCapture.consume();
      final second = await LastErrorCapture.consume();
      expect(first, isNotNull);
      expect(second, isNull, reason: 'auto-clear 应让第二次 consume 返 null');
    });
  });

  group('LastErrorCapture 容错', () {
    test('malformed payload → consume 返 null, 不 throw', () async {
      // 直接写坏数据到 SharedPreferences (绕过 record)
      SharedPreferences.setMockInitialValues(<String, Object>{
        'last_startup_error': 'garbage_no_newline',
      });
      final result = await LastErrorCapture.consume();
      expect(result, isNull, reason: 'malformed payload 应 graceful 返 null');
    });

    test('timestamp 解析失败 → 返 null', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'last_startup_error': 'not-a-date\nERROR: x\nSTACK:\n',
      });
      final result = await LastErrorCapture.consume();
      expect(result, isNull);
    });
  });

  group('LastErrorCapture 截断', () {
    test('error string 超 200 字符 → 截断带省略号', () async {
      final longMsg = 'X' * 500;
      await LastErrorCapture.record(
        Exception(longMsg),
        StackTrace.empty,
      );
      final result = await LastErrorCapture.consume();
      expect(result, isNotNull);
      // 200 + 省略号
      expect(result!.error.length, lessThanOrEqualTo(201));
      expect(result.error, endsWith('…'));
    });

    test('stack 超 5 行 → 截断到 5 行', () async {
      final stack = StackTrace.fromString(
        'frame1\nframe2\nframe3\nframe4\nframe5\nframe6\nframe7',
      );
      await LastErrorCapture.record(Exception('boom'), stack);
      final result = await LastErrorCapture.consume();
      expect(result, isNotNull);
      // 5 行内应保留
      expect(result!.stack, contains('frame1'));
      expect(result.stack, contains('frame5'));
      // 第 6 行起应被截
      expect(result.stack, isNot(contains('frame6')));
      expect(result.stack, isNot(contains('frame7')));
    });
  });
}
