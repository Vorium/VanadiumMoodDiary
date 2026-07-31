// v0.15 (Round 18) VentMapper — Drift row ↔ domain entity
// v0.21 (Round 22, P0-1) — text 字段升级为 BLOB 加密，加解密在 mapper 里
//
// 边界处的翻译官。Drift schema 变化时只改这里，UI 拿到的 entity 保持稳定。
// toEntity / toCompanion 都变 async（加解密依赖 async EncryptionService）。

import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;

import 'package:chroniccare/core/data/services/encryption_service.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/entities/vent_entry_entity.dart';
import 'package:chroniccare/core/data/database/app_database.dart';

/// 全局 vent text 加密服务（懒加载 + 内存缓存 key）
final _ventTextEncryption = EncryptionService();

/// Drift row → entity (async 因为要 decrypt)
extension VentToEntity on VentEntry {
  Future<VentEntryEntity> toEntity() async {
    String? text;
    final blob = contentTextEnc;
    if (blob != null) {
      try {
        final plain =
            await _ventTextEncryption.decrypt(Uint8List.fromList(blob));
        text = utf8.decode(plain);
      } catch (e, st) {
        // 解密失败 = 旧 schema 残留 / key 损坏 / 迁移失败 → 视为空。
        // SchemaVersion 9 migration 应该已经一次性加密所有旧数据,
        // 这里只是兜底,**不应**正常触发。
        swallowError(where: 'VentMapper.toEntity', error: e, stack: st);
      }
    }
    return VentEntryEntity(
      id: id,
      timestamp: timestamp,
      contentText: text,
      audioPath: audioPath,
      audioDurationSec: audioDurationSec,
      audioSizeBytes: audioSizeBytes,
    );
  }
}

/// entity → Drift row
extension VentEntryEntityToDrift on VentEntryEntity {
  /// 构造 insert 用的 Companion (async 因为要 encrypt)
  Future<VentEntriesCompanion> toCompanion() async {
    Uint8List? encText;
    final text = contentText;
    if (text != null && text.trim().isNotEmpty) {
      encText = await _ventTextEncryption
          .encrypt(Uint8List.fromList(utf8.encode(text)));
    }
    return VentEntriesCompanion(
      id: id == 0 ? const Value.absent() : Value(id),
      timestamp: Value(timestamp),
      contentTextEnc: Value(encText),
      audioPath: Value(audioPath),
      audioDurationSec: Value(audioDurationSec),
      audioSizeBytes: Value(audioSizeBytes),
    );
  }
}

// 因为 entity 跟 Drift row 同名（都是 VentEntry），需要给其中一个起别名
// 这里用 `VentEntryEntity` 做 domain 实体名，Drift row 沿用 VentEntry。
// 但 extension 用了 import 'app_database.dart' 拿到 Drift 的 VentEntry，
// 所以这个文件里 VentEntry 默认指 Drift row。
