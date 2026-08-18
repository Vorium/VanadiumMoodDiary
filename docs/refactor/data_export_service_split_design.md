# data_export_service god class 拆解设计

> **Sprint**: v0.24 Sprint #5c
> **基线**: v0.24 round 45 / 8 commit 落地 / mood_dialog 738→199 刚 commit `7412138`
> **Skill 视角**: emilkowalski (设计工程师 · 状态归属 · facade 模式 · 单一职责 · testability)
> **目标文件**: `lib/core/data/services/data_export_service.dart` (582 行, 1 个 service 装 4 职责)
> **参考样板**: `mood_dialog.dart` 738 → 199 (1 orchestrator + 5 子 widget), 详细见 `mood_dialog_split_design.md`

---

## 1. 现状诊断 (emil 视角)

### 1.1 数字说话

| 指标 | 值 | emil 评估 |
|---|---|---|
| 总行数 | **582** | 远超 god class 阈值 (500+) |
| 业务职责 | **4 类** (导出 / 加密 / 音频 / JSON schema) | 严重违反 SRP |
| public method | **2** (`exportToJson` + `importFromJson`) + `ImportResult` class | 接口简洁但内部 4 决策混在一起 |
| 私有 method | 8 (`_buildVentEntryExport` + 6 `_validate*` + 1 隐式 `_isoUtc` top-level) | 校验逻辑散在 service 内 |
| 测试覆盖 | **50+ case** (round 39 加) | 关键路径已覆盖, 拆解后应保持 100% pass |
| 外部依赖 | `EncryptionService` (单例) + `AppDatabase` + `ReportHistoryRepository` | 单例依赖通过构造注入可解 |
| 行数历史 | 488 → **582** (+94) | **逆增长** — round 39 加 50 test 时把 _validateIntOr / _validateDouble 等 helper 堆进来 |

### 1.2 emil "decisions should be nameable" 检查

`data_export_service.dart` 当前 4 类决策**命名混乱**:

1. **导出决策** (line 75-171 `exportToJson`) — 拉所有 DB 数据 + 拼装 JSON map
2. **加密决策** (line 177-207 `_buildVentEntryExport` + line 431-435 `importFromJson` 内) — vent text encrypt/decrypt + `swallowError` 集中器
3. **音频决策** (line 202-205 + line 441-451) — 实际上只有 metadata 引用 (duration / sizeBytes / hadAudio 标志), 文件本体**不导出**
4. **JSON schema 决策** (line 215-472 + 476-517) — version 1-4 兼容 + 6 个 `_validate*` 静态 helper

**emil 视角**: "decisions that can't be named are usually wrong" — 这 4 类决策**没有清晰命名**, 全在 `DataExportService` 1 个类名下混装, 调用方无法表达"我要的是加密, 不是 schema 校验"。

### 1.3 当前 god class 的 4 类决策混在一起

| 决策类 | 行为 | 副作用 | 失败处理 |
|---|---|---|---|
| **导出** (orchestration) | DB 读 + 拼 JSON map | drift stream (5s timeout) | timeout → 空数组 (P0-3) |
| **加密** (vent text) | AES-256 encrypt/decrypt blob ↔ utf8 string | IO + key cache (单例) | decrypt 失败 → null (P1-5) |
| **音频** (metadata) | 序列化 vent audio 段 (不导文件) | 0 (pure map) | n/a |
| **JSON schema** (validation) | 6 个字段校验 helper + version 范围 | 0 (pure) | 不通过 → skip / default |

---

## 2. 拆解方案 (emil 决策)

### 2.1 拆分原则 (5 条)

1. **3 个子 service + 1 个 facade**: 跟 mood_dialog 5 子 widget + 1 orchestrator 同模式
2. **状态机/副作用下沉到子 service**: encrypt/decrypt 副作用全部进 `ExportCryptoService`; 字段校验纯函数全部进 `ExportSchemaService`
3. **facade 只持跨 service 编排**: importData / exportData 流程编排 + 委托 3 sub-service, **不再持有任何业务逻辑**
4. **构造函数注入 3 sub-service** (DI 模式, 跟 mood_dialog `MoodRecorderController` 同思路)
5. **保留所有 P0/P1 修复**: ISO 8601 Z 后缀 / 5s timeout / 4D 情绪 / vent 二次确认 (presentation 层不动) / version 1-4 兼容 / `swallowError` 模式 / encrypt fail → null

