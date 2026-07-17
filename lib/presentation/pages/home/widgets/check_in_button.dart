import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';

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
        duration: AppTokens.durNormal,
        curve: AppTokens.curveStandard,
        decoration: BoxDecoration(
          color: isChecked ? AppTokens.disabled : AppTokens.primary,
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
                        isChecked ? '今天已打卡 ✓' : '我今天吃了药',
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
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
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
class _StreakCounter extends StatelessWidget {
  final int value;
  final bool isChecked;
  const _StreakCounter({required this.value, required this.isChecked});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      // tween 0 → value,内部自动 lerp
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: AppTokens.durSlow,
      curve: AppTokens.curveDecelerate, // 数字停止用 decelerate 比 delight 更克制
      builder: (context, animatedValue, child) {
        return Text(
          '已坚持 ${animatedValue.round()} 天',
          style: TextStyle(
            fontSize: AppTokens.fontSizeLabel,
            color: Colors.white.withValues(alpha: 0.85),
            height: 1.2,
          ),
        );
      },
    );
  }
}
