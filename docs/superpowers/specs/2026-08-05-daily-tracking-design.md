# 日常追踪模块 (Daily Tracking) Design Spec

> v0.30 round 91 (sub-spec 7)
> 情绪日记升级: 7 子功能 + 整合入口页 + 治疗记录联动 medication
> 合并现有 4 mood 入口 → 1 个统一入口 + 心境图表按时间段标记

## 背景

R84 落地 CBT 思维记录 (8 字段加 mood_entries) + R85 R86 R87 3 个 sub-spec 增强 mood (mood_list 列表 + trend 图表 + assessment reminder)。R90 落地量表中心 (12 量表)。

**当前痛点 (R87 后状态)**:
1. **4 入口分散**: mood_dialog (打卡) / mood_list (历史) / trend (趋势) / 主页评估按钮 — 用户搞不清
2. **mood_entries 表 "心境变化" 维度缺失** — 没显式 period 字段,morning/noon/evening/night 心境不能分段聚合
3. **焦虑水平只能跟 mood 一起填** — mood_entries.anxiety 字段,但用户想"快速评估"独立条目
4. **睡眠 / 体重 / 治疗 0 追踪** — 生理指标完全空白
5. **社会节律 / 应激源 0 追踪** — 临床常用 ecological momentary assessment (EMA) 维度缺失
6. **治疗记录 0 跟 medication 联动** — R55 medication reminder 独立,治疗历史不连接

**目标**:
- 7 子功能整合 1 个 `/daily-tracking` 入口 (类比 R90 assessment_center)
- 4 mood 入口合并 → 1 个统一入口 + 心境图表按时间段标记
- 治疗记录与 medication 联动 (同表 cross-FK, join 渲染)
- 6 张新表 (sleep / social_rhythm / stress_events / treatment / weight / anxiety_agitation)
- mood_entries 加 1 个 `period` 列 (schemaVersion 17 → 18)
- 多指标趋势图 (体重 + 睡眠 + 心境 + 应激源 叠加, R90 多线 chart 经验复用)

## 7 子功能 + 整合入口

### 子功能清单 (7 个)

| # | 子功能 | 表 | 主要字段 | 跟现有模块关系 |
|---|---|---|---|---|
| 1 | 情绪日记 (合并) | mood_entries + period 列 | score / tags / note / period (新) | 合并 mood_dialog + 心境表格 + 评估心境 + 评估心境表格 → 1 个 |
| 2 | 焦虑急躁水平快速评估 | anxiety_agitation_entries | anxietyScore 1-5 / agitationScore 1-5 / note | 独立, 跟 mood 解耦, 1 条 = 1 个时间点 |
| 3 | 睡眠记录 | sleep_entries | bedtime / wakeTime / durationMin / regularityScore | 跟 social_rhythm 联动 (起床时间 cross-check) |
| 4 | 社会节律 | social_rhythm_entries | wakeTime / firstMealTime / lastMealTime / socialMin / workMin / exerciseMin | 1 天 1 条, 跟 sleep wakeTime 联动 |
| 5 | 生活事件/应激源 | stress_events | eventType (enum) / intensity 1-5 / note / linkedMoodEntryId | 跟 mood_entries 弱联动 (FK nullable) |
| 6 | 治疗记录 | treatment_entries | treatmentType / description / linkedMedicationId / linkedMedicationName | 跟 R55 medication 强联动 (FK), 1 条治疗 = 1 次咨询/物理治疗/用药 |
| 7 | 体重记录 | weight_entries | weightKg / bmi / note | 独立, 1 天可多次 (e.g. morning/evening) |

### 整合入口页 (`/daily-tracking`)

**类比 R90 `/assessment-center`**: 7 卡片 grid (2 列移动端 1 列)
- 每卡片: 子功能名 + 短描述 + 上次记录 + "记录" 按钮
- 顶部 mini 趋势图 (体重/睡眠/心境 3 指标叠加, 30 天)
- FAB "全部趋势" → 全屏多指标 chart

### mood 4 入口合并计划

**现有 4 入口**:
1. `lib/presentation/pages/mood/mood_dialog.dart` (主页 / 主页 FAB 跳)
2. `lib/presentation/pages/mood_list/mood_list_page.dart` (R87 列表)
3. `lib/presentation/pages/trend/...` (R13 trend, 趋势图)
4. `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` (R88 home 评估按钮)

