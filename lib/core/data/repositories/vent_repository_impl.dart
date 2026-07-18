// v0.15 (Round 18) VentRepositoryImpl — data 层 Drift 实现
//
// 树洞 audio 文件存本地 app docs 目录（[VentAudioStorage] 管理），
// DB 只存文件路径。删除条目时同步删文件。
library;

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/vent_entry.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/vent/vent_mapper.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';

/// Vent 仓库的 Drift 实现
class VentRepositoryImpl implements VentRepository {
  final AppDatabase _db;
  final VentAudioStorage _audioStorage;

  VentRepositoryImpl(this._db, [VentAudioStorage? audioStorage])
      : _audioStorage = audioStorage ?? VentAudioStorage();

  @override
  Stream<List<VentEntryEntity>> watchAll() {
    return _db
        .watchVentEntries()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    DateTime? at,
  }) {
    final hasText = text != null && text.trim().isNotEmpty;
    final hasAudio = audioPath != null && audioPath.isNotEmpty;
    if (!hasText && !hasAudio) {
      throw ArgumentError('text 和 audio 至少要有一个');
    }

    return _db.insertVentEntry(
      VentEntriesCompanion.insert(
        timestamp: at ?? DateTime.now(),
        contentText: Value(hasText ? text.trim() : null),
        audioPath: Value(hasAudio ? audioPath : null),
        audioDurationSec: Value(audioDurationSec),
        audioSizeBytes: Value(audioSizeBytes),
      ),
    );
  }

  @override
  Future<bool> delete(int id) async {
    // 先查一下，看有没有 audio 路径要一起删
    final entry = await (_db.select(_db.ventEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    if (entry == null) return false;

    // 删 DB 行
    final deleted = await _db.deleteVentEntry(id) > 0;
    if (!deleted) return false;

    // 删 audio 文件（best-effort，失败不影响）
    final path = entry.audioPath;
    if (path != null && path.isNotEmpty) {
      await _audioStorage.deleteAudio(path);
    }
    return true;
  }

  @override
  Future<VentEntryEntity?> getById(int id) async {
    final row = await (_db.select(_db.ventEntries)
          ..where((t) => t.id.equals(id)))
        .getSingleOrNull();
    return row?.toEntity();
  }
}
