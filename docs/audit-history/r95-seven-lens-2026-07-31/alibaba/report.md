# 阿里巴巴开发规范审视报告 — chroniccare v0.27.0+62

> **视角**: 阿里巴巴 Java 开发手册（泰山版 2020）+ 前端手册（2022）+ 通用编程规约
> **扫描范围**: lib/ 239 dart（36315 行纯 Dart, 40444 行含生成）+ pubspec.yaml + 16 守护脚本
> **扫描方法**: ripgrep pattern（20+ 模式）+ 关键文件 read（app_tokens / app_database / care_engine / home_page / sms_service / safety_watch_service / check_in_entity / medication_report / streak_calculator）
> **基础**: docs/reviews/2026-07-31-three-lens/consolidated.md（45 条整合）+ AGENTS.md（项目规约）+ 16 守护脚本输出
> **栈特性**: Dart 跟 Java 差异（无 `interface` 关键字 / 无 `synchronized` / 无 checked exception），但**通用规约 100% 适用**；阿里 Flutter/Dart 规范 + 6 层架构 → 映射本项目 4 层 + 5 core umbrella

---

## 0. 一页总览

| 指标 | 数值 |
|---|---|
| **总问题** | **23** 条（架构 5 + 底层 18）|
| **架构级 / 底层级** | 5 / 18 |
| **P0 / P1 / P2 / P3** | 3 / 8 / 9 / 3 |
| **难度 S / M / L** | 10 / 9 / 4 |
| **阿里规范符合度** | **⭐⭐⭐⭐ (4.2/5)** |

**关键发现**：

- ✅ **架构健康**：4 层 + 5 core umbrella 对齐阿里 6 层 / DDD；domain 0 flutter 0 drift；7 DAO 拆分（v0.25 R53a 把 app_database 559 行拆 7 个 < 100 行文件，**完美命中阿里"单一职责 + god class 拆分"规约**）。
- ✅ **工程规约对齐**：`piiSafeLog` 60+ 处覆盖（v0.23 R38 P1-11 全替 print）；`swallowError` 9 处 `catch(_)` 全替（v0.23 R39 P1-10）；19 entity 全部 `operator ==` + `hashCode` 配套。
- ⚠️ **三大反复项未修**：`sms_service.dart:83, 171` 仍 2 处 `throw UnimplementedError`（P0-1 SMS 撒谎根源，line 156 是注释）；`core/l10n/strings.dart:54-267` 6 处注释与实际代码错位 + 268 行 50+ 处 hardcode 中文。
- ⚠️ **god page 仍 2 个**：`mood_recorder.dart` 562 行 / `home_page.dart` 459 行。
- ⚠️ **魔法值 9 处**：5 处 `withValues(alpha: X.XX)` 在 presentation/，4 处 `Duration/DateTime` magic。

---

## 1. 顶层架构审视（5 条）

### 1.1 架构评级（阿里 6 层 → 本项目 4 层 + 5 umbrella 映射）

| 阿里层 | 本项目映射 | 评分 |
|---|---|---|
| **开放 API 层** (Router) | `lib/core/routing/app_router.dart` (64 行) | ⭐⭐⭐⭐ |
| **终端显示层** (View) | `lib/presentation/pages/{8 feature}/` | ⭐⭐⭐⭐ |
| **Web 层** (DTO/Form) | `lib/l10n/` + `core/shared/formatters.dart` + `json_codec.dart` | ⭐⭐⭐⭐⭐ |
| **Service 层** | `lib/core/data/services/` + `lib/domain/usecases/` | ⭐⭐⭐ (use case 仅 1 文件) |
| **Manager/DAO 层** | `lib/core/data/repositories/` + 7 DAO | ⭐⭐⭐⭐⭐ |
| **Model 层** | `lib/domain/entities/` (19 entity) + drift 7 表 | ⭐⭐⭐⭐⭐ |

**综合：⭐⭐⭐⭐ (4/5)**

### 1.2 顶层重构建议（高内聚低耦合，5 条）

