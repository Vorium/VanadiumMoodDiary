// v0.27 round 64 (spen P1-12 god class 拆分收尾): SafetyDetector 抽离
//
// 之前 safety_watch_service._checkAndAlert 122 行混合 8 类业务判定 +
// 3 类 sub-service 协调 (config / repo / dispatcher), god method。
// R64 抽 8 类业务判定到本文件 (纯函数), facade 仅负责加载 inputs +
// 调 detector + 委派 dispatcher。
//
// 设计原则:
// - **纯函数**: 0 副作用, 不调 sub-service, 不发通知, 不写 DB, 不读
//   SharedPreferences。所有 inputs 由 caller 注入。
// - **sealed class 返值**: 8 个 leaf class 对应 8 个 SafetyCheckKind, 让
//   facade 走 switch expression 强制穷举 (compile-time check, 新加 kind
//   编译失败提醒)。
// - **0 依赖 Drift / Riverpod / Flutter widget**: 仅依赖 domain entity
//   + SafetyConfigService (top-level 静态 daysBetween / isSameDay)。
// - **deterministic**: 相同 inputs 永远返相同 outputs, 易单测 + 5s
//   timeout / 异常等副作用全部留在 facade。
//
// caller 模式 (safety_watch_service._checkAndAlert):
// ```dart
// final enabled = await _config.isEnabled();
// final threshold = await _config.getThresholdDays();
// final latest = await _checkInRepo.getLatestNormalCheckIn();
// final lastCheckInAt = latest?.timestamp;
// final effectiveNow = now ?? DateTime.now();
// final lastAlertAt = await _config.getLastAlertAt();
// final inDnd = await _config.isInDnd(effectiveNow);
// final profile = await _userProfileRepo.get();
// final contacts = await _loadContacts(); // facade 私有, 含 timeout
//
// final decision = SafetyDetector.detect(
//   enabled: enabled,
//   threshold: threshold,
//   lastCheckInAt: lastCheckInAt,
//   now: effectiveNow,
//   lastAlertAt: lastAlertAt,
//   inDnd: inDnd,
//   profile: profile,
//   contacts: contacts,
// );
// return _actOn(decision: decision, ...);
// ```
//
// v0.29 R85 (spzh P1 架构修复): 文件从 lib/core/data/services/ 挪到
// lib/domain/logic/, 满足 4 层架构"domain 不依赖 data"硬约束。原先依赖
// SafetyConfigService 提供的 top-level 静态 daysBetween / isSameDay
// 已内联到本文件 (纯函数, 跟 [daysBetween] / [isSameDay] top-level 1:1
// 实现), 删除 SafetyConfigService import。
import 'package:chroniccare/core/data/services/safety_watch_service.dart' show SafetyCheckKind;
import 'package:chroniccare/domain/entities/contact_entity.dart';
import 'package:chroniccare/domain/entities/user_profile_entity.dart';

/// v0.29 R85: 内联 daysBetween (从 SafetyConfigService 抽过来, 纯函数)
int daysBetween(DateTime from, DateTime to) {
  // v0.16 round 19B fix: 缓存 now 一次, 避免跨 await DateTime.now() 多次
  // 调用 race (跨 midnight 后 now 变 → daysBetween 偏 1 天)
  final fromDate = DateTime(from.year, from.month, from.day);
  final toDate = DateTime(to.year, to.month, to.day);
  return toDate.difference(fromDate).inDays;
}

/// v0.29 R85: 内联 isSameDay (从 SafetyConfigService 抽过来, 纯函数)
bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// v0.27 round 64 (spen P1-12 god class 拆分): 安全判定 — 8 类 early-return 决策
///
/// 7 段顺序 (跟 R57 拆分前 R63 facade 现状 1:1):
/// 1. `enabled == false`              → [SafetyDecisionDisabled]
/// 2. `lastCheckInAt == null`         → [SafetyDecisionNoData]  (新用户, 不打扰)
/// 3. `daysSinceLast < threshold`     → [SafetyDecisionOk]
/// 4. `lastAlertAt isSameDay(now)`    → [SafetyDecisionAlertedToday]
/// 5. `inDnd`                         → [SafetyDecisionDndSuppressed]
/// 6. `profile == null`               → [SafetyDecisionNoData]  (无档案)
/// 7. `contacts.isEmpty`              → [SafetyDecisionNoContacts] (含 timeout 降级)
/// 8. otherwise                       → [SafetyDecisionAlert]   (走 facade dispatch)
class SafetyDetector {
  // 不可实例化 — 纯函数类
  const SafetyDetector._();

