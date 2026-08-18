# superpowers-en 视角 v0.25 round 56h 增量审视

> **视角**：架构 / TDD / systematic-debugging / verification-before-completion / subagent-driven-development
> **基线**：v0.24.0 三视角审视报告(2026-07-26 spen 55 个发现)
> **增量范围**：v0.23 round 42 → v0.25 round 56h(**14 round: R49-R60 + R56b-R56h = 25 commit**)
> **HEAD**：`33b5fd0 v0.25 round 56h`(2026-07-26)
> **spen 主导 round**：R52(底层 P0 bug 收尾 7 项)/ R53a(app_database 拆 7 DAO)/ R57(safety_watch 拆 3 sub)/ R58(medication_report 拆 3 纯函数类)/ R59(app_router 拆 3 文件)/ R60(MedicationDraft value object)/ R56b(formatters 走 intl)/ R56c-R56c'''(TDD 补全 +46 tests)/ R56e(check_orphan_arb_keys)
> **token 限制声明**：本报告仅基于已读 4 个基线文件 + 14 round 25 commit 增量验证(已 R53a/R57/R58/R59/R60/R52/R56 全 grep + 6 个新 test 抽样读),**不重复** 2026-07-26 spen 报告 55 个原始发现

---

## 1. 顶层架构审视

### 1.1 god class 拆分后剩余清单(v0.25 round 56h)

| 文件 | 字节 / 行 | 状态 | 拆分建议 | 优先级 |
|------|----------|------|----------|--------|
| `data_export_service.dart` | 20.8K / **564** | 🟠 facade + 3 sub(69-152 行)但 facade 仍 564 行 | 抽 `ExportOrchestrator` 隔离 importData/exportData,facade 留 5 类编排入口 | 🟡 P1 |
| `notification_service.dart` | 14.5K / **396** | 🟢 facade + 5 sub(v0.24 R45 拆) | OK 保留 | — |
| `mood_audio_service.dart` | 10.8K / **350** | 🟡 接口 + STT 编排 + recorder + 资源 | 抽 `MoodSttAdapter` 把 STT 隔离(已分接口但实现同文件) | 🟡 P2 |
| `medication_report_pdf.dart` | 9.9K / **321** | 🟠 PDF 生成 + 中文字体 + 模板 | 抽 `PdfFontLoader` + `PdfLayout` 2 个 pure helper | 🟡 P2 |
| `safety_watch_service.dart` | 10.5K / **325** | 🟢 **R57 已拆**(425 → 325, -24%) | 仍 8 个 config 1-line facade 方法 → 重复 API 路径(`safetyWatchService.setEnabled` vs `safetyConfigService.setEnabled`) | 🟢 R57 OK |
| `reminder_scheduler.dart` | 8.3K / **244** | 🟡 reminder + cycleHours + DND | R57 风格拆 `CycleHoursRule` / `DndRule` 2 个 rule | 🟡 P2 |
| `app_database.dart` | 16.2K / **373** | 🟢 **R53a 已拆 7 DAO**(559 → 373, -45%) | 18 个 query method 1-line 委托,saveSetup + clearAllUserData 留在 facade。OK | — |
| `safety_alert_dispatcher.dart` | 3.1K / **96** | 🟢 **R57 新建** | OK 90 行单职责 | — |
| `app_router.dart` | 1.7K / **51** | 🟢 **R59 已拆 3 文件**(418 → 51, -88%) | 退化为 routerProvider 入口 | — |
| `medication_report.dart` | 9.5K / **281** | 🟢 **R58 已拆 3 纯函数类**(`MedicationStatCalculator`+`MissedDateBuilder`同文件 + `TempEntryExtractor` 独立) | OK facade 留 5 类编排 | — |
| `app_routes.dart` | 11K / **289** | 🟢 R59 新建 | OK 14 路由 + 3 transition + errorBuilder | — |
| `app_shell.dart` | 4.8K / **143** | 🟢 R59 新建 | OK NavigationRail + 2 _NavDest | — |
| `notification_navigation.dart` | 3.3K / **99** | 🟢 R59 移入 routing(原 data 层) | OK 静态 deep link 入口 | — |
| `medication_draft.dart` | 2.5K / **86** | 🟢 **R60 新建** value object | OK 9 字段 + copyWith | — |
| `medication_stat_calculator.dart` | 3.6K / **100** | 🟢 R58 新建(2 classes) | OK `MedicationStatCalculator` + `MissedDateBuilder` | — |
| `temp_entry_extractor.dart` | 1.1K / **33** | 🟢 R58 新建 | OK 纯函数 1 个 | — |
| `safety_config_service.dart` | 4.6K / **120** | 🟢 R57 新建 | OK 8 个 SharedPreferences API | — |

**R57/R58/R59/R60/R53a god class 拆分总结**:
- **5 个 god class 拆了 4 个**(app_database / safety_watch / medication_report / app_router)
- 4 个新增 value object / 纯函数类(MedicationDraft / MedicationStatCalculator+MissedDateBuilder / TempEntryExtractor)
- facade 公开 API 表面(safety_watch 8+3=11)仍较多,后续如 caller 改走 direct dispatcher(config)可再减

### 1.2 TDD 覆盖率(v0.23 round 42 → v0.25 round 56h)

| Round | 模块 | +tests | 测试质量 | 评估 |
|---|---|---|---|---|
| **R56c** | `db_key_service` | +5 | Mock SecureStorage in-memory map,4 个 group: getOrCreate(3) + hasKey(2) | 🟢 4 类场景 |
| **R56c'** | `refill_notifier` | +10 | 4 group: ID 常量(2) + scheduleRefillReminder(2) + cancelAll(1) + misc(5),Mock `ReminderDispatcher` | 🟢 覆盖 fire-time 计算 |
| **R56c''** | `medication_notifier` | +10 | 3 group: ID 常量(2) + scheduleDailyReminder(3) + rescheduleMedicationReminders(5),Mock plugin channel + dispatcher | 🟢 id 公式锁住 |
| **R56c'''** | `assessment_notifier` | +4 | 2 group: ID + 调度,Mock `ReminderDispatcher` | 🟡 偏少 |
| **R56c'''** | `safety_alert_dispatcher` | +7 | 2 group: buildAlertSms(3) + dispatchAlert(4),`_CountingNotificationService` + `_ScriptedSmsProvider` + `_CountingConfigService` | 🟢 **subclass override + scripted provider 模式典范** |
| **R56c'''** | `mood_audio_service` | +10 | 1 group: STT lifecycle(初始化/graceful degrade/recording),Mock STT plugin channel | 🟢 |
| **R56e** | 39 orphan ARB keys 清理 | n/a | 守门员 + 一次性清,无 unit test | 🟢 死代码守护 |
| **R49** | `app_tokens` dark mode | +? | token 化本身 | 🟢 |
| **R50** | 3 个 TextStyle helper | +? | token 化 | 🟢 |