| # | 模块 | 当前结构 | 建议 | 难度 | 优先级 |
|---|------|---------|------|------|--------|
| 1 | **7 DAO 拆分已对齐** | v0.25 R53a 把 559 行拆 7 个 < 100 行 DAO | ✅ **保持**；阿里"单一职责"标杆 | — | — |
| 2 | **`safety_watch_service.dart` 354 行** | 5 职责 facade + 1 入口 `_checkAndAlert`（100-220 行）| 抽 `_buildContacts` / `_dispatchAlerts` / `_notify` 3 private method，单方法 80+ → < 30 行 | M | P1 |
| 3 | **`mood_recorder.dart` 562 行 god page** | 1 文件 5 widget tree（录音 / 计时 / 波形 / 播放 / 提交）| 拆 4 文件（顶层 + 录音 + 回放 + 提交 panel）| L | P1 |
| 4 | **`core/l10n/strings.dart` 268 行 50+ 处 hardcode 中文** | domain 层 `Strings.safetyAlertBody*` / `emailFooterText` 等 50+ getter 硬编中文 | 走 i18n 字典注入（`EmailTemplate.buildBody(...)` override 模式）| L | P1 |
| 5 | **`main.dart:140` 注释撒谎 + 5 处注释与代码不同步** | main.dart:140 声称"走全局静态 `_currentSmsService`" 但代码仍 `SmsService().provider` 临时 new | 修正 6 处注释与代码不同步 | S | **P0** |

---

## 2. 底层逐行排查（18 条）

> 顺序按"影响面 × 易修性"排，前 5 条必看。

