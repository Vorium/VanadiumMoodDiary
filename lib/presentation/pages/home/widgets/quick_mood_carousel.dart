// v0.31 round 9a (Apple Health redesign · Phase 3 Task 3.1):
// QuickMoodCarousel 重设
//
// 历史:
// - v0.28 R81 (emil design-2): 主页快速记心情 carousel
//   B 站"哗哩哗哩能量加油站" 4 情绪横滑 carousel, 1 tap 速记 score。
//
// v0.31 R9a 改造 (Apple Health 心情 5 档圆形按钮):
// - AppleListSection("心情") 包装 (iOS 群组列表风格)
// - 5 个圆形 mood button 48x48 (跟 spec 5 档对齐, 之前是 PageView 隐藏第 5 档)
// - 横向 Row + 间距 12 (spacingSm) — 替代横滑 PageView
// - 选中 spring 放大 1.1 + 背景色 = mood metric color (systemPink 0xFFFF2D55)
//   curveSpring durNormal 250ms, AnimatedScale + AnimatedContainer 串联
// - 右上角 "more" icon 走完整 MoodDialog 4 维度评分 (跟 R81 一致)
// - 去掉 PageController / PageView (5 档全可见, 不再隐藏)
//
// 设计选择:
// - 不再走 PageView 5 档横滑: Apple Health 风格 5 档可见并排更直观
// - 选中态走 spring scale 1.1 (R7a AppleHealthTile 视觉一致), 0.97 → 1.1
// - 默认无选中态 (跟 R81 一样, _selected = null), 选中后高亮 + haptic
// - tappable area 用 PressFeedback + 圆形 Container (mode 1 自带 onTap)

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/apple_list_section.dart';
import 'package:chroniccare/presentation/widgets/feedback.dart' show Haptics;
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页快速记心情 5 档 (Apple Health 风格圆形按钮)
///
/// v0.31 R9a: 5 个圆形 mood button 48x48, 横排, 选中 spring 放大 1.1 +
/// 背景色 = mood metric color (systemPink)。
///
/// 完整 4 维度评分走右上角 "more" icon → [MoodDialog] (跟 R81 一致)。
class QuickMoodCarousel extends ConsumerStatefulWidget {
  final VoidCallback onOpenFullDialog;

  const QuickMoodCarousel({super.key, required this.onOpenFullDialog});

  @override
  ConsumerState<QuickMoodCarousel> createState() => _QuickMoodCarouselState();
}

class _QuickMoodCarouselState extends ConsumerState<QuickMoodCarousel> {
  // R81: 5 档状态 — 1=很差 2=差 3=一般 4=好 5=很好
  // (跟 MoodEntryDraft.score 1-5 一致, 5 档全可见)
  static const _scores = [1, 2, 3, 4, 5];

  int? _selected;
  bool _saving = false;

  Future<void> _recordQuick(int score) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(moodRepositoryProvider).add(
            draft: MoodEntryDraft(
              score: score,
              // 1 tap 速记, 其他维度留 null (完整 4 维度走 MoodDialog)
              tags: const [],
            ),
          );
      if (!mounted) return;
      setState(() => _selected = score);
      // 触觉反馈 (emil "feedback" 原则: press 后即时确认)
      // PressFeedback scale 0.97 + 这里 Haptics 一起, 跟 checkIn 风格一致
      // R32 (P0-11 a11y): 加 Haptics.success() (注释早写了但漏 1 行代码, 半年没补)
      unawaited(Haptics.success());
    } catch (e, st) {
      swallowError(
        where: 'QuickMoodCarousel._recordQuick',
        error: e,
        stack: st,
        note: '1 tap 速记 mood 失败, 用户可改走 MoodDialog',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('记录失败，请重试'),
            duration: AppTokens.snackBarDurationShort,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final moodColor = AppColors.healthMetricsColorFor('mood'); // systemPink
    return AppleListSection(
      title: '心情',
      margin: EdgeInsets.zero,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.homeQuickMoodTitle,
                  style: AppTokens.textStyleCaptionStrong(context),
                ),
                const Spacer(),
                // "more" icon: 1 tap 走完整 MoodDialog 4 维度评分
                PressFeedback(
                  onTap: widget.onOpenFullDialog,
                  child: Icon(
                    Icons.tune,
                    size: 18,
                    color: AppTokens.textHintColor(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.spacingXs),
            // 5 个圆形 mood button, 横排 + 间距 12
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final score in _scores)
                  _MoodButton(
                    score: score,
                    isSelected: score == _selected,
                    color: moodColor,
                    onTap: _saving ? null : () => _recordQuick(score),
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

/// v0.31 R9a: 单个圆形 mood button (48x48, 选中 spring 放大 1.1)
class _MoodButton extends StatelessWidget {
  const _MoodButton({
    required this.score,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final int score;
  final bool isSelected;
  final Color color;
  final VoidCallback? onTap;

  /// 圆形 button 直径 — 48pt (Apple Health 风格 5 档可点区域)
  static const double _diameter = 48;

  @override
  Widget build(BuildContext context) {
    return PressFeedback(
      onTap: onTap,
      pressedScale: 1.0, // 不让 PressFeedback 自带 0.97 干扰 spring 选中态
      child: AnimatedScale(
        // 选中 spring 放大 1.1
        scale: isSelected ? 1.1 : 1.0,
        duration: AppTokens.durNormal,
        curve: AppTokens.curveSpring,
        child: AnimatedContainer(
          duration: AppTokens.durNormal,
          curve: AppTokens.curveStandard,
          width: _diameter,
          height: _diameter,
          decoration: BoxDecoration(
            // 选中: metric 色 18% alpha (dark) / 12% alpha (light);
            // 未选: 透明 (跟 AppleListSection surface 一致)
            color: isSelected
                ? color.withValues(
                    alpha:
                        Theme.of(context).brightness == Brightness.dark
                            ? 0.18
                            : 0.12,
                  )
                : AppColors.transparent,
            shape: BoxShape.circle,
            border: isSelected
                ? Border.all(color: color, width: 2)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            MoodVisual.ipEmojiFor(score),
            style: const TextStyle(fontSize: AppTokens.fontSizeScoreLg),
          ),
        ),
      ),
    );
  }
}
