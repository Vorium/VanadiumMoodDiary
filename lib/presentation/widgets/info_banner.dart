// v0.27 round 67 (C-2 重构): "icon + 文字" 信息条集中器
//
// 背景: 3+ 处同款 `Container(padding, color: primaryLight, radius, Row(icon, text))`
//       信息条散落在 medication_calendar_page / setup_step_medication /
//       reminders_hub_page。emil "cohesion" 原则: 视觉同款 = 同一 widget。
//
// 抽到 InfoBanner 集中器, 支持 4 个 tone + 1 个 muted 变种:
// - info:    primaryLight 背景 + primaryColor 前景 (顶部说明/描述)
// - muted:   primaryLight 背景 + secondaryColor 前景 + 边框 (空状态提示)
// - warning: tintedWarningSoft 背景 + warningColor 前景
// - error:   tintedErrorSoft 背景 + errorColor 前景
//
// 5+ 处的 inline Container 全部改为 InfoBanner(...), 1 个地方改 token 全部生效。

import 'package:flutter/material.dart';

import 'package:chroniccare_theme/chroniccare_theme.dart';

/// 信息条 tone (背景 + 前景色对)
///
/// emil "cohesion" 原则: 视觉同款 = 同一 widget
enum InfoBannerTone {
  /// 顶部说明/描述 (primaryLight bg + primaryColor fg)
  info,

  /// 空状态提示 (primaryLight bg + secondaryColor fg + 边框)
  muted,

  /// 警告 (tintedWarningSoft bg + warningColor fg)
  warning,

  /// 错误 (tintedErrorSoft bg + errorColor fg)
  error,
}

/// 通用 "icon + 文字" 信息条
///
/// 用法:
/// ```dart
/// InfoBanner(
///   icon: Icons.info_outline,
///   text: l10n.someDescription,
/// )
/// // tone 变种:
/// InfoBanner(
///   icon: Icons.warning_amber_outlined,
///   text: l10n.archivedHint,
///   tone: InfoBannerTone.warning,
/// )
/// ```
class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.icon,
    required this.text,
    this.tone = InfoBannerTone.info,
    this.bordered = false,
  });

  final IconData icon;

  final String text;

  final InfoBannerTone tone;

  /// 是否加边框 (仅 [InfoBannerTone.muted] 用, 视觉上像 "空状态卡片")
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _resolveTone(context, tone);
    return Container(
      width: double.infinity,
      padding: AppTokens.edgeInsetsMd,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(
          tone == InfoBannerTone.muted
              ? AppTokens.radiusCard
              : AppTokens.radiusChip,
        ),
        border:
            bordered ? Border.all(color: AppTokens.borderColor(context)) : null,
      ),
      child: Row(
        children: [
          Icon(icon, color: fg, size: AppTokens.iconSize),
          const SizedBox(width: AppTokens.spacingSm),
          Expanded(
            child: Text(
              text,
              style: AppTokens.textStyleBody(context).copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }

  /// 返回 (背景色, 前景色) 对
  (Color, Color) _resolveTone(BuildContext context, InfoBannerTone tone) {
    switch (tone) {
      case InfoBannerTone.info:
        return (
          AppTokens.primaryLightColor(context),
          AppTokens.primaryColor(context),
        );
      case InfoBannerTone.muted:
        return (
          AppTokens.primaryLightColor(context),
          AppTokens.textSecondaryColor(context),
        );
      case InfoBannerTone.warning:
        return (
          AppTokens.tintedWarningSoft(context),
          AppTokens.warningColor(context),
        );
      case InfoBannerTone.error:
        return (
          AppTokens.tintedErrorSoft(context),
          AppTokens.errorColor(context),
        );
    }
  }
}
