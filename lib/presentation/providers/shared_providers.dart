import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/entities/check_in_entity.dart';
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/domain/entities/mood_entry_entity.dart';
import 'package:chroniccare/domain/entities/report_history_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';
import 'package:chroniccare/domain/logic/streak_calculator.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// 用户档案（v0.16: domain entity, no longer Drift row）
///
/// v0.21 Round 22 (P1-16 修复): 加 autoDispose — 离开设置页时取消 stream,
/// 减少 background DB watch。re-fetch 在用户回到设置页时触发,DB indexed query
/// < 50ms 不可感知。
final userProfileProvider = StreamProvider.autoDispose<UserProfileEntity?>(
  (ref) => ref.watch(userProfileRepositoryProvider).watch(),
);

/// 今天的打卡
final todayCheckInProvider = StreamProvider.autoDispose<CheckInEntity?>(
  (ref) => ref.watch(checkInRepositoryProvider).watchToday(),
);

/// 所有打卡（含 normal + temp + phq9 + gad7），用于趋势图
final allCheckInsProvider = StreamProvider.autoDispose<List<CheckInEntity>>(
  (ref) => ref.watch(checkInRepositoryProvider).watchAll(),
);

/// 所有 normal 类型打卡（用于计算 streak）
/// P0 fix: DB 级 WHERE type='normal'，不再全表扫描+Dart 过滤
final allNormalCheckInsProvider =
    StreamProvider.autoDispose<List<CheckInEntity>>(
  (ref) => ref.watch(checkInRepositoryProvider).watchNormalCheckIns(),
);

/// 当前 streak + 是否断签（B8 fix: 在 build 顶部算一次）
///
/// 之前 home_page 在 build 里调 [StreakCalculator.calculate] 3 次
/// （鼓励文案 / 打卡按钮 / 是否断签），跨 23:59:59 时 streak 不一致。
/// 提到 provider 后用 const now 注入，所有 widget 看到的是同一个值。
class StreakSnapshot {
  final int streak;
  final bool shouldShowStreakBroken;
  const StreakSnapshot({
    required this.streak,
    required this.shouldShowStreakBroken,
  });
}

final streakSummaryProvider = Provider<AsyncValue<StreakSnapshot>>((ref) {
  final async = ref.watch(allNormalCheckInsProvider);
  return async.whenData((checkIns) {
    final now = DateTime.now();
    return StreakSnapshot(
      streak: StreakCalculator.calculate(checkIns: checkIns, now: now),
      shouldShowStreakBroken: StreakCalculator.shouldShowStreakBroken(
        checkIns: checkIns,
        now: now,
      ),
    );
  });
});

/// 联系人列表
final contactsProvider = StreamProvider.autoDispose<List<ContactEntity>>(
  (ref) => ref.watch(contactRepositoryProvider).watchAll(),
);

/// 吃药列表（v0.13 Round 11: 返回 MedicationEntity，不直接暴露 Drift row）
final medicationsProvider = StreamProvider.autoDispose<List<MedicationEntity>>(
  (ref) => ref.watch(medicationRepositoryProvider).watchAll(),
);

/// 所有 medication 列表（含已停药，给"用药报告"用）
///
/// 历史用药可能在窗口内有打卡记录，但 medication.isActive=false，
/// 报告必须包含这些数据才能完整还原用户服药历史。（B3 fix）
final allMedicationsProvider =
    StreamProvider.autoDispose<List<MedicationEntity>>(
  (ref) {
    final repo = ref.watch(medicationRepositoryProvider);
    // v0.16: 新增 watchAllIncludingInactive() abstract method
    return repo.watchAllIncludingInactive();
  },
);

/// 所有评估记录（PHQ-9 / GAD-7，按时间正序）
final assessmentsProvider = StreamProvider.autoDispose<List<CheckInEntity>>(
  (ref) => ref.watch(checkInRepositoryProvider).watchAssessments(),
);

/// 报告历史（按生成时间倒序）— v0.16: 用 domain entity
final reportHistoriesProvider =
    StreamProvider.autoDispose<List<ReportHistoryEntity>>(
  (ref) => ref.watch(reportHistoryRepositoryProvider).watchAll(),
);

/// 今日情绪记录
final todayMoodProvider = StreamProvider.autoDispose<List<MoodEntryEntity>>(
  (ref) => ref.watch(moodRepositoryProvider).watchToday(),
);

/// 所有情绪记录
final allMoodProvider = StreamProvider.autoDispose<List<MoodEntryEntity>>(
  (ref) => ref.watch(moodRepositoryProvider).watchAll(),
);

/// v0.21 (P0-6 fix): "今天已变更" tick provider
///
/// **bug 现象**: 之前 widget 跨 midnight 不自动 rebuild ——
/// `medication_calendar_page` 跟 `trend_calendar` 用 `DateTime.now()` 算
/// "今天" / "窗口起算日",但 widget 没在跨 midnight 时触发新 build,
/// 导致格子不刷新、calendar 起算日还是"昨天"。
///
/// **修法**: AppRoot 在两个时机递增这个 tick:
/// 1. 跨 midnight timer 到点 (00:00:05 触发)
/// 2. app 从后台回前台时发现 [crossedMidnightSince]
///
/// 所有关心"今天是哪天"的 widget watch 这个 provider 就能在跨日时
/// 自动 rebuild。语义明确 (不依赖 streakSummary 跨日副作用)。
class DayChangeTickNotifier extends Notifier<int> {
  @override
  int build() => 0;

  /// 跨日时由 AppRoot 调用,递增 tick 触发所有 watch 的 widget rebuild
  void tick() {
    if (!ref.mounted) return;
    state = state + 1;
  }
}

final dayChangeTickProvider =
    NotifierProvider<DayChangeTickNotifier, int>(DayChangeTickNotifier.new);
