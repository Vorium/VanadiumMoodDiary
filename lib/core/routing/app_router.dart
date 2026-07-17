import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/core/theme/theme_toggle_button.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_history_page.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_page.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/email_preview.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_detail_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/data_providers.dart';

/// 路由切换动画辅助函数（v0.17 round 2 / A2 emil 动效）
///
/// 频度决策（emil 决策框架）：
/// - 主导航（/, /settings）→ 偶尔切 → 简单 fade
/// - 子页（/trend, /assessment/*, /settings/reminders）→ occasional → slide-from-right
/// - 全屏深页（/setup, /vent/*）→ rare → slide-up + fade（full-screen modal 感）
Page<T> _fadePage<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppTokens.durNormal,
    reverseTransitionDuration: AppTokens.durFast,
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

Page<T> _slideRightPage<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppTokens.durNormal,
    reverseTransitionDuration: AppTokens.durFast,
    transitionsBuilder: (_, anim, __, child) {
      // 从右滑入 + 淡入（emil: 标准的 Material 风格 push 动画）
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: anim, curve: AppTokens.curveStandard),),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

Page<T> _slideUpPage<T>(LocalKey key, Widget child) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppTokens.durSlow,
    reverseTransitionDuration: AppTokens.durNormal,
    transitionsBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
            CurvedAnimation(parent: anim, curve: AppTokens.curveStandard),),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  // 监听用户档案，判断是否已设置
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // v0.17 round 3: Riverpod 3.x 改名为 .value（之前 .valueOrNull）
      final profile = profileAsync.value;
      final isSetupDone = profile != null;
      final goingToSetup = state.matchedLocation == '/setup';

      if (!isSetupDone && !goingToSetup) return '/setup';
      if (isSetupDone && goingToSetup) return '/';
      return null;
    },
    routes: [
      // 设置流程不进 shell（全屏引导）— rare 频度 → slide-up
      GoRoute(
        path: '/setup',
        pageBuilder: (_, state) =>
            _slideUpPage(state.pageKey, const SetupPage()),
      ),
      // 主 app shell：宽屏带 NavigationRail，窄屏纯 body
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          // 主导航：occasional 频度 → fade
          GoRoute(
            path: '/',
            pageBuilder: (_, state) =>
                _fadePage(state.pageKey, const HomePage()),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (_, state) =>
                _fadePage(state.pageKey, const SettingsPage()),
          ),
          // 子页：occasional → slide-from-right
          GoRoute(
            path: '/email-preview',
            pageBuilder: (_, state) =>
                _slideRightPage(state.pageKey, const EmailPreviewPage()),
          ),
          // v0.14 (Round 12C) 提醒中心
          GoRoute(
            path: '/settings/reminders',
            pageBuilder: (_, state) =>
                _slideRightPage(state.pageKey, const RemindersHubPage()),
          ),
          // v0.14 (Round 13A) 续方管理
          GoRoute(
            path: '/settings/refills',
            pageBuilder: (_, state) =>
                _slideRightPage(state.pageKey, const RefillManagePage()),
          ),
          GoRoute(
            path: '/trend',
            pageBuilder: (_, state) =>
                _slideRightPage(state.pageKey, const TrendPage()),
          ),
          GoRoute(
            path: '/assessment',
            redirect: (_, __) => '/assessment/phq9',
          ),
          // v0.14 (Round 13B) 评估历史独立页
          // ⚠️ 必须在 :id 之前声明，否则 :id 会先匹配（GoRouter 按声明顺序匹配）
          GoRoute(
            path: '/assessment/history',
            pageBuilder: (_, state) =>
                _slideRightPage(state.pageKey, const AssessmentHistoryPage()),
          ),
          GoRoute(
            path: '/assessment/:id',
            pageBuilder: (_, state) => _slideRightPage(
              state.pageKey,
              AssessmentPage(scaleId: state.pathParameters['id'] ?? 'phq9'),
            ),
          ),
          // v0.14 (Round 13C) 用药日历（医生视角热力图）
          GoRoute(
            path: '/medication/calendar',
            pageBuilder: (_, state) =>
                _slideRightPage(state.pageKey, const MedicationCalendarPage()),
          ),
          // ============== v0.15 (Round 18) 树洞 ==============
          // 全屏深页（full-screen modal feel）— rare 频度 → slide-up
          GoRoute(
            path: '/vent',
            pageBuilder: (_, state) =>
                _slideUpPage(state.pageKey, const VentListPage()),
          ),
          GoRoute(
            path: '/vent/compose',
            pageBuilder: (_, state) =>
                _slideUpPage(state.pageKey, const VentComposePage()),
          ),
          GoRoute(
            path: '/vent/detail/:id',
            pageBuilder: (_, state) => _slideUpPage(
              state.pageKey,
              VentDetailPage(
                // v0.16 round 19C fix: 用 tryParse 替代 parse，URL 是 '/abc' 时
                // 不会崩，回退到 0（找不到对应条目 → 详情页显示"找不到了"）
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
            ),
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
        final isWide = constraints.maxWidth >= AppTokens.breakpointExpanded;
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
                onDestinationSelected: (i) => context.go(_destinations[i].path),
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
