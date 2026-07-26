import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/loading_text_button.dart';
import 'package:chroniccare/presentation/widgets/medication_report_dialog.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/choose_window_dialog.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/report_history_dialog.dart';

/// 数据管理 section — 导出/报告/历史/导入/清空
///
/// 从 settings_page.dart 提取 (v0.23 P1 refactor)
class DataManagementSection extends ConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Column(
        children: [
          AppListTile(
            leading: const Icon(
              Icons.upload_outlined,
              color: AppTokens.primary,
            ),
            title: Text(AppLocalizations.of(context).settingsExportData),
            subtitle: Text(
              AppLocalizations.of(context).settingsExportSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context, ref),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: const Icon(
              Icons.summarize_outlined,
              color: AppTokens.primary,
            ),
            title: Text(AppLocalizations.of(context).settingsMedReport),
            subtitle: Text(
              AppLocalizations.of(context).settingsMedReportSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _chooseAndShowReport(context, ref),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: const Icon(Icons.history, color: AppTokens.primary),
            title: Text(AppLocalizations.of(context).settingsReportHistory),
            subtitle: Text(
              AppLocalizations.of(context).settingsReportHistorySubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReportHistory(context),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: const Icon(
              Icons.download_outlined,
              color: AppTokens.primary,
            ),
            title: Text(AppLocalizations.of(context).settingsImportData),
            subtitle: Text(
              AppLocalizations.of(context).settingsImportSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showImportDialog(context, ref),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: const Icon(
              Icons.delete_forever_outlined,
              color: AppTokens.error,
            ),
            title: Text(
              AppLocalizations.of(context).settingsClearAllData,
              style: AppTokens.textStyleBody(context)
                  .copyWith(color: AppTokens.error),
            ),
            subtitle: Text(
              AppLocalizations.of(context).settingsClearAllDataSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showClearAllDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.settingsExportVentConfirmTitle),
        content: Text(l10n.settingsExportVentConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.settingsExportVentConfirmConfirm),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final service = ref.read(dataExportServiceProvider);
    try {
      final json = await service.exportToJson();
      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppLocalizations.of(context).settingsExportDialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(AppLocalizations.of(context).settingsExportInstruction),
              const SizedBox(height: AppTokens.spacingXs),
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSm),
                decoration: BoxDecoration(
                  color: AppTokens.tintedWarningSoft(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: Text(
                  AppLocalizations.of(context).settingsExportVentWarning,
                  style: AppTokens.textStyleLegal(context),
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSm),
                decoration: BoxDecoration(
                  color: AppTokens.dividerColor(context),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: AppTokens.fontSizeCaptionSm,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(context).commonClose),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: Text(AppLocalizations.of(context).settingsCopy),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    AppSnackBar.info(
                      ctx,
                      AppLocalizations.of(ctx).snackbarCopied,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context,
              action: AppLocalizations.of(context).settingsActionExport,
              error: e);
      }
    }
  }

  Future<void> _chooseAndShowReport(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!context.mounted) return;
    final days = await showDialog<int>(
      context: context,
      builder: (ctx) => const ChooseWindowDialog(),
    );
    if (days == null) return;
    if (!context.mounted) return;
    await _showMedicationReport(context, ref, days: days);
  }

  Future<void> _showMedicationReport(
    BuildContext context,
    WidgetRef ref, {
    required int days,
  }) async {
    try {
      final results = await Future.wait([
        ref.read(userProfileProvider.future),
        ref.read(allMedicationsProvider.future),
        ref.read(allCheckInsProvider.future),
      ]);
      final userProfile = results[0] as UserProfileEntity?;
      final meds = results[1] as List<MedicationEntity>;
      final checkIns = results[2] as List<CheckInEntity>;

      if (!context.mounted) return;
      final userName = userProfile?.userName ?? '';
      final report = MedicationReport.compute(
        userName: userName,
        meds: meds,
        checkIns: checkIns,
        days: days,
      );
      final reportText = report.toReportString();

      try {
        await ref.read(reportHistoryRepositoryProvider).insert(
              windowDays: days,
              generatedAt: report.generatedAt,
              userName: userName,
              reportText: reportText,
            );
      } catch (e, st) {
        swallowError(
          where: 'DataManagementSection._showMedicationReport.writeHistory',
          error: e,
          stack: st,
          note: '写历史失败不影响主流程',
        );
      }

      if (!context.mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => MedicationReportDialog(
          report: reportText,
          reportData: report,
          windowDays: days,
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(context,
              action: AppLocalizations.of(context).settingsActionGenerateReport,
              error: e);
      }
    }
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
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.error,
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
          error: e,);
    }
  }

  Future<void> _showImportDialog(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController();
    bool importing = false;
    if (!context.mounted) return;
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
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
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
                          .settingsImportSuccess(result.summary),);
                } else {
                  setLocal(() => importing = false);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    AppSnackBar.error(
                      context,
                      action: AppLocalizations.of(context).settingsActionImport,
                      error: result.error,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }
}
