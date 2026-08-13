// v0.30 round 88: CbtThoughtRecordPdf facade + layout 测试
//
// 验证: 5/7 栏 mood entries 导出 PDF + 空 entries 走 empty page
//
// TDD: red → green
// 参考: medication_report_pdf_round57_test.dart (同 facade + layout 模式)
//
// v0.32 R112 (AR-16): l10n 改 CbtPdfL10n interface, test 走
// AppLocalizationsCbtPdfL10n 适配器 (presentation)。

import 'package:flutter_test/flutter_test.dart';
import 'package:chroniccare/core/data/services/cbt_thought_record_pdf.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/presentation/services/cbt_pdf_l10n.dart';

void main() {
  test('5 栏 entries build → Uint8List non-empty 且 PDF 魔术字正确', () async {
    final pdf = CbtThoughtRecordPdf();
    final entries = [
      MoodEntryEntity(
        id: 1,
        timestamp: DateTime(2026, 8, 4),
        score: 4,
        situation: 's',
        automaticThought: 'at',
        evidenceFor: 'ef',
        evidenceAgainst: 'ea',
        alternativeThought: 'alt',
        reratedScore: 3,
      ),
    ];
    final result = await pdf.build(
      entries: entries,
      l10n: AppLocalizationsCbtPdfL10n(AppLocalizationsZh()),
    );
    expect(result, isNotEmpty);
    // PDF 魔术字: %PDF-1.x
    expect(String.fromCharCodes(result.sublist(0, 4)), '%PDF');
  });

  test('空 entries build → 仍然返回 valid PDF (with "无数据" 页)', () async {
    final pdf = CbtThoughtRecordPdf();
    final result = await pdf.build(
      entries: const <MoodEntryEntity>[],
      l10n: AppLocalizationsCbtPdfL10n(AppLocalizationsZh()),
    );
    expect(result, isNotEmpty);
    expect(String.fromCharCodes(result.sublist(0, 4)), '%PDF');
  });
}