### 2.2 目标文件树

```
lib/core/data/services/
├── data_export_service.dart              (~250 行 — facade: importData / exportData 编排 + ImportResult class)
├── export/
│   ├── export_crypto_service.dart        (~150 行 — vent text encrypt/decrypt 包装 + 密钥管理)
│   ├── export_audio_service.dart         (~100 行 — vent audio metadata 序列化 + 校验)
│   └── export_schema_service.dart        (~120 行 — JSON schema version + 6 个 _validate helper + 旧表删除安全模式)
```

> **新增子目录 `export/`**: 跟 `report_history/` / `check_in/` 1 个表 = 1 子目录的命名约定一致 (v0.18 起的表子目录组织)。

**总行数**: 582 → 250 + 150 + 100 + 120 = **620 行** (分解后总和, 含子 service 独立 doc comment)
**实际效果**: 每个文件 ≤ 250 行, 单一职责, 可独立 mock / 测

### 2.3 数据流 (facade ↔ 3 sub-service)

```
DataExportService (facade)
  ├── _cryptoService: ExportCryptoService
  │     └── _encryption: EncryptionService (单例)
  ├── _audioService: ExportAudioService
  │     └── (无外部依赖 — pure map 操作 + 校验)
  └── _schemaService: ExportSchemaService
        └── (无外部依赖 — pure helper + safe table delete)

exportToJson():
  1. 拉所有 DB (profile / contacts / medications / checkIns / moodEntries / reportHistories / ventEntries)
     ↳ 5s timeout 仍在 facade (P0-3 timeout 修复, 不下沉)
  2. 拼 JSON map:
     - profile / contacts / medications / checkIns / reportHistories / moodEntries: facade 直接拼 (无 sub-service 介入)
     - ventEntries: facade 调 _cryptoService.decryptVentText + _audioService.buildAudioMetadata
  3. JsonEncoder.withIndent('  ') 序列化 (facade 持有)

importFromJson():
  1. jsonDecode + _schemaService.validateVersion
  2. 调 _db.transaction:
     a. 清表 (facade 调 _schemaService.deleteOldDataSafely 3 次, 旧表缺失容错)
     b. profile / contacts / medications / checkIns: facade 直接处理 (用 _schemaService.validateXxx 静态 helper)
     c. reportHistories + moodEntries (version >= 2): facade 直接处理
     d. ventEntries (version >= 3): facade 调 _cryptoService.encryptVentText + _audioService.parseAudio*
  3. 拼 ImportResult (facade 持有)
```

### 2.4 3 个子 service 接口 (emil "decisions should be nameable")

#### `ExportCryptoService` (~150 行)

```dart
/// 树洞文字 encrypt/decrypt 包装 — v0.21 Round 22 P0-3 拆出
///
/// 职责: AES-256 encrypt/decrypt blob ↔ utf8 string
/// 失败处理: decrypt 失败 → null (PKCS7 pad 错误不抛, v0.23 round 39 P1-5 修复保留)
/// 依赖: EncryptionService (单例, DI 可注入 mock)
class ExportCryptoService {
  ExportCryptoService([EncryptionService? encryption])
    : _encryption = encryption ?? EncryptionService();

  final EncryptionService _encryption;

  /// 解密 vent 文字 BLOB → utf8 字符串
  ///
  /// 失败 (PKCS7 pad / data corruption) → 返回 null, 不抛异常
  Future<String?> decryptVentText(Uint8List? blob) async {
    if (blob == null) return null;
    try {
      final plain = await _encryption.decrypt(Uint8List.fromList(blob));
      return utf8.decode(plain);
    } catch (e, st) {
      swallowError(
        where: 'ExportCryptoService.decryptVentText',
        error: e,
        stack: st,
        note: 'vent 文字 decrypt 失败 (PKCS7 pad / data corruption), 视为无文字',
      );
      return null;
    }
  }

  /// 加密 vent 文字 utf8 string → BLOB (供 insertVentEntry.contentTextEnc)
  ///
  /// 空字符串 → null (跟 decryptVentText 对称)
  Future<Uint8List?> encryptVentText(String? text) async {
    if (text == null || text.isEmpty) return null;
    return _encryption.encrypt(Uint8List.fromList(utf8.encode(text)));
  }
}
```

