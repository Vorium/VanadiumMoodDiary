// v0.14 (Round 12A) CheckInEntity / mapper 单元测试
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/check_in/check_in_mapper.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/core/shared/domain_value.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

CheckIn _driftRow({
  int id = 1,
  String type = 'normal',
  DateTime? timestamp,
  int? medicationId,
  String? note,
}) {
  return CheckIn(
    id: id,
    timestamp: timestamp ?? DateTime(2026, 7, 15, 8, 0),
    type: type,
    medicationId: medicationId,
    note: note,
  );
}

void main() {
  group('CheckInToEntity (Drift → Entity)', () {
    test('基础字段正确映射', () {
      final row = _driftRow(id: 42, medicationId: 7, note: '备忘');
      final entity = row.toEntity();
      expect(entity.id, 42);
      expect(entity.timestamp, row.timestamp);
      expect(entity.medicationId, 7);
      expect(entity.note, '备忘');
    });

    test('type string → CheckInType 枚举', () {
      expect(_driftRow(type: 'normal').toEntity().type, CheckInType.normal);
      expect(_driftRow(type: 'temp').toEntity().type, CheckInType.temp);
      expect(_driftRow(type: 'phq9').toEntity().type, CheckInType.phq9);
      expect(_driftRow(type: 'gad7').toEntity().type, CheckInType.gad7);
    });

    test('未知 type 字符串 fallback 到 normal', () {
      // 防止老数据 / 数据损坏时不崩
      expect(_driftRow(type: 'unknown').toEntity().type, CheckInType.normal);
      expect(_driftRow(type: '').toEntity().type, CheckInType.normal);
    });

    test('medicationId / note 可空', () {
      final row = _driftRow(medicationId: null, note: null);
      final entity = row.toEntity();
      expect(entity.medicationId, isNull);
      expect(entity.note, isNull);
    });
  });

  group('CheckInEntityToDrift (Entity → Companion)', () {
    test('type enum → wire string', () {
      final e = CheckInEntity(
        id: 0,
        timestamp: DateTime(2026, 7, 15),
        type: CheckInType.phq9,
      );
      final c = e.toCompanion();
      expect(c.type.value, 'phq9');
    });

    test('可空字段用 Value<T?> 包装', () {
      final e = CheckInEntity(
        id: 0,
        timestamp: DateTime(2026, 7, 15),
        type: CheckInType.temp,
        medicationId: null,
        note: '备注',
      );
      final c = e.toCompanion();
      expect(c.medicationId.value, isNull);
      expect(c.note.value, '备注');
    });
  });

  group('Round trip (Drift → Entity → Drift)', () {
    test('完整数据无丢失', () {
      final original = _driftRow(
        id: 99,
        type: 'temp',
        timestamp: DateTime(2026, 7, 15, 20, 30),
        medicationId: null,
        note: '{"name":"布洛芬","desc":"头痛"}',
      );
      final entity = original.toEntity();
      final companion = entity.toCompanion();
      // 重新构造 Drift row 测试一致性
      final row = CheckIn(
        id: 99,
        timestamp: companion.timestamp.value,
        type: companion.type.value,
        medicationId: companion.medicationId.value,
        note: companion.note.value,
      );
      expect(row.id, original.id);
      expect(row.timestamp, original.timestamp);
      expect(row.type, original.type);
      expect(row.medicationId, original.medicationId);
      expect(row.note, original.note);
    });

    test('所有 4 种 type round-trip', () {
      for (final t in ['normal', 'temp', 'phq9', 'gad7']) {
        final e = _driftRow(type: t).toEntity();
        expect(e.toCompanion().type.value, t);
      }
    });
  });

  group('业务方法', () {
    test('isNormal / isTemp / isAssessment / isPhq9 / isGad7', () {
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.normal,
        ).isNormal,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.normal,
        ).isTemp,
        isFalse,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.temp,
        ).isTemp,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.phq9,
        ).isAssessment,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.gad7,
        ).isAssessment,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.phq9,
        ).isPhq9,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.gad7,
        ).isGad7,
        isTrue,
      );
      expect(
        CheckInEntity(
          id: 1,
          timestamp: DateTime(2026),
          type: CheckInType.normal,
        ).isAssessment,
        isFalse,
      );
    });

    test('isForMedication 严格相等', () {
      final e = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.normal,
        medicationId: 5,
      );
      expect(e.isForMedication(5), isTrue);
      expect(e.isForMedication(4), isFalse);
      expect(e.isForMedication(0), isFalse);
    });

    test('copyWith 基础字段', () {
      final original = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15, 8, 0),
        type: CheckInType.normal,
      );
      final copy = original.copyWith(type: CheckInType.temp);
      expect(copy.type, CheckInType.temp);
      expect(copy.id, original.id);
    });

    test('copyWith 可空字段用 Value<>, 能"清空"', () {
      final original = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15),
        type: CheckInType.normal,
        medicationId: 5,
      );
      final cleared =
          original.copyWith(medicationId: const DomainValue<int?>(null));
      expect(cleared.medicationId, isNull);
    });

    test('copyWith 不传可空字段保留原值', () {
      final original = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026, 7, 15),
        type: CheckInType.normal,
        medicationId: 5,
        note: '备忘',
      );
      final copy = original.copyWith(type: CheckInType.temp);
      expect(copy.medicationId, 5);
      expect(copy.note, '备忘');
    });
  });

  group('等值', () {
    test('== hashCode 字段全等才相等', () {
      final a = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.normal,
      );
      final b = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.normal,
      );
      final c = CheckInEntity(
        id: 1,
        timestamp: DateTime(2026),
        type: CheckInType.temp,
      );
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });
  });

  group('集成：从 DB 读 CheckIn → toEntity → UI 流程', () {
    test('内存 DB 写一条 → 读 → 转 entity → 字段一致', () async {
      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(() async => await db.close());

      final ts = DateTime(2026, 7, 15, 8, 0);
      await db.insertCheckIn(
        CheckInsCompanion.insert(
          timestamp: ts,
          type: 'normal',
          medicationId: const Value(3),
          note: const Value('备忘'),
        ),
      );

      final rows = await db.watchAllCheckIns().first;
      expect(rows.length, 1);

      final entity = rows.first.toEntity();
      expect(entity.timestamp, ts);
      expect(entity.type, CheckInType.normal);
      expect(entity.medicationId, 3);
      expect(entity.note, '备忘');
    });
  });
}
