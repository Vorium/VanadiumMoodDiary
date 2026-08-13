// 数据导出/导入服务 facade — v0.26 round 57 (spen P1 #2 god class 拆分续)
//
// **基线**: v0.24 round 45: 582 行 → ~250 行 (1 facade + 3 sub-service)
// **v0.26 round 57**: 539 → 119 行 (1 facade + 4 sub-service), 复杂编排下沉
//         ExportOrchestrator。
//
// **职责 (拆分后, v0.26)**:
// - **facade** (本文件, 119 行): importData / exportData 5 类编排入口 + ImportResult summary
//   getter (i18n 走 Strings) — 仅 facade 引用 l10n
// - **ExportOrchestrator** (export_orchestrator.dart, ~340 行): importData/exportData 内部编排
// - **ExportCryptoService**: vent text encrypt/decrypt 副作用封装
// - **ExportAudioService**: vent audio metadata 序列化 + 校验
// - **ExportSchemaService**: JSON schema version + 6 字段校验 + 旧表删除
//
// **来源历史**:
// - v0.7: 用户换手机/重装 app 时恢复数据 (不加密, 不依赖云端)
// - v0.21 Round 22 (P0-3): vent 文字导出时 decrypt → 给明文 (跨设备恢复需要); 导入时再 encrypt
// - v0.22 round 30 (P0): JSON schema version 1-4 兼容 (不破坏老用户数据)
// - v0.22 round 32 (spzh 合规): vent 二次确认 (presentation 层不动, 数据层无感)
// - v0.23 round 39 (P1-5): 加 50+ case test (data_export_round39_test.dart)
// - v0.23 round 39 (P1-10): catch(_) → swallowError 集中器
// - v0.23 round 40 (P2): exportToJson 5s timeout 防 drift stream hang
// - v0.24 round 45: god class 拆 3 sub-service
// - v0.26 round 57: 抽 ExportOrchestrator, facade 减到 119 行
//
// **隐私边界**:
// - vent 文字: export 时 decrypt → 明文, import 时 encrypt → blob (PIPL §28)
// - vent audio: **不导出文件** (跨设备路径失效), 只导 metadata 引用
// - 二次确认: presentation 层 (data_management_section) 决定, service 不感知
//
// **JSON schema version**:
// - v1: 基础 (profile / contacts / medications / checkIns)
// - v2: + reportHistories + moodEntries (v0.9)
// - v3: + ventEntries 文字 (v0.15)
// - v5 (current): + R111 E1/E2/E3 + 6 daily tracking 表 + PIPL §14 留痕 (v0.32 round 8)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_orchestrator.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/domain/repositories/report_history_repository.dart';

// 兼容旧 import 路径: 老代码 `import 'data_export_service.dart' show ImportResult;`
// 在新架构下仍能编译 (ImportResult 从 export_orchestrator.dart 转出,
// facade 不再 define ImportResult, 但通过 re-export 让老 import 仍可用)。
// 显式 re-export:
export 'package:chroniccare/core/data/services/export/export_orchestrator.dart'
    show ImportResult;

/// v0.26 round 57 (spen P1 #2): 数据导出/导入 facade
///
/// 公开 API 跟拆分前一致 (exportToJson / importFromJson), 50+ 现有 test 不用改。
/// 内部把 import/export 编排委托给 [ExportOrchestrator]。
class DataExportService {
  final ExportOrchestrator _orchestrator;

  /// 构造注入 (DI 模式, 跟 mood_dialog `MoodRecorderController` 同思路)
  ///
  /// **构造签名向后兼容** (v0.24 sprint #5c + v0.26 R57 不破): 保留
  /// `DataExportService(db, [reportRepo, ventTextEncryption])` 3 参数位置签名,
  /// 内部转给 [ExportOrchestrator.legacy] 工厂, 现有 50+ test 不用改。
  DataExportService(
    AppDatabase db, [
    ReportHistoryRepository? reportRepo,
    EncryptionService? ventTextEncryption,
  ]) : _orchestrator = ExportOrchestrator.legacy(
          db: db,
          reportRepo: reportRepo,
          ventTextEncryption: ventTextEncryption,
        );

  /// 公开构造 — 测试或 sub-class 想直接控制 sub-service 时用
  ///
  /// 跟 3 参数位置签名 100% 等价, 只是参数命名 + 显式 sub-service 注入。
  DataExportService.withServices({
    required AppDatabase db,
    required ExportCryptoService cryptoService,
    required ExportAudioService audioService,
    required ExportSchemaService schemaService,
    ReportHistoryRepository? reportRepo,
  }) : _orchestrator = ExportOrchestrator(
          db: db,
          cryptoService: cryptoService,
          audioService: audioService,
          schemaService: schemaService,
          reportRepo: reportRepo,
        );

  /// 直接访问 orchestrator (低层 API, 给需要细粒度控制的 caller 用)
  ///
  /// 大多数 caller 走 [exportToJson] / [importFromJson] 即可。
  ExportOrchestrator get orchestrator => _orchestrator;

  /// 导出所有数据为 JSON 字符串 (5 类编排入口之一)
  Future<String> exportToJson({DateTime? now}) =>
      _orchestrator.exportToJson(now: now);

  /// 从 JSON 字符串导入数据 (5 类编排入口之一)
  Future<ImportResult> importFromJson(String json) =>
      _orchestrator.importFromJson(json);

  // ============== 5 类编排入口 (R57 facade 设计) ==============
  // 1. exportToJson (上面)
  // 2. importFromJson (上面)
  // 3. 公开 ExportOrchestrator (上面 orchestrator getter)
  // 4. ImportResult 公开类型 (从 export_orchestrator.dart re-export 兼容 caller)
  // 5. ImportResult.summary getter (在 ImportResult 内部, 走 Strings)
}
