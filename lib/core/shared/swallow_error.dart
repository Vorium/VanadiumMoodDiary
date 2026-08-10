import 'dart:developer' as developer;

/// v0.17 round 14 (P1-5): 把"静默 catch"统一成可观测的 swallow
///
/// 解决的问题:
/// 之前 9 处 `} catch (_) {}` 完全吞错，出 bug 时排查没线索。改成:
///   1. 走 developer.log,kDebugMode 守卫 → dev 模式能看见
///   2. 集中位置: 出错位置 + 失败原因 + 是否影响主流程，看 log 一目了然
///
/// 用法:
/// ```dart
/// try {
///   await ref.read(notificationServiceProvider).cancelAllSnoozes();
/// } catch (e, st) {
///   swallowError(
///     where: 'home_page._onCheckIn',
///     error: e,
///     stack: st,
///     note: '通知清理失败不影响主流程，重试下次打卡',
///   );
/// }
/// ```
///
/// 不会:
/// - 抛 → 失败路径不向上传播
/// - 阻塞 → fire-and-forget,调用方继续
/// - 静默 → dev 模式 devtools / `flutter logs` 看得到

// release 模式下为 true，debug/profile 为 false（替代 kDebugMode，无 Flutter 依赖）
const bool _isProduct =
    bool.fromEnvironment('dart.vm.product', defaultValue: false);

/// P2-19 (2026-08-09): 并发安全说明
///
/// 本函数是无状态纯函数（stateless pure function），不持有任何可变队列
/// 或共享可变状态。Dart 单线程事件循环模型保证同一 isolate 内不会出现
/// 并发写入问题，因此无需额外的锁或队列保护。
void swallowError({
  required String where,
  required Object error,
  StackTrace? stack,
  String? note,
}) {
  if (!_isProduct) {
    developer.log(
      note == null ? '$where failed' : '$where failed: $note',
      name: 'swallow',
      error: error,
      stackTrace: stack,
    );
  }
}