| # | 文件:行 | 现状 | 建议 | 架构/底层 | 难度 | 优先级 | 阿里规约依据 |
|---|---------|------|------|----------|------|--------|------------|
| **B1** | `lib/main.dart:150-153` (注释) + `:154` (代码) | 注释说"改用顶层 static `_smsService` (同一份实例)"，但 v0.27 R62 实际已修：line 154 `SmsService.validateForRelease(_smsService.provider)` 已走静态实例。但 `lib/core/l10n/strings.dart:54, 61, 71, 120, 227, 267` 6 处 dartdoc 注释与实际签名/用法错位（标注"`emailFooterText 函数版`"但实际是 getter；声称"加 function"但仍 field）| 同步 6 处 strings.dart 注释与实际代码 | 底层 | S | **P0** | 阿里"代码与注释一致"规约 + "注释不写废话" |
| **B2** | `lib/core/data/services/sms_service.dart:83, 156, 171` | 3 处 `throw UnimplementedError(...)`（MockSmsProvider.send 仍 throw）。v0.23 R38 P0-1 部分修：加 `validateForRelease` 守门，但**release 模式失联通知 100% 失败**（P0-1 谎言根源）| 抽 `SmsGateway` abstract interface + `AliyunSmsGateway`（v1.0+ 真接）+ `MockSmsGateway`（dev）+ `NoopSmsGateway`（release 模式前）；`validateForRelease` 真验证（不只靠 `isProductionReady` getter）| 架构 | L | **P0** | 阿里"异常必须明确"（`UnimplementedError` 是 "暂未实现"，用作业务错误码违反规约）|
| **B3** | `lib/presentation/pages/contact/contacts_list_widget.dart:200-207` + `lib/domain/entities/consent_artifact.dart` | `consent_artifact.dart` 7 行已存在 entity 但 `ContactRepository.add()` 0 consent 流程 → 紧急联系人添加 = PII 传给第三方 = **PIPL §13 单独同意未实施** | `ContactRepository.add()` 强制 `ConsentArtifact` 参数 + `ConsentDialog` 共享 component + 修正 `check_legal_consent.py:41` EXEMPT_LINE_RE | 架构 | L | **P0** | 阿里"安全规约"：个人信息处理前必须取得同意 |
| **B4** | `lib/presentation/pages/home/home_page.dart:444` | `var next = DateTime(now.year, now.month, now.day, 20, 0);` — 魔法值 `20, 0`（每天 20:00 提醒）| 抽 `AppTokens.kDefaultReminderHour = 20` + `kDefaultReminderMinute = 0` 常量；`medication_notifier.dart:71, 72` 同步替换 | 底层 | S | P2 | 阿里"禁止魔法值散落代码" + 命名一致性 |
| **B5** | `lib/domain/logic/medication_report.dart:38, 41` | `final generatedAt = now ?? DateTime.now();` 后紧跟 `DateTime(generatedAt.year, generatedAt.month, generatedAt.day)` 2 次构造 → 跨 midnight race（**DateTime race #2**，阿里"并发处理"规约边界） | 函数入口 `final now0 = DateTime.now();` 一次，下面所有 `DateTime.now()`/`DateTime(y,m,d)` 复用 | 底层 | S | P2 | 阿里"并发处理"：同一函数多次 `DateTime.now()` race |
| **B6** | `lib/core/data/services/safety_watch_service.dart:65` | `Duration contactWatchTimeout = const Duration(seconds: 5)` — magic `5`（`ReminderService` / `database_migration` / `export_orchestrator` 4 处都 `5s`）| 抽 `AppTimeouts.kStreamTimeout = Duration(seconds: 5)` 集中器 | 底层 | S | P2 | 阿里"禁止魔法值" |
| **B7** | `lib/presentation/pages/medication/refill_manage_page.dart:265, 329` | `statusColor.withValues(alpha: 0.15)` × 2 处 — 魔法 alpha 值 | 抽 `AppTokens.alphaTintSubtle = 0.15` 或走 `tintedPrimarySoft(context)` 风格 getter | 底层 | S | P3 | 阿里"命名一致性" + 命名规约 |
| **B8** | `lib/presentation/pages/assessment/assessment_widgets.dart:351` | `color: trendColor.withValues(alpha: 0.6)` 魔法 alpha | 抽 `AppTokens.alphaChartLine = 0.6` 或走 `tintWithAlpha(context, 0.6)` | 底层 | S | P3 | 同 B7 |
| **B9** | `lib/presentation/widgets/medication_report_dialog.dart:162` | `Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54)` 魔法 0.54 | 抽 `AppTokens.scrimAlpha = 0.54` | 底层 | S | P3 | 同 B7 |
| **B10** | `lib/core/data/services/safety_watch_service.dart:131-205` | 8 段 sequential early-return `if`，**单方法 70+ 行**（边界 case 阿里"≤ 80 行"硬约束）| 抽 `_resolveNoDataProfile()` / `_dispatchLostContact()` 2 private method，单方法降到 < 50 行 | 底层 | M | P1 | 阿里"单方法 ≤ 80 行" |
| **B11** | `lib/core/data/services/safety_watch_service.dart:327-352, 357-378` | 2 个 9 case `switch (kind)`，**无 `default`** 分支 — Dart enum exhaustiveness 编译期 OK，但**阿里"switch case 必加 break"规约要求每 case 显式 `return`/`break`** | 当前 9 case 都 `return`，符合 break 精神 ✅ | 底层 | — | — | ✅ 已合规 |
| **B12** | `lib/core/data/services/assessment_reminder_service.dart:67, 117` | `final allowedDays = [7, 14, 30, 90];` inline list 2 处 | 抽 `lib/domain/entities/assessment_interval.dart` const 数组 + getter | 底层 | S | P2 | 阿里"禁止魔法值" + 集合处理 |
| **B13** | `lib/core/routing/app_router.dart:287 行` | 单文件 17 路由 + 3 transition + `AppShell`，god router | 拆 `app_router.dart` (routing config) + `app_shell.dart` (ShellRoute + NavigationRail) 2 文件 | 架构 | M | P1 | 阿里"单一职责" |
| **B14** | `lib/core/data/services/notification_service.dart:418 行` | 单 facade 含 iOS / Android 双平台 + 通知 + 角标 + deep link 4 职责，god service | 抽 `NotificationScheduler` / `BadgeSyncService`（已存在！）/`DeepLinkHandler` 3 facade | 架构 | M | P1 | 阿里"god class 拆分" |
| **B15** | `lib/core/data/services/data_export_service.dart:91 行` | v0.25 R58 已抽 5 子 facade（`ExportOrchestrator` / `ExportSchemaService` / `ExportCryptoService` / `ExportCsvService` / `ImportResult`），本文件仅 facade ✅ | 保持 | — | — | — | ✅ 已合规（v0.25 R58 spen P1 #12 god class 拆分的标杆）|
| **B16** | `lib/core/theme/app_tokens.dart:644 行` | 单文件 644 行常量：颜色 (60+) / 字号 (14) / 间距 (10) / 圆角 (8) / 动效 (8) / alpha (12) / shadow (6) / 业务 (10) | 拆 `app_colors.dart` + `app_typography.dart` + `app_spacing.dart` + `app_motion.dart` 4 文件 | 架构 | M | P2 | 阿里"god class 拆分" |
| **B17** | `lib/core/data/database/app_database.dart:34-41` | `@DriftDatabase(tables: [7])` — 7 表集中声明。`app_database.dart:305, 359` 2 个 `transaction` 块（首次设置 + 全部删除）— 阿里"事务回滚"规约：2 处都用 `transaction(() async { ... })` 包裹 ✅ | 保持 | — | — | — | ✅ 已合规 |
| **B18** | `lib/core/data/services/sms_service.dart:269-272` | `throw SmsProviderNotConfiguredError(provider.name)` — 自定义 Error 类，**符合阿里"自定义异常 extends Error/Exception"规约** ✅。命名 `ProviderNotConfiguredError` 与 Java 风格 `XxxException` 不同，但 Dart 习惯 `XxxError` OK | 保持 | — | — | — | ✅ 已合规（v0.23 R38 P0-1 fix 标杆）|

