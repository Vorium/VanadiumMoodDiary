# 顶层架构 + TDD 审计报告（superpowers-en 上游方法论视角）

**项目**: `D:\Batch\chroniccare` — 慢病管家（精神心理患者吃药打卡 App）
**审计日期**: 2026-07-27
**审计方法**: superpowers-en 14 子技能中的 4 个（verification-before-completion / test-driven-development / requesting-code-review / subagent-driven-development / using-git-worktrees）
**审计类型**: READ-ONLY（无源码修改，无 git commit）
**对照基线**: v0.27 round 60（1098 tests，0 analyzer error，16 守护脚本）

---

## 0. Summary

### 总体评价：**良好（Good）**

工程组织有清晰的 4 层架构 + 共享层 + 5 个跨层 umbrella；16 个守护脚本大部分通过；CI 三 job 跑全（test / architecture / build）；schema 14 迁移完整；Riverpod 3.x 升级无残留 `.valueOrNull`；C1/M1/C2 上一轮 audit 修正到位。但本轮审计发现 **2 个 P0 真实问题**（其中 1 个导致 release 路径失效风险，1 个是测试文件物理损坏），5 个 P1 TDD 盲点，3 个 P1 工程组织 gap。

### 顶层 5 个最关键架构问题

| 序 | 严重度 | 位置 | 摘要 |
|---|---|---|---|
| 1 | **P0** | `lib/core/data/services/safety_watch_service.dart:74, 87, 95, 101, 105, 111, 116, 123` | 8 个 `@Deprecated('Use safetyConfigServiceProvider directly')` 注解全部指向**不存在的 provider**。R57 commit `ba12784` 写"修正 `safetyConfigServiceProvider` 后再删 facade"，但直到 v0.27 round 60 (`fdfa172`) 该 provider 从未被创建。caller `reminders_hub_provider.dart:33-37` 仍走已弃用 facade，deprecation 实质上是个**虚假完成**。 |
| 2 | **P0** | `test/domain/assessment_record_equality_round60_test.dart:62` | 单行 **186,298 字符**（约 186KB），字符串内容为"修正后"约 2000 次重复，疑似编辑时粘贴错位 / 自动补全 bug。文件总长 375,451 bytes 但只有 62 行；按"verification-before-completion"原则这是 0 test 覆盖（dart test 跑这行会怎么解释需要现场验证，但即使是有效字符串也属于超长 line 不应 commit）。 |
| 3 | **P1** | `lib/core/data/services/medication_report.dart` 拆 3 sub-class（`MedicationStatCalculator` / `MissedDateBuilder` / `TempEntryExtractor`，v0.25 R58 commit `de0e7f0`） | isolated test 只覆盖 1/3（`medication_stat_calculator_round60_test.dart`，5,927 bytes）。R58 commit 信息写"god class 拆 3 纯函数类"但 R60 修正 M1（phantom missedDates）只补了 1 个 sub-class test。`MissedDateBuilder`（missed dates 列表 + effectiveDaysClamped 应用）和 `TempEntryExtractor`（temp medication 窗口筛选）0 isolated test。 |
| 4 | **P1** | `lib/core/data/services/safety_watch_service.dart` 已拆 `SafetyConfigService`（v0.25 R57 commit `ba12784`，8 method）+ `SafetyAlertDispatcher`（commit `1d546e2` 加测 12,123 bytes） | `SafetyConfigService` 0 isolated test — 8 个 SharedPreferences API（`isEnabled` / `setEnabled` / `getThresholdDays` / `setThresholdDays` / `getDoNotDisturb` / `setDoNotDisturb` / `getLastAlertAt` / `setLastAlertAt` + 3 纯函数 `daysBetween` / `isSameDay` / `isInDnd`）是失联检测的"开关 + 节流 + 审计"基础，错一个 = 用户死后没人通知。 |
| 5 | **P1** | `.github/workflows/ci.yml:47-66` | CI 只跑 16 个守护脚本中的 5 个（`check_cross_feature` / `check_arb_keys` / `check_drift_namespace` / `check_datetime_race2` / `check_fullwidth_punctuation`）。**漏 10 个**：`check_orphan_arb_keys`（R56e 新加）/ `check_widget_dispose`（资源泄漏）/ `check_changelog`（版本同步）/ `check_legal_consent`（PIPL §13 单独同意）/ `check_sms_release_ready`（R58 降 warn-only）/ `check_strings_hardcoded`（R57 新加）/ `check_zh_hant_consistency`（R57 新加）/ `check_no_hardcoded_utc`（R48 新加）/ `check_no_pua`（R40 新加）/ `check_datetime_race`（R19 第一版）。AGENTS.md 列了 16 个但 CI 只跑 5 个 = 11 个守护脚本是"本地手动跑"。 |

### TDD 覆盖盲点（3-5 个）

