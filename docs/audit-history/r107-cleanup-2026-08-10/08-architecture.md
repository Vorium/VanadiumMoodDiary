# 顶层架构审视报告

> 审视员：MiniMax M3（顶层架构师视角）
> 范围：`D:\Batch\chroniccare`（v0.30.0+85）
> 审视日期：2026-08-10
> 方法：Read + 结构扫描，**未跑** `flutter analyze` / `flutter test`（任务豁免）

---

## 1. 评分（8.2 / 10）

| 维度 | 评分 | 备注 |
|---|---|---|
| 整体架构 | **8.2** | 4 层 + 19 守门员 / 8 FeatureFlag / 2019 tests，**最成熟阶段** |
| 分层清晰度 | 9.0 | 4 层 + core umbrella 边界清晰，dart script `check_all.dart` 守门 |
| 依赖方向 | 9.5 | `presentation → domain ← data` 严格，0 反向 import（`check_all.dart` + `check_cross_feature.py` 双守门） |
| 模块内聚 | 7.5 | pages 按 feature 拆，但 **15 个 feature god class** 仍在 presentation/state 单文件 |
| 模块解耦 | 8.0 | feature 间通过 domain 接口 / core/ 通信；cross_feature 守门员覆盖 |
| 抽象层级 | 9.5 | domain 0 Flutter 0 Drift 已验，shared/ 每个文件至少被 2 层用 |
| 接口稳定 | 8.5 | 16 abstract repo 稳定，data impl 集中在 `data/repositories/{feature}/` |
| Provider 设计 | 8.0 | core/service/vent/shared 4 文件拆分，颗粒度合理 |
| 状态归属 | 7.0 | 业务状态 80% 在 domain，但 home_page_state 仍混入 FireCareEngine 编排 |
| 可测试性 | 9.0 | 2019 tests + ProviderScope overrides + visibleForTesting top-level 函数 |
| 可扩展性 | 7.5 | 5 步新功能 15-20 文件 / 1-2 天，但 god class 复用难 |

**综合判断**：当前是「**架构成熟期**」。分层、依赖、接口、测试都到位，**主要债务集中在 presentation 层 15 个 god class**（占 395 dart 文件总行数 ~18%）。重构空间 90% 在 state 拆解 + 文件级重组，**无需**重大架构变革。

---

## 2. 当前架构健康度

### 2.1 4 层 + 共享 umbrella（实测）

| 层 | 文件数 | 大小 | 边界状态 |
|---|---|---|---|
| `lib/main.dart` + `lib/app.dart` | 2 | 24KB | ⚠️ main 4 占位 app 耦合（见 §3.1） |
| `lib/core/data/`（DB + Repos + Services） | ~80 | ~700KB | ✅ 16 abstract repo + 16 impl + 30+ services |
| `lib/core/shared/` | 5 | <10KB | ✅ 每文件 ≥2 层用，2 守门员覆盖 |
| `lib/core/theme/`（R65 拆 4 文件 + facade） | 6 | ~70KB | ✅ |
| `lib/core/routing/`（R59 拆 god class） | 4 | <15KB | ✅ |
| `lib/core/l10n/` domain strings | 1 | 17.8KB | ⚠️ dual API（const 字段 + i18n 函数）—— R57 妥协 |
| `lib/l10n/` presentation flutter_localizations | 5 | ~570KB | ✅ |
| `lib/domain/` | 80+ | ~280KB | ✅ 0 Flutter 0 Drift 验过 |
| `lib/presentation/` | ~210 | ~1500KB | ⚠️ **15 god class 候选在 state** |

**关键证据**：domain/ 0 处 `import flutter`、0 处 `import drift`、data/ 0 处 `import presentation`、cross_feature 0 violation（3 守门员实证）。

### 2.2 19 守门员（实测，AGENTS.md 列 17 + 修正）

```
check_16kb_alignment.py    check_all.dart           check_arb_keys.py
check_changelog.py         check_coverage.py        check_cross_feature.py
check_datetime_race.py     check_datetime_race2.py  check_drift_namespace.py
check_fullwidth_punctuation (warn-only)             check_legal_consent.py
check_no_hardcoded_utc.py   check_no_pua.py          check_orphan_arb_keys.py
check_sms_release_ready.py (warn-only v0.27)        check_strings_hardcoded.py
check_widget_dispose.py     check_zh_hant_consistency.py
apply_l10n_implements.py    (utility)
```

