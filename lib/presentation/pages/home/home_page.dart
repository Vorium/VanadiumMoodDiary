import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/database/app_database.dart';
import '../../../domain/logic/streak_calculator.dart';
import '../../../l10n/strings.dart';
import '../../../theme/app_tokens.dart';
import '../../providers/check_in_notifier.dart';
import '../../providers/data_providers.dart';
import '../../widgets/page_scaffold.dart';
import 'widgets/check_in_button.dart';
import 'widgets/last_med_info.dart';

/// 主页
class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todayCheckInProvider);
    final allNormalAsync = ref.watch(allNormalCheckInsProvider);
    final userProfileAsync = ref.watch(userProfileProvider);

    return PageScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                userProfileAsync.maybeWhen(
                  data: (profile) => '${profile?.userName ?? "我"} 还在坚持',
                  orElse: () => '慢病管家',
                ),
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeHeadline,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: () => context.push('/settings'),
                tooltip: Strings.settingsAbout,
              ),
            ],
          ),

          const Spacer(flex: 2),

          // 主按钮
          todayAsync.when(
            data: (today) {
              final streak = allNormalAsync.maybeWhen(
                data: (checkIns) => StreakCalculator.calculate(
                  checkIns: checkIns,
                  now: DateTime.now(),
                ),
                orElse: () => 0,
              );

              return CheckInButton(
                isChecked: today != null,
                streakDays: streak,
                onPressed: () {
                  ref.read(checkInNotifierProvider.notifier).checkIn();
                },
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (_, __) => CheckInButton(
              isChecked: false,
              streakDays: 0,
              onPressed: () {},
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          SizedBox(
            width: double.infinity,
            height: AppTokens.buttonHeightSmall,
            child: OutlinedButton(
              onPressed: () => _showTempMedicationDialog(context, ref),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppTokens.primary, width: 1.5),
                foregroundColor: AppTokens.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                ),
              ),
              child: const Text(
                Strings.homeTempMed,
                style: TextStyle(
                  fontSize: AppTokens.fontSizeButton,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),

          const Spacer(flex: 1),

          todayAsync.when(
            data: (today) {
              final shouldShowBroken = allNormalAsync.maybeWhen(
                data: (List<CheckIn> checkIns) =>
                    StreakCalculator.shouldShowStreakBroken(
                  checkIns: checkIns,
                  now: DateTime.now(),
                ),
                orElse: () => false,
              );
              return LastMedInfo(
                lastCheckIn: today?.timestamp,
                nextReminder: _nextReminderTime(),
                showStreakBroken: shouldShowBroken,
              );
            },
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),

          const SizedBox(height: AppTokens.spacingXl),

          const Center(
            child: Text(
              Strings.homeStillOnline,
              style: TextStyle(
                fontSize: AppTokens.fontSizeBody,
                color: AppTokens.textHint,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 计算下次提醒时间（每天 20:00）
  DateTime? _nextReminderTime() {
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, 20, 0);
    if (next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  void _showTempMedicationDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final noteController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加临时吃药'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: '药名',
                hintText: '如：布洛芬',
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: '原因',
                hintText: '如：感冒',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(Strings.commonCancel),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;
              await ref.read(checkInNotifierProvider.notifier).addTempMedication(
                    name: nameController.text.trim(),
                    note: noteController.text.trim(),
                  );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text(Strings.commonSave),
          ),
        ],
      ),
    );
  }
}
