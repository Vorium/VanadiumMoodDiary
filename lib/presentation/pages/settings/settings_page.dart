import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/assessment/widgets/assessment_reminder_section.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/choose_window_dialog.dart';
import 'package:chroniccare/presentation/pages/contact/contacts_list_widget.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_report_dialog.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medications_list_widget.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/notification_status_card.dart';
import 'package:chroniccare/presentation/pages/settings/widgets/report_history_dialog.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 心理评估量表列表（设置页用）
final List<AssessmentScale> _assessmentScales = allScales();

/// 设置页
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactsAsync = ref.watch(contactsProvider);
    final medsAsync = ref.watch(medicationsProvider);

    return PageScaffold(
      title: AppLocalizations.of(context).settingsTitle,
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          _SectionHeader(title: AppLocalizations.of(context).settingsContacts),
          const SizedBox(height: AppTokens.spacingSm),
          contactsAsync.when(
            data: (contacts) => ContactsListWidget(contacts: contacts),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => Text(
                AppLocalizations.of(context).commonLoadFailed(e.toString())),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          _SectionHeader(
            title: AppLocalizations.of(context).settingsMedication,
          ),
          const SizedBox(height: AppTokens.spacingSm),
          medsAsync.when(
            data: (meds) => MedicationsListWidget(meds: meds),
            loading: () => const LoadingSkeleton.fullScreen(),
            error: (e, _) => Text(
                AppLocalizations.of(context).commonLoadFailed(e.toString())),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          _SectionHeader(
              title: AppLocalizations.of(context).settingsDataManagement),
          const SizedBox(height: AppTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.upload_outlined,
                    color: AppTokens.primary,
                  ),
                  title: Text(AppLocalizations.of(context).settingsExportData),
                  subtitle:
                      Text(AppLocalizations.of(context).settingsExportSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
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
                ListTile(
                  leading: const Icon(Icons.history, color: AppTokens.primary),
                  title:
                      Text(AppLocalizations.of(context).settingsReportHistory),
                  subtitle: Text(
                    AppLocalizations.of(context).settingsReportHistorySubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReportHistory(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.download_outlined,
                    color: AppTokens.primary,
                  ),
                  title: Text(AppLocalizations.of(context).settingsImportData),
                  subtitle:
                      Text(AppLocalizations.of(context).settingsImportSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          // v0.14 (Round 12C) 提醒中心入口
          _SectionHeader(title: AppLocalizations.of(context).settingsReminders),
          const SizedBox(height: AppTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTokens.primary,
                  ),
                  title:
                      Text(AppLocalizations.of(context).settingsReminderCenter),
                  subtitle: Text(
                    AppLocalizations.of(context).settingsReminderCenterSubtitle,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/reminders'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.shopping_cart_outlined,
                    color: AppTokens.primary,
                  ),
                  title: Text(
                      AppLocalizations.of(context).settingsRefillManagement),
                  subtitle: Text(AppLocalizations.of(context)
                      .settingsRefillManagementSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/refills'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          // v0.16 round 20: 通知自检卡（一键测试 + OEM 后台引导）
          // 放在「提醒」section 末尾，跟「提醒中心/续方管理」配套
          const NotificationStatusCard(),

          const SizedBox(height: AppTokens.spacingLg),

          _SectionHeader(
              title: AppLocalizations.of(context).settingsAssessment),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.14 (Round 13B) 评估历史入口
          Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: AppTokens.primary),
              title:
                  Text(AppLocalizations.of(context).settingsAssessmentHistory),
              subtitle: Text(AppLocalizations.of(context)
                  .settingsAssessmentHistorySubtitle),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/assessment/history'),
            ),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.13 (Round 7) 评估周期提醒（Apple Health 思路）
          const AssessmentReminderSection(),
          const SizedBox(height: AppTokens.spacingSm),
          // 心理评估：列出所有可用量表
          Card(
            child: Column(
              children: [
                for (int i = 0; i < _assessmentScales.length; i++) ...[
                  ListTile(
                    leading: Icon(
                      _assessmentScales[i].id == 'phq9'
                          ? Icons.psychology_outlined
                          : Icons.psychology_alt_outlined,
                      color: AppTokens.primary,
                    ),
                    title: Text(_assessmentScales[i].displayName),
                    subtitle: Text(_assessmentScales[i].shortDescription),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        context.push('/assessment/${_assessmentScales[i].id}'),
                  ),
                  if (i < _assessmentScales.length - 1)
                    const Divider(height: 1, indent: 56),
                ],
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          Card(
            child: ListTile(
              leading:
                  const Icon(Icons.email_outlined, color: AppTokens.primary),
              title: Text(AppLocalizations.of(context).settingsEmailPreview),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/email-preview'),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          Card(
            child: ListTile(
              leading: const Icon(Icons.info_outline, color: AppTokens.primary),
              title: Text(AppLocalizations.of(context).settingsAbout),
              subtitle: Text(AppLocalizations.of(context).settingsAboutVersion),
            ),
          ),

          Card(
            child: ListTile(
              leading: const Icon(
                Icons.shield_outlined,
                color: AppTokens.textSecondary,
              ),
              title: Text(AppLocalizations.of(context).settingsDisclaimer),
              subtitle:
                  Text(AppLocalizations.of(context).settingsDisclaimerText),
            ),
          ),
        ],
      ),
    );
  }

  /// 导出：生成 JSON → 弹 Dialog → 用户点"复制到剪贴板"
  Future<void> _exportData(BuildContext context, WidgetRef ref) async {
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
              // P0-3 fix: 透明告知用户 vent 导出范围(文字导出，录音不导出)。
              const SizedBox(height: AppTokens.spacingXs),
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSm),
                decoration: BoxDecoration(
                  color: AppTokens.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: Text(
                  AppLocalizations.of(context).settingsExportVentWarning,
                  style: const TextStyle(fontSize: 12, height: 1.4),
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Container(
                padding: const EdgeInsets.all(AppTokens.spacingSm),
                decoration: BoxDecoration(
                  color: AppTokens.divider,
                  borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 300),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      json,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
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
                      context,
                      AppLocalizations.of(context).snackbarCopied,
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
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context,
              action: AppLocalizations.of(context).settingsActionExport,
              error: e),
        );
      }
    }
  }

  /// 选时间窗口 → 生成用药报告 → 弹全屏预览
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

  /// 用药报告：指定窗口天数的用药情况，给医生看的纯文本
  ///
  /// 成功生成后**自动写入报告历史**
  Future<void> _showMedicationReport(
    BuildContext context,
    WidgetRef ref, {
    required int days,
  }) async {
    try {
      // P0 fix: 并行获取三路数据（互相独立）
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

      // 写历史（在弹 dialog 前做，避免 dialog 关闭时 history provider 还没刷新）
      try {
        await ref.read(reportHistoryRepositoryProvider).insert(
              windowDays: days,
              generatedAt: report.generatedAt,
              userName: userName,
              reportText: reportText,
            );
      } catch (_) {
        // 写历史失败不影响主流程
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
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context,
              action: AppLocalizations.of(context).settingsActionGenerateReport,
              error: e),
        );
      }
    }
  }

  /// 报告历史：列表 + 详情预览
  Future<void> _showReportHistory(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => const ReportHistoryListDialog(),
    );
  }

  /// 导入：弹 Dialog → 粘贴 JSON → 验证 → 覆盖
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
            ElevatedButton(
              onPressed: importing
                  ? null
                  : () async {
                      final input = controller.text.trim();
                      if (input.isEmpty) return;
                      setLocal(() => importing = true);
                      final service = ref.read(dataExportServiceProvider);
                      final result = await service.importFromJson(input);
                      if (!ctx.mounted) return;
                      if (result.success) {
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(AppLocalizations.of(context)
                                .settingsImportSuccess(result.summary)),
                          ),
                        );
                      } else {
                        setLocal(() => importing = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          AppSnackBar.error(
                            context,
                            action: AppLocalizations.of(context)
                                .settingsActionImport,
                            error: result.error,
                          ),
                        );
                      }
                    },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Text(AppLocalizations.of(context).settingsImportAndOverwrite),
                  if (importing)
                    const IgnorePointer(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).then((_) => controller.dispose());
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: AppTokens.fontSizeLabel,
        color: AppTokens.textSecondary,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
