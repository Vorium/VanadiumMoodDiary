/// 通知 payload 编码/解析 — Deep Linking 基础设施
///
/// v0.11 (Round 5) — 参考 HealthReminder:
/// 点推送不要走 3 步首页，直接跳到对应"今天打卡"页。
///
/// payload 格式: `chroniccare://<action>/<arg1>/<arg2>/...`
/// **action 放在 host 位置**(`//` 之后第一段),不是 path 位置。
/// Dart 的 `Uri.parse('chroniccare://check-in/today')` 会把 'check-in'
/// 解析为 host,'today' 解析为 path,所以我们跟着这个习惯来。
///
/// 注意:payload 是 iOS/Android 通知的有限字段(< 1KB),
/// 这里用最小集合，不要往里塞大对象。
library;

import 'package:flutter/foundation.dart' show immutable;

/// 支持的 deep link 目标
enum DeepLinkTarget {
  /// 跳到主页 + 触发"打卡"动效
  todayCheckIn,

  /// 跳到主页 + 自动开 medication check-in dialog
  medicationCheckIn,

  /// 跳到 PHQ-9 / GAD-7 评估页
  assessment,

  /// 跳到主页 + 显示安全告警 SnackBar
  safetyAlert,
}

/// 解析后的 deep link
@immutable
class NotificationDeepLink {
  final DeepLinkTarget target;
  final Map<String, String> args;

  const NotificationDeepLink._({required this.target, required this.args});

  /// medication check-in:args = { 'medId': '1' }
  factory NotificationDeepLink.medicationCheckIn(int medicationId) {
    return NotificationDeepLink._(
      target: DeepLinkTarget.medicationCheckIn,
      args: {'medId': medicationId.toString()},
    );
  }

  /// assessment:args = { 'scaleId': 'phq9' }
  factory NotificationDeepLink.assessment(String scaleId) {
    return NotificationDeepLink._(
      target: DeepLinkTarget.assessment,
      args: {'scaleId': scaleId},
    );
  }

  /// safety alert:args = { 'days': '3' }
  factory NotificationDeepLink.safetyAlert(int daysSince) {
    return NotificationDeepLink._(
      target: DeepLinkTarget.safetyAlert,
      args: {'days': daysSince.toString()},
    );
  }

  /// today check-in
  factory NotificationDeepLink.todayCheckIn() {
    return const NotificationDeepLink._(
      target: DeepLinkTarget.todayCheckIn,
      args: {},
    );
  }

  int? get medicationId => int.tryParse(args['medId'] ?? '');
  String? get scaleId => args['scaleId'];
  int? get daysSince => int.tryParse(args['days'] ?? '');

  /// 编码成 URI 字符串(payload 字段)
  ///
  /// host = action
  /// path = /arg1/arg2
  String encode() {
    const scheme = 'chroniccare';
    switch (target) {
      case DeepLinkTarget.todayCheckIn:
        return '$scheme://today';
      case DeepLinkTarget.medicationCheckIn:
        return '$scheme://medication/${medicationId ?? 0}';
      case DeepLinkTarget.assessment:
        return '$scheme://assessment/${scaleId ?? "phq9"}';
      case DeepLinkTarget.safetyAlert:
        return '$scheme://safety-alert/${daysSince ?? 0}';
    }
  }

  /// 解析 payload,失败返 null
  static NotificationDeepLink? parse(String? payload) {
    if (payload == null || payload.isEmpty) return null;
    final uri = Uri.tryParse(payload);
    if (uri == null) return null;
    if (uri.scheme != 'chroniccare') return null;

    final action = uri.host;
    if (action.isEmpty) return null;

    switch (action) {
      case 'today':
        return NotificationDeepLink.todayCheckIn();

      case 'medication':
        // path = "/42"
        final segs = uri.pathSegments;
        if (segs.isEmpty) return null;
        final medId = int.tryParse(segs[0]) ?? 0;
        return NotificationDeepLink.medicationCheckIn(medId);

      case 'assessment':
        // path = "/phq9"
        final segs = uri.pathSegments;
        if (segs.isEmpty) return null;
        return NotificationDeepLink.assessment(segs[0]);

      case 'safety-alert':
        final segs = uri.pathSegments;
        if (segs.isEmpty) return null;
        final days = int.tryParse(segs[0]) ?? 0;
        return NotificationDeepLink.safetyAlert(days);

      default:
        return null;
    }
  }

  @override
  bool operator ==(Object other) =>
      other is NotificationDeepLink &&
      other.target == target &&
      _mapEquals(other.args, args);

  @override
  int get hashCode => Object.hash(target, Object.hashAll(args.entries));

  @override
  String toString() => 'NotificationDeepLink(${encode()})';
}

bool _mapEquals(Map<String, String> a, Map<String, String> b) {
  if (a.length != b.length) return false;
  for (final k in a.keys) {
    if (a[k] != b[k]) return false;
  }
  return true;
}