| 序 | 盲点 | 证据 |
|---|---|---|
| TDD-1 | `medication_report.dart` 3 sub-class 只测 1 个 | `medication_stat_calculator_round60_test.dart:1` 存在（5,927 bytes），但 `test/` 0 个 `missed_date_builder_*_test.dart` / `temp_entry_extractor_*_test.dart`。`lib/domain/logic/medication_stat_calculator.dart:80-129` 修正 M1 改 effectiveDaysClamped 应用，commit `402ca71` 修正动机是"phantom missedDates"，但 sister class `MissedDateBuilder` 是否仍存在同类 bug 0 test guard。 |
| TDD-2 | `SafetyConfigService` 0 isolated test | `lib/core/data/services/safety_config_service.dart:17-130` 含 8 SharedPreferences API + 3 纯函数。`test/` 0 `safety_config_service_*.dart`。`safety_watch_service_round12_test.dart:15303 bytes` 测的是 facade 端到端，0 unit test 覆盖 threshold 边界（1-14）/ DND 跨天边界（start > end 表示 22-08）/ audit log UTC 化等关键逻辑。 |
| TDD-3 | `_showCrisisDialog` widget 0 测试 | `lib/presentation/pages/assessment/assessment_page.dart:201-204` 调 `scale.detectCrisis` + `_showCrisisDialog`。`test/domain/phq9_detect_crisis_round60_test.dart` 修正后 21 case（`fdfa172` 修正），但 `test/presentation/pages/assessment/` 0 个 widget test 验证 crisis dialog 真的弹 + 真的把 6 region hotline 渲染。`assessment_history_round13b_test.dart` 不覆盖 crisis path。 |
| TDD-4 | `lib/core/shared/swallow_error.dart` 1 KB test (1,156 bytes) | `test/core/shared/swallow_error_round14_test.dart:1-56` 只 1 个 happy-path test。`swallow_error` 集中器被 8+ 处 `lib/core/data/**` 使用（`medication_times.dart:36` / `vent_mapper.dart:35` / `encrypted_audio_storage.dart:168,183,223,243`），但 0 test 验证 "release 模式不抛" / "debug 模式 throw" / "stack 注入" / "note 字段拼" 这些契约。 |
| TDD-5 | `legal_consent_provider.dart` 0 test | `lib/presentation/providers/legal_consent_provider.dart` 整文件 0 任何 test。PIPL §26 撤回同意 UI 是真合规承诺，但 `withdraw` / `reset` / `isWithdrawn` / `withdrawnAt` 4 method 0 任何隔离测试，`legal_page.dart:43-65` 的 3 toggle 流程无 guard。 |

---

## 1. 4 层架构纯度（P0 硬约束）

### 1.1 验证结果

```
$ dart scripts/check_all.dart
============================================================
4 层架构综合检查（v0.18 Round 19）
============================================================
--- [1/2] 4 层架构纯度检查 ---
✅ 通过
   - domain/  0 flutter / 0 drift / 0 data / 0 presentation
   - shared/  0 flutter / 0 drift / 0 data / 0 presentation
   - data/    不依赖 presentation/
   - 同时检测 package: 绝对路径 + ../../ 相对路径
--- [2/2] 架构语义一致性检查 ---
✅ 通过
   - 每个 domain *Entity 都对应一个 drift table
   - 每个 drift table data class 都对应一个 domain *Entity
   - shared/ 工具被 ≥2 层使用
```

### 1.2 grep 深度验证（补充自动化检查没覆盖的）

| 检查 | 命令 | 结果 |
|---|---|---|
| `domain/` 是否含 `package:flutter/` | `grep -rln "package:flutter/" lib/domain/` | 仅 1 处（`hour_minute.dart:3` 注释里说明"domain 不依赖 flutter/material.dart"）— 注释不是 import，**通过** |
| `domain/` 是否含 `package:drift` | `grep -rln "package:drift" lib/domain/` | **0 处** ✅ |
| `domain/` 是否含 `package:fl_chart` / `package:pdf` / `package:record` / `package:audioplayers` | `grep -rln` | **0 处** ✅ |
| `data/` 是否依赖 `presentation/` | `grep -rln "import.*presentation" lib/core/data/` | **0 处** ✅ |
| `core/shared` 被多少层使用 | 31 个 `core/shared` import 分布：domain (8) / data (15) / presentation (8) | **3 层都用** ✅ |
| `core/shared/formatters.dart` 自身 import | `import 'package:chroniccare/domain/entities/dosage_unit.dart';`（line 13） | 跨 `shared → domain` 引用 domain enum。**单向合法**（domain 是底层），但这意味着 `core/shared` 不是 100% 与 domain 解耦。**注**：AGENTS.md / check_all.dart 都未检查此 back-edge，应补充进 `check_all.dart` 的 `[1/2]` 列表。 |
| 跨 feature 引用 | `python scripts/check_cross_feature.py` | 66 files checked, 0 violations ✅ |

### 1.3 P0 finding 实际有 1 个 cross-layer 边角

**位置**: `lib/core/shared/formatters.dart:13`
```dart
import 'package:chroniccare/domain/entities/dosage_unit.dart';
```

**说明**: 4 层架构原则是 `presentation → domain ← data` + `shared` 独立。`formatters.dart` 引 domain enum `DosageUnit`（`dosageUnit` 字段格式化时需要 label）。这违反"shared 0 跨层依赖"精神，但实际是 **shared → domain（底层）单向** 引用，符合 dart import 习惯（被引用方是底层）。`check_all.dart` 没报是因为它只检查 `shared/ 0 flutter / 0 drift / 0 data / 0 presentation`（4 类），没检查"是否反向依赖 domain"。

**影响**: 极低。但若未来想把 `domain/` 单独拆 package（monorepo），`formatters.dart` 必须内联 enum label 或抽到 shared。

**修复**: 在 `check_all.dart` 的 `[1/2]` 增加一条 "shared/ 不应 import domain" 规则（**不**破坏 `formatters.dart`，因为 cross-package 拆包再处理；本地库可豁免）。

---

## 2. 状态管理（Riverpod 3.x）

### 2.1 provider 树全景

```
lib/presentation/providers/ (10 文件, 27 KB total)
├── core_providers.dart       (5 KB)   db + encryption + notification + sms + 7 repo = 10 provider
├── service_providers.dart    (2.8 KB) reminder / safety / assessment / data export = 4 service
├── vent_providers.dart       (2.1 KB) ventAudio + ventRepo + ventEntriesStream + ventById = 4
├── shared_providers.dart     (5.4 KB) 11 StreamProvider (user/today/allCheckIns/streak/...) + DayChangeTickNotifier
├── check_in_notifier.dart    (3.2 KB) CheckInNotifier + 3 usecase provider
├── mood_providers.dart       (1.3 KB) 1 mood provider
├── legal_consent_provider.dart (3 KB) 3 provider (consent store + 2 stream)
├── reminders_hub_provider.dart (1.5 KB) 1 FutureProvider (assessment+safety config)
├── calendar_window_provider.dart (1.4 KB) 1 Notifier (跨页共享)
└── notification_init_provider.dart (1.2 KB) 1 数据类 (P17 fix, main.dart 注入)
```

