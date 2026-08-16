// v1.1.0 R113 wave 2 (BUG 1): refillReminderDays=0 让全部续方提醒静默失效
//
// 背景: 导入校验允许 refillReminderDays min:0 (import_entities.dart),
// 而 RefillScheduler.computeRefillFireTime 对 <1 抛 ArgumentError,
// 异常传播到 ScheduleRefillReminderUseCase → rescheduleRefillReminders 整体
// abort → AppRoot catch 吞掉 → 所有续方提醒静默死掉 (一个 0 天脏数据
// 杀死全部提醒)。
//
// defense-in-depth 修法 (双保险):
// 1. 导入侧 clamp: JSON refillReminderDays <1 → 存 1 (validateIntOr 保持
//    min:0 接脏数据, 再显式 clamp ≥1, 保留用户"续方当天提醒"意图)
// 2. 调度侧不抛: computeRefillFireTime 对 <1 返回 null (caller 跳过该
//    med, 不 abort 整个重排)
//
// 覆盖:
// 1. 纯函数: reminderDays=0 / -1 → null (不再 ArgumentError)
// 2. 导入 round-trip: refillReminderDays:0 JSON → success + DB 值 == 1
// 3. 编排: clamp 后的 med 走 ScheduleRefillReminderUseCase → fireAt 非 null
//    (提醒仍会被调度); 0 天 med 直接走 usecase → fireAt null (跳过不 abort)

import 'dart:convert';
import 'dart:typed_data';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_import_pipeline.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/refill_scheduler.dart';
import 'package:chroniccare/domain/usecases/schedule_refill_reminder.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RefillScheduler.computeRefillFireTime — <1 不抛, 返 null', () {
    test('reminderDays=0 → null (不再 ArgumentError)', () {
      expect(
        RefillScheduler.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: 0,
        ),
        isNull,
      );
    });

    test('reminderDays 负数 → null (不再 ArgumentError)', () {
      expect(
        RefillScheduler.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: -1,
        ),
        isNull,
      );
    });

    test('reminderDays>=1 行为不变: 7 → refillAt - 7 天 9:00', () {
      expect(
        RefillScheduler.computeRefillFireTime(
          refillAt: DateTime(2026, 9, 15),
          reminderDays: 7,
        ),
        DateTime(2026, 9, 8, 9, 0),
      );
    });
  });

  group('import refillReminderDays=0 — clamp 到 1, 提醒仍可调度', () {
    late AppDatabase db;
    late ExportOrchestrator orch;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      final enc = EncryptionService();
      enc.setKeyForTest(Uint8List.fromList(List<int>.filled(32, 0x42)));
      orch = ExportOrchestrator(
        db: db,
        cryptoService: ExportCryptoService(enc),
        audioService: const ExportAudioService(),
        schemaService: const ExportSchemaService(),
      );
    });

    tearDown(() async {
      await db.close();
    });

    Map<String, dynamic> medJson({required int refillReminderDays}) => {
          'name': '舍曲林',
          'dosageUnit': 'mg',
          'dosage': 50.0,
          'startDate': '2026-06-01T00:00:00.000',
          'refillAt': '2026-09-15T00:00:00.000',
          'refillReminderDays': refillReminderDays,
          'isActive': true,
        };

    Future<Map<String, dynamic>> importMed(int days) async {
      final json = jsonEncode({
        'version': ExportSchemaService.currentVersion,
        'profile': <String, dynamic>{},
        'medications': [medJson(refillReminderDays: days)],
      });
      return jsonDecode(json) as Map<String, dynamic>;
    }

    test('refillReminderDays=0 → success + DB 值 clamp 到 1', () async {
      final data = await importMed(0);
      final result = await runImportFromJson(orch, jsonEncode(data));

      expect(result.success, isTrue);
      expect(result.medicationCount, 1);

      final rows = await db.select(db.medications).get();
      expect(rows, hasLength(1));
      expect(rows.single.refillReminderDays, 1);
    });

    test('clamp 后的 med 走 usecase → fireAt 非 null (提醒仍会被调度)', () async {
      final data = await importMed(0);
      final result = await runImportFromJson(orch, jsonEncode(data));
      expect(result.success, isTrue);

      final rows = await db.select(db.medications).get();
      final entity = MedicationEntity(
        id: rows.single.id,
        name: rows.single.name,
        dosage: rows.single.dosage,
        dosageUnit: DosageUnit.fromId(rows.single.dosageUnit),
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: rows.single.startDate,
        isActive: rows.single.isActive,
        refillAt: rows.single.refillAt,
        refillReminderDays: rows.single.refillReminderDays,
      );
      expect(entity.refillReminderDays, 1);

      const usecase = ScheduleRefillReminderUseCase();
      final schedules = usecase(
        medications: [entity],
        now: DateTime(2026, 8, 1),
      );
      expect(schedules.single.fireAt, isNotNull);
    });

    test('0 天 med 直接走 usecase → fireAt null (跳过, 不 abort 整个重排)', () {
      const usecase = ScheduleRefillReminderUseCase();
      final entity = MedicationEntity(
        id: 1,
        name: 'test',
        dosage: 1.0,
        dosageUnit: DosageUnit.mg,
        times: const [HourMinute(hour: 8, minute: 0)],
        startDate: DateTime(2026, 6, 1),
        isActive: true,
        refillAt: DateTime(2026, 9, 15),
        refillReminderDays: 0,
      );
      final schedules = usecase(
        medications: [entity],
        now: DateTime(2026, 8, 1),
      );
      expect(schedules.single.fireAt, isNull);
    });
  });
}
