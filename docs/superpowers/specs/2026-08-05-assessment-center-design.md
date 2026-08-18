# 量表中心 (Assessment Center) Design Spec

> v0.30 round 90 (sub-spec 6)
> 整合现有 4 量表 (PHQ-9 / GAD-7 / ISI / PSS) + 新增 8 量表 = 12 量表中心
> 单选答题 + 自动计分 + 多线趋势图

## 背景

R60 引入 `AssessmentScale` abstract interface (lib/domain/logic/assessment_scale.dart),统一 PHQ-9 / GAD-7 答题 + 计分 + 危机检测。R78 加 `ScaleTranslations` 抽象支持 en/zh_Hant。R51 加 `hotlineByRegion` 6 region 危机电话。

**当前痛点**:
1. `scale_registry.dart` 只注册 2 量表 (phq9 / gad7),ISI/PSS const class 存在但**未注册到 UI** (R60 失访)
2. `CheckInDao.watchAssessments()` hardcode `type='phq9' | 'gad7'`,ISI/PSS 提交后**历史趋势看不见**
3. 没有"量表中心"统一入口,用户在 settings / 主页 / 趋势页到处找
4. `trend_assessment_chart` 单线 (R13),扩展到 5+ 量表需要多线多色
5. 临床常用量表 (WHODAS / 成人抑郁严重度 / Level 2 精神病等) 缺失

**目标**:
- 12 量表中心化入口 (`/assessment-center` 路由)
- 8 新量表题库 + 计分 (含公开/收费 mix 策略)
- 多线趋势图 (不同量表不同颜色+线型)
- 数据兼容 (现有 phq9/gad7 check_ins entry 不迁移)
- 架构: 复用 R60 AssessmentScale interface,新增 = 加 1 import + 1 行

## 5 个 Design Decisions (已 user 确认)

### D1: 范围
**12 量表** = 4 已有 (注册) + 8 新增

| # | 量表 | id | 来源 | 题目数 | 状态 |
|---|---|---|---|---|---|
| 1 | PHQ-9 抑郁筛查 | `phq9` | 公开 (R60 已注册) | 9 | ✅ 已有 |
| 2 | GAD-7 广泛焦虑 | `gad7` | 公开 (R60 已注册) | 7 | ✅ 已有 |
| 3 | ISI 失眠严重指数 | `isi` | 公开 (R60 const 但未注册) | 7 | 🔧 注册 |
| 4 | PSS 压力量表 | `pss` | 公开 (R60 const 但未注册) | 10 | 🔧 注册 |
| 5 | WHODAS 2.0 (WHO 残疾评定) | `whodas` | 公开 (WHO 官方) | 12 (简化) | ✨ 新增 |
| 6 | 成人抑郁严重程度 (DSM-5 Level 2) | `level2_depression` | 公开 (APA) | 8 | ✨ 新增 |
| 7 | 成人广泛焦虑严重程度 (DSM-5 Level 2) | `level2_anxiety` | 公开 (APA) | 7 | ✨ 新增 |
| 8 | 成人躁狂严重程度 (DSM-5 Level 2) | `level2_mania` | 公开 (APA) | 5 | ✨ 新增 |
| 9 | Altman 自评躁狂量表 (ASRM) | `asrm` | 公开 (Altman 1997) | 5 | ✨ 新增 |
| 10 | 成人 PTSD 严重程度 (NSESSS) | `nsesss` | 收费 (NCS Pearson) | 22 | ⚠️ TODO 占位 |
| 11 | 成人精神病性症状 (DSM-5 Level 2) | `level2_psychosis` | 公开 (APA) | 8 | ✨ 新增 |
| 12 | CRDPSS (情绪与精神病性症状) | `crdpss` | 内部/缩写歧义 | ? | ⚠️ TODO 占位 |

