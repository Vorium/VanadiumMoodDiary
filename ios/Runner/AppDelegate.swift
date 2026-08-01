import Flutter
import UIKit
import BackgroundTasks
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

    // 2. 注册 BGTaskScheduler — Info.plist 已声明
    //    `com.chroniccare.safety-check` (BGTaskSchedulerPermittedIdentifiers),
    //    必须跟这里 register 一致, 否则后台任务不调度
    // v0.27 R66 (2026-07-31) 现状: 失联通知业务整体暂停
    // (FeatureFlags.emergencyContactEnabled = false), 真正的 SMS 触达
    // 等 v1.0 接阿里云 SMS provider 后启用。本 register 占位, 让 iOS 审核
    // 看到 capability 已声明但不实际触发 (跟 Info.plist 一致)
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: "com.chroniccare.safety-check",
      using: nil
    ) { task in
      self.handleSafetyCheckTask(task: task as! BGProcessingTask)
    }

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

  // v0.27 round 67: BGTaskScheduler handler 占位实现
  //
  // 真实逻辑 (v1.0+ 接入阿里云 SMS 后):
  // 1. 通过 MethodChannel 调 Flutter 端 `checkLostContact(now)`
  // 2. 拿 CareEngine 决策结果
  // 3. 若需要通知 → 调 SMS provider 发短信给紧急联系人
  // 4. 设 task.setTaskCompleted(success: true)
  //
  // 当前 (R67): 业务暂停, 直接 setTaskCompleted, 防止 iOS 后台资源浪费。
  private func handleSafetyCheckTask(task: BGProcessingTask) {
    task.setTaskCompleted(success: true)
  }
}
