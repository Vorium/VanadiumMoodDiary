// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): SocialRhythmListWidget + SocialRhythmEntryDialog
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R88 mood_dialog 风格 (AlertDialog + ListTile + TextField + 保存/取消)。
//
// 社会节律记录 (R91 6 字段, 1 天 1 条):
// - wakeTime TimeOfDay (默认 07:00, 起床)
// - firstMealTime TimeOfDay (默认 12:00, 第一餐)
// - lastMealTime TimeOfDay (默认 19:00, 最后一餐)
// - socialMin int (默认 0, 社交时长分钟)
// - workMin int (默认 0, 工作时长分钟)
// - exerciseMin int (默认 0, 运动时长分钟)
//
// v0.30 R91 Task 7: i18n — 替换 hardcoded 中文 placeholder 走 l10n
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/social_rhythm_entry.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/daily_tracking_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 社会节律记录列表 (监听 socialRhythmEntriesProvider stream)
///
/// R88 mood_dialog 风格 + R60 list 模式
///
/// v0.30 R91 Fix Round 1 (I-2): AppBar title 走 l10n.socialRhythmName,
/// 跟 R87 MoodListPage pattern 一致. 路由 file 不再包 PageScaffold wrapper.
class SocialRhythmListWidget extends ConsumerWidget {
  const SocialRhythmListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(socialRhythmEntriesProvider);

    return PageScaffold(
      title: l10n.socialRhythmName,
      child: Column(
        children: [
          Padding(
            padding: AppTokens.edgeInsetsSm,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.socialRhythmAddButton),
                onPressed: () => SocialRhythmEntryDialog.show(context),
              ),
            ),
          ),
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, st) => ErrorState(
                  title: l10n.commonLoadFailed(e.toString()),
                ),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.schedule_outlined,
                      title: l10n.socialRhythmNoData,
                      subtitle: l10n.socialRhythmHint,
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _SocialRhythmEntryTile(entry: entries[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条 social_rhythm entry tile
class _SocialRhythmEntryTile extends StatelessWidget {
  const _SocialRhythmEntryTile({required this.entry});
  final SocialRhythmEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.schedule, color: AppTokens.primaryColor(context)),
        title: Text(
          l10n.socialRhythmWakeTime(_fmt(entry.wakeTime)),
          style: AppTokens.textStyleLabelStrong(context),
        ),
        subtitle: Text(
          '${l10n.socialRhythmFirstMeal(_fmt(entry.firstMealTime))} · ${l10n.socialRhythmLastMeal(_fmt(entry.lastMealTime))} · '
          '${l10n.socialRhythmMinutesSummary(entry.socialMin, entry.workMin, entry.exerciseMin)}',
        ),
      ),
    );
  }

  static String _fmt(DateTime t) => DailyTrackingTimeFormat.formatDateTimeHHmm(t);
}

/// SocialRhythmEntryDialog — 6 字段 (3 TimeOfDay + 3 number)
class SocialRhythmEntryDialog extends ConsumerStatefulWidget {
  const SocialRhythmEntryDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SocialRhythmEntryDialog(),
    );
  }

  @override
  ConsumerState<SocialRhythmEntryDialog> createState() =>
      _SocialRhythmEntryDialogState();
}

class _SocialRhythmEntryDialogState
    extends ConsumerState<SocialRhythmEntryDialog> {
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _firstMealTime = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _lastMealTime = const TimeOfDay(hour: 19, minute: 0);
  final _socialController = TextEditingController(text: '0');
  final _workController = TextEditingController(text: '0');
  final _exerciseController = TextEditingController(text: '0');
  bool _saving = false;

  @override
  void dispose() {
    _socialController.dispose();
    _workController.dispose();
    _exerciseController.dispose();
    super.dispose();
  }

  String _fmtTime(TimeOfDay t) => DailyTrackingTimeFormat.formatHHmm(t);

  Future<void> _pickTime(
    void Function(TimeOfDay) setter,
    TimeOfDay current,
  ) async {
    final picked = await showTimePicker(context: context, initialTime: current);
    if (picked != null) setState(() => setter(picked));
  }

  Future<void> _save() async {
    if (_saving) return;
    final social = int.tryParse(_socialController.text.trim()) ?? 0;
    final work = int.tryParse(_workController.text.trim()) ?? 0;
    final exercise = int.tryParse(_exerciseController.text.trim()) ?? 0;
    setState(() => _saving = true);
    try {
      final today = DailyTrackingDate.today();
      await ref.read(socialRhythmRepositoryProvider).add(
            date: today,
            wakeTime: DailyTrackingDate.combineWithDate(today, _wakeTime),
            firstMealTime:
                DailyTrackingDate.combineWithDate(today, _firstMealTime),
            lastMealTime:
                DailyTrackingDate.combineWithDate(today, _lastMealTime),
            socialMin: social,
            workMin: work,
            exerciseMin: exercise,
          );
      if (!mounted) return;
      DailyTrackingNav.safePop(context);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      DailyTrackingSnackBar.showSaveError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.socialRhythmAddButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 起床时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(l10n.socialRhythmWakeTimeTitle),
              trailing: Text(_fmtTime(_wakeTime)),
              onTap: () => _pickTime((v) => _wakeTime = v, _wakeTime),
            ),
            // 第一餐
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.restaurant_outlined),
              title: Text(l10n.socialRhythmFirstMealTitle),
              trailing: Text(_fmtTime(_firstMealTime)),
              onTap: () => _pickTime((v) => _firstMealTime = v, _firstMealTime),
            ),
            // 最后一餐
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.dinner_dining_outlined),
              title: Text(l10n.socialRhythmLastMealTitle),
              trailing: Text(_fmtTime(_lastMealTime)),
              onTap: () => _pickTime((v) => _lastMealTime = v, _lastMealTime),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // 社交/工作/运动 分钟数
            TextField(
              controller: _socialController,
              decoration: InputDecoration(
                labelText: l10n.socialRhythmSocialMinLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: _workController,
              decoration: InputDecoration(
                labelText: l10n.socialRhythmWorkMinLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppTokens.spacingSm),
            TextField(
              controller: _exerciseController,
              decoration: InputDecoration(
                labelText: l10n.socialRhythmExerciseMinLabel,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: Text(l10n.commonCancel),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.commonSave),
        ),
      ],
    );
  }
}
