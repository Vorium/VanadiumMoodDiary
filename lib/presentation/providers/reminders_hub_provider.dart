// v0.23 round 41 (spen P3-35): reminders_hub_page 改用 FutureProvider
//
// 之前 4 个 nullable 字段 + initState _load + setState 异步填值
// 改成 watch remindersHubConfigProvider, 异步值自动 rebuild + 共享给 sheet
//
// 跟 v0.17 round 7 calendarWindowProvider 模式一致
//
// 1.1.0 round 4: safety 配置整摘 (失联通信业务暂停定版), config 只剩
// assessment 2 字段。

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/presentation/providers/service_providers.dart';

/// reminders hub 配置 (assessment)
class RemindersHubConfig {
  final bool assessmentEnabled;
  final int assessmentDays;

  const RemindersHubConfig({
    required this.assessmentEnabled,
    required this.assessmentDays,
  });
}

/// FutureProvider — 异步加载 assessment 配置
///
/// 失败 / 未加载完时返 fallback 默认值,跟 widget 兼容
final remindersHubConfigProvider =
    FutureProvider.autoDispose<RemindersHubConfig>((ref) async {
  final assess = ref.watch(assessmentReminderServiceProvider);
  final aEnabled = await assess.isEnabled();
  final aDays = await assess.getDays();
  return RemindersHubConfig(
    assessmentEnabled: aEnabled,
    assessmentDays: aDays,
  );
});
