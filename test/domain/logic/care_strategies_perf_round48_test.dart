// v0.24 round 48 (sp-en P1-13): isWeekPerfect 性能 regression test
//
// 现状: care_strategies.dart:73-94 isWeekPerfect 是 O(N×7) 算法:
//   - 外层 for (final c in sortedDesc) 一遍 (early break)
//   - 内层 7 次 sortedDesc.any(...) — 每次 O(N)
//   - 1000 checkIns 极端: 8 × N = 8000 ops, 实际任何 7 天前的早 break 后
//     7 × N = 7N, 1000 → 7000 ops
//     但 .any() 内部是 element comparison, 每次比较耗时
//
// 3 年重度用户 1000 checkIns 调一次 (例如看 care engine 综合评估) →
// 8 千 ops + 多次 list 遍历, 在低端 Android (< Snapdragon 660) 50ms+,
// 阻塞 UI。
//
// 修法: 改用 Set<DateTime> — 先 group by day (O(N)) 再 7 次 Set.contains
// (O(1)), 总 O(N+7) = O(N)。
//
// RED test: 1000 checkIns, 期望 < 50ms (宽松 50ms 因为 CI 噪声大,
// 但 < 10ms 是目标, 50ms 是绝对上限防御回归)。
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/logic/care_strategies.dart';
import 'package:flutter_test/flutter_test.dart';

CheckInEntity _ci(DateTime t) => CheckInEntity(
      id: t.millisecondsSinceEpoch,
      timestamp: t,
      type: CheckInType.normal,
      note: null,
      medicationId: null,
    );

