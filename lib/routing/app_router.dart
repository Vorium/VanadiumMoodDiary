import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_tokens.dart';
import '../../theme/theme_toggle_button.dart';
import '../presentation/pages/assessment/assessment_history_page.dart';
import '../presentation/pages/assessment/assessment_page.dart';
import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/medication/medication_calendar_page.dart';
import '../presentation/pages/settings/refill_manage_page.dart';
import '../presentation/pages/settings/reminders_hub_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/settings/widgets/email_preview.dart';
import '../presentation/pages/setup/setup_page.dart';
import '../presentation/pages/trend/trend_page.dart';
import '../presentation/providers/data_providers.dart';

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  // 监听用户档案，判断是否已设置
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final profile = profileAsync.valueOrNull;
      final isSetupDone = profile != null;
      final goingToSetup = state.matchedLocation == '/setup';

      if (!isSetupDone && !goingToSetup) return '/setup';
      if (isSetupDone && goingToSetup) return '/';
      return null;
    },
    routes: [
      // 设置流程不进 shell（全屏引导）
      GoRoute(
        path: '/setup',
        builder: (_, __) => const SetupPage(),
      ),
      // 主 app shell：宽屏带 NavigationRail，窄屏纯 body
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(path: '/', builder: (_, __) => const HomePage()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsPage(),
          ),
          GoRoute(
            path: '/email-preview',
            builder: (_, __) => const EmailPreviewPage(),
          ),
          // v0.14 (Round 12C) 提醒中心
          GoRoute(
            path: '/settings/reminders',
            builder: (_, __) => const RemindersHubPage(),
          ),
          // v0.14 (Round 13A) 续方管理
          GoRoute(
            path: '/settings/refills',
            builder: (_, __) => const RefillManagePage(),
          ),
          GoRoute(
            path: '/trend',
            builder: (_, __) => const TrendPage(),
          ),
          GoRoute(
            path: '/assessment',
            redirect: (_, __) => '/assessment/phq9',
          ),
          // v0.14 (Round 13B) 评估历史独立页
          // ⚠️ 必须在 :id 之前声明，否则 :id 会先匹配（GoRouter 按声明顺序匹配）
          GoRoute(
            path: '/assessment/history',
            builder: (_, __) => const AssessmentHistoryPage(),
          ),
          GoRoute(
            path: '/assessment/:id',
            builder: (_, state) => AssessmentPage(
              scaleId: state.pathParameters['id'] ?? 'phq9',
            ),
          ),
          // v0.14 (Round 13C) 用药日历（医生视角热力图）
          GoRoute(
            path: '/medication/calendar',
            builder: (_, __) => const MedicationCalendarPage(),
          ),
          // ============== Round 5: Deep Linking 路由 ==============
          // 点 medication 通知 → 直接跳 home 并自动打卡该药
          // 不经过 3 步首页流程（参考 HealthReminder）
          GoRoute(
            path: '/check-in/medication/:id',
            redirect: (_, state) {
              final medId = state.pathParameters['id'] ?? '0';
              return '/?medId=$medId&autofire=1';
            },
          ),
          // 点 default / soft 通知 → 跳 home
          GoRoute(
            path: '/check-in/today',
            redirect: (_, state) {
              final reason = state.uri.queryParameters['reason'];
              if (reason == 'safety') {
                return '/?reason=safety';
              }
              return '/';
            },
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面不存在: ${state.matchedLocation}'),
      ),
    ),
  );
});

/// 响应式 shell：
/// - 窄屏（< 840）：只显示 child（页面），无侧栏
/// - 宽屏（>= 840）：左侧 NavigationRail（extended 模式，显示文字）+ 右侧 child
class AppShell extends ConsumerWidget {
  final Widget child;
  final String currentLocation;

  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  static const _destinations = [
    _NavDest(
      label: '打卡',
      icon: Icons.check_circle_outline,
      selectedIcon: Icons.check_circle,
      path: '/',
    ),
    _NavDest(
      label: '设置',
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      path: '/settings',
    ),
  ];

  int get _currentIndex {
    for (int i = 0; i < _destinations.length; i++) {
      if (currentLocation == _destinations[i].path) return i;
      // /email-preview 算设置子页
      if (_destinations[i].path == '/settings' &&
          currentLocation.startsWith('/settings')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide =
            constraints.maxWidth >= AppTokens.breakpointExpanded;
        if (!isWide) {
          // 窄屏：去掉各页面自己的 AppBar（shell 不管），child 自行处理
          return child;
        }
        return Row(
          children: [
            SizedBox(
              width: AppTokens.navRailExtendedWidth,
              child: NavigationRail(
                extended: true,
                minWidth: AppTokens.navRailWidth,
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) =>
                    context.go(_destinations[i].path),
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
                        '慢病管家',
                        style: TextStyle(
                          fontSize: AppTokens.fontSizeLabel,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const ThemeToggleButton(),
                    ],
                  ),
                ),
                destinations: [
                  for (final d in _destinations)
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
