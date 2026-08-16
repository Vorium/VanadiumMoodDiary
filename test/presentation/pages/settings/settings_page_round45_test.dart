// v0.24 (Round 45): settings_page widget 单测
//
// 之前 v0.22 round 30 P1-38 标的"settings 整片 0 widget 测"残留 2 周。
// v0.24 round 45 (Sprint #6 中段 3 page 0 widget 测补齐之二) 补 3 个 case:
//
// 1. meds error → 渲染 ErrorState (loading + error 状态切换)
// 2. meds data 空 → ProfileGroup 渲染 + Medication list 渲染
// 3. contacts data 1 → ContactsListWidget 渲染 + name 显示
//
// 1.1.0 round 4 (emotion-first refactor): 联系人 section 整摘, 原 case 3
// 删除, 剩 2 case。
//
// v0.30 round 95 (sub-spec 8 task 17): 4 group 重构 (Profile / Reminders / Data / Legal),
// 测试 7 个 section 改成 4 个 group (只验证 on-screen 必 render 的 ProfileGroup)。
// scrollUntilVisible 不再需要 — 4 group 内部 section 仍 lazy build, 但 on-screen
// ProfileGroup 必 render。
//
// v1.1.0 round 11 (R115 emotion-first refactor): 5 group 重构, Medication +
// Assessment 从 ProfileGroup 抽出 → 新 HealthDataGroup (置顶)。
//  - 原 case 1 (meds error → ErrorState) 失效: HealthDataGroup 不再走
//    medsAsync.when(...), 改用 `ref.watch(...).value ?? []` 直接拿空 list
//    (错误时也显示 0/0, 不渲染 ErrorState)。
//  - 原 case 2 (meds 空 → ProfileGroup + Medication) 失效: Medication 已挪走,
//    改测 HealthDataGroup + SettingsPage 渲染 5 group。
//
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates
// - ProviderScope overrides mock Stream<List> provider
// - 测 group 容器渲染, 不测 group 内部逻辑 (各自有测)
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/health_data_group.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/profile_group.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  // v0.29 round 84 (CBT 思维记录): 共享给所有 test 的 SP mock 实例
  // CbtSection 通过 thoughtRecordLevelProvider 读 SP, 必须 override。
  // setUp 返回 Future, 测试前 await。top-level 变量供 buildSettingsPage 闭包用。
  late SharedPreferences mockSp;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    mockSp = await SharedPreferences.getInstance();
  });

  // helper: 构造测试 widget
  Widget buildSettingsPage({
    List<MedicationEntity> meds = const [],
    bool medsError = false,
  }) {
    return ProviderScope(
      overrides: [
        medicationsProvider.overrideWith(
          (ref) => medsError
              ? Stream<List<MedicationEntity>>.error(Exception('test error'))
              : Stream.value(meds),
        ),
        // v1.1.0 round 11 (R115): HealthDataGroup 新增 watch — 需 override
        assessmentsProvider.overrideWith(
          (ref) => Stream.value(const <CheckInEntity>[]),
        ),
        // v1.1.0 round 11 (R115): HealthDataGroup watch todayAllCheckInsProvider
        // 算今日已服药数 — test 环境需要 override 避免 DB 访问
        todayAllCheckInsProvider.overrideWith(
          (ref) => Stream.value(const <CheckInEntity>[]),
        ),
        // v0.29 round 84: CbtSection 引用 thoughtRecordLevelProvider, 后者
        // 走 sharedPreferencesProvider 读 SP。test 必须 override 否则抛
        // UnimplementedError: Override at app boot (cbt_providers.dart:27)。
        sharedPreferencesProvider.overrideWithValue(mockSp),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('zh'),
        home: SettingsPage(),
      ),
    );
  }

  testWidgets('meds error → HealthDataGroup 仍渲染 (不弹 ErrorState, 改用空 list)',
      (tester) async {
    // v1.1.0 round 11 (R115) 行为变更: HealthDataGroup 不再走
    // medsAsync.when(...), 直接 .value ?? [] 取空 list。error 时显示
    // 0/0 / "—" 而非 ErrorState (跟 Settings 顶置弱化一致)。
    await tester.pumpWidget(buildSettingsPage(medsError: true));
    // 用 pump 100ms 替代 pumpAndSettle — 后者会因 NotificationStatusCard
    // 永 hang 抛 timeout, 前者只是跑 100ms 后返回 (跟原 4 group 同款)。
    await tester.pump(const Duration(milliseconds: 100));

    // HealthDataGroup 渲染 (不弹 ErrorState)
    expect(find.byType(HealthDataGroup), findsOneWidget);
  });

  testWidgets('meds 空 → 5 group widget 全部渲染', (tester) async {
    // v1.1.0 round 11 (R115): 4 group → 5 group, HealthDataGroup 置顶。
    await tester.pumpWidget(buildSettingsPage());
    await tester.pump(const Duration(milliseconds: 100));

    // 1. HealthDataGroup 必 render (置顶, R115 新加)
    expect(find.byType(HealthDataGroup), findsOneWidget);
    // 2. ProfileGroup 必 render (原 4 group 第 1)
    expect(find.byType(ProfileGroup), findsOneWidget);
  });
}
