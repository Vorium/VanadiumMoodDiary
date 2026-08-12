# 底层逐行审计 A — domain + data + core/shared (2026-08-13)

范围: lib/domain/** + lib/core/data/** + lib/core/shared/** + lib/core/l10n/** + main/app.dart, 全部遍历; 跑了 check_all (3 违规)。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| B1-1 | data·robustness | **通知 ID 碰撞 — 固定 ID 被 cancel range 静默误杀**: safetyAlertId=5000 / assessmentReminderId=7000 / moodReminderId=8000 / badgeSyncId=9999 全部落入 medication [2000,202000) 与 refill [6000,206000) 区间; 且 med id ≥6000 (medId≥398, 公式 2000+medId*10) 落入 refill 区间, refill id 落入 med 区间。每次启动/改药/续方重排都会删除这些 pending 通知 | reminder_dispatcher.dart:75-96 / medication_notifier.dart:113,127 / refill_notifier.dart:41,57,201 / notification_service.dart:81 / mood_reminder_notifier.dart:27 / badge_sync_service.dart:29 | ≤1h | **P0 bug** |
| B1-2 | 纯度 | 3 处 domain purity 违规 (与 AR-1 同): phone_validator / feature_flags / flutter/foundation visibleForTesting | 见 AR-1 | ≤0.5h/处 | **P1** |
| B1-3 | 逻辑 | **SleepCalculator.regularityScore 用线性 mean 算圆形时间**: 23:50/00:10 交替 (跨午夜规律) → stdDev≈1430min → 得分 1 最差 (数学错误); durationMin bedtime==wakeTime=0 (文档化, OK) | sleep_calculator.dart:43-62 | ≤1d | P2 |
| B1-4 | data | MedicationTimes.getter 接受未校验 h/m (无 0..23/0..59 边界); legacy v1-v4 或 import 脏行 (h:24) → zonedDaily 错/吞 | mappers/medication/medication_times.dart:26-40 | ≤0.5h | P2 |
| B1-5 | hygiene | SafetyAlertBuilder.buildFor 死 userName 参数 (safeUserName 算完丢弃, R32 后 title 有意无名字) — 死参数防回归 | safety_alert_builder.dart:115-116 | ≤0.5h | P3 |
| B1-6 | 鲁棒 | SQLCipher key 丢失 = 无恢复路径 (DB 文件在 keychain 丢): 打开 garbage → "file is not a database" → 错误横幅, 无导出/恢复入口 | connection/native.dart:30-43 / db_key_service.dart / main.dart:170-179 | ≤1d | P3 |
| B1-7 | 逻辑 | (中置信) assessment reminder past-fireAt 被跳过无 follow-up: notifier 单 id 7000, catch-up now+1h 只在 policy, 若分歧 → 评估提醒永不重发 | assessment_notifier.dart / assessment_reminder_policy.dart:computeNextFireTime | ≤2h | P2 |

## 验证干净项 (全绿)

- mapper 1:1 字段对齐 (check_in/medication/mood 全读) · DateTime.now() 入口单次纪律 9 处 (safety_alert_builder 已修多调 race) · swallow_log_sink UTC 时间戳 (R108 P0-12 闭环) · streak_calculator 显式 DESC sort + minutes 级过期 · 迁移链 (delete-old-DB + throw) + main.dart 对话框流 · data/* 用 flutter/foundation 合规 (data 层可用 Flutter)

## 总结

1) **P0 系统性 bug: 200000 宽 cancel 区间锚在 2000/6000, 固定 ID 5000/7000/8000/9999 全被误杀** (每次启动/重排都会静默删); 修法: 固定 ID 移 2M+ 带 (snooze 已占 300000+2M, 需避开) — 直接违背 AGENTS 已知坑本意 (range 扩到 200000 但固定 ID 留在里面); 2) P1: 3 处 purity (3 个小 move); 3) P2: sleep 圆统计 + MedicationTimes 校验 + 评估提醒时机; 4) P3: 死参数 / key 丢失恢复 / ; 5) 其余全部干净。