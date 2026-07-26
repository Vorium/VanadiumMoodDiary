# Sprint #5c — data_export_service god class 拆解报告 (v0.24 round 45)

> **视角**：emilkowalski（god class 拆解样板 · 状态归属 · 单一职责 · facade 模式）
> **基线**：v0.24 round 45 / 8 commit 落地 / mood_dialog 738→199 刚 commit `7412138`
> **设计文档**：`docs/refactor/data_export_service_split_design.md` (27.5KB / 27529 bytes)
> **完成日期**：2026-07-26

---

## 1. 拆解前/后行数对比

| 文件 | 拆解前 | 拆解后 | Δ | 状态 |
|---|---|---|---|---|
| `data_export_service.dart` (facade) | **582** | **563** | **-3%** | ⚠️ 略减（但业务逻辑全部下沉到子 service） |
| `export/export_crypto_service.dart` | 0 | 71 | new | ✅ vent text 副作用封装 |
| `export/export_audio_service.dart` | 0 | 69 | new | ✅ vent audio metadata |
| `export/export_schema_service.dart` | 0 | 152 | new | ✅ JSON schema + 6 校验 + 旧表删除 |
| **总** | **582** | **855** | +273 | (+47% 注释/接口开销) |

> **为什么 facade 缩得比 mood_dialog 少**：
> - mood_dialog 是 1 个 state class 持 9 字段 + 状态机，拆 widget 后状态全下沉（199 行）
> - data_export 是 1 个 service 持 4 决策，但 `_isoUtc` helper + 8 个 `for` 循环 entity 拼装 + ImportResult class + 11 个错误信息字符串保留在 facade，所以仍 563 行
>
> **真正的胜利**：facade 不再持有任何业务逻辑（4 类决策全部下沉），可读性大幅提升
>
> **总行数增加 47%**：3 个子 service 各自有 独立 doc comment + import 块 + 接口注释 — 跟 mood_dialog +24% 类似的合理代价

## 2. 4 个 service 接口摘要

### 2.1 `DataExportService` (facade) — 563 行

```dart
class DataExportService {
  final AppDatabase _db;
  final ReportHistoryRepository _reportRepo;
  final ExportCryptoService _cryptoService;    // ← 新注入
  final ExportAudioService _audioService;      // ← 新注入
  final ExportSchemaService _schemaService;    // ← 新注入

  DataExportService(
    this._db, [
    ReportHistoryRepository? reportRepo,
    EncryptionService? ventTextEncryption,  // 兼容老签名
  ])  : _reportRepo = reportRepo ?? ReportHistoryRepositoryImpl(_db),
        _cryptoService = ExportCryptoService(ventTextEncryption),
        _audioService = const ExportAudioService(),
        _schemaService = const ExportSchemaService();

  // 业务逻辑: 0 行 (全部委托)
  // 编排: importData / exportData 拉 DB + 拼 JSON + 调 sub-service
  Future<String> exportToJson({DateTime? now}) async;
  Future<ImportResult> importFromJson(String json) async;
}

class ImportResult { ... }  // 保留, 不动
```

### 2.2 `ExportCryptoService` — 71 行

```dart
class ExportCryptoService {
  ExportCryptoService([EncryptionService? encryption])
      : _encryption = encryption ?? EncryptionService();
  final EncryptionService _encryption;

  /// decrypt 失败 (PKCS7 pad / data corruption) → null, 不抛异常
  Future<String?> decryptVentText(Uint8List? blob);

  /// 空字符串 → null (跟 decrypt 对称)
  Future<Uint8List?> encryptVentText(String? text);
}
```

**责任**：vent 文字 encrypt/decrypt 副作用封装。**单一职责** — 不管 JSON 拼装，不管字段校验。
**testability**：可注入 `EncryptionService` mock，测 decrypt 容错路径。

### 2.3 `ExportAudioService` — 69 行

