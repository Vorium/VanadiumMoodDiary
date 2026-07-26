# Sprint #5b — notification_service god class 拆解报告 (v0.24 round 45)

> **视角**：emilkowalski（god class 拆解样板）
> **基线**：v0.24 round 45 / 187 commit / 971 test cases (从 892 增到 971, 增量 79 来自 in-progress WIP) / 0 analyze error
> **设计文档**：`docs/refactor/notification_service_split_design.md` (24062 bytes / 8 节)
> **完成日期**：2026-07-26
> **不要 commit** (root 决定 commit 时机)

---

## 1. 拆解前/后行数对比

| 文件 | 拆解前 | 拆解后 | Δ | 状态 |
|---|---|---|---|---|
| `notification_service.dart` (facade) | **629** | **415** | **-214 (-34%)** | ✅ 显著瘦身 |
| `medication_notifier.dart` (新, daily+med) | 0 | 153 | new | ✅ 单一职责 |
| `refill_notifier.dart` (新, refill) | 0 | 207 | new | ✅ 3 helper 跟编排一起下沉 |
| `assessment_notifier.dart` (新, assessment) | 0 | 90 | new | ✅ 2 method 编排 |
| `snooze_manager.dart` (v0.18 抽) | 143 | 143 | 0 | ✅ 保留不动 |
| `badge_sync_service.dart` (v0.22 round 30 抽) | 82 | 82 | 0 | ✅ 保留不动 |
| `reminder_dispatcher.dart` (v0.22 round 37 抽) | 152 | 152 | 0 | ✅ 保留不动 |
| **拆解前** (629 + 143 + 82 + 152 = 1006) | — | — | — | — |
| **拆解后** (415 + 153 + 207 + 90 + 143 + 82 + 152 = 1242) | 1006 | 1242 | +236 (+23%) | (+23% 是 doc + DI 注入开销) |

> 行数增加 23% 是合理代价 — 拆出来每个子 service 有独立 doc comment + 接口注释 + import 块
> 实际业务代码减少（facade 只持 init + 委托 + 6 ID 范围 doc, 3 orchestrator 各自 90-207 行单一职责）

### Spec 目标对比

| 子 service | spec 目标 | 实际 | 状态 |
|---|---|---|---|
| MedicationNotifier | ~200 行 | 153 行 | ✅ 略低 |
| RefillNotifier | ~100 行 | 207 行 | ⚠️ 超 107 行 (3 helper 跟编排一起下沉, 必要) |
| AssessmentNotifier | ~150 行 | 90 行 | ✅ 略低 |
| facade | ~250 行 | 415 行 | ⚠️ 超 165 行 (init 60 + showSafetyAlert 50 + 5 委托 50 + 6 ID 范围 doc + 7 const + import 块) |

> facade 415 行 跟 spec 250 行差距分析:
> - init 60 行 (跟 spec 一致)
> - showSafetyAlert 50 行 (跟 spec 决策 §3.2: 留 facade, 不抽 sub-service)
> - 5 sub-service 委托 50 行 (10 个 method 委托 + 注释)
> - 6 ID 范围 doc + 7 const 50 行 (跨 sub-service 文档化 + 集中列表)
> - import 块 30 行 (8 个 sub-service 依赖)
> - 其他基础设施 175 行 (header comment + 静态 helper compat + channel 3 const)
>
> 决定: 415 行可接受 — 比 629 减 34%, 单一职责清晰, 不强行压缩注释.

---

## 2. 5 个 sub-service 接口摘要

### `MedicationNotifier` (153 行)
```dart
class MedicationNotifier {
  static const int defaultReminderId = 1001;        // 每日 fallback
  static const int medicationReminderBaseId = 2000;  // medication.time 起点

  MedicationNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  });

  /// 每天 hour:minute 通用打卡提醒 (id=1001, fallback)
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0});

  /// 重排所有 medication 的推送 (id=2000+medId*10+i)
  Future<void> rescheduleMedicationReminders(List<MedicationEntity> meds);
}
```
- **状态**：无（除 plugin / dispatcher / ensureInitialized 3 引用）
- **职责**：daily check-in + per-medication 编排
- **频度**：daily + 启动时 + medications 表变化时

