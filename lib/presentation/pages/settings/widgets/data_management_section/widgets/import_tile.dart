// v0.30 round 95 (sub-spec 1 task 1): import_tile 骨架
//
// 数据导入入口 tile — 走 JSON 导入 + 风险告知 + 用户确认
//
// 步骤 1 骨架: 只渲染 AppListTile, 业务逻辑仍在主壳
// 步骤 5 抽 _showImportDialog → 这里
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 数据导入 tile (JSON 导入 + 风险告知)
class ImportTile extends StatelessWidget {
  const ImportTile({super.key, required this.onImport});

  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: Icon(
        Icons.download_outlined,
        color: AppTokens.primaryColor(context),
      ),
      title: Text(AppLocalizations.of(context).settingsImportData),
      subtitle: Text(
        AppLocalizations.of(context).settingsImportSubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onImport,
    );
  }
}