**责任**: vent 文字加密/解密的副作用封装。**单一职责** — 不管 JSON 拼装, 不管字段校验。
**emil 决策**: decrypt 失败 → null (跟 `int? _validateInt` 风格一致, **决策可命名**: `decryptVentText → null on failure`)。
**testability**: 可注入 `EncryptionService` mock, 测 decrypt 失败 → null 的容错路径。

#### `ExportAudioService` (~100 行)

```dart
/// 树洞 audio metadata 序列化 + 校验 — v0.24 round 45 抽
///
/// **关键约束**: vent audio 文件**不导出** (跨设备路径失效),
/// 只导出 metadata 引用 (duration / sizeBytes / hadAudio 标志)。
/// 重装 → 导入后, 文字会恢复, 录音会标 `hasAudio=false`。
class ExportAudioService {
  const ExportAudioService();

  /// 序列化 vent 段 audio 字段
  ///
  /// 跨设备不可用 → audioPath 永不导出
  Map<String, dynamic> buildAudioMetadata({
    required int? audioDurationSec,
    required int? audioSizeBytes,
    required String? audioPath,  // 仅作 `hadAudio` 标志用
  }) {
    return {
      'audioDurationSec': audioDurationSec,
      'audioSizeBytes': audioSizeBytes,
      if (audioPath != null) 'hadAudio': true,
    };
  }

  /// 校验 + 解析 audio 段字段 (import 时用)
  ///
  /// 跟 facade 其他 _validateXxx 模式一致, 但参数化 max 边界
  int parseAudioDurationSec(dynamic v, {int defaultValue = 0}) =>
      ExportSchemaService.validateIntOr(v, defaultValue, min: 0, max: 86400);

  int parseAudioSizeBytes(dynamic v, {int defaultValue = 0}) =>
      ExportSchemaService.validateIntOr(v, defaultValue, min: 0, max: 1073741824);  // 1GB
}
```

**责任**: vent audio metadata 序列化 + 校验。**单一职责** — 不管加密, 不管 JSON 顶层拼装。
**emil 决策**: max 86400s (24h) / 1GB hardcode 走 `ExportSchemaService.validateIntOr` 静态 helper 复用, 不再散在 facade。
**testability**: pure function 0 外部依赖, 易测。

#### `ExportSchemaService` (~120 行)

```dart
/// JSON schema version 管理 + 字段校验 helper — v0.24 round 45 抽
///
/// 职责:
/// 1. version 1-4 范围校验 (P0 兼容, 不破坏老用户数据)
/// 2. 6 个字段类型 + 长度 + pattern 校验 (static helper, 纯函数)
/// 3. 旧 schema 缺失表的安全删除 (P1-10 fix: 不再 catch(_) 完全静默)
class ExportSchemaService {
  const ExportSchemaService();

  /// 当前 schema 版本 (v0.18: 加入 4D 情绪 = version 4)
  static const int currentVersion = 4;

  /// 校验 JSON version 字段
  ///
  /// 返回 version 整数, 不通过 (非 int / 范围错) → null (facade 负责翻译成 ImportResult.failure)
  int? validateVersion(dynamic v) {
    if (v is! int || v < 1 || v > currentVersion) return null;
    return v;
  }

  /// 安全删除表 (旧 schema 缺失容错, v0.23 round 39 P1-10 fix)
  Future<void> deleteOldDataSafely(AppDatabase db, TableInfo table, {String? label}) async {
    try {
      await db.delete(table).go();
    } catch (e, st) {
      swallowError(
        where: 'ExportSchemaService.deleteOldDataSafely(${label ?? 'unknown'})',
        error: e,
        stack: st,
        note: '表不存在(旧 schema),忽略',
      );
    }
  }

  // ===== 6 个字段校验 helper (static, pure) =====

  static String? validateString(
    dynamic v,
    String field, {
    int maxLen = 1000,
    RegExp? pattern,
  });

  static int? validateInt(dynamic v, int? defaultValue, {int? min, int? max});

  /// 非空默认值场景: 直接返回 int (validateInt 返回 int? 但 defaultValue 兜底)
  static int validateIntOr(dynamic v, int defaultValue, {int? min, int? max});

  static double? validateDouble(dynamic v);

  /// DateTime 解析 (v0.21 P0-2 fix: 用 tryParse 替代 try/catch)
  static DateTime? validateDate(dynamic v);
}
```

