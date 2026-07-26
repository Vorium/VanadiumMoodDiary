import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/presentation/widgets/theme_toggle_button.dart';

/// go_router 路由配置
///
/// **架构说明**: 此文件位于 core/routing/ 并 import 了 presentation/pages/，
/// 这是 go_router 的固有限制 —— 路由必须知道页面 widget 才能构建路由。
/// 将其移至 presentation/ 会导致循环依赖（presentation → core for theme/l10n，
/// core → presentation for pages）。接受此 trade-off，已在 AGENTS.md 架构检查中豁免。
import 'package:chroniccare/presentation/pages/assessment/assessment_history_page.dart';
import 'package:chroniccare/presentation/pages/assessment/assessment_page.dart';
import 'package:chroniccare/presentation/pages/home/home_page.dart';
import 'package:chroniccare/presentation/pages/medication/medication_calendar_page.dart';
import 'package:chroniccare/presentation/pages/medication/refill_manage_page.dart';
import 'package:chroniccare/presentation/pages/settings/reminders_hub_page.dart';
import 'package:chroniccare/presentation/pages/settings/settings_page.dart';
import 'package:chroniccare/presentation/pages/settings/legal_page.dart';
import 'package:chroniccare/presentation/pages/settings/email_preview.dart';
import 'package:chroniccare/presentation/pages/setup/setup_page.dart';
import 'package:chroniccare/presentation/pages/trend/trend_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_compose_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_detail_page.dart';
import 'package:chroniccare/presentation/pages/vent/vent_list_page.dart';
import 'package:chroniccare/presentation/providers/shared_providers.dart';

/// 路由切换动画辅助函数（v0.17 round 2 / A2 emil 动效）
///
/// 频度决策（emil 决策框架）：
/// - 主导航（/, /settings）→ 偶尔切 → 简单 fade
/// - 子页（/trend, /assessment/*, /settings/reminders）→ occasional → slide-from-right
/// - 全屏深页（/setup, /vent/*）→ rare → slide-up + fade（full-screen modal 感）
///
/// v0.21 Round 22 (P1-13 修复): helper 接收 BuildContext 用于
/// 尊重 prefers-reduced-motion (Motion.duration 类)
Page<T> _fadePage<T>(LocalKey key, Widget child, BuildContext context) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: Motion.duration(context, AppTokens.durNormal),
    reverseTransitionDuration: Motion.duration(context, AppTokens.durFast),
    transitionsBuilder: (_, anim, __, child) =>
        FadeTransition(opacity: anim, child: child),
  );
}

Page<T> _slideRightPage<T>(
  LocalKey key,
  Widget child,
  BuildContext context,
) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: Motion.duration(context, AppTokens.durNormal),
    reverseTransitionDuration: Motion.duration(context, AppTokens.durFast),
    transitionsBuilder: (_, anim, __, child) {
      // 从右滑入 + 淡入（emil: 标准的 Material 风格 push 动画）
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.1, 0),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: anim, curve: AppTokens.curveStandard),
        ),
        child: FadeTransition(opacity: anim, child: child),
      );
    },
  );
}

