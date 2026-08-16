// v1.1.0 R114 (Wave D, spec §5.5): mood 5 档大圆形评分按钮
//
// Apple Health 风格 5 档圆形 mood button (72x72) 横向排布 + spring 选中。
// spec §5.5 "5 档大圆形 mood button（72x72）横向 spring 选中" — v0.31
// redesign 遗留的 mood 打磨项, R114 落地。
//
// 设计:
// - 72pt 圆形 (AppSpacing.moodScoreButtonSize), 窄屏按比例收缩 ≥48pt
//   (AppSpacing.moodScoreButtonMinSize, Apple HIG 44 / M3 48 触达下限)
// - 选中态: 圆 fill moodScoreColor(score) (R32 5 元色板) + 下方 label
//   moodScoreFgColor(score) 深色档 (R112 EM-16b 同族对比度达标)
// - 未选中态: 透明圆 + hairline 边框 + textHint label
// - 选中瞬间 Spring.standard (stiffness 200 / damping 20, 临界阻尼 ~0.4s
//   轻过冲) scale 0.92 → 1.0 pop; reduce-motion 归零直跳终态
//   (跟 check_in_button._EntrySpring 同款接线, R113 BUG6 模式)
// - 按下走 PressFeedback scale 0.97 + Haptics.light (emil "被听见")
// - emoji 走 MoodVisual.emojiFor (😢😟😐🙂😄 标准人脸 5 档, 跟旧 slider
//   端点 😢/😄 语言一致); label 走 l10n moodLabel1-5 (3 语)
// - 语义: AppSemantics.container(moodRatingSemantics) + button
//   (moodRatingButtonSemantics, 跟 DimensionRow 同款)
//
// 频度: tens/day (mood 录入核心动作) — 标准动画档
//
// 使用: CbtThreeColumnMode 移出后由 mood_recorder_page 情绪评分组直挂;
// CbtWizard step 2 / step 3 同款复用 (统一 5 档按钮唯一实现)。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/shared/mood_visual.dart';
import 'package:chroniccare/core/theme/app_colors.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/spring.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 5 档大圆形 mood 评分按钮 (72pt, spec §5.5)
///
/// 横向排布 5 个圆形按钮 (1-5), 选中态 spring scale pop。
/// Stateless: value 从父 state 来, onChanged 上抛 (跟旧 DimensionRow 接口一致)。
class MoodScoreButtons extends StatelessWidget {
  /// 当前选中分数 (1-5)
  final int value;

  /// 点击某档回调 (score 1-5)
  final ValueChanged<int> onChanged;

