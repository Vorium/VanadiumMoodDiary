// v0.30 round 95 (sub-spec 1 task 4a): 抽 report_tile
//
// 用药报告入口 tile — 走 ChooseWindowDialog + medication report + swallowError 写 history
//
// 业务逻辑从主壳 (~75 行) 抽到本 sub-tile:
// - ChooseWindowDialog 让用户选 7/14/30 天窗口
// - MedicationReport.compute(userName, meds, checkIns, days) 生成报告
// - reportHistoryRepositoryProvider.insert(...) 写历史 (失败走 swallowError 不阻塞主流程)
// - MedicationReportDialog 弹报告
//
// props callback 模式 (R95 sub-spec 1 步骤 2-3 一致):
// - ConsumerWidget 自包含 _chooseAndShowReport 完整流程
// - 接受 onShow 回调 (默认调内部 _chooseAndShowReport; 测试可注入自定义 handler 跳过完整流)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/medication_report.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/medication_report_dialog.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/choose_window_dialog.dart';

/// 用药报告 tile (ChooseWindowDialog → MedicationReport + 写 history)
///
/// v0.30 round 95: ConsumerWidget, 内部 _chooseAndShowReport 走完整 report 流程
///
/// [onShow] 回调 — 留给测试可注入自定义 handler 跳过完整流。
/// 默认 = 内部 _chooseAndShowReport 完整流程 (ChooseWindowDialog + MedicationReport + 写 history)
class ReportTile extends ConsumerWidget {
  const ReportTile({super.key, this.onShow});

  /// 可选 callback; null 时走内部 _chooseAndShowReport 完整流程
  final Future<void> Function()? onShow;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // v0.32 round 13 (R112 EM-02/AH-04): 透明 Material 包 ListTile,
    // 防 Flutter debug assert (ListTile 在 AppleListSection 白色
    // DecoratedBox 容器内 ink 不可见)
    return Material(
      type: MaterialType.transparency,
      child: AppListTile(
        contentPadding: EdgeInsets.zero,
        leading: Icon(
          Icons.summarize_outlined,
          color: AppTokens.primaryColor(context),
        ),
        title: Text(AppLocalizations.of(context).settingsMedReport),
        subtitle: Text(
          AppLocalizations.of(context).settingsMedReportSubtitle,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          if (onShow != null) {
            onShow!();
          } else {
            _chooseAndShowReport(context, ref);
          }
        },
      ),
    );
  }

  /// v0.30 round 95 (sub-spec 1 task 4a): 完整 medication report 流程
  ///
  /// 1. ChooseWindowDialog 让用户选 7/14/30 天窗口 (默认 14)
  /// 2. ref.read(userProfileProvider.future) + allMedicationsProvider + allCheckInsProvider 并行拿数据
  /// 3. MedicationReport.compute() 生成报告
  /// 4. reportHistoryRepositoryProvider.insert(...) 写历史 (失败走 swallowError 不阻塞)
  /// 5. MedicationReportDialog 弹报告
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

      // v0.21 R83 (P0-1): 写 history 失败不应该阻塞主流程 (用户已经看到报告)
      // 走 swallowError 跟 export audit log 失败模式一致
      try {
        await ref.read(reportHistoryRepositoryProvider).insert(
              windowDays: days,
              generatedAt: report.generatedAt,
              userName: userName,
              reportText: reportText,
            );
      } catch (e, st) {
        swallowError(
          where: 'ReportTile._showMedicationReport.writeHistory',
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
}
