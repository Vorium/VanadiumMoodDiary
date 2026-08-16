// user profile 导入 — v1.1.0 R113 wave 5 (gdc P1-7 god class 拆分)
//
// 从 export_import_pipeline.dart 抽出 (R77/R112-ARCH-03 的 4 子任务之一
// _importProfile), 按 R113 gdc 审计建议按实体簇拆 3 文件之一:
//   - import_profile.dart (本文件): user profile (全局单条)
//   - import_entities.dart: medications / checkIns / reportHistories /
//     moodEntries / worryThreads + 6 张 daily tracking 表
//   - import_vent.dart: vent entries
//   - import_shared.dart: ImportResultBuilder 共享聚合器
//
// 除下述 P2-13 gate 修复外 PURE MOVE, 兜底测试全绿
// (export_import_pipeline_round99 / data_export_v5_round8 等)。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';

/// 子任务 2/4: user profile 导入 (全局单条, id=1)
///
/// v0.32 round 8 (R112 E7 fix): drift insertOnConflictUpdate 忽略
/// Value(null) → 老文件缺的字段不会清掉旧设备残留。改 update().write()
/// (显式 SET NULL), import = 全量替换语义。
///
/// R113 wave 2 (P2-13 fix): gate = profile 段存在 (data['profile'] != null),
/// 不再是 userName 非空。用户清空昵称 (v0.21 P1-24 userName nullable) 时
/// PIPL §14 同意留痕 4 字段 (R63) 不再被整体跳过静默丢失。
Future<void> importProfile(AppDatabase db, Map<String, dynamic> data) async {
  if (data['profile'] != null) {
    final p = data['profile'] as Map<String, dynamic>;
    final userName = ExportSchemaService.validateString(
      p['userName'],
      'userName',
      maxLen: 50,
    );
    final companion = UserProfilesCompanion.insert(
      // v0.21 Round 23 (P1-24): userName nullable
      userName: Value(userName),
      checkInCycleHours: Value(
        ExportSchemaService.validateIntOr(
          p['checkInCycleHours'],
          48,
          min: 1,
          max: 168,
        ),
      ),
      firstLaunchAt: ExportSchemaService.validateDate(p['firstLaunchAt']) ??
          DateTime.now(),
      // v0.32 round 8 (R112-06 fix): lastCheckInAt 已导出但 import
      // 从不读 (P0-10 注释意图未实现)。
      lastCheckInAt: Value(
        ExportSchemaService.validateDate(p['lastCheckInAt']),
      ),
      // v0.32 round 8 (R112 E7 fix): PIPL §14 同意留痕 4 字段
      // (R63 加)。跟 contact consent 同款: 老 v4 文件无这 4 字段
      // → null (老数据, 法务可接受)。
      userAgreementVersion: Value(
        ExportSchemaService.validateString(
          p['userAgreementVersion'],
          'profile.userAgreementVersion',
          maxLen: 50,
        ),
      ),
      privacyPolicyVersion: Value(
        ExportSchemaService.validateString(
          p['privacyPolicyVersion'],
          'profile.privacyPolicyVersion',
          maxLen: 50,
        ),
      ),
      sensitiveDataConsentAt: Value(
        ExportSchemaService.validateDate(p['sensitiveDataConsentAt']),
      ),
      consentRevokedAt: Value(
        ExportSchemaService.validateDate(p['consentRevokedAt']),
      ),
    );
    if (await db.userProfileDao.get() == null) {
      await db.userProfileDao.upsert(companion);
    } else {
      // v0.32 round 8 (R112 E7 fix): 显式 SET NULL, import = 全量替换语义。
      await (db.update(db.userProfiles)..where((t) => t.id.equals(1)))
          .write(companion);
    }
  }
}
