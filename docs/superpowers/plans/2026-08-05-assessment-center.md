# 量表中心 (Assessment Center) Implementation Plan

> v0.30 round 90 (sub-spec 6)
> 5-7 task sub-spec,跟 R89 (CBT AI) 同模式
> Spec: docs/superpowers/specs/2026-08-05-assessment-center-design.md (6415 bytes)

## Goal

12 量表中心化 (4 已有 + 8 新增), 单选答题 + 自动计分, 多线趋势图

## Architecture

**复用 R60 AssessmentScale** (lib/domain/logic/assessment_scale.dart:77) — 新增量表 = 加 1 import + 1 行。
**数据走 check_ins.type** (R60 模式) — 现有 phq9/gad7 entry 不动, 新量表 type = 'whodas' / 'level2_depression' / ...
**i18n 走 ScaleTranslations** (R78) — 12 量表每题/选项/严重度全 ARB
**多线趋势图 fl_chart** (R85 双线扩 12 线)

## Global Constraints

- Flutter 3.41.9 / Dart 3.12.2
- 4-layer architecture (domain 0 flutter 0 drift)
- 守门员: 16+ 全绿
- TDD: red → green → commit
- baseline 1487 pass / 0 fail (R88 + R89 docs commit)
- master commit e5af96d
- **不重新发明 R60 interface** — 新量表 = const class implements AssessmentScale
- **不重命名 check_ins** — type 字段长 20 char 限制,新 scale_id 需 ≤ 20 char

## File Structure

### 新增
- `lib/domain/logic/isi.dart` (R60 const 补全, 注册到 registry)
- `lib/domain/logic/pss.dart` (R60 const 补全, 注册到 registry)
- `lib/domain/logic/whodas.dart` (新增 12 题简化)
- `lib/domain/logic/level2_depression.dart` (新增 8 题)
- `lib/domain/logic/level2_anxiety.dart` (新增 7 题)
- `lib/domain/logic/level2_mania.dart` (新增 5 题)
- `lib/domain/logic/asrm.dart` (新增 5 题 Altman)
- `lib/domain/logic/level2_psychosis.dart` (新增 8 题)
- `lib/domain/logic/nsesss.dart` (TODO 占位)
- `lib/domain/logic/crdpss.dart` (TODO 占位)
- `lib/domain/entities/assessment_entry.dart` (domain entity)
- `lib/domain/logic/assessment_color_palette.dart` (12 色 + 线型 token)
- `lib/core/data/database/daos/assessment_dao.dart` (跨 type 拉取)
- `lib/core/data/repositories/assessment/assessment_repository_impl.dart`
- `lib/presentation/providers/assessment_providers.dart`
- `lib/presentation/pages/assessment/assessment_center_page.dart`
- `lib/presentation/pages/assessment/widgets/assessment_center_card.dart`
- `lib/presentation/pages/assessment/widgets/assessment_multi_line_chart.dart`
- `lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart` (TODO 状态)
- `test/domain/logic/whodas_round90_test.dart`
- `test/domain/logic/level2_depression_round90_test.dart`
- `test/domain/logic/level2_anxiety_round90_test.dart`
- `test/domain/logic/level2_mania_round90_test.dart`
- `test/domain/logic/asrm_round90_test.dart`
- `test/domain/logic/level2_psychosis_round90_test.dart`
- `test/domain/logic/isi_round90_test.dart` (R60 补全)
- `test/domain/logic/pss_round90_test.dart` (R60 补全)
- `test/core/data/database/assessment_dao_round90_test.dart`
- `test/presentation/pages/assessment/assessment_center_page_round90_test.dart`
- `test/presentation/pages/assessment/assessment_multi_line_chart_round90_test.dart`

### 修改
- `lib/domain/logic/scale_registry.dart` (扩 12 行, 10 量表)
- `lib/domain/logic/assessment_record.dart` (扩 compute 兼容 12)
- `lib/core/data/database/daos/check_in_dao.dart:30-34` (watchAssessments 扩 10 type)
- `lib/core/routing/app_router.dart` (加 /assessment-center 路由)
- `lib/presentation/pages/settings/widgets/assessment_section.dart` (加"打开量表中心"按钮)
- `lib/presentation/pages/home/home_page.dart` (加"量表中心"入口, 跟 R61 同位置)
- `lib/presentation/pages/trend/widgets/trend_assessment_chart.dart` (升级多线)
- `lib/core/theme/app_tokens.dart` (12 色 + 3 线型常量)
- `lib/l10n/app_zh.arb` / `app_en.arb` / `app_zh_Hant.arb` (~250 keys)