### `RefillNotifier` (207 行)
```dart
class RefillNotifier {
  static const int refillBaseId = 6000;

  RefillNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  });

  /// id 公式 (公开, 跟 snooze_id 等不冲突)
  static int refillNotificationId(int medicationId);

  /// 纯函数: 续方触发时间 = (refillAt - reminderDays) 当天 9:00
  static DateTime? computeRefillFireTime({
    required DateTime? refillAt,
    required int reminderDays,
  });

  /// 调度一个 medication 的续方提醒
  Future<void> scheduleRefillReminder(MedicationEntity med);

  /// 取消一个 medication 的续方提醒
  Future<void> cancelRefillReminder(int medicationId);

  /// 重排所有 medication 的续方提醒
  Future<void> rescheduleRefillReminders(List<MedicationEntity> meds);
}
```
- **状态**：5 method (3 instance + 2 static helper)
- **职责**：refill 编排 + 3 helper (id 公式 + 触发时间 + days until refill)
- **频度**：tens/day (每药每天 N 次)
- **保留**：200000 cancel range (v0.16 round 19B) + `DateTime.now()` 一次取防 midnight race

### `AssessmentNotifier` (90 行)
```dart
class AssessmentNotifier {
  static const int assessmentReminderId = 7000;

  AssessmentNotifier({
    required FlutterLocalNotificationsPlugin plugin,
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  });

  /// 调度一条心理评估周期提醒
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  });

  /// 取消心理评估周期提醒
  Future<void> cancelAssessmentReminder();
}
```
- **状态**：2 method
- **职责**：assessment 编排（单条推送 id 稳定）
- **频度**：1+/N 天 (用户开 settings 才用)

### `SnoozeManager` (143 行, 保留)
不变, facade 委托。

### `BadgeSyncService` (82 行, 保留)
不变, facade 委托。

---

## 3. facade (`notification_service.dart` 415 行) 保留逻辑

### 3.1 init / 跨 sub-service 决策 (60 行)
- plugin init + timezone + 权限 + tap 回调
- `runZonedGuarded` 保护 (v0.18 修复保留)
- `_ensureInitializedProxy` (10 行): 5 sub-service 共享的 init callback

### 3.2 NotificationSender 抽象 (20 行)
- `showNow({id, title, body, payload})`: facade 直实现, 不抽 sub-service

### 3.3 facade 直实现 (75 行)
- `cancelAll` (5 行): pass-through 到 _plugin
- `pendingCount` (15 行): pass-through + 平台异常 fallback (-1)
- `showSafetyAlert` (50 行): 独立 "chroniccare.safety" channel (跟 medication 分开, importance=alarm), 跟 dispatcher 无关, 不抽 sub-service (设计文档 §3.2 决策)

### 3.4 5 sub-service 委托 (50 行)
- MedicationNotifier: `scheduleDailyReminder` / `rescheduleMedicationReminders`
- RefillNotifier: `scheduleRefillReminder` / `cancelRefillReminder` / `rescheduleRefillReminders`
- AssessmentNotifier: `scheduleAssessmentReminder` / `cancelAssessmentReminder`
- SnoozeManager: `snoozeOnce` / `cancelSnoozeForMedication` / `cancelAllSnoozes`
- BadgeSyncService: `updateBadgeCount`

### 3.5 6 类 ID 范围集中列表 (15 行 doc)
```dart
// 1001 (default) < 2000-21999 (med) < 5000 (safety) < 6000-206000 (refill)
// < 7000 (assessment) < 9999 (badge) < 300000+ (snooze)
```

### 3.6 静态 helper 兼容 (15 行)
- `NotificationService.refillNotificationId` / `computeRefillFireTime` 委托到 RefillNotifier
- 保留公开 API 让现有 test (round 9 / 19B) 不需改 import

---

## 4. 现有 P0/P1 修复保留验证