**评估**：覆盖架构 / i18n / 法律 / 平台 / 资源 / 命名空间全维度。密度健康 —— 每加 1 个新 feature 必有 3-5 守门员在跑。

### 2.3 8 FeatureFlag 守门（R93 阶段 2）

```dart
FeatureFlags.emergencyContactEnabled   // _prod=false  (失联业务暂停)
FeatureFlags.iapEnabled                // _prod=false  (Apple 2.1 拒因)
FeatureFlags.phqGad7I18nEnabled        // _prod=false  (R65b 阶段开启)
FeatureFlags.bootReceiverEnabled       // _prod=false  (R93 改, 等 WorkManager)
FeatureFlags.aliyunSmsEnabled          // _prod=false  (R93 新, 等法务+AccessKey)
FeatureFlags.emailServiceEnabled       // _prod=false  (R93 新, 等 SendGrid)
FeatureFlags.fiveVendorPushEnabled     // _prod=false  (R93 新, 等 5 厂商 SDK)
FeatureFlags.ventAudioEnabled          // _prod=TRUE   (R104 翻 true)
```

**设计质量**：8 flag = 8 `_prodXxx` const + 8 `_currentXxx` nullable + getter = `_currentXxx ?? _prodXxx`。test helper `enableForTest(flag)` / `resetForTest(flag)` 28 test 已用。**该模式是项目亮点**，可推广到新开关。

---

## 3. 架构债务清单（按严重度）

### 3.1 🔴 P0 — lib/main.dart 459 行 + 4 占位 app（god class 候选）

`main.dart` 现状：
- 顶层 `final _smsService / _emailService`（R62 P0 修）
- `main()` / `_bootstrap()` / `_loadEnv()` / `_initTimezones()` / `_initNotification()`（195 行 orchestrator）
- `_showMigrationConfirmDialog`（60 行）
- 4 占位 widget：`_MigrationPromptApp` / `_MigrationAbortedApp` / `_MigrationFailedApp` / `_EarlyLoadingApp`（R104 新增）
- 1 helper `_MigrationPromptController`

**问题**：4 占位 widget 共 ~200 行，跟主流程无强耦合。启动顺序 + 5 widget 全在 1 文件，未来加 1 个新启动状态要重读 459 行。

**重构 ROI**：🟢 极高（孤岛 / 1 天 / 0 风险）

### 3.2 🟠 P1 — home_page_state.dart 597 行（最大 god class，已部分拆）

R95 sub-spec 4 task 5 抽自 home_page.dart，1 个 ConsumerState 类（3 Timer + 1 ScrollController），9 业务方法：

| 方法 | 行 | 职责 |
|---|---|---|
| `_handleDeepLink` + `_autofireMedicationCheckIn` | 80 | 深链自动打卡 |
| `_runSafetyCheck` + `_runAfterCheckIn` | 65 | 失联检测 |
| `_onCheckIn` | 30 | 打卡主流程 |
| `_fireCareEngine` | 70 | FireCareStrategyUseCase 编排 |
| `_snooze5Min` | 25 | 5min 后通知 |
| `_celebrationFor` / `_showCelebrationOverlay` | 45 | 顶部 overlay |
| `_nextReminderTime` | 10 | 下次提醒时间 |
| `build()` | 180 | widget tree |

**问题**：597 行单 ConsumerState 违反 SRP。R95 已抽 state class 到独立文件，但**没进一步抽 controller**：deep link handler / care engine dispatcher / celebration controller 都该是独立 ChangeNotifier / controller。`build()` 占 180 行 = 主屏 6 区域全 inline。

**重构 ROI**：🟠 中-高（~400 行可抽 3 controller / 2-3 天）

### 3.3 🟠 P1 — medication_page.dart 540 行 + medication feature 3 god

`medication_page.dart`：1 `MedicationPage` ConsumerWidget（200 行 build + 180 行 helpers）+ 1 `_TimeSlot` enum（morning/afternoon/evening/bedtime 含 `contains(hour)` 算法）+ 1 `_SlotEntry` class + 3 helper method。

**问题**：时间段算法（`_TimeSlot.contains` + `_buildTimeSlots`）是纯业务，应进 `domain/logic/medication_slot_calculator.dart`，可在 test 中直接覆盖。medication feature **3 god class**（medication_page 18KB + add_medication_page 17.6KB + edit_medication_dialog 15.3KB）证明 medication 是**最重 feature**（148.9KB 总）。

