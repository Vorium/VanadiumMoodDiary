// v0.15 (Round 18) VentRepositoryImpl — data 层 Drift 实现
// v0.21 (Round 22, P0-1) — text 字段级加密，repository 内部处理
//
// 树洞 audio 文件存本地 app docs 目录（[VentAudioStorage] 管理），
// DB 只存文件路径。删除条目时同步删文件。
// 树洞 text 走 EncryptionService 加密后存 BLOB（v0.21 Round 22 起）。
//
// v0.27 round 67 (Sprint 1 上架前 P0, spzh C-P0-6):
// 撤回 vent 同意 → 真正拒绝 add() / restore()。PIPL §14 撤回场景业务层生效。
// 通过构造函数注入 [ConsentGate] (默认 [SharedPrefsConsentGate] 兜底, 测
// 试可 override)。撤回后 throw [VentConsentWithdrawnError], UI 弹
// snackbar 提示"已撤回同意"。

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/vent/vent_mapper.dart';
import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/data/services/vent_audio_storage.dart';
import 'package:chroniccare/core/shared/consent_gate.dart';
import 'package:chroniccare/core/shared/date_time_resolver.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/domain/repositories/vent_repository.dart';

/// v0.27 round 67: 撤回 vent 同意时, add() / restore() 抛此异常
///
/// 业务层抛错, UI 弹 snackbar "已撤回树洞同意, 无法添加新条目"。
/// 见 [ConsentKind.vent] + 隐私政策 §4 撤回同意 + §12 单独同意。
class VentConsentWithdrawnError extends Error {
  final String message;
  VentConsentWithdrawnError([this.message = '已撤回树洞(PIPL §14)同意, 无法添加新条目']);

  @override
  String toString() => 'VentConsentWithdrawnError: $message';
}

/// Vent 仓库的 Drift 实现
class VentRepositoryImpl implements VentRepository {
  final AppDatabase _db;
  final VentAudioStorage _audioStorage;
  final EncryptionService _encryption;
  final ConsentGate _consentGate;

  VentRepositoryImpl(
    this._db, [
    VentAudioStorage? audioStorage,
    EncryptionService? encryption,
    ConsentGate? consentGate,
  ])  : _audioStorage = audioStorage ?? VentAudioStorage(),
        _encryption = encryption ?? EncryptionService(),
        _consentGate = consentGate ?? const SharedPrefsConsentGate();

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
    // v0.27 round 67: PIPL §14 撤回同意 → add 直接拒绝
    if (await _consentGate.isWithdrawn(ConsentKind.vent)) {
      throw VentConsentWithdrawnError();
    }
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
        timestamp: DateTimeResolvers.at(at),
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
