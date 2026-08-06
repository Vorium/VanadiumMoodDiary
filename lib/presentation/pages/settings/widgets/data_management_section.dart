import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/report_history_dialog.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/cbt_pdf_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/clear_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/export_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/history_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/import_tile.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/data_management_section/widgets/report_tile.dart';

/// 数据管理 section — 导出/报告/历史/导入/清空
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
/// v0.30 round 95 (sub-spec 1 task 1): 拆 6 sub-tile 入口, 主壳改 props callback 模式
/// v0.30 round 95 (sub-spec 1 task 2a): 抽 ExportTile (200+ 行 → sub-tile, 走 ConsumerWidget)
/// v0.30 round 95 (sub-spec 1 task 3): 抽 CbtPdfTile
/// v0.30 round 95 (sub-spec 1 task 4a): 抽 ReportTile (ChooseWindowDialog + medication report + swallowError)
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          const ExportTile(),
          const Divider(height: 1),
          // v0.30 round 88 (sub-spec 4): 导出 5/7 栏 CBT 思维记录 PDF 入口
          // v0.30 round 95 (sub-spec 1 task 3): 抽到 cbt_pdf_tile.dart
          const CbtPdfTile(),
          const Divider(height: 1),
          const ReportTile(),
          const Divider(height: 1),
          HistoryTile(onShow: () => _showReportHistory(context)),
          const Divider(height: 1),
          ImportTile(onImport: () => _showImportDialog(context, ref)),
          const Divider(height: 1),
          ClearTile(onClear: () => _showClearAllDataDialog(context, ref)),
        ],
      ),
    );
  }

  Future<void> _showReportHistory(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => const ReportHistoryListDialog(),
    );
  }

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

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    bool importing = false;
    if (!context.mounted) return;
    try {
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(AppLocalizations.of(context).settingsImportDialogTitle),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(AppLocalizations.of(context).settingsImportWarning),
                const SizedBox(height: AppTokens.spacingSm),
                TextField(
                  controller: controller,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context).settingsImportHint,
                    border: const OutlineInputBorder(),
                  ),
                  // v0.26 round 57 (emil EMIL-INC-03): 走 textStyleMono 集中器
                  // 替代内联 TextStyle('monospace', fontSize: 12)
                  // 注: 12.0 = fontSizeCaptionSm, 等价
                  style: AppTokens.textStyleMono(
                    context,
                    size: AppTokens.fontSizeCaptionSm,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: importing ? null : () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).commonCancel),
              ),
              LoadingTextButton(
                label: AppLocalizations.of(context).settingsImportAndOverwrite,
                isLoading: importing,
                onPressed: () async {
                  final input = controller.text.trim();
                  if (input.isEmpty) return;
                  setLocal(() => importing = true);
                  final service = ref.read(dataExportServiceProvider);
                  final result = await service.importFromJson(input);
                  if (!ctx.mounted) return;
                  if (result.success) {
                    Navigator.pop(ctx);
                    AppSnackBar.showInfo(
                      context,
                      AppLocalizations.of(context)
                          .settingsImportSuccess(result.summary),
                    );
                  } else {
                    setLocal(() => importing = false);
                    // v0.27 round 59 (emil EMIL-T13): 用 showError 集中器
                    AppSnackBar.showError(
                      context,
                      action: AppLocalizations.of(context).settingsActionImport,
                      error: result.error,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      );
    } finally {
      // v0.27 R71 (P5.4): try/finally 替代 .then(), 异常路径也保证 dispose
      controller.dispose();
    }
  }
}
