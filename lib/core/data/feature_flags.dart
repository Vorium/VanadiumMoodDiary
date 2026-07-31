// 2026-07-31 联系人软隐藏 (病耻感 + 失联通信业务暂停)
//
// v0.27 round 67 (C-7 重构): 推广 R66 FeatureFlags 模式
// R66 只抽 1 个 emergencyContactEnabled, 推广到 IAP / 量表 / BootReceiver
// 共 4 个独立 flag, 走"prod const + nullable override"模式。
//
// 设计:
// - 每个 flag 有 1 个 `_prodXxx` const (生产代码用) + 1 个 `_currentXxx` nullable
//   (test override 用, null = 用 prod 值)
// - getter 走 `_currentXxx ?? _prodXxx`
// - test helper 有 4 个 per-flag setter + 1 个全局 enableForTest / resetForTest
//   (保持跟原 R66 enableForTest 兼容, 28 个老 test 不用改)
//
// 影响范围 (各 flag 关闭时):
//   - emergencyContactEnabled=false:
//     Setup step 1 可选紧急联系人 + Settings 隐藏联系人 section
//     + SafetyWatchService 早返 disabled
//   - iapEnabled=false:
//     main.dart warmup 跳过 StoreKitService.warmup
//     + StoreKitService.buyLifetime 早返 false (隐藏 IAP 入口避 Apple 2.1 拒)
//   - phqGad7I18nEnabled=false (R65b 阶段开启):
//     PHQ-9 / GAD-7 16 题 i18n 走 fallback key (避免 zh_Hant 显示英文 fallback)
//   - bootReceiverEnabled=false (v0.28 WorkManager 完善之前临时关闭):
//     SafetyWatchService.onAppStart 跳过 rescheduleAll
//
// 位置说明: 本文件放 `core/data/` 而非 `core/shared/`,因为实际只有 data 层
// (safety_watch_service / safety_alert_dispatcher / store_kit_service) 引用,
// 符合"shared/ 工具至少被 2 层用"的架构约束。`check_all.dart` 守门员已校验。
import 'package:flutter/foundation.dart' show visibleForTesting;

class FeatureFlags {
  const FeatureFlags._();

  // ====== Production const values (启动时锁定, prod 永不改变) ======
  static const bool _prodEmergencyContactEnabled = false;
  // R68: IAP 8 元买断在 release 模式 `buyLifetime()` 返 false + user_agreement.md 写"8 元买断" = 描述 vs 实际不一致(CC-3)
  // 临时关闭 IAP 入口,等 v0.28 真接 productId 后再开
  static const bool _prodIapEnabled = false;
  static const bool _prodPhqGad7I18nEnabled = false;
  static const bool _prodBootReceiverEnabled = true;

  // ====== Test override (nullable, null = use _prod) ======
  static bool? _currentEmergencyContactEnabled;
  static bool? _currentIapEnabled;
  static bool? _currentPhqGad7I18nEnabled;
  static bool? _currentBootReceiverEnabled;

  // ====== 公共 getter (生产代码读这里) ======

  /// 失联通知 / 紧急联系人 SMS 业务总开关
  ///
  /// 生产代码读取此值决定是否走真实失联检测 / 紧急联系人 SMS / 失联通知。
  /// 默认 false (整个失联通信业务暂停)。
  static bool get emergencyContactEnabled =>
      _currentEmergencyContactEnabled ?? _prodEmergencyContactEnabled;

  /// IAP 8 元买断开关
  ///
  /// false 时:
  /// - main.dart warmup 跳过 StoreKitService.warmup
  /// - StoreKitService.buyLifetime 早返 false
  /// - UI 隐藏"立即买断"按钮 (避 Apple 2.1 拒 — "未提供其他购买方式")
  /// 默认 true (v0.28 真接 productId 时启用)。
  static bool get iapEnabled => _currentIapEnabled ?? _prodIapEnabled;

  /// PHQ-9 / GAD-7 量表 16 题 i18n 开关
  ///
  /// R65b 阶段开启 (量表题目 + 严重度 + 危机电话完整 i18n 走完 ARB 时)
  /// 默认 false (题目用 fallback key, 避免 zh_Hant 显示英文)。
  static bool get phqGad7I18nEnabled =>
      _currentPhqGad7I18nEnabled ?? _prodPhqGad7I18nEnabled;

  /// Android BootReceiver 完善开关
  ///
  /// v0.28 WorkManager 完善之前临时关闭 (避 BootReceiver 重启时 crash)
  /// 默认 true (跟现有行为一致 — 设备重启后重排通知)。
  static bool get bootReceiverEnabled =>
      _currentBootReceiverEnabled ?? _prodBootReceiverEnabled;

  // ====== Per-flag test setter (v0.27 R67 新增) ======

  /// 仅供 test 使用 — 临时把 [iapEnabled] 翻成指定值,跑测试期间覆盖。
  ///
  /// caller 必须在 tearDown 调 `setIapEnabledForTest(null)` 恢复,避免污染后续 test。
  @visibleForTesting
  static void setIapEnabledForTest(bool? v) => _currentIapEnabled = v;

  /// 仅供 test 使用 — 临时把 [phqGad7I18nEnabled] 翻成指定值。
  @visibleForTesting
  static void setPhqGad7I18nEnabledForTest(bool? v) =>
      _currentPhqGad7I18nEnabled = v;

  /// 仅供 test 使用 — 临时把 [bootReceiverEnabled] 翻成指定值。
  @visibleForTesting
  static void setBootReceiverEnabledForTest(bool? v) =>
      _currentBootReceiverEnabled = v;

  // ====== Global test helper (保持 R66 兼容, 28 个老 test 不用改) ======

  /// 仅供 test 使用 — 临时把全部 4 个 flag 翻成 enable,跑测试期间走真实业务。
  ///
  /// 等价于:
  ///   setIapEnabledForTest(true)
  ///   setPhqGad7I18nEnabledForTest(true)
  ///   setBootReceiverEnabledForTest(true)
  ///   (emergencyContactEnabled 默认就是 false, R66 期间 setter 没暴露)
  ///
  /// caller 必须在 tearDown 调 [resetForTest] 恢复,避免污染后续 test。
  @visibleForTesting
  static void enableForTest() {
    _currentEmergencyContactEnabled = true;
    _currentIapEnabled = true;
    _currentPhqGad7I18nEnabled = true;
    _currentBootReceiverEnabled = true;
  }

  /// 仅供 test 使用 — 把 4 个 flag 全部清空 override,回到 prod 默认值。
  @visibleForTesting
  static void resetForTest() {
    _currentEmergencyContactEnabled = null;
    _currentIapEnabled = null;
    _currentPhqGad7I18nEnabled = null;
    _currentBootReceiverEnabled = null;
  }
}
