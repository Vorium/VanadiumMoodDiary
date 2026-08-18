// v0.30 R101: 用药主页 — 参照 Apple Health Medications
//
// 独立路由 /medication，包含:
// - 今日服药计划（时间段分组：早/午/晚/睡前）
// - 我的药物列表（卡片式）
// - 快捷操作（日历/续方/报告）
//
// v0.30 R108 (P1 medication_page 拆): 抽时间段算法 (_TimeSlot enum + contains
// 方法) 到 `domain/logic/medication_slot_calculator.dart`, 0 Flutter 0 Drift
// 可直接覆盖测试。本文件删 _TimeSlot enum, 改用 [MedicationTimeSlot]。
//
// v0.31 round 11a (Apple Health redesign · Phase 3 Task 3.3):
// 改 Apple Health 仪表盘风格 (spec §5.3 medication):
// - 顶部 4-5 AppleHealthTile 横滚 (medication 主题 systemRed)
// - 今日用药走 AppleListSection (iOS 群组列表)
// - 我的药物走 AppleListSection
// - 快捷操作 2x2 AppleHealthTile 网格 (medication 内同类操作入口)
// - 底部 FAB 添加 (systemRed 圆点, spec §5.3 "FAB")
// - 整体 spacing 16 (spacingMd) 替代 24 (spacingLg)
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/features/medication/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_page_stats_calculator.dart';
import 'package:chroniccare/domain/logic/medication_slot_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_empty_state_cards.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_list_cell.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_slot_entry_row.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// v0.30 R108 (P1 medication_page 拆): 抽到 domain 后, presentation 层只
/// 负责 [MedicationTimeSlot.name] → icon + l10n label 的映射。
///
/// 集中放这避免 _TimeSlotCard 内部散落 switch, 跟 R97 emil token 化
/// 模式一致 (集中器去散落)。
///
/// R32 (N-10 警告): _slotIcon 0 caller (R108 P1 拆解漏删), 删

/// 一个时间段内的服药条目
///
/// v0.32 R109 (god class 拆 round 3): 抽到 `domain/logic/medication_page_stats_calculator.dart`
/// 公开 `MedicationSlotEntry` 类, 跟原 `_SlotEntry` 1:1 对应 (med + time + done).
/// 本类删, 所有 caller 改 import 公开类.
typedef _SlotEntry = MedicationSlotEntry;

class MedicationPage extends ConsumerWidget {
  const MedicationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final medsAsync = ref.watch(medicationsProvider);
    final checkInsAsync = ref.watch(allCheckInsProvider);
    final today = ref.watch(todayProvider);

