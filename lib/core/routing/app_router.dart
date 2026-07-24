import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/theme/app_tokens.dart';
import 'package:chroniccare/l10n/app_localizations.dart';
import 'package:chroniccare/core/theme/theme_toggle_button.dart';

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
import 'package:chroniccare/presentation/providers/data_providers.dart';

/// 璺敱鍒囨崲鍔ㄧ敾杈呭姪鍑芥暟锛坴0.17 round 2 / A2 emil 鍔ㄦ晥锛?
///
/// 棰戝害鍐崇瓥锛坋mil 鍐崇瓥妗嗘灦锛夛細
/// - 涓诲鑸紙/, /settings锛夆啋 鍋跺皵鍒?鈫?绠€鍗?fade
/// - 瀛愰〉锛?trend, /assessment/*, /settings/reminders锛夆啋 occasional 鈫?slide-from-right
/// - 鍏ㄥ睆娣遍〉锛?setup, /vent/*锛夆啋 rare 鈫?slide-up + fade锛坒ull-screen modal 鎰燂級
///
/// v0.21 Round 22 (P1-13 淇): helper 鎺ュ彈 BuildContext 鐢ㄤ簬
/// 灏婇噸 prefers-reduced-motion (Motion.duration 璋?銆?
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
      // 浠庡彸婊戝叆 + 娣″叆锛坋mil: 鏍囧噯鐨?Material 椋庢牸 push 鍔ㄧ敾锛?
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

/// 璺敱 Provider
final routerProvider = Provider<GoRouter>((ref) {
  // 鐩戝惉鐢ㄦ埛妗ｆ锛屽垽鏂槸鍚﹀凡璁剧疆
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) {
      // v0.17 round 3: Riverpod 3.x 鏀瑰悕涓?.value锛堜箣鍓?.valueOrNull锛?
      final profile = profileAsync.value;
      final isSetupDone = profile != null;
      final goingToSetup = state.matchedLocation == '/setup';

      if (!isSetupDone && !goingToSetup) return '/setup';
      if (isSetupDone && goingToSetup) return '/';
      return null;
    },
    routes: [
      // 璁剧疆娴佺▼涓嶈繘 shell锛堝叏灞忓紩瀵硷級鈥?rare 棰戝害 鈫?slide-up
      GoRoute(
        path: '/setup',
        pageBuilder: (context, state) =>
            _slideUpPage(state.pageKey, const SetupPage(), context),
      ),
      // 涓?app shell锛氬灞忓甫 NavigationRail锛岀獎灞忕函 body
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentLocation: state.matchedLocation,
          child: child,
        ),
        routes: [
          // 涓诲鑸細occasional 棰戝害 鈫?fade
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
          // 瀛愰〉锛歰ccasional 鈫?slide-from-right
          GoRoute(
            path: '/email-preview',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const EmailPreviewPage(), context,),
          ),
          // v0.14 (Round 12C) 鎻愰啋涓績
          GoRoute(
            path: '/settings/reminders',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const RemindersHubPage(), context,),
          ),
          // v0.14 (Round 13A) 缁柟绠＄悊
          GoRoute(
            path: '/settings/refills',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const RefillManagePage(), context,),
          ),
          // v0.21 Round 22 (P0-2): 娉曞緥涓庨殣绉侀〉
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
          // v0.14 (Round 13B) 璇勪及鍘嗗彶鐙珛椤?
          // 鈿狅笍 蹇呴』鍦?:id 涔嬪墠澹版槑锛屽惁鍒?:id 浼氬厛鍖归厤锛圙oRouter 鎸夊０鏄庨『搴忓尮閰嶏級
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
          // v0.14 (Round 13C) 鐢ㄨ嵂鏃ュ巻锛堝尰鐢熻瑙掔儹鍔涘浘锛?
          GoRoute(
            path: '/medication/calendar',
            pageBuilder: (context, state) => _slideRightPage(
                state.pageKey, const MedicationCalendarPage(), context,),
          ),
          // ============== v0.15 (Round 18) 鏍戞礊 ==============
          // 鍏ㄥ睆娣遍〉锛坒ull-screen modal feel锛夆€?rare 棰戝害 鈫?slide-up
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
                // v0.16 round 19C fix: 鐢?tryParse 鏇夸唬 parse锛孶RL 鏄?'/abc' 鏃?
                // 涓嶄細宕╋紝鍥為€€鍒?0锛堟壘涓嶅埌瀵瑰簲鏉＄洰 鈫?璇︽儏椤垫樉绀?鎵句笉鍒颁簡"锛?
                id: int.tryParse(state.pathParameters['id'] ?? '') ?? 0,
              ),
              context,
            ),
          ),
          // ============== Round 5: Deep Linking 璺敱 ==============
          // 鐐?medication 閫氱煡 鈫?鐩存帴璺?home 骞惰嚜鍔ㄦ墦鍗¤鑽?
          // 涓嶇粡杩?3 姝ラ椤垫祦绋嬶紙鍙傝€?HealthReminder锛?
          GoRoute(
            path: '/check-in/medication/:id',
            redirect: (_, state) {
              final medId = state.pathParameters['id'] ?? '0';
              return '/?medId=$medId&autofire=1';
            },
          ),
          // 鐐?default / soft 閫氱煡 鈫?璺?home
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
      // v0.21 (P2-2 fix): 涔嬪墠 error page 鍙湁涓€涓?Text, 鐢ㄦ埛鍗′綇娌℃湁鍑哄彛
      // emil UX 鍘熷垯: error 鍑虹幇 = 鐢ㄦ埛鍗′綇, 蹇呴』缁欐槑纭嚭鍙?(icon + hint + 寮曞鎸夐挳)
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
                  size: 64,
                  color: AppTokens.textSecondaryColor(context),
                ),
                const SizedBox(height: AppTokens.spacingMd),
                Text(
                  l10n?.errorPageNotFound(state.matchedLocation) ??
                      '椤甸潰涓嶅瓨鍦? ${state.matchedLocation}',
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
                  label: Text(l10n?.errorPageBackHome ?? '杩斿洖棣栭〉'),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
});

/// 鍝嶅簲寮?shell锛?
/// - 绐勫睆锛? 840锛夛細鍙樉绀?child锛堥〉闈級锛屾棤渚ф爮
/// - 瀹藉睆锛?= 840锛夛細宸︿晶 NavigationRail锛坋xtended 妯″紡锛屾樉绀烘枃瀛楋級+ 鍙充晶 child
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
        label: l10n?.navCheckIn ?? '鎵撳崱',
        icon: Icons.check_circle_outline,
        selectedIcon: Icons.check_circle,
        path: '/',
      ),
      _NavDest(
        label: l10n?.navSettings ?? '璁剧疆',
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
      // /email-preview 绠楄缃瓙椤?
      if (dests[i].path == '/settings' &&
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
          // 绐勫睆锛氬幓鎺夊悇椤甸潰鑷繁鐨?AppBar锛坰hell 涓嶇锛夛紝child 鑷澶勭悊
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
                            '鎱㈢梾绠″',
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
