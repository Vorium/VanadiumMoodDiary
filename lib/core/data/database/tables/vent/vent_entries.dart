import 'package:drift/drift.dart';

/// 树洞表（v0.15 Round 18）
///
/// 私密倾诉空间，**完全独立于情绪日记**：
/// - 情绪日记：量化跟踪，进趋势页
/// - 树洞：纯倾诉 / 宣泄，**不进任何分析**
///
/// 存储：
/// - text 内容直接存 [contentText]
/// - audio 存本地加密文件，[audioPath] 存相对路径
/// - 同一行可同时有 text + audio（先录后补文字，或反过来）
@DataClassName('VentEntry')
class VentEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 记录时间
  DateTimeColumn get timestamp => dateTime()();

  /// 文字内容（可空，纯 audio 条目为 null）
  TextColumn get contentText => text().nullable()();

  /// 录音文件路径（相对 app docs 目录，可空，纯 text 条目为 null）
  /// v0.15 用文件路径字符串；v1.0+ 可考虑 BLOB 存 DB
  TextColumn get audioPath => text().nullable()();

  /// 录音时长（秒，可空）
  IntColumn get audioDurationSec => integer().nullable()();

  /// 录音大小（字节，可空）
  IntColumn get audioSizeBytes => integer().nullable()();
}
