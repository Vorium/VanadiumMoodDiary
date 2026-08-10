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
import 'package:chroniccare/presentation/widgets/feedback.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// v0.30 R108 (P1 medication_page 拆): 抽到 domain 后, presentation 层只
/// 负责 [MedicationTimeSlot.name] → icon + l10n label 的映射。
///
/// 集中放这避免 _TimeSlotCard 内部散落 switch, 跟 R97 emil token 化
/// 模式一致 (集中器去散落)。
IconData _slotIcon(String name) {
  switch (name) {
    case 'morning':
      return Icons.wb_sunny_outlined;
    case 'afternoon':
      return Icons.wb_cloudy_outlined;
    case 'evening':
      return Icons.wb_twilight_outlined;
    case 'bedtime':
      return Icons.nights_stay_outlined;
    default:
      return Icons.access_time_outlined; // fallback
  }
}

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
        PressFeedback(
          child: IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: l10n.medAddTooltip,
            onPressed: () => context.push('/medication/add'),
          ),
        ),
      ],
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
              // ── 今日服药计划 ──
              _SectionHeader(
                icon: Icons.today_outlined,
                title: l10n.medTodaySchedule,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              if (activeMeds.isEmpty)
                _EmptyScheduleCard(l10n: l10n)
              else
                ...slots.entries.map(
                  (e) => _TimeSlotCard(
                    slot: e.key,
                    entries: e.value,
                    l10n: l10n,
                  ),
                ),

              const SizedBox(height: AppTokens.spacingLg),

              // ── 我的药物 ──
              _SectionHeader(
                icon: Icons.medication_outlined,
                title: l10n.medMyMedications,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              if (allMeds.isEmpty)
                _EmptyMedicationsCard(l10n: l10n)
              else
                ...allMeds.map(
                  (med) => _MedicationListCard(
                    med: med,
                    onTap: () => context.push('/medication/detail/${med.id}'),
                  ),
                ),

              const SizedBox(height: AppTokens.spacingLg),

              // ── 快捷操作 ──
              _SectionHeader(
                icon: Icons.shortcut_outlined,
                title: l10n.medQuickActions,
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.calendar_month_outlined,
                      label: l10n.medCalendar,
                      onTap: () => context.push('/medication/calendar'),
                    ),
                  ),
                  const SizedBox(width: AppTokens.spacingSm),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.inventory_2_outlined,
                      label: l10n.medRefill,
                      onTap: () => context.push('/settings/refills'),
                    ),
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
}

// ═══════════════════════════════════════════════════════════════════
// Sub-widgets
// ═══════════════════════════════════════════════════════════════════

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTokens.primaryColor(context)),
        const SizedBox(width: AppTokens.spacingXs),
        Text(
          title,
          style: TextStyle(
            fontSize: AppTokens.fontSizeBody,
            fontWeight: FontWeight.w700,
            color: AppTokens.textPrimaryColor(context),
          ),
        ),
      ],
    );
  }
}

/// 时间段卡片 (早上/下午/晚上/睡前)
class _TimeSlotCard extends StatelessWidget {
  const _TimeSlotCard({
    required this.slot,
    required this.entries,
    required this.l10n,
  });

  // v0.30 R108 (P1 medication_page 拆): 改用 [MedicationTimeSlot] (domain),
  // 不再用 _TimeSlot enum (presentation-private)。Icon 通过 [_slotIcon(name)]
  // 映射, l10n label 通过 [_slotLabel] 映射。
  final MedicationTimeSlot slot;
  final List<_SlotEntry> entries;
  final AppLocalizations l10n;

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

  @override
  Widget build(BuildContext context) {
    final done = entries.where((e) => e.done).length;
    final total = entries.length;
    final allDone = done == total;

    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 时间段标题
            Row(
              children: [
                Icon(
                  // v0.30 R108 (P1 medication_page 拆): icon 改 [_slotIcon(name)]
                  // 映射, domain MedicationTimeSlot 不持有 icon (UI 关注点)
                  _slotIcon(slot.name),
                  size: 18,
                  color: AppTokens.textSecondaryColor(context),
                ),
                const SizedBox(width: AppTokens.spacingXs),
                Text(
                  _slotLabel(slot, l10n),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeBodySm,
                    fontWeight: FontWeight.w600,
                    color: AppTokens.textPrimaryColor(context),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingXs),
                Text(
                  entries
                      .map(
                        (e) =>
                            '${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}',
                      )
                      .toSet()
                      .toList()
                      .join('  '),
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
                const Spacer(),
                Text(
                  '$done/$total',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    fontWeight: FontWeight.w600,
                    color: allDone
                        ? AppTokens.primaryColor(context)
                        : AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // 药物列表
            ...entries.map((e) => _SlotEntryRow(entry: e)),
          ],
        ),
      ),
    );
  }
}

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
                    fontSize: AppTokens.fontSizeBodySm,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.textPrimaryColor(context),
                  ),
                ),
                Text(
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

/// 我的药物卡片
class _MedicationListCard extends StatelessWidget {
  const _MedicationListCard({required this.med, required this.onTap});
  final MedicationEntity med;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return PressFeedback(
      child: Card(
        margin: const EdgeInsets.only(bottom: AppTokens.spacingXs),
        child: ListTile(
          leading: MedicationPillIcon(
            colorIndex: med.colorIndex,
            size: 36,
            initial: med.name,
          ),
          title: Text(
            med.name,
            style: const TextStyle(
              fontSize: AppTokens.fontSizeBody,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            '${med.dosage}${med.dosageUnit.id}  '
            '${med.times.map((t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}').join(', ')}',
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              color: AppTokens.textHintColor(context),
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
          onTap: onTap,
        ),
      ),
    );
  }
}

/// 快捷操作卡片
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      child: Card(
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          child: Padding(
            padding: AppTokens.edgeInsetsMd,
            child: Column(
              children: [
                Icon(icon, size: 28, color: AppTokens.primaryColor(context)),
                const SizedBox(height: AppTokens.spacingXs),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
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
    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsLg,
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
    return Card(
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 32,
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
      ),
    );
  }
}
