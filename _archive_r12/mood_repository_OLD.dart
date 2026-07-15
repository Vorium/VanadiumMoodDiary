import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../database/app_database.dart';
import '../utils/json_codec.dart';

/// 情绪日记仓库
///
/// 字段：
/// - score 1-5：1=很差 2=差 3=一般 4=好 5=很好
/// - tags：标签列表（如 ["焦虑","失眠"]），存为 JSON 字符串
/// - note：自由备注
class MoodRepository {
  final AppDatabase _db;
  MoodRepository(this._db);

  /// 监听所有情绪记录
  Stream<List<MoodEntry>> watchAll() => _db.watchMoodEntries();

  /// 监听今日情绪
  Stream<List<MoodEntry>> watchToday() => _db.watchTodayMoodEntries();

  /// 添加一条
  Future<int> add({
    required int score,
    required List<String> tags,
    String? note,
    DateTime? at,
  }) {
    return _db.insertMoodEntry(
      MoodEntriesCompanion.insert(
        timestamp: at ?? DateTime.now(),
        score: score,
        tagsJson: Value(JsonCodec.encodeStringList(tags)),
        note: Value(note),
      ),
    );
  }

  /// 删除一条
  Future<int> delete(int id) => _db.deleteMoodEntry(id);

  // ===== 静态工具（无状态）=====

  /// 解析 tagsJson 为 `List<String>`
  ///
  /// 向后兼容：老数据若不是合法 JSON 也能兜底。
  static List<String> decodeTags(String json) =>
      JsonCodec.decodeStringList(json);

  /// 分数 → emoji（1-5 映射）
  static String emojiFor(int score) {
    switch (score) {
      case 1:
        return '😢';
      case 2:
        return '😟';
      case 3:
        return '😐';
      case 4:
        return '🙂';
      case 5:
        return '😄';
      default:
        return '😐';
    }
  }

  /// 分数 → 中文
  static String labelFor(int score) {
    switch (score) {
      case 1:
        return '很差';
      case 2:
        return '差';
      case 3:
        return '一般';
      case 4:
        return '好';
      case 5:
        return '很好';
      default:
        return '一般';
    }
  }

  /// 分数 → 颜色
  static Color colorFor(int score) {
    switch (score) {
      case 1:
        return const Color(0xFF6B7280);
      case 2:
        return const Color(0xFF60A5FA);
      case 3:
        return const Color(0xFF9CA3AF);
      case 4:
        return const Color(0xFF6BCF7F);
      case 5:
        return const Color(0xFF4FB05F);
      default:
        return const Color(0xFF9CA3AF);
    }
  }
}
