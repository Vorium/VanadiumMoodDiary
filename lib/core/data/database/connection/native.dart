import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:chroniccare/core/data/services/db_key_service.dart';
import 'package:chroniccare/core/data/utils/skip_backup.dart';

/// Native 端数据库连接（iOS / Android / Windows / macOS / Linux）
///
/// **架构**：
/// - 迁移由 [main.dart] 在 app 启动时统一调一次
/// - 本文件只负责"打开已迁移好的 DB"
/// - 避免在 [LazyDatabase] 回调里再跑迁移 → 双重调用 + 启动时间翻倍
///
/// **R108 P0-1**: 标记 DB 文件不参与 iCloud Backup (精神心理 PII 不上云)
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chroniccare.sqlite'));
    final password = await DbKeyService.getOrCreate();

    // R108 (P0 #1): iOS 端标记 DB 文件不参与 iCloud Backup
    // 精神心理患者数据敏感, 零云端架构基线, PIPL §6 最小化原则
    // Android / Web 走 SkipBackup 内部 noop 分支
    await SkipBackup.markAsSkipped(file.path);

    // sqlcipher 加密：PRAGMA key 必须在第一次 SQL 之前
    // drift 的 setup 回调正好用于此场景
    //
    // R104 (P0-1 fix): 验证 password 只含 base64 安全字符 + 转义单引号
    // DbKeyService.getOrCreate() 返回 base64 编码的 32 字节 key,
    // base64 字母表 = [A-Za-z0-9+/=] 不含单引号, 但防御性验证+转义双保险。
    if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(password)) {
      throw StateError('DB key contains unexpected characters');
    }
    final escaped = password.replaceAll("'", "''");
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute("PRAGMA key = '$escaped'");
      },
    );
  });
}
