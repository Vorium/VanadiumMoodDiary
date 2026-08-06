// v0.30 round 95 (sub-spec 1 task 3): 抽 cbt_pdf_tile
//
// R88 (sub-spec 4) 新增 CBT 思维记录 PDF 导出入口 — 走 date range picker +
// cbtReratedEntriesProvider + CbtThoughtRecordPdf.build + Printing.layoutPdf
//
// 业务逻辑从主壳 (40-60 行) 抽到本 sub-tile:
// - showDateRangePicker 选区间 (默认本月)
// - ref.read(cbtReratedEntriesProvider) 拿已过滤 cbtLevel >= 5 的 entries
// - 按 dateRange 在 handler 内过滤 (闭区间)
// - CbtThoughtRecordPdf().build(entries, dateRange, l10n) 生成 PDF
// - Printing.layoutPdf 弹系统打印/分享面板
// - SnackBar 成功/失败
//
// R19B DateTime race fix: 入口 `final now = DateTime.now();` 一次, 复用 4 处
// (now.year - 5 / +1 / now.month / +1), 防止跨 midnight 后不一致
//
// props callback 模式 (R93 task 1 模式):
// - 主壳持 ref + context
// - sub-tile 接受 onExport 回调 (默认调内部 _exportCbtPdf; 测试可注入自定义回调)
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import 'package:chroniccare/core/data/services/cbt_thought_record_pdf.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// CBT 思维记录 PDF 导出 tile (R88 新增)
///
/// v0.30 round 95: ConsumerWidget, 内部 _exportCbtPdf 走完整 PDF 导出流程
///
/// [onExport] 回调 — 留给测试可注入自定义 handler 跳过完整流
/// 默认 = 内部 _exportCbtPdf 完整流程 (date range picker + PDF 生成)
class CbtPdfTile extends ConsumerWidget {
  const CbtPdfTile({super.key, this.onExport, this.pdfBuilder});

  /// 可选 callback; null 时走内部 _exportCbtPdf 完整流程
  final Future<void> Function()? onExport;

  /// 可选 PDF 工厂 — 留给测试注入抛异常的 fake (test 5)
  /// 默认 = `() => CbtThoughtRecordPdf()` (生产 facade)
  final CbtThoughtRecordPdf Function()? pdfBuilder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppListTile(
      leading: Icon(
        Icons.picture_as_pdf_outlined,
        color: AppTokens.primaryColor(context),
      ),
      title: Text(AppLocalizations.of(context).cbtExportPdfButton),
      subtitle: Text(
        AppLocalizations.of(context).cbtExportPdfDialogTitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (onExport != null) {
          onExport!();
        } else {
          _exportCbtPdf(context, ref);
        }
      },
    );
  }

  /// v0.30 round 95 (sub-spec 1 task 3): 完整 CBT PDF 导出流程
  ///
  /// 流程:
  /// 1. showDateRangePicker 选区间 (默认本月, 跟 mood_list_filter_bar 同 mode)
  /// 2. ref.read(cbtReratedEntriesProvider) 拿已过滤 cbtLevel >= 5 的 entries
  /// 3. 按 dateRange 在 handler 内过滤 (闭区间), 跟 facade 内部 filter 同语义
  /// 4. CbtThoughtRecordPdf().build(entries: filtered, dateRange, l10n) 生成 PDF
  /// 5. Printing.layoutPdf 弹系统打印/分享面板 (跟 MedicationReportPdf 同模式)
  /// 6. SnackBar 成功/失败
  ///
  /// R19B DateTime race fix: `final now = DateTime.now();` 入口一次, 复用 4 处
  /// (now.year - 5 / +1 / now.month / +1)。原本在 showDateRangePicker 之前
  /// 多次 DateTime(...) 构造没问题 (都是用同一个 now), 但 R19B 文档要求入口一次
  /// 显式固化, 防止后续维护误改成 DateTime.now() 多次调用。
  Future<void> _exportCbtPdf(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
    );
    if (picked == null) return;
    if (!context.mounted) return;

    // cbtReratedEntriesProvider 已过滤 cbtLevel >= 5 (5/7 栏) — 见
    // cbt_rerated_entries_provider.dart。在 handler 内再按 dateRange 过滤一次,
    // 跟 facade 内部 filter 同语义, 但 SnackBar 数字 = 实际 PDF 页数。
    final all = ref.read(cbtReratedEntriesProvider);
    final filtered = all
        .where(
          (e) =>
              !e.timestamp.isBefore(picked.start) &&
              !e.timestamp.isAfter(picked.end),
        )
        .toList();
    final pdfFacade = pdfBuilder?.call() ?? CbtThoughtRecordPdf();
    try {
      final pdfBytes = await pdfFacade.build(
        entries: filtered,
        dateRange: picked,
        l10n: l10n,
      );
      if (!context.mounted) return;
      // Printing.layoutPdf 要求 LayoutCallback 返回 FutureOr<Uint8List> (见
      // printing/callback.dart typedef), 而 CbtThoughtRecordPdf.build 返回
      // List<int>。包一层 Uint8List.fromList 转换, 跟 MedicationReportPdf
      // 现有 onLayout 模式一致 (bytes 已经是 Uint8List, 这里从 List<int> 显式转)。
      final pdfUint8 = Uint8List.fromList(pdfBytes);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfUint8,
        name: 'cbt_thought_record.pdf',
      );
      if (!context.mounted) return;
      AppSnackBar.showInfo(
        context,
        l10n.cbtExportPdfSuccess(filtered.length),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showInfo(context, l10n.cbtExportPdfFailed);
      }
    }
  }
}
