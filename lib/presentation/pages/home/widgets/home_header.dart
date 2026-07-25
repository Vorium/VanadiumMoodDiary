import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback_icon_button.dart';

/// 主页顶部 header:用户名 + 趋势/评估/设置 入口
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出，减少 god-page 行数。
/// 之前是 build 方法内联 Row,现在单独 widget 隔离样式。
/// v0.24 round 43 (emil P1-01 H-01): 3 个 IconButton 改用
/// `PressFeedbackIconButton` 集中器, 跟 vent_list / theme_toggle 体感一致
class HomeHeader extends StatelessWidget {
  final String userName;

  const HomeHeader({
    super.key,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            userName.isEmpty
                ? AppLocalizations.of(context).homeHeaderDefaultTitle
                : AppLocalizations.of(context).homeHeaderKeepGoing(userName),
            style: TextStyle(
              fontSize: AppTokens.fontSizeHeadline,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        PressFeedbackIconButton(
          icon: Icons.show_chart,
          tooltip: AppLocalizations.of(context).homeTooltipTrend,
          onTap: () => context.push('/trend'),
        ),
        PressFeedbackIconButton(
          icon: Icons.psychology_outlined,
          tooltip: AppLocalizations.of(context).homeTooltipAssessmentHistory,
          onTap: () => context.push('/assessment/history'),
        ),
        PressFeedbackIconButton(
          icon: Icons.settings_outlined,
          tooltip: AppLocalizations.of(context).settingsAbout,
          onTap: () => context.push('/settings'),
        ),
      ],
    );
  }
}
