// v0.31 round 6 (Apple Health redesign · Phase 2 Task 2.2): CheckInButton 重写
//
// 历史:
// - v0.23 P1 refactor: 从 pages/check_in/ 移到 widgets/ (解除跨 feature import)
// - v0.17 round 1 (emil 动效): AnimatedContainer + AnimatedSwitcher 引入
//
// v0.31 R6 改造 (Apple Health 巨型 pill CTA):
// - 高度 64 (buttonHeight 50 + 14, **硬编码**, 跟 buttonHeight 50 不同档)
// - 圆角 32 (**硬编码全圆角**, 跟 radiusLargeButton 22 / radiusButton 14 不同档
//   —— Apple Health 巨型 pill 必须是全圆角才能出"药丸"感, 不走 token)
// - 字号 20 / w700 / lineHeightTight (fontSizeButton 17 不够 pill 大, **硬编码**)
// - 内部: Row[Icon 24pt, SizedBox 12, Column[Text 主, SizedBox 2, _StreakCounter 副]]
// - 背景: AnimatedContainer primaryColor ↔ disabledColor (durNormal 250ms, curveStandard)
// - 进场: scale 0.95 → 1.0 + opacity 0 → 1 (curveSpring, durNormal 250ms, 一次性)
// - InkWell 替换为 PressFeedback (100ms scale 0.97 按下反馈, mode 1 带 onTap)
// - 完成态: AnimatedSwitcher 切到 check icon + "已打卡" + 庆祝 scale 0.95→1 spring
//
// 保留:
// - _StreakCounter (tween 递增, 不动)
// - isLoading (spinner overlay)
// - onPressed / isChecked / streakDays
// - ARB l10n (homeCheckIn / homeCheckedIn / homeStreak) — caller 0 改动
//
// 设计选择:
// - 硬编码 64/32/20 而非新增 token: 1 次性 Apple Health pill 专用值, 跟
//   buttonHeight / radiusLargeButton / fontSizeButton 都不重叠. 加 token 会污染
//   AppSpacing / AppTypography, 留给将来若需第 2 处 pill 按钮再抽.
// - 进场动画用 _EntrySpring StatefulWidget (非 TweenAnimationBuilder):
//   仅一次性 initState forward, 明确 dispose() controller, 避免 check_widget_dispose
//   守门员报警. pumpAndSettle 自然等待 250ms 跑完, 不会跟外层 AnimatedContainer 冲突.
// - PressFeedback mode 1 (with onTap): 替换 InkWell, 自己处理 tap+disabled.
//   mode 2 (Listener) 不消费 tap, 跟"无 InkWell"组合会导致 enabled 时不响应.
//   mode 1 用 GestureDetector, onTap:null 时降级到 mode 2 (Listener) 仍可触发
//   scale 视觉反馈.
import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

/// 主页大按钮:「我今天吃了药」
///
/// v0.31 round 6 (Apple Health redesign · Phase 2 Task 2.2): 重写为 Apple Health
/// 巨型 pill CTA (64pt 高 + 32pt 全圆角 + spring 进场 + 完成态 spring 庆祝).
///
/// 保留: _StreakCounter tween 递增 / isLoading / onPressed / ARB l10n
/// (caller primary_action_row.dart 不动, 留给后续 task 改 caller).
class CheckInButton extends StatelessWidget {
  final bool isChecked;
  final int streakDays;
  final VoidCallback onPressed;
  final bool isLoading;

