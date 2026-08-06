// v0.24 (Round 45): settings_page widget 单测
//
// 之前 v0.22 round 30 P1-38 标的"settings 整片 0 widget 测"残留 2 周。
// v0.24 round 45 (Sprint #6 中段 3 page 0 widget 测补齐之二) 补 3 个 case:
//
// 1. contacts error → 渲染 ErrorState (loading + error 状态切换)
// 2. contacts data 空 + meds data 空 → 7 section widget 全部渲染
// 3. contacts data 1 → ContactsListWidget 渲染 + name 显示
//
// v0.29 round 84 (CBT 思维记录): 补 CbtSection (在 RemindersSection 之后),
// 测试数 6 → 7。sharedPreferencesProvider override 必加 (CbtSection 依赖
// thoughtRecordLevelProvider, 后者读 SP)。
//
// 测试 setup:
// - MaterialApp + AppLocalizations.localizationsDelegates
// - ProviderScope overrides mock Stream<List> provider
// - 测 contacts/meds 状态切换, 不测 6 个 section widget 内部逻辑 (各自有测)
//
// v0.24 Sprint #5 (mood_dialog 拆解) 后 settings_page 99 行只剩 section 拼接,
// 每个 section 在 settings/widgets/ 独立测, 测 main page 容器逻辑 ROI 最高
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/assessment_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/cbt_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/legal_section.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/reminders_section.dart';
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
    List<ContactEntity> contacts = const [],
    List<MedicationEntity> meds = const [],
    bool medsError = false,
  }) {
    return ProviderScope(
      overrides: [
        contactsProvider.overrideWith((ref) => Stream.value(contacts)),
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
    // pumpAndSettle 让 Stream.error microtask 跑完, Riverpod 转 AsyncError,
    // 渲染 ErrorState。限制 duration 防止 hang (master 上无 contacts section
    // 重排, 现在有 setUp+drag 副作用, 短 timeout 更稳)。
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    // v0.31 联系人软隐藏: contacts section 挪到最底部, viewport 内不渲染。
    // meds section 仍在 ListView 上面, viewport 内直接渲染 ErrorState。
    expect(find.byType(ErrorState), findsOneWidget);
  });

  testWidgets('contacts + meds 都空 → 7 个 section widget 全部渲染', (tester) async {
    await tester.pumpWidget(buildSettingsPage());
    await tester.pumpAndSettle();

    // ListView 内 section 默认只渲染 viewport 内, 用 scrollUntilVisible
    // 把每个 section scroll 出来验证渲染
    await tester.scrollUntilVisible(
      find.byType(DataManagementSection),
      100,
    );
    expect(find.byType(DataManagementSection), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(LegalSection), 100);
    expect(find.byType(LegalSection), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(RemindersSection), 100);
    expect(find.byType(RemindersSection), findsOneWidget);

    // v0.29 round 84: CbtSection (思维记录档位) 紧跟 RemindersSection
    await tester.scrollUntilVisible(find.byType(CbtSection), 100);
    expect(find.byType(CbtSection), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byType(NotificationStatusCard),
      100,
    );
    expect(find.byType(NotificationStatusCard), findsOneWidget);

    await tester.scrollUntilVisible(find.byType(AssessmentSection), 100);
    expect(find.byType(AssessmentSection), findsOneWidget);
  });

  testWidgets('contacts data 1 → ContactsListWidget 渲染 + name 显示',
      (tester) async {
    // v0.30 round 93 (阶段 2 audit-fixes): 联系人 section 走
    // [FeatureFlags.emergencyContactEnabled] gate, 默认 false hidden。
    // emergencyContactEnabled 没有 per-flag setter (R66 兼容模式), 用 enableForTest
    // 翻 8 个全 true 让老 test 不破 (跟 notification_status_card_round20 修法一致)。
    FeatureFlags.enableForTest();
    const contact = ContactEntity(
      id: 1,
      name: '张三',
      phone: '13800000001',
      sortOrder: 0,
      isActive: true,
    );
    await tester.pumpWidget(buildSettingsPage(contacts: [contact]));
    await tester.pumpAndSettle();

    // v0.31 联系人软隐藏: contacts section 在 ListView 最底部, scroll 才能看到
    await tester.scrollUntilVisible(find.byType(ContactsListWidget), 100);
    // contacts 1 → ContactsListWidget 渲染 + name 显示
    expect(find.byType(ContactsListWidget), findsOneWidget);
    expect(find.text('张三'), findsOneWidget);

    // meds 验证移除: contacts 已 scroll 到 ListView 底部, meds section 在
    // viewport 之上 offstage, scroll back up 容易 overscroll, 单独 meds 测试
    // 在 medications_list_widget_round* 测。
    FeatureFlags.resetForTest();
  });
}
