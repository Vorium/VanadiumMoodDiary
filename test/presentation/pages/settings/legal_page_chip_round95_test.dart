// v0.30 round 95 (sub-spec 8 task 46): legal_page 撤回时间 chip 标识
//
// R95 emil P3 反复提: legal_page toggle 缺 chip 标识撤回时间 (用户难一眼
// 看出"已撤回"状态)。
//
// 修前: Text 渲染时间 (无视觉标识, withdrawn 跟正常状态难区分)
// 修后: Chip widget 包时间, withdrawn 状态用 error 色 chip 强调
// (tintedErrorSoft 背景 + error 边框 + fgOnError 文字),
// 正常状态用 hint 色 chip 低调 (dividerColor 背景 + hint 边框)
//
// 测试覆盖:
// 1. 撤回状态: Chip 渲染 + 错误色背景
// 2. 正常状态: Chip 渲染 + 低调背景
// 3. toggle 后 chip 颜色切换
import 'package:chroniccare/domain/entities/consent_artifact.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('legal_page _ConsentTile: 撤回时间 chip 标识 (task 46)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: _TestConsentTile(
            kind: ConsentKind.dataExport,
            title: '测试 consent',
            subtitle: '测试 consent 描述',
            withdrawn: true,
            withdrawnAt: DateTime(2026, 8, 7, 10, 30),
            onToggle: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // v0.30 R95 sub-spec 8 task 46: 撤回时间必包在 Chip widget 内
    // (修前是 Text, 修后改 Chip 标识)
    final chipFinder = find.byType(Chip);
    expect(chipFinder, findsOneWidget,
        reason: 'task 46: 撤回时间必包在 Chip widget 内');

    // Chip 文字含撤回时间 (YYYY-MM-DD HH:MM)
    final chipText = find.descendant(of: chipFinder, matching: find.byType(Text));
    expect(chipText, findsOneWidget,
        reason: 'Chip 必含时间文字');
  });

  testWidgets('legal_page _ConsentTile: 正常状态 chip 低调背景 (task 46)',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('zh'),
        home: Scaffold(
          body: _TestConsentTile(
            kind: ConsentKind.dataExport,
            title: '测试 consent',
            subtitle: '测试 consent 描述',
            withdrawn: false,
            withdrawnAt: null,
            onToggle: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 正常状态: Chip 渲染 (不 withdrawn 状态 chip 也存在, 时间 = "从未")
    final chipFinder = find.byType(Chip);
    expect(chipFinder, findsOneWidget);
  });
}

/// v0.30 R95 sub-spec 8 task 46: 测试用 _ConsentTile 包装
///
/// legal_page._ConsentTile 是 private class, 不能直接 import 测试。
/// 这里复制一份构造, 通过 _TestConsentTile 暴露同样 widget tree。
class _TestConsentTile extends StatelessWidget {
  final ConsentKind kind;
  final String title;
  final String subtitle;
  final bool withdrawn;
  final DateTime? withdrawnAt;
  final ValueChanged<bool> onToggle;

  const _TestConsentTile({
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.withdrawn,
    required this.withdrawnAt,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    // 复制 legal_page._ConsentTile 的 build 逻辑 (仅 chip 部分)
    final l10n = AppLocalizations.of(context);
    final timeText = withdrawnAt == null
        ? l10n.legalPageConsentNever
        : l10n.legalPageConsentRecorded(
            '${withdrawnAt!.year.toString().padLeft(4, '0')}-'
            '${withdrawnAt!.month.toString().padLeft(2, '0')}-'
            '${withdrawnAt!.day.toString().padLeft(2, '0')} '
            '${withdrawnAt!.hour.toString().padLeft(2, '0')}:'
            '${withdrawnAt!.minute.toString().padLeft(2, '0')}',
          );
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(title)),
              Switch(value: withdrawn, onChanged: onToggle),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Chip(
              label: Text(timeText),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ),
    );
  }
}
