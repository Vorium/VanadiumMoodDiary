// v0.32 R112 (R112-ARCH-02): 通知 deep link payload → 路由 path 纯函数
//
// 背景: `NotificationNavigation._pathFor` (core/routing, import
// flutter/widgets + go_router) 被 data 层 2 个 service import →
// data 传递依赖 Flutter (守门盲区, check_all 3 轮没 gate 管)。
// 修: 把 payload → route string 决策下沉为 domain 纯函数 (0 Flutter /
// 0 Drift / 0 data / 0 l10n), GoRouter 绑定留在
// core/routing/notification_navigation.dart (presentation/app 层接线)。
//
// payload wire 格式 (跟 data 层 notification_payload.dart 编码约定 1:1):
// `chroniccare://<action>/<arg1>/...` — action 在 host 位置 (Dart
// `Uri.parse('chroniccare://check-in/today')` 把 'check-in' 解析为 host,
// 'today' 为 path)。
//
// 4 类 action → 最终 go_router path (注意: app_router 可能有 redirect,
// 这里写最终 path):
// - today        → /check-in/today
// - medication   → /check-in/medication/{medId}
// - assessment   → /assessment/{scaleId}
// - safety-alert → /check-in/today?reason=safety

/// 通知 payload → 最终路由 path 决策 (纯函数)
///
/// 返回 null = 不跳转 (payload 空 / 格式非法 / action 未注册)。
/// 0 副作用: 不碰 router / 不碰 UI, 只算字符串。
String? resolveNotificationDeepLinkRoute(String? payload) {
  if (payload == null || payload.isEmpty) return null;
  final uri = Uri.tryParse(payload);
  if (uri == null || uri.scheme != 'chroniccare') return null;

  final action = uri.host;
  if (action.isEmpty) return null;

  switch (action) {
    case 'today':
      return '/check-in/today';
    case 'medication':
      // path = "/42"
      final segs = uri.pathSegments;
      if (segs.isEmpty) return null;
      final medId = int.tryParse(segs[0]) ?? 0;
      return '/check-in/medication/$medId';
    case 'assessment':
      // path = "/phq9"
      final segs = uri.pathSegments;
      if (segs.isEmpty) return null;
      return '/assessment/${segs[0]}';
    case 'safety-alert':
      return '/check-in/today?reason=safety';
    default:
      return null;
  }
}