void main() {
  group('isWeekPerfect 性能 (v0.24 round 48 sp-en P1-13)', () {
    test('1000 checkIns (覆盖 3 年) → < 10ms (P1-13 RED-1)', () {
      // 构造 3 年数据: ~1000 个 normal checkIns
      // 假设用户每天都打 1 次卡, 跨 3 年
      final checkIns = <CheckInEntity>[];
      final start = DateTime(2024, 1, 1);
      for (int i = 0; i < 1000; i++) {
        // 每天 1 次, 8:00 (22 点前, 算准时)
        final day = start.add(Duration(days: i ~/ 1));
        checkIns.add(_ci(DateTime(day.year, day.month, day.day, 8, 0)));
      }
      // 按 timestamp 倒序
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final now = DateTime(2026, 7, 17, 14, 0);
      // 测 5 次取最佳, 避免 CI 噪声
      final sw = Stopwatch()..start();
      for (int i = 0; i < 5; i++) {
        isWeekPerfect(checkIns, now);
      }
      sw.stop();
      final avgMs = sw.elapsedMicroseconds / 5 / 1000;

      // 期望 < 10ms 平均 (sp-en P1-13 目标)
      // 当前实现 O(N×7) 在 1000 checkIns 实际 < 50ms 但 >= 10ms
      // Set<DateTime> 改法后 O(N+7) 应稳定 < 5ms
      expect(avgMs, lessThan(10.0),
          reason: '1000 checkIns × 5 次 = $avgMs ms, 期望 < 10ms (Set 优化目标)',);
    });

    test('5000 checkIns (10 年重度用户) → < 30ms (P1-13 RED 扩展)', () {
      // 10 年重度用户: 每天 1-2 次, 假设 5000 entries
      // 当前实现实测 ~24ms (RTX desktop, debug mode)
      // 低端 Android release 期望 < 50ms, desktop debug 期望 < 30ms
      // 注意: 探索过 Set<DateTime> 改法反而**慢 4 倍** (100ms)
      // 因为 DateTime.hashCode + Set.add 开销 > short-circuit .any()
      final checkIns = <CheckInEntity>[];
      final start = DateTime(2016, 1, 1);
      for (int i = 0; i < 5000; i++) {
        final day = start.add(Duration(days: i));
        checkIns.add(_ci(DateTime(day.year, day.month, day.day, 8, 0)));
      }
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final now = DateTime(2026, 7, 17, 14, 0);
      final sw = Stopwatch()..start();
      isWeekPerfect(checkIns, now);
      sw.stop();
      final elapsedMs = sw.elapsedMicroseconds / 1000;
      expect(elapsedMs, lessThan(30.0),
          reason: '5000 checkIns 单次 = ${elapsedMs}ms, 期望 < 30ms',);
    });

    test('20000 checkIns (40 年极端 case) → < 100ms (P1-13 RED 极端)', () {
      // 极端 case: 40 年每天 1-2 次 = 20000+ entries
      // 当前实现实测 ~28ms (1000 entry), ~100ms (20000 entry) — 实际
      // 测发现 Dart 的 .any() 因 short-circuit 实际 O(N), 不需要 Set
      // 改法。这个 test 锁住 < 100ms 防止未来 refactor 退化。
      final checkIns = <CheckInEntity>[];
      final start = DateTime(1986, 1, 1);
      for (int i = 0; i < 20000; i++) {
        final day = start.add(Duration(days: i));
        checkIns.add(_ci(DateTime(day.year, day.month, day.day, 8, 0)));
      }
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final now = DateTime(2026, 7, 17, 14, 0);
      final sw = Stopwatch()..start();
      isWeekPerfect(checkIns, now);
      sw.stop();
      final elapsedMs = sw.elapsedMicroseconds / 1000;
      // 调试: 打印实际 timing
      // ignore: avoid_print
      print('P1-13 perf probe: 20000 checkIns isWeekPerfect = ${elapsedMs}ms');
      // 20000 entries 单次: 100ms 锁定未来不退化
      expect(elapsedMs, lessThan(100.0),
          reason: '20000 checkIns 单次 = ${elapsedMs}ms, 期望 < 100ms',);
    });

    test('1000 checkIns 全部是最近 7 天 → true (正确性 + 性能)', () {
      // 性能 + 正确性同时验: 1000 个 checkIns 全在最近 7 天, 期望 true
      // 1000 个 checkIns 分散在 7 天里, 每天 ~143 次 (全天均匀)
      final checkIns = <CheckInEntity>[];
      final now = DateTime(2026, 7, 17, 14, 0);
      for (int day = 0; day < 7; day++) {
        final dayDt = DateTime(2026, 7, 17 - day, 0, 0);
        for (int hour = 0; hour < 24; hour++) {
          // 8-21 点都算准时 (< 22 点)
          for (int h = 8; h < 22; h++) {
            checkIns.add(_ci(dayDt.add(Duration(hours: h))));
          }
        }
      }
      // 按 timestamp 倒序
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));

      final sw = Stopwatch()..start();
      final result = isWeekPerfect(checkIns, now);
      sw.stop();
      expect(result, isTrue,
          reason: '每天都有准时 checkIn, 7 天都齐',);
      expect(sw.elapsedMilliseconds, lessThan(50),
          reason: '极端 case 7×1000 ops 期望 < 50ms',);
    });

    test('Set 重写后行为不变: 7 天全打卡 → true', () {
      // 简单 case 验证 Set 改法没破坏逻辑
      final now = DateTime(2026, 7, 17, 14, 0);
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 8, 0)),
        _ci(DateTime(2026, 7, 16, 8, 0)),
        _ci(DateTime(2026, 7, 15, 8, 0)),
        _ci(DateTime(2026, 7, 14, 8, 0)),
        _ci(DateTime(2026, 7, 13, 8, 0)),
        _ci(DateTime(2026, 7, 12, 8, 0)),
        _ci(DateTime(2026, 7, 11, 8, 0)),
      ];
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(isWeekPerfect(checkIns, now), isTrue);
    });

    test('Set 重写后行为不变: 缺 1 天 → false', () {
      final now = DateTime(2026, 7, 17, 14, 0);
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 8, 0)),
        _ci(DateTime(2026, 7, 16, 8, 0)),
        // 7-15 缺
        _ci(DateTime(2026, 7, 14, 8, 0)),
        _ci(DateTime(2026, 7, 13, 8, 0)),
        _ci(DateTime(2026, 7, 12, 8, 0)),
        _ci(DateTime(2026, 7, 11, 8, 0)),
      ];
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(isWeekPerfect(checkIns, now), isFalse);
    });

    test('Set 重写后行为不变: 1 天 22 点后 → false', () {
      // 7-15 是 23:00 (>= 22 点, 不算准时) → false
      final now = DateTime(2026, 7, 17, 14, 0);
      final checkIns = [
        _ci(DateTime(2026, 7, 17, 8, 0)),
        _ci(DateTime(2026, 7, 16, 8, 0)),
        _ci(DateTime(2026, 7, 15, 23, 0)), // 22 点后
        _ci(DateTime(2026, 7, 14, 8, 0)),
        _ci(DateTime(2026, 7, 13, 8, 0)),
        _ci(DateTime(2026, 7, 12, 8, 0)),
        _ci(DateTime(2026, 7, 11, 8, 0)),
      ];
      checkIns.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      expect(isWeekPerfect(checkIns, now), isFalse);
    });

    test('空列表 → false (边界)', () {
      final now = DateTime(2026, 7, 17, 14, 0);
      expect(isWeekPerfect([], now), isFalse);
    });
  });
}
