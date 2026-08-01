import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/report_history_entity.dart';
import 'package:chroniccare/core/shared/formatters.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/medication_report_dialog.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// 报告历史列表 dialog
class ReportHistoryListDialog extends ConsumerWidget {
  const ReportHistoryListDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHistories = ref.watch(reportHistoriesProvider);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppTokens.spacingSm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 标题栏
            Padding(
              padding: const EdgeInsets.all(AppTokens.spacingMd),
              child: Row(
                children: [
                  Text(
                    AppLocalizations.of(context).settingsReportHistory,
                    style: const TextStyle(
                      fontSize: AppTokens.fontSizeHeadline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  // v0.26 round 57 (emil B-11): 走 PressFeedbackIconButton 集中器
                  // 原 IconButton 缺 tooltip, 这里加 commonClose 走无障碍标准
                  PressFeedbackIconButton(
                    icon: Icons.close,
                    tooltip: AppLocalizations.of(context).commonClose,
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 列表
            Expanded(
              child: asyncHistories.when(
                loading: () => const LoadingSkeleton.fullScreen(),
                // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
                error: (e, _) => ErrorState(
                  title: AppLocalizations.of(context).commonLoadFailed(e.toString()),
                  detail: e.toString(),
                ),
                data: (histories) {
                  if (histories.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(AppTokens.spacingLg),
                      child: Center(
                        child: Text(
                          AppLocalizations.of(context).reportHistoryEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTokens.textHintColor(context),
                          ),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: histories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final h = histories[i];
                      // v0.26 round 57 (emil C-12): 走 AppListTile.standard 集中器
                      return AppListTile.standard(
                        leading: Icon(
                          Icons.description_outlined,
                          color: AppTokens.primaryColor(context),
                        ),
                        title: Text(
                          AppLocalizations.of(context).reportHistoryItemTitle(
                            Formatters.dateTime(h.generatedAt),
                            h.windowDays,
                          ),
                          // v0.26 round 57 (emil B-10): 走 textStyleLabel 集中器
                          // 替代内联 TextStyle(fontSizeLabel) (ListTile title)
                          style: AppTokens.textStyleLabel(context),
                        ),
                        subtitle: Text(
                          // v0.21 Round 23 (P1-24): userName nullable
                          AppLocalizations.of(context).reportHistoryItemPatient(
                            (h.userName ?? '').isEmpty
                                ? AppLocalizations.of(context)
                                    .reportHistoryItemNotSet
                                : h.userName!,
                          ),
                          // v0.26 round 57 (emil B-10): 走 textStyleCaptionHint 集中器
                          // 替代内联 TextStyle(fontSizeCaption, textHintColor)
                          style: AppTokens.textStyleCaptionHint(context),
                        ),
                        trailing: // v0.26 round 57 (emil B-11): 走 PressFeedbackIconButton 集中器
                            PressFeedbackIconButton(
                          icon: Icons.delete_outline,
                          tooltip: AppLocalizations.of(context).commonDelete,
                          onPressed: () => _deleteOne(context, ref, h.id),
                          color: AppTokens.errorColor(context),
                        ),
                        onTap: () => _openDetail(context, h),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOne(BuildContext context, WidgetRef ref, int id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context).reportHistoryDeleteTitle),
        content: Text(AppLocalizations.of(context).reportHistoryDeleteContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppLocalizations.of(context).commonDelete,
              style: AppTokens.textStyleBody(context)
                  .copyWith(color: AppTokens.errorColor(context)),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(reportHistoryRepositoryProvider).delete(id);
    } catch (e) {
      if (context.mounted) {
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonDelete,
          error: e,
        );
      }
    }
  }

  void _openDetail(BuildContext context, ReportHistoryEntity h) {
    showDialog<void>(
      context: context,
      builder: (ctx) => MedicationReportDialog(
        report: h.reportText,
        reportData: null, // 历史无结构化数据，PDF 按钮置灰
        windowDays: h.windowDays,
      ),
    );
  }
}
