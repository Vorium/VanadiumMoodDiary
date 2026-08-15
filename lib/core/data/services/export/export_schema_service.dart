// JSON schema version 管理 + 字段校验 helper — v0.24 Sprint #5c (emil god class 拆解)
//
// **职责**:
// 1. version 1-4 范围校验 (P0 兼容, 不破坏老用户数据 — v0.22 round 30 P0)
// 2. 6 个字段类型 + 长度 + pattern 校验 (static helper, 纯函数)
// 3. 旧 schema 缺失表的安全删除 (P1-10 fix: 不再 catch(_) 完全静默, 走 swallowError
//    集中器便于排查异常 schema — v0.23 round 39)
//
// **来源**: 原本所有校验 + 旧表删除都堆在 `data_export_service.dart` 内
// (line 215-472 import 编排 + line 476-517 `_validate*` 静态 helper),
// Sprint #5c 抽到 `ExportSchemaService`。
//
// **JSON schema version 历史**:
// - v1: 基础 (profile / contacts / medications / checkIns)
// - v2: + `reportHistories` + `moodEntries` (v0.9 引入)
// - v3: + `ventEntries` 文字 (v0.15 引入, 跨设备恢复需要)
// - v4: 4D 情绪 (energy / sleep / anxiety) (v0.18 引入)
// - v5 (current): R111 E1/E2/E3 (v0.32 round 8) — medications +5 字段
//   (refillAt / refillReminderDays / form / colorIndex / notes) + mood +5 字段
//   (audioTranscript / audioDurationMs / period / influenceFactorsJson /
//   recordingMode) + contact consent 4 字段 (PIPL §13 留痕) + medication id
//   导出 → checkIn.medicationId 导入重映射 (修孤儿 FK)
// - v5 (R112, 未发布继续扩): E6 6 张 daily tracking 表 (sleepEntries /
//   socialRhythmEntries / stressEvents / treatmentEntries / weightEntries /
//   anxietyAgitationEntries, R91) + profile PIPL §14 同意留痕 4 字段
//   (userAgreementVersion / privacyPolicyVersion / sensitiveDataConsentAt /
//   consentRevokedAt) + medications 改 watchAllIncludingInactive (软停药不丢)
//   + endDate 导出 + mood id 导出 → stress.linkedMoodEntryId /
//   treatment.linkedMedicationId 重映射 + lastCheckInAt 导入 + isActive
//   脏数据容错 (is-check 替代裸 cast)。老 v4 文件无新 key → 优雅降级。
// - v6 (current): v1.1.0 情绪优先重构 (round 3) — 删 contacts 段
//   (外联全链删除, 表 Task 9 才删, 导入不再清/写 contacts), mood
//   +statusPhrase, vent +tagsJson。老 v5 文件含 contacts key → 忽略。
//
// **emil 设计决策**:
// - "decisions should be nameable" — schema version 兼容 + 字段校验 决策独立命名
// - 6 个 `_validate*` 全部 public static, 命名去掉下划线 (跟 `EncryptionService`
//   风格一致) — `ExportAudioService.parseAudioDurationSec` 复用 `validateIntOr`
// - `deleteOldDataSafely` 走 `swallowError` 集中器 — P1-10 修过的 "不静默 catch(_)"
// - `const` constructor (0 状态, 0 runtime cost)
// - `validateDate` 内部用 `DateTime.tryParse` (v0.21 P0-2 fix: 替代 try/catch 反模式)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';
import 'package:drift/drift.dart' show Table, TableInfo;

/// JSON schema version 管理 + 字段校验 helper
///
/// 单一职责: schema version 校验 + 6 个字段类型校验 + 旧表缺失容错
class ExportSchemaService {
  const ExportSchemaService();

  /// 当前 schema 版本 (v6: v1.1.0 情绪优先重构 — 删 contacts 段,
  /// mood +statusPhrase, vent +tagsJson)
  static const int currentVersion = 6;

  /// 校验 JSON version 字段
  ///
  /// 返回 version 整数, 不通过 (非 int / 范围错) → `null`,
  /// facade 负责把 `null` 翻译成 `ImportResult.failure('数据版本不匹配...')`
  ///
  /// **emil 决策**: 校验失败用 `null` 表示 (跟 `validateInt` 风格一致),
  /// 而不是抛异常 — "import 是用户操作, 应优雅降级"
  int? validateVersion(dynamic v) {
    if (v is! int || v < 1 || v > currentVersion) return null;
    return v;
  }

