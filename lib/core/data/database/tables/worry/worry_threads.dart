import 'package:drift/drift.dart';

/// 烦恼主题表 (v1.1.0 round 9 F1 烦恼闭环)
///
/// 一个烦恼主题 = 同一烦恼的多条情绪记录的容器。创建时 title 由首条
/// 倾诉 note 前 20 字生成, 之后可编辑。
///
/// - status: 'open' (进行中) / 'resolved' (已闭环 → 忆往昔)
/// - resolvedAt: 闭环时间, resolved 时非空
@DataClassName('WorryThread')
class WorryThreads extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 标题 (首条倾诉 note 前 20 字, 可编辑)
  TextColumn get title => text()();

  /// 创建时间
  DateTimeColumn get createdAt => dateTime()();

  /// 状态 ('open' / 'resolved')
  TextColumn get status => text().withDefault(const Constant('open'))();

  /// 闭环时间 (status == 'resolved' 时非空)
  DateTimeColumn get resolvedAt => dateTime().nullable()();
}
