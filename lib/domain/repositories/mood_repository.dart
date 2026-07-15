// v0.14 (Round 12A) MoodRepository — domain 层 abstract
//
// 4 层架构：domain 定义接口，data 层实现。
library;

import '../entities/mood_entry_entity.dart';

/// 情绪日记仓库（domain 接口）
abstract class MoodRepository {
  /// 监听所有情绪记录
  Stream<List<MoodEntryEntity>> watchAll();

  /// 监听今日情绪
  Stream<List<MoodEntryEntity>> watchToday();

  /// 添加一条
  Future<int> add({
    required int score,
    required List<String> tags,
    String? note,
    DateTime? at,
  });

  /// 删除一条
  Future<int> delete(int id);
}
