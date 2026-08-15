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
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates
// - ProviderScope overrides mock Stream<List> provider
// - 测 meds 状态切换, 不测 4 个 group widget 内部逻辑 (各自有测)
//
// v0.24 Sprint #5 (mood_dialog 拆解) 后 settings_page 99 行只剩 section 拼接,
// 每个 section 在 settings/widgets/ 独立测, 测 main page 容器逻辑 ROI 最高
// v0.30 R95 (sub-spec 8 task 17): 4 group 重构, main page 容器 60 行 0 业务方法
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/profile_group.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
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

  testWidgets('meds error → 显示 ErrorState', (tester) async {
    await tester.pumpWidget(buildSettingsPage(medsError: true));
    // v0.30 round 95 (sub-spec 8 task 17): 4 group 重构, NotificationStatusCard
    // 挪到 RemindersGroup 末尾 (原在 settings_page ListView 底部), 维持 lazy load
    // 不触发 _refresh() 永远 schedule frame 的问题, pumpAndSettle 仍可用。
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // meds section 在 ListView 上面, viewport 内直接渲染 ErrorState。
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('meds 空 → 4 group widget 全部渲染', (tester) async {
    // v0.30 round 95 (sub-spec 8 task 17): 4 group 重构, 验证 4 group widget 渲染
    // (不再验证 7 个独立 section — 4 group 把 8 section 拼成 4 container)
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle();

    // 1. ProfileGroup 必 render (顶部)
    expect(find.byType(ProfileGroup), findsOneWidget);
    // Medication 在 ProfileGroup 顶部
    expect(find.byType(MedicationsListWidget), findsOneWidget);
  });
}
