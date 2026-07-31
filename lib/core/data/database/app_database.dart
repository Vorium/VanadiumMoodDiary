import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;

import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';

import 'package:chroniccare/core/data/database/connection/connection.dart'
    if (dart.library.html) 'connection/web.dart'
    if (dart.library.io) 'connection/native.dart';

import 'dart:convert';

import 'package:chroniccare/core/data/database/daos/check_in_dao.dart';
import 'package:chroniccare/core/data/database/daos/contact_dao.dart';
import 'package:chroniccare/core/data/database/daos/medication_dao.dart';
import 'package:chroniccare/core/data/database/daos/mood_dao.dart';
import 'package:chroniccare/core/data/database/daos/report_dao.dart';
import 'package:chroniccare/core/data/database/daos/user_profile_dao.dart';
import 'package:chroniccare/core/data/database/daos/vent_dao.dart';
import 'package:chroniccare/core/data/database/mappers/medication/medication_times.dart';
import 'package:chroniccare/core/data/database/tables/check_in/check_ins.dart';
import 'package:chroniccare/core/data/database/tables/contact/contacts.dart';
import 'package:chroniccare/core/data/database/tables/medication/medications.dart';
import 'package:chroniccare/core/data/database/tables/mood/mood_entries.dart';
import 'package:chroniccare/core/data/database/tables/report/report_histories.dart';
import 'package:chroniccare/core/data/database/tables/user_profile/user_profiles.dart';
import 'package:chroniccare/core/data/database/tables/vent/vent_entries.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';

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
  // v0.18 round 18 (P2-P0-8): schemaVersion 7 → 8
  // - 4 个查询索引(check_ins / mood_entries / vent_entries / medications)
  // v0.21 round 22 (P0-1 修复): schemaVersion 8 → 9
  // - vent_entries 加 contentTextEnc (BLOB, AES-256 加密) 列
  // - 一次性把旧 contentText (TEXT, 明文) 全部加密写回新列
  // - 旧 contentText 列保留(代码层不再用),后续 v10+ 彻底 DROP
  // v0.21 round 22 (P1-22 修复): schemaVersion 9 → 10
  // - user_profiles 加 4 个 consent 字段
  // v0.21 round 23 (P1-24 修复): schemaVersion 10 → 11
  // - user_profiles.userName 改 nullable
  // - report_histories.userName 改 nullable
  // - 老数据 "" 仍写回 "" (空字符串),但允许 null
  // - 实际: drift 的 alter table 不支持改列属性,SQLite 也没有 ALTER COLUMN
  //   所以这条变更**只在 createAll 里生效** (新装用户自动是新 schema)
  //   升级用户 schema 没改,代码层判断 if (userName?.isNotEmpty ?? false)
  //   兼容老数据 "" 和新数据 null
  // v0.23 round 31 (P0 新功能): schemaVersion 11 → 12
  // - mood_entries 加 audioPath / audioTranscript / audioDurationMs 3 个 nullable 列
  // - 老数据自动为 null(纯文字模式行为不变)
  // - audioPath 引用独立 mood_audio/ 目录的加密 .m4a.enc 文件
  //
  // v0.23 round 43: schemaVersion 12 → 13
  // - check_ins 加 medicationId 索引（优化药物打卡查询）
  //
  // v0.23 round 44: schemaVersion 13 → 14
  // - contacts 加 (is_active, sort_order) 复合索引
  // - report_histories 加 generated_at 索引
  //
  // v0.27 round 63 (P0-2 修复): schemaVersion 14 → 15
  // - contacts 加 4 个 consent 字段 (PIPL §13 留痕要求)
  // - 4 字段全部 nullable,旧数据自动为 null
  // - 老数据 (schemaVersion <= 14) 的联系人 "consent 历史" 只在 piiSafeLog
  //   (R62 working tree 状态), DB 落库是这次新加。考虑 v1.0 法务过审
  //   时是否给老用户"重新同意"流程 (本批不做, 留 R64+ 评估)
  @override
  int get schemaVersion => 15;

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
          // v7 → v8: 加 4 个查询索引,大表(1 年+ 用户)避免全表扫
          // - check_ins (timestamp, type) — 覆盖 streak / 评估 / watchAll
          // - mood_entries (timestamp) — 按天/月查情绪
          // - vent_entries (timestamp DESC) — 树洞 watchAll 倒序
          // - medications (isActive, startDate) — watchAll 过滤 + 续方排序
          if (from <= 7) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_checkin_ts_type ON check_ins(timestamp, type)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_mood_ts ON mood_entries(timestamp)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_vent_ts ON vent_entries(timestamp DESC)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_med_active_start ON medications(is_active, start_date)',
            );
          }
          // v8 → v9: vent 文字字段级加密 (P0-1 修复)
          // - 加 contentTextEnc (BLOB nullable) 列
          // - 读旧 contentText 加密写回新列
          // - 旧 contentText 列保留(代码层不再用),后续 v10+ 彻底清理
          if (from <= 8) {
            await m.addColumn(ventEntries, ventEntries.contentTextEnc);
            // 一次性加密所有历史 vent 文字
            // 关键: 必须用 drift 的 typed select(ventEntries),不能用 raw query —
            // raw query 走的是新 schema,row 拿不到 contentText 字段
            final oldRows = await select(ventEntries).get();
            final enc = EncryptionService();
            for (final row in oldRows) {
              try {
                final oldText = row.contentText;
                if (oldText == null || oldText.isEmpty) continue;
                final encrypted =
                    await enc.encrypt(Uint8List.fromList(utf8.encode(oldText)));
                await (update(ventEntries)..where((t) => t.id.equals(row.id)))
                    .write(
                  VentEntriesCompanion(
                    contentTextEnc: Value(encrypted),
                  ),
                );
              } catch (e, st) {
                // v0.27 round 63 (P1-7 修复): 走 swallowError 集中器
                // (R39 P1-10 模式), 替代全 lib 唯一 1 处 `catch (e) {}`
                // 完全静默。dev 模式 devtools / `flutter logs` 看得到。
                // 单条加密失败不阻塞整个升级, 该行 contentTextEnc 保持 null,
                // 用户打开该条树洞时 VentMapper.toEntity 会兜底显示空内容。
                swallowError(
                  where: 'app_database.v8v9_vent_encrypt_fail',
                  error: e,
                  stack: st,
                  note:
                      'ventId=${row.id} contentText 加密失败, contentTextEnc 保持 null',
                );
              }
            }
          }
          // v9 → v10: UserProfile 加 4 个 consent 字段 (P1-22 修复)
          // - 4 字段都 nullable,旧数据自动为 null
          // - setup 步骤 0 完成后会写版本号 + timestamp
          if (from <= 9) {
            await m.addColumn(userProfiles, userProfiles.userAgreementVersion);
            await m.addColumn(userProfiles, userProfiles.privacyPolicyVersion);
            await m.addColumn(
              userProfiles,
              userProfiles.sensitiveDataConsentAt,
            );
            await m.addColumn(userProfiles, userProfiles.consentRevokedAt);
          }
          // v10 → v11: userName 改 nullable (P1-24 修复)
          // - user_profiles.userName + report_histories.userName
          // - 老数据 "" 仍写回 "" (空字符串),但允许 null
          // - 实际: drift 的 alter table 不支持改列属性,SQLite 也没有 ALTER COLUMN
          //   所以这条变更**只在 createAll 里生效** (新装用户自动是新 schema)
          //   升级用户 schema 没改,**统一走 `core/shared/user_name_helper.dart`
          //   的 `safeUserName()` 兼容老数据 "" 和新数据 null**
          //   (v0.22 round 31 sp-en P0-3 抽 helper 集中 5+ 处散落判断)
          // v11 → v12: mood_entries 加语音录入 3 字段 (v0.23 round 31)
          // - audioPath / audioTranscript / audioDurationMs 全部 nullable
          // - 老数据自动为 null,纯文字模式行为完全不变
          // - 新数据:audioPath 必有(录音一定有文件),transcript/durationMs 可空
          if (from <= 11) {
            await m.addColumn(moodEntries, moodEntries.audioPath);
            await m.addColumn(moodEntries, moodEntries.audioTranscript);
            await m.addColumn(moodEntries, moodEntries.audioDurationMs);
          }
          // v12 → v13: check_ins 加 medicationId 索引 (P2 优化)
          // - 药物打卡查询按 medicationId 过滤,无索引走全表扫描
          if (from <= 12) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_checkin_med_id ON check_ins(medication_id)',
            );
          }
          // v13 → v14: contacts + report_histories 加索引 (P2 优化)
          if (from <= 13) {
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_contact_active_sort ON contacts(is_active, sort_order)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_report_gen_at ON report_histories(generated_at)',
            );
          }
          // v14 → v15: contacts 加 4 个 consent 字段 (P0-2 修复, PIPL §13 留痕)
          // - 4 字段全部 nullable, 旧数据 (schemaVersion <= 14) 自动为 null
          // - 新加联系人 (schemaVersion 15+) ContactRepositoryImpl.add() 强制
          //   caller 传 ConsentArtifact, 4 字段写进 ContactsCompanion.insert(...)
          // - 索引: consent_at 加索引 (按同意时间倒序查 audit log)
          if (from <= 14) {
            await m.addColumn(contacts, contacts.consentAt);
            await m.addColumn(contacts, contacts.consentKind);
            await m.addColumn(contacts, contacts.consentBy);
            await m.addColumn(contacts, contacts.consentVersion);
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_contact_consent_at ON contacts(consent_at)',
            );
          }
        },
        beforeOpen: (details) async {
          // 启用外键
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ============= CheckIns (v0.25 R53a: 委托给 CheckInDao) =============

  // v0.25 round 53a (spen P1 #12 god class 拆分): 抽 7 DAO + app_database
  // 改成 1 行委托。caller 暂时不动 (保留 facade 兼容), 后续 R53b 渐进迁移。
  late final checkInDao = CheckInDao(this);
  late final medicationDao = MedicationDao(this);
  late final contactDao = ContactDao(this);
  late final userProfileDao = UserProfileDao(this);
  late final reportDao = ReportDao(this);
  late final moodDao = MoodDao(this);
  late final ventDao = VentDao(this);

  // v0.27 round 65 (spen P1-11): 删 32 行 facade 委派 (line 264-316), caller
  // 已全迁到 _db.xxxDao.xxx() / db.xxxDao.xxx() (94 处). 保留 saveSetup /
  // clearAllUserData (业务编排, 非纯委派).

  /// 完成首次设置：在同一个事务里写入用户档案、联系人、药物，
  /// 任何一个失败整体回滚，避免半成品数据
  ///
  /// v0.27 round 68 (CC-1 修复, PIPL §13 单独同意): 加 `contactConsents` 参数
  /// (跟 `contactList` 等长)。setup 阶段每个填了的联系人必须有 ConsentArtifact,
  /// 否则联系人不会写入(4 个 consent 字段必有值)。setup_page 必须在调 saveSetup
  /// 之前对每个联系人弹 ConsentDialog 拿 consent。
  Future<void> saveSetup({
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
    // v0.21 (P1-2 fix): 函数入口取一次 now, 避免 2 个 await 之间跨 midnight
    // firstLaunchAt 跟 medStart 用了不同 DateTime.now() → 同一次 setup
    // 在 23:59:59.x 跨过 0 点时,两个时间戳差 1 天。
    final now = DateTime.now();
    await transaction(() async {
      // upsert user profile（保留 firstLaunchAt）
      // v0.27 round 65 (spen P1-11): 删 facade getUserProfile, saveSetup 内部
      // 改用 userProfileDao.get() (R53a 已抽 7 DAO)
      final existing = await userProfileDao.get();
      await into(userProfiles).insertOnConflictUpdate(
        UserProfilesCompanion.insert(
          // v0.21 Round 23 (P1-24): userName 改 nullable
          // 接受 null,UI "我是" 时退化为 "Friend" 或空
          userName: Value(userName),
          checkInCycleHours: const Value(48),
          firstLaunchAt: existing?.firstLaunchAt ?? now,
        ),
      );

      // insert contacts (R68 CC-1: PIPL §13 单独同意, 4 个 consent 字段必有)
      assert(contactList.length == contactConsents.length,
          'contactList 跟 contactConsents 必须等长 — setup_page 必须逐个弹 ConsentDialog');
      for (var i = 0; i < contactList.length; i++) {
        final c = contactList[i];
        final consent = contactConsents[i];
        await into(contacts).insert(
          ContactsCompanion.insert(
            name: c.name,
            phone: c.phone,
            sortOrder: Value(c.sortOrder),
            // R68 CC-1 修复: 4 个 consent 字段从 setup 阶段就写
            // (之前留空 → PIPL §13 技术层面不成立, §47 查询权无效)
            consentAt: Value(consent.grantedAt),
            consentKind: Value(consent.kind.name),
            consentBy: Value(consent.grantedBy),
            consentVersion: Value(consent.version),
          ),
        );
      }

      // insert medications
      // startDate 用同一个 now,确保 firstLaunchAt 跟 medStart 一致
      final medStart = now;
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

  // ============= 隐私 / 清空数据 (v0.21 Round 22, P0-8 修复) =============

  /// 清空所有用户数据表 (PIPL §47 主动删除权)
  ///
  /// **不**重置 schemaVersion,**不**删 DB 文件 — 保留表结构,只清数据。
  /// 调用方需自己处理后续(跳 setup / 通知用户)。
  ///
  /// 不删:无 (用户档案 / 联系人 / 药物 / 打卡 / 报告 / 情绪 / 树洞 都可清)。
  /// 保留:无 (AppDatabase 无非用户表)。
  ///
  /// **不**清 vent audio 文件 (文件不在 DB),调用方需自己调
  /// [VentAudioStorage.deleteAll] 删文件。
  Future<void> clearAllUserData() async {
    await transaction(() async {
      // 顺序重要:外键依赖先清
      // (当前 schema 无外键,顺序不重要,但保持防御性)
      await delete(checkIns).go();
      await delete(medications).go();
      await delete(contacts).go();
      await delete(userProfiles).go();
      await delete(reportHistories).go();
      await delete(moodEntries).go();
      await delete(ventEntries).go();
    });
  }

  // _encodeTimes 移到了 MedicationRepository.encodeTimes（共用，格式不变）
}