---

### Task 1: 量表库 - 补全 4 已有 + 加 6 新 (公开)

**Files:**
- Modify: `lib/domain/logic/isi.dart` (R60 const 补全)
- Modify: `lib/domain/logic/pss.dart` (R60 const 补全)
- Create: `lib/domain/logic/whodas.dart` (12 题)
- Create: `lib/domain/logic/level2_depression.dart` (8 题)
- Create: `lib/domain/logic/level2_anxiety.dart` (7 题)
- Create: `lib/domain/logic/level2_mania.dart` (5 题)
- Create: `lib/domain/logic/asrm.dart` (5 题 Altman)
- Create: `lib/domain/logic/level2_psychosis.dart` (8 题)
- Test: 8 new test files

**每量表结构** (R60 模式):
```dart
class WhodasScale implements AssessmentScale {
  @override
  ScaleTranslations get translations => const StaticScaleTranslations();  // 起步, Task 5/6 换 ARB
  
  @override
  String get id => 'whodas';
  
  @override
  String get displayName => 'WHODAS 2.0 残疾评定';
  
  // 12 题, 5 档 0-4, 总分 0-48
  @override
  List<AssessmentItem> get items => [...];
  
  @override
  Map<int, String> get options => {0: '没有', 1: '轻微', 2: '中度', 3: '重度', 4: '极重度'};
  
  @override
  int get totalRange => 48;
  
  @override
  List<SeverityCutoff> get severityCutoffs => [...];  // 5 档
  
  @override
  AssessmentResult computeResult(List<int> scores) { ... }
  
  @override
  CrisisSignal? detectCrisis(...) => null;  // 公开量表不触发危机, 走 PHQ-9
}
```

**Score 公式** (各量表不同):
- PHQ-9: sum (0-27)
- GAD-7: sum (0-21)
- ISI: sum (0-28)
- PSS: sum × 反向 (0-40, 4 题反向计分)
- WHODAS 2.0: sum × 100/48 (标准化 0-100, 简化版)
- Level 2 Depression: sum (0-24, 8 题 × 3 档)
- Level 2 Anxiety: sum (0-21, 7 题 × 3 档)
- Level 2 Mania: sum (0-20, 5 题 × 4 档)
- ASRM: sum (0-20, 5 题 × 4 档)
- Level 2 Psychosis: sum (0-24, 8 题 × 3 档)

**TDD**: 8 量表 × 1 case (computeResult 正确) = 8 test,基线 → 1495 pass。

**1 commit**: `v0.30 round 90 (data): 8 量表题库 + 4 已有补全 (R60 AssessmentScale 复用)`

---

### Task 2: scale_registry 中心化 (10 量表) + ScaleTranslations 抽象补全

**Files:**
- Modify: `lib/domain/logic/scale_registry.dart` (扩 12 行)
- Modify: `lib/domain/logic/scale_translations.dart` (扩 8 量表抽象方法)
- Modify: `lib/domain/entities/scale_translations_impl.dart` (10 量表 zh fallback)
- Test: `test/domain/logic/scale_registry_round90_test.dart`

**scale_registry.dart**:
```dart
List<AssessmentScale> allScales() => const [
  phq9Scale, gad7Scale, isiScale, pssScale,  // 4 已有
  whodasScale, level2DepressionScale, level2AnxietyScale, level2ManiaScale, asrmScale,  // 5 新
  level2PsychosisScale,  // 6 新 (1 个跳过 TODO)
  // TODO: nsesssScale, crdpssScale  // 2 个未开放
];
```

**scale_translations.dart 抽象方法** (R78 模式):
- phq9*: 已有 21 方法
- gad7*: 已有 18 方法
- isi*: 加 15 方法 (name/shortDescription/instruction + 7 items + 5 options + 5 severity × 2)
- pss*: 加 20 方法
- whodas*: 加 30 方法
- level2Depression*: 加 26 方法
- level2Anxiety*: 加 23 方法
- level2Mania*: 加 17 方法
- asrm*: 加 17 方法
- level2Psychosis*: 加 26 方法