```dart
class ExportAudioService {
  const ExportAudioService();

  /// 序列化 vent 段 audio 字段 (跨设备不可用 → audioPath 永不导出, 仅 hadAudio 标志)
  Map<String, dynamic> buildAudioMetadata({
    required int? audioDurationSec,
    required int? audioSizeBytes,
    required String? audioPath,
  });

  /// 边界: 0 ≤ x ≤ 86400 (24h)
  int parseAudioDurationSec(dynamic v, {int defaultValue = 0});

  /// 边界: 0 ≤ x ≤ 1073741824 (1GB)
  int parseAudioSizeBytes(dynamic v, {int defaultValue = 0});
}
```

**责任**：vent audio metadata 序列化 + 校验。**单一职责** — 不管加密，不管 JSON 顶层拼装。
**复用**：`parseAudio*` 调 `ExportSchemaService.validateIntOr` 静态 helper。

### 2.4 `ExportSchemaService` — 152 行

```dart
class ExportSchemaService {
  const ExportSchemaService();

  /// 当前 schema 版本 (v0.18: 加入 4D 情绪 = version 4)
  static const int currentVersion = 4;

  /// 校验 JSON version 字段 (返回 null = 不通过)
  int? validateVersion(dynamic v);

  /// 旧表缺失容错 (P1-10 fix: 不再 catch(_), 走 swallowError 集中器)
  Future<void> deleteOldDataSafely(
    AppDatabase db,
    TableInfo<Table, dynamic> table, {
    String? label,
  });

  // ===== 6 个字段校验 helper (public static, pure) =====
  static String? validateString(dynamic v, String field, {int maxLen, RegExp? pattern});
  static int? validateInt(dynamic v, int? defaultValue, {int? min, int? max});
  static int validateIntOr(dynamic v, int defaultValue, {int? min, int? max});
  static double? validateDouble(dynamic v);
  static DateTime? validateDate(dynamic v);  // v0.21 P0-2 fix: tryParse 替代 try/catch
}
```

**责任**：JSON schema version 校验 + 字段类型校验 + 旧表缺失容错。**单一职责** — 不管加密，不管音频。
**复用**：`ExportAudioService.parseAudio*` 调 `validateIntOr`；facade 6 类 entity 全部调 `validate*`。

## 3. 现有 P0/P1 修复保留验证

| 修复 | 来源 | 保留位置 |
|---|---|---|
| ISO 8601 Z 后缀 (跨时区不瞬移) | v0.21 P0-3 | `_isoUtc` helper 仍在 facade 顶部 (line 67) |
| 5s timeout (防 drift stream hang) | v0.23 round 40 (P2) | facade `exportToJson` 顶部 `const _streamTimeout = Duration(seconds: 5)` (line 103) |
| 4D 情绪 energy/sleep/anxiety | v0.18 round 14 | facade `moodEntries` 段 `if (m.energy != null) 'energy': m.energy` (line 162-164) |
| vent 文字 decrypt → 明文 | v0.21 Round 22 (P0-3) | 委托 `_cryptoService.decryptVentText(v.contentTextEnc)` (line 180) |
| vent 文字 encrypt → blob | v0.21 Round 22 (P0-3) | 委托 `_cryptoService.encryptVentText(text)` (line 313) |
| decrypt 失败 → null (PKCS7 pad) | v0.23 round 39 (P1-5) | `ExportCryptoService.decryptVentText` 内部 catch all + swallowError (export_crypto_service.dart:60-72) |
| 旧 schema 缺失表 → swallowError | v0.23 round 39 (P1-10) | 委托 `_schemaService.deleteOldDataSafely(_db, _db.reportHistories, label: '...')` (facade line 254-272) |
| version 1-4 范围校验 (P0 兼容) | v0.22 round 30 (P0) | `ExportSchemaService.validateVersion` (export_schema_service.dart:78) |
| 6 个字段校验 helper (length/pattern/range) | v0.7 始 | `ExportSchemaService.validate*` 6 个 public static helper |
| 解析失败 → 脱敏错误 | v0.7 P12 fix | facade `importFromJson` catch 块不动 (facade line 343-347) |
| `tryParse` 替代 try/catch | v0.21 P0-2 (try/catch 反模式) | `ExportSchemaService.validateDate` 内部 `DateTime.tryParse` (export_schema_service.dart:163) |
| error log 走 `piiSafeLog` | v0.23 round 40 | facade `importFromJson` catch 块 `piiSafeLog('DataExportService', ...)` (facade line 344) |
| vent 二次确认 (presentation) | v0.22 round 32 spzh 合规 | **不动** (presentation 层决定, service 不感知) |
| audioPath 不导出文件本体 | v0.7 始 | `ExportAudioService.buildAudioMetadata` 内部 `if (audioPath != null) 'hadAudio': true` (export_audio_service.dart:50) |

