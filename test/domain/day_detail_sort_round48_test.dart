// v0.24 round 48 (sp-en P1-11): DayDetailCalculator.fromData 排序 logic 锁定
//
// 现状: DayDetailCalculator.fromData 在 events 收齐后 (line 232):
//   events.sort((a, b) => a.time.compareTo(b.time));
// 排序行为正确 (Dart List.sort 是 Tim sort, 同 key 时稳定保留原序),但
// 没 unit test 锁行为。v0.16 round 19/19B 立的"隐式排序假设"反模式:
// caller 传"乱序"events 时, 依赖 sort 才能正确显示, 哪天实现偷懒去掉
// .sort() (或换成 .reversed) 就会 silently 翻车。
//
// 本 test 锁:
// 1. 乱序 events 进来 → 输出正序
// 2. 同秒多 events (稳定 sort) → 保留插入顺序
// 3. checkIn + moodEntries 混合 → 整体正序
//
// 0 flutter 0 drift 纯 Dart 测。
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:flutter_test/flutter_test.dart';

// 复用 day_detail_round10_test 的 factory,保持构造一致
CheckInEntity _ci({
  required int id,
  required DateTime timestamp,
  String type = 'normal',
}) {
  return CheckInEntity(
    id: id,
    timestamp: timestamp,
    type: CheckInType.fromWire(type),
  );
}

MoodEntryEntity _mood({
  required int id,
  required DateTime timestamp,
  required int score,
  List<String> tags = const [],
  String? note,
}) {
  final tagsJson =
      tags.isEmpty ? '[]' : '[${tags.map((t) => '"$t"').join(',')}]';
  return MoodEntryEntity(
    id: id,
    timestamp: timestamp,
    score: score,
    tagsJson: tagsJson,
    note: note,
  );
}

void main() {
  group('DayDetailCalculator.fromData sort (v0.24 round 48 sp-en P1-11)', () {
    test('checkIns 乱序输入 → 输出正序 (P1-11 RED-1)', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        // 故意乱序: 14 → 8 → 20 → 12
        checkIns: [
          _ci(id: 1, timestamp: DateTime(2026, 7, 15, 14)),
          _ci(id: 2, timestamp: DateTime(2026, 7, 15, 8)),
          _ci(id: 3, timestamp: DateTime(2026, 7, 15, 20)),
          _ci(id: 4, timestamp: DateTime(2026, 7, 15, 12)),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.length, 4);
      // 验证输出按 time 正序: 8, 12, 14, 20
      expect(d.events[0].time, DateTime(2026, 7, 15, 8));
      expect(d.events[1].time, DateTime(2026, 7, 15, 12));
      expect(d.events[2].time, DateTime(2026, 7, 15, 14));
      expect(d.events[3].time, DateTime(2026, 7, 15, 20));
    });

    test('moodEntries 乱序 → 输出正序', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: const [],
        // 乱序: 22 → 10 → 18
        moodEntries: [
          _mood(id: 1, timestamp: DateTime(2026, 7, 15, 22), score: 6),
          _mood(id: 2, timestamp: DateTime(2026, 7, 15, 10), score: 4),
          _mood(id: 3, timestamp: DateTime(2026, 7, 15, 18), score: 5),
        ],
        medications: const [],
      );
      expect(d.events.length, 3);
      expect(d.events[0].time, DateTime(2026, 7, 15, 10));
      expect(d.events[1].time, DateTime(2026, 7, 15, 18));
      expect(d.events[2].time, DateTime(2026, 7, 15, 22));
    });

    test('checkIn + moodEntries 混合乱序 → 整体按 time 正序 (P1-11 RED-3)', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        // 故意混着乱序: checkIn 14, mood 9, checkIn 8, mood 16, checkIn 12
        checkIns: [
          _ci(id: 1, timestamp: DateTime(2026, 7, 15, 14)),
          _ci(id: 2, timestamp: DateTime(2026, 7, 15, 8)),
          _ci(id: 3, timestamp: DateTime(2026, 7, 15, 12)),
        ],
        moodEntries: [
          _mood(id: 1, timestamp: DateTime(2026, 7, 15, 9), score: 4),
          _mood(id: 2, timestamp: DateTime(2026, 7, 15, 16), score: 5),
        ],
        medications: const [],
      );
      expect(d.events.length, 5);
      // 8, 9, 12, 14, 16
      expect(d.events[0].time.hour, 8);
      expect(d.events[1].time.hour, 9);
      expect(d.events[2].time.hour, 12);
      expect(d.events[3].time.hour, 14);
      expect(d.events[4].time.hour, 16);
      // 验证 kind 交叉: 8(ci), 9(mood), 12(ci), 14(ci), 16(mood)
      expect(d.events[0].kind, DayEventKind.checkInNormal);
      expect(d.events[1].kind, DayEventKind.mood);
      expect(d.events[2].kind, DayEventKind.checkInNormal);
      expect(d.events[3].kind, DayEventKind.checkInNormal);
      expect(d.events[4].kind, DayEventKind.mood);
    });

    test('同秒多 events → 稳定 sort 保留插入顺序 (P1-11 RED-2)', () {
      // Dart List.sort 是 stable sort, 同 key 保留原插入顺序
      // checkIn + mood 都在 14:00:00, 验证:
      //   ci(id=1) 先插入 → 输出在前
      //   mood(id=2) 后插入 → 输出在后
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          _ci(id: 1, timestamp: DateTime(2026, 7, 15, 14, 0, 0)),
        ],
        moodEntries: [
          _mood(id: 2, timestamp: DateTime(2026, 7, 15, 14, 0, 0), score: 4),
        ],
        medications: const [],
      );
      expect(d.events.length, 2);
      // 同 time, ci 先插 → 排前
      expect(d.events[0].kind, DayEventKind.checkInNormal);
      expect(d.events[1].kind, DayEventKind.mood);
    });

    test('倒序输入 → 输出正序 (极端 case)', () {
      // caller 完全反着传 — sort 必须能处理
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          _ci(id: 1, timestamp: DateTime(2026, 7, 15, 23)),
          _ci(id: 2, timestamp: DateTime(2026, 7, 15, 18)),
          _ci(id: 3, timestamp: DateTime(2026, 7, 15, 13)),
          _ci(id: 4, timestamp: DateTime(2026, 7, 15, 8)),
          _ci(id: 5, timestamp: DateTime(2026, 7, 15, 3)),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.length, 5);
      for (int i = 0; i < 4; i++) {
        expect(
          d.events[i].time.isBefore(d.events[i + 1].time),
          isTrue,
          reason: 'event[$i] 必须在 event[${i + 1}] 之前',
        );
      }
    });
  });
}
