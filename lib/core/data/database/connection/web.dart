// v0.17 round 14 (P2-9): web platform DB connection.
//
// IMPORTANT: Web 端不支持 SQLCipher（WASM 没法调 SQLite Encryption
// Extension）。本文件是 fallback,实际从未被调用 — v0.7 起项目主平台是
// Android/iOS,Web build 只在 CI smoke test 跑过。
//
// 如果未来 contributor 真的要在 Web 跑，需要重新评估:
//   - 数据库无加密: 跟项目的 "零云端 + 本地加密" 隐私边界冲突
//   - drift_worker.js / sqlite3.wasm asset 打包 (v0.7 文档提到 404 问题)
//   - SQLCipher 替代: IndexedDB 加密 API (Web Crypto + PBKDF2),但会引
//     入 ~50KB crypto polyfill
//
// v0.17 起只在 dev / CI 跑 flutter test 时被 conditional import 加载,
// 生产 build (flutter build apk / ipa) 不会调用本文件。
//
// 之前 v0.9 留下的 TODO (Web Crypto 加密) 仍未做，优先级低，见 round 8 决策。

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
