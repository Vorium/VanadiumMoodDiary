// v0.14 (Round 10) DayDetailCalculator 纯函数测试
// v0.14 (Round 12A) 4 层架构：CheckInEntity / MoodEntryEntity
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/logic/day_detail.dart';
import 'package:flutter_test/flutter_test.dart';

MedicationEntity med({
  int id = 1,
  String name = '氟西汀',
  double dosage = 40,
  String unit = 'mg',
  List<HourMinute> times = const [HourMinute(hour: 8, minute: 0)],
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: unit,
    times: times,
    startDate: DateTime(2026, 1, 1),
    endDate: null,
    isActive: true,
    refillAt: null,
    refillReminderDays: 7,
  );
}

CheckInEntity ci({
  required int id,
  required DateTime timestamp,
  String type = 'normal',
  int? medicationId,
  String? note,
}) {
  return CheckInEntity(
    id: id,
    timestamp: timestamp,
    type: CheckInType.fromWire(type),
    medicationId: medicationId,
    note: note,
  );
}

MoodEntryEntity mood({
  required int id,
  required DateTime timestamp,
  required int score,
  List<String> tags = const [],
  String? note,
}) {
  final tagsJson = tags.isEmpty
      ? '[]'
      : '[${tags.map((t) => '"$t"').join(',')}]';
  return MoodEntryEntity(
    id: id,
    timestamp: timestamp,
    score: score,
    tagsJson: tagsJson,
    note: note,
  );
}

