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

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
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
