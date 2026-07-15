// v0.13 (Round 11) RecordCheckInUseCase — 首例 UseCase
//
// 4 层架构示范：UseCase 是"业务操作"，放 `domain/logic/`（不是 usecases/）。
// 跟 [domain/repositories/]、[domain/entities/] 平级。
//
// 设计：
// - 一个方法一个类（Single-Method UseCase 模式）
// - 业务逻辑放在这里（"今天已经打卡" 的去重判断）
// - 不依赖 Flutter / Drift，只依赖 abstract repository
library;

import '../entities/check_in_entity.dart';
import '../repositories/check_in_repository.dart';

/// 打卡（每日）
///
/// 业务规则：
/// - 24h 内已有 normal 打卡 → 不重复打（避免 streak 算错）
/// - 否则写一条 normal check-in
///
/// v0.11 (Round 5) deep linking 也走这里（带 medicationId 走 medication
/// 通道时仍然要遵守"24h 不重复"规则）。
class RecordCheckInUseCase {
  final CheckInRepository _repo;

  RecordCheckInUseCase(this._repo);

  /// 执行打卡
  ///
  /// 返回 [RecordCheckInResult] 说明执行结果（成功 / 已存在 / 失败）
  Future<RecordCheckInResult> call({
    int? medicationId,
    DateTime? at,
  }) async {
    final now = at ?? DateTime.now();

    // 业务规则：去重
    final recent = await _repo.recentNormalCheckIns(since: now.subtract(const Duration(hours: 24)));
    if (recent.isNotEmpty && medicationId == null) {
      // 普通打卡去重（medicationId 场景：用户可能手动打了多次不同药）
      return const RecordCheckInResult.duplicate();
    }

    try {
      final id = await _repo.insertNormal(at: now, medicationId: medicationId);
      return RecordCheckInResult.success(id: id, timestamp: now);
    } catch (e) {
      return RecordCheckInResult.failure(error: e.toString());
    }
  }
}

/// UseCase 返回值
class RecordCheckInResult {
  final bool success;
  final bool duplicate;
  final int? id;
  final DateTime? timestamp;
  final String? error;

  const RecordCheckInResult._({
    required this.success,
    required this.duplicate,
    this.id,
    this.timestamp,
    this.error,
  });

  const RecordCheckInResult.success({
    required int id,
    required DateTime timestamp,
  }) : this._(success: true, duplicate: false, id: id, timestamp: timestamp);

  const RecordCheckInResult.duplicate()
      : this._(success: false, duplicate: true);

  const RecordCheckInResult.failure({required String error})
      : this._(success: false, duplicate: false, error: error);

  @override
  String toString() {
    if (success) return 'RecordCheckInResult.success(id=$id)';
    if (duplicate) return 'RecordCheckInResult.duplicate';
    return 'RecordCheckInResult.failure(error=$error)';
  }
}
