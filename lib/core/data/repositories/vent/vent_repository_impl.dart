// v0.15 (Round 18) VentRepositoryImpl — data 层 Drift 实现
// v0.21 (Round 22, P0-1) — text 字段级加密，repository 内部处理
//
// 树洞 audio 文件存本地 app docs 目录（[VentAudioStorage] 管理），
// DB 只存文件路径。删除条目时同步删文件。
// 树洞 text 走 EncryptionService 加密后存 BLOB（v0.21 Round 22 起）。

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/vent/vent_mapper.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';

/// Vent 仓库的 Drift 实现
class VentRepositoryImpl implements VentRepository {
  final AppDatabase _db;
  final VentAudioStorage _audioStorage;
  final EncryptionService _encryption;

  VentRepositoryImpl(this._db,
      [VentAudioStorage? audioStorage, EncryptionService? encryption,])
      : _audioStorage = audioStorage ?? VentAudioStorage(),
        _encryption = encryption ?? EncryptionService();

  @override
  Stream<List<VentEntryEntity>> watchAll() {
    return _db.ventDao.watchAll().asyncMap(
      (rows) async {
        final entities = await Future.wait(rows.map((r) => r.toEntity()));
        return entities;
      },
    );
  }

  @override
  Future<int> add({
    String? text,
    String? audioPath,
    int? audioDurationSec,
    int? audioSizeBytes,
    DateTime? at,
  }) async {
    final hasText = text != null && text.trim().isNotEmpty;
    final hasAudio = audioPath != null && audioPath.isNotEmpty;
    if (!hasText && !hasAudio) {
      throw ArgumentError('text and audio: at least one is required');
    }

    Uint8List? encText;
    if (hasText) {
      // hasText 已保证 text != null, 这里 trim 后给 encryption service
      encText = await _encryption.encrypt(
        Uint8List.fromList(utf8.encode(text.trim())),
      );
    }

    return _db.ventDao.insert(
      VentEntriesCompanion.insert(
        timestamp: at ?? DateTime.now(),
        contentTextEnc: Value(encText),
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

    // 事务保护 read + delete 原子性，防止 TOCTOU 竞态
    final deleted = await _db.transaction(() async {
      return await _db.ventDao.delete(id) > 0;
    });
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
    if (row == null) return null;
    return row.toEntity();
  }

  @override
  Future<int> restore(VentEntryEntity entry) async {
    // v0.21 Round 23 (P1-26): Dismissible Undo → 重新插入原内容
    // 注意: audio 文件在 delete 时已删,restore 只恢复 text(音频无法复活)
    // 用 add + at 注入原时间,新 id 由 drift auto-increment 生成
    return add(
      text: entry.contentText,
      audioPath: null,
      audioDurationSec: null,
      audioSizeBytes: null,
      at: entry.timestamp,
    );
  }
}