合计 ~200 方法。`StaticScaleTranslations` (zh fallback) + `AppLocalizationsScaleTranslations` (l10n 注入) 都实现。

**TDD**: scaleById 12 case + allScales 长度 10 = 2 test,基线 → 1497 pass。

**1 commit**: `v0.30 round 90 (data): scale_registry 10 量表 + ScaleTranslations 200 方法 (R78 i18n 扩)`

---

### Task 3: check_ins DAO 扩 watchAssessments + AssessmentDao + repo

**Files:**
- Modify: `lib/core/data/database/daos/check_in_dao.dart:30-34` (扩 10 type)
- Create: `lib/core/data/database/daos/assessment_dao.dart` (跨 type 拉取)
- Create: `lib/core/data/database/daos/assessment_dao.g.dart` (build_runner 自动)
- Create: `lib/domain/entities/assessment_entry.dart` (domain entity)
- Create: `lib/core/data/repositories/assessment/assessment_repository_impl.dart`
- Modify: `lib/core/data/database/app_database.dart` (dao 注册)
- Test: `test/core/data/database/assessment_dao_round90_test.dart`

**check_in_dao.dart:30-34**:
```dart
Stream<List<CheckIn>> watchAssessments() {
  return (select(checkIns)
        ..where((t) => t.type.isIn([
          'phq9', 'gad7', 'isi', 'pss',  // R60 已有
          'whodas', 'level2_depression', 'level2_anxiety',
          'level2_mania', 'asrm', 'level2_psychosis',  // R90 新
        ]))
        ..orderBy([(t) => OrderingTerm.asc(t.timestamp)]))
      .watch();
}
```

**assessment_dao.dart** (新 DAO):
- `watchAllAssessmentEntries()` → `Stream<List<AssessmentEntry>>` (跨 type join)
- `getLatestEntryByType(String scaleId)` → `Future<AssessmentEntry?>`
- `countByType()` → `Future<Map<String, int>>` (统计每量表提交次数)

**AssessmentEntry domain entity**:
```dart
class AssessmentEntry {
  final int id;
  final DateTime timestamp;
  final String scaleId;  // 'whodas' / 'phq9' / ...
  final int score;
  final int severityRank;  // 0-4
  // future: answersJson (各题答案)
}
```

**TDD**: 4 case (watchAll / getLatest / countByType / 跨 type 聚合) = 4 test,基线 → 1501 pass。

**1 commit**: `v0.30 round 90 (data): AssessmentDao + watchAssessments 10 type + AssessmentEntry entity + repo`

---

### Task 4: 中心化入口页 + 12 卡片 + 入口按钮

**Files:**
- Create: `lib/presentation/providers/assessment_providers.dart`
- Create: `lib/presentation/pages/assessment/assessment_center_page.dart`
- Create: `lib/presentation/pages/assessment/widgets/assessment_center_card.dart`
- Create: `lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart` (TODO 状态)
- Modify: `lib/core/routing/app_router.dart` (加 /assessment-center 路由)
- Modify: `lib/presentation/pages/settings/widgets/assessment_section.dart` (加"打开量表中心"按钮)
- Modify: `lib/presentation/pages/home/home_page.dart` (加"量表中心"入口)
- Test: `test/presentation/pages/assessment/assessment_center_page_round90_test.dart`

**assessment_center_page.dart** 结构:
- AppBar: "量表中心" + 搜索 icon (v0.31+ TODO)
- Body:
  - 顶部 mini 趋势图 (12 量表叠加, 30 天, R85 fl_chart 基础)
  - 12 卡片 grid (2 列, 移动端 1 列)
- FAB: "全部趋势" → 跳 trend_assessment_chart 全屏

**assessment_center_card.dart**:
- 量表名 (大)
- 短描述 (caption)
- 上次得分 (大数字 + 严重度 badge)
- 上次时间 ("3 天前")
- "开始" 按钮 (CTA, 跳 /assessment/:scaleId)
- TODO 状态卡片: 灰色 + 锁 icon + "需法务审核" badge

**router 加路由**:
```dart
GoRoute(
  path: '/assessment-center',
  builder: (context, state) => const AssessmentCenterPage(),
),
```

**settings assessment_section.dart**:
- 现有"提醒" + "提醒时间" + "上次提醒" 卡片下面加新按钮"打开量表中心" (FilledButton.tonalIcon)

