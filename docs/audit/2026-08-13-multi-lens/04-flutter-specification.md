# flutter-specification 视角审计 (2026-08-13)

只读文件审计, 未跑 analyze/test (工作树 mid-R109)。

## Findings

| ID | 类别 | 标题 | 证据 | 难度 | 优先级 |
|---|---|---|---|---|---|
| FS-1 | 架构 | **domain purity 3 处违规 (R109 已 commit, 非 transient)**: flutter/foundation visibleForTesting + phone_validator + feature_flags | domain/usecases/schedule_assessment_reminder.dart:15 / domain/logic/setup_welcome_form_validator.dart:16 / domain/logic/safety_alert_policy.dart:14 | ≤1h | **P1** |
| FS-2 | 性能 | daily_tracking_page 单 build watch 8 stream, 任一 tick 重建 403L 页 | daily_tracking_page.dart:43-52 | ≤1d | P2 |
| FS-3 | state | temp_medication_dialog 冷启动 ref.read(...).value ?? [] 闪空 + 可能 stale | temp_medication_dialog.dart:49,94 | ≤2h | P3 |
| FS-4 | state | shared_providers import 页面 widget (反向依赖, 仅 doc comment 用) | shared_providers.dart:1-2,152 | ≤0.5h | P3 |
| FS-7 | lifecycle | quick_mood_carousel raw SnackBar 绕过集中器 (注释声称走集中器但没走) | quick_mood_carousel.dart:90-97 | ≤0.5h | P3 |
| FS-8 | 性能 | 11 个 ≥400L god class 0 test (R109 拆解 50% 完成) | 见 SP-en-2~5 | XL | P2 |
| FS-9 | 性能 | 6 处非 builder ListView (有界列表, 今天可接受, trend 有增长风险) | reminders_hub / legal / settings / medication / trend / assessment_center | — | P3 |
| FS-10 | UI | reduce-transparency `&& false` 恒假死分支 | page_scaffold.dart:61-65 | ≤0.5h | P3 |
| FS-11 | state | home_fab_toolbar SingleTickerProviderStateMixin 无 ticker | home_fab_toolbar.dart:46 | ≤0.5h | P3 |
| FS-12 | db | schemaVersion 22 正确, **仅文档漂移** (AGENTS.md "12") | app_database.dart:143 | ≤0.5h | P3 |
| FS-13 | 架构 | saveSetup + clearAllUserData 业务编排仍在 AppDatabase | app_database.dart:420-510 | ≤1w | **P1** |

## 验证健康项 (全绿)

- Riverpod 3: autoDispose StreamProvider only / AsyncValue.guard (3.x sync) / 0 context.watch 滥用 / 0 valueOrNull 残留 / 0 keepAlive hack / streak midnight refresh (AppRoot timer + dayChangeTickProvider + crossedMidnightSince)
- 生命周期: 9 `.listen(` 全 cancel (vent_detail / vent_compose / mood_audio_recorder_widget / app_router ref.listen); 8 Timer 全 dispose; controllers 全 dispose; audio 顺序 recorder→player; 61 `!mounted` 守卫
- DB: SQLCipher PRAGMA key 先于 SQL / base64 校验 / createInBackground isolate / web 抛 UnsupportedError (零云端) / 全异步 watch
- 常量化: DateTime.now() 入口单次 (13 文件抽查) / kReminderCancelRange=200000 + snooze 2000000 集中 / NotificationStatusCard 存在
- 路由: 3 类 transition + Motion.duration reduce-motion / ShellRoute + 响应式 NavigationBar/Rail / redirect 纯函数 / route 字符串与 call site 匹配
- 平台: dart:io 限于 core/data / conditional import web/native / shaders ink_sparkle 3978B 声明齐全 / l10n 3 locale

## 总结

1) 架构: 3 处 commit 在 R109 的 purity 违规今天就让 check_all 红 (P1, 1h); 2) 性能: daily_tracking 8-stream 是最大重建范围问题, 其余 Riverpod 用法典范级; 3) 生命周期零新泄漏; 4) DB schema 22 + 迁移链 1→22 完整, 剩 saveSetup/clearAllUserData 编排债; 5) R32 闭环项全部实锤落地。