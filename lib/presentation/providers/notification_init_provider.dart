// v0.25 round 56g (spen P1 #1 cross-layer import 修): 抽 notificationInitResultProvider
//
// 之前 NotificationInitResult class + notificationInitResultProvider 写在
// lib/main.dart (line 316-325), home_page.dart 通过
//   import 'package:chroniccare/main.dart' show notificationInitResultProvider;
// 跨层引用. presentation → main 是 reverse dependency (main 是 app entry,
// 不该被业务页面 import).
//
// 修法: 抽到 presentation/providers/notification_init_provider.dart,
// main.dart 和 home_page.dart 都从这里 import.
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 通知初始化结果(注入到 provider 树,首页用)
class NotificationInitResult {
  final bool ok;
  final String? error;
  const NotificationInitResult({required this.ok, this.error});
}

/// provider 在 main.dart 启动时 override 注入实际初始化结果。
///
/// 默认值 "ok=true, error=null" 是乐观默认 — 大多数平台初始化成功,
/// 失败时由 [AppInitializer.run] 主动 override.
final notificationInitResultProvider = Provider<NotificationInitResult>(
  (ref) => const NotificationInitResult(ok: true, error: null),
);
