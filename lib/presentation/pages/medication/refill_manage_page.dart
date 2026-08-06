// v0.14 (Round 13A) 续方管理页面
//
// 集中查看所有药物的续方状态：
// - 每种药一行：药名 / 剂量 / 续方日期 / 距今天 X 天 / 状态徽章
// - 状态：未设 / 已设（远）/ 提醒中 / 已过期
// - 行点击 → 跳到该药的编辑对话框
//
// 数据源：MedicationEntity（domain）+ MedicationRepository（abstract）
// 业务方法直接用 entity.isInRefillWindow / .isRefillOverdue

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/stat_card.dart';

/// 续方状态
enum RefillStatus {
  /// 没设续方日期
  notConfigured,

  /// 续方日还在远处（> 提醒窗口）
  farFuture,

  /// 进入提醒窗口
  inWindow,

  /// 已过期
  overdue,
}

extension RefillStatusX on RefillStatus {
  String labelOf(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (this) {
      case RefillStatus.notConfigured:
        return l10n.medsRefillStatusNotConfigured;
      case RefillStatus.farFuture:
        return l10n.medsRefillStatusSet;
      case RefillStatus.inWindow:
        return l10n.medsRefillStatusReminding;
      case RefillStatus.overdue:
        return l10n.medsRefillStatusOverdue;
    }
  }

  Color colorOf(BuildContext context) => switch (this) {
        RefillStatus.notConfigured => AppTokens.textHintColor(context),
        RefillStatus.farFuture => AppTokens.primaryColor(context),
        RefillStatus.inWindow => AppTokens.warningColor(context),
        RefillStatus.overdue => AppTokens.errorColor(context),
      };
}

