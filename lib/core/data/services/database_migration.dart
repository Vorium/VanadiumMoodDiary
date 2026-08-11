import 'dart:io';

import 'package:flutter/services.dart' show MissingPluginException;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'package:chroniccare/core/data/services/db_key_service.dart';

/// 数据库迁移：v0.1 ~ v0.8 的非加密 DB → v0.9 的 sqlcipher 加密 DB
///
/// 检测：
/// - secure storage 没有 key（说明从未升级到 v0.9）
/// - 旧 DB 文件（chroniccare.sqlite）存在
///
/// 策略：
/// - **删除旧 DB**，因为 sqlcipher 不能直接打开非加密 DB
/// - 旧数据 v0.9 之前没有"导出／导入"流程（data_export_service 是 v0.7 引入），
///   实际损失有限（v0.1 ~ v0.6 阶段用户少）
/// - v0.9 之后用户可以用"导出数据"备份，升级不再丢数据
///
/// **B1 fix**：失败必须 throw，不能静默 return false
/// 之前的代码在删除失败时返回 false，调用方忽略 → sqlcipher 拿新 key 打开旧
/// 非加密 DB 直接 throw，用户看到神秘错误。改为：删除失败抛 MigrationException，
/// 由 [main.dart] 捕获后给用户明确提示。
class DatabaseMigration {
  DatabaseMigration._();

  static const _dbFileName = 'chroniccare.sqlite';

  /// 检查是否需要迁移（不实际删除，给 UI 弹确认用）
  ///
  /// 返回 `true` 表示"有旧非加密 DB 等待升级"。
  ///
  /// v0.22 round 28 (spen-bug-01): web 端 `dart:io` 抛 `UnsupportedError`,
  /// 之前 main.dart:76 无 try/catch → web 端启动直接崩。修：内部吞
  /// UnsupportedError 返回 false (web 端无文件系统, 永远不需要迁移)。
  static Future<bool> needsMigration() async {
    if (await DbKeyService.hasKey()) return false;
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      return File(p.join(dbFolder.path, _dbFileName)).existsSync();
    } on MissingPluginException {
      // 测试环境 path_provider plugin 不可用
      return false;
    } on UnsupportedError {
      // web 端 dart:io 不可用 (MissingPluginException 已 catch, 这兜底其他)
      return false;
    }
  }

  /// 检测 + 迁移
  ///
  /// 失败抛 [MigrationException]，不静默。
  static Future<void> migrateIfNeeded() async {
    if (await DbKeyService.hasKey()) {
      // 已经有 key，说明不是首次启动
      return;
    }

    final dbFolder = await getApplicationDocumentsDirectory();
    final oldDb = File(p.join(dbFolder.path, _dbFileName));
    if (!oldDb.existsSync()) {
      // 没有旧 DB（全新安装或 web 端），无需迁移
      return;
    }

    // 删旧 DB。失败必须抛——静默吞异常会让 sqlcipher 后续
    // 拿新 key 打开旧文件时直接 throw，错误信息让用户摸不着头脑。
    try {
      await oldDb.delete();
    } on FileSystemException catch (e) {
      throw MigrationException(
        '无法删除旧数据库（$e）。请先手动备份 Documents 目录下的 chroniccare.sqlite '
        '后卸载重装 App。',
      );
    }
  }
}

/// 迁移失败时抛出
class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);

  @override
  String toString() => message;
}
