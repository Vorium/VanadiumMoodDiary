import 'package:flutter/material.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/app_semantics.dart';
import 'package:chroniccare/presentation/widgets/loading_skeleton.dart';

/// 主页大按钮：「我今天吃了药」
///
/// v0.23 P1 refactor: 从 presentation/pages/check_in/ 移到 widgets/，
/// 解除 home → check_in 跨 feature import。
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
        duration: Motion.duration(context, AppTokens.durNormal),
        curve: AppTokens.curveStandard,
        decoration: BoxDecoration(
          color:
              isChecked ? AppTokens.disabledColor(context) : AppTokens.primaryColor(context),
          borderRadius: BorderRadius.circular(AppTokens.radiusButton),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (isChecked || isLoading) ? null : onPressed,
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedSwitcher(
                  duration: Motion.duration(context, AppTokens.durNormal),
                  switchInCurve:
                      Motion.curve(context, AppTokens.curveStandard),
                  switchOutCurve:
                      Motion.curve(context, AppTokens.curveAccelerate),
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
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeButton,
                          fontWeight: FontWeight.w600,
                          height: AppTokens.lineHeightTight,
                          color: AppTokens.fgOnPrimary(context),
                        ),
                      ),
                      const SizedBox(height: AppTokens.spacingXxs),
                      _StreakCounter(
                        value: streakDays,
                        isChecked: isChecked,
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  IgnorePointer(
                    child: LoadingSpinner(
                      size: 24,
                      color: AppTokens.fgOnPrimary(context),
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

/// streak 数字 tween 递增
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
