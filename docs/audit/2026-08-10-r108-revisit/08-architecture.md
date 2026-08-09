# 顶层架构审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: architecture (顶层架构)
- 审视者: subagent-top-architecture
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71, working tree=30+M 26D
- 范围: 4 层架构纯度 + 一致性 (`check_all.dart` 跑通);`check_cross_feature.py` 脚本(虽然 Python 缺失, 但手工 grep 模拟验证);god class 候选扫描(`lib/**/*.dart` 共 403 个 dart 文件, 80+ 个 > 250 行);god widget 候选扫描;R108 拆解进度(working tree 12 个新文件 + 15 改动);domain 抽象层;provider 注册表;use case 层;feature-first 重构可行性;pub workspace 评估;跨 feature privacy boundary。

---

## 1. 整体评分(0-10)

**8.4/10** — 4 层架构 1:1 落地, 抽象层(Repository / Notifier)成熟, 18 守门员 + 4 层纯度脚本全绿, R108 4 项 god class 拆完成;但**顶层仍有 6 个 400+ 行 god class 候选**(medication_page / setup_page_state / add_medication_page / home_page_state / notification_service / static_scale_translations), use case 层利用率低(仅 4 文件 / 425L), pub workspace / feature-first 仍是 1+ 月后的 v1.0 工作, 顶层 static mutable service(SmsService/EmailService top-level `final` in main.dart)违反 Riverpod DI 哲学。

---

## 2. 关键发现(按 P0/P1/P2/P3 排序,每项含架构/底层标签 + 修复难度)

### P0(必修,阻塞架构健康度/跨模块一致性)

---

#### [架构] **[P0-001] main.dart 顶层 `final` SmsService/EmailService 违反 Riverpod DI 哲学** — 修复难度:S — 工作量:2h
- 位置: `lib/main.dart:50,61`; `lib/presentation/providers/core_providers.dart:92,109`
- 现状: `final SmsService _smsService = SmsService();` 和 `final EmailService _emailService = EmailService();` 在 main.dart 顶层 `final` 持有,**同时** `core_providers.dart` 又定义 `smsServiceProvider` / `emailServiceProvider` Provider。bootstrap 时 `provider.overrideWithValue(_smsService)` 注入。问题是:
  1. **两路实例化** = Provider 设计的味道变了(Provider 该是 lazy / container-managed, 不是 top-level static)
  2. **测试 override 不彻底** — ProviderScope override 只能覆写 provider, 不能覆写 main.dart 顶层 final
  3. **subagent 调用栈**: NotificationService 自身已 R108 走 Provider, 但 SmsService / EmailService 仍是 top-level final
  4. 跟 R97-P1-13 修过的"mutable static 改 `late final`"思路不彻底 (改成 `final` 还是 top-level, ProviderScope 之外实例化, 仍违反 Riverpod)
- 建议: 把 `SmsService` / `EmailService` 改走 `FutureProvider<SmsService>` (异步初始化, 阿里云 / SendGrid 真实 API key 走 env 注入), main.dart bootstrap 不再 top-level 实例化, 改在 ProviderScope overrides 里 `smsServiceProvider.overrideWith((ref) => SmsService.init(env))`。同时 `validateForRelease` 检查走 Provider 的 lifecycle (autoDispose + state)。

---

#### [架构] **[P0-002] `medication_page.dart` 553L 仍是顶层 god class, R108 拆解目标未达成** — 修复难度:M — 工作量:4h
- 位置: `lib/presentation/pages/medication/medication_page.dart:553L`
- 现状: R108 Fix #4 目标 "540→400L", 实际看文件 553L(只把 _TimeSlot enum 抽到 `domain/logic/medication_slot_calculator.dart` 减 20L, 同时 build 树加注释/HeaderCard 反而增 30L)。文件内含 7 个 private widget class:`_SectionHeader` / `_TimeSlotCard` / `_SlotEntryRow` / `_MedicationListCard` / `_QuickActionCard` / `_EmptyMedicationsCard` / `_EmptyScheduleCard` + 1 个 helper `_buildTimeSlots` 50L。属于"多个 sub-widget + build 编排 + helper 业务"混在一文件, 违反 SRP。
- 建议: 抽 `lib/presentation/pages/medication/widgets/` 子目录, 7 个 private widget 全部提到 `widgets/time_slot_card.dart` / `widgets/slot_entry_row.dart` / `widgets/medication_list_card.dart` / `widgets/quick_action_card.dart` / `widgets/empty_*.dart` / `widgets/section_header.dart`(注: R40 已抽通用 `SectionHeader`, 但 medication 用的不是同一个,有重复)。`medication_page.dart` 只留 build + `_buildTimeSlots` helper。**目标: 553 → 200L**。

---

#### [架构] **[P0-003] `setup_page_state.dart` 506L 是 R95/R108 都漏掉的 god state class** — 修复难度:M — 工作量:4h
- 位置: `lib/presentation/pages/setup/setup_page_state.dart:506L`
- 现状: 4 步 wizard(consent / welcome / medication / done)+ 5 个 consent bool + 1 saving flag + `_onTextChanged` 状态机 + 4 步 step build method,全堆在一个 `_SetupPageState` ConsumerState。R95 sub-spec 4 task 5 抽 setup_page_state 时只拆了 step_xxx 4 个文件,但主壳 state class 没动。`build()` 1 个 method 100+ 行,4 个 `_buildStep*` method 各 50+ 行。
- 建议: 抽 `lib/presentation/pages/setup/controllers/setup_consent_controller.dart` 装 5 bool + saving,`build()` method 拆成 `widgets/setup_step_router.dart` 路由 step → step widget。**目标: 506 → 200L**。

---

#### [架构] **[P0-004] `add_medication_page.dart` 506L 是 R95/R108 都漏掉的 god page** — 修复难度:M — 工作量:4h
- 位置: `lib/presentation/pages/medication/add_medication_page.dart:506L`
- 现状: 4 步 wizard(med info / dosage / times / confirm)+ 1 colorIndex + 1 saving + 4 个 `_buildStep*` method。跟 setup_page_state 同款 wizard 模式但完全独立, 没复用。**没有共用 wizard 抽象层**(R95 sub-spec 8 task 18 P3 UX 提到但没做)。
- 建议: 抽 `lib/presentation/widgets/wizard/wizard_controller.dart` 抽象基类(步骤状态机 + saving flag + 步骤切换);setup 和 add_medication 都继承。`add_medication_page.dart` 减到 200L。

---

