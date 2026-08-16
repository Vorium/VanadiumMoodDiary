// 规则 3 标记: 迁移错误提示 中文 fallback — v1.0+ i18n (显示层走 ARB)
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
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

  /// R114 B1-8: 探测本地 DB 是否可解密打开 (key-DB 失配检测)
  ///
  /// 场景: Android 备份恢复只还原了 DB 文件、没还原 Keystore 里的加密 key
  /// (或 key 损坏) → SQLCipher "file is not a database" → 修前用户卡死
  /// 无法启动, 无任何恢复入口。本探测在 bootstrap 并行跑一次 (开连接 +
  /// 1 条 trivial 查询), 失败 → main.dart 走 [DatabaseResetPromptApp]
  /// 引导用户"重试 / 重置本地数据"。
  ///
  /// 返回 false = 不可读 (key 失配 / 文件损坏); true = 可读或无需探测
  /// (无 key / 无 DB 文件 / 测试与 web 平台)。
  static Future<bool> probeDatabaseReadable() async {
    if (!await DbKeyService.hasKey()) {
      // 全新安装 (或旧明文 DB 迁移场景) — 不探测
      return true;
    }
    try {
      final dbFolder = await getApplicationDocumentsDirectory();
      final file = File(p.join(dbFolder.path, _dbFileName));
      if (!file.existsSync()) {
        return true; // 还没建库
      }
      final password = await DbKeyService.getOrCreate();
      // 跟 connection/native.dart 同款防御: base64 校验 + 单引号转义
      if (!RegExp(r'^[A-Za-z0-9+/=]+$').hasMatch(password)) {
        return false;
      }
      final escaped = password.replaceAll("'", "''");
      final db = _ProbeDatabase(
        NativeDatabase(
          file,
          setup: (db) => db.execute("PRAGMA key = '$escaped'"),
        ),
      );
      try {
        await db.customSelect('SELECT count(*) AS c FROM sqlite_master').get();
        return true;
      } finally {
        try {
          await db.close();
        } catch (_) {
          // open 失败路径的 close 再抛不重要
        }
      }
    } on MissingPluginException {
      // 测试环境 path_provider / secure storage plugin 不可用
      return true;
    } on UnsupportedError {
      // web 端 dart:io 不可用
      return true;
    } catch (_) {
      // SQLCipher key 失配 ("file is not a database") / 文件损坏 /
      // 磁盘错误 → 不可读, 走重置引导
      return false;
    }
  }

  /// R114 B1-8: 重置本地数据 (用户两次确认后调)
  ///
  /// 删主 DB 文件 + -wal / -shm 伴生文件 + secure storage 里的加密 key。
  /// 之后重试启动 = 全新安装 (新 key + 空 DB)。失败抛 [MigrationException]
  /// — 绝不静默删数据。
  static Future<void> resetLocalData() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, _dbFileName));
    try {
      for (final f in <File>[
        file,
        File('${file.path}-wal'),
        File('${file.path}-shm'),
      ]) {
        if (f.existsSync()) {
          await f.delete();
        }
      }
    } on FileSystemException catch (e) {
      throw MigrationException(
        '无法删除本地数据库（$e）。请尝试卸载重装 App。',
      );
    }
    await DbKeyService.deleteKey();
  }
}

/// 迁移失败时抛出
class MigrationException implements Exception {
  final String message;
  MigrationException(this.message);

  @override
  String toString() => message;
}

/// R114 B1-8: probeDatabaseReadable 用的最小 GeneratedDatabase
///
/// 只为跑一条 trivial 查询触发 lazy open (PRAGMA key setup 回调在首次
/// SQL 前执行), 不需要表定义。
class _ProbeDatabase extends GeneratedDatabase {
  _ProbeDatabase(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy();
}
// rule3-whitelist: 76-77, 158
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   R114 B1-8: resetLocalData 错误文案 (MigrationException, 显示层拼
//   l10n.migrationFailedFooter) 扩行 157-158
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
