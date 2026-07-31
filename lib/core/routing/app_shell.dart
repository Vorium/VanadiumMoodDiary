// v0.25 round 59: AppShell 抽离 (app_router god class 拆分)
//
// 装 AppShell class (响应式 shell — 窄屏纯 body / 宽屏 NavigationRail extended)
// + _NavDest data class. 14 个 GoRoute 跟 3 transition helper 在 app_routes.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/theme_toggle_button.dart';

/// v0.25 round 59 (spen P1 #12 god class 拆分续): 响应式 shell
///
/// - 窄屏 (< 840): 只显示 child (页面), 无侧栏
/// - 宽屏 (>= 840): 左侧 NavigationRail (extended 模式, 显示文字) + 右侧 child
class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentLocation;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  static List<_NavDest> _destinations(BuildContext context) {
    final l10n = Localizations.of<AppLocalizations>(context, AppLocalizations);
    return [
      _NavDest(
        // v0.25 round 52 (spen P0 #11): i18n 失败时 fallback 改英文,
        // 不再用 mojibake 中文 ('鎵撳崱' / '璁剧疆' 是 Big5 错码后的乱码)
        label: l10n?.navCheckIn ?? 'Check-in',
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
        path: '/',
      ),
      _NavDest(
        // v0.25 round 52: 同上 'Settings' fallback
        label: l10n?.navSettings ?? 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        path: '/settings',
      ),
    ];
  }

  int _currentIndex(BuildContext context) {
    final dests = _destinations(context);
    for (int i = 0; i < dests.length; i++) {
      if (currentLocation == dests[i].path) return i;
      // /email-preview 算设置子页
      if (dests[i].path == '/settings' &&
          (currentLocation.startsWith('/settings') ||
              currentLocation == '/email-preview')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= AppTokens.breakpointExpanded;
        if (!isWide) {
          // 窄屏: 去掉各页面自己的 AppBar (shell 不管), child 自行处理
          return child;
        }
        return Row(
          children: [
            SizedBox(
              width: AppTokens.navRailExtendedWidth,
              child: NavigationRail(
                extended: true,
                minWidth: AppTokens.navRailWidth,
                selectedIndex: _currentIndex(context),
                onDestinationSelected: (i) =>
                    context.go(_destinations(context)[i].path),
                leading: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Column(
                    children: [
                      Icon(
                        Icons.favorite_outline,
                        size: 32,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Localizations.of<AppLocalizations>(
                              context,
                              AppLocalizations,
                            )?.navAppName ??
                            // v0.25 round 52 (spen P0 #11): i18n 失败 fallback
                            // 改英文 'ChronicCare', 不用 '慢病管家' 硬编
                            'ChronicCare',
                        // v0.27 round 63 (P1-10 修复): 走
                        // AppTokens.textStyleLabelStrong 集中器, 替代 inline
                        // TextStyle(fontSize + fontWeight + color)。emil P2-12
                        // 修 80% 剩 20%, 这处是漏网之鱼; 统一 token 让 dark
                        // mode / fontScale 集中改。
                        style: AppTokens.textStyleLabelStrong(context),
                      ),
                      const SizedBox(height: 8),
                      const ThemeToggleButton(),
                    ],
                  ),
                ),
                destinations: [
                  for (final d in _destinations(context))
                    NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.selectedIcon),
                      label: Text(d.label),
                    ),
                ],
              ),
            ),
            VerticalDivider(
              width: 1,
              thickness: 1,
              color: Theme.of(context).dividerColor,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}

class _NavDest {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String path;
  const _NavDest({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.path,
  });
}