**责任**: JSON schema version 校验 + 字段类型校验 + 旧表缺失容错。**单一职责** — 不管加密, 不管音频。
**emil 决策**: 6 个 `_validate*` 全部下沉, 命名保留 `_validate*` → `validate*` 去掉下划线 (public static, 跟 `EncryptionService` 风格一致)。
**testability**: 纯函数 + 静态方法, 0 mock 成本, 单元测试覆盖率 100% 容易达成。

### 2.5 facade `data_export_service.dart` (~250 行)

```dart
class DataExportService {
  final AppDatabase _db;
  final ReportHistoryRepository _reportRepo;
  final ExportCryptoService _cryptoService;
  final ExportAudioService _audioService;
  final ExportSchemaService _schemaService;

  DataExportService(
    this._db, [
    ReportHistoryRepository? reportRepo,
    EncryptionService? ventTextEncryption,  // 兼容老构造签名
  ])  : _reportRepo = reportRepo ?? ReportHistoryRepositoryImpl(_db),
        _cryptoService = ExportCryptoService(ventTextEncryption),
        _audioService = const ExportAudioService(),
        _schemaService = const ExportSchemaService();

  /// 导出所有数据为 JSON 字符串
  ///
  /// 编排: 拉 DB → 拼 JSON map (委托 3 sub-service) → JsonEncoder
  Future<String> exportToJson({DateTime? now}) async {
    final profile = await _db.getUserProfile();
    const _streamTimeout = Duration(seconds: 5);  // P0-3 timeout 修复, 留在 facade
    final contacts = await _db.watchContacts().first.timeout(_streamTimeout, onTimeout: () => const []);
    final medications = await _db.watchMedications().first.timeout(_streamTimeout, onTimeout: () => const []);
    final checkIns = await _db.watchAllCheckIns().first.timeout(_streamTimeout, onTimeout: () => const []);
    final reportHistories = await _reportRepo.getAll();
    final moodEntries = await _db.getAllMoodEntries();
    final ventEntries = await _db.watchVentEntries().first.timeout(_streamTimeout, onTimeout: () => const []);

    final data = {
      'version': ExportSchemaService.currentVersion,
      'exportedAt': _isoUtc(now ?? DateTime.now()),
      'profile': profile == null ? null : {
        'userName': profile.userName,
        'checkInCycleHours': profile.checkInCycleHours,
        'firstLaunchAt': _isoUtc(profile.firstLaunchAt),
        if (profile.lastCheckInAt != null) 'lastCheckInAt': _isoUtc(profile.lastCheckInAt!),
      },
      'contacts': [for (final c in contacts) {
        'name': c.name, 'phone': c.phone,
        'sortOrder': c.sortOrder, 'isActive': c.isActive,
      }],
      'medications': [for (final m in medications) {
        'name': m.name, 'dosage': m.dosage, 'dosageUnit': m.dosageUnit,
        'timesJson': m.timesJson, 'startDate': _isoUtc(m.startDate),
        'isActive': m.isActive,
      }],
      'checkIns': [for (final c in checkIns) {
        'timestamp': _isoUtc(c.timestamp), 'type': c.type,
        'medicationId': c.medicationId, 'note': c.note,
      }],
      'reportHistories': [for (final h in reportHistories) {
        'windowDays': h.windowDays, 'generatedAt': _isoUtc(h.generatedAt),
        'userName': h.userName, 'reportText': h.reportText,
      }],
      'moodEntries': [for (final m in moodEntries) {
        'timestamp': _isoUtc(m.timestamp), 'score': m.score,
        if (m.energy != null) 'energy': m.energy,
        if (m.sleep != null) 'sleep': m.sleep,
        if (m.anxiety != null) 'anxiety': m.anxiety,
        'tagsJson': m.tagsJson, 'note': m.note,
      }],
      'ventEntries': [
        for (final v in ventEntries) {
          'timestamp': _isoUtc(v.timestamp),
          'contentText': await _cryptoService.decryptVentText(v.contentTextEnc),  // 委托
          ..._audioService.buildAudioMetadata(  // 委托
            audioDurationSec: v.audioDurationSec,
            audioSizeBytes: v.audioSizeBytes,
            audioPath: v.audioPath,
          ),
        },
      ],
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// 从 JSON 字符串导入数据
  Future<ImportResult> importFromJson(String json) async {
    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      final version = _schemaService.validateVersion(data['version']);  // 委托
      if (version == null) {
        return ImportResult.failure('数据版本不匹配（期望 1-${ExportSchemaService.currentVersion}, 实际 ${data['version']}）');
      }

      // 计数 + 清表 + insert — 委托 _schemaService.validateXxx 静态 helper
      int contactCount = 0, medicationCount = 0, checkInCount = 0,
          reportHistoryCount = 0, moodEntryCount = 0, ventEntryCount = 0;

      await _db.transaction(() async {
        await _db.delete(_db.checkIns).go();
        await _db.delete(_db.medications).go();
        await _db.delete(_db.contacts).go();
        await _schemaService.deleteOldDataSafely(_db, _db.reportHistories, label: 'reportHistories');
        await _schemaService.deleteOldDataSafely(_db, _db.moodEntries, label: 'moodEntries');
        await _schemaService.deleteOldDataSafely(_db, _db.ventEntries, label: 'ventEntries');

        // profile + 6 类 entity insert (用 _schemaService.validateXxx 静态 helper)
        // ... (省略, 跟原 facade 同结构)

        // ventEntries (version >= 3): facade 调 _cryptoService.encryptVentText
        if (version >= 3) {
          for (final v in (data['ventEntries'] as List? ?? [])) {
            if (v is! Map) continue;
            final m = v;
            final ts = ExportSchemaService.validateDate(m['timestamp']);
            if (ts == null) continue;
            final text = ExportSchemaService.validateString(m['contentText'], 'vent.text', maxLen: 100000);
            final encText = await _cryptoService.encryptVentText(text);  // 委托
            await _db.insertVentEntry(VentEntriesCompanion.insert(
              timestamp: ts,
              contentTextEnc: Value(encText),
              audioDurationSec: Value(_audioService.parseAudioDurationSec(m['audioDurationSec'])),  // 委托
              audioSizeBytes: Value(_audioService.parseAudioSizeBytes(m['audioSizeBytes'])),  // 委托
            ));
            ventEntryCount++;
          }
        }
      });

      return ImportResult.success(...);
    } catch (e, st) {
      piiSafeLog('DataExportService', 'importFromJson error: $e\n$st');
      return ImportResult.failure('解析失败：数据格式不正确，请确认是从本 App 导出的 JSON');
    }
  }
}

class ImportResult { ... }  // 保留, 不动
```