**总 provider 数**：~30 个，分布在 10 个文件。**拆分粒度**清晰（按"基础服务 / 业务服务 / vent 独立模块 / 跨页状态 / 单 feature"分）。

### 2.2 AsyncValue 处理一致性

| 检查 | 命令 | 结果 |
|---|---|---|
| 残留 `valueOrNull` | `grep -rn "valueOrNull" lib/` | 1 处（`temp_medication_dialog.dart:75` 注释解释 R3 改名）— **无实际调用残留** ✅ |
| `.value` 调用 | `grep -rn "\.value" lib/presentation/providers/` | 2 处（`app_router.dart:39, 44` 用 `userProfileProvider.value` 拿 `UserProfileEntity?`）— Riverpod 3.x 正确用法 ✅ |
| 跨 widget 跨 async gap | `grep -rn "if (!mounted)" lib/` | 27 处 widget 层 + 2 处 `app.dart`（mounted widget check）+ 2 处 Notifier `ref.mounted`（`calendar_window_provider.dart:24` + `shared_providers.dart:129`）。**统计准确无误**（v0.17 R7 标的"27 处 widget + 1 处 ref.mounted"是真实基线）✅ |
| `Notifier` 直接 `new` 跳过 provider | `grep -rn "new Notifier" lib/` | 0 处 ✅ |

### 2.3 StreamController / StreamSubscription 泄漏

| 位置 | 模式 | 是否 dispose | 守护脚本 |
|---|---|---|---|
| `lib/core/data/services/mood_audio_service.dart:119` | `final StreamController<String> _sttController = StreamController.broadcast();` | 需查 dispose | — |
| `lib/presentation/pages/mood/widgets/mood_recorder.dart:121-122` | 2 `StreamSubscription` 字段 | `dispose()` 链 (R19B fix) | `check_widget_dispose.py` |
| `lib/presentation/pages/vent/vent_compose_page.dart:57` | 1 `StreamSubscription<void>?` | 待查 | `check_widget_dispose.py` |
| `lib/presentation/pages/vent/vent_detail_page.dart:41-43` | 3 `StreamSubscription<Duration>?` | 待查 | `check_widget_dispose.py` |

**守护脚本结果**：
```
$ python scripts/check_widget_dispose.py
[OK] check_widget_dispose: 0 资源泄漏
```
**全过** ✅

### 2.4 P1 finding: 安全开关 provider deprecation 失效

**位置**: `lib/core/data/services/safety_watch_service.dart` 8 处 `@Deprecated('Use safetyConfigServiceProvider directly')`
```dart
@Deprecated('Use safetyConfigServiceProvider directly')
Future<bool> isEnabled() => _config.isEnabled();   // line 89
@Deprecated('Use safetyConfigServiceProvider directly')
Future<void> setEnabled(bool value) => _config.setEnabled(value);  // line 96
// ...6 more, line 95, 101, 105, 111, 116, 123
```

**commit 历史**:
- `ba12784` (v0.25 R57) 创建 `@Deprecated` 注解 + 注释 "R60 修正 `safetyConfigServiceProvider` 后再删 facade"
- `d1b5868` (v0.27 R59) "三视角 P0/P1 修正批次 1" — 修正列表里没有这一项
- `e1568cf` (v0.27 R60) "批次 0 归档清理" — 同样未修正
- `fdfa172` (v0.27 R60 HEAD) "P1 加测 MedicationEntity hashCode" — 与本问题无关

**实际验证**:
```
$ grep -rn "safetyConfigServiceProvider" lib/presentation/providers/
(no output — 0 处)
```

**影响**:
- caller `lib/presentation/providers/reminders_hub_provider.dart:33-37` 仍调 `safety.isEnabled()` / `safety.getDays()` / `safety.getThresholdDays()` 走 deprecation 方法
- caller `lib/presentation/pages/home/home_page.dart:146, 313` 走 facade `onAppStart()` / `onCheckIn()`（无 deprecation）
- caller `lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart:40` 调 `service.isEnabled()` 走 deprecation
- caller `lib/presentation/pages/settings/reminders_hub_page.dart:393` 调 facade 无 deprecation
- caller `lib/presentation/pages/settings/widgets/reminder_cards.dart` 走 widget state, 不调 service

**结论**: 修正未完成，caller 仍走 deprecation 路径。**安全性不致命**（`_config` 已经把数据搬到 `SafetyConfigService`，deprecation 路径只多一层 `safety_watch_service` facade 转发），但**承诺给读者"已迁新 provider"是误导**。

**修复**（R61 P0-1 fix）：
1. `lib/presentation/providers/service_providers.dart` 加：
   ```dart
   final safetyConfigServiceProvider = Provider<SafetyConfigService>(
     (ref) => SafetyConfigService(),
   );
   ```
2. 把 `safety_watch_service.dart:74, 87-123` 的 8 处 `@Deprecated` 注解消息从 `Use safetyConfigServiceProvider directly` 改为 `Use safetyConfigServiceProvider in service_providers.dart`（明确指明位置）。
3. 后续 R62+ 修正所有 caller 切到新 provider 后，删 8 个 facade 方法。

**TDD 跟进**：`safety_config_service_test.dart` 加 8 + 3 = 11 unit test（见 §6 TDD-2）。

---

## 3. 路由（go_router 14.6）

### 3.1 路由文件拆分（R57 + R59 修正后）