/// 续方管理
class RefillManagePage extends ConsumerWidget {
  const RefillManagePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(medicationsProvider);
    return PageScaffold(
      title: AppLocalizations.of(context).settingsRefillManagement,
      child: medsAsync.when(
        data: (meds) => _buildBody(context, ref, meds),
        loading: () => const LoadingSkeleton.fullScreen(),
        // v0.27 round 77 (R76-N8 修): commonLoadFailed 传 e.toString()
        error: (e, _) => ErrorState(
          title: AppLocalizations.of(context).commonLoadFailed(e.toString()),
          detail: e.toString(),
          onRetry: () => ref.invalidate(medicationsProvider),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    List<MedicationEntity> meds,
  ) {
    final now = DateTime.now();

    // 给每种药计算状态
    final rows = meds
        .map(
          (m) => _Row(
            med: m,
            status: _statusFor(m, now),
            daysUntil: _daysUntilRefill(m, now),
          ),
        )
        .toList()
      ..sort((a, b) {
        // 状态优先级：已过期 > 提醒中 > 已设 > 未设置
        int rank(RefillStatus s) => switch (s) {
              RefillStatus.overdue => 0,
              RefillStatus.inWindow => 1,
              RefillStatus.farFuture => 2,
              RefillStatus.notConfigured => 3,
            };
        final r = rank(a.status).compareTo(rank(b.status));
        if (r != 0) return r;
        // 续方日近的排前面
        if (a.daysUntil != null && b.daysUntil != null) {
          return a.daysUntil!.compareTo(b.daysUntil!);
        }
        return a.med.name.compareTo(b.med.name);
      });

    // 顶部汇总
    final overdue = rows.where((r) => r.status == RefillStatus.overdue).length;
    final inWindow =
        rows.where((r) => r.status == RefillStatus.inWindow).length;
    final configured = rows.where((r) => r.med.hasRefill).length;

    return ListView(
      children: [
        const SizedBox(height: AppTokens.spacingMd),

        // 顶部汇总卡
        // v0.30 round 95 (sub-spec 2 task 10): 4 StatCard Row 改 2x2 grid
        // (R92 emil P1-2.1.4: 4 StatCard 数字挤一起, 视觉密度太高),
        // 数字更大 / 间距更合理, 改 2x2 改善可读性。
        Card(
          child: Padding(
            padding: AppTokens.edgeInsetsMd,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      // v0.27 round 67 (C-4): 走 StatCard 集中器
                      child: StatCard(
                        label: AppLocalizations.of(context).medsTotal,
                        value: '${meds.length}',
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingMd),
                    Expanded(
                      child: StatCard(
                        label:
                            AppLocalizations.of(context).medsRefillSetCount,
                        value: '$configured',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTokens.spacingMd),
                Row(
                  children: [
                    Expanded(
                      child: StatCard(
                        label:
                            AppLocalizations.of(context).medsRefillReminding,
                        value: '$inWindow',
                        valueColor: inWindow > 0
                            ? AppTokens.warningColor(context)
                            : null,
                      ),
                    ),
                    const SizedBox(width: AppTokens.spacingMd),
                    Expanded(
                      child: StatCard(
                        label:
                            AppLocalizations.of(context).refillManageOverdue,
                        value: '$overdue',
                        valueColor: overdue > 0
                            ? AppTokens.errorColor(context)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppTokens.spacingMd),

        if (rows.isEmpty)
          Padding(
            padding: AppTokens.edgeInsetsXl,
            child: Center(
              child: Text(
                AppLocalizations.of(context).medsNoMedicationsAdded,
                style: AppTokens.textStyleBody(context)
                    .copyWith(color: AppTokens.textHintColor(context)),
              ),
            ),
          )
        else
          Card(
            child: Column(
              children: [
                for (int i = 0; i < rows.length; i++) ...[
                  if (i > 0) const Divider(height: 1, indent: 56),
                  _RefillRow(
                    row: rows[i],
                    onTap: () => _editMedication(context, rows[i].med),
                  ),
                ],
              ],
            ),
          ),

        const SizedBox(height: AppTokens.spacingMd),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTokens.spacingMd),
          child: Text(
            AppLocalizations.of(context).medsRefillEditHint,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
          ),
        ),
      ],
    );
  }

  RefillStatus _statusFor(MedicationEntity m, DateTime now) {
    if (!m.hasRefill) return RefillStatus.notConfigured;
    if (m.isRefillOverdue(now)) return RefillStatus.overdue;
    if (m.isInRefillWindow(now)) return RefillStatus.inWindow;
    return RefillStatus.farFuture;
  }

  /// 按"天"计算 refill 距今多少天（负数=已过期 N 天；0=今天；正数=还有 N 天）
  ///
  /// 用 `m.refillAt.difference(today)` 而不是 `m.refillAt.difference(now)`，
  /// 避免时分秒导致的边界误差。
  static int _daysUntilRefill(MedicationEntity m, DateTime now) {
    if (m.refillAt == null) return 0;
    final today = DateTime(now.year, now.month, now.day);
    final refillDay = DateTime(
      m.refillAt!.year,
      m.refillAt!.month,
      m.refillAt!.day,
    );
    return refillDay.difference(today).inDays;
  }

  Future<void> _editMedication(
    BuildContext context,
    MedicationEntity med,
  ) async {
    await showEditMedicationDialog(context, med);
  }
}

class _Row {
  final MedicationEntity med;
  final RefillStatus status;
  final int? daysUntil; // 负数 = 已过期
  const _Row({required this.med, required this.status, this.daysUntil});
}

class _RefillRow extends StatelessWidget {
  final _Row row;
  final VoidCallback onTap;
  const _RefillRow({required this.row, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final m = row.med;
    final statusColor = row.status.colorOf(context);
    // v0.26 round 57 (emil C-12): 走 AppListTile.standard 集中器
    // 替代 inline ListTile + PressFeedback
    return AppListTile.standard(
      onTap: onTap,
      leading: _StatusDot(status: row.status),
      title: Row(
        children: [
          Expanded(
            child: Text(
              '${m.name} ${_formatDose(m.dosage, m.dosageUnit)}',
              style: AppTokens.textStyleLabelStrong(context),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.spacingXs,
              vertical: AppTokens.spacingXxxs,
            ),
            decoration: BoxDecoration(
              color: AppColors.tintedStatusSoft(context, statusColor),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: Text(
              row.status.labelOf(context),
              style: AppTokens.textStyleMicro(context).copyWith(
                color: statusColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: AppTokens.spacingXxs),
        child: Text(
          _subtitleFor(context, row),
          // v0.26 round 57 (emil B-10): 走 textStyleCaptionHint 集中器
          // 替代内联 TextStyle(fontSizeCaption, textHintColor)
          style: AppTokens.textStyleCaptionHint(context),
        ),
      ),
      trailing:
          Icon(Icons.chevron_right, color: AppTokens.textHintColor(context)),
    );
  }

  String _subtitleFor(BuildContext context, _Row r) {
    final l10n = AppLocalizations.of(context);
    final m = r.med;
    if (!m.hasRefill) {
      return l10n.medsRefillNotSetSubtitle(m.refillReminderDays);
    }
    final dateStr =
        '${m.refillAt!.year}-${m.refillAt!.month.toString().padLeft(2, '0')}-${m.refillAt!.day.toString().padLeft(2, '0')}';
    final days = r.daysUntil!;
    String suffix;
    if (days < 0) {
      suffix = l10n.medsRefillExpiredDays(-days);
    } else if (days == 0) {
      suffix = l10n.medsRefillToday;
    } else {
      suffix = l10n.medsRefillRemainingDays(days);
    }
    return l10n.medsRefillSubtitleTemplate(
      dateStr,
      suffix,
      m.refillReminderDays,
    );
  }

  String _formatDose(double d, DosageUnit u) {
    final isInt = d == d.truncateToDouble();
    return '${isInt ? d.toInt() : d}${u.id}';
  }
}

class _StatusDot extends StatelessWidget {
  final RefillStatus status;
  const _StatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppTokens.avatarSizeSm,
      height: AppTokens.avatarSizeSm,
      decoration: BoxDecoration(
        color: AppColors.tintedStatusSoft(context, status.colorOf(context)),
        shape: BoxShape.circle,
      ),
      child: Icon(
        switch (status) {
          RefillStatus.notConfigured => Icons.help_outline,
          RefillStatus.farFuture => Icons.check,
          RefillStatus.inWindow => Icons.notifications_active,
          RefillStatus.overdue => Icons.warning_amber,
        },
        color: status.colorOf(context),
        size: AppTokens.iconSizeInline,
      ),
    );
  }
}
