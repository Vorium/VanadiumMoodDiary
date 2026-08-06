# 日常追踪模块 (Daily Tracking) Implementation Plan

> v0.30 round 91 (sub-spec 7)
> 7 task sub-spec (R90 6 task 扩 1)
> Spec: docs/superpowers/specs/2026-08-05-daily-tracking-design.md (13715 bytes)

## Goal

7 子功能 (情绪日记合并 + 焦虑急躁 + 睡眠 + 社会节律 + 应激源 + 治疗 + 体重) + 整合入口页 + 治疗联动 medication + mood_entries 加 period 列 (schemaVersion 17 → 18)

## Architecture

**复用 R90 量表中心经验**:
- 多线趋势图 12 色 + 3 线型 (`assessment_multi_line_chart.dart`)
- color palette 12 色 (R90)
- 4-layer 架构 (domain 0 flutter 0 drift, data drift OK)

**新增 6 张新表** (drift):
- `sleep_entries` / `social_rhythm_entries` / `stress_events` / `treatment_entries` / `weight_entries` / `anxiety_agitation_entries`

**修改 1 张表** (drift migration):
- `mood_entries` 加 `period` 列 (TextColumn, nullable, enum morning/noon/evening/night/unspecified)

**schemaVersion 17 → 18** (1 migration, 6 new tables + 1 new column, 老用户 0 数据迁移)

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture (domain 0 flutter 0 drift)
- 守门员: 16+ 全绿
- TDD: red → green → commit
- baseline 1556 pass / 0 fail (R90 后)
- master commit 349c4f0
- **不重写 R84-R90 现有代码** — 改造而非重写 (mood_dialog 加 period, mood_list 加 filter, home_fab 改 1 行)

## File Structure

### 新增 (Task 1 data 层)
- `lib/core/data/database/tables/daily_tracking/sleep_entries.dart`
- `lib/core/data/database/tables/daily_tracking/social_rhythm_entries.dart`
- `lib/core/data/database/tables/daily_tracking/stress_events.dart`
- `lib/core/data/database/tables/daily_tracking/treatment_entries.dart`
- `lib/core/data/database/tables/daily_tracking/weight_entries.dart`
- `lib/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart`
- `lib/domain/entities/sleep_entry.dart` / 5 other
- `lib/domain/logic/sleep_calculator.dart` (bedtime + wakeTime → durationMin + regularityScore)
- `lib/domain/logic/bmi_calculator.dart` (weight + height → bmi)
- `lib/core/data/database/daos/sleep_dao.dart` / 5 other
- `lib/core/data/repositories/daily_tracking/sleep_repository_impl.dart` / 5 other

### 新增 (Task 2-6 presentation)
- `lib/presentation/providers/daily_tracking_providers.dart`
- `lib/presentation/pages/daily_tracking/daily_tracking_page.dart`
- `lib/presentation/pages/daily_tracking/widgets/daily_tracking_card.dart`
- `lib/presentation/pages/daily_tracking/widgets/sleep_widgets.dart` (含 entry dialog)
- `lib/presentation/pages/daily_tracking/widgets/social_rhythm_widgets.dart`
- `lib/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart`
- `lib/presentation/pages/daily_tracking/widgets/treatment_widgets.dart`
- `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart`
- `lib/presentation/pages/daily_tracking/widgets/anxiety_agitation_widgets.dart`
- `lib/presentation/pages/daily_tracking/widgets/mood_period_aggregator_chart.dart`
- `lib/presentation/widgets/charts/daily_tracking_multi_chart.dart` (复用 R90 chart 模式)

### 修改
- `lib/core/data/database/app_database.dart` (schemaVersion 18 + 6 DAO getter + migration)
- `lib/core/data/database/tables/mood/mood_entries.dart` (加 period 列)
- `lib/presentation/pages/mood/mood_dialog.dart` (加 period UI)
- `lib/presentation/pages/mood_list/mood_list_page.dart` (加 period filter)
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` (改 FAB 跳 daily-tracking)
- `lib/core/routing/app_router.dart` (加 /daily-tracking 路由)
- `lib/core/theme/app_tokens.dart` (4 指标色 + 4 线型常量)
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` (~80 keys)