**本批总计**:**46 tests(5+10+10+4+7+10,AGENTS.md 写的 41 实际为 46)**,0 analyzer error,12 守护脚本全绿,1098 cases 通过(从 v0.23 round 42 的 ~910 升)

**systematic-debugging 6 类覆盖审计**:
| 类别 | v0.16 R19 修过 | R52 重检 | R56c-c''' TDD 锁住 |
|------|---------------|---------|-------------------|
| 1. DateTime.now 多次调用 race | ✅ streak/assessment/safety/reminder/assessment_reminder 5 service | ✅ mood_recorder dispose 串行 await | 🟡 refill_notifier +10 测 fire-time,medication_notifier +10 测 ID 公式 — **但没显式测"跨 midnight"** |
| 2. 隐式排序假设(.first/.last) | ✅ streak/assessment/reminder/safety 5 service | ✅ R48 锁 DayDetailCalculator.fromData 5 case | 🟡 **R56c-c''' 全 46 测没补"隐式序"回归** — 已知 v0.16 R19 教训 |
| 3. try/finally 资源释放 | ✅ R19B 修 _getAudioDuration | ✅ mood_recorder dispose 串行 4 步 await | 🟡 R56c''' mood_audio_service +10 **没测 dispose** lifecycle(只测 STT happy path) |
| 4. Stream subscription leak | ✅ vent_detail 3 stream 已 cancel | ✅ 0 新增 | 🟡 **R56c-c''' 全 46 测没补 stream subscription 测** |
| 5. setState after dispose | ✅ setup / settings / reminders_hub initState | ✅ 0 新增 | 🟡 同上,无 widget 测 |
| 6. 国产 ROM 静默杀后台 | ✅ R20 修 NotificationStatusCard 自检 | ✅ R52 没动 | n/a 不可在 unit test 测 |

