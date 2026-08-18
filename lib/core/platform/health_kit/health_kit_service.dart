// v1.1.0+183 R128c (R110 阶段 4) — HealthKit 平台抽象 stub 骨架
//
// 背景:
// - R108 §六 综合审视: HealthKit 0 集成, 留 v1.0 长期 (5-6 月) 真接
// - R128c 阶段 1: 跟 R124 5 厂商 push 同模式, 先建 abstract + NoOp stub,
//   flag=false 默认走 NoOp, 5-6 月后真接时只换 impl + 加 health_kit pub
//   依赖 + iOS HealthKit entitlement
//
// 修正模式 (跟 R124 5 厂商 push facade 完整一致):
// - 1 个 abstract HealthKitChannel (4 method: isAvailable / authorize /
//   writeMindfulSession / readMindfulSession)
// - 1 个 NoOpHealthKitChannel 默认实现 (未接 SDK 时早返 false / null)
// - 1 个 HealthKitService 公开 facade (4 method 走 flag 短路 + factory)
// - FeatureFlag.healthKitEnabled (默认 false, 跟 fiveVendorPushEnabled 同)
//
// v1.0 真实集成路径 (R128d 阶段 5 之后, 5-6 月后):
// 1. pubspec.yaml 加 `health_kit: ^4.x` (Apple HealthKit Flutter 插件)
// 2. iOS Runner.entitlements 加 `com.apple.developer.healthkit: true`
// 3. iOS Info.plist 加 `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription`
// 4. 修正 PrivacyInfo.xcprivacy 加 NSPrivacyAccessedAPITypesUserDefaults (read-only)
// 5. 真接 impl: AppleHealthKitChannel implements HealthKitChannel (走 health_kit
//    插件的 requestAuthorization + writeData + readData)
// 6. 修正 check_apple_health_claim.py (5.1.3 拒审防护 → 改成 accept health_kit import)
// 7. flag 翻 true (5 厂商 push 审核 1-2 月 + HealthKit 审核 1 周同步翻)
//
// 4 层架构纯度: 0 flutter / 0 drift / 0 data / 0 presentation, 本文件是
// service 抽象层。0 violation, check_all.dart 守门员绿。

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';

/// HealthKit channel 抽象 (R128c 阶段 1 stub, 跟 R124 5 厂商 push 抽象同模式)
abstract class HealthKitChannel {
  /// 平台名 (用于日志 + 守门员 + 自检卡显示)
  String get channelName;

  /// HealthKit 是否可用 (设备支持 + 用户已授权)
  Future<bool> isAvailable();

  /// 请求 HealthKit 授权 (读写 mindful session / mood 数据)
  ///
  /// 返 true = 用户授权成功, false = 用户拒绝 / 平台不支持
  Future<bool> authorize();

  /// 写 mindful session 到 Apple Health (情绪日记用户主动冥想 1 次记 1 条)
  ///
  /// 返 true = 写入成功, false = 用户未授权 / 平台不支持
  Future<bool> writeMindfulSession({
    required DateTime start,
    required DateTime end,
  });

  /// 读最近 N 天 mindful session 列表 (从 Apple Health 拉, 给情绪回顾用)
  ///
  /// 返 `List<MindfulSession>` (start, end) pair, 空 = 平台不支持 / 用户未授权
  Future<List<MindfulSession>> readMindfulSessions({int days = 7});
}

/// 单条 mindful session 数据 (R128c 阶段 1 stub, v1.0 真接时跟 health_kit
/// 插件的 HKCategorySample 字段对齐, 字段全 final 已是 immutable)
class MindfulSession {
  const MindfulSession({required this.start, required this.end});
  final DateTime start;
  final DateTime end;
}

/// NoOp 默认 channel — HealthKit SDK 未接入时走此
///
/// R128c 阶段 1: 在 SDK 接入前, 所有 method 早返 false / 空 List。
/// 跟 R124 NoOpFiveVendorPushChannel 同模式, 行为 100% 一致:
/// - isAvailable() → false
/// - authorize() → false
/// - writeMindfulSession() → false
/// - readMindfulSessions() → []
///
/// flag=false 时 (默认 prod 状态), HealthKitService 直接走 NoOp, 不调
/// factory, 0 副作用。
class NoOpHealthKitChannel implements HealthKitChannel {
  const NoOpHealthKitChannel();