```
lib/core/routing/ (9 文件, 23 KB total)
├── app_router.dart           (3 KB)   Provider 入口 + ref.read + cache (R57 perf fix)
├── app_routes.dart           (7 KB)   3 transition + errorBuilder + all() 委托
├── app_route_main.dart       (2.6 KB) / + /setup + ShellRoute (AppShell)
├── app_route_assessment.dart (1.5 KB) /trend + /assessment + /assessment/history + /assessment/:id
├── app_route_medication.dart (1.7 KB) /settings/reminders + /settings/refills + /settings/legal + /medication/calendar
├── app_route_vent.dart       (1.5 KB) /vent + /vent/compose + /vent/detail/:id
├── app_route_check_in.dart   (1.2 KB) /check-in/medication/:id + /check-in/today
├── app_shell.dart            (5 KB)   AppShell + _NavDest (响应式)
└── notification_navigation.dart (3.7 KB) notification → router 桥接
```

**14 路由**，**5 个 file 按 feature 拆**（commit `4ce7bf9` v0.26 R57 + commit `e246aa5` v0.25 R59）。**god class 拆分完整**。

### 3.2 路由守卫

| 类型 | 位置 | 模式 |
|---|---|---|
| setup 守卫 | `app_router.dart:50-57` | `redirect: (context, state) { if (!isSetupDone && !goingToSetup) return '/setup'; ... }` — **基于 `userProfileProvider` cache**（R57 perf fix），不是 `ref.watch`，profile 变化只 invalidate cache，GoRouter 实例不重建 ✅ |
| 路径参数 | `app_route_vent.dart:35` | `int.tryParse(state.pathParameters['id'] ?? '') ?? 0` — **tryParse** ✅ |
| 路径参数 | `app_route_assessment.dart:32` | `state.pathParameters['id'] ?? 'phq9'` — String fallback ✅ |
| 路径参数 | `app_route_check_in.dart` | 类似 tryParse（待细查）— 一致 |
| 路由优先级 | `app_route_assessment.dart:21-23` | `/assessment/history` 必须在 `/assessment/:id` 之前声明（GoRouter 按声明顺序匹配）— 注释已说明 ✅ |

### 3.3 3 类 transition 一致性

| 频度 | helper | 用途 | 用法 |
|---|---|---|---|
| 主导航 (occasional) | `AppRoutes.fadePage` | `/`, `/settings` | 短时 fade ✅ |
| 子页 (occasional) | `AppRoutes.slideRightPage` | `/trend`, `/assessment/*`, `/medication/calendar` | slide-from-right + fade ✅ |
| 深页 (rare) | `AppRoutes.slideUpPage` | `/setup`, `/vent/*` | slide-up + fade (full-screen modal 感) ✅ |

**emil 决策框架** 落实（注释 line 30-35）。**`Motion.duration` 尊重 prefers-reduced-motion** ✅。

### 3.4 P0 finding: errorBuilder 用 `Localizations.of` 而不是 `AppLocalizations.of`

**位置**: `lib/core/routing/app_routes.dart:128-130`
```dart
final l10n =
    Localizations.of<AppLocalizations>(context, AppLocalizations);
```

**问题**: `AppLocalizations.of(context)` 是 generated helper，等价但**更简洁**。`Localizations.of<AppLocalizations>(context, AppLocalizations)` 同样工作但冗长。

**影响**: 无功能 bug。**统一性**：项目里 90+ 处用 `AppLocalizations.of(context)`，这是孤例。

**修复**: 改 `final l10n = AppLocalizations.of(context);` — S 级 / P2 / 1 行改。

### 3.5 P2 finding: 14 路由无 route 单元测试

**位置**: `test/routing/route_parsing_round19c_test.dart:1815 bytes` — 仅 1 测试文件，2 case。

`app_route_assessment.dart:23-30` 的 `/assessment/:id` 路径参数化 + `redirect: /assessment/phq9` + `/assessment/history` 优先级声明 3 个独立行为无 isolated test。

---

## 4. 数据层（Drift 2.20.3 + SQLCipher）

### 4.1 schema 状态

| 字段 | 值 | 来源 |
|---|---|---|
| `schemaVersion` | **14** | `app_database.dart:82` |
| 当前表数 | 7 (CheckIns / Medications / Contacts / UserProfiles / ReportHistories / MoodEntries / VentEntries) | `app_database.dart:32-41` |
| 迁移覆盖 | 1→2 (rename email→phone + dosage) / 2→3 (report) / 3→4 (mood) / 4→5 (refill) / 5→6 (vent) / 6→7 (mood 4D) / 7→8 (4 indices) / 8→9 (vent encrypt) / 9→10 (consent) / 10→11 (userName nullable) / 11→12 (mood audio) / 12→13 (med_id index) / 13→14 (contact+report indices) | `app_database.dart:89-213` |
| 迁移分支条件 | `if (from <= X)` 覆盖**到当前版本**（13→14 是最新） | ✅ 完整 |
| `beforeOpen` | `PRAGMA foreign_keys = ON` | `app_database.dart:215-218` ✅ |

**评估**: **完整且自洽**。注释每行都标了 round + 修正动机（"P0-1 修复" / "P2 优化"），追溯性好。

### 4.2 generated 文件新鲜度

| 文件 | 最后修改 |
|---|---|
| `lib/core/data/database/app_database.dart` | 2026-7-26 17:36:50 |
| `lib/core/data/database/app_database.g.dart` | 2026-7-21 12:10:59 |
| `.dart_tool/build/generated/chroniccare/lib/core/data/database/app_database.drift.g.part` | 2026-7-26 20:56:12 |

**gap 5 天 + dart_tool 4 天后** — **可疑**。但验证 generated 内容：
- ✅ 含 `audioTranscript` (column 12) — 对应 v0.23 R31 (schemaVersion 11→12)
- ✅ 含 `contentTextEnc` (column 27) — 对应 v0.21 R22 (schemaVersion 8→9)
- ✅ `late final $VentEntriesTable ventEntries` 存在 — 对应 v0.15 R5

