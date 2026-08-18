// 2026-07-31 联系人软隐藏 (病耻感 + 失联通信业务暂停)
//
// v0.27 round 67 (C-7 重构): 推广 R66 FeatureFlags 模式
// R66 只抽 1 个 emergencyContactEnabled, 推广到量表 / BootReceiver
// 共 3 个独立 flag, 走"prod const + nullable override"模式。
//
// v0.30 round 93 (阶段 2 audit-fixes): "所有需要真接的内容先隐藏" 策略
// 加 4 个新 flag (AliyunSms / EmailService / FiveVendorPush / VentAudio),
// 同步改 _prodBootReceiverEnabled = true → false, 共 10 个独立 flag
// 全 _prodXxxEnabled = const false (编译期锁定, 真接业务后翻 true)。
//
// v1.0.0+147: 永久免费定版, flag 数量 8 → 7 (已取消业务删除)。
//
// 1.1.0 round 4b (emotion-first refactor): 外联通信业务删除定版,
// 3 个外联 flag 整摘 (emergencyContactEnabled / aliyunSmsEnabled /
// emailServiceEnabled), 7 → 4 flag。
//
// 设计:
// - 每个 flag 有 1 个 `_prodXxx` const (生产代码用) + 1 个 `_currentXxx` nullable
//   (test override 用, null = 用 prod 值)
// - getter 走 `_currentXxx ?? _prodXxx`
// - test helper 有 4 个 per-flag setter + 1 个全局 enableForTest / resetForTest
//   (保持跟原 R66 enableForTest 兼容, 老 test 不用改)
//
// 影响范围 (各 flag 关闭时):
//   - phqGad7I18nEnabled=false (R65b 阶段开启):
//     PHQ-9 / GAD-7 16 题 i18n 走 fallback key (避免 zh_Hant 显示英文 fallback)
//   - bootReceiverEnabled=false (R93 阶段 2 默认改 false):
//     NotificationInitializer 跳过设备重启后重排
//   - fiveVendorPushEnabled=false (R93 阶段 2 新增, 5 厂商 push SDK 接入前):
//     NotificationStatusCard 隐藏"5 厂商自检" section
//   - healthKitEnabled=false (v1.1.0+183 R128c 新增, HealthKit 5-6 月真接前):
//     HealthKitService 所有 method 走 NoOp (mood → Apple Health 联动 0 副作用)
//   - ventAudioEnabled=true (R93 阶段 2 新增, R104 启用语音录制):
//     vent_compose_page + mood_recorder_page 显示 mic 录音 button
//
// 位置说明: 本文件放 `core/data/` 而非 `core/shared/`,因为实际只有 data 层
// 引用, 符合"shared/ 工具至少被 2 层用"的架构约束。`check_all.dart` 守门员已校验。
import 'package:flutter/foundation.dart' show visibleForTesting;

class FeatureFlags {
  const FeatureFlags._();

  // ====== Production const values (启动时锁定, prod 永不改变) ======
  static const bool _prodPhqGad7I18nEnabled = false;
  // R93 阶段 2: BootReceiver 完善前 (R55 阶段), 设备重启后 WorkManager 触发
  // 可能 crash。临时关闭避风险, 等 v0.28 真接 WorkManager 完善后翻 true。
  // 跟 R72 Sprint 撤回逻辑一致 (Sprint 1 撤回后默认不开)。
  static const bool _prodBootReceiverEnabled = false;
  // R93 阶段 2 新增: 5 厂商 push SDK 接入前 (米/华/OPP/vivo/魅族, 1-2 月审核)。
  // FiveVendorPushService.register 默认早返 false + NotificationStatusCard
  // 隐藏"5 厂商自检" section。
  static const bool _prodFiveVendorPushEnabled = false;
  // v1.1.0+183 R128c 新增: HealthKit 5-6 月真接前 (Apple HealthKit entitlement +
  // Info.plist NSHealthShareUsageDescription + health_kit pub 依赖 + 真接 impl)。
  // HealthKitService 所有 method 走 NoOp (跟 5 厂商 push NoOp 同模式),
  // 情绪日记联动 Apple Health 0 副作用, 不阻塞主流程。
  static const bool _prodHealthKitEnabled = false;
  // R93 阶段 2 新增: vent audio 录音业务闭环不全 (storage / export 业务暂停)。
  // vent_compose_page + mood_recorder_page 隐藏 mic 录音 button。
  // R104: 启用语音录制，支持用户录制语音存入树洞
  static const bool _prodVentAudioEnabled = true;

  // ====== Test override (nullable, null = use _prod) ======
  static bool? _currentPhqGad7I18nEnabled;
  static bool? _currentBootReceiverEnabled;
  static bool? _currentFiveVendorPushEnabled;
  static bool? _currentHealthKitEnabled;
  static bool? _currentVentAudioEnabled;

  // ====== 公共 getter (生产代码读这里) ======

