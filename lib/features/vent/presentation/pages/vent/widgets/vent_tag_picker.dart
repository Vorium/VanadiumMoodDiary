// lib/presentation/pages/vent/widgets/vent_tag_picker.dart
import 'package:flutter/material.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/logic/vent_tag_library.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/l10n/preset_content_l10n.dart';

/// 树洞标签多选（预置 chips + 自定义输入）
class VentTagPicker extends StatefulWidget {
  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;
  const VentTagPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  State<VentTagPicker> createState() => _VentTagPickerState();
}

class _VentTagPickerState extends State<VentTagPicker> {
  final TextEditingController _customCtrl = TextEditingController();

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  void _toggle(String tag) {
    final next = {...widget.selected};
    next.contains(tag) ? next.remove(tag) : next.add(tag);
    widget.onChanged(next);
  }

  void _addCustom(String raw) {
    final tag = raw.trim();
    if (!VentTagLibrary.isValidTag(tag)) return;
    // 自定义输入 = 已选标签时保持选中 (不 toggle 掉), 只清输入
    if (!widget.selected.contains(tag)) {
      widget.onChanged({...widget.selected, tag});
    }
    _customCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final allTags = {...VentTagLibrary.presetTags, ...widget.selected};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ventTagSectionTitle,
          style: AppTokens.textStyleLabelStrong(context),
        ),
        const SizedBox(height: AppTokens.spacingXs),
        Wrap(
          spacing: AppTokens.spacingXs,
          runSpacing: 4,
          children: [
            for (final tag in allTags)
              FilterChip(
                label: Text(localizedVentTag(context, tag)),
                selected: widget.selected.contains(tag),
                onSelected: (_) => _toggle(tag),
              ),
          ],
        ),
        const SizedBox(height: AppTokens.spacingXs),
        TextField(
          controller: _customCtrl,
          maxLength: VentTagLibrary.maxCustomTagLength,
          decoration: InputDecoration(hintText: l10n.ventTagCustomHint),
          onSubmitted: _addCustom,
        ),
      ],
    );
  }
}
