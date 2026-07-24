# superpowers-en 视角审视报告 (v0.21+, round 27)

> 视角: subagent-driven development + systematic debugging + code review
> 范围: `lib/` 全部 + 7 个必读文件 + 1 个 schemaVersion 8→11 演进
> 日期: 2026-07-20

---

## 0. 项目现状

### 0.1 工具链结果

| 命令 | 结果 | 备注 |
|---|---|---|
| `flutter analyze` | **0 issues** | 无 error / warning / info |
| `flutter test` | **703 / 703 pass** | 74 个 test 文件；约 703 cases (从 702+1) |
| `dart scripts/check_all.dart` | **2/2 通过** | purity + consistency |
| `python scripts/check_cross_feature.py` | **0 violations** | 49 files checked |

### 0.2 文档 vs 代码同步问题

| 项 | 文档 (AGENTS.md) | 实际 | 差异 |
|---|---|---|---|
| `schemaVersion` | 8 | **11** | **差 3 个大版本** (v0.21 round 22/23 加了 9/10/11) |
| `flutter test` 总数 | 702 | 703 | 差 1 个 test case |
| `!mounted` 计数 | 30+ 处 | **38 处** | 又加了 8+ |
| `ref.mounted` | 1 处 (v0.17 round 7) | **7 处** | 增长 7x |
| 测试文件数 | 未提 | 74 个 | round 后缀覆盖 3-20 |

**结论**: AGENTS.md 至少落后 2 个 round。建议下次顺手 sync。

### 0.3 v0.16-0.21 round 1-23 已修 bug 回顾

来源: `docs/CHANGELOG.md` + AGENTS.md 已知坑清单

**v0.16 round 1-19** (技术债清理):
- ✅ 4 层架构合并到 `check_all.dart`（替代 2 个旧 script）
- ✅ `care_engine.dart` 相对路径绕过 purity → 改 `NotificationSender` 抽象
- ✅ 18 个 unused import + 1 dead try/catch + 2 dead `// ignore` + dead `audioExists()`
- ✅ 4 个 `RadioListTile` 迁移到 `RadioGroup`（Flutter 3.32+）
- ✅ Stream subscription leak：vent detail/compose 修
- ✅ 18 个文件 `dart format` + `dart fix --apply`（229 fixes）
- ✅ `vent_entry.dart` 死代码清理

**v0.16 round 19 隐式排序 5 个 service** (重大):
- `streak_calculator` / `assessment_comparison` / `reminder_scheduler` / `safety_watch_service` / `assessment_reminder_service`

**v0.16 round 19/19B DateTime race**:
- `medications_list_widget._editRefill` (3 → 1)
- `trend_page._calendarMonth` (2 → 1 via `_initialCalendarMonth()`)
- `scheduleRefillReminder` (2 → 1)

**v0.16 round 19/19B Notification id cancel range**:
- `cancelAllSnoozes` (1000 → 2000000)
- `rescheduleMedicationReminders` (1000 → 200000)
- `rescheduleRefillReminders` (1000 → 200000)

**v0.16 round 19B Resource leak**:
- `vent_compose_page._getAudioDuration` AudioPlayer 加 `try/finally` 强制 dispose

**v0.16 round 19C 路由 parse error**:
- `app_router.dart:212` `int.parse` → `int.tryParse` (vent detail)

**v0.16 round 20 OEM 静默杀通知**:
- `NotificationStatusCard` 自检卡 + 5 品牌引导

**v0.17 round 1-5** (emil 动效 + Riverpod 3.x):
- `AppTokens.curveStandard/Decelerate/Accelerate/Delight` 4 个
- `CheckInButton` 状态过渡 `AnimatedContainer + AnimatedSwitcher`
- `streak` 数字 `TweenAnimationBuilder`
- 3 类 page transition (fade / slide-right / slide-up)
- vent list → detail Hero
- `nextMidnightRefresh` 跨 midnight timer
- 12 个 CareEngine edge case test
- `valueOrNull` → `value` (2 处)

