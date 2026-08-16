// v1.1.0 R116 (god class 拆): 心理评估提醒设置 BottomSheet
//
// 历史:
// - v0.14 (Round 12C) 提醒中心: 4 大类提醒 (打卡/用药/续方/评估) + 失联 (R4 摘)
// - v0.23 (Round 41 spen P3-35): 改用 FutureProvider 替代 setState 模式
// - v0.27 (Round 67 C-5): ChoiceChipWrap 集中器替换内联 Wrap
// - v1.1.0 R116: 从 reminders_hub_page.dart 312L 拆出, 本文件装 sheet
//
// 公开 API:
// - AssessmentReminderSheet: BottomSheet 入口, 持 enabled + days 状态,
//   save() 走 AssessmentReminderService.setEnabled / setDays / onSettingsChanged,
//   失败走 AppSnackBar.showError, 成功 onSaved callback + Navigator.pop
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/service_providers.dart';
import 'package:chroniccare/presentation/widgets/app_snack_bar.dart';
import 'package:chroniccare/presentation/widgets/choice_chip_wrap.dart';
import 'package:chroniccare/presentation/widgets/primary_button.dart';

/// 心理评估提醒设置 BottomSheet
///
/// 主壳 (reminders_hub_page.dart) 通过 [showModalBottomSheet] 唤起本组件,
/// 接受 initialEnabled / initialDays 初值, save 成功后 onSaved 回调 +
/// Navigator.pop 关闭 sheet。
class AssessmentReminderSheet extends ConsumerStatefulWidget {
  final bool initialEnabled;
  final int initialDays;
  final VoidCallback onSaved;
  const AssessmentReminderSheet({
    super.key,
    required this.initialEnabled,
    required this.initialDays,
    required this.onSaved,
  });

  @override
  ConsumerState<AssessmentReminderSheet> createState() =>
      _AssessmentReminderSheetState();
}

class _AssessmentReminderSheetState
    extends ConsumerState<AssessmentReminderSheet> {
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
        AppSnackBar.showError(
          context,
          action: AppLocalizations.of(context).commonSave,
          error: e,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return SafeArea(
      child: Padding(
        padding: AppTokens.edgeInsetsMd,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              loc.reminderHubAssessmentTitle,
              style: const TextStyle(
                fontSize: AppTokens.fontSizeTitle,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppTokens.spacingMd),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(loc.reminderHubEnable),
              subtitle: Text(loc.reminderHubAssessmentSubtitle),
              value: _enabled,
              onChanged: _busy ? null : (v) => setState(() => _enabled = v),
            ),
            if (_enabled) ...[
              const Divider(),
              Text(
                loc.reminderHubInterval,
                style: const TextStyle(
                  fontSize: AppTokens.fontSizeLabel,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: AppTokens.spacingSm),
              // v0.27 round 67 (C-5): 用 ChoiceChipWrap 集中器
              ChoiceChipWrap<int>(
                options: _options,
                selected: _days,
                labelOf: loc.reminderHubEveryNDays,
                onSelect: (d) => setState(() => _days = d),
                disabled: _busy,
              ),
            ],
            const SizedBox(height: AppTokens.spacingLg),
            Row(
              children: [
                Expanded(
                  child: PrimaryButton(
                    variant: PrimaryButtonVariant.secondary,
                    isFullWidth: true,
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    child: Text(loc.commonCancel),
                  ),
                ),
                const SizedBox(width: AppTokens.spacingSm),
                Expanded(
                  child: PrimaryButton(
                    isFullWidth: false,
                    onPressed: _busy ? null : _save,
                    child: Text(loc.commonSave),
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
