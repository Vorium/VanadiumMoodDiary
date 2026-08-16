// 规则 3 标记: 导入错误文案 中文 fallback — v1.0+ i18n (显示层走 ARB)
// 数据导入 pipeline — v0.27 round 77 (R76-N8 重构 续)
//
// 背景 (R76 superpowers-en 报告 P1-8):
//   export_orchestrator.dart 21.5KB, 1 facade + 1 god method (importFromJson 310 行)
//   + 1 class (ImportResult 65 行) 全堆一起, 修改 import 逻辑需要滚屏 + 风险。
//
//   拆法 (渐进 facade 模式, 跟 R57 safety_watch / R58 medication_report 同款):
//   - export_orchestrator.dart (12KB): 公共 facade + exportToJson + ImportResult
//   - export_import_pipeline.dart (本文件, 9KB): importFromJson 整 method
//
// 设计:
//   - importFromJson 内部高度耦合 _db / _schemaService / _reportRepo / _cryptoService
//     / _audioService 等私有字段, 不能简单抽 extension (会破坏封装)
//   - 改: 把整个 importFromJson method 整体迁出到本文件作为 `Future<ImportResult>
//     runImportFromJson(ExportOrchestrator orchestrator, String json)` 顶层函数
//   - ExportOrchestrator.importFromJson(json) 改成 1 行委托:
//     `=> runImportFromJson(this, json)`
//   - 50+ test 不用改 (走 facade.public method)
//
// v0.32 架构批 2 (R112-ARCH-03): 执行 R77 注释的 4 子任务拆分计划
//   - runImportFromJson 拆为 4 private 顶层函数:
//     _clearData / _importProfile / _importEntities / _importVent
//   - ImportResultBuilder 聚合 6 个计数 (v1.1.0 round 3 删 contactCount;
//     medIdMap / moodIdMap 老→新 id
//     映射在 _importEntities 内部闭环, 不泄漏到其它子任务)
//   - 行为 100% 不变 (data_export_v5_round8 / export_import_pipeline_round99
//     等兜底测试全绿)
//
// v1.1.0 R113 wave 5 (gdc P1-7 最后真 god class 拆分): 按实体簇拆 3 文件,
//   本文件降级为 facade (编排 + 清空旧数据), 子导入器:
//   - import_profile.dart — user profile (R113 wave 2 P2-13 gate 修复随迁)
//   - import_entities.dart — medications / checkIns / reportHistories /
//     moodEntries / worryThreads + 6 张 daily tracking 表
//   - import_vent.dart — vent entries
//   - import_shared.dart — ImportResultBuilder 共享聚合器
//   行为 100% 不变 (PURE MOVE), 兜底测试全绿:
//   data_export_v7_worry_round9 / export_import_pipeline_round99 /
//   data_export_round39 / data_export_round3 / data_export_schema_round45 /
//   data_export_v6_round3 / data_export_v5_round8。

import 'dart:convert';

import 'package:flutter/foundation.dart' show kReleaseMode;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/export/import_entities.dart';
import 'package:chroniccare/core/data/services/export/import_profile.dart';
import 'package:chroniccare/core/data/services/export/import_shared.dart';
import 'package:chroniccare/core/data/services/export/import_vent.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';

