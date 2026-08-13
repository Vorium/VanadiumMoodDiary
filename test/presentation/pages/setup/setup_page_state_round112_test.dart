// v0.32 R112 (AR-20 批2a): setup_page_state 拆前补测 (characterization)
//
// 背景: setup_page_state.dart 503L god class (职责 3: 4 步导航 + consent
// 编排 + 提交), 0 专用测试 (SP-111-06 / SP-en-3)。按 AR-20 "先补 test 再拆"
// 模式: 本文件锁定既有行为, 拆分后必须全绿 (行为 1:1, 测试只加不减)。
//
// 覆盖缺口 (对照 round77 / round18 / round14 已有测试):
// 1. 4 步导航流转: consent→welcome→medication→done 完整走通 + step 2 返回
// 2. consent 弹窗编排: 填联系人手机号 → 完成时弹 PIPL §13 同意 dialog;
//    拒绝 → snackbar + 停留 step 2 + committer 不被调; 同意 → 联系人入提交
//    数据 (E.164 normalize); 手机号留空 → 跳过 dialog 直接提交
// 3. 提交成功: committer 收到 userName/contacts/meds + recordConsent 被调
//    (PIPL §14) + 进 step 3 (done)
// 4. 提交失败: committer 抛异常 → error snackbar + 停留 step 2 + saving 复位
// 5. E5 (R111 fix): committer 抛 StateError (contactList/contactConsents
//    长度不一致) → 走同一失败路径, 错误信息透传 snackbar
//
// 依赖注:
// - flutter_local_notifications channel 全 mock (refill_notifier_round61c
//   同款), 让 _finishSetup 的通知段 (requestPermission / reschedule /
//   scheduleDailyReminder) 在 test 环境安全执行
// - 数据面全部 fake (committer / userProfileRepo / medicationRepo), 不碰真
//   drift isolate (testWidgets FakeAsync 下真 DB await 会 hang)
import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopNotificationService extends NotificationService {}

/// 记录 completeSetup 调用 + 可注入异常 (E5 StateError 等)
class _RecordingSetupCommitter extends SetupCommitter {
  _RecordingSetupCommitter(super.db);

  Object? throwOnComplete;
  int calls = 0;
  String? receivedUserName;
  final List<({String name, String phone, int sortOrder})> receivedContacts =
      [];
  final List<ConsentArtifact> receivedConsents = [];
  final List<
          ({
            String name,
            double dosage,
            String dosageUnit,
            List<HourMinute> times,
          })>
      receivedMeds = [];

  @override
  Future<void> completeSetup({
    required String userName,
    required List<({String name, String phone, int sortOrder})> contactList,
    required List<ConsentArtifact> contactConsents,
    required List<
            ({
              String name,
              double dosage,
              String dosageUnit,
              List<HourMinute> times,
            })>
        medicationList,
  }) async {
    calls++;
    if (throwOnComplete != null) throw throwOnComplete!;
    receivedUserName = userName;
    receivedContacts.addAll(contactList);
    receivedConsents.addAll(contactConsents);
    receivedMeds.addAll(medicationList);
  }
}

class _RecordingUserProfileRepository implements UserProfileRepository {
  int recordConsentCalls = 0;

  @override
  Stream<UserProfileEntity?> watch() => Stream.value(null);

  @override
  Future<UserProfileEntity?> get() async => null;

  @override
  Future<void> save({String? userName, int checkInCycleHours = 48}) async {}

  @override
  Future<void> updateLastCheckIn(DateTime time) async {}

  @override
  Future<void> recordConsent({
    required String userAgreementVersion,
    required String privacyPolicyVersion,
  }) async {
    recordConsentCalls++;
  }

  @override
  Future<void> withdrawConsent() async {}

  @override
  Future<void> resetConsent() async {}
}

class _EmptyMedicationRepository implements MedicationRepository {
  @override
  Stream<List<MedicationEntity>> watchAll() => Stream.value(const []);

  @override
  Stream<List<MedicationEntity>> watchAllIncludingInactive() =>
      Stream.value(const []);