### Tests
- `test/domain/logic/sleep_calculator_round91_test.dart`
- `test/domain/logic/bmi_calculator_round91_test.dart`
- `test/domain/logic/mood_period_aggregator_round91_test.dart`
- `test/core/data/database/daos/sleep_dao_round91_test.dart` / 5 other (6 测试)
- `test/core/data/repositories/daily_tracking/*_repository_round91_test.dart` (6 测试)
- `test/presentation/pages/daily_tracking/daily_tracking_page_round91_test.dart`
- `test/presentation/pages/daily_tracking/daily_tracking_multi_chart_round91_test.dart`
- `test/presentation/pages/mood/mood_dialog_period_round91_test.dart` (mood 加 period)
- `test/presentation/pages/mood_list/mood_list_period_filter_round91_test.dart`

---

### Task 1: schema 升级 + 6 新表 + mood_entries 加 period + 6 DAO + 6 entity + 6 repo

**Files:**
- Create: 6 个新表 (drift)
- Modify: `lib/core/data/database/tables/mood/mood_entries.dart` (加 period 列)
- Modify: `lib/core/data/database/app_database.dart` (schemaVersion 18 + migration + 6 DAO getter)
- Create: 6 个 domain entity
- Create: 2 个 domain logic (sleep_calculator / bmi_calculator)
- Create: 6 个 DAO + 6 个 repository
- Test: 8 + 6 = 14 test (3 logic + 6 DAO + 5 entity)

**schema migration**:
```dart
@override
int get schemaVersion => 18;

@override
MigrationStrategy get migration => MigrationStrategy(
  onCreate: (m) => m.createAll(),
  onUpgrade: (m, from, to) async {
    if (from < 18) {
      // 1. 加 period 列到 mood_entries
      await m.addColumn(moodEntries, moodEntries.period);
      // 2. 创建 6 张新表
      await m.createTable(sleepEntries);
      await m.createTable(socialRhythmEntries);
      await m.createTable(stressEvents);
      await m.createTable(treatmentEntries);
      await m.createTable(weightEntries);
      await m.createTable(anxietyAgitationEntries);
    }
  },
);
```

**每表结构** (R60 R90 drift 模式):
- id (autoIncrement)
- timestamp / date
- 5-8 个字段 (e.g. sleep: bedtime, wakeTime, durationMin, regularityScore)

**TDD**: 14 测试 (3 logic + 6 DAO + 5 entity), 1567 pass baseline + 14 = 1570 pass。

**1 commit**: `v0.30 round 91 (data): schema 17→18 + 6 新表 (sleep/social_rhythm/stress/treatment/weight/anxiety) + mood_entries period 列 + 14 test`

---

### Task 2: 4 mood 入口合并 + period UI + 心境图表

**Files:**
- Modify: `lib/presentation/pages/mood/mood_dialog.dart` (加 period dropdown)
- Modify: `lib/presentation/pages/mood_list/mood_list_page.dart` (加 period filter chip)
- Create: `lib/domain/logic/mood_period_aggregator.dart` (4 段聚合纯函数)
- Create: `lib/presentation/pages/daily_tracking/widgets/mood_period_aggregator_chart.dart` (4 段柱状/折线)
- Test: 3 test (aggregator + dialog period + list filter)

**mood_dialog.dart** 改造 (R84 基础上加 1 个 dropdown):
```dart
// 在 score 1-5 选择后, 加 PeriodField (morning/noon/evening/night/unspecified)
PeriodField(
  initialValue: state.draft.period ?? 'unspecified',
  onChanged: (v) => notifier.updateField(period: v),
),
```

**mood_list_page.dart** 加 period filter chip (R87 基础上):
```dart
// 顶部 chip 列表: 全部 / 早 / 中 / 晚 / 夜 / 未指定
// filterProvider 接受 period, R87 filter 升级
```

**mood_period_aggregator.dart** 纯函数:
```dart
class MoodPeriodAggregator {
  /// 给定 30 天 mood_entries, 返回 4 段均值
  /// {morning: 3.2, noon: 2.8, evening: 4.1, night: 2.5, count: 30}
  static Map<String, double> aggregateByPeriod(List<MoodEntry> entries) {
    // ...
  }
}
```

**mood_period_aggregator_chart.dart** (4 段柱状):
- 4 柱 (morning/noon/evening/night), Y 轴 score 1-5
- 跟 R90 trend_assessment_chart 风格一致

**TDD**: 3 case, 1570+3 = 1573 pass。

