// v0.30 round 95 (sub-spec 1 task 1): clear_tile 骨架
//
// 清空全部数据入口 tile — 走清空数据 dialog + 二次确认
//
// 步骤 1 骨架: 只渲染 AppListTile, 业务逻辑仍在主壳
// 步骤 6 抽 _showClearAllDataDialog → 这里
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 清空数据 tile (二次确认 dialog + 走 database.clearAllUserData)
class ClearTile extends StatelessWidget {
  const ClearTile({super.key, required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: Icon(
        Icons.delete_forever_outlined,
        color: AppTokens.errorColor(context),
      ),
      title: Text(
        AppLocalizations.of(context).settingsClearAllData,
        style: AppTokens.textStyleBody(context)
            .copyWith(color: AppTokens.errorColor(context)),
      ),
      subtitle: Text(
        AppLocalizations.of(context).settingsClearAllDataSubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onClear,
    );
  }
}
