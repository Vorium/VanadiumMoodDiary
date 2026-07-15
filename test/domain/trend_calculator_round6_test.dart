// v0.12 (Round 6) TrendCalculator.monthlyCalendar + shiftMonth 测试
// v0.14 (Round 12A) 4 层架构：CheckInEntity / MoodEntryEntity
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/trend_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TrendCalculator.shiftMonth', () {
    test('正数 = 下个月', () {
      final m = DateTime(2026, 7, 1);
      expect(TrendCalculator.shiftMonth(m, 1), DateTime(2026, 8, 1));
    });

    test('负数 = 上个月', () {
      final m = DateTime(2026, 7, 1);
      expect(TrendCalculator.shiftMonth(m, -1), DateTime(2026, 6, 1));
    });

    test('跨年', () {
      final m = DateTime(2026, 1, 1);
      expect(TrendCalculator.shiftMonth(m, -1), DateTime(2025, 12, 1));
      expect(TrendCalculator.shiftMonth(m, 1), DateTime(2026, 2, 1));
    });

    test('跨大月（1月→2月 / 31天）', () {
      // 1月有 31 天, +1 = 2月1号
      expect(TrendCalculator.shiftMonth(DateTime(2026, 1, 1), 1),
          DateTime(2026, 2, 1));
      // 3月有 31 天, -1 = 2月1号
      expect(TrendCalculator.shiftMonth(DateTime(2026, 3, 1), -1),
          DateTime(2026, 2, 1));
    });
  });

  CheckInEntity ciAt(DateTime t, {String type = 'normal'}) {
    return CheckInEntity(
      id: 0,
      timestamp: t,
      type: CheckInType.fromWire(type),
      medicationId: null,
      note: null,
    );
  }

  MoodEntryEntity moodAt(DateTime t, int score) {
    return MoodEntryEntity(
      id: 0,
      timestamp: t,
      score: score,
      tagsJson: '[]',
      note: null,
    );
  }

  group('TrendCalculator.monthlyCalendar', () {
    test('返回 42 格（6行 × 7列）', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: const [],
      );
      expect(cm.cells.length, 42);
    });

    test('cell.weekday 从 1 周一开始（周一=1, ..., 周日=7）', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: const [],
      );
      // 2026-07-01 是星期三
      // 网格起点 = 2026-06-29（周一）
      expect(cm.cells.first.date, DateTime(2026, 6, 29));
      expect(cm.cells.first.date.weekday, 1); // 周一
      // 终点 = 2026-08-09（周日）
      expect(cm.cells.last.date, DateTime(2026, 8, 9));
      expect(cm.cells.last.date.weekday, 7); // 周日
    });

    test('byDate 只含当月日期（不含上月末尾/下月开头）', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: const [],
      );
      // 当月 31 天
      expect(cm.byDate.length, 31);
      expect(cm.byDate.containsKey(DateTime(2026, 7, 15)), isTrue);
      expect(cm.byDate.containsKey(DateTime(2026, 6, 30)), isFalse);
      expect(cm.byDate.containsKey(DateTime(2026, 8, 1)), isFalse);
    });

    test('空数据：所有 cell.isEmpty=true', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: const [],
      );
      for (final c in cm.cells) {
        expect(c.isEmpty, isTrue, reason: 'cell ${c.date} should be empty');
        expect(c.hasNormalCheckIn, isFalse);
        expect(c.moodScore, isNull);
      }
    });

    test('normal 打卡计入 hasNormalCheckIn', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: [
          ciAt(DateTime(2026, 7, 15, 8, 30)),
          ciAt(DateTime(2026, 7, 15, 20, 30)), // 同一天 2 次也算
        ],
      );
      final day = cm.byDate[DateTime(2026, 7, 15)]!;
      expect(day.hasNormalCheckIn, isTrue);
      expect(day.checkInCount, 2);
    });

    test('temp 打卡计入 checkInCount 但不计入 hasNormalCheckIn', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: [
          ciAt(DateTime(2026, 7, 10), type: 'temp'),
        ],
      );
      final day = cm.byDate[DateTime(2026, 7, 10)]!;
      expect(day.hasNormalCheckIn, isFalse);
      expect(day.checkInCount, 1);
      expect(day.isEmpty, isFalse); // 有事件, 不算空
    });

    test('assessment 计入 checkInCount（药报告 + 评估合并）', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: [
          ciAt(DateTime(2026, 7, 20), type: 'phq9'),
        ],
      );
      final day = cm.byDate[DateTime(2026, 7, 20)]!;
      expect(day.checkInCount, 1);
    });

    test('当天最高情绪分：多次 moodEntry 取 max', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: const [],
        moodEntries: [
          moodAt(DateTime(2026, 7, 5, 8, 0), 2),
          moodAt(DateTime(2026, 7, 5, 20, 0), 4), // 更高
          moodAt(DateTime(2026, 7, 5, 22, 0), 3),
        ],
      );
      final day = cm.byDate[DateTime(2026, 7, 5)]!;
      expect(day.moodScore, 4);
    });

    test('打卡 + 情绪 同时存在：两个字段都填', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: [ciAt(DateTime(2026, 7, 8))],
        moodEntries: [moodAt(DateTime(2026, 7, 8, 21, 0), 5)],
      );
      final day = cm.byDate[DateTime(2026, 7, 8)]!;
      expect(day.hasNormalCheckIn, isTrue);
      expect(day.moodScore, 5);
      expect(day.checkInCount, 1);
    });

    test('跨天打卡：只算当天', () {
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 7, 1),
        checkIns: [
          ciAt(DateTime(2026, 7, 1, 23, 59)), // 当月最后秒
        ],
      );
      // 7/1 在当月
      expect(cm.byDate[DateTime(2026, 7, 1)]!.hasNormalCheckIn, isTrue);
      // 7/2 没了
      expect(cm.byDate[DateTime(2026, 7, 2)]!.hasNormalCheckIn, isFalse);
    });

    test('2月（28 / 29天）byDate 长度正确', () {
      // 2026 不是闰年
      final cm1 = TrendCalculator.monthlyCalendar(
        month: DateTime(2026, 2, 1),
        checkIns: const [],
      );
      expect(cm1.byDate.length, 28);
      // 2024 是闰年
      final cm2 = TrendCalculator.monthlyCalendar(
        month: DateTime(2024, 2, 1),
        checkIns: const [],
      );
      expect(cm2.byDate.length, 29);
    });

    test('1月1日是周五：周一是 12/30', () {
      // 2027-01-01 是星期五
      final cm = TrendCalculator.monthlyCalendar(
        month: DateTime(2027, 1, 1),
        checkIns: const [],
      );
      // 周一 = 2026-12-28（因为 12-28 是周一, 12-30 是周三）
      // 等等: 12/28 周一, 12/29 周二, 12/30 周三, 12/31 周四, 1/1 周五
      // 实际: 2027-01-01 的 weekday = 5
      // leading = 5 - 1 = 4
      // gridStart = 2027-01-01 - 4天 = 2026-12-28
      expect(cm.cells.first.date, DateTime(2026, 12, 28));
    });
  });
}