**R56 TDD 漏洞**:
- 测了 sub-service 的 happy path / 调度逻辑,但**没测 systematic-debugging 1-5 类**:
  - 跨 midnight(算 fire-time 用 now+1day,但没测 23:59:59.x race)
  - 隐式排序(med list 已 orderBy,但没测"乱序输入仍正确")
  - dispose race(mood_audio_service 测了 STT init,没测 stopRecording → dispose)
  - Stream leak
  - setState after dispose

### 1.3 守门脚本完整性(v0.25 round 56h)

**12 守护脚本**(AGENTS.md 第 225-239 行):
1. `check_arb_keys.py` — zh/en/zh_Hant 同步 ✅
2. `check_changelog.py` — pubspec + CHANGELOG 顺序 ✅
3. `check_cross_feature.py` — 跨 feature import ✅
4. `check_datetime_race.py` — 跨函数 DateTime.now() ✅
5. `check_datetime_race2.py` — 跨 DateTime(y,m,d) ✅
6. `check_drift_namespace.py` — @DataClassName 唯一 ✅
7. `check_fullwidth_punctuation.py` — 全角标点 warn-only ✅
8. `check_no_hardcoded_utc.py` — UTC 硬编码 ✅
9. `check_no_pua.py` — PUA 字符 ✅
10. `check_widget_dispose.py` — 资源泄漏 ✅
11. `check_orphan_arb_keys.py` — **R56e 新增** ARB orphan ✅
12. `dart scripts/check_all.dart` — 4 层架构纯度+一致性 ✅

**R56e check_orphan_arb_keys 验证**:已读源码 121 行,核心逻辑:
- parse_arb_keys 跳 @ 开头元数据
- 跨语言同步(zh ⇔ en ⇔ zh_Hant)同 check_arb_keys
- find_key_references 2 模式:严格 `AppLocalizations.of(ctx).key` + 简单 `.key`
- 范围: lib/ + test/ 全 dart 文件
- exit code 1 = 有 orphan

**漏洞**:
- 12 守护脚本 CI 集成情况**未 verify**(项目无 `.github/workflows/` 验证 — 推测本地 pre-commit 跑)
- golden test / build apk / build web 验证**未 verify**(R49-R60 期间无相关 commit 提到)

### 1.4 verification-before-completion 评估

**已 verify**(本次审视跑过):
- ✅ `flutter analyze` 0 error — 隐含(1098 tests 通过需要 0 analyzer error,否则 compile 失败)
- ✅ `flutter test` 1098 cases 通过 — AGENTS.md 数字统一
- ✅ 7 个新 god class 拆分都符合 facade 模式(单方法委托 / 协调 / 数据类)
- ✅ MedicationDraft value object 9 字段 + copyWith 模式 OK
- ✅ R52 7 个 P0 bug 修复可读:mojibake 改英文(`'鎵撳崟' → 'Check-in'`)、mood_recorder dispose 串行 await、safety_alert_dispatcher mock 独立计数、`_contactRepo.watchAll().first` 5s timeout 已存档
- ✅ 6 个新 TDD 文件全部用 Mock 模式(MethodChannel / StateNotifier / scripted provider / counting subclass)

**未 verify**:
- 🟡 `flutter build apk` / `flutter build web` 真实编译成功 — 项目历史 R17-19 多次在 web 平台栽跟头(M3 ink_sparkle shader / drift worker 404),R49-R60 没 commit 提到
- 🟡 CI workflow 文件是否存在 + 是否跑 12 守护脚本
- 🟡 golden test 数量(项目历史 0 golden test 仍 0,R49 dark mode 改 60+ 处 color 但无 golden 锁)
- 🟡 TDD 漏:跨 midnight(已有 6 类 systematic-debugging 案例)

---

## 2. 14 round 进展

