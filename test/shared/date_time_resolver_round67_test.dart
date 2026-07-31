// v0.27 round 67 (C-1 重构): DateTimeResolvers 集中器测试
//
// R63 P1-6 抽的 file-private `_resolveTimestamp` 在 round 67 公开到
// `core/shared/date_time_resolver.dart`, 给 4 处 caller 复用。
// 这 5 个 case 验证行为跟原 file-private helper 完全一致 (refactor 行为不变)。

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/shared/date_time_resolver.dart';

void main() {
  group('DateTimeResolvers.at (R67 C-1)', () {
    test('1. at 非 null 返 at (原值不变)', () {
      final provided = DateTime(2026, 7, 31, 14, 30, 0);
      final result = DateTimeResolvers.at(provided);
      expect(result, equals(provided));
      expect(result.isUtc, isFalse); // 本地时区
    });

    test('2. at null 返 DateTime.now() (误差 < 100ms)', () {
      final before = DateTime.now();
      final result = DateTimeResolvers.at(null);
      final after = DateTime.now();
      // 实际值应该在 before / after 区间内 (允许毫秒级精度)
      expect(
        result.isAfter(before.subtract(const Duration(milliseconds: 1))),
        isTrue,
      );
      expect(
        result.isBefore(after.add(const Duration(milliseconds: 1))),
        isTrue,
      );
    });

    test('3. 多次调 at(null) 在 1 小时内不会因 race 返跨小时', () {
      // R19B DateTime race 纪律: 函数入口 1 次取, 不要散落多次
      // 这里验证集中器对"短时间内多次调"返回合理值 (同 1 ms 内)
      final results = <DateTime>[];
      for (var i = 0; i < 100; i++) {
        results.add(DateTimeResolvers.at(null));
      }
      // 100 次连续调, 最早和最晚差距 < 1 秒 (跟原 helper 行为完全一致)
      final span = results.last.difference(results.first).inMilliseconds.abs();
      expect(span, lessThan(1000));
    });

    test('4. 集中器跟原 file-private _resolveTimestamp 行为一致 (refactor 行为不变)', () {
      // R63 P1-6 file-private version: `DateTime _resolveTimestamp(DateTime? at) => at ?? DateTime.now();`
      // 验证行为完全相同:
      // - 非 null: 返 at
      // - null: 返 now
      // - 不做时区转换
      // - 不抛错 (任何 DateTime 值都接受, 包括 epoch / 远未来)

      // 远未来
      final farFuture = DateTime(2099, 12, 31, 23, 59, 59);
      expect(DateTimeResolvers.at(farFuture), equals(farFuture));

      // 远过去
      final farPast = DateTime(2000, 1, 1, 0, 0, 0);
      expect(DateTimeResolvers.at(farPast), equals(farPast));
    });

    test('5. edge case: at = epoch (1970-01-01) 仍返 epoch (不转换时区)', () {
      final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: false);
      final result = DateTimeResolvers.at(epoch);
      expect(result, equals(epoch));
      expect(result.millisecondsSinceEpoch, equals(0));
    });
  });
}
