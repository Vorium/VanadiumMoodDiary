// 用药报告 PDF 排版 helper — v0.26 round 57 (spen P1 #3 god class 拆分续)
//
// **职责**: 把 medication_report_pdf.dart 里的排版片段 (header / footer /
// section title / 表格 / kv pair) 抽成 pure helper class, 让 facade 只负责
// `pw.Document` + `pw.MultiPage` 编排, 排版细节下沉到本 class。
//
// **拆分前**: medication_report_pdf.dart 304 行 facade 含:
// - 1 个 `build` 编排方法
// - 7 个排版 helper (`_header` / `_footer` / `_patientInfoBlock` / `_kv` /
//   `_sectionTitle` / `_emptyLine` / `_medicationBlocks` / `_tempMedTable` /
//   `_summaryBlock`)
// - 内嵌 Strings 调用 + Formatters 调用 + AppTokens 引用
//
// **拆分后**:
// - `MedicationReportPdf` (facade, ~80 行): `build` 编排 + 1 行委托
// - `PdfLayout` (本文件, ~210 行): 8 个 pure widget 构造器
// - 0 业务逻辑改动, 公开 API 100% 兼容 (build 签名不变)
//
// **架构延续**: 跟 R57 safety_watch / R58 medication_report 拆 3 纯函数类
// / R59 app_router 拆 2 文件 / R60 medication_repository 抽 value object /
// R57 抽 ExportOrchestrator 同款"渐进 facade 模式"。

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';

/// v0.26 round 57: PDF 排版纯函数集合
///
/// 所有方法都是 static + pure (除引用 Strings / Formatters / AppTokens 外无副作用),
/// 便于在 widget test 里独立验证 (虽然 PDF widget test 复杂度高, 但至少能
/// 在 unit test 调一下, 验证不抛)。
class PdfLayout {
  PdfLayout._();

  // ===== 页面 header / footer =====

  /// 页面 header — 标题 + 时间窗口
  static pw.Widget header(MedicationReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            Strings.pdfTitle,
            style: const pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            Strings.pdfRecentDays(data.windowDays),
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  /// 页面 footer — 免责 + 页码
  static pw.Widget footer(pw.Context ctx) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.5),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            Strings.pdfFooterNotice,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            Strings.pdfPageN(ctx.pageNumber, ctx.pagesCount),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ===== 患者信息块 =====

  /// 患者信息块 — 姓名 (maskName) + 报告周期 + 生成时间
  static pw.Widget patientInfoBlock(MedicationReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // v0.23 round 39 (P1-7 fix): userName 走 maskName
          // 之前直接显示真实姓名,医生收到的 PDF 是患者敏感信息
          // 改成"张**"形式,既保留 PII 又有可读性
          kv(
            Strings.pdfLabelPatient,
            data.userName.isEmpty ? Strings.pdfUnset : maskName(data.userName),
          ),
          kv(
            Strings.pdfLabelReportPeriod,
            Strings.pdfReportPeriodValue(
              Formatters.date(data.periodStart),
              Formatters.date(data.periodEnd),
              data.windowDays,
            ),
          ),
          kv(
            Strings.pdfLabelGeneratedAt,
            Formatters.dateTime(data.generatedAt),
          ),
        ],
      ),
    );
  }

  /// 键值对 (label: value) 行
  static pw.Widget kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.SizedBox(
            width: 70,
            child: pw.Text(
              k,
              style: const pw.TextStyle(
                fontSize: 11,
                color: PdfColors.grey700,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(v, style: const pw.TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  // ===== section title / empty line =====

  /// 段落标题 (绿色背景 + 圆角)
  static pw.Widget sectionTitle(String s) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(AppTokens.radiusCellLg),
      ),
      child: pw.Text(
        s,
        style: const pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
    );
  }

  /// 空值占位 (灰文字)
  static pw.Widget emptyLine(String s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(s, style: const pw.TextStyle(color: PdfColors.grey600)),
    );
  }

  // ===== 长期用药块 =====

  /// 长期用药列表 — 每药一个圆角卡片
  static List<pw.Widget> medicationBlocks(MedicationReportData data) {
    final widgets = <pw.Widget>[];
    for (int i = 0; i < data.medicationStats.length; i++) {
      final s = data.medicationStats[i];
      final m = s.medication;
      final timesStr = s.times.isEmpty
          ? Strings.pdfUnsetTime
          : s.times
              .map(
                (t) =>
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
              )
              .join(' / ');
      final freqStr = s.times.isEmpty
          ? Strings.pdfUnset
          : Strings.pdfDailyNTimes(s.times.length, timesStr);

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(AppTokens.radiusCellLg),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${i + 1}. ${m.name} ${Formatters.dosage(m.dosage, m.dosageUnit)} · $freqStr',
                style: const pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              kv(Strings.pdfLabelStart, Formatters.date(m.startDate)),
              kv(
                Strings.pdfLabelMedicationStats,
                Strings.pdfMedicationStatsValue(
                  s.actualDoseDays,
                  data.windowDays,
                  s.actualDoseCount,
                  s.expectedDoseCount,
                ),
              ),
              if (s.missedDates.isNotEmpty)
                kv(
                  Strings.pdfLabelMissed,
                  s.missedDates.map(Formatters.monthDay).join('、'),
                )
              else
                kv(Strings.pdfLabelMissed, Strings.pdfNoMissed),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  // ===== 临时用药表 =====

  /// 临时用药表 — 4 列 (日期 / 时间 / 药名 / 备注)
  static pw.Widget tempMedTable(MedicationReportData data) {
    return pw.TableHelper.fromTextArray(
      headerStyle: const pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.white,
      ),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.green700),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: const {
        0: pw.FlexColumnWidth(2),
        1: pw.FlexColumnWidth(1.2),
        2: pw.FlexColumnWidth(2),
        3: pw.FlexColumnWidth(2),
      },
      headers: const [
        Strings.pdfColumnDate,
        Strings.pdfColumnTime,
        Strings.pdfColumnMed,
        Strings.pdfColumnNote,
      ],
      data: [
        for (final t in data.tempMedications)
          [
            Formatters.monthDay(t.timestamp),
            Formatters.time(t.timestamp),
            t.name,
            t.description,
          ],
      ],
    );
  }

  // ===== 总结块 =====

  /// 总结块 — 按时 / 漏 / 额外 / 临时 / 依从率
  ///
  /// B6 fix: 期望为 0 时显示 "—" 而不是 0%
  static pw.Widget summaryBlock(MedicationReportData data) {
    final adh = data.adherencePct;
    final lines = <String>[
      Strings.pdfOnTime(data.onTimeDoses),
      Strings.pdfMissed(data.missedDoses),
      if (data.extraDoses > 0) Strings.pdfExtra(data.extraDoses),
      Strings.pdfTempN(data.tempMedications.length),
      Strings.pdfAdherencePct(adh),
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(AppTokens.radiusCellLg),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          for (final line in lines)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Text(line, style: const pw.TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}
