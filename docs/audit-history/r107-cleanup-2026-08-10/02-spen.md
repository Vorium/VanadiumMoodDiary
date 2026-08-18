# superpowers-en 视角审计报告 (2026-08-10)

> **视角**: 英文软件工程 — TDD / SDD / Code Review / Worktree / 测试金字塔 / 重构
> **基线**: [R105 spen 9.5/10](../../audit-archive-2026-08-10/2026-08-09/review-round-105/02-superpowers-en.md) (2026-08-09)
> **当前**: v0.30.0+85, 2019 test cases, 18 守门员, 0 analyzer error (按 R105 baseline; 2 守门员 FAIL 已知)
> **审计范围**: R101+ 未提交批次 (medication 重构 / mood 详情 + 趋势 / daily-tracking 自定义 / 8 量表)

---

## 0. 评分 (TL;DR)

**评分: 9.0 / 10**（较 R105 9.5 退化 -0.5）

**退化主因**:
1. R105 N1 (P1 silent data loss) 仅部分修复 — `_save()` 加了 `form` / `colorIndex`,但 `notes` 字段仍未持久化
2. R105 N4 / N5 / N6 死代码 3 处仍未清理 (mood_detail_page / mood_factor_analysis / mood_reminder_notifier UI 入口)
3. R105 2 个守门员 FAIL (`check_orphan_arb_keys` 42 孤儿 / `check_zh_hant_consistency` 16 简繁) 仍未修
4. R105 N10 / N11 / N12 / N13 / N15 DRY 与 i18n 重复未抽（日常追踪新模块又新增一批）

**保持的强项**:
- domain 0 flutter 依赖 (1 R105 验证 0 violation)
- core/data 0 material 依赖 (1 本审计 0 violation)
- 2019 test cases, 0 analyzer error, 18 守门员 (16 绿 + 2 已知 FAIL)
- 集成测试 6 个 (R95 sub-spec 6 baseline) — user journey 覆盖 check-in/streak/contacts/assessment/export/vent
- 隐私边界严格 (vent 数据绝不进任何 analysis / notification / care)
- Riverpod 3.3.2 + go_router 14.6 现代栈, FeatureFlag 门控所有未完成功能
- 拆分成熟: notification_service 629 → 469 行, home_page 731 → 138 + 590, setup_page 517 → 25 + 480, scale_translations_l10n 785 → 24 + 760

---

## 1. 优点 (具体证据)

### 1.1 架构纯度 (极高)
- `grep -l "^import package:flutter" lib/domain/` → **No matches found** (R105 验证)
- `grep -l "^import package:flutter/material" lib/core/data/` → **No matches found** (本审计验证)
- 4 层架构由 `dart scripts/check_all.dart` 自动校验 (R95 sub-spec 6 加, 当前 2/2 全绿)
- 跨 feature import 边界由 `python scripts/check_cross_feature.py` 校验 (R17 round 12 起, 当前 131 文件 0 violation)

