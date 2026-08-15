// v0.32 架构批 2 (AR-19): SetupCommitter — 首次设置提交 + 清空数据编排
//
// 背景 (R112 top-level-arch 报告 AR-19):
//   app_database.dart 420-519 行的 saveSetup (1 transaction 写 3 实体 +
//   PIPL §13 consent 长度校验) 和 clearAllUserData 是标准 business
//   orchestration, 放 DB 门面违反单一职责。但它们也是唯一保证 "setup
//   原子性" 的位置。
//
// 拆法 (跟 R57 safety_watch / R58 medication_report 同款渐进 facade 模式):
//   - SetupCommitter(AppDatabase db) 收编 2 个编排方法, transaction 语义
//     与 StateError 校验原样保留 (SP-R112-04 测试跟随迁移)
//   - app_database.dart 只留 DAO facade + schema/migration
//   - caller (setup_page_state / clear_tile) 构造
//     `SetupCommitter(ref.read(databaseProvider))` 调用, provider 接线见
//     fix-reports/09-architecture-batch2.md 报告
import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/medication/medication_times.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';

/// 首次设置提交 + 清空数据 (从 AppDatabase 抽出的业务编排)
class SetupCommitter {
  final AppDatabase db;

  const SetupCommitter(this.db);

  /// Complete first-time setup: in one transaction write user profile, medications,
  /// any failure rolls back entirely, avoid half-baked data
  ///
  /// 1.1.0 round 4: contacts 写入段整摘 (失联通信业务暂停定版) —
  /// contactList / contactConsents 参数 + PIPL §13 consent 长度校验删除。
  Future<void> completeSetup({
    required String userName,
    required List<
            ({
              String name,
              double dosage,
              String dosageUnit,
              List<HourMinute> times,
            })>
        medicationList,
  }) async {
    // v0.21 (P1-2 fix): take now once at function entry, avoid crossing midnight between 2 awaits
    // firstLaunchAt and medStart used different DateTime.now() → same setup
    // when crossing 0:00 at 23:59:59.x, two timestamps differ by 1 day.
    final now = DateTime.now();
    await db.transaction(() async {
      // upsert user profile (preserve firstLaunchAt)
      final existing = await db.userProfileDao.get();
      await db.into(db.userProfiles).insertOnConflictUpdate(
            UserProfilesCompanion.insert(
              // v0.21 Round 23 (P1-24): userName change to nullable
              // accept null, UI 'I am' falls back to 'Friend' or empty
              userName: Value(userName),
              checkInCycleHours: const Value(48),
              firstLaunchAt: existing?.firstLaunchAt ?? now,
            ),
          );

      // insert medications
      // startDate uses the same now, ensure firstLaunchAt and medStart consistent
      final medStart = now;
      for (final m in medicationList) {
        await db.into(db.medications).insert(
              MedicationsCompanion.insert(
                name: m.name,
                dosage: m.dosage,
                dosageUnit: m.dosageUnit,
                timesJson: Value(encodeTimes(m.times)),
                startDate: medStart,
              ),
            );
      }
    });
  }

  /// Clear all user data tables (PIPL §47 active delete right)
  ///
  /// **not** reset schemaVersion, **not** delete DB file — keep table structure, only clear data.
  /// Caller must handle follow-up (jump to setup / notify user).
  ///
  /// Not deleted: none (user profile / contacts / medications / check-ins / reports / mood / vent all can be cleared).
  /// Kept: none (AppDatabase has no non-user tables).
  ///
  /// **not** clear vent audio files (files not in DB), caller must call itself
  /// [VentAudioStorage.deleteAll] to delete files.
  Future<void> clearAllUserData() async {
    await db.transaction(() async {
      for (final table in db.allTables) {
        await db.delete(table).go();
      }
    });
  }
}