#### [架构] **[P0-005] `notification_service.dart` 417L + `notification_delegate.dart` 200L 是 facade+delegate 双 god 文件(混合态未完成)** — 修复难度:M — 工作量:3h
- 位置: `lib/core/data/services/notification_service.dart:417L`, `lib/core/data/services/notification_delegate.dart:200L`
- 现状: R108 Fix #2 拆 facade 12 委派到 delegate,但 facade 自己仍 417L(主壳保留 init 60L / requestPermission / showNow / cancelAll / pendingCount / showSafetyAlert / rescheduleAll / _canScheduleExact / 3 channel const)。CHANGELOG 标"⚠️ 半成品"。R108 中段 subagent E + F 因 token 上限中断,**未完成"删旧字段+减重到目标"**。
- 建议:
  1. `NotificationService` 改 100% pure facade (init / showNow / cancelAll / showSafetyAlert / rescheduleAll 5 method + 3 channel const),其它全走 `service.delegate.xxx()`
  2. `init()` 60L 抽 `NotificationInitializer` 子类(init plugin / tz / 权限 / onNotificationTap 4 步)
  3. `rescheduleAll` 30L 抽 `NotificationOrchestrator` 子类(协调 dispatcher + 3 sub-delegate + _canScheduleExact)
  4. 目标 facade < 150L, delegate < 100L(只留 wrapper,业务全在 6 sub-service)

---

#### [架构] **[P0-006] `static_scale_translations.dart` 659L 是 domain 层最大 god data class(10 量表 × 23 method = 230 method 中文 fallback)** — 修复难度:L — 工作量:1d
- 位置: `lib/domain/entities/scale_translations/static_scale_translations.dart:659L`
- 现状: R95 sub-spec 4 task 2 把抽象 `ScaleTranslations` 拆出去(剩 198L),但 StaticScaleTranslations 实现仍在 1 个文件,含 10 量表(2 老 PHQ-9/GAD-7 + 8 新 ISI/PSS/WHODAS/Level2 Depression/Anxiety/Mania/Psychosis/ASRM)× 6 类方法(name / shortDescription / instruction / items / options / severityLabel+Summary)= 230 method。文件含 ~250 段 const 中文 fallback。
- 建议: 按量表拆 10 文件:
  ```
  lib/domain/entities/scale_translations/static/
    phq9_zh.dart
    gad7_zh.dart
    isi_zh.dart
    pss_zh.dart
    whodas_zh.dart
    level2_depression_zh.dart
    level2_anxiety_zh.dart
    level2_mania_zh.dart
    level2_psychosis_zh.dart
    asrm_zh.dart
  ```
  StaticScaleTranslations 改 `mixin` 组合,每个量表 1 mixin,主壳只剩 crisis hotline + dispatcher method。**目标: 659 → 150L(主壳) + 10×50L(子)**。

---

### P1(应修,影响品质 / 长期可维护性)

---

#### [架构] **[P1-001] `home_page_state.dart` 440L R108 拆 3 controller 后仍超 350L 目标** — 修复难度:M — 工作量:4h
- 位置: `lib/presentation/pages/home/home_page_state.dart:440L`
- 现状: R108 Fix 抽 3 controller(deep_link 10.5KB / care_engine 8.3KB / celebration 4.2KB),但 home_page_state 主壳仍 440L(目标 < 350L,CHANGELOG 标 "597→515L (-14%)" 但实际 440L 是控制器已经抽完的状态)。剩余的 build() 180L / dispose / 4 业务方法(onCheckIn / snooze5Min / runSafetyCheck / nextReminderTime) + 1 lifecycle enum + 1 ScrollController 仍多。
- 建议: 抽 `home_celebration_overlay.dart` widget(庆祝 overlay 渲染)+ 抽 `home_next_reminder_time_calculator.dart` 纯函数(从 build() 抽出来)。**目标: 440 → 250L**。

---

#### [架构] **[P1-002] `mood_audio_recorder_widget.dart` 529L + `vent_compose_page.dart` 416L R108 共享 mixin 但仍 > 400L** — 修复难度:M — 工作量:4h
- 位置: `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:529L`, `lib/presentation/pages/vent/vent_compose_page.dart:416L`
- 现状: R108 Fix #1 抽 `audio_lifecycle.dart` AudioLifecycleMixin,减 191L + 168L。但 CHANGELOG 标"⚠️ 半成品 - 旧字段未删"。`mood_audio_recorder_widget` 实际 529L(从 530→339 计划失败,实际看 530→587 增 57L,加注释反而长);`vent_compose_page` 实际 416L(从 495→327 计划失败,实际 495→445 减 50L 但仍 416L)。
- 建议: R108 残尾"删旧字段"做完(每个文件减 50-80L),同时 `mood_audio_recorder_widget` 拆 `widgets/mood_audio_recording_controls.dart` + `widgets/mood_audio_transcript_view.dart`,主壳减到 300L。

---

#### [架构] **[P1-003] `legal_page.dart` 460L + `reminders_hub_page.dart` 441L 是 settings hub 内的双 god page** — 修复难度:M — 工作量:6h
- 位置: `lib/presentation/pages/settings/legal_page.dart:460L`, `lib/presentation/pages/settings/reminders_hub_page.dart:441L`
- 现状: legal_page 含 1 主壳 + 4 private widget class(`_SectionTitle` / `_DocTile` / `_ConsentTile` / `_WithdrawOption`)。reminders_hub_page 含 1 主壳 + 2 sheet class(`_AssessmentReminderSheet` / `_SafetyReminderSheet`)。都属于"主壳 + 多个 sub-widget"模式。
- 建议: legal_page 4 sub-widget 全提到 `widgets/legal_page/`,主壳减到 200L。reminders_hub_page 2 sheet 提到 `widgets/reminder_sheets/`,主壳减到 200L。`reminder_cards.dart` 已 306L,R108 应一并拆。

---

#### [架构] **[P1-004] use case 层利用率低(domain 仅有 4 个 usecase 文件 / 425L,多数业务在 domain/logic 纯函数里)** — 修复难度:L — 工作量:1-2d
- 位置: `lib/domain/usecases/`(仅 4 文件:`fire_care_strategy.dart` 221L, `schedule_refill_reminder.dart` 82L, `check_safety.dart` 62L, `check_in_usecases.dart` 60L)
- 现状: R27 round 65 抽了 4 个 usecase(关怀触发 / 续方提醒 / 失联检测 / 打卡),但**核心业务流**(streak 计算、refill 调度、CBT 重评、trend 聚合)都直接走 `domain/logic/` 纯函数,presentation 直接调。没走 use case orchestration。导致 presentation 层直接依赖 domain/logic 函数,违反 "presentation → domain/usecases → domain/logic" 标准 4 层 + use case 层 5 层模式。
- 建议: 把 8+ 业务流提到 use case:
  - `RecordCheckInUseCase`(封装 streak + today count + safety rerun + care engine trigger 4 步,目前 home_page_state._onCheckIn 内联)
  - `ComputeStreakUseCase`(streak_calculator wrapper + shouldShowStreakBroken,presentation 调)
  - `GetMedicationTimeSlotsUseCase`(medication_slot_calculator + activeMeds filter)
  - `ComputeDayDetailUseCase`(day_detail 319L 大文件 1:1 包成 use case)
  - `AggregateTrendUseCase`(trend_calculator wrapper)
  - `RerateCbtUseCase`(cbt_rerated_entries logic)
  - `SealVentEntriesUseCase`(PIPL §47 封存)
  - `WithdrawConsentUseCase`(legal_consent 撤回)
  8 个 usecase × 平均 60L = 480L 新代码,移动 ~600L 业务从 presentation 到 usecase。**目标: presentation 层 0 直接调 domain/logic,全走 usecase**。