  @override
  Future<int> add(MedicationDraft draft) async => 1;

  @override
  Future<bool> update(MedicationEntity medication) async => true;

  @override
  Future<bool> setActive({
    required int medicationId,
    required bool isActive,
  }) async =>
      true;

  @override
  Future<bool> updateRefill({
    required int medicationId,
    required DateTime? refillAt,
    int? reminderDays,
  }) async =>
      true;

  @override
  Future<int> delete(int id) async => 1;
}

const _pluginChannel =
    MethodChannel('dexterous.com/flutter/local_notifications');

/// flutter_timezone channel — 不 mock 时 delegate.send 走真引擎 messenger,
/// testWidgets 下 future 永不完成 → init() 挂死 (实测)。返 Asia/Shanghai
/// 让 tz.getLocation 拿到合法时区。
const _tzChannel = MethodChannel('flutter_timezone');

Future<_RecordingSetupCommitter> _pumpSetup(
  WidgetTester tester, {
  Object? throwOnComplete,
}) async {
  // R110 round 3 (AS-07 gate): 联系人 section 挂 flag, test 翻 true
  FeatureFlags.enableForTest();
  addTearDown(FeatureFlags.resetForTest);
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  // flutter_local_notifications channel 全 mock — _finishSetup 的通知段
  // (requestPermission / reschedule / dailyReminder) 安全执行
  // 注: 'initialize' / 'requestPermissions' / 'requestNotificationsPermission'
  // 必须返 true — 包内 Future<bool> async 方法直接 return channel null 会抛
  // "type 'Null' is not a subtype of type 'FutureOr<bool>'"
  TestWidgetsFlutterBinding.ensureInitialized();
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pluginChannel, (call) async {
    if (call.method == 'initialize' ||
        call.method == 'requestPermissions' ||
        call.method == 'requestNotificationsPermission') {
      return true;
    }
    return null;
  });
  addTearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_pluginChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_tzChannel, null);
  });
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_tzChannel, (call) async => 'Asia/Shanghai');

  final db = AppDatabase.forTesting(NativeDatabase.memory());
  addTearDown(db.close);
  final committer = _RecordingSetupCommitter(db)
    ..throwOnComplete = throwOnComplete;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        notificationServiceProvider.overrideWithValue(
          _NoopNotificationService(),
        ),
        setupCommitterProvider.overrideWithValue(committer),
        userProfileRepositoryProvider.overrideWithValue(
          _RecordingUserProfileRepository(),
        ),
        medicationRepositoryProvider.overrideWithValue(
          _EmptyMedicationRepository(),
        ),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: SetupPage(),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return committer;
}

/// step 0 → step 2: 勾 5 单独 consent → 填名字 (+可选联系人) → 到药物步
Future<void> _walkToMedicationStep(
  WidgetTester tester, {
  String contactName = '',
  String contactPhone = '',
}) async {
  final checkboxes = find.byType(Checkbox);
  for (var i = 1; i < 6; i++) {
    await tester.tap(checkboxes.at(i));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.text('开始设置'));
  await tester.pumpAndSettle();

  await tester.enterText(
    find.widgetWithText(TextField, '您的名字（选填）'),
    '小明',
  );
  if (contactName.isNotEmpty) {
    await tester.enterText(
      find.widgetWithText(TextField, '联系人 1 姓名'),
      contactName,
    );
  }
  if (contactPhone.isNotEmpty) {
    await tester.enterText(
      find.widgetWithText(TextField, '紧急联系人手机号 1'),
      contactPhone,
    );
  }
  await tester.pumpAndSettle();
  await tester.tap(find.text('下一步 →'));
  await tester.pumpAndSettle();
  expect(find.text('您常吃什么药？'), findsOneWidget,
      reason: '应该已到 step 2 (medication)',);
}

/// 排空 SnackBar 计时器 (info 2s / error 4s), 避免 test 结束 pending timer
Future<void> _drainSnackbars(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 5));
  await tester.pumpAndSettle();
}