**合并后**:
- `/daily-tracking` 是 1 个主入口
- 主页 FAB 跳 `/daily-tracking` (改 1 处, R88 home 评估按钮 → daily tracking 按钮)
- mood_list 列表保留 (R87 已有, 跟 daily tracking 并存, 链接到 R90 assessment 历史)
- trend 趋势页保留, 升级为多指标

## 5 Design Decisions

### D1: 范围
**7 子功能 + 整合入口** (user 设计完整) — 6 新表 + mood_entries 加 1 列 + 1 整合入口页 + 治疗联动 medication + 多指标趋势图

### D2: schemaVersion 升级 (R90 17 → 18)
**升级** (R91): 7 新表 + mood_entries 1 列 → 1 schema change
- **理由**: R90 16 守门员全绿, schemaVersion 升级有 R84 经验 (R84 加 8 CBT 字段也升级过)
- 老用户升级 0 数据迁移 (新表空, 新列 nullable)
- R91 风险: drift migration 必须覆盖, 但 1 列加 6 表都是新增, 简单

### D3: 心境时段标记 (mood_entries.period 列)
**加 1 个 `period` 列** (TextColumn, nullable, enum morning/noon/evening/night/unspecified)
- 4 段聚合 (心境图表按 4 段叠柱状/折线)
- 老 entry 兼容 (period = 'unspecified' 当 null)
- 简化 vs 4 张表 (mood_period_entries) — 0 新表, 0 跨表 join

### D4: 治疗记录联动 medication
**FK nullable** (linkedMedicationId) + 缓存字段 (linkedMedicationName)
- R55 medication 表 R88 已存在, schemaVersion 14+ 有 medications 表
- treatment_entries. linkedMedicationId 是 medications.id 的 nullable FK
- Drift 不强制外键 (R60 模式: "MVP 阶段不建外键约束"), 由应用层维护
- 渲染: treatment 列表 join medication 显示名字

### D5: 多指标趋势图 (跟 R90 复用)
**复用 R90 `assessment_multi_line_chart` 模式**:
- 不同颜色: 体重(蓝) / 睡眠时长(紫) / 心境均值(绿) / 应激源强度均值(红)
- 顶部 chip 列表 toggle 显示/隐藏
- Y 轴归一化 (各指标单位不同 → 0-1 标准化)

## 架构

### 复用 (R90)
- `lib/presentation/widgets/charts/assessment_multi_line_chart.dart` (R90 12 色 + 3 线型) — 改用于 4 指标
- `lib/presentation/widgets/charts/assessment_color_palette.dart` (R90) — 复用 12 色, 改 mapping
- `lib/core/data/database/daos/check_in_dao.dart` (R60 R90) — 不动
- `lib/core/data/repositories/assessment/assessment_repository_impl.dart` (R90) — 不动
- 4-layer 架构 (domain 0 flutter 0 drift, data drift OK, presentation 包装)
- 现有 4 mood 入口 (R84 R87 R88) 改造不重写