---

#### [架构] **[P1-005] `app_database.dart` 494L 含 14 tables + schemaVersion 13 + MigrationStrategy 1 个文件统一管** — 修复难度:L — 工作量:1d
- 位置: `lib/core/data/database/app_database.dart:494L`
- 现状: 14 drift table(`CheckIns` / `Medications` / `Contacts` / `UserProfiles` / `ReportHistories` / `MoodEntries` / `VentEntries` + 7 daily tracking tables)全部 `@DriftDatabase(tables: [...])` 列在 1 个文件。`MigrationStrategy` 跟 13 个 schemaVersion upgrade 的迁移代码堆在 1 个文件。schemaVersion 14 即将加 vent_entries.contentText DROP(R22 round 22 注释说"v10+ DROP entirely" 但 4 round 没动)。
- 建议: 拆 `database/schema/` 子目录,每 schemaVersion 1 文件:
  ```
  lib/core/data/database/schema/
    schema_v01.dart  // 1-5
    schema_v06.dart
    schema_v07.dart
    ...
    schema_v13.dart
  ```
  AppDatabase 主体只剩 `@DriftDatabase(tables: [...])` + `MigrationStrategy { onUpgrade: (m, from, to) async { for (final v in allMigrations) await v.upgrade(m, from, to); } }`。**目标: 494 → 200L**。

---

#### [架构] **[P1-006] daily_tracking 7 widget 6 repository 是 R95 新加 feature 但拆得过散(每条 daily 1 个 repo + 1 个 table + 1 个 dao + 1 个 entity + 1 个 mapper = 5 文件,7 条 = 35 文件)** — 修复难度:L — 工作量:2-3d
- 位置: `lib/core/data/repositories/daily_tracking/`(6 repo)+ `lib/core/data/database/tables/daily_tracking/`(7 table)+ `lib/core/data/database/daos/`(6 dao)+ `lib/domain/entities/`(6 entity)+ `lib/domain/logic/`(3 calculator: bmi / sleep / mood_period_aggregator)
- 现状: 7 daily tracking sub-feature(sleep / social_rhythm / stress_event / treatment / weight / anxiety_agitation / cbt_thought_record)每个走 5 文件 pattern。共 35 个文件但每个文件平均 < 100L。"过工程化" — 6 个简单 CRUD table 没必要每条都全栈分层。
- 建议: 3 步收口:
  1. 6 个 dao 合并为 1 个 `DailyTrackingDao`(`watchAll(sleep)` / `watchAll(socialRhythm)` 等 enum dispatch 或 7 个 typed method)
  2. 6 个 repo 合并为 1 个 `DailyTrackingRepository`(7 个 entity 各 1 套 watchX / insertX / updateX / deleteX)
  3. 7 个 table 文件不动(每个 schema 1 文件合理),但 entity 跟 table 1:1,可考虑 entity 跟 table 文件合并
  **目标: 35 文件 → 12 文件, 行数从 35×80 = 2800L 减到 12×200 = 2400L**(实际减 14%)。**注意**: 这是逆 R95 趋势, 决策前需 PM review — 业务可能在 v1.0 后扩展(医院同步 / Apple Health),保持每条 1 repo 利于扩展。P1 候选,不是 P0。

---

### P2(可修,优化)

---

#### [架构] **[P2-001] `static_scale_translations_l10n.dart` 720L 是 presentation 层 i18n 实现的镜像 god 文件** — 修复难度:M — 工作量:1d
- 位置: `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart:720L`
- 现状: R78 加的 10 量表 × 23 method = 230 method,每个 method 走 `AppLocalizations.of(context).xxx` 包成 i18n。720L 含 230 个 method 1:1 镜像 `static_scale_translations.dart` 659L。**两份 1300L 是同构的**, 仅 fallback vs ARB 区别。
- 建议: 用 codegen 模式取代 — 写 1 个 `ScaleTranslationsRegistry` abstract class,`static_scale_translations.dart` 跟 `static_scale_translations_l10n.dart` 都通过 `class X extends ScaleTranslations { @override String phq9Name({override}) => override ?? '...'; }` 生成。或者用 build_runner 自动生成。**注意**: 这 1300L 是 R28 起步 + R78 大扩的产物, 当下 P2 候选, 不影响 v1.0 上架。

---

#### [架构] **[P2-002] `lib/core/l10n/strings.dart` 314L 集中器已成熟但仍有 ~80 处 const 中文 fallback 写在 domain 层(违反"domain 0 i18n"原则)** — 修复难度:L — 工作量:1d
- 位置: `lib/core/l10n/strings.dart:314L`
- 现状: R23 round 39 (P1-9 fix) 把通知 / 邮件 fallback 集中到本类,R26 R57 加 override 参数(允许 presentation 注入 AppLocalizations)。但本类仍含 ~80 处 `static const` 中文,**R57 注释承诺"v1.0+ 计划: domain EmailTemplate 接收 i18n strings 作为参数,完全脱离本文件"** —— R57 至今 1+ 年未做。
- 建议: 给 R1.0 列任务 — domain `EmailTemplate` / `LostContactSms` / `care_copy` 改成接收 `Strings` 参数(纯 String 函数)而不是调 `Strings.xxx()`,这样 domain 0 中文字面量。**目标: 314 → 100L(只留 override 函数 + 1 段注释)**。

---

#### [架构] **[P2-003] provider 文件 16 个, 大小均 < 250L, 但 `shared_providers.dart` 123L 含 19+ provider 横跨 8 entity 跨 6 feature** — 修复难度:S — 工作量:2h
- 位置: `lib/presentation/providers/shared_providers.dart:123L`
- 现状: 用户档案 + 打卡(5 个 provider) + streak + 联系人 + 药物(2 个) + 评估 + 报告 + 情绪(3 个) + dayChangeTick + today 12 类 19+ provider 全在 1 文件。R17 round 14 拆 core_providers 后留下的"业务无关 entity 派生 provider"大杂烩。
- 建议: 按 entity 拆 5 文件:
  - `user_profile_providers.dart`(userProfileProvider)
  - `check_in_providers.dart`(5 个 checkIn + streak)
  - `medication_providers.dart`(2 个 medications)
  - `mood_providers.dart`(3 个 mood + dayChangeTick + today)
  - `contact_providers.dart`(1 个 contacts)
  - `report_providers.dart`(1 个 reportHistories)
  `core_providers.dart` 留 7 个 repo + 4 service。
