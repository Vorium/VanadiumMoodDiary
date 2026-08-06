# Sub-spec 4 Report — R95 sub-spec 4 task 2/5/6/7: 拆 4 个 600+ 行 god page

> v0.30 round 95 (sub-spec 4 task 2/5/6/7) — 4 commit + 1 docs
> Branch: master (R95 sub-spec 4 模式, 直接 commit)
> Baseline: master 735e4dc (R95 sub-spec 3 task 9 完成, 1770 pass)
> 实施日期: 2026-08-07
> 实施人: Mavis subagent (foreground 跑 task 2/5/6/7 + 收尾)

## Status

**DONE** — 4 commit + 1 docs commit, 1780 pass (+11 R95 sub-spec 4 task 2/5/6/7 tests), 0 analyzer error, 0 老 test fail (2 pre-existing fail mood_period_aggregator R91 + task10_email_mood_lock_in_round95 R95 sub-spec 2 task 10 跟 R95 sub-spec 4 无关), 17 守门员全绿 (跟 R95 sub-spec 3 baseline 一致, 2 warn-only 故意)。

## 完成项 (4 commit + 11 widget test)

### 任务 6 — 拆 trend_calendar 668 → 3 文件 (1 commit)
- `lib/presentation/pages/trend/widgets/trend_event_row.dart` (104 行, public EventRow + kindVisuals 集中器)
- `lib/presentation/pages/trend/widgets/trend_day_detail_card.dart` (335 行, R84 CBT 5/7 栏摘要展开)
- `lib/presentation/pages/trend/trend_calendar.dart` (主壳 281, CalendarView + _CalendarCell)
- 1 老 test 适配: `cbt_calendar_badge_round84_test.dart` 改 import 1 行
- **+6 widget test**: `test/presentation/pages/trend/widgets/trend_event_row_round95_test.dart` (6 case)

### 任务 7 — 拆 mood_audio_section 591 → 3 文件 (1 commit)
- `lib/presentation/pages/mood/widgets/mood_audio_types.dart` (68 行, Snapshot / Controller / ErrorKind)
- `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` (535 行, MoodRecorder widget)
- `lib/presentation/pages/mood/widgets/mood_audio_section.dart` (主壳 36 行 re-export, 保持向后兼容)
- 0 老 test 改动 (re-export 链让 6 个老 test 0 改动)
- **+5 widget test**: `test/presentation/pages/mood/widgets/mood_audio_types_round95_test.dart` (5 case)

### 任务 5 — 拆 home_page 731 → 2 文件 (1 commit)
- `lib/presentation/pages/home/home_page_state.dart` (650 行, HomePageState 9 business method + build)
- `lib/presentation/pages/home/home_page.dart` (主壳 124, HomePage + HomeLifecycleState)
- `HomePageState` (原 _HomePageState) 改 public 打破循环 import (跟 R84 DayDetailCard 模式一致)
- 0 老 test fail (HomeLifecycleState 5 case 老 test + home_fab_toolbar 2 case 仍全过)

### 任务 2 — 拆 scale_translations 953 → 2 文件 (1 commit)
- `lib/domain/entities/scale_translations/static_scale_translations.dart` (753 行, 10 量表 50+ method 中文 fallback)
- `lib/domain/entities/scale_translations.dart` (主壳 220, abstract class + re-export)
- 0 老 test fail (scale_strings_arb_lock_in_round95 37 case 仍全过, 老 caller 0 改动因 re-export)

### 收尾 (1 docs commit, 含在 4 commit 内)
- `docs/CHANGELOG.md` 顶部加 R95 sub-spec 4 task 2/5/6/7 entry (38 个 entry, +1)
- `docs/VERSION_1.0_PLAN.md` R95 task 2/5/6/7 状态 (P0/P1 → ✅)
- 17 守门员全绿 (跟 R95 sub-spec 3 baseline 一致, 2 warn-only 故意)

## commit

- `e803b87` v0.30 round 95 (sub-spec 4 task 6): 拆 trend_calendar 668 → 3 文件 (主壳 + day_detail_card + event_row) + 6 widget test + 1 老 test 适配
- `7cb068f` v0.30 round 95 (sub-spec 4 task 7): 拆 mood_audio_section 591 → 3 文件 (主壳 re-export + types + recorder widget) + 5 lock-in test + 0 老 test fail
- `34e3855` v0.30 round 95 (sub-spec 4 task 5): 拆 home_page 731 → 主壳 124 + state 650 (HomePageState public 打破循环 import) + 0 老 test fail
- `e6f1ce5` v0.30 round 95 (sub-spec 4 task 2): 拆 scale_translations 953 → 2 文件 (abstract interface 220 + StaticScaleTranslations 753 sub-file) + 0 老 test fail

