// v0.14 (Round 12A) CheckInRepository — domain 层 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
// 之前 `data/repositories/check_in_repository.dart` 直接暴露 Drift row，
// 现在改为返回 CheckInEntity，UI 不再看到 Drift 依赖。

import 'package:chroniccare/domain/entities/check_in_entity.dart';

/// 打卡仓库（domain 接口）
///
/// 业务方法清单（不暴露 Drift 细节）：
/// - [watchAll] - 监听所有打卡（含 normal / temp / phq9 / gad7，按时间倒序）
/// - [watchAssessments] - 监听所有量表评估（type ∈ {phq9, gad7}，按时间正序）
/// - [watchToday] - 监听今天的每日打卡（type=normal）
/// - [checkIn] - 新增每日打卡
/// - [addTempMedication] - 新增临时吃药
/// - [saveAssessment] - 新增量表评估
abstract class CheckInRepository {
  /// 监听所有打卡（按时间倒序，含 normal / temp / phq9 / gad7）
  Stream<List<CheckInEntity>> watchAll();

  /// 监听所有量表评估（phq9 / gad7，按时间正序）
  Stream<List<CheckInEntity>> watchAssessments();

  /// 监听今天的每日打卡（type=normal）
  Stream<CheckInEntity?> watchToday();

  /// 监听今天所有打卡（用于首页概览卡统计今日药物进度）
  Stream<List<CheckInEntity>> watchTodayAll();

  /// 监听所有 normal 类型打卡（DB 级过滤，避免全表扫描）
  Stream<List<CheckInEntity>> watchNormalCheckIns();

  /// 获取最近一次 normal 打卡（单条查询，DB 级 LIMIT 1）
  Future<CheckInEntity?> getLatestNormalCheckIn();

  /// 获取最近一次评估的时间戳（DB 级 LIMIT 1）
  Future<DateTime?> getLatestAssessmentTimestamp();

  /// 新增每日打卡
  Future<int> checkIn({DateTime? at, int? medicationId});

  /// 新增临时吃药
  ///
  /// [name] 药名，[note] 备注
  Future<int> addTempMedication({
    required String name,
    required String note,
    DateTime? at,
  });

  /// 新增量表评估（phq9 / gad7）
  Future<int> saveAssessment({
    required String scale,
    required List<int> scores,
    required int total,
    DateTime? at,
  });
}
