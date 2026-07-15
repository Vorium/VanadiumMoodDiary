// v0.13 (Round 11) MedicationEntity / MedicationMapper 单元测试
import 'package:chroniccare/data/database/app_database.dart';
import 'package:chroniccare/data/database/medication_mapper.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Medication _driftRow({
  int id = 1,
  String name = '氟西汀',
  double dosage = 40,
  String unit = 'mg',
  List<TimeOfDay> times = const [TimeOfDay(hour: 8, minute: 0)],
  DateTime? refillAt,
  int refillReminderDays = 7,
  bool isActive = true,
  DateTime? endDate,
}) {
  return Medication(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: unit,
    timesJson: '[${times.map((t) => '{"h":${t.hour},"m":${t.minute}}').join(',')}]',
    startDate: DateTime(2026, 1, 1),
    endDate: endDate,
    isActive: isActive,
    refillAt: refillAt,
    refillReminderDays: refillReminderDays,
  );
}

MedicationEntity _entity({
  int id = 1,
  String name = '氟西汀',
  double dosage = 40,
  String unit = 'mg',
  List<TimeOfDay> times = const [TimeOfDay(hour: 8, minute: 0)],
  DateTime? refillAt,
  int refillReminderDays = 7,
  bool isActive = true,
  DateTime? endDate,
  DateTime? startDate,
}) {
  return MedicationEntity(
    id: id,
    name: name,
    dosage: dosage,
    dosageUnit: unit,
    times: times,
    startDate: startDate ?? DateTime(2026, 1, 1),
    endDate: endDate,
    isActive: isActive,
    refillAt: refillAt,
    refillReminderDays: refillReminderDays,
  );
}

