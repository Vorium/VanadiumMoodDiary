// v0.14 (Round 12B) CheckInNotifier — 调 UseCase
//
// 4 层架构：Notifier 只负责 UI state，business logic 走 domain/use case
// - RecordCheckInUseCase        每日打卡
// - RecordTempMedicationUseCase  临时吃药
//
// 1.1.0 round 4: TriggerReminderUseCase 调试入口整摘 (失联检测不再从
// presentation 触发)。
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/domain/usecases/check_in_usecases.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';

/// 打卡操作 Notifier
class CheckInNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// 每日打卡
  ///
  /// v0.11 (Round 5): [medicationId] 用于 deep linking 通知 → 自动打卡该药
  /// v0.14 (Round 12B): 委托给 RecordCheckInUseCase
  /// v0.32 round 8 (R111 R111-03 fix): 加 [at] 参数 — 补打卡走
  ///   RecordCheckInUseCase 的注入时间 (补记过去某天)
  Future<void> checkIn({int? medicationId, DateTime? at}) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final useCase = ref.read(recordCheckInUseCaseProvider);
      await useCase(medicationId: medicationId, at: at);
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
}

final checkInNotifierProvider =
    NotifierProvider<CheckInNotifier, AsyncValue<void>>(CheckInNotifier.new);

/// v0.14 (Round 12B) UseCase providers — 4 层架构
///
/// 在 Riverpod tree 里组装 UseCase + Repository 依赖。
/// UI（Notifier）只拿 use case，不直接拿 repository。
final recordCheckInUseCaseProvider = Provider<RecordCheckInUseCase>(
  // P0-10 fix: use case 加 userProfileRepositoryProvider 依赖,
  // 让 check-in 后同步写 user_profiles.lastCheckInAt。
  (ref) => RecordCheckInUseCase(
    ref.watch(checkInRepositoryProvider),
    ref.watch(userProfileRepositoryProvider),
  ),
);

final recordTempMedicationUseCaseProvider =
    Provider<RecordTempMedicationUseCase>(
  (ref) => RecordTempMedicationUseCase(ref.watch(checkInRepositoryProvider)),
);
