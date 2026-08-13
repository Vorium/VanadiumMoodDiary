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
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';

/// 首次设置提交 + 清空数据 (从 AppDatabase 抽出的业务编排)
class SetupCommitter {
  final AppDatabase db;

  const SetupCommitter(this.db);

  /// Complete first-time setup: in one transaction write user profile, contacts, medications,
  /// any failure rolls back entirely, avoid half-baked data
  ///
  /// v0.27 round 68 (CC-1 fix, PIPL §13 separate consent): add `contactConsents` parameter
  /// (same length as `contactList`). Each contact filled in setup phase must have ConsentArtifact,
  /// otherwise contact won't be written (4 consent columns required). setup_page must, before calling completeSetup,
  /// show ConsentDialog for each contact to get consent.
  Future<void> completeSetup({
    required String userName,
    required List<({String name, String phone, int sortOrder})> contactList,
    required List<ConsentArtifact> contactConsents,
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

      // insert contacts (R68 CC-1: PIPL §13 separate consent, 4 consent columns required)
      // v0.32 round 8 (R111 E5 fix): assert → release 安全 check。
      // assert 只 debug 生效; release 长度不一致会 RangeError (fail-fast 但无
      // 清晰错误) 或静默漏 consent (PIPL §13 留痕断裂)。改: 不一致时抛
      // StateError (release 也生效, 错误信息清晰)。
      if (contactList.length != contactConsents.length) {
        throw StateError(
          'contactList (${contactList.length}) 与 contactConsents '
          '(${contactConsents.length}) 长度不一致 — setup_page 必须为每个 '
          '联系人弹 ConsentDialog (PIPL §13)',
        );
      }
      for (var i = 0; i < contactList.length; i++) {
        final c = contactList[i];
        final consent = contactConsents[i];
        await db.into(db.contacts).insert(
              ContactsCompanion.insert(
                name: c.name,
                phone: c.phone,
                sortOrder: Value(c.sortOrder),
                // R68 CC-1 fix: 4 consent columns written from setup phase
                // (previously left empty → PIPL §13 technically invalid, §47 query right invalid)
                consentAt: Value(consent.grantedAt),
                consentKind: Value(consent.kind.name),
                consentBy: Value(consent.grantedBy),
                consentVersion: Value(consent.version),
              ),
            );
      }

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
