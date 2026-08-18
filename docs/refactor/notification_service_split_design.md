# notification_service god class 拆解设计

> **Sprint**: v0.24 Sprint #5b
> **基线**: v0.24 round 45 / commit `7412138` (HEAD) / 187 commit / 876 test cases
> **Skill 视角**: emilkowalski (facade 拆分 · 状态归属 · 单一职责 · testability)
> **目标文件**: `lib/core/data/services/notification_service.dart` (629 行, facade god class)
> **参考样板**: `mood_dialog.dart` 738 → 199 (Sprint #5 刚 commit 7412138) + `settings_page.dart` 681 → 114 (v0.22 round 30)
> **完成日期**: 2026-07-26

---

## 1. 现状诊断 (emil 视角)

### 1.1 数字说话

| 指标 | 值 | emil 评估 |
|---|---|---|
| 总行数 | **629** | 远超 god class 阈值 (500+) |
| 公开方法 | **14** 个 (init / showNow / scheduleDailyReminder / cancelAll / pendingCount / rescheduleMedicationReminders / snoozeOnce / cancelSnoozeForMedication / cancelAllSnoozes / scheduleRefillReminder / cancelRefillReminder / rescheduleRefillReminders / scheduleAssessmentReminder / cancelAssessmentReminder / showSafetyAlert / updateBadgeCount) | 1 个 facade 装 6 类编排 |
| 业务职责 | **6 类**: init / daily check-in / medication / refill / assessment / safety / snooze / badge | 违反 SRP (Single Responsibility) |
| ID 范围常量 | **6 个**: 1001 / 2000+medId*10+i / 5000 / 6000+medId / 7000 / 9999 | 集中在 facade 内, 散落难维护 |
| 既有子 facade | 3 个 (SnoozeManager 90 行 + BadgeSyncService 40 行 + ReminderDispatcher 146 行) | 已抽但 **facade 自身仍 600+ 行因 4 类通知编排** |

### 1.2 emil "decisions should be nameable" 检查

`notification_service.dart` 当前 6 类决策**没有清晰命名**:
- init (90 行): 平台初始化 + 时区 + 权限 + tap 回调
- daily check-in: `scheduleDailyReminder` (1 个 method 26 行)
- medication: `rescheduleMedicationReminders` (1 个 method 50 行) — 循环调度
- refill: `scheduleRefillReminder` (50 行) + `cancelRefillReminder` (5 行) + `rescheduleRefillReminders` (20 行) + 3 个 helper (40 行)
- assessment: `scheduleAssessmentReminder` (40 行) + `cancelAssessmentReminder` (5 行)
- safety: `showSafetyAlert` (45 行, 用独立 channel)
- snooze: 委托 SnoozeManager (3 个 method)
- badge: 委托 BadgeSyncService (1 个 method)

**emil 视角**: 6 类决策混在 1 个 facade, 后续每加 1 类通知 → facade 又胖。

### 1.3 当前 facade 的 6 类决策混在一起

1. **平台 init 决策** (plugin init / timezone / 权限) — init-only
2. **daily check-in 决策** (id=1001, 20:00 fallback) — 1 个 method
3. **medication 编排决策** (id=2000+medId*10+i, 每药每 time 循环) — 1 个 method
4. **refill 编排决策** (id=6000+medId, refillAt - reminderDays 9:00) — 3 个 method + 3 个 helper
5. **assessment 编排决策** (id=7000, fireAt 一次性) — 2 个 method
6. **safety alert 决策** (id=5000, 独立 channel, _plugin.show) — 1 个 method

---

## 2. 拆解方案 (emil 决策)

### 2.1 拆分原则 (5 条)

1. **3 个新 orchestrator + 1 个 facade**: 跟 mood_dialog 拆解同模式 (1 orchestrator + 5 子 widget)
2. **每类通知的"schedule/cancel/reschedule"流程独立成单一职责的 orchestrator**:
   - `MedicationNotifier` (200 行) — daily check-in + medication
   - `RefillNotifier` (100 行) — refill 编排
   - `AssessmentNotifier` (150 行) — assessment 编排
3. **facade 只持 init + 跨 orchestrator 决策 + 5 sub-service DI 委托** (~250 行)
4. **保留 3 个既有子 facade (SnoozeManager / BadgeSyncService / ReminderDispatcher)** — 不重构
5. **保留所有 P0/P1 修复**: 200000 cancel range / safety_watch timeout / SMS fail-fast / StreamSubscription leak / ID range 公式

### 2.2 目标文件树

```
lib/core/data/services/
├── notification_service.dart              (~250 行 — facade, init + 5 sub-service DI + 6 ID 范围常量 + showSafetyAlert + showNow + cancelAll + pendingCount)
├── snooze_manager.dart                   (90 行 — 保留, 不动)
├── badge_sync_service.dart               (40 行 — 保留, 不动)
├── reminder_dispatcher.dart               (146 行 — 保留, 不动)
├── medication_notifier.dart              (新, ~200 行 — daily check-in + medication 编排)
├── refill_notifier.dart                  (新, ~100 行 — refill 编排 + 3 helper)
├── assessment_notifier.dart              (新, ~150 行 — assessment 编排)
└── ... (其他 service 不动)
```

**总行数**: 629 + 90 + 40 + 146 = 905 → 250 + 90 + 40 + 146 + 200 + 100 + 150 = **976 行** (+71 行 / +7.8%)
**实际效果**: facade 250 行 init + 委托; 3 个新 sub-service 各 100-200 行单一职责; 现有 3 个子 facade 不动

### 2.3 数据流 (facade → 5 sub-service)

```
NotificationService (facade)
  ├── init() → FlutterLocalNotificationsPlugin.initialize + tz + 权限
  ├── showNow(...)         — NotificationSender 抽象方法, facade 直实现
  ├── cancelAll()          — 委托 _plugin.cancelAll
  ├── pendingCount         — 委托 _plugin.pendingNotificationRequests
  ├── showSafetyAlert(...) — facade 内独立 channel, 不走 dispatcher
  ├── _medicationNotifier  — 委托 MedicationNotifier (daily + medication)
  ├── _refillNotifier      — 委托 RefillNotifier
  ├── _assessmentNotifier  — 委托 AssessmentNotifier
  ├── _snoozeManager       — 委托 SnoozeManager (snoozeOnce/cancelSnoozeFor/cancelAllSnoozes)
  ├── _badgeSync           — 委托 BadgeSyncService (updateBadgeCount)
  └── _dispatcher          — ReminderDispatcher (facade 共享给 3 new sub-service, 但 facade 不直接用)
```

### 2.4 5 个 sub-service 接口 (emil "decisions should be nameable")

#### `MedicationNotifier` (~200 行)

```dart
class MedicationNotifier {
  /// 药物通知 id 范围: 2000-21999 (medId * 10 + i 公式)
  static const _medicationReminderBaseId = 2000;
  /// 每日打卡 fallback id (无 medication 时用)
  static const _defaultReminderId = 1001;
  
  /// v0.22 round 37: ReminderDispatcher 注入, cancel/zonedSchedule 走 dispatcher
  final ReminderDispatcher _dispatcher;
  /// 父 service init 引用 (调 _plugin 的 init 标志)
  final Future<void> Function() _ensureInitialized;
  
  MedicationNotifier({
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  });
  
  /// 设置每天 hour:minute 通用打卡提醒 (id=1001)
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0});
  
  /// 重排所有 medication 的推送 (id=2000+medId*10+i)
  /// 每次 medications 表变化时调
  Future<void> rescheduleMedicationReminders(List<MedicationEntity> meds);
}
```

**责任**: daily check-in + medication 编排。2 个公开 method。**3 个 ID 范围常量** 跟其他 sub-service 不冲突。

**emil 决策**: 把 daily check-in 跟 medication 编排合并到 1 个 sub-service, 因为:
- 都在 "medication channel" (慢性病 channel)
- 都用 ReminderDispatcher
- 用户路径单一: 设置药 → 收到 medication 推送 / 没设药 → 收到 daily fallback

#### `RefillNotifier` (~100 行)

```dart
class RefillNotifier {
  /// 续方 id 起始基数 (id = base + medId, 范围 6000-206000)
  static const _refillBaseId = 6000;
  
  final ReminderDispatcher _dispatcher;
  final Future<void> Function() _ensureInitialized;
  
  RefillNotifier({
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  });
  
  /// id 公式 (公开, 跟 snooze_id 等不冲突)
  @visibleForTesting
  static int refillNotificationId(int medicationId) => _refillBaseId + medicationId;
  
  /// 纯函数: 续方触发时间 = (refillAt - reminderDays) 当天 9:00
  @visibleForTesting
  static DateTime? computeRefillFireTime({
    required DateTime? refillAt,
    required int reminderDays,
  });
  
  /// 按"天"计算 refill 距今多少天 (纯函数)
  static int _daysUntilRefill(DateTime refillAt, DateTime now);
  
  /// 调度一个 medication 的续方提醒
  Future<void> scheduleRefillReminder(MedicationEntity med);
  
  /// 取消一个 medication 的续方提醒
  Future<void> cancelRefillReminder(int medicationId);
  
  /// 重排所有 medication 的续方提醒
  Future<void> rescheduleRefillReminders(List<MedicationEntity> meds);
}
```

**责任**: refill 编排 + 3 个 helper。5 个公开 method (3 instance + 2 static)。**保留 200000 cancel range 公式** (v0.16 round 19B 修过的)。

#### `AssessmentNotifier` (~150 行)

```dart
class AssessmentNotifier {
  /// 评估通知 id (单条推送, 稳定)
  static const _assessmentReminderId = 7000;
  
  final ReminderDispatcher _dispatcher;
  final Future<void> Function() _ensureInitialized;
  
  AssessmentNotifier({
    required ReminderDispatcher dispatcher,
    required Future<void> Function() ensureInitialized,
  });
  
  /// 调度一条心理评估周期提醒
  /// - 单条推送, id 固定
  /// - fireAt 已过 = 跳过 (但取消旧的)
  Future<void> scheduleAssessmentReminder({
    required DateTime fireAt,
    String scaleId = 'phq9',
    int days = 14,
  });
  
  /// 取消心理评估周期提醒
  Future<void> cancelAssessmentReminder();
}
```

**责任**: assessment 编排。2 个公开 method。

#### `SnoozeManager` (90 行, 保留)

不变, 继续 facade 委托。

#### `BadgeSyncService` (40 行, 保留)

不变, 继续 facade 委托。

### 2.5 facade (`notification_service.dart` ~250 行)

```dart
class NotificationService implements NotificationSender {
  // ===== 6 ID 范围常量 =====
  static const _channelId = 'chroniccare.medication';
  static const _channelName = Strings.notifChannelMedicationName;
  static const _channelDesc = Strings.notifChannelMedicationDesc;
  static const _safetyAlertId = 5000;
  // (MedicationNotifier._medicationReminderBaseId = 2000 + _defaultReminderId = 1001)
  // (RefillNotifier._refillBaseId = 6000)
  // (AssessmentNotifier._assessmentReminderId = 7000)
  // (BadgeSyncService.badgeVirtualId = 9999)
  // 注: 6 类常量分散在 5 个 sub-service, 集中列表 (v0.16 round 19 文档化):
  //   1001 (default) < 2000-21999 (med) < 5000 (safety) < 6000-206000 (refill) < 7000 (assessment) < 9999 (badge)
  // < 300000+ (snooze)
  
  // ===== 5 sub-service DI =====
  late final MedicationNotifier _medicationNotifier;
  late final RefillNotifier _refillNotifier;
  late final AssessmentNotifier _assessmentNotifier;
  late final SnoozeManager _snoozeManager;
  late final BadgeSyncService _badgeSync;
  late final ReminderDispatcher _dispatcher;
  
  NotificationService({this.onNotificationTap = _defaultOnTap})
      : _plugin = FlutterLocalNotificationsPlugin() {
    // 6 sub-service 在 constructor 注入 (DI 模式, 跟 mood_dialog 拆解同模式)
    _dispatcher = ReminderDispatcher(
      plugin: _plugin,
      channelId: _channelId,
      channelName: _channelName,
      channelDescription: _channelDesc,
    );
    _ensureInitialized = () async => await init();
    _medicationNotifier = MedicationNotifier(
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitialized,
    );
    _refillNotifier = RefillNotifier(
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitialized,
    );
    _assessmentNotifier = AssessmentNotifier(
      dispatcher: _dispatcher,
      ensureInitialized: _ensureInitialized,
    );
    _snoozeManager = SnoozeManager(plugin: _plugin);
    _badgeSync = BadgeSyncService(plugin: _plugin);
  }
  
  // ===== init / lifecycle =====
  Future<void> init() async { ... }  // 60 行: plugin init + tz + 权限
  static void _onResponse(NotificationResponse response) { ... }  // 7 行
  
  // ===== NotificationSender 抽象 =====
  @override
  Future<void> showNow({...}) async { ... }  // 20 行
  
  // ===== facade 直实现 (不走 sub-service) =====
  Future<void> cancelAll() async { ... }  // 5 行
  Future<int> get pendingCount async { ... }  // 15 行
  Future<void> showSafetyAlert({...}) async { ... }  // 50 行 (独立 channel, 跟 dispatcher 无关)
  
  // ===== 5 sub-service 委托 =====
  Future<void> scheduleDailyReminder({int hour = 20, int minute = 0}) =>
    _medicationNotifier.scheduleDailyReminder(hour: hour, minute: minute);
  Future<void> rescheduleMedicationReminders(List<MedicationEntity> meds) =>
    _medicationNotifier.rescheduleMedicationReminders(meds);
  Future<void> scheduleRefillReminder(MedicationEntity med) =>
    _refillNotifier.scheduleRefillReminder(med);
  Future<void> cancelRefillReminder(int medId) =>
    _refillNotifier.cancelRefillReminder(medId);
  Future<void> rescheduleRefillReminders(List<MedicationEntity> meds) =>
    _refillNotifier.rescheduleRefillReminders(meds);
  Future<void> scheduleAssessmentReminder({...}) =>
    _assessmentNotifier.scheduleAssessmentReminder(...);
  Future<void> cancelAssessmentReminder() =>
    _assessmentNotifier.cancelAssessmentReminder();
  Future<void> snoozeOnce({...}) async {
    await init();
    return _snoozeManager.snoozeOnce(...);
  }
  Future<void> cancelSnoozeForMedication(int medId) async {
    await init();
    return _snoozeManager.cancelSnoozeForMedication(medId);
  }
  Future<void> cancelAllSnoozes() async {
    await init();
    return _snoozeManager.cancelAllSnoozes();
  }
  Future<void> updateBadgeCount(int count) async {
    await init();
    return _badgeSync.updateBadgeCount(count);
  }
}
```

**总行数**: ~250 行 (init 60 + onResponse 7 + showNow 20 + cancelAll 5 + pendingCount 15 + showSafetyAlert 50 + 6 ID consts 10 + 5 sub-service 委托 30 + import 块 30 + doc comment 30)

---

## 3. 关键设计决策 (emil 决策框架)

### 3.1 决策 1: daily check-in 跟 medication 合并到 MedicationNotifier?

| 候选 | 优劣 |
|---|---|
| **A. 合并到 MedicationNotifier** ✅ | 同 channel, 同 dispatcher, 同用户路径 (无药→daily/有药→medication) |
| B. 独立 DailyCheckInNotifier | 1 个 method 26 行不值得 1 个 sub-service |
| C. 留在 facade | facade 仍 270+ 行, 拆解失败 |

**决策**: A。daily check-in 跟 medication 编排合并到 `MedicationNotifier`。理由:
- 都在 "chroniccare.medication" channel
- 都用 ReminderDispatcher
- 用户路径单一: 没药时用 daily 1001, 有药时用 2000+medId*10+i
- daily 跟 medication 互斥 (有药时 daily 不发, 没药时 daily 才发)

### 3.2 决策 2: showSafetyAlert 留 facade 还是抽 4th sub-service?

| 候选 | 优劣 |
|---|---|
| **A. 留 facade** ✅ | 1 个 method 50 行, 独立 channel 跟 dispatcher 无关 |
| B. 抽 SafetyAlertNotifier | 1 个 method 不值得 1 个 sub-service |
| C. 合并到现有 sub-service | 跟 medication/refill/assessment 都不是同业务 |

**决策**: A。`showSafetyAlert` 留 facade, 因为:
- 1 个 method 50 行不值得 1 个 sub-service
- 用独立 "chroniccare.safety" channel (跟 medication channel 分开)
- 不走 ReminderDispatcher (因为是 `_plugin.show` 不是 `zonedSchedule`)
- 业务上 1-off, 不是周期性 reminder

### 3.3 决策 3: RefillNotifier 3 个 helper (refillNotificationId / computeRefillFireTime / _daysUntilRefill) 留 RefillNotifier 还是挪到 domain?

| 候选 | 优劣 |
|---|---|
| **A. 留 RefillNotifier (static)** ✅ | 跟 refill 编排强耦合, 现有 test 期望 NotificationService.computeRefillFireTime |
| B. 挪到 domain/logic | domain 层无 Flutter 依赖, 但 refill 编排现在用 entity, 挪过去没强需求 |
| C. 留 facade 公开静态 | facade 仍胖, 拆解失败 |

**决策**: A。3 个 helper 留 `RefillNotifier` 公开 static:
- `refillNotificationId(int medId)`: 跟 medication ID 公式配套
- `computeRefillFireTime({refillAt, reminderDays})`: 现有 round 9 test 已用
- `_daysUntilRefill(DateTime, DateTime)`: 内部用

**breaking change 风险**: `NotificationService.computeRefillFireTime` 公开 API 调用方 (现有 test `notification_service_refill_round9_test.dart`) 改成 `RefillNotifier.computeRefillFireTime`。test 文件同步改 import。

### 3.4 决策 4: 5 sub-service 用 constructor DI 还是 `late final`?

| 候选 | 优劣 |
|---|---|
| **A. constructor DI** ✅ | emil 推荐的 testability 模式, mock 友好 |
| B. late final 内部 new (现有模式) | 1 行简单, 但 test 时无法 mock |

**决策**: A。5 sub-service 都在 constructor 注入, 跟 mood_dialog 拆解同模式:
- 主 facade 接受 plugin + 5 sub-service factory (或者 facade 自己 new, 测试时 mock)
- sub-service 接受 ReminderDispatcher + ensureInitialized callback
- 现有 SnoozeManager / BadgeSyncService / ReminderDispatcher 保持自己 new plugin (内部依赖)

**具体实现**: 主 facade 在 constructor 内部 new 5 sub-service (因为 _plugin 是 facade 持有, sub-service 共享 facade 的 _plugin), 但把 `ensureInitialized` 作为 callback 传入, sub-service 在每个 method 入口 await 调一次 (保证 init 顺序)。

### 3.5 决策 5: ID 范围常量散落到 5 sub-service 还是集中到 facade?

| 候选 | 优劣 |
|---|---|
| **A. 散落到 5 sub-service** ✅ | 单一职责, 各 sub-service 自己管自己 ID |
| B. 集中到 facade | facade 仍胖, ID 范围 + 6 个 const 50+ 行 |
| C. 抽 IDRangePolicy 单例 | 过度工程, 6 个常量不值得 1 个类 |

**决策**: A。ID 范围常量散落到 5 sub-service:
- `MedicationNotifier._medicationReminderBaseId` (2000) + `_defaultReminderId` (1001)
- `RefillNotifier._refillBaseId` (6000)
- `AssessmentNotifier._assessmentReminderId` (7000)
- `BadgeSyncService.badgeVirtualId` (9999, 已有)
- `SnoozeManager.snoozeBaseId` (300000, 已有)
- facade 留 `_safetyAlertId` (5000) 因为 showSafetyAlert 在 facade

**集中列表** (v0.16 round 19 文档化, 留 facade doc comment):
```
1001 (default) < 2000-21999 (med) < 5000 (safety) < 6000-206000 (refill) < 7000 (assessment) < 9999 (badge) < 300000+ (snooze)
```

---

## 4. 验证策略

### 4.1 静态验证

```bash
flutter analyze     # 0 error (48 info-level 已有, 不回归)
flutter test        # 876 cases pass (不回归)
dart scripts/check_all.dart  # 4 层架构 0 violation
python scripts/check_cross_feature.py  # 0 violation
```

### 4.2 测试覆盖

| 文件 | 行数 | 测试目标 |
|---|---|---|
| `notification_service.dart` (facade) | ~250 | 5 sub-service 委托 / init / showNow / showSafetyAlert / cancelAll / pendingCount |
| `medication_notifier.dart` (新) | ~200 | scheduleDailyReminder + rescheduleMedicationReminders (mock dispatcher) |
| `refill_notifier.dart` (新) | ~100 | 5 method (mock dispatcher) + 3 static helper |
| `assessment_notifier.dart` (新) | ~150 | 2 method (mock dispatcher) |

**新 test**: `test/data/notification_service_split_round45b_test.dart`
- 验证 3 个新 sub-service 都能 mount
- 验证 facade 委托链 (mock 5 sub-service 验证调用)
- 验证 computeRefillFireTime / refillNotificationId (跟现有 round 9 / 19b test 兼容)
- 验证 ID 范围公式不回归 (200000 cancel range)

**现有 test 必须 0 改动通过**:
- `notification_service_refill_round9_test.dart` — `NotificationService.computeRefillFireTime` 改 import `RefillNotifier.computeRefillFireTime`
- `notification_service_round19b_test.dart` — `NotificationService.refillNotificationId` 改 import `RefillNotifier.refillNotificationId`
- `notification_service_round4_test.dart` — 仅验证 const 4000, 改 const 300000 (跟 SnoozeManager 同步)
- `reminder_dispatcher_round37_test.dart` — 不动
- `badge_sync_service_round37_test.dart` — 不动
- `snooze_manager_round18_test.dart` — 不动

### 4.3 行为不变性 (P0/P1 不回归)

| P0/P1 修复 | 保留位置 |
|---|---|
| 200000 cancel range (v0.16 round 19/19B) | `ReminderDispatcher.cancelByIdRange` (内部) + `_medicationReminderBaseId` / `_refillBaseId` 仍走 dispatcher |
| safety_watch timeout (v0.23 round 38) | `SafetyWatchService` 不动 |
| SMS fail-fast (v0.23 round 38) | `SmsService` 不动 |
| StreamSubscription leak (v0.22 round 19B) | 主 facade init `runZonedGuarded` 仍存 |
| `DateTime.now()` 多次 race (v0.16 round 19B) | `computeRefillFireTime` + `_daysUntilRefill` 内部仍一次性取 now |
| notification id 200000 range (v0.16 round 19) | 5 sub-service 都用 dispatcher.cancelByIdRange 统一 |
| `swallowError` 模式 (v0.22 round 30) | 5 sub-service 内部 catch + log 仍走 swallowError |
| snooze id 300000 (v0.23 round P0-1 H3) | `SnoozeManager` 不动 |
| RefillNotifier 3 个 helper (refillNotificationId / computeRefillFireTime / _daysUntilRefill) | 内部 static, 公开 (跟现有 test 兼容) |

---

## 5. 工作量估算

| 步骤 | 工作量 |
|---|---|
| Step 1: 现状摸清 + 设计文档 | 🟢 1 小时 (已完成) |
| Step 2: 抽 MedicationNotifier (~200 行) | 🟠 2 小时 |
| Step 3: 抽 RefillNotifier (~100 行) | 🟢 1 小时 (3 helper 跟现有 logic 直接搬) |
| Step 4: 抽 AssessmentNotifier (~150 行) | 🟢 1 小时 (method 跟现有 logic 直接搬) |
| Step 5: 重写 facade (~250 行, 5 sub-service DI) | 🟠 1.5 小时 |
| Step 6: 写 split test (3 sub-service + facade) | 🟡 1.5 小时 |
| Step 7: 改 3 个现有 test import (refill_round9 / refill_round19b / round4) | 🟢 30 分钟 |
| Step 8: 全量验证 | 🟢 30 分钟 |
| **合计** | **🟠 1-1.5 天** (8-10 小时) |

---

## 6. 风险评估

| 风险 | 概率 | 缓解 |
|---|---|---|
| facade 公共 API 签名 breaking change | 🟢 低 | 所有公开 method 保留原签名, 仅内部委托 sub-service |
| `computeRefillFireTime` 公开 API 改名 | 🟡 中 | 同步改 1 个 test 文件 import, facade 留 `@Deprecated` alias 指向 RefillNotifier (兼容性) |
| 现有 widget 调 `NotificationService.xxx` 失败 | 🟢 低 | facade 公共 method 全部保留, 仅内部委托 |
| sub-service init 顺序错乱 | 🟢 低 | facade 内部统一 `await init()` 在每个 method 入口, sub-service 不直接调 plugin init |
| ID 范围常量散落 → 维护难 | 🟢 低 | facade 留 "ID 范围集中列表" doc comment 文档化 |

---

## 7. 不在本次 scope

- ❌ SnoozeManager / BadgeSyncService / ReminderDispatcher 内部重构
- ❌ SafetyWatchService / AssessmentReminderService 重构
- ❌ data_export_service 拆 ExportCryptoService/ExportAudioService/ExportSchemaService 3 子 (P3 god class 候选, 留给 Sprint #5c)
- ❌ 其他 8 个 god class (assessment_history / trend_charts / vent_compose / medications_list / setup_page / medication_calendar)
- ❌ token 化 14 处 `withValues(alpha:)` 散落
- ❌ 4 处 hardcode duration / 4 处 hardcode icon size
- ❌ ScaffoldMessenger 集中化 56% → 95%

**本次只动 `notification_service.dart` + 新增 3 个 sub-service + 改 3 个现有 test import**。

---

## 8. 参考样板: mood_dialog 拆解成功关键 (跟本次类比)

| 关键 | mood_dialog 体现 | notification_service 体现 |
|---|---|---|
| 1 page = 1 orchestrator | 199 行, 仅 AlertDialog 容器 + 跨 widget 状态 | 250 行, 仅 init + 5 sub-service 委托 + 6 ID 范围 doc |
| 5 个子 widget 各管自己职责 | MoodScoreForm / MoodTags / MoodTextNote / MoodRecorder / MoodDialogActions | MedicationNotifier / RefillNotifier / AssessmentNotifier / SnoozeManager / BadgeSyncService |
| 跨 widget 状态不上抛 | 4 维度 + tag + text 留在 orchestrator (dialog scope, 简单值) | _plugin / _dispatcher / 5 sub-service 留在 facade (init 共享) |
| 状态机下沉到子 widget | 录音机状态机 99% 副作用不外泄 | 通知编排 (id 公式 + cancel 范围 + dispatcher 调) 100% 在 sub-service |
| 不引入新架构 | 仅用 ValueNotifier + Controller | 仅用 constructor DI (跟现有 late final 同) |

**notification_service 拆解关键 (跟 mood_dialog 同)**:
- 1 facade = 1 orchestrator (~250 行, init + 委托)
- 5 个 sub-service 各管自己职责
- 跨 sub-service 状态 (_plugin / _dispatcher) 留在 facade (init 共享)
- 通知 ID 范围常量散落到 5 sub-service (单一职责)
- 不引入新架构 (跟现有 SnoozeManager / BadgeSyncService 同 constructor DI 模式)
