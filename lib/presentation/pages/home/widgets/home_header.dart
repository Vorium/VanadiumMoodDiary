import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 主页顶部 header:用户名 + 趋势/评估/设置 入口
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出，减少 god-page 行数。
/// 之前是 build 方法内联 Row,现在单独 widget 隔离样式。
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
        IconButton(
          icon: const Icon(Icons.show_chart),
          onPressed: () => context.push('/trend'),
          tooltip: AppLocalizations.of(context).homeTooltipTrend,
        ),
        IconButton(
          icon: const Icon(Icons.psychology_outlined),
          onPressed: () => context.push('/assessment/history'),
          tooltip: AppLocalizations.of(context).homeTooltipAssessmentHistory,
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed: () => context.push('/settings'),
          tooltip: AppLocalizations.of(context).settingsAbout,
        ),
      ],
    );
  }
}