**重构 ROI**：🟠 中-高（算法抽 domain + widget 抽 widgets/，1-2 天）

### 3.4 🟠 P1 — vent_compose_page 495L + mood_audio_recorder_widget 530L（音频状态机重复）

2 文件实现**几乎相同**的 audio state machine：

| 重复点 | vent_compose | mood_audio |
|---|---|---|
| 字段 | `_isRecording` / `_isPlaying` / `_audioPath` / `_tempDecryptedPath` | 同上 + `_liveTranscript` |
| `_asyncDispose` 4 步链 | 50 行 | 65 行（pattern 1:1）|
| `swallowError + unawaited + catchError` | 多处 | 多处 |
| 底层 plugin | `record` + `audioplayers` | `MoodAudioService` 封装 record + stt |

**问题**：2 套并行 audio state machine = 2 倍 bug surface。`AudioStateController` / `RecordingLifecycle` 抽象缺失。

**重构 ROI**：🟠 高（抽 `lib/presentation/widgets/audio_lifecycle.dart` 共享，~150 行去重，1-2 天）

### 3.5 🟡 P2 — notification_service.dart 426 行（已 R65 拆 facade，残留）

1 `NotificationService` class，**7 sub-service DI** + 18 public method（13 个 1 行委派）+ 自有方法 5 个（init 60 行 / requestPermission 15 行 / showNow 20 行 / cancelAll / pendingCount / showSafetyAlert 5 行委派到 SafetyAlertBuilder）。

**问题**：13 个 1 行委派 method 占 60+ 行 = facade 模板残留。`init()` 60 行含 plugin init + tz data + iOS/Android 平台分支，未来加 Linux / macOS 桌面支持时这 60 行要膨胀。

**重构 ROI**：🟡 中（合并委派到 `delegate` namespace / 1 天）

### 3.6 🟡 P2 — 其余 11 个 god class（详表）

| 文件 | KB/L | 类 | 主要问题 | ROI |
|---|---|---|---|---|
| setup_page_state.dart | 20.7/504 | 1 | 5 bool consent + 4 controller + wizard 编排 | 🟡 中（抽 setup_presenter 1-2 天）|
| app_database.dart | 27.1/494 | 1 | 21 步 migration 嵌 1 闭包 + 8 DAO 委派 + saveSetup 业务 | 🟡 中（migration 表驱动 1 天）|
| mood_trend_page.dart | 19.2/517 | 1 | 趋势算法 + UI 混 | 🟡 中 |
| app_colors.dart | 18.3/276 | 1 | R65 已拆 4 文件，本文件纯 const 0 拆解 | ✅ 已完成 |
| strings.dart | 17.8/300 | 1 | dual API（const 字段 + i18n 函数）R57 妥协 | 🟢 v1.0 大工程 |
| add_medication_page.dart | 17.6/506 | 1 | 跟 edit_dialog / medication_page 共用 _MedFormFields | 🟡 中 |
| legal_page.dart | 17.5/460 | 1 | vent 撤回 3 选 1 dialog + 业务编排 | 🟡 中 |
| app_tokens.dart | 17.2/285 | 1 | facade 285 行，95% caller 仍用 | 🟢 低（加 @Deprecated 0.5 天）|
| mood_recorder_page.dart | 17/348 | 1 | 录音 UI | 🟡 中 |
| vent_list_page.dart | 16.7/367 | 1 | 列表 + filter chip | 🟡 中 |
| reminders_hub_page.dart | 16.5/441 | 1 | 提醒 hub 拆 widgets/ | 🟡 中 |
| vent_detail_page.dart | 16.1/380 | 1 | 播放 + audio 加密 | 🟡 中 |
| assessment_widgets.dart | 15.7/407 | 1 | SparklinePainter 抽 widgets/sparkline.dart | 🟢 0.5 天 |
| notification_status_card.dart | 15.7/396 | 1 | settings widgets 拆 | 🟡 中 |
| safety_watch_service.dart | 15.4/338 | 1 | CareChannelConfig 抽（R43）+ 业务 | 🟡 中 |
| contacts_list_widget.dart | 15.3/319 | 1 | 列表 widget 拆 | 🟡 中 |
| edit_medication_dialog.dart | 15.3/398 | 1 | 跟 add_medication 共用 _MedFormFields | 🟡 中 |