**v0.17 round 12 跨 feature import**:
- `check_cross_feature.py` 拦截 `pages/{A}/` → `pages/{B}/`

**v0.17 round 14 拆 core_providers**:
- `core_providers.dart` (db + 基础 service + 7 repo)
- `service_providers.dart` (reminder / safety / assessment / data export)
- `vent_providers.dart` (vent audio + entries)

**v0.18 round 14 P0-2 vent 加密**:
- `EncryptionService` (singleton, 设备绑定 AES-256)
- vent audio 录音→加密→.m4a.enc; 播放→解密→temp
- vent text 字段从明文 → BLOB 加密 (schemaVersion 9)

**v0.18 round 18 NotificationService 拆分**:
- 拆出 `SnoozeManager`（-90 行）
- CareEngine 文案集中到 `care_copy.dart`

**v0.21 round 22-25** (本审视主要针对):
- schemaVersion 8→11 (3 个迁移步骤)
- 4 个 consent 字段 + `userName` nullable
- PIPL §47 主动删除（`clearAllUserData`）
- 评估提醒移入 `addPostFrameCallback`（替代 magic 100ms delay）
- `dayChangeTickProvider` 跨日 widget rebuild
- `crossedMidnightSince` app 回前台检测
- `notificationStatusCard` Android 兼容
- `M3 Material` inkwell shader 兼容 + Flutter 3.41

---

## 1. 顶层架构审视

### 1.1 4 层架构健康度

| 维度 | 状态 | 证据 |
|---|---|---|
| 纯度 (domain 0 flutter / 0 drift) | ✅ | `check_all.dart [1/2]` pass |
| 一致性 (Entity ↔ drift table) | ✅ | `check_all.dart [2/2]` pass |
| 跨 feature import 边界 | ✅ | `check_cross_feature.py` 0 violations / 49 files |
| Repository 接口/实现分离 | ✅ | `core_providers` 暴露 domain `XRepository` 接口，impl 内部包 |
| data 0 presentation 依赖 | ✅ | `check_all.dart` 检测通过 |
| 共享层工具使用度 | ✅ | 4 个 `core/shared/` 工具均被 ≥2 层使用 |
| `app_router.dart` 跨层耦合 | ⚠️ | 注释自承认 trade-off: routing 必须 import pages（go_router 架构） |

**结论**: 架构健康度优秀。`app_router.dart` 跨层是 go_router 固有限制，已在注释中说明并在 `check_all.dart` 排除。

### 1.2 可重构的模块

**1) 两个 AES-256 加密服务重复** — **高优先级重构**

| 服务 | 用途 | Key 存储 | 单例? | Key name |
|---|---|---|---|---|
| `EncryptionService` (v0.18 round 14) | vent audio + vent text 加密 | SecureStorage | ✅ `_shared` static | `vent_audio_encryption_key_v1` |
| `CryptoService` (v0.7) | 联系人邮箱 / 用户姓名 / 旧路径 | SecureStorage | ❌ 每次 new instance | `chroniccare.aes.key` |

两者都 AES-256-CBC + PKCS7 + 16 字节 IV + 32 字节 key 存 base64。代码几乎复制粘贴。区别仅在:
- `EncryptionService` 用 `Uint8List` 接口 + 设备绑定 + 每次随机 IV
- `CryptoService` 用 `String` 接口 (UTF-16 codeUnits) + 无缓存 (每次 SecureStorage 读)

**建议**: 合并为 1 个 `EncryptionService`，同时支持 `String` + `Uint8List` 两种接口。`CryptoService` 标记 `@Deprecated`，引导调用方迁移。

**2) `notification_service.dart` `_softReminderId` (3000) 是 dead code** — **中优先级**

