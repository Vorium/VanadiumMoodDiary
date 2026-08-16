// v1.1.0 round 9 (F1 烦恼闭环): WorryDao 抽离
//
// 跟其他 DAO 模式一致 — 不用 @DriftAccessor (避免 build_runner 重建),
// 手动 wrapper + AppDatabase 持有。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:drift/drift.dart';

class WorryDao {
  final AppDatabase _db;
  WorryDao(this._db);

  /// 进行中的烦恼 (open, 创建时间倒序)
  Stream<List<WorryThread>> watchOpen() {
    return (_db.select(_db.worryThreads)
          ..where((t) => t.status.equals('open'))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.createdAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  /// 已闭环的烦恼 (resolved, 闭环时间倒序)
  Stream<List<WorryThread>> watchResolved() {
    return (_db.select(_db.worryThreads)
          ..where((t) => t.status.equals('resolved'))
          ..orderBy([
            (t) => OrderingTerm(
                  expression: t.resolvedAt,
                  mode: OrderingMode.desc,
                ),
          ]))
        .watch();
  }

  Future<WorryThread?> getById(int id) {
    return (_db.select(_db.worryThreads)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// 全部烦恼主题 (导出用)
  Future<List<WorryThread>> getAll() => _db.select(_db.worryThreads).get();

  Future<int> insert({
    required String title,
    required DateTime createdAt,
  }) {
    return _db.into(_db.worryThreads).insert(
          WorryThreadsCompanion.insert(
            title: title,
            createdAt: createdAt,
            status: const Value('open'),
          ),
        );
  }

  Future<int> resolve(int id, {required DateTime resolvedAt}) {
    return (_db.update(_db.worryThreads)..where((t) => t.id.equals(id))).write(
      WorryThreadsCompanion(
        status: const Value('resolved'),
        resolvedAt: Value(resolvedAt),
      ),
    );
  }

  Future<int> reopen(int id) {
    return (_db.update(_db.worryThreads)..where((t) => t.id.equals(id))).write(
      const WorryThreadsCompanion(
        status: Value('open'),
        resolvedAt: Value(null),
      ),
    );
  }

  Future<int> rename(int id, String title) {
    return (_db.update(_db.worryThreads)..where((t) => t.id.equals(id)))
        .write(WorryThreadsCompanion(title: Value(title)));
  }

  /// 删除主题 (v1.1.0 R113 BUG 4: 新建烦恼后 mood 保存失败回滚用)
  Future<int> delete(int id) {
    return (_db.delete(_db.worryThreads)..where((t) => t.id.equals(id))).go();
  }
}