  @override
  String get channelName => 'NoOp (HealthKit SDK 未接入)';

  @override
  Future<bool> isAvailable() async => false;

  @override
  Future<bool> authorize() async => false;

  @override
  Future<bool> writeMindfulSession({
    required DateTime start,
    required DateTime end,
  }) async =>
      false;

  @override
  Future<List<MindfulSession>> readMindfulSessions({int days = 7}) async =>
      const <MindfulSession>[];
}

/// HealthKit 5 厂商 push factory (R128c 阶段 1 stub, 5-6 月后真接时改)
class HealthKitFactory {
  HealthKitFactory._();

  /// 创建 channel (现阶段全部 NoOp, 真接后改 platform isIOS + hasHealthKit
  /// → AppleHealthKitChannel)
  static HealthKitChannel createChannel() {
    return const NoOpHealthKitChannel();
  }
}

/// HealthKit service 公开 facade (R128c 阶段 1 stub, 跟 R124 5 厂商 push facade 同模式)
///
/// 公开 API:
/// - [isAvailable] flag=true + 平台支持 + 用户授权
/// - [requestAuthorization] 申请 HealthKit 授权 (dialog)
/// - [writeMindfulSession] 写 1 条 mindful session (情绪日记联动)
/// - [readMindfulSessions] 读最近 N 天 mindful session (情绪回顾增强)
///
/// R128c 阶段 1 设计意图:
/// - flag=false 时 (默认 prod 状态) 所有 method 早返 false / null / [],
///   不影响主流程
/// - flag=true 时 (5-6 月后真接) 走 factory 选 channel
/// - 现阶段 HealthKit SDK 未接, 即使 flag=true 也会走 NoOp
///
/// 错误处理: 走 audioErrorSink (跟 R120 notification_service 7 facade
/// 同款, 失败不阻塞情绪日记流)。
class HealthKitService {
  const HealthKitService._();

  /// HealthKit 是否可用 (flag=true + 平台支持 + 用户已授权)
  static Future<bool> isAvailable() async {
    if (!FeatureFlags.healthKitEnabled) return false;
    try {
      final channel = HealthKitFactory.createChannel();
      return await channel.isAvailable();
    } catch (e, st) {
      audioErrorSink(
        where: 'health_kit_service.isAvailable',
        error: e,
        stack: st,
        note: 'HealthKit isAvailable 失败 — 走本地数据流',
      );
      return false;
    }
  }

  /// 请求 HealthKit 授权 (用户首次点"同步到 Apple Health"时调)
  static Future<bool> requestAuthorization() async {
    if (!FeatureFlags.healthKitEnabled) return false;
    try {
      final channel = HealthKitFactory.createChannel();
      return await channel.authorize();
    } catch (e, st) {
      audioErrorSink(
        where: 'health_kit_service.requestAuthorization',
        error: e,
        stack: st,
        note: 'HealthKit requestAuthorization 失败',
      );
      return false;
    }
  }

  /// 写 1 条 mindful session 到 Apple Health
  static Future<bool> writeMindfulSession({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!FeatureFlags.healthKitEnabled) return false;
    try {
      final channel = HealthKitFactory.createChannel();
      return await channel.writeMindfulSession(start: start, end: end);
    } catch (e, st) {
      audioErrorSink(
        where: 'health_kit_service.writeMindfulSession',
        error: e,
        stack: st,
        note: 'HealthKit writeMindfulSession 失败',
      );
      return false;
    }
  }

  /// 读最近 N 天 mindful session 列表
  static Future<List<MindfulSession>> readMindfulSessions({
    int days = 7,
  }) async {
    if (!FeatureFlags.healthKitEnabled) return const <MindfulSession>[];
    try {
      final channel = HealthKitFactory.createChannel();
      return await channel.readMindfulSessions(days: days);
    } catch (e, st) {
      audioErrorSink(
        where: 'health_kit_service.readMindfulSessions',
        error: e,
        stack: st,
        note: 'HealthKit readMindfulSessions 失败',
      );
      return const <MindfulSession>[];
    }
  }
}
