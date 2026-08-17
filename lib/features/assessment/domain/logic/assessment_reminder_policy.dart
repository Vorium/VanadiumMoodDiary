// v0.31.1 R109 (god class 专项 round 1):
// 抽 AssessmentReminderPolicy 纯函数到 domain/logic
//
// 改前: `computeNextFireTime` 是 `AssessmentReminderService` 的
//   `@visibleForTesting static` 私有方法, 跟 prefs 持久化 / notification
//   调度混在 1 个 service (199L).
// 改后: 纯函数 policy 提到 domain/logic, 0 Flutter / 0 Drift / 0 service
//   依赖, 可被 use case 调, 可被 widget test 调, 可被 domain unit test 调.
//
// 4 层架构: domain/logic/ 放 0 副作用 0 Flutter 0 Drift 0 service 调
//   的纯函数, AGENTS.md 必读. 跟 `lib/domain/logic/refill_scheduler.dart`
//   同款 (R27 抽的, 模式一致).

/// 心理评估周期提醒的业务规则
///
/// R109 (god class 拆): 跟 reminder scheduler / refill scheduler 同款,
/// 把"算下次 fire time" 的业务规则从 service 抽到 domain/logic, use case
/// 和 widget test 可以直接调, 不依赖 service / Flutter / Drift.
///
/// 业务规则:
/// - enabled=false → 不调度 (返 null)
/// - 没历史评估 → 现在 + days 天 (首次装 app 后 +N 天提醒)
/// - 有历史评估 → 上次评估 + days 天
/// - 计算结果 < 现在 → 现在 + 1 小时 (catch-up, 避免一开机就立即响)
/// - 截到 10:00 (用户普遍起床活跃时段)
class AssessmentReminderPolicy {
  /// 默认提醒间隔: 14 天
  static const int defaultDays = 14;

  /// 允许的间隔选项 (settings UI 用的也是这几个)
  static const List<int> allowedDays = [7, 14, 30, 60, 90];

  /// 评估类型 ID, 跟 notification delegate 配套
  static const String defaultScaleId = 'phq9';

  /// 计算下次提醒的触发时间
  ///
  /// 参数:
  /// - [enabled] false → 返 null (不调度)
  /// - [days] 必须在 [allowedDays] 中, 否则抛 ArgumentError
  /// - [lastAssessmentAt] null → 走"首次装 app" 路径 (现在 + N 天)
  /// - [now] 注入方便测试, 默认 [DateTime.now]
  ///
  /// 返回: 下次 fire time (本地时间), 永远 ≥ [now] (catch-up 推到 +1h)
  static DateTime? computeNextFireTime({
    required bool enabled,
    required int days,
    required DateTime? lastAssessmentAt,
    DateTime? now,
  }) {
    if (!enabled) return null;
    if (!allowedDays.contains(days)) {
      throw ArgumentError('days must be in $allowedDays; got: $days');
    }
    final n = now ?? DateTime.now();
    final base = lastAssessmentAt ?? n;
    var fire = base.add(Duration(days: days));
    // 把时分秒截到 10:00 (用户普遍起床活跃时段)
    fire = DateTime(fire.year, fire.month, fire.day, 10, 0);
    if (fire.isBefore(n)) {
      // 已经过 → 推迟 1 小时 (避免开机立即响)
      fire = n.add(const Duration(hours: 1));
    }
    return fire;
  }

  /// 校验 days 是否合法
  ///
  /// 跟 [computeNextFireTime] 内部校验一致, 抽出给 caller (settings UI)
  /// 显式调, 避免 service / use case 重复写 contains 校验。
  static bool isValidDays(int days) => allowedDays.contains(days);
}