**1 commit**: `v0.30 round 91 (data): mood 4 入口合并 + period UI + 4 段聚合图表 + 3 test`

---

### Task 3: 治疗记录联动 medication (cross-table join)

**Files:**
- Modify: `lib/core/data/repositories/daily_tracking/treatment_repository_impl.dart` (FK nullable join)
- Modify: `lib/core/data/database/daos/treatment_dao.dart` (join medication 表)
- Create: `lib/domain/entities/treatment_entry.dart` (含 medicationName 缓存)
- Modify: `lib/presentation/pages/daily_tracking/widgets/treatment_widgets.dart` (list 显示 medication name)
- Test: 4 test (join 渲染 + linked/unlinked)

**treatment_entries 跟 medications 关系**:
- treatment_entries.linked_medication_id (nullable FK → medications.id)
- treatment_entries.linked_medication_name (cache, 写时 snapshot, R55 medication rename 时不更新历史)

**DAO join** (R90 R60 模式):
```dart
// treatmentDao.watchAllTreatmentEntries() — Stream<List<TreatmentEntry>>
// join medications: SELECT treatments.*, medications.name
// 左外连接, linked_medication_id IS NULL 也返回
```

**TDD**: 4 case (基本 / linked / unlinked / medication 改 name 不影响 history), 1573+4 = 1577 pass。

**1 commit**: `v0.30 round 91 (data): treatment 联动 medication (cross-table join + name 缓存) + 4 test`

---

### Task 4: 6 子功能 UI (sleep / social_rhythm / stress / weight / anxiety)

**Files:**
- Create: `lib/presentation/pages/daily_tracking/widgets/sleep_widgets.dart` (list + entry dialog)
- Create: `lib/presentation/pages/daily_tracking/widgets/social_rhythm_widgets.dart`
- Create: `lib/presentation/pages/daily_tracking/widgets/stress_event_widgets.dart`
- Create: `lib/presentation/pages/daily_tracking/widgets/weight_widgets.dart`
- Create: `lib/presentation/pages/daily_tracking/widgets/anxiety_agitation_widgets.dart`
- (treatment Task 3 已做)
- Test: 6 case (每子功能 1 个 widget test, 验证 list + entry dialog + submit)

**每子功能 widget 结构** (R88 mood_dialog 风格):
- ListView 显示历史 entry (时间倒序)
- FAB "添加" 按钮 → entry dialog
- Entry dialog: 表单字段 + 提交按钮
- Submit → 调 repository.insert + 关闭 dialog + 触发 list rebuild

**sleep_entry_dialog** (最复杂):
- bedtime picker (TimeOfDay)
- wake time picker
- 自动算 durationMin (e.g. 23:00 → 07:30 = 8.5h = 510 min)
- regularityScore 5 档评分 (1=不规律 / 5=很规律)

**weight_entry_dialog**:
- weightKg 输入 (1 decimal, 30-200 kg)
- 自动算 BMI (读 profile.height, 找不到时 bmi = null)
- note 可选

**TDD**: 6 case, 1577+6 = 1583 pass。

**1 commit**: `v0.30 round 91 (ui): 6 子功能 UI (sleep/social_rhythm/stress/weight/anxiety + entry dialog) + 6 test`

---

### Task 5: 整合入口页 + 7 卡片 + /daily-tracking 路由 + 主页 FAB 改

**Files:**
- Create: `lib/presentation/providers/daily_tracking_providers.dart`
- Create: `lib/presentation/pages/daily_tracking/daily_tracking_page.dart`
- Create: `lib/presentation/pages/daily_tracking/widgets/daily_tracking_card.dart`
- Modify: `lib/core/routing/app_router.dart` (加 /daily-tracking 路由)
- Modify: `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` (改 FAB 跳 daily-tracking)
- Test: 4 case (渲染 7 卡片 / 跳子功能 / FAB 跳 / period 卡片显示)

**daily_tracking_page.dart** 结构 (类比 R90 assessment_center_page):
- AppBar: "日常追踪" + FAB "全部趋势"
- Body:
  - 顶部 mini 趋势图 (Task 6 实施, 留 SizedBox 占位)
  - 7 卡片 grid (2 列):
    1. 情绪日记 (合并) — 上次 score + period
    2. 焦虑急躁 — 上次 2 score
    3. 睡眠 — 上次 duration + regularity
    4. 社会节律 — 上次活动时间分布
    5. 应激源 — 上次 intensity + type
    6. 治疗 — 上次 type + 描述
    7. 体重 — 上次 weightKg + bmi

