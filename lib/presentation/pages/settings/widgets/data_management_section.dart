import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:printing/printing.dart';

import 'package:chroniccare/core/data/services/cbt_thought_record_pdf.dart';
import 'package:chroniccare/core/data/services/pii_safe_log.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/presentation/providers/cbt_rerated_entries_provider.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/legal_consent_provider.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';
import 'package:chroniccare/presentation/providers/vent_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/consent_dialog.dart';
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
            leading: Icon(
              Icons.upload_outlined,
              color: AppTokens.primaryColor(context),
            ),
            title: Text(AppLocalizations.of(context).settingsExportData),
            subtitle: Text(
              AppLocalizations.of(context).settingsExportSubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportData(context, ref),
          ),
          const Divider(height: 1),
          // v0.30 round 88 (sub-spec 4): 导出 5/7 栏 CBT 思维记录 PDF 入口
          // 紧跟"导出全部数据" 之后, 走 date range picker 选区间 → 调
          // CbtThoughtRecordPdf.build → Printing.layoutPdf 弹系统打印/分享面板。
          // 设计参考: medication_report_dialog._exportPdf (同 mode)。
          AppListTile(
            leading: Icon(
              Icons.picture_as_pdf_outlined,
              color: AppTokens.primaryColor(context),
            ),
            title: Text(AppLocalizations.of(context).cbtExportPdfButton),
            subtitle: Text(
              AppLocalizations.of(context).cbtExportPdfDialogTitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _exportCbtPdf(context, ref),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: Icon(
              Icons.summarize_outlined,
              color: AppTokens.primaryColor(context),
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
            leading:
                Icon(Icons.history, color: AppTokens.primaryColor(context)),
            title: Text(AppLocalizations.of(context).settingsReportHistory),
            subtitle: Text(
              AppLocalizations.of(context).settingsReportHistorySubtitle,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showReportHistory(context),
          ),
          const Divider(height: 1),
          AppListTile(
            leading: Icon(
              Icons.download_outlined,
              color: AppTokens.primaryColor(context),
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
            onTap: () => _showClearAllDataDialog(context, ref),
          ),
        ],
      ),
    );
  }

  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    // v0.27 R82: PIPL §13 单独同意 — 数据导出走 ConsentDialog (kind: dataExport)
    // 替代之前的"敏感文字警告" 通用 dialog。修复前只警告, 没生成 ConsentArtifact,
    // 法务复查时缺 §13 同意证据。修复后: 弹 ConsentDialog 走 dataExportConsent
    // 模板 (purpose / dataCategories / retention 3 placeholder) → 用户同意 →
    // 写 audit log (LegalConsentStore.recordDataExportConsent) → 继续 export。
    final consent = await ConsentDialog.show(
      context,
      kind: ConsentKind.dataExport,
      placeholders: const {
        'purpose': '本地备份 / 跨设备迁移',
        'dataCategories':
            '用药记录、打卡记录、紧急联系人、情绪日记、树洞文字 (录音不导出)',
        'retention': '剪贴板 + 用户自行保存到加密存储',
      },
    );
    if (consent == null) {
      // 用户点了"暂不同意" — 静默退出, 不弹额外提示
      return;
    }
    // R82: 写 audit log (PIPL §17 同意记录可追溯)
    try {
      await ref
          .read(legalConsentStoreProvider)
          .recordDataExportConsent(consent);
    } catch (e, st) {
      // 写 audit log 失败不应该阻塞主流程 (consent 已拿到, 用户已明确同意)
      // 走 swallowError 跟 _showMedicationReport 写 history 失败的模式一致
      swallowError(
        where: 'DataManagementSection._exportData.recordAudit',
        error: e,
        stack: st,
        note: '写 audit log 失败, 主流程继续 (consent 已拿到)',
      );
    }
    if (!context.mounted) return;

    final service = ref.read(dataExportServiceProvider);
    try {
      final json = await service.exportToJson();
      if (!context.mounted) return;
      // v0.28 R83 (Q4b 律师): 导出 JSON dialog 加明文风险 + 责任划界
      // + 强制勾选"我已了解风险"才允许复制 (PIPL §17 告知后用户确认,
      // 责任划界由用户承担 — 跟"明文 = 用户自负"是法律标配)
      bool isAcknowledged = false;
      await showDialog<void>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setLocal) => AlertDialog(
            title: Text(
              AppLocalizations.of(context).settingsExportDialogTitle,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.of(context).settingsExportInstruction,
                  ),
                  const SizedBox(height: AppTokens.spacingXs),
                  // 已有: vent 录音不导出 提示 (v0.26 round 57 加)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTokens.tintedWarningSoft(context),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: Text(
                      AppLocalizations.of(context).settingsExportVentWarning,
                      style: AppTokens.textStyleLegal(context),
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  // Q4b: 明文风险 + 责任划界 (律师反馈 必改)
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTokens.tintedErrorSoft(context),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                      border: Border.all(
                        color: AppTokens.errorColor(context),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppTokens.errorColor(context),
                              size: AppTokens.iconSizeInline,
                            ),
                            const SizedBox(
                              width: AppTokens.spacingXxs,
                            ),
                            Expanded(
                              child: Text(
                                AppLocalizations.of(context)
                                    .settingsExportRiskTitle,
                                style: AppTokens.textStyleLabel(context)
                                    .copyWith(
                                  color: AppTokens.errorColor(context),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppTokens.spacingXxs),
                        Text(
                          AppLocalizations.of(context)
                              .settingsExportRiskBody,
                          style: AppTokens.textStyleBody(context),
                        ),
                        const SizedBox(height: AppTokens.spacingXxs),
                        Text(
                          AppLocalizations.of(context)
                              .settingsExportRiskLiability,
                          style: AppTokens.textStyleLegal(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  // 强制勾选 checkbox 才允许复制
                  CheckboxListTile(
                    value: isAcknowledged,
                    onChanged: (v) =>
                        setLocal(() => isAcknowledged = v ?? false),
                    title: Text(
                      AppLocalizations.of(context)
                          .settingsExportRiskAcknowledge,
                      style: AppTokens.textStyleBody(context),
                    ),
                    controlAffinity:
                        ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: AppTokens.spacingSm),
                  // JSON 容器
                  Container(
                    padding: const EdgeInsets.all(AppTokens.spacingSm),
                    decoration: BoxDecoration(
                      color: AppTokens.dividerColor(context),
                      borderRadius:
                          BorderRadius.circular(AppTokens.radiusChip),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 300),
                      child: SingleChildScrollView(
                        child: SelectableText(
                          json,
                          // v0.26 round 57 (emil EMIL-INC-03): 走 textStyleMono 集中器
                          // 替代内联 TextStyle('monospace', fontSizeCaptionSm)
                          style: AppTokens.textStyleMono(
                            context,
                            size: AppTokens.fontSizeCaptionSm,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(AppLocalizations.of(context).commonClose),
              ),
              ElevatedButton.icon(
                icon: const Icon(
                  Icons.copy,
                  size: AppTokens.iconSizeInline,
                ),
                label: Text(AppLocalizations.of(context).settingsCopy),
                onPressed: isAcknowledged
                    ? () async {
                        await Clipboard.setData(
                          ClipboardData(text: json),
                        );
                        if (ctx.mounted) {
                          // v0.27 round 59 (emil EMIL-T13): 用 showInfo 集中器
                          AppSnackBar.showInfo(
                            ctx,
                            AppLocalizations.of(ctx).snackbarCopied,
                          );
                        }
                      }
                    : null,
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).settingsActionExport,
          error: e,
        );
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

  /// v0.30 round 88 (sub-spec 4): 导出 5/7 栏 CBT 思维记录 PDF
  ///
  /// 流程:
  /// 1. showDateRangePicker 选区间 (默认本月, 跟 mood_list_filter_bar 同 mode)
  /// 2. ref.read(cbtReratedEntriesProvider) 拿已过滤 cbtLevel >= 5 的 entries
  /// 3. 按 dateRange 在 handler 内过滤 (闭区间), 跟 facade 内部 filter 同语义
  /// 4. CbtThoughtRecordPdf().build(entries: filtered, dateRange, l10n) 生成 PDF
  /// 5. Printing.layoutPdf 弹系统打印/分享面板 (跟 MedicationReportPdf 同模式)
  /// 6. SnackBar 成功/失败
  ///
  /// 注: cbtReratedEntriesProvider 是 autoDispose — 在 handler 内 ref.read
  /// 同步取值即可, 不在 build 监听 (避免每次 build 重建 PDF)。
  Future<void> _exportCbtPdf(BuildContext context, WidgetRef ref) async {
    if (!context.mounted) return;
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
    );
    if (picked == null) return;
    if (!context.mounted) return;

    // cbtReratedEntriesProvider 已过滤 cbtLevel >= 5 (5/7 栏) — 见
    // cbt_rerated_entries_provider.dart。在 handler 内再按 dateRange 过滤一次,
    // 跟 facade 内部 filter 同语义, 但 SnackBar 数字 = 实际 PDF 页数。
    final all = ref.read(cbtReratedEntriesProvider);
    final filtered = all
        .where(
          (e) =>
              !e.timestamp.isBefore(picked.start) &&
              !e.timestamp.isAfter(picked.end),
        )
        .toList();
    try {
      final pdfBytes = await CbtThoughtRecordPdf().build(
        entries: filtered,
        dateRange: picked,
        l10n: l10n,
      );
      if (!context.mounted) return;
      // Printing.layoutPdf 要求 LayoutCallback 返回 FutureOr<Uint8List> (见
      // printing/callback.dart typedef), 而 CbtThoughtRecordPdf.build 返回
      // List<int>。包一层 Uint8List.fromList 转换, 跟 MedicationReportPdf
      // 现有 onLayout 模式一致 (bytes 已经是 Uint8List, 这里从 List<int> 显式转)。
      final pdfUint8 = Uint8List.fromList(pdfBytes);
      await Printing.layoutPdf(
        onLayout: (_) async => pdfUint8,
        name: 'cbt_thought_record.pdf',
      );
      if (!context.mounted) return;
      AppSnackBar.showInfo(
        context,
        l10n.cbtExportPdfSuccess(filtered.length),
      );
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showInfo(context, l10n.cbtExportPdfFailed);
      }
    }
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
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).settingsActionGenerateReport,
          error: e,
        );
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
