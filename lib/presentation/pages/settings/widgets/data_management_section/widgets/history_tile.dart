// v0.30 round 95 (sub-spec 1 task 4b): 抽 history_tile
//
// 报告历史入口 tile — 走 ReportHistoryListDialog
//
// 业务逻辑从主壳 (~7 行) 抽到本 sub-tile:
// - showDialog(ReportHistoryListDialog) 让用户查看历史报告 (含删除/查看 PDF 按钮)
//
// ConsumerWidget 模式 (R95 sub-spec 1 步骤 2-4a 一致):
// - ConsumerWidget 自包含 _showReportHistory 完整流程
// - 接受 onShow 回调 (默认调内部 _showReportHistory; 测试可注入自定义 handler 跳过完整流)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/report_history_dialog.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 报告历史 tile (ReportHistoryListDialog)
///
/// v0.30 round 95: ConsumerWidget, 内部 _showReportHistory 走完整 history 流程
///
/// [onShow] 回调 — 留给测试可注入自定义 handler 跳过完整流。
/// 默认 = 内部 _showReportHistory 完整流程 (ReportHistoryListDialog)
class HistoryTile extends ConsumerWidget {
  const HistoryTile({super.key, this.onShow});

  /// 可选 callback; null 时走内部 _showReportHistory 完整流程
  final Future<void> Function()? onShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppListTile(
      leading:
          Icon(Icons.history, color: AppTokens.primaryColor(context)),
      title: Text(AppLocalizations.of(context).settingsReportHistory),
      subtitle: Text(
        AppLocalizations.of(context).settingsReportHistorySubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        if (onShow != null) {
          onShow!();
        } else {
          _showReportHistory(context);
        }
      },
    );
  }

  /// v0.30 round 95 (sub-spec 1 task 4b): 弹 ReportHistoryListDialog
  ///
  /// ReportHistoryListDialog 是 ConsumerWidget 自身, 内部 watch reportHistoriesProvider
  /// 加载历史列表 + 列表项打开 MedicationReportDialog 看历史报告
  Future<void> _showReportHistory(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => const ReportHistoryListDialog(),
    );
  }
}
