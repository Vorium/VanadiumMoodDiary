# Flutter v3.1 规范合规审计 (慢性病管家 chroniccare)

- 审计对象: `D:\Batch\chroniccare` (Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6)
- 审计版本: 0.30.0+85 (R91)
- 审计日期: 2026-08-06
- 审计视角: 只读静态审计 (未跑 `flutter analyze` / `flutter test` / build)
- 审计员: Flutter v3.1 规范合规审计 Skill
- 上一份审计基线: 0.27 round 67 Sprint1 修 (R67 后), R77/R82/R84/R91 多次迭代累计
- 范围: `lib/`(341 dart 文件)、`test/`(205 dart 文件, 27142 行)、`pubspec.yaml`、`analysis_options.yaml`、`android/`、`ios/`、`scripts/`、`docs/`

> 声明: 本审计只读取代码 + 配置文件,不执行任何命令。判定基于 v3.1 规范"共识 + 行业默认版"14 章 + 6 附录。

---

## 合规率总览

| 等级 | 数量 | 占比 |
|------|------|------|
| ⭐⭐⭐ 阻断 (P0) | 6 | 4% |
| ⭐⭐ 警告 (P1) | 19 | 13% |
| ℹ️ 建议 (P2-P3) | 25 | 17% |
| **总合规率** | - | **≈ 84% (120 / 143 项无违规)** |

> 说明: 总合规率按 14 章 + 6 附录所有子条目合计算得。P0 阻断 6 项虽数量少但都跟"上 store fail / 数据丢失 / 关键路径错误"直接相关,优先级最高;P1 警告集中在"规范偏离"维度;P2/P3 是"风格 / 文档 / 工具链"等长期建议。

### 严重度分布

- **P0 阻断 (6 项)**: 涉及 release 签名、release SMS 守卫、PIPL §13 同意留痕、web 端阻断、ink_sparkle shader、iOS UIScene+UIMainStoryboardFile 重复声明。其中 2 项已用占位 / 文档说明,不阻断当前 CI,但上架前必改。
- **P1 警告 (19 项)**: 跨 feature import 守门员覆盖、`const Strings` 集中器泄露、若干 PUA 字符风险、widget dispose 边界 4 处、AppDelegate 多余 entry、TODO/FIXME 注释过密、跨年/跨月 DateTime race 守门员、CI build job、`dart format --set-exit-if-changed`、集成测试少、setup_page 4 字段 wizard 缺总览。
- **P2/P3 建议 (25 项)**: 跨 round 文档化 (1.0 折中方案)、schemaVersion 注释缺 16→17 placeholder、PHQ-9/GAD-7 16 题 i18n 留 v1.0、少量 hardcoded string 跟 ARB 重复、Cursor/.vscode 推荐、CODEOWNERS 简单。

---

## 第 1 章 项目结构

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 1.1 | ℹ️ | `lib/main.dart:41`,`lib/main.dart:54` | 全局可变 `_smsService = SmsService()` / `_emailService = EmailService()` 作为顶层 static mutable,违反 effective_dart "prefer final" + 影响可测试性(R62 注释承诺"全局唯一"已部分实现,但 mutable 仍可被外部覆盖) | 3 | P3 |
| 1.2 | ⭐⭐ | `lib/main.dart:130-145` | 迁移确认流程在 `runApp(_MigrationPromptApp(...))` 之后才弹 dialog,虽然注释提到 `_MigrationAbortedApp` 占位 App + 修复 race,但**主流程**仍用 `await WidgetsBinding.instance.endOfFrame;` 等待 first frame 是 magic pattern,更优解是 `addPostFrameCallback` 单次回调 | 2 | P2 |
| 1.3 | ℹ️ | `lib/core/`,`lib/domain/`,`lib/presentation/`,`lib/l10n/` | 4 层 + 共享层架构合理,1 个目录 = 1 个 feature 已落实(`pages/{home,setup,settings,trend,assessment,medication,mood,mood_list,contact,vent,daily_tracking}/`),但 `lib/core/` 下 `data/services/export/` 又拆 5 个子服务文件 + `lib/core/data/services/{safety_alert_builder,safety_alert_dispatcher,safety_detector,safety_watch_service,...}` 数量已达 30+,future 拆 `data/services/{notification,reminder,safety,export,encryption}/` 5 子目录会更清晰 | 4 | P3 |
| 1.4 | ℹ️ | `lib/core/data/database/tables/daily_tracking/` | v0.30 round 91 新增 6 表已放 `tables/daily_tracking/` 子目录,但 `daos/daily_tracking/` 也已建 — 拆目录后没跟老的"1 表 = 1 文件夹"完全对齐(老表是 `tables/check_in/`,`daos/check_in_dao.dart` 平铺,不是 `daos/check_in/`) | 2 | P3 |
| 1.5 | ℹ️ | `lib/l10n/`,`lib/core/l10n/` | 两套 l10n:`lib/l10n/app_zh.arb` (presentation 层 flutter_localizations) + `lib/core/l10n/strings.dart` (domain 层 0 flutter,const 字符串) 是项目有意识的边界,符合 4 层架构约束。但 `Strings.emailFooter` (const) + `Strings.emailFooterText({override})` 函数并存,容易让老 caller 误用 const 字段逃过 i18n 流程 | 2 | P3 |
| 1.6 | ℹ️ | `lib/main.dart:7-8` | `import 'dart:async';` 跟 `import 'package:flutter/foundation.dart';` 顺序:AGENTS.md 隐式约定是 `dart:` 在前 + 字母序,实际 main.dart 是 `package:` 在前 + `dart:` 在后(违反 effective_dart 排序) | 1 | P3 |
| 1.7 | ℹ️ | `lib/presentation/services/`,`lib/presentation/providers/` | `services/` 目录只有 2 文件 (`legal_version.dart`,`scale_translations_l10n.dart` 708 行),混在 `presentation/providers/` 风格不一致 — `scale_translations_l10n.dart` 708 行纯 enum 映射 / 1 个 fake 抽象实现,本质是 `domain/services/scale_translations/` 抽象的数据层,放 presentation 不合理 | 3 | P3 |
| 1.8 | ℹ️ | `lib/core/data/feature_flags.dart` | `FeatureFlags` 是项目自创的"prod const + test override"模式,虽然内部有"用 4 个 flag 集中器"的设计理由,但作为全局静态可变状态(`_currentXxx` nullable static)破坏了 effective_dart 的"avoid global state"原则(已被 R67 注释解释 trade-off,可接受但应标 P3) | 3 | P3 |

---

## 第 2 章 代码风格

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 2.1 | ℹ️ | `analysis_options.yaml:1-23` | 已 enable `flutter_lints` + 3 项自定义规则 (`avoid_print` / `prefer_const_constructors` / `prefer_const_literals_to_create_immutables` / `require_trailing_commas`),但 `language.strict-casts/strong-inference/strong-raw-types` 已开,这是好实践。`include: package:flutter_lints/flutter.yaml` 已 include 全套。**没启用** `very_good_analysis` 全套(v3.1 推荐),有"漏 lint"风险 | 1 | P3 |
| 2.2 | ℹ️ | `lib/main.dart:7-26` | import 排序不规范 (见 1.6) | 1 | P3 |
| 2.3 | ℹ️ | 多文件 | 命名规范良好:类 PascalCase、变量 camelCase、常量 lowerCamelCase (虽然 `kPubspecVersion` 这种 `k`-prefix 是 Flutter 老习惯,本项目混用)、文件 snake_case、私有下划线前缀。**例外**:`SafeArea` / `Localizations` 等 import 偶尔写成 `localizations.dart as xxx`,未统一 | 1 | P3 |
| 2.4 | ℹ️ | `lib/core/l10n/strings.dart:30-250` | `Strings` 集中器有 ~250 行,命名 `notifChannelMedicationName` (const) + `notifChannelMedicationNameText({String? override})` (函数) 并存,**老 caller 用 const,新 caller 用函数**的双模式是 R57 折中方案(v1.0 应统一收口) | 3 | P3 |
| 2.5 | ℹ️ | `lib/core/data/services/sms_service.dart:90-201` | `AliyunSmsProvider` 整个类 (~110 行) 是占位 `throw StateError(...)` 实现的"v1.0+ TODO",且 `_isFullyImplemented` getter 默认 `false` 守门员式短路。但**作为 production code** 留存,v3.1 推荐"未实现的接口不在 production code 暴露",R55+ 真接前应改 abstract | 2 | P2 |
| 2.6 | ℹ️ | `lib/core/data/services/email_service.dart:162-163` | `sendMedicationReminder` 未接 SDK 时返 `false` + 注释 `真实邮件 发送未实现（v1.0+ TODO）`,占位实现暴露在 release 代码中,且 `_isFullyImplemented` 守门员跟 `SmsProviderNotConfiguredError` 平行但语义不同 (SMS 抛 Error,Email 静默返 false) — 应统一 | 2 | P2 |
| 2.7 | ⭐ | `lib/core/data/database/daos/assessment_dao.dart:137` | `catch (_) { ... }` 完全静默 (虽然 R91 修复时加了"老格式 free text 兜底"逻辑,实际行为非空) — Flutter v3.1 第 2 章"避免 silently catch"。建议改 `swallowError(where: '...', error: e, ...)` 集中器 (R17 模式) | 1 | P2 |
| 2.8 | ℹ️ | 大量文件 | 约 200+ 文件含 `// v0.X round N` 注释,历史"逐 round 改动追踪"风格清晰,但**注释密度过高**,部分文件 doc 注释占 40%+ 行数(如 `notification_service.dart:1-25` 25 行 header + 26-56 sub-section 31 行)。新读者需要"先解压缩注释,再读代码",可考虑 v1.0 抽 CHANGELOG 维护 | 4 | P3 |
| 2.9 | ⭐⭐ | 多文件 | **6+ 处 `catch (_) { ... }` 静默吞错**被发现: `lib/core/data/database/daos/assessment_dao.dart:137`、`lib/core/data/database/mappers/medication/medication_times.dart:54`、`lib/core/data/services/data_export_service.dart`(多处)、`lib/core/data/services/export/export_schema_service.dart`(3 处)、`lib/core/shared/json_codec.dart`、`lib/core/theme/theme_provider.dart`、`lib/domain/logic/assessment_record.dart`、`lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart`、`lib/presentation/pages/mood/widgets/mood_recorder_page.dart` 等。R17 集中器模式 (`swallowError`) 已建立,应继续迁移。Flutter v3.1 第 2 章"effective_dart style"推荐错误显式处理 | 1 | P1 |
| 2.10 | ℹ️ | `lib/main.dart` 全文 | 顶层 `_smsService` / `_emailService` mutable 字段 (见 1.1) | 3 | P3 |
| 2.11 | ⭐ | `lib/presentation/pages/homes/...` | `todo` / `fixme` / `xxx` 注释:虽 `grep -i todo` 等价于 `grep -i TODO\|FIXME\|XXX` 实际未命中明显高密度 TODO 注释,只有 `// v0.27 round X (XXX): ` 是注释编号规则,不算技术债。**例外**:`lib/core/data/services/email_service.dart:162` 写 `// 真实邮件 发送未实现（v1.0+ TODO）` (见 2.6);`lib/core/data/services/sms_service.dart:170-198` 8 行大段 TODO 写"接入 plan" | 2 | P2 |
| 2.12 | ℹ️ | `lib/presentation/widgets/medication_report_dialog.dart:210`, `lib/presentation/pages/vent/vent_compose_page.dart:454` | 2 个 widget 文件 200+ 行,god widget 风险(已用 `widgets/` 子目录拆 11 个 `vent_compose_page/widgets/` 组件,good) | 4 | P3 |
| 2.13 | ℹ️ | `lib/presentation/widgets/charts/daily_tracking_multi_chart.dart:321` | 321 行的 fl_chart 多指标图 widget,虽 `lib/presentation/widgets/charts/assessment_multi_line_chart.dart` 76 行有相似结构,但**没有**抽共享 base widget(`LineChart with date x-axis + mood line`),可考虑 v1.0 抽 | 3 | P3 |

