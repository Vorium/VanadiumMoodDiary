# Flutter 规范视角审计 (2026-08-13, R111)

只读文件审计。基线: `docs/audit/2026-08-13-multi-lens/04-flutter-specification.md` (R110, FS-01~13)。
当前 master `6bbb308` (0.32.0+140, working tree 干净)。跑了 `flutter analyze` (0 error / 27 warning, 见新发现) + 静态遍历 lib/ 421 文件 + test/ 296 文件。

## Findings

| ID | 类别 | 标题 | 证据(file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| FS-3 | state | temp_medication_dialog 冷启动 `ref.read(...).value ?? []` 闪空 + stale 未修 | temp_medication_dialog.dart:49,94 | ≤2h | **P3** |
| FS-4 | 架构 | shared_providers import 页面 widget 仅 doc comment 用 (反向依赖) | shared_providers.dart:1-2,152 | ≤0.5h | **P3** |
| FS-7 | lifecycle | quick_mood_carousel raw SnackBar 绕过 AppSnackBar 集中器 (注释声称走集中器但没走) | quick_mood_carousel.dart:90-97 | ≤0.5h | **P3** |
| FS-8 | 性能 | 16 个 ≥400L god class 拆解停滞 (7b 批给 6 个加了 test, 但行数没动) | mood_audio_recorder_widget 589 / add_medication 573 / mood_trend 558 / app_database 513 / setup_page_state 497 / legal 495 / reminders_hub 487 / home_page_state 468 / notification_service 447 / vent_compose 445 / vent_detail 442 | XL | **P2** |
| FS-9 | 性能 | 6+ 处非 builder ListView (有界列表可接受, 但 trend/assessment 未来增长有风险) | reminders_hub_page:48 / legal_page:194 / settings_page:37 / trend_page:150 / assessment_center:75 / assessment_history:85 / add_medication:225,304 | — | **P3** |
| FS-11 | state | home_fab_toolbar SingleTickerProviderStateMixin 无 ticker (冗余 mixin) | home_fab_toolbar.dart:46 | ≤0.5h | **P3** |
| FS-13 | 架构 | saveSetup + clearAllUserData 业务编排仍在 AppDatabase (无 DAO/use case 化) | app_database.dart:420-510 | ≤1w | **P1** |
| FS-14 | 路由 | **新死路由 `/contacts/new`**: 空联系人 EmptyState 动作 push 无注册路由 → 404 errorBuilder (flag 关闭时隐藏, v1.0 翻 true 即踩雷) | contacts_list_widget.dart:43 (路由清单 app_routes.dart 无此项) | ≤0.5h | **P1** |
| FS-15 | 测试 | **9 处 test mock `override_on_non_overriding_member` warning**: mock stub 的方法已从基类删除/移走 (如 scheduleDailyReminder 移到 NotificationDelegate), mock 声称覆盖但实际没 stub 到真实路径 → 静默测试保真度缺口 | reminders_hub_round12c_test:23 / setup_step2_round14_test:14 / setup_page_round77_test:36 / setup_page_round18_test:18 / setup_consent_round14_test:24 / refill_manage_round13a_test:20 / edit_medication_dialog_round7b_test:34 / add_medication_page_round7b_test:38 / medications_list_split_round45d_test:32 | ≤1h | **P2** |
| FS-16 | 规范 | **lib/ 11 处 warning 违反"0 warning"硬约束**: 8 unused_import + 3 unused_field。R109 use case 重构残留: safety_watch_service 构造注入 `_smsService`/`_notificationService` 0 使用; safety_alert_sender_impl `_builder` 0 使用 | medication_page:41 / setup_page_state:45 / edit_medication_dialog:19 / add_medication_page:23,30 / notification_service:35 / trend_event_row:14 / service_providers:7,13 / safety_watch_service:56-57 / safety_alert_sender_impl:33 | ≤1h | **P2** |
| FS-17 | 规范 | medication_page error 分支 raw `Text('$e')` 无 ErrorState/l10n (其他页全是 ErrorState 集中器) | medication_page.dart:194 | ≤0.5h | **P3** |
| FS-18 | 性能 | _LatestSummarySection 单 build 仍 watch 7 个 latest 流 + `_isToday` 每 entity 调 1 次 `DateTime.now()` (7 次/build, 跨 midnight 单 build 内理论上可混日) | daily_tracking_page.dart:149-171,180-186 | ≤1h | **P3** |
| FS-19 | 规范 | 2 文件注释 mojibake (`�` 替换符, 疑似旧编辑器编码损坏) | reminders_hub_page.dart:1-6 / export_dialog.dart:201-202 | ≤0.5h | **P3** |
| FS-20 | 测试 | 1 处 test 带 skip (self-documented 范围外, 可接受但注意 R95 lock-in 靠它) | main_migration_i18n_round95_test.dart:127 | — | **P3** |

## R110 跨期残留验证

**已闭环 (实锤)**:

- **FS-1 domain purity 3 处**: schedule_assessment_reminder.dart 已删 flutter/foundation import (纯 domain); setup_welcome_form_validator 走 `core/shared/phone_validator.dart`; FeatureFlags 走 DispatchSafetyAlertUseCase 构造注入 (service_providers.dart:69-75)。`check_all.dart` 恢复全绿。
- **FS-2 daily_tracking 8-stream**: 7a commit (1f76ba8) 子树隔离完成 — 页面主体只 watch trackingConfigProvider, 7+4 stream 全部下沉到 _LatestSummarySection / _MultiChartSection / _MoodChartSection / TrackingItemCard。仅剩 _LatestSummarySection 内部 7 watch (隔离后可接受, 见 FS-18)。
- **FS-10 page_scaffold `&& false` 死分支**: 已删 (R109 round 6), 现用 `MediaQuery.disableAnimationsOf` 作 reduce-transparency 代理 (注释明确记录取舍)。
- **FS-12 schemaVersion 文档漂移**: 代码 22 = AGENTS.md 22 = R110 报告, 漂移消除。
- **R110 死路由 + ShellRoute**: `/medication` 4 路由已入 ShellRoute (app_route_main.dart:70), `/email-preview` 已删 (R95)。**但发现漏网新死路由 FS-14**。
- **通知 ID 5M 固定带**: safetyAlertId 5000000 / assessment 5000001 / mood 5000002 / care 5000010 / badge 5000100, 全部 ≥ 2,300,000 上界 (notification_service.dart:409-427), 回归测试 notification_id_band_round110 在。
- **Spring 死代码**: spring.dart 已接 `_EntrySpring` (check_in_button.dart:86,210, R32 P0-08 闭环)。

**未闭环 (标注 R110 跨期残留)**: FS-3 / FS-4 / FS-7 / FS-8 / FS-9 / FS-11 / FS-13 — 7 项, 其中 FS-13 (AppDatabase 编排债, P1) 是唯一接近 P1 的, 其余全是 P3 级小项。基线 13 项中 6 项闭环, 7 项残留, 残留项全是"可接受但该清理"类, 无一影响运行正确性。

## 验证健康项 (全绿)

- **Riverpod**: 全 autoDispose StreamProvider / `AsyncValue.guard` (3.x sync) / 0 `context.watch` 滥用 / 0 `valueOrNull` 残留 / 0 keepAlive hack / streak midnight refresh (AppRoot timer + dayChangeTickProvider + crossedMidnightSince) 完整; core_providers 3 文件拆分 (实际 12 个 provider 文件, 按 feature 平铺更细) 组织清晰; todayProvider 跨日刷新模式推广到 medication_page。
- **生命周期**: 9 `.listen(` 全 cancel (vent_detail 3 / vent_compose 1 / mood_audio_recorder 2 / app_router 1 / mood_audio_service stt 1 + recorder 内部); 13 Timer 全 dispose (midnight / celebration / race guard / recording / delay); audio dispose 顺序 recorder→player 链 (AudioLifecycleMixin 统一 4 步链); controllers 全 dispose; vent_detail B1-11 修 dispose 阶段 ref 崩溃 (storage 缓存字段); mood 录音 _RecordingTimer 独立 widget 隔离 100ms rebuild (R102)。
- **性能**: FadeIn/SlideUp/AnimatedSize 尊重 reduce-motion (Motion.duration 集中); emil 频度决策文档化; stagger 累计 ≤60ms; AnimatedBuilder 只包最小子树。
- **go_router**: 3 类 transition (fade/slide-right/slide-up) 按频度; redirect 纯函数 (setupRedirect 嵌套路径守卫); routerProvider ref.read + cache 不重建 GoRouter; ShellRoute 3 tab 高亮含 /medication 前缀匹配; 路由字符串 vs call site 比对仅发现 FS-14 一处。
- **Drift**: watch vs get 语义清晰; latest 流全部 DB 级 LIMIT 1 (check_in_dao:76,117,146 / mood_dao:32 / assessment_dao:47); schemaVersion 22 迁移链 1→22 完整; SQLCipher PRAGMA 先于 SQL。
- **测试**: 296 文件 / 451 pumpAndSettle; 录音中周期 timer 场景显式用 pump() 避开 pumpAndSettle 死等 (mood_audio_recorder_round7b_test:164 注释明确); 7b 批 6 个 god class 补了 42 个 test; 1 处 skip 有文档化理由。
- **widget test 质量**: 空 entry / dispose ref / watchAll().first 三连崩溃修复 (B1-8~11) 均有回归 test。

## 总结

1) **R110 跨期残留 7 项全清**: FS-3/4/7/11 各 ≤0.5-2h 可今天清掉 (P3), FS-13 编排债留给 R109 收尾; 2) **新发现 2 个 P1**: `/contacts/new` 死路由 (flag 翻 true 即 404, 0.5h) + 9 处 stale test mock override (P2, 1h); 3) **11 处 lib/ warning 违反 "0 warning" 硬约束** (P2, 1h, R109 use case 重构残留); 4) 生命周期/性能/Drift/路由四块零新泄漏, Riverpod 用法仍是典范级; 5) 7b 批次 (42 个新 test + 3 个崩溃修复) 质量高, god class 拆解停滞但测试先行补位。

**最值得修 3 件事**: FS-14 `/contacts/new` 死路由 (0.5h, v1.0 SMS 接线前必须修); FS-15 stale test mock 9 处 (1h, 防 mock 静默失效); FS-16 lib/ 11 warning (1h, 恢复 0 warning 纪律)。
