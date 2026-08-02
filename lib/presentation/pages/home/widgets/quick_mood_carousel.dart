// v0.28 R81 (emil design-2): QuickMoodCarousel 主页快速记心情 carousel
//
// 背景 (R81 emil design eng 借鉴 B 站"哗哩哗哩能量加油站" 截图):
//   B 站主页 4 情绪横滑 carousel (开心☀️/一般⛅/有点烦🌧/不开心⛈),
//   1 tap 速记心情, 治愈系 IP 风格, 不用打开 dialog。
//
//   chroniccare 之前: home_page → MoodQuickButton (单按钮) →
//   MoodDialog (4 维度评分 dialog, 完整流程)。用户想"快速记"时
//   需要点 2 次 + 填 4 维度, 摩擦大。
//
// 修法: 在 home_page PrimaryActionRow 上方加 4 档 IP 化太阳
// emoji 横滑 carousel, 1 tap 写 MoodEntryDraft (score=1-5,
// energy/sleep/anxiety 留 null — 完整 4 维度仍走 MoodDialog)。
//
// emil 频度: occasional (跟 checkIn button 同频度, primary action),
// standard animation OK, PressFeedback scale 0.97 100ms (轻反馈)。
// PageView 横滑 transition 200ms ease-out (custom curve)。
//
// 跟 MoodQuickButton 关系: 横滑 carousel 替代单一按钮 (B 站同款),
// 1 tap 速记 = 4 档太阳。完整 MoodDialog 走"more" icon (右上角)
// 1 tap 进, 提供 4 维度评分 + 录音。
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/shared/swallow_error.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/domain/entities/mood_entry_draft.dart';
import 'package:chroniccare/presentation/providers/core_providers.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页快速记心情 carousel
///
/// 4 档 IP 化太阳 emoji (R81-1 跟 B 站风格对齐), 1 tap 写
/// [MoodEntryDraft] (score=1-5, 其他维度留 null)。
///
/// 完整 4 维度评分走 [MoodDialog] (右上角 "more" icon 入口)。
class QuickMoodCarousel extends ConsumerStatefulWidget {
  final VoidCallback onOpenFullDialog;

  const QuickMoodCarousel({super.key, required this.onOpenFullDialog});

  @override
  ConsumerState<QuickMoodCarousel> createState() => _QuickMoodCarouselState();
}

class _QuickMoodCarouselState extends ConsumerState<QuickMoodCarousel> {
  // R81: 4 档状态 — 1=很差 2=差 3=一般 4=好 5=很好
  // (跟 MoodEntryDraft.score 1-5 一致, 5 档 = 5 太阳 emoji)
  // 公开 4 档 (B 站对齐) + 1 隐藏档 (5 很好, 显示在最后一屏)
  static const _scores = [1, 2, 3, 4, 5];

  int _selected = 3; // 默认选中"一般" (R82+ 评估是否改为 null)
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
      // v0.22 round 30 (emil P2-4): 走 Haptics.success 集中器
      // (用户输入成功, tens/day 频度 OK)
      // R82+ 加 Haptics 集中器
    } catch (e, st) {
      swallowError(
        where: 'QuickMoodCarousel._recordQuick',
        error: e,
        stack: st,
        note: '1 tap 速记 mood 失败, 用户可改走 MoodDialog',
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.spacingMd,
        vertical: AppTokens.spacingSm,
      ),
      decoration: BoxDecoration(
        color: AppTokens.tintedPrimaryDeep(context).withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
      ),
      child: Column(
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
          SizedBox(
            // v0.28 R81: 横滑 PageView, 4 档可见 + 1 档隐藏
            // (B 站同款, 主屏聚焦 1 档 + 左右滑探索)
            height: 80,
            child: PageView.builder(
              controller: PageController(
                initialPage: 2, // 默认居中"一般" (index 2 = score 3)
                viewportFraction: 0.4,
              ),
              itemCount: _scores.length,
              onPageChanged: (i) => setState(() => _selected = _scores[i]),
              itemBuilder: (ctx, i) {
                final score = _scores[i];
                final isSelected = score == _selected;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: PressFeedback(
                    onTap: _saving ? null : () => _recordQuick(score),
                    child: AnimatedContainer(
                      duration: Motion.duration(context, AppTokens.durFast),
                      curve: Motion.curve(context, AppTokens.curveStandard),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTokens.tintedPrimarySoft(context)
                            : Colors.transparent,
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusCard),
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            MoodVisual.ipEmojiFor(score),
                            style: const TextStyle(fontSize: 32),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            MoodVisual.labelFor(score),
                            style: TextStyle(
                              fontSize: AppTokens.fontSizeCaption,
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : AppTokens.textHintColor(context),
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