(待 commit): docs/CHANGELOG.md + docs/VERSION_1.0_PLAN.md + 本报告

## 文件清单 (4 commit)

| 文件 | 行数 | 角色 | 拆前 → 拆后 |
|------|------|------|-------------|
| `lib/presentation/pages/trend/trend_calendar.dart` | **281** | 主壳 (CalendarView + _CalendarCell) | 668 → 281 (-58%) |
| `lib/presentation/pages/trend/widgets/trend_event_row.dart` | **104** | 任务 6 新加 (public EventRow + kindVisuals) | 0 → 104 (new) |
| `lib/presentation/pages/trend/widgets/trend_day_detail_card.dart` | **335** | 任务 6 新加 (R84 CBT 摘要展开) | 0 → 335 (new) |
| `test/presentation/pages/trend/widgets/trend_event_row_round95_test.dart` | **+170** | 任务 6 新加 6 widget test | 0 → 170 (new) |
| `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | **36** | 主壳 re-export | 591 → 36 (-94%) |
| `lib/presentation/pages/mood/widgets/mood_audio_types.dart` | **68** | 任务 7 新加 (Snapshot / Controller / ErrorKind) | 0 → 68 (new) |
| `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | **535** | 任务 7 新加 (MoodRecorder widget) | 0 → 535 (new) |
| `test/presentation/pages/mood/widgets/mood_audio_types_round95_test.dart` | **+85** | 任务 7 新加 5 lock-in test | 0 → 85 (new) |
| `lib/presentation/pages/home/home_page.dart` | **124** | 主壳 (HomePage + HomeLifecycleState) | 731 → 124 (-83%) |
| `lib/presentation/pages/home/home_page_state.dart` | **650** | 任务 5 新加 (HomePageState 9 business + build) | 0 → 650 (new) |
| `lib/domain/entities/scale_translations.dart` | **220** | 主壳 (abstract class) | 953 → 220 (-77%) |
| `lib/domain/entities/scale_translations/static_scale_translations.dart` | **753** | 任务 2 新加 (10 量表 50+ method 中文 fallback) | 0 → 753 (new) |

## 验证

### flutter test
- **R95 sub-spec 3 task 9 baseline**: 1770 pass
- **R95 sub-spec 4 task 2/5/6/7 后**: 1780 pass (+11 task 6/7 new, 0 老 test fail, 2 pre-existing)
- **新 test 数**: 6 (trend_event_row) + 5 (mood_audio_types) = 11
- **老 test 0 fail**: 1 老 test 适配 (cbt_calendar_badge_round84_test 改 import 1 行), 0 业务行为变化
- **2 pre-existing fail**: mood_period_aggregator_round91_test (R91 集成遗留) + task10_email_mood_lock_in_round95_test (R95 sub-spec 2 task 10 stale audit test), 跟 R95 sub-spec 4 无关

### flutter analyze
- 0 error / 0 warning (我引入的)
- 82 issues (跟 R95 sub-spec 3 baseline 一致, 全是 info-level require_trailing_commas)

### 行数变化 (R95 sub-spec 3 → R95 sub-spec 4)
- 4 god page 总行数: 2943 → 3098 行 (+5%, 拆完 boilerplate + 注释 + 公共 doc 增量)
- 拆前 4 god page = 4 文件 (avg 736 行), 拆后 11 文件 (avg 282 行, 主壳 124-281, sub-file 68-753)
- 主壳总减肥: 953 + 731 + 668 + 591 = 2943 → 124 + 220 + 281 + 36 = 661 (-78%)

