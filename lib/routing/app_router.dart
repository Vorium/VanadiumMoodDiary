import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../presentation/pages/home/home_page.dart';
import '../presentation/pages/settings/settings_page.dart';
import '../presentation/pages/settings/widgets/email_preview.dart';
import '../presentation/pages/setup/setup_page.dart';
import '../presentation/providers/data_providers.dart';

/// 路由 Provider
final routerProvider = Provider<GoRouter>((ref) {
  // 监听用户档案，判断是否已设置
  final profileAsync = ref.watch(userProfileProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final profile = profileAsync.valueOrNull;
      final isSetupDone = profile != null;
      final goingToSetup = state.matchedLocation == '/setup';

      if (!isSetupDone && !goingToSetup) return '/setup';
      if (isSetupDone && goingToSetup) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const HomePage()),
      GoRoute(path: '/setup', builder: (_, __) => const SetupPage()),
      GoRoute(path: '/settings', builder: (_, __) => const SettingsPage()),
      GoRoute(path: '/email-preview', builder: (_, __) => const EmailPreviewPage()),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('页面不存在: ${state.matchedLocation}'),
      ),
    ),
  );
});