### 新增 (R91)
- `lib/core/data/database/tables/daily_tracking/sleep_entries.dart` (新表)
- `lib/core/data/database/tables/daily_tracking/social_rhythm_entries.dart` (新表)
- `lib/core/data/database/tables/daily_tracking/stress_events.dart` (新表)
- `lib/core/data/database/tables/daily_tracking/treatment_entries.dart` (新表)
- `lib/core/data/database/tables/daily_tracking/weight_entries.dart` (新表)
- `lib/core/data/database/tables/daily_tracking/anxiety_agitation_entries.dart` (新表)
- `lib/core/data/database/tables/mood/mood_entries.dart` (加 period 列)
- `lib/core/data/database/app_database.dart` (schemaVersion 17 → 18, 6 个 DAO getter, 1 migration)
- `lib/domain/entities/sleep_entry.dart` / `social_rhythm_entry.dart` / `stress_event.dart` / `treatment_entry.dart` / `weight_entry.dart` / `anxiety_agitation_entry.dart`
- `lib/domain/logic/sleep_calculator.dart` (纯函数: bedtime + wakeTime → durationMin + regularityScore)
- `lib/domain/logic/bmi_calculator.dart` (weight + height → bmi, 需 profile 表读 height, 找不到时 null)
- `lib/domain/logic/mood_period_aggregator.dart` (4 段聚合: morning/noon/evening/night 均值)
- `lib/core/data/database/daos/sleep_dao.dart` / 5 other DAOs
- `lib/core/data/repositories/daily_tracking/sleep_repository_impl.dart` / 5 other repos
- `lib/presentation/providers/daily_tracking_providers.dart` (新)
- `lib/presentation/pages/daily_tracking/daily_tracking_page.dart` (整合入口)
- `lib/presentation/pages/daily_tracking/widgets/daily_tracking_card.dart` (7 卡片 widget)
- `lib/presentation/pages/daily_tracking/widgets/sleep_card.dart` / 5 other
- `lib/presentation/pages/daily_tracking/widgets/sleep_entry_dialog.dart` / 5 other (输入 dialog)
- `lib/presentation/pages/daily_tracking/widgets/daily_tracking_multi_chart.dart` (多指标趋势图)
- `lib/presentation/pages/mood/mood_dialog.dart` (改造: 加 period 字段)
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` (改 FAB 跳 daily-tracking)
- `lib/core/routing/app_router.dart` (加 /daily-tracking 路由)
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` (~80 keys)

### 修改
- `lib/core/data/database/app_database.dart` (schemaVersion 18 + 6 DAO getter)
- `lib/core/data/database/tables/mood/mood_entries.dart` (加 period 列)
- `lib/presentation/pages/mood/mood_dialog.dart` (period UI)
- `lib/presentation/pages/mood_list/mood_list_page.dart` (period 过滤)
- `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` (改 FAB)
- `lib/core/routing/app_router.dart` (加路由)
- `lib/core/theme/app_tokens.dart` (4 指标色 + 4 线型)

## 数据流

```
User 7 子功能 → 各 entry dialog → Submit → 各自 DAO.insert 
  → 写新表 (sleep / social_rhythm / ...) 或 mood_entries (period 列)
  → 触发 watchAll() rebuild
  → daily_tracking_page 卡片 "上次记录" 更新
  → 多指标趋势图重绘
```

## UI 设计

### daily_tracking_page (整合入口)
- AppBar: "日常追踪" + FAB "全部趋势"
- Body:
  - 顶部 mini 趋势图 (4 指标 30 天, R90 复用)
  - 7 卡片 grid:
    1. 情绪日记 (合并) — 上次 score 1-5 + 短描述 + period
    2. 焦虑急躁 — 上次 2 score 1-5
    3. 睡眠 — 上次 duration 7h30 + regularity 4/5
    4. 社会节律 — 上次 1 天活动时间分布
    5. 应激源 — 上次 强度 4/5 + 类型
    6. 治疗 — 上次 类型 + 描述
    7. 体重 — 上次 weightKg + BMI

### 各子功能 entry dialog
- 跟 R88 mood_dialog 同风格 (Card + 表单 + 保存按钮)
- sleep_entry_dialog: bedtime picker + wake time picker + 自动算 durationMin + regularity 5 档评分
- weight_entry_dialog: weightKg 输入 + 自动算 BMI (读 profile.height)
- treatment_entry_dialog: treatmentType dropdown + 描述 + 可选 medication 关联
- 等等

### 多指标趋势图
- 体重(蓝) / 睡眠时长(紫) / 心境均值(绿) / 应激源均值(红)
- 4 chip toggle
- Y 轴归一化 0-1
- tooltip "{指标名} {date} {value}"

## i18n (~80 ARB keys)

整合入口 + 7 子功能,每子功能 8-12 keys:
- `dailyTrackingTitle` = "日常追踪"
- `dailyTrackingLastTime` = "{time}"
- 7 子功能名 (moodDiary / anxietyAgitation / sleep / socialRhythm / stressEvent / treatment / weight)
- 7 短描述
- 7 提示 (placeholder)
- period 标签 (morning/noon/evening/night) × 1
- entry dialog 提示 × 7
- treatment 类型 (medication/consultation/physiotherapy/other) × 1
- stress event 类型 (work/relationship/health/financial/other) × 1
- regularity 评分 (0-4) × 1
- 卡片 4 状态 (noData / today / thisWeek / thisMonth) × 1

