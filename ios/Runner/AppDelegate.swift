import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, UNUserNotificationCenterDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // v0.27 round 67 (Sprint 1 上架前 P0, appstore C-P0-8):
    // 1. iOS 10+ foreground 通知显示 — UNUserNotificationCenter.delegate 设 self
    //    → iOS 14+ foreground 通知正常弹 (.banner + .sound + .badge)
    //    失联通知 / 打卡提醒关键场景, 用户在 app 内也要看到。
    //
    // v0.27 round 75 (R74 报告 AS-P0-3 修): 之前 R67 写 `self as? UNUserNotificationCenterDelegate`
    //    → AppDelegate 没 conform protocol → delegate = nil → foreground 通知
    //    静默不弹, 精神心理患者错过失联告警。修法: AppDelegate conform
    //    UNUserNotificationCenterDelegate + 删 `as?` 强转 + 实现
    //    `userNotificationCenter(_:willPresent:withCompletionHandler:)`。
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    // v0.30 R100 (P0#6, appstore A-3): BGTaskScheduler.register 占位代码已删
    // (跟 Info.plist 删 UIBackgroundModes processing + BGTaskSchedulerPermitted
    // Identifiers 同步, 避 Apple 2.5.4 拒)。失联检测 BGProcessingTask 真接时
    // (阿里云 SMS 启用后) 重新加回 register + Info.plist 声明。
    //
    // v0.30 R108 (P0#2): UIBackgroundModes audio 已恢复
    // (Info.plist 同步加回, 原因: R104 ventAudioEnabled=true 后台录音需要)。
    // 不需要在 AppDelegate 里 register 任何东西, audio mode 是系统级声明,
    // AVAudioSession 在录音启动时自动接管后台。

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // v0.30 R108 (P0#1): 注册 "chroniccare/backup" MethodChannel
    // 让 Dart 侧 (SkipBackup) 调 setSkipBackup 标文件不参与 iCloud Backup。
    // 精神心理患者敏感数据 (SQLCipher DB / vent audio / audit log) 默认
    // 会随 iCloud Backup 上传, 违反零云端架构基线 + PIPL 风险。
    // 在 didInitializeImplicitFlutterEngine 注册: 跟 GeneratedPluginRegistrant
    // 同步, Flutter engine 就绪后立刻注册 channel, Dart 侧 SkipBackup 调用
    // 不会因 channel 未注册而抛 MissingPluginException。
    // 用 FlutterAppDelegate 的 controller (FlutterViewController) 拿 binaryMessenger
    // —— standard pattern, 跟 SceneDelegate / 其他官方插件注册同源。
    if let messenger = self.controller?.binaryMessenger {
      let backupChannel = FlutterMethodChannel(
        name: "chroniccare/backup",
        binaryMessenger: messenger
      )
      backupChannel.setMethodCallHandler { [weak self] (call, result) in
        guard let self = self else {
          result(FlutterError(code: "UNAVAILABLE", message: "AppDelegate gone", details: nil))
          return
        }
        switch call.method {
        case "setSkipBackup":
          guard let args = call.arguments as? [String: Any],
                let path = args["path"] as? String else {
            result(FlutterError(code: "BAD_ARGS", message: "Missing 'path' argument", details: nil))
            return
          }
          self.setSkipBackupAttributeToItem(path: path)
          result(nil)
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }
  }

  /// v0.30 R108 (P0#1): iCloud Backup 排除
  ///
  /// 设 `isExcludedFromBackup = true` 让指定文件 / 目录不随 iCloud Backup 上传。
  /// 失败不抛 (best-effort, Dart 侧 swallow + log)。 重复调幂等。
  private func setSkipBackupAttributeToItem(path: String) {
    var fileURL = URL(fileURLWithPath: path)
    do {
      var values = URLResourceValues()
      values.isExcludedFromBackup = true
      try fileURL.setResourceValues(values)
    } catch {
      // best-effort: 不抛错, Dart 侧 SkipBackup 内部 swallow
    }
  }

  // v0.27 round 75 (R74 报告 AS-P0-3 修): iOS 10+ foreground 通知展示。
  //
  // 之前 R67 只设 delegate 没实现 willPresent, foreground 通知被系统静默。
  // 失联告警 / 打卡提醒属精神心理患者关键场景, 在 app 内也要弹通知。
  //
  // 返回 [.banner, .list, .sound, .badge]: banner 顶部横幅, list 通知中心,
  // sound 提示音, badge 角标 (跟 Android 4 channel importance=max 对齐)。
  @available(iOS 10.0, *)
  func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    completionHandler([.banner, .list, .sound, .badge])
  }
}