**emil 决策**: facade 用 3 个子 service 委托, **业务逻辑全部下沉**, facade 只剩"拉数据 + 拼 JSON"2 件事。

---

## 3. 关键设计决策 (emil 决策框架)

### 3.1 决策 1: 3 个子 service vs 4 个?

| 候选 | 优劣 |
|---|---|
| **A. 3 个子 service (Crypto / Audio / Schema)** ✅ | 跟 task 描述对齐 + 命名清晰 + 各 ≤ 150 行 |
| B. 4 个子 service (按 entity 拆: Profile / Contact / Medication / ...) | 过度拆, 6 类 entity 各自 1 service 会爆 6 文件, 大部分都是 facade 内的 for 循环直拼 |
| C. 2 个子 service (Crypto + Schema, Audio 并入 facade) | Audio 段虽然短, 但 86400s / 1GB 边界校验有独立价值 |

**决策**: A。3 个子 service 各司其职, Audio 单独抽是因为它的 max 86400s / 1GB hardcode + `hadAudio` 标志是 1 个明确决策集。

### 3.2 决策 2: 校验 helper 公开还是私有?

| 候选 | 优劣 |
|---|---|
| **A. `ExportSchemaService.validateXxx` (public static)** ✅ | 子 service 可复用 (ExportAudioService.parseAudioDurationSec 调 validateIntOr), 测试可直接 import |
| B. 私有 helper, 子 service 不能复用 | 重复代码 + Audio 段的 max 86400s 边界可能飘 |