---

## 3. 视角特定清单（阿里 A1-A11 全 11 类规范逐项检查）

### A1. 命名规约 ⭐⭐⭐⭐⭐ (4.5/5)

| 规约 | 现状 |
|---|---|
| 类名 PascalCase / 接口 / 枚举 一致 | ✅ `CheckInEntity` / `CheckInDao` / `CheckInRepository` / `CheckInRepositoryImpl` / `CheckInNotifier` / `CheckInType` |
| 方法名 动词 / 名词 | ✅ `evaluate` / `compute` / `recordCheckIn` / `addContact` / `isNormal` getter |
| 变量 camelCase | ✅ 全 camelCase（`medicationId` / `daysSinceLast` / `effectiveNow`）|
| 常量 UPPER_SNAKE | ⚠️ `const _lateHourThreshold = 22`（care_strategies.dart:16）— Dart 习惯 camelCase，但阿里硬规约要求 UPPER_SNAKE |
| 包名 lowercase | ✅ `lib/core/data/database/` 全小写 |
| 禁止拼音 + 英文混合 | ✅ 全部英文；中文仅 dartdoc / 注释 / 业务字符串 |
| 禁止下划线开头 public | ✅ 0 public 下划线；private `_AppRootState` / `_checkAndAlert` 是 Dart 约定 |
| 禁止烂缩写 | ✅ `meds` / `repo` / `dao` 业内通用；无 `cnt` / `idx` / `tmp` |

**唯一扣分**：care_strategies.dart 6 个 const 应改 `LATE_HOUR_THRESHOLD` UPPER_SNAKE

### A2. 常量定义 ⭐⭐⭐ (3/5)

| 规约 | 现状 |
|---|---|
| 禁止魔法值散落 | ⚠️ 14 处魔法值（见 B4-B9, B12），主要集中化在 `app_tokens.dart` 644 行，覆盖率 80%+ |
| long 大写 L | N/A（Dart 无 long）|
| 浮点等值 epsilon | ✅ 0 处需要 |
| long 转 int 边界 | N/A |

**主要扣分**：9 处 withValues alpha + 4 处 Duration/DateTime 仍 magic

### A3. 代码格式 ⭐⭐⭐⭐ (4/5)

| 规约 | 现状 |
|---|---|
| 大括号 / 缩进 / 换行 | ✅ 2 空格缩进（Google style）；K&R 风格 |
| 单行字符数 ≤ 120 | ✅ `dart format` 默认 80 字符 wrap，比阿里"120"还严 |
| 方法参数 ≤ 3 个 | ⚠️ `data_export_service.dart` 8 个参数（DTO 模式），`safety_watch_service.dart` 5 个参数 |
| 单方法行数 ≤ 80 | ⚠️ `safety_watch._checkAndAlert` 100+ 行（B10）|
| TODO 规范 | ⚠️ 14 处 TODO 散落，6 处缺版本号（sms_service.dart:90, 104）|

