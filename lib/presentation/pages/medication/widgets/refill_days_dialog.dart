// v0.14 (Round 13A) 续方管理 — 续方提前天数选择 dialog
//
// v0.24 (Round 45) 从 medications_list_widget.dart 抽到独立文件
// 让 refill_manage_page 也能复用, 同时方便 widget test 单独测。
//
// 5 个预设天数选项 [3, 5, 7, 14, 30], 选中后 Navigator.pop(context, days)。
// initial 不在 _options 时回落到 7 (默认 7 天)。

import 'package:flutter/material.dart';

import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/dialog_actions_row.dart';

/// 续方提前天数选择 dialog
///
/// 弹 dialog 让用户选 5 个预设之一, 返回 int? (null = 取消, 否则为天数)。
class RefillDaysDialog extends StatefulWidget {
  final int initial;
  const RefillDaysDialog({super.key, required this.initial});

  @override
  State<RefillDaysDialog> createState() => _RefillDaysDialogState();
}

class _RefillDaysDialogState extends State<RefillDaysDialog> {
  late int _selected;
  static const _options = [3, 5, 7, 14, 30];

  @override
  void initState() {
    super.initState();
    _selected = _options.contains(widget.initial) ? widget.initial : 7;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocalizations.of(context).medsRefillDaysTitle),
      content: RadioGroup<int>(
        groupValue: _selected,
        onChanged: (v) {
          if (v != null) setState(() => _selected = v);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in _options)
              RadioListTile<int>(
                value: d,
                title: Text(AppLocalizations.of(context).medsRefillDaysUnit(d)),
                subtitle: Text(_hintFor(d, context)),
              ),
          ],
        ),
      ),
      actions: [
        // v0.27 round 67 (C-3): 走 DialogActionsRow 集中器
        // (顺道把 ElevatedButton 升级到 M3 FilledButton via LoadingTextButton filled variant)
        DialogActionsRow(
          cancelLabel: AppLocalizations.of(context).commonCancel,
          onCancel: () => Navigator.pop(context, null),
          confirmLabel: AppLocalizations.of(context).commonConfirmOk,
          onConfirm: () => Navigator.pop(context, _selected),
        ),
      ],
    );
  }

  String _hintFor(int d, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (d) {
      case 3:
        return l10n.medsRefillHint3;
      case 5:
        return l10n.medsRefillHint5;
      case 7:
        return l10n.medsRefillHint7;
      case 14:
        return l10n.medsRefillHint14;
      case 30:
        return l10n.medsRefillHint30;
      default:
        return '';
    }
  }
}