/// 有界 pump 等待 finder 出现 (saving=true 时 LoadingSpinner 无限动画,
/// 不能 pumpAndSettle — press_feedback_round95 同款坑)
Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  int maxPumps = 80,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets,
      reason: '有界 pump 后 finder 仍未出现 (可能提交卡住)',);
}

/// step 2 完成按钮的 saving 复位断言: saving=true 时 '下一步 →' 文本被
/// LoadingSpinner 替代, 文本重新可见 = saving=false (按钮可重试)
void _expectSavingReset(WidgetTester tester) {
  expect(find.text('下一步 →'), findsOneWidget,
      reason: 'saving 应复位 (spinner 消失, 完成按钮文本重新可见)',);
}

void main() {
  group('4 步导航流转 (AR-20 批2a)', () {
    testWidgets('1. consent→welcome→medication→done 完整流转 (提交成功)',
        (tester) async {
      final committer = await _pumpSetup(tester);
      await _walkToMedicationStep(tester);

      // step 2: 添加 1 个药 + 药名 + 剂量
      await tester.tap(find.text('+ 添加药物'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, '药名'), '舍曲林');
      await tester.enterText(find.widgetWithText(TextField, '剂量'), '50');
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('下一步 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步 →'));
      await _pumpUntilFound(tester, find.text('全部完成！'));
      await tester.pumpAndSettle();

      // step 3 (done)
      expect(find.text('全部完成！'), findsOneWidget,
          reason: '提交成功应进 step 3 done 页',);

      // committer 收到数据
      expect(committer.calls, 1);
      expect(committer.receivedUserName, '小明');
      expect(committer.receivedMeds.length, 1);
      expect(committer.receivedMeds.single.name, '舍曲林');
      expect(committer.receivedMeds.single.dosage, 50.0);
      expect(committer.receivedMeds.single.dosageUnit, 'mg');

      // 不填联系人 → 0 个同意弹窗, contacts 空
      expect(committer.receivedContacts, isEmpty);
      expect(committer.receivedConsents, isEmpty);

      // PIPL §14: recordConsent 被调 1 次
      final container = ProviderScope.containerOf(
        tester.element(find.byType(SetupPage)),
      );
      final profileRepo =
          container.read(userProfileRepositoryProvider)
              as _RecordingUserProfileRepository;
      expect(profileRepo.recordConsentCalls, 1,
          reason: 'setup 完成应记录同意时刻 + 协议版本 (PIPL §14)',);
    });

    testWidgets('2. step 2 上一步 → 回 step 1 (welcome)', (tester) async {
      await _pumpSetup(tester);
      await _walkToMedicationStep(tester);

      await tester.ensureVisible(find.text('← 上一步'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('← 上一步'));
      await tester.pumpAndSettle();

      expect(find.text('您好，我是慢病管家'), findsOneWidget,
          reason: 'step 2 上一步应回 step 1',);
    });
  });

  group('consent 弹窗编排 (PIPL §13)', () {
    testWidgets('3. 填联系人手机号 → 完成时弹同意 dialog → 同意入提交数据',
        (tester) async {
      final committer = await _pumpSetup(tester);
      await _walkToMedicationStep(
        tester,
        contactName: '妈妈',
        contactPhone: '13800138000',
      );

      await tester.ensureVisible(find.text('下一步 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步 →'));
      await _pumpUntilFound(tester, find.byType(AlertDialog));

      // PIPL §13 同意 dialog 弹出
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('知情同意'), findsOneWidget);

      // 同意 → 提交继续
      await tester.tap(find.text('已告知并取得同意'));
      await _pumpUntilFound(tester, find.text('全部完成！'));
      await tester.pumpAndSettle();

      expect(find.text('全部完成！'), findsOneWidget);
      expect(committer.calls, 1);
      expect(committer.receivedContacts.length, 1);
      expect(committer.receivedContacts.single.name, '妈妈');
      // v0.18 P1-14: phone 走 E.164 normalize
      expect(committer.receivedContacts.single.phone, '+8613800138000');
      // R68 CC-1: contactList 与 contactConsents 等长
      expect(committer.receivedConsents.length, 1);
      expect(committer.receivedConsents.single.kind,
          ConsentKind.emergencyContactSharing,);
    });

    testWidgets('4. 拒绝同意 → setupConsentRejected snackbar + 停留 step 2 + committer 不被调',
        (tester) async {
      final committer = await _pumpSetup(tester);
      await _walkToMedicationStep(
        tester,
        contactName: '妈妈',
        contactPhone: '13800138000',
      );

      await tester.ensureVisible(find.text('下一步 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步 →'));
      await _pumpUntilFound(tester, find.byType(AlertDialog));
      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('暂不同意'));
      await tester.pumpAndSettle();

      expect(find.textContaining('已拒绝该联系人'), findsOneWidget,
          reason: '拒绝后应显示 setupConsentRejected 提示',);
      expect(find.text('您常吃什么药？'), findsOneWidget,
          reason: 'PIPL §13 严同意: 拒绝 → 终止 setup, 停留 step 2',);
      expect(committer.calls, 0, reason: '拒绝后 committer 不应被调');

      // saving 复位 → 完成按钮可重试
      _expectSavingReset(tester);

      await _drainSnackbars(tester);
    });

    testWidgets('5. 联系人手机号留空 → 不弹 dialog 直接提交', (tester) async {
      final committer = await _pumpSetup(tester);
      await _walkToMedicationStep(tester, contactName: '妈妈');

      await tester.ensureVisible(find.text('下一步 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步 →'));
      await _pumpUntilFound(tester, find.text('全部完成！'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsNothing,
          reason: '手机号空 → 跳过 consent dialog',);
      expect(find.text('全部完成！'), findsOneWidget);
      expect(committer.receivedContacts, isEmpty);
      expect(committer.receivedConsents, isEmpty);
    });
  });

  group('提交成功/失败 + E5', () {
    testWidgets('6. committer 抛异常 → error snackbar + 停留 step 2 + saving 复位',
        (tester) async {
      final committer =
          await _pumpSetup(tester, throwOnComplete: Exception('db locked'));
      await _walkToMedicationStep(tester);

      await tester.ensureVisible(find.text('下一步 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步 →'));
      await _pumpUntilFound(tester, find.textContaining('完成设置失败'));
      await tester.pumpAndSettle();

      // v0.27 round 62: error snackbar 走 l10n '完成设置失败：...'
      expect(find.textContaining('完成设置失败'), findsOneWidget);
      expect(find.text('您常吃什么药？'), findsOneWidget,
          reason: '提交失败应停留 step 2',);
      expect(committer.calls, 1);

      // saving 复位 → 完成按钮可重试
      _expectSavingReset(tester);

      await _drainSnackbars(tester);
    });

    testWidgets('7. E5: committer 抛 StateError (长度不一致) → 同一失败路径 + 错误透传',
        (tester) async {
      await _pumpSetup(
        tester,
        throwOnComplete: StateError(
          'contactList (1) 与 contactConsents (0) 长度不一致 — '
          'setup_page 必须为每个联系人弹 ConsentDialog (PIPL §13)',
        ),
      );
      await _walkToMedicationStep(
        tester,
        contactName: '妈妈',
        contactPhone: '13800138000',
      );

      await tester.ensureVisible(find.text('下一步 →'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('下一步 →'));
      await _pumpUntilFound(tester, find.byType(AlertDialog));

      // 同意 dialog 先弹 (同意后 committer 才抛)
      await tester.tap(find.text('已告知并取得同意'));
      await _pumpUntilFound(tester, find.textContaining('完成设置失败'));
      await tester.pumpAndSettle();

      expect(find.textContaining('完成设置失败'), findsOneWidget,
          reason: 'E5 StateError 应走统一失败路径 (error snackbar)',);
      expect(find.textContaining('长度不一致'), findsOneWidget,
          reason: 'E5 错误信息应透传到 snackbar',);
      expect(find.text('您常吃什么药？'), findsOneWidget,
          reason: 'E5 后应停留 step 2',);
      _expectSavingReset(tester);

      await _drainSnackbars(tester);
    });
  });
}
