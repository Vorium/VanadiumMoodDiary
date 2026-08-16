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
import 'package:chroniccare/core/data/services/cbt_thought_record_pdf_layout.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations_en.dart';
import 'package:chroniccare/l10n/app_localizations_zh.dart';
import 'package:chroniccare/presentation/services/cbt_pdf_l10n.dart';

MoodEntryEntity _cbtEntry({int cbtLevel = 7, int score = 4, int? rerated = 3}) {
  return MoodEntryEntity(
    id: 1,
    timestamp: DateTime(2026, 8, 4, 14, 30),
    score: score,
    situation: 's',
    automaticThought: 'at',
    evidenceFor: 'ef',
    evidenceAgainst: 'ea',
    alternativeThought: 'alt',
    reratedScore: rerated,
    // cbtLevel 是派生 getter: 7 = coreBelief 非空, 5 = 仅 5/7 栏共享字段
    coreBelief: cbtLevel == 7 ? 'cb' : null,
  );
}

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

  // ===== v1.1.0 R113 (BUG A): PDF 头硬编码中文本地化回归 =====

  test('header zh: CBT 7 栏 + 情绪', () {
    final zh = AppLocalizationsCbtPdfL10n(AppLocalizationsZh());
    final header = CbtLayout.header(_cbtEntry(cbtLevel: 7), zh);
    expect(header, contains('CBT 7 栏'));
    expect(header, contains('情绪'));
    expect(header, contains('2026-08-04 14:30'));
    expect(header, contains('4/5'));
  });

  test('header en: 0 CJK — en 用户 PDF 头不得混中文', () {
    final en = AppLocalizationsCbtPdfL10n(AppLocalizationsEn());
    final header = CbtLayout.header(_cbtEntry(cbtLevel: 5), en);
    expect(header, contains('CBT 5-column'));
    expect(header, contains('Mood'));
    expect(header, contains('4/5'));
    expect(
      RegExp(r'[\u4e00-\u9fff]').hasMatch(header),
      isFalse,
      reason: '修前 header 硬编码 "CBT 7 栏"/"情绪" — en 用户 PDF 头混中文',
    );
  });

  test('reratedBody en: 0 CJK (修前 "(原 4)" 混中文)', () {
    final en = AppLocalizationsCbtPdfL10n(AppLocalizationsEn());
    final body = CbtLayout.reratedBody(_cbtEntry(score: 4, rerated: 3), en);
    expect(body, '3 (original 4)');
    expect(RegExp(r'[\u4e00-\u9fff]').hasMatch(body), isFalse);
  });

  test('reratedBody zh: (原 4) 语义保留', () {
    final zh = AppLocalizationsCbtPdfL10n(AppLocalizationsZh());
    expect(
        CbtLayout.reratedBody(_cbtEntry(score: 4, rerated: 3), zh), '3 (原 4)');
  });

  test('rerated null → - (原 4) 不崩', () {
    final zh = AppLocalizationsCbtPdfL10n(AppLocalizationsZh());
    expect(
      CbtLayout.reratedBody(_cbtEntry(score: 4, rerated: null), zh),
      '- (原 4)',
    );
  });
}
