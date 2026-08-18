// 规则 3 标记: CJK 字面量 = developer 日志/内部 note (非用户可见 UI 文案), 豁免 i18n 扫描
import 'package:chroniccare/core/data/services/pii_safe_log.dart';

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import 'package:chroniccare/core/platform/notification/notification_payload.dart';
import 'package:chroniccare/domain/logic/notification_deep_link_resolver.dart';

/// 全局 Deep Link 路由器
///
/// 通知回调 / cold-start 启动 payload / 外部 URL 都通过这个统一入口
/// 转换成 GoRouter 跳转。
///
/// 设计要点:
/// - 用静态 API,不绑死 widget(通知 callback 在 main 里调，那时没 widget)
/// - bind() 在 AppRoot 第一次 build 后调(那时 GoRouter 已就绪)
/// - 启动 payload 用 pendingPayload 缓存,bind() 时自动消费
///
/// P1 fix: 从 core/data/services/ 移入 core/routing/（本体是路由逻辑，不应在 data 层）
///
/// v0.32 R112 (R112-ARCH-02): payload → route 决策下沉到 domain 纯函数
/// [resolveNotificationDeepLinkRoute] (0 Flutter 依赖), 本类只保留 GoRouter
/// 绑定 + onLink 观察。data 层 service 不再 import 本文件 (改注入回调)。
class NotificationNavigation {
  /// 已绑定的 GoRouter(在 AppRoot 第一次 build 时设置)
  static GoRouter? _router;

  /// App 启动时收到的 launch payload(app 被杀着，用户点通知拉起)
  ///
  /// AppRoot bind() 时如果这里有值，会立即跳走并清空
  static String? _pendingLaunchPayload;

  /// 通知 callback 触发的 deep link(可选，用于埋点)
  static final ValueNotifier<NotificationDeepLink?> onLink =
      ValueNotifier(null);

  /// 由 AppRoot.build() 调用，把 router 绑进来
  static void bind(GoRouter router) {
    _router = router;
    final payload = _pendingLaunchPayload;
    if (payload != null) {
      _pendingLaunchPayload = null;
      final route = resolveNotificationDeepLinkRoute(payload);
      if (route != null) {
        _go(route, fromLaunch: true);
      }
    }
  }

  /// main.dart 在 init NotificationService 时传入
  /// app 是被通知拉起时调用，记录 payload 等 router 就绪
  static void setLaunchPayload(String? rawPayload) {
    final route = resolveNotificationDeepLinkRoute(rawPayload);
    if (route == null) return;
    if (_router != null) {
      _go(route, fromLaunch: true);
    } else {
      _pendingLaunchPayload = rawPayload;
    }
  }

  /// 用户在前台/后台点通知 — 由 notification_service 的 callback 调
  ///
  /// [onLink] 通知也会被触发(settings / 调试用)
  static void handleTap(String? rawPayload) {
    final route = resolveNotificationDeepLinkRoute(rawPayload);
    if (route == null) return;
    final link = NotificationDeepLink.parse(rawPayload);
    if (link != null) onLink.value = link;
    _go(route, fromLaunch: false);
  }

  static void _go(
    String path, {
    required bool fromLaunch,
  }) {
    final router = _router;
    if (router == null) {
      piiSafeLog(
        'NotificationNavigation',
        '⚠️ NotificationNavigation._go: router 未绑定',
      );
      return;
    }
    try {
      router.go(path);
      piiSafeLog(
        'NotificationNavigation',
        '✅ Deep link → $path (fromLaunch=$fromLaunch)',
      );
    } catch (e) {
      piiSafeLog(
        'NotificationNavigation',
        '❌ Deep link go 失败: $e',
        error: e,
      );
    }
  }

  /// 测试 / 调试用
  static void reset() {
    _router = null;
    _pendingLaunchPayload = null;
    onLink.value = null;
  }
}
// rule3-whitelist: 82, 95
//   R113 BUG A: 精确行号豁免 (修前文件头 i18n 标记整文件豁免)
//   新增 CJK 字面量需自带 i18n 标记或扩本清单 — 详见 scripts/check_strings_hardcoded.py
