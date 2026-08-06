// v0.30 round 95 (sub-spec 1 task 6): 抽 clear_tile
//
// 清空全部数据入口 tile — 走清空数据 dialog + 二次确认
//
// 业务逻辑从主壳 (~50 行) 抽到本 sub-tile:
// - AlertDialog 二次确认: title + body + 取消/清空按钮 (FilledButton error color)
// - ref.read(databaseProvider).clearAllUserData() 清 DB
// - ref.read(ventAudioStorageProvider).deleteAllWithRetry() 清录音
// - piiSafeLog 录音删除失败提示
// - 成功: AppSnackBar.showInfo + GoRouter.go('/setup') 重启
// - 失败: AppSnackBar.showError
//
// props callback 模式 (R95 sub-spec 1 步骤 2-5 一致):
// - ConsumerWidget 自包含 _showClearAllDataDialog 完整流程
// - 接受 onClear 回调 (默认调内部 _showClearAllDataDialog; 测试可注入自定义 handler)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 清空数据 tile (二次确认 dialog + 走 database.clearAllUserData + vent audio)
///
/// v0.30 round 95: ConsumerWidget, 内部 _showClearAllDataDialog 走完整 clear 流程
///
/// [onClear] 回调 — 留给测试可注入自定义 handler 跳过完整流。
/// 默认 = 内部 _showClearAllDataDialog 完整流程 (二次确认 + 清 DB + 跳 /setup)
class ClearTile extends ConsumerWidget {
  const ClearTile({super.key, this.onClear});

  /// 可选 callback; null 时走内部 _showClearAllDataDialog 完整流程
  final Future<void> Function()? onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      onTap: () {
        if (onClear != null) {
          onClear!();
        } else {
          _showClearAllDataDialog(context, ref);
        }
      },
    );
  }

  /// v0.30 round 95 (sub-spec 1 task 6): 完整 clear 流程
  ///
  /// 1. AlertDialog 二次确认 (title + body + 取消/清空 FilledButton error color)
  /// 2. db.clearAllUserData() 清 DB
  /// 3. ventAudio.deleteAllWithRetry() 清录音 (3 retries, 失败 piiSafeLog)
  /// 4. 成功: AppSnackBar.showInfo + GoRouter.go('/setup') 重启
  /// 5. 失败: AppSnackBar.showError
  Future<void> _showClearAllDataDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsClearAllDataDialogTitle),
        content: SingleChildScrollView(
          child: Text(l10n.settingsClearAllDataDialogBody),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          PrimaryButton(
            isFullWidth: false,
            style: FilledButton.styleFrom(
              backgroundColor: AppTokens.errorColor(context),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsClearAllDataConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final db = ref.read(databaseProvider);
    final ventAudio = ref.read(ventAudioStorageProvider);
    final navigator = GoRouter.of(context);

    try {
      await db.clearAllUserData();
      final audioDeleted = await ventAudio.deleteAllWithRetry();
      if (audioDeleted == 0 && await ventAudio.totalSizeBytes() > 0) {
        piiSafeLog('Settings', '⚠️ vent audio delete failed after 3 retries');
      }
      if (!context.mounted) return;
      AppSnackBar.showInfo(context, l10n.settingsClearAllDataSuccess);
      navigator.go('/setup');
    } on Exception catch (e) {
      if (!context.mounted) return;
      AppSnackBar.showError(
        context,
        action: l10n.settingsClearAllData,
        error: e,
      );
    }
  }
}