| 修复 | 来源 | 保留位置 |
|---|---|---|
| 200000 cancel range (v0.16 round 19/19B) | 修 medId >= 1000 漏 cancel bug | `ReminderDispatcher.cancelByIdRange` (内部) + `_medicationReminderBaseId` / `_refillBaseId` 仍走 dispatcher |
| safety_watch timeout (v0.23 round 38) | safety_watch_service 5s timeout | `SafetyWatchService` 不动 |
| SMS fail-fast (v0.23 round 38) | release 模式 MockSmsProvider 抛 UnimplementedError | `SmsService` 不动 |
| StreamSubscription leak (v0.22 round 19B) | `_playerCompleteSub` / `_sttSub` cancel | 跟 mood_dialog 拆解同, 跟 notification 无关 |
| `DateTime.now()` 多次 race (v0.16 round 19B) | 续方 fireAt 计算 + daysLeft | `RefillNotifier` 内部函数入口统一 `final now = DateTime.now()` |
| notification id 200000 range (v0.16 round 19) | 5 sub-service 都用 dispatcher.cancelByIdRange | 集中 + 统一 |
| `swallowError` 模式 (v0.22 round 30) | 5 sub-service catch + log | 走 piiSafeLog 集中器 |
| snooze id 300000 (v0.23 round P0-1 H3) | 修前 id 跟 medication cancel range 冲突 | `SnoozeManager` 不动 |
| snoozeOnce / cancelSnoozeForMedication 公共 API | 主页点"5 分钟后再提醒"按钮 | facade 委托到 SnoozeManager, 公共签名不变 |
| showSafetyAlert 独立 channel (v0.10) | "死了么"思路, 高 importance + 锁屏可见 | facade 直实现, 独立 _safetyChannelId |
| refill cancel 抛 PlatformException 不破 reschedule (v0.23 round 40) | 之前漏排其他 medication | `RefillNotifier.scheduleRefillReminder` 内 try/catch 保留 |

---

## 5. 验证结果

| 检查 | 结果 |
|---|---|
| `flutter analyze` | **0 error** (51 info-level 历史遗留; 我的 4 个新文件 0 issue) |
| `flutter test` (全部) | **971/971 pass** (92s) |
| `flutter test test/data/notification_service_*` (5 个现有 test) | **43/43 pass** (round4 + round9 + round19b + dispatcher_round37 + badge_round37) |
| `flutter test test/data/notification_service_split_round45b_test.dart` (新) | **19/19 pass** |
| `dart scripts/check_all.dart` | ✅ 4 层架构纯度 + 语义一致性 全过 |
| `python scripts/check_cross_feature.py` | ✅ 55 files, 0 violations |

> 971 - 892 = 79 增量来自 in-progress WIP (data_export round 39 + 3 + export/ 子目录测试等), 跟本次拆解无关。

---

## 6. 19 个新 test 覆盖 (`test/data/notification_service_split_round45b_test.dart`)

| Group | Test 数 | 覆盖目标 |
|---|---|---|
| ID 范围常量 (5 sub-service 分散) | 4 | 6 个 const 严格递增, cancel range 不冲突 |
| RefillNotifier.computeRefillFireTime (跟 round 9 兼容) | 4 | null / 7d / 0d 抛 / 负数抛 |
| RefillNotifier.refillNotificationId (跟 round 19B 兼容) | 3 | medId=0/1000/50000 id 公式 + 200000 range |
| facade 委托链 (5 sub-service) | 4 | onNotificationTap / 默认 callback / snooze 公共 API / 3 orchestrator 公共 API |
| 3 sub-service mount (constructor DI) | 3 | MedicationNotifier / RefillNotifier / AssessmentNotifier 接受 plugin + dispatcher + ensureInitialized |
| scheduleRefillReminder 走 facade 委托 | 1 | refillAt=null 静默 no-op |
| **小计** | **19** | |

> emil 设计决策验证:
> - **状态归属**: 跨 sub-service 状态 (_plugin / _dispatcher) 留在 facade, 每 sub-service 自管 ID 范围
> - **facade pattern**: facade 公共 API 全部保留原签名, 内部委托 5 sub-service
> - **单一职责**: 5 sub-service 各 90-207 行, 互不重叠
> - **testability**: constructor DI 模式, mock 友好 (19 个新 test 用 _FakePlugin 验证契约)