void main() {
  group('DayDetailCalculator.fromData', () {
    test('完全空：events=[]', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: const [],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events, isEmpty);
      expect(d.isEmpty, isTrue);
      expect(d.totalCheckIns, 0);
      expect(d.totalMoodEntries, 0);
      expect(d.totalAssessments, 0);
      expect(d.bestMoodScore, isNull);
      expect(d.worstMoodScore, isNull);
      expect(d.hasNormalCheckIn, isFalse);
    });

    test('跨日截断：前一天的打卡不算', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 14, 23, 59)), // 前一天
          ci(id: 2, timestamp: DateTime(2026, 7, 15, 0, 0)), // 当天 0 点
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.length, 1);
      expect(d.events.first.time, DateTime(2026, 7, 15, 0, 0));
    });

    test('跨日截断：次日凌晨 0 点不算当天', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 23, 59, 59)), // 当天
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.length, 1);
    });

    test('normal 打卡：算入 totalCheckIns', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 8), type: 'normal'),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.totalCheckIns, 1);
      expect(d.hasNormalCheckIn, isTrue);
    });

    test('temp 打卡：独立计数', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 8), type: 'normal'),
          ci(
            id: 2,
            timestamp: DateTime(2026, 7, 15, 14),
            type: 'temp',
            note: '{"name":"布洛芬","desc":"头痛"}',
          ),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.totalCheckIns, 1);
      expect(d.totalTempMeds, 1);
      // temp 事件的 title 包含药名
      final temp = d.events.firstWhere((e) => e.kind == DayEventKind.checkInTemp);
      expect(temp.title, '临时 · 布洛芬');
    });

    test('temp 打卡老格式 "name: desc" 也能解析', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 14),
            type: 'temp',
            note: '布洛芬: 头痛',
          ),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.first.title, '临时 · 布洛芬');
      expect(d.events.first.subtitle, contains('头痛'));
    });

    test('评估 phq9：解析 total 字段', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 21),
            type: 'phq9',
            note: '{"scale":"phq9","scores":[0,0,0,0,0,0,0,0,0],"total":0}',
          ),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.totalAssessments, 1);
      final a = d.events.first;
      expect(a.kind, DayEventKind.assessment);
      expect(a.title, 'PHQ-9 抑郁筛查');
      expect(a.assessmentTotal, 0);
    });

    test('gad7 评估：title 正确', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15),
            type: 'gad7',
            note: '{"scale":"gad7","scores":[1],"total":1}',
          ),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.first.title, 'GAD-7 焦虑筛查');
    });

    test('medicationId 反查 name', () {
      final m = med(id: 5, name: '奥氮平');
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 8),
            type: 'normal',
            medicationId: 5,
          ),
        ],
        moodEntries: const [],
        medications: [m],
      );
      expect(d.events.first.title, '打卡 · 奥氮平');
      expect(d.events.first.medicationName, '奥氮平');
    });

    test('medicationId 在 medications 列表里找不到 → 退化为"每日打卡"', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 8),
            type: 'normal',
            medicationId: 999,
          ),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.first.title, '每日打卡');
    });

    test('情绪记录：emoji + 标签 + 备注', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: const [],
        moodEntries: [
          mood(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 21, 30),
            score: 2,
            tags: ['焦虑', '失眠'],
            note: '工作压力大',
          ),
        ],
        medications: const [],
      );
      expect(d.totalMoodEntries, 1);
      expect(d.bestMoodScore, 2);
      expect(d.worstMoodScore, 2);
      final m = d.events.first;
      expect(m.kind, DayEventKind.mood);
      expect(m.title, contains('😟'));
      expect(m.title, contains('差'));
      expect(m.subtitle, contains('焦虑'));
      expect(m.subtitle, contains('失眠'));
      expect(m.subtitle, contains('工作压力大'));
    });

    test('多条情绪：bestMoodScore / worstMoodScore', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: const [],
        moodEntries: [
          mood(id: 1, timestamp: DateTime(2026, 7, 15, 8), score: 2),
          mood(id: 2, timestamp: DateTime(2026, 7, 15, 12), score: 5),
          mood(id: 3, timestamp: DateTime(2026, 7, 15, 20), score: 3),
        ],
        medications: const [],
      );
      expect(d.totalMoodEntries, 3);
      expect(d.bestMoodScore, 5);
      expect(d.worstMoodScore, 2);
    });

    test('事件按时间正序', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 22), type: 'temp',
            note: '{"name":"晚"}'),
          ci(id: 2, timestamp: DateTime(2026, 7, 15, 8), type: 'normal'),
        ],
        moodEntries: [
          mood(id: 3, timestamp: DateTime(2026, 7, 15, 12), score: 4),
        ],
        medications: const [],
      );
      expect(d.events.length, 3);
      expect(d.events[0].time.hour, 8);  // normal 8:00
      expect(d.events[1].time.hour, 12); // mood 12:00
      expect(d.events[2].time.hour, 22); // temp 22:00
    });

    test('混合：normal + temp + assessment + mood 全部识别', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 8), type: 'normal'),
          ci(
            id: 2,
            timestamp: DateTime(2026, 7, 15, 14),
            type: 'temp',
            note: '{"name":"布洛芬"}',
          ),
          ci(
            id: 3,
            timestamp: DateTime(2026, 7, 15, 21),
            type: 'phq9',
            note: '{"scale":"phq9","scores":[1,1,0,0,0,0,0,0,0],"total":2}',
          ),
        ],
        moodEntries: [
          mood(id: 4, timestamp: DateTime(2026, 7, 15, 12), score: 4),
        ],
        medications: const [],
      );
      expect(d.events.length, 4);
      expect(d.totalCheckIns, 1);
      expect(d.totalTempMeds, 1);
      expect(d.totalAssessments, 1);
      expect(d.totalMoodEntries, 1);
    });

    test('空 note 的 temp：title 退化', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(
            id: 1,
            timestamp: DateTime(2026, 7, 15, 14),
            type: 'temp',
            note: '',
          ),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.first.title, '临时吃药');
    });

    test('note 为 null 的 temp：title 退化', () {
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 14), type: 'temp'),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.events.first.title, '临时吃药');
    });

    test('date 接受任意时间：内部取日期', () {
      // 传入 15 号 23:59 → 应该取 15 号
      final d = DayDetailCalculator.fromData(
        date: DateTime(2026, 7, 15, 23, 59),
        checkIns: [
          ci(id: 1, timestamp: DateTime(2026, 7, 15, 8), type: 'normal'),
        ],
        moodEntries: const [],
        medications: const [],
      );
      expect(d.date, DateTime(2026, 7, 15));
    });
  });
}
