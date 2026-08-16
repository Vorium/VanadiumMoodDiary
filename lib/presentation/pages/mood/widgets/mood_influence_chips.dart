// v0.30 R101: 影响因素标签选择器 — 参照 Apple Health State of Mind
//
// 6 大类 30+ 预设标签，用户可多选。
// 用于 MoodRecorderPage Dialog 内。
//
// v0.32 R112-03: chip label 走 kInfluenceFactorKeys ARB 派发 (不再显示
// domain 中文), onChanged 返回 i18n key (录入侧存 key, 不再存中文)。

import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/influence_category.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/services/influence_factor_l10n.dart';

/// 影响因素标签选择器
///
/// 按类别分组展示 chip，多选。
/// 回调 [onChanged] 返回当前选中的因素 **key** 列表 (i18n key, 非中文)。
/// [selected] 接受 key 列表; 兼容历史中文字面量 (按归一化 key 匹配)。
class MoodInfluenceChips extends StatelessWidget {
  const MoodInfluenceChips({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  /// 当前选中的因素 key 列表 (v0.32 R112-03: 存 key)
  final List<String> selected;

  /// 选中/取消回调 (返回 key 列表)
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
            .where((c) => kInfluenceFactorKeys.containsKey(c))
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
    final l10n = AppLocalizations.of(context);
    // v0.32 R112-03: 展示走 key list (ARB 派发), 不再用中文 kInfluenceFactors
    final keys = kInfluenceFactorKeys[category] ?? [];
    // 兼容历史中文字面量选中值: 归一化成 key 后匹配
    final normalizedSelected =
        selected.map(influenceFactorNormalizeKey).toSet();

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
            children: keys.map((key) {
              final isSelected = normalizedSelected.contains(key);
              return FilterChip(
                label: Text(influenceFactorL10nLabel(l10n, key)),
                selected: isSelected,
                onSelected: (_) {
                  // v0.32 R112-03: 写入/移除均走 key, 旧中文选中值一并清掉
                  final newList = List<String>.from(selected)
                    ..removeWhere((s) => influenceFactorNormalizeKey(s) == key);
                  if (!isSelected) {
                    newList.add(key);
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
