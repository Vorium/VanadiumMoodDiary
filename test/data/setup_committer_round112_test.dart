// v0.32 R112 架构批 2 (AR-19): SetupCommitter 测试
//
// 迁移自 app_database_save_setup_round112_test.dart (SP-R112-04)。背景:
// saveSetup 从 AppDatabase 迁到 SetupCommitter.completeSetup, transaction
// 语义必须原样:
// 1. 成功路径: 1 transaction 写 user profile + medications
//    (timesJson encodeTimes 格式不变)
// 2. clearAllUserData: 清空所有表, 保持表结构 (PIPL §47 删除权)
//
// 1.1.0 round 4 (emotion-first refactor): contacts 写入段整摘 —
// 原 case 1 (contactList/contactConsents 长度不一致 → StateError) 删除。
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late SetupCommitter committer;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    committer = SetupCommitter(db);
  });

  tearDown(() async {
    await db.close();
  });

  test(
      'completeSetup 成功: 1 transaction 写 profile + medications '
      '(timesJson 兼容)', () async {
    await committer.completeSetup(
      userName: '李四',
      medicationList: const [
        (
          name: '舍曲林',
          dosage: 50.0,
          dosageUnit: 'mg',
          times: [
            HourMinute(hour: 8, minute: 0),
            HourMinute(hour: 20, minute: 0),
          ]
        ),
      ],
    );

    final profile = await db.userProfileDao.get();
    expect(profile, isNotNull);
    expect(profile!.userName, '李四');

    final meds = await db.medicationDao.watchAllIncludingInactive().first;
    expect(meds.length, 1);
    expect(meds.first.name, '舍曲林');
    // encodeTimes 格式保持向后兼容: [{"h":8,"m":0},{"h":20,"m":0}]
    expect(meds.first.timesJson, '[{"h":8,"m":0},{"h":20,"m":0}]');
  });

  test('clearAllUserData 后再 completeSetup: 重新写入新 profile (PIPL §47 后重设)',
      () async {
    await committer.completeSetup(
      userName: '第一次',
      medicationList: const [],
    );
    final first = await db.userProfileDao.get();
    expect(first, isNotNull);
    expect(first!.userName, '第一次');

    // 真实世界的"第二次 setup"路径: 清空所有数据 (PIPL §47) → 重走 setup。
    // 注: 直接对已有 id=1 行再 completeSetup 时 drift insertOnConflictUpdate
    // (PK 不在 companion 内) 不会覆盖既有行 — 原 saveSetup 同款行为, 保持 1:1。
    await committer.clearAllUserData();
    expect(await db.userProfileDao.get(), isNull);

    final before = DateTime.now().subtract(const Duration(seconds: 1));
    await committer.completeSetup(
      userName: '第二次',
      medicationList: const [],
    );
    final after = DateTime.now().add(const Duration(seconds: 1));
    final second = await db.userProfileDao.get();
    expect(second, isNotNull);
    expect(second!.userName, '第二次');
    expect(
      second.firstLaunchAt.isAfter(before) &&
          second.firstLaunchAt.isBefore(after),
      isTrue,
      reason: '新行 firstLaunchAt = 新的 DateTime.now() (原 saveSetup 语义)',
    );
  });

  test('clearAllUserData: 清空全部表数据, 表结构保留 (PIPL §47)', () async {
    // seed: profile + medication + checkIn
    await committer.completeSetup(
      userName: '王五',
      medicationList: const [
        (name: '舍曲林', dosage: 50.0, dosageUnit: 'mg', times: []),
      ],
    );
    await db.checkInDao.insert(
      CheckInsCompanion.insert(
        timestamp: DateTime(2026, 7, 1),
        type: 'normal',
      ),
    );

    await committer.clearAllUserData();

    expect(await db.userProfileDao.get(), isNull);
    expect(await db.medicationDao.watchAllIncludingInactive().first, isEmpty);
    expect(await db.checkInDao.watchAll().first, isEmpty);
  });
}
