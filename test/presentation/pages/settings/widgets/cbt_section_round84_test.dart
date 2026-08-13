// v0.29 round 84 (CBT 思维记录): CbtSection widget 测试
//
// 覆盖:
// 1. 默认 SP 空 → level=three → 3 个 radio 全部渲染 + 3 栏 selected
// 2. 点击 5 栏 radio → SP key 'mood.thought_record_level' 立即写 5
// 3. mock initial SP value=7 → 渲染时 7 栏 selected (覆盖 SP 启动读路径)
//
// 模式 (跟项目其它 settings widget test 一致):
// - MaterialApp + AppLocalizations.localizationsDelegates + locale: Locale('zh')
// - ProviderScope overrides: sharedPreferencesProvider (cbt_providers.dart 公开名)
// - SharedPreferences.setMockInitialValues({...}) 注入初始值
//
// R97-P1-12 (2026-08-07): 迁移到 RadioGroup 新 API 测试。
// 之前测试读 deprecated `RadioListTile.groupValue` 字段 — 迁移到 RadioGroup 后
// 该字段为 null (group value 由祖先 RadioGroup 管理)。改读 RadioGroup.groupValue。
import 'package:chroniccare/domain/entities/thought_record_level.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/cbt_section.dart';
import 'package:chroniccare/presentation/providers/cbt_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kSpKey = 'mood.thought_record_level';

Widget _build({required SharedPreferences sp}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sp),
    ],
    child: const MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: Locale('zh'),
      home: Scaffold(
        body: CbtSection(),
      ),
    ),
  );
}

/// 从 widget tree 取 RadioGroup[ThoughtRecordLevel] 的 groupValue。
///
/// R97-P1-12: 迁移后 group value 由 RadioGroup 祖先集中管理, 不再读
/// RadioListTile.groupValue (deprecated + 始终 null)。
ThoughtRecordLevel? _groupValueOf(WidgetTester tester) {
  final group = tester.widget<RadioGroup<ThoughtRecordLevel>>(
    find.byType(RadioGroup<ThoughtRecordLevel>),
  );
  return group.groupValue;
}

void main() {
  // 1. 默认 SP 空 → level=three → 3 个 radio 全部渲染 + 3 栏 selected
  testWidgets('默认 level=three 渲染 3 栏 / 5 栏 / 7 栏 radio + 3 栏默认 selected',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(_build(sp: sp));
    await tester.pumpAndSettle();

    // 3 个 radio 标题都渲染
    expect(find.text('3 栏'), findsOneWidget);
    expect(find.text('5 栏'), findsOneWidget);
    expect(find.text('7 栏'), findsOneWidget);

    // v0.32 round 13 (R112 EM-02/AH-04 视觉债): 容器 Card → AppleListSection
    expect(find.byType(AppleListSection), findsOneWidget);
    expect(find.byType(Card), findsNothing);

    // 3 个 RadioListTile 全部存在
    expect(
      find.byType(RadioListTile<ThoughtRecordLevel>),
      findsNWidgets(3),
    );

    // 默认 SP 没 key → fromInt(null ?? 3) → three
    // R97-P1-12: 读 RadioGroup.groupValue (不再读 deprecated RadioListTile.groupValue)
    expect(_groupValueOf(tester), ThoughtRecordLevel.three);
  });

  // 2. 点击 5 栏 radio → SP 立即写 5
  testWidgets('点击 5 栏 radio 立即写 SP key "mood.thought_record_level"=5',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(_build(sp: sp));
    await tester.pumpAndSettle();

    // 点击 5 栏 radio 标题
    await tester.tap(find.text('5 栏'));
    await tester.pumpAndSettle();

    // SP 立即写入 5
    expect(sp.getInt(_kSpKey), 5);

    // widget 重建后, RadioGroup.groupValue 变成 five (覆盖已写 SP)
    expect(_groupValueOf(tester), ThoughtRecordLevel.five);
  });

  // 3. mock initial SP value=7 → 渲染时 7 栏 selected
  testWidgets('mock initial SP value=7 → 启动渲染时 7 栏 selected', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      _kSpKey: 7,
    });
    final sp = await SharedPreferences.getInstance();
    await tester.pumpWidget(_build(sp: sp));
    await tester.pumpAndSettle();

    // RadioGroup.groupValue == seven (SP 初始值 7 → fromInt(7) → seven)
    expect(_groupValueOf(tester), ThoughtRecordLevel.seven);
  });
}
