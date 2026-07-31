import Flutter
import UIKit
import BackgroundTasks
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // v0.27 round 67 (Sprint 1 上架前 P0, appstore C-P0-8):
    // 1. iOS 10+ foreground 通知显示 — 不设 UNUserNotificationCenter.delegate
    //    → iOS 14+ foreground 通知不弹, 用户体验断档 (不见通知不知道失联)
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as? UNUserNotificationCenterDelegate
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
