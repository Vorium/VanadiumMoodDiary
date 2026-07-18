// v0.14 (Round 12C) 提醒中心 — 集中查看/管理所有类型的提醒
//
// 之前散落在各处的设置（notification / assessment / safety watch）整合到一个页面
//
// 五大类提醒：
// 1. 每日打卡提醒（notification_service.scheduleDailyReminder，固定 20:00）
// 2. 用药提醒（notification_service - 每个 medication 的每个 time）
// 3. 续方提醒（medication.refillAt - refillReminderDays）
// 4. 心理评估提醒（AssessmentReminderService）
// 5. 失联通知（SafetyWatchService - 死了么/撸了么）
library;

import '../../providers/service_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/domain/entities/medication_entity.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';
import 'package:chroniccare/presentation/widgets/page_scaffold.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';

/// 提醒中心
class RemindersHubPage extends ConsumerStatefulWidget {
  const RemindersHubPage({super.key});

  @override
  ConsumerState<RemindersHubPage> createState() => _RemindersHubPageState();
}

class _RemindersHubPageState extends ConsumerState<RemindersHubPage> {
  // 各提醒的运行时状态（initState 加载）
  bool? _assessmentEnabled;
  int? _assessmentDays;
  bool? _safetyEnabled;
  int? _safetyThreshold;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final assessService = ref.read(assessmentReminderServiceProvider);
    final safetyService = ref.read(safetyWatchServiceProvider);
    final aEnabled = await assessService.isEnabled();
    final aDays = await assessService.getDays();
    final sEnabled = await safetyService.isEnabled();
    final sThreshold = await safetyService.getThresholdDays();
    if (!mounted) return;
    setState(() {
      _assessmentEnabled = aEnabled;
      _assessmentDays = aDays;
      _safetyEnabled = sEnabled;
      _safetyThreshold = sThreshold;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final medsAsync = ref.watch(medicationsProvider);
    return PageScaffold(
      title: '提醒中心',
      child: ListView(
        children: [
          const SizedBox(height: AppTokens.spacingMd),

          // 顶部说明
          Container(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            decoration: BoxDecoration(
              color: AppTokens.primaryLight,
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: AppTokens.primary,
                ),
                SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: Text(
                    '集中管理所有提醒：每天打卡、用药时间、续方日期、心理评估、失联通知。',
                    style: TextStyle(fontSize: AppTokens.fontSizeBody),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTokens.spacingMd),

          // 1. 每日打卡提醒
          _ReminderCard(
            icon: Icons.check_circle_outline,
            title: '每日打卡提醒',
            description: '每天 20:00 推送"记得打卡"，漏 1 次没关系',
            statusText: '已启用 · 每天 20:00',
            statusActive: true,
            actionLabel: '查看通知预览',
            onAction: () => context.push('/email-preview'),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 2. 用药提醒
          medsAsync.when(
            data: (meds) => _MedicationReminderCard(meds: meds),
            loading: () => const _ReminderCard(
              icon: Icons.medication_outlined,
              title: '用药提醒',
              description: '加载中...',
              statusText: '',
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
            error: (e, _) => _ReminderCard(
              icon: Icons.medication_outlined,
              title: '用药提醒',
              description: '加载失败: $e',
              statusText: '出错',
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 3. 续方提醒
          medsAsync.when(
            data: (meds) => _RefillReminderCard(meds: meds),
            loading: () => const _ReminderCard(
              icon: Icons.shopping_cart_outlined,
              title: '续方提醒',
              description: '加载中...',
              statusText: '',
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
            error: (e, _) => _ReminderCard(
              icon: Icons.shopping_cart_outlined,
              title: '续方提醒',
              description: '加载失败: $e',
              statusText: '出错',
              statusActive: false,
              actionLabel: '',
              onAction: null,
            ),
          ),

          const SizedBox(height: AppTokens.spacingSm),

          // 4. 心理评估提醒
          _buildAssessmentCard(context),

          const SizedBox(height: AppTokens.spacingSm),

          // 5. 失联通知
          _buildSafetyCard(context),

          const SizedBox(height: AppTokens.spacingMd),
        ],
      ),
    );
  }

  void _showAssessmentSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AssessmentReminderSheet(
        initialEnabled: _assessmentEnabled ?? false,
        initialDays: _assessmentDays ?? 14,
        onSaved: _load,
      ),
    );
  }

  void _showSafetySettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _SafetyReminderSheet(
        initialEnabled: _safetyEnabled ?? false,
        initialThreshold: _safetyThreshold ?? 2,
        onSaved: _load,
      ),
    );
  }

  Widget _buildAssessmentCard(BuildContext context) {
    if (_loading) {
      return const _ReminderCard(
        icon: Icons.psychology_outlined,
        title: '周期评估提醒',
        description: '加载中...',
        statusText: '',
        statusActive: false,
        actionLabel: '',
        onAction: null,
      );
    }
    final enabled = _assessmentEnabled ?? false;
    final days = _assessmentDays ?? 14;
    return _ReminderCard(
      icon: Icons.psychology_outlined,
      title: '周期评估提醒',
      description:
          enabled ? '每 $days 天提醒做心理评估（PHQ-9 / GAD-7）' : '关闭 · 不会推送评估提醒',
      statusText: enabled ? '已启用 · 每 $days 天' : '未启用',
      statusActive: enabled,
      actionLabel: '配置',
      onAction: () => _showAssessmentSettings(context),
    );
  }

  Widget _buildSafetyCard(BuildContext context) {
    if (_loading) {
      return const _ReminderCard(
        icon: Icons.shield_outlined,
        title: '失联通知（安全开关）',
        description: '加载中...',
        statusText: '',
        statusActive: false,
        actionLabel: '',
        onAction: null,
      );
    }
    final enabled = _safetyEnabled ?? false;
    final threshold = _safetyThreshold ?? 2;
    // P0-1 fix: 检测当前 SMS provider,如果还是 mock 状态，显示显眼 banner。
    // 用户必须知道「失联通知」功能还没真接通 — 否则可能误以为已保护家人。
    final providerName = ref.watch(smsProviderNameProvider);
    final isMockSms = providerName == 'mock';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (isMockSms)
          Container(
            margin: const EdgeInsets.only(bottom: AppTokens.spacingSm),
            padding: const EdgeInsets.all(AppTokens.spacingSm),
            decoration: BoxDecoration(
              color: AppTokens.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              border: Border.all(color: AppTokens.error, width: 1),
            ),
            child: const Row(
              children: [
                Icon(Icons.error_outline, color: AppTokens.error, size: 18),
                SizedBox(width: AppTokens.spacingXs),
                Expanded(
                  child: Text(
                    'SMS 通道未接通（当前使用 Mock）。失联触发时只会推本地通知,'
                    '不会真发短信给紧急联系人。上 store 前必须接入真实 SMS provider。',
                    style: TextStyle(fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        _ReminderCard(
          icon: Icons.shield_outlined,
          title: '失联通知（安全开关）',
          description: enabled
              ? '连续 $threshold 天没打卡 → 自动 SMS 通知紧急联系人 + 本地推送'
              : '关闭 · 不会自动通知紧急联系人',
          statusText: enabled ? '已启用 · 阈值 $threshold 天' : '未启用',
          statusActive: enabled,
          actionLabel: '配置',
          onAction: () => _showSafetySettings(context),
        ),
      ],
    );
  }
}

/// 通用提醒卡片
class _ReminderCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String statusText;
  final bool statusActive;
  final String actionLabel;
  final VoidCallback? onAction;

  const _ReminderCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.statusText,
    required this.statusActive,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    statusActive ? AppTokens.primaryLight : AppTokens.divider,
                borderRadius: BorderRadius.circular(AppTokens.radiusChip),
              ),
              child: Icon(icon, color: AppTokens.primary, size: 22),
            ),
            const SizedBox(width: AppTokens.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: AppTokens.fontSizeBody,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (statusText.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: statusActive
                                ? AppTokens.primary.withValues(alpha: 0.12)
                                : AppTokens.divider,
                            borderRadius:
                                BorderRadius.circular(AppTokens.radiusChip),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              fontSize: AppTokens.fontSizeCaption,
                              color: statusActive
                                  ? AppTokens.primary
                                  : AppTokens.textHint,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: AppTokens.fontSizeCaption,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (onAction != null && actionLabel.isNotEmpty) ...[
                    const SizedBox(height: AppTokens.spacingSm),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: onAction,
                        icon: const Icon(Icons.tune, size: 18),
                        label: Text(actionLabel),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 用药提醒卡片
class _MedicationReminderCard extends StatelessWidget {
  final List<MedicationEntity> meds;
  const _MedicationReminderCard({required this.meds});

  @override
  Widget build(BuildContext context) {
    final activeMeds = meds.where((m) => m.isInUse).toList();
    final totalTimes =
        activeMeds.fold<int>(0, (sum, m) => sum + m.times.length);
    final active = activeMeds.isNotEmpty;

    return _ReminderCard(
      icon: Icons.medication_outlined,
      title: '用药提醒',
      description: active
          ? '共 ${activeMeds.length} 种在用药物，$totalTimes 个时间点会推送提醒'
          : '还没有在用药物 · 添加后会自动启用',
      statusText:
          active ? '已启用 · ${activeMeds.length} 种 / $totalTimes 时间点' : '未配置',
      statusActive: active,
      actionLabel: '管理用药',
      onAction: () => context.push('/settings'),
    );
  }
}

/// 续方提醒卡片
class _RefillReminderCard extends StatelessWidget {
  final List<MedicationEntity> meds;
  const _RefillReminderCard({required this.meds});

  @override
  Widget build(BuildContext context) {
    final withRefill = meds.where((m) => m.hasRefill && m.isInUse).toList();
    final overdue = withRefill.where((m) => m.isRefillOverdue()).toList();
    final inWindow = withRefill
        .where((m) => m.isInRefillWindow() && !m.isRefillOverdue())
        .toList();
    final active = withRefill.isNotEmpty;

    String description;
    if (!active) {
      description = '未给任何药物设置续方日期 · 在"用药设置"中可加';
    } else if (overdue.isNotEmpty) {
      description = '${overdue.length} 种已过期续方 · ${inWindow.length} 种在提醒窗口内';
    } else {
      description = '${withRefill.length} 种药物已设续方 · 临近时会推送提醒';
    }

    return _ReminderCard(
      icon: Icons.shopping_cart_outlined,
      title: '续方提醒',
      description: description,
      statusText: active
          ? overdue.isNotEmpty
              ? '已过期 ${overdue.length}'
              : inWindow.isNotEmpty
                  ? '提醒中 ${inWindow.length}'
                  : '已启用 · ${withRefill.length} 种'
          : '未配置',
      statusActive: active,
      actionLabel: '管理续方',
      onAction: () => context.push('/settings/refills'),
    );
  }
}

/// 评估提醒设置 sheet
class _AssessmentReminderSheet extends ConsumerStatefulWidget {
  final bool initialEnabled;
  final int initialDays;
  final VoidCallback onSaved;
  const _AssessmentReminderSheet({
    required this.initialEnabled,
    required this.initialDays,
    required this.onSaved,
  });

  @override
  ConsumerState<_AssessmentReminderSheet> createState() =>
      _AssessmentReminderSheetState();
}

class _AssessmentReminderSheetState
    extends ConsumerState<_AssessmentReminderSheet> {
  late bool _enabled;
  late int _days;
  bool _busy = false;

  static const _options = [7, 14, 30, 60, 90];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _days = widget.initialDays;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final service = ref.read(assessmentReminderServiceProvider);
      await service.setEnabled(_enabled);
      if (_enabled) {
        await service.setDays(_days);
      }
      await service.onSettingsChanged();
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context, action: '保存', error: e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '周期评估提醒',
              style: TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用'),
              subtitle: const Text('每隔 N 天推送一次心理评估'),
              value: _enabled,
              onChanged: _busy ? null : (v) => setState(() => _enabled = v),
            ),
            if (_enabled) ...[
              const Divider(),
              const Text(
                '提醒间隔',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _options)
                    ChoiceChip(
                      label: Text('每 $d 天'),
                      selected: _days == d,
                      onSelected: _busy
                          ? null
                          : (sel) {
                              if (sel) setState(() => _days = d);
                            },
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _save,
                    child: Text(AppLocalizations.of(context).commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// 失联通知设置 sheet
class _SafetyReminderSheet extends ConsumerStatefulWidget {
  final bool initialEnabled;
  final int initialThreshold;
  final VoidCallback onSaved;
  const _SafetyReminderSheet({
    required this.initialEnabled,
    required this.initialThreshold,
    required this.onSaved,
  });

  @override
  ConsumerState<_SafetyReminderSheet> createState() =>
      _SafetyReminderSheetState();
}

class _SafetyReminderSheetState extends ConsumerState<_SafetyReminderSheet> {
  late bool _enabled;
  late int _threshold;
  bool _busy = false;

  static const _options = [1, 2, 3, 5, 7, 14];

  @override
  void initState() {
    super.initState();
    _enabled = widget.initialEnabled;
    _threshold = widget.initialThreshold;
  }

  Future<void> _save() async {
    setState(() => _busy = true);
    try {
      final service = ref.read(safetyWatchServiceProvider);
      await service.setEnabled(_enabled);
      if (_enabled) {
        await service.setThresholdDays(_threshold);
      }
      if (mounted) {
        widget.onSaved();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppSnackBar.error(context, action: '保存', error: e),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.spacingMd),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '失联通知（安全开关）',
              style: TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingSm),
            Text(
              '连续 N 天没打卡 → 自动 SMS 通知所有启用的紧急联系人 + 本地推送',
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('启用'),
              value: _enabled,
              onChanged: _busy ? null : (v) => setState(() => _enabled = v),
            ),
            if (_enabled) ...[
              const Divider(),
              const Text(
                '触发阈值（连续 N 天没打卡）',
                style: TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final d in _options)
                    ChoiceChip(
                      label: Text('$d 天'),
                      selected: _threshold == d,
                      onSelected: _busy
                          ? null
                          : (sel) {
                              if (sel) setState(() => _threshold = d);
                            },
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(AppLocalizations.of(context).commonCancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _busy ? null : _save,
                    child: Text(AppLocalizations.of(context).commonSave),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
