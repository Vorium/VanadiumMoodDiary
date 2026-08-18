// R128e (2026-08-18): 药物步移出引导 — 原 setup 第 2 步 (药物列表) 测试
// 改为断言 3 步 wizard: welcome 下一步直接进 done, 不再显示药物列表。
//
// 用药管理改为二级页面 (/medication 路由), 相关测试见
// test/presentation/pages/medication/* + setup_step_medication_* (widget 直测)。
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/core/platform/notification/notification_service.dart';
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

class _NoopNotificationService extends NotificationService {}

class _FakeSetupCommitter extends SetupCommitter {
  _FakeSetupCommitter(super.db);
  @override
  Future<void> completeSetup({
    required String userName,
    required List<
            ({
              String name,
              double dosage,
              String dosageUnit,
              List<HourMinute> times,
            })>
        medicationList,
  }) async {}
}

class _FakeUserProfileRepository implements UserProfileRepository {
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
  }) async {}
  @override
  Future<void> withdrawConsent() async {}
  @override
  Future<void> resetConsent() async {}
}

class _FakeMedicationRepository implements MedicationRepository {
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
const _tzChannel = MethodChannel('flutter_timezone');

void main() {
  Future<void> pumpSetup(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

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

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          notificationServiceProvider.overrideWithValue(
            _NoopNotificationService(),
          ),
          setupCommitterProvider.overrideWithValue(_FakeSetupCommitter(db)),
          userProfileRepositoryProvider.overrideWithValue(
            _FakeUserProfileRepository(),
          ),
          medicationRepositoryProvider.overrideWithValue(
            _FakeMedicationRepository(),
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
  }

  Future<void> passConsent(WidgetTester tester) async {
    for (var i = 1; i < 6; i++) {
      await tester.tap(find.byType(Checkbox).at(i));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(FilledButton, '开始设置'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'R128e: 药物步移出引导 — welcome 下一步直接进 done, 无药物列表',
    (tester) async {
      await pumpSetup(tester);
      await passConsent(tester);

      final nextFinder = find.widgetWithText(FilledButton, '下一步 →');
      expect(nextFinder, findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextField, '您的名字（选填）'),
        '小明',
      );
      await tester.pumpAndSettle();
      await tester.tap(nextFinder);

      // 有界 pump 等提交完成 (done 页)
      for (var i = 0; i < 80; i++) {
        if (find.text('全部完成！').evaluate().isNotEmpty) break;
        await tester.pump(const Duration(milliseconds: 100));
      }
      await tester.pumpAndSettle();

      expect(
        find.text('全部完成！'),
        findsOneWidget,
        reason: 'R128e: welcome 下一步应直接进 done (3 步 wizard)',
      );
      expect(
        find.text('您常吃什么药？'),
        findsNothing,
        reason: 'R128e: 药物步已移出引导, 不再显示药物列表标题',
      );
      expect(
        find.text('+ 添加药物'),
        findsNothing,
        reason: 'R128e: 引导内不再出现添加药物按钮 (用药走 /medication 二级页)',
      );
    },
  );

  testWidgets(
    'R128e: 3 步 wizard 进度条 — 共 3 步',
    (tester) async {
      await pumpSetup(tester);
      await passConsent(tester);

      expect(
        find.textContaining('步 ／ 共'),
        findsOneWidget,
        reason: '顶部显示"第 X 步 ／ 共 X 步" (R128e 3 步流程)',
      );
      // 共 3 步: 同意 → 欢迎 → 完成
      expect(find.textContaining('共 3 步'), findsWidgets);
    },
  );
}
