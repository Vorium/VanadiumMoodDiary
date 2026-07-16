import '../entities/report_history_entity.dart';

/// 报告历史仓库（domain 抽象接口）
///
/// data 层用 Drift 实现，UI 只调 watchAll() / delete()。
abstract class ReportHistoryRepository {
  /// 监听所有报告历史（按生成时间倒序）
  Stream<List<ReportHistoryEntity>> watchAll();

  /// 删除一条报告历史
  Future<int> delete(int id);

  /// 一次性拉所有（给导出用）
  Future<List<ReportHistoryEntity>> getAll();

  /// 清空全部
  Future<int> clearAll();

  /// 插入一条
  Future<int> insert({
    required int windowDays,
    required DateTime generatedAt,
    required String userName,
    required String reportText,
  });
}
