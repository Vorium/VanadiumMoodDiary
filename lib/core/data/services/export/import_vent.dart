// 树洞导入 — v1.1.0 R113 wave 5 (gdc P1-7 god class 拆分)
//
// 从 export_import_pipeline.dart 抽出 (R77/R112-ARCH-03 的 4 子任务之一
// _importVent), 按 R113 gdc 审计建议按实体簇拆 3 文件之一:
//   - import_vent.dart (本文件): vent entries (录音路径永远丢弃)
//   - import_profile.dart: user profile (全局单条)
//   - import_entities.dart: medications / checkIns / reportHistories /
//     moodEntries / worryThreads + 6 张 daily tracking 表
//   - import_shared.dart: ImportResultBuilder 共享聚合器
//
// PURE MOVE: 函数体逐行不变, 只换文件。兜底测试:
// export_import_pipeline_round99 (vent 加密 round-trip) / data_export_v6 等。

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/export/export_audio_service.dart';
import 'package:chroniccare/core/data/services/export/export_crypto_service.dart';
import 'package:chroniccare/core/data/services/export/export_schema_service.dart';
import 'package:chroniccare/core/data/services/export/import_shared.dart';

/// 子任务 4/4: vent_entries 文字导入 (录音路径永远丢弃, 跨设备不可用)。
/// version 3+ 才有, 老导出文件没这段也兼容。
/// v0.21 Round 22: 文字从 JSON 读出是明文, 导入时 encrypt 写回 BLOB。
Future<void> importVent(
  AppDatabase db,
  ExportCryptoService cryptoService,
  ExportAudioService audioService,
  Map<String, dynamic> data,
  int version,
  ImportResultBuilder counts,
) async {
  if (version < 3) return;
  for (final v in (data['ventEntries'] as List? ?? [])) {
    if (v is! Map) continue;
    final m = v;
    final ts = ExportSchemaService.validateDate(m['timestamp']);
    if (ts == null) continue;
    // 文字可以很大 (树洞常长篇), 放宽到 100k
    final text = ExportSchemaService.validateString(
      m['contentText'],
      'vent.text',
      maxLen: 100000,
    );
    // 委托 ExportCryptoService.encryptVentText — encrypt 副作用下沉
    final encText = await cryptoService.encryptVentText(text);
    await db.ventDao.insert(
      VentEntriesCompanion.insert(
        timestamp: ts,
        contentTextEnc: Value(encText),
        // audioPath 永远 null — 旧路径在重装后失效
        audioDurationSec: Value(
          audioService.parseAudioDurationSec(m['audioDurationSec']),
        ),
        audioSizeBytes: Value(
          audioService.parseAudioSizeBytes(m['audioSizeBytes']),
        ),
        tagsJson: Value(
          ExportSchemaService.validateString(
                m['tagsJson'],
                'vent.tagsJson',
                maxLen: 1000,
              ) ??
              '[]',
        ),
      ),
    );
    counts.ventEntryCount++;
  }
}
