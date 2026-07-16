import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/database/app_database.dart';
import '../../../../shared/formatters.dart';
import '../../../../l10n/strings.dart';
import '../../../../theme/app_tokens.dart';
import '../../../providers/core_providers.dart';
import '../../../providers/data_providers.dart';
import 'medication_report_dialog.dart';

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
                  const Text(
                    Strings.settingsReportHistory,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeHeadline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 列表
            Expanded(
              child: asyncHistories.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('加载失败：$e')),
                data: (histories) {
                  if (histories.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppTokens.spacingLg),
                      child: Center(
                        child: Text(
                          '还没有报告历史\n生成一次报告后会自动记录',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppTokens.textHint),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    itemCount: histories.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final h = histories[i];
                      return ListTile(
                        leading: const Icon(
                          Icons.description_outlined,
                          color: AppTokens.primary,
                        ),
                        title: Text(
                          '${Formatters.dateTime(h.generatedAt)} · 近 ${h.windowDays} 天',
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeLabel,
                          ),
                        ),
                        subtitle: Text(
                          '患者: ${h.userName.isEmpty ? '未设置' : h.userName}',
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeCaption,
                            color: AppTokens.textHint,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppTokens.error,
                          ),
                          onPressed: () => _deleteOne(context, ref, h.id),
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
        title: const Text('删除这条报告？'),
        content: const Text('删除后无法恢复，但可以重新生成。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(Strings.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('删除', style: TextStyle(color: AppTokens.error)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(databaseProvider).deleteReportHistory(id);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('删除失败：$e')),
        );
      }
    }
  }

  void _openDetail(BuildContext context, ReportHistory h) {
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
