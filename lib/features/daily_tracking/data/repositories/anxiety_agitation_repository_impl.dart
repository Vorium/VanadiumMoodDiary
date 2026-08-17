// v1.1.0+171 R125 (R110 feature-first 阶段 1) — AnxietyAgitationRepositoryImpl
// (样板: 从 lib/core/data/repositories/daily_tracking/anxiety_agitation_repository_impl.dart 迁)
//
// R110 阶段 1 样板迁移验证:
// - 仍 implements 旧路径 AnxietyAgitationRepository (lib/domain/repositories/...)
//   跟新路径 AnxietyAgitationRepository (lib/features/daily_tracking/domain/...)
//   内容相同, 旧 abstract 待 R110 阶段 2 删
// - repository_impl 仍 import 旧 AppDatabase (drift 共享限制, 阶段 3 拆
//   workspace 时跨包共享 challenge)
// - row→entity 翻译走新 mapper (R125 阶段 1 新增)
// - write 操作 (add / delete) 走原 inline 逻辑 (R110 阶段 2 抽 mapper 时再走 mapper)

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/features/daily_tracking/data/mappers/anxiety_agitation_mapper.dart';
import 'package:chroniccare/features/daily_tracking/domain/entities/anxiety_agitation_entry.dart';
import 'package:chroniccare/features/daily_tracking/domain/repositories/anxiety_agitation_repository.dart';
import 'package:drift/drift.dart' show Value;

/// AnxietyAgitation 仓库的 Drift 实现 (R125 阶段 1 样板迁移)
class AnxietyAgitationRepositoryImpl implements AnxietyAgitationRepository {
  final AppDatabase _db;

  AnxietyAgitationRepositoryImpl(this._db);

  @override
  Stream<List<AnxietyAgitationEntryEntity>> watchAll() {
    return _db.anxietyAgitationDao.watchAll().map(
          (rows) => rows.map(anxietyAgitationRowToEntity).toList(growable: false),
        );
  }

  @override
  Future<int> add({
    required DateTime timestamp,
    required int anxietyScore,
    required int agitationScore,
    String? note,
  }) {
    return _db.anxietyAgitationDao.insert(
      AnxietyAgitationEntriesCompanion.insert(
        timestamp: timestamp,
        anxietyScore: anxietyScore,
        agitationScore: agitationScore,
        note: Value(note),
      ),
    );
  }

  @override
  Future<int> delete(int id) {
    return _db.anxietyAgitationDao.delete(id);
  }
}