### 1.2 拆分成熟 (本批新增强)
- **`notification_service.dart` 629 → 469 行** (R65: 6 sub-service + SafetyAlertBuilder 委派)
  - `MedicationNotifier` / `RefillNotifier` / `AssessmentNotifier` / `MoodReminderNotifier` (R56c/R56c''' TDD 续, +40 unit test)
  - 6 类 ID 范围常量 (1001/2000+/5000/6000+/7000/9999/300000+) R19 fix + R95 sub-spec 1 文档化
- **`home_page.dart` 731 → 138 + `home_page_state.dart` 590 行** (R95 sub-spec 4 task 5)
  - `HomeLifecycleState` 3 bool → 1 enum 状态机 (R64 防御 race)
  - `_celebrationTimer` + `_deepLinkRaceTimer` + `_scrollController` 3 resource 走 dispose cancel (R62/R63/R92)
- **`setup_page.dart` 517 → 25 + `setup_page_state.dart` 480 行** (R95 sub-spec 6 commit 3)
- **`scale_translations_l10n.dart` 785 → 24 + `static_scale_translations_l10n.dart` 760 行** (R95 sub-spec 6 commit 2)
- **`medication_calendar_page` 642 → 209 行** (R93 task 1)
- **`mood_period_aggregator` 集成遗留 fail 修** (R95 sub-spec 6 commit 1, 修正 +7 行加 `now` 参数)

### 1.3 守门员体系 (18 脚本, 16 绿 + 2 已知 FAIL)
- `check_coverage.py` (R95 sub-spec 6 新增, 5 层阈值 + 3 critical file + lcov 解析)
- `check_16kb_alignment.py` (R77 新增, Google Play 2025-11 强制)
- `check_legal_consent.py` / `check_sms_release_ready.py` (R57 新增, PIPL §13/§14 + AppStore 3.1.5 准备度)
- `check_orphan_arb_keys.py` (R56e 新增, 一次性清 39 个 orphan)
- `check_no_pua.py` / `check_no_hardcoded_utc.py` / `check_widget_dispose.py` (R45-48 新增)
- `check_datetime_race.py` + `check_datetime_race2.py` (跨函数/跨 DateTime(y,m,d) race 双保险)

### 1.4 集成测试 (从 1 扩到 6)
- R95 sub-spec 6 commit 4: `test/integration/end_to_end_flows_round95_test.dart` 300 行, 5 user journey
  - 打卡 → streak 实时
  - 紧急联系人 → contactsProvider + ConsentArtifact
  - 评估 → PHQ-9 → DB round-trip
  - 导出 → JSON 含 schema + data
  - vent 树洞 → 写 + 加密 + 删除 (PIPL §47)

### 1.5 TDD 续命 (R56c 系列)
- `db_key_service` +5 unit (FlutterSecureStorage MethodChannel mock 模式)
- `refill_notifier` +10 (id 公式 + `computeRefillFireTime` 纯函数 + `scheduleRefillReminder` instance)
- `medication_notifier` +10 (ID 常量 + `scheduleDailyReminder` + `rescheduleMedicationReminders`)
- `assessment_notifier` +4 + `safety_alert_dispatcher` +7 + `mood_audio_service` +10 = +21

### 1.6 资源管理成熟
- `select-string "cancel\(\);"` 全工程一致 (Timer / StreamSubscription / AudioPlayer / ScrollController 4 类全 cancel)
- `try { ... } finally { await player.dispose(); }` 模式统一 (R19B 修过 leak)
- `home_page_state.dart:120-135` dispose 4 行 cancel 模板可复用

### 1.7 死代码 / 静默吞错清零
- `grep "print\("` 在 `lib/` → 0 (production 无 print)
- `grep "catch\s*\(_\)"` 在 `lib/` → 0 (全走 `swallowError` 集中器)
- `grep "catch\s*(e)\s*{"` 在 `lib/` → 0 (业务路径全走 `swallowError` 或显式 log)

---

## 2. 问题清单 (R101+ 新发现 + R105 未修)

| # | 文件:行 | 问题 | 层级 | 难度 | 优先级 | 修复建议 |
|---|---------|------|------|------|--------|----------|
| **R105 未修** ||||||
| 1 | `lib/presentation/pages/medication/add_medication_page.dart:91-94` | `_save()` 缺 `notes` 字段 (R105 N1 部分修, form+colorIndex 修, notes 漏) — 静默丢用户备注 | 正确性 | 简单 | **P1** | 加 `notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim()`, +1 widget test |
| 2 | `lib/presentation/pages/mood_list/mood_detail_page.dart` | 死代码, 全工程无 route 入口 (R105 N4) | 一致性 | 简单 | P2 | 接 `MoodListItem.onTap → push /mood-detail`, 或删文件 + 同步删 ARB key |
| 3 | `lib/presentation/pages/mood_list/widgets/mood_factor_analysis.dart:17,96-130` | 死代码, 全工程无 mount (R105 N5), `_analyze` build 内对全量 entries 重算无 memo | 一致性 + 性能 | 中 | P2 | 挂到 mood_trend 或 mood_list 详情; `_analyze` 抽 computed provider + memo |
| 4 | `lib/core/data/services/mood_reminder_notifier.dart:45` + `notification_service.dart:290,295` | `scheduleMoodReminder` 已注, 但全工程无 UI 开关调用 (R105 N6) — 功能半成品 + 25 个 moodReminder* ARB key 孤儿 | 一致性 | 简单 | P2 | reminders_hub/settings 加开关接线; 否则删 service + ARB key |
| 5 | `lib/core/data/privacy/encrypted_audio_storage.dart:116,127,208` | `Random().nextInt(10000)` 非 secure (R105 N14), 跟 `db_key_service` / `encryption_service` 已 secure 不一致 | 安全 | 简单 | P2 | 全改 `Random.secure().nextInt(10000)` |
| 6 | `lib/l10n/app_zh.arb` (含 zh_Hant) | `check_orphan_arb_keys.py` 42 孤儿 key + `check_zh_hant_consistency.py` 16 处简繁不一致 (R105 N3, R105 已知 FAIL) | 工程守门员 | 简单 | **P1** | 新 feature ARB key 接线; zh_Hant 走 OpenCC s2tw 校正 (medAdd* / medEmpty* / 添加 vs 新增) |
| 7 | `lib/presentation/pages/medication/medication_page.dart:168-214,48-187` + `today_med_schedule.dart:24,112-150` + `today_summary_card.dart:34-42` | DRY 退化: `_SlotEntry` + `_ScheduleEntry` + summary 3 处重复实现 (R105 N10) | 架构/DRY | 中 | P2 | 抽公共 helper (`activeMeds×times 展平 + 当日已打卡 medIds`), 3 处复用 |
| 8 | `lib/presentation/pages/medication/*` + `medication_detail_page.dart:82` + `add_medication_page.dart:332,373` + `mood_detail_page.dart:264` + `mood_list_item.dart:83` | 71 处 `padLeft(2,'0')` 手写时间格式化, 不复用 `HourMinute.toTimeString()` / `Formatters` (R105 N11) | 架构/DRY | 简单 | P2 | 全改 `t.toTimeString()` / `Formatters.dateTime` |
| 9 | `lib/domain/logic/trend_calculator.dart:188` + `care_strategies.dart:29,32,46` | `_dateOnly` 5 处仍私有 + `DateTime(y,m,d)` 4 处内联, `date_utils.dart` 已建但只 2 处引用 (R105 N13) | 底层/DRY | 简单 | P2 | 全替换为 `isSameCalendarDay` / `calendarDaysBetween`; `assessment_comparison:273` 残余 `_daysBetween` wrapper 一并删 |
| 10 | `lib/domain/entities/influence_category.dart:36-118` + `mood_influence_chips.dart:97-141` | domain 硬编 36 个因子名中文 (违反 domain 0 中文约束), chips 直接显示原中文; `kInfluenceFactorKeys` 定义但 0 调用, 注释引用的 `kInfluenceFactorsL10n` 不存在 (R105 N15) | 架构/i18n | 中 | **P1** | chips 走 `kInfluenceFactorKeys → l10n` (25 个 `influenceFactor*` ARB key 顺便接线); 删死 map/注释; domain 只留 key 定义 |
| 11 | `lib/domain/logic/day_detail.dart:371-394` + `check_in_entity.dart:85-95` | `_scaleName` 只映射 phq9/gad7 (其他 6 量表显 raw id); `_assessmentScaleIds` 硬编 3 量表 (R105 N16) | 底层/i18n | 简单 | P2 | `scale_registry` 统一 `displayName` + id 映射 |
| 12 | `lib/presentation/pages/mood_list/mood_trend_page.dart:64,20-21,311-317,382,539-540` | 硬编 `Tab('CBT')` / `7D/30D/6M/1Y` / emoji 数组 / hex 颜色 (未走 ARB / `MoodVisual.emojiFor` / `AppTokens`); `kMedPillColors` 跟 `tracking` 颜色值重复 (R105 N17) | 底层/i18n+UI | 简单 | P3 | 文案/区间走 ARB; emoji 走 `MoodVisual`; 颜色走 `AppTokens`; pill 色复用 `tracking` 色 token |
| 13 | `lib/presentation/providers/tracking_config_provider.dart:90-128,23-29` | `_save` fire-and-forget (快速连续 toggle 可丢写); `get(id)` 未查 id 静默返空, mood 配置丢失 (R105 N18) | 正确性 | 简单 | P3 | 合并写 + 队列化; 未查 id 走 `kDefaultTrackingItems` 反查, 找不到返空 config |
| 14 | `lib/presentation/pages/medication/medication_detail_page.dart:181` | R105 N7 提的编辑按钮 `onPressed: () {}` no-op 仍未挂 (本审计 grep 未匹配, 实际可能改了) | 半成品 | 中 | P2 | 验证现状; 接 `EditMedicationDialog` 或先隐藏按钮 (no-op 比没按钮更糟) |
| **R101+ 新发现** ||||||
| 15 | `lib/presentation/pages/medication/medication_detail_page.dart:415` + `medication_page.dart` | R105 N1 提的"列表/详情页同款 TODO" 仍存在, `colorIndex: 0` TODO 未改取实体值 | 正确性 | 简单 | **P1** | 跟 N1 一起, 修正 2 处实体读取 |
| 16 | `lib/presentation/pages/daily_tracking/widgets/sleep_widgets.dart` (12.7KB) + `weight_widgets.dart` + `anxiety_agitation_widgets.dart` + `social_rhythm_widgets.dart` + `stress_event_widgets.dart` + `treatment_list.dart` + `treatment_add_dialog.dart` (各 10-12KB) | **新增日常追踪模块 7+ widget 各自 god class, 跨 widget 重复 `_formatTime` / `_buildSliderField` / `_buildCategoryChip` 模式** (本批新功能未经 spen 审计) | 架构/DRY | 中 | **P1** | 抽 `daily_tracking_widgets.dart` 公共 helper: `buildSliderField` / `buildCategoryChip` / `formatDuration`; 7 widget 共用 |
| 17 | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:55-61,153` | R105 N9 提的 `_isToday` build 内 `DateTime.now()` 未走 `todayProvider`, 跨 midnight 判定 stale (R17 round 4 同款 pattern) | 正确性 | 简单 | P2 | watch `todayProvider` 复用同一 now |
| 18 | `lib/presentation/pages/daily_tracking/widgets/tracking_item_card.dart:152-235` + `tracking_customize_page.dart:175-207` | R105 N12 提的 `_getLocalizedName` (152-235) + `_getCategoryLabel` (175-207) 两个 switch 重复, `category→label/icon` 映射硬落 | 架构/DRY | 简单 | P2 | 抽 `tracking_item_config_ext.dart` 统一 `nameKey/categoryKey → l10n` 映射 |
| 19 | `lib/presentation/pages/daily_tracking/mood_list/mood_trend_page.dart:186-202,152` | R105 N8 提的 `_MoodLineChart` 日均值用 `.sum / .seen` (各点权重不均, 非当日均值); build 内 `DateTime.now()` 未挂 `todayProvider`, 跨 midnight 数据 stale (AGENTS 已知坑) | 正确性 | 简单 | P2 | 按日 sum/count 求期平均; 图表 watch `todayProvider` 复用同一 now |
| 20 | `lib/domain/entities/check_in_entity.dart:19` (R101 P2 #19) | `isNormal` 用字符串比较 (`_assessmentScaleIds` 硬编 3 量表 + isNormal 字符串比较), 跟 `scale_registry` 重复定义 | 底层 | 简单 | P3 | `scale_registry.isNormal(score, scaleId)` 统一 |
| **架构/可维护性 (R105 关注外)** ||||||
| 21 | `lib/presentation/pages/home/home_page_state.dart:30-31` | 顶层 import `safety_watch_service` 跟 `fire_care_strategy` (domain usecase), 跨 `presentation → core/data/services` + `domain/usecases` — 数据流在 home 集中, god class 590 行负责 9 业务方法 | 架构 | 中 | P2 | 抽 `home_lifecycle.dart` (5 状态 + 3 transition) + `home_actions.dart` (9 业务方法 facade), home_page_state 只管 build |
| 22 | `lib/core/data/services/notification_service.dart:290-299` | `scheduleMoodReminder` facade 委派 5 行委派到 `_moodReminderNotifier.scheduleMoodReminder`, 跟 R65 拆 6 sub-service 模式一致; 但因 R105 N6 UI 不接, 实际是死路径 | 半成品 | 简单 | P2 | 接线或删除 (跟 #4 一起) |
| 23 | `lib/main.dart:488` (R95 sub-spec 6 修正后 19KB) | main.dart 仍 488 行, 5 阶段: 1) env 2) DB 迁移 3) 通知 init 4) SMS/Email/StoreKit 守卫 5) App 启动; 5 `_XxxApp` 内部 widget (_EarlyLoadingApp / _MigrationPromptApp / _MigrationAbortedApp / _MigrationFailedApp + 共享 controller) | 架构 | 中 | P2 | 抽 `lib/app/bootstrap/` 子目录: `bootstrap.dart` 编排 + `migration_apps.dart` 4 内部 widget; main.dart 缩到 80 行 |
| 24 | `lib/core/data/services/safety_watch_service.dart:15.4KB/361 行` | 仍 361 行, 包含 timeout 编排 + SMS 发送 + lost_contact_sms 文案 + 状态机; 4 业务模式 (P0 fail-fast R38 修) + 4 notification id 范围 | 架构 | L | P2 | 抽 `safety_watch_state.dart` (state machine) + `safety_watch_sender.dart` (SMS 委派) + `safety_watch_timeout.dart` (timeout 编排); facade 缩到 100 行 |
| 25 | `lib/core/data/services/sms_service.dart:13.2KB/338 行` | facade 338 行, `AliyunSmsProvider` 仍 2 文件 + 1 状态机; R38 P0 fail-fast 已加, 但 AliyunSms 真接留 R55 (外部依赖) | 架构 | 中 | P3 | 真接前不动, R55 一起重构 |

---

## 3. 跟 R95 9.0 / R101 9.0 / R105 9.5 对比

| 项 | R95 8.0 | R101 9.0 | R105 9.5 | 当前 9.0 |
|---|---------|---------|---------|---------|
| 4 层纯度 | 1 违规 (R100 修) | 0 | 0 (R104 修) | 0 ✓ |
| 跨 feature 边界 | 部分 | 0 | 0 (131 文件 0 violation) | 0 ✓ |
| god class 拆分 | 8 个 600+ 拆剩 5 | 11 个 god page 续拆 | R95 sub-spec 1-8 拆 2 (scale_translations_l10n / setup_page) | 2 新 god widget (daily_tracking 7 文件) |
| catch (_) 静默吞错 | 10+ | 9 (P2 #11) | 0 (全 swallowError) | 0 ✓ |
| 集成测试 | 1 | 1 (待 3-5) | 6 (R95 sub-spec 6) | 6 ✓ |
| coverage 阈值 | 0 | 0 | 5 层阈值 (73.8/47/57.4/88.1/25.8%) | 同 R105 ✓ |
| 18 守门员 | 部分 | 17/18 | 16/18 (2 已知 FAIL: orphan + zh_hant) | 16/18 (同 R105) |
| StreamSubscription / Timer dispose | 部分 | 部分 | 全 cancel | 全 cancel ✓ |
| 死代码 | 多 | 少 | R105 N4/N5/N6 3 处 | 3 处 (同 R105) |
| Resource leak 模式 | R19 修过 | R19 修过 | R19 修过 | R19 修过 ✓ |
| TDD 续 (sub-service) | 18+ 待补 | 0 | 0 (R56c 续修) | 0 ✓ |
| `print(` in production | 多 | 0 | 0 | 0 ✓ |
| 隐私边界 (vent) | 严 | 严 | 严 | 严 ✓ |

**退化点** (vs R105):
- **N1 部分修不完整** (-0.2): 2 个 P1 静默丢数据只剩 1 个, notes 字段未持久化
- **N4/N5/N6 死代码未清** (-0.2): mood_detail / mood_factor_analysis / mood_reminder UI 接线缺失
- **2 守门员 FAIL 仍 FAIL** (-0.05): orphan 42 + zh_hant 16 已知问题, 跟 R105 持平
- **新增日常追踪 7+ widget 各 10-12KB** (-0.05): DRY 退化 + 跨 widget 重复 helper 模式

**保持点** (vs R105):
- 0 analyzer error, 2019 tests, 16/18 守门员绿
- 4 层架构纯度 + 跨 feature 边界 + 资源管理 + 死代码 catch/print 清零

---

## 4. 重点: 架构改进 + god class 候选 + 重构路径

### 4.1 高内聚低耦合 (3 个高 ROI 重构)

**A. `daily_tracking_widgets.dart` 公共 helper 抽离 (P1, ROI 高)**
- 当前: 7 widget 各自手写 `_formatTime` / `_buildSliderField` / `_buildCategoryChip`, 跨 widget 重复
- 收益: -200 行, 7 widget 各减 30 行, 新增 tracking 类别时 0 重复 boilerplate
- 风险: 低 (纯 helper, 0 业务逻辑)

**B. `home_page_state.dart` 590 行拆 `home_actions.dart` facade (P2, ROI 中)**
- 当前: state class 兼 build + 9 业务方法 + 3 Timer 资源 + 5 状态机
- 拆法: `home_lifecycle.dart` (5 状态 + 3 transition) + `home_actions.dart` (9 业务方法 facade) + `home_page_state.dart` (只管 build)
- 收益: state class 缩到 250 行, 业务方法可独立 widget test

**C. `main.dart` 488 行抽 `bootstrap/` 子目录 (P2, ROI 中)**
- 当前: 5 阶段串在 `_bootstrap()` 一函数 + 4 `_XxxApp` 内部 widget
- 拆法: `app/bootstrap/bootstrap.dart` 编排 + `app/bootstrap/migration_apps.dart` 4 widget + `app/bootstrap/notification_init.dart`
- 收益: main.dart 缩到 80 行, _bootstrap 可独立 test, _XxxApp 可复用

### 4.2 god class 候选 (按 ROI 排序)

| 文件 | 当前 | 目标 | 重构路径 |
|------|------|------|----------|
| `daily_tracking/widgets/sleep_widgets.dart` | 12.7KB/368 | 8KB | 抽公共 `buildSleepField` + 复用 `daily_tracking_widgets.dart` helper |
| `daily_tracking/widgets/anxiety_agitation_widgets.dart` | 10-12KB | 8KB | 同上 |
| `daily_tracking/widgets/stress_event_widgets.dart` | 10-12KB | 8KB | 同上 |
| `daily_tracking/widgets/social_rhythm_widgets.dart` | 10-12KB | 8KB | 同上 |
| `daily_tracking/widgets/weight_widgets.dart` | 10-12KB | 8KB | 同上 |
| `daily_tracking/widgets/treatment_list.dart` + `treatment_add_dialog.dart` | 各 10-12KB | 各 8KB | 抽 treatment 表单公共 helper |
| `home_page_state.dart` | 30KB/641 (含 home_page 138) | 14KB 总 | 拆 3 文件 (A + build) |
| `notification_service.dart` | 21.2KB/469 | 12KB | R65 已拆 6 sub-service, 续拆 facade init 60 行 + showSafetyAlert 5 行 + 5 sub-service 委托 30 行 |
| `safety_watch_service.dart` | 15.4KB/361 | 8KB | 抽 state machine + sender + timeout 3 文件 |
| `mood_list/mood_trend_page.dart` | 19.2KB/547 | 12KB | 拆 `_MoodLineChart` (N8 fix) + `mood_factor_analysis` 挂入 (N5 fix) |
| `mood_audio_recorder_widget.dart` | 19.7KB/563 | 12KB | 拆 recorder + timer + UI 3 文件 |
| `medication_page.dart` | 18KB/575 | 12KB | 抽 `_buildTimeSlots`/`_SlotEntry` 到共享 helper (N10) |
| `vent_compose_page.dart` | 17.8KB/517 | 12KB | 拆 compose + record + preview 3 文件 |

### 4.3 重构路径 (按 ROI 排序)

| 优先级 | 任务 | ROI | 估时 |
|--------|------|-----|------|
| P1 | `daily_tracking_widgets.dart` 公共 helper 抽离 (7 widget 减 30 行) | 高 | 2-3d |
| P1 | R105 N1 修正 (`notes` + 2 处列表/详情) | 高 | 1d |
| P1 | R105 N3 修守门员 FAIL (42 orphan + 16 zh_hant) | 中 | 1-2d |
| P1 | R105 N15 chips i18n 接线 (25 个 influenceFactor* ARB key) | 中 | 2d |
| P1 | R101+ N15 列表/详情 `colorIndex: 0` TODO | 高 | 1d |
| P2 | R105 N4-N7 死代码 4 处清理 / 接线 | 中 | 2-3d |
| P2 | R105 N10 DRY 抽 `medication_time_helper` | 中 | 1-2d |
| P2 | R105 N11 71 处 `padLeft(2,'0')` 替换 | 中 | 1d |
| P2 | R105 N13 `_dateOnly`/`DateTime(y,m,d)` 全替换 | 中 | 1d |
| P2 | R105 N14 `Random() → Random.secure()` | 高 | 30min |
| P2 | `main.dart` 488 → 80 拆 `bootstrap/` | 中 | 1-2 周 |
| P2 | `home_page_state` 拆 3 文件 | 中 | 1 周 |
| P2 | `safety_watch_service` 拆 3 文件 | 中 | 1 周 |
| P2 | R105 N16 `_scaleName` 走 `scale_registry` | 低 | 1d |
| P2 | R105 N17 mood_trend 硬编 → ARB / MoodVisual / AppTokens | 低 | 1-2d |
| P3 | R105 N18 tracking_config `_save` 合并写 + `get(id)` 反查 | 低 | 1-2d |
| P3 | `notification_service` 续拆 facade | 低 | 3-5d |
| P3 | R105 N12 tracking `_getLocalizedName` 抽 helper | 低 | 1d |
| P3 | R101 P2 #20 `isNormal` 走 `scale_registry` | 低 | 1d |

---

## 5. 测试覆盖率 + lock-in test + integration test 现状

### 5.1 测试金字塔 (实测, R95 sub-spec 6 沿用)
| 层 | 文件数 | 占比 | 估用例数 | 实测覆盖率 (R95 sub-spec 6) |
|----|--------|------|----------|----------------------|
| `test/domain/` | 66 | 25% | ~1200 | **73.8%** ✓ (≥70% 阈值) |
| `test/data/` + `test/core/data/` | 42 + 2 | 17% | ~500 | **47%** △ (未达 50% 阈值, 已知 R96 留) |
| `test/presentation/` | 95 | 36% | ~900 | **57.4%** ✓ (≥30% 阈值) |
| `test/integration/` | 2 | 1% | 6 | 6 user journey |
| `test/core/` (含 theme/l10n) | 43 | 16% | ~300 | **25.8%** △ (R95 sub-spec 6 加 coverage 阈值, 留 R96) |
| `test/shared/` + `routing/` | 2 | 1% | ~50 | **88.1%** ✓ |
| **总计** | **261** | 100% | **2019** | — |

**问题**:
- 1. **data 47% 未达 50% 阈值** (R95 sub-spec 6 已知 issue, 留 R96+ 提)
- 2. **core 25.8% 远未达** (l10n 生成文件排除后仍 30%+, R95 sub-spec 6 已知)
- 3. **presentation 36% 文件** 偏重 widget test, 但单文件质量高 (ProviderScope override 真实 in-memory DB)
- 4. **integration 1%** 6 个 e2e 已加, 但 R95 报告 §3.2 P1 #6 提"应扩到 10+"

### 5.2 lock-in test 现状
- **220+ lock-in test** (R76 起累计, 防止 token / 颜色 / 字体 / 时长 / EdgeInsets 回归)
- 关键 lock-in:
  - `app_tokens_lock_in_round95_test.dart` (318 行, 6 group, 20 test — TextStyle/EdgeInsets/Duration/AppSpacing/AppTypography/AppMotion)
  - `badge_sync_service_swallow_error_lock_in_round95_test.dart` (R95 N10 P0 fix)
  - `care_copy_round18_test.dart` (R18 集中 4 触发文案)
  - `scale_strings_arb_lock_in_round95_test.dart` (R95 sub-spec 7 +13 key baseline 1058)
  - `assessment_dao_pii_safe_round95_test.dart` (R95 sub-spec 7 task 30 PII 泄露锁)
  - `app_tokens_dark_round18_test.dart` (dark mode token)
  - `data_group` / `legal_group` / `reminders_group` / `profile_group` 4 group widget test (R95 sub-spec 8 commit 2)

### 5.3 integration test 现状
- `test/integration/end_to_end_flows_round95_test.dart` 300 行, 6 user journey:
  1. 打卡 → streak 实时 (CheckInRepository + StreakCalculator + allNormalCheckInsProvider)
  2. 设置 → 紧急联系人 → contactsProvider + ConsentArtifact PIPL §13
  3. 评估 → PHQ-9 → DB round-trip (JSON 编码 score+severity+answers)
  4. 数据导出 → JSON 含 schema + data (7 段 + R57 schema version)
  5. vent 树洞 → 写 + 加密 + 删除 (PIPL §47)
  6. (待加) R95 报告 §3.2 P1 #6 提的 "10+ user journey" 缺 4 个

### 5.4 widget test 真实性
- 模式统一: `ProviderScope(overrides: [...])` + `MaterialApp` + `tester.pumpAndSettle`
- `Material 3 ink_sparkle shader` fix 已知 (R17 round 8 — `assets/shaders/ink_sparkle.frag` + pubspec `shaders:` 声明)
- `MethodChannel mock` 模式 (FlutterSecureStorage / 通知 / 录音) 在 R56c 系列普及

### 5.5 fixture / builder 复用
- **缺**: `test/helpers/` 目录 (R95 报告 §3.2 提"应加 `test_helpers.dart` 收 common setup" — 待 R96+)
- 现状: 多个 widget test 各自 inline `MaterialApp(home: ProviderScope(overrides: [databaseProvider.overrideWithValue(InMemoryAppDatabase()), ...]))` boilerplate

---

## 6. 调试 / 工程实践评估

### 6.1 强项
1. **TDD 成熟**: 业务逻辑层 (domain 32 文件) 几乎都有 lock-in test, R56c 系列给 sub-service 加 41 unit
2. **守门员脚本 18 个**: CI 友好, 覆盖架构/一致/法律/隐私/守门员/i18n/PUA/UTC/datetime race
3. **资源管理**: Timer / StreamSubscription / AudioPlayer / Recorder 全 dispose cancel (R19 修过, R19B 加 try/finally 模式)
4. **错误兜底**: `runZonedGuarded` + `FlutterError.onError` + `LastErrorCapture` 三层 (R22 round 33 spen P0 + R45 R51b)
5. **隐私边界**: vent 数据 0 进 analysis/notification/care, check_cross_feature.py 守门员
6. **commit 规范**: `<version> round <N>: <title>` 一致 (R23 起)
7. **CHANGELOG 维护**: Keep a Changelog 格式, v0.30.0 10+ sub-spec 收尾文档全

### 6.2 弱项
1. **R105 14 项 N1-N18 仍未修** — 已知 backlog 留 R106+
2. **2 守门员 FAIL (orphan + zh_hant)** — CI fail 但未阻塞 merge
3. **R101+ 新增 daily_tracking 7 widget 未做 spen 审计** — DRY 退化模式已显现
4. **死代码 3 处** (mood_detail / mood_factor_analysis / mood_reminder UI) — 知道但未清
5. **god class 候选 13 个** (>15KB 文件, 部分 R95 已拆剩)
6. **多 widget 重复 helper** (sleep/weight/anxiety/stress/social_rhythm/treatment) — 7 个文件各 10-12KB
7. **`main.dart` 488 行多职责** — 5 阶段 + 4 内部 widget

### 6.3 调试 (R95 已知坑)
- DateTime race: check_datetime_race.py + check_datetime_race2.py 双守门员 ✓
- DateTime.now() build 内取: 27 处 `!mounted` check + 1 处 `ref.mounted` (Riverpod 3.x 限制) ✓
- 跨 midnight streak 不刷新: AppRoot midnight timer + `nextMidnightRefresh` 纯函数 (R17 round 4) ✓
- Stream subscription leak: `check_widget_dispose.py` 守门员 (R48 加, 1 false positive known) ✓
- 国产 ROM 静默杀: `NotificationStatusCard` 自检 (R20 加) ✓
- Schema version 漏 migration: `check_changelog.py` 校验 (R48 加) ✓
- Material 3 ink_sparkle shader: assets 复制 fix (R17 round 8) ✓

### 6.4 缺失的工程实践
1. **codecov / coverage 趋势** — 配置文件已有 (R95 sub-spec 6 commit 5), 缺实际接入 CI
2. **`test/helpers/test_helpers.dart`** — 缺统一 fixture/builder, 多个 widget test 重复 boilerplate
3. **CI workflow 文件** — 缺 `.github/workflows/` 配 18 守门员 + `flutter test` + coverage 上传
4. **release publish 自动化** — fastlane 配置 / 签名 / 商店上传脚本 (外部依赖)
5. **CHANGELOG 自动生成** — 当前手写, 多 sub-spec 量大易漏
6. **R105 14 项 backlog tracking** — 缺 `docs/backlog/r105-fixes.md` 跟踪 P0/P1/P2/P3

---

## 7. 推荐的下一步重构 (按 ROI 排序)

| # | 任务 | ROI | 估时 | 优先级 |
|---|------|-----|------|--------|
| 1 | **修 2 守门员 FAIL** (orphan 42 + zh_hant 16) | 中 | 1-2d | P1 |
| 2 | **R105 N1 修正** (notes + 列表/详情 colorIndex: 0) | 高 | 1d | P1 |
| 3 | **daily_tracking 7 widget 公共 helper 抽离** | 高 | 2-3d | P1 |
| 4 | **R105 N15 chips i18n 接线** (25 influenceFactor* ARB key + 删 domain 硬编) | 中 | 2d | P1 |
| 5 | **R105 N14 `Random() → Random.secure()`** | 高 | 30min | P2 |
| 6 | **R105 N4-N7 死代码 4 处清理 / 接线** | 中 | 2-3d | P2 |
| 7 | **R105 N10 DRY 抽 medication time helper** | 中 | 1-2d | P2 |
| 8 | **R105 N11 71 处 padLeft 替换** | 中 | 1d | P2 |
| 9 | **R105 N13 `_dateOnly` 全替换** | 中 | 1d | P2 |
| 10 | **`main.dart` 488 → 80 拆 bootstrap/** | 中 | 1-2 周 | P2 |
| 11 | **`home_page_state` 590 → 250 拆 3 文件** | 中 | 1 周 | P2 |
| 12 | **`safety_watch_service` 361 → 100 拆 3 文件** | 中 | 1 周 | P2 |
| 13 | **`test/helpers/test_helpers.dart` 统一 fixture** | 中 | 2-3d | P2 |
| 14 | **CI workflow + Codecov 接入** | 中 | 2-3d | P2 |
| 15 | **R105 N12 tracking 抽 helper** | 低 | 1d | P3 |
| 16 | **`mood_trend_page` 547 → 350 拆 _MoodLineChart + 挂 factor_analysis** | 低 | 3-5d | P3 |
| 17 | **`mood_audio_recorder_widget` 563 → 350 拆 3 文件** | 低 | 3-5d | P3 |
| 18 | **`notification_service` 469 → 300 续拆 facade** | 低 | 3-5d | P3 |
| 19 | **`medication_page` 575 → 350 抽 time slot helper** | 低 | 3-5d | P3 |
| 20 | **`vent_compose_page` 517 → 350 拆 3 文件** | 低 | 3-5d | P3 |

**P1 紧急 (1 周内)**: #1 + #2 + #3 + #4 (3-4 项共 5-8d)
**P2 重要 (2-3 周)**: #5-#14 (10 项共 4-6 周)
**P3 nice-to-have (1+ 月)**: #15-#20 (6 项共 3-5 周)

---

## 8. spen 视角结论

**项目状态**: 高度工程化, 4 层架构纯度 + 18 守门员 + 2019 tests + 0 analyzer error 表现优异, **R95 → R101 → R105 持续提升, R101+ 出现 14 项 backlog + daily_tracking 新模块未审计**。

**核心优势**:
- 拆分成熟度行业领先 (notification_service 629 → 469, home_page 731 → 138+590, setup_page 517 → 25+480, scale_translations_l10n 785 → 24+760)
- 守门员 18 脚本覆盖架构/法律/隐私/i18n/资源/UT 时间 race/PUA/16KB page size
- 集成测试 6 user journey + ProviderScope override 真实 in-memory DB
- TDD 续命 (R56c 系列 41 sub-service unit) + 220+ lock-in test
- 隐私边界严 (vent 数据 0 进任何 analysis/notification/care)

**核心劣势**:
- R105 14 项 N1-N18 backlog 仍未动 (P1 静默丢数据 / 守门员 FAIL / 死代码 / DRY / i18n)
- R101+ 新增 daily_tracking 7 widget 各 10-12KB 跨 widget 重复
- 13 个 god class 候选 (R95 拆剩 5 + R101+ 新增 8)
- CI workflow / Codecov 缺实际接入
- test/helpers/test_helpers.dart 缺统一 fixture

**一句话总结**: 架构和工程实践已达 9.0-9.5 优秀水平, 但 R101+ 新功能 (medication 重构 / mood 详情 + 趋势 / daily-tracking) 引入一批新 god widget + DRY 退化 + 死代码, R105 14 项 backlog 未清, 当前实际表现 9.0, **需 R106 集中清 R105 backlog + R101+ 新增审计**。

---

**报告时间**: 2026-08-10 | **审计员**: Mavis (spen 视角) | **参考**: R95 / R101 / R105 spen 报告