**daily_tracking_providers.dart**:
- 7 个子功能 lastEntryProvider (跟 R90 latestEntryByScaleProvider 模式)
- dailyTrackingRepositoryProvider (聚合 6 个 repo)

**home_fab_toolbar.dart** 改 1 行:
```dart
// 之前: context.push('/assessment-center') (R90)
// 之后: context.push('/daily-tracking')
```

**TDD**: 4 case, 1583+4 = 1587 pass。

**1 commit**: `v0.30 round 91 (ui): 整合入口页 + 7 卡片 + /daily-tracking 路由 + 主页 FAB 改 daily-tracking + 4 test`

---

### Task 6: 多指标趋势图 (体重/睡眠/心境/应激源)

**Files:**
- Create: `lib/presentation/widgets/charts/daily_tracking_multi_chart.dart`
- Modify: `lib/core/theme/app_tokens.dart` (4 指标色 + 4 线型)
- Modify: `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` (mini chart 接上)
- Test: 4 case (空数据 / 单指标 / 4 指标叠加 / toggle 隐藏)

**AppTokens 扩** (4 指标 + 4 线型):
```dart
static const List<Color> dailyTrackingColors = [
  Color(0xFF1E88E5),  // 体重 蓝
  Color(0xFF8E24AA),  // 睡眠 紫
  Color(0xFF43A047),  // 心境 绿
  Color(0xFFE53935),  // 应激源 红
];

// 4 线型 (实/虚/点/双点)
static const List<List<int>> dailyTrackingDashArrays = [
  <int>[],
  <int>[5, 5],
  <int>[2, 3],
  <int>[8, 3, 2, 3],
];
```

**daily_tracking_multi_chart.dart**:
- 复用 R90 `AssessmentMultiLineChart` 模式 (chip toggle + Y 归一化 + 4 line)
- 接受 `Map<String, List<({DateTime ts, double value})>>` (4 指标)
- Y 归一化 (体重 kg / 睡眠 min / 心境 1-5 / 应激源 1-5 单位不同)

**TDD**: 4 case, 1587+4 = 1591 pass。

**1 commit**: `v0.30 round 91 (ui): 多指标趋势图 (体重/睡眠/心境/应激源) + 4 指标色 + 4 线型 + 复用 R90 chart 模式 + 4 test`

---

### Task 7: i18n ~80 ARB keys + CHANGELOG + final review + fix + merge

**Files:**
- Modify: 3 ARB files (~80 keys)
- Modify: `docs/CHANGELOG.md` (R91 entry)
- Modify: `lib/l10n/app_localizations*.dart` (gen-l10n 自动)
- Test: (无新 test, 由 守门员 verify)

**ARB keys 拆解** (~80):
- 整合入口 5 (title / fab / miniChartTitle / noData / lastTime)
- 7 子功能 × 8 keys (name / shortDesc / hint / addButton / noData / regularity / period / type) ≈ 56
- 治疗类型 4 (medication / consultation / physiotherapy / other)
- 应激源类型 5 (work / relationship / health / financial / other)
- period 4 (morning / noon / evening / night)
- regularity 5 (very irregular / irregular / normal / regular / very regular)
- 卡片状态 4 (noData / today / thisWeek / thisMonth)
- 合计 ~85 keys × 3 lang = 255 entries

**CHANGELOG R91 entry** (R90 之后):
```markdown
## [0.30.0] - 2026-08-XX

### Added (R91)

- **日常追踪模块** (Daily Tracking): 7 子功能整合 1 个入口页 (/daily-tracking)
- **7 子功能**: 情绪日记 (合并 4 入口 + period) / 焦虑急躁 / 睡眠 / 社会节律 / 应激源 / 治疗 / 体重
- **6 新表**: sleep_entries / social_rhythm_entries / stress_events / treatment_entries / weight_entries / anxiety_agitation_entries
- **mood_entries 加 period 列**: morning / noon / evening / night / unspecified, 4 段聚合心境图表
- **schemaVersion 17 → 18**: 6 新表 + 1 列, 老用户 0 数据迁移
- **治疗联动 medication**: treatment_entries FK + name 缓存, 跨表 join
- **多指标趋势图**: 体重/睡眠/心境/应激源 4 指标叠加, 复用 R90 chart 经验
- **整合入口页**: 7 卡片 grid + 顶部 mini 趋势图, 主页 FAB 跳 daily-tracking
- **80 ARB keys** × 3 lang: 7 子功能 + 整合入口 + period + 类型 + regularity

### Notes

- 4 mood 入口合并 (mood_dialog + 心境表格 + 评估心境 + 评估心境表格) → 1 个统一入口
- 主页 FAB 改 daily-tracking (R90 改 /assessment-center)
- mood_list 保留独立访问 (R87)
- trend 趋势页保留, 升级为多指标
- 提醒服务整合 / 交叉分析引擎 留 v0.31+ (跟 R90 一样)
```