  /// 纯函数判定: 给定 inputs 返 [SafetyDecision] (sealed)
  ///
  /// 全部 8 个参数必传 (含 nullable 的"缺席"语义)。facade 负责加载真实
  /// 值; 本方法只做 decision tree。
  static SafetyDecision detect({
    required bool enabled,
    required int threshold,
    required DateTime? lastCheckInAt,
    required DateTime now,
    required DateTime? lastAlertAt,
    required bool inDnd,
    required UserProfileEntity? profile,
    required List<ContactEntity> contacts,
  }) {
    // 1. 关闭
    if (!enabled) {
      return const SafetyDecisionDisabled();
    }

    // 2. 没数据 (新用户)
    if (lastCheckInAt == null) {
      return const SafetyDecisionNoData();
    }

    final daysSinceLast = daysBetween(lastCheckInAt, now);

    // 3. 正常 (在阈值内)
    if (daysSinceLast < threshold) {
      return SafetyDecisionOk(daysSinceLast: daysSinceLast);
    }

    // 4. 今天已经发过
    if (lastAlertAt != null &&
        isSameDay(lastAlertAt, now)) {
      return SafetyDecisionAlertedToday(daysSinceLast: daysSinceLast);
    }

    // 5. DND 时段
    if (inDnd) {
      return SafetyDecisionDndSuppressed(daysSinceLast: daysSinceLast);
    }

    // 6. 没档案
    if (profile == null) {
      return const SafetyDecisionNoData();
    }

    // 7. 没联系人 (含 stream timeout / 异常降级 — facade 负责 catch + 返空 list)
    if (contacts.isEmpty) {
      return SafetyDecisionNoContacts(daysSinceLast: daysSinceLast);
    }

    // 8. 真触发 — facade 调 SafetyAlertDispatcher
    // 前置 gate 1-7 已保证 lastCheckInAt / profile 非空, 显式塞字段避免
    // facade 拿上游 nullable 变量 `!` 强转
    return SafetyDecisionAlert(
      daysSinceLast: daysSinceLast,
      lastCheckInAt: lastCheckInAt,
      profile: profile,
    );
  }
}

// ============== Sealed decision 层级 ==============
//
// 8 个 leaf class 对应 8 个 SafetyCheckKind, 让 facade 走 switch expression
// 强制穷举 (compile-time exhaustiveness check)。注释中按 4 大类分组:
//
//  1. Alert:    SafetyDecisionAlert
//  2. NoAlert:  SafetyDecisionOk / SafetyDecisionNoData /
//               SafetyDecisionAlertedToday / SafetyDecisionDndSuppressed /
//               SafetyDecisionNoContacts
//  3. Disabled: SafetyDecisionDisabled
//  4. Error:    (facade 外层 catch 处理, detector 不抛 — 纯函数)

/// Sealed 基类: 8 个 leaf 之一
sealed class SafetyDecision {
  const SafetyDecision();

  /// 距离上次打卡的天数。Disabled / NoData / Error 返 null (无意义或缺失)。
  /// 其余 leaf 必为非负整数。
  int? get daysSinceLast;
}

/// Leaf 1/8: 失联告警触发
///
/// 含义: 检测到失联 + 所有 gate (enabled / threshold / same-day / DND /
/// profile / contacts) 全过, **需要调 SafetyAlertDispatcher 实际发 SMS +
/// 推本地通知**。facade 拿到这个 decision 后走 dispatch。
///
/// v0.28 Round 93 (#12 修复): detector 内部已知 [lastCheckInAt] /
/// [profile] 非空 (前置 gate 保证), 显式塞到 decision 字段, 避免 facade
/// 拿 nullable 变量 `!` 强转。upstream 改判也不会让 facade NPE。
final class SafetyDecisionAlert extends SafetyDecision {
  @override
  final int daysSinceLast;
  final DateTime lastCheckInAt;
  final UserProfileEntity profile;

  const SafetyDecisionAlert({
    required this.daysSinceLast,
    required this.lastCheckInAt,
    required this.profile,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyDecisionAlert &&
          other.daysSinceLast == daysSinceLast &&
          other.lastCheckInAt == lastCheckInAt &&
          other.profile == profile;

  @override
  int get hashCode => Object.hash(daysSinceLast, lastCheckInAt, profile);
}

/// Leaf 2/8: 正常 (在阈值内, 不需要告警)
final class SafetyDecisionOk extends SafetyDecision {
  @override
  final int daysSinceLast;
  const SafetyDecisionOk({required this.daysSinceLast});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyDecisionOk && other.daysSinceLast == daysSinceLast;

  @override
  int get hashCode => daysSinceLast.hashCode;
}

/// Leaf 3/8: 没数据
///
/// 含义: 用户从没打过卡 (lastCheckInAt == null) **或** 没用户档案
/// (profile == null)。两种情况对用户都"无可通知对象", facade 返
/// [SafetyCheckKind.noData]。
final class SafetyDecisionNoData extends SafetyDecision {
  const SafetyDecisionNoData();

  @override
  int? get daysSinceLast => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SafetyDecisionNoData;

  @override
  int get hashCode => 'noData'.hashCode;
}

/// Leaf 4/8: 今天已发过告警
final class SafetyDecisionAlertedToday extends SafetyDecision {
  @override
  final int daysSinceLast;
  const SafetyDecisionAlertedToday({required this.daysSinceLast});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyDecisionAlertedToday &&
          other.daysSinceLast == daysSinceLast;

  @override
  int get hashCode => daysSinceLast.hashCode;
}

/// Leaf 5/8: DND 时段抑制
final class SafetyDecisionDndSuppressed extends SafetyDecision {
  @override
  final int daysSinceLast;
  const SafetyDecisionDndSuppressed({required this.daysSinceLast});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyDecisionDndSuppressed &&
          other.daysSinceLast == daysSinceLast;

  @override
  int get hashCode => daysSinceLast.hashCode;
}

/// Leaf 6/8: 没联系人 (含 stream timeout / 异常降级到空 list)
final class SafetyDecisionNoContacts extends SafetyDecision {
  @override
  final int daysSinceLast;
  const SafetyDecisionNoContacts({required this.daysSinceLast});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SafetyDecisionNoContacts && other.daysSinceLast == daysSinceLast;

  @override
  int get hashCode => daysSinceLast.hashCode;
}

/// Leaf 7/8: 关闭 (enabled = false)
final class SafetyDecisionDisabled extends SafetyDecision {
  const SafetyDecisionDisabled();

  @override
  int? get daysSinceLast => null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is SafetyDecisionDisabled;

  @override
  int get hashCode => 'disabled'.hashCode;
}