  const CheckInButton({
    super.key,
    required this.isChecked,
    required this.streakDays,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    // v0.31 R6: 高度 64 (buttonHeight 50 + 14, Apple Health 巨型 pill,
    // 跟 buttonHeight 50 / buttonHeightSmall 38 都不同档 → 硬编码 + 注释)
    const double pillHeight = AppTokens.buttonHeight + 14; // = 64
    // v0.31 R6: 圆角 32 (Apple Health 巨型 pill 全圆角, 跟 radiusButton 14 /
    // radiusLargeButton 22 都不同档 → 硬编码 + 注释. 必须全圆角才能出"药丸"感)
    const double pillRadius = 32;
    // v0.31 R6: 字号 20 (pill 大按钮字, fontSizeButton 17 / fontSizeBody 15
    // 都不够 pill 视觉重量 → 硬编码 + 注释)
    const double pillFontSize = 20;

    final fg = AppTokens.fgOnPrimary(context);
    final fgMuted = AppTokens.fgOnPrimaryMuted(context);

    return SizedBox(
      width: double.infinity,
      height: pillHeight,
      child: _EntrySpring(
        child: PressFeedback(
          // v0.31 R6: PressFeedback 替换 InkWell, mode 1 (带 onTap) 处理
          // tap+disabled. onTap null 时 PressFeedback 降级到 mode 2 (Listener)
          // 仍可触发 scale 视觉反馈, 行为跟旧 InkWell 一致.
          onTap: (isChecked || isLoading) ? null : onPressed,
          child: AnimatedContainer(
            duration: Motion.duration(context, AppTokens.durNormal),
            curve: Motion.curve(context, AppTokens.curveStandard),
            decoration: BoxDecoration(
              color: isChecked
                  ? AppTokens.disabledColor(context)
                  : AppTokens.primaryColor(context),
              borderRadius: BorderRadius.circular(pillRadius),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Motion.duration(context, AppTokens.durNormal),
                  // v0.31 R6: 入场用 spring 庆祝 (scale 0.95→1)
                  switchInCurve:
                      Motion.curve(context, AppTokens.curveSpring),
                  switchOutCurve:
                      Motion.curve(context, AppTokens.curveAccelerate),
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(
                      scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                        CurvedAnimation(
                          parent: anim,
                          curve: AppTokens.curveSpring,
                        ),
                      ),
                      child: child,
                    ),
                  ),
                  child: _PillContent(
                    key: ValueKey<bool>(isChecked),
                    isChecked: isChecked,
                    streakDays: streakDays,
                    fontSize: pillFontSize,
                    fg: fg,
                    fgMuted: fgMuted,
                  ),
                ),
                if (isLoading)
                  IgnorePointer(
                    child: LoadingSpinner(
                      size: 24,
                      color: fg,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// v0.31 R6: 内部 pill 内容
/// (Row[Icon 24, gap 12, Column[Text 主, gap 2, Streak 副]])
class _PillContent extends StatelessWidget {
  final bool isChecked;
  final int streakDays;
  final double fontSize;
  final Color fg;
  final Color fgMuted;

  const _PillContent({
    super.key,
    required this.isChecked,
    required this.streakDays,
    required this.fontSize,
    required this.fg,
    required this.fgMuted,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // v0.31 R6: 完成态 check icon / 未打卡 medicine icon (24pt, Apple 标准)
    final IconData iconData =
        isChecked ? Icons.check_rounded : Icons.medication_rounded;
    final String mainText =
        isChecked ? l10n.homeCheckedIn : l10n.homeCheckIn;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData, size: 24, color: fg),
        const SizedBox(width: 12),
        Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              mainText,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                height: AppTokens.lineHeightTight,
                color: fg,
              ),
            ),
            const SizedBox(height: 2),
            _StreakCounter(
              value: streakDays,
              isChecked: isChecked,
            ),
          ],
        ),
      ],
    );
  }
}

/// v0.31 R6: 进场 spring 动画 (scale 0.95→1 + opacity 0→1, curveSpring,
/// durNormal 250ms, 一次性 initState forward).
///
/// 用 StatefulWidget 而非 TweenAnimationBuilder:
/// - 仅一次性 (不像 streak 数字 tween 需要响应 prop 变化)
/// - 明确 dispose() controller, 避免 check_widget_dispose 守门员报警
/// - pumpAndSettle 自然等待 250ms 跑完, 不会跟外层 AnimatedContainer 冲突
class _EntrySpring extends StatefulWidget {
  final Widget child;
  const _EntrySpring({required this.child});

  @override
  State<_EntrySpring> createState() => _EntrySpringState();
}

class _EntrySpringState extends State<_EntrySpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.durNormal,
    );
    _scale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTokens.curveSpring),
    );
    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppTokens.curveSpring),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// streak 数字 tween 递增 (v0.17 round 1 / v0.23 P1 保留, R6 未动)
class _StreakCounter extends StatefulWidget {
  final int value;
  final bool isChecked;
  const _StreakCounter({required this.value, required this.isChecked});

  @override
  State<_StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<_StreakCounter>
    with SingleTickerProviderStateMixin {
  int _lastValue = 0;
  late AnimationController _controller;
  late double _currentAnimated;
  late final VoidCallback _tickListener;

  @override
  void initState() {
    super.initState();
    _currentAnimated = widget.value.toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: AppTokens.durSlow,
    );
    _tickListener = () {
      setState(() {
        _currentAnimated =
            _lastValue + (widget.value - _lastValue) * _controller.value;
      });
    };
    _controller.addListener(_tickListener);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = Motion.duration(context, AppTokens.durSlow);
  }

  @override
  void didUpdateWidget(covariant _StreakCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      _lastValue = _currentAnimated.round();
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_tickListener);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppSemantics.container(
      label: AppLocalizations.of(context).homeStreak(_currentAnimated.round()),
      liveRegion: true,
      child: AppSemantics.exclude(
        child: Text(
          AppLocalizations.of(context).homeStreak(_currentAnimated.round()),
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: AppTokens.fgOnPrimaryMuted(context),
            height: AppTokens.lineHeightTight,
          ),
        ),
      ),
    );
  }
}
