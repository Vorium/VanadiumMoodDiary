import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Web 端不支持 sqlcipher（WASM 没法调 SQLite Encryption Extension）
///
/// 策略：v0.9 之后 Web 端**不加密**本地数据，但提示用户：
///   "Web 端数据未加密（浏览器沙箱限制），请用 APK 版本获得完整加密保护"
///
/// TODO v1.0：考虑用 IndexedDB 加密 API（Web Crypto API + PBKDF2）
///  目前不做，避免引入 crypto-js 这类大依赖
QueryExecutor openConnection() {
  return DatabaseConnection.delayed(
    Future(() async {
      final db = await WasmDatabase.open(
        databaseName: 'chroniccare',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.dart.js'),
      );
      return db.resolvedExecutor;
    }),
  );
}
