// v0.32 round 8 (R112 drift probe 修复 lock-in): insertOnConflictUpdate 忽略
// Value(null) — save(userName: null) 对已存在行改走显式 update().write,
// 否则用户删除姓名后旧名字永久残留 (与 export import profile 段同款修法)。
//
// 探针结论 (R112 fix-reports/01-export.md E7): drift `insertOnConflictUpdate`
// 对 Value(null) 不写入 (旧值保留)。本测试锁住 save() 的清名语义。

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/repositories/user_profile/user_profile_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late UserProfileRepositoryImpl repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = UserProfileRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('UserProfileRepository.save (R112 drift probe fix)', () {
    test('首行 save(name) → userName 写入', () async {
      await repo.save(userName: '张三');
      final p = await db.userProfileDao.get();
      expect(p, isNotNull);
      expect(p!.userName, '张三');
    });

    test('已存在行 save(null) → userName 被清空 (修前残留旧名)', () async {
      await repo.save(userName: '张三');
      await repo.save(userName: null);
      final p = await db.userProfileDao.get();
      expect(p, isNotNull);
      expect(p!.userName, isNull,
          reason: 'insertOnConflictUpdate 忽略 Value(null); 显式 update 才清名',);
    });

    test('清名后再 save(新名) → 新名写入', () async {
      await repo.save(userName: '张三');
      await repo.save(userName: null);
      await repo.save(userName: '李四');
      final p = await db.userProfileDao.get();
      expect(p!.userName, '李四');
    });

    test('save 不清 firstLaunchAt (保留首次启动时间)', () async {
      await repo.save(userName: '张三');
      final first = await db.userProfileDao.get();
      await repo.save(userName: '李四');
      final second = await db.userProfileDao.get();
      expect(second!.firstLaunchAt, first!.firstLaunchAt);
    });
  });
}
