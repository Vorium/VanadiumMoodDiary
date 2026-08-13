// v0.30 round 88: CBT 思维记录 PDF layout helpers
//
// **职责**: 把 cbt_thought_record_pdf.dart 里的排版片段 (entry page / empty
// page / header / section block) 抽成 pure helper class,让 facade 只负责
// `pw.Document` + `pw.Page` 编排,排版细节下沉到本 class。
//
// **设计要点**:
// - 1 页 1 entry,5/7 栏分别渲染 (走 cbtLevel 区分 5 vs 7 档位)
// - 复用 R84 i18n keys: `moodCbtSection*` + `moodCbtScoreReratedLabel`
// - 新加 1 个 key `cbtExportPdfEmpty` (R88 新加,空态页文案)
// - evidenceFor/Against 合并 1 段 (节省垂直空间,医生阅读体验)
// - rerated / original score 同行显示,直观对比
// - 7 栏专属 (coreBelief / behaviorResponse) 走 conditional section,5 栏不显示
//
// **字体策略**: 跟 MedicationReportPdf 一致,走 pdf 内置 Helvetica,无需字体文件。
//
// **v0.32 R112 (AR-16)**: l10n 改 [CbtPdfL10n] interface (caller 注入实现,
// data 0 依赖 l10n/ 生成 ARB)。presentation 适配器
// `AppLocalizationsCbtPdfL10n` 在 `lib/presentation/services/cbt_pdf_l10n.dart`。

import 'package:pdf/widgets.dart' as pw;

import 'package:chroniccare/domain/entities/mood_entry_entity.dart';

/// CBT PDF 文案接口 — caller (presentation) 注入实现, data 0 依赖 ARB
///
/// 10 个 getter 跟 ARB moodCbt* / cbtExportPdfEmpty key 1:1。
abstract interface class CbtPdfL10n {
  String get moodCbtSectionSituation;
  String get moodCbtSectionAutomaticThought;
  String get moodCbtSectionEvidenceFor;
  String get moodCbtSectionEvidenceAgainst;
  String get moodCbtSectionAlternative;
  String get moodCbtSectionRerated;
  String get moodCbtScoreReratedLabel;
  String get moodCbtSectionCoreBelief;
  String get moodCbtSectionBehavior;
  String get cbtExportPdfEmpty;
}

/// v0.30 round 88: CBT 思维记录 PDF 排版纯函数集合
///
/// 所有方法都是 static + pure (除引用 [CbtPdfL10n] 外无副作用),
/// 便于在 unit test 里独立验证。
class CbtLayout {
  CbtLayout._();

  /// 单条 entry 页 — 5/7 栏分别渲染
  ///
  /// 排版顺序: header (档位 + 时间 + 原始情绪分) → 5 栏字段 (situation /
  /// automaticThought / evidence 合并 / alternative / rerated) → 7 栏扩展
  /// (coreBelief / behaviorResponse, 7 档才显示)
  static pw.Widget entryPage(MoodEntryEntity e, CbtPdfL10n l10n) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(24),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _header(e),
          pw.SizedBox(height: 16),
          _section(l10n.moodCbtSectionSituation, e.situation),
          _section(l10n.moodCbtSectionAutomaticThought, e.automaticThought),
          _section(
            '${l10n.moodCbtSectionEvidenceFor} / ${l10n.moodCbtSectionEvidenceAgainst}',
            '${e.evidenceFor ?? '-'}\n${e.evidenceAgainst ?? '-'}',
          ),
          _section(l10n.moodCbtSectionAlternative, e.alternativeThought),
          _section(
            '${l10n.moodCbtSectionRerated} (${l10n.moodCbtScoreReratedLabel})',
            '${e.reratedScore ?? '-'} (原 ${e.score})',
          ),
          if (e.coreBelief != null)
            _section(l10n.moodCbtSectionCoreBelief, e.coreBelief),
          if (e.behaviorResponse != null)
            _section(l10n.moodCbtSectionBehavior, e.behaviorResponse),
        ],
      ),
    );
  }

  /// 空态页 — 单页居中显示 "无数据" 提示
  static pw.Widget empty(CbtPdfL10n l10n) {
    return pw.Center(child: pw.Text(l10n.cbtExportPdfEmpty));
  }

  /// 页面 header — CBT 档位 (5/7) + 时间戳 + 原始情绪分
  static pw.Widget _header(MoodEntryEntity e) {
    final ts =
        '${e.timestamp.year}-${e.timestamp.month.toString().padLeft(2, '0')}-${e.timestamp.day.toString().padLeft(2, '0')} '
        '${e.timestamp.hour.toString().padLeft(2, '0')}:${e.timestamp.minute.toString().padLeft(2, '0')}';
    return pw.Text(
      '${e.cbtLevel == 7 ? "CBT 7 栏" : "CBT 5 栏"}  $ts  情绪 ${e.score}/5',
      style: const pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
    );
  }

  /// 单个 section 块 — 标题加粗 + 4 间距 + 正文
  ///
  /// body 为 null 或空字符串 → 返回 SizedBox.shrink (不占空间)
  static pw.Widget _section(String title, String? body) {
    if (body == null || body.isEmpty) return pw.SizedBox.shrink();
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: const pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12),
          ),
          pw.SizedBox(height: 4),
          pw.Text(body, style: const pw.TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