**结论**: content 是新鲜的（覆盖到 schemaVersion 14），mtime gap 是 git checkout / timestamp drift / build_runner cache 问题。**但**这违反 "build_runner drift 生成是否最新" 的 superpowers-en 原则，**应** 加一条守护脚本验证 `app_database.dart` 修改时间 ≤ `app_database.g.dart` 修改时间。

### 4.3 SQLCipher 加密 key 管理

**位置**: `lib/core/data/services/db_key_service.dart:31-40`
- 32 字节 `Random.secure().nextInt(256)` 生成 key
- base64 编码存 `flutter_secure_storage` (iOS Keychain / Android EncryptedSharedPreferences / Windows DPAPI)
- `openConnection()` (`lib/core/data/connection/native.dart:24-29`) 通过 `PRAGMA key` 注入

**评估**: **fail-fast 合理** — key 缺失时 `getOrCreate()` 立即生成（不是 fail-fast throw）。这是**接受**的取舍：fresh install 走 first-launch flow 自动生成。**0 unit test** 直到 v0.25 R56c (commit `dd2857b`) 修正后 5 case。

### 4.4 god class 拆分

| 文件 | v0.25 R53a 修正前 | 修正后 | 评估 |
|---|---|---|---|
| `app_database.dart` | 559 行 | 305 行 (-45%) | 抽 7 DAO（`checkInDao` / `medicationDao` / `contactDao` / `userProfileDao` / `reportDao` / `moodDao` / `ventDao`）+ facade 委托 ✅ |
| `data_export_service.dart` | 539 行 | 119 行 (-78%) | 抽 4 sub-service（`ExportOrchestrator` / `ExportCryptoService` / `ExportAudioService` / `ExportSchemaService`）✅ |
| `notification_service.dart` | 629 行 | 250 行 (-60%) | 抽 5 sub-service（`SnoozeManager` / `BadgeSyncService` / `ReminderDispatcher` / `MedicationNotifier` / `RefillNotifier` / `AssessmentNotifier`）✅ |
| `safety_watch_service.dart` | 425 行 | 325 行 (-24%) | 抽 2 sub（`SafetyConfigService` / `SafetyAlertDispatcher`）✅ |
| `medication_report.dart` | 347 行 | 11090 bytes (3 纯函数类) | 抽 `MedicationStatCalculator` / `MissedDateBuilder` / `TempEntryExtractor` ⚠️ TDD 仅 1/3 |
| `app_router.dart` | 418 行 | 51 行 (-88%) | 抽 7 文件（`app_routes.dart` + 5 feature file + `app_shell.dart`）✅ |

**修正率**: 5/6 完整。**`medication_report` 修正只完成 50%**（3 sub-class 中 1 个有 isolated test，2 个 0 测）。

### 4.5 P2 finding: repository impl 重复 CRUD 模式

**位置**: 7 个 `lib/core/data/repositories/*/*_repository_impl.dart` + 7 个 `lib/core/data/database/daos/*_dao.dart`

**问题**: `watchAll` / `add` / `update` / `delete` 在 7 个 repository 几乎 1:1 重复（`select(where: t.id.equals(id))` / `into(table).insertOnConflictUpdate()` / `(update(table)..where(...)).write()` 模式）。

**评估**: 接受此重复 — **泛化抽象会引入 7×N 个 generic parameter + 1 个大 base class，违反 4 层架构"明确胜于灵活"原则**。`check_drift_namespace` 守护脚本保证 @DataClassName 唯一（已过），但**没有守护脚本验证 repository impl 的 method 签名一致性**（如 `Future<int> add(T)` / `Future<bool> update(T)` / `Future<int> delete(int id)`）。

**修复建议**: S 级 P2 — 加 `check_repository_contract.py` 检查 7 个 impl 的 method 名 + 签名一致（不强制相同 body，但保证 caller 调 `repo.add(entity)` 在 7 个 feature 都成立）。

---

## 5. 错误处理

### 5.1 main.dart 错误兜底

`lib/main.dart:38-72` — `runZonedGuarded<Future<void>>` + `FlutterError.onError` 双层包裹：
- `FlutterError.onError` (line 44-50): 捕获 widget build 阶段
- `runZonedGuarded` (line 53-71): 捕获所有 async 异常
- release 模式: 静默 log + `LastErrorCapture.record(error, stack)` (R33 修正)
- debug 模式: 重新 throw + `FlutterError.reportError`

**评估**: **完整 + fail-loud + 用户可见**（`LastStartupErrorBanner` 在 `app.dart:226-227`）。✅

### 5.2 catch 吞错模式

| 模式 | 位置 | 修正 |
|---|---|---|
| `} catch (_) {}` 静默 | v0.23 R39 前 9 处 | 全部修正走 `swallowError` 集中器（`swallow_error.dart`）— 修正后 0 处 ✅ |
| `} catch (e) { print(...) }` | 修正前多处 | 修正走 `piiSafeLog` 集中器（`pii_safe_log.dart`）— release 模式不打印 PII ✅ |
| `try/catch` + `return false` | `medication_repository_impl.dart:65-78` `setActive` 修正前 | R60 修正 + 加边界 unit test |

### 5.3 守护脚本覆盖

| 脚本 | 检查 | 结果 |
|---|---|---|
| `check_no_pua.py` | 0 PUA 字符 | ✅ 0 处 |
| `check_strings_hardcoded.py` | 29 处中文 static const/String | ✅ 28 处 R57 override 配对 + 1 处 i18n 标记 |
| `check_fullwidth_punctuation.py` | 全角标点 (warn-only) | ⚠️ 45 处 (zh ARB `…` 半角省略号) |
| `check_no_hardcoded_utc.py` | UTC 硬编码 | ✅ 0 处 |

**评估**: 错误处理守护脚本覆盖完整，**主路径全部修正**。