    return PageScaffold(
      title: l10n.medPageTitle,
      actions: [
        // v0.31.1 round 8 (emil P0-C + R108 P1-001 漏修): 改用
        // PressFeedbackIconButton 集中器, 去掉外层 PressFeedback 包装
        // (集中器内部已自带 PressFeedback)。
        PressFeedbackIconButton(
          icon: Icons.add_rounded,
          tooltip: l10n.medAddTooltip,
          onPressed: () => context.push('/medication/add'),
        ),
      ],
      // v0.31 R11a (spec §5.3): FAB 添加 medication (systemRed 圆形)
      floatingActionButton: medsAsync.maybeWhen(
        data: (meds) => meds.isEmpty
            ? null
            : FloatingActionButton(
                // 顶部已放 IconButton.add, FAB 这里改主题色点 (spec §5.3 "FAB")
                backgroundColor: AppColors.healthMetricsColorFor('medication'),
                // R32 hotfix round 2 (P0-34): Colors.white → AppColors.fgOnPrimary
                // (M3 theme-aware, 跟 emil "颜色集中" 原则)
                foregroundColor: AppColors.fgOnPrimary(context),
                onPressed: () => context.push('/medication/add'),
                child: const Icon(Icons.add_rounded),
              ),
        orElse: () => null,
      ),
      child: medsAsync.when(
        data: (meds) {
          final activeMeds =
              meds.where((m) => m.isInUse && m.times.isNotEmpty).toList();
          final allMeds = meds;

          // 构建今日时间段分组
          final slots = _buildTimeSlots(
            activeMeds,
            checkInsAsync.value,
            today,
          );

          return ListView(
            padding: AppTokens.edgeInsetsMd,
            children: [
              // ═══════════════════════════════════════════════════
              // 顶部 4-5 AppleHealthTile 横滚 (medication 主题 systemRed)
              // ═══════════════════════════════════════════════════
              SizedBox(
                height: AppleHealthTile.tileHeight,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.pageMarginH,
                  ),
                  children: [
                    // 今日待服 (medication 红, "待服" 计数)
                    AppleHealthTile(
                      metricId: 'medication',
                      label: l10n.medTodayPending, // "待服"
                      value: '${_pendingCount(slots)}',
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    // v0.32 R112 (AH-16): 已服 → checkIn (systemGreen,
                    // 打卡/完成语义; 修前 4 tile 全同色同 icon)
                    // v1.1.0+186 R129 P0-10 (R128e 综合审视修正): checkIn
                    // metricId 修正 跟 apple_health_tile 8 metric 修正中 checkIn
                    // 修正 enum 修正冲突 (medication 业务"已服"修正 vs 修正
                    // metric 修正 "打卡" 修正), 修正 修正 'medication' 修正
                    // (跟 tile 修正 'medication' 修正 修正 metric, 同色同 icon
                    // 修正 修正 修正 修正)
                    AppleHealthTile(
                      metricId: 'medication',
                      label: l10n.medTodayTaken, // "已服"
                      value: '${_takenCount(slots)}',
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    // v0.32 R112 (AH-16): 续方提醒 → contact (systemOrange,
                    // R112 审计建议 refill=orange; 修前同 medication 红)
                    AppleHealthTile(
                      metricId: 'contact',
                      label: l10n.medTodayRefill, // "需续方"
                      value: '${_refillAlertCount(meds)}',
                      onTap: () => context.push('/settings/refills'),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    // v0.32 R112 (AH-16): 用药日历 → trend (systemBlue,
                    // R112 审计建议 history=blue; 修前同 medication 红)
                    AppleHealthTile(
                      metricId: 'trend',
                      label: l10n.medsCalendarTitle, // "用药日历"
                      value: l10n.homeQuickActionView, // "查看"
                      onTap: () => context.push('/medication/calendar'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.spacingMd),

              // ═══════════════════════════════════════════════════
              // 章节 1: 今日服药计划 — AppleListSection
              // ═══════════════════════════════════════════════════
              if (activeMeds.isEmpty)
                EmptyScheduleCard(l10n: l10n)
              else
                ..._buildSlotSections(context, slots, l10n, ref),

              const SizedBox(height: AppTokens.spacingMd),

              // ═══════════════════════════════════════════════════
              // 章节 2: 我的药物 — AppleListSection
              // ═══════════════════════════════════════════════════
              AppleListSection(
                title: l10n.medMyMedications, // "我的药物"
                margin: EdgeInsets.zero,
                chip: '${allMeds.length}',
                children: [
                  if (allMeds.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppTokens.spacingMd,
                      ),
                      child: EmptyMedicationsCard(l10n: l10n),
                    )
                  else
                    for (final med in allMeds)
                      MedicationListCell(
                        med: med,
                        onTap: () =>
                            context.push('/medication/detail/${med.id}'),
                      ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: LoadingSpinner()),
        // v0.32 round 8 (R111 EM-15 fix): inline Text error → ErrorState
        error: (e, _) => ErrorState(title: '$e'),
      ),
    );
  }

  /// 顶部 4 tile 计数 helper
  /// v0.32 R109: 透传 calculator, 行为 100% 一致
  int _pendingCount(Map<MedicationTimeSlot, List<_SlotEntry>> slots) {
    final allEntries = slots.values.expand((e) => e);
    return MedicationPageStatsCalculator.pendingCount(allEntries);
  }

  int _takenCount(Map<MedicationTimeSlot, List<_SlotEntry>> slots) {
    final allEntries = slots.values.expand((e) => e);
    return MedicationPageStatsCalculator.takenCount(allEntries);
  }

  /// 续方提醒数: 处于 inWindow 或 overdue 状态的药物数
  /// v0.32 R109: 透传 calculator
  int _refillAlertCount(List<MedicationEntity> meds) =>
      MedicationPageStatsCalculator.refillAlertCount(meds);

  /// 按时间段分组服药条目
  ///
  /// v0.32 R109: 透传 calculator 静态方法, 行为跟原 47L 实现 100% 一致
  Map<MedicationTimeSlot, List<_SlotEntry>> _buildTimeSlots(
    List<MedicationEntity> meds,
    List<CheckInEntity>? checkIns,
    DateTime now,
  ) {
    final result = MedicationPageStatsCalculator.buildTimeSlots(
      meds,
      checkIns,
      now,
    );
    // 转 Map<MedicationTimeSlot, List<_SlotEntry>> (类型别名 _SlotEntry = MedicationSlotEntry)
    return result;
  }

  /// 按时间段生成 AppleListSection
  List<Widget> _buildSlotSections(
    BuildContext context,
    Map<MedicationTimeSlot, List<_SlotEntry>> slots,
    AppLocalizations l10n,
    WidgetRef ref,
  ) {
    return [
      for (final slot in MedicationTimeSlot.all)
        if (slots[slot] != null)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.spacingMd),
            child: AppleListSection(
              title: _slotLabel(slot, l10n), // "早上" / "下午" / etc
              margin: EdgeInsets.zero,
              chip:
                  '${slots[slot]!.where((e) => e.done).length}/${slots[slot]!.length}',
              children: [
                for (final e in slots[slot]!) MedicationSlotEntryRow(entry: e),
              ],
            ),
          ),
    ];
  }

  /// v0.32 R109: 透传 calculator slotLabel, 4 个 l10n getter 注入
  String _slotLabel(MedicationTimeSlot slot, AppLocalizations l10n) =>
      MedicationPageStatsCalculator.slotLabel(
        slot: slot,
        morningLabel: l10n.medSlotMorning,
        afternoonLabel: l10n.medSlotAfternoon,
        eveningLabel: l10n.medSlotEvening,
        bedtimeLabel: l10n.medSlotBedtime,
      );
}

// v0.32 R109 (god class 拆 round 3): 删 2 个 private 空态 widget
//   (`_EmptyMedicationsCard` / `_EmptyScheduleCard`), 移到
//   `widgets/medication_empty_state_cards.dart` 公开 class (EmptyMedicationsCard
//   / EmptyScheduleCard), caller 改 import 公开类. emil DRY 跟 R31 R108
//   子 widget 抽模式一致.
//
// v1.1.0 R116 (god class 拆 round 3): _SlotEntryRow (92L) 拆到
//   widgets/medication_slot_entry_row.dart, 本文件瘦身 380L → ~280L.
