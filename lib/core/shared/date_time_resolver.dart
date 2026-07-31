// v0.27 round 67 (C-1 重构): `_resolveTimestamp` 公开集中器
//
// 背景: R63 P1-6 抽了 file-private helper `DateTime _resolveTimestamp(DateTime? at)
//       => at ?? DateTime.now();` 在 check_in_repository_impl.dart:22, 但只是
//       file-private。4 处同款 pattern 散落:
//       - vent_repository_impl.dart:94       `at ?? DateTime.now()`
//       - mood_repository_impl.dart:41       `draft.at ?? DateTime.now()`
//       - medication_repository_impl.dart:49 `draft.startDate ?? DateTime.now()`
//       - check_in_usecases.dart:41          `final time = at ?? DateTime.now();`
//
// 抽到 core/shared 公开集中器, 防止未来 caller 复用时再写错, 也符合 R19B
// "DateTime race" 纪律: 函数入口 1 次取 DateTime.now(), 不要散落多次。

/// 解析"用户传入的时间"或"当前时间"为本地时间戳
///
/// 用法: `final ts = DateTimeResolvers.at(at);`
///
/// 行为:
/// - 如果 [at] 非 null, 返 [at] (原值, 不做时区转换)
/// - 如果 [at] 为 null, 返 [DateTime.now()] (本地时区当前时间)
///
/// 设计目的:
/// - 防止 `at ?? DateTime.now()` 散落 (R19B 跨函数多次调 DateTime.now() race)
/// - 集中器有 1 个 entry point, 未来加埋点 / 转换 tz 都在 1 处改
/// - 静态方法 + 私有构造, 不允许实例化
class DateTimeResolvers {
  // 私有构造, 防止实例化 (跟 `Collections` / `Durations` 等 Dart 标准库风格一致)
  DateTimeResolvers._();

  /// 解析 [at], 非 null 直接返回, null 则取当前本地时间
  static DateTime at(DateTime? at) {
    if (at != null) return at;
    return DateTime.now();
  }
}