### 5.4 P1 finding: `safety_alert_dispatcher` 部分 catch 路径缺 swallowError

**位置**: `lib/core/data/services/safety_alert_dispatcher.dart` 修正后 12 KB，测试 12 KB。**修正质量高**，但 SMS release 模式（`SmsProviderNotConfiguredError`）只在 `main.dart:135` `validateForRelease` 触发，**未在 `safety_alert_dispatcher.dart:sendSafetyAlert` 二次 catch**。如果未来代码路径绕过 main.dart 直接调 SMS 发送，错误不会被 LastErrorCapture 接住。

**修复**: S 级 P1 — `safety_alert_dispatcher.dart:sendSafetyAlert` 包 try/catch + 调 `LastErrorCapture.record`。

---

## 6. TDD / 测试质量

### 6.1 测试规模

```
test/ (115 files)
├── core/         (12 KB + 5 KB) — 11 unit test (加密/notification/SMS notifier)
│   ├── data/services/  (10 files, ~80 KB)
│   ├── data/utils/     (1 file, phone_validator)
│   ├── shared/         (4 files, ~5 KB)
│   └── theme/          (2 files, ~8 KB)
├── data/         (33 files, ~140 KB) — repository/dao round-trip
├── domain/       (32 files, ~470 KB) — pure function + entity 契约
├── presentation/ (19 files, ~70 KB) — widget + provider
├── routing/      (1 file, route_parsing)
└── scripts/      (1 file, check_all 集成测试)
```

**总计 1098 cases pass**（commit `fdfa172` HEAD）。

### 6.2 round 编号测试组织一致性

| 模式 | 示例 | 状态 |
|---|---|---|
| `{module}_round{N}_test.dart` | `streak_calculator_round19_test.dart` | **98% 文件遵循** ✅ |
| 1 file 多个 round (修正累积) | `care_engine_round3_test.dart` + `round17_test.dart` + `round19_test.dart` + `round18_copy_test.dart` | 修正累积模式 ✅ |
| 修正 C/P/M 修正前缀 | `phq9_detect_crisis_round60_test.dart` (修正 C1) | ✅ |
| 1 个 file 修正累积 | `safety_watch_service_round12_test.dart` 修正后 15 KB (含 dispatch 修正) | ✅ |
| 1 个 file 0 round 编号 | `test_delivery_rate.dart` (`scripts/test_delivery_rate.dart` — 不是 test) | 不算 ✅ |

**评估**: **命名一致性极高**，修正累积策略清晰（修正 + roundN 共存，不删旧 test）。

### 6.3 5 个孤立 god class 找具体未覆盖的边界 case

#### God class 1: `medication_report.dart` 拆 3 sub-class

| sub-class | isolated test | 覆盖边界 case |
|---|---|---|
| `MedicationStatCalculator` | ✅ `medication_stat_calculator_round60_test.dart` 5,927 bytes | 修正 M1 (effectiveDaysClamped) ✅ |
| `MissedDateBuilder` | ❌ 0 isolated test | `effectiveDaysClamped` 应用 + 跨月 + 未来 startDate + 同天多次打卡去重 = 4 边界 0 测 |
| `TempEntryExtractor` | ❌ 0 isolated test | 窗口边界（periodStart 当天/前一天/后一天）+ temp type 过滤 + note 字段保留 = 3 边界 0 测 |

#### God class 2: `safety_watch_service.dart` 拆 2 sub

| sub-class | isolated test | 覆盖边界 case |
|---|---|---|
| `SafetyConfigService` | ❌ 0 isolated test | `setThresholdDays(0)` / `setThresholdDays(15)` ArgumentError 修正 / `setDoNotDisturb` 跨天 (22-08) / `setLastAlertAt` UTC 化 / `daysBetween` DST 边界 = 5 边界 0 测 |
| `SafetyAlertDispatcher` | ✅ `safety_alert_dispatcher_round61c3_test.dart` 12,123 bytes | audit log + SMS dispatch + 修正完整 ✅ |
| `SafetyWatchService` facade | ✅ `safety_watch_service_round12_test.dart` 15,303 bytes | end-to-end ✅ |

#### God class 3: `notification_service.dart` 拆 5 sub-service

