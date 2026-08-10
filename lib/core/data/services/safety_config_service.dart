// v0.25 round 57: SafetyConfigService 抽离 (safety_watch_service god class 拆分)
//
// 之前 safety_watch_service.dart 425 行含 8 个 SharedPreferences method +
// 3 个触发入口 + 142 行 _checkAndAlert 核心 + 4 个工具方法, god class 标签。
// R57 抽 2 sub + facade 编排:
//   - SafetyConfigService  (本文件): 8 个 SharedPreferences 配置 API
//   - SafetyAlertDispatcher: SMS + 本地通知 + audit log 写入
//   - SafetyWatchService:   facade 协调, 保留 onAppStart/onCheckIn/checkNow
//
// caller 暂时不动 (保留 facade 兼容, 后续 R57b 渐进迁移)
import 'package:chroniccare/core/shared/date_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// v0.25 round 57 (spen P1 #12 god class 拆分): 安全开关配置服务
///
/// SharedPreferences 包装。safety_watch_service 的 8 个配置 API
/// (enabled/thresholdDays/DND/lastAlertAt) 全部抽到这里。
class SafetyConfigService {
  // SharedPreferences key 常量 (跟原 safety_watch_service 一致, 兼容老数据)
  static const _kEnabled = 'safety_watch_enabled';
  static const _kThresholdDays = 'safety_watch_threshold_days';
  static const _kLastAlertAt = 'safety_watch_last_alert_at';
  static const _kDoNotDisturbStart = 'safety_watch_dnd_start';
  static const _kDoNotDisturbEnd = 'safety_watch_dnd_end';

  /// 默认阈值: 2 天
  static const int defaultThresholdDays = 2;

  // R102 (P1): 缓存 SharedPreferences 实例, 避免每个方法都调 getInstance()
  // (异步平台调用, 每次走 MethodChannel)
  SharedPreferences? _prefs;

  Future<SharedPreferences> _getPrefs() async =>
      _prefs ?? await SharedPreferences.getInstance();

  // ============== Enabled ==============

  /// 是否启用安全开关
  Future<bool> isEnabled() async {
    final prefs = await _getPrefs();
    return prefs.getBool(_kEnabled) ?? false;
  }

  /// 切换启用状态
  Future<void> setEnabled(bool value) async {
    final prefs = await _getPrefs();
    await prefs.setBool(_kEnabled, value);
  }

  // ============== Threshold ==============

  /// 阈值天数 (连续多少天没打卡触发)
  Future<int> getThresholdDays() async {
    final prefs = await _getPrefs();
    return prefs.getInt(_kThresholdDays) ?? defaultThresholdDays;
  }

  Future<void> setThresholdDays(int days) async {
    if (days < 1 || days > 14) {
      throw ArgumentError('threshold must be between 1 and 14 days');
    }
    final prefs = await _getPrefs();
    await prefs.setInt(_kThresholdDays, days);
  }

  // ============== DND (Do Not Disturb) ==============

  /// DND 时段 (小时, 24h 制, start < end 同一天; 跨天用 start > end 表示)
  Future<({int? start, int? end})> getDoNotDisturb() async {
    final prefs = await _getPrefs();
    return (
      start: prefs.getInt(_kDoNotDisturbStart),
      end: prefs.getInt(_kDoNotDisturbEnd),
    );
  }

  Future<void> setDoNotDisturb({int? startHour, int? endHour}) async {
    final prefs = await _getPrefs();
    if (startHour == null) {
      await prefs.remove(_kDoNotDisturbStart);
    } else {
      await prefs.setInt(_kDoNotDisturbStart, startHour);
    }
    if (endHour == null) {
      await prefs.remove(_kDoNotDisturbEnd);
    } else {
      await prefs.setInt(_kDoNotDisturbEnd, endHour);
    }
  }

  // ============== Last Alert At (audit log) ==============

  /// 上次告警时间 (ISO string)
  Future<DateTime?> getLastAlertAt() async {
    final prefs = await _getPrefs();
    final s = prefs.getString(_kLastAlertAt);
    if (s == null) return null;
    // v0.22 round 30 (sp-zh P1-1): _setLastAlertAt 改用 toUtc 存
    // → get 时转 local 保持原 _isSameDay 行为 (local day 比较)
    return DateTime.tryParse(s)?.toLocal();
  }

  Future<void> setLastAlertAt(DateTime when) async {
    final prefs = await _getPrefs();
    // v0.22 round 30 (sp-zh P1-1): 显式 toUtc, 跟 v0.21 round 22 P0-3
    // data_export_service 一致。 之前无 Z 后缀 → DateTime.parse() 按
    // local 解析, 跨时区 drift (e.g. 北京用户飞纽约后从 backup 恢复会差 13h)。
    await prefs.setString(_kLastAlertAt, when.toUtc().toIso8601String());
  }

  // ============== 纯函数工具 (不依赖 SharedPreferences) ==============

  /// 跨日的"日历差"
  /// R102 (P2): 改用 core/shared/date_utils.dart 单一来源
  static int daysBetween(DateTime a, DateTime b) => calendarDaysBetween(a, b);

  /// R102 (P2): 改用 core/shared/date_utils.dart 单一来源
  static bool isSameDay(DateTime a, DateTime b) => isSameCalendarDay(a, b);

  /// 判断 now 是否在 DND 时段内
  Future<bool> isInDnd(DateTime now) async {
    final dnd = await getDoNotDisturb();
    if (dnd.start == null || dnd.end == null) return false;
    final h = now.hour;
    if (dnd.start! < dnd.end!) {
      return h >= dnd.start! && h < dnd.end!;
    } else {
      // 跨天: 例如 22 ~ 08 表示 22:00-08:00
      return h >= dnd.start! || h < dnd.end!;
    }
  }
}