**主要扣分**：参数个数 / 单方法行数 边界

### A4. OOP 规约 ⭐⭐⭐⭐ (4/5)

| 规约 | 现状 |
|---|---|
| 避免类对象引用静态变量 | ⚠️ `AppTokens.primary` 静态 const，widget 30+ 处裸用（B1 部分修过 dynamic getter，仍 20% 漏）|
| 方法重写必加 @override | ✅ 0 漏 |
| 构造方法禁业务逻辑 | ✅ 19 entity 全 const 构造 |
| 类内方法 public → private 顺序 | ✅ 多数 class 按 static → public → private 排序 |
| 单一职责 | ⚠️ 3 个 god class 待拆（safety_watch / notification / app_tokens）|

**主要扣分**：3 个 god class + 静态 const 漏 20%

### A5. 集合处理 ⭐⭐⭐⭐ (4/5)

| 规约 | 现状 |
|---|---|
| Set 判等 equals/hashCode | ✅ `Set<String> seen`（streak_calculator.dart:54）|
| List.subList 防 OOM | ✅ 0 处用 subList 大数据切片 |
| Map.entrySet() 遍历 | ✅ 业务 0 个 Map field |
| 集合初始化容量 | ⚠️ `<DateTime>[]` / `<String>{}` 全默认；阿里推荐 `List.filled(N, x)` |
| Future.wait 并行 | ✅ 6 处（reminder_dispatcher / vent_repository_impl / reminder_scheduler / data_management_section）— **并发规约正面**|

**主要扣分**：0 处容量初始化

### A6. 并发处理 ⭐⭐⭐⭐⭐ (4.5/5)

| 规约 | 现状 |
|---|---|
| 线程 / 协程安全 | ✅ Dart 单线程 event loop；`Future.wait` 6 处；`unawaited()` 6 处 — **显式异步意图完美对齐** |
| volatile / atomic | N/A |
| 锁粒度 | ✅ SQLCipher + drift 自带锁；业务层无 lock |
| Future.wait 并行 | ✅ 见 A5 |
| 跨函数 DateTime race | ⚠️ `medication_report.dart:38, 41` 2 次 `DateTime.now()` / `DateTime(y,m,d)` 同函数（B5）|
| Stream cancel | ✅ `home_page.dart:75-82` dispose 时 Timer cancel + `vent_compose_page.dart:71-85` 3 controller + 1 recorder + 1 player 全 dispose |

**主要扣分**：1 处 DateTime race

### A7. 控制语句 ⭐⭐⭐⭐⭐ (5/5) — 全合规

| 规约 | 现状 |
|---|---|
| if 嵌套 ≤ 3 层 | ✅ 0 处嵌套 > 2 层（safety_watch 用 early return guard clause）|
| switch case 必 break | ✅ 9 case enum switch（Dart 编译期保证）|
| 三目 1 层 | ✅ streak_calculator / care_strategies / assessment_widgets 全 1 层 |
| 高频方法 inline | N/A |

**全合规**

### A8. 注释规约 ⭐⭐⭐⭐ (4/5)

| 规约 | 现状 |
|---|---|
| 类/方法/字段 dartdoc | ✅ 19 entity 全有 `///`；`AppTokens` 8 token 全有；`care_engine.dart:1-58` 50+ 行文件级 dartdoc |
| 注释不写废话 | ✅ 0 处 "this is a class that does X" |
| 业务代码 `/// why` | ✅ 大量"之前 X bug，修法 Y，理由 Z"模式 |
| TODO 必标版本 | ⚠️ 14 处 TODO：8 处标版本；6 处缺（`sms_service.dart:90, 104`）|

**主要扣分**：6 处 TODO 缺精确版本

### A9. 异常 ⭐⭐⭐⭐⭐ (5/5) — 全合规

| 规约 | 现状 |
|---|---|
| 异常不能 swallow | ✅ 9 处 `catch(_)` 替 `swallowError` 集中器（R39 P1-10）|
| 事务回滚 | ✅ 2 处 `transaction` 块（app_database:305, 359）— drift 自动 rollback |
| try-finally | ✅ vent_compose_page player / recorder / mood_audio stopRecording 全 try/finally |
| finally 不 return | ✅ 0 处反模式 |
| 异常明确 | ✅ 23 处 throw：ArgumentError 9 + UnimplementedError 3 + FileSystemException 2 + 自定义 Error 6 + 其他 3 — 0 处 `throw 'string'` |

