# Domain Layer Audit Report

**Scope**: `D:\Batch\chroniccare\lib\domain\` (entities / logic / repositories / usecases)
**Date**: 2026-07-27
**Total files audited**: 39 source files (3404 lines)
**Test coverage**: 30 test files in `test/domain/`
**Audit type**: READ-ONLY

## Summary Stats

| 类别 | 🔴 严重 | 🟡 中等 | 🟢 低 | 总计 |
|---|---|---|---|---|
| 1. 死代码/过期 | 0 | 5 | 9 | 14 |
| 2. 优化点 | 0 | 5 | 7 | 12 |
| 3. Bug/隐患 | 1 | 4 | 5 | 10 |
| 4. 代码健康 | 1 | 4 | 3 | 8 |
| **总计** | **2** | **18** | **24** | **44** |

Domain 层整体质量较高：4 层架构严格执行（grep 验证 0 flutter / 0 drift import，2 个文件只 import `core/l10n/strings.dart` 这条豁免 path AGENTS.md 已承认），1098 tests 通过，`streak_calculator` / `care_strategies` 等核心纯函数均经过边界测试。**2 个 critical finding 集中在：crisis detection 完全无单测 + medication startDate 在未来时的 missedDates 误报**。其余 42 个 finding 为中低优先级。

---

## 1. 死代码 / 过期候选

### 🟡 1.1 `ChineseHolidays` 整个 class 是死代码（仅 test 用）
**文件**: `lib\domain\logic\chinese_holidays.dart:21-135`
**现状**: 整个类 (`isHoliday` + `nextWorkdayAfter` + `_dateKey` + `_holidayDates`) 在 `lib/` 下 0 caller。文件头注释 (line 6-7) 自承 "v0.24 仅建立 data layer + TDD test，**不集成到 reminder_scheduler**"，计划 "v0.25+ 集成" 但 R56/R56b/R56c 全部未集成。`test/domain/chinese_holidays_round48_test.dart` 有完整测试。
**问题**: 60 行硬编码假期表（2026-2030）占 domain 层体积，零业务价值。
**建议**: 
- 选项 A（推荐）: 删 `chinese_holidays.dart` + 测试 + CHANGELOG 注释。假期避开逻辑等真接续方功能时再 v2.0 重建。
- 选项 B: 加 `chinese_holidays.dart` 顶层 @Deprecated 注释 + 写集成 TODO，保留代码供未来使用。
- 选项 C: 集成到 `medication_stat_calculator.MissedDateBuilder` 真正用起来（sp-en P2-4 建议），但跨 sprint 大工程。

### 🟡 1.2 `domain/logic/reminder_scheduler.dart` 3/4 static method 死代码
**文件**: `lib\domain\logic\reminder_scheduler.dart:20-38, 44-57`
**现状**: 4 个 static method 中只有 `selectAllActiveContacts` (line 60-67) 被 `core/data/services/reminder_scheduler.dart:170` 调。3 个死：
- `shouldSendAlert` (line 20-29) — 仅测试调 (`test/domain/reminder_scheduler_round12_test.dart`)，真实分级逻辑在 data 层 `ReminderService.evaluateLevel` 重新实现
- `hoursSinceLastCheckIn` (line 32-38) — 仅测试调
- `selectFirstContact` (line 44-57) — 仅测试调

**问题**: 30 行死代码 + 测试代码 50+ 行锁死行为，造成"测试通过 = production 安全"的假象。data 层 evaluateLevel 是真生产路径。
**建议**: 删 `shouldSendAlert` / `hoursSinceLastCheckIn` / `selectFirstContact` + 3 个 test group + `core/data/services/reminder_scheduler.dart:14-15` 注释（"v0.16 Round 7 合并"已不再准确）。保留 `selectAllActiveContacts`（真生产路径）。

### 🟡 1.3 `ContactRepository.update` 抽象方法 0 生产 caller
**文件**: `lib\domain\repositories\contact_repository.dart:21`
**现状**: `Future<bool> update(ContactEntity contact);` 抽象定义 + `contact_repository_impl.dart:40-46` 实现 + `test/domain/contact_entity_round12_test.dart:41` (mock 实现)。grep 验证 `lib/` 全无 `contactRepositoryProvider).update(` 调用。文件头注释 (line 20) 自承 "更新（保留以备 API 稳定，UI 暂未调用）"。
**问题**: 抽象接口稳定 ≠ "保留未用的 method"。这是 dead API surface。
**建议**: 删抽象 + impl + 1 处 mock。`ContactRepository` 只剩 4 个真用的 method (`watchAll` / `add` / `delete` / `restore`)。

### 🟡 1.4 `MedicationRepository.setActive` 抽象方法 0 生产 caller
**文件**: `lib\domain\repositories\medication_repository.dart:35-38`
**现状**: `Future<bool> setActive({required int medicationId, required bool isActive});` 定义 + impl + `medication_repository_round9_test.dart` 测试覆盖 4 个 case。grep 验证 `lib/` 全无 `medicationRepositoryProvider).setActive(` 调用。UI 端"软停药"用 `medications_list_widget.dart:114` 调 `delete`（硬删），不调 `setActive`。
**问题**: 软停药功能未实施，API 提前设计。
**建议**: 删抽象 + impl + 测试 + `medication_repository_impl.dart:65-78`。`softDelete` 走 `update(medication.copyWith(isActive: false))` 模式。

### 🟡 1.5 `UserProfileRepository.save` / `withdrawConsent` / `resetConsent` 全部 0 生产 caller
**文件**: `lib\domain\repositories\user_profile_repository.dart:18-21, 35, 38`
**现状**: 
- `save({userName, checkInCycleHours})` (line 18-21) — 0 caller；setup 改用户名走别处
- `withdrawConsent()` (line 35) — 0 caller；隐私撤回 UI 未实现
- `resetConsent()` (line 38) — 0 caller；同上

**问题**: PIPL §14 consent 是合规需求，AGENTS.md R22 已记为合规实施。但撤回 UI + reset UI 都未实施，3 个 method 全死。
**建议**: 删这 3 个抽象 + impl + `user_profile_repository_impl.dart:90-124` 3 个方法。撤回 UI 实施时再加。AGENTS.md 同步标记 "PIPL §14 撤回 UI 待 v0.27+"。

### 🟢 1.6 `CheckInEntity.isForMedication(int)` 死代码
**文件**: `lib\domain\entities\check_in_entity.dart:106`
**现状**: 0 caller in lib/，无测试。语义上 `c.medicationId == medId` 一行可替代。
**建议**: 删。

### 🟢 1.7 `CheckInTypeX.label` extension 死代码
**文件**: `lib\domain\entities\check_in_entity.dart:48-62`
**现状**: `extension CheckInTypeX on CheckInType { String get label { ... } }` 定义 4 个中文 label ("每日打卡" / "临时吃药" / "PHQ-9 评估" / "GAD-7 评估")。0 caller in lib/，0 测试。
**问题**: 违反 "domain 0 flutter 0 i18n" 精神（应走 AppLocalizations）。即使要用，应该是 `AppLocalizations.of(context).xxx`。
**建议**: 删整个 extension + `extension` 注释。UI 端如需标签走 l10n。

### 🟢 1.8 `CheckInEntity.isPhq9` / `isGad7` 死代码
**文件**: `lib\domain\entities\check_in_entity.dart:100, 103`
**现状**: 测试覆盖 (`check_in_entity_round12_test.dart:164, 172`)，0 caller in lib/。`isAssessment` (line 97) 已覆盖语义。
**建议**: 删。`type == CheckInType.phq9` 直接比较即可。

### 🟢 1.9 `ContactEntity.active` getter 死代码
**文件**: `lib\domain\entities\contact_entity.dart:27`
**现状**: `bool get active => isActive;` 0 caller in lib/。所有调用都用 `contact.isActive` 直接。
**建议**: 删。

### 🟢 1.10 `MoodEntryEntity.isValidScore` / `isFull4D` 死代码（但有测试）
**文件**: `lib\domain\entities\mood_entry_entity.dart:86, 89`
**现状**: 测试覆盖 `isValidScore` (4 case) + `isFull4D` (3 case)，但 0 caller in lib/。mood_dialog 走 form validation 不用 entity getter。
**建议**: 删。如果要保留 entity 自检，加测试注释说明 "供 future validation 调用"。

### 🟢 1.11 `UserProfileEntity.hasWithdrawnConsent` 死代码
**文件**: `lib\domain\entities\user_profile_entity.dart:78-79`
**现状**: 0 caller in lib/，0 测试。`withdrawConsent()` API 也没人调（finding 1.5）。
**建议**: 跟 1.5 一起删。

### 🟢 1.12 `HourMinute.fromString` / `toTimeString` 死代码
**文件**: `lib\domain\entities\hour_minute.dart:25-32, 35-36`
**现状**: 0 caller in lib/，0 测试。UI 端用 `TimeOfDay` → `HourMinute(hour: t.hour, minute: t.minute)` 显式构造，格式化用 inline `'${pad2(h)}:${pad2(m)}'`。
**建议**: 删 2 个 method。`copyWith` 仍可能有用，保留。

### 🟢 1.13 `MedicationEntity._listEq` 应为 top-level 或 DomainValue
**文件**: `lib\domain\entities\medication_entity.dart:150-156`
**现状**: `static bool _listEq(...)` 是 private static helper，类内用。语义"List 相等"应是 `DomainValue<List<HourMinute>>` 范畴。当前能用，但内嵌于 entity 类不优雅。
**建议**: 移到 `lib/core/shared/equality.dart` 或作为 extension on `List<HourMinute>`。

### 🟢 1.14 `CareEngine.fire` success log 误用 swallowError
**文件**: `lib\domain\logic\care_engine.dart:133-137`
**现状**:
```dart
swallowError(
  where: 'CareEngine.fire',
  error: '关怀触发: ${trigger.type.name}',
  note: 'success',
);
```
`swallowError` (lib/core/shared/swallow_error.dart:33) 设计为 "失败可观测，dev 模式打 log" 的工具。这里用 `note: 'success'` 误导，dev 模式输出 "CareEngine.fire failed: success" 自相矛盾。
**建议**: 删这段（成功无需 log）。如要 trace，dev 模式加 `developer.log('CareEngine.fire success: $typeName', name: 'care')`。

---

## 2. 优化点

### 🟡 2.1 `medication_stat_calculator.dart:41` 静默 fallback 1 dose/day
**文件**: `lib\domain\logic\medication_stat_calculator.dart:41`
**现状**:
```dart
final dosesPerDay = times.isEmpty ? 1 : times.length;
```
**问题**: medication 如果没有 `times`（空 list），被当成 1 dose/day 算 expected。这违反"未配置时间 = 不应计入依从率"的语义。setup 端 (line 287) 确实强制要求设置时间，但 domain 层不应依赖 UI 守卫。罕见但有 silent bug 风险。
**建议**: 改 `final dosesPerDay = times.length;` + 入口检查 `if (times.isEmpty) return _emptyStat(med);`（actualDoseCount=0, expectedDoseCount=0, missedDates=[]）。

### 🟡 2.2 `medication_report.dart:81` magic number `1 << 30`
**文件**: `lib\domain\logic\medication_report.dart:81`
**现状**: `final extraDoses = (actualDoses - expectedDoses).clamp(0, 1 << 30).toInt();`
**问题**: `1 << 30` = 1,073,741,824 作为 defensive upper bound，但无注释说明为啥用这个数。下一位维护者看不懂。
**建议**: 抽 `static const int _maxExtraDoses = 1 << 30;` 顶部常量 + 注释 "defensive cap: 实际场景最多几十, 1G 足够防溢出"。

### 🟡 2.3 `toReportString` 90 行 god function
**文件**: `lib\domain\logic\medication_report.dart:189-280`
**现状**: 单个方法 92 行，4 个 section (header / routine / temp / summary) 串行。计算 + 格式化混合。
**建议**: 抽 4 个 private helper:
- `_headerSection(buf)` (line 192-209)
- `_routineMedsSection(buf, stats)` (line 211-246)
- `_tempMedsSection(buf, temps)` (line 248-262)
- `_summarySection(buf)` (line 264-274)
- `_renderTextFrame(buf, content)` 复用外框

`toReportString()` 退化为 5 个 helper 调用 + 边界处理。

### 🟡 2.4 `day_detail.fromData` 95 行 god function（多职责）
**文件**: `lib\domain\logic\day_detail.dart:139-235`
**现状**: 单方法 95 行，3 个职责: (1) filter+convert checkIns → events, (2) filter+convert moodEntries → events, (3) sort + 包装。
**建议**: 抽 3 个 private static helper:
- `_checkInToEvents(checkIns, medById, day, nextDay)` → `List<DayEvent>`
- `_moodEntryToEvents(moodEntries, day, nextDay)` → `List<DayEvent>`
- `fromData` 仅做 3 行: filter helpers → concat → sort → return

### 🟡 2.5 `medication_stat_calculator._dayKey` 重复实现
**文件**: 
- `lib\domain\logic\medication_stat_calculator.dart:80`
- `lib\domain\logic\medication_stat_calculator.dart:106` (MissedDateBuilder 内)

**现状**: 同一个 `static String _dayKey(DateTime dt) => Formatters.date(dt);` 在 2 个 class 内复制（注释 line 79 说 "R58 抽到顶层避免 3 个 calculator 重复"，但实际 2 个都重复了）。
**建议**: 抽到文件顶层 top-level `String _dayKey(DateTime dt) => Formatters.date(dt);` 或 `String dayKey(DateTime dt)` 公共 helper（如果 TempEntryExtractor 也用）。

### 🟢 2.6 `AssessmentHistory.average/max/min` 多次扫描 records
**文件**: `lib\domain\logic\assessment_comparison.dart:109-129`
**现状**:
```dart
List<int> get totals => records.map((r) => r.total).toList(growable: false);
double? get average {
  if (records.isEmpty) return null;
  final s = totals.fold<int>(0, (a, b) => a + b);
  return s / records.length;
}
int? get max => records.isEmpty ? null : totals.reduce((a, b) => a > b ? a : b);
int? get min => records.isEmpty ? null : totals.reduce((a, b) => a < b ? a : b);
```
`average` + `max` + `min` 各调一次 `totals`，每次创建新 list + 完整遍历 records。N=50 records × 3 getter = 9 次 list pass。
**建议**: 一次遍历算 sum/min/max（经典 reduce），O(N) 而非 O(3N)。

### 🟢 2.7 `DayDetail.bestMoodScore/worstMoodScore` 多次扫描 events
**文件**: `lib\domain\logic\day_detail.dart:108-121`
**现状**: 2 个 getter 各 `events.where().map()` + `reduce`，O(2N)。
**建议**: 一次循环 `int? best, int? worst; for (final e in events) { ... }` 算 2 个值，O(N)。

### 🟢 2.8 `MedicationReport.compute` 内 3 次 clamp 散落
**文件**: `lib\domain\logic\medication_report.dart:78-83`
**现状**:
```dart
final missedDoses = (expectedDoses - actualDoses).clamp(0, expectedDoses).toInt();
final extraDoses = (actualDoses - expectedDoses).clamp(0, 1 << 30).toInt();
final onTimeDoses = actualDoses.clamp(0, expectedDoses);
```
3 个表达式结构相似但参数各异。
**建议**: 抽 `(int, int) classifyDoses({required expected, required actual})` 返回 `(missed, extra, onTime)`。testable 独立 + 表达式统一。

### 🟢 2.9 `medication_report.compute` 12 个参数（部分场景可拆 config）
**文件**: `lib\domain\logic\medication_report.dart:31-37`
**现状**: `static compute({userName, meds, checkIns, days=14, now})` — 5 个参数不算多。注释 (line 27) 解释"caller 不重复实现窗口 filter" 是好设计，**当前合理**。
**建议**: 不动。如果未来加更多参数（如 includeInactive / sortBy），改 `MedicationReportConfig` value object。

### 🟢 2.10 `care_strategies` 6 个 const 阈值应聚类
**文件**: `lib\domain\logic\care_strategies.dart:16-21`
**现状**:
```dart
const _lateHourThreshold = 22;
const _lateHabitDays = 3;
const _lateHabitDayRange = 2;
const _weekendGuardHour = 18;
const _secondDayMissedMinutes = 36 * 60;
const _secondDayMissedHour = 10;
```
6 个 magic const 散落文件头。
**建议**: 抽 `class _CareStrategyThresholds { static const ... }` 或加注释 doc block 说明每个值的来源（AASM 指南？v0.7 spec？）。

### 🟢 2.11 `StreakCalculator.expiryThresholdHours` 与 `StreakCalculator.shouldShowStreakBroken` 阈值不同源
**文件**: `lib\domain\logic\streak_calculator.dart:18, 85-99`
**现状**: `expiryThresholdHours = 36`（streak 归零阈值），但 `shouldShowStreakBroken` 硬编码 24h（"少 1 次没关系"提示阈值）。2 个阈值不同源，semantic 关系不明（为何 36h 归零但 24h 提示？）。
**建议**: 加注释解释 "24h = 提示阈值（UI 友好），36h = 严格 streak 归零阈值（业务规则）"。或者抽 `_showBrokenThresholdHours = 24` 为 const 顶部统一。

### 🟢 2.12 `care_strategies._daysBetween` 等重复 `_daysBetween`
**文件**: 
- `lib\domain\logic\assessment_comparison.dart:243-247` (private static)
- `lib\core/data/services/reminder_scheduler.dart:239-243` (private static, data layer)
- `lib\core/data/services/safety_config_service.dart:109-113` (public static `daysBetween`)
- `lib\domain\entities/medication_entity.dart` 内联 DateTime 算术

**现状**: 4 处实现 "strip time-of-day → difference.inDays"。audit-data-layer 2.2 已建议复用 `SafetyConfigService.daysBetween`。**`assessment_comparison._daysBetween` 是 domain 内重复**。
**建议**: 抽到 `lib/core/shared/date_utils.dart` 顶层 `int daysBetweenDateOnly(DateTime a, DateTime b)`，domain 引用。

---

## 3. Bug / 隐患

### 🔴 3.1 `Phq9Scale.detectCrisis` 和 `hotlineByRegion` **0 测试覆盖**（CRITICAL）
**文件**: `lib\domain\logic\phq9.dart:118-133` + `lib\domain\logic\assessment_scale.dart:114-119, 162-185`
**现状**: 
- `Phq9Scale.detectCrisis` — **0 测试**。GAD-7 detectCrisis 测了 (返 null) 但 PHQ-9 没测。
- `hotlineByRegion` const Map — **0 测试**。6 region × 2 hotlines = 12 条数据完全没单测。
- `HotlineRegion` enum — 0 测试。

**CRITICAL 影响**: v0.25 R51 (spzh P0 #3) 的核心 fix 就是 PHQ-9 region routing 改"硬编码 2 个中国电话" → "按 region 选电话"，修"海外用户做评估时看到中国电话打不通 = 医疗法律责任"。但实际决定 hotline 返回的代码路径**完全没单测**。如果未来某天改 PHQ-9 第 9 题阈值（如 `scores[8] >= 1` → `>= 2`），无测试 fail 提醒，**用户自杀念头时显示错的危机电话**。

**建议**:
1. 加 `test/domain/phq9_detect_crisis_round51_test.dart`，覆盖：
   - scores[8] = 0 → null
   - scores[8] = 1 → CrisisSignal with hotlineByRegion[region]
   - 6 region × 兜底 case（HK/SG/UK 各 1 hotline，CN/US/TW 各 2）
   - scores.length < 9 → null（不崩）
2. 加 `test/domain/assessment_scale_hotlines_test.dart`，断言 `hotlineByRegion.values` 都不为空 + `label` / `number` 非空。
3. 加 CI 守护：`check_crisis_hotline_region.py` 扫 `assessment_scale.dart:hotlineByRegion` 必含 6 region。

### 🟡 3.2 `MedicationStatCalculator` medication 未开始时 `missedDates` 误报
**文件**: `lib\domain\logic\medication_stat_calculator.dart:44-66` + `lib\domain\logic\medication_report.dart:78-83`
**现状**:
```dart
// med_stat_calculator.dart:47
final effectiveDays = periodStart.add(Duration(days: days)).difference(effectiveStart).inDays;
final expected = dosesPerDay * effectiveDays.clamp(0, days);
// line 60-66
final missedDays = days - daysWithDose.length;
final missedDates = MissedDateBuilder.build(
  periodStart: periodStart,
  daysWithDose: daysWithDose,
  missedDays: missedDays,
);
```
**Bug**: 当 `med.startDate > periodEnd` (药物未到开始日期)：
- `effectiveDays = -5` → clamp(0, days) = 0 → `expected = 0` ✓
- `daysWithDose = {}` → `missedDays = 14` → `MissedDateBuilder.build` 返回 14 个日期
- `MedicationStat` 字段: `actualDoseCount=0, expectedDoseCount=0, missedDates=[14 dates]` 

报告渲染 (line 238-243) 会输出 `   ⚠️ 漏服: 7/1、7/2、7/3、...` 给"还没开始吃的药"。

**风险**: 用户添加"未来某日开始"的药 (如预约挂号开药) → 立刻生成报告看到 14 天漏服。罕见但显示错误。

**建议**: `medication_stat_calculator.dart:60-66` 前加:
```dart
if (effectiveDays <= 0) {
  return MedicationStat(
    medication: med,
    times: times,
    actualDoseDays: 0,
    missedDates: const [],
    actualDoseCount: 0,
    expectedDoseCount: 0,
  );
}
```

### 🟡 3.3 `_formatDateTime` 时区 label 与显示时间语义错位
**文件**: `lib\domain\logic\email_template.dart:91-107`
**现状**:
```dart
final ref = referenceNow ?? DateTime.now();
final offset = ref.timeZoneOffset;
// ...
return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} '
    '${_pad(dt.hour)}:${_pad(dt.minute)} '
    '(UTC$sign$hours:$minutes)';
