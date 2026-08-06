// v0.30 round 95 (sub-spec 1 task 1): history_tile 骨架
//
// 报告历史入口 tile — 走 ReportHistoryListDialog
//
// 步骤 1 骨架: 只渲染 AppListTile, 业务逻辑仍在主壳
// 步骤 4b 抽 _showReportHistory → 这里
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 报告历史 tile (ReportHistoryListDialog)
class HistoryTile extends StatelessWidget {
  const HistoryTile({super.key, required this.onShow});

  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading:
          Icon(Icons.history, color: AppTokens.primaryColor(context)),
      title: Text(AppLocalizations.of(context).settingsReportHistory),
      subtitle: Text(
        AppLocalizations.of(context).settingsReportHistorySubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onShow,
    );
  }
}