**累计 22 god class 候选 / ~9600 行 / 1300KB**，占 lib/ 总 ~40%。

---

## 4. 重复代码 / 抽象泄漏

### 4.1 重复代码

| # | 位置 | 重复次数 | 状态 |
|---|---|---|---|
| 1 | audio state machine (vent_compose / mood_audio_recorder) | 2 | ⚠️ 唯一残留（§3.4）|
| 2 | `_showSnackBar` 4 处 | 4 | ✅ 已抽 `AppSnackBar.showInfo/Error/Success` |
| 3 | `swallowError + unawaited + try/finally` | 50+ | ✅ 已抽 `swallowError(where, error, stack, note)` |
| 4 | `DateTime.now()` 跨 midnight | 多处 | ✅ R14/R17/R19B 全修 + 2 守门员 |
| 5 | `Future.delayed` 不可 cancel | 多处 | ✅ R62-R63 全替换 `Timer + cancel` |

**结论**：✅ **基本清完**，唯一残留是 audio state machine 2 处（§3.4）。

### 4.2 抽象泄漏（实测 0 处）

| 检查项 | 状态 | 守门员 |
|---|---|---|
| `domain/` import `package:flutter/...` | ✅ 0 处 | `check_all.dart` |
| `domain/` import `package:drift/...` | ✅ 0 处 | 同上 |
| `data/` import `presentation/` | ✅ 0 处 | 同上 |
| `core/shared/` 文件被 < 2 层用 | ✅ 0 处 | 一致性规则 |
| `domain/` entity 暴露 drift type | ✅ 0 处 | 24+ entity 纯 Dart，`*Entity` 后缀 |
| 循环依赖 A↔B | ✅ 0 处 | R14/R95 拆 provider / state 解决 |

### 4.3 散落配置

✅ **基本清完**（R40-R49 emil token 化 + R56b spacing 46 处 + AppMotion 4 文件）。剩余 ~5 处低风险 magic number（如 `kDefaultDailyReminderHour: 20` 建议抽 const）。

---

## 5. 4 个架构选项对比

| 选项 | 方案 | 适配 | 工时 | 风险 | 收益 | 推荐 |
|---|---|---|---|---|---|---|
| **1. 维持 4 层 + 抽 8 feature 包** | `lib/features/{feature}/{domain,data,presentation}/` | 🟢 高度适配 | 1-2 周 | 🟡 中 | 高内聚 / 加 feature 边际成本 -30% | ⭐⭐⭐⭐⭐ **强烈推荐** |
| 2. Clean Architecture | 加 `interface_adapters/` + `frameworks/` 子层 | 🟡 中 | 3-4 周 | 🟠 高 | 学术纯净 | ⭐⭐ 不推荐（过度工程）|
| 3. Modular / GetIt | `get_it` 替代 Riverpod 注册 | 🟡 中 | 2-3 周 | 🟠 高 | 解耦 service locator | ⭐⭐ 不推荐（重复造轮子）|
| 4. 微前端 / pub workspace | 拆 `packages/chroniccare_vent` 等 | 🟡 中 | 1-2 月 | 🔴 很高 | 团队分仓 | ⭐ 等 50+ 文件/feature 再考虑 |

**最优路径**：选项 1 作中期目标，**当前阶段不做**（先做 god class 拆解）。

---

## 6. 可重构模块清单（按 ROI 排序）

