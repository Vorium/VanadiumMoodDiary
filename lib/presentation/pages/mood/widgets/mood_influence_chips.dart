// v0.30 R101: 影响因素标签选择器 — 参照 Apple Health State of Mind
//
// 6 大类 30+ 预设标签，用户可多选。
// 用于 MoodRecorderPage Dialog 内。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/influence_category.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 影响因素标签选择器
///
/// 按类别分组展示 chip，多选。
/// 回调 [onChanged] 返回当前选中的因素列表。
class MoodInfluenceChips extends StatelessWidget {
  const MoodInfluenceChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// 当前选中的因素列表
  final List<String> selected;

  /// 选中/取消回调
  final ValueChanged<List<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.moodInfluenceTitle,
          style: TextStyle(
            fontSize: AppTokens.fontSizeBody,
            fontWeight: FontWeight.w600,
            color: AppTokens.textPrimaryColor(context),
          ),
        ),
        const SizedBox(height: AppTokens.spacingXxs),
        Text(
          l10n.moodInfluenceSubtitle,
          style: TextStyle(
            fontSize: AppTokens.fontSizeCaption,
            color: AppTokens.textHintColor(context),
          ),
        ),
        const SizedBox(height: AppTokens.spacingSm),
        ...InfluenceCategory.values
            .where((c) => kInfluenceFactors.containsKey(c))
            .map(
              (category) => _CategorySection(
                category: category,
                selected: selected,
                onChanged: onChanged,
              ),
            ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.selected,
    required this.onChanged,
  });

  final InfluenceCategory category;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;

  String _categoryLabel(InfluenceCategory c, AppLocalizations l10n) {
    switch (c) {
      case InfluenceCategory.relationships:
        return l10n.moodInfluenceRelationships;
      case InfluenceCategory.health:
        return l10n.moodInfluenceHealth;
      case InfluenceCategory.activities:
        return l10n.moodInfluenceActivities;
      case InfluenceCategory.mindfulness:
        return l10n.moodInfluenceMindfulness;
      case InfluenceCategory.weather:
        return l10n.moodInfluenceWeather;
      case InfluenceCategory.other:
        return l10n.moodInfluenceOther;
    }
  }

  @override
  Widget build(BuildContext context) {
    final factors = kInfluenceFactors[category] ?? [];
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.spacingSm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _categoryLabel(category, l10n),
            style: TextStyle(
              fontSize: AppTokens.fontSizeCaption,
              fontWeight: FontWeight.w500,
              color: AppTokens.textSecondaryColor(context),
            ),
          ),
          const SizedBox(height: AppTokens.spacingXxs),
          Wrap(
            spacing: AppTokens.spacingXs,
            runSpacing: AppTokens.spacingXxs,
            children: factors.map((factor) {
              final isSelected = selected.contains(factor);
              return FilterChip(
                label: Text(factor),
                selected: isSelected,
                onSelected: (_) {
                  final newList = List<String>.from(selected);
                  if (isSelected) {
                    newList.remove(factor);
                  } else {
                    newList.add(factor);
                  }
                  onChanged(newList);
                },
                selectedColor:
                    AppTokens.primaryColor(context).withValues(alpha: 0.15),
                checkmarkColor: AppTokens.primaryColor(context),
                labelStyle: TextStyle(
                  fontSize: AppTokens.fontSizeCaption,
                  color: isSelected
                      ? AppTokens.primaryColor(context)
                      : AppTokens.textSecondaryColor(context),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
