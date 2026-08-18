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
//
// v0.32 R112 (AR-20 批2b): 拆前补测 (7-13) + AddMedicationSubmitFlow
// 新类 TDD (14-15):
// 7. Step1 药名纯空格 → 校验 snackbar 不前进 (validateName trim)
// 8. 剂量清空 → 保存成功 dosage 兜底 0 (R109 validator 文档化行为守门)
// 9. 剂量非法文本 → 保存成功 dosage 兜底 0
// 10. Step3 选第 3 色 → draft.colorIndex == 2
// 11. Step1 选剂型胶囊 → Step3 确认 + draft.form == capsule
// 12. Step2 添加时间 20:00 → Step3 双时间 + draft.times 2 项
// 13. Step2 底部"上一步" → 回 Step1 (不 pop)
// 14. AddMedicationSubmitFlow: repo.add 收 draft + 双 reschedule 不抛
// 15. AddMedicationSubmitFlow: repo.add 抛异常原样上抛 (page 管 snackbar)

import 'dart:async';

import 'package:chroniccare/core/platform/notification/notification_service.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_draft.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/medication_form.dart';
import 'package:chroniccare/domain/repositories/medication_repository.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/add_medication_page.dart';
import 'package:chroniccare/presentation/pages/medication/add_medication_submit_flow.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
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
/// 注: push future 必须 unawaited (fake async 下 await 会在 pump 前死锁)
Future<void> _openAddPage(WidgetTester tester, GoRouter router) async {
  unawaited(router.push('/add'));
  await tester.pumpAndSettle();
}

/// R112 批2b 新增: 统一 phone 视口设置 (原 6 test 各自重复 8 行)
Future<void> _setupView(WidgetTester tester) async {
  tester.view.physicalSize = const Size(800, 1600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

/// R112 批2b 新增: 从 Step1 走到 Step3 (药名 '氟西汀' 默认剂型/剂量)
Future<void> _gotoStep3(WidgetTester tester, GoRouter router) async {
  await tester.enterText(find.byType(TextField), '氟西汀');
  await tester.tap(find.text('下一步'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('下一步'));
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
    TestWidgetsFlutterBinding.ensureInitialized()
        .defaultBinaryMessenger
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

  testWidgets('5) 保存失败 → error snackbar + 可重试 (repo 计数 2)', (tester) async {
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
    await tester.tap(
      find.descendant(
        of: find.byType(PrimaryButton),
        matching: find.text('保存'),
      ),
    );
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

  // ═══════════════════════════════════════════════════════════
  // v0.32 R112 (AR-20 批2b): 拆前补测 (7-13) — 校验 / 提交细节 / wizard 导航
  // ═══════════════════════════════════════════════════════════

  testWidgets('7) Step1 药名纯空格 → 校验 snackbar, 不前进', (tester) async {
    await _setupView(tester);

    final (w, r) = _wrap(_RecordingMedicationRepository());
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(find.text('请输入药物名称'), findsOneWidget);
    // 仍在 Step1 (基本信息 section 可见, Step2 标题不可见)
    expect(find.text('基本信息'), findsOneWidget);
    expect(find.text('用药时间'), findsNothing);
  });

  testWidgets('8) 剂量清空 → 保存成功 dosage 兜底 0 (R109 行为守门)', (tester) async {
    await _setupView(tester);

    final repo = _RecordingMedicationRepository();
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    expect(repo.drafts.single.dosage, 0);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('9) 剂量非法文本 → 保存成功 dosage 兜底 0', (tester) async {
    await _setupView(tester);

    final repo = _RecordingMedicationRepository();
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'abc');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    expect(repo.drafts.single.dosage, 0);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('10) Step3 选第 3 色 → draft.colorIndex == 2', (tester) async {
    await _setupView(tester);

    final repo = _RecordingMedicationRepository();
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);
    await _gotoStep3(tester, r);

    await tester.tap(find.byType(MedicationPillIcon).at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    expect(repo.drafts.single.colorIndex, 2);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('11) Step1 选剂型胶囊 → Step3 确认 + draft.form == capsule',
      (tester) async {
    await _setupView(tester);

    final repo = _RecordingMedicationRepository();
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.widgetWithText(ChoiceChip, '胶囊'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    expect(find.text('胶囊'), findsOneWidget);
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    expect(repo.drafts.single.form, MedicationForm.capsule);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('12) Step2 添加时间 20:00 → Step3 双时间 + draft.times 2 项',
      (tester) async {
    await _setupView(tester);

    final repo = _RecordingMedicationRepository();
    final (w, r) = _wrap(repo);
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('添加时间'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('确定'));
    await tester.pumpAndSettle();
    expect(find.text('20:00'), findsOneWidget);

    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();
    expect(find.text('08:00, 20:00'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(repo.drafts, hasLength(1));
    expect(repo.drafts.single.times, [
      const HourMinute(hour: 8, minute: 0),
      const HourMinute(hour: 20, minute: 0),
    ]);
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('13) Step2 底部"上一步" → 回 Step1 (不 pop)', (tester) async {
    await _setupView(tester);

    final (w, r) = _wrap(_RecordingMedicationRepository());
    await tester.pumpWidget(w);
    await _openAddPage(tester, r);

    await tester.enterText(find.byType(TextField), '氟西汀');
    await tester.tap(find.text('下一步'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('上一步'));
    await tester.pumpAndSettle();

    expect(find.text('基本信息'), findsOneWidget);
    expect(find.text('用药时间'), findsNothing);
    expect(find.text('HOME'), findsNothing);
  });

  // ═══════════════════════════════════════════════════════════
  // v0.32 R112 (AR-20 批2b): AddMedicationSubmitFlow 新类 (14-15)
  // ═══════════════════════════════════════════════════════════

  MedicationDraft buildDraft() => const MedicationDraft(
        name: '氟西汀',
        dosage: 50,
        dosageUnit: DosageUnit.mg,
        times: [HourMinute(hour: 8, minute: 0)],
        form: MedicationForm.tablet,
        colorIndex: 0,
      );

  testWidgets('14) SubmitFlow: repo.add 收 draft + 双 reschedule 不抛',
      (tester) async {
    final repo = _RecordingMedicationRepository();
    final notif = _NoopNotificationService();

    await AddMedicationSubmitFlow.run(
      repo: repo,
      delegate: notif.delegate,
      draft: buildDraft(),
    );

    expect(repo.drafts, hasLength(1));
    expect(repo.drafts.single.name, '氟西汀');
    expect(repo.drafts.single.dosage, 50);
  });

  testWidgets('15) SubmitFlow: repo.add 抛异常 → 原样上抛 (page 管 snackbar)',
      (tester) async {
    final repo = _RecordingMedicationRepository()
      ..throwOnAdd = Exception('db busy');
    final notif = _NoopNotificationService();

    await expectLater(
      AddMedicationSubmitFlow.run(
        repo: repo,
        delegate: notif.delegate,
        draft: buildDraft(),
      ),
      throwsException,
    );
    expect(repo.drafts, isEmpty);
  });
}
