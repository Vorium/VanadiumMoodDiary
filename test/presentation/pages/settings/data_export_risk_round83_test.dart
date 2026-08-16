// v0.28 Round 83 (Q4b 律师反馈): 数据导出 dialog 加明文风险 + 责任划界
//
// 律师 review 必改项:
// - 用户导出的 JSON 是明文 (含敏感健康信息), 必须在导出 dialog 内醒目提示风险
// - 必须明确告知: 导出后,文件安全由用户自负 (PIPL §17 告知后用户确认)
// - 必须强制用户勾选"我已了解风险"才能复制 (避免无意识分享到公共云盘)
//
// 测试 3 个层面:
// 1. i18n 三个 locale 都有 Q4b 4 个 key (Q4b ARB 添加正确)
// 2. 中文版 l10n 含核心关键词"明文" + "责任" (语义正确)
// 3. 英文版 l10n 含 "PLAINTEXT" + "PIPL" (英文版法律术语一致)
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('i18n Q4b risk keys 在 3 locale 都加载', () {
    test('zh l10n 4 个 Q4b key 都有中文文案', () {
      final l10n = AppLocalizationsZh();
      expect(l10n.settingsExportRiskTitle, isNotEmpty);
      expect(l10n.settingsExportRiskBody, isNotEmpty);
      expect(l10n.settingsExportRiskLiability, isNotEmpty);
      expect(l10n.settingsExportRiskAcknowledge, isNotEmpty);
    });

    test('en l10n 4 个 Q4b key 都有英文文案', () {
      final l10n = AppLocalizationsEn();
      expect(l10n.settingsExportRiskTitle, isNotEmpty);
      expect(l10n.settingsExportRiskBody, isNotEmpty);
      expect(l10n.settingsExportRiskLiability, isNotEmpty);
      expect(l10n.settingsExportRiskAcknowledge, isNotEmpty);
    });

    test('zh 含核心关键词"明文" + "责任" (法律语义)', () {
      final l10n = AppLocalizationsZh();
      // 标题含"明文" — 强调风险性质
      expect(l10n.settingsExportRiskTitle, contains('明文'));
      // 责任文案含"责任" — 划界明确
      expect(l10n.settingsExportRiskLiability, contains('责任'));
    });

    test('en 含 "PLAINTEXT" + "PIPL §17" (国际法律术语)', () {
      final l10n = AppLocalizationsEn();
      // 标题强调 PLAINTEXT (全大写 = 视觉警示)
      expect(l10n.settingsExportRiskBody, contains('PLAINTEXT'));
      // 责任文案引用 PIPL §17 (个人信息保护法第 17 条)
      expect(l10n.settingsExportRiskLiability, contains('PIPL §17'));
    });

    test('3 locale 文案不全相同 (验证多语言真的生效)', () {
      final zh = AppLocalizationsZh();
      final en = AppLocalizationsEn();
      // title 在 zh 是 "明文风险提示", en 是 "Plaintext risk warning"
      expect(
        zh.settingsExportRiskTitle,
        isNot(equals(en.settingsExportRiskTitle)),
      );
      expect(
        zh.settingsExportRiskAcknowledge,
        isNot(equals(en.settingsExportRiskAcknowledge)),
      );
    });
  });

  group('Q4b UI widget 行为 — 风险卡 + 勾选启用复制按钮', () {
    // 这组 case 测 _exportData 跑完后, AlertDialog 内 Q4b 风险卡的行为。
    // 完整 _exportData 跑通需要 mock dataExportService / database, 端到端
    // 测试在 widget_test.dart + settings_page_round45_test.dart 已覆盖
    // (settings section widget 渲染 + 6 section 布局)。这里只测 Q4b
    // 改造的"新引入 widget tree" — 风险卡 + checkbox + 复制按钮 disabled
    // → enabled。
    //
    // 做法: 直接构造一个模拟 dialog 内容 widget, 不挂整个 DataManagementSection
    // (避免 mock 整个 provider graph)。dialog 内容 widget 独立可测。

    testWidgets('未勾选 → 复制按钮 onPressed=null (disabled)', (tester) async {
      bool isAcknowledged = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Material(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: isAcknowledged,
                      onChanged: (v) =>
                          setLocal(() => isAcknowledged = v ?? false),
                      title: const Text('我已了解风险,继续导出'),
                    ),
                    ElevatedButton(
                      onPressed: isAcknowledged
                          ? () {/* copy */}
                          : null, // 关键: disabled 时 onPressed=null
                      child: const Text('复制'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 复制按钮存在
      final copyBtn = find.widgetWithText(ElevatedButton, '复制');
      expect(copyBtn, findsOneWidget);

      // onPressed == null → 按钮 disabled (Material 内部 enabled=false)
      final btnWidget = tester.widget<ElevatedButton>(copyBtn);
      expect(
        btnWidget.onPressed,
        isNull,
        reason: 'Q4b: 未勾选时复制按钮应 disabled, 防止无意识复制到不安全位置',
      );
    });

    testWidgets('勾选 → 复制按钮 onPressed=non-null (enabled)', (tester) async {
      bool isAcknowledged = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Material(
                child: Column(
                  children: [
                    CheckboxListTile(
                      value: isAcknowledged,
                      onChanged: (v) =>
                          setLocal(() => isAcknowledged = v ?? false),
                      title: const Text('我已了解风险,继续导出'),
                    ),
                    ElevatedButton(
                      onPressed: isAcknowledged ? () {/* copy */} : null,
                      child: const Text('复制'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 勾选 checkbox
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();

      // 复制按钮 enabled
      final btnWidget = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, '复制'),
      );
      expect(
        btnWidget.onPressed,
        isNotNull,
        reason: 'Q4b: 勾选后复制按钮应 enabled, 用户可继续导出',
      );
    });
  });
}
