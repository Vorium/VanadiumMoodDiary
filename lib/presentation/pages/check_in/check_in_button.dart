import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 主页大按钮：「我今天吃了药」
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
    return SizedBox(
      width: double.infinity,
      height: AppTokens.buttonHeight,
      child: AnimatedContainer(
        // v0.17 round 1 (A3 emil 动效): isChecked 切换时背景色 +
        // 圆角缓慢过渡。durations + curve 来自 AppTokens,统一项目风格。
        // v0.21 Round 22 (P1-13 修复): wrap Motion.duration
        // 让系统开 reduce-motion 时动效瞬时完成
        duration: Motion.duration(context, AppTokens.durNormal),
        curve: AppTokens.curveStandard,
        decoration: BoxDecoration(
          // v0.21 (P1-9 fix): 用 disabledColor 跟 theme 走,
          // 之前用静态 AppTokens.disabled 在 dark mode 下是浅灰看不见
          color:
              isChecked ? AppTokens.disabledColor(context) : AppTokens.primary,
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isChecked || isLoading) ? null : onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            // InkWell 默认 splashFactory = InkRipple,跟 M3 风格一致
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 用 AnimatedSwitcher 切"今天已打卡 ✓ ↔ 我今天吃了药"
                // 文字颜色 + 字号都自动过渡,emil 决策框架:occasional 频度
                // (一天看几次) → 标准 animation 适用
                AnimatedSwitcher(
                  duration: AppTokens.durNormal,
                  switchInCurve: AppTokens.curveStandard,
                  switchOutCurve: AppTokens.curveAccelerate,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  ),
                  child: Column(
                    key: ValueKey<bool>(isChecked),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        isChecked
                            ? AppLocalizations.of(context).homeCheckedIn
                            : AppLocalizations.of(context).homeCheckIn,
                        style: const TextStyle(
                          fontSize: AppTokens.fontSizeButton,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // streak 数字 A6: TweenAnimationBuilder 让数字递增
                      // 状态切换时数字"飞"过去(emil: rare 频度可加 delight)
                      _StreakCounter(
                        value: streakDays,
                        isChecked: isChecked,
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const IgnorePointer(
                    child: LoadingSpinner(
                      size: 24,
                      color: Colors.white,
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

/// A6: streak 数字 tween 递增（emil 决策:rare / 庆祝频度 → 可加 delight）
///
/// 状态切换瞬间数字从 0 跳到 N 太突兀,tween 让它"飞"过去。
/// duration 用 durSlow(500ms) + curveDelight(elasticOut) 制造"弹一下"的感觉。
/// 性能: 数字变化频度极低(tens/day),不担心 rebuild 成本。
///
/// v0.21 Round 25 (P2 polish): 起始值用上次 value 而非 0
/// 之前 `Tween(begin: 0, end: value)` 在父级 rebuild 时也会触发 tween 0→value
/// 例如: 用户已坚持 30 天,父级 setState 后 _StreakCounter 重建,数字会从 0 飞回 30
/// 修法: StatefulWidget 缓存 _lastValue, 仅在 value 真的变了时 tween
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
  // v0.22 round 28 (emil-bug-03): 抽 _tickListener 字段复用,避免 didUpdateWidget
  // 每次 value 变化都新 add 1 个匿名 listener → controller 持有 N 个 listener,
  // 每次 tick 触发 N 次 setState → 指数级 rebuild 风险
  late final VoidCallback _tickListener;

  @override
  void initState() {
    super.initState();
    _currentAnimated = widget.value.toDouble();
    _controller = AnimationController(
      vsync: this, // State 本身实现 TickerProvider (SingleTickerProviderStateMixin)
      duration: AppTokens.durSlow,
    );
    // 1 个稳定引用,didUpdateWidget 复用
    _tickListener = () {
      setState(() {
        // tween 从 _lastValue 到当前 widget.value (用最新 widget 字段而非闭包捕获)
        _currentAnimated =
            _lastValue + (widget.value - _lastValue) * _controller.value;
      });
    };
    _controller.addListener(_tickListener);
  }

  @override
  void didUpdateWidget(covariant _StreakCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) {
      // 起始用上次动画结束时的值 (_currentAnimated.round),避免父级 rebuild
      // 时数字"飞回 0" (v0.21 P2-12 修过 0 跳回 bug,本 round 加 listener leak fix)
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
    return Text(
      // v0.17 round 14 (P2-12): 走 ARB homeStreak 模板 (zh: 已坚持 X 天 /
      // en: X-day streak)。emoji 不在 string 里 — 频度高 (10+/day),
      // emoji 在大按钮里反视觉噪声。
      AppLocalizations.of(context).homeStreak(_currentAnimated.round()),
      style: TextStyle(
        fontSize: AppTokens.fontSizeLabel,
        color: Colors.white.withValues(alpha: 0.85),
        height: 1.2,
      ),
    );
  }
}
