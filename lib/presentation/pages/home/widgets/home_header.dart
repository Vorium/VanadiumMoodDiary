import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/press_feedback.dart';

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
        // v0.22 round 36 (emil C1/A-opp-1 P1): 3 个 IconButton 外包
        // PressFeedback (tens/day 频度, 缺 scale 反馈) — 跟 secondary_action_row
        // 模式一致 (emil-28 修过 Vent 按钮)
        PressFeedback(
          onTap: () => context.push('/trend'),
          child: IconButton(
            icon: const Icon(Icons.show_chart),
            onPressed: null, // 实际触发由 PressFeedback
            tooltip: AppLocalizations.of(context).homeTooltipTrend,
          ),
        ),
        PressFeedback(
          onTap: () => context.push('/assessment/history'),
          child: IconButton(
            icon: const Icon(Icons.psychology_outlined),
            onPressed: null,
            tooltip: AppLocalizations.of(context).homeTooltipAssessmentHistory,
          ),
        ),
        PressFeedback(
          onTap: () => context.push('/settings'),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: null,
            tooltip: AppLocalizations.of(context).settingsAbout,
          ),
        ),
      ],
    );
  }
}
