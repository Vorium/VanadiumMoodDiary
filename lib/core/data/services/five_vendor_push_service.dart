// v1.1.0+170 R124 (v1.0 长期 5 厂商 push facade 接入) — 5 厂商 push 抽象
// 通道 + NoOp 默认实现 + factory
//
// 背景 (R93 阶段 2 + 1.1.0 round 4b → R124 闭环):
// - 1.1.0 round 4b: 失联通知 100% 失效, 5 厂商 push SDK 1-2 月审核中
// - R93 阶段 2 加了 [FeatureFlags.fiveVendorPushEnabled] flag (默认 false),
//   但 FiveVendorPushService.register 早返 false 的承诺代码没写
// - NotificationStatusCard UI 已写 5 厂商 OEM 引导 (gate 在 false 时 hidden)
//
// v1.0 准备 (R124):
// - 5 通道 abstract 抽象 (跟 R120 notification_service 7 facade 模式匹配)
// - 5 厂商占位 impl 框架 (SDK 接入时改 implement, 现阶段 throw
//   UnimplementedError 让 caller 知道 SDK 还没接)
// - NoOpFiveVendorPushChannel 默认实现 — flag=false / SDK 未接时走此
// - 工厂方法按 device brand 选 impl (现阶段全部 NoOp, 真接后改)
// - 公开 facade FiveVendorPushService.register / unregister / isAvailable
//
// 实际 SDK 接入推迟 (5 厂商审核 1-2 月, 不在本批工作):
// - 小米 MiPush: mipush SDK 接入 (AndroidManifest service + receiver +
//   AppID / AppKey / AppSecret)
// - 华为 HMS Push: huawei.hms:push 接入 (com.huawei.hms 包名, agconnect)
// - OPPO HeyTap Push: com.heytap.msp 接入 (HeyTap 开发者中心)
// - vivo Push: com.vivo.push 接入 (vivo 开发者中心)
// - 魅族 FlymePush: com.meizu.cloud 接入 (魅族 Flyme 开发者中心)
//
// 4 层架构纯度: 0 flutter / 0 drift / 0 data / 0 presentation, 本文件是
// service 抽象层。FeatureFlags 是 data 层但本 facade 是 data 层服务实现
// (实际调用 5 厂商 SDK 必然 data 层)。check_all.dart 守门员 0 violation。

import 'package:chroniccare/core/data/feature_flags.dart';
import 'package:chroniccare/core/shared/error_sinks.dart';

/// 5 厂商 push channel 抽象 (R124 5 厂商 facade)
abstract class FiveVendorPushChannel {
  /// 厂商名 (用于日志 + 守门员 + 自检卡显示)
  String get vendorName;

  /// 注册 channel (申请 push token, 失败返 false)
  Future<bool> register();

  /// 反注册 channel (清 token + 解绑 alias)
  Future<void> unregister();

  /// 拿 push token (null = 未注册 / 失败)
  Future<String?> getPushToken();
}

/// NoOp 默认 channel — 5 厂商 SDK 未接入时走此
///
/// R93 阶段 2 + 1.1.0 round 4b: 在 SDK 接入前, register 早返 false, no-op 实现
/// 跟本地通知 (flutter_local_notifications) 共存, 不影响现有通知流。
class NoOpFiveVendorPushChannel implements FiveVendorPushChannel {
  const NoOpFiveVendorPushChannel();

  @override
  String get vendorName => 'NoOp';

  @override
  Future<bool> register() async => false;

  @override
  Future<void> unregister() async {
    // no-op
  }

  @override
  Future<String?> getPushToken() async => null;
}

/// 5 厂商 push channel 工厂 (R124)
abstract class FiveVendorPushFactory {
  /// 按 device brand 选 impl — R124 现阶段全部 NoOp, SDK 接入时改
  ///
  /// 真接后改模式:
  ///   if (brand == 'xiaomi') return MiPushChannel();
  ///   if (brand == 'huawei') return HmsPushChannel();
  ///   ...
  ///   return const NoOpFiveVendorPushChannel();
  static FiveVendorPushChannel createChannel() =>
      const NoOpFiveVendorPushChannel();
}

// ===== 5 厂商占位 impl (R124 现阶段 throw UnimplementedError) =====
//
// v1.0 真接 SDK 时改: 替换 UnimplementedError 调真实 SDK API
// (mipush.register / hms.HmsMessaging.getInstance / oppo.PushManager 等)
// + 在 AndroidManifest 加 service / receiver + AppID / AppKey
// + pubspec.yaml 加 5 厂商 dependency
// + 守门员 check_five_vendor_push_ready.py 加 5 厂商 SDK 真接验证

/// 小米 MiPush channel 占位 (R124 阶段 1: SDK 未接)
class MiPushChannel implements FiveVendorPushChannel {
  const MiPushChannel();

  @override
  String get vendorName => 'MiPush';

  @override
  Future<bool> register() async {
    throw UnimplementedError(
      'MiPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 register',
    );
  }

  @override
  Future<void> unregister() async {
    throw UnimplementedError(
      'MiPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 unregister',
    );
  }