**决策**: A。`validateXxx` 全 public static, ExportAudioService 复用 `validateIntOr`。

### 3.3 决策 3: 构造签名向后兼容?

| 候选 | 优劣 |
|---|---|
| **A. 保留 `DataExportService(db, [reportRepo, ventTextEncryption])` 3 参数** ✅ | 现有 50+ test 不用改, 跟 round 39 P1-5 加 test 时的签名一致 |
| B. 改 `DataExportService(db, {crypto, audio, schema})` 命名参数 | test 全部要改, ROI 低 |

**决策**: A。保持现有构造签名, 内部把 `ventTextEncryption` 委托给 `ExportCryptoService(ventTextEncryption)`。

### 3.4 决策 4: 5s timeout 在 facade 还是 sub-service?

**emil "频度决策"**: timeout 修复是 1 次性 P0-3 保护, 不属于 4 类决策任一。
**决策**: **保留在 facade `exportToJson` 顶部**。sub-service 0 阻塞 IO (pure map + 加密 < 1s), timeout 只防 drift stream hang。

### 3.5 决策 5: vent 隐私边界怎么保留?

| 来源 | 修复 | 保留位置 |
|---|---|---|
| v0.22 round 32 (spzh 合规) | vent 二次确认 dialog (presentation 层) | **不动** (presentation 决定, service 不感知) |
| v0.21 Round 22 (P0-3) | vent 文字导出时 decrypt 给明文, 导入时再 encrypt | 委托给 `ExportCryptoService.decryptVentText / encryptVentText` |
| v0.23 round 39 (P1-5) | decrypt 失败 → null (PKCS7 pad 容错) | 委托给 `ExportCryptoService.decryptVentText` (内部 catch + swallowError) |

**决策**: vent 二次确认**presentation 层不动**; 数据层隐私边界 (decrypt → null on failure) 委托给 `ExportCryptoService`。

### 3.6 决策 6: 旧 schema 缺失表的安全删除 (P1-10)

| 来源 | 修复 | 保留位置 |
|---|---|---|
| v0.23 round 39 (P1-10) | `try { await _db.delete(table).go(); } catch (_) { ... }` 走 `swallowError` 集中器 | 委托给 `ExportSchemaService.deleteOldDataSafely` |

**决策**: facade 3 处 `try { delete } catch (e, st) { swallowError(...) }` 全部下沉到 `ExportSchemaService.deleteOldDataSafely(db, table, label: '...')`。

---

## 4. 验证策略

### 4.1 静态验证

```bash
flutter analyze         # 0 error (44 info-level 已有, 不回归)
flutter test            # 876 cases pass (不回归, 重点跑 data_export test)
dart scripts/check_all.dart  # 4 层架构 0 violation
```

### 4.2 测试覆盖