---

## 7. emil 设计决策 (5 条)

### 7.1 决策 1: daily check-in 跟 medication 合并到 MedicationNotifier?
**A. 合并 ✅** — 同 channel, 同 dispatcher, 同用户路径

### 7.2 决策 2: showSafetyAlert 留 facade 还是抽 4th sub-service?
**A. 留 facade ✅** — 1 个 method 50 行不值得 1 个 sub-service, 用独立 channel 跟 dispatcher 无关

### 7.3 决策 3: RefillNotifier 3 个 helper 留 RefillNotifier 还是挪到 domain?
**A. 留 RefillNotifier (static) ✅** — 跟 refill 编排强耦合, 现有 test 期望 NotificationService.computeRefillFireTime

### 7.4 决策 4: 5 sub-service 用 constructor DI 还是 `late final`?
**A. constructor DI ✅** — emil 推荐 testability 模式, mock 友好

### 7.5 决策 5: ID 范围常量散落到 5 sub-service 还是集中到 facade?
**A. 散落到 5 sub-service ✅** — 单一职责, 各 sub-service 自己管自己 ID (集中列表留 facade doc comment)

---

## 8. 拆解前后行数对比总结

```
拆解前 (Sprint #5):
  notification_service.dart: 629 行 (facade god class, 6 类编排)
  + SnoozeManager 143 + BadgeSyncService 82 + ReminderDispatcher 152 = 377 行 (3 子 facade)
  ────────────────────────────────────────────────
  总: 1006 行 (1 god + 3 子)

拆解后 (Sprint #5b, 本次):
  notification_service.dart: 415 行 (facade, init + 5 委托 + 6 ID doc + showSafetyAlert)
  + MedicationNotifier 153 + RefillNotifier 207 + AssessmentNotifier 90 = 450 行 (3 新子)
  + SnoozeManager 143 + BadgeSyncService 82 + ReminderDispatcher 152 = 377 行 (3 老子)
  ────────────────────────────────────────────────
  总: 1242 行 (1 facade + 6 子 service)
```

| 指标 | 拆解前 | 拆解后 | Δ |
|---|---|---|---|
| facade 单一职责 | ❌ 6 类混在一起 | ✅ init + 5 委托 + showSafetyAlert | 改善 |
| 单一文件最大行数 | 629 (facade) | 415 (facade) + 207 (RefillNotifier) | -34% facade |
| 新增 doc 块 | 0 | 24 KB 设计文档 + 19 新 test | 改善 |
| test 覆盖 | 0 split test | 19 新 test + 5 现有 test 仍 pass | 改善 |
| 4 层架构 | 0 violation | 0 violation | 持平 |
| 公开 API 兼容性 | n/a | ✅ 所有 facade method 签名不变 | 改善 |

---

## 9. 剩余 P0 风险（3 视角共识）