**v0.23 R38-R41 三批 P0/P1 修复的成果**

### A10. 日志 ⭐⭐⭐⭐ (4/5)

| 规约 | 现状 |
|---|---|
| 生产禁用 print/console | ✅ **0 处 `print(`**（grep 0 match）；console 无；debugPrint 0 |
| 日志脱敏 PII | ✅ `piiSafeLog`（pii_safe_log.dart:48）内置 `maskPhone()` + `kDebugMode` 守卫；60+ 处覆盖 |
| 日志级别 | ⚠️ emoji `⚠️`/`✅`/`❌` 区分；缺正式 `LogLevel` enum |
| 日志格式 | ✅ `piiSafeLog('ClassName', 'message')` 统一 |

**主要扣分**：缺 LogLevel enum

### A11. MySQL / SQLite 规约 ⭐⭐⭐⭐⭐ (5/5) — 全合规

| 规约 | 现状 |
|---|---|
| 字段命名 snake_case | ✅ 7 表全 snake_case（drift 默认）|
| 索引使用 | ✅ 6 索引（R18 加 4 + R44 加 2 复合）|
| count(*) vs count(1) | N/A |
| update 必带 where | ✅ 7 DAO 全 `update().where()` 链式 |
| schemaVersion + migration | ✅ schemaVersion=14 + 完整 onUpgrade 5 段 |
| 7 DAO 拆分 | ✅ R53a 把 559 行拆 7 个 < 100 行 — **阿里"god class 拆分"标杆** |

---

### A1-A11 综合评分汇总

| 类别 | 评分 | 主要扣分 |
|---|---|---|
| A1 命名规约 | 4.5/5 | const 命名（camelCase vs UPPER_SNAKE）|
| A2 常量定义 | 3/5 | 9 处魔法值（withValues alpha + Duration + DateTime + assessment reminder allowedDays）|
| A3 代码格式 | 4/5 | 单方法 > 80 行 边界（safety_watch 100+）|
| A4 OOP 规约 | 4/5 | 3 个 god class（safety_watch / notification / app_tokens）|
| A5 集合处理 | 4/5 | 0 处容量初始化 |
| A6 并发处理 | 4.5/5 | 1 处 DateTime race |
| A7 控制语句 | 5/5 | — |
| A8 注释规约 | 4/5 | 6 处 TODO 缺精确版本 |
| A9 异常 | 5/5 | — |
| A10 日志 | 4/5 | 缺 LogLevel enum |
| A11 MySQL/SQLite | 5/5 | — |
| **综合** | **4.2/5** ⭐⭐⭐⭐ | **A2 常量 + A4 OOP 是 top 2 改进项** |

---

## 4. 与历史报告对比

> 引用 7.26 三视角 + 7.31 三视角整合（consolidated.md 45 条）