| 文件 | 行数 | 现有 test |
|---|---|---|
| `data_export_service.dart` (facade) | ~250 | `data_export_round39_test.dart` (50+ case) + `data_export_round3_test.dart` (12 case) — **全保持 pass** |
| `export/export_crypto_service.dart` (新增) | ~150 | 新加: `data_export_crypto_round45_test.dart` (decrypt 失败 → null, encrypt 空 → null, encrypt → decrypt round-trip) |
| `export/export_audio_service.dart` (新增) | ~100 | 新加: `data_export_audio_round45_test.dart` (buildAudioMetadata 3 字段, parseAudioDurationSec 边界, parseAudioSizeBytes 1GB 边界) |
| `export/export_schema_service.dart` (新增) | ~120 | 新加: `data_export_schema_round45_test.dart` (validateVersion 1-4, validateInt/IntOr/String/Double/Date, deleteOldDataSafely 旧表缺失) |

**新 test 目标**: 4 文件覆盖 3 sub-service, ~30+ case (decrypt 容错 + audio 边界 + schema 6 helper)。

### 4.3 行为不变性 (P0/P1 不回归)

| P0/P1 修复 | 来源 | 保留位置 |
|---|---|---|
| ISO 8601 Z 后缀 | v0.21 P0-3 (避免跨时区瞬移) | `_isoUtc` helper 仍在 facade 顶部 |
| 5s timeout | v0.23 round 40 (P2 防 drift stream hang) | facade `exportToJson` 顶部 `const _streamTimeout = Duration(seconds: 5)` |
| 4D 情绪 (energy/sleep/anxiety) | v0.18 round 14 | facade `moodEntries` 段 `if (m.energy != null) 'energy': m.energy` |
| vent 文字 decrypt → 明文 | v0.21 Round 22 (P0-3) | 委托 `_cryptoService.decryptVentText(v.contentTextEnc)` |
| vent 文字 encrypt → blob | v0.21 Round 22 (P0-3) | 委托 `_cryptoService.encryptVentText(text)` |
| decrypt 失败 → null | v0.23 round 39 (P1-5) | `ExportCryptoService.decryptVentText` 内部 catch + swallowError |
| 旧 schema 缺失表 → swallowError | v0.23 round 39 (P1-10) | 委托 `_schemaService.deleteOldDataSafely` |
| version 1-4 范围校验 | v0.22 round 30 (P0) | `ExportSchemaService.validateVersion` |
| 6 个字段校验 helper (length/pattern/range) | v0.7 始 | `ExportSchemaService.validate*` 6 个 static helper |
| 解析失败 → 脱敏错误 | v0.7 P12 fix | facade `importFromJson` catch 块不动 |
| `tryParse` 替代 try/catch | v0.21 P0-2 (try/catch 反模式) | `ExportSchemaService.validateDate` 内部用 `DateTime.tryParse` |
| error log 走 `piiSafeLog` | v0.23 round 40 | facade `importFromJson` catch 块 `piiSafeLog('DataExportService', ...)` |
| vent 二次确认 (presentation) | v0.22 round 32 spzh 合规 | **不动** (presentation 层决定) |

---

## 5. 工作量估算

| 步骤 | 工作量 |
|---|---|
| Step 1: 3 个子 service 抽出 | 🟠 3-4 小时 |
| Step 2: facade 重新组装 + DI 注入 | 🟢 1 小时 |
| Step 3: 3 个新 test 文件 (~30 case) | 🟠 1-2 小时 |
| Step 4: 全量验证 (analyze + test + check_all) | 🟢 30 分钟 |
| **合计** | **🟠 半天 (5-7 小时)** |

---

## 6. 风险评估

