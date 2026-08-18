// v0.30 round 91 (sub-spec 7 日常追踪 / Task 4 UI): SleepListWidget + SleepEntryDialog
//
// 4 层架构: presentation/pages/daily_tracking/widgets/, 0 跨 feature import。
// 复用 R88 mood_dialog 风格 (AlertDialog + ListTile + ChoiceChip + TextField + 保存/取消)。
//
// 睡眠记录 (R91 4 字段, 跨午夜):
// - bedtime TimeOfDay picker (默认 23:00)
// - wakeTime TimeOfDay picker (默认 07:00)
// - durationMin 自动算 (跨午夜: 23:00 → 07:00 = 480min = 8h00min)
// - regularityScore 1-5 (5 档评分 ChoiceChip, nullable = 未评分)
// - note 可选备注 (TextField)
//
// 复用 R60 R90 calculator 模式:
// - SleepCalculator.durationMin(bedtime, wakeTime) 算跨午夜时长
// - 跟 daily_tracking_providers.sleepRepositoryProvider.add() 写库
//
// v0.30 R91 Task 7: i18n — 替换 hardcoded 中文 placeholder 走 l10n
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/domain/entities/sleep_entry.dart';
import 'package:chroniccare/domain/logic/sleep_calculator.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/pages/daily_tracking/widgets/daily_tracking_widgets.dart';
import 'package:chroniccare/presentation/providers/daily_tracking_providers.dart';
import 'package:chroniccare/presentation/widgets/empty_state.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/error_state.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';

/// 睡眠记录列表 (监听 sleepEntriesProvider stream)
///
/// R88 mood_dialog 风格 + R60 list 模式:
/// - 空 → EmptyState (添加按钮, 跳 SleepEntryDialog)
/// - 非空 → ListView (Card + ListTile) + 顶部"添加"按钮
/// - 加 FAB "添加" 跟 R87 mood_list 一致
///
/// v0.30 R91 Fix Round 1 (I-2): AppBar title 走 l10n.sleepName, 跟 R87
/// MoodListPage pattern 一致. 路由 file 不再包 PageScaffold wrapper.
class SleepListWidget extends ConsumerWidget {
  const SleepListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final entriesAsync = ref.watch(sleepEntriesProvider);

    return PageScaffold(
      title: l10n.sleepName,
      child: Column(
        children: [
          // 顶部添加按钮 (R88 mood_dialog 风格, 不走 FAB — list 页面通常 FAB 被 Card 占用)
          Padding(
            padding: AppTokens.edgeInsetsSm,
            child: Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                icon: const Icon(Icons.add),
                label: Text(l10n.sleepAddButton),
                onPressed: () => SleepEntryDialog.show(context),
              ),
            ),
          ),
          // 列表主体
          Expanded(
            child: entriesAsync.when(
              loading: () => const LoadingSkeleton.fullScreen(),
              error: (e, st) => ErrorState(
                title: l10n.commonLoadFailed(e.toString()),
              ),
              data: (entries) => entries.isEmpty
                  ? EmptyState(
                      icon: Icons.bedtime_outlined,
                      title: l10n.sleepNoData,
                      subtitle: l10n.sleepHint,
                    )
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, i) =>
                          _SleepEntryTile(entry: entries[i]),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 单条 sleep entry tile
class _SleepEntryTile extends StatelessWidget {
  const _SleepEntryTile({required this.entry});
  final SleepEntryEntity entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingSm,
        vertical: AppTokens.spacingXxs,
      ),
      child: ListTile(
        leading: Icon(Icons.bedtime, color: AppTokens.primaryColor(context)),
        title: Text(
          entry.durationLabel,
          style: AppTokens.textStyleLabelStrong(context),
        ),
        subtitle: Text(
          '${l10n.sleepBedtime(_fmt(entry.bedtime))} · ${l10n.sleepWakeTime(_fmt(entry.wakeTime))}'
          '${entry.hasRegularityScore ? ' · ${l10n.sleepRegularityScore(entry.regularityScore!)}' : ''}'
          '${entry.note != null ? ' · ${entry.note}' : ''}',
        ),
      ),
    );
  }

  static String _fmt(DateTime t) =>
      DailyTrackingTimeFormat.formatDateTimeHHmm(t);
}

/// SleepEntryDialog — 4 字段 (bedtime / wakeTime / regularity / note)
///
/// R88 mood_dialog 风格: AlertDialog + ListTile (time picker) + ChoiceChip row
/// (regularity 5 档) + TextField (note) + 取消/保存。
///
/// 默认值: bedtime=23:00, wakeTime=07:00 (跨午夜 8h, 跟一般用户作息一致)。
/// 跨午夜由 SleepCalculator.durationMin() 处理 (R91 brief 明确)。
class SleepEntryDialog extends ConsumerStatefulWidget {
  const SleepEntryDialog({super.key});