  /// PHQ-9 / GAD-7 量表 16 题 i18n 开关
  ///
  /// R65b 阶段开启 (量表题目 + 严重度 + 危机电话完整 i18n 走完 ARB 时)
  /// 默认 false (题目用 fallback key, 避免 zh_Hant 显示英文)。
  static bool get phqGad7I18nEnabled =>
      _currentPhqGad7I18nEnabled ?? _prodPhqGad7I18nEnabled;

  /// Android BootReceiver 完善开关
  ///
  /// v0.28 WorkManager 完善之前临时关闭 (避 BootReceiver 重启时 crash)
  /// R93 阶段 2: 默认改为 false (设备重启后不重排通知, 等 WorkManager 完善后翻 true)。
  static bool get bootReceiverEnabled =>
      _currentBootReceiverEnabled ?? _prodBootReceiverEnabled;

  /// 5 厂商 push SDK 接入开关
  ///
  /// R93 阶段 2 新增: 5 厂商 push SDK 接入前 (米/华/OPP/vivo/魅族, 1-2 月审核)。
  /// false 时 FiveVendorPushService.register 早返 false,
  /// NotificationStatusCard 隐藏"5 厂商自检" section。
  /// 默认 false (v1.0 真接后翻 true)。
  static bool get fiveVendorPushEnabled =>
      _currentFiveVendorPushEnabled ?? _prodFiveVendorPushEnabled;

  /// HealthKit 接入开关 (Apple Health 情绪日记联动)
  ///
  /// v1.1.0+183 R128c 新增: HealthKit 5-6 月真接前 (Apple HealthKit entitlement +
  /// Info.plist NSHealthShareUsageDescription + health_kit pub 依赖 + 真接 impl)。
  /// false 时 HealthKitService 所有 method 走 NoOp (跟 5 厂商 push NoOp 同模式),
  /// 情绪日记联动 Apple Health 0 副作用, 不阻塞主流程。
  /// 默认 false (v1.0 真接后翻 true)。
  static bool get healthKitEnabled =>
      _currentHealthKitEnabled ?? _prodHealthKitEnabled;

  /// vent audio 录音业务开关
  ///
  /// R93 阶段 2 新增: vent audio 录音业务闭环不全 (storage / export 业务暂停)。
  /// false 时 vent_compose_page + mood_recorder_page 隐藏 mic 录音 button,
  /// VentAudioService.record 早返 null。
  /// R104 起默认 true (启用语音录制)。
  static bool get ventAudioEnabled =>
      _currentVentAudioEnabled ?? _prodVentAudioEnabled;

  // ====== Per-flag test setter (v0.27 R67 新增, R93 阶段 2 扩, round 4b 收 4 个) ======

  /// 仅供 test 使用 — 临时把 [phqGad7I18nEnabled] 翻成指定值。
  @visibleForTesting
  static void setPhqGad7I18nEnabledForTest(bool? v) =>
      _currentPhqGad7I18nEnabled = v;

  /// 仅供 test 使用 — 临时把 [bootReceiverEnabled] 翻成指定值。
  @visibleForTesting
  static void setBootReceiverEnabledForTest(bool? v) =>
      _currentBootReceiverEnabled = v;

  /// 仅供 test 使用 — 临时把 [fiveVendorPushEnabled] 翻成指定值。
  @visibleForTesting
  static void setFiveVendorPushEnabledForTest(bool? v) =>
      _currentFiveVendorPushEnabled = v;

  /// 仅供 test 使用 — 临时把 [healthKitEnabled] 翻成指定值。
  @visibleForTesting
  static void setHealthKitEnabledForTest(bool? v) =>
      _currentHealthKitEnabled = v;

  /// 仅供 test 使用 — 临时把 [ventAudioEnabled] 翻成指定值。
  @visibleForTesting
  static void setVentAudioEnabledForTest(bool? v) =>
      _currentVentAudioEnabled = v;

  // ====== Global test helper (保持 R66 兼容, 老 test 不用改) ======

  /// 仅供 test 使用 — 临时把全部 4 个 flag 翻成 enable,跑测试期间走真实业务。
  ///
  /// 等价于:
  ///   setPhqGad7I18nEnabledForTest(true)
  ///   setBootReceiverEnabledForTest(true)
  ///   setFiveVendorPushEnabledForTest(true)
  ///   setVentAudioEnabledForTest(true)
  ///
  /// caller 必须在 tearDown 调 [resetForTest] 恢复,避免污染后续 test。
  @visibleForTesting
  static void enableForTest() {
    _currentPhqGad7I18nEnabled = true;
    _currentBootReceiverEnabled = true;
    _currentFiveVendorPushEnabled = true;
    _currentVentAudioEnabled = true;
  }

  /// 仅供 test 使用 — 把 4 个 flag 全部清空 override,回到 prod 默认值。
  @visibleForTesting
  static void resetForTest() {
    _currentPhqGad7I18nEnabled = null;
    _currentBootReceiverEnabled = null;
    _currentFiveVendorPushEnabled = null;
    _currentVentAudioEnabled = null;
  }
}