**home_page.dart**:
- 现有 4 主页按钮 (打卡 / 设置 / 倾诉 / 评估) 评估按钮改成"量表中心"路由

**TDD**: 4 case (渲染 / 12 卡片 / TODO 状态 / FAB 跳转) = 4 test,基线 → 1505 pass。

**1 commit**: `v0.30 round 90 (ui): 中心化入口页 + 12 卡片 + 路由 + 入口按钮`

---

### Task 5: 多线趋势图 (12 量表多色多线型) + 颜色 token

**Files:**
- Create: `lib/domain/logic/assessment_color_palette.dart` (12 色 + 3 线型)
- Modify: `lib/core/theme/app_tokens.dart` (加 12 色 + 3 线型常量)
- Create: `lib/presentation/pages/assessment/widgets/assessment_multi_line_chart.dart`
- Modify: `lib/presentation/pages/trend/widgets/trend_assessment_chart.dart` (升级多线)
- Test: `test/presentation/pages/assessment/assessment_multi_line_chart_round90_test.dart`

**AppTokens 新增**:
```dart
// 12 量表颜色 (色相分散, 色盲友好)
static const List<Color> assessmentColors = [
  Color(0xFF1E88E5),  // PHQ-9 蓝
  Color(0xFFE53935),  // GAD-7 红
  Color(0xFF43A047),  // ISI 绿
  Color(0xFFFB8C00),  // PSS 橙
  Color(0xFF8E24AA),  // WHODAS 紫
  Color(0xFF00ACC1),  // Level 2 Dep 青
  Color(0xFFD81B60),  // Level 2 Anx 粉
  Color(0xFF6D4C41),  // Level 2 Mania 棕
  Color(0xFF3949AB),  // ASRM 蓝紫
  Color(0xFF7CB342),  // Level 2 Psy 浅绿
  Color(0xFFF4511E),  // NSESSS 深橙 (TODO)
  Color(0xFF546E7A),  // CRDPSS 蓝灰 (TODO)
];

// 3 线型 (实线/虚线/点线, 循环)
static const List<List<int>> assessmentDashArrays = [
  [],           // 实线
  [5, 5],       // 虚线
  [2, 3],       // 点线
];
```

**assessment_multi_line_chart.dart**:
- 接受 `Map<String, List<({DateTime ts, int score})>>` (10 量表)
- 归一化 Y 轴 (各量表 totalRange 不同 → 0-1 标准化)
- 12 条 LineChartBarData,各用 assessmentColors[i] + assessmentDashArrays[i % 3]
- 顶部 chip 列表 (12 chip, toggle 显示/隐藏)
- tooltip: "{量表名} {date} {score}/{totalRange} ({severity})"

**trend_assessment_chart 升级**:
- 现有单线 (R13) → 改成调用 assessment_multi_line_chart + 默认显示所有 10 量表
- toggle 状态本地化 (FutureBuilder 模式)

**TDD**: 4 case (空数据 / 单量表 / 12 量表 / toggle 隐藏 1 个) = 4 test,基线 → 1509 pass。

**1 commit**: `v0.30 round 90 (ui): 多线趋势图 12 量表 + 12 色 + 3 线型 + toggle chip`

---

### Task 6: i18n ~250 ARB keys + CHANGELOG + final review + fix + merge

**Files:**
- Modify: 3 ARB files (~250 keys)
- Modify: `docs/CHANGELOG.md` (R90 entry)
- Modify: `lib/l10n/app_localizations_*.dart` (gen-l10n 自动)
- Test: (无新 test, 由 守门员 check_orphan_arb_keys 验证)

**ARB keys 拆解**:
- 12 量表 × 5 类别 (name/shortDescription/instruction/items/options/severity) ≈ 200 keys
- 中心化入口 8 keys
- 1 个 crisis detection (PHQ-9 已有, 不重写)
- 合计 ~210 keys × 3 lang = 630 entries

**实操**:
1. 加 ARB entries (zh 优先, en/zh_Hant 跟 R88 一致, 简体优先)
2. `flutter pub get` 触发生成
3. 跑 `check_orphan_arb_keys` (0 orphan) + `check_arb_keys` (3 lang sync) + `check_strings_hardcoded` (0 hardcoded) + `check_zh_hant_consistency`
4. CHANGELOG R90 entry 跟 R89 同格式