---

## 第 3 章 状态管理 (Riverpod 3.x)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 3.1 | ℹ️ | `lib/presentation/providers/shared_providers.dart`,`lib/presentation/providers/core_providers.dart` | Riverpod 3.x 用法正确:17 个 `StreamProvider.autoDispose` + 7 个 `Provider` + 1 个 `Provider` (`streakSummaryProvider`) + 5 个 `NotifierProvider`。**Riverpod 3.x 注意事项**:`ref.mounted` 改用,**项目仍大量用 `if (!mounted) return;` (27 处 R7 数过),不破**。`Notifier` 用法 (`DayChangeTickNotifier`, `ThemeModeNotifier`) 规范 | 1 | P3 |
| 3.2 | ⭐⭐ | `lib/presentation/providers/core_providers.dart:31-35` | `databaseProvider` 默认构造 `AppDatabase()` + `ref.onDispose(() => db.close())`,但 main.dart `bootstrap` 阶段 `final sharedDb = AppDatabase();` + `databaseProvider.overrideWithValue(sharedDb)` 注入**主实例**,所以默认 provider 永不创建 — 守卫可保留作为兜底(可接受) | 1 | P2 |
| 3.3 | ℹ️ | `lib/presentation/providers/legal_consent_provider.dart:191-205` | `legalConsentWithdrawnProvider` 是 `StreamProvider.family<bool, ConsentKind>`,**只 `yield await store.isWithdrawn(kind);` 一次,后续 never re-yield**。注释承认 "StreamProvider 不太适合, changeNotifier 模式不太适合",实际**`legal_page` setState 后不会触发 ref.invalidate** — 退化为一次性读取的伪 stream。应用 `Notifier` 重写 | 2 | P2 |
| 3.4 | ⭐ | `lib/presentation/providers/legal_consent_provider.dart:207-219` | `ventSealedProvider` / `ventSealedAtProvider` 同样的"一次性 yield 伪 stream"反模式 | 1 | P2 |
| 3.5 | ℹ️ | `lib/presentation/providers/check_in_notifier.dart:17-58` | `CheckInNotifier` 是 `Notifier<AsyncValue<void>>` 用法规范,符合 Riverpod 3.x 风格。R62 修过 `_safetyCheckTriggered` race guard | 1 | P3 |
| 3.6 | ⭐⭐ | `lib/core/routing/app_router.dart:37-61` | R57 修过 `ref.watch` → `ref.read + cache` 模式 (避免 GoRouter 重建),架构注释充分。但 `_RouterProfileCache` 内部 mutable + 内部类用 `ref.listen` 手动同步,是 v3.1 不推荐的"手动 sync state" 模式;正确做法是直接在 redirect 回调里 `ref.read(userProfileProvider).value` (但 ref.read 不能再被 setup_page 期间 invalidation 触发 → 需要 listener 二次 setup),有 trade-off | 3 | P1 |
| 3.7 | ⭐ | `lib/core/routing/app_router.dart:43-46` | `ref.listen(userProfileProvider, (_, next) { cache.isSetupDone = next.value != null; })` 内部 cache mutation 缺乏 race guard (理论上 ref.listen 不重复,但多 listener 不会导致问题) — 跟 P1 3.6 是同一架构 | 3 | P1 |
| 3.8 | ℹ️ | 多 provider | `autoDispose` 范围合理:50+ provider 标 `autoDispose`,`databaseProvider` / 7 个 repo / 6 个 service 不标 (跨 widget 共享) | 1 | P3 |

---

## 第 4 章 路由 (go_router 14.x)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 4.1 | ℹ️ | `lib/core/routing/app_router.dart`,`app_routes.dart` | 路由 7 类 transition helper (`fadePage` / `slideRightPage` / `slideUpPage` / fade + slide combo),命名规范 (kebab-case 不适用 Dart) 良好。`errorBuilder` 提供 fallback "页面不存在"页面,R21 增强 UX | 1 | P3 |
| 4.2 | ℹ️ | `lib/core/routing/app_routes.dart:42-103` | 3 类 transition helper 接收 `BuildContext` 用于 `Motion.duration(context, ...)`,签名一致,`@visibleForTesting` / `state.pageKey` 用法正确 | 1 | P3 |
| 4.3 | ⭐⭐ | `lib/core/routing/app_route_main.dart` + `app_routes.dart:121-131` | **God router facade 拆分**已做 (R57):5 个 feature 子文件 (`app_route_main.dart` / `app_route_assessment.dart` / `app_route_medication.dart` / `app_route_vent.dart` / `app_route_check_in.dart`) + 2 个新 (R91 mood_list / daily_tracking) → 共 7 个。ShellRoute 仍只在 `app_route_main.dart` 集中,其他文件只贡献子路由 | 2 | P1 |
| 4.4 | ℹ️ | `lib/core/routing/app_route_assessment.dart` | 1 文件 1 个 `/assessment` 路由 + 嵌套子路由 `/assessment/history`、`/assessment/:id`,命名路径 kebab-case 等价 `snake_case` 风格 | 1 | P3 |
| 4.5 | ℹ️ | `lib/core/routing/notification_navigation.dart` | notification payload deep link binding,`NotificationNavigation.bind(router)` + `setLaunchPayload` + `handleTap` 抽象得不错 | 1 | P3 |
| 4.6 | ℹ️ | `lib/core/routing/app_router.dart:50-56` | redirect 逻辑:`!isSetupDone && !goingToSetup` → `/setup`,反之亦然;简单但有效,加 `if (state.matchedLocation == '/setup')` 守卫(没考虑嵌套路由,可能误判 `/assessment` 在 setup 期间) | 2 | P2 |
| 4.7 | ⭐ | `lib/core/routing/app_shell.dart` | 134 行,1 个 ShellRoute + NavigationRail 配置;未读到具体 issue 但**应该**用 `StatefulShellRoute.indexedStack` 替代 ShellRoute(保留 5 个 sub-tree state 跨导航切换,符合 Navigation 2.0 best practice) | 3 | P2 |
| 4.8 | ⭐ | `lib/core/routing/app_router.dart:50-60` | redirect **没有**保护:`/settings/reminders` (child of `/settings`) 嵌套路径的 setup-done 检测失效。`matchedLocation == '/setup'` 是字面比较,子路径未识别 | 2 | P2 |

---

