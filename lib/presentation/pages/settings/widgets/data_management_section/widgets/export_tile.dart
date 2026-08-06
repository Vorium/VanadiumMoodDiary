// v0.30 round 95 (sub-spec 1 task 1): export_tile 骨架
//
// 数据导出入口 tile — 走 ConsentDialog + audit log + JSON 弹窗 + PIPL §17 告知
// 复用 R75 引入的 AppListTile 公共组件
//
// 步骤 1 骨架: 只渲染 AppListTile, 业务逻辑 (200+ 行) 仍在主壳
// 步骤 2a 抽 _exportData → 这里, 走 callback 模式 (主壳持 ref + context, sub-tile 接受 callback)
import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';

/// 导出全部数据 tile (PIPL §13 + §17 + §28 风险告知)
///
/// 接受 onExport 回调 — 主壳持有 ref + context, 在 build 闭包内调用 _exportData
class ExportTile extends StatelessWidget {
  const ExportTile({super.key, required this.onExport});

  final VoidCallback onExport;

  @override
  Widget build(BuildContext context) {
    return AppListTile(
      leading: Icon(
        Icons.upload_outlined,
        color: AppTokens.primaryColor(context),
      ),
      title: Text(AppLocalizations.of(context).settingsExportData),
      subtitle: Text(
        AppLocalizations.of(context).settingsExportSubtitle,
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: onExport,
    );
  }
}

// 步骤 1 暂不抽 _exportData, 留步骤 2a 抽走
// 步骤 2a 改为: class ExportTile extends ConsumerWidget, 持有 _exportData
// 主壳改 ExportTile(onExport: () => _exportData(context, ref)) → 直接传 onExport 不再接 _exportData