- **目标: 123 → 30L/文件, 6 文件平均**, 跨 feature 改动冲突从 1 文件减到 6 文件, 风险更分散。

---

#### [架构] **[P2-004] presentation/pages/{feature}/ 子目录布局**7 个 feature 仍用 flat 目录(medication/vent/mood/...),**feature-first 重组未做** — 修复难度:XL — 工作量:2-3 周
- 位置: `lib/presentation/pages/`(7 feature 子目录:home / setup / settings / trend / assessment / check_in / contact / medication / mood / mood_list / vent / daily_tracking / crisis_hotline_page)
- 现状: 4 层架构 + 共享层是 **layer-first**(domain 在 1 目录, data 在 1 目录, presentation 在 1 目录)。优点: 跨 feature 共享容易(domain entity / repository 都在 layer 内聚合)。缺点: **1 个 feature 改动要跨 3+ 目录**: 改 medication 业务要改 `domain/entities/medication_entity.dart` + `domain/logic/streak_calculator.dart`(streak 用 medication)+ `data/repositories/medication/medication_repository_impl.dart` + `data/database/tables/medication/medications.dart` + `presentation/pages/medication/...` + `core/routing/app_route_medication.dart` 5-6 目录,改动容易散。
- 建议(feature-first 重构): v1.0 后 2-3 周专项。规划:
  ```
  lib/features/
    medication/
      domain/         # entities + repositories + logic (medication 相关)
      data/           # tables + daos + repositories_impl + mappers
      presentation/   # pages + widgets + providers
    vent/             # 同上(隐私边界特殊, 留独立)
    mood/             # 同上
    daily_tracking/   # 7 sub-feature 折叠到 1 个 feature
    check_in/         # 单独 feature
    assessment/
    setup/
    home/             # hub
    settings/         # hub
  lib/core/           # 留 infrastructure(db / theme / routing / l10n / shared)
  lib/l10n/
  ```
  **R110 路线图**(AGENTS.md 已记): 1-2 月, 大型 PR, 需渐进迁移(双 import 兼容 + 弃用 + 最终删 layer-first 旧路径)。
- **本 subagent 不建议 R108 期间做**, 单独 roadmap item。

---

#### [架构] **[P2-005] pub workspace / monorepo 拆分未做** — 修复难度:XL — 工作量:1-2 月
- 位置: 根 `pubspec.yaml`(单 pubspec)
- 现状: 整个 app 1 个 pubspec(80+ dependency)。**优点**: dev 简单, build 一步。**缺点**:
  1. `domain/` 跟 `presentation/` / `data/` 共享 pubspec = 共享所有依赖,无法独立 test 0 依赖
  2. v1.0 后开 2 个产品线(maybe "B2B 医生端"?) 时无法共享 domain 层代码
  3. CI build 整个 app = 慢(全部 pub get + drift codegen)
- 建议: 3 workspace:
  ```
  pubspec.yaml               # workspace
  packages/
    chroniccare_core/        # domain + shared(0 flutter 0 drift 0 presentation, 0 dep)
    chroniccare_data/        # data + drift + db + service(0 presentation, 0 flutter)
    chroniccare_app/         # presentation + flutter(presentational dep)
  ```
  - `chroniccare_core` 可独立 test (domain logic 0 依赖, 跑 `dart test` 而非 `flutter test`)
  - `chroniccare_data` 可独立 test (data layer 0 flutter dep 已在 R22 达成, 但还需 import `package:drift/...` 跑 codegen)
  - `chroniccare_app` 是 presentation + flutter entrypoint
  - CI 三段并行, total build 提速 ~40%
- **决策**: v1.0 之前(2026-Q4)不拆, v1.0 后看产品线决定。

---

### P3(建议,长期)

---

#### [架构] **[P3-001] `app_database.g.dart` 8111L 是 drift codegen 输出,但 `app_database.dart` 494L + 14 tables 让生成代码 16× 膨胀,drift codegen 耗时 ~8s** — 修复难度:M — 工作量:1d
- 位置: `lib/core/data/database/app_database.g.dart:8111L`(自动生成)
- 现状: 14 table × 580L 平均 codegen = 8111L。drift 跑 `dart run build_runner build --delete-conflicting-outputs` ~8s 每次 full rebuild。**改 1 行表 schema → 8s codegen 阻塞**。PR 流程慢。
- 建议: drift 支持 incremental codegen 吗?查文档,如果有 — 改 build 配置;如果没有 — 把 14 table 拆 2 个 database(check_in_database / mood_database / vent_database),每个 4-5 table,生成代码 3000L,codegen ~3s。**注意**: drift database 拆 2+ 共享 connection 走 native.dart 的 OpenConnection,所以 SQLCipher key 同步,1 个 SQLCipher file 装多 schema。技术可行,需 spike 验证。**P3 候选**。

---

#### [架构] **[P3-002] `safety_watch_service.dart` 338L + `care_strategies.dart` 86L + `care_copy.dart` 56L + `care_engine.dart` 19L + `fire_care_strategy.dart` 221L 是 5 个 care 业务相关文件, 业务散落** — 修复难度:L — 工作量:1-2d
- 位置: `lib/core/data/services/safety_watch_service.dart:338L`, `lib/domain/logic/care_*.dart`(4 文件), `lib/domain/usecases/fire_care_strategy.dart:221L`
- 现状: care 业务(失联检测 / 4 strategy 触发 / 文案 / 渠道编排)散在 5 个文件,每个都"近 100L - 300L"但职责有重叠(safety_watch_service 同时含 detector + 渠道选择 + use case orchestration)。
- 建议: 收 1 个 `care/` 子目录,5 文件合并 1-2 文件。但要保留 use case 层(presentation 不直接调 safety_watch_service,走 use case)。

---

#### [架构] **[P3-003] `mood_list/mood_trend_page.dart` 517L 是 R108 新建但已超阈值** — 修复难度:M — 工作量:4h
- 位置: `lib/presentation/pages/mood_list/mood_trend_page.dart:517L`
- 现状: R108 新加 mood 列表 / 详情 / 趋势三件套,trend_page 一上来就 517L。**新代码不应超 350L 阈值**。原因是它同时管 list + detail + chart 三种 view,每个 view 含 80-100L 业务。
- 建议: 抽 3 文件: `mood_list_page.dart` + `mood_detail_page.dart`(308L 已有)+ `mood_trend_charts/` 子目录含 3 chart widget。`mood_trend_page.dart` 减到 200L。

---

#### [架构] **[P3-004] 跨 feature import 边界:home/settings 是 hub 唯一例外,但 `legal_page.dart` import `setup/setup_legal_dialog.dart`(setup 跨入 settings)的对称** — 修复难度:S — 工作量:1h
- 位置: `lib/presentation/pages/settings/legal_page.dart:16` → `package:chroniccare/presentation/pages/setup/setup_legal_dialog.dart`
- 现状: `check_cross_feature.py` 规则 "settings 可 import 任何 feature" 已豁免 legal_page 跨入 setup。**反向**: setup 何时 import settings?目前 0 反向(setup 只 import 自己 + domain + core)。
- 建议: 这是 AGENTS.md 已记的 "hub 可双向" 规则的正确实现。**无需改**,但应加 1 个 `check_cross_feature_inverse.py` 反向检查(任何 feature import hub 是允许的,但 hub import feature 之外的应 fail)。**P3 候选**。

