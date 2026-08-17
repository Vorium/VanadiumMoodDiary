// v0.14 (Round 13A) 续方管理页面
//
// 集中查看所有药物的续方状态：
// - 每种药一行：药名 / 剂量 / 续方日期 / 距今天 X 天 / 状态徽章
// - 状态：未设 / 已设（远）/ 提醒中 / 已过期
// - 行点击 → 跳到该药的编辑对话框
//
// 数据源：MedicationEntity（domain）+ MedicationRepository（abstract）
// 业务方法直接用 entity.isInRefillWindow / .isRefillOverdue
//
// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
// 改 AppleListSection 风格 (spec §5.3 medication):
// - 顶部 4 StatCard 改 ultralight `large` variant (34pt w200)
// - 4 StatCard 放在 AppleListSection 内 (iOS 群组列表风格)
// - 续方列表用 AppleListSection 包装, 内部用 hairline divider
// - 章节走 SectionHeader ALL CAPS

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chroniccare/domain/entities/dosage_unit.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

import 'package:chroniccare/features/medication/domain/entities/medication_entity.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/edit_medication_dialog.dart';
import 'package:chroniccare/presentation/widgets/app_list_tile.dart';
import 'package:chroniccare/presentation/widgets/section_header.dart';
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
    final l10n = AppLocalizations.of(context);

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

        // 章节 1: 顶部汇总 — SectionHeader ALL CAPS + AppleListSection
        // v0.31 R11a: 4 StatCard 改 ultralight large variant (34pt w200)
        // 装在 AppleListSection 内 (iOS 群组列表风格)
        // R114 Wave B2 (B2-4): 页面内所有 pageMarginH 20 删除 — 本页在
        // PageScaffold 内 (已包 20px), 内部再包 20 曾叠加成 40px 双重 inset。
        SectionHeader(title: l10n.refillManageSummary),
        const SizedBox(height: AppTokens.spacingXxs),
        AppleListSection(
          children: [
            // 2x2 StatCard 网格 — ultralight large variant (34pt w200)
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: l10n.medsTotal,
                      value: '${meds.length}',
                      variant: StatCardVariant.large,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: StatCard(
                      label: l10n.medsRefillSetCount,
                      value: '$configured',
                      variant: StatCardVariant.large,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            IntrinsicHeight(
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: l10n.medsRefillReminding,
                      value: '$inWindow',
                      variant: StatCardVariant.large,
                      valueColor:
                          inWindow > 0 ? AppTokens.warningColor(context) : null,
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: StatCard(
                      label: l10n.refillManageOverdue,
                      value: '$overdue',
                      variant: StatCardVariant.large,
                      valueColor:
                          overdue > 0 ? AppTokens.errorColor(context) : null,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: AppTokens.spacingMd),

        // 章节 2: 续方列表 — SectionHeader ALL CAPS + AppleListSection
        // (R114 B2-4: 页边距由 PageScaffold 负责, 不再页面内包 20)
        SectionHeader(
          title: l10n.refillManageMedsList,
          chip: '${rows.length}', // 数量 chip
        ),
        const SizedBox(height: AppTokens.spacingXxs),

        if (rows.isEmpty)
          Center(
            child: Text(
              l10n.medsNoMedicationsAdded,
              style: AppTokens.textStyleBody(context)
                  .copyWith(color: AppTokens.textHintColor(context)),
            ),
          )
        else
          AppleListSection(
            children: [
              // v0.31 R11a: 列表项 - 改用 _RefillRow (已包 AppListTile.standard)
              for (final r in rows)
                _RefillRow(
                  row: r,
                  onTap: () => _editMedication(context, r.med),
                ),
            ],
          ),

        const SizedBox(height: AppTokens.spacingMd),
        // iOS section footer — 章节下方说明文字
        // (R114 B2-4: 页边距由 PageScaffold 负责, 不再页面内包 20)
        Text(
          l10n.medsRefillEditHint,
          style: TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            color: AppTokens.textHintColor(context),
          ),
        ),
        const SizedBox(height: AppTokens.spacingLg),
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