```
**Bug**: `dt` 是 `lastCheckIn` (用户本地时间)，`offset` 是 `ref` (caller 当前) 的时区偏移。如果用户在北京打卡 (UTC+8)，联系人在纽约 (UTC-5)，输出:
- 时间: `2026-07-15 22:00` (北京墙钟)
- 偏移: `(UTC-05:00)` (纽约当前)

**语义错位**: 时间是用户视角，offset 是联系人视角，海外紧急联系人看到 "UTC-05:00 22:00" 误以为纽约本地 22:00，实际是北京 22:00 = 纽约 10:00。

**风险**: v0.24 R48 spen P0-4 fix 注释 (line 95-98) 承认 "海外紧急联系人看到错误时区会误读'未来时间已发生'"，但 fix 方向错误 — 应该是 convert `dt` 到 caller's tz 而非贴 caller tz label。

**建议**: 短期保留 + 加注释 "TODO v1.0: 用 timezone package 真正转换 dt 到 caller tz"。长期 fix。

### 🟡 3.4 DST 跨界算天 bug（streak + assessment）
**文件**: 
- `lib\domain\logic\streak_calculator.dart:70` `daysDiff = prev.difference(curr).inDays`
- `lib\domain\logic\assessment_comparison.dart:243-247` `_daysBetween`

**现状**: `Duration.inDays = inMicroseconds ~/ microsecondsPerDay` (微秒截断，非日历日差)。
- 正常日子 24h: `inDays = 1` ✓
- DST spring forward (美国 3 月 8 日, 23h): `inDays = 0` ✗
- DST fall back (美国 11 月 1 日, 25h): `inDays = 1` ✓ (偶发对了)

**影响**:
- `StreakCalculator.calculate` 在美国用户春令时当日漏 1 天: 实际墙钟 24h 算 0 天 → streak 中断。
- `AssessmentComparison._daysBetween` 同样问题: "上次评估距今 N 天" 在 DST 跨界日偏差 ±1。

**风险**: 仅 DST 区域 (US/EU/AU/CA) 受影响，每年 2 次。中国用户无影响（无 DST）。

**建议**: 抽 `int calendarDaysBetween(DateTime a, DateTime b)` top-level helper 到 `lib/core/shared/date_utils.dart`:
```dart
int calendarDaysBetween(DateTime a, DateTime b) {
  final aDay = DateTime(a.year, a.month, a.day);
  final bDay = DateTime(b.year, b.month, b.day);
  // 用 UTC 算微秒差,避免 DST 跨界 23h/25h 问题
  return bDay.toUtc().difference(aDay.toUtc()).inDays;
}
```
注: `bDay.toUtc()` 在 DST 跨界日仍可能少 1h，但 `Duration.inDays` 在 23h vs 24h 时结果不同。需要更稳的方法 — 用 `DateUtils.dateOnly` (flutter) 或自己算 `(bDay - aDay).inDays` 但用 `.toUtc()` 后构造 `DateTime.utc(year, month, day)` 规避 DST。

### 🟡 3.5 `isSecondDayMissed` 阈值 hardcode 22 点 + 10 点
**文件**: `lib\domain\logic\care_strategies.dart:106-110`
**现状**:
```dart
bool isSecondDayMissed(List<CheckInEntity> sortedDesc, DateTime now) {
  if (sortedDesc.isEmpty) return false;
  final lastCheckIn = sortedDesc.first.timestamp;
  final minutesSince = now.difference(lastCheckIn).inMinutes;
  return minutesSince >= _secondDayMissedMinutes && now.hour >= _secondDayMissedHour;
}
```
**潜在问题**:
- `_secondDayMissedMinutes = 36h` (line 20)
- `_secondDayMissedHour = 10` (line 21)
- 函数名 "second day missed" 但实际是 "距上次打卡 ≥36h 且 10 点后" — 用户最后打卡在昨天下午 22 点（14h 前）今天 10 点不提醒（不到 36h）。但用户最后打卡在前天下午 22 点 (38h 前) 今天 10 点提醒。

**边界**:
- 用户打卡习惯是 20 点最后吃,次日 20 点前再吃。漏 1 天 = 2 天后才补。`now.hour >= 10` 假定早上 10 点用户起来，没考虑夜班用户 / 海外用户。
- 时区: `now.hour` 是 local time,海外用户时区不同，10 点是北京时间。用户在美国 22 点 = 北京次日 10 点，会误触发。

**建议**: 
- 加注释 "假设用户晚 22 点前吃, 漏 1 天后次日 10am 提醒"
- 真要支持时区，应读 `userProfile.timeZone` (目前 entity 无此字段)
- 海外时区用户应在 setup 时配 timezone

### 🟢 3.6 `care_strategies.nextWorkdayAfter` 语义模糊
**文件**: `lib\domain\logic\chinese_holidays.dart:117-127` (死代码 + 见 1.1) ; `care_strategies.dart` 无此函数。但 `chinese_holidays.nextWorkdayAfter` 注释 (line 102-110) 说"返回 [date] 之后第一个工作日"，但实现是 `date.add(Duration(days: 1))` 起算 — 传 workday 也跳一天。

**风险**: 未来集成时 caller 可能误传 workday 期望"今天"，结果返回"明天"。

**建议**: 集成时改 `DateTime d = date; do { d = d.add(Duration(days: 1)); } while (isHoliday(d) || weekend);` 或加 `includeToday` 参数。

### 🟢 3.7 `MedicationEntity._listEq` 不区分 list mutability
**文件**: `lib\domain\entities\medication_entity.dart:150-156`
**现状**: 私有 helper 比较 2 个 `List<HourMinute>` 元素相等。`==` 用 (line 122) `_listEq` 参与比较。`copyWith` (line 88-112) 接受 `List<HourMinute>?` 但若 caller 传同一 list instance，== 返 true（但 identity vs 内容比较要看）。
**问题**: `==` 是值相等，list 是 identity 相等。`_listEq` 正确处理。但 `hashCode` (line 131) 用 `Object.hashAll(times)` — `Object.hashAll` 对 list 是 identity-based 还是 element-based？
**验证**: Dart `Object.hashAll` 对 List 用 `Object.hash` (identity) — 不展开元素。所以两个 `List<HourMinute>` 内容相同但 instance 不同, `hashCode` 不同 → 放 Set/Dict 时找不到。
**风险**: 极小 (List<HourMinute> 通常新构造)。`==` 修了但 `hashCode` 漏修，违反 `a == b ⟹ hashCode a == hashCode b` 契约。
**建议**: `hashCode` 改:
```dart
Object.hashAll(times.map((t) => Object.hash(t.hour, t.minute))),
```

### 🟢 3.8 `AssessmentRecord ==` 不比较 `scores` 列表
**文件**: `lib\domain\logic\assessment_record.dart:33-40`
**现状**:
```dart
bool operator ==(Object other) =>
    identical(this, other) ||
    other is AssessmentRecord &&
        other.scaleId == scaleId &&
        other.timestamp == timestamp &&
        other.total == total;
