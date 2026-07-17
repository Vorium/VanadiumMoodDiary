import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';

/// 用药报告 PDF 生成器
///
/// 输入：[MedicationReportData]（compute 结果）
/// 输出：Uint8List（PDF 二进制）
///
/// 设计原则：
/// - 中文用内置 Helvetica 即可（无需字体文件，体积小；缺点是不支持复杂汉字
///   但常用简体没问题，且不增加 app 体积）
/// - 排版按医生阅读习惯：患者信息块 → 常吃药 → 临时用药 → 总览
/// - 用 MultiPage 自动分页
class MedicationReportPdf {
  MedicationReportPdf._();

  /// 构建 PDF
  static Future<Uint8List> build(MedicationReportData data) async {
    final doc = pw.Document(
      title: '慢病管家 · 用药报告',
      author: '慢病管家',
      subject: '${data.windowDays} 天用药情况',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (ctx) => _header(data),
        footer: (ctx) => _footer(ctx),
        build: (ctx) => [
          _patientInfoBlock(data),
          pw.SizedBox(height: 16),
          _sectionTitle('常吃药方案'),
          if (data.medicationStats.isEmpty)
            _emptyLine('（无）')
          else
            ..._medicationBlocks(data),
          pw.SizedBox(height: 16),
          _sectionTitle('临时用药'),
          if (data.tempMedications.isEmpty)
            _emptyLine('（无）')
          else
            _tempMedTable(data),
          pw.SizedBox(height: 16),
          _sectionTitle('总览'),
          _summaryBlock(data),
        ],
      ),
    );

    return doc.save();
  }

  // ===== 组件 =====

  static pw.Widget _header(MedicationReportData data) {
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
            '慢病管家 · 用药报告',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '近 ${data.windowDays} 天',
            style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
          ),
        ],
      ),
    );
  }

  static pw.Widget _footer(pw.Context ctx) {
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
            '本报告由「慢病管家」App 自动生成 · 本应用不提供医疗建议',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            '第 ${ctx.pageNumber} / ${ctx.pagesCount} 页',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  static pw.Widget _patientInfoBlock(MedicationReportData data) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _kv('患者', data.userName.isEmpty ? '未设置' : data.userName),
          _kv(
            '报告周期',
            '${Formatters.date(data.periodStart)} 至 ${Formatters.date(data.periodEnd)}'
                '（共 ${data.windowDays} 天）',
          ),
          _kv('生成时间', Formatters.dateTime(data.generatedAt)),
        ],
      ),
    );
  }

  static pw.Widget _kv(String k, String v) {
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

  static pw.Widget _sectionTitle(String s) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: pw.BoxDecoration(
        color: PdfColors.green50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        s,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.green800,
        ),
      ),
    );
  }

  static pw.Widget _emptyLine(String s) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      child: pw.Text(s, style: const pw.TextStyle(color: PdfColors.grey600)),
    );
  }

  static List<pw.Widget> _medicationBlocks(MedicationReportData data) {
    final widgets = <pw.Widget>[];
    for (int i = 0; i < data.medicationStats.length; i++) {
      final s = data.medicationStats[i];
      final m = s.medication;
      final timesStr = s.times.isEmpty
          ? '未设置时间'
          : s.times
              .map(
                (t) =>
                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}',
              )
              .join(' / ');
      final freqStr =
          s.times.isEmpty ? '未设置' : '每日 ${s.times.length} 次（$timesStr）';

      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
            borderRadius: pw.BorderRadius.circular(4),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '${i + 1}. ${m.name} ${Formatters.dosage(m.dosage, m.dosageUnit)} · $freqStr',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              _kv('起始', Formatters.date(m.startDate)),
              _kv(
                '服药统计',
                '${s.actualDoseDays}/${data.windowDays} 天 · ${s.actualDoseCount}/${s.expectedDoseCount} 次',
              ),
              if (s.missedDates.isNotEmpty)
                _kv('漏服', s.missedDates.map(Formatters.monthDay).join('、'))
              else
                _kv('漏服', '✓ 无'),
            ],
          ),
        ),
      );
    }
    return widgets;
  }

  static pw.Widget _tempMedTable(MedicationReportData data) {
    return pw.TableHelper.fromTextArray(
      headerStyle: pw.TextStyle(
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
      headers: const ['日期', '时间', '药名', '备注'],
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

  static pw.Widget _summaryBlock(MedicationReportData data) {
    // B6 fix: 期望为 0 时显示 "—" 而不是 0%
    final adh = data.adherencePct;
    final adhStr = adh == null ? '—（无可比较的常吃药）' : '$adh%';
    final lines = <String>[
      '按时服药: ${data.onTimeDoses} 次',
      '漏服: ${data.missedDoses} 次',
      if (data.extraDoses > 0) '补服: ${data.extraDoses} 次',
      '临时用药: ${data.tempMedications.length} 次',
      '依从率: $adhStr',
    ];
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
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
