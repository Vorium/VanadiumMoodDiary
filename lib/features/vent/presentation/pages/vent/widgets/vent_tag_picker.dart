// lib/presentation/pages/vent/widgets/vent_tag_picker.dart
import 'package:flutter/material.dart';
import 'package:chroniccare_theme/chroniccare_theme.dart';
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
    final customTags = widget.selected
        .where((t) => !VentTagLibrary.presetTags.contains(t))
        .toSet();

    String categoryLabel(VentTagCategory cat) {
      switch (cat) {
        case VentTagCategory.workLife:
          return l10n.ventTagCategoryWorkLife;
        case VentTagCategory.emotionalLife:
          return l10n.ventTagCategoryEmotionalLife;
        case VentTagCategory.wellBeing:
          return l10n.ventTagCategoryWellBeing;
      }
    }

    Widget buildCategoryChips(VentTagCategory cat) {
      final tags = VentTagLibrary.tagsInCategory(cat);
      if (tags.isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: AppTokens.spacingXs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 分类小标题 (R128e 论文 2 吕沛强 §2.1.1 优化: 树状分类)
            Text(
              categoryLabel(cat),
              style: AppTokens.textStyleCaption(context).copyWith(
                color: AppTokens.textHintColor(context),
              ),
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            Wrap(
              spacing: AppTokens.spacingXs,
              runSpacing: 4,
              children: [
                for (final tag in tags)
                  FilterChip(
                    label: Text(localizedVentTag(context, tag)),
                    selected: widget.selected.contains(tag),
                    onSelected: (_) => _toggle(tag),
                  ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.ventTagSectionTitle,
          style: AppTokens.textStyleLabelStrong(context),
        ),
        const SizedBox(height: AppTokens.spacingXs),
        for (final cat in VentTagLibrary.categoryOrder)
          buildCategoryChips(cat),
        // 自定义标签 (R128e: 单独一组, 走 wellBeing 分类逻辑)
        if (customTags.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: AppTokens.spacingXs),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  categoryLabel(VentTagCategory.wellBeing),
                  style: AppTokens.textStyleCaption(context).copyWith(
                    color: AppTokens.textHintColor(context),
                  ),
                ),
                const SizedBox(height: AppTokens.spacingXxs),
                Wrap(
                  spacing: AppTokens.spacingXs,
                  runSpacing: 4,
                  children: [
                    for (final tag in customTags)
                      FilterChip(
                        label: Text(localizedVentTag(context, tag)),
                        selected: true,
                        onSelected: (_) => _toggle(tag),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
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