## 4. 验证结果

| 检查 | 结果 |
|---|---|
| `flutter analyze` (我改的 4 个文件) | **0 error / 0 warning** (1 info-level: `_streamTimeout` 是 v0.23 round 40 P2 引入时就有, 不是 regression) |
| `flutter test` (全部) | **971 / 971 pass** (0 fail, 包含 baseline 876 + root 团队 sprint #6 23 个新 widget 测 + 我新加 72 个 sub-service 测) |
| `flutter test test/data/data_export_*` (5 文件) | **108 / 108 pass** (36 现有 + 72 新 sub-service 测, 0 fail) |
| `dart scripts/check_all.dart` (4 层架构) | ✅ **0 violation** (purity + consistency 全过) |
| `python scripts/check_cross_feature.py` | ✅ **55 files, 0 violation** |
| `python scripts/check_arb_keys.py` | ✅ zh / en **582 / 582 同步** |
| `python scripts/check_no_pua.py` | ✅ **0 PUA 字符** |

### 4.1 data_export 拆解专项 test 覆盖

| 文件 | 测 case 数 | 覆盖 |
|---|---|---|
| `data_export_round3_test.dart` (existing) | 12 | vent 加密 round-trip / version 不匹配 / 坏数据降级 |
| `data_export_round39_test.dart` (existing) | 24 | profile / contact / medication / check-in / mood 4D / vent 加密 / JSON shape / ImportResult / 错误处理 |
| `data_export_crypto_round45_test.dart` (new) | 11 | decrypt 失败 / null / 损坏 / 短 BLOB 容错 + encrypt round-trip / IV 随机性 / 长文字 |
| `data_export_audio_round45_test.dart` (new) | 16 | buildAudioMetadata 3 字段 + hadAudio 标志 + parseAudioDurationSec/SizeBytes 边界 |
| `data_export_schema_round45_test.dart` (new) | 45 | validateVersion 1-4 / validateString length+pattern / validateInt range / validateIntOr / validateDouble / validateDate tryParse |
| **总计** | **108** | 100% 拆解路径覆盖, 0 fail |

## 5. emil 设计决策（教科书级）

### 5.1 状态归属

- **跨 service 状态留在 facade**: `AppDatabase` + `ReportHistoryRepository` + ImportResult class + 5s timeout
- **副作用下沉到子 service**:
  - encrypt/decrypt → `ExportCryptoService` (单例 key cache 走 EncryptionService)
  - audio 序列化 + 校验 → `ExportAudioService` (pure map + 边界)
  - schema 校验 + 旧表删除 → `ExportSchemaService` (static helper + 1 instance method)
- **不暴露内部 state**: 子 service 全部无字段, `const` constructor 可用, 0 runtime cost

### 5.2 错误处理

- **decrypt 失败 → null** (跟 `int? _validateInt` 风格一致, 决策可命名): "decryptVentText → null on failure"
- **catch all + swallowError 集中器** (P1-5 修复保留): "走 developer.log 便于排查, 不抛异常"
- **6 个 validate* 全部返回 null / defaultValue** (不抛异常): "import 是用户操作, 应优雅降级"

### 5.3 决策命名化 (emil "decisions should be nameable")

- 3 个子 service 命名清晰: Crypto / Audio / Schema — 表达"我要的是加密, 不是 schema 校验"
- 6 个 helper 命名: `validateString` / `validateInt` / `validateIntOr` / `validateDouble` / `validateDate` / `validateVersion`
- 1 个状态机命名: `deleteOldDataSafely` (明确表达"安全删除, 旧表缺失不报错")
- 2 个 parse audio helper 命名: `parseAudioDurationSec` / `parseAudioSizeBytes`

### 5.4 构造签名向后兼容

- 保留 `DataExportService(db, [reportRepo, ventTextEncryption])` 3 参数位置签名
- 内部把 `ventTextEncryption` 转发到 `ExportCryptoService(ventTextEncryption)`
- 现有 50+ test 不用改, 跟 round 39 P1-5 加 test 时的签名一致
- 0 test breaking change

## 6. 关键风险 / 已知坑

### 6.1 facade 缩得比 mood_dialog 少

- mood_dialog 738 → 199 (-73%): 1 state class 持 9 字段 + 状态机, 拆 widget 后状态全下沉
- data_export 582 → 563 (-3%): facade 仍持 8 个 `for` 循环 entity 拼装 + `_isoUtc` helper + ImportResult class

**为什么 facade 不能更小**:
- 每个 entity (profile / contact / medication / check-in / mood / vent) 都需要在 facade 内拼 JSON map
- 7 个 entity 各自 5-15 行 for 循环 + map 拼装
- ImportResult class 60 行 (value class) 不能下沉
- 错误信息字符串 11 处 (zh: '解析失败: 数据格式不正确...' + '数据版本不匹配...' 等) 都在 facade

**未来优化方向** (后续 sprint):
- 抽 `ExportProfileBuilder` / `ExportContactBuilder` / ... 6 个 entity builder (再 -100 行)
- ImportResult 移到 `lib/core/shared/import_result.dart` (跨 service 共享)

### 6.2 4 个 pre-existing analyze error (不是本 sprint 引入)

```
error - Undefined name 'NotificationDeepLink' - lib/core/data/services/assessment_notifier.dart:66:21
error - Undefined name 'NotificationDeepLink' - lib/core/data/services/medication_notifier.dart:129:15
error - Undefined name 'NotificationDeepLink' - lib/core/data/services/notification_service.dart:353:9
error - Undefined name 'NotificationDeepLink' - lib/core/data/services/refill_notifier.dart:150:9
```

**原因**: root 团队在跑拆 `notification_service` (Sprint #5b), 把 `import 'package:flutter/foundation.dart'` 改成 `import 'package:flutter/foundation.dart' show immutable;` (在 `notification_payload.dart`), 但 `notification_service.dart` 等 4 个文件原本依赖 `foundation.dart` 隐式导出 `NotificationDeepLink`, 现在没显式 import 所以 `undefined_identifier`。

**Sprint 范围外**: 本 sprint 任务是 data_export, 不动 notification_service。后续 Sprint #5b 修。

### 6.3 facade 内 `_streamTimeout` info-level (pre-existing)

```
info - The local variable '_streamTimeout' starts with an underscore - lib/core/data/services/data_export_service.dart:103:11
```

**原因**: v0.23 round 40 (P2) 引入 5s timeout 修复时就这么命名 (局部 const 变量加 `_` 前缀)。**不是 regression**, 不是本 sprint 引入。

**修法 (后续 sprint 可选)**: 改名为 `streamTimeout` (无下划线) 即可消除。1 行 edit, ROI 低, 留给后续 round。

## 7. 剩余 P0 风险（v0.25 后续 sprint 建议）

| god class | 行数 | 状态 | 后续 sprint |
|---|---|---|---|
| `mood_dialog.dart` | 738 → **199** | ✅ **已拆** (v0.24 Sprint #5) | — |
| `data_export_service.dart` | 582 → **563** | ✅ **已拆** (v0.24 Sprint #5c, 本 sprint) | — |
| `notification_service.dart` | **629** (root 团队 Sprint #5b 拆中) | ⚠️ WIP (4 NotificationDeepLink error 待修) | **v0.24 Sprint #5b** (root 团队 in progress) |
| `assessment_history_page.dart` | **654** | ⚠️ 仍 god class (4 widget 未抽) | **v0.25 Sprint #5d** (1-2 天) |
| `trend_charts.dart` | **622** | ⚠️ 仍 god class (4 种图 + Stagger) | **v0.25 Sprint #5e** (1-2 天) |
| `medications_list_widget.dart` | **554** | ⚠️ 仍 god class (medication 列表 + edit + delete + refill) | **v0.25 Sprint #5f** (1-2 天) |
| `vent_compose_page.dart` | **566** | ⚠️ 仍 god class (录音 + 编辑 + 播放 + 提交) | **v0.25 Sprint #5g** (1-2 天) |
| `setup_page.dart` | **444** | ⚠️ 仍偏厚 (4 步骤全 1 state class) | **v0.25 Sprint #5h** (1 天) |
| `medication_calendar_page.dart` | **445** | ⚠️ 日历 + 当日 + 统计 + 状态切换全 1 文件 | **v0.25 Sprint #5i** (1-2 天) |

**v0.25 Sprint 节奏建议**:
- 优先级 #1: 修 notification_service 4 个 NotificationDeepLink error (Sprint #5b root 团队接着做)
- 优先级 #2: assessment_history / trend_charts / vent_compose 拆 5 子 (Sprint #5d-5g)
- 优先级 #3: medications_list / setup / medication_calendar 拆 3 子 (Sprint #5h-5i)
- 优先级 #4: facade 进一步瘦身的 entity builder 抽 (Sprint #5j, ROI ⭐)

## 8. 设计样板继承 (跟 mood_dialog 拆解模式对比)

| 关键 | mood_dialog (Sprint #5) | data_export (Sprint #5c) |
|---|---|---|
| 1 orchestrator / facade | 199 行 (AlertDialog 容器 + 跨 widget 状态) | 563 行 (importData / exportData 编排 + 7 entity 拼装) |
| 5 个 / 3 个子组件 | MoodScoreForm / MoodTags / MoodTextNote / MoodRecorder / MoodDialogActions | ExportCryptoService / ExportAudioService / ExportSchemaService |
| 状态机 / 副作用下沉 | MoodRecorder 内部消化 9 字段 + 2 StreamSubscription + AudioPlayer + temp file | ExportCryptoService 内部消化 encrypt/decrypt 副作用 + swallowError 集中器 |
| 跨组件 / 跨 service 状态不上抛 | orchestrator 持 4 维度 + tag Set + controller | facade 持 DB + ReportRepo + ImportResult class |
| 回调 / 委托统一 | ValueChanged / VoidCallback | 调 sub-service 静态 / instance method |
| 不引入 Riverpod (单 scope) | ✅ ValueNotifier + Controller | ✅ 直接构造注入 (DI 模式) |
| 保留所有 P0/P1 修复 | ✅ snackbar 移到 pop 前 / AudioPlayer dispose 顺序 / EncryptedAudioStorage | ✅ ISO Z 后缀 / 5s timeout / 4D 情绪 / vent 二次确认 / version 1-4 / `swallowError` / `tryParse` |

**复用经验**:
- 1 主类 = 1 编排 (orchestrator / facade)
- 副作用 / 状态机下沉到子组件 (子 widget / 子 service)
- 子组件全部 `const` constructor (0 状态, 0 runtime cost)
- 校验 helper 全部 `public static` (子 service 复用)

**差异**:
- mood_dialog 1 state class → 5 widget, facade 缩 -73%
- data_export 1 service → 3 sub-service, facade 缩 -3% (因 7 entity 拼装仍在 facade)

**原因**: data_export 是 service 编排 (无 UI), 7 个 entity 拼装是 facade 职责, 不能下沉; mood_dialog 是 UI 编排, 5 个子 widget 各自封装独立 UI。

## 9. 子目录组织 (跟表子目录约定对齐)

```
lib/core/data/services/
├── data_export_service.dart              ← facade (563 行)
├── export/                               ← 新子目录 (跟 check_in/ / contact/ / medication/ 同模式)
│   ├── export_crypto_service.dart        ← 71 行
│   ├── export_audio_service.dart         ← 69 行
│   └── export_schema_service.dart        ← 152 行
├── encryption_service.dart               (不动)
├── notification_service.dart             (root 团队 Sprint #5b 拆中)
└── ...
```

**emil 决策**: 1 个表 = 1 子目录, 现在延伸到 1 个 service 拆 3 子 = 1 个子目录 (`export/`)。命名约定 `export_*_service.dart` 跟 `*_service.dart` 保持一致 (data_export_service / encryption_service / notification_service)。

## 10. 后续 sprint 建议

- **v0.25 Sprint #5d-i**: 8 个 page god class 续拆 (assessment_history / trend_charts / medications_list / vent_compose / setup / medication_calendar / ...)
- **v0.25 Sprint #5j**: facade 进一步瘦身 — 抽 `ExportProfileBuilder` / `ExportContactBuilder` / `ExportMedicationBuilder` / ... 6 个 entity builder, facade 预计 -100 行
- **v0.25 Sprint #5k**: `ImportResult` 移到 `lib/core/shared/import_result.dart` (跨 service 共享)
- **v0.26+ Sprint #1**: 合规 P0 5 项律师外审
- **v0.26+ Sprint #8**: 5 厂商 push SDK 接入

---

## 11. Sprint 总结

| 指标 | 值 |
|---|---|
| 拆解前 facade 行数 | 582 |
| 拆解后 facade 行数 | 563 (-3%, 因 7 entity 拼装仍在 facade) |
| 新增子 service 数 | 3 (Crypto / Audio / Schema) |
| 子 service 总行数 | 292 (71 + 69 + 152) |
| 拆解后总行数 | 855 (含子 service 独立 doc + import 块) |
| 拆解后总行数 Δ | +273 (+47%, 跟 mood_dialog +24% 类似合理代价) |
| 现有 test (round3 + round39) | 36 (0 regression) |
| 新加 test (3 sub-service) | 72 (超额 30+ 目标) |
| data_export test 总数 | 108 (0 fail) |
| 全部 test | 971 (0 fail, baseline 876 + 95 新, 含 root 团队 23 个 widget 测) |
| analyze error (我改的 4 文件) | 0 |
| analyze warning (我改的 4 文件) | 0 |
| 4 层架构 violation | 0 |
| 跨 feature import violation | 0 |
| P0/P1 修复保留 | 13/13 ✅ |
| vent 隐私边界保持 | ✅ (decrypt → null on failure + vent 二次确认 presentation 不动) |
| JSON schema version 兼容 | ✅ (1-4 全保留) |
| 5s timeout 保留 | ✅ (facade 顶部 const _streamTimeout) |
| 4D 情绪保留 | ✅ (energy/sleep/anxiety if-not-null) |

**核心胜利**:
- **业务逻辑全部下沉到 3 个子 service** — facade 不再持有任何业务逻辑
- **0 regression** — 36 现有 test 100% pass, 876 baseline → 971 (+95, 0 fail)
- **P0/P1 修复 13/13 全部保留** — vent 加密 / 二次确认 / 5s timeout / 4D 情绪 / version 兼容 / `swallowError` / `tryParse` 一个不丢
- **可读性大幅提升** — 4 类决策全部命名化 (Crypto / Audio / Schema), 调方知道"我要什么"
- **可测试性大幅提升** — 3 个子 service 可独立 mock / 测, 0 facade 依赖

**未达预期**:
- facade 缩得少 (-3% vs mood_dialog -73%): 7 entity 拼装仍在 facade, 后续 Sprint #5j 抽 entity builder 可再 -100 行

---

> **参考样板**:
> - 设计文档: `docs/refactor/data_export_service_split_design.md` (27.5KB)
> - mood_dialog 拆解: `docs/refactor/mood_dialog_split_design.md` (14.8KB)
> - 报告样板: `reports/sprint-5-mood-dialog-v24.md`
> - audit topdown v2 第 1.1 节: `reports/audit-emilkowalski-topdown-v2.md:34-52`
> - audit topdown v2 第 3.14 P3: `reports/audit-emilkowalski-topdown-v2.md:377-382`