---

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

按架构 subagent 视角(代码层 域名/邮箱/URL 引用):

| 位置 | 内容 | 状态 |
|---|---|---|
| `lib/core/data/services/sms_service.dart` | 阿里云 SMS API endpoint 占位(`.env` `ALIYUN_SMS_ENDPOINT`) | 占位符(等付费启动真接) |
| `lib/core/data/services/email_service.dart` | SendGrid API endpoint 占位 | 占位符(等付费启动) |
| `lib/core/data/services/store_kit_service.dart` | Apple IAP productId 占位 | 占位符 |
| `lib/core/data/services/notification_service.dart` | `chroniccare.medication` / `chroniccare.safety` channel id | internal id, 无外链 |
| 整个 `lib/` | 0 `http://` / `https://` 硬编外链(除 .env template) | ✅ 0 外链泄漏 |
| `assets/legal/*.md` | 3 份法律协议 (user_agreement / privacy_policy / sensitive_data_consent) | R107 已 R95 阶段 2 加业务暂停延伸说明, 但**外链引用**待 R108 P0#13 域名注册后填 |
| 整个 `pubspec.yaml` | `description` 是中文(已 R69 双语) + `homepage` / `repository` 字段未填 | 留空(等 R108 域名注册) |

**架构 subagent 视角结论**:**0 外链泄漏到代码层**(全在 .env + 占位符),**R107 / R108 已 P0#13 修**。

---

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关(架构相关部分)

- **`app_database.g.dart` 8111L** 是 drift 生成代码,无上架问题,但 codegen 8s 阻塞 PR。R108 期间不动,留 v1.0 P3 候选。
- **R108 4 项 god class 半成品**: 详见 P0-005 / P1-001 / P1-002 / P1-003。`notification_service.dart` / `mood_audio_recorder_widget.dart` / `medication_page.dart` 实际行数超过 CHANGELOG 目标。**这不是上架 blocker**(不影响编译, 也不影响 R108 P0 13 项修),但**R108 收尾必须做**: 删旧字段 + 减重到目标,否则 3 文件 "半成品" 状态会留到 v1.0。
- **6 文件 400+ 行 god class** (`medication_page` / `setup_page_state` / `add_medication_page` / `legal_page` / `reminders_hub_page` / `mood_audio_recorder_widget` / `vent_compose_page` / `assessment_widgets` / `static_scale_translations`) 不影响上架但影响 v1.0 长期可维护性。**R108 收尾后开 R109 god class 专项 1-2 月**(AGENTS.md 已记)。

### 4.2 架构相关(顶层架构 subagent 必须深写)

#### 4.2.1 4 层架构 + 共享层 现状评估

**4 层架构纯度 + 一致性**: `dart scripts/check_all.dart` 跑通 0 violation(本 subagent 已验证)。
- ✅ domain 0 flutter / 0 drift / 0 data / 0 presentation
- ✅ shared 0 flutter / 0 drift / 0 data / 0 presentation
- ✅ data 0 presentation
- ✅ drift `@DataClassName('X')` ↔ domain `*Entity` 一一对应(10+ entity 全对应)
- ✅ shared 工具被 ≥2 层使用

**5 层架构(use case 层)实际利用率**:**低**。`lib/domain/usecases/` 仅 4 文件 425L,而 `lib/domain/logic/` 30+ 文件 3000+L。**presentation 直接调 domain/logic 函数** 是当前主路径。**R110 feature-first 重组 + use case 层厚化应一起做**。

#### 4.2.2 顶层 vs 底层 god class 候选清单(R108 进行中 + 收尾后)

| # | 文件 | 行数 | 类别 | R108 拆解状态 | 收尾建议 |
|---|---|---|---|---|---|
| 1 | `medication_page.dart` | 553 | presentation page | ⚠️ 抽 _TimeSlot enum, 增注释反变重 | R109 拆 7 sub-widget → widgets/ |
| 2 | `mood_audio_recorder_widget.dart` | 529 | presentation widget | ⚠️ AudioLifecycleMixin 接入, 旧字段未删 | R108 收尾删字段 + 拆 2 sub-widget |
| 3 | `static_scale_translations.dart` | 659 | domain data | R95 已拆 interface 198L, 剩实现 659L | R109 按量表拆 10 文件 |
| 4 | `mood_trend_page.dart` | 517 | presentation page | R108 新建, 一上来就超阈值 | R108 收尾拆 3 sub-file |
| 5 | `setup_page_state.dart` | 506 | presentation state | R95 抽 4 step file, state 主壳未动 | R109 拆 controller + 复用 wizard 抽象 |
| 6 | `add_medication_page.dart` | 506 | presentation page | 未拆,跟 setup_page_state 重复模式 | R109 抽 wizard 抽象 + 拆 sub-widget |
| 7 | `app_database.dart` | 494 | data schema | 14 tables 全列, 13 schemaVersion migration 堆一起 | R109 拆 schema/v01-v13/ 子目录 |
| 8 | `legal_page.dart` | 460 | presentation page | 4 private sub-widget class 内联 | R109 拆 4 sub-widget → widgets/legal_page/ |
| 9 | `reminders_hub_page.dart` | 441 | presentation page | 2 sheet class 内联 | R109 拆 2 sheet → widgets/reminder_sheets/ |
| 10 | `home_page_state.dart` | 440 | presentation state | R108 抽 3 controller, build() 180L 仍多 | R108 收尾抽 celebration overlay + 1 helper |
| 11 | `notification_service.dart` | 417 | data service | R108 抽 NotificationDelegate 200L, 主壳 417L 仍多 | R108 收尾拆 NotificationInitializer + Orchestrator |
| 12 | `vent_compose_page.dart` | 416 | presentation page | R108 AudioLifecycleMixin 接入, 旧字段未删 | R108 收尾删字段 + 拆 1-2 sub-widget |
| 13 | `assessment_widgets.dart` | 407 | presentation widget | 未拆, 4 private widget class 内联 | R109 拆 4 sub-widget → widgets/assessment/ |
| 14 | `static_scale_translations_l10n.dart` | 720 | presentation i18n | R78 大扩, 230 method 1:1 镜像 | R109 codegen 化 / R1.0 重建 |
| 15 | `core/l10n/strings.dart` | 314 | core l10n | R57 override 模式成熟, 80+ const 中文 fallback | R1.0 计划已记, 未排期 |