- `scheduleSoftReminder` 已在 v0.18 P2-P0-5 删除
- `cancelSoftReminder()` 还在 line 257-260, 注释说"保留以防历史通知残留"
- 但**没有任何 caller** 在用户打卡后真正依赖（实际上 `home_page._onCheckIn` line 298 还在调它，但 `scheduleSoftReminder` 已删，cancel 是 no-op）

**建议**: 完全删 `_softReminderId` + `cancelSoftReminder()`，删除 `home_page._onCheckIn` 中的 cancel 调用。

**3) 命名不一致** — **低优先级 (cosmetic)**

- `_assessmentReminderId` (单数, const) vs API `scheduleAssessmentReminder` / `cancelAssessmentReminder` (复数)
- 建议: const 改 `_assessmentReminderBaseId` 或 API 改单数

### 1.3 抽象层设计

| 抽象 | 评价 | 备注 |
|---|---|---|
| `XRepository` (domain interface) + `XRepositoryImpl` (data) | ✅ 优秀 | 7 个 repo 全部如此 |
| `NotificationSender` (domain interface) | ✅ 优秀 | 让 `care_engine.dart` 不再依赖具体实现 |
| `ReminderChecker` (domain interface) | ✅ 优秀 | use case 拿这个，不直接拿 `ReminderService` |
| `EncryptionService` (concrete) | ⚠️ 应该是 abstract | 当前是具体类，没有 impl 分离 |
| `NotificationService` (concrete, implements `NotificationSender`) | ✅ 良好 | 但 700+ 行太大 |
| `NotifierProvider<DayChangeTickNotifier, int>` | ✅ 优秀 | Riverpod 3.x 模式 |
| `StreamProvider.autoDispose` 全覆盖 | ✅ 优秀 | 10 个 stream provider 全 autoDispose |

### 1.4 Provider 拆分评价 (v0.17 round 14)

| 文件 | provider 数 | 评价 |
|---|---|---|
| `core_providers.dart` | 11 | db + crypto + notification + sms + 7 repo |
| `service_providers.dart` | 5 | reminder / safety / assessment / dataExport |
| `vent_providers.dart` | 4 | audioStorage + repo + entries + byId |

**结论**: 拆分合理，core 11 个适中（v0.16 之前 25+ 确实太大）。可考虑把 `smsService` + `smsProviderName` 抽到 `service_providers`（与 reminder / safety 同组，都是通知链路），但不强求。

---

## 2. 底层逐行排查

### 2.1 必查项清单（已用 grep 系统扫）

| 项 | 扫到的位置 | 结论 |
|---|---|---|
| `\.first\b\|\.last\b` 隐式排序 | 7 个文件，13 处 | **已修** v0.16 round 19 (5 个 service)；`data_export_service.watchX().first` 是 stream-first 标准用法；`parts.first` 字符串 split；`points.first.dx` path 起点。**全部有显式 sort 或语义正确** |
| `DateTime.now()` 同一函数多次 | 35 个文件，60+ 处 | **全部有显式 `final now = DateTime.now()` 缓存** 或不同方法分散；no race |
| 资源 `try/finally` | 27 处 try + 16 处 finally | vent_compose_page._getAudioDuration ✅ |
| `StreamSubscription` 字段 + dispose | 4 个字段，5 处 .cancel() | vent_compose_page (1) + vent_detail_page (3) + app.dart (1) — **全部清理** |
| `int.parse` / `DateTime.parse` 用户输入 | 仅 `data_export_service._validateDate` 用 `tryParse` | ✅ v0.21 P0-2 fix |
| `pathParameters[]` 路由参数 | `app_router.dart:183, 212, 223` | line 183 (string fallback), 212 (tryParse, v0.16 round 19C fix), 223 (string) — 全部安全 |
| `\!mounted` 检查 | 14 个文件，38 处 | 配合 `context.mounted` 21 处 + `ref.mounted` 7 处 |
| 空 catch 块 | **0 处** (经 grep 验证) | v0.16 round 19 已清 |
| `as` 强转 | 5 个文件，~17 处 | 多在 `data_export_service` JSON 反序列化，catch 处理 |
| `Random()` vs `Random.secure()` | vent_audio_storage 3 处 | `Random()` (默认种子) **只用于文件名**，**不是安全场景**（实际内容是加密的）— 可接受 |
| `!isActive.equals(true)` vs `\.equals(true)` | 4 处 | drift orderBy/where，标准用法 |

