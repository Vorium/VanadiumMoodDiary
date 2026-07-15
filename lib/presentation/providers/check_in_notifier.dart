// v0.14 (Round 12B) CheckInNotifier — 调 UseCase
//
// 4 层架构：Notifier 只负责 UI state，business logic 走 domain/use case
// - RecordCheckInUseCase        每日打卡
// - RecordTempMedicationUseCase  临时吃药
// - TriggerReminderUseCase       触发失联检测
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/usecases/check_in_usecases.dart';
import 'core_providers.dart';

/// 打卡操作 Notifier
class CheckInNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// 每日打卡
  ///
  /// v0.11 (Round 5): [medicationId] 用于 deep linking 通知 → 自动打卡该药
  /// v0.14 (Round 12B): 委托给 RecordCheckInUseCase
  Future<void> checkIn({int? medicationId}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(recordCheckInUseCaseProvider);
      await useCase(medicationId: medicationId);
    });
  }

  /// 临时吃药
  Future<void> addTempMedication({
    required String name,
    required String note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(recordTempMedicationUseCaseProvider);
      await useCase(name: name, note: note);
    });
  }

  /// 手动触发失联检测（调试用）
  ///
  /// 返回 true = 通知已发送，false = 跳过了（未到时间或没联系人）
  Future<bool> triggerReminder() async {
    state = const AsyncValue.loading();
    try {
      final useCase = ref.read(triggerReminderUseCaseProvider);
      final result = await useCase();
      state = const AsyncValue.data(null);
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final checkInNotifierProvider =
    NotifierProvider<CheckInNotifier, AsyncValue<void>>(CheckInNotifier.new);

/// v0.14 (Round 12B) UseCase providers — 4 层架构
///
/// 在 Riverpod tree 里组装 UseCase + Repository 依赖。
/// UI（Notifier）只拿 use case，不直接拿 repository。
final recordCheckInUseCaseProvider = Provider<RecordCheckInUseCase>(
  (ref) => RecordCheckInUseCase(ref.watch(checkInRepositoryProvider)),
);

final recordTempMedicationUseCaseProvider =
    Provider<RecordTempMedicationUseCase>(
  (ref) => RecordTempMedicationUseCase(ref.watch(checkInRepositoryProvider)),
);

final triggerReminderUseCaseProvider = Provider<TriggerReminderUseCase>(
  (ref) => TriggerReminderUseCase(ref.watch(reminderServiceProvider)),
);