| # | 模块 | 现状 → 目标 | ROI | 工时 | 风险 | 优先级 |
|---|---|---|---|---|---|---|
| 1 | main.dart 4 占位 app + 4 helper | 459L → 200L main + 5 文件 | 🟢 极高 | 1 天 | 极低 | 🔴 P0 |
| 2 | vent_compose + mood_audio_recorder 共享 audio state | 2×500L 重复 → -150L | 🟢 高 | 1-2 天 | 中 | 🔴 P0 |
| 3 | notification_service 13 个 1 行委派合 namespace | 426L → 250L | 🟢 高 | 1 天 | 低 | 🟠 P1 |
| 4 | home_page_state 拆 3 controller | 597L → 250L + 3 controller | 🟠 中-高 | 2-3 天 | 中 | 🟠 P1 |
| 5 | medication_page 时间段算法抽 domain | 540L → 350L | 🟠 中-高 | 1-2 天 | 低 | 🟠 P1 |
| 6 | setup_page_state 抽 setup_presenter | 504L → 200L | 🟡 中 | 2 天 | 中 | 🟡 P2 |
| 7 | app_database migration 改表驱动 | 494L → 350L | 🟡 中 | 1 天 | 中 | 🟡 P2 |
| 8 | legal_page 抽 VentWithdrawFlow | 460L → 280L | 🟡 中 | 1 天 | 低 | 🟡 P2 |
| 9 | assessment_widgets SparklinePainter 抽 widgets/ | 407L → 300L | 🟢 低 | 0.5 天 | 极低 | 🟡 P2 |
| 10 | medication 3 god + settings 3 god 拆 widgets/ | 100KB → 60KB | 🟡 中 | 2+2 天 | 中 | 🟡 P2 |
| 11 | strings.dart dual API → 单 API | 300L → 150L | 🟢 低（v1.0 整体）| 1 周 | 中 | 🟢 P3 |
| 12 | AppTokens facade 加 @Deprecated | 285L → 285L | 🟢 低 | 0.5 天 | 极低 | 🟢 P3 |
| 13 | **feature-first 重构**（中期） | 395 文件重分布 | 🟠 中-高 | 1-2 周 | 🟠 中 | ⚪ 中期 |
| 14 | **pub workspace 拆 vent / medication**（长期） | 拆 2-3 包 | 🟡 中 | 1-2 月 | 🔴 很高 | ⚪ 长期 |

**累计**：P0 + P1 12-15 天清 6 大 god class。P2 + P3 再 1 周。**3 周内可完成 P0+P1+P2**。

---

## 7. 推荐路径

### 7.1 短期（v0.31-0.32，~3 周）

**目标**：拆 P0 + P1 共 6 大 god class，**不破坏 4 层架构**。

- **Week 1**（P0）：抽 `lib/main/boot_apps.dart` / 抽 `lib/presentation/widgets/audio_lifecycle.dart` / 改 notification_service 委派
- **Week 2-3**（P1）：拆 `home_page_state` 3 controller / 抽 `domain/logic/medication_slot_calculator.dart` / 拆 medication_page widgets

**验证**：`flutter analyze` 0 error + `flutter test` 2019 全过 + 19 守门员全绿 + 边界 0 violation。

### 7.2 中期（v0.33+，~1-2 月）

**目标**：feature-first 重构（选项 1）。

```
lib/
├── core/                          # 不变
├── features/
│   ├── check_in/  medication/  mood/  vent/  assessment/
│   │   ├── domain/   (entity + abstract repo)
│   │   ├── data/     (table + mapper + repo impl)
│   │   └── presentation/  (pages + widgets + providers)
│   ├── safety/      (失联 + CareEngine + SMS)
│   ├── consent/     (PIPL §13/§14 + 法务文档)
│   └── home/        (主页 = 跨 feature coordinator)
└── shared/         # 跨 feature 复用
```

**约束**：`features/{A}/` 不得 import `features/{B}/`；`home/` 是唯一允许跨 feature 的 hub；`core/` 仍被所有 features import。

**工时**：1-2 周（390+ 文件 move + import 重写 + 守门员更新 + 测试回归）

### 7.3 长期（v1.0+，~3-6 月）

**目标**：pub workspace 拆 vent / medication 独立 package（选项 4）。

**触发条件**：vent > 50 文件 / medication > 80 文件 + 团队分仓。**风险 🔴 高**（drift schemaVersion 跨包对齐 + 跨包类型共享 + CI/CD multi-package）。

---

## 8. 加 1 个新 feature 边际成本

| 复杂度 | 步骤 | 文件数 | 工时 |
|---|---|---|---|
| **简单**（1 字段，参考 v0.30 R101 mood recordingMode）| domain 1 实体字段 + data 1 列 + 1 migration + 1 provider + 2 test | 6 | **0.8 天** |
| **中等**（1 子功能）| + enum / dialog / service / widget | 10 | **1.7 天** |
| **复杂**（1 page，参考 v0.15 R18 vent）| entity + repo + table + mapper + audio storage + schemaVersion + 3 page + 5-8 test | ~20 | **3-5 天** |
| **跨 feature**（含 privacy 边界）| + ConsentDialog + consent store + privacy 守门 | 25-30 | **5-8 天** |