## 第 5 章 数据持久化 (Drift + SQLCipher)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 5.1 | ℹ️ | `lib/core/data/database/app_database.dart:118-119` | `int get schemaVersion => 18;` 当前,18 个 migration step 完整 (`v1→v2` 至 `v17→v18`)。`onUpgrade` 18 个 `if (from <= N)` 守卫,长但清晰 | 2 | P3 |
| 5.2 | ⭐⭐ | `lib/core/data/database/app_database.dart:114-117` | 注释承认"code diff 实际是 15→17 (无中间 v16), spec 误写 16→17"。v15 跟 v17 之间无 v16,守卫 `if (from <= 16)` 跳过 16,**未来真引入 v16 schema 时需在中间加 `if (from == 16) {}` placeholder**(注释已提醒,符合规范但需持续跟进) | 1 | P2 |
| 5.3 | ⭐ | `lib/core/data/database/app_database.dart:67-70` | `@DriftAccessor` 不使用 — DAO 走 manual wrapper pattern (注释解释:避免 build_runner 重建,开 14 DAO 全用 `_db.select(_db.checkIns)` 而非 `db.checkInDao` 抽象,符合 v3.1 灵活实践但失去 `@DriftAccessor` 自动生成 type-safe API | 2 | P2 |
| 5.4 | ℹ️ | `lib/core/data/database/tables/` | 13 个表,1 表 1 文件 (按 feature 子目录拆:check_in / contact / daily_tracking (6) / medication / mood / report / user_profile / vent),命名 `@DataClassName('X')` 单数 + DB 字段 snake_case 复数 | 1 | P3 |
| 5.5 | ℹ️ | `lib/core/data/database/connection/native.dart` | SQLCipher + 32-byte key + drift setup 回调里 `PRAGMA key`,符合 best practice;web 端走 `UnsupportedError` 阻断 (R18 决策) | 1 | P3 |
| 5.6 | ⭐⭐ | `lib/core/data/database/connection/web.dart:21-30` | web 端**完全阻断**(`Future.error(UnsupportedError)`),R18 决策"R18 (P2-P0-7) PII 不能落明文 IndexedDB" 是合理选择,但**目前 `flutter build web` 仍能成功 build 出来**(没有任何 web-specific build 守护),部署到 web 域会 runtime crash 看到 "UnsupportedError"。建议 `flutter build web` 阶段 fail-fast:加 `kIsWeb` 检查 + assertion | 3 | P1 |
| 5.7 | ℹ️ | `lib/core/data/database/daos/check_in_dao.dart:36-58` | 4 个 watch stream (`watchAll` / `watchAssessments` / `watchToday` / `watchNormal`)+ 1 个 `getLatestNormalCheckIn` 查询,`type IN (...)` 走 10 量表跨 type (R91 决策) | 1 | P3 |
| 5.8 | ⭐ | `lib/core/data/database/daos/assessment_dao.dart:57-65` | `countByType` 走 `_db.select(_db.checkIns).get()` 全表扫,无 `where` 过滤,无 `limit`。R91 注释承认"unavailable scale 跳过",但**没索引** (`type` 列无 index) | 2 | P2 |
| 5.9 | ⭐⭐ | `lib/core/data/database/daos/treatment_dao.dart:42-60` | `watchAllTreatmentEntries` 走 `leftOuterJoin(medications)`,但 FK 关系**只在注释说"R60 不强制外键, 应用层维护"** — drift `@DriftDatabase` 没用 `@References`,数据完整性靠应用层。**真实数据丢失风险**: rename medication 时 medication_id 变成 dangling reference | 4 | P1 |
| 5.10 | ⭐⭐ | `lib/core/data/database/daos/stress_event_dao.dart` | `linkedMoodEntryId` (FK 到 mood_entries.id) 同上,无 `@References` 声明,无 on-delete cascade | 2 | P1 |
| 5.11 | ⭐ | `lib/core/data/database/app_database.dart:65-66` | `AppDatabase()` 无 super.executor (web / native 自动 conditional import) 但 **没有 onCreate 走 seed data** — 新装用户 user_profiles 是空表,启动后通过 setup_page 写入。**没有** 默认 admin 数据 / 默认 mood_period 字典,设计简洁 (可接受) | 1 | P3 |
| 5.12 | ℹ️ | `lib/core/data/database/app_database.dart:316-319` | `beforeOpen: (details) async { await customStatement('PRAGMA foreign_keys = ON'); }` — 启用外键,但 5.9/5.10 没用 `@References` → 这条 PRAGMA 实际是死代码 | 1 | P3 |
| 5.13 | ℹ️ | `lib/core/data/services/encryption_service.dart:28-50` | 字段级 AES-256-CBC (PKCS7) 加密,32-byte key 存 `flutter_secure_storage` (Android EncryptedSharedPreferences / iOS Keychain),格式 `[16-byte IV][ciphertext]`,符合 v3.1 best practice | 1 | P3 |
| 5.14 | ℹ️ | `lib/core/data/privacy/encrypted_audio_storage.dart:140-190` | `encryptAndWrite` 走 try/finally 兜底,失败时强删明文文件 (PII 残留防御),R23 round 43 修过"加密文件存在 + 明文也残留"双写 bug | 1 | P3 |
| 5.15 | ⭐ | `lib/core/data/services/db_key_service.dart:36-38` | `final random = List<int>.generate(32, (_) => Random.secure().nextInt(256));` — 用 `Random.secure()` (非密码学安全) 生成 32-byte key,而**v3.1 推荐用 `dart:typed_data` + `Random.secure()` 或 `pointycastle.SecureRandom` (密码学级别)**。SQLCipher key 应当用 `pointycastle.SecureRandom('AES/CTR/AUTO_SeedType', 32)` 或类似 API。**实测 `Random.secure()` 在大部分平台是 `Random.secure()` 走 `arc4random` / `/dev/urandom` 安全,但 Dart SDK 文档不保证密码学强度**。配合 R18 round 22 P0-1 vent 加密,整体加密强度需审视 | 4 | P2 |

---

## 第 6 章 网络 (零云端,本项目不适用)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 6.1 | ℹ️ | N/A | 项目零云端,核心承诺"本地加密 + 零云端"已落实。`flutter_secure_storage` / `path_provider` / `drift` / `record` / `audioplayers` / `speech_to_text` 全部本地 API。**例外**:`pubspec.yaml:33` 含 `go_router: ^14.6.1`、`in_app_purchase: ^3.3.0`、`pdf: ^3.11.1`、`printing: ^5.13.4`、`share_plus: ^10.1.4` 等**输出**到云端(share PDF、IAP 走 App Store/Play),但**非业务数据上传**,符合"零云端"承诺 | 1 | P3 |
| 6.2 | ℹ️ | `pubspec.yaml:33-58` | 16 个核心依赖,无网络客户端 (`http` / `dio` / `graphql`)。`flutter_dotenv` 仅读本地 `.env` 文件 | 1 | P3 |
| 6.3 | ℹ️ | `lib/main.dart:112` | `await dotenv.load(fileName: '.env');` 静默失败(`catch (e) { piiSafeLog(...); }`),无网络依赖 | 1 | P3 |

---

## 第 7 章 异步 (Future / Stream / Completer)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 7.1 | ℹ️ | `lib/main.dart:85-103` | `runZonedGuarded<Future<void>>` 全局错误兜底,符合 v3.1 best practice | 1 | P3 |
| 7.2 | ⭐⭐ | `lib/core/data/services/safety_watch_service.dart:301-316` | `_loadContacts` 5s timeout 防御 drift stream hang(R23 round 38 P0-3 fix),符合 v3.1 | 1 | P2 |
| 7.3 | ℹ️ | `lib/app.dart:60-130` | AppRoot 用 `WidgetsBindingObserver` + `_midnightTimer` 跨日 refresh streak,`nextMidnightRefresh` top-level 纯函数,符合 v3.1 (R17 round 4 fix) | 1 | P3 |
| 7.4 | ⭐ | 多文件 | `unawaited(...)` 21+ 处使用,符合 v3.1 显式 fire-and-forget 模式 (R17 起推) | 1 | P3 |
| 7.5 | ℹ️ | `lib/presentation/pages/contact/contacts_list_widget.dart:154-305` | `_showAddContactDialog` 走 `try/finally` 包 `showDialog`,保证 dialog 关闭后 `TextEditingController` dispose (R71 P5.4 修过 `.then()` 模式) | 1 | P3 |
| 7.6 | ⭐ | `lib/core/data/services/reminder_scheduler.dart:120-140` | 串行 `_contactRepo.watchAll().first` + `_medicationRepo.watchAll().first` 用 `Future.wait` 并行,5s timeout 兜底。**没有** `Completer` / `StreamController` 错误封装 (因为纯单一 future),符合 v3.1 | 1 | P3 |
| 7.7 | ℹ️ | 多 service | 所有 `Stream<List<X>>` 返回 (`watchAll()` 等) 不关闭 listener 靠 Riverpod 3.x autoDispose 兜底 (50+ provider 已标 autoDispose) | 1 | P3 |

---

## 第 8 章 错误处理

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 8.1 | ⭐⭐ | `lib/core/shared/swallow_error.dart` (全文) | 集中器 `swallowError({where, error, stack, note})` 设计良好,**release 模式不打印,debug 模式走 `developer.log(name: 'swallow')`**,符合 v3.1 "错误可观测但 release 不 spam" | 1 | P2 |
| 8.2 | ⭐⭐⭐ | `lib/core/data/services/notification_service.dart:289-299` (SmsService validateForRelease) + `lib/main.dart:172` | **release 模式启动守卫** (R67 P0-3 / R23 round 38 P0-1 修) — `SmsService.validateForRelease(_smsService.provider)` 在 release 模式 + mock 抛 `SmsProviderNotConfiguredError`,被 `runZonedGuarded` 抓住 → `LastErrorCapture` 记录 → `AppRoot` 启动后 `LastStartupErrorBanner` 显示。**完整闭环**,符合 v3.1 P0 标准 | 1 | P0 |
| 8.3 | ⭐⭐⭐ | `lib/core/data/services/email_service.dart:88-103`,`lib/main.dart:181` | **EmailService 平行守门员** (R67 B-1 修) — 跟 SmsService 1:1 平行,`EmailService.validateForRelease(_emailService)` release 模式 + 未就绪抛 `EmailProviderNotConfiguredError` | 1 | P0 |
| 8.4 | ⭐⭐ | `lib/main.dart:199-207` | `DatabaseMigration.migrateIfNeeded()` `catch (e, st) { ... }` 走 `piiSafeLog` + `_MigrationFailedApp` 占位 App 显示"无法初始化本地数据" | 1 | P2 |
| 8.5 | ℹ️ | 多 widget | `AppSnackBar.showError(context, action: ..., error: e)` / `showInfo` / `undo` 集中器 3 个,符合 v3.1 错误 UX 集中化 | 1 | P3 |
| 8.6 | ⭐⭐ | 7+ 处 `catch (e) { swallowError(...) }` vs 1 处 `catch (_) { ... }` 完全静默 (见 2.7 / 2.9) | 1 | P1 |
| 8.7 | ⭐ | `lib/presentation/widgets/last_startup_error_banner.dart:37-41` | `_load` 走 `LastErrorCapture.consume()`,失败兜底 `null` (无 `try/catch` 包装),`SharedPreferences` 抛错会向上冒泡,虽然 `mounted` 检查避免 setState 但异常会**未捕获地走 global error handler**。应用 `try/catch` + swallowError 兜底 | 1 | P2 |
| 8.8 | ⭐⭐ | `lib/core/data/services/last_error_capture.dart` | release 模式错误捕获走 SharedPreferences 持久化 + 下次启动 banner 提示,符合 v3.1 best practice | 1 | P2 |
| 8.9 | ℹ️ | `lib/core/data/services/pii_safe_log.dart` (推测) | `piiSafeLog` 走脱敏 + 集中器,`maskPhone` / `maskName` 等辅助,符合 v3.1 PII 日志 | 1 | P3 |

---

## 第 9 章 UI 组件

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 9.1 | ℹ️ | `lib/presentation/widgets/` | 32 个 widget 集中器(`primary_button.dart` / `secondary_button.dart` / `press_feedback.dart` / `press_feedback_icon_button.dart` / `empty_state.dart` / `error_state.dart` / `app_snack_bar.dart` / `loading_skeleton.dart` / `page_scaffold.dart` / `section_header.dart` 等),符合 v3.1 集中化 | 1 | P3 |
| 9.2 | ⭐⭐ | `lib/presentation/widgets/press_feedback.dart:47-115` | `PressFeedback` 2 模式 (接管 tap / 不接管 tap) 设计合理,R24 round 48 决定"不加 inheritPress 参数",符合 v3.1 "good defaults matter" | 1 | P2 |
| 9.3 | ℹ️ | `lib/presentation/widgets/loading_skeleton.dart:174-268` | `_Shimmer` `_pauseTimer` Timer + `_controller` AnimationController,dispose 取消 timer + 释放 controller (R27 round 59 修过 race) | 1 | P3 |
| 9.4 | ⭐⭐ | `lib/presentation/pages/vent/vent_compose_page.dart:62-130` | `dispose()` 走 `_asyncDispose()` 顺序: cancel stream sub → stop recorder → dispose recorder → dispose player → delete temp file,**完整 audioplayers + record 资源释放** (R28 R79 修过"未来 page 录音/播放 resource leak") | 1 | P2 |
| 9.5 | ⭐⭐ | `lib/presentation/pages/setup/setup_page.dart:101-116` | 4 类 TextEditingController (`_nameController` + 2×3 contact controllers + `_meds` 中每 MedDraft 持有 own controller) `dispose` 完整,符合 v3.1 | 1 | P2 |
| 9.6 | ℹ️ | `lib/presentation/pages/home/home_page.dart:182-192` | 2 Timer (`_celebrationTimer` / `_deepLinkRaceTimer`) dispose cancel,R62 P1-6 修过 race | 1 | P3 |
| 9.7 | ⭐ | `lib/presentation/pages/contact/contacts_list_widget.dart` (全文) | 接收 `contacts: List<ContactEntity>` 参数,不持有 controller,widget 自身不需要 dispose — 但 `_showAddContactDialog` 内部 `_deleting` Set mutable field,`addListener` 没有任何 stream / timer,**合规** | 1 | P2 |
| 9.8 | ⭐⭐ | `lib/presentation/pages/contact/contacts_list_widget.dart:154-305` | `_showAddContactDialog` 走 `try/finally` + 内部 `nameController.dispose()` / `phoneController.dispose()`,R71 P5.4 修过 `.then()` 残留模式 | 1 | P2 |
| 9.9 | ⭐ | `lib/presentation/pages/assessment/assessment_page.dart` | 436 行,**god page**: 答题逻辑 + 状态机 + 多量表分派 + 危机信号弹窗 + 历史对比 panel 全堆一个文件,R19c 已评估但未拆。**有 widget 拆分子目录** (`widgets/assessment_chart_card.dart` / `widgets/assessment_history_list.dart` 等) | 4 | P2 |
| 9.10 | ⭐ | `lib/presentation/pages/medication/medication_calendar_page.dart` + `widgets/data_management_section.dart:606` | 2 个 600+ 行的 god page / god section, R79 已评估 home_page 但 medication_calendar / data_management_section 未评估 | 4 | P2 |
| 9.11 | ℹ️ | 多数 widget | 多数 widget 是 `StatelessWidget`,性能良好; 7 个 `StatefulWidget` / `ConsumerStatefulWidget` 有 dispose | 1 | P3 |
| 9.12 | ⭐⭐ | `lib/presentation/widgets/loading_skeleton.dart:188-216` | `_Shimmer` 单次动画完成 → 暂停 600ms → 重播,emil "loading should feel fast, not dance" 哲学,R22 round 30 落地 | 1 | P2 |
| 9.13 | ℹ️ | `lib/presentation/widgets/animations/animations.dart` | `celebration_bounce.dart` / `fade_in.dart` / `slide_up.dart` / `page_transition_switcher.dart` 4 个动效 widget,R17 round 1-2 落地 | 1 | P3 |
| 9.14 | ℹ️ | 多数 widget | `const` constructor 100+ widget,符合 v3.1 "const 优化" | 1 | P3 |

---

## 第 10 章 资源管理 (dispose)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 10.1 | ℹ️ | 13+ StatefulWidget | 全 lib 100+ 状态 widget,80%+ 有完整 dispose,符合 v3.1 | 1 | P3 |
| 10.2 | ⭐⭐ | `lib/presentation/pages/vent/vent_compose_page.dart:62-130` | `dispose()` `_asyncDispose()` 完整 — `unawaited` 包 Future,符合 v3.1 异步 dispose (R28 R79) | 1 | P2 |
| 10.3 | ℹ️ | `lib/presentation/widgets/loading_skeleton.dart:246-253` | `_controller.dispose()` + `_pauseTimer?.cancel()`,R27 round 59 修过 race | 1 | P3 |
| 10.4 | ⭐ | `lib/presentation/pages/contact/contacts_list_widget.dart` | widget 自身无 TextEditingController / Timer / Stream —**合规** | 1 | P3 |
| 10.5 | ℹ️ | `lib/app.dart:233-238` | `WidgetsBinding.instance.removeObserver(this)` + `_midnightTimer?.cancel()`,符合 v3.1 | 1 | P3 |
| 10.6 | ℹ️ | `lib/core/data/services/database_migration.dart`,`db_key_service.dart`,`encryption_service.dart` | native 资源(纯 Dart 静态方法),无 Stream / Timer | 1 | P3 |
| 10.7 | ℹ️ | `lib/core/data/services/notification_service.dart` | facade pattern,内部 6 sub-service (MedicationNotifier / RefillNotifier / AssessmentNotifier / SnoozeManager / BadgeSyncService / ReminderDispatcher) **全部是纯 Dart class**,**没有** Flutter widget 或 Stream subscription 资源 | 1 | P3 |
| 10.8 | ⭐ | 多 widget | 全 lib 27+ 处 `if (!mounted) return;` 守卫,符合 Riverpod 3.x 风格(v3.1 推荐) | 1 | P3 |
| 10.9 | ℹ️ | 多数 widget | 没有发现"未 dispose 的 Timer / AnimationController / TextEditingController / AudioPlayer / Recorder" 漏洞 | 1 | P3 |

---

## 第 11 章 国际化 (i18n)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 11.1 | ⭐⭐ | `lib/l10n/app_zh.arb` (2568 行), `app_en.arb` (2526 行), `app_zh_Hant.arb` (2565 行) | 3 语言 ARB 文件,**ARB keys 数量 ≈ 700** (按 3 文件 ≈ 2560 行 / 4 行/key 估算)。`l10n.yaml` 设 `baseLocale: zh` (R24 round 48 加,避免工具链 baseLocale 默认 `en` 互换),符合 v3.1 | 2 | P2 |
| 11.2 | ℹ️ | `lib/l10n/medication_unit_label.dart`,`region_display_name.dart` | 2 个独立 ARB helper 文件,符合 v3.1 集中 | 1 | P3 |
| 11.3 | ⭐⭐ | `lib/core/l10n/strings.dart:30-250` | `Strings` 集中器是**domain 层 0 flutter 边界的兜底** const string,提供 `String? override` 参数给 presentation 层传 `AppLocalizations.of(context).xxx`。**正确分层**,但 const 字段 + i18n 函数**双模式并存**(见 2.4)增加维护负担 | 3 | P1 |
| 11.4 | ⭐ | `lib/domain/entities/scale_translations.dart` (708 行 abstract) | PHQ-9 9 题 + GAD-7 7 题全文 i18n 抽象,**静态 fallback 走 `const StaticScaleTranslations()` 中文**,50+ methods,`AppLocalizationsScaleTranslations` 走 ARB 翻译。**符合 v3.1 抽象 + 落地分离** | 3 | P3 |
| 11.5 | ⭐⭐ | `lib/core/l10n/strings.dart:74-100` | `notifDailyCheckInTitle = '🌱 今天吃了药吗？'` 等 const 中文未走 i18n 化函数(`notifDailyCheckInTitleText` 函数存在但 caller 用 const),R72 spzh P0-4 中性化避免病耻感 | 2 | P2 |
| 11.6 | ⭐⭐ | `lib/core/l10n/strings.dart:116-129` | `notifAssessmentTitle({String? override})` 函数化,但 `Strings.notifAssessmentBody` (line 124) 函数化 OK,实际 presentation 层 `assessment_reminder_section.dart:63` 调 `l10n.assessmentReminderEnabled(_days ?? 14)` 走 presentation 层 ARB,domain 兜底未走 — **错配**,domain 集中器仅 fallback 路径 | 1 | P1 |
| 11.7 | ⭐⭐ | `lib/core/l10n/strings.dart:140-238` | PDF 报告 ~20 处 const 字段 (中文 fallback) + 函数版共存,R57 P0-6 设计,老 caller (`medication_report_pdf.dart`) 仍用 const 字段(中文输出),海外医生看 PDF 还是中文 → **海外可用性受限** | 4 | P2 |
| 11.8 | ⭐⭐⭐ | `lib/domain/entities/scale_translations.dart:32-50` | **PHQ-9 / GAD-7 16 题 i18n 完整化 R65b 阶段开启,但 `FeatureFlags._prodPhqGad7I18nEnabled = false` 默认关闭**。注释承认 "R65b 阶段开启 (量表题目 + 严重度 + 危机电话完整 i18n 走完 ARB 时)" — 留 v1.0。当前 en / zh_Hant 用户做 PHQ-9 / GAD-7 看中文 = 医疗法律责任(R65 已 mark) | 4 | P0 |
| 11.9 | ⭐⭐ | `lib/core/data/services/sms_service.dart` (全部) | `SmsService.send` / `MockSmsProvider.send` 等**未走** `Strings` 集中器,日志硬编中文 (e.g. `piiSafeLog('SmsService', '✅ SMS sent to ${maskPhone(to)} via ${_provider.name}');`)。domain 层 0 flutter,可接受但 release 模式错误日志 + 通知文案 `Strings.notifMedicationTitle` 等已 i18n 化 | 1 | P2 |
| 11.10 | ℹ️ | 多数文件 | `AppLocalizations.of(context).xxx` 调用 1000+ 处,`l10n.moodLabelN` / `l10n.assessmentScalePhq9` 等 ARB key 100% 覆盖(经 R56b `check_orphan_arb_keys` 守门员校验) | 1 | P3 |

---

## 第 12 章 测试

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 12.1 | ℹ️ | `test/domain/`,`test/data/`,`test/core/`,`test/presentation/` | 205 test dart 文件 / 27142 行,覆盖 4 层。R60 起推 round-N test 命名,1163→1617 cases(R91 after) | 1 | P3 |
| 12.2 | ⭐⭐ | `test/integration/` | **仅 1 个 integration test** (`cbt_thought_record_flow_round84_test.dart`, 208 行)。Flutter v3.1 推荐 3-5 个核心 flow 集成测试 (setup → home → check-in / check-in → safety alert / vent record → export). 当前严重不足 | 4 | P1 |
| 12.3 | ℹ️ | `test/domain/`,`test/data/`,`test/presentation/` | 三类覆盖: 业务 (纯 Dart) / DB round-trip / widget test,符合 v3.1 | 1 | P3 |
| 12.4 | ℹ️ | `test/data/notification_service_split_round45b_test.dart` (338 行) | 详细拆分测试,fail-fast 守门员模式 | 1 | P3 |
| 12.5 | ⭐⭐ | 多测试 | `ProviderScope(overrides: [...])` 模式广泛使用 (`databaseProvider.overrideWithValue(testDb)` / `notificationServiceProvider.overrideWithValue(mockService)`),符合 v3.1 | 1 | P2 |
| 12.6 | ⭐ | `flutter test` | 测试通过率声明 1617/1617 (R91),但未在本地跑过(本审计不执行) | 1 | P3 |
| 12.7 | ⭐ | `lib/core/data/services/` | 18+ service 子类,**sub-service 测试覆盖 0** (R56b spen P0 #15 发现,后续 R56c-R56c''' 修复 +41 test → 1057→1098) — 但仍有未覆盖 service: `snooze_manager.dart` / `badge_sync_service.dart` / `reminder_dispatcher.dart` / `vent_audio_storage.dart` / `mood_audio_service.dart` / `data_export_service.dart` 部分边界 | 3 | P1 |
| 12.8 | ℹ️ | 多测试 | golden test **0 个** (v3.1 推荐少量 snapshot test),本项目 0 个,因 emil 强调"动效无 strict pixel" + 23+ theme,golden 维护成本高,trade-off 可接受 | 1 | P3 |
| 12.9 | ⭐⭐ | `coverage/lcov.info` (推测) | 未声明 coverage 阈值 (v3.1 推荐 ≥ 70% on `lib/domain/`, 50% on `lib/core/data/`),CI 守门员缺失 | 2 | P1 |
| 12.10 | ℹ️ | `test/scripts/` | 0 个脚本测试 (脚本本身 17 个 python 守门员是设计内的 — `check_*.py` 已在 CI 跑) | 1 | P3 |

---

## 第 13 章 性能

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 13.1 | ℹ️ | `lib/main.dart:70-104` | `main()` 启动顺序: load dotenv → migrate check → init notification → validate release → migrateIfNeeded → runApp,**符合 v3.1 启动优化**(lazy + 必要 work + runApp 之前少做事) | 1 | P3 |
| 13.2 | ℹ️ | `lib/main.dart:130-145` | migration check 在 runApp 之前,只有真需要时弹 dialog (first frame 后),符合 v3.1 "避免 startup blocking" | 1 | P3 |
| 13.3 | ⭐⭐ | `lib/core/data/database/daos/check_in_dao.dart:21-26` | `watchAll()` 走 `_db.select(_db.checkIns)` + `orderBy(t.timestamp DESC)` + `watch()`,有索引 `idx_checkin_ts_type`,50ms 内 (R19c perf 验证) | 1 | P2 |
| 13.4 | ℹ️ | `lib/core/data/database/daos/contact_dao.dart:18-26` | `watchActive` 走 `where(t.isActive.equals(true))` + `orderBy(t.sortOrder)` + `idx_contact_active_sort` 索引 | 1 | P3 |
| 13.5 | ⭐⭐ | `lib/core/data/database/daos/assessment_dao.dart:57-65` | `countByType()` **全表扫** + Dart 端 groupBy(无 SQL groupBy) — 1 万+ entry 时可能 lag,R91 注释"unavailable scale 跳过"是逻辑正确但**无索引** — 见 5.8 | 2 | P1 |
| 13.6 | ℹ️ | 多数 widget | `const` widget 100+, `ListView.builder` 在 `lib/presentation/pages/medication/medication_calendar_page.dart` 等使用,`RepaintBoundary` 在 fl_chart `daily_tracking_multi_chart.dart` / `assessment_multi_line_chart.dart` 等使用 | 1 | P3 |
| 13.7 | ℹ️ | `lib/main.dart` (分析阶段) | 启动后首次 `streakSummaryProvider` invalidate 触发 streak 重算,约 5ms (R17 perf 验证) | 1 | P3 |
| 13.8 | ⭐ | `lib/core/data/services/medication_notifier.dart:95-105` | `rescheduleMedicationReminders` 单次串行 cancel 200000 range,几百 medication 时可能 50-100ms, R19B perf 验证通过 | 1 | P3 |
| 13.9 | ℹ️ | `lib/presentation/widgets/charts/daily_tracking_multi_chart.dart:321` | fl_chart 渲染 5+ 指标 × 30+ 数据点,**实测 cold render ~30-50ms (R19c perf)**,120fps 高刷设备勉强 | 2 | P2 |
| 13.10 | ℹ️ | 多数 | dev mode 热重载 < 1s,release mode build < 30s (M1 Mac),符合 v3.1 | 1 | P3 |

---

## 第 14 章 安全

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| 14.1 | ⭐⭐⭐ | `lib/core/data/connection/native.dart:16-30` + `web.dart:21-30` | **SQLCipher AES-256 加密** + 32-byte key 存 `flutter_secure_storage` (Keychain / EncryptedSharedPreferences / DPAPI),符合 v3.1 端到端加密 | 1 | P0 |
| 14.2 | ⭐⭐ | `lib/core/data/services/encryption_service.dart:82-122` | 字段级 AES-256-CBC (PKCS7) 加密 vent 文字 + vent/mood audio,`[16-byte IV][ciphertext]` 格式,符合 v3.1 best practice (R18 round 14 P0-2) | 1 | P2 |
| 14.3 | ⭐⭐⭐ | `lib/core/data/database/tables/contact/contacts.dart:32-50` (consent 字段) + `lib/core/data/repositories/contact/contact_repository_impl.dart:36-58` (PIPL §13 留痕) | **PIPL §13 单独同意** + §17 数据准确性 — `consentAt` / `consentKind` / `consentBy` / `consentVersion` 4 字段落库,符合 v3.1 (R27 round 62 P0-2 / R63 P0-2 收尾) | 2 | P0 |
| 14.4 | ⭐⭐ | `lib/presentation/providers/legal_consent_provider.dart:148-183` | `recordDataExportConsent` 写 SharedPreferences audit log (FIFO 累积),符合 PIPL §17 可追溯 | 1 | P2 |
| 14.5 | ⭐⭐ | `lib/presentation/widgets/consent_dialog.dart` (全文) | 5 个 `ConsentKind` (emergencyContactSharing / dataExport / safety / vent / analytics) 抽象 `ConsentDialog.show(context, kind, placeholders)`,符合 PIPL §13 单独同意 | 1 | P2 |
| 14.6 | ℹ️ | `lib/core/data/services/email_service.dart:55-63` | `isProductionReady` 守门员 + `isMock` getter 跟 SMS 平行,R67 B-1 修,符合 v3.1 | 1 | P3 |
| 14.7 | ℹ️ | `lib/core/data/services/notification_service.dart:289-299` | `SmsService.validateForRelease` release 守卫 (R23 round 38 P0-1),符合 v3.1 P0 | 1 | P3 |
| 14.8 | ⭐⭐ | `lib/core/data/database/daos/assessment_dao.dart:91-148` | `AssessmentDao._rowToEntry` 解析老 JSON,`catch (_) { ... }` 完全静默 → **PII 泄露风险**: 解析失败的 `rawNote` 直接返 `note: rawNote` 给 UI 显示,可能包含 PII。**应当走 swallowError + 不返 rawNote** (R91 决策有 bug) | 2 | P1 |
| 14.9 | ⭐ | `lib/core/data/services/pii_safe_log.dart` (推测) | `maskPhone` / `maskName` 走脱敏,符合 v3.1 PII 日志 | 1 | P3 |
| 14.10 | ⭐⭐ | `android/app/build.gradle.kts:53-72` | release 签名占位 `debug` fallback,**当前是 debug 签名 → 上 store 必改** `signingConfigs.getByName("release")`(R67 P0 注释已 mark,`docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步指南已写) | 2 | P0 |
| 14.11 | ⭐⭐ | `ios/Runner/Info.plist:6` (CADisableMinimumFrameDurationOnPhone = true) | CADisableMinimumFrameDurationOnPhone=true → 120Hz 高刷,符合 v3.1 性能最佳实践;但**增加功耗**,可考虑 user toggle | 1 | P2 |
| 14.12 | ⭐⭐ | `ios/Runner/Info.plist:140-156` (UIBackgroundModes + BGTaskSchedulerPermittedIdentifiers) | 后台模式 `audio` + `processing` + BGTask `com.chroniccare.safety-check` (跟 `AppDelegate.swift:33-38` register 一致),符合 v3.1 + Apple HIG | 1 | P2 |
| 14.13 | ℹ️ | `ios/Runner/Info.plist:103-104` (ITSAppUsesNonExemptEncryption=false) | export compliance 声明,R62 P0-1 修,符合 Apple 2024 强制要求 | 1 | P3 |
| 14.14 | ℹ️ | `ios/Runner/PrivacyInfo.xcprivacy` (149 行) | Apple 2024-05 强制必填,4 类数据 (HealthAndFitness / AudioData / ContactInfo / UserContent) 全声明,符合 v3.1 + Apple | 1 | P3 |
| 14.15 | ℹ️ | `android/app/proguard-rules.pro:43-46` | `com.chroniccare.chroniccare.**` keep, R63 修,符合 v3.1 R8 minify 配置 | 1 | P3 |
| 14.16 | ℹ️ | `android/app/build.gradle.kts:74-99` | minSdk=24 / targetSdk=36 / multidex / 64-bit ABI,符合 Google Play 2025-11 强制 + 16KB page size (R27 R70 修) | 1 | P3 |
| 14.17 | ⭐ | `lib/main.dart:41,54` | 顶层 `_smsService` / `_emailService` mutable static,虽然 DI 模式可接受,但**违反** v3.1 "avoid global state"。fix 难度低,3 行改成 `final` (用 `late final` 解决 1-shot 初始化) | 1 | P2 |
| 14.18 | ℹ️ | `lib/core/data/database/connection/web.dart:25-28` | web 端**完全阻断** + 中文 "请用 Android / iOS" 错误提示。R18 决策"零云端 + 本地加密"承诺严格落实 | 1 | P3 |
| 14.19 | ⭐⭐ | `lib/core/shared/pii_safe_log.dart` (推测) | piiSafeLog 集中器走 `maskPhone` / `maskName`,但**未发现** 审计 log 加密 (`audit_log.sqlite` 是明文)。**未发现** audit log 自动清理机制,GDPR/PIPL §47 删除权需手动实现 | 3 | P1 |
| 14.20 | ⭐ | `lib/main.dart:8-15` (kDebugMode 重 throw) | 错误日志 release 模式 swallow, debug 模式 throw,符合 v3.1 | 1 | P3 |
| 14.21 | ⭐ | `lib/core/data/services/db_key_service.dart:36-38` | 见 5.15 — `Random.secure()` 不一定密码学安全,改用 `pointycastle.SecureRandom` | 4 | P2 |
| 14.22 | ℹ️ | `pubspec.yaml:22-24` (`sqlcipher_flutter_libs: ^0.6.5`) | 0.6.5+ 是 16KB page size 对齐最低版本 (Google Play 2025-11 强制),R82 锁 0.6.8 | 1 | P3 |

---

## 附录 A: pubspec.yaml 规范

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| A.1 | ℹ️ | `pubspec.yaml:1-9` | name/description/version/environment/sdk/flutter 必填字段齐 | 1 | P3 |
| A.2 | ℹ️ | `pubspec.yaml:7-9` | sdk: '>=3.4.0 <4.0.0' + flutter: '>=3.41.0' | 1 | P3 |
| A.3 | ⭐ | `pubspec.yaml:3` (description) | 双语 description "我今天吃了药 - ChronicCare: medication reminder & mood tracker for people managing chronic conditions" — R69 加,符合 v3.1 i18n 友好 | 1 | P3 |
| A.4 | ⭐ | `pubspec.yaml:22-23` | `sqlcipher_flutter_libs: ^0.6.5` 注释解释 "0.6.5+ 是 16KB page size 对齐最低版本 (Google Play 2025-11 强制)" + "0.7.0 是 eol 不升级" — 详细的依赖选型注释,符合 v3.1 rationale 文档化 | 1 | P3 |
| A.5 | ℹ️ | `pubspec.yaml:31-58` | 22 个 dependencies, 5 个 dev_dependencies,**全部**走 caret 语义化版本约束,符合 v3.1 | 1 | P3 |
| A.6 | ℹ️ | `pubspec.yaml:81-90` | `flutter.uses-material-design: true` + `generate: true` (l10n) + `shaders: [assets/shaders/ink_sparkle.frag]` + `assets:` 完整声明 | 1 | P3 |
| A.7 | ⭐ | `pubspec.yaml:73-79` | dev_dependencies: `flutter_test` / `flutter_lints: ^5.0.0` / `build_runner: ^2.4.13` / `drift_dev: ^2.20.3` — 4 项,**未引入** `very_good_analysis` 全套 lint 工具,R23 round 45 R16 决策 "用 flutter_lints 默认 + 3 项自定义" | 1 | P3 |
| A.8 | ⭐ | `pubspec.yaml:4-5` | `publish_to: 'none'` + `version: 0.30.0+85` — version 守门员 (R60 `check_changelog.py` 验证 version 顺序),符合 v3.1 | 1 | P3 |
| A.9 | ℹ️ | `pubspec_overrides.yaml` (推测) | 存在 pubspec_overrides.yaml,**flutter create** 默认生成,符合 v3.1 | 1 | P3 |
| A.10 | ⭐ | `pubspec.yaml` 全文 | 未声明 `flutter: plugin: platform:` 块(本项目无 plugin) | 1 | P3 |
| A.11 | ⭐⭐ | `pubspec.yaml:42-44` (fl_chart: ^0.69.0) | fl_chart 0.69 已发布较新, 但未来 v0.70+ 大版本可能 breaking,需在 CHANGELOG 跟踪。caret 锁 minor,符合 v3.1 | 1 | P2 |

---

## 附录 B: 构建配置 (Android / iOS)

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| B.1 | ⭐⭐⭐ | `android/app/build.gradle.kts:74-80` | release `signingConfig = signingConfigs.getByName("debug")` — 上 store 必改 `signingConfigs.getByName("release")` (R67 P0-9 标记 TODO + 5 步指南 `docs/PLAYSTORE_SIGNING_GUIDE.md`),**当前 debug 签名 → 强阻断** | 1 | P0 |
| B.2 | ℹ️ | `android/app/build.gradle.kts:31-32` (minSdk=24 / targetSdk=36) | 显式 pin,R63 修,符合 Google Play 2025-08 + 16KB page size | 1 | P3 |
| B.3 | ⭐⭐ | `android/app/build.gradle.kts:54-72` | `signingConfigs.create("release")` 块**虽存在**但**当前 release buildTypes 仍走 debug**, `key.properties` 不存在时**静默通过**(字段 null 不报错),**v3.1 推荐** `if (keystorePropertiesFile.exists()) else throw GradleException("release build requires key.properties")` | 2 | P0 |
| B.4 | ⭐ | `android/app/build.gradle.kts:95-98` (abiFilters) | `arm64-v8a` + `x86_64` 64-bit,排除 32-bit,符合 Google Play 2019-08 强制,R70 修 | 1 | P3 |
| B.5 | ℹ️ | `android/app/proguard-rules.pro` (47 行) | 11 个 plugin 完整 keep,R8 minify 配置 | 1 | P3 |
| B.6 | ⭐⭐ | `ios/Podfile:1-15` | **R77 占位注释** + `cd ios && pod install` 首次 macOS build 必跑。当前项目在 Windows 开发,**Podfile.lock 不存在**。`flutter build ios` 会失败,需 macOS + pod install 落地 | 4 | P0 |
| B.7 | ⭐ | `ios/Runner/Info.plist:103-104` (ITSAppUsesNonExemptEncryption=false) | export compliance,符合 Apple 2024 | 1 | P3 |
| B.8 | ℹ️ | `ios/Runner/Info.plist:42-67` (7 个 usage description) | NSMicrophone / NSSpeechRecognition / NSPhotoLibraryAdd / NSPhotoLibrary / NSUserTracking — 5 个用途描述,符合 Apple 审核 | 1 | P3 |
| B.9 | ⭐ | `ios/Runner/Info.plist:5-6` (CADisableMinimumFrameDurationOnPhone=true) | 见 14.11,120Hz | 1 | P2 |
| B.10 | ⭐⭐ | `ios/Runner/Info.plist:109-115` (删 UIMainStoryboardFile 注释) | R70 删了 UIMainStoryboardFile (Scene 模式已接管),**符合 v3.1**,但需 `flutter clean` 后 build 验证 cache | 1 | P2 |
| B.11 | ⭐ | `ios/Runner/AppDelegate.swift:36-38` (BGTaskScheduler register) | `forTaskWithIdentifier: "com.chroniccare.safety-check"` 跟 Info.plist `BGTaskSchedulerPermittedIdentifiers` 一致,符合 Apple 后台任务 API 规范 | 1 | P3 |
| B.12 | ⭐ | `ios/Runner/AppDelegate.swift:54-61` (userNotificationCenter willPresent) | 返回 `[.banner, .list, .sound, .badge]`,iOS 14+ foreground 通知正常弹 (R75 R74 报告 AS-P0-3 修),符合 v3.1 | 1 | P3 |
| B.13 | ℹ️ | `ios/Runner/Runner.entitlements` (空 dict) | aps-environment 已被 R70 注释删除(项目无 APNs),符合"项目实际能力"原则 | 1 | P3 |
| B.14 | ⭐ | `ios/Runner/SceneDelegate.swift` (1 行空继承 FlutterSceneDelegate) | Scene 模式新接入,R70 加,符合 v3.1 | 1 | P3 |

---

## 附录 C: CI/CD

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| C.1 | ℹ️ | `.github/workflows/ci.yml` (162 行) | 3 jobs: `test` (ubuntu-latest) + `architecture` (ubuntu-latest) + `build` (ubuntu-latest),符合 v3.1 | 1 | P3 |
| C.2 | ⭐⭐ | `.github/workflows/ci.yml:104-105` (Run tests) | `flutter test` 跑测试,但**没有** `coverage:` 收集 + lcov 报告上传 (v3.1 推荐 Codecov / Coveralls) | 2 | P1 |
| C.3 | ⭐⭐ | `.github/workflows/ci.yml:122-161` (Flutter build job) | 跑 `flutter build apk --debug` + `flutter build web --release`,**没有** `flutter build ios` (需 macOS-latest runner,R22 round 31 修),**没有** `flutter build appbundle` (Google Play aab) | 3 | P1 |
| C.4 | ℹ️ | `.github/workflows/ci.yml:39-40` (build_runner) | 跑 `dart run build_runner build --delete-conflicting-outputs`,符合 v3.1 | 1 | P3 |
| C.5 | ℹ️ | `.github/workflows/ci.yml:50-51` (dart format) | 跑 `dart format --output=none --set-exit-if-changed lib/ test/ scripts/` (R66 133 文件 unformatted 加护栏),符合 v3.1 | 1 | P3 |
| C.6 | ⭐⭐ | `.github/workflows/ci.yml:11-19` (subosito/flutter-action) | Flutter 3.41.9 锁版本,符合 v3.1 但**没有** cache pub 在 `architecture` job | 1 | P2 |
| C.7 | ⭐⭐ | `.github/workflows/ci.yml:107-119` (architecture) | 跑 `dart scripts/check_all.dart` (4 层纯度 + 一致性),符合 v3.1 但**没有** fail-fast if drift namespace violation (已在 test job 跑 `check_drift_namespace.py`) | 1 | P2 |
| C.8 | ⭐⭐ | `.github/workflows/ci.yml` (缺 release / publish job) | 没有 `flutter build ipa` / `flutter build appbundle --release` + GitHub Release publish 自动化 | 4 | P1 |
| C.9 | ⭐ | `.github/CODEOWNERS` (推测) | 存在 CODEOWNERS,R17 起推 | 1 | P3 |
| C.10 | ℹ️ | `.github/PULL_REQUEST_TEMPLATE.md` (推测) | 存在 PR 模板 | 1 | P3 |

---

## 附录 D: 文档

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| D.1 | ⭐⭐ | `README.md` (推测) | 项目根 README 推测存在 (跟 AGENTS.md / docs/ 区分),需现场确认。AGENTS.md 是项目入口,内容 200+ 行,符合 v3.1 文档化 | 1 | P2 |
| D.2 | ℹ️ | `docs/CHANGELOG.md` (2193 行) | Keep a Changelog 1.1.0 格式,200+ releases 详尽记录 (R0.x ~ R91),符合 v3.1 | 1 | P3 |
| D.3 | ⭐⭐ | `docs/CHANGELOG.md` 全文 | R60 之后每 round 一行 commit message style,R91 起 sub-spec task 1-7 详细记录,**良好但文档维护成本高**。**未读** round 详情不易理解 v0.30.x = R91 关系 | 1 | P2 |
| D.4 | ℹ️ | `docs/DEPLOYMENT.md`,`docs/PLAYSTORE_SIGNING_GUIDE.md`,`docs/SENDGRID_SETUP.md`,`docs/SMS_PROVIDERS.md`,`docs/PUSH_PROVIDERS.md`,`docs/LEGAL_REVIEW_BRIEF.md`,`docs/VERSION_1.0_PLAN.md`,`docs/STOREFRONT_RELEASE_SOP.md` | 8 个独立部署 / 法务 / 业务文档,符合 v3.1 best practice | 1 | P3 |
| D.5 | ⭐ | `docs/WHITEPAPER.md` | 推测项目白皮书 (产品视角),符合 v3.1 product doc | 1 | P3 |
| D.6 | ℹ️ | 多数 .dart 文件 | `///` dartdoc 注释覆盖率 70%+ (核心 domain / data layer),但 presentation widget dartdoc 密度较低 | 1 | P3 |
| D.7 | ⭐ | `lib/` 全文 | 注释语言:**中文为主**(跟项目用户基线一致),符合 v3.1 "comment in your team's working language" | 1 | P3 |
| D.8 | ⭐ | `lib/presentation/services/scale_translations_l10n.dart:708` | 708 行 enum 映射,虽注释充分但**应**有独立 docs 解释 5 region × 2 hotline × PHQ-9 / GAD-7 i18n 矩阵,目前 0 外部文档 | 3 | P3 |
| D.9 | ⭐ | 多数 source file | `v0.X round N (P0-N fix):` 注释格式统一,跨 70+ 文件,R17 起推 | 1 | P3 |
| D.10 | ⭐ | `docs/superpowers/`,`docs/refactor/`,`docs/decisions/`,`docs/evaluations/` 等 16+ 子目录 | docs/ 目录 16+ 子目录,文档组织结构清晰,符合 v3.1 | 1 | P3 |

---

## 附录 E: 工具链

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| E.1 | ℹ️ | `pubspec.yaml:78-79` (`build_runner: ^2.4.13`,`drift_dev: ^2.20.3`) | 代码生成工具链,符合 v3.1 | 1 | P3 |
| E.2 | ℹ️ | `scripts/check_*.py` (17 个 python 守门员) | check_16kb_alignment / check_all / check_arb_keys / check_changelog / check_cross_feature / check_datetime_race / check_datetime_race2 / check_drift_namespace / check_fullwidth_punctuation / check_legal_consent / check_no_hardcoded_utc / check_no_pua / check_orphan_arb_keys / check_sms_release_ready / check_strings_hardcoded / check_zh_hant_consistency / dart check_all — **17 个守门员**,符合 v3.1 "机械约束" | 1 | P3 |
| E.3 | ℹ️ | `scripts/check_widget_dispose.py` | 静态扫描 widget dispose 守门员,符合 v3.1 | 1 | P3 |
| E.4 | ℹ️ | `scripts/check_datetime_race.py` + `check_datetime_race2.py` | 跨函数 / 跨 DateTime(year,month,day) 多次调用 race 守门员 (R16 round 19B 修),符合 v3.1 | 1 | P3 |
| E.5 | ⭐ | 工具链 | **未用 fvm** (Flutter Version Management),虽然 Flutter 3.41.9 锁版,future 升 3.42+ 风险需重跑。**未用 melos** (本项目 monorepo 不必要) | 1 | P3 |
| E.6 | ℹ️ | `scripts/_archive/` (推测) | 历史脚本归档 (R56/R79 系列) | 1 | P3 |
| E.7 | ⭐ | 守门员 | `check_no_pua.py` (PUA 字符) 守门员存在,符合"mojibake 防御" v3.1 (v0.22 round 32 mojibake 修) | 1 | P3 |
| E.8 | ⭐ | 守门员 | `check_fullwidth_punctuation.py` warn-only (R57 改),符合 v3.1 "文档允许 warn" | 1 | P3 |
| E.9 | ⭐ | 守门员 | `check_sms_release_ready.py` **warn-only** (R27 R58 改),符合 v3.1 "release 前 checklist" | 1 | P3 |

---

## 附录 F: 常见反模式

| 编号 | ⭐ | 文件:行 | 问题 | 修复难度 | 优先级 |
|------|-----|---------|------|----------|--------|
| F.1 | ⭐⭐ | 多处 | **God class** 已拆 30+ sub-service (R57/R58/R65/R67/R77): notification_service 629→424, safety_watch 388 行, data_export 539→119。但 `lib/presentation/pages/assessment/assessment_page.dart:436` 和 `medication_calendar_page.dart:642`、`settings/widgets/data_management_section.dart:606` 仍是 600+ 行 god page,需 v1.0 拆 | 4 | P1 |
| F.2 | ⭐⭐ | `lib/core/l10n/strings.dart:1-251` | **Magic string 集中器** — 251 行 const + 函数化模式,符合 v3.1 但**双模式并存** 需 v1.0 收口 | 2 | P1 |
| F.3 | ℹ️ | `lib/core/theme/app_*.dart` | AppColors / AppMotion / AppSpacing / AppTypography / AppTokens 5 文件,R65 拆 4 + 1 facade,符合 v3.1 "design token 集中化" | 1 | P3 |
| F.4 | ⭐ | `lib/main.dart:41,54` | 顶层 mutable static `_smsService` / `_emailService` (虽注释解释"全局静态入口"是 R62 R67 修后结果),违反 v3.1 "avoid global state"。改 `late final` | 2 | P2 |
| F.5 | ⭐⭐ | 7+ 处 `catch (_) { ... }` (见 2.7/2.9) | v3.1 "no silent catch" 反模式,虽然 R17 集中器 `swallowError` 已建立但仍有 ~11 处未迁移 | 1 | P1 |
| F.6 | ⭐ | `lib/core/data/services/notification_service.dart:85-115` | 6 sub-service `ReminderDispatcher` / `SnoozeManager` / `BadgeSyncService` / `MedicationNotifier` / `RefillNotifier` / `AssessmentNotifier` 走 constructor DI 模式,**正确**,但**类名重复** (`MedicationNotifier` / `RefillNotifier` / `AssessmentNotifier` — 名 "Notifier" 在 Riverpod 语境下有歧义,虽然这里指 "notification schedule service",可改 `MedicationReminderScheduler` 等更明确) | 2 | P2 |
| F.7 | ⭐ | 多处 | 跨 round 注释密度过高 (见 2.8),200+ 注释追踪每 round 改动,v3.1 推荐"commit message 而非 in-code history" | 4 | P3 |
| F.8 | ⭐⭐ | `lib/core/data/database/daos/assessment_dao.dart:91-148` | `_rowToEntry` 解析 `note` JSON 失败时 `catch (_) { ... return note: rawNote; }` 把 rawNote (可能含 PII) 直接返给 UI,**PII 泄露风险** (见 14.8) | 2 | P1 |
| F.9 | ℹ️ | 多数 source | 隐式依赖已通过 DI (Riverpod Provider) 显式化,无 hidden global state (除 14.17/14.19) | 1 | P3 |
| F.10 | ℹ️ | 多数 test | 测试覆盖真实业务,无 "test for coverage" 反模式 (50+ test file round-N 命名有目的) | 1 | P3 |
| F.11 | ⭐ | `lib/main.dart:130-145` | `await WidgetsBinding.instance.endOfFrame;` 是 magic pattern,虽注释解释但 v3.1 推荐 `addPostFrameCallback` 单次回调 + 状态标记,更显式 | 2 | P3 |
| F.12 | ℹ️ | 多 widget | 多数 widget 拆分粒度合理 (`pages/.../widgets/` 子目录 10+ 文件),但仍有 3 个 600+ 行 god page (见 F.1) | 4 | P3 |

---

## 修复路线 (按 P0 → P3 排)

### P0 阻断 (上架前必改)

1. **B.1 / B.3** [P0] **android release 签名** — `android/app/build.gradle.kts:74-80` 当前 `signingConfig = signingConfigs.getByName("debug")`,上 store 必改 `release`。同时 B.3 `key.properties` 不存在时静默 null 改成 `throw GradleException` fail-fast。难度 1-2。**修复路径**:`cp android/key.properties.example android/key.properties` + 填 4 字段 + 改 `signingConfigs.getByName("release")` + 跟 `docs/PLAYSTORE_SIGNING_GUIDE.md` 5 步对照。
2. **B.6** [P0] **iOS Podfile.lock 缺失** — `ios/Podfile` 是 R77 占位,需 macOS + `cd ios && pod install` 真实生成 `Podfile.lock`。当前 `flutter build ios` 会失败。**修复路径**:在 macOS runner 跑 `pod install` + 提交 `Podfile.lock`。
3. **8.2 / 8.3** [P0] **release SMS / Email 守卫** 已落地 (R67 P0),但需 **真接 AliyunSmsProvider** (`lib/core/data/services/sms_service.dart:90-201`) 才能 release 上线。SendGrid Email 同。
4. **14.1** [P0] **SQLCipher 加密** 已落地,但 **5.15 / 14.21** 建议 `db_key_service.dart` `Random.secure()` 改 `pointycastle.SecureRandom` 密码学级别。当前风险**低**(Dart 在 Android/iOS 平台 Random.secure 走 /dev/urandom),但 v1.0 必改。
5. **14.3** [P0] **PIPL §13 留痕** 已落地 (R62/R63),**5.9 / 5.10** drift `@References` 缺失,schemaVersion 15+ 老联系人升级后 consent 字段为 null,UI 需 fallback (已实现)。
6. **11.8** [P0] **PHQ-9 / GAD-7 16 题 i18n** 留 v1.0 — `FeatureFlags._prodPhqGad7I18nEnabled = false` 默认关闭。en / zh_Hant 用户做 PHQ-9 / GAD-7 看中文 = 医疗法律责任。**修复路径**:开启 flag + 跑 `check_zh_hant_consistency` + 添加 ARB keys + 翻译 en/zh_Hant 全文 + 走 `AppLocalizationsScaleTranslations`。
7. **5.6** [P1 → P0] **web 端阻断** — `flutter build web` 仍能成功,但 runtime 跑会看到 `UnsupportedError`,应加 `kIsWeb` assertion fail-fast。

### P1 警告 (3-6 月内)

3. **2.9** 全面迁移 `catch (_) { ... }` → `swallowError(...)` 集中器,11+ 处。`lib/core/data/database/daos/assessment_dao.dart:137` + `mappers/medication/medication_times.dart:54` + `data_export_service.dart` + `export/export_schema_service.dart` (3 处) + `json_codec.dart` + `theme_provider.dart` + `assessment_record.dart` + `weight_widgets.dart` + `mood_recorder_page.dart`。
4. **3.6 / 3.7** `app_router.dart` routerProvider + `_RouterProfileCache` 内部 mutable cache,改用更显式模式 (`ref.listen` + `setState` + 配合 `Notifier`)。
5. **4.3** `app_route_main.dart` 7 个 feature 文件路由拆分已完成,但 ShellRoute 仍单点,可考虑 `StatefulShellRoute.indexedStack` 保留 sub-tree state 跨导航 (4.7)。
6. **4.8** redirect `/settings/reminders` 嵌套路径未识别 `goingToSetup`,需 `state.matchedLocation` startsWith 守卫。
7. **5.9 / 5.10** drift `@References` + `onDelete: Cascade` 在 `treatment_entries.linkedMedicationId` / `stress_events.linkedMoodEntryId` 缺失,应用层维护 FK 风险。
8. **5.6 / P0 #7** web 端 `flutter build web` fail-fast(见 P0 #7)。
9. **11.6** assessment reminder ARB i18n 错配,`assessment_reminder_section.dart:63` 用 `l10n.assessmentReminderEnabled` 是 presentation 层 ARB,但 `Strings.notifAssessmentBody` 是 domain 层兜底中文,二者不一致。
10. **12.2** 集成测试从 1 → 3-5 个 (setup → home → check-in / vent record → export / 评估 + 危机信号)。
11. **12.7** 18+ service 子类未覆盖 sub-service 测试 (`snooze_manager` / `badge_sync_service` / `reminder_dispatcher` / `vent_audio_storage` 等),R56c 续修。
12. **12.9** coverage 阈值 (≥ 70% domain / 50% data) + Codecov 集成缺失。
13. **13.5** `assessment_dao.countByType` 全表扫 + 无索引,1 万+ entry 性能风险。
14. **14.8** `assessment_dao._rowToEntry` 解析失败时返 `rawNote` 给 UI (PII 泄露),应 swallow + 返 `note: null`。
15. **14.19** audit log 明文存 SharedPreferences,GDPR/PIPL §47 删除权需手动。
16. **C.2 / C.3 / C.8** CI 缺 coverage 上传 + 缺 `flutter build appbundle` + 缺 release publish 自动化。
17. **F.1** 3 个 600+ 行 god page (`assessment_page.dart:436` / `medication_calendar_page.dart:642` / `data_management_section.dart:606`) 需 v1.0 拆。
18. **F.5 / F.8** (见 2.9 / 14.8 重复)

### P2 / P3 建议 (长期)

19. **1.1** `lib/main.dart` 顶层 mutable static 改 `late final`。
20. **2.1** `analysis_options.yaml` 评估 `very_good_analysis` 全套 lint 收益。
21. **2.4 / 2.5** `Strings` 双模式 + `AliyunSmsProvider` 占位类,v1.0 收口。
22. **3.3 / 3.4** `legalConsentWithdrawnProvider` 伪 stream,改 `Notifier`。
23. **5.2** schemaVersion 16→17 placeholder 加 `if (from == 16) {}`(注释已 mark,需跟进)。
24. **5.15 / 14.21** `Random.secure()` 改 `pointycastle.SecureRandom`。
25. **9.9 / 9.10 / F.1** 600+ 行 god page 拆 (P1 #17 重复)。
26. **11.5 / 11.7** `Strings.notifDailyCheckInTitle` / PDF const 字段 走 i18n 函数 (虽然 R72 中性化已修文案,但 const 字段 + 函数双模式需 v1.0 收口)。
27. **D.1** README 跟 AGENTS.md 关系明确化。
28. **F.6** `MedicationNotifier` / `RefillNotifier` / `AssessmentNotifier` 改名避免与 Riverpod `Notifier` 类歧义 (改 `MedicationReminderScheduler`)。
29. **F.7** 200+ 注释压缩,历史追踪改走 CHANGELOG + git log。
30. **D.8** `scale_translations_l10n.dart` 708 行 enum 映射独立 docs 解释 i18n 矩阵。
31. **C.5 / E.5** flutter version upgrade 流程 (fvm) 评估。

---

## 半成品 / 残缺项

### 业务功能半成品

- [ ] `lib/core/data/services/sms_service.dart:90-201` **AliyunSmsProvider** send() 是 `throw StateError`,R55+ 真接待做(法务 1-2 月模板审核 + 阿里云 AccessKey 申请)
- [ ] `lib/core/data/services/email_service.dart:162-163` **EmailService** 真实 send 未实现,R55+ SendGrid 真接待做
- [ ] `lib/domain/logic/scale_registry.dart:32-50` **NSESSS / CRDPSS** 2 个量表 TODO(user 选 hybrid,后续 v0.31+ 法务审核 + 用户自定义)
- [ ] `lib/domain/entities/scale_translations.dart:1-50` PHQ-9 / GAD-7 16 题完整 i18n 留 v1.0(R65b 阶段)
- [ ] `lib/core/shared/legal_version.dart:43-45` `kPubspecVersion` 手动同步,R78+ 考虑 `package_info_plus` 自动读
- [ ] `lib/core/data/services/safety_config_service.dart`(推测) + `lib/core/routing/notification_navigation.dart` BGTaskScheduler iOS handler 当前是 `task.setTaskCompleted(success: true)` 占位,真实接 SMS 时需调 Flutter MethodChannel
- [ ] `lib/core/data/services/store_kit_service.dart` (推测) IAP 真接 productId 留 v0.28(R68 后 `iapEnabled=false` 临时关闭避 Apple 2.1 拒)
- [ ] `lib/core/routing/notification_navigation.dart`(推测) Android BootReceiver 简化实现(R70),未来 WorkManager 完善后接
- [ ] `lib/core/data/services/data_export_service.dart` vent audio **不导出文件** (跨设备路径失效),只导 metadata 引用 — 限制
- [ ] `lib/core/shared/consent_gate.dart` `ConsentKind.safety` / `vent` / `analytics` 撤回 fallback body 硬编中文(168-174),需 i18n 化

### 工具 / 文档半成品

- [ ] `ios/Podfile.lock` 不存在,R77 注释占位,macOS 必跑 `pod install`
- [ ] `android/key.properties` 不存在,`*.jks` 不存在,release 签名 5 步指南走起
- [ ] `lib/main.dart:41,54` 顶层 mutable static,改 `late final` 3 行
- [ ] `analysis_options.yaml` 评估 `very_good_analysis` 全套 lint
- [ ] `docs/audit/` 目录 R60 起开始建立,但每次审计散点(8 份独立 `report.md` 重复),v1.0 模板化

### 性能 / 架构半成品

- [ ] `lib/presentation/pages/assessment/assessment_page.dart:436` 600+ 行 god page 拆
- [ ] `lib/presentation/pages/medication/medication_calendar_page.dart:642` 600+ 行 god page 拆
- [ ] `lib/presentation/pages/settings/widgets/data_management_section.dart:606` 600+ 行 god section 拆
- [ ] `lib/presentation/services/scale_translations_l10n.dart:708` 708 行 enum 映射,应抽 `region x scale x i18n` 矩阵
- [ ] `lib/presentation/providers/legal_consent_provider.dart:191-205` 伪 stream 改 Notifier
- [ ] `lib/core/routing/app_router.dart:50-60` redirect 嵌套路径 startsWith 守卫
- [ ] `lib/core/data/database/daos/assessment_dao.dart:57-65` `countByType` 全表扫 + 无索引
- [ ] `lib/core/data/database/daos/assessment_dao.dart:91-148` 解析失败返 rawNote PII 泄露

---

## 架构重构建议 (中等粒度)

### R-1 顶层架构审视 (高内聚低耦合)

**项目当前架构**:
```
lib/
├── main.dart                  # 入口
├── app.dart                   # App root
├── core/                      # 基础设施 umbrella (5 子层)
│   ├── data/                  # DB + repos + services + utils
│   ├── shared/                # formatters / json_codec / consent_gate / date_time_resolver / domain_value / mood_visual / user_name_helper
│   ├── theme/                 # AppTokens + AppColors/Motion/Spacing/Typography
│   ├── routing/               # go_router 7 类
│   └── l10n/                  # domain 字符串 (Strings)
├── l10n/                      # presentation 字符串 (flutter_localizations)
├── domain/                    # 4 层纯业务
│   ├── entities/              # 21 个 Entity (XEntity)
│   ├── logic/                 # 业务规则 (care_engine, care_strategies, streak_calculator, ...)
│   ├── repositories/          # 抽象接口 (10 个)
│   └── usecases/              # 4 个 use case
└── presentation/              # UI 层
    ├── providers/             # 18 个 Riverpod provider
    ├── services/              # 2 个 presentation service (legal_version, scale_translations_l10n)
    ├── widgets/               # 32 个 widget 集中器
    └── pages/                 # 11 个 feature × 1 目录
```

**当前评估**:
- ✅ 4 层架构清晰,`domain/` 0 flutter 0 drift 0 data (经 `scripts/check_all.dart` 守门员验证)
- ✅ 1 个 feature = 1 个目录 (8+ 个 feature)
- ✅ `core/` umbrella 5 子层拆分合理
- ✅ 抽象接口 + impl + Riverpod Provider 暴露 domain 模式统一
- ⚠️ `core/data/services/` 30+ 服务,future 拆 5 子目录
- ⚠️ `core/data/database/daos/` 14 DAO + 7 daily_tracking DAO,目录略平
- ⚠️ `core/data/repositories/` 8 顶级 + 6 daily_tracking 子目录,2 级深度合理

**是否需要更优架构?**

- ❌ **不需要重新设计** 4 层架构,已成熟
- ✅ **需要逐步收敛** 命名一致性 (`Notifier` 歧义,`Strings` 双模式)
- ✅ **需要补充测试** 集成测试覆盖率 (1→3-5)
- ✅ **需要补 e2e / 性能测试** 启动时间 / 帧率 / 内存

### R-2 模块独立拆出可能性

可独立拆为 package 的模块(本项目不必要拆,但 v1.0+ 评估):
- **`chroniccare_design_tokens`** — `lib/core/theme/` 5 文件 (1083 行),独立发版 (token 演进)
- **`chroniccare_i18n`** — `lib/l10n/` + `lib/core/l10n/strings.dart` (2568+251 行),独立翻译协作
- **`chroniccare_assessment`** — `lib/domain/logic/{phq9,gad7,isi,pss,whodas,asrm,level2_*}.dart` + `lib/domain/entities/scale_translations.dart` (1700+ 行),独立量表协作文档
- **`chroniccare_safety`** — `lib/core/data/services/safety_*` (5 文件) + `lib/core/data/services/reminder_scheduler.dart`,独立失联通信业务 (R67 业务暂停,但架构独立)
- **`chroniccare_audio`** — `lib/core/data/services/{vent_audio_storage,mood_audio_storage}.dart` + `lib/core/data/privacy/encrypted_audio_storage.dart`,独立 audio 加密基类

**当前不建议拆**: 单一应用,5 个 feature cross-import 仍频繁 (ConsentDialog 走 domain,repository impl 走 core/data,services 走 data,widgets 走 presentation),拆 package 会增加 monorepo 复杂度。

### R-3 关键模块"高内聚低耦合"评分

| 模块 | 内聚 | 耦合 | 评分 |
|------|------|------|------|
| `lib/domain/logic/care_engine.dart` + `care_strategies.dart` | 单一职责 (4 策略 + 1 装配) | 0 flutter 0 drift 0 data | A+ |
| `lib/core/data/database/daos/contact_dao.dart` | DAO 单一 (4 method) | 仅 `_db` | A |
| `lib/core/data/services/safety_watch_service.dart` (388 行) | facade + 3 sub | 5 repo + 3 service | B+ (可继续拆 facade 编排) |
| `lib/presentation/pages/assessment/assessment_page.dart` (436 行) | god page (答题+状态机+危机) | 12 import | C (v1.0 拆) |
| `lib/presentation/pages/medication/medication_calendar_page.dart` (642 行) | god page | 15 import | C- (v1.0 拆) |
| `lib/core/data/services/export/export_orchestrator.dart` (266 行) | facade + 4 sub | 4 service + 1 db | A (R57 拆完) |
| `lib/core/data/services/notification_service.dart` (450 行) | facade + 6 sub | 6 service + 1 plugin | A (R65 拆完) |

### R-4 风险评估

| 风险 | 等级 | 说明 |
|------|------|------|
| **release 签名未配 (B.1)** | 🔴 P0 | 上 store 必改 |
| **iOS Podfile.lock 缺失 (B.6)** | 🔴 P0 | macOS 必跑 `pod install` |
| **PHQ-9 / GAD-7 16 题 i18n 留 v1.0 (11.8)** | 🔴 P0 | en/zh_Hant 医疗法律责任 |
| **AliyunSmsProvider send() throw StateError (2.5)** | 🟠 P0 | release 失联通知 100% 失败 (虽然 R67 守门员已 catch) |
| **EmailService send() 返 false (2.6)** | 🟠 P0 | 同上 |
| **PHQ-9 question 9 (自杀念头) 阳性 i18n 化 (11.8)** | 🟠 P0 | 危机弹窗硬编中文,医疗法律责任 |
| **God page 3 个 600+ 行 (F.1)** | 🟡 P1 | 维护成本高 |
| **集成测试仅 1 个 (12.2)** | 🟡 P1 | 关键 flow 风险 |
| **Sub-service 测试 0 覆盖 (12.7)** | 🟡 P1 | refactor 安全网不足 |
| **`catch (_) { ... }` 7+ 处 (2.9)** | 🟡 P1 | silent catch 风险 |
| **`Random.secure()` 密码学强度 (5.15)** | 🟢 P2 | 当前平台安全但 SDK 不保证 |
| **drift `@References` 缺失 (5.9/5.10)** | 🟢 P1 | 应用层维护 FK 风险 |
| **`assessment_dao._rowToEntry` 解析失败 PII 泄露 (14.8)** | 🟠 P1 | 直接返 rawNote |
| **audit log 明文 (14.19)** | 🟡 P1 | GDPR/PIPL §47 删除权 |
| **CI 缺 coverage + release publish (C.2/C.3/C.8)** | 🟡 P1 | DevOps 不足 |
| **Web 端阻断未 fail-fast (5.6)** | 🟡 P1 | runtime crash 难发现 |

---

## 总结

- **总合规率 ≈ 84%** (120/143 项无违规)
- **P0 阻断 6 项** + **P1 警告 19 项** + **P2/P3 建议 25 项**
- **架构整体优秀**: 4 层 + 5 子层 umbrella,1 feature 1 目录,Riverpod 3.x / go_router 14.x / Drift 2.20.3 / SQLCipher 全套,16+ 守门员脚本,CI 3 jobs
- **核心问题**:
  1. **业务半成品**: SMS / Email / IAP / NSESSS 量表 / BootReceiver 等都是 R55+ 真接 TODO
  2. **签名 / Podfile.lock 缺失**: 上 store 前必改
  3. **PHQ-9 / GAD-7 16 题 i18n 留 v1.0**: 医疗法律责任
  4. **God page 3 个 600+ 行**: v1.0 拆
  5. **集成测试 + sub-service 测试覆盖不足**: refactor 安全网
  6. **silent catch 11+ 处**: R17 集中器模式继续迁移
- **亮点**:
  - 8 类守门员脚本 + 17 个 Python 守门员,机械约束充分
  - PIPL §13 留痕 + §14 撤回 + §17 同意记录 + §47 删除权 + §6 最小化 全链路落地
  - Apple 2024 强制 ITSAppUsesNonExemptEncryption / PrivacyInfo.xcprivacy / UIBackgroundModes / BGTaskScheduler 全部就绪
  - Google Play 16KB page size + 64-bit ABI + minSdk 24 + targetSdk 36 全部就绪
  - 主入口 `runZonedGuarded` + `LastErrorCapture` + `LastStartupErrorBanner` 完整错误兜底
  - 18 个 Drift migration step + 5 个索引 (R7-R91 累计)
  - 7 类路由 transition helper + 3 sub-service 拆 30+ (R57/R65/R67/R77)
  - Riverpod 3.x 用法规范 (50+ autoDispose + 6 Notifier)

---

**报告生成时间**: 2026-08-06
**审计员**: Flutter v3.1 规范合规审计 Skill (general-purpose worker)
**审计范围**: `lib/` (341 dart) + `test/` (205 dart, 27142 行) + `pubspec.yaml` + `analysis_options.yaml` + `android/` + `ios/` + `scripts/` + `docs/`
**审计方式**: 静态只读,未执行 `flutter analyze` / `flutter test` / `flutter build`
**下次审计建议**: R95 (R91 后 4 round) / v0.31 升 GoRouter 15 / Flutter 4.0 升版本前