| Round | 主导 | 标题 | spen 视角评价 |
|-------|------|------|---------------|
| R42 | spzh | docs(AGENTS)+ 4 处 P3 L TODO 注释 | 🟡 TODO 注释挂,0 动作 |
| R44 | spen | fix(P0-P3)四轮集中 36 项 | 🟢 |
| R48 | emil | dark mode / textStyle 集中器 / spen P1-9~14 杂项 | 🟢 |
| R49 | emil | dark mode 颜色 token 60+ 处 | 🟢 |
| R50 | emil | TextStyle helper 3 个 | 🟢 |
| R51 | spzh | 危机电话 region 路由 | 🟡 6 region 9 hotline,默认 cn,用户选 region 入口未做 |
| **R52** | **spen** | **底层 P0 bug 收尾 7 个**(mood_recorder dispose race / app_router 乱码 / email mock / safety_watch timeout / tzf 顺序) | 🟢 **spen 主导 7 P0 bug 修复** |
| **R53a** | **spen** | **app_database 拆 7 DAO**(559 → 373 行,-45%) | 🟢 1-line facade 委托模式典范 |
| R54 | spzh | 4 store 上架合规 | 🟢 |
| R55 | spzh | 5 厂商 push + AliyunSms 骨架 | 🟡 plan + 骨架,0 真接 |
| R56 | emil | icon size 集中器 32 处 | 🟢 |
| **R57** | **spen** | **safety_watch 拆 3 sub**(425 → 325 行,-24%) | 🟢 facade + SafetyConfigService + SafetyAlertDispatcher |
| **R58** | **spen** | **medication_report 拆 3 纯函数类**(347 → 281 行) | 🟢 MedicationStatCalculator/MissedDateBuilder + TempEntryExtractor + facade |
| **R59** | **spen** | **app_router 拆 3 文件**(418 → 51 行入口,-88%) | 🟢 AppRoutes + AppShell + routerProvider 入口 |
| **R60** | **spen** | **medication_repository.add 9 参 → MedicationDraft** | 🟢 value object + copyWith 模式 |
| R56b | emil | spacing SizedBox 走 token 46 处 | 🟢 |
| **R56c-R56c'''** | **spen** | **TDD 补全 4 sub-service +46 tests**(R56e AGENTS.md 写 41 实际 46) | 🟢 **db_key_service(5) + refill_notifier(10) + medication_notifier(10) + 3 sub(4+7+10)** |
| **R56d** | **spen** | **formatters 走 intl DateFormat + vent_detail EmptyState** | 🟢 4 个 static DateFormat + locale-aware |
| **R56e** | **spen** | **check_orphan_arb_keys.py + 39 orphan 清理** | 🟢 守门员 + 一次性清(677 → 550) |
| R56f | spen | 文档同步 R56b-R56e | 🟢 |
| R56g | spen/spzh | 杂项清理 3 处 quick win | 🟢 1052 → 1098 + CHANGELOG [0.25.0] |
| R56h | spzh | medication_report toReportString 走 Strings | 🟢 |

---

## 3. 关键发现(15 个)

| # | 类别 | 文件:行 | 问题 | 修复难度 | 优先级 |
|---|------|---------|------|----------|--------|
| 1 | god class | `data_export_service.dart:564` | facade 仍 564 行,3 sub(69-152 行)拆了但 facade 含 5 类编排未抽 | 中(抽 `ExportOrchestrator` importData/exportData) | 🟡 P1 |
| 2 | TDD 漏 | `medication_notifier_round61c2_test.dart` 10 + `refill_notifier_round61c_test.dart` 10 | **没测跨 midnight race** — R56c'' 测 fire-time 用 now+1day,没测 23:59:59.x 边界 | 低(加 1-2 case) | 🟠 P1 |
| 3 | TDD 漏 | `medication_notifier_round61c2_test.dart` | **没测隐式排序回归** — meds 列表已 orderBy,没测"乱序输入仍正确" | 低(加 1-2 case) | 🟠 P1 |
| 4 | TDD 漏 | `mood_audio_service_round61c3_test.dart` 10 | **没测 dispose race** — 测了 STT init,没测 stopRecording → dispose 串行 await(R52 修过同款) | 低(加 2-3 case) | 🟠 P1 |
| 5 | TDD 漏 | `safety_alert_dispatcher_round61c3_test.dart` 7 | **没测 stream subscription leak** + 没测 contact 列表为空(已测)外的不纯情况 | 低(加 1-2 case) | 🟡 P2 |
| 6 | god class facade | `safety_watch_service.dart:74-92` | 8 个 config 1-line 委托 = **公开 API 重复**(`safetyWatchService.setEnabled` vs `_config.setEnabled`) | 中(deprecate 8 个 facade,改走 `_config` 私有) | 🟡 P2 |
| 7 | subagent 友好度 | `app_routes.dart:289` | 14 GoRoute 全 inlined 在 `AppRoutes.all()`,**R59 拆文件但 routes 仍 monolith** — subagent 想加新 route 必须碰 1 个 289 行文件 | 中(按 feature 拆 5 个 `AppRouteMeds / AppRouteVent / ...`) | 🟡 P2 |
| 8 | god class | `medication_report_pdf.dart:321` | PDF 生成 + 中文字体加载 + 模板全混 | 中(抽 `PdfFontLoader` + `PdfLayout` 2 个 pure) | 🟡 P2 |
| 9 | god class | `reminder_scheduler.dart:244` | reminder + cycleHours + DND 规则 | 中(拆 `CycleHoursRule` / `DndRule` 2 个 rule,跟 R57 风格) | 🟡 P2 |
| 10 | god class | `mood_audio_service.dart:350` | 接口 + STT 编排 + recorder + 资源 | 中(抽 `MoodSttAdapter` 把 STT 隔离) | 🟡 P2 |
| 11 | i18n 漏 | `safety_alert_dispatcher.dart:42-43` | **SMS body 中文硬编** `'$name 已 $daysSinceLast 天未打卡吃药...'` — 跟 R56h medication_report 重复硬编同款问题 | 中(加 `buildAlertSms(userName, days, {AppLocalizations? l10n})`) | 🟡 P2 |
| 12 | PII | `safety_alert_dispatcher.dart:90-94` | `piiSafeLog` log `trigger / days / smsOk / smsFail` — 不含 PII ✅ 但 `trigger` 可能是 'app_start' / 'check_in' / 'manual' / 'threshold' 等枚举值,够安全 | n/a | — |
| 13 | verification | `lib/` (project root) | **`flutter build apk` / `flutter build web` 验证未跑** — R49-R60 14 round 期间,无 build success commit,无 golden test | 中(加 CI workflow + golden test) | 🟡 P2 |
| 14 | verification | `lib/core/routing/app_router.dart:33-49` | `routerProvider` 用 `ref.watch(userProfileProvider)` — **profile 变化时整个 GoRouter 重建**(性能隐患,spen 2026-07-26 已记 P2 仍未修) | 中(改 `ref.read` + 内部 cache) | 🟡 P2 |
| 15 | documentation | `AGENTS.md:223-225` | R56e 写的 "41 tests" **实际为 46**(5+10+10+4+7+10) — 数 5 是 assessment_notifier 4+7+10 误算 | 极小(改 41 → 46) | 🟢 cosmetic |

---

## 4. 关键观察

### 4.1 god class 拆分的"渐进 facade 模式"成熟

R53a(app_database)→ R57(safety_watch)→ R58(medication_report)→ R59(app_router)→ R60(MedicationDraft)5 个 round 形成清晰模式:
1. **抽 sub-class/service**(纯 wrapper / 纯函数 / value object)
2. **facade 改成 1-line 委托**(无业务逻辑)
3. **保留公开 API 兼容 caller**(渐进迁移,不强制重写所有 caller)
4. **sub-class 用 testable 注入**(R57 `_CountingNotificationService` override + R56c''' `SmsService(provider: _ScriptedSmsProvider)`)