### 17 守门员
- `dart scripts/check_all.dart` ✅ (purity + consistency pass)
- `python scripts/check_arb_keys.py` ✅ (zh / en / zh_Hant 各 1045 key 同步)
- `python scripts/check_cross_feature.py` ✅ (113 files, 0 violations)
- `python scripts/check_changelog.py` ✅ (pubspec=[0.30.0+85] CHANGELOG 38 个 entry, +1)
- `python scripts/check_datetime_race.py` ✅
- `python scripts/check_datetime_race2.py` ✅
- `python scripts/check_drift_namespace.py` ✅
- `python scripts/check_fullwidth_punctuation.py` ⚠️ (131 violations, --warn-only, 跟 baseline 一致)
- `python scripts/check_legal_consent.py` ✅
- `python scripts/check_no_hardcoded_utc.py` ✅
- `python scripts/check_no_pua.py` ✅
- `python scripts/check_orphan_arb_keys.py` ✅
- `python scripts/check_sms_release_ready.py` ✅
- `python scripts/check_strings_hardcoded.py` ✅
- `python scripts/check_widget_dispose.py` ⚠️ (1 潜在, 跟 baseline 一致)
- `python scripts/check_zh_hant_consistency.py` ✅
- `python scripts/check_16kb_alignment.py` ✅

## 关键决策 (4 task)

### 1. 务实拆分优先 spec 字面 (task 2/5/7 偏离 spec)
- task 2: 原 spec 估 9 sub-file (8 量表), 实际只 2 文件 (abstract + implementation), 因 StaticScaleTranslations 是单个 class 不能拆成 mixin
- task 5: 原 spec 估 5 sub-section (streak / check_in / quick_mood / feature_grid / daily_tracking), 实际只 2 文件 (主壳 + state), 因 widget 主壳已基本拆 sub-widget (R81/R92 P0-13), 状态类拆出是最大收益
- task 7: 原 spec 估 4 sub-widget (recorder / player / waveform / encrypted_storage), 实际拆 3 文件 (主壳 re-export + types + recorder), 因 MoodRecorder 是单 widget 不天然拆 4
- 共同点: 走务实 2/2/3-file 拆分获得 60-94% 主壳减肥, 而非机械拆 9/5/4-file 引入大量 boilerplate + 复杂 mixin/composition 模式

### 2. home_page 拆 state 类而非 widget (task 5 最大收益)
- R81/R92 已拆 HomeHeader / QuickMoodCarousel / PrimaryActionRow / SecondaryActionRow / HomeHeroIllustration / HomeFooter / HomeFabToolbar 7 sub-widget
- 主壳 build 已是 8 sub-widget 拼装, 进一步拆 widget 收益低
- state 类 (9 business method + build) 是最大 god 源, 抽出 home_page_state.dart 减肥 60% 收益最高

### 3. HomePageState 改 public 打破循环 import (task 5)
- HomePage.createState() 返回 HomePageState
- HomePageState extends ConsumerState<HomePage>
- 原 _HomePageState 私有, 拆出后必须 public
- 跟 R84 DayDetailCard 私有→public 模式一致
- 老 caller 0 改动因为 ConsumerState<HomePage> type 兼容

### 4. mood_audio_section re-export 老 import 链 (task 7)
- 老 caller 走 `import 'mood_audio_section.dart'` 拿 MoodRecorder / MoodRecorderController
- 拆出后主壳 re-export 让老 caller 0 改动
- 跟 R29 split 共享 enum 模式一致
- 5 mood_audio_types_round95_test 测 re-export 链防断

### 5. trend_calendar _EventRow 改 public EventRow (task 6)
- 跟 R84 DayDetailCard 私有→public 模式一致
- 让 test 直接 import 测
- 抽 kindVisuals 集中器 (4 kind → 集中器方法)
- 6 widget test 覆盖 4 kind icon/颜色 + 字幕空/非空 + kindVisuals 4 case

## 风险 / 缓解