Page<T> _slideUpPage<T>(LocalKey key, Widget child, BuildContext context) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: Motion.duration(context, AppTokens.durSlow),
    reverseTransitionDuration: Motion.duration(context, AppTokens.durNormal),
    transitionsBuilder: (_, anim, __, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.05),
          end: Offset.zero,
        ).animate(
          CurvedAnimation(parent: anim, curve: AppTokens.curveStandard),
        ),
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
        pageBuilder: (context, state) =>
            _slideUpPage(state.pageKey, const SetupPage(), context),
      ),
      // 整个 app shell：宽屏带 NavigationRail，窄屏纯 body
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          // 主导航：occasional 频度 → fade
          GoRoute(
            path: '/',
            pageBuilder: (context, state) =>
                _fadePage(state.pageKey, const HomePage(), context),
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) =>
                _fadePage(state.pageKey, const SettingsPage(), context),
          ),
          // 子页（occasional → slide-from-right）
          GoRoute(
            path: '/email-preview',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const EmailPreviewPage(), context,),
          ),
          // v0.14 (Round 12C) 提醒中心
          GoRoute(
            path: '/settings/reminders',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const RemindersHubPage(), context,),
          ),
          // v0.14 (Round 13A) 续方管理
          GoRoute(
            path: '/settings/refills',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const RefillManagePage(), context,),
          ),
          // v0.21 Round 22 (P0-2): 法律与隐私页
          GoRoute(
            path: '/settings/legal',
            pageBuilder: (context, state) =>
                _slideRightPage(state.pageKey, const LegalPage(), context),
          ),
          GoRoute(
            path: '/trend',
            pageBuilder: (context, state) =>
                _slideRightPage(state.pageKey, const TrendPage(), context),
          ),
          GoRoute(
            path: '/assessment',
            redirect: (_, __) => '/assessment/phq9',
          ),
          // v0.14 (Round 13B) 评估历史独立页
          // ⚠️ 必须在 :id 之前声明，否则 :id 会先匹配（GoRouter 按声明顺序匹配）
          GoRoute(
            path: '/assessment/history',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const AssessmentHistoryPage(), context,),
          ),
          GoRoute(
            path: '/assessment/:id',
            pageBuilder: (context, state) => _slideRightPage(
              state.pageKey,
              AssessmentPage(scaleId: state.pathParameters['id'] ?? 'phq9'),
              context,
            ),
          ),
          // v0.14 (Round 13C) 用药日历（医生视角热力图）
          GoRoute(
            path: '/medication/calendar',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const MedicationCalendarPage(), context,),
          ),
          // ============== v0.15 (Round 18) 树洞 ==============
          // 全屏深页（full-screen modal feel）— rare 频度 → slide-up
          GoRoute(
            path: '/vent',
            pageBuilder: (context, state) =>
                _slideUpPage(state.pageKey, const VentListPage(), context),
          ),
          GoRoute(
            path: '/vent/compose',
            pageBuilder: (context, state) =>
                _slideUpPage(state.pageKey, const VentComposePage(), context),
          ),
          GoRoute(
            path: '/vent/detail/:id',
            pageBuilder: (context, state) => _slideUpPage(
              state.pageKey,
              VentDetailPage(
                // v0.16 round 19C fix: 用 tryParse 替代 parse，URL 是 '/abc' 时
                // 不会崩，回退到 0（找不到对应条目 → 详情页显示"找不到了"）
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
              context,
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
    errorBuilder: (context, state) {
      // v0.21 (P2-2 fix): 之前 error page 只有一个 Text, 用户卡住没有出口
      // emil UX 原则: error 出现 = 用户卡住, 必须给明确出口 (icon + hint + 引导按钮)
      final l10n =
          Localizations.of<AppLocalizations>(context, AppLocalizations);
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppTokens.spacingMd),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.help_outline,
                  size: AppTokens.iconSizeEmpty,
                  color: AppTokens.textSecondaryColor(context),
                ),
                const SizedBox(height: AppTokens.spacingMd),
                Text(
                  l10n?.errorPageNotFound(state.matchedLocation) ??
                  '页面不存在: ${state.matchedLocation}',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingSm),
                Text(
                  l10n?.errorPageHint ?? '',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTokens.textSecondaryColor(context),
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppTokens.spacingMd),
                FilledButton.icon(
                  onPressed: () => GoRouter.of(context).go('/'),
                  icon: const Icon(Icons.home),
                  label: Text(l10n?.errorPageBackHome ?? '返回首页'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
});

/// 响应式 shell
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
                                    context, AppLocalizations,)
                                ?.navAppName ??
                            // v0.25 round 52 (spen P0 #11): i18n 失败 fallback
                            // 改英文 'ChronicCare', 不用 '慢病管家' 硬编
                            'ChronicCare',
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