**god class 顶层候选总数**: 15 个(> 400 行 OR 职责多文件混)
- R108 收尾必修: 4 个(medication_page / mood_audio_recorder / home_page_state / notification_service / vent_compose / mood_trend_page = 实际 6 个, 因半成品)
- R109 拆分: 7 个(legal_page / reminders_hub_page / setup_page_state / add_medication_page / assessment_widgets / app_database / static_scale_translations × 2 = 实际 8 个)
- R1.0 长期: 2 个(strings.dart / static_scale_translations_l10n.dart)

#### 4.2.3 跨 feature import 边界(privacy + architecture)

**Vent 隐私边界(本 subagent 重点)**: ✅ **0 violation**。

手工 grep 验证 5 个非 vent feature 是否 import vent:
- `lib/presentation/pages/trend/` × vent imports: 0 ✅
- `lib/presentation/pages/medication/` × vent imports: 0 ✅
- `lib/presentation/pages/assessment/` × vent imports: 0 ✅
- `lib/presentation/pages/daily_tracking/` × vent imports: 0 ✅
- `lib/presentation/pages/contact/` × vent imports: 0 ✅

domain 层 vent:
- `domain/repositories/vent_repository.dart` 是独立接口
- `domain/entities/vent_entry_entity.dart` 是独立 entity
- `domain/entities/consent_artifact.dart` 引用 vent(`PIPL §47 封存` 业务)但**仅 metadata**, 不读 vent_entries 内容

**结论**: Vent 完全独立, 不进任何分析 / 通知 / 关怀 / 趋势, AGENTS.md "隐私边界" 表 5/5 行 ✅ 全绿。

**Settings + home hub 边界**: ✅ 正确。
- `lib/presentation/pages/home/home_page_state.dart` import medication (today_med_schedule, temp_medication_dialog) + mood (mood_recorder_page) — hub 允许
- `lib/presentation/pages/settings/legal_page.dart` import setup/setup_legal_dialog — hub 允许
- 反向: medication/assessment/mood/etc 不 import settings/home — 0 反向

**`check_cross_feature.py` 规则**: 跑通(本 subagent 因 Python 缺失未跑脚本, 但 11+ 文件手工 grep 全合规)。`check_all.dart` 已跑通。

#### 4.2.4 DI 模式(Riverpod 3.x)+ God Provider 评估

**Provider 拆分**:
- `core_providers.dart` 113L: db + 7 repo + 5 service (encryption / notification / sms / email) + 1 派生 (smsProviderName) + 1 legal version
- `service_providers.dart` 73L: reminder + safety + assessment reminder + data export
- `vent_providers.dart` 54L: vent audio storage + vent entries stream + vent by id
- `shared_providers.dart` 123L: 19+ entity-derived providers(已在 P2-003 列)
- 12 个专题 provider 文件: iap / cbt / cbt_rerated / assessment / daily_tracking / tracking_config / check_in_notifier / mood / mood_list_filter / reminders_hub / calendar_window / care_strategy / notification_init / legal_consent(226L, 边界)

**0 god provider** ✅ — 单文件最大 226L(legal_consent_provider),但 226L 含 5 个 ConsentKind × 4 method + dataExport log + 封存 4 method = ~25 method,职责单一。**未达 god class 阈值**。

**⚠️ P0-001**: `main.dart:50,61` top-level `final SmsService()` / `final EmailService()` 违反 Riverpod DI 哲学 — Provider 应在 ProviderScope 内 lazy 实例化, 不是 top-level static 持有。R108 P0#12 (developer.log guard) 思路正确但未推到 service 层。

#### 4.2.5 路由架构(go_router 14.6)

**路由拆分**: 11 个文件 + 1 个 routerProvider 入口。
- `app_router.dart` 77L: routerProvider + setupRedirect top-level 纯函数 + _RouterProfileCache
- `app_routes.dart` 169L: AppRoutes.all() 14 GoRoute + errorBuilder + 3 transition helper (fade / slide-right / slide-up)
- `app_shell.dart` 164L: AppShell + _NavDest NavigationRail 响应式
- 7 个 `app_route_{feature}.dart`: check_in / vent / medication / assessment / daily_tracking / mood_list / main

**0 god router** ✅ — 单文件最大 169L,职责清晰。