### 2.2 找到的问题

#### 架构边界类

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-01** | 重复服务 | `lib/core/data/services/crypto_service.dart` 整文件 vs `encryption_service.dart` 整文件 | 两个 AES-256 服务并存，复制粘贴的 cipher init + key 生成代码；`CryptoService` 未实现单例 | 中 | 中 | **P1** |
| **spen-02** | Dead code | `lib/core/data/services/notification_service.dart:257-260` | `cancelSoftReminder()` 保留但 `scheduleSoftReminder` 已在 v0.18 P2-P0-5 删除 | 低 | 低 | P3 |
| **spen-03** | Dead code | `lib/presentation/pages/home/home_page.dart:298` | `await ref.read(notificationServiceProvider).cancelSoftReminder();` 调用一个 no-op 方法 | 低 | 极低 | P3 |
| **spen-04** | 命名不一致 | `lib/core/data/services/notification_service.dart:36` | `_assessmentReminderId` (单数) vs `scheduleAssessmentReminder` (复数) | 低 | 极低 | P4 |

#### SQLCipher / Drift 类

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-05** | SQL 注入风险（理论） | `lib/core/data/database/connection/native.dart:27` | `db.execute("PRAGMA key = '$password'")` 用字符串拼接，password 含单引号会破。**当前 key 是 base64 不含 `'`，实际不可利用**；但 SQLCipher PRAGMA key 不支持绑定参数 | 低 | 低 | P3 |
| **spen-06** | Web crash | `lib/core/data/services/database_migration.dart:35` | `File(p.join(...)).existsSync()` 在 web 端 `dart:io` 抛 `UnsupportedError`；`main.dart:76` `await DatabaseMigration.needsMigration()` **无 try/catch** → web 直接崩 | 中 | 低 | **P1** (如果 web 是公开目标) |

#### 加密服务类

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-07** | 编码不规范 | `lib/core/data/services/crypto_service.dart:34, 54` | `String.fromCharCodes` + `codeUnits` (UTF-16 codeUnits) — **对中文能 round-trip 但非标准**；`EncryptionService` 用 `Uint8List` + `utf8.encode/decode` 更规范 | 低 | 低 | P3 |
| **spen-08** | 性能 + 潜在 race | `lib/core/data/services/crypto_service.dart:58-72` | `_getOrCreateKey` 每次都读 SecureStorage（platform channel，慢）；首次并发调用可能 race 生成多个 key | 低 | 中 | P3 |
| **spen-09** | 跨平台 key 存储 | `lib/core/data/services/crypto_service.dart:16-19` | `IOSOptions(accessibility: KeychainAccessibility.first_unlock)` vs `EncryptionService._storage` 的 `first_unlock_this_device` — 加密范围不一致 | 低 | 低 | P3 |

#### DateTime / 隐式排序类

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-10** | Dead code (空 if) | `lib/app.dart:69-71` | `if (now.isBefore(nowCutoff)) { /* empty, just comment */ }` 空 if 块，注释和实际逻辑矛盾（注释说"nowCutoff 是昨天"，实际是今天） | 极低 | 极低 | P4 |
| **spen-11** | 跨 midnight widget rebuild | `lib/presentation/pages/medication/medication_calendar_page.dart:157` + `lib/presentation/pages/trend/trend_calendar.dart:44` | `final today = DateTime.now()` 在 build 内取，跨 midnight 后**靠** `dayChangeTickProvider` (v0.21 P0-6 fix) 触发 rebuild。**修法已落地**，但需在 widget 内 `ref.watch(dayChangeTickProvider)` 才生效。**需验证这 2 个文件是否真的 watch 了** | 中 | 低 | **P2** (验证) |
| **spen-12** | int32 overflow (理论) | `lib/core/data/services/snooze_manager.dart:68` | `snoozeBaseId + (medicationId * minutesPerMedication)` — `medicationId * 1440` 在 int32-only 平台（罕见）会溢出。64-bit / JS 53-bit mantissa 安全 | 极低 | 低 | P4 |

