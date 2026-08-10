// v0.30 round 88 (sub-spec 4): CBT 思维记录 PDF 生成器 facade
//
// 复用 MedicationReportPdf 模式 (facade + layout 拆分)
// - `CbtThoughtRecordPdf` (本文件, ~80 行): `build` 编排 + 委托
// - `CbtLayout` (cbt_thought_record_pdf_layout.dart, ~150 行): 2 个 pure widget
//   构造器 (entryPage / empty)
//
// **设计原则**:
// - 1 页 1 entry,5/7 栏分别渲染 (走 cbtLevel 区分 5 vs 7 档位)
// - i18n 走 caller 注入 AppLocalizations (避免 service 层读 BuildContext)
// - entries 必须过滤 cbtLevel >= 5 (调用方负责,例如 cbtReratedEntriesProvider)
// - dateRange 可选 filter,DateTimeRange.start/end 含闭区间
// - 字体走 pdf 内置 Helvetica (跟 MedicationReportPdf 一致,不引字体文件)
//
// R101: 用自定义 DateRange 替代 flutter/material DateTimeRange, 满足
// data 层 0 flutter 硬约束。

import 'package:pdf/widgets.dart' as pw;

import 'package:chroniccare/core/data/services/cbt_thought_record_pdf_layout.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// R101: 纯 Dart 日期范围, 替代 flutter/material DateTimeRange
class DateRange {
  final DateTime start;
  final DateTime end;
  const DateRange(this.start, this.end);
}

/// v0.30 round 88: CBT 思维记录 PDF facade
///
/// 导出 5/7 栏 mood entries 进 PDF,每条 entry 独立 1 页。
class CbtThoughtRecordPdf {
  CbtThoughtRecordPdf();

  /// 构建 PDF 二进制
  ///
  /// - [entries] 必须已过滤 cbtLevel >= 5 (调用方负责)
  /// - [dateRange] 可选,过滤 timestamp ∈ [start, end] (闭区间)
  /// - [l10n] i18n strings (caller 注入,避免 service 层读 context)
  ///
  /// 过滤后为空 → 走 empty page (单页 "无数据" 提示)
  Future<List<int>> build({
    required List<MoodEntryEntity> entries,
    DateRange? dateRange,
    required AppLocalizations l10n,
  }) async {
    final doc = pw.Document();
    final filtered = dateRange == null
        ? entries
        : entries
            .where(
              (e) =>
                  !e.timestamp.isBefore(dateRange.start) &&
                  !e.timestamp.isAfter(dateRange.end),
            )
            .toList();

    if (filtered.isEmpty) {
      doc.addPage(pw.Page(build: (_) => CbtLayout.empty(l10n)));
    } else {
      for (final entry in filtered) {
        doc.addPage(pw.Page(build: (_) => CbtLayout.entryPage(entry, l10n)));
      }
    }
    return doc.save();
  }
}