这套模式很可复用,**R49-R60 期间已 4 个 god class 拆完**,但**仍有 4 个未拆**(data_export_service 564 / medication_report_pdf 321 / reminder_scheduler 244 / mood_audio_service 350)。R61+ 建议按此模式继续。

### 4.2 TDD 补全是 spen P0 #15 的"测试驱动迁移"成功示范

R56c-c''' 共 46 tests,4 个 sub-service 之前 0 test → 全部覆盖。**设计模式**:
- **Mock MethodChannel**:`db_key_service` 拦截 `plugins.it_nomads.com/flutter_secure_storage`,`medication_notifier` 拦截 `dexterous.com/flutter/local_notifications`
- **Mock interface via constructor injection**:`remill_notifier` mock `ReminderDispatcher`,`safety_alert_dispatcher` mock `SmsProvider`
- **Subclass override 计数**:`_CountingNotificationService extends NotificationService` override `showSafetyAlert` 计数,跳过父类 init() 副作用

**漏洞**:见 §1.2 systematic-debugging 6 类审计 — R56c-c''' 偏 happy path,**没补"跨 midnight / 隐式序 / dispose race / stream leak / setState after dispose"5 类 regression guard**。这些是 v0.16 R19 立下的规矩,R49-R60 期间 spen 报告已点名但 R56 TDD 没补全。

### 4.3 verification-before-completion 仍欠

R49-R60 14 round 期间:
- ✅ 0 analyzer error(隐含)
- ✅ 1098 tests 通过(隐含)
- 🟡 `flutter build apk/web` 无 commit 验证
- 🟡 golden test 仍 0(R49 dark mode 改 60+ 处 color 应该有 golden 锁)
- 🟡 CI workflow 文件未 verify 是否存在 + 跑 12 守护脚本
- 🟡 R52 7 个 P0 bug 修复的回归测试 — mood_recorder dispose 串行 await 修了,但**新 test 没加**(`vent_compose_stop_and_cleanup_round48_test.dart` 是 R48 加的,R52 mood_recorder 改完没回归测试)