  @override
  Future<String?> getPushToken() async {
    throw UnimplementedError(
      'MiPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 getPushToken',
    );
  }
}

/// 华为 HMS Push channel 占位
class HmsPushChannel implements FiveVendorPushChannel {
  const HmsPushChannel();

  @override
  String get vendorName => 'HmsPush';

  @override
  Future<bool> register() async {
    throw UnimplementedError(
      'HmsPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 register',
    );
  }

  @override
  Future<void> unregister() async {
    throw UnimplementedError(
      'HmsPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 unregister',
    );
  }

  @override
  Future<String?> getPushToken() async {
    throw UnimplementedError(
      'HmsPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 getPushToken',
    );
  }
}

/// OPPO HeyTap Push channel 占位
class OppoPushChannel implements FiveVendorPushChannel {
  const OppoPushChannel();

  @override
  String get vendorName => 'OppoPush';

  @override
  Future<bool> register() async {
    throw UnimplementedError(
      'OppoPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 register',
    );
  }

  @override
  Future<void> unregister() async {
    throw UnimplementedError(
      'OppoPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 unregister',
    );
  }

  @override
  Future<String?> getPushToken() async {
    throw UnimplementedError(
      'OppoPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 getPushToken',
    );
  }
}

/// vivo Push channel 占位
class VivoPushChannel implements FiveVendorPushChannel {
  const VivoPushChannel();

  @override
  String get vendorName => 'VivoPush';

  @override
  Future<bool> register() async {
    throw UnimplementedError(
      'VivoPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 register',
    );
  }

  @override
  Future<void> unregister() async {
    throw UnimplementedError(
      'VivoPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 unregister',
    );
  }

  @override
  Future<String?> getPushToken() async {
    throw UnimplementedError(
      'VivoPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 getPushToken',
    );
  }
}

/// 魅族 FlymePush channel 占位
class MeizuPushChannel implements FiveVendorPushChannel {
  const MeizuPushChannel();

  @override
  String get vendorName => 'MeizuPush';

  @override
  Future<bool> register() async {
    throw UnimplementedError(
      'MeizuPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 register',
    );
  }

  @override
  Future<void> unregister() async {
    throw UnimplementedError(
      'MeizuPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 unregister',
    );
  }

  @override
  Future<String?> getPushToken() async {
    throw UnimplementedError(
      'MeizuPush SDK 未接入 (R124 阶段 1), v1.0 真接前请勿调 getPushToken',
    );
  }
}

/// 5 厂商 push service 公开 facade (R124 阶段 1)
///
/// 公开 API:
/// - [register] 申请 push token (flag=false 早返 false, flag=true 走 factory)
/// - [unregister] 清 token + 解绑 alias
/// - [isAvailable] flag=true + register 成功
///
/// R124 阶段 1 设计意图:
/// - flag=false 时 (默认 prod 状态) register 早返 false, 不影响本地通知
/// - flag=true 时 (v1.0 真接 5 厂商 SDK 后) 走 factory 选 channel
/// - 现阶段 5 厂商 SDK 未接, 即使 flag=true 也会走 NoOp
///
/// 错误处理: 5 厂商 register 失败走 audioErrorSink (跟 R120 notification_service
/// 7 facade 同款, 失败不阻塞通知流)。
class FiveVendorPushService {
  const FiveVendorPushService._();

  /// 申请 push token
  ///
  /// 返 true = 注册成功 (5 厂商 SDK 实际接入后会拿 token)
  /// 返 false = flag 关闭 / register 失败
  static Future<bool> register() async {
    if (!FeatureFlags.fiveVendorPushEnabled) {
      return false;
    }
    try {
      final channel = FiveVendorPushFactory.createChannel();
      return await channel.register();
    } catch (e, st) {
      audioErrorSink(
        where: 'five_vendor_push_service.register',
        error: e,
        stack: st,
        note: '5 厂商 push register 失败 — 走本地通知 fallback',
      );
      return false;
    }
  }

  /// 反注册 (清 token + 解绑 alias)
  static Future<void> unregister() async {
    if (!FeatureFlags.fiveVendorPushEnabled) {
      return;
    }
    try {
      final channel = FiveVendorPushFactory.createChannel();
      await channel.unregister();
    } catch (e, st) {
      audioErrorSink(
        where: 'five_vendor_push_service.unregister',
        error: e,
        stack: st,
        note: '5 厂商 push unregister 失败 — 忽略',
      );
    }
  }

  /// 是否可用 (flag=true + 5 厂商 SDK 实际接入)
  static Future<bool> isAvailable() async {
    if (!FeatureFlags.fiveVendorPushEnabled) return false;
    final token = await getPushToken();
    return token != null;
  }

  /// 拿 push token
  static Future<String?> getPushToken() async {
    if (!FeatureFlags.fiveVendorPushEnabled) return null;
    try {
      final channel = FiveVendorPushFactory.createChannel();
      return await channel.getPushToken();
    } catch (e, st) {
      audioErrorSink(
        where: 'five_vendor_push_service.getPushToken',
        error: e,
        stack: st,
        note: '5 厂商 push getPushToken 失败',
      );
      return null;
    }
  }
}
