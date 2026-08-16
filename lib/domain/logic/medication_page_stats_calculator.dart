// v0.32 R109 (god class 拆 round 3): 抽 MedicationPageStatsCalculator 纯函数
//
// 改前: `medication_page.dart` 552L god class, 内嵌 3 个 helper:
//   - `_buildTimeSlots` (47L) 算 4 时段分组
//   - `_pendingCount` / `_takenCount` / `_refillAlertCount` (3×7L) 算 4 tile 计数
//   - `_slotLabel` (15L) MedicationTimeSlot → l10n label
//   这 5 个 helper 共 ~80L 散落 page, 跟 UI 渲染混.
// 改后: 抽到 `domain/logic/medication_page_stats_calculator.dart` 纯函数类,
//   UI page 只负责 widget 渲染. 跟 R108 抽 `medication_slot_calculator.dart`
//   同款 (P1 medication_page 拆).
//
// 4 层架构: domain/logic/ 放 0 副作用 0 Flutter 0 Drift 0 service 调
//   的纯函数, AGENTS.md 必读.

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/hour_minute.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/logic/medication_slot_calculator.dart';

/// 用药主页统计计算器 (R109 抽纯函数集中器)
///
/// 改前 5 个散落 helper 集中到 1 个纯函数类:
/// - `buildTimeSlots` (47L) 4 时段分组 (早/午/晚/睡前)
/// - `pendingCount` / `takenCount` (2×7L) 顶部 tile 计数
/// - `refillAlertCount` (7L) 续方提醒计数
/// - `slotLabel` (15L) MedicationTimeSlot → l10n label
///
/// 0 副作用 0 Flutter: 不调 repo, 不读 prefs, 不调 plugin.
/// 字段计算跟 UI 渲染分离, 易单测 + 易复用 (未来 mood_page 也能用).
class MedicationPageStatsCalculator {
  // 不可实例化 — 纯函数类
  const MedicationPageStatsCalculator._();

  /// 单个时段内的服药条目 (R108 P1 拆原位)
  ///
  /// 公开是因为 `MedicationPage` build() 渲染时仍要拿 `_SlotEntry`
  /// (med + time + done) 数据. 跟 R108 抽到 `domain/logic/` 同款.
  /// (跨层 private 不可见问题: presentation 拿这个 entry 渲染用.)
  static Map<MedicationTimeSlot, List<MedicationSlotEntry>> buildTimeSlots(
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
    final allEntries = <MedicationSlotEntry>[];
    for (final m in meds) {
      for (final t in m.times) {
        allEntries.add(
          MedicationSlotEntry(
            med: m,
            time: t,
            done: doneMedIds.contains(m.id),
          ),
        );
      }
    }

    // 按时间段分组 (跟 R108 P1 拆原版 1:1 一致)
    final result = <MedicationTimeSlot, List<MedicationSlotEntry>>{};
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

  /// 顶部 tile "今日待服" 计数
  static int pendingCount(Iterable<MedicationSlotEntry> entries) =>
      entries.where((e) => !e.done).length;

  /// 顶部 tile "今日已服" 计数
  static int takenCount(Iterable<MedicationSlotEntry> entries) =>
      entries.where((e) => e.done).length;

  /// 顶部 tile "需续方" 计数 (处于 inWindow 或 overdue 状态的药物数)
  static int refillAlertCount(List<MedicationEntity> meds) {
    final now = DateTime.now();
    return meds
        .where(
          (m) =>
              m.hasRefill &&
              (m.isInRefillWindow(now) || m.isRefillOverdue(now)),
        )
        .length;
  }

  /// MedicationTimeSlot → l10n label (跨 4 时段)
  ///
  /// 接受 4 个 String getter 作参数 (R109 抽象 l10n 模式: tear-off
  /// 闭包 / String getter 注入, use case 跟 logic 0 l10n import).
  static String slotLabel({
    required MedicationTimeSlot slot,
    required String morningLabel,
    required String afternoonLabel,
    required String eveningLabel,
    required String bedtimeLabel,
  }) {
    switch (slot.name) {
      case 'morning':
        return morningLabel;
      case 'afternoon':
        return afternoonLabel;
      case 'evening':
        return eveningLabel;
      case 'bedtime':
        return bedtimeLabel;
      default:
        return slot.name; // fallback (防止新增 slot 名称未对应)
    }
  }
}

/// 单个时段内的服药条目
///
/// v0.32 R109: 抽到 `domain/logic/`, presentation 渲染时拿这个数据.
/// 跟 `_SlotEntry` (presentation 私有) 1:1 对应, 公开化.
class MedicationSlotEntry {
  final MedicationEntity med;
  final HourMinute time;
  final bool done;
  const MedicationSlotEntry({
    required this.med,
    required this.time,
    required this.done,
  });
}
