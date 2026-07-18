// v0.17 round 7 (B1 + B2 合并): CalendarWindowNotifier
//
// 把 medication_calendar_page 的 _days setState 状态提到 Notifier:
// - 跨 page 共享(未来"设置"也能调窗口)
// - test 直接覆盖 provider (no widget pump)
// - 演示 Riverpod 3 Notifier 统一 API + ref.mounted 用法
//
// ref.mounted vs widget.mounted:
// - widget !mounted: widget 已经被 dispose
// - ref.mounted: Notifier 还在被 watch (有 listener)
// - 两者语义不同,但 setState 状态提到 Notifier 后,Notifier 不再
//   关心 widget 生命周期 — ref.mounted 防止 Notifier 在无 listener
//   时还写 state(避免 rebuild 浪费)
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用药日历的"时间窗口" (7/30/90 天)
// 默认 30,跟 widget 之前 setState 初始值一致
class CalendarWindowNotifier extends Notifier<int> {
  @override
  int build() => 30;

  /// 设窗口大小,只接受 7/30/90 之一
  void setDays(int days) {
    if (!ref.mounted) return; // Notifier 已 dispose,跳过
    if (days != 7 && days != 30 && days != 90) {
      throw ArgumentError('days must be 7, 30, or 90; got: $days');
    }
    if (state == days) return; // dedup
    state = days;
  }
}

/// Provider 入口
final calendarWindowProvider =
    NotifierProvider<CalendarWindowNotifier, int>(CalendarWindowNotifier.new);