合计 ~80 keys × 3 lang = 240 entries

## 守门员

- 16+ 守门员全绿
- `flutter analyze` 0 error (R90 9 pre-existing info OK)
- `flutter test` 1600+ pass (R90 1556 + R91 6 DAO × 1 + 7 widget + 1 multi-chart = 50+)
- `check_orphan_arb_keys` 0 orphan
- `check_strings_hardcoded` 0 hardcoded
- `check_cross_feature` 0 跨 feature import
- `check_all.dart` 4 layer 纯度

## 风险评估

| 风险 | 概率 | 缓解 |
|---|---|---|
| schemaVersion 升级老用户数据迁移 | 低 | 6 新表空 + 1 列 nullable, 0 数据迁移 |
| 7 张新表 + 1 列 + 8 widget 工作量大 | 中 | 7 task sub-spec 拆, 每 task 1 subagent |
| mood_entries 改 schema, R87 mood_list 过滤 break | 中 | period 兼容 'unspecified' 默认, 老 entry 不变 |
| treatment 联动 medication join 性能 | 低 | 1 条治疗 = 1 medication lookup, FK 缓存 name 字段 |
| 体重 BMI 需读 profile.height, 找不到时 null | 中 | weight_kg 必填, bmi nullable 兼容 |
| 4 mood 入口合并, 现有 test break | 中 | 4 task 单独跑 mood_list / mood_dialog 旧 test verify 兼容 |

## Out of scope

- ❌ 量表中心 (R90 已做)
- ❌ CBT 思维记录 (R84-R89 已做)
- ❌ 提醒服务整合 (v0.31+)
- ❌ 交叉分析引擎 (v0.31+ 大工程)
- ❌ 体重 / 睡眠 PDF 导出 (v0.31+)
- ❌ 多指标趋势图跟量表多线图交叉 (v0.31+ 用户画像)
- ❌ 治疗记录语音输入 (v0.31+)
- ❌ mood_entries 老 entry 自动重算 period (历史数据保持 unspecified)

## 跟现有模块关系

- **mood_entries (R84 R87)**: 加 period 列, 兼容老 entry
- **mood_list (R87)**: 加 period filter 升级
- **mood_dialog (R84)**: 加 period UI 字段
- **trend (R13)**: 升级多指标 chart (体重/睡眠/心境)
- **medication (R55)**: treatment_entries FK nullable
- **量表中心 (R90)**: 不交叉, v0.31+ 用户画像
- **CBT (R84-R89)**: 不动
- **AI (R89 flag 隐藏)**: 不动

## 决策记录

| 决策 | 原因 |
|---|---|
| 7 子功能 + 整合入口 | user 需求完整 |
| schemaVersion 17 → 18 | 6 新表 + 1 列必须, R84 升级经验 OK |
| mood_entries 加 period 列 | 简化 vs 4 张 mood_period 表 |
| treatment FK nullable | R60 drift 不强制外键模式 |
| 多指标趋势图复用 R90 | 12 色 + 3 线型经验 |
| 4 mood 入口合并到 1 整合入口 | user 设计, mood_list 保留独立访问 |
| 7 task sub-spec | R90 6 task 模式扩展, R91 多 1 task (治疗联动) |
| 估算 35-45 commits | 6 表 + 1 整合 + 1 联动 + 1 chart + i18n |

## 7 Task 拆解概要

- **Task 1**: schema 升级 + 6 新表 + mood_entries 加 period + 6 DAO + 6 entity + 6 repository (数据层)
- **Task 2**: 4 mood 入口合并 + period UI (mood_dialog + mood_list + 心境图表)
- **Task 3**: treatment 联动 medication (cross-table join, FK nullable, 缓存 name)
- **Task 4**: 6 子功能 UI (sleep / social_rhythm / stress / weight / anxiety + entry dialog)
- **Task 5**: 整合入口页 + 7 卡片 + /daily-tracking 路由 + 主页 FAB 改
- **Task 6**: 多指标趋势图 (体重/睡眠/心境/应激源, 复用 R90 chart 经验)
- **Task 7**: i18n + CHANGELOG + final review + fix + merge
