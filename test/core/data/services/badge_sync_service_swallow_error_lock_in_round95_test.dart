// v0.30 round 95 (sub-spec 2 task 26): badge_sync_service catch (e) →
// swallowError lock-in
//
// **关键发现**: R95 增量综合审视报告 §3.2 提 "badge_sync_service catch (e)
// 加 swallowError 包装 (R76 P3-3, R93 仍未修)" — **实际 R79 (fec978f) 已修**:
//
// - R79 修法: 唯一漏改的 catch 块走 swallowError 集中器, 错误记录到
//   LastErrorCapture + piiSafeLog。PIPL §6 错误透明度 + dev tooling:
//   piiSafeLog 输出脱敏 + developer.log 记完整 stack, release 包只走
//   piiSafeLog。
//
// 跟 R95 sub-spec 2 task 8 (catch (_) → swallowError) + task 25
// (vent_compose dispose 异步未 await) 模式一致: stale audit → 0 改动需要,
// 加 lock-in test 防御未来 refactor 退回 `} catch (e, st) { ... }` 不
// 走 swallowError 集中器。
//
// 3 case 静态源码 grep 守门:
// 1. badge_sync_service.dart 有 catch (e, st) 块 (R17 模式带 stack trace)
// 2. catch 块内调 swallowError(...)
// 3. swallowError 调用带 where / error / stack / note 4 个参数
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('badge_sync_service error sink lock-in (R95 sub-spec 2 task 26 + R112 AR-23)', () {
    late String source;

    setUpAll(() {
      final file = File(
        'lib/core/data/services/badge_sync_service.dart',
      );
      source = file.readAsStringSync();
    });

    test('R79 fix 1: catch (e, st) 块存在 (带 stack trace)', () {
      // 验证 badge_sync_service.dart 唯一 1 个 catch 块带 stack trace
      // (跟 R17 模式一致, swallowError 需要 stack 参数)
      final catchMatch =
          RegExp(r'\}\s*catch\s*\(\s*e\s*,\s*st\s*\)\s*\{').allMatches(source);
      expect(
        catchMatch.length,
        greaterThanOrEqualTo(1),
        reason: '应至少有 1 个 `catch (e, st) {` 块 (R17 模式带 stack trace)',
      );
    });

    test('R79 fix 2: catch 块内调 notificationErrorSink (AR-23 分簇)', () {
      // 验证 catch 块内调 notificationErrorSink(...) (R17 + R79 模式 +
      // R112 AR-23: badge 属 notification-safety 簇, 改调 scoped wrapper)
      // 不能用 `} catch (e) { ... }` 完全吞错
      final catchBodyMatches = RegExp(
        r'\}\s*catch\s*\(\s*e\s*,\s*st\s*\)\s*\{(.*?)\n\s*\}',
        multiLine: true,
        dotAll: true,
      ).allMatches(source);
      expect(
        catchBodyMatches.length,
        greaterThanOrEqualTo(1),
        reason: '应能找到 catch (e, st) { ... } 块 body',
      );

      // 至少有一个 catch 块 body 包含 notificationErrorSink(
      final hasSink = catchBodyMatches.any(
        (m) => (m.group(1) ?? '').contains('notificationErrorSink('),
      );
      expect(
        hasSink,
        isTrue,
        reason: '至少一个 catch (e, st) 块必须调 notificationErrorSink(...) '
            '(AR-23: badge 走 notification-safety 簇 wrapper), '
            '不能 `} catch (e) { ... }` 静默吞错',
      );
    });

    test('R79 fix 3: notificationErrorSink 调用带 where / error / stack / note 4 个参数', () {
      // 验证 notificationErrorSink 调用带 4 个 named 参数 (swallowError API)
      // - where (位置定位)
      // - error (异常对象)
      // - stack (stack trace)
      // - note (失败影响说明)
      final sinkCallMatches = RegExp(
        r'notificationErrorSink\s*\(\s*([\s\S]*?)\)',
        multiLine: true,
      ).allMatches(source);
      expect(
        sinkCallMatches.length,
        greaterThanOrEqualTo(1),
        reason: '应至少有 1 个 notificationErrorSink(...) 调用',
      );

      // 至少有一个 notificationErrorSink 调用带 4 个参数
      final hasFourArgs = sinkCallMatches.any((m) {
        final args = m.group(1) ?? '';
        return args.contains('where:') &&
            args.contains('error:') &&
            args.contains('stack:') &&
            args.contains('note:');
      });
      expect(
        hasFourArgs,
        isTrue,
        reason: 'notificationErrorSink 应带 where / error / stack / note 4 个 '
            'named 参数 (swallowError API 完整调用, 防御未来 refactor 漏参数)',
      );
    });
  });
}