#### 资源 / 异步类

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-13** | Temp file leak | `lib/core/data/services/vent_audio_storage.dart:130-134` | `decryptToTemp` 如果 `writeAsBytes` 抛异常，temp 文件不会被删；调用方 `_getAudioDuration` 已有 try/finally 调 `deleteTempFile`，但 `vent_detail_page._togglePlay` 和 `vent_compose_page._togglePlay` 没清（**try-catch 内**仅设 `_isPlaying = false`） | 中 | 低 | **P2** |
| **spen-14** | Async 后 context 使用 | `lib/core/routing/notification_navigation.dart:77` (有 try) | grep 显示有 try/finally，但需 spot-check await 后是否 mounted-check 完整 | — | — | 验证 |

#### Notification / 测试

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-15** | 测试覆盖 | 整体 | `cancelSoftReminder` (dead code) 和 `updateBadgeCount` (虚拟 id 9999) 无 widget test 覆盖；`crossedMidnightSince` 有单测但 AppRoot 的 `didChangeAppLifecycleState` 集成路径无 | 低 | 中 | P3 |
| **spen-16** | O(n²) perf | `lib/core/data/services/notification_service.dart:201-207, 482-487` | `rescheduleMedicationReminders` / `rescheduleRefillReminders` 拉全部 pending 通知再按 id 范围 cancel；用户 > 50 药时每次重排 O(n) | 低 | 中 | P3 |

---

## 3. Bug 清单

> "Bug" 指**当前行为有问题**或**违反某已知模式/最佳实践**，区别于 §2 "可优化"。

| 编号 | 类别 | 文件:行 | 描述 | 严重度 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **spen-bug-01** | Web crash | `lib/main.dart:76` + `lib/core/data/services/database_migration.dart:32-36` | web 平台 `await DatabaseMigration.needsMigration()` 调 `File.existsSync()` 抛 `UnsupportedError`，`main.dart` **无 try/catch** → runZonedGuarded 兜底但不友好 | 中 | 低 | **P1** (若 web 公开) |
| **spen-bug-02** | Temp file leak | `lib/presentation/pages/vent/vent_detail_page.dart:91-108` + `lib/presentation/pages/vent/vent_compose_page.dart:213-231` | `_togglePlay` try/catch 失败时**不删** `_tempDecryptedPath`；`dispose` 时会清（OK），但若用户同页面反复失败，会堆积 temp 文件 | 中 | 低 | **P2** |
| **spen-bug-03** | Hot path perf + race | `lib/core/data/services/crypto_service.dart` | 无单例 + 无缓存 → 每次 `encrypt()` 调 SecureStorage (platform channel 慢)；首次并发 race 生成多个 key | 低 | 中 | P3 |
| **spen-bug-04** | 死代码 | `lib/core/data/services/notification_service.dart:30, 257-260` + `lib/presentation/pages/home/home_page.dart:298` | `_softReminderId` 整条调用链 dead code；保留只是技术债 | 低 | 极低 | P3 |
| **spen-bug-05** | Dead code (空 if) | `lib/app.dart:69-71` | `if (now.isBefore(nowCutoff)) { /* 注释 */ }` 块内只有注释，编译为 no-op；注释说"nowCutoff 是昨天"与实际逻辑矛盾 | 极低 | 极低 | P4 |
| **spen-bug-06** | SQL 拼接 code smell | `lib/core/data/database/connection/native.dart:27` | `PRAGMA key = '$password'` 字符串拼接；当前 key base64 安全，但 PRAGMA key 不支持 binding，是已知 SQLCipher 限制 | 低 | 低 | P3 |
| **spen-bug-07** | 文档过期 | `AGENTS.md:104` | `schemaVersion 当前 8` → 实际 11（v0.21 round 22 加了 9/10/11，3 步大迁移） | 低 | 极低 | P3 |
| **spen-bug-08** | 文档过期 | `AGENTS.md:31` (隐私边界表) + `AGENTS.md:163` | 树洞 row 含 `contentTextEnc` (BLOB) 不是 TEXT；测试总数 702 → 实际 703 | 低 | 极低 | P3 |
| **spen-bug-09** | 重复实现 | `lib/core/data/services/crypto_service.dart` vs `encryption_service.dart` | 两个 AES-256 服务并存，60+ 行几乎复制粘贴；`CryptoService` 无单例、无 cache、未实现设备绑定（key 名字与 EncService 区别） | 中 | 中 | **P2** (技术债) |
| **spen-bug-10** ⚠️ **已确认** | 跨日 widget rebuild 漏改 | `lib/presentation/pages/trend/trend_calendar.dart:44` + `lib/presentation/pages/trend/trend_page.dart` | `final _today = DateTime.now()` 在 initState 取一次，**不** watch `dayChangeTickProvider`。对比 `medication_calendar_page.dart:44` 正确 watch。**结果**：用户打开 `/trend` 不退出，跨过 00:00:05 后，"今天"格子仍高亮昨天；streak 卡片不刷（streak 单独 invalidate，但 trend 页 today 标记是另一回事）。**修法**：trend_calendar.dart 加 `ref.watch(dayChangeTickProvider);` 同 medication_calendar_page | 中 | 极低 | **P1** |

