import 'package:chroniccare/core/shared/pii_safe_log.dart';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/data/services/notification_payload.dart';

/// 全局 Deep Link 路由器
///
/// 通知回调 / cold-start 启动 payload / 外部 URL 都通过这个统一入口
/// 转换成 GoRouter 跳转。
///
/// 设计要点:
/// - 用静态 API,不绑死 widget(通知 callback 在 main 里调，那时没 widget)
/// - bind() 在 AppRoot 第一次 build 后调(那时 GoRouter 已就绪)
/// - 启动 payload 用 pendingPayload 缓存,bind() 时自动消费
class NotificationNavigation {
  /// 已绑定的 GoRouter(在 AppRoot 第一次 build 时设置)
  static GoRouter? _router;

  /// App 启动时收到的 launch payload(app 被杀着，用户点通知拉起)
  ///
  /// AppRoot bind() 时如果这里有值，会立即跳走并清空
  static NotificationDeepLink? _pendingLaunchLink;

  /// 通知 callback 触发的 deep link(可选，用于埋点)
  static final ValueNotifier<NotificationDeepLink?> onLink =
      ValueNotifier(null);

  /// 由 AppRoot.build() 调用，把 router 绑进来
  static void bind(GoRouter router) {
    _router = router;
    if (_pendingLaunchLink != null) {
      _goInternal(_pendingLaunchLink!, fromLaunch: true);
      _pendingLaunchLink = null;
    }
  }

  /// main.dart 在 init NotificationService 时传入
  /// app 是被通知拉起时调用，记录 payload 等 router 就绪
  static void setLaunchPayload(String? rawPayload) {
    final link = NotificationDeepLink.parse(rawPayload);
    if (link == null) return;
    if (_router != null) {
      _goInternal(link, fromLaunch: true);
    } else {
      _pendingLaunchLink = link;
    }
  }

  /// 用户在前台/后台点通知 — 由 notification_service 的 callback 调
  ///
  /// [onLink] 通知也会被触发(settings / 调试用)
  static void handleTap(String? rawPayload) {
    final link = NotificationDeepLink.parse(rawPayload);
    if (link == null) return;
    onLink.value = link;
    _goInternal(link, fromLaunch: false);
  }

  static void _goInternal(
    NotificationDeepLink link, {
    required bool fromLaunch,
  }) {
    final router = _router;
    if (router == null) {
      piiSafeLog('NotificationNavigation', '⚠️ NotificationNavigation._goInternal: router 未绑定',
      );
      return;
    }
    final path = _pathFor(link);
    if (path == null) return;
    try {
      router.go(path);
      piiSafeLog('NotificationNavigation', '✅ Deep link → $path (fromLaunch=$fromLaunch)',
      );
    } catch (e) {
      piiSafeLog('NotificationNavigation', '❌ Deep link go 失败: $e',
        error: e,
      );
    }
  }

  /// DeepLinkTarget → app_router 里的 path
  ///
  /// 注意:app_router 里可能有 redirect,这里写最终 path
  static String? _pathFor(NotificationDeepLink link) {
    switch (link.target) {
      case DeepLinkTarget.todayCheckIn:
        return '/check-in/today';
      case DeepLinkTarget.medicationCheckIn:
        final medId = link.medicationId;
        if (medId == null) return null;
        return '/check-in/medication/$medId';
      case DeepLinkTarget.assessment:
        final scaleId = link.scaleId ?? 'phq9';
        return '/assessment/$scaleId';
      case DeepLinkTarget.safetyAlert:
        return '/check-in/today?reason=safety';
    }
  }

  /// 测试 / 调试用
  static void reset() {
    _router = null;
    _pendingLaunchLink = null;
    onLink.value = null;
  }
}
