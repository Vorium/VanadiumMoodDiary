package com.chroniccare.chroniccare

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.util.Log

/// v0.27 round 63 (GooglePlay P0 修复): BootReceiver 通知恢复
///
/// 背景: AndroidManifest.xml:30 声明 `RECEIVE_BOOT_COMPLETED` 权限,但
/// 之前 0 任何 BroadcastReceiver 实现 → 用户重启手机后所有 flutter_local_notifications
/// 定时通知全失 → 精神心理患者 7 天后才发现"已停药"无提醒。
///
/// 修复: 本 Receiver 接收 `BOOT_COMPLETED` 广播后,启动 MainActivity 让
/// Flutter 侧 `lib/core/data/services/notification_service.dart` 的
/// `rescheduleAll()` 方法重排全部通知 (MainActivity 启动时已调)。
///
/// 实现方案 (v0.27 R63 起步, 后续 R64+ 完善):
/// 1. 启动 MainActivity 重新调 scheduleDailyReminder / rescheduleAll
/// 2. 完整方案需 FlutterEngineCache.getInstance().get(engineId) 复用 engine
///    + MethodChannel 调 Flutter 侧 rescheduleAll, 留给 R64 完善。
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != Intent.ACTION_BOOT_COMPLETED &&
            intent.action != "android.intent.action.QUICKBOOT_POWERON") {
            return
        }

        // 简化方案: 启动 MainActivity 重新调 scheduleDailyReminder。
        // 完整方案需 FlutterEngineCache.getInstance().get(engineId) 复用 engine
        // + MethodChannel 调 Flutter 侧 rescheduleAll, 留给 R64 完善。
        try {
            val launchIntent = Intent(context, MainActivity::class.java).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                putExtra("from_boot", true)
            }
            context.startActivity(launchIntent)
        } catch (e: Exception) {
            // 用户重启场景失败不应崩 — 用户看不到 log, 仅 dev 模式可见
            Log.w("BootReceiver", "Failed to launch MainActivity on BOOT_COMPLETED", e)
        }
    }
}
