import 'package:drift/drift.dart';

/// 树洞表（v0.15 Round 18, v0.21 Round 22 文字加密）
///
/// 私密倾诉空间，**完全独立于情绪日记**：
/// - 情绪日记：量化跟踪，进趋势页
/// - 树洞：纯倾诉 / 宣泄，**不进任何分析**
///
/// 存储：
/// - text 内容存 [contentTextEnc] (BLOB, AES-256 加密，v9+ 主字段)
/// - text 内容也存 [contentText] (TEXT, 旧字段，v9 migration 期间临时保留)
/// - audio 存本地加密文件，[audioPath] 存相对路径
/// - 同一行可同时有 text + audio（先录后补文字，或反过来）
///
/// v0.21 Round 22 (P0-1 修复): 原 `contentText` (TEXT, 明文) 升级为
/// `contentTextEnc` (BLOB, AES-256 加密)。每次写入 mapper 自动 encrypt，
/// 每次读取 mapper 自动 decrypt。旧 `contentText` 列保留（代码层不再用），
/// 后续 v10+ 彻底 DROP COLUMN 清理。
///
/// **安全模型**：设备 root + 拿到 DB 加密 key + 拿到 SecureStorage key 三者
/// 凑齐仍能解密（这是加密的本质——保护"没拿到 key 的人"），但拿不到
/// SecureStorage key 的人无法读字段明文。配合 v0.18 round 14 的 audio
/// 加密，文字 + 录音均加密。
///
/// **PIPL §28 敏感个人信息需加密** —— 精神心理 App 树洞文字属于敏感
/// 健康信息，**明文存 SQLCipher 表内字段**违反此条（PIPL 字段级保护）。
@DataClassName('VentEntry')
class VentEntries extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// 记录时间
  DateTimeColumn get timestamp => dateTime()();

  /// **旧字段保留**（v9 migration 期间用于读旧数据；代码层不再写入）
  ///
  /// v0.21 Round 22 起：所有新写入走 [contentTextEnc]。
  /// 旧数据 migration 一次性把 contentText 加密写回 contentTextEnc。
  TextColumn get contentText => text().nullable()();

  /// 文字内容（加密 BLOB，可空，v9+ 主字段）
  ///
  /// v0.21 Round 22 起：原 `contentText` (TEXT 明文) 升级为 BLOB 加密。
  /// mapper 自动处理加解密，UI 拿到的仍是 [String?]。
  BlobColumn get contentTextEnc => blob().nullable()();

  /// 录音文件路径（相对 app docs 目录，可空，纯 text 条目为 null）
  TextColumn get audioPath => text().nullable()();

  /// 录音时长（秒，可空）
  IntColumn get audioDurationSec => integer().nullable()();

  /// 录音大小（字节，可空）
  IntColumn get audioSizeBytes => integer().nullable()();
}
