// v1.1.0 round 9 (论文落地 F1 烦恼闭环): 烦恼主题仓库 (domain 接口)
import 'package:chroniccare/domain/entities/worry_thread_entity.dart';

/// 烦恼主题仓库 (domain 接口)
abstract class WorryThreadRepository {
  /// 监听进行中的烦恼 (open, 按创建时间倒序)
  Stream<List<WorryThreadEntity>> watchOpen();

  /// 监听已闭环的烦恼 (resolved, 按闭环时间倒序)
  Stream<List<WorryThreadEntity>> watchResolved();

  /// 按 id 查单条 (烦恼时间线页用)
  Future<WorryThreadEntity?> getById(int id);

  /// 创建新烦恼主题
  ///
  /// [title] 由调用方用 [WorryThreadLibrary.generateTitle] 生成
  /// (首条倾诉 note 前 20 字), 之后可 [rename]。
  Future<int> create({required String title, required DateTime at});

  /// 闭环 (不再烦恼啦) — open → resolved, 记 resolvedAt
  Future<int> resolve(int id, {required DateTime at});

  /// 重新打开 (又烦恼了) — resolved → open, 清 resolvedAt
  Future<int> reopen(int id);

  /// 重命名 (title 可编辑)
  Future<int> rename(int id, String title);

  /// 删除主题 (v1.1.0 R113 BUG 4: 新建烦恼后 mood 保存失败 → 回滚孤儿主题)
  Future<int> delete(int id);
}
