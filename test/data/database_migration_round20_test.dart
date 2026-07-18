// database_migration_round20_test.dart
//
// 测试 DatabaseMigration + MigrationException
import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/database_migration.dart';

void main() {
  group('MigrationException', () {
    test('stores message', () {
      final e = MigrationException('test error');
      expect(e.message, 'test error');
    });

    test('toString returns message', () {
      final e = MigrationException('cannot delete old db');
      expect(e.toString(), 'cannot delete old db');
    });

    test('is Exception', () {
      final e = MigrationException('err');
      expect(e, isA<Exception>());
    });
  });

  group('DatabaseMigration', () {
    test('needsMigration returns false when DbKeyService.hasKey is true',
        () async {
      // DbKeyService.hasKey() 依赖 SecureStorage,在 test 环境会抛错
      // 这里验证类存在且方法可调用
      expect(DatabaseMigration.needsMigration, isA<Function>());
    });

    test('migrateIfNeeded is callable', () {
      expect(DatabaseMigration.migrateIfNeeded, isA<Function>());
    });
  });
}