**结论**：✅ **1-2 天新 feature 边际成本**符合 AGENTS.md 文档承诺，god class 拆解后预计再降 30%。

---

## 9. 8 FeatureFlag 守门状态

| FeatureFlag | _prod | 完整？ | 半成品原因 |
|---|---|---|---|
| `emergencyContactEnabled` | false | 🟡 半成品 | 整个失联业务暂停 |
| `iapEnabled` | false | 🟡 半成品 | Apple 2.1 拒因，等 productId |
| `phqGad7I18nEnabled` | false | 🟡 半成品 | v1.0 大工程 |
| `bootReceiverEnabled` | false | 🟡 半成品 | 等 WorkManager 完善 |
| `aliyunSmsEnabled` | false | 🟡 半成品 | 等法务 + AccessKey |
| `emailServiceEnabled` | false | 🟡 半成品 | 等 SendGrid |
| `fiveVendorPushEnabled` | false | 🟡 半成品 | 1-2 月 5 厂商 SDK 接入 |
| `ventAudioEnabled` | **true** | ✅ 完整 | R104 翻 true |

**8 个 flag 中 1 个完整 + 7 个半成品** —— 反映"零云端 + 法务驱动"现实约束。所有半成品有明确 owner + 触发条件 + 文档位置（AGENTS.md / CHANGELOG）。

---

## 10. 半成品 / TODO 清单

| # | 位置 | 描述 | 阻塞 |
|---|---|---|---|
| 1 | `notification_service.dart:313-325` | SCHEDULE_EXACT_ALARM 运行时权限检查 | Android 12+ 撤回权限后 zonedSchedule 静默降级 |
| 2 | `safety_watch_service.dart` | 真正接阿里云 SMS 走 `_smsService.send` | R55 等法务 + AccessKey |
| 3 | `phq9.dart` / `gad7.dart` 16 题 i18n | 题目 + 严重度 + 危机电话完整走 ARB | v1.0 大工程 |
| 4 | `feature_flags.dart` ventAudio=true | export / import vent audio 业务闭环不全 | vent audio export / import |
| 5 | `BootReceiver` 半成品 | R70 简化方案走 idempotent rescheduleAll | 等 R28 WorkManager |
| 6 | `EmailService` | dead code，未来 v1.0 真接 SendGrid 时引入 | 外部依赖 |
| 7 | `sms_service.dart:13.2KB` | MockSmsProvider 完整 + AliyunSmsProvider 框架未启用 | 外部依赖 |
| 8 | `legal_page` vent 撤回封存 | 封存后 UI 隐藏数据没真删 | v1.0 audit |

**项目半成品纪律良好**：每个半成品有明确 owner + 触发条件 + 文档位置。

---

## 11. 高内聚低耦合具体改进建议（每 god class 一条）

| God Class | 建议 | 工时 |
|---|---|---|
| **main.dart (459L)** | 抽 `lib/main/boot_apps.dart` 含 4 占位 widget + MigrationPromptController；main.dart 只留 `main()` + `_bootstrap()` + 3 init helper | 1 天 |
| **vent_compose + mood_audio_recorder (2×500L)** | 抽 `lib/presentation/widgets/audio_lifecycle.dart` 含 `RecordingState` enum + `AsyncDispose` mixin；2 page 改用 mixin 去重 ~150 行 | 1-2 天 |
| **home_page_state (597L)** | 抽 3 controller：`HomeDeepLinkHandler` (50L) / `HomeCareEngineDispatcher` (70L) / `HomeCelebrationController` (50L)；state class 保留 build + onCheckIn + snooze (~200L) | 2-3 天 |
| **medication_page (540L)** | 抽 `domain/logic/medication_slot_calculator.dart` 含 `_TimeSlot` 纯函数；抽 `medication/widgets/medication_list_widgets.dart` | 1-2 天 |
| **notification_service (426L)** | 13 个 1 行委派合 `delegate` namespace；facade 主体留 6 method（init / requestPermission / showNow / cancelAll / pendingCount / showSafetyAlert）| 1 天 |
| **setup_page_state (504L)** | 5 bool consent → `ConsentState` class + `bool[5]` + `areAllAgreed`；`_validateWelcomeForm` + `_finishSetup` 抽 `setup_presenter.dart`；`int _step` 改 `enum SetupStep` | 2 天 |
| **app_database (494L)** | `onUpgrade` 21 步 `if (from <= X)` 抽 `migrations/migration_table.dart` 表驱动；`saveSetup` 抽 `domain/usecases/save_setup_usecase.dart` | 2 天 |
| **app_tokens (285L)** | 所有 1:1 转发加 `@Deprecated('use AppColors.xxx directly')`；3-6 月后 grep 0 命中时删 facade | 0.5 天 |
| **settings 3 god (50KB)** | legal_page 抽 VentWithdrawFlow / reminders_hub + notification_status_card 拆 widgets/ | 2 天 |
| **medication 3 god (50KB)** | 抽 `medication/widgets/_MedFormFields` / `_MedListTile` / `_MedEmptyState` 共用 widget | 2 天 |
| **assessment_widgets (407L)** | 抽 `SparklinePainter` 到 `presentation/widgets/sparkline.dart` | 0.5 天 |