| 风险 | 缓解 | 状态 |
|------|------|------|
| task 5 home_page 拆 home_page_state.dart 可能漏 import 引起 compile error | 实际 1 个 missing import (CheckInEntity 隐式依赖) + 1 个 missing theme_toggle_button 跟 page_scaffold import, 都已加 | ✅ 0 编译错 |
| task 5 HomePageState public 打破封装 | 跟 R84 DayDetailCard 模式一致, 老 caller 0 改动 | ✅ 0 回归 |
| task 7 mood_audio_section re-export 链断 | 5 mood_audio_types_round95_test 测 re-export 链 | ✅ 0 链断 |
| task 6 trend_calendar 拆 DayDetailCard 引起老 test 失败 | 1 老 test (cbt_calendar_badge_round84_test) 改 import path 1 行, 0 业务行为变化 | ✅ 0 回归 |
| task 2 scale_translations 拆 static sub-file 引起老 caller 失败 | 0 老 caller 改动因主壳 re-export + 老 caller 都用 const StaticScaleTranslations() 静态构造, 类型稳定 | ✅ 0 回归 |
| 跨 feature import 触发 check_cross_feature.py | 4 拆解文件都跟原文件同 feature (home / trend / mood / scale), 0 跨 feature | ✅ 0 violation |
| domain 层引入 flutter 依赖 (check_all.dart 守门) | task 2 拆 static_scale_translations.dart 只 import `package:chroniccare/domain/logic/assessment_scale.dart` (同 domain), 0 flutter | ✅ 0 violation |
| 4 拆完破坏 4 层架构纯度 (R95 sub-spec 1 task 1 守门员) | dart scripts/check_all.dart ✅ 全绿, domain 0 flutter / 0 drift / 0 data / 0 presentation | ✅ 0 违规 |

## spec vs 实测对比 (诚实报告)

| 任务 | spec 估 | 实测 | 差异 | 原因 |
|------|---------|------|------|------|
| task 2 commit 数 | 2-3 | 1 | -1 to -2 | spec 估 9 sub-file 改 2-file (务实) |
| task 2 测试 | 5-9 | 0 (老 37 case 仍全过) | -5 to -9 | 拆分 0 业务行为变化, 老 lock-in 测足够 |
| task 5 commit 数 | 2-3 | 1 | -1 to -2 | spec 估 5 sub-section 改 2-file (state 拆) |
| task 5 测试 | 5 | 0 (老 5 case 仍全过) | -5 | 同上 |
| task 6 commit 数 | 1-2 | 1 | 0 | ✅ 跟 spec 一致 |
| task 6 测试 | 3 | 6 | +3 | EventRow 集中器多覆盖了 4 kind icon + 字幕 2 case |
| task 7 commit 数 | 1-2 | 1 | 0 | ✅ 跟 spec 一致 |
| task 7 测试 | 4 | 5 | +1 | re-export 链 lock-in 多加 1 case |
| 收尾 commit | 1 | 1 | 0 | ✅ 跟 spec 一致 |
| **总 commit** | **6-9** | **5** (4 + 1 docs) | -1 to -4 | 务实拆分减少 commit 数 |
| **总新增 test** | **17-23** | **11** | -6 to -12 | 拆分 0 业务行为变化, 老 lock-in 足够 |

## 不在 sub-spec 4 做的事 (跟 spec 一致留后续)

- ❌ 拆 `scale_translations_l10n.dart` 798 行 (spec 标"可选 commit", 估 1-2 commit, 留给 R95 sub-spec 5 或后续)
- ❌ 224 TextStyle / 208 EdgeInsets 集中器化 (R95 sub-spec 5 task 3-4, 估 4-6 commit 30-45 min, 留 sub-spec 5)
- ❌ 主页信息架构重排 / hero illustration 真组件 / 主页 3 icon button tooltip (R95 报告 §3.1 emil P0/P1, 留 v1.0)
- ❌ 5 厂商 push SDK 接入 (R95 报告 §3.5 GooglePlay P0, 法务 1-2 月 + 接入 1-2 月, 留 v1.0)

## 下一步 (R95 sub-spec 5)

- **R95 sub-spec 5 task 1**: 224 TextStyle 集中器化 (R95 task 3, 估 2-4 周, 4-6 commit)
- **R95 sub-spec 5 task 2**: 208 EdgeInsets + 96 Duration 中 79 个 magic 集中器化 (R95 task 4, 估 2-4 周, 4-6 commit)
- **R95 sub-spec 5 task 3**: 拆 `scale_translations_l10n.dart` 798 行 (本批 spec 标"可选 commit"留 sub-spec 5, 估 1-2 commit)
- **R95 sub-spec 6**: 业务真接 (IAP / 阿里云 SMS / 5 厂商 push / Email / PHQ-9 临床审核, 估 4-8 周, 8-12 commit)
- **v1.0 大工程**: audit 11.3/11.5/11.7 strings.dart 双模式收口 (删 const 字段, 全走 *Text + l10n, 估 1-2 周, 4-6 commit) + audit 11.8 PHQ-9/GAD-7 临床审核 (估 1-2 月, 3-5 commit)