void main() {
  group('MedicationToEntity (Drift → Entity)', () {
    test('基础字段正确映射', () {
      final row = _driftRow();
      final entity = row.toEntity();
      expect(entity.id, row.id);
      expect(entity.name, row.name);
      expect(entity.dosage, row.dosage);
      expect(entity.dosageUnit, row.dosageUnit);
      expect(entity.isActive, row.isActive);
      expect(entity.refillReminderDays, row.refillReminderDays);
    });

    test('timesJson 解析为 List<TimeOfDay>', () {
      final row = _driftRow(times: const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 20, minute: 30),
      ]);
      final entity = row.toEntity();
      expect(entity.times.length, 2);
      expect(entity.times[0].hour, 8);
      expect(entity.times[0].minute, 0);
      expect(entity.times[1].hour, 20);
      expect(entity.times[1].minute, 30);
    });

    test('空 timesJson → times = const []', () {
      final row = Medication(
        id: 1,
        name: 'X',
        dosage: 1,
        dosageUnit: 'mg',
        timesJson: '[]',
        startDate: DateTime(2026, 1, 1),
        endDate: null,
        isActive: true,
        refillAt: null,
        refillReminderDays: 7,
      );
      expect(row.toEntity().times, isEmpty);
    });

    test('续方字段（refillAt / refillReminderDays）保留', () {
      final row = _driftRow(
        refillAt: DateTime(2026, 7, 25),
        refillReminderDays: 14,
      );
      final entity = row.toEntity();
      expect(entity.refillAt, DateTime(2026, 7, 25));
      expect(entity.refillReminderDays, 14);
    });
  });

  group('MedicationEntityToDrift (Entity → Drift row)', () {
    test('基础字段正确', () {
      final entity = _entity();
      final row = entity.toDriftRow();
      expect(row.id, entity.id);
      expect(row.name, entity.name);
      expect(row.dosage, entity.dosage);
      expect(row.dosageUnit, entity.dosageUnit);
      expect(row.isActive, entity.isActive);
      expect(row.refillReminderDays, entity.refillReminderDays);
    });

    test('times 序列化为 JSON', () {
      final entity = _entity(times: const [
        TimeOfDay(hour: 8, minute: 0),
        TimeOfDay(hour: 20, minute: 30),
      ]);
      final row = entity.toDriftRow();
      expect(row.timesJson, '[{"h":8,"m":0},{"h":20,"m":30}]');
    });

    test('空 times → "[]"', () {
      final entity = _entity(times: const []);
      expect(entity.toDriftRow().timesJson, '[]');
    });
  });

  group('Round trip (Drift → Entity → Drift)', () {
    test('完整数据无丢失', () {
      final original = _driftRow(
        id: 42,
        name: '舍曲林',
        dosage: 50,
        unit: 'mg',
        times: const [
          TimeOfDay(hour: 8, minute: 0),
          TimeOfDay(hour: 20, minute: 0),
        ],
        refillAt: DateTime(2026, 8, 1),
        refillReminderDays: 14,
      );
      final roundTripped = original.toEntity().toDriftRow();
      expect(roundTripped.id, original.id);
      expect(roundTripped.name, original.name);
      expect(roundTripped.dosage, original.dosage);
      expect(roundTripped.dosageUnit, original.dosageUnit);
      expect(roundTripped.timesJson, original.timesJson);
      expect(roundTripped.isActive, original.isActive);
      expect(roundTripped.refillAt, original.refillAt);
      expect(roundTripped.refillReminderDays, original.refillReminderDays);
    });
  });

  group('MedicationEntity 业务方法', () {
    test('isInUse = isActive', () {
      expect(_entity(isActive: true).isInUse, isTrue);
      expect(_entity(isActive: false).isInUse, isFalse);
    });

    test('hasRefill: refillAt != null', () {
      expect(_entity().hasRefill, isFalse);
      expect(_entity(refillAt: DateTime(2026, 7, 25)).hasRefill, isTrue);
    });

    test('isRefillOverdue: refillAt 过了"次日" → true', () {
      // 7/15 = today
      final now = DateTime(2026, 7, 15, 14, 0);
      // 7/14 (昨天) → 已过期
      expect(
        _entity(refillAt: DateTime(2026, 7, 14))
            .isRefillOverdue(now),
        isTrue,
      );
      // 7/15 (今天) → 还没过期（refill day 仍算"今天"）
      expect(
        _entity(refillAt: DateTime(2026, 7, 15))
            .isRefillOverdue(now),
        isFalse,
      );
      // 7/16 (明天) → 还没过期
      expect(
        _entity(refillAt: DateTime(2026, 7, 16))
            .isRefillOverdue(now),
        isFalse,
      );
      // null = 从未过期
      expect(_entity().isRefillOverdue(now), isFalse);
    });

    test('isRefillOverdue: 不依赖时分秒，只比日期', () {
      // refillAt = 7/15 23:59:59，now = 7/15 00:00:00
      // 实际: 7/15 都算今天，还没过期
      final now = DateTime(2026, 7, 15, 0, 0, 0);
      expect(
        _entity(refillAt: DateTime(2026, 7, 15, 23, 59, 59))
            .isRefillOverdue(now),
        isFalse,
      );
    });

    test('isInRefillWindow: [refillAt - reminderDays, refillAt 当天] 都算窗口', () {
      // v0.14 (Round 13 audit) 修：refill day 整天算窗口（之前是 refillAt 00:00 排除在外）
      final refillAt = DateTime(2026, 7, 25);
      // 窗口起点 = 7/18 (refillAt - 7)
      // 窗口外（之前）
      expect(
        _entity(refillAt: refillAt, refillReminderDays: 7)
            .isInRefillWindow(DateTime(2026, 7, 17, 14, 0)),
        isFalse,
      );
      // 窗口起点 = 7/18 → 在窗口
      expect(
        _entity(refillAt: refillAt, refillReminderDays: 7)
            .isInRefillWindow(DateTime(2026, 7, 18, 14, 0)),
        isTrue,
      );
      // 窗口内
      expect(
        _entity(refillAt: refillAt, refillReminderDays: 7)
            .isInRefillWindow(DateTime(2026, 7, 24, 14, 0)),
        isTrue,
      );
      // refill day 整天算窗口（之前排除）
      expect(
        _entity(refillAt: refillAt, refillReminderDays: 7)
            .isInRefillWindow(DateTime(2026, 7, 25, 14, 0)),
        isTrue,
      );
      // 窗口外（之后）
      expect(
        _entity(refillAt: refillAt, refillReminderDays: 7)
            .isInRefillWindow(DateTime(2026, 7, 26, 14, 0)),
        isFalse,
      );
    });

    test('isInRefillWindow: 边界 — windowStart 当天算 in', () {
      // windowStart = 7/18，now = 7/18 00:00 → 算 in
      final refillAt = DateTime(2026, 7, 25);
      expect(
        _entity(refillAt: refillAt, refillReminderDays: 7)
            .isInRefillWindow(DateTime(2026, 7, 18, 0, 0, 0)),
        isTrue,
      );
    });

    test('copyWith: 基础字段', () {
      final original = _entity(name: 'A');
      final copy = original.copyWith(name: 'B', dosage: 100);
      expect(copy.name, 'B');
      expect(copy.dosage, 100);
      expect(copy.id, original.id); // 未改
    });

    test('copyWith: 可空字段用 Value<>, 能"清空" endDate', () {
      final original = _entity(endDate: DateTime(2026, 7, 15));
      // 传 Value(null) 应该清空
      final cleared = original.copyWith(endDate: const Value(null));
      expect(cleared.endDate, isNull);
    });

    test('copyWith: 不传 endDate 应保留原值', () {
      final original = _entity(endDate: DateTime(2026, 7, 15));
      // 不传 endDate → 保留
      final copy = original.copyWith(name: 'B');
      expect(copy.endDate, DateTime(2026, 7, 15));
    });

    test('copyWith: 不传 refillAt 应保留原值', () {
      final original = _entity(refillAt: DateTime(2026, 7, 25));
      final copy = original.copyWith(name: 'B');
      expect(copy.refillAt, DateTime(2026, 7, 25));
    });

    test('copyWith: 传 Value(refillAt: null) 应清空', () {
      final original = _entity(refillAt: DateTime(2026, 7, 25));
      final cleared = original.copyWith(refillAt: const Value(null));
      expect(cleared.refillAt, isNull);
    });

    test('==, hashCode: 字段全等才相等', () {
      final a = _entity(id: 1, name: 'A');
      final b = _entity(id: 1, name: 'A');
      final c = _entity(id: 1, name: 'B');
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test('==, hashCode: times 列表也参与比较', () {
      final a = _entity(times: const [TimeOfDay(hour: 8, minute: 0)]);
      final b = _entity(times: const [TimeOfDay(hour: 8, minute: 0)]);
      final c = _entity(times: const [TimeOfDay(hour: 8, minute: 30)]);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('集成：从 DB 读 Medication → toEntity → UI 流程', () {
    test('内存 DB 写一条 → 读 → 转 entity → 字段一致', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => await db.close());

      await db.insertMedication(MedicationsCompanion.insert(
        name: '氟西汀',
        dosage: 40,
        dosageUnit: 'mg',
        timesJson: const Value('[{"h":8,"m":0},{"h":20,"m":0}]'),
        startDate: DateTime(2026, 1, 1),
      ));

      final rows = await db.watchAllMedicationsIncludingInactive().first;
      expect(rows.length, 1);

      final entity = rows.first.toEntity();
      expect(entity.name, '氟西汀');
      expect(entity.dosage, 40);
      expect(entity.dosageUnit, 'mg');
      expect(entity.times.length, 2);
      expect(entity.times[0].hour, 8);
      expect(entity.times[1].hour, 20);
    });
  });
}
