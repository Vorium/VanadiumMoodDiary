// v0.30 round 95 (sub-spec 1 task 1): cbt_pdf_tile 骨架
//
// R88 (sub-spec 4) 新增 CBT 思维记录 PDF 导出入口 — 走 date range picker +
// cbtReratedEntriesProvider + CbtThoughtRecordPdf.build + Printing.layoutPdf
//
// 步骤 1 骨架: 只渲染 AppListTile, 业务逻辑 (40-60 行) 仍在主壳
// 步骤 3 抽 _exportCbtPdf → 这里, 同时修 R19B DateTime.now() race
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// CBT 思维记录 PDF 导出 tile (R88 新增)
///
/// 接受 onExport 回调 — 主壳持有 ref + context
class CbtPdfTile extends StatelessWidget {
  const CbtPdfTile({super.key, required this.onExport});

  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
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
      onTap: onExport,
    );
  }
}