  /// 安全删除表 (旧 schema 缺失容错)
  ///
  /// v0.23 round 39 (P1-10 fix): 不再 `catch (_)` 完全静默, 走 `swallowError`
  /// 集中器 (developer.log) 便于排查异常 schema。
  ///
  /// 用法 (facade import 段):
  /// ```dart
  /// await _schemaService.deleteOldDataSafely(_db, _db.reportHistories, label: 'reportHistories');
  /// ```
  Future<void> deleteOldDataSafely(
    AppDatabase db,
    TableInfo<Table, dynamic> table, {
    String? label,
  }) async {
    try {
      await db.delete(table).go();
    } catch (e, st) {
      exportErrorSink(
        where: 'ExportSchemaService.deleteOldDataSafely(${label ?? 'unknown'})',
        error: e,
        stack: st,
        note: '表不存在（旧 schema)，忽略',
      );
    }
  }

  // ===== 6 个字段校验 helper (public static, pure) =====
  //
  // 命名约定: 去掉下划线 (跟 public API 一致), facade + ExportAudioService 都用
  // 失败处理: 全部返回 `null` (用 defaultValue 兜底) 或 `defaultValue`,
  //          不抛异常 — "import 是用户操作, 应优雅降级"

  /// 校验字符串字段
  ///
  /// 返回 `null` 场景:
  /// - v 是 null (字段缺失)
  /// - v 不是 String
  /// - v 是空字符串
  /// - v.length > maxLen
  /// - v 不匹配 pattern (如 phone regex `^\+?\d{6,20}$`)
  static String? validateString(
    dynamic v,
    String field, {
    int maxLen = 1000,
    RegExp? pattern,
  }) {
    if (v == null) return null;
    if (v is! String) return null;
    if (v.isEmpty) return null;
    if (v.length > maxLen) return null;
    if (pattern != null && !pattern.hasMatch(v)) return null;
    return v;
  }

  /// 校验 int 字段, 可空 (返回 `null` 用 `defaultValue` 兜底)
  ///
  /// 返回 `defaultValue` 场景:
  /// - v 是 null (字段缺失)
  /// - v 不是 int
  /// - v 超出 [min, max] 范围
  static int? validateInt(
    dynamic v,
    int? defaultValue, {
    int? min,
    int? max,
  }) {
    if (v == null) return defaultValue;
    if (v is int) {
      if (min != null && v < min) return defaultValue;
      if (max != null && v > max) return defaultValue;
      return v;
    }
    return defaultValue;
  }

  /// 校验 int 字段, 非空默认值场景
  ///
  /// `validateIntOr(x, 48, min: 1, max: 168)` 直接返回 int (defaultValue 兜底)
  ///
  /// 等同 `validateInt(...)?.. ?? defaultValue` 但 0 中间变量, 表达更清晰
  static int validateIntOr(
    dynamic v,
    int defaultValue, {
    int? min,
    int? max,
  }) {
    final r = validateInt(v, defaultValue, min: min, max: max);
    return r ?? defaultValue;
  }

  /// 校验 double 字段 (medication dosage 用)
  ///
  /// 返回 `null` 场景: v 是 null 或非 num
  /// 注意: `int` 是 `num` 子类, 所以 `validateDouble(0.3)` 和 `validateDouble(0)` 都返回 `0.0`
  static double? validateDouble(dynamic v) {
    if (v is num) return v.toDouble();
    return null;
  }

  /// 校验 + 解析 ISO 8601 日期字段
  ///
  /// v0.21 (P0-2 fix): 用 `tryParse` 替代 `try/catch + DateTime.parse`。
  /// 之前 `try/catch` 是反模式 — `DateTime.parse` 失败是**预期内**的情况
  /// (用户导入了格式异常的历史数据), 不是异常。`try/catch` 在 hot path 上还有
  /// stack 捕获开销。
  static DateTime? validateDate(dynamic v) {
    if (v is! String) return null;
    return DateTime.tryParse(v);
  }
}