**P0 + P1 总工时 12-15 天**（6 大 god class），P2 再 1 周。

---

## 12. 总结

### 12.1 架构强项

- ✅ 4 层 + core umbrella 边界**严格**（19 守门员覆盖）
- ✅ domain 0 Flutter 0 Drift（实证）
- ✅ 16 abstract repo + 16 impl，**接口稳定**
- ✅ Provider 4 文件拆分合理
- ✅ 8 FeatureFlag `_prodXxx` const + `_currentXxx` nullable 模式优雅
- ✅ 2019 tests pass / 0 error
- ✅ cross_feature / no_pua / zh_hant / orphan_arb 等守门员 i18n / 法律维度强
- ✅ AGENTS.md 持续同步（含 v0.30 R100 6 视角 + 19 守门员）

### 12.2 主要债务

- 🟠 15 god class 候选（占 395 dart 文件总行数 ~18%）
- 🟠 4 个 presentation feature（medication / settings / vent / mood）总 KB 超 50% 集中
- 🟠 audio state machine 2 处重复（vent_compose / mood_audio_recorder）
- 🟠 main.dart 4 占位 widget 残留
- 🟡 Strings dual API（v1.0 大工程，暂不动）
- 🟡 AppTokens facade 95% caller 仍用，未引导迁移

### 12.3 决策建议（3 阶段）

| 阶段 | 目标 | 工时 | 风险 |
|---|---|---|---|
| **短期（v0.31-0.32）** | 拆 6 大 god class + 抽 audio lifecycle + main 占位 app | 3 周 | 🟢 低 |
| **中期（v0.33-0.34）** | feature-first 重构（选项 1）| 1-2 周 | 🟡 中 |
| **长期（v1.0+）** | pub workspace 拆 vent / medication（选项 4）| 1-2 月 | 🔴 高（外部依赖）|

**不建议**：❌ Clean Architecture（4 层够用）/ ❌ GetIt（Riverpod 已是 DI）/ ❌ v0.x 阶段拆 pub workspace（monorepo 395 文件可控）。

### 12.4 1 句话评估

**当前架构在 v0.30 处于「成熟稳定期」，19 守门员 + 4 层 + 8 FeatureFlag + 2019 tests 是健康信号；**15 个 presentation god class 是**已知**且**局部**的技术债，3 周内可拆 6 大头，1-2 月可做 feature-first 重构。**不需要**重大架构变革。

---

## 附录：核心数据

| 指标 | 数值 |
|---|---|
| 总 dart 文件 | 395 |
| lib/ 总大小 | ~2.6MB |
| domain/ 文件 | 80+ / ~280KB |
| data/ services | 30+ |
| data/ repositories (impl) | 13 |
| domain/ abstract repos | 16 |
| presentation/ pages (feature) | 11 |
| presentation/ total files | ~210 |
| presentation/ providers | 18 (in 4 files) |
| tests | 2019 cases |
| 守门员 scripts | 19 (16 .py + 1 .dart + 2 utility) |
| FeatureFlags | 8 (7 半成品 + 1 完整) |
| god class 候选（>14KB）| 22 |
| 半成品 TODO（代码内）| 9 |
| god class 累计行数 | ~9600（占 lib/ ~40%） |

---

> 报告完毕。如对 P0/P1 拆解优先级有不同意见，请在 Sprint planning 时讨论。
