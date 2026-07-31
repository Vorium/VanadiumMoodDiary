// v0.23 round 41 (spen P3-35): reminders_hub_page 改用 FutureProvider
//
// 之前 4 个 nullable 字段 + initState _load + setState 异步填值
// 改成 watch remindersHubConfigProvider, 异步值自动 rebuild + 共享给 sheet
//
// 跟 v0.17 round 7 calendarWindowProvider 模式一致

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/providers/service_providers.dart';

/// reminders hub 配置 (assessment + safety)
class RemindersHubConfig {
  final bool assessmentEnabled;
  final int assessmentDays;
  final bool safetyEnabled;
  final int safetyThreshold;

  const RemindersHubConfig({
    required this.assessmentEnabled,
    required this.assessmentDays,
    required this.safetyEnabled,
    required this.safetyThreshold,
  });
}

/// FutureProvider — 异步加载 assessment + safety 配置
///
/// 失败 / 未加载完时返 fallback 默认值,跟 widget 兼容
///
/// v0.27 round 61 (P1-12 god class 拆分收尾): 改用 `safetyConfigServiceProvider`
/// 直接读 SharedPreferences, 不再走 `safetyWatchServiceProvider` facade。
/// `safetyWatchServiceProvider` 是 facade 只留触发入口 (`onAppStart` / `onCheckIn`
/// / `checkNow`), 配置 API 走 sub-service 集中器。
final remindersHubConfigProvider =
    FutureProvider.autoDispose<RemindersHubConfig>((ref) async {
  final assess = ref.watch(assessmentReminderServiceProvider);
  final safetyConfig = ref.watch(safetyConfigServiceProvider);
  final aEnabled = await assess.isEnabled();
  final aDays = await assess.getDays();
  final sEnabled = await safetyConfig.isEnabled();
  final sThreshold = await safetyConfig.getThresholdDays();
  return RemindersHubConfig(
    assessmentEnabled: aEnabled,
    assessmentDays: aDays,
    safetyEnabled: sEnabled,
    safetyThreshold: sThreshold,
  );
});