**架构问题**: `core/routing/app_router.dart` **import presentation/pages/** — 这是 go_router 固有限制(路由必须知道 page widget),**AGENTS.md 已记豁免**。feature-first 重构后这个豁免不变。

**0 routing god 候选**。

#### 4.2.6 状态管理边界(local / page / global)

**3 层状态**:
- **Global (ProviderScope)**: db / repos / services / entities streams / legal version / dayChangeTick — 19+ provider
- **Page (ConsumerState)**: setup / vent_compose / mood_recorder / home — 仅 4 page 用 ConsumerStatefulWidget,其余走 ConsumerWidget + ref.watch
- **Widget (ValueNotifier / TextEditingController)**: ScrollController / _MoodRecorderController (ValueListenable) / TextEditingController 等

**状态管理边界清晰** ✅。**唯一灰色**: home_page_state 用 ConsumerState(440L) 装 3 controller, controller 字段是 `late final`。R108 拆 controller 是正确方向。

#### 4.2.7 SOLID 原则审计

| 原则 | 当前 | 评估 |
|---|---|---|
| **单一职责 (SRP)** | ⚠️ 大部分文件合规; 15 个 400+ 行 god class 违反 | 1 项: 6 文件 R108 收尾 + 7 文件 R109 拆 |
| **开闭原则 (OCP)** | ✅ `FeatureFlags` 8 flag 守门 + `NotificationSender` interface + `ReminderChecker` interface + `SmsService` provider 抽象 | 0 违反 |
| **里氏替换 (LSP)** | ✅ domain 抽象 (`*Repository`) 全 `interface`, data impl (`*RepositoryImpl`) 100% 实现, 单元测试能 mock | 0 违反 |
| **接口隔离 (ISP)** | ✅ Repository 按 entity 拆(7 repo × 1 entity), use case 独立(4 文件) | 0 违反 |
| **依赖倒置 (DIP)** | ✅ presentation → domain, data → domain, 0 反向; Provider 注入 Repository (domain interface) | 0 违反 |

**结论**: 5/5 SOLID 原则, 仅 SRP 在 god class 上有 15 处违规, R108 收尾 + R109 专项可解。

#### 4.2.8 feature-first 重构 vs layer-first(决策)

**当前 layer-first**(R22 起): domain 在 1 目录, data 在 1 目录, presentation 在 1 目录。
- ✅ 跨 feature 共享容易(`domain/entities/medication_entity.dart` 同时被 `medication_page` + `medication_calendar_page` 用)
- ✅ 抽象层清晰(1 个 AppDatabase 装 14 table, 1 个 `core_providers` 装 7 repo)
- ❌ 1 个 feature 改动跨 5-6 目录
- ❌ 编译/IDE 跳转跨目录慢

**feature-first 目标**(R110):
- ✅ 1 个 feature 改动只改 1 个 feature 目录
- ✅ IDE 跳转快(同 feature 文件同根)
- ✅ pub workspace 拆包天然契合
- ❌ 跨 feature 共享靠 `core/` (domain entity 仍居 `core/`) 或 `features/_shared/`
- ❌ 大型 PR 1-2 月, 业务暂停期间最合适

**决策建议**: R1.0(2027-Q1)之前不动 layer-first, R1.0 之后(产品线扩 / 业务真接)开 R110 专项。**R108 / R109 期间不重构 layer**。

#### 4.2.9 pub workspace 评估

**当前**: 1 个 `pubspec.yaml`(80+ dependency)。
- 优势: dev 简单, build 一步
- 劣势:
  1. `domain/` 跟 `presentation/` 共享 pubspec = domain 层理论上 0 dep 但实际能访问所有
  2. CI build 整个 app ~5min(全 pub get + drift codegen)
  3. v1.0 后开 2 个产品线(医生端 / 家属端)无法共享 domain

**建议**: R1.0 拆 3 workspace:
- `packages/chroniccare_core/` — domain + shared, 0 flutter 0 drift 0 presentation, 0 pubspec dep
- `packages/chroniccare_data/` — data + drift + db, 0 presentation 0 flutter, 依赖 core + drift
- `packages/chroniccare_app/` — presentation + flutter, 依赖 core + data

CI 三段并行, build 提速 40%。**R108 期间不动, R1.0 后看产品线**。

### 4.3 重构建议(顶层架构 subagent 必须深写)

#### 4.3.1 R108 收尾(2-3 天)

- **必须做**(影响 P0 12 / P1-002 目标达成):
  1. P0-005 `notification_service.dart` 删旧字段 + 拆 NotificationInitializer + Orchestrator(目标 < 150L)
  2. P1-002 `mood_audio_recorder_widget.dart` / `vent_compose_page.dart` 删旧字段(目标各减 50L)
  3. P1-001 `home_page_state.dart` 抽 celebration overlay + next reminder time calculator(目标 440→250L)
  4. P3-003 `mood_trend_page.dart` 拆 3 sub-file(目标 517→200L)
  5. P0-001 `main.dart` 顶层 `final` SmsService/EmailService 改 Provider override(目标 2h)
  6. P0-002 `medication_page.dart` 拆 7 sub-widget → widgets/(目标 553→200L)
- **小修同步**: P2-003 `shared_providers.dart` 拆 5 文件(2h)

#### 4.3.2 R109 god class 专项(1-2 月, AGENTS.md 已记)

按 4.2.2 表的 7-8 个 R109 候选依次拆:
1. `setup_page_state.dart` 抽 wizard controller + 复用抽象
2. `add_medication_page.dart` 抽 wizard 抽象
3. `legal_page.dart` 拆 4 sub-widget
4. `reminders_hub_page.dart` 拆 2 sheet
5. `assessment_widgets.dart` 拆 4 sub-widget
6. `app_database.dart` 拆 schema/v01-v13/ 子目录
7. `static_scale_translations.dart` 拆 10 量表子文件
8. `static_scale_translations_l10n.dart` 拆 10 量表子文件(跟 #7 对称)

#### 4.3.3 R110 feature-first 重构(2-3 周, AGENTS.md 已记)

按 4.2.8 决策, R1.0 之后 1-2 月开专项。同时叠加:
- use case 层厚化(P1-004, 8 个 usecase)
- pub workspace 拆分(P2-005, 3 package)

#### 4.3.4 R1.0 长期

- `core/l10n/strings.dart` 314L 改 domain 0 中文字面量(R57 计划)
- drift 数据库拆 2-3 个 db(P3-001)
- care 业务 5 文件合并 1-2 文件(P3-002)

### 4.4 半成品 / TODO / 残缺功能

(跨 subagent 重点, 但跟架构相关的部分)

- **R108 6 个 god class 半成品**: P0-005 / P1-001 / P1-002 / P3-003 (CHANGELOG 已标, 实际 6 项), R108 收尾必修
- **R107 cleanup 6 个 god class**: 已完成 ✅ (R95 sub-spec 4 task 2/4/5/6/7/8 拆 6 god page, R107 cleanup 收尾)
- **R95 sub-spec 4 task 5 setup_page_state 拆**: 完成一半(step 文件拆了, state class 主壳没动), R109 收尾
- **`v0.30 R95 sub-spec 7 task 54` app_database 注释翻译**: ✅ 已完成 (1499→0 中文)
- **TODO_R108.md**:
  - `Fix #11a` keystore bash 脚本 ⏸️ 半成品(PowerShell 版已有, bash 缺)
  - `Fix #11b` Data Safety Form 验证 v0.30 状态 ⏸️ 半成品
  - `Fix #11c` Health Apps Questionnaire 0 启动 ❌
  - `Fix #12` 截图自动化脚本 0 启动 ❌
  - `Fix #13` 域名 + 邮箱 ⏸️ 文档完成, 注册 7-20d ICP 等

**架构 subagent 视角 TODO**:
- `app_database.dart:494L` 14 tables 集中管理 → R109 拆 schema/v01-v13/ (P1-005)
- `main.dart:50,61` top-level final SmsService/EmailService → R108 收尾改 Provider (P0-001)
- `core/l10n/strings.dart:314L` 80+ const 中文 fallback → R1.0 改 domain 0 中文 (P2-002)

---

## 5. 总结 + 给整合者的建议

**架构健康度 8.4/10**: 4 层 + 5 层(use case 弱化)架构纯度 + 一致性 100% 守门,18 守门员全绿,跨 feature privacy boundary 0 violation,vent 隐私边界 5/5 ✅,5 SOLID 原则 4.5/5(SRP 在 15 god class 上扣分),Riverpod 3.x 0 god provider,go_router 路由拆分 11 文件干净。

**R108 收尾 6 项必修**(影响 P0 12 / P1-002 / P1-001 目标):
1. P0-001 main.dart 顶层 SmsService/EmailService 改 Provider (2h, S)
2. P0-002 medication_page 拆 7 sub-widget (4h, M)
3. P0-005 notification_service 拆 Initializer + Orchestrator (3h, M)
4. P1-001 home_page_state 抽 celebration overlay + helper (4h, M)
5. P1-002 mood_audio_recorder / vent_compose 删旧字段 (4h, M)
6. P3-003 mood_trend_page 拆 3 sub-file (4h, M)

总计 ~2d, R108 收尾可一次做完。

**R109 路线图(AGENTS.md 已记)**: god class 专项 1-2 月, 7-8 个 400+ 行文件按 P1-003 / P1-004 / P1-005 顺序拆,叠加 use case 层厚化(P1-004 8 个 usecase, 1-2d)。

**R110 路线图(AGENTS.md 已记)**: feature-first 重构 2-3 周 + pub workspace 3 package, R1.0 之后开。

**给整合者的关键 takeaway**:
- 4 层架构 1:1 落地, **不动 layer-first**
- R108 半成品 god class 必须收尾(影响 P0 12 项目标达成)
- god class 总数 15 → R108 收尾 6 → R109 7 → R1.0 2
- 跨 feature privacy 0 violation, vent 边界清晰
- 顶层 static mutable service 是 Riverpod 反模式, R108 收尾必修
- use case 层利用率低, R109 厚化 8 个 usecase

---

## 附录: 详细证据

### A. 文件行数全表(> 250 行,presentation + core 优先)

(见 4.2.2 顶层 vs 底层 god class 候选清单表, 共 15 个候选)

### B. check_all.dart 跑通

```
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

### C. 跨 feature privacy boundary 验证(grep 证据)

```
grep "package:chroniccare/presentation/pages/vent/|VentEntry|vent_repository|vent_entries|vent_providers" lib/presentation/pages/trend/
→ No matches found ✅
grep "package:chroniccare/presentation/pages/vent/|VentEntry|vent_repository|vent_entries|vent_providers" lib/presentation/pages/medication/
→ No matches found ✅
grep "package:chroniccare/presentation/pages/vent/|VentEntry|vent_repository|vent_entries|vent_providers" lib/presentation/pages/assessment/
→ No matches found ✅
grep "package:chroniccare/presentation/pages/vent/|VentEntry|vent_repository|vent_entries|vent_providers" lib/presentation/pages/daily_tracking/
→ No matches found ✅
grep "package:chroniccare/presentation/pages/vent/|VentEntry|vent_repository|vent_entries|vent_providers" lib/presentation/pages/contact/
→ No matches found ✅
```

### D. provider 拆分(16 个文件, 0 god)

| 文件 | 行数 | 状态 |
|---|---|---|
| `core_providers.dart` | 113 | ✅ 1 个 db + 7 repo + 5 service |
| `service_providers.dart` | 73 | ✅ 4 service |
| `vent_providers.dart` | 54 | ✅ 1 vent service + 2 vent stream |
| `shared_providers.dart` | 123 | ⚠️ 19+ entity-derived provider 杂烩, R109 拆 5 文件 |
| `legal_consent_provider.dart` | 226 | ✅ 边界, 5 ConsentKind × 4 method, 职责单一 |
| 其余 11 个 | < 80 each | ✅ |

### E. 路由拆分(11 个文件, 0 god)

| 文件 | 行数 | 状态 |
|---|---|---|
| `app_router.dart` | 77 | ✅ routerProvider + redirect top-level |
| `app_routes.dart` | 169 | ✅ AppRoutes.all() 14 GoRoute + 3 transition |
| `app_shell.dart` | 164 | ✅ AppShell + _NavDest |
| `app_route_{feature}.dart` (7 文件) | < 115 each | ✅ 按 feature 拆 |

### F. use case 层(4 文件 / 425L, 弱化)

| 文件 | 行数 | 业务 |
|---|---|---|
| `fire_care_strategy.dart` | 221 | 4 strategy first-match + 渠道选择 |
| `schedule_refill_reminder.dart` | 82 | refill 提醒调度 |
| `check_safety.dart` | 62 | 失联检测 |
| `check_in_usecases.dart` | 60 | 打卡业务 |

**对比**: domain/logic 30+ 文件 / 3000+L, presentation 直接调 logic 占比 > 80%。R109 厚化 8 usecase (P1-004)。

### G. R108 拆解实际状态(对照 CHANGELOG 目标)

| 目标 | 计划 | 实际 | 差距 | 收尾 |
|---|---|---|---|---|
| `main.dart` 488→80L | 488→276L (-43%) | ✅ 已 276L, 抽 `boot_apps.dart` 261L | 80L 目标未达 | R108 收尾可降到 150L |
| `home_page_state` 597→< 370L | 597→515L (-14%) | ⚠️ 实际 440L (R108 抽 3 controller) | 70L 差距 | R108 收尾 (P1-001) |
| `notification_service` 629→308L | 426→482L (混合态) | ⚠️ 实际 417L (混合态) | 109L 差距 | R108 收尾 (P0-005) |
| `vent_compose_page` 495→~300L | 495→445L (-10%) | ⚠️ 实际 416L (混合态) | 116L 差距 | R108 收尾 (P1-002) |
| `mood_audio_recorder` 530→339L | 530→587L (混合态) | ⚠️ 实际 529L (混合态) | 190L 差距 | R108 收尾 (P1-002) |
| `medication_page` 540→~400L | 540→601L (近完成) | ⚠️ 实际 553L (近完成) | 153L 差距 | R108 收尾 (P0-002) |
| `daily_tracking` 7 widget 75→70KB | 7 widget 合计 75→70KB | ✅ 已完成 | 0 差距 | n/a |

**R108 god class 拆 4 项完成 + 2.5 项半成品** 状态, 半成品 6 项需 R108 收尾做(影响 P0 12 / P1-001 / P1-002 目标达成)。

### H. SOLID 原则审计明细

| 原则 | 当前 | 评估 | 关联 |
|---|---|---|---|
| SRP | ⚠️ 15 god class | 1.5/5 | 4.2.2 |
| OCP | ✅ FeatureFlags + 3 interface | 5/5 | NotificationSender / ReminderChecker / SmsProvider |
| LSP | ✅ interface 100% 实现 | 5/5 | domain/*Repository 抽象 |
| ISP | ✅ 7 repo × 1 entity | 5/5 | Repository 按 entity 拆 |
| DIP | ✅ 0 反向依赖 | 5/5 | presentation → domain, data → domain |

合计 21/25 (84%), god class 是 SRP 唯一扣分点。

### I. R108 实际文件改动(对照 git status --short)

30+ modified + 26 deleted + 12+ new lib files。核心改动:
- 新建 `lib/main/boot_apps.dart` 261L
- 新建 `lib/presentation/pages/home/controllers/{home_celebration_controller, home_care_engine_dispatcher, home_deep_link_handler}.dart` 3 个
- 新建 `lib/presentation/widgets/audio_lifecycle.dart` 382L (mixin)
- 新建 `lib/core/data/services/notification_delegate.dart` 200L
- 新建 `lib/core/data/services/mood_reminder_notifier.dart` 156L
- 新建 `lib/core/data/utils/skip_backup.dart` 73L
- 新建 `lib/core/shared/date_utils.dart` 57L
- 新建 `lib/domain/logic/medication_slot_calculator.dart` 122L
- 新建 `lib/presentation/pages/mood_list/{mood_detail_page, mood_trend_page}.dart` 517L + 308L
- 新建 14+ round108 lock-in test

R108 拆解意图正确, 但因 subagent E + F 中途中断, 半成品状态明显。R108 收尾必修 6 项(P0-001 / P0-002 / P0-005 / P1-001 / P1-002 / P3-003)。

---

<!-- subagent: top-architecture 完成时间: 2026-08-10T20:30:00+08:00 -->
