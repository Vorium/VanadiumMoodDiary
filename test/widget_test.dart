// v0.27 round 61 (R61): 替代 flutter create 默认 widget_test.dart
//
// 之前默认 test 引用 `MyApp` (flutter create 占位 Counter app),
// 项目用 `AppRoot` (ConsumerStatefulWidget + ProviderScope + DB),
// 跑 widget test 需完整 mock DB / notification / SMS 等, 复杂度高。
//
// 改: 测轻量目标 - i18n 资源加载, 确认 l10n key 可被解析。
// 完整 widget test 已有 1148 个分布在 test/presentation/ 下。

import 'package:flutter_test/flutter_test.dart';

import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';

void main() {
  testWidgets('i18n: AppLocalizations 中文版可加载关键 key', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizationsZh();
    // 关键 key 存在性 smoke test
    expect(l10n.commonSave, isNotEmpty);
    expect(l10n.commonCancel, isNotEmpty);
    expect(l10n.medicationUnitMg, equals('mg'));
    expect(l10n.medicationUnitTablet, equals('片'));
    expect(l10n.safetyCheckResultDisabled, isNotEmpty);
  });

  testWidgets('i18n: AppLocalizations 英文版可加载关键 key', (
    WidgetTester tester,
  ) async {
    final l10n = AppLocalizationsEn();
    expect(l10n.commonSave, isNotEmpty);
    expect(l10n.commonCancel, isNotEmpty);
    expect(l10n.medicationUnitMg, equals('mg'));
    expect(l10n.medicationUnitTablet, equals('tablet'));
    expect(l10n.safetyCheckResultDisabled, isNotEmpty);
  });

  test('i18n: 中英文文案不同 (验证多语言真的生效)', () {
    final zh = AppLocalizationsZh();
    final en = AppLocalizationsEn();
    // medicationUnitTablet 在 zh 是 '片', en 是 'tablet'
    expect(zh.medicationUnitTablet, isNot(equals(en.medicationUnitTablet)));
  });
}