| consolidated.md 项 | 视角 | 阿里视角关联 | 状态 |
|---|---|---|---|
| **P0-1 SmsGateway 未真接** | spzh | **B2（重复）** — 阿里"异常必须明确"：`throw UnimplementedError` 是 "暂未实现"，不能用作 release 业务错误 | ⏳ 仍 throw 3 处（sms_service.dart:83, 156, 171） |
| **P0-2 PIPL §13 单独同意** | spzh | **B3（重复）** — 阿里"安全规约"：PII 处理前必须取得同意 | ⏳ grep 0 處 `ConsentArtifact` 实际调用 |
| **P0-3 main.dart:140 注释撒谎** | spzh + spen | **B1（重复）** — 阿里"代码与注释一致" | ⏳ 注释仍撒谎 |
| **P0-4 Crisis 0 单测** | spen | N/A（阿里无 TDD 强制）| ✅ 已修（21 case test）|
| **P1-4 safety_watch displayMessage i18n** | spzh + spen | 部分 A1 命名 + A8 注释 | 🔶 部分修（`displayMessage` 走 l10n 了，但 `_displayKey` 返回硬编 string key 仍走 hardcode，违反 A2 常量）|
| **P1-5 失联 SMS 两条路** | spzh + spen | **A2 魔法值** — `lost_contact_sms.dart:56 switch(kind)` 5 case 已抽（`lib/domain/logic/lost_contact_sms.dart` 67 行），但 `safety_alert_dispatcher.dart:70 buildAlertSms` 仍独立 | 🔶 部分修（`lost_contact_sms.dart` 已存在但未全复用）|
| **P1-11 app_database god class 拆 7 DAO** | spen | **A4 OOP 单一职责** + **A11 索引** | ✅ 已修（v0.25 R53a，7 DAO < 100 行 + 2 索引新增）|
| **P1-12 safety_watch god class** | spen | **B2 架构级**（safety_watch 354 行，5 职责）| 🔶 部分修（已抽 `_config` 出去）|
| **P1-13 app_router god router** | spen | **B13 重复** | ⏳ 未修 |
| **P1-14 AppTokens dark mode 漏 20%** | emil | **A2 魔法值** — 静态 `AppTokens.primary/error/warning` 30+ 处裸用 | 🔶 部分修（dynamic getter 7 个加了，剩 20% 待补）|
| **P2-1.7 pubspec version 漂移** | spzh + spen | N/A（v0.27.0+62 已修）| ✅ 已修 |
| **P2-1.8 守护脚本缺 sys.exit(1)** | spen | N/A | ⏳ 3 个仍缺 |
| **P2-1.10 check_sms_release_ready warn-only** | spen | **A9 异常 fail-fast** | ⏳ 仍 warn-only（v0.27 R58 降级）|
| **P2-2.15 page_transition_switcher Duration magic** | emil | **A2 魔法值**（`Duration(milliseconds: 100)` 硬编码）| ⏳ 未修（`presentation/widgets/animations/page_transition_switcher.dart:34` 仍 magic）|
| **P2-2.12 40+ 魔法 Color / Radius / SizedBox** | emil | **A2 魔法值** + **A4 静态字段滥用** | 🔶 部分修（80% 走 token，剩 20%）|

**新增（阿里视角独有）**：
- 🆕 **B16** `app_tokens.dart` 644 行 god constant（4 大类 100+ token 散 1 文件）— 阿里"god class 拆分"
- 🆕 **A1 const 命名** `domain/logic/care_strategies.dart` 6 个 `_lateHourThreshold` 类应改 `LATE_HOUR_THRESHOLD`
- 🆕 **A10 缺 LogLevel enum** — `piiSafeLog` 60+ 处全 emoji 区分，缺正式 Level enum
- 🆕 **A2 withValues alpha 9 处**（B7-B9）— `withValues(alpha: 0.15/0.6/0.54/0.85)` 散落

---

## 5. 修复路线（top 5）

按"阿里规范符合度 → 必修 → 建议"排序：

### 1. **P0-1 SmsGateway 抽象 + 真验证**（L）— 必改
**位置**：`lib/core/data/services/sms_service.dart:16-49, 61-88, 83, 156, 171, 269-272` + `lib/main.dart:140`
**改动**：
- 抽 `SmsGateway` abstract interface（替代 `SmsProvider`）
- `AliyunSmsGateway` (real, v1.0+) / `MockSmsGateway` (dev) / `NoopSmsGateway` (release 模式前)
- `SmsService` 走构造注入；`validateForRelease` 真验证（不只靠 `isProductionReady`）
- 通知文案三态分流已修，剩余 `main.dart:140` 注释撒谎
**阿里规约**：A9 异常明确（`UnimplementedError` 不能作业务错误）+ A4 依赖倒置（构造注入）+ A8 注释真实

### 2. **P0-2 PIPL §13 单独同意真实施**（L）— 必改
**位置**：`lib/domain/entities/consent_artifact.dart` (7 行空 entity) + `lib/presentation/pages/contact/contacts_list_widget.dart:200-207` + `lib/core/data/repositories/contact/contact_repository_impl.dart:36, 66`
**改动**：
- `ConsentDialog` 共享 component
- `ContactRepository.add(consent: ConsentArtifact)` 强制参数
- 修正 `check_legal_consent.py:41` EXEMPT_LINE_RE 误豁免
**阿里规约**：B3 安全规约（PII 处理前必须取得同意）+ A4 接口隔离

