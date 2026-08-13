// v0.32 R112 (AR-20 批2a): setup_page_state 拆解后新类单元测试
//
// 拆解产物 (1 文件 1 职责, 本文件 1 group 1 类):
// - SetupConsentState (setup_consent_state.dart): 5 勾选状态 + agreeAll
// - MedDraft.fromTemplate (setup_widgets.dart): template → 草稿工厂
// - SetupContactConsentFlow (setup_contact_consent_flow.dart): 同意弹窗循环
// - SetupSubmitFlow (setup_submit_flow.dart): 提交序列 (错误原样上抛)
// - SetupWizardFrame (widgets/setup_wizard_frame.dart): 4 步 wizard 壳
//
// 模式: 拆前 characterization 见 setup_page_state_round112_test.dart
// (7 case 锁定既有行为), 本文件测新类公开 API。
import 'dart:async';

import 'package:chroniccare/core/data/database/app_database.dart';
import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/core/data/services/preset_medication_templates.dart'
    as templates;
import 'package:chroniccare/core/data/services/setup_committer.dart';
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/domain/repositories/user_profile_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/setup/setup_consent_state.dart';
import 'package:chroniccare/presentation/pages/setup/setup_contact_consent_flow.dart';
import 'package:chroniccare/presentation/pages/setup/setup_submit_flow.dart';
import 'package:chroniccare/presentation/pages/setup/setup_widgets.dart';
import 'package:chroniccare/presentation/pages/setup/widgets/setup_wizard_frame.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _NoopNotificationService extends NotificationService {}

/// 记录 completeSetup 调用 + 可注入异常
class _RecordingSetupCommitter extends SetupCommitter {
  _RecordingSetupCommitter(super.db);

  Object? throwOnComplete;
  int calls = 0;
  String? receivedUserName;
  final List<({String name, String phone, int sortOrder})> receivedContacts =
      [];
  final List<ConsentArtifact> receivedConsents = [];

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
const _tzChannel = MethodChannel('flutter_timezone');

void _mockNotificationChannels() {
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
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_tzChannel, (call) async => 'Asia/Shanghai');
}

void _clearNotificationChannels() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_pluginChannel, null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_tzChannel, null);
}

