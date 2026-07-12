import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core_providers.dart';

/// 打卡操作 Notifier
class CheckInNotifier extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  /// 打卡（normal）
  Future<void> checkIn() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(checkInRepositoryProvider).checkIn();
    });
  }

  /// 添加临时吃药
  Future<void> addTempMedication({
    required String name,
    required String note,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(checkInRepositoryProvider).addTempMedication(
            name: name,
            note: note,
          );
    });
  }

  /// 手动触发失联检测（调试用）
  Future<bool> triggerReminder() async {
    state = const AsyncValue.loading();
    try {
      final sent = await ref.read(reminderServiceProvider).checkAndSend();
      state = const AsyncValue.data(null);
      return sent;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final checkInNotifierProvider =
    NotifierProvider<CheckInNotifier, AsyncValue<void>>(CheckInNotifier.new);
