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
// Apple Health 风格 (spec §3.4.3 spring physics + §4.2 Apple Health giant pill (64pt height, 32pt radius, w700 fontWeight)) [R32 集中器注释, 防后续误改为 Material 3 风格]

import 'package:chroniccare_theme/chroniccare_theme.dart';
import 'package:chroniccare/core/theme/spring.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/animations/tween_number.dart';
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

  /// 1.1.0 round 5b (Task 12): compact 变体 — 打卡从"巨型 pill 主 CTA"
  /// 降级为普通按钮后使用 (height 48 / radius 24 / 字号 fontSizeButton 17)
  final bool compact;

  /// Wave 7 (Task A, R113): 是否播放 _EntrySpring 进场 (scale 0.95→1 +
  /// opacity 0→1)。false → 直接跳到终态 (controller.value=1.0)。
  /// 主页 tab 切回 (非首次 mount) 时传 false, 避免每次切 tab 重播
  /// ~0.4s spring。其他 caller 默认 true (行为不变)。
  final bool animateEntry;

  const CheckInButton({
    super.key,
    required this.isChecked,
    required this.streakDays,
    required this.onPressed,
    this.isLoading = false,
    this.compact = false,
    this.animateEntry = true,
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
    // 1.1.0 round 5b (Task 12): compact 降级尺寸 — 48/24/17 (按钮标准档,
    // 全圆角保持药丸感)
    final height = compact ? 48.0 : pillHeight;
    final radius = compact ? 24.0 : pillRadius;
    final fontSize = compact ? AppTokens.fontSizeButton : pillFontSize;

    final fg = AppTokens.fgOnPrimary(context);
    final fgMuted = AppTokens.fgOnPrimaryMuted(context);

    return SizedBox(
      width: double.infinity,
      height: height,
      child: _EntrySpring(
        animateEntry: animateEntry,
        child: PressFeedback(
          // v0.31 R6: PressFeedback 替换 InkWell, mode 1 (带 onTap) 处理
          // tap+disabled. onTap null 时 PressFeedback 降级到 mode 2 (Listener)
          // 仍可触发 scale 视觉反馈, 行为跟旧 InkWell 一致.
          // v0.32 round 8 (R111 EM-14 fix): 完成/加载态 enabled=false,
          // 禁用态无 scale + haptic 假反馈
          enabled: !isChecked && !isLoading,
          onTap: (isChecked || isLoading) ? null : onPressed,
          child: AnimatedContainer(
            duration: Motion.duration(context, AppTokens.durNormal),
            curve: Motion.curve(context, AppTokens.curveStandard),
            decoration: BoxDecoration(
              color: isChecked
                  ? AppTokens.disabledColor(context)
                  : AppTokens.primaryColor(context),
              borderRadius: BorderRadius.circular(radius),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Motion.duration(context, AppTokens.durNormal),
                  // v0.31 R6: 入场用 spring 庆祝 (scale 0.95→1)
                  switchInCurve: Motion.curve(context, AppTokens.curveSpring),
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
                    fontSize: fontSize,
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
    final String mainText = isChecked ? l10n.homeCheckedIn : l10n.homeCheckIn;
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

/// v0.31.1 R10 (P0-08): 进场 spring 物理模型动画 (scale 0.95→1 + opacity 0→1).
///
/// v0.31 R6 原版走 `Curves.easeOutCubic` 风格 cubic bezier (`AppTokens.curveSpring`),
/// 但 spec §3.4.3 要求 iOS-style 物理 spring — 双轨制 (curve token + spring
/// physics). 跨视角共识修 (emil P0-E + superpowers-en P1 + Apple Health P0-3):
/// Spring.standard.toSimulation() 提供更"物理"的进场弹性, 跟外层
/// AnimatedContainer (curveStandard, durNormal) 形成 spring + curve 双轨.
///
/// 用 StatefulWidget 而非 TweenAnimationBuilder:
/// - 仅一次性 (不像 streak 数字 tween 需要响应 prop 变化)
/// - 明确 dispose() controller, 避免 check_widget_dispose 守门员报警
/// - `AnimationController.unbounded` 是 SpringSimulation 必要条件
///   (SpringSimulation 会让 value 过冲/下冲 1.0, bounded controller 会 clamp
///   破坏物理形态). pumpAndSettle 自然等待 SpringSimulation.isDone.
class _EntrySpring extends StatefulWidget {
  final Widget child;
  final bool animateEntry;
  const _EntrySpring({required this.child, this.animateEntry = true});

  @override
  State<_EntrySpring> createState() => _EntrySpringState();
}

class _EntrySpringState extends State<_EntrySpring>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    // v0.31.1 R10 (P0-08): Spring 物理模型 (spec §3.4.3)
    // unbounded controller 是 SpringSimulation 必要条件
    _controller = AnimationController.unbounded(vsync: this);
    // Wave 7 (Task A, R113): 非首次 mount (tab 切回) 直接跳到终态
    // (scale 1.0 / opacity 1.0), 不播 ~0.4s spring。首次 mount 走
    // animateWith 完整播放 (首启动自然体验保留)。
    if (!widget.animateEntry) {
      _controller.value = 1.0;
      return;
    }
    // Spring.standard = (mass: 1, stiffness: 200, damping: 20) —
    // 临界阻尼 ~0.4s, 轻度过冲, iOS push 行为
    // from=0.0, to=1.0: SpringSimulation 的 0→1 进程,
    // build() 内手动把 0..1 映射成 scale 0.95..1.0 + opacity 0..1
    _controller.animateWith(
      Spring.standard.toSimulation(from: 0.0, to: 1.0, velocity: 0.0),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // R113 (BUG 6): 尊重 prefers-reduced-motion — 全 lib 唯一绕过 Motion
    // 包装的动画。修前 Spring 进场无条件跑 (0.4s 弹跳), reduce-motion
    // 用户每次进首页都眩晕。修后跟 FadeIn.didChangeDependencies 同款:
    // 系统开了直接跳到终态 (scale 1.0 / opacity 1.0), 并停止 simulation。
    if (Motion.prefersReduced(context) && _controller.value < 1.0) {
      _controller.value = 1.0;
    }
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
      builder: (_, child) {
        // Spring value 范围: [0, 1+] (damping=20 临界阻尼, 极轻过冲).
        // t 可能轻微过冲 1.0, 允许 scale 跟随 (弹感).
        // opacity 严格 clamp 到 [0, 1] (透明度不能 > 1, 否则渲染无变化但语义错).
        final t = _controller.value;
        final scale = 0.95 + t * 0.05;
        final opacity = t.clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: widget.child,
    );
  }
}

/// streak 数字 tween 递增 (v0.17 round 1 / v0.23 P1 保留, R6 未动)
// R32 (P1-13 superpowers-en): 改用公共 TweenNumber widget (跟 stat_card._TweenNumber 95% 重复)
class _StreakCounter extends StatelessWidget {
  final int value;
  final bool isChecked;
  const _StreakCounter({required this.value, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return TweenNumber(
      value: value,
      builder: (ctx, current) {
        final streakText = AppLocalizations.of(ctx).homeStreak(current);
        return AppSemantics.container(
          label: streakText,
          liveRegion: true,
          child: AppSemantics.exclude(
            child: Text(
              streakText,
              style: TextStyle(
                fontSize: AppTokens.fontSizeLabel,
                color: AppTokens.fgOnPrimaryMuted(ctx),
                height: AppTokens.lineHeightTight,
              ),
            ),
          ),
        );
      },
    );
  }
}
