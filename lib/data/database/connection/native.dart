import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../services/db_key_service.dart';

/// Native 端数据库连接（iOS / Android / Windows / macOS / Linux）
///
/// **架构**：
/// - 迁移由 [main.dart] 在 app 启动时统一调一次
/// - 本文件只负责"打开已迁移好的 DB"
/// - 避免在 [LazyDatabase] 回调里再跑迁移 → 双重调用 + 启动时间翻倍
QueryExecutor openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'chroniccare.sqlite'));
    final password = await DbKeyService.getOrCreate();

    // sqlcipher 加密：PRAGMA key 必须在第一次 SQL 之前
    // drift 的 setup 回调正好用于此场景
    return NativeDatabase.createInBackground(
      file,
      setup: (db) {
        db.execute("PRAGMA key = '$password'");
      },
    );
  });
}