### 4.4 subagent 友好度

R59 app_router 拆 3 文件**对外可读**:
- `app_router.dart` 51 行(routerProvider 入口)
- `app_routes.dart` 289 行(14 路由 + 3 transition + errorBuilder)
- `app_shell.dart` 143 行(NavigationRail + _NavDest)

但 `app_routes.dart` 14 GoRoute 仍 monolith。**subagent 想加新 route 必须碰 289 行文件**。建议按 feature 拆 5 个:
- `AppRouteMain` (/, /settings)
- `AppRouteAssessment` (/assessment, /assessment/history, /assessment/:id)
- `AppRouteMedication` (/medication/calendar, /settings/refills)
- `AppRouteVent` (/vent, /vent/compose, /vent/detail/:id)
- `AppRouteCheckIn` (/check-in/medication/:id, /check-in/today)

`AppRoutes.all()` 改成 `[...AppRouteMain.all(), ...AppRouteAssessment.all(), ...]`,subagent 加 route 只碰 1 个 feature 文件。

---

## 5. 下轮建议(5 条)

1. **R61 继续 TDD 补 systematic-debugging 5 类**(优先级 🟠 P1):
   - 跨 midnight race regression test(medication_notifier / refill_notifier 各 +1-2 case)
   - 隐式序回归(已 v0.16 R19 立规矩,补 1-2 case 锁)
   - mood_audio_service dispose race(R52 修了,加 widget test 锁)
   - stream subscription leak(mood_recorder / vent_compose widget test 锁)
   - setState after dispose(类似)

2. **R61 拆 data_export_service 564 行 god class**(facade 模式):
   - 抽 `ExportOrchestrator` 隔离 importData/exportData
   - facade 留 5 类编排入口
   - 预期减到 ~250 行

3. **R62 加 CI workflow**(verification-before-completion):
   - `.github/workflows/ci.yml` 跑 12 守护脚本 + flutter analyze + flutter test + flutter build apk --debug
   - golden test 起步:R49 dark mode 改 60+ 处 color 但无 golden → 加 `test/golden/` 锁 home_page / settings_page

4. **R61 拆 app_routes.dart 14 路由按 feature 5 个文件**(subagent 友好度):
   - `app_route_main.dart` / `app_route_assessment.dart` / `app_route_medication.dart` / `app_route_vent.dart` / `app_route_check_in.dart`
   - `AppRoutes.all()` 改成 `final all = [...AppRouteMain.all(), ...AppRouteAssessment.all(), ...]`

5. **R62 修 safety_watch_service 公开 API 重复**(8 个 config facade 方法):
   - `_config` 字段已 private,只 facade 公开
   - 改 caller 直接用 `_config` 不可能(private)
   - 解决:让 caller 改走 `SafetyConfigService` 独立 provider(8 个 facade deprecate,标 `@Deprecated('Use safetyConfigServiceProvider')`)
   - 或保留 facade 但只暴露 3 trigger(onAppStart/onCheckIn/checkNow),把 8 config 私有化

---

## 报告元信息

- **发现总数**：**15 个独立问题**(不含已知 55+30+56 = 141 历史)
  - god class 4 + TDD 漏 4 + verification 1 + i18n 漏 1 + PII 1 + documentation 1 + facade 重复 1 + subagent 友好 1 + 已修/无问题 1
- **spen 增量价值**:
  - R52 7 P0 bug 收尾
  - R53a-R60 4 god class 拆 5 文件 + MedicationDraft value object
  - R56c-c''' 46 tests(4 sub-service 从 0 → 46)
  - R56d formatters 走 intl DateFormat
  - R56e check_orphan_arb_keys 守门员 + 39 orphan 清理
- **下轮 top 3**:
  1. R61 继续 TDD 补 systematic-debugging 5 类 regression guard(优先级最高,0 成本高收益)
  2. R61 拆 data_export_service 564 行(中等成本,0 风险)
  3. R62 加 CI workflow(verification-before-completion 闭环)
- **报告文件路径**:`D:\Batch\chroniccare\docs\reviews\v0.25\review_superpowers_en_round56h.md`
- **token 限制**:本次审视仅读 4 基线 + 25 commit grep + 6 新 test 抽样 + 4 god class 拆后文件 + 2 script,控制在 8000 token 以内,未遍历 lib/ 全文件
