// v1.1.0+167 R122 P2-2 (legal_page 555L 拆 3 facade 模式) regression test:
// legal_page 主壳拆 4 widget + 1 enum 到 widgets/legal_*.dart, 主壳
// 555L → 344L (-38%)。
//
// Goal: if anyone re-merges 4 widget + 1 enum 回主 legal_page 文件 (undoing
// the split), this test fails. The split is a soft architectural choice
// (file size + readability), not a functional one — so the test asserts
// structural properties:
//
//   1. 5 文件双存在 (主壳 + 4 widget + 1 enum)
//   2. 主壳 < 400L (R122 拆后 344L, god-class size guard — R108 §六 555L
//      起点, 拆 -38% 显著改进)
//   3. 主壳不再含 4 private widget class (_SectionTitle / _DocTile /
//      _ConsentTile / _WithdrawOption)
//   4. 主壳不再含 _VentWithdrawChoice private enum
//   5. 4 widget + 1 enum 公开名 (LegalSectionTitle / LegalDocTile /
//      LegalConsentTile / LegalWithdrawOption / LegalWithdrawChoice) 各自
//      提供 super.key
//   6. 5 文件总和 < 700L (拆前 555L, +overhead 限 < 26%, 主要是 import / 文档)
//
// Functional correctness: integration tests under `test/presentation/`
// (legal_page_chip_round95 + legal_withdraw_error_round113 + ...)

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('R122 P2-2 — legal_page 拆 4 widget + 1 enum', () {
    const mainPath = 'lib/features/settings/presentation/pages/settings/legal_page.dart';
    const sectionTitlePath =
        'lib/features/settings/presentation/pages/settings/widgets/legal_section_title.dart';
    const docTilePath =
        'lib/features/settings/presentation/pages/settings/widgets/legal_doc_tile.dart';
    const consentTilePath =
        'lib/features/settings/presentation/pages/settings/widgets/legal_consent_tile.dart';
    const withdrawOptionPath =
        'lib/features/settings/presentation/pages/settings/widgets/legal_withdraw_option.dart';
    const withdrawChoicePath =
        'lib/features/settings/presentation/pages/settings/widgets/legal_withdraw_choice.dart';

    test('6 文件双存在 (主壳 + 4 widget + 1 enum)', () {
      expect(File(mainPath).existsSync(), isTrue, reason: mainPath);
      expect(File(sectionTitlePath).existsSync(), isTrue,
          reason: sectionTitlePath);
      expect(File(docTilePath).existsSync(), isTrue, reason: docTilePath);
      expect(File(consentTilePath).existsSync(), isTrue,
          reason: consentTilePath);
      expect(File(withdrawOptionPath).existsSync(), isTrue,
          reason: withdrawOptionPath);
      expect(File(withdrawChoicePath).existsSync(), isTrue,
          reason: withdrawChoicePath);
    });

    test('主壳 < 400L (R122 拆后 344L, god-class size guard)', () {
      final lines = File(mainPath).readAsLinesSync().length;
      expect(
        lines,
        lessThan(400),
        reason:
            'legal_page.dart 主壳应保持精简 (R122 P2-2 拆 4 widget 后 344L), '
            '回归到 400+L 表示 widget 逻辑被回填',
      );
    });

    test('主壳不再含 4 private widget class', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains('class _SectionTitle')),
        reason: '主壳不应再有 _SectionTitle (迁到 LegalSectionTitle)',
      );
      expect(
        main,
        isNot(contains('class _DocTile')),
        reason: '主壳不应再有 _DocTile (迁到 LegalDocTile)',
      );
      expect(
        main,
        isNot(contains('class _ConsentTile')),
        reason: '主壳不应再有 _ConsentTile (迁到 LegalConsentTile)',
      );
      expect(
        main,
        isNot(contains('class _WithdrawOption')),
        reason: '主壳不应再有 _WithdrawOption (迁到 LegalWithdrawOption)',
      );
    });

    test('主壳不再含 _VentWithdrawChoice private enum', () {
      final main = File(mainPath).readAsStringSync();
      expect(
        main,
        isNot(contains('enum _VentWithdrawChoice')),
        reason: '主壳不应再有 _VentWithdrawChoice (迁到 LegalWithdrawChoice)',
      );
    });

    test('5 公开 widget/enum 各自提供 super.key (跟 project widget 集中器模式一致)',
        () {
      // 4 widget 全部 super.key
      expect(
        File(sectionTitlePath).readAsStringSync().contains('super.key'),
        isTrue,
        reason: 'LegalSectionTitle 应提供 super.key',
      );
      expect(
        File(docTilePath).readAsStringSync().contains('super.key'),
        isTrue,
        reason: 'LegalDocTile 应提供 super.key',
      );
      expect(
        File(consentTilePath).readAsStringSync().contains('super.key'),
        isTrue,
        reason: 'LegalConsentTile 应提供 super.key',
      );
      expect(
        File(withdrawOptionPath).readAsStringSync().contains('super.key'),
        isTrue,
        reason: 'LegalWithdrawOption 应提供 super.key',
      );
    });

    test('公开 widget 命名一致 (Legal* 前缀跟 project widget 集中器模式对齐)', () {
      final sectionTitle = File(sectionTitlePath).readAsStringSync();
      final docTile = File(docTilePath).readAsStringSync();
      final consentTile = File(consentTilePath).readAsStringSync();
      final withdrawOption =
          File(withdrawOptionPath).readAsStringSync();
      final withdrawChoice = File(withdrawChoicePath).readAsStringSync();

      expect(sectionTitle.contains('class LegalSectionTitle'), isTrue,
          reason: '应有公开 class LegalSectionTitle');
      expect(docTile.contains('class LegalDocTile'), isTrue,
          reason: '应有公开 class LegalDocTile');
      expect(consentTile.contains('class LegalConsentTile'), isTrue,
          reason: '应有公开 class LegalConsentTile');
      expect(withdrawOption.contains('class LegalWithdrawOption'), isTrue,
          reason: '应有公开 class LegalWithdrawOption');
      expect(withdrawChoice.contains('enum LegalWithdrawChoice'), isTrue,
          reason: '应有公开 enum LegalWithdrawChoice');
    });

    test('主壳用公开 widget 名替换 (不直接用 _SectionTitle / _DocTile 等)', () {
      final main = File(mainPath).readAsStringSync();
      // 公开 widget 在主壳的引用
      expect(main.contains('LegalSectionTitle('), isTrue,
          reason: '主壳应使用公开 LegalSectionTitle');
      expect(main.contains('LegalDocTile('), isTrue,
          reason: '主壳应使用公开 LegalDocTile');
      expect(main.contains('LegalConsentTile('), isTrue,
          reason: '主壳应使用公开 LegalConsentTile');
      expect(main.contains('LegalWithdrawOption('), isTrue,
          reason: '主壳应使用公开 LegalWithdrawOption');
      // 公开 enum 在主壳的引用 (替代 _VentWithdrawChoice)
      expect(main.contains('LegalWithdrawChoice.delete'), isTrue,
          reason: '主壳应使用公开 LegalWithdrawChoice.delete');
      expect(main.contains('LegalWithdrawChoice.sealed'), isTrue,
          reason: '主壳应使用公开 LegalWithdrawChoice.sealed');
    });

    test('6 文件总和 < 700L (拆前 555L, +overhead 限 < 26%)', () {
      // 验证: 拆 facade 不应让总行数爆涨
      // baseline: 拆前 555L; step 预期 ~590L (5 widget + 1 enum + 主壳 + overhead)
      final main = File(mainPath).readAsLinesSync().length;
      final sectionTitle = File(sectionTitlePath).readAsLinesSync().length;
      final docTile = File(docTilePath).readAsLinesSync().length;
      final consentTile = File(consentTilePath).readAsLinesSync().length;
      final withdrawOption =
          File(withdrawOptionPath).readAsLinesSync().length;
      final withdrawChoice =
          File(withdrawChoicePath).readAsLinesSync().length;
      final total =
          main + sectionTitle + docTile + consentTile + withdrawOption + withdrawChoice;
      expect(
        total,
        lessThan(700),
        reason:
            '拆 4 widget + 1 enum 后 6 文件总和应保持 < 700L (拆前 555L, +overhead 限 < 26%), '
            '回归到 700+L 表示有 widget 业务回填',
      );
      // 打印拆分比例
      // ignore: avoid_print
      print(
        '拆 4 widget + 1 enum L 数: '
        'main=$main sectionTitle=$sectionTitle docTile=$docTile '
        'consentTile=$consentTile withdrawOption=$withdrawOption '
        'withdrawChoice=$withdrawChoice total=$total',
      );
    });
  });
}
