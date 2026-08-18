// v1.1.0 round 9 (F1 烦恼闭环): WorryThreadRepositoryImpl — data 层 Drift 实现
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/database/mappers/worry/worry_thread_mapper.dart';
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';
import 'package:chroniccare/domain/repositories/worry_thread_repository.dart';

class WorryThreadRepositoryImpl implements WorryThreadRepository {
  final AppDatabase _db;

  WorryThreadRepositoryImpl(this._db);

  @override
  Stream<List<WorryThreadEntity>> watchOpen() {
    return _db.worryDao
        .watchOpen()
        .map((rows) => rows.map((r) => r.toEntity()).toList(growable: false));
  }

  @override
  Stream<List<WorryThreadEntity>> watchResolved() {
    return _db.worryDao.watchResolved().map(
          (rows) => rows.map((r) => r.toEntity()).toList(growable: false),
        );
  }

  @override
  Future<WorryThreadEntity?> getById(int id) async {
    final row = await _db.worryDao.getById(id);
    return row?.toEntity();
  }

  @override
  Future<int> create({required String title, required DateTime at}) {
    return _db.worryDao.insert(title: title, createdAt: at);
  }

  @override
  Future<int> resolve(int id, {required DateTime at}) {
    return _db.worryDao.resolve(id, resolvedAt: at);
  }

  @override
  Future<int> reopen(int id) => _db.worryDao.reopen(id);

  @override
  Future<void> noteRelapse(int id, {required DateTime at}) async {
    // v1.1.0 R128e (论文 3 §5.3 "我又烦恼了"): open 状态下用户承认烦恼又回来,
    // 当前实现 = no-op (复用现有 mood_entries.worryThreadId 关联, 用户保存
    // 新 mood entry 自动延伸 timeline)。未来 v1.2+ 可加 lastRelapseAt 列
    // (schemaVersion 24→25), 当前先不强制 migration。
    return;
  }

  @override
  Future<int> rename(int id, String title) => _db.worryDao.rename(id, title);

  @override
  Future<int> delete(int id) => _db.worryDao.delete(id);
}