### 3.1 隐私边界专项检查 (AGENTS.md 红线)

| 模块 | 跨界 | 状态 |
|---|---|---|
| 树洞（vent）→ 趋势 | grep `ventEntries\|contentText` 在 `lib/presentation/pages/trend/` | ✅ 0 处（trend 用 `checkIns` + `moodEntries`） |
| 树洞 → 评估 | grep `vent` 在 `lib/presentation/pages/assessment/` | ✅ 0 处 |
| 树洞 → CareEngine | grep `vent` 在 `lib/domain/logic/care_engine.dart` | ✅ 0 处 |
| 树洞 → SafetyWatch | grep `vent` 在 `lib/core/data/services/safety_watch_service.dart` | ✅ 0 处 |
| 树洞 → 通知 | grep `ventEntries` 在 `lib/core/data/services/notification_service.dart` | ✅ 0 处（**正确**，即使内容含"想死"也不通知家人） |
| 树洞 → 关怀 | grep `vent` 在 `lib/domain/logic/` | ✅ 0 处 |
| 情绪（mood）→ 通知 | grep `mood` 在 `notification_service.dart` | ✅ 0 处 |
| 评估（assessment）→ 失联通知 | `CrisisSignal` 走 `NotificationService.showNow` | ✅ 正确（v0.7 设计） |
| 打卡（check-in）→ 评估 | grep `assessment\|phq9\|gad7` 在 `lib/core/data/repositories/check_in/` | ⚠️ 0 处（但 `app_database.watchAssessments()` 是 filter checkIns where type='phq9'\|type='gad7'，是 DB 视图层共享，OK） |

**结论**: 隐私边界 100% 守住。

---

## 4. 总结

### 4.1 关键发现 3 条

1. **架构健康度优秀，但有 1 个 latent web crash** (spen-bug-01): `database_migration.dart` 用了 `dart:io` 但 web 平台没有 try/catch。如果 web 是公开目标（AGENTS.md 没明说 web 是否在发布列表），是 P1 必修。

2. **技术债集中于 2 个 AES-256 服务** (spen-bug-09 + spen-01): `CryptoService` (v0.7 旧) + `EncryptionService` (v0.18 新) 重复实现，建议合并。这不是 critical bug 但影响维护性。

