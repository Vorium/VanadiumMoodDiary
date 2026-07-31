// v0.22 round 33 (sp-en P0): 上次启动 error banner
//
// 配 [LastErrorCapture]: 如果上次启动有未捕获 error, 启动后顶部显示一个
// 可关闭的 banner 提示用户"上次启动出错，请截图反馈"，避免 release 模式
// 静默 swallow 让用户 / 开发者看不到任何信号。
import 'package:flutter/material.dart';

import 'package:chroniccare/core/data/services/last_error_capture.dart';
import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// "上次启动出错" 顶部 banner
///
/// State 管理:
/// - 启动时 consume 一次 (返回 null = 上次启动 OK, banner 不显示)
/// - 用户点关闭 → setState 隐藏 (本会话内不再显示)
class LastStartupErrorBanner extends StatefulWidget {
  const LastStartupErrorBanner({super.key, required this.child});

  final Widget child;

  @override
  State<LastStartupErrorBanner> createState() =>
      _LastStartupErrorBannerState();
}

class _LastStartupErrorBannerState extends State<LastStartupErrorBanner> {
  LastError? _lastError;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final err = await LastErrorCapture.consume();
    if (!mounted) return;
    setState(() => _lastError = err);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showBanner = _lastError != null && !_dismissed;
    return Stack(
      children: [
        widget.child,
        if (showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Material(
                color: AppTokens.tintedErrorSoft(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTokens.spacingMd,
                    vertical: AppTokens.spacingSm,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: AppTokens.fgOnError(context),
                        size: AppTokens.iconSize,
                      ),
                      const SizedBox(width: AppTokens.spacingSm),
                      Expanded(
                        child: Text(
                          // v0.23 round 39 (P1-9 fix): 走 ARB i18n
                          l10n.lastStartupErrorBannerBody,
                          style: AppTokens.textStyleLabel(context).copyWith(
                            color: AppTokens.fgOnError(context),
                          ),
                        ),
                      ),
                      // v0.27 round 62 (P1-15 修复): 改用 PressFeedbackIconButton 集中器
                      PressFeedbackIconButton(
                        icon: Icons.close,
                        size: AppTokens.iconSize,
                        color: AppTokens.fgOnError(context),
                        onPressed: () => setState(() => _dismissed = true),
                        tooltip: l10n.commonClose,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
