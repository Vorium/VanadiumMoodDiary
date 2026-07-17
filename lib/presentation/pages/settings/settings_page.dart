import '../../providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/logic/assessment_scale.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:chroniccare/domain/logic/scale_registry.dart';
import 'package:chroniccare/core/l10n/strings.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
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
      title: '设置',
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          const _SectionHeader(title: Strings.settingsContacts),
          const SizedBox(height: AppTokens.spacingSm),
          contactsAsync.when(
            data: (contacts) => ContactsListWidget(contacts: contacts),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          const _SectionHeader(title: Strings.settingsMedication),
          const SizedBox(height: AppTokens.spacingSm),
          medsAsync.when(
            data: (meds) => MedicationsListWidget(meds: meds),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('加载失败: $e'),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          const _SectionHeader(title: '数据管理'),
          const SizedBox(height: AppTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_outlined,
                      color: AppTokens.primary,),
                  title: const Text('导出数据'),
                  subtitle: const Text('生成 JSON，复制到安全地方'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _exportData(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.summarize_outlined,
                      color: AppTokens.primary,),
                  title: const Text(Strings.settingsMedReport),
                  subtitle: const Text(Strings.settingsMedReportSubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _chooseAndShowReport(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history, color: AppTokens.primary),
                  title: const Text(Strings.settingsReportHistory),
                  subtitle: const Text(Strings.settingsReportHistorySubtitle),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showReportHistory(context),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined,
                      color: AppTokens.primary,),
                  title: const Text('导入数据'),
                  subtitle: const Text('从 JSON 恢复（覆盖现有数据）'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showImportDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          // v0.14 (Round 12C) 提醒中心入口
          const _SectionHeader(title: '提醒'),
          const SizedBox(height: AppTokens.spacingSm),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTokens.primary,
                  ),
                  title: const Text('提醒中心'),
                  subtitle: const Text(
                    '管理所有提醒：每日打卡、用药时间、续方、心理评估、失联通知',
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
                  title: const Text('续方管理'),
                  subtitle: const Text('集中查看所有药物的续方状态'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/settings/refills'),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingLg),

          // v0.16 round 20: 通知自检卡（一键测试 + OEM 后台引导）
          // 放在「提醒」section 末尾,跟「提醒中心/续方管理」配套
          const NotificationStatusCard(),

          const SizedBox(height: AppTokens.spacingLg),

          const _SectionHeader(title: '心理评估'),
          const SizedBox(height: AppTokens.spacingSm),
          // v0.14 (Round 13B) 评估历史入口
          Card(
            child: ListTile(
              leading: const Icon(Icons.history, color: AppTokens.primary),
              title: const Text('评估历史'),
              subtitle: const Text('查看所有 PHQ-9 / GAD-7 评估的折线图与对比'),
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
              title: const Text(Strings.settingsEmailPreview),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/email-preview'),
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          const Card(
            child: ListTile(
              leading: Icon(Icons.info_outline, color: AppTokens.primary),
              title: Text(Strings.settingsAbout),
              subtitle: Text('v0.1.0 · 我今天吃了药'),
            ),
          ),

          const Card(
            child: ListTile(
              leading:
                  Icon(Icons.shield_outlined, color: AppTokens.textSecondary),
              title: Text(Strings.settingsDisclaimer),
              subtitle: Text('本应用不提供医疗建议，所有功能仅供参考。'),
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
          title: const Text('导出数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('把下面这串 JSON 保存到安全的地方：'),
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
              child: const Text('关闭'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('复制'),
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: json));
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('已复制到剪贴板')),
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
          SnackBar(content: Text('导出失败：$e')),
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
      // 三路数据：userName + meds（含已停药）+ allCheckIns
      // B3 fix: meds 用 allMedicationsProvider，让已停药的历史打卡也能进报告
      final userProfile = await ref.read(userProfileProvider.future);
      final meds = await ref.read(allMedicationsProvider.future);
      final checkIns = await ref.read(allCheckInsProvider.future);

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
          SnackBar(content: Text('生成报告失败：$e')),
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
          title: const Text('导入数据'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('⚠️ 会覆盖现有所有数据，确定后再继续'),
              const SizedBox(height: AppTokens.spacingSm),
              TextField(
                controller: controller,
                maxLines: 8,
                decoration: const InputDecoration(
                  hintText: '把导出的 JSON 粘贴到这里',
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: importing ? null : () => Navigator.pop(ctx),
              child: const Text('取消'),
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
                            content: Text('导入完成：${result.summary}'),
                          ),
                        );
                      } else {
                        setLocal(() => importing = false);
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('导入失败：${result.error}')),
                        );
                      }
                    },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text('导入并覆盖'),
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
