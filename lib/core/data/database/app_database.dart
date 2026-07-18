import 'package:drift/drift.dart';
// 隐藏 Flutter 的 Table，避免跟 drift 的 Table 冲突
import 'package:flutter/material.dart' hide Table;
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:chroniccare/domain/entities/hour_minute.dart';

import 'package:chroniccare/core/data/database/connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

import 'package:chroniccare/core/data/database/mappers/medication/medication_times.dart';
import 'package:chroniccare/core/data/database/tables/check_in/check_ins.dart';
import 'package:chroniccare/core/data/database/tables/contact/contacts.dart';
import 'package:chroniccare/core/data/database/tables/medication/medications.dart';
import 'package:chroniccare/core/data/database/tables/mood/mood_entries.dart';
import 'package:chroniccare/core/data/database/tables/report/report_histories.dart';
import 'package:chroniccare/core/data/database/tables/user_profile/user_profiles.dart';
import 'package:chroniccare/core/data/database/tables/vent/vent_entries.dart';

part 'app_database.g.dart';

/// 慢病管家数据库
@DriftDatabase(
  tables: [
    CheckIns,
    Medications,
    Contacts,
    UserProfiles,
    ReportHistories,
    MoodEntries,
    VentEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(openConnection());

  /// 测试用构造：传入内存 DB（不经过 path_provider / sqlcipher）
  @visibleForTesting
  AppDatabase.forTesting(super.executor);

  // v0.18 round 18 (P1-15): schemaVersion 6 → 7
  // - mood_entries 加 energy / sleep / anxiety 3 个 nullable column
  // - 老数据自动有 null 3 字段(单 score 模式)
  // - 新数据 4 维全填
  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: 联系人 email 改 phone，medication 加 dosage / dosageUnit / 删 frequencyPerDay
          if (from == 1) {
            // Contacts: 旧 email 数据丢掉（用户主动决定删 email），
            // 删表重建最简单（drift 的 deleteTable 接受表名）
            await m.deleteTable('contacts');
            await m.createTable(contacts);
            // Medications: 加 dosage / dosageUnit
            await m.addColumn(medications, medications.dosage);
            await m.addColumn(medications, medications.dosageUnit);
          }
          // v2 → v3: 新增 report_histories 表（用药报告历史）
          if (from <= 2) {
            await m.createTable(reportHistories);
          }
          // v3 → v4: 新增 mood_entries 表（情绪日记）
          if (from <= 3) {
            await m.createTable(moodEntries);
          }
          // v4 → v5: medications 加续方字段 refillAt + refillReminderDays
          // 旧数据不需要迁移：null = 没设过续方提醒
          if (from <= 4) {
            await m.addColumn(medications, medications.refillAt);
            await m.addColumn(medications, medications.refillReminderDays);
          }
          // v5 → v6: 新增 vent_entries 表（树洞）
          if (from <= 5) {
            await m.createTable(ventEntries);
          }
          // v6 → v7: mood_entries 加 4 维度 3 个新列 (energy / sleep / anxiety)
          // 老数据 3 列默认 null(单 score 模式),新数据 4 维全填
          if (from <= 6) {
            await m.addColumn(moodEntries, moodEntries.energy);
            await m.addColumn(moodEntries, moodEntries.sleep);
            await m.addColumn(moodEntries, moodEntries.anxiety);
          }
        },
        beforeOpen: (details) async {
          // 启用外键
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ============= CheckIns =============
  Stream<List<CheckIn>> watchAllCheckIns() {
    return (select(checkIns)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  /// 监听所有评估记录（type='phq9' / 'gad7'），按时间正序（折线图用）
  Stream<List<CheckIn>> watchAssessments() {
    return (select(checkIns)
          ..where((t) => t.type.equals('phq9') | t.type.equals('gad7'))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  Stream<CheckIn?> watchTodayCheckIn() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(checkIns)
          ..where(
            (t) =>
                t.timestamp.isBiggerOrEqualValue(startOfDay) &
                t.timestamp.isSmallerThanValue(endOfDay) &
                t.type.equals('normal'),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ])
          ..limit(1))
        .watchSingleOrNull();
  }

  Future<int> insertCheckIn(CheckInsCompanion entry) {
    return into(checkIns).insert(entry);
  }

  // ============= Medications =============
  Stream<List<Medication>> watchMedications() {
    return (select(medications)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.startDate),
          ]))
        .watch();
  }

  /// 监听所有 medication（含已停药）
  ///
  /// 给"用药报告"用：用户可能上个月停了一个药，但历史打卡还在，
  /// 报告里不应该把这段历史吃掉。（B3 fix）
  Stream<List<Medication>> watchAllMedicationsIncludingInactive() {
    return (select(medications)
          ..orderBy([
            (t) => OrderingTerm(expression: t.startDate),
          ]))
        .watch();
  }

  Future<int> insertMedication(MedicationsCompanion entry) {
    return into(medications).insert(entry);
  }

  Future<bool> updateMedication(Medication medication) {
    return update(medications).replace(medication);
  }

  Future<int> deleteMedication(int id) {
    return (delete(medications)..where((t) => t.id.equals(id))).go();
  }

  // ============= Contacts =============
  Stream<List<Contact>> watchContacts() {
    return (select(contacts)
          ..where((t) => t.isActive.equals(true))
          ..orderBy([
            (t) => OrderingTerm(expression: t.sortOrder),
          ]))
        .watch();
  }

  Future<int> insertContact(ContactsCompanion entry) {
    return into(contacts).insert(entry);
  }

  Future<bool> updateContact(Contact contact) {
    return update(contacts).replace(contact);
  }

  Future<int> deleteContact(int id) {
    return (delete(contacts)..where((t) => t.id.equals(id))).go();
  }

  // ============= UserProfile =============
  Stream<UserProfile?> watchUserProfile() {
    return (select(userProfiles)..where((t) => t.id.equals(1)))
        .watchSingleOrNull();
  }

  Future<UserProfile?> getUserProfile() {
    return (select(userProfiles)..where((t) => t.id.equals(1)))
        .getSingleOrNull();
  }

  Future<void> upsertUserProfile(UserProfilesCompanion entry) async {
    await into(userProfiles).insertOnConflictUpdate(entry);
  }

  // ============= ReportHistories =============
  /// 监听所有报告历史，按生成时间倒序
  Stream<List<ReportHistory>> watchReportHistories() {
    return (select(reportHistories)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.generatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<int> insertReportHistory(ReportHistoriesCompanion entry) {
    return into(reportHistories).insert(entry);
  }

  Future<int> deleteReportHistory(int id) {
    return (delete(reportHistories)..where((t) => t.id.equals(id))).go();
  }

  Future<int> clearAllReportHistories() {
    return delete(reportHistories).go();
  }

  /// 一次性拉所有报告历史（给导出用）
  Future<List<ReportHistory>> getAllReportHistories() {
    return (select(reportHistories)
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.generatedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .get();
  }

  // ============= MoodEntries =============
  /// 监听所有情绪记录（按时间正序，折线图用）
  Stream<List<MoodEntry>> watchMoodEntries() {
    return (select(moodEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .watch();
  }

  /// 一次性拉所有情绪记录（给导出用）
  Future<List<MoodEntry>> getAllMoodEntries() {
    return (select(moodEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// 监听今日情绪记录（0~N 条）
  Stream<List<MoodEntry>> watchTodayMoodEntries() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(moodEntries)
          ..where(
            (t) =>
                t.timestamp.isBiggerOrEqualValue(startOfDay) &
                t.timestamp.isSmallerThanValue(endOfDay),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insertMoodEntry(MoodEntriesCompanion entry) {
    return into(moodEntries).insert(entry);
  }

  Future<int> deleteMoodEntry(int id) {
    return (delete(moodEntries)..where((t) => t.id.equals(id))).go();
  }

  // ============= VentEntries (v0.15 Round 18 树洞) =============

  /// 监听所有树洞条目（按时间倒序）
  Stream<List<VentEntry>> watchVentEntries() {
    return (select(ventEntries)
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.timestamp, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<int> insertVentEntry(VentEntriesCompanion entry) {
    return into(ventEntries).insert(entry);
  }

  Future<int> deleteVentEntry(int id) {
    return (delete(ventEntries)..where((t) => t.id.equals(id))).go();
  }

  /// 完成首次设置：在同一个事务里写入用户档案、联系人、药物，
  /// 任何一个失败整体回滚，避免半成品数据
  Future<void> saveSetup({
    required String userName,
    required List<({String name, String phone, int sortOrder})> contactList,
    required List<
            ({
              String name,
              double dosage,
              String dosageUnit,
              List<HourMinute> times,
            })>
        medicationList,
  }) async {
    await transaction(() async {
      // upsert user profile（保留 firstLaunchAt）
      final existing = await getUserProfile();
      await into(userProfiles).insertOnConflictUpdate(
        UserProfilesCompanion.insert(
          userName: userName,
          checkInCycleHours: const Value(48),
          firstLaunchAt: existing?.firstLaunchAt ?? DateTime.now(),
        ),
      );

      // insert contacts
      for (final c in contactList) {
        await into(contacts).insert(
          ContactsCompanion.insert(
            name: c.name,
            phone: c.phone,
            sortOrder: Value(c.sortOrder),
          ),
        );
      }

      // insert medications
      // startDate 提到循环外：所有 medication 用同一个时间点，语义更清晰
      final medStart = DateTime.now();
      for (final m in medicationList) {
        await into(medications).insert(
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

  // _encodeTimes 移到了 MedicationRepository.encodeTimes（共用，格式不变）
}