**Final review (whole-branch)**:
- Dispatch verifier 看 164KB diff (spec/plan + 6 task 全)
- 期望: 0 Critical, 0-2 Important, 5-10 Minor
- 如有 Important → fix subagent 修
- Final review PASS 后 merge master

**1 commit**: `v0.30 round 90 (i18n): 210 ARB keys (12 量表 × 5 类别 + 中心化入口 8) + CHANGELOG R90`

---

### Task 7: Final whole-branch review + fix + merge + cleanup

**Files:** (review 后决定)
- 任何 fix subagent 修的 issue

**Step**:
1. Dispatch verifier (final review 整 sub-spec 6)
2. Dispatch fix subagent for Important findings (如有)
3. `git merge feat/assessment-center` to master
4. `git worktree remove --force .worktrees/feat-assessment-center`
5. `git worktree prune`
6. `git branch -d feat/assessment-center`
7. Save SDD workspace → `docs/superpowers/sdd-logs/round90-assessment-center/`
8. Master 跑全测 verify (期望 1509+ pass / 0 fail / 16 守门全绿)

**1 commit (fix round)**: `v0.30 round 90 (fix): final review 修 Important findings` (可能)

---

## Self-Review

- [x] Spec coverage: 12 量表 (Task 1+2) / 数据兼容 (Task 3) / 中心化入口 (Task 4) / 趋势图 (Task 5) / i18n (Task 6)
- [x] No placeholders (TODO 状态量表 #10, #12 显式标 unavailable)
- [x] Type consistency: scaleId = String (≤ 20 char, check_ins.type 限制)
- [x] TDD: red → green → commit per task
- [x] DRY: 1 AssessmentScale interface (R60) + 1 AssessmentDao (新) + 1 scale_registry (扩)
- [x] YAGNI: 不重写 R60 interface / 不重命名 check_ins / 不重写 assessment_runner UI
- [x] Fail-safe: CrisisSignal 走 PHQ-9 第 9 题, 其他量表不触发
- [x] 隐私: 0 网络 (量表题库全本地 const)

## 已知坑

1. **R60 AssessmentScale interface 已有** — 不重写,Task 1-2 只新增 const class 实现
2. **R78 ScaleTranslations 抽象已有** — Task 2 扩 8 量表方法,不要重命名 phq9* / gad7* (老 test 引用)
3. **check_ins.type 长度 20 char** — 'level2_depression' (17), 'level2_psychosis' (18), 'nsesss' (6), 都 < 20,OK
4. **12 量表 ARB keys 工作量大** — Task 6 拆 3 sub-task, zh 优先, en/zh_Hant 简体优先
5. **trend_assessment_chart 升级** — 现有单线 (R13) 重写 → 多线, 跑 R13 老 test 验证不破
6. **R89 AI flag 隐藏** — 跟本 sub-spec 无关, 跑守门员时确认 flag = false 仍过
7. **schemaVersion 不变** — Task 3 不加新表,只扩 check_in_dao.watchAssessments 的 type IN (10 个) = 0 schema change

## 跟其他模块的契约

- R60 AssessmentScale interface — 不动,Task 1-2 加 const class 实现
- R78 ScaleTranslations — Task 2 扩 8 量表方法
- R13 trend_assessment_chart — Task 5 升级多线
- R61c3 assessment reminder — 不动,本 sub-spec 不影响 reminder 逻辑
- R89 AI (flag 隐藏) — 不动,本 sub-spec 0 依赖 AI
- R88 PDF 导出 — 不动, v0.31+ 量表 PDF 是单独 sub-spec
- R84-88 CBT 思维记录 — 不动, mood_entries 表独立

## 不在 scope

- ❌ 量表 PDF 导出 (v0.31+)
- ❌ 量表跨用户分享 (法务)
- ❌ 量表题目全量汉化校审 (法务审核时)
- ❌ 12 量表临床建议 (recommendDoctorVisit 已有)
- ❌ 中心化入口搜索 / 收藏 / 排序 (v0.31+)
- ❌ 严重度区域背景 (v0.31+ fl_chart 扩展)
- ❌ 重写 R60 AssessmentScale / R78 ScaleTranslations
- ❌ 重命名 check_ins.type
- ❌ NSESSS / CRDPSS 内容 (TODO 占位)
- ❌ Sub-spec 7 日常追踪模块 (独立 sub-spec)