  /// 静态入口 — Dialog 模态
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (_) => const SleepEntryDialog(),
    );
  }

  @override
  ConsumerState<SleepEntryDialog> createState() => _SleepEntryDialogState();
}

class _SleepEntryDialogState extends ConsumerState<SleepEntryDialog> {
  // 默认 23:00 入睡, 07:00 起床 (跨午夜 8h)
  TimeOfDay _bedtime = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);
  int? _regularityScore; // 1-5, null = 未评分
  final _noteController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  /// 自动算 durationMin (跨午夜支持)
  int get _durationMin {
    final today = DailyTrackingDate.today();
    final bedtime = DailyTrackingDate.combineWithDate(today, _bedtime);
    // 跨午夜: wakeTime hour < bedtime hour → +1 day
    final wakeTime = _wakeTime.hour >= _bedtime.hour
        ? DailyTrackingDate.combineWithDate(today, _wakeTime)
        : DailyTrackingDate.combineWithDate(
            today.add(const Duration(days: 1)),
            _wakeTime,
          );
    return SleepCalculator.durationMin(bedtime, wakeTime);
  }

  String get _durationLabel =>
      DailyTrackingTimeFormat.formatDurationMin(_durationMin);

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
    );
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  String _fmtTime(TimeOfDay t) => DailyTrackingTimeFormat.formatHHmm(t);

  /// regularity 1-5 → l10n 中文 label
  String _regularityLabel(int score, AppLocalizations l10n) {
    switch (score) {
      case 1:
        return l10n.regularityVeryIrregular;
      case 2:
        return l10n.regularityIrregular;
      case 3:
        return l10n.regularityNormal;
      case 4:
        return l10n.regularityRegular;
      case 5:
        return l10n.regularityVeryRegular;
    }
    return '$score';
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final bedtime = DailyTrackingDate.combineWithDate(
        DailyTrackingDate.dateOnly(now),
        _bedtime,
      );
      final wakeTime = _wakeTime.hour >= _bedtime.hour
          ? DailyTrackingDate.combineWithDate(
              DailyTrackingDate.dateOnly(now),
              _wakeTime,
            )
          : DailyTrackingDate.combineWithDate(
              DailyTrackingDate.dateOnly(now).add(const Duration(days: 1)),
              _wakeTime,
            );
      await ref.read(sleepRepositoryProvider).add(
            date: DailyTrackingDate.dateOnly(now),
            bedtime: bedtime,
            wakeTime: wakeTime,
            durationMin: SleepCalculator.durationMin(bedtime, wakeTime),
            regularityScore: _regularityScore,
            note: _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
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
      title: Text(l10n.sleepAddButton),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 入睡时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.nights_stay_outlined),
              title: Text(l10n.sleepBedtimeTitle),
              trailing: Text(_fmtTime(_bedtime)),
              onTap: _pickBedtime,
            ),
            // 起床时间
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.wb_sunny_outlined),
              title: Text(l10n.sleepWakeTimeTitle),
              trailing: Text(_fmtTime(_wakeTime)),
              onTap: _pickWakeTime,
            ),
            // durationLabel (自动算, 不可编辑)
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: AppTokens.spacingSm),
              child: Row(
                children: [
                  Icon(
                    Icons.timelapse,
                    color: AppTokens.textHintColor(context),
                  ),
                  const SizedBox(width: AppTokens.spacingXs),
                  Text(
                    l10n.sleepDurationLabel(_durationLabel),
                    style: AppTokens.textStyleLabelMedium(context),
                  ),
                ],
              ),
            ),
            // regularity 5 档评分 (v0.30 R91 Task 7: chip label 走 l10n.regularity*)
            const SizedBox(height: AppTokens.spacingSm),
            Row(
              children: [
                Icon(Icons.repeat, color: AppTokens.textHintColor(context)),
                const SizedBox(width: AppTokens.spacingXs),
                Text(l10n.sleepRegularityTitle),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              children: [
                for (var i = 1; i <= 5; i++)
                  ChoiceChip(
                    label: Text(_regularityLabel(i, l10n)),
                    selected: _regularityScore == i,
                    onSelected: (_) {
                      setState(() {
                        _regularityScore = _regularityScore == i ? null : i;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingSm),
            // note
            TextField(
              controller: _noteController,
              decoration: InputDecoration(
                // R100 (P1#9): 走 ARB 集中器 (复用 dailyTrackingNote*)
                labelText: l10n.dailyTrackingNoteLabel,
                border: const OutlineInputBorder(),
                hintText: l10n.dailyTrackingNoteHint,
              ),
              maxLines: 2,
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