/// 导入数据 (覆盖现有) — 从 ExportOrchestrator.importFromJson 拆出
///
/// 返回导入条数摘要 [ImportResult]
Future<ImportResult> runImportFromJson(
  ExportOrchestrator orchestrator,
  String json,
) async {
  // v0.27 round 77: 抽 5 个依赖为 final local, 避免每次访问 orchestrator._xxx
  // (跨文件 private 字段访问会失败 — 改用 ExportOrchestrator 公开 getter)
  final db = orchestrator.db;
  final schemaService = orchestrator.schemaService;

  try {
    final data = jsonDecode(json) as Map<String, dynamic>;
    final version = schemaService.validateVersion(data['version']);
    if (version == null) {
      return ImportResult.failure(
        '数据版本不匹配（期望 1-${ExportSchemaService.currentVersion}, 实际 ${data['version']}）',
      );
    }

    final counts = ImportResultBuilder();

    await db.transaction(() async {
      // 清空旧数据
      await _clearData(db, schemaService);

      // profile
      await importProfile(db, data);

      // contacts / medications / checkIns / reportHistories / moodEntries /
      // 6 张 daily tracking 表 (medIdMap + moodIdMap 在本子任务内闭环)
      await importEntities(
        db,
        orchestrator.reportRepo,
        data,
        version,
        counts,
      );

      // P0-3: vent_entries 文字导入 (录音路径永远丢弃, 跨设备不可用)。
      await importVent(
        db,
        orchestrator.cryptoService,
        orchestrator.audioService,
        data,
        version,
        counts,
      );
    });

    return counts.build();
  } catch (e, st) {
    // v1.1.0 R113 (BUG 2): kReleaseMode 守卫 — piiSafeLog 内部用
    // dart.vm.product 守卫, 该常量在 web release (dart2js/ddc) 下默认
    // false 会漏; kReleaseMode 全平台 release 都为 true。$e\n$st 可能含
    // PII (文件名 / 路径 / 用户数据), 生产构建不写 console。
    if (!kReleaseMode) {
      piiSafeLog('DataExportService', 'importFromJson error: $e\n$st');
    }
    // P12 fix: 脱敏, 只告诉用户"解析失败", 不暴露具体异常
    return ImportResult.failure('解析失败：数据格式不正确，请确认是从本 App 导出的 JSON');
  }
}

/// 子任务 1/4: 清空旧数据 (覆盖导入语义)
///
/// v0.23 round 39 P1-10 fix: 旧 schema 缺失表安全删除走 swallowError
/// 集中器 (deleteOldDataSafely), 不再 catch(_) 完全静默。
/// v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91) 也 clear。
Future<void> _clearData(
  AppDatabase db,
  ExportSchemaService schemaService,
) async {
  await db.delete(db.checkIns).go();
  await db.delete(db.medications).go();
  // v1.1.0 round 3 (Task 6): contacts 表不清 — Task 9 才删表, 导入器
  // 不再引用 contacts (v5 文件含 contacts key 时忽略)。
  // 旧 schema 缺失表安全删除
  await schemaService.deleteOldDataSafely(
    db,
    db.reportHistories,
    label: 'reportHistories',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.moodEntries,
    label: 'moodEntries',
  );
  // v1.1.0 round 9 (F1 烦恼闭环): 烦恼主题表 (覆盖导入语义, 跟 moodEntries
  // 一起清 — 残留旧设备的烦恼会跟新数据混在一起)
  await schemaService.deleteOldDataSafely(
    db,
    db.worryThreads,
    label: 'worryThreads',
  );
  // P0-3: vent_entries 表 (v0.15+ 存在, 不需要 guard, 但仍走安全删除)
  await schemaService.deleteOldDataSafely(
    db,
    db.ventEntries,
    label: 'ventEntries',
  );
  // v0.32 round 8 (R112 E6 fix): 6 张 daily tracking 表 (R91, DB schema 22)。
  // 之前 import 不 clear → 导入后残留旧设备数据 (与新数据混在一起)。
  await schemaService.deleteOldDataSafely(
    db,
    db.sleepEntries,
    label: 'sleepEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.socialRhythmEntries,
    label: 'socialRhythmEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.stressEvents,
    label: 'stressEvents',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.treatmentEntries,
    label: 'treatmentEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.weightEntries,
    label: 'weightEntries',
  );
  await schemaService.deleteOldDataSafely(
    db,
    db.anxietyAgitationEntries,
    label: 'anxietyAgitationEntries',
  );
}
// rule3-whitelist: 72, 116
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
