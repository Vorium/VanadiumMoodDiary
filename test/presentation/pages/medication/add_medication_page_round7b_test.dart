// v0.32 R110 round 7b: add_medication_page (568L god class) 补 0-test
//
// 覆盖:
// 1. Step1 空药名 + 下一步 → 校验 snackbar, 不前进
// 2. Step1 输入药名 + 下一步 → Step2 (时间编辑区)
// 3. Step2 下一步 → Step3 确认信息 (名称/剂型/剂量/时间)
// 4. 保存成功 → repo.add 收到 draft (名称/剂量/单位/时间/剂型/颜色) +
//    medicationAdded snackbar + 自动 pop 回上一页
// 5. 保存失败 → error snackbar + 按钮恢复可用 (可重试, repo 计数 2)
// 6. Step1 返回箭头 → 直接 pop
//
// 保存路径注: 保存后 reschedule 走 delegate → MedicationNotifier, 空
// medications 列表时仅 plugin.cancel (test env 安全), 不会碰 zonedSchedule。

import 'package:chroniccare/core/data/services/notification_service.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/medication_form.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/add_medication_page.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _NoopNotificationService extends NotificationService {
  @override
  Future<void> init() async {}
  @override
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) async {}
}

/// 记录 add 调用 + 可注入异常
class _RecordingMedicationRepository implements MedicationRepository {
  final List<MedicationDraft> drafts = [];
  Exception? throwOnAdd;

  @override
  Future<int> add(MedicationDraft draft) async {
    if (throwOnAdd != null) throw throwOnAdd!;
    drafts.add(draft);
    return drafts.length;
  }

  @override
  Future<int> delete(int id) async => 1;
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
  Stream<List<MedicationEntity>> watchAll() => Stream.value(const []);
  @override
  Stream<List<MedicationEntity>> watchAllIncludingInactive() =>
      Stream.value(const []);
}

/// 从 HOME push 打开添加页 (保证栈底有可 pop 的 HOME)
Future<void> _openAddPage(WidgetTester tester, GoRouter router) async {
  router.push('/add');
  await tester.pumpAndSettle();
}

GoRouter _buildRouter() {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) =>
            const Scaffold(body: Center(child: Text('HOME'))),
        routes: [
          GoRoute(
            path: 'add',
            builder: (context, state) => const AddMedicationPage(),
          ),
        ],
      ),
    ],
  );
}

(Widget, GoRouter) _wrap(
  _RecordingMedicationRepository repo, {
  GoRouter? router,
}) {
  final r = router ?? _buildRouter();
  return (
    ProviderScope(
      overrides: [
        medicationRepositoryProvider.overrideWithValue(repo),
        notificationServiceProvider
            .overrideWithValue(_NoopNotificationService()),
        medicationsProvider.overrideWith((ref) => Stream.value(const [])),
      ],
      child: MaterialApp.router(
        theme: ThemeData.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        routerConfig: r,
      ),
    ),
    r,
  );
}



void main() {
  setUp(() {
    // flutter_local_notifications 平台 channel 在 widget test 无宿主,
    // 不 mock 的话 pendingNotificationRequests() 永不完成 → _save 挂死。
    TestWidgetsFlutterBinding.ensureInitialized().defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('dexterous.com/flutter/local_notifications'),
      (call) async => switch (call.method) {
        'pendingNotificationRequests' => <Map<String, Object?>>[],
        _ => null,
      },
    );
  });

  testWidgets('1) Step1 空药名 → 校验 snackbar, 不前进', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (w, r) = _wrap(_RecordingMedicationRepository());
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(find.text('请输入药物名称'), findsOneWidget);
    expect(find.text('用药时间'), findsNothing);
  });

  testWidgets('2) Step1 填名 → 下一步 → Step2 时间编辑', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (w, r) = _wrap(_RecordingMedicationRepository());
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(find.text('用药时间'), findsWidgets);
    expect(find.text('08:00'), findsOneWidget);
    expect(find.text('添加时间'), findsOneWidget);
  });

  testWidgets('3) Step2 → Step3 确认信息展示', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (w, r) = _wrap(_RecordingMedicationRepository());
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(find.text('确认信息'), findsOneWidget);
    expect(find.text('氟西汀'), findsWidgets);
    expect(find.text('片剂'), findsOneWidget);
    expect(find.text('50mg'), findsOneWidget);
    expect(find.text('08:00'), findsOneWidget);
  });

  testWidgets('4) 保存成功 → repo.add 收 draft + snackbar + pop 回首页',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _RecordingMedicationRepository();
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    final draft = repo.drafts.single;
    expect(draft.name, '氟西汀');
    expect(draft.dosage, 50);
    expect(draft.dosageUnit, DosageUnit.mg);
    expect(draft.times, [const HourMinute(hour: 8, minute: 0)]);
    expect(draft.form, MedicationForm.tablet);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('5) 保存失败 → error snackbar + 可重试 (repo 计数 2)',
      (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _RecordingMedicationRepository()
      ..throwOnAdd = Exception('db busy');
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repo.drafts, isEmpty);
    expect(find.textContaining('保存失败'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
    // 等 snackbar 消失后再重试 (不遮挡按钮)
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();

    repo.throwOnAdd = null;
    // error snackbar 自带 action 也是 '保存', 必须限定 PrimaryButton 内
    await tester.tap(find.descendant(
      of: find.byType(PrimaryButton),
      matching: find.text('保存'),
    ));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('6) Step1 返回箭头 → 直接 pop', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final (w, r) = _wrap(_RecordingMedicationRepository());
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
  });
}