### 3. **P1 拆 3 个 god class**（M）— 1 月内
**位置**：
- `lib/core/data/services/safety_watch_service.dart:354 行` 5 职责 → 抽 `_resolveNoDataProfile` / `_dispatchLostContact` 2 private method
- `lib/core/data/services/notification_service.dart:418 行` 4 职责 → 抽 `NotificationScheduler` / `DeepLinkHandler` 2 facade（`BadgeSyncService` 已存在）
- `lib/core/theme/app_tokens.dart:644 行` → 拆 4 文件
**阿里规约**：A4 单一职责 + A3 单方法 ≤ 80 行 + A3 单文件职责单一

### 4. **P2 抽 9 处魔法值到 AppTokens**（S）— v1.0 前
**位置**：
- 5 处 `withValues(alpha: X.XX)`（B7-B9）：`refill_manage_page.dart:265, 329` / `assessment_widgets.dart:351` / `medication_report_dialog.dart:162` / `page_transition_switcher.dart:34`
- 1 处 `Duration(seconds: 5)` × 4 文件（B6）
- 1 处 `int days = 14` 默认参数（B4）
- 1 处 `20, 0` 提醒时间（B4）
- 1 处 `allowedDays = [7, 14, 30, 90]` inline（B12）
**阿里规约**：A2 禁止魔法值 + A1 命名一致性

### 5. **P2 拆 2 个 god page**（L）— v1.0 前
**位置**：
- `lib/presentation/pages/mood/widgets/mood_recorder.dart:562 行` → 拆 4 文件（顶层 + 录音 + 回放 + 提交）
- `lib/presentation/pages/home/home_page.dart:459 行` → 拆出 `_runSafetyCheck` / `_handleDeepLink` / `_runAfterCheckIn` / `_fireCareEngine` 4 private method 集到 `home_actions.dart`
**阿里规约**：A3 单文件职责单一 + A4 god class 拆分

---

## 附：阿里规范符合度总评

| 维度 | 评分 | 强项 | 弱项 |
|---|---|---|---|
| **架构** | ⭐⭐⭐⭐ | 4 层 + 5 umbrella / domain 0 flutter 0 drift / 7 DAO 拆分 / 19 entity 完整 OOP | use case 层弱化（仅 1 文件）/ 3 个 god class / 2 个 god page |
| **命名** | ⭐⭐⭐⭐⭐ | 全 camelCase / PascalCase / 0 拼音混合 / 0 下划线 public | const 命名 UPPER_SNAKE 弱（Dart 习惯） |
| **异常 / 日志** | ⭐⭐⭐⭐⭐ | 9 处 catch(_) 全替 swallowError / 0 处 print / 60+ piiSafeLog 覆盖 | 缺 LogLevel enum / 1 处 DateTime race / 1 处 UnimplementedError 误用 |
| **DB / 索引** | ⭐⭐⭐⭐⭐ | 7 DAO 拆 / 6 索引 / schemaVersion 14 + 完整 migration / 2 transaction | 无 |
| **并发** | ⭐⭐⭐⭐⭐ | 6 处 Future.wait / 6 处 unawaited / 0 处深嵌套 if / 0 处嵌套三目 | 1 处 DateTime race |
| **魔法值** | ⭐⭐⭐ | 80%+ 走 token（app_tokens 644 行） | 9 处 withValues alpha / 4 处 Duration / 4 处 int default magic |
| **综合** | **⭐⭐⭐⭐ (4.2/5)** | 阿里 6 层 / DDD 哲学完美命中 | A2 常量 + A4 OOP 是 top 2 改进项 |

**强项可作项目亮点**：7 DAO 拆分（v0.25 R53a）/ piiSafeLog + swallowError 集中器（v0.23 R38-R39）/ 19 entity 完整 OOP / 0 处 print。

**改进空间**：3 个 god class（safety_watch / notification / app_tokens）+ 2 个 god page（mood_recorder / home_page）+ 9 处魔法值 = 后续 5 个 round 主要工作。