/// 等待一个未 await 的 future 完成 (有界 pump, spinner 场景同款)
Future<void> _pumpUntil(
  WidgetTester tester,
  bool Function() done, {
  int maxPumps = 80,
}) async {
  for (var i = 0; i < maxPumps; i++) {
    if (done()) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(done(), isTrue, reason: '有界 pump 后仍未完成 (可能挂死)');
}

void main() {
  group('SetupConsentState (AR-20 批2a)', () {
    test('1. 初始 5 勾选全 false + allAgreed false', () {
      final state = SetupConsentState();
      expect(state.userAgreement, isFalse);
      expect(state.privacyPolicy, isFalse);
      expect(state.sensitiveData, isFalse);
      expect(state.ageAttestation, isFalse);
      expect(state.medicalDisclaimer, isFalse);
      expect(state.allAgreed, isFalse);
    });

    test('2. agreeAll → 5 勾选全 true + allAgreed true (R104 一键全部同意)', () {
      final state = SetupConsentState();
      state.agreeAll();
      expect(state.allAgreed, isTrue);
      expect(state.userAgreement, isTrue);
      expect(state.ageAttestation, isTrue);
      expect(state.medicalDisclaimer, isTrue);
    });

    test('3. 逐个勾到 4/5 → allAgreed 仍 false, 勾满 5 个才 true', () {
      final state = SetupConsentState();
      state.userAgreement = true;
      state.privacyPolicy = true;
      state.sensitiveData = true;
      state.ageAttestation = true;
      expect(state.allAgreed, isFalse,
          reason: '医学免责声明未勾 → 不允进入下一步 (R103)',);
      state.medicalDisclaimer = true;
      expect(state.allAgreed, isTrue);
    });
  });

  group('MedDraft.fromTemplate (AR-20 批2a)', () {
    testWidgets('4. template → 草稿: name i18n / dosage 整数化 / unit / times 转 TimeOfDay',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(),
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));
      final template = templates.kMedicationTemplates.firstWhere(
        (t) => t.meds.isNotEmpty,
      );

      final draft = MedDraft.fromTemplate(template.meds.first, l10n);

      expect(draft.nameController.text, isNotEmpty);
      expect(draft.dosageController.text, isNotEmpty);
      expect(draft.dosageUnit, template.meds.first.dosageUnit);
      expect(draft.times.length, template.meds.first.times.length);
      for (var i = 0; i < draft.times.length; i++) {
        expect(
          draft.times[i],
          TimeOfDay(
            hour: template.meds.first.times[i].hour,
            minute: template.meds.first.times[i].minute,
          ),
        );
      }
      draft.dispose();
    });

    testWidgets('5. 整数 dosage → 无小数点, 小数 dosage → 保留小数', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(),
        ),
      );
      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold)));

      final intDosage = MedDraft.fromTemplate(
        const templates.MedicationDraft(
          nameKey: 'presetMedSsriName',
          dosage: 40.0,
          dosageUnit: 'mg',
          times: [],
        ),
        l10n,
      );
      expect(intDosage.dosageController.text, '40',
          reason: '40.0 → "40" (整数去 .0)',);
      intDosage.dispose();

      final fracDosage = MedDraft.fromTemplate(
        const templates.MedicationDraft(
          nameKey: 'presetMedSsriName',
          dosage: 12.5,
          dosageUnit: 'mg',
          times: [],
        ),
        l10n,
      );
      expect(fracDosage.dosageController.text, '12.5',
          reason: '12.5 → "12.5" (保留小数)',);
      fracDosage.dispose();
    });
  });

  group('SetupContactConsentFlow (AR-20 批2a)', () {
    testWidgets('6. 手机号全空 → 0 dialog + 空 result (联系人可选跳过)',
        (tester) async {
      final nameCtrl = TextEditingController();
      final phoneCtrl = TextEditingController();
      addTearDown(() {
        nameCtrl.dispose();
        phoneCtrl.dispose();
      });
      late BuildContext ctx;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      final result = await SetupContactConsentFlow.collect(
        context: ctx,
        nameControllers: [nameCtrl],
        phoneControllers: [phoneCtrl],
      );

      expect(result, isNotNull);
      expect(result!.contactList, isEmpty);
      expect(result.contactConsents, isEmpty);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('7. 同意 → contactList 1 条 (E.164 normalize + 空名 fallback) + consents 等长',
        (tester) async {
      final nameCtrl = TextEditingController();
      final phoneCtrl = TextEditingController(text: '13800138000');
      addTearDown(() {
        nameCtrl.dispose();
        phoneCtrl.dispose();
      });
      late BuildContext ctx;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      SetupContactConsentResult? result;
      final future = SetupContactConsentFlow.collect(
        context: ctx,
        nameControllers: [nameCtrl],
        phoneControllers: [phoneCtrl],
      ).then((r) => result = r);
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsOneWidget,
          reason: '填了手机号 → 必须弹 PIPL §13 同意 dialog',);

      await tester.tap(find.text('已告知并取得同意'));
      await tester.pumpAndSettle();
      await future;

      expect(result, isNotNull);
      expect(result!.contactList.length, 1);
      expect(result!.contactList.single.phone, '+8613800138000',
          reason: 'phone 走 PhoneValidator.normalize (E.164)',);
      expect(result!.contactList.single.name, isNotEmpty,
          reason: '姓名为空 → setupContactFallbackName(i+1) 兜底',);
      expect(result!.contactConsents.length, 1,
          reason: 'R68 CC-1: contactList 与 consents 等长',);
      expect(result!.contactConsents.single.kind,
          ConsentKind.emergencyContactSharing,);
    });

    testWidgets('8. 拒绝 → 返回 null + setupConsentRejected snackbar',
        (tester) async {
      final nameCtrl = TextEditingController();
      final phoneCtrl = TextEditingController(text: '13800138000');
      addTearDown(() {
        nameCtrl.dispose();
        phoneCtrl.dispose();
      });
      late BuildContext ctx;
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Builder(
                builder: (c) {
                  ctx = c;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      SetupContactConsentResult? result;
      var completed = false;
      final future = SetupContactConsentFlow.collect(
        context: ctx,
        nameControllers: [nameCtrl],
        phoneControllers: [phoneCtrl],
      ).then((r) {
        result = r;
        completed = true;
      });
      await tester.pumpAndSettle();
      await tester.tap(find.text('暂不同意'));
      await tester.pumpAndSettle();
      await future;

      expect(completed, isTrue);
      expect(result, isNull, reason: '拒绝 → null (PIPL §13 严同意, 终止 setup)');
      expect(find.textContaining('已拒绝该联系人'), findsOneWidget);

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    });
  });

  group('SetupSubmitFlow (AR-20 批2a)', () {
    testWidgets('9. run 成功序列: completeSetup → recordConsent → 通知重排 (不抛)',
        (tester) async {
      _mockNotificationChannels();
      addTearDown(_clearNotificationChannels);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final committer = _RecordingSetupCommitter(db);
      final profileRepo = _RecordingUserProfileRepository();
      late WidgetRef ref;
      late BuildContext ctx;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            notificationServiceProvider.overrideWithValue(
              _NoopNotificationService(),
            ),
            setupCommitterProvider.overrideWithValue(committer),
            userProfileRepositoryProvider.overrideWithValue(profileRepo),
            medicationRepositoryProvider.overrideWithValue(
              _EmptyMedicationRepository(),
            ),
          ],
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (c, r, _) {
                  ctx = c;
                  ref = r;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      var done = false;
      Object? thrown;
      unawaited(
        SetupSubmitFlow.run(
          ref: ref,
          context: ctx,
          userName: '小明',
          contactList: const [],
          contactConsents: const [],
          medicationList: const [],
        ).then((_) {
          done = true;
        }).catchError((Object e) {
          thrown = e;
        }),
      );
      await _pumpUntil(tester, () => done || thrown != null);

      expect(thrown, isNull, reason: '完整序列不应抛');
      expect(committer.calls, 1);
      expect(committer.receivedUserName, '小明');
      expect(profileRepo.recordConsentCalls, 1,
          reason: 'PIPL §14 同意留痕应在提交序列内调用',);
    });

    testWidgets('10. committer 抛 StateError → run 原样上抛 (caller 管 snackbar)',
        (tester) async {
      _mockNotificationChannels();
      addTearDown(_clearNotificationChannels);

      final db = AppDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final committer = _RecordingSetupCommitter(db)
        ..throwOnComplete = StateError(
          'contactList (1) 与 contactConsents (0) 长度不一致 (E5)',
        );
      late WidgetRef ref;
      late BuildContext ctx;

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
          child: MaterialApp(
            locale: const Locale('zh'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: Consumer(
                builder: (c, r, _) {
                  ctx = c;
                  ref = r;
                  return const SizedBox();
                },
              ),
            ),
          ),
        ),
      );

      Object? thrown;
      var done = false;
      unawaited(
        SetupSubmitFlow.run(
          ref: ref,
          context: ctx,
          userName: '小明',
          contactList: const [],
          contactConsents: const [],
          medicationList: const [],
        ).then((_) {
          done = true;
        }).catchError((Object e) {
          thrown = e;
        }),
      );
      await _pumpUntil(tester, () => done || thrown != null);

      expect(done, isFalse);
      expect(thrown, isA<StateError>(),
          reason: 'E5 StateError 原样上抛, 由 SetupPageState 管 error snackbar',);
      expect(committer.calls, 1);
    });

    test('11. collectMedications: 空药名跳过 + dosage 兜底 0 + times 转 HourMinute',
        () {
      final emptyName = MedDraft()
        ..nameController.text = '   '
        ..dosageController.text = '50';
      final valid = MedDraft()
        ..nameController.text = ' 舍曲林 '
        ..dosageController.text = '40.5'
        ..times.add(const TimeOfDay(hour: 8, minute: 0))
        ..times.add(const TimeOfDay(hour: 20, minute: 30));

      final result = SetupSubmitFlow.collectMedications([emptyName, valid]);
      addTearDown(() {
        emptyName.dispose();
        valid.dispose();
      });

      expect(result.length, 1, reason: '空药名 (trim 后空) → 跳过');
      expect(result.single.name, '舍曲林', reason: 'name 走 trim');
      expect(result.single.dosage, 40.5);
      expect(result.single.dosageUnit, 'mg');
      expect(result.single.times, [
        const HourMinute(hour: 8, minute: 0),
        const HourMinute(hour: 20, minute: 30),
      ]);
    });

    test('12. collectMedications: dosage 非法文本 → 兜底 0 (double.tryParse)', () {
      final invalid = MedDraft()
        ..nameController.text = '舍曲林'
        ..dosageController.text = 'abc';
      final result = SetupSubmitFlow.collectMedications([invalid]);
      addTearDown(invalid.dispose);

      expect(result.single.dosage, 0,
          reason: 'double.tryParse 失败 → 0 (跟原 _finishSetup 1:1)',);
    });
  });

  group('SetupWizardFrame (AR-20 批2a)', () {
    testWidgets('13. step=0 → canPop false; step>0 → canPop true (PopScope 壳)',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SetupWizardFrame(step: 0, child: Text('step-0')),
        ),
      );
      await tester.pumpAndSettle();

      // PopScope 在 Flutter 3.44 是 generic (PopScope<T>), byType(PopScope)
      // 匹配不到 runtimeType — 走 byWidgetPredicate + descendant 锁定
      // SetupWizardFrame 内的那一个 (Navigator 自身也包 PopScope)
      var popScope = tester.widget<PopScope<Object?>>(
        find.descendant(
          of: find.byType(SetupWizardFrame),
          matching: find.byWidgetPredicate((w) => w is PopScope),
        ),
      );
      expect(popScope.canPop, isFalse,
          reason: 'step 0 (consent) 不可 pop (必须显式走流程)',);
      expect(find.text('step-0'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SetupWizardFrame(step: 2, child: Text('step-2')),
        ),
      );
      await tester.pumpAndSettle();

      popScope = tester.widget<PopScope<Object?>>(
        find.descendant(
          of: find.byType(SetupWizardFrame),
          matching: find.byWidgetPredicate((w) => w is PopScope),
        ),
      );
      expect(popScope.canPop, isTrue,
          reason: 'step > 0 可 pop',);
      expect(find.text('step-2'), findsOneWidget);
    });

    testWidgets('14. 标题 = setupStep(step+1, totalSteps) + 进度条 currentStep 同步',
        (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          locale: Locale('zh'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: SetupWizardFrame(step: 2, child: SizedBox()),
        ),
      );
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(SetupWizardFrame)),
      );
      expect(find.text(l10n.setupStep(3, 4)), findsOneWidget,
          reason: 'title 应显示 "第 3 步 ／ 共 4 步"',);

      final progressBar = tester.widget<SetupProgressBar>(
        find.byType(SetupProgressBar),
      );
      expect(progressBar.currentStep, 2);
      expect(progressBar.totalSteps, 4);
    });
  });
}
