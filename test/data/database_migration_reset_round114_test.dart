// R114 B1-8: key-DB 失配无恢复路径 → 探测 + 重置引导
// (2026-08-16 标准审计 · 04-engineering S-01 + 10-bottom-core-data 发现)
//
// 修前: Android 备份恢复只还原 DB 文件、没还原 keystore 加密 key →
// SQLCipher "file is not a database" → 用户卡死无法启动, 无任何恢复入口。
// 修后: probeDatabaseReadable() bootstrap 探测 (开连接 + trivial 查询),
// 失败 → DatabaseResetPromptApp 引导"重试 / 重置本地数据 (二次确认)"。
//
// 注: test 环境 sqlite3 是 plain (无 sqlcipher), PRAGMA key 是 no-op —
// 合法文件 probe = true; 垃圾文件 (SQLite 头损坏) = false。
import 'dart:io';

import 'package:chroniccare/core/data/services/database_migration.dart';
import 'package:chroniccare/main/boot_apps.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// 建合法测试 DB 文件用的最小 GeneratedDatabase
class _LegitDb extends GeneratedDatabase {
  _LegitDb(super.executor);

  @override
  Iterable<TableInfo<Table, dynamic>> get allTables => const Iterable.empty();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  final storage = <String, String>{};

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('chroniccare_reset_test');
    storage.clear();
    const secure =
        MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(secure, (call) async {
      final args = (call.arguments as Map?) ?? const {};
      final key = args['key'] as String?;
      switch (call.method) {
        case 'read':
          return storage[key];
        case 'write':
          storage[key!] = args['value'] as String;
          return null;
        case 'delete':
          storage.remove(key);
          return null;
        case 'readAll':
          return Map<String, String>.from(storage);
        case 'containsKey':
          return storage.containsKey(key);
      }
      return null;
    });
    const pp = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pp, (call) async {
      if (call.method == 'getApplicationDocumentsDirectory') {
        return tempDir.path;
      }
      return null;
    });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
      null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  String dbPath() => '${tempDir.path}/chroniccare.sqlite';

  group('probeDatabaseReadable', () {
    test('无 key → true (全新安装/迁移场景, 不探测)', () async {
      expect(await DatabaseMigration.probeDatabaseReadable(), isTrue);
    });

    test('有 key + 无 DB 文件 → true', () async {
      storage['db_encryption_key'] = 'aGVsbG8='; // 合法 base64
      expect(await DatabaseMigration.probeDatabaseReadable(), isTrue);
    });

    test('有 key + 垃圾文件 (SQLite 头损坏) → false (key-DB 失配/损坏)', () async {
      storage['db_encryption_key'] = 'aGVsbG8=';
      File(dbPath()).writeAsBytesSync(List<int>.filled(4096, 0x5A));
      expect(await DatabaseMigration.probeDatabaseReadable(), isFalse);
    });

    test('有 key + 合法 DB 文件 → true', () async {
      storage['db_encryption_key'] = 'aGVsbG8=';
      // 建一个合法 SQLite 文件 (test 环境 plain sqlite3, PRAGMA key no-op)
      final db = _LegitDb(NativeDatabase(File(dbPath())));
      await db.customStatement('CREATE TABLE t (id INTEGER)');
      await db.close();
      expect(await DatabaseMigration.probeDatabaseReadable(), isTrue);
    });
  });

  group('resetLocalData', () {
    test('删 DB + -wal + -shm + key', () async {
      storage['db_encryption_key'] = 'aGVsbG8=';
      File(dbPath()).writeAsBytesSync(const [1, 2, 3]);
      File('${dbPath()}-wal').writeAsBytesSync(const [4]);
      File('${dbPath()}-shm').writeAsBytesSync(const [5]);

      await DatabaseMigration.resetLocalData();

      expect(File(dbPath()).existsSync(), isFalse);
      expect(File('${dbPath()}-wal').existsSync(), isFalse);
      expect(File('${dbPath()}-shm').existsSync(), isFalse);
      expect(storage.containsKey('db_encryption_key'), isFalse);
    });
  });

  group('DatabaseResetPromptApp (重置引导 UI)', () {
    testWidgets('弹重置对话框 → 二次确认 → 重置后回调 onRetry', (tester) async {
      storage['db_encryption_key'] = 'aGVsbG8=';
      File(dbPath()).writeAsBytesSync(const [1, 2, 3]);
      var retried = false;

      await tester.pumpWidget(
        DatabaseResetPromptApp(onRetry: () async {
          retried = true;
        }),
      );
      // LoadingSkeleton 持续动画 → 不能用 pumpAndSettle, 用定时 pump
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 第一层: 重试 / 重置本地数据
      expect(find.text("Can't open local database"), findsOneWidget);
      expect(find.text('Reset local data'), findsWidgets);

      await tester.tap(find.text('Reset local data'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // 第二层: 二次确认 (绝不静默删)
      expect(
          find.text(
              'Resetting will delete all local records and cannot be undone. Confirm reset?'),
          findsOneWidget);
      await tester.tap(find.text('Delete'));
      await tester.pump();
      // resetLocalData 走真实 dart:io (File.delete) — fake-async zone 里
      // 必须 runAsync 让真实 event loop 转完 I/O
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump();

      expect(retried, isTrue);
      expect(File(dbPath()).existsSync(), isFalse);
      expect(storage.containsKey('db_encryption_key'), isFalse);
    });

    testWidgets('重试 → 直接回调 onRetry, 不删数据', (tester) async {
      storage['db_encryption_key'] = 'aGVsbG8=';
      File(dbPath()).writeAsBytesSync(const [1, 2, 3]);
      var retried = false;

      await tester.pumpWidget(
        DatabaseResetPromptApp(onRetry: () async {
          retried = true;
        }),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(retried, isTrue);
      expect(File(dbPath()).existsSync(), isTrue, reason: '重试不删数据');
      expect(storage.containsKey('db_encryption_key'), isTrue);
    });
  });
}
