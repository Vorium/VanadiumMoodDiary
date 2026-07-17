import 'package:drift/drift.dart';

/// 平台无关的连接抽象
///
/// 在 native 平台（iOS / Android / Windows / macOS / Linux）走 [native.dart]
/// 在 web 平台走 [web.dart]
/// 用 conditional import 切换：见 `app_database.dart` 的 import 块
QueryExecutor openConnection() => throw UnsupportedError(
      'openConnection() should be overridden by a platform-specific import',
    );
