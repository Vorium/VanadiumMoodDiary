// v0.30 R108 (P0 #1: iCloud Backup 排除)
//
// 精神心理患者敏感数据 (SQLCipher db / vent audio / audit log / notification
// channel metadata) 默认会随 iCloud Backup 上传到 Apple 服务器。
// 跟项目零云端架构冲突,也是 PIPL 风险 (精神心理 PII 备份到 Apple = 跨境数据)。
//
// 本集中器: 4 处 caller (native.dart / encrypted_audio_storage.dart /
// swallow_log_sink.dart / notification_service channel metadata) 调
// `SkipBackup.markAsSkipped(path)`, 内部走 iOS MethodChannel 调 Swift helper
// 设 `URLResourceValues.isExcludedFromBackup = true`。
//
// 平台策略:
// - iOS: 走 Swift helper (`chroniccare/backup` MethodChannel)
// - Android: noop (Android backup 由 AndroidManifest 的 `android:allowBackup`
//   + `android:fullBackupContent` 控制, 本类不涉及)
// - Web: noop (web 端用 IndexedDB, 不参与 iCloud Backup)
// - 测试 / 不支持的平台: noop, 但不抛错 (避免 release 之前开发流程 crash)
//
// 设计原则:
// - 不抛错: backup 标记失败不阻塞主流程, swallow + log
// - 幂等: 重复调安全 (NSURL setResourceValues 是 idempotent)
// - 隔离: 仅操作传入的 path, 不扫整个目录 (避免误标记用户文件)
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart'
    show kIsWeb, kDebugMode, visibleForTesting, debugPrint;
import 'package:flutter/services.dart' show MethodChannel;

import 'package:chroniccare/core/shared/swallow_error.dart';

/// v0.30 R108: iCloud Backup 排除集中器
///
/// 用途: 把精神心理敏感数据的本地文件标记为"不参与 iCloud Backup", 满足:
/// 1. 零云端架构 (项目基线原则)
/// 2. PIPL §6 最小化原则 (不向云端同步 PII)
/// 3. App Store 5.1.1 隐私指引 ("health & sensitive data" 明确应 opt-out)
///
/// iOS 实现: 调 `chroniccare/backup` MethodChannel → Swift
/// `setSkipBackupAttributeToItem(path)` 设 `isExcludedFromBackup = true`。
/// Android / Web / 测试环境: noop (Android 走 Manifest, Web 走 IndexedDB)。
class SkipBackup {
  SkipBackup._();

  /// MethodChannel name (跟 iOS `AppDelegate.swift` 注册的 channel 对应)
  ///
  /// 修改时同步 iOS `AppDelegate.swift` 的 `FlutterMethodChannel(name:...)`
  @visibleForTesting
  static const String channelName = 'chroniccare/backup';

  /// Method name (Swift 侧 handler 的 case)
  @visibleForTesting
  static const String methodMark = 'setSkipBackup';

  /// 缓存 MethodChannel 实例 (避免每次调用都重建, MethodChannel 内部
  /// BinaryMessenger 注册幂等, 但单例可减少开销)
  @visibleForTesting
  static MethodChannel? _channel;

  /// 是否为 iOS 平台 (避免在 Android / Web / 测试环境调 platform channel)
  static bool get _isIos => !kIsWeb && Platform.isIOS;

  /// 取 MethodChannel 实例 (测试可见, override 注入)
  @visibleForTesting
  static MethodChannel getChannel() {
    return _channel ??= const MethodChannel(channelName);
  }

  /// 测试用: 重置 channel 缓存 (允许 mock / override)
  @visibleForTesting
  static void resetChannelForTest() {
    _channel = null;
  }

  /// 把 path 标记为"不参与 iCloud Backup"
  ///
  /// 行为:
  /// - iOS: 调 platform channel 同步设 `isExcludedFromBackup = true`
  /// - 其他平台 (Android / Web / Linux / macOS / Windows / Fuchsia): noop
  /// - path 为空: 早返, 不发空消息
  /// - platform channel 抛错: swallow + log, 不阻塞 caller
  ///
  /// 调用场景:
  /// - native.dart:18 — SQLCipher DB 创建后
  /// - encrypted_audio_storage.dart:99 — vent / mood audio 目录创建后
  ///   (注意: 标记目录 = 整个目录都不进 iCloud backup, 包括新加文件)
  /// - swallow_log_sink.dart:54 — swallow.log 创建后
  ///
  /// 不调 channel 的场景: caller 在 web 端 / 测试环境 (不会调到 iOS 真机)。
  /// 假设 4 caller 都在 native 端 (iOS / Android), Android 走 noop 分支。
  static Future<void> markAsSkipped(String path) async {
    if (path.isEmpty) return;
    if (!_isIos) return; // Android / Web / other → noop
    try {
      await getChannel().invokeMethod<void>(methodMark, {'path': path});
    } catch (e, st) {
      // backup 标记失败不阻塞主流程 (DB / audio / log 创建已成功)
      // 走 swallowError, dev mode 看到, release mode 写 swallow.log
      swallowError(
        where: 'SkipBackup.markAsSkipped',
        error: e,
        stack: st,
        note: 'iOS setSkipBackup failed for path, PII may still backup. '
            'path.len=${path.length}',
      );
      if (kDebugMode) {
        debugPrint('[SkipBackup] iOS mark failed (path.len=${path.length}): $e');
      }
    }
  }
}
