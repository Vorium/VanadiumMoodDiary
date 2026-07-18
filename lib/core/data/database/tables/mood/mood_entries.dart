import 'package:drift/drift.dart';

/// 情绪日记表
///
/// 用户每天可记 1~N 次心情，存 4 维度分数（情绪/精力/睡眠/焦虑，各 1-5）+ 标签 JSON + 备注
/// 设计：1=很差 / 2=差 / 3=一般 / 4=好 / 5=很好
///
/// v0.18 round 18 (P1-15): 升级 4 维度
/// - score 仍是必填(情绪，老 schema 兼容)
/// - energy / sleep / anxiety 3 个新列 nullable(老数据没值，新数据 4 维全填)
/// - 焦虑反向计分: 1=严重 / 5=平静(UI 提示 "1=焦虑严重 5=完全平静")
@DataClassName('MoodEntry')
class MoodEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 记录时间
  DateTimeColumn get timestamp => dateTime()();

  /// 情绪分数 1-5（必填,1=很差 5=很好）
  IntColumn get score => integer()();

  /// 精力分数 1-5（v0.18 P1-15 新增,1=很低 5=充沛）
  IntColumn get energy => integer().nullable()();

  /// 睡眠分数 1-5（v0.18 P1-15 新增,1=很差 5=很好）
  IntColumn get sleep => integer().nullable()();

  /// 焦虑分数 1-5（v0.18 P1-15 新增，反向:1=严重 5=平静）
  IntColumn get anxiety => integer().nullable()();

  /// 情绪标签 JSON 数组：'["焦虑","失眠"]'
  /// 选填，单选多个
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();

  /// 自由备注
  TextColumn get note => text().nullable()();
}