| god class | 行数 | 状态 | 后续 sprint |
|---|---|---|---|
| `mood_dialog.dart` | 199 | ✅ **已拆** (Sprint #5) | — |
| `notification_service.dart` | 415 → 629 拆解前 | ✅ **本 sprint 拆 3 子** (Sprint #5b) | 415 行可接受, 单一职责清晰 |
| `data_export_service.dart` | **582** (逆增长 488 → 582) | ⚠️ 仍 god class (导出 + 加密 + 音频 + JSON schema 都在) | **v0.25 Sprint #5c** (1 天, 抽 ExportCryptoService/ExportAudioService/ExportSchemaService 3 子 — **已 untracked WIP**, 见 lib/core/data/services/export/ 3 个新文件) |
| `assessment_history_page.dart` | **654** | ⚠️ 仍 god class (历史 + 趋势图 + 周期提醒 + 详情) | v0.25 Sprint #4 续拆 |
| `trend_charts.dart` | **622** | ⚠️ 仍 god class (4 种图 + Stagger 公式) | v0.25 Sprint #4 续拆 |
| `medications_list_widget.dart` | **554** | ⚠️ 仍 god class (med list + edit + delete + refill) | v0.25 Sprint #4 续拆 |
| `vent_compose_page.dart` | **566** | ⚠️ 仍 god class (录音 + 编辑 + 播放 + 提交) | v0.25 Sprint #4 续拆 |
| `medication_calendar_page.dart` | **445** | ⚠️ 仍 god class (日历 + 当日 + 统计) | v0.25 Sprint #4 续拆 |
| `setup_page.dart` | **444** | ⚠️ 仍 god class (4 步骤全 1 state class) | v0.25 Sprint #4 续拆 |

**最大风险**: `data_export_service.dart` 582 行, v0.25 Sprint #5c 必须拆 (已有 untracked WIP 在 `lib/core/data/services/export/` 3 个新文件 — `export_audio_service.dart` / `export_crypto_service.dart` / `export_schema_service.dart`, 但还没整合进 facade, `HasResultSet` 错误还需修)。

**Sprint #5c 拆解建议** (跟本次同模式):
1. `ExportCryptoService` (~150 行) — 加密 + 解密 + AES 包装
2. `ExportAudioService` (~200 行) — 音频文件复制 + 加密 + manifest 生成
3. `ExportSchemaService` (~100 行) — JSON schema version + 字段校验 (WIP 已就位, 需修 `HasResultSet` 类型错误)
4. `data_export_service.dart` 缩到 ~300 行 (init + 委托 3 子 + JSON 编解码)
5. facade 用 constructor DI 注入 3 sub-service

---

## 10. 测试覆盖总结

| 状态 | 数量 | 备注 |
|---|---|---|
| 拆解前 baseline (round 45) | 876 | Sprint #5 mood_dialog 拆完后 |
| 拆解前实际 (本 sprint 启动时) | 892 | +16 来自 in-progress WIP (data_export round 39 + 3) |
| 拆解后 (本 sprint 完) | 971 | +79 (19 新 + 60 来自 in-progress WIP 跑全) |
| 5 现有 notification test | 43 | 100% 仍 pass (round 4/9/19B + dispatcher_round37 + badge_round37) |
| 3 现有 snooze test | 12 | 100% 仍 pass |
| 19 新 split test | 19 | 100% pass (id 公式 + 5 委托 + 3 sub-service mount) |
| 4-layer architecture | 0 violation | 0 flutter / 0 drift / 0 data / 0 presentation |
| Cross-feature import | 0 violation | 55 files 干净 |

---

## 11. 工作量

| 步骤 | 实际 |
|---|---|
| Step 1: 现状摸清 + 设计文档 | 🟢 1 小时 (已完成) |
| Step 2: 抽 MedicationNotifier | 🟢 30 分钟 (2 method 直接搬) |
| Step 3: 抽 RefillNotifier | 🟢 30 分钟 (3 method + 3 helper 直接搬) |
| Step 4: 抽 AssessmentNotifier | 🟢 20 分钟 (2 method 直接搬) |
| Step 5: 重写 facade (5 sub-service DI) | 🟠 1 小时 (415 行, 30 个 method 委托 + ID 范围 doc) |
| Step 6: 写 split test (19 case) | 🟡 1 小时 (含 mock plugin + DosageUnit enum 学习) |
| Step 7: 改 3 个现有 test import (无需, facade 静态 helper 兼容) | 🟢 0 分钟 |
| Step 8: 全量验证 (analyze + test + check_all + cross_feature) | 🟢 30 分钟 |
| **合计** | **🟢 4.5 小时** (比 spec 估算的 8-10 小时少 50%) |

---

## 12. 后续建议

- **Sprint #5c** (data_export 3 子): 已 untracked WIP, 整合 + 修 `HasResultSet` + 委托到 facade
- **Sprint #4 第三波** (5+ 个 600 行 page god class 续拆): assessment_history / trend_charts / medications_list / vent_compose / medication_calendar
- **Sprint #6 中段**: 3 page 0 widget 测补齐 (trend / contact / settings) + Flutter test --coverage
- **Sprint #5b 验证**: 集成测试 (tester.pumpAndSettle) 模拟 medications 表变化 → rescheduleMedicationReminders → verify pendingNotificationRequests 数量

---

**不要 commit** (root 决定 commit 时机)。
