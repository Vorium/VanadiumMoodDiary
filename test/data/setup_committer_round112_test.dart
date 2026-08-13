// v0.32 R112 架构批 2 (AR-19): SetupCommitter 测试
//
// 迁移自 app_database_save_setup_round112_test.dart (SP-R112-04)。背景:
// saveSetup 的 PIPL §13 consent 长度校验 (StateError, R111 E5 fix) 从
// AppDatabase 迁到 SetupCommitter.completeSetup, transaction 语义必须原样:
// 1. contactList.length != contactConsents.length → throwsA(StateError),
//    且整个 transaction 回滚 (0 数据写入)
// 2. 成功路径: 1 transaction 写 user profile + contacts (含 4 consent 字段)
//    + medications (timesJson encodeTimes 格式不变)
// 3. clearAllUserData: 清空所有表, 保持表结构 (PIPL §47 删除权)
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
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
      'completeSetup: contactList 2 条 / contactConsents 1 条 → 抛 StateError '
      '且 transaction 回滚 (0 数据写入)', () async {
    final consent = ConsentArtifact(
      kind: ConsentKind.emergencyContactSharing,
      grantedAt: DateTime(2026, 1, 1),
      grantedBy: 'tester',
      version: '1.0',
    );
    expect(
      () => committer.completeSetup(
        userName: '张三',
        contactList: const [
          (name: '妈妈', phone: '13800138000', sortOrder: 1),
          (name: '爸爸', phone: '13900139000', sortOrder: 2),
        ],
        contactConsents: [consent],
        medicationList: const [],
      ),
      throwsA(isA<StateError>()),
    );

    // transaction 回滚验证: 用户资料 / 联系人 都不该写进去
    final profile = await db.userProfileDao.get();
    expect(profile, isNull, reason: 'StateError 抛在 transaction 内, 应整体回滚');
    final contacts = await db.contactDao.watchActive().first;
    expect(contacts, isEmpty, reason: '联系人不应被写入');
  });

  test(
      'completeSetup 成功: 1 transaction 写 profile + contacts (4 consent 字段) '
      '+ medications (timesJson 兼容)', () async {
    final consent = ConsentArtifact(
      kind: ConsentKind.emergencyContactSharing,
      grantedAt: DateTime(2026, 1, 1, 9, 30),
      grantedBy: 'user',
      contactId: null,
      version: 'v0.32-2026-08-13',
    );
    await committer.completeSetup(
      userName: '李四',
      contactList: const [(name: '妈妈', phone: '13800138000', sortOrder: 0)],
      contactConsents: [consent],
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

    final contacts = await db.contactDao.watchActive().first;
    expect(contacts.length, 1);
    expect(contacts.first.name, '妈妈');
    // R68 CC-1: 4 consent 字段跟着 setup 写 (PIPL §13 留痕)
    expect(contacts.first.consentAt, DateTime(2026, 1, 1, 9, 30));
    expect(contacts.first.consentKind, 'emergencyContactSharing');
    expect(contacts.first.consentBy, 'user');
    expect(contacts.first.consentVersion, 'v0.32-2026-08-13');

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
      contactList: const [],
      contactConsents: const [],
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
      contactList: const [],
      contactConsents: const [],
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
    // seed: profile + contact + medication + checkIn + mood
    await committer.completeSetup(
      userName: '王五',
      contactList: const [(name: '妈妈', phone: '13800138000', sortOrder: 0)],
      contactConsents: [
        ConsentArtifact(
          kind: ConsentKind.emergencyContactSharing,
          grantedAt: DateTime(2026, 1, 1),
          grantedBy: 'user',
          version: '1.0',
        ),
      ],
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
    expect(await db.contactDao.watchActive().first, isNotEmpty);

    await committer.clearAllUserData();

    expect(await db.userProfileDao.get(), isNull);
    expect(await db.contactDao.watchActive().first, isEmpty);
    expect(await db.medicationDao.watchAllIncludingInactive().first, isEmpty);
    expect(await db.checkInDao.watchAll().first, isEmpty);
  });
}