| 风险 | 概率 | 缓解 |
|---|---|---|
| 现有 50+ test 失效 | 🟢 低 | 构造签名不变, 3 sub-service 行为跟原 facade 完全一致 |
| decrypt 容错路径漂移 | 🟡 中 | `ExportCryptoService.decryptVentText` 内 catch all + `swallowError` 完整保留 + 新加 test 覆盖 |
| 子 service 间循环依赖 | 🟢 低 | 3 sub-service 互相无依赖, 各自依赖 (EncryptionService / TableInfo / 静态) |
| 旧表缺失容错漂移 | 🟡 中 | `deleteOldDataSafely` 走 `swallowError` 集中器, 新加 test 覆盖 "表不存在" 路径 |
| `ExportSchemaService.validate*` 公开破坏封装 | 🟢 低 | 全 static, 无 instance state, 等同 utility, Flutter 项目惯例 |

---

## 7. 不在本次 scope

- ❌ notification_service 拆 3 orchestrator (P0 god class 候选 #1, 留给 Sprint #5b)
- ❌ vent_compose_page 拆 3 子 widget (P2 god class, 留给 v0.25)
- ❌ 14 处 `color.withValues(alpha:)` 散落 (tinted 集中化)
- ❌ 13+ ListTile → AppListTile 替换
- ❌ vent 二次确认 dialog (presentation 层, 不动)
- ❌ EncryptionService 内部重构 (单例 + key cache 不动)
- ❌ `_isoUtc` 抽到 `core/shared/formatters.dart` (P3 小事, 留给后续)

**本次只动 `data_export_service.dart` + 新增 3 个子 service + 新增 3 个 test 文件**。

---

## 8. 参考样板: mood_dialog 拆解成功关键

| 关键 | 体现 |
|---|---|
| 1 dialog = 1 orchestrator | 199 行, 仅 AlertDialog 容器 + 跨 widget 状态 |
| 5 个子 widget 各管自己职责 | MoodScoreForm / MoodTags / MoodTextNote / MoodRecorder / MoodDialogActions |
| 状态机下沉 | MoodRecorder 内部消化 9 个字段 + 2 StreamSubscription + AudioPlayer + temp file |
| 跨 widget 状态不上抛 | orchestrator 持 4 维度 + tag Set + controller, 子 widget 全 callback 透传 |
| 回调统一 `ValueChanged / VoidCallback` | 不用 Riverpod (单 dialog scope) |

**data_export 拆解关键 (跟 mood_dialog 同)**:
- 1 service = 1 facade (~250 行, importData / exportData 编排)
- 3 个子 service 各管自己职责 (Crypto / Audio / Schema)
- 副作用下沉 (decrypt/encrypt → ExportCryptoService, 旧表删除 → ExportSchemaService)
- 跨 service 状态不上抛 (facade 持 DB + ReportRepo, 拉数据 + 拼 JSON, 委托 3 sub-service)
- 不用 Riverpod (单 service scope, 直接构造注入 DI)

---

## 9. 拆解后预期 (目标数字)

| 文件 | 拆解前 | 拆解后 | Δ | 状态 |
|---|---|---|---|---|
| `data_export_service.dart` (facade) | **582** | **~250** | **-57%** | ✅ 大幅瘦身 |
| `export/export_crypto_service.dart` | 0 | ~150 | new | ✅ 副作用封装 |
| `export/export_audio_service.dart` | 0 | ~100 | new | ✅ 音频元数据 |
| `export/export_schema_service.dart` | 0 | ~120 | new | ✅ 校验集中 |
| **总** | **582** | **~620** | +38 | (+6% 注释/接口开销, 跟 mood_dialog +24% 类似合理) |
| 现有 test (`data_export_round39_test.dart` + `round3`) | 60+ | 60+ | 0 | ✅ 不回归 |
| 新加 test (3 sub-service 各 1 文件) | 0 | 30+ | +30 | ✅ 拆解同步 |
| **总 test** | **876** | **906+** | **+30** | ✅ 基线不回归 + 新覆盖 |

**验证目标**:
- `flutter analyze` 0 error
- `flutter test` 906+ pass (876 baseline + 30 新 case)
- `dart scripts/check_all.dart` 4 层架构 0 violation
- vent 隐私边界 (decrypt → null on failure) 保持
- JSON schema version 1-4 兼容
- 5s timeout 保留
- 4D 情绪保留
