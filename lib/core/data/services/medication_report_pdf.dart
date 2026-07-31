// 用药报告 PDF 生成器 facade — v0.26 round 57 (spen P1 #3 god class 拆分续)
//
// 输入：[MedicationReportData]（compute 结果）
// 输出：Uint8List（PDF 二进制）
//
// **拆分前**: 304 行 facade 含编排 + 8 个排版 helper 全在内。
// **拆分后**:
// - `MedicationReportPdf` (本文件, ~80 行): `build` 编排 + 委托
// - `PdfLayout` (medication_report_pdf_layout.dart, ~210 行): 8 个 pure widget 构造器
//
// **设计原则**:
// - 中文用内置 Helvetica 即可（无需字体文件，体积小；缺点是不支持复杂汉字
//   但常用简体没问题，且不增加 app 体积）
// - 排版按医生阅读习惯：患者信息块 → 常吃药 → 临时用药 → 总览
// - 用 MultiPage 自动分页
//
// **PDF 颜色说明**: 全文用 `PdfColors.*` (pdf package 自身), 不是 Material
// `Colors.*`, 不会被 dark mode 影响, 无需做"反白修复"。R56h 报告提到的
// "11 处 Colors.white/black" 在实际代码里并不存在 — v0.18 已统一走 PdfColors。

import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:chroniccare/core/data/services/medication_report_pdf_layout.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';

/// v0.26 round 57: 用药报告 PDF facade
class MedicationReportPdf {
  MedicationReportPdf._();

  /// 构建 PDF
  static Future<Uint8List> build(MedicationReportData data) async {
    final doc = pw.Document(
      title: Strings.pdfTitle,
      author: Strings.pdfAuthor,
      subject: Strings.pdfSubject(data.windowDays),
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => PdfLayout.header(data),
        footer: (ctx) => PdfLayout.footer(ctx),
        build: (ctx) => [
          PdfLayout.patientInfoBlock(data),
          pw.SizedBox(height: 16),
          PdfLayout.sectionTitle(Strings.pdfSectionRoutineMeds),
          if (data.medicationStats.isEmpty)
            PdfLayout.emptyLine(Strings.pdfNoValue)
          else
            ...PdfLayout.medicationBlocks(data),
          pw.SizedBox(height: 16),
          PdfLayout.sectionTitle(Strings.pdfSectionTempMeds),
          if (data.tempMedications.isEmpty)
            PdfLayout.emptyLine(Strings.pdfNoValue)
          else
            PdfLayout.tempMedTable(data),
          pw.SizedBox(height: 16),
          PdfLayout.sectionTitle(Strings.pdfSectionSummary),
          PdfLayout.summaryBlock(data),
        ],
      ),
    );

    return doc.save();
  }
}