3. **v0.16 那一轮 5 个 service 的隐式排序 + 3 个 DateTime race + 3 个 notification id cancel range + 1 个 audio leak 修复极其成功**：本轮系统 grep 全部无 regression。说明 v0.16 那一轮 "先 grep 后 fix" 模式可作为未来新功能 review 的样板。

### 4.2 Top 5 必修列表

| 排名 | 编号 | 标题 | 影响 | 估时 |
|---|---|---|---|---|
| **1** | spen-bug-01 | web 端 `database_migration.dart` 抛 `UnsupportedError` 未捕获 | web 直接崩 | 30 min |
| **2** | spen-bug-10 | `trend_calendar.dart` 加 `ref.watch(dayChangeTickProvider)` (同 medication_calendar_page) | 跨日 trend 页 today 标记不刷新 | **5 min** |
| **3** | spen-bug-02 | `vent_compose_page._togglePlay` / `vent_detail_page._togglePlay` 失败时删 temp file | temp 堆积泄漏 | 20 min |
| **4** | spen-01 + spen-bug-09 | 合并 `CryptoService` → `EncryptionService` 抽象 | 维护性 + 一致性 | 1-2 hour |
| **5** | spen-bug-04 | 删 `_softReminderId` + `cancelSoftReminder()` + 调用方 | 死代码清理 | 15 min |

> **注**: spen-bug-10 估时 5 min（1 行 fix），但**优先级拉到 P1**（真实可观察 bug，仅 grep 验证，建议加 widget test 锁定行为）

### 4.3 整体健康度评分

| 维度 | 分数 (1-10) | 备注 |
|---|---|---|
| 架构 | **9.5** | 4 层 + shared 边界全守；privacy 100% |
| 测试覆盖 | **9.0** | 74 文件 / 703 cases / 23 round；domain 业务 + data round-trip + presentation widget 三层齐；**缺**：notification_service 死代码 + crypto_service + app 集成路径 |
| 代码质量 | **8.5** | 几乎无 lint warning；少数 dead code + 重复实现；emil/Riverpod 3.x 风格统一 |
| 安全 / 隐私 | **9.5** | SQLCipher 设备绑 key + 字段级加密 (vent text BLOB) + 隐私边界严守 + 国产 ROM 引导 |
| 时序正确性 | **9.5** | DateTime 全部缓存 now 一次；streak/midnight/跨日 4 套修复 |
| 文档同步 | **6.0** | AGENTS.md 落后 2-3 round（schemaVersion 8→11 / 测试 702→703 / privacy 边界表过时） |

**综合**: 8.7 / 10 — 进入 production-ready 阶段，只需小修小补。

### 4.4 建议

- **P0 (本周修)**: spen-bug-01, spen-bug-02, spen-bug-10 验证, spen-bug-07/08 文档 sync
- **P1 (下个 round 修)**: spen-01 + spen-bug-09 合并两个加密服务
- **P2 (技术债清理)**: 删 dead code (spen-bug-04/05)
- **P3 (可选优化)**: spen-16 O(n) cancel, spen-bug-06 SQL 拼接, spen-bug-03 单例

### 4.5 跟进建议

下次发起 round 时建议同时跑：
1. `flutter analyze` + `flutter test` + `dart scripts/check_all.dart` + `python scripts/check_cross_feature.py` 4 件套 baseline
2. `grep -rn 'TODO\|FIXME\|XXX\|HACK' lib/` 看技术债清单
3. 同步 `AGENTS.md` 的 schemaVersion / 测试数 / privacy 边界表
4. 加 1 个新 widget test 覆盖 `dayChangeTickProvider` + 跨日 rebuild（spen-bug-10 验证）

---

*报告生成时间: 2026-07-20*
*审视工具: Read + ripgrep + dart scripts + flutter analyze + flutter test*
*审视范围: 74 test files + ~80 lib files + 7 must-read files + 1 changelog*
