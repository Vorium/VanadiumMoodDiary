import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';

/// 主页顶部 header:用户名 + 趋势/评估/设置 入口
///
/// v0.18 round 18 (P1-27): 从 home_page 抽出,减少 god-page 行数。
/// 之前是 build 方法内联 Row,现在单独 widget 隔离样式。
class HomeHeader extends StatelessWidget {
  final String userName;
  final String? fallbackTitle;

  const HomeHeader({
    super.key,
    required this.userName,
    this.fallbackTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            userName.isEmpty
                ? (fallbackTitle ?? '慢病管家')
                : '$userName 还在坚持',
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
          tooltip: '查看趋势',
        ),
        IconButton(
          icon: const Icon(Icons.psychology_outlined),
          onPressed: () => context.push('/assessment/history'),
          tooltip: '评估历史',
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
