// v0.30 round 95 (sub-spec 1 task 1): report_tile 骨架
//
// 用药报告入口 tile — 走 ChooseWindowDialog + medication report + swallowError 写 history
//
// 步骤 1 骨架: 只渲染 AppListTile, 业务逻辑仍在主壳
// 步骤 4a 抽 _chooseAndShowReport + _showMedicationReport → 这里
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 用药报告 tile (ChooseWindowDialog → MedicationReport)
class ReportTile extends StatelessWidget {
  const ReportTile({super.key, required this.onShow});

  final VoidCallback onShow;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: Icon(
        Icons.summarize_outlined,
        color: AppTokens.primaryColor(context),
      ),
      title: Text(AppLocalizations.of(context).settingsMedReport),
      subtitle: Text(
        AppLocalizations.of(context).settingsMedReportSubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onShow,
    );
  }
}