**hybrid 策略 (user 选)**: 公开量表 (#5-9, 11) 写完整题库 + 计分;收费/歧义 (#10, 12) TODO 占位 (量表 description + "暂未开放" 提示)。

### D2: 题库数据化
**保持 R60 模式** — 量表 = `class XxxScale implements AssessmentScale` const Dart class,不存 DB。
- 优点: 编译期检查 / 0 网络 / 0 翻译漏 / 简单
- 缺点: 新增量表要发版
- 替代方案: DB 存题库 → 灵活但 schema 复杂,法务审核每题需走流程

### D3: 数据兼容 (user 选 keep)
**保留 `check_ins` 表** (R60 模式) — 量表 entry = `check_ins.type = '<scale_id>'`。
- 现有 PHQ-9 / GAD-7 entry 不动 (兼容老用户)
- 新量表写 `check_ins.type = 'whodas' / 'level2_depression' / ...`
- `CheckInDao.watchAssessments()` 扩展为 `type IN (10 个 scale_id)`
- 不开 `assessment_results` 独立表 (user 选 keep)

### D4: 趋势图多线
**扩展现有 `trend_assessment_chart`** (R13 单线) → 5+ 量表多线多色。
- 颜色: 每量表独立 AppToken 色 (`AppTokens.assessmentColorXxx`)
- 线型: 实线 / 虚线 / 点线 轮换 (`LineChartBarData.dashArray`)
- 量表开关: 顶部 chip 列表 (toggle 显示/隐藏)
- 严重度区域背景 (可选 v0.31+)

### D5: 中心化入口
**新页面 `assessment_center_page`** (路由 `/assessment-center`)。
- 12 量表卡片网格 (2 列)
- 卡片显示: 量表名 / 短描述 / 上次得分 / 上次时间 / "开始" 按钮
- 顶部: 全局趋势图 (mini, 12 量表叠加可选)
- 入口: home / settings 都有按钮 (跟 R13 R61 风格)

## 架构

### 复用 (R60 R78 R51)
- `AssessmentScale` interface (lib/domain/logic/assessment_scale.dart:77) — 12 量表共用
- `ScaleTranslations` abstract (lib/domain/logic/scale_translations.dart) — i18n
- `hotlineByRegion` 6 region (lib/domain/logic/assessment_scale.dart:181) — 危机电话
- `AssessmentRunner` UI (lib/presentation/pages/assessment/assessment_page.dart) — 答题引擎 (单 scaleId)
- `app_localizations_zh.dart` ARB 文件 — 翻译

### 新增
- `lib/domain/logic/isi.dart` / `pss.dart` (注册到 scale_registry,不算"新量表"但要补全)
- `lib/domain/logic/whodas.dart` / `level2_depression.dart` / `level2_anxiety.dart` / `level2_mania.dart` / `asrm.dart` / `level2_psychosis.dart` / `nsesss.dart` / `crdpss.dart` (8 新 const class)
- `lib/domain/logic/scale_registry.dart` — 12 量表 list (扩 10 行)
- `lib/domain/entities/assessment_entry.dart` — **新** domain entity (12 量表结果 view,跨表 join)
- `lib/core/data/database/daos/assessment_dao.dart` — **新** DAO (跨多 type 拉取)
- `lib/core/data/repositories/assessment/assessment_repository_impl.dart` — repo
- `lib/presentation/pages/assessment/assessment_center_page.dart` — **新** 中心化入口
- `lib/presentation/pages/assessment/widgets/assessment_center_card.dart` — 卡片 widget
- `lib/presentation/pages/assessment/widgets/assessment_multi_line_chart.dart` — **新** 多线趋势图
- `lib/presentation/providers/assessment_providers.dart` — **新** 中心化 provider
- `lib/core/routing/app_router.dart` — 加 `/assessment-center` 路由
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` — 翻译

### 修改
- `lib/core/data/database/daos/check_in_dao.dart:30-34` — `watchAssessments()` 扩 10 scale_id
- `lib/presentation/pages/trend/widgets/trend_assessment_chart.dart` — 升级多线 (或新写)
- `lib/presentation/pages/settings/widgets/assessment_section.dart` — 加"打开量表中心"按钮
- `lib/presentation/pages/home/home_page.dart` — 加"量表中心"入口 (跟 R61 同位置)

## 数据流

```
User 答题 (assessment_runner) 
  → AssessmentScale.computeResult(scores)  // 12 量表共用
  → CrisisSignal? (PHQ-9 / 自杀念头题)
  → CheckInDao.insert(CheckIn(type='whodas', timestamp=now))  // R60 模式
  → 写历史成功,触发 watchAllAssessments() rebuild
  → trend_assessment_chart 重绘多线
```

## UI 设计

### 中心化入口页 (assessment_center_page)
- AppBar: "量表中心" + 搜索 icon (按量表名搜索, v0.31+)
- 顶部 mini chart: 最近 30 天 12 量表叠加 (用户可点击 chip 切换)
- 12 卡片 grid (2 列):
  - 量表名 + 短描述
  - 上次得分 (大数字 + 严重度 badge)
  - 上次时间 ("3 天前")
  - "开始" 按钮 (CTA)
- TODO 状态 (#10 NSESSS, #12 CRDPSS): 灰色卡片 + "需法务/临床审核" badge + 不可点

### 多线趋势图
- Y 轴: 各量表归一化分数 (0-1, 各量表 totalRange 不同 → 归一)
- X 轴: 时间 (date)
- 颜色: 12 量表 = 12 色 (AppTokens.assessmentColorXxx)
- 线型: 实线 / 虚线 / 点线 轮换
- 顶部 chip 列表: toggle 显示/隐藏
- 点击 line → 显示 tooltip: "{量表名} {date} {score} ({severity})"

## i18n (≥ 30 ARB keys)

新量表 (每量表 6 keys):
- `<scaleId>Name` (e.g. `whodasName` = "WHODAS 2.0 残疾评定")
- `<scaleId>ShortDescription` (e.g. "WHO 通用残疾评估 12 题简化版")
- `<scaleId>Item_<0..N>` (题目, 12 量表 × 10 题平均 = 120+ keys)
- `<scaleId>Option_<0..M>` (选项, 4-5 选项 × 12 = 50 keys)
- `<scaleId>SeverityLabel_<0..4>` (5 档严重度, 12 × 5 = 60 keys)
- `<scaleId>SeveritySummary_<0..4>` (5 档描述, 12 × 5 = 60 keys)

中心化入口 (8 keys):
- `assessmentCenterTitle` = "量表中心"
- `assessmentCenterLastScore` = "上次 {score} 分"
- `assessmentCenterLastTime` = "{time} 填写"
- `assessmentCenterNoData` = "尚未填写过"
- `assessmentCenterStartButton` = "开始评估"
- `assessmentCenterMultiLineTitle` = "全部量表趋势"
- `assessmentCenterNotAvailable` = "需法务/临床审核, 暂未开放"
- `assessmentCenterComingSoon` = "敬请期待"

合计: **约 250+ ARB keys** (zh/en/zh_Hant × 250 = 750 entries)。

## 守门员

- 16+ 守门员全绿
- `flutter analyze` 0 error (9 pre-existing info OK)
- `flutter test` 1500+ pass (基线 1487 + 12 量表 × 1 单测 + UI 测试)
- `check_orphan_arb_keys` 0 orphan
- `check_strings_hardcoded` 0 hardcoded
- `check_cross_feature` 0 跨 feature import
- `check_all.dart` 4 layer 纯度

## 风险评估

| 风险 | 概率 | 缓解 |
|---|---|---|
| 8 新量表题库查错 (DSM-5 Level 2 公开简化版) | 中 | 引用 APA 官方源 + 注释 source URL + v0.31+ 法务审核时调整 |
| 12 量表 ARB keys 工作量大 | 高 | Task 6 拆 3-4 sub-task,中文优先,en/zh_Hant Phase 2 |
| 多线趋势图性能 (12 量表 × 30 天) | 低 | fl_chart 已支持 5+ 线 (R85 双线扩展),数据量 < 360 点 |
| check_ins.type 字段长 20 char 限制 | 低 | scale_id 缩 4-15 char (whodas/level2_depression 都 < 20) |
| ISI/PSS 之前 const class 但未注册 | 低 | Task 1 一起处理 (注册 + 翻译) |
| 5 档严重度对 12 量表不是统一 (有些 4 档) | 中 | `SeverityCutoff` 列表支持任意数量,`severityCutoffs.length` 不固定 |

## Out of scope

- ❌ 量表提醒 (R61c3 已有, 本次不动)
- ❌ 量表填写历史对比 (R13 R65 已有, 本次用现有 component)
- ❌ 12 量表题目全量汉化校审 (法务审核时)
- ❌ 12 量表临床建议 (recommendDoctorVisit 已抽象, 不重写)
- ❌ CRDPSS 内部 / NSESSS 收费 (TODO 占位)
- ❌ 中心化入口的搜索 / 收藏 / 排序 (v0.31+)
- ❌ 量表 PDF 导出 (跟 R88 mood PDF 类似, v0.31+)
- ❌ 量表跨用户分享 / 家人看 (PIPL 法务)

## 跟现有模块关系

- **CBT 思维记录 (R84-R89)**: 不动,mood_entries 8 CBT 字段不动,跟 assessment 表独立
- **设置 (R45)**: settings 加"打开量表中心"按钮 (跟 R45 风格一致)
- **主页 (home)**: 加"量表中心"入口 (跟 R61 assessment reminder 同位置)
- **趋势 (trend)**: trend_assessment_chart 升级多线 (12 量表叠加)
- **AI 辅助 (R89)**: 跟 AI 隐藏无关,本次不交叉 (R89 flag = false 隐藏)
- **导出 PDF (R88)**: 量表结果后续可加 PDF 导出 (v0.31+)

## 决策记录

| 决策 | 原因 |
|---|---|
| 12 量表 (4 已有 + 8 新) | user 描述 + hybrid 策略 |
| 复用 R60 AssessmentScale | 不重写,新增 = 加 1 import + 1 行 |
| 数据走 check_ins.type | R60 模式, user 选 keep 兼容 |
| 多线趋势图 (扩展 trend_assessment_chart) | 已有 fl_chart R85 基础 |
| 中心化入口新页面 | user 要求,跟 R60 单 scale 路由并存 |
| 公开量表写, 收费标 TODO | user 选 hybrid |
| ARB keys ~250 | 12 量表 × 5 类别 (name/desc/item/option/severity) + 入口 8 |
| 6 task sub-spec | 跟 R89 模式一致,每 task 1 subagent |
