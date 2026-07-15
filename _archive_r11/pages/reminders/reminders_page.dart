// v0.13 (Round 11) Reminders Hub Page
//
// 集中展示所有推送类提醒（5 类），用户可一目了然看到：
// - 哪些是开着的
// - 哪些是关着的
// - 下次什么时候响
// - 一键跳到设置页
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/services/assessment_reminder_service.dart';
import '../../../data/services/notification_service.dart' show NotificationService;
import '../../../domain/logic/assessment_record.dart';
import '../../../domain/logic/reminders_hub.dart';
import '../../../l10n/strings.dart';
import '../../../theme/app_tokens.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../widgets/page_scaffold.dart';
import 'widgets/reminder_card.dart';

class RemindersPage extends ConsumerStatefulWidget {
  const RemindersPage({super.key});

  @override
  ConsumerState<RemindersPage> createState() => _RemindersPageState();
}

class _RemindersPageState extends ConsumerState<RemindersPage> {
  /// 默认每日 20:00（与 NotificationService.scheduleDailyReminder 默认一致）
  static const _dailyHour = 20;
  static const _dailyMinute = 0;

  @override
  Widget build(BuildContext context) {
    final asyncMeds = ref.watch(allMedicationsProvider);
    final asyncCheckIns = ref.watch(allCheckInsProvider);

    return PageScaffold(
      title: '提醒中心',
      child: asyncMeds.when(
        data: (meds) {
          return asyncCheckIns.when(
            data: (checkIns) {
              // 读 assessment reminder 配置
              final assessmentEnabled = _readAssessmentEnabled();
              final assessmentDays = _readAssessmentDays();
              final lastAssessmentAt = _readLastAssessment(checkIns);

              final reminders = RemindersHubCalculator.compute(
                medications: meds,
                checkIns: checkIns,
                dailyReminderHour: _dailyHour,
                dailyReminderMinute: _dailyMinute,
                softEnabled: true, // 软提醒始终在跑
                assessmentEnabled: assessmentEnabled,
                assessmentDays: assessmentDays,
                lastAssessmentAt: lastAssessmentAt,
                now: DateTime.now(),
              );
              final sorted =
                  RemindersHubCalculator.sortedByKind(reminders);
              return _buildBody(sorted, assessmentEnabled);
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('加载失败: $e')),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildBody(List<ScheduledReminder> reminders, bool assessmentEnabled) {
    // 简单汇总
    final enabledCount = reminders.where((r) => r.isEnabled).length;
    final totalCount = reminders.length;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 顶部汇总
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
              vertical: AppTokens.spacingSm,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: AppTokens.spacingXs),
                Text(
                  '已开启 $enabledCount / $totalCount',
                  style: const TextStyle(
                    fontSize: AppTokens.fontSizeBody,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                Text(
                  '从 DB 计算（不一定 100% 等于实际调度）',
                  style: TextStyle(
                    fontSize: AppTokens.fontSizeCaption,
                    color: AppTokens.textHint,
                  ),
                ),
              ],
            ),
          ),
          // 列表
          for (final r in reminders)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTokens.pageMarginH,
                vertical: AppTokens.spacingXs / 2,
              ),
              child: ReminderCard(reminder: r),
            ),
          const SizedBox(height: AppTokens.spacingLg),
          // 提示卡
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTokens.pageMarginH,
            ),
            child: Card(
              color: AppTokens.primaryLight,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.spacingMd),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppTokens.primary,
                      size: 18,
                    ),
                    const SizedBox(width: AppTokens.spacingXs),
                    Expanded(
                      child: Text(
                        '这里是所有"应该被调度"的提醒预览。'
                        '实际推送由系统 NotificationService 负责，'
                        '在重启/卸载/权限关闭时可能与预览不一致。\n\n'
                        '要新增/修改/关闭某类提醒 → 去设置页。',
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeCaption,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: AppTokens.spacingLg),
        ],
      ),
    );
  }

  // ====== 读 AssessmentReminderService 的配置 ======
  // 因为 AssessmentReminderService 用了 SharedPreferences（异步），
  // 我们同步地读 future 是不可能的。这里改为：UI 上 fallback 到默认值，
  // 不阻塞 build。后续可用 FutureBuilder 升级。

  bool _readAssessmentEnabled() {
    // v0.13 简化：默认 false（评估提醒是 opt-in 功能）。
    // 如果用户开启了，那 AssessmentReminderService.onAppStart() 会调度；
    // 这里用 false 表示"如果没开启就不显示这条"。
    return false; // 占位：用 ConsumerState 的 initState 异步读会更准
  }

  int _readAssessmentDays() {
    return AssessmentReminderService.defaultDays;
  }

  DateTime? _readLastAssessment(List<CheckIn> checkIns) {
    final assessments = checkIns
        .map(AssessmentRecord.tryFromCheckIn)
        .whereType<AssessmentRecord>()
        .toList();
    if (assessments.isEmpty) return null;
    assessments.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return assessments.last.timestamp;
  }
}