  const MoodScoreButtons({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppSemantics.container(
      label: l10n.moodRatingSemantics,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 72pt 理想尺寸; 窄屏 (5 个并排装不下) 按比例收缩到 ≥48pt,
          // 间距同时收缩 (12 → 0), 保证 5 个按钮始终一排放得下。
          final maxWidth = constraints.maxWidth;
          const maxSize = AppTokens.moodScoreButtonSize;
          const minSize = AppTokens.moodScoreButtonMinSize;
          final ideal = (maxWidth - 4 * AppTokens.spacingSm) / 5;
          final size = ideal.clamp(minSize, maxSize);
          final gap =
              ((maxWidth - 5 * size) / 4).clamp(0.0, AppTokens.spacingSm);
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (int s = 1; s <= 5; s++) ...[
                if (s > 1) SizedBox(width: gap),
                _MoodScoreButton(
                  score: s,
                  selected: value == s,
                  size: size,
                  l10n: l10n,
                  onTap: () => onChanged(s),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// 单个圆形档位按钮 — spring 选中态 + PressFeedback 按下反馈
class _MoodScoreButton extends StatefulWidget {
  final int score;
  final bool selected;
  final double size;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _MoodScoreButton({
    required this.score,
    required this.selected,
    required this.size,
    required this.l10n,
    required this.onTap,
  });

  @override
  State<_MoodScoreButton> createState() => _MoodScoreButtonState();
}

class _MoodScoreButtonState extends State<_MoodScoreButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring;

  @override
  void initState() {
    super.initState();
    // Spring.standard 是 SpringSimulation 必要条件 (unbounded)。
    // 初始 (未选中 / 已选中挂载) 都停在终态 1.0 — 选中动画只在用户
    // 点击切换时播 (dialog 打开不播进场 spring)。
    _spring = AnimationController.unbounded(vsync: this, value: 1.0);
  }

  @override
  void didUpdateWidget(_MoodScoreButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 从未选中 → 选中: 播 Spring.standard 0→1 (scale 0.92 → 1.0 轻过冲)。
    // reduce-motion 时直跳终态 (跟 didChangeDependencies 双保险)。
    if (!oldWidget.selected && widget.selected) {
      if (Motion.prefersReduced(context)) {
        _spring.value = 1.0;
      } else {
        _spring.value = 0.0;
        _spring.animateWith(
          Spring.standard.toSimulation(from: 0.0, to: 1.0, velocity: 0.0),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // R113 BUG6 同款: 尊重 prefers-reduced-motion — spring 进行中开
    // 系统设置则直跳终态 (前庭敏感用户 0 弹跳)。
    if (Motion.prefersReduced(context) && _spring.value < 1.0) {
      _spring.value = 1.0;
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final score = widget.score;
    final selected = widget.selected;
    final size = widget.size;
    return PressFeedback(
      onTap: widget.onTap,
      child: AppSemantics.button(
        inMutuallyExclusiveGroup: true,
        selected: selected,
        label: l10n.moodRatingButtonSemantics(
          score,
          selected ? 'true' : 'false',
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 圆形: spring scale pop (Transform.scale) 包 AnimatedContainer
            // 颜色渐变 (reduce-motion 时 color 动画归零, 见 Motion.duration)
            AnimatedBuilder(
              animation: _spring,
              builder: (context, _) {
                // Spring value 范围 [0, 1+] (damping 20 临界阻尼轻过冲),
                // scale 跟随过冲 = 弹感。终态 t=1.0 → scale 1.0。
                final t = _spring.value;
                final scale = 0.92 + t * 0.08;
                return Transform.scale(
                  key: ValueKey('mood-score-scale-$score'),
                  scale: scale,
                  child: _ScoreCircle(
                    score: score,
                    selected: selected,
                    size: size,
                  ),
                );
              },
            ),
            const SizedBox(height: AppTokens.spacingXxs),
            AnimatedDefaultTextStyle(
              duration: Motion.duration(context, AppTokens.durFast),
              curve: Motion.curve(context, AppTokens.curveStandard),
              style: TextStyle(
                fontSize: AppTokens.fontSizeCaption,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected
                    ? AppColors.moodScoreFgColor(score)
                    : AppTokens.textHintColor(context),
              ),
              child: Text(
                switch (score) {
                  1 => l10n.moodLabel1,
                  2 => l10n.moodLabel2,
                  3 => l10n.moodLabel3,
                  4 => l10n.moodLabel4,
                  _ => l10n.moodLabel5,
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 圆形面: 选中 = moodScoreColor 实心, 未选中 = 透明 + hairline 边框
class _ScoreCircle extends StatelessWidget {
  final int score;
  final bool selected;
  final double size;

  const _ScoreCircle({
    required this.score,
    required this.selected,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: Motion.duration(context, AppTokens.durFast),
      curve: Motion.curve(context, AppTokens.curveStandard),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            selected ? AppColors.moodScoreColor(score) : AppColors.transparent,
        border: selected
            ? null
            : Border.all(
                width: 0.5,
                color: AppTokens.borderColor(context),
              ),
      ),
      child: Center(
        child: Text(
          MoodVisual.emojiFor(score),
          style: const TextStyle(
            fontSize: AppTokens.fontSizeScoreXl,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
