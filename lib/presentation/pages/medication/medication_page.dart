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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_slot_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/medication/widgets/medication_pill_icon.dart';
import 'package:chroniccare/presentation/providers/check_in_notifier.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_health_tile.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// v0.30 R108 (P1 medication_page 拆): 抽到 domain 后, presentation 层只
/// 负责 [MedicationTimeSlot.name] → icon + l10n label 的映射。
///
/// 集中放这避免 _TimeSlotCard 内部散落 switch, 跟 R97 emil token 化
/// 模式一致 (集中器去散落)。
///
/// R32 (N-10 警告): _slotIcon 0 caller (R108 P1 拆解漏删), 删

/// 一个时间段内的服药条目
class _SlotEntry {
  final MedicationEntity med;
  final HourMinute time;
  final bool done;
  const _SlotEntry({
    required this.med,
    required this.time,
    required this.done,
  });
}

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
                foregroundColor: Colors.white,
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
                    // 已服 (medication 红, "已服" 计数)
                    AppleHealthTile(
                      metricId: 'medication',
                      label: l10n.medTodayTaken, // "已服"
                      value: '${_takenCount(slots)}',
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    // 续方提醒 (medication 红, "需续方" 计数)
                    AppleHealthTile(
                      metricId: 'medication',
                      label: l10n.medTodayRefill, // "需续方"
                      value: '${_refillAlertCount(meds)}',
                      onTap: () => context.push('/settings/refills'),
                    ),
                    const SizedBox(width: AppTokens.spacingSm),
                    // 用药日历 (medication 红, "日历" 入口)
                    AppleHealthTile(
                      metricId: 'medication',
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
                _EmptyScheduleCard(l10n: l10n)
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
                      child: _EmptyMedicationsCard(l10n: l10n),
                    )
                  else
                    for (final med in allMeds)
                      _MedicationListCell(
                        med: med,
                        onTap: () => context.push('/medication/detail/${med.id}'),
                      ),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
      ),
    );
  }

  /// 顶部 4 tile 计数 helper
  int _pendingCount(Map<MedicationTimeSlot, List<_SlotEntry>> slots) {
    var pending = 0;
    for (final entries in slots.values) {
      pending += entries.where((e) => !e.done).length;
    }
    return pending;
  }

  int _takenCount(Map<MedicationTimeSlot, List<_SlotEntry>> slots) {
    var taken = 0;
    for (final entries in slots.values) {
      taken += entries.where((e) => e.done).length;
    }
    return taken;
  }

  /// 续方提醒数: 处于 inWindow 或 overdue 状态的药物数
  int _refillAlertCount(List<MedicationEntity> meds) {
    final now = DateTime.now();
    return meds
        .where((m) => m.hasRefill && (m.isInRefillWindow(now) || m.isRefillOverdue(now)))
        .length;
  }

  /// 按时间段分组服药条目
  ///
  /// v0.30 R108 (P1 medication_page 拆): 改用 [MedicationTimeSlot.all]
  /// 遍历 + [MedicationTimeSlot.contains] 判定, 跟原 _TimeSlot.values
  /// 行为 1:1 一致 (保持 4 时段固定顺序: morning → afternoon → evening
  /// → bedtime)。
  Map<MedicationTimeSlot, List<_SlotEntry>> _buildTimeSlots(
    List<MedicationEntity> meds,
    List<CheckInEntity>? checkIns,
    DateTime now,
  ) {
    // 收集今天已打卡的 medId
    final doneMedIds = <int>{};
    if (checkIns != null) {
      for (final c in checkIns) {
        if (!c.isNormal) continue;
        if (c.timestamp.year == now.year &&
            c.timestamp.month == now.month &&
            c.timestamp.day == now.day) {
          if (c.medicationId != null) doneMedIds.add(c.medicationId!);
        }
      }
    }

    // 展平所有 med × time
    final allEntries = <_SlotEntry>[];
    for (final m in meds) {
      for (final t in m.times) {
        allEntries.add(
          _SlotEntry(
            med: m,
            time: t,
            done: doneMedIds.contains(m.id),
          ),
        );
      }
    }

    // 按时间段分组
    final result = <MedicationTimeSlot, List<_SlotEntry>>{};
    for (final slot in MedicationTimeSlot.all) {
      final slotEntries =
          allEntries.where((e) => slot.contains(e.time.hour)).toList()
            ..sort((a, b) {
              final c = a.time.hour.compareTo(b.time.hour);
              return c != 0 ? c : a.time.minute.compareTo(b.time.minute);
            });
      if (slotEntries.isNotEmpty) {
        result[slot] = slotEntries;
      }
    }
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
              chip: '${slots[slot]!.where((e) => e.done).length}/${slots[slot]!.length}',
              children: [
                for (final e in slots[slot]!) _SlotEntryRow(entry: e),
              ],
            ),
          ),
    ];
  }

  String _slotLabel(MedicationTimeSlot slot, AppLocalizations l10n) {
    // 跟 [MedicationTimeSlot.name] 一一对应 (R108 P1 拆)
    switch (slot.name) {
      case 'morning':
        return l10n.medSlotMorning;
      case 'afternoon':
        return l10n.medSlotAfternoon;
      case 'evening':
        return l10n.medSlotEvening;
      case 'bedtime':
        return l10n.medSlotBedtime;
      default:
        return slot.name; // fallback (防止新增 slot 名称未对应)
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════

/// 时间段内的单条药物 — 支持直接打卡
class _SlotEntryRow extends ConsumerWidget {
  const _SlotEntryRow({required this.entry});
  final _SlotEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = entry;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          MedicationPillIcon(
            colorIndex: e.med.colorIndex,
            size: 32,
            initial: e.med.name,
          ),
          const SizedBox(width: AppTokens.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.med.name,
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textPrimaryColor(context),
                  ),
                ),
                Text(
                  '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')} · '
                  '${e.med.dosage}${e.med.dosageUnit.id}',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
          ),
          // 直接打卡按钮 (参照 Apple Health Medications checkbox)
          GestureDetector(
            onTap: e.done
                ? null
                : () async {
                    await ref
                        .read(checkInNotifierProvider.notifier)
                        .checkIn(medicationId: e.med.id);
                    await Haptics.success();
                  },
            child: AnimatedSwitcher(
              duration: AppTokens.durFast,
              child: Icon(
                e.done
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                key: ValueKey(e.done),
                size: 28,
                color: e.done
                    ? AppTokens.primaryColor(context)
                    : AppTokens.textHintColor(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 我的药物 list cell (AppleListSection 内部用)
class _MedicationListCell extends StatelessWidget {
  const _MedicationListCell({required this.med, required this.onTap});
  final MedicationEntity med;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PressFeedback(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingXxs),
        child: Row(
          children: [
            MedicationPillIcon(
              colorIndex: med.colorIndex,
              size: 36,
              initial: med.name,
            ),
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    med.name,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeBody,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textPrimaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${med.dosage}${med.dosageUnit.id}  ·  '
                    '${med.times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: AppTokens.textHintColor(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppTokens.spacingXs),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.spacingXs,
                vertical: AppTokens.spacingXxxs,
              ),
              decoration: BoxDecoration(
                color: med.isInUse
                    ? AppTokens.tintedSuccessSoft(context)
                    : AppTokens.dividerColor(context),
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Text(
                med.isInUse
                    ? l10n.medicationStatusInUse
                    : l10n.medicationStatusStopped,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeCaptionSm,
                  fontWeight: FontWeight.w600,
                  color: med.isInUse
                      ? AppColors.success
                      : AppTokens.textHintColor(context),
                ),
              ),
            ),
            const SizedBox(width: AppTokens.spacingXxs),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: AppTokens.textHintColor(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// 空态：无药物
class _EmptyMedicationsCard extends StatelessWidget {
  const _EmptyMedicationsCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingMd),
      child: Column(
        children: [
          Icon(
            Icons.medication_outlined,
            size: 48,
            color: AppTokens.textHintColor(context),
          ),
          const SizedBox(height: AppTokens.spacingSm),
          Text(
            l10n.medEmptyTitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w600,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          Text(
            l10n.medEmptySubtitle,
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

/// 空态：无今日计划
class _EmptyScheduleCard extends StatelessWidget {
  const _EmptyScheduleCard({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return AppleListSection(
      title: l10n.medTodaySchedule,
      margin: EdgeInsets.zero,
      children: [
        Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 28,
              color: AppTokens.textHintColor(context),
            ),
            const SizedBox(width: AppTokens.spacingSm),
            Expanded(
              child: Text(
                l10n.medNoScheduleToday,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeBodySm,
                  color: AppTokens.textHintColor(context),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