| sub-service | isolated test | 评估 |
|---|---|---|
| `SnoozeManager` | ✅ `snooze_manager_round18_test.dart` 8,385 bytes | ✅ |
| `BadgeSyncService` | ✅ `badge_sync_service_round37_test.dart` | ✅ |
| `ReminderDispatcher` | ✅ `reminder_dispatcher_round37_test.dart` | ✅ |
| `MedicationNotifier` | ✅ `medication_notifier_round61c2_test.dart` 15,942 bytes (R56c'' 修正后) | ✅ |
| `RefillNotifier` | ✅ `refill_notifier_round61c_test.dart` 11,381 bytes (R56c' 修正后) | ✅ |
| `AssessmentNotifier` | ✅ `assessment_notifier_round61c3_test.dart` 5,003 bytes (R56c''' 修正后) | ✅ |

#### God class 4: `data_export_service.dart` 拆 4 sub-service

| sub-service | isolated test | 评估 |
|---|---|---|
| `ExportCryptoService` | ✅ `data_export_crypto_round45_test.dart` 4,939 bytes | ✅ |
| `ExportAudioService` | ✅ `data_export_audio_round45_test.dart` 4,284 bytes | ✅ |
| `ExportSchemaService` | ✅ `data_export_schema_round45_test.dart` 7,550 bytes | ✅ |
| `ExportOrchestrator` (含 facade) | ✅ `data_export_round3_test.dart` 10 KB + `data_export_round39_test.dart` 14 KB + `data_export_schema_round45_test.dart` 7.5 KB | ✅ |
| `DataExportService` facade | 同上 + R39 修正 P1-5 +50 case | ✅ |

#### God class 5: `app_database.dart` 拆 7 DAO

| DAO | isolated test | 评估 |
|---|---|---|
| `CheckInDao` | ⚠️ 间接 (round-trip via `medication_repository_round9_test.dart` + `data_export_*_test.dart`) | **无 isolated test**，修正 P2 修正 DAO 但 0 DAO 单测 |
| 其他 6 DAO | 同上 | **无 isolated test** |

**修正缺口**: **7 DAO 0 isolated test** — 修正 R53a god class 拆分 7 DAO 但只修正 integration test（repository → DAO 链）。未来 DAO SQL 修正（如 `order by` / `index hint`）无 test guard。

**修复建议**: M 级 P1 — `check_in_dao_round61_test.dart` + 6 sister test file，每个 50-100 case 覆盖 `watch*` / `get*` / `insert*` / `update` / `delete` 的 SQL 行为（含 index 用到/未用到）。

### 6.4 TDD 红绿循环断点（看 2-3 个 round 文件）

`test/domain/assessment_record_equality_round60_test.dart` 修正动机明确（line 1-15 注释详尽），是 **R60 audit C1 修正** 的产物。**修正模式**为"修正动机 → 新 test → implementation fix"。✅

`test/data/safety_watch_service_round12_test.dart` (15 KB) — R12 修正 + 后续累积（12+1+1+1 case）。**修正累积** 风格清晰。✅

`test/core/data/services/safety_alert_dispatcher_round61c3_test.dart` (12 KB) — R61c3 修正，新增 7 case 修正 dispatcher 行为。**修正 + isolated** 范本。✅

**修正质量**整体很高。**唯一断点**: P0 finding #2（`assessment_record_equality_round60_test.dart:62` 186KB 单行）— 这是 TDD 红绿循环**修正前**没 review 该 test 的产物。

### 6.5 mock 重 / happy-path 偏多风险

| 文件 | 模式 | 风险 |
|---|---|---|
| `medication_repository_round9_test.dart` | `NativeDatabase.memory()` + addMed helper | **good** — 真实 DB 走 migration，0 mock |
| `safety_watch_service_round12_test.dart` | `SafetyWatchService(...)` 直接构造 | **good** — 0 mock (但 0 isolated sub-class test 见 §6.3) |
| `app_snack_bar_round14_test.dart` | `tester.pumpAndSettle` + l10n | **good** — happy-path 但语义清晰 |
| `streak_calculator_round19_test.dart` | 各种边界 | **excellent** — 修正 v0.16 R19 加 unsorted input 修正 case |
| `care_strategies_round43_test.dart` (12.7 KB) | 22 case 修正 4 function | **excellent** — 修正 spen-3 off-by-one + 跨月 + 跨年 + 边界 |

**评估**: **整体 mock 偏少**，happy-path 修正到位。**P0 finding #2 (186KB 行) 是真修正前 review 漏检**。

---

## 7. 工程组织

### 7.1 16 个守护脚本覆盖完整度

| # | 脚本 | 类型 | 修正动机 | 当前状态 | CI 跑？ |
|---|---|---|---|---|---|
| 1 | `check_arb_keys.py` | Python | R10 同步 | ✅ 551 keys / 0 missing | ✅ |
| 2 | `check_changelog.py` | Python | v0.24 R48 | ✅ pubspec 0.25.0+1 同步 | ❌ |
| 3 | `check_cross_feature.py` | Python | v0.17 R12 | ✅ 0 violations | ✅ |
| 4 | `check_datetime_race.py` | Python | v0.16 R19B | ✅ 0 races | ❌ |
| 5 | `check_datetime_race2.py` | Python | v0.17 R14 | ✅ 0 races | ✅ |
| 6 | `check_drift_namespace.py` | Python | R11 | ✅ 7 table / 7 @DataClassName | ✅ |
| 7 | `check_fullwidth_punctuation.py` | Python | R10 | ⚠️ 45 violations (warn-only) | ✅ |
| 8 | `check_no_hardcoded_utc.py` | Python | R48 | ✅ 0 处 | ❌ |
| 9 | `check_no_pua.py` | Python | R40 | ✅ 0 PUA | ❌ |
| 10 | `check_orphan_arb_keys.py` | Python | v0.25 R56e | ✅ 0 orphan | ❌ |
| 11 | `check_legal_consent.py` | Python | v0.26 R57 | ✅ 0 TODO | ❌ |
| 12 | `check_sms_release_ready.py` | Python | v0.26 R57 → R58 warn-only | ⚠️ 1 warn (AliyunSms 未接) | ❌ |
| 13 | `check_strings_hardcoded.py` | Python | v0.26 R57 | ✅ 28 配对 + 1 标记 | ❌ |
| 14 | `check_zh_hant_consistency.py` | Python | v0.26 R57 | ✅ 100% 一致 (OpenCC s2tw) | ❌ |
| 15 | `check_widget_dispose.py` | Python | v0.25 R45B | ✅ 0 泄漏 | ❌ |
| 16 | `check_all.dart` | Dart | v0.18 R19 | ✅ 双 4 层 + 一致性 | ✅ (separate job) |

**CI 覆盖率**: 5/16 = 31%。**11 个守护脚本在 CI 跑不到**，只在开发者本地跑。

**修正动机**: v0.27 R60 commit `d32f290` "P0 文档同步 (D1) AGENTS.md 守护脚本 12→16 修正" — 修正了 AGENTS.md 文档列表，但**没修正 CI 流水线**。**修正声明 < 修正事实**。

**修复**: M 级 P1 — 在 `.github/workflows/ci.yml` `test` job 的 `Cross-feature import check` 之后加：
```yaml
- name: Run all guard scripts
  run: |
    python scripts/check_orphan_arb_keys.py
    python scripts/check_widget_dispose.py --ci
    python scripts/check_changelog.py
    python scripts/check_legal_consent.py
    python scripts/check_no_hardcoded_utc.py
    python scripts/check_no_pua.py
    python scripts/check_datetime_race.py
    python scripts/check_strings_hardcoded.py
    python scripts/check_zh_hant_consistency.py
    # check_sms_release_ready 是 warn-only, 不需要 fail
```

### 7.2 并行 worktree 开发可行性

**public API 边界清晰度**:
- ✅ `lib/domain/repositories/*.dart` 9 个 abstract interface — domain 边界清楚
- ✅ `lib/core/data/services/*.dart` 28 service 都通过 provider 注入，caller 不直接 `new Service()`（除 sub-service facade `withServices` 工厂）
- ✅ `lib/core/routing/app_routes.dart` 5 feature file 按 feature 拆，加新 feature route 只碰 1 文件
- ✅ `lib/presentation/pages/{feature}/*.dart` 9 feature directory，按 feature 1:1 对应
- ✅ `lib/presentation/providers/` 按"基础 / 业务 / vent / 跨页 / 单 feature"分 10 文件

**并行 worktree 可行性**: **强**。新 feature "X 心情分析" 可在 worktree 只改 `lib/presentation/pages/mood/` + `lib/core/data/repositories/mood/` + `lib/domain/logic/` + 1 个 `lib/presentation/providers/mood_providers.dart` + 1 个 `lib/core/routing/app_route_mood.dart`，**主分支零冲突**。

**潜在冲突**:
- `app_database.dart` schema 加新表 → 影响所有 worktree（需 release lock）
- `pubspec.yaml` 加新依赖 → 影响所有 worktree（需 release lock）
- `app_localizations*.dart` 加新 ARB key → 影响 i18n worktree（需 release lock）

**评估**: 修正动机充分，**修正率 90%+**。修正缺口在 `safetyConfigServiceProvider` (P0-1) + `medication_report` 修正 50% + 7 DAO 0 测 + 4 个其他 god class 修正 100%。

### 7.3 pubspec.yaml 依赖健康

**位置**: `pubspec.yaml:1-81`
- 17 runtime deps + 2 dev deps
- `pubspec_overrides.yaml:1-5` 锁 `objective_c: 9.3.0` 修正 Dart SDK 3.11.5 兼容性 (注释 line 1-3 修正动机清晰)
- `flutter: >=3.41.0` / `sdk: '>=3.4.0 <4.0.0'`
- `version: 0.25.0+1` — CHANGELOG 修正，**一致性 OK**
- `assets/shaders/ink_sparkle.frag` — R17-8 修正 ink_sparkle shader 缺失 → widget test fail

**评估**: **健康 + 修正充分**。**没有 unused dependency**（grep 验证 `fl_chart` 仅 5 file 引用 = 真用 / `pdf` 仅 2 file = 真用 / `record` 仅 vent + mood audio = 真用）。

**潜在风险**: 17 deps 偏多，但**没有一个是明显 dead dependency**。

### 7.4 build_runner drift 生成文件新鲜度

**P2 finding**（见 §4.2）: `app_database.g.dart` 比 `app_database.dart` 老 5 天，`.dart_tool/build/generated/` 新于源文件 — 修正未完成，**生成文件可能 stale**。验证 content 是新鲜的，但**应加 `check_drift_freshness.py`** 比较 mtime。

### 7.5 CI / CD 状态

**位置**: `.github/workflows/ci.yml:1-122` — 3 jobs:
1. **test** (line 8-66): `flutter analyze` + 5 守护脚本 + `flutter test`
2. **architecture** (line 67-80): `dart scripts/check_all.dart` (1 个脚本，覆盖 4 层)
3. **build** (line 82-122): `flutter build apk --debug` + `flutter build web --release`

**评估**: **3 job 设计合理**（dev build 修正 + release build 修正 = R31 sp-en P0-2 修正 "dev 模式能跑 ≠ release 模式能 build"）。

**修正缺口**:
1. `test` job 只跑 5/16 守护脚本（11 个修正不修正，CI 修正不修正）
2. `architecture` job 只跑 `check_all.dart`，不跑其他 Python 守护脚本
3. `build` job 不跑守护脚本（修正 release build 不修正 ARB key 一致性会 silent fail）

---

## 8. Top 10 actionable fixes（按 ROI + 架构纯净度排序）

### Fix #1: 修正 `safetyConfigServiceProvider` 修正（P0 / 1 文件 / TDD 需要）

- **描述**: `safety_watch_service.dart` 8 个 `@Deprecated('Use safetyConfigServiceProvider directly')` 注解全部指向不存在的 provider。R57 commit `ba12784` 修正声明但 R60 修正未完成。
- **位置**: `lib/core/data/services/safety_watch_service.dart:74, 87, 95, 101, 105, 111, 116, 123` (8 处) + `lib/presentation/providers/service_providers.dart` (新增 provider)
- **修复**: 1. `service_providers.dart` 加 `safetyConfigServiceProvider`；2. `@Deprecated` 注解消息修正加 file:line；3. caller 修正 R62+ 切到新 provider；4. 修正 R63+ 删 facade。
- **难度**: S（1 文件加 5 行 + 改 8 行注解）
- **影响范围**: P0（release 路径）
- **TDD 跟进**: 必须 — 加 `safety_config_service_test.dart` 11 case (修正 §6.3 god class 2)

### Fix #2: 修正 `assessment_record_equality_round60_test.dart:62` 186KB 单行（P0 / 1 文件 / 无 TDD）

- **描述**: 修正某 assert 修正动机时字符串拼接错位，1 行 186,298 字符，"修正后" 重复 2000+ 次。`dart test` 修正能跑过（expect 不检查 reason 字符串长度），但**修正前 review 修正KB
       reason: '修正前 == 修正 total 后可能误判',
  );
      expect(a7, isNot(equals(b)),