**Final review (whole-branch)**:
- Dispatch verifier 看 ~500KB diff (spec/plan + 7 task)
- 期望: 0-1 Critical, 0-3 Important, 5-10 Minor
- 如有 Critical/Important → fix subagent
- Final review PASS 后 merge master

**Cleanup**:
- Save SDD → `docs/superpowers/sdd-logs/round91-daily-tracking/`
- `git worktree remove --force`
- `git worktree prune`
- `git branch -d feat/daily-tracking`

**1 commit**: `v0.30 round 91 (i18n): 85 ARB keys × 3 lang + CHANGELOG R91`

---

## Self-Review

- [x] Spec coverage: 7 子功能 (Task 1+2+3+4) / 整合入口 (Task 5) / 多指标图 (Task 6) / i18n (Task 7)
- [x] No placeholders (R60 R78 R90 复用, 6 张新表具体)
- [x] Type consistency: 各 entity 字段 nullable 兼容老 entry
- [x] TDD: red → green → commit per task
- [x] DRY: 1 mood_entries (加 period, 不开 4 张 mood_period) / 复用 R90 chart
- [x] YAGNI: 7 task 而非 8, 不重写 R84-R90 现有代码
- [x] Fail-safe: 治疗 FK nullable, 老 medication 删了不影响 treatment
- [x] 隐私: 0 网络, 7 张新表全本地

## 已知坑 (R91)

1. **schemaVersion 升级** — R84 R87 R90 都升级过, R91 17→18 加 1 列 6 表, 1 migration
2. **mood_entries 老 entry period 兼容** — nullable + 'unspecified' 默认, 老数据 0 迁移
3. **4 mood 入口合并** — 不删 mood_list_page (R87), 只是 FAB 改 1 行 + mood_dialog 加 period
4. **treatment 联动 medication** — FK nullable + name 缓存 (medication rename 不影响 history)
5. **体重 BMI 读 profile.height** — profile 找不到时 bmi = null, weight 必填
6. **6 张新表 + 1 列 + 8 widget + 7 ARB groups = 工作量大** — 7 task 拆, 每 task 1 subagent
7. **跨 feature import 守门** — 7 子功能都在 `presentation/pages/daily_tracking/` + `presentation/widgets/charts/`, 0 跨 feature
8. **schemaVersion 18 老用户升级** — R84 经验, `addColumn` 简单 + `createTable` 6 个
9. **R90 chart 复用** — `daily_tracking_multi_chart.dart` 类似 `assessment_multi_line_chart.dart`, 复用 color palette
10. **主页 FAB 改 daily-tracking** — 改 1 行, 不破坏 R90 评估按钮 (在 settings 内)

## 跟其他模块契约

- R84 (CBT 思维记录) — 不动, mood_entries 加 period 不影响 8 CBT 字段
- R87 (mood_list) — 加 period filter, list 本身不动
- R90 (量表中心) — 不交叉, v0.31+ 用户画像
- R88 (PDF 导出) — 不动, v0.31+ 日常追踪 PDF
- R55 (medication) — treatment FK nullable, 不破坏 medication 表
- R13 (trend) — 保留, v0.31+ 多指标升级

## 不在 scope

- ❌ 量表中心 (R90 已做)
- ❌ CBT 思维记录 (R84-R89 已做)
- ❌ 提醒服务整合 (v0.31+)
- ❌ 交叉分析引擎 (v0.31+)
- ❌ 体重/睡眠 PDF 导出
- ❌ 治疗语音输入
- ❌ mood_entries 老 entry 自动重算 period
- ❌ 12 量表跟日常追踪 cross 数据
- ❌ 8 CBT 字段加进 daily_tracking 整合