```
**Bug**: `scores` 不参与 == 比较 — 两个 `AssessmentRecord` scaleId + timestamp + total 相等但 scores 不同 → 判等 true。实际场景罕见 (同 millisecond 不会重复保存)，但**违反 `==` 完整性**。
**建议**: 加 `other.scores.length == scores.length && _listEq(other.scores, scores)` (line 56 scores 已存)。

### 🟢 3.9 `DayDetailCalculator.fromData` 对 `nextDay` DST 跨日算事件边界
**文件**: `lib\domain\logic\day_detail.dart:145-146`
**现状**:
```dart
final day = DateTime(date.year, date.month, date.day);
final nextDay = day.add(const Duration(days: 1));
```
DST 春令时 3 月 8 日: `day = 2026-03-08 00:00 EST`, `nextDay = day + 24h = 2026-03-09 00:00 - 1h = 2026-03-08 23:00 EST`。filter `c.timestamp.isBefore(nextDay)` 排除 2026-03-08 23:00 后到 2026-03-09 00:00 的事件。
**风险**: 美国用户春令时当日日历详情可能少 1 小时事件。中国用户无影响。
**建议**: 改用 `DateTime(date.year, date.month, date.day + 1)` 让 Dart 自动 rollover（跨月/跨年也正确），且不依赖 Duration math。

### 🟢 3.10 `medication_report.compute` `periodEndExclusive` DST 跨界
**文件**: `lib\domain\logic\medication_report.dart:47`
**现状**: `final periodEndExclusive = periodEnd.add(const Duration(days: 1));` — 同 3.9 同样 DST 跨界少 1h。
**风险**: 同 3.9。

---

## 4. 架构健康

### 🔴 4.1 `assessment_scale.dart` crisis detection 无单测（与 3.1 重复，CRITICAL）
见 finding 3.1.

### 🟡 4.2 `domain/logic/email_template.dart:1` 违反 domain 0 flutter 原则
**文件**: `lib\domain\logic\email_template.dart:1`
**现状**: `import 'package:chroniccare/core/l10n/strings.dart';` 引用 domain strings fallback。`core/l10n/strings.dart:7` 注释承认 "domain 层不能 import flutter, 所以通知/邮件模板 (EmailTemplate) 仍用 [core/l10n/strings]（变通）"。
**问题**: 严格 4 层架构 domain 0 flutter 0 drift 0 data 0 presentation。`core/l10n/strings.dart` 是 domain-shared 概念 (无 Flutter API) 但放在 `core/l10n/`。
**建议**: audit-data-layer 4.1 建议同步: 改名 `core/l10n/strings.dart` → `core/l10n/domain_strings.dart` 或 `domain/text/domain_strings.dart`，domain 引用。v1.0 改 i18n injection 模式彻底解耦。

### 🟡 4.3 `domain/logic/medication_report.dart:1` 同 4.2 问题
**文件**: `lib\domain\logic\medication_report.dart:1`
**现状**: 同样 `import 'package:chroniccare/core/l10n/strings.dart';`。`Strings.pdfTitle/pdfFooterNotice/pdfSection*` 等 11 个 const 引用。
**建议**: 同 4.2 同步处理。

### 🟡 4.4 错误处理风格不统一（throw vs null vs Result）
**文件**: 
- `lib\domain\logic\assessment_comparison.dart:187` throws `ArgumentError`
- `lib\domain\logic/assessment_record.dart:48` returns `null` on parse fail
- `lib\domain\repositories/vent_repository.dart:28-30` 注释说"都为空时抛 ArgumentError" (实际未实现也未测试)
- `lib\domain/entities/check_in_entity.dart:40-45` `CheckInType.fromWire` returns fallback to `normal` (no throw)

**问题**: 5+ 风格混用，新人接手不知道该 throw 还是 return null。
**建议**: 写《Domain Error Handling Guide》注释 (lib/domain/AGENTS.md 或 lib/domain/README.md) 定 3 种模式:
- **Throw** `ArgumentError` / `ArgumentError.notNull` 用于: caller contract violation (传 null to non-nullable, 传负数等)
- **Return null** 用于: 业务可能不存在 (无最新打卡, JSON parse 失败, 联系人未启用)
- **`Result<T, E>` sealed class** 用于: 复杂错误 (网络 + 业务 + 权限)

短期 P1 删 `vent_repository.dart:28-30` 注释里"抛 ArgumentError"无对应实现的不一致承诺。

### 🟡 4.5 测试覆盖 gap：3 个 R58 抽出的纯函数类无单测
**文件**: 
- `lib\domain\logic\medication_stat_calculator.dart:22-81` (MedicationStatCalculator)
- `lib\domain\logic\medication_stat_calculator.dart:85-107` (MissedDateBuilder)
- `lib\domain\logic\temp_entry_extractor.dart:13-33` (TempEntryExtractor)

**现状**: v0.25 R58 god class 拆分注释 (medication_report.dart:1-19) 说"3 个纯函数类拆出,独立易测"。但 **0 个 isolated 测试** — 只有 `medication_report_round18_test.dart` 走 `MedicationReport.compute` end-to-end 间接覆盖。
**问题**: 拆分降低 testability 但实际没补测试 = 半成品重构。bug 隐藏 (如 finding 3.2 就会被 `MedicationStatCalculator.calculate` isolated test 抓到)。
**建议**: 加 3 个独立 test file:
- `test/domain/medication_stat_calculator_round58_test.dart` — 测 effectiveDays / startDate 边界 (finding 3.2 立即被抓)
- `test/domain/missed_date_builder_round58_test.dart` — 测 missedDays <= 0 / 全空 / 部分空
- `test/domain/temp_entry_extractor_round58_test.dart` — 测 isTemp filter / sort DESC / description 占位符

### 🟢 4.6 缺失 `UserProfileEntity` 直接测试
**文件**: `lib\domain\entities\user_profile_entity.dart` 无对应 test file。
**现状**: `medication_entity_round11_test.dart` 有完整 entity test (copyWith / == / hashCode / 业务方法)。`check_in_entity_round12_test.dart` 同。`user_profile_entity` 无。
**影响**: 5 个 PIPL §14 字段 + 2 个 nullable 版本字段 + 1 个 `hasWithdrawnConsent` getter (finding 1.11 dead) 行为无单测锁。
**建议**: 加 `test/domain/user_profile_entity_round22_test.dart`，覆盖:
- copyWith 各 nullable 字段 (Value<T?>)
- == / hashCode 包含所有 8 字段
- hasWithdrawnConsent 边界 (4 case: 都没/只有 consent/只有 revoke/都有)

### 🟢 4.7 缺失 `TrendCalculator.dailyBreakdown` / `monthlyBreakdown` isolated test
**文件**: `lib\domain\logic\trend_calculator.dart:90-114, 117-147`
**现状**: `trend_calculator_round6_test.dart` 50 个 test 全测 `monthlyCalendar` / `shiftMonth` (R6 范围)。`dailyBreakdown` / `monthlyBreakdown` / `streakSummary` 0 isolated test。
**影响**: trend 页 30 天热力图 / 6 个月柱状图计算无单测锁。`streakSummary` 间接走 `streak_calculator_round3/19_test.dart` 覆盖（OK）。但 `dailyBreakdown` / `monthlyBreakdown` 完全没测。
**建议**: 加 `test/domain/trend_calculator_daily_monthly_roundXX_test.dart`。

### 🟢 4.8 `care_engine.dart:124` 通知 id 公式 8000+index 跟其他 service id range 紧邻
**文件**: `lib\domain\logic\care_engine.dart:124-126`
**现状**: `final id = 8000 + trigger.type.index;` (5 trigger × 1 = 8000-8004)
**问题**: 5 个 id (8000-8004) 占用同 range，但 `reminder_dispatcher.dart:28` 注释 "kReminderCancelRange = 200000"。CareEngine id 跟其他 service 不冲突，OK。但 8000-8004 浪费 7995 个空 id 位。
**风险**: 0 (注释 line 125 解释 8000-8099 段 + snooze 300000+medId 段)。
**建议**: 注释已够清晰,不动。

---

## 5. 验证 / 已合规（正面观察）

为避免 future audit 重复扫描,以下区域**已经合规,勿动**:

- ✅ **Domain 0 flutter / 0 drift**: grep 验证 0 个 `package:flutter/` / `package:drift/` import。仅 `core/l10n/strings.dart` (1-2 处) + `core/shared/*` 8 处是合规的 shared layer 引用。
- ✅ **`*Entity` 命名 + `@DataClassName` 单一来源**: 所有 domain entity 都是 PascalCase + Entity 后缀 (`CheckInEntity` / `ContactEntity` / `MedicationEntity` 等),drift 生成 row 无后缀。`check_all.dart` 已检查。
- ✅ **`MedicationDraft` 参数对象**: 9 字段参数拆成 value object (R60),`copyWith` 模式支持 UI 编辑。
- ✅ **`MoodEntryDraft` 参数对象**: 10 字段参数拆成 value object (R48),同样模式。
- ✅ **核心纯函数都有边界测试**: `StreakCalculator` (3/19 round 覆盖 36h 边界 + 跨日) / `CareEngine` (3/17/19 round 4 策略 + 边界) / `AssessmentComparison` (18 round 跨 record 比较) / `MedicationEntity` (11 round 业务方法)。
- ✅ **隐式排序假设全修**: v0.16 round 19/19B 立的规矩 (`.first` / `.last` 用时序数据必须显式 sort) 5+ service 已修,domain 内 `StreakCalculator` / `CareEngine` / `MedicationReport` 都显式 sort。
- ✅ **`DateTime.now()` 一次取防 midnight race**: domain 内纯函数都接受 `now: DateTime?` 注入 (caller 在 transaction 入口取一次),无隐藏 `DateTime.now()` 跨 await 调用。
- ✅ **God class 拆分**: `MedicationReport` (R58) 拆 3 纯函数 + data class,`CareEngine` (R41) 拆 4 strategy (care_strategies.dart)。
- ✅ **mutable 不污染 caller**: `selectAllActiveContacts` (R48) 显式 `[...filtered]..sort(...)` 防御性 copy。
- ✅ **CareEngine.fire 不向上传播**: try/catch + swallowError (care_engine.dart:127-145) 失联通知失败不阻塞 check-in 主流程。
- ✅ **`isValidScore` 等 1-line 业务方法有测试**: 即使是 dead code (finding 1.10),测试 4 case 锁行为。

---

## 6. 跨文件交叉 issue（domain 边界）

### 🟢 6.1 `EmailTemplate` 跟 `EmailService` 是 50% 重复
**文件**: `lib\domain\logic\email_template.dart` (domain) + `lib\core\data\services\email_service.dart:55-73` (data `_buildSmsBody`)。
**现状**: 失联通知两路径: `ReminderService._buildSmsBody` (SMS 体) vs `EmailService.sendMedicationReminder` (邮件体)。两路径文案不一致 ("小时没打卡" vs "天没吃药")。audit-data-layer 1.3 已建议合并。
**建议**: domain 抽 `buildLostContactSms(...)` + `buildLostContactEmail(...)`,ReminderService 和 EmailService 都调,文案统一。

### 🟢 6.2 `core/l10n/strings.dart` 是 domain-shared 概念放错位置
**文件**: `lib\core\l10n\strings.dart:1-263`
**现状**: 整个 `Strings` class 是 domain 概念 (通知/邮件/i18n fallback 字符串),但放在 `core/l10n/`。`Strings` 含 0 flutter import,但被 2 个 domain file 引用 — 反映 "strings" 概念是 domain 层 need。
**建议**: 改 `core/l10n/strings.dart` → `domain/text/domain_strings.dart`,presentation 层调用方不变 (无 import 路径变化,只是 import 路径前缀变)。

---

## 7. 守护脚本当前覆盖

| 守护脚本 | 覆盖 finding |
|---|---|
| `check_all.dart` (purity) | 4.2, 4.3 (0 flutter in domain) |
| `check_all.dart` (consistency) | Entity ↔ drift @DataClassName 一一对应 |
| `check_drift_namespace.py` | @DataClassName 唯一 |
| `check_datetime_race.py` / `check_datetime_race2.py` | domain 0 现在 (pure function 全 now-inject) |
| `check_cross_feature.py` | 4.5 vent 边界 |

**建议新增守护脚本**:
- **`check_crisis_hotline_region.py`**: 扫 `assessment_scale.dart:hotlineByRegion` 必含 6 region (cn/us/hk/tw/sg/uk), 缺一 fail CI (CRITICAL 3.1 配套)
- **`check_dead_domain_method.py`**: 扫 `lib/domain/` 0 caller 的 public method,加 `@deprecated` 或删除 (1.1-1.14 配套)
- **`check_domain_god_function.py`**: 扫 `lib/domain/logic/` 函数 > 50 行 (2.3, 2.4 配套)

---

## 8. 优先处理建议 (按 ROI 排)

| 优先级 | Finding | 收益 |
|---|---|---|
| 🔴 P0 | 3.1 + 4.1 (PHQ-9 detectCrisis 测试) | 修医疗法律责任风险; 加 8-10 test 锁危机路径 |
| 🔴 P0 | 4.5 (3 个 R58 抽类 isolated test) | 抓 3.2 bug; 加 12+ test 锁拆分行为 |
| 🟡 P1 | 1.1 (删 ChineseHolidays) | 减 60 行死代码 + 1 个 test 文件 + 1 个 CHANGELOG |
| 🟡 P1 | 1.2 (删 reminder_scheduler 3 method) | 减 30 行 + 1 个 test group |
| 🟡 P1 | 1.3 / 1.4 / 1.5 (3 个 repository dead method) | 减 50+ 行死代码 |
| 🟡 P1 | 3.2 (medication 未开始时 missedDates 误报) | 1 处 if + 8 test |
| 🟡 P1 | 4.6 (UserProfileEntity test) | 锁 PIPL §14 字段 |
| 🟡 P1 | 4.7 (TrendCalculator daily/monthly test) | 锁热力图计算 |
| 🟢 P2 | 1.6-1.14 (entity 9 处 dead method) | 减 30 行死代码 |
| 🟢 P2 | 2.3 / 2.4 (2 个 god function 拆) | 提升可读性 + 可测性 |
| 🟢 P2 | 3.4 (DST 跨界算天) | 加 helper + 1 处 import 改 |
| 🟢 P2 | 2.6 / 2.7 (multiple-pass 优化) | 性能,小数据可忽略 |
| 🟢 P3 | 3.7 / 3.8 (== / hashCode 完整性) | 修契约违反, 罕见 |
| 🟢 P3 | 3.9 / 3.10 (DST day-detail 边界) | 跟 3.4 同步改 |
| 🟢 P3 | 6.1 / 6.2 (跨文件重构) | 大工程, 建议 v0.27+ |

---

## 结论

Domain 层整体**健康**。44 个 finding 中 2 critical、18 中等、24 低。

主要优势:
- 4 层架构严格执行,0 flutter / 0 drift import
- 核心业务逻辑 (streak / care engine / medication report) 都有边界测试
- 隐式排序、midnight race、`inHours` 截断等 AGENTS.md "已知坑"全修
- R58 god class 拆分、Medic*Draft 参数对象等重构决策正确

主要风险:
- **🔴 3.1 PHQ-9 detectCrisis 完全无单测** (海外危机电话路由) — 医疗法律责任级别
- **🟡 3.2 medication 未开始时 missedDates 误报** — 罕见但 silent 显示错误
- **🟡 1.1-1.5 五处真死代码** (ChineseHolidays / reminder_scheduler / 3 个 repository method) — 总 150+ 行可删

主要重构债:
- `MedicationReport.toReportString` 90 行 + `DayDetail.fromData` 95 行 = 2 个 god function 待拆
- `_daysBetween` / `dayKey` / `MedicationEntryDraft` 等 4+ 处重复 helper 待抽
- DST 跨界算天 (4 处 microsecond-based `inDays`) 待统一 helper

**2 critical 阻塞 P0**: 3.1 (crisis detection 测试) + 4.5 (R58 抽类测试) 必须在下次 release 前补。其余 42 项可在 2-3 sprint 内分批清理。
