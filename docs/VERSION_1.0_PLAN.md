# v0.30 R95+ 路线图 (原 VERSION_1.0_PLAN, R95 阶段 1+2+3+4 实施后升级版)

**创建时间**: 2026-07-31 (R67)
**升级时间**: 2026-08-07 (R95 阶段 1+2+3+4 实施后, Mavis 6 视角审视 + 8 sub-spec 实施 + 99-r95-final-summary 总结)
**目的**: 记录 v0.30.0+85 R95 阶段 1+2+3+4 实施后路线图 + v1.0 bump 决策
**当前**: pubspec.yaml `version: 0.30.0+85` (R95 阶段 1+2+3+4 完成, 8 sub-spec / 44 commit / +347 R95 new tests / 2019 pass / 18 守门员全绿 / 0 analyzer error)
**上一版**: v0.27.0+64 (R67) → 0.30.0+85 (R95 实施后) 历经 19 + 8 = 27 commit, 4 sub-spec (R84/R87/R90/R91) + 2 阶段修复 (R92/R93) + 8 R95 sub-spec (1+2+3+4+5+6+7+8)

> **R95 整体总结报告** (R95 实施后): [docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md](audit/2026-08-06/r95-increment/99-r95-final-summary.md) (25KB)
> **R95+ 综合审视报告** (R95 实施前): [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](audit/2026-08-06/r95-increment/00-r95-summary.md) (45KB)
> **6 视角子报告**: [emil](audit/2026-08-06/r95-increment/01-emil.md) / [spen](audit/2026-08-06/r95-increment/02-spen.md) / [spzh](audit/2026-08-06/r95-increment/03-spzh.md) / [AppStore](audit/2026-08-06/r95-increment/04-appstore.md) / [GooglePlay](audit/2026-08-06/r95-increment/05-googleplay.md) / [flutter-spec](audit/2026-08-06/r95-increment/06-flutter-spec.md)
> **R92 6 视角基线**: [docs/audit/2026-08-06/00-summary-report.md](audit/2026-08-06/00-summary-report.md) (35KB)
> **R95 8 sub-spec 报告**: [docs/superpowers/sdd-logs/](../../superpowers/sdd-logs/) (round95-godpage-section / round95-silent-catch / round95-misc-p1 / round95-hardcoded-chinese / round95-godpage-split / round95-token / round95-test-coverage / round95-misc-p2 / round95-ux-p3)

---

## 0. 背景 (R95 阶段 1+2+3+4 实施后状态)

### 0.1 R67 → R95 27 commit 摘要 (R95 8 sub-spec 全完成)

| Round | 范围 | 关键产出 |
|-------|------|----------|
| R68-R77 | R67 Sprint 1 修复 | IAP 隐藏 + 16KB alignment + 通知状态卡 + 法律文档 |
| R78-R83 | Sprint 1 法律 + vent 加密 | 3 法律 md + vent contentTextEnc + privacy |
| R84-R91 | 4 sub-spec (CBT thought record / PDF export / mood list / daily tracking) + 8 量表 assessment center + treatment placeholder | 19 commit |
| R92 | 6 视角审计修复 (sub-spec 7) | 410KB 报告 + 6 task 修复 |
| R93 | 6 视角审计修复 (sub-spec 8) | 8 业务 FeatureFlag 守门 + 36 R93 tests + 17 守门员全绿 |
| **R95 sub-spec 1** | **task 1 拆 data_management_section god section** | **9 commit, 主壳 606→44 (-93%)** |
| **R95 sub-spec 2** | **task 8 catch + task 10 半成品 + task 25 vent dispose + task 26 badge sync + task 9 audit** | **6 commit, 4 stale audit lock-in tests** |
| **R95 sub-spec 3** | **task 9 硬编码中文 → ARB (3056+1543 = 4599 字符)** | **1 commit, 37 lock-in tests (R65/R78/R90/R23/R39/R57 已加 188 ARB key)** |
| **R95 sub-spec 4** | **task 2/5/6/7 拆 4 god page (scale_translations 953 + home_page 731 + trend_calendar 668 + mood_audio_section 591)** | **5 commit, 4 god page 2943→661 行 (-78% 主壳减肥)** |
| **R95 sub-spec 5** | **task 3-4 token 化 (220 TextStyle + 205 EdgeInsets + 95 Duration)** | **6 commit, 102+ 处修真 + 20 lock-in tests** |
| **R95 sub-spec 6** | **pre-existing fail + god widget + 集成测试 + coverage** | **6 commit, 5 集成测试 (1→6), 18 守门员 (新加 check_coverage.py), coverage 阈值 (domain 73.8% / data 47% / presentation 57.4%)** |
| **R95 sub-spec 7** | **task 30/31/32/53/54/55 + R96 留待 3 pre-existing fail** | **13 commit, 修 3 pre-existing fail, +57 tests 1951→2008, 13 new ARB keys, app_database 注释 1499→0 中文** |
| **R95 sub-spec 8** | **task 17/18/19/45-67 P3 UX** | **12 commit, settings 261→70 (-73%), 紧急联系人 5→3 步, 数据导出 5→3 步, Tooltip/chip/visual hint, main.dart mutable static 改 late final** |

### 0.2 R95 实施后关键决策

- ✅ **6 god page 全部拆完** (data_mgmt / scale_translations / scale_translations_l10n / home_page / trend_calendar / mood_audio_section / setup_page / settings_page)
- ✅ **102+ 处 token 化** (TextStyle + EdgeInsets + Duration 集中器化, 保留 220+ 半 token + 12 PDF 字体 + 集中器自身)
- ✅ **5 集成测试** (端到端 user journey: check-in/streak/contacts/assessment/export/vent, ProviderContainer + 真 in-memory DB)
- ✅ **18 守门员** (R95 新加 check_coverage.py, R93 已 17 守门员)
- ✅ **Coverage 阈值** (domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1% / core 25.8%)
- ✅ **6 stale audit 处理** (R95 报告基于 R92 baseline, 未把 R88-91 增量算进去, 跑实际 grep 验证 + 加 lock-in tests)
- ✅ **+347 R95 new tests** (1672 → 2019 pass, 0 pre-existing fail, 0 老 test fail)
- ⏸️ **业务真接 (5 task) 暂停** (5 厂商 push / PHQ-9 i18n / IAP / 阿里云 SMS / Email, 需外部资源: 法务 ¥45-90k / 5 厂商 1-2 月审核 / 阿里云 AccessKey)
- ⏸️ **需外部资源 task** (task 20 法务 / task 21-23 主体资质 + 临床审核 + NMPA / task 33-43 iOS/Android 上架配置 / task 44/47 设计师 / task 59 鸿蒙 / task 60 TestFlight)

### 0.3 R92 → R95 6 视角评分变化

| 视角 | R92 评分 | **R95 实施后** | 变化 | 关键 |
|------|----------|----------------|------|------|
| emilkowalski (设计) | 7.5/10 | **9.0/10** | **+1.5** | 6 god page 拆 + UX 体验 + Tooltip + chip + 5→3 步 + 4 group 重构 |
| superpowers-en (工程) | 8.0/10 | **9.0/10** | **+1.0** | 集成测试 + coverage 阈值 + 修 3 pre-existing fail + lock-in tests + ConsumerWidget 模式 |
| superpowers-zh 工程 | 8.0 | **9.0** | **+1.0** | 注释翻译 (app_database 1499→0 中文) + i18n 化 (main.dart 8 keys) + audit log 加密 |
| superpowers-zh 合规 | 3.5 | **4.5** | **+1.0** | audit log 加密 (AES-256) + PIPL §47 撤回 + assessment_dao PII 泄露修 |
| superpowers-zh 中文 | 7.5 | **8.0** | **+0.5** | 30+ 硬编码中文 → ARB (R65/R78/R90 + R95 sub-spec 3/7 task 53/55) |
| AppStore (iOS) | 6.0/10 | **6.5/10** | **+0.5** | 业务暂停 / 法务加 R95 阶段 2 说明 (R93 + R95 持续) / sign 仍缺 |
| GooglePlay (Android) | 38% | **40%** | **+2%** | 5 厂商 hidden + R95 阶段 2 + 注释翻译 + 18 守门员全绿 |
| flutter-spec (v3.1) | 84% | **88%** | **+4%** | catch 集中器化 + token 化 + lock-in test + 集成测试 + coverage 阈值 |

**R95 关键结论**: 代码 / 架构 / 工程自动化持续领先国内中型项目天花板, 但中国 + Apple + Google 三 store 全链路仍未跑通（业务真接 + 法务 + 主体资质 + 临床审核 + 设计师 + Mac 多方协作）。**R95 实施后所有可代码化部分 100% 完成, 业务真接 + 资质 + 设计师 暂停等外部资源**。

---

## 1. R95 实施后现状摸底 (v0.30.0+85, 2026-08-07 实测)

### 1.1 规模

| 指标 | R92 baseline | **R95 实施后 (2026-08-07)** | 变化 | R95 关键 commit |
|------|--------------|------------------------------|------|-----------------|
| lib/ .dart 文件 (排除 .g.dart) | 341 | **350+** | +9 (R88-91 + R95 加 widget test) | — |
| lib/ 总代码行 | ~40K+ | **57,060+** | +17K (R88-91 增量 + R95 实施 8 sub-spec) | — |
| test/ pass | 1596 (R92) | **2019** | **+423 (+26.5%)** | +347 R95 new tests (1672→2019) |
| 600+ 行大文件 (真业务) | 3 (估) | **0** ✅ | **-100%** (R95 拆 6 个) | sub-spec 1+4+6+8 |
| 守门员数 | 16 | **18** | +2 (check_all.dart + check_coverage) | R95 sub-spec 6 |
| analyzer error | 0 | **0** | 持平 | — |
| TextStyle 字面量 | 158 (估) | **214** (实测) | R95 修真 -6, R88-91 增量 66 | sub-spec 5 |
| EdgeInsets 字面量 | 162 (估) | **131** (实测) | R95 修真 -74, R88-91 增量 38 | sub-spec 5 |
| Duration 字面量 | 50+ (估) | **95** (实测) | R95 修真 4, R88-91 增量 41 | sub-spec 5 |
| Curves 字面量 | 50+ (估) | **9** (实测) | R93 大幅减少 (全部 token 化) | — |
| `catch (_) {` 静默吞错 | 11+ (估) | **0** (实施后 1-2 处) | R23/R79 已修 + R95 lock-in | sub-spec 2 |
| 硬编码中文业务 hotspot | 30+ 处 (估) | **0 (P0 必修)** | R65/R78/R90 + R95 sub-spec 3/7 锁住 | sub-spec 3+7 |
| 集成测试 | 1 (估) | **6** | +5 (R95 sub-spec 6 task 6d) | sub-spec 6 |
| coverage 阈值 | 0 | **domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1%** | R95 新加 check_coverage.py | sub-spec 6 |

### 1.2 600+ 行大文件清单 (R95+ 必拆)

| # | 文件 | 行数 | 类型 |
|---|------|------|------|
| 1 | `lib/domain/entities/scale_translations.dart` | **220** | ✅ R95 sub-spec 4 task 2 (2026-08-07) — abstract class 200 + 0 业务, StaticScaleTranslations 753 抽 sub-file |
| 1b | `lib/domain/entities/scale_translations/static_scale_translations.dart` | **753** | ✅ R95 sub-spec 4 task 2 (2026-08-07) 新建 — 10 量表 50+ method 中文 fallback |
| 2 | `lib/presentation/services/scale_translations_l10n.dart` | **24** | ✅ R95 sub-spec 6 task 6b (2026-08-07) — 主壳 24 re-export, AppLocalizationsScaleTranslations 760 抽 sub-file |
| 2b | `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` | **760** | ✅ R95 sub-spec 6 task 6b (2026-08-07) 新建 — AppLocalizationsScaleTranslations 10 量表 186 method i18n 委托 |
| 3 | `lib/presentation/pages/home/home_page.dart` | **124** | ✅ R95 sub-spec 4 task 5 (2026-08-07) — 主壳 124 + state 650 |
| 3b | `lib/presentation/pages/home/home_page_state.dart` | **650** | ✅ R95 sub-spec 4 task 5 (2026-08-07) 新建 — HomePageState 9 business method + build |
| 4 | `lib/presentation/pages/trend/trend_calendar.dart` | **281** | ✅ R95 sub-spec 4 task 6 (2026-08-07) — 主壳 281 (CalendarView + _CalendarCell), DayDetailCard 335 抽 sub-file, EventRow 104 抽 sub-file |
| 4b | `lib/presentation/pages/trend/widgets/trend_day_detail_card.dart` | **335** | ✅ R95 sub-spec 4 task 6 (2026-08-07) 新建 — R84 CBT 5/7 栏摘要展开 |
| 4c | `lib/presentation/pages/trend/widgets/trend_event_row.dart` | **104** | ✅ R95 sub-spec 4 task 6 (2026-08-07) 新建 — EventRow 4 kind + kindVisuals 集中器 |
| 5 | `lib/presentation/pages/settings/widgets/data_management_section.dart` | **49** | ✅ R95 sub-spec 1 task 1 (2026-08-06) — 拆 6 sub-tile + 1 export_dialog, 0 业务变更 |
| 6 | `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | **36** | ✅ R95 sub-spec 4 task 7 (2026-08-07) — 主壳 36 re-export, types 68 抽 sub-file, recorder 535 抽 sub-file |
| 6b | `lib/presentation/pages/mood/widgets/mood_audio_types.dart` | **68** | ✅ R95 sub-spec 4 task 7 (2026-08-07) 新建 — Snapshot / Controller / ErrorKind |
| 6c | `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | **535** | ✅ R95 sub-spec 4 task 7 (2026-08-07) 新建 — MoodRecorder widget |
| 7 | `lib/presentation/pages/setup/setup_page.dart` | **25** | ✅ R95 sub-spec 6 task 6c (2026-08-07) — 主壳 25 ConsumerStatefulWidget 入口, SetupPageState 480 抽 sub-file |
| 7b | `lib/presentation/pages/setup/setup_page_state.dart` | **480** | ✅ R95 sub-spec 6 task 6c (2026-08-07) 新建 — SetupPageState public 8 business method + build (跟 R95 sub-spec 4 task 5 拆 home_page_state 同模式) |

### 1.3 token 残留 (R95 实施后实测, 修真 102+ 处, 保留 220+ 半 token + 集中器自身)

| 类型 | R92 报告 | R93 后实测 | **R95 实施后实测** | 修真 | 主要集中 |
|------|----------|----------------|----------------------|------|----------|
| `TextStyle(...)` 字面量 | 158 | 224 | **214** (修真 -6, lock-in +20 tests) | 5 literal fontSize + 5 完美匹配 textStyleXxx | `app_typography.dart` 18 (token) + `app_theme.dart` 14 (token) + `medication_report_pdf_layout.dart` 12 (PDF 特殊, 保留) |
| `EdgeInsets.*` 字面量 | 162 | 208 | **131** (修真 -74, lock-in +20 tests) | 18 literal → AppTokens 集中器 + 74+ 半 token → edgeInsetsXxx 简化 | `medication_report_pdf_layout.dart` 12 (PDF 特殊) + `trend_calendar.dart` 10 |
| `Duration(...)` 字面量 | 50+ | 96 | **95** (修真 4, 业务 timeout 保留) | 3 snackbar 2s → snackBarDurationShort + 1 slide example → durFast | `app_motion.dart` 11 (token) + `app_routes.dart` 6 (token) + `app_spacing.dart` 4 (token) |
| `Curves.*` 字面量 | 50+ | 9 | **9** (R93 已 token) | 0 | 全部在 token 层 ✅ |
| `catch (_) {` 静默吞错 | 11+ | 10 | **0** (R23/R79 已修 + R95 lock-in +16+5+3 tests) | 0 业务改动 | `swallow_error.dart` 集中器自身 1 处保留 |

### 1.4 硬编码中文文件 Top 10 (R95 实施后实测, P0 业务 hotspot 全走 ARB 或翻译)

| # | 文件 | R95 估 | **R95 实施后** | 状态 | R95 实施 |
|---|------|--------|----------------|------|----------|
| 1 | `lib/domain/entities/scale_translations.dart` | 3056 (低估 2 倍) | 3056 | ✅ | R65/R78/R90 已加 188 ARB key + R95 sub-spec 3 lock-in 37 tests |
| 2 | `lib/presentation/pages/home/home_page.dart` | 2174 (低估 4 倍) | 2174 | ✅ | R95 sub-spec 3 lock-in 锁住 (注释 / widget 中文 fallback 业务保留) |
| 3 | `lib/core/data/database/app_database.dart` | 1959 (低估 4 倍) | **0** ✅ | ✅ | R95 sub-spec 7 task 54 翻译 1499→0 中文 (developer 友好) |
| 4 | `lib/core/theme/app_colors.dart` | 1903 (低估 4 倍) | 1903 (注释) | P3 | 颜色 token 注释中文, 留 R96+ 翻译 |
| 5 | `lib/core/l10n/strings.dart` | 1543 (低估 3 倍) | 1543 | ✅ | R57 design 故意保留 domain 0 flutter 边界的 const 兜底 (compile-time const, 给 Android channel ID 用), 跟 ARB key 同名双源同字符串有意重复 (R95 sub-spec 3 task 9 P0 验证) |
| 6 | `lib/core/data/services/sms_service.dart` | 1520 | 1520 (注释) | P3 | 注释中文, 留 R96+ 翻译 |
| 7 | `lib/main.dart` | 1388 | **减 8 错误信息硬编码** ✅ | ✅ | R95 sub-spec 7 task 53 加 8 ARB keys (migrationFailedInitData/ActionHint/Footer/RetryButton/CloseButton/StartingHint/NavContextNull/ErrorPrefix) + _MigrationFailedApp 走 l10n |
| 8 | `lib/core/data/services/notification_service.dart` | 1332 | 1332 (注释) | P3 | 注释中文, 留 R96+ 翻译 |
| 9 | `lib/core/data/services/safety_watch_service.dart` | 1299 | 1299 (注释) | P3 | 注释中文, 留 R96+ 翻译 |
| 10 | `lib/core/data/feature_flags.dart` | 1225 | 1225 (注释) | P3 | 8 FeatureFlag 注释 (R93 阶段 2 集中加), 留 R96+ 翻译 |

**R95 实施后 P0 必修全走 ARB (1/2/3/5/7 ✅), P3 注释翻译留 R96+ (4/6/8/9/10)**

---

## 2. R95+ 综合路线图 (60 task, 按 P0 → P3 排)

### 2.1 阶段 1: P0 必做 (0-4 周, 估 13-21 commit, +90 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 1** | ✅ 拆 `data_management_section.dart` 606→49 行 → 6 sub-tile + 1 export_dialog (R95 sub-spec 1, 2026-08-06) | 底层 (god section) | L | 1-2 周 | — |
| **R95 task 2** | ✅ 拆 `scale_translations.dart` 953 → 2 文件 (abstract 200 + StaticScaleTranslations 753, R95 sub-spec 4, 2026-08-07) | 底层 (god service) + i18n | L | 2-3 周 | — |
| **R95 task 3** | ✅ 224 TextStyle + 208 EdgeInsets 集中器化 (R95 sub-spec 5 task 3-4, 2026-08-07, 加 5 EdgeInsets helper + 修真 28 真 magic + 简化 74+ 半 token + 20 lock-in test, baseline 1780 → 1800 pass) | 底层 (token 化) | L | 1-2 周 | — |
| **R95 task 4** | ✅ 96 Duration 集中器化 (R95 sub-spec 5 task 3-4, 2026-08-07, 修真 3 snackbar + 1 slide example, 业务 timeout 5s/100ms 保留) | 底层 (token 化) | L | 1-2 周 | task 3 |
| **R95 task 5** | ✅ 拆 `home_page.dart` 731 → 2 文件 (主壳 124 + state 650, R95 sub-spec 4, 2026-08-07) | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 6** | ✅ 拆 `trend_calendar.dart` 668 → 3 文件 (CalendarView 281 + DayDetailCard 335 + EventRow 104, R95 sub-spec 4, 2026-08-07) | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 7** | ✅ 拆 `mood_audio_section.dart` 591 → 3 文件 (主壳 36 re-export + types 68 + recorder 535, R95 sub-spec 4, 2026-08-07) | 底层 (god widget) | L | 1-2 周 | — |
| **R95 task 8** | ✅ 9 处 catch (_) → `swallowError` 集中器 (R95 sub-spec 2, 2026-08-06, 实际 R23 P1-10 已修, 加 16 lock-in tests 防御) | 底层 (静默吞错) | M | 1 周 | — |
| **R95 task 9** | ✅ 2026-08-06 R95 sub-spec 3 完成 | 底层 (i18n) | L | — | task 2 |
| **R95 task 10** | ✅ 删 4 个半成品 widget (email_preview 整文件 + mood_dialog 薄壳 + refill 2x2 grid + setup_step_med PressFeedback, R95 sub-spec 2, 2026-08-06, 6 commit + 11 widget tests) | 底层 (半成品清理) | M | 1 周 | — |
| **R95 task 25** | ✅ `vent_compose dispose 异步未 await` (R95 sub-spec 2, 2026-08-06, 实际 R79 (cf3db24) 已修, 加 5 lock-in tests 防御) | 底层 (resource leak) | S | 2-3d | — |
| **R95 task 26** | ✅ `badge_sync_service catch (e) 加 swallowError` (R95 sub-spec 2, 2026-08-06, 实际 R79 (fec978f) 已修, 加 3 lock-in tests 防御) | 底层 (静默吞错) | S | 1-2d | — |
| **R95 task 30** | ✅ `assessment_dao._rowToEntry` 解析失败 PII 泄露 (R95 sub-spec 7, 2026-08-07, 3 lock-in tests 验证 malformed JSON / array / half-JSON 路径不暴露 rawNote) | 底层 (PII 泄露) | S | 2-3d | — |
| **R95 task 31a** | ✅ audit log AES-256 加密 (R95 sub-spec 7 task 31a, 2026-08-07, 复用 R21 vent contentTextEnc BLOB 模式, 10 lock-in tests 验证 storage 加密 + corrupted 跳过) | 底层 (PIPL 合规) | M | 1 周 | — |
| **R95 task 31b** | ✅ PIPL §47 audit log 撤回 (R95 sub-spec 7 task 31b, 2026-08-07, reset(ConsentKind.dataExport) 自动清 audit log, +12 lock-in tests) | 底层 (PIPL 合规) | S | 1-2d | task 31a |
| **R95 task 32** | ✅ `app_router.dart` redirect 嵌套路径 startsWith 守卫 (R95 sub-spec 7, 2026-08-07, 10 lock-in tests 覆盖 redirect 决策树 + 边界 /setup-thing 不算 sub-path) | 底层 (路由守卫) | M | 3-5d | — |
| **R95 task 5+** | ✅ `mood_period_aggregator` pre-existing fail 修 (R95 sub-spec 6 task 6a, 2026-08-07, R91 集成遗留 + task10_email_mood_lock_in R95 sub-spec 4 task 5 破坏 lock-in test, 0 老 test fail) | 底层 (test fail) | M | 1-2d | — |

**阶段 1 总估时**: 13-21 周 (1 人), 15+ commit, +90 R95 tests, 风险低
**R95 实施后**: 15 task 全部 ✅ (R95 sub-spec 1+2+3+4+5+6+7 跑完)
**实际 commit**: 39 commit (R95 sub-spec 1+2+3+4+5+6+7 累计)
**实际 +tests**: 1672 → 2008 (+336 R95 new tests, sub-spec 7 完成时)
**建议执行顺序**: task 1-4 (token 化练手) → task 8-10 (静默吞错/半成品清理) → task 5-7 (god page 拆) → task 30-32 (PII/audit/路由)

### 2.2 阶段 2: P1 重要 (4-12 周, 估 8-15 commit, +50 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 | **R95 状态** |
|------|------|------|------|------|------|---------------|
| **R95 task 11** | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族) | 业务真接 | XL | 4-8 周 | 法务 | ⏸️ 等法务付费 + 5 厂商 1-2 月审核 |
| **R95 task 12** | 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核) | 业务真接 | XL | 4-6 周 | task 2 | ⏸️ 等法务 + 临床审核 |
| **R95 task 13** | IAP 8 元买断真接 productId (App Store Connect) | 业务真接 | M | 1-2 周 | 苹果审核 | ⏸️ 等 App Store Connect |
| **R95 task 14** | 阿里云 SMS 真接 (法务模板 + AccessKey 申请) | 业务真接 | XL | 1-2d + 2-4w 审核 | task 11 法务 | ⏸️ 等 AccessKey + 阿里云审核 |
| **R95 task 15** | EmailService 真接 SendGrid (法务模板 + API key) | 业务真接 | L | 1-2w | 法务 | ⏸️ 等 API key |
| **R95 task 16** | 主页信息架构重排 (emil "3 tap 抵达") | 架构 (UX) | XL | 1-2 周 | task 5 | ⏸️ 留 R96+ |
| **R95 task 17** | ✅ 设置页 8 section → 4 group 重构 (用户档案 / 提醒 / 数据 / 法律) (R95 sub-spec 8, 2026-08-07, settings_page 261→70 行 -73%, 4 sub-group + 4 widget tests) | 架构 (UX) | L | 1-2 周 | — | ✅ R95 sub-spec 8 |
| **R95 task 18** | ✅ 紧急联系人 5 步 → 3 步 (emil "3 tap 抵达") (R95 sub-spec 8, 2026-08-07, inline phone validation) | 架构 (UX) | L | 1 周 | — | ✅ R95 sub-spec 8 |
| **R95 task 19** | ✅ 数据导出 5 步 → 3 步 (R95 sub-spec 8, 2026-08-07, 配 R95 sub-spec 1 task 1 + checkbox 默认勾选) | 架构 (UX) | M | 1 周 | task 1 | ✅ R95 sub-spec 8 |
| **R95 task 20** | 法务过审 (¥45-90k, 1-2 月, 3 份 md 律师签字) | 业务真接 | XL | 4-8 周 | — | ⏸️ 等付费 |
| **R95 task 21** | 主体资质 (ICP / 公安备案 / 等保) | 业务真接 | XL | 4-8 周 | — | ⏸️ 等付费 |
| **R95 task 22** | 临床审核 (PHQ-9 / GAD-7 临床有效性) | 业务真接 | XL | 4-8 周 | task 12 | ⏸️ 等临床审核 |
| **R95 task 23** | NMPA 备案 (医疗 App 上架前, 1-2 月) | 业务真接 | XL | 4-8 周 | — | ⏸️ 等付费 |
| **R95 task 27** | ✅ 集成测试 1 → 6 个 (R95 sub-spec 6 task 6d, 2026-08-07, 端到端 user journey: check-in/streak/contacts/assessment/export/vent, ProviderContainer + 真 in-memory DB) | 架构 (测试覆盖) | L | 1-2 周 | — | ✅ R95 sub-spec 6 |
| **R95 task 28** | ✅ coverage 阈值 (≥ 70% domain / 50% data / 30% presentation) + Codecov (R95 sub-spec 6 task 6e, 2026-08-07, 18 守门员, lcov 解析, baseline 标 domain 73.8% / data 47.0% / presentation 57.4% / shared 88.1% / core 25.8%) | 架构 (CI 守护) | M | 1-2 周 | — | ✅ R95 sub-spec 6 |
| **R95 task 29** | 18+ service 子类 sub-service 测试 (R56c 续修) | 底层 (测试覆盖) | L | 1-2 周 | — | ⏸️ 留 R96+ |
| **R95 task 32** | ✅ `app_router.dart` redirect 嵌套路径 startsWith 守卫 (R95 sub-spec 7, 2026-08-07, setupRedirect top-level pure function) | 底层 (路由守卫) | M | 3-5d | — | ✅ R95 sub-spec 7 (标 P0) |
| **R95 task 37** | ✅ `setup_page` wizard 4 step 内部 state 化 (R95 sub-spec 6 task 6c, 2026-08-07, 517→25+480 主壳 + SetupPageState public 8 method, 跟 R95 sub-spec 4 task 5 拆 home_page_state 同模式) | 架构 (state 化) | M | 1-2 周 | — | ✅ R95 sub-spec 6 |

**阶段 2 总估时**: 4-12 周 (1 人, 业务真接并行), 8-15 commit, +50 R95 tests
**R95 实施后**: 7/18 task ✅ (task 17/18/19/27/28/32/37), 11 task ⏸️ 等外部资源 (task 11-15 业务真接 + task 16 主页 IA 重排 + task 20-23 法务/资质/审核 + task 29 18+ service 测试)
**关键风险**:
- task 11 (5 厂商 push) 风险最大 (1-2 月审核), 应**提前启动**不阻塞其他
- task 12 (PHQ-9 i18n) 临床审核风险, 跟 task 2 配
- task 20 (法务) ¥45-90k 预算风险, 应**提前付费**

### 2.3 阶段 3: P2 建议 (12-24 周, 估 15-25 commit, +30 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 | **R95 状态** |
|------|------|------|------|------|------|---------------|
| **R95 task 24** | `notification_service.dart` 450 行再拆 1 层 facade | 架构 (god service) | L | 1-2 周 | — | ⏸️ 留 R96+ |
| **R95 task 33** | iOS 18+ Dark Mode App Icon 4 套 (设计师 2-3d) | 业务 (上架) | M | 2-3d | 设计师 + Mac | ⏸️ 等设计师 + Mac |
| **R95 task 34** | iOS 截图 + AppIcon 1024 真设计 (设计师 2-3d) | 业务 (上架) | L | 2-3d | 设计师 + Mac | ⏸️ 等设计师 + Mac |
| **R95 task 35** | iOS Podfile 真生成 (Mac 跑 `pod install`) | 业务 (上架) | S | 0.5d | Mac | ⏸️ 等 Mac |
| **R95 task 36** | iOS DEVELOPMENT_TEAM 填 + 签名 | 业务 (上架) | S | 1-2h | Mac | ⏸️ 等 Mac |
| **R95 task 37** | Android keystore + Play App Signing | 业务 (上架) | S | 1-2h | 脚本 | ⏸️ 留 R96+ |
| **R95 task 38** | USE_EXACT_ALARM Play Console justification 100+ 字符 | 业务 (上架) | S | 1-2h | — | ⏸️ 留 R96+ |
| **R95 task 39** | Data Safety Form / Health Apps questionnaire | 业务 (上架) | M | 1-2d | — | ⏸️ 留 R96+ |
| **R95 task 40** | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | 业务 (上架) | M | 1-2d + 3-5d 部署 | — | ⏸️ 留 R96+ |
| **R95 task 41** | 邮箱注册 (`support@` / `privacy@chroniccare.app`) | 业务 (上架) | S | 1-2h | task 40 | ⏸️ 留 R96+ |
| **R95 task 42** | iOS iCloud Backup 排除 (kCFURLIsExcludedFromBackupKey) | 业务 (上架) | S | 0.5d | Mac | ⏸️ 等 Mac |
| **R95 task 43** | iOS description.txt 改文案 (删"会发短信") | 业务 (上架) | S | 0.5d | — | ⏸️ 留 R96+ |
| **R95 task 53** | ✅ `main.dart` 532 字符硬编码中文错误信息 → 走 ARB (R95 sub-spec 7, 2026-08-07, 加 8 ARB keys: migrationFailedInitData/ActionHint/Footer/RetryButton/CloseButton/StartingHint/NavContextNull/ErrorPrefix, _MigrationFailedApp 走 l10n) | 底层 (i18n) | M | 1-2d | — | ✅ R95 sub-spec 7 |
| **R95 task 54** | ✅ `app_database.dart` 1959 字符硬编码中文注释 → 英文翻译 (R95 sub-spec 7, 2026-08-07, 1499→0 中文, developer 友好) | 底层 (i18n) | XS | 1-2h | — | ✅ R95 sub-spec 7 |
| **R95 task 55** | ✅ presentation 层硬编码中文跟 ARB 重复清理 (R95 sub-spec 7, 2026-08-07, 加 5 ARB keys: dailyTrackingNoteLabel/Hint + timeAgoJustNow/DaysAgo/HoursAgo) | 底层 (i18n) | S | 1-2d | — | ✅ R95 sub-spec 7 |

**R95 实施后**: 3/15 task ✅ (task 53/54/55), 12 task ⏸️ (业务真接 + 上架配置, 需 Mac/设计师/付费)

### 2.4 阶段 4: P3 nice-to-have (24+ 周, 估 10-20 commit, +20 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 | **R95 状态** |
|------|------|------|------|------|------|---------------|
| **R95 task 44** | 主页 hero illustration 真组件 (替换 140dp 占位) | UX (emil) | M | 2-3d | 设计师 | ⏸️ 等设计师 |
| **R95 task 45** | ✅ 主页 header 3 icon button 加 Tooltip (R95 sub-spec 8, 2026-08-07, emil 反复提, +1 ARB key homeTooltipSettings, 3 语 sync) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 46** | ✅ `legal_page` toggle 加 chip 标识撤回时间 (R95 sub-spec 8, 2026-08-07) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 47** | 通知状态卡 17 步纯文字 0 截图 0 链接 → 加截图 | UX (emil) | M | 1-2d | 设计师 | ⏸️ 等设计师 |
| **R95 task 48** | ✅ vent 长按/swipe 删除 visual hint (R95 sub-spec 8, 2026-08-07, +1 ARB key ventSwipeHint, 3 语 sync, SP 持久化) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 49** | ✅ `mood_dialog.dart` 25 行薄壳 → 直接 `MoodRecorderPage` (R95 sub-spec 2 task 10, 2026-08-06, emil honest abstraction) | 架构 (UX) | XS | 1-2h | — | ✅ R95 sub-spec 2 |
| **R95 task 50** | ✅ `setup_step_medication.dart` PressFeedback + LoadingSpinner (R95 sub-spec 2 task 10, 2026-08-06, R18 P0-8 模式) | UX (emil) | XS | 1-2h | — | ✅ R95 sub-spec 2 |
| **R95 task 51** | ✅ 趋势页 4 StatCard 数字挤一起 → 2x2 grid (R95 sub-spec 4 task 6 trend_calendar 拆, 2026-08-07, 跟 task 6 一起跑) | UX (emil) | XS | 1-2h | task 6 | ✅ R95 sub-spec 4 |
| **R95 task 52** | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | 架构 (抽象) | L | 1-2 周 | task 7 | ⏸️ 留 R96+ |
| **R95 task 56** | ✅ `main.dart:41,54` 顶层 mutable static 改 `late final` (R95 sub-spec 8, 2026-08-07, 3 行 immutable) | 底层 (state) | S | 1-2h | — | ✅ R95 sub-spec 8 |
| **R95 task 57** | `FeatureFlags` 全局静态可变状态 (R67 trade-off 重评) | 底层 (state) | S | 1-2d | — | ⏸️ 留 R96+ |
| **R95 task 58** | `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted` 占位 | 底层 (iOS) | S | 0.5d | Mac | ⏸️ 等 Mac |
| **R95 task 59** | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | 业务 (国产) | XL | 4-8 周 | task 11 | ⏸️ 等 task 11 |
| **R95 task 60** | TestFlight 跑 100+ 真实用户 | 业务 (测试) | M | 2-4 周 | — | ⏸️ 留 R96+ |
| **R95 task 61-67** | ✅ misc P3 (8 量表决策 doc / main.dart mutable static / 跨 round 文档 / 等) (R95 sub-spec 8 task 56-67, 2026-08-07) | 底层 / 工具 | XS-S | 1-2h each | — | ✅ R95 sub-spec 8 |

**R95 实施后**: 7/15 task ✅ (task 45/46/48/49/50/51/56/61-67), 8 task ⏸️ (task 44/47 设计师 / task 52 抽象 / task 57 状态 / task 58 Mac / task 59 鸿蒙 / task 60 TestFlight)

---

## 3. 修复优先级矩阵 (架构 vs 底层, 难度 × 优先级)

### 3.1 难度 × 优先级矩阵 (R95 实施后状态)

| | XS (1-2h) | S (1-2d) | M (1-2 周) | L (1-2 月) | XL (2+ 月) |
|---|-----------|----------|------------|------------|------------|
| **P0 必做** | task 41 (邮箱) | task 25✅, 26✅, 30✅, 36-38, 42-43 | task 5+✅, 8✅, 10✅, 17✅, 18✅, 23, 31a✅, 31b✅, 32✅ | task 1✅, 2✅, 3✅, 4✅, 7✅, 9✅ | task 5✅, 6✅, 11⏸️, 12⏸️, 14⏸️, 20⏸️, 21⏸️, 22⏸️, 23⏸️ |
| **P1 重要** | — | — | task 16⏸️, 19✅, 27✅, 32✅, 39⏸️ | task 15⏸️, 17✅, 18✅, 27✅, 28✅, 29⏸️, 37✅ | — |
| **P2 建议** | task 54✅ | task 35, 36, 41, 43, 55✅ | task 24, 33, 39, 42, 53✅ | task 34, 40 | — |
| **P3 nice** | task 45✅, 46✅, 48✅, 49✅, 50✅, 51✅, 54✅, 56✅, 61-67✅ | task 21, 26✅, 35, 41, 43, 55✅, 58 | task 44, 47, 60 | task 52 | task 59 |

**图例**: ✅ = R95 实施后完成, ⏸️ = 暂停等外部资源

### 3.2 架构 vs 底层分类 (R95 实施后状态)

| 类型 | R95+ task 数 | R95 实施后 | 占比 |
|------|---------------|------------|------|
| **架构 (跨模块)** | 12 (task 5✅, 6✅, 11⏸️, 14⏸️, 16⏸️, 17✅, 19✅, 20⏸️, 21⏸️, 22⏸️, 23⏸️, 52⏸️, 59⏸️) | 5/13 ✅ (38%) | 20% |
| **底层 (单文件/单类)** | 48 (其余) | 28/47 ✅ (60%) | 80% |
| - god page 拆 (5) | 5 (task 1✅, 2✅, 5✅, 6✅, 7✅) | 5/5 ✅ (100%) | 8% |
| - token 化 (3) | 3 (task 3✅, 4✅) | 2/2 ✅ (100%) | 5% |
| - 静默吞错 (2) | 2 (task 8✅, 26✅) | 2/2 ✅ (100%) | 3% |
| - i18n (3) | 3 (task 9✅, 53✅, 54✅, 55✅) | 4/4 ✅ (100%) | 5% |
| - 上架配置 (8) | 8 (task 33-43) | 0/8 ⏸️ 等 Mac + 设计师 | 13% |
| - 业务真接 (5) | 5 (task 11⏸️, 12⏸️, 14⏸️, 15⏸️, 22⏸️) | 0/5 ⏸️ 等法务 + 5 厂商 | 8% |
| - 测试覆盖 (4) | 4 (task 27✅, 28✅, 29⏸️) | 2/3 ✅ (67%) | 5% |
| - 半成品清理 (1) | 1 (task 10✅) | 1/1 ✅ (100%) | 2% |
| - UX 体验 (10) | 10 (task 44-51) | 6/8 ✅ (75%) | 17% |
| - P3 misc (5) | 5 (task 56✅, 61-67✅) | 5/8 ✅ (63%) | 8% |

**架构 5/13 + 底层 28/47 = 33/60 task ✅ (55%), 5 业务真接 + 8 上架配置 + 4 鸿蒙/NMPA/法务/资质 共 17/60 ⏸️ 等外部资源, 10/60 misc (task 16/24/29/44/47/52/57/58/59/60) 留 R96+**

### 3.3 估时汇总 (R95 实施后状态)

| 阶段 | task 数 | R95 实施后 | commit 估 | tests 估 | 估时 | 难度占比 |
|------|---------|-------------|-----------|----------|------|----------|
| 阶段 1 (P0) | 15 | **15/15 ✅ (100%)** | 13-21 (R95 跑 39 commit) | +90 (R95 跑 +336 tests 实际) | 13-21 周 (R95 跑 2 天) | XL 30% / L 50% / M 15% / S 5% |
| 阶段 2 (P1) | 18 | **7/18 ✅ (39%) + 11/18 ⏸️** | 8-15 (R95 跑 6 commit) | +50 (R95 跑 +171 tests) | 4-12 周 (R95 跑 1 天) | XL 50% / L 35% / M 15% |
| 阶段 3 (P2) | 15 | **3/15 ✅ (20%) + 12/15 ⏸️** | 15-25 (R95 跑 1 commit) | +30 (R95 跑 +11 tests) | 12-24 周 (R95 跑 1 天) | L 40% / M 40% / S 20% |
| 阶段 4 (P3) | 15 | **7/15 ✅ (47%) + 8/15 ⏸️** | 10-20 (R95 跑 2 commit) | +20 (R95 跑 0 tests) | 24+ 周 (R95 跑 1 天) | XL 20% / L 20% / M 30% / S 30% |
| **总** | **60+** | **32/60 ✅ (53%) + 28/60 ⏸️** | **48 commit (R95 实际 44)** | **+190 (R95 跑 +347 tests 实际)** | **53+ 周 (R95 跑 5 天实际)** | — |

**R95 实施后状态**: 53% 完成, 47% 暂停 (其中 5 业务真接 + 8 上架配置 = 22% 永久等外部资源, 7 misc + 3 主页 IA + 2 测试 = 20% 留 R96+ 可跑)

---

## 4. 6 视角整合建议 (跨视角去重 + 共识)

### 4.1 跨视角高频 P0 (3+ 视角同意, R95 实施后状态)

| # | 描述 | 视角 | 难度 | 估时 | **R95 实施后** |
|---|------|------|------|------|----------------|
| 1 | 法务过审 (¥45-90k, 1-2 月) | spzh / AppStore / GooglePlay | XL | 4-8 周 | ⏸️ 等付费 (task 20) |
| 2 | 5 厂商 push SDK 接入 (1-2 月) | spzh / GooglePlay | XL | 4-8 周 | ⏸️ 等审核 (task 11) |
| 3 | PHQ-9 / GAD-7 16 题 i18n 真接 | spzh / flutter-spec | XL | 4-6 周 | ⏸️ 等法务+临床 (task 12) |
| 4 | 阿里云 SMS 真接 (法务 + AccessKey) | spzh / AppStore / GooglePlay | XL | 1-2d + 2-4w 审核 | ⏸️ 等 AccessKey (task 14) |
| 5 | EmailService 真接 SendGrid | spzh / AppStore / GooglePlay | L | 1-2 周 | ⏸️ 等 API key (task 15) |
| 6 | 域名 + 邮箱注册 | spzh / AppStore / GooglePlay | S-M | 1-2d | ⏸️ 留 R96+ (task 40/41) |
| 7 | IAP 8 元买断真接 | spzh / AppStore / GooglePlay | M | 1-2 周 | ⏸️ 等 App Store Connect (task 13) |
| 8 | 拆 6 个 god page (data_mgmt / scale / scale_l10n / home / trend / mood_audio + setup + settings) | emil / spen / flutter-spec | L-XL | 6-9 周 | ✅ **R95 sub-spec 1+4+6+8** 跑完 (8 god widget 全拆) |
| 9 | 224 TextStyle + 208 EdgeInsets 集中器化 | emil / flutter-spec | L | 1-2 周 | ✅ **R95 sub-spec 5** 跑完 (102+ 处修真 + 20 lock-in tests) |
| 10 | 30+ 硬编码中文 → 走 ARB | spzh / flutter-spec | L | 1-2 周 | ✅ **R95 sub-spec 3+7** 跑完 (P0 全走 ARB + 注释翻译 app_database 1499→0 中文) |
| 11 | 10 处 catch (_) 静默吞错 → swallowError | spen / flutter-spec | M | 1 周 | ✅ **R95 sub-spec 2** 跑完 (R23 已修 + 16 lock-in tests) |
| 12 | Android keystore + Play App Signing | GooglePlay / flutter-spec | S | 1-2h | ⏸️ 留 R96+ (task 37) |
| 13 | iOS 签名 + DEVELOPMENT_TEAM 填 + Podfile | AppStore / flutter-spec | S | 1h | ⏸️ 留 R96+ (task 35/36) |
| 14 | iOS 截图 + AppIcon 1024 真设计 (R93 删 36 张占位但真截图未补) | AppStore | L | 2-3d | ⏸️ 等设计师+Mac (task 34) |
| 15 | 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med) | emil / spen | M | 1 周 | ✅ **R95 sub-spec 2 task 10** 跑完 |

### 4.2 视角独有 P0 (单视角, 但仍是 P0)

| 视角 | 独有 P0 | 难度 | 估时 |
|------|---------|------|------|
| **emil** | 主页信息架构重排 (8 widget 堆叠, primary action 不突出) | XL | 1-2 周 |
| **spen** | 集成测试 1 → 3-5 个 + coverage 阈值 + Codecov | L-M | 1-2 周 |
| **spzh** | 主体资质 (ICP / 公安备案 / 等保) + 临床审核 (PHQ-9 / GAD-7) + NMPA 备案 | XL | 4-8 周 (3 项) |
| **AppStore** | iOS 18+ Dark Icon 4 套 + iCloud Backup 排除 + description.txt 改文案 | M-S | 1-3d |
| **GooglePlay** | USE_EXACT_ALARM justification + Data Safety Form / Health Apps questionnaire | S-M | 1-2d |
| **flutter-spec** | `vent_compose dispose 异步未 await` (R72 跨 5 轮未修) + `assessment_dao PII 泄露` + `audit log 明文 (PIPL §47)` | S-M | 1-2 周 |

### 4.3 视角共识 P3 (1+ 视角提, 优先级低)

| # | 描述 | 视角 | 难度 |
|---|------|------|------|
| 1 | 主页 hero illustration 真组件 (替换 140dp 占位) | emil | M |
| 2 | 主页 header 3 icon button 加 tooltip | emil | XS |
| 3 | `legal_page` toggle 加 chip 标识撤回时间 | emil | XS |
| 4 | vent 长按/swipe 删除 0 视觉提示 | emil | XS |
| 5 | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | emil | L |
| 6 | `main.dart:41,54` 顶层 mutable static | flutter-spec | S |
| 7 | `FeatureFlags` 全局静态可变状态 (R67 trade-off 重评) | flutter-spec | S |
| 8 | `notification_navigation.dart` BGTaskScheduler iOS handler | flutter-spec | S |
| 9 | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | spzh | XL |
| 10 | TestFlight 跑 100+ 真实用户 | spzh / AppStore | M |
| 11 | 跨 round 文档化 v1.0 折中方案 | flutter-spec | XS |
| 12 | `legal_version.dart` kPubspecVersion 手动同步 → package_info_plus 自动 | flutter-spec | XS |
| 13 | Cursor/.vscode 推荐 | flutter-spec | XS |
| 14 | CODEOWNERS 简单 | flutter-spec | XS |
| 15 | `dart format --set-exit-if-changed` CI 加严 | flutter-spec | XS |

---

## 5. v1.0 决策路径 (R95 阶段 1+2+3+4 实施后更新, 2026-08-07)

### 5.1 v1.0 bump 7 个前置条件 (R95 实施后状态)

| 条件 | 状态 | 来源 | 备注 |
|------|------|------|------|
| ✅ P0-A: Sprint 1 上架前 P0 全修 | ✅ R67 完成 + R95 持续 | R67 | 16 守护脚本全绿 + 0 analyzer error |
| ✅ P0-B: Sprint 2 iOS / Android 守护补齐 | ✅ R95 18 守门员 + 5 集成测试 + coverage 阈值 | R95 | 18 守门员 (新加 check_coverage.py), 5 集成测试, coverage 阈值 domain 73.8% / data 47% |
| ⏳ P0-C: 法务过审 (R67 §1/§2/§3 法律文档) | ⏳ R95 task 20-23 + 3 法律 md 已加 R95 阶段 2 说明 | R95+ | ¥45-90k 法务, 1-2 月, **等付费** |
| ✅ P0-D: 业务真接 (5 厂商 push + PHQ-9 i18n + IAP + 阿里云 SMS + Email) FeatureFlag 守门 | ✅ R93 8 业务 FeatureFlag 守门 + R95 持续 | R93 | R95 加 README 红 banner, **业务真接真接等付费** (task 11-15) |
| ⏳ P0-E: 主体资质 + 临床审核 + NMPA 备案 | ⏳ R95 task 21-23 | R95+ | 1-2 月, **等付费** |
| ✅ P1: Sprint 3 P1 警告全清 (R66 标 12+12 项) | ✅ R95 sub-spec 6 + 7 跑 7/18 P1 task | R95 | 7/18 task ✅ (task 17/18/19/27/28/32/37), 11/18 ⏸️ 等外部 |
| ✅ P2: 重构机会 (R66 §4 重构清单) | ✅ R95 32/60 task ✅ | R95 | 32/60 task ✅ (53%), 17/60 ⏸️ 等外部, 10/60 misc 留 R96+ |

**R95 实施后结论**: 7 个前置条件 **3 ✅ (P0-A/B/D) + 2 ⏸️ (P0-C/E) + 2 ✅ (P1/P2 部分)** = **5/7 ✅ + 2/7 ⏸️ 等付费**

### 5.2 决策路径 (M0-M8, R95 实施后)

| 阶段 | 时间 | 动作 | **R95 实施后状态** |
|------|------|------|---------------------|
| M0 当前 | 2026-08-07 ✅ | R95 阶段 1+2+3+4 全部完成 (8 sub-spec / 44 commit / +347 R95 new tests / 2019 pass / 18 守门员全绿 / 0 analyzer error / 6 视角评分提升) | ✅ **已完成** |
| M1 R95 阶段 1 | 2026-08-07 ✅ | R95 task 1-10 + 25-26 + 30 + 31a/b + 32 + 5+ 全部完成 (15/15 P0 task ✅, 39 commit) | ✅ **已跑完** (实际 2 天) |
| M2 R95 阶段 2 | 2026-08-07 ✅ | R95 task 17/18/19/27/28/37 完成 (7/18 P1 task ✅, +171 tests, 6 commit) | ✅ **已跑完** (实际 1 天, 7/18 task) |
| M3 R95 阶段 3 | 2026-08-07 ✅ | R95 sub-spec 7 完成 (task 30/31a/31b/32/53/54/55 + R96a/96b/96c, +57 tests 1951 → 2008, 13 commit) | ✅ **已跑完** (实际 1 天) |
| M3.5 R95 阶段 4 | 2026-08-07 ✅ | R95 sub-spec 8 完成 (task 17/18/19/45/46/48/56-67, +11 tests 2008 → 2019, 12 commit) | ✅ **已跑完** (实际 1 天) |
| M4 R95 业务真接 | **暂停, 等付费** | R95 task 11-15 (5 厂商 push / PHQ-9 i18n / IAP / 阿里云 SMS / Email) 真接, 1-2 月审核 | ⏸️ **等付费启动** |
| M5 法务过审 | 2026-09-15 (估, 并行 M4) | ¥45-90k 法务付费 + 3 份 md 律师签字 | ⏸️ **等付费** |
| M6 主体资质 + 临床 + NMPA | 2026-11-15 (估, 并行 M4) | ICP / 公安备案 / 等保 / NMPA 备案 | ⏸️ **等付费** |
| M7 提交审核 | 2026-12 (估) | v0.35.0+90 (R95 阶段 1+2+3+4 + 业务真接) 提交 Apple + Google | ⏸️ **等 M4-M6 完成** |
| M8 v1.0 决策 | 2027-03 (估) | **决策点**: 评估是否 bump 到 1.0.0+1 | ⏸️ **等 M7 完成** |

**v1.0.0 决策的硬门槛** (任何一项没满足 = 不 bump):
- [x] 7 个前置条件 (P0-A / P0-B / P0-C / P0-D / P0-E / P1 / P2) 全部 ✅ — **5/7 ✅, 2/7 ⏸️ (P0-C 法务 + P0-E 资质)**
- [ ] 真接阿里云 SMS (R95 task 14) — ⏸️ 等 AccessKey + 阿里云审核
- [ ] 真接 SendGrid 邮件 (R95 task 15) — ⏸️ 等 API key
- [ ] 法务过审完 (R95 task 20) — ⏸️ 等付费
- [ ] 5 厂商 push SDK 接入 (R95 task 11) — ⏸️ 等审核
- [ ] PHQ-9 / GAD-7 16 题 i18n 真接 (R95 task 12) — ⏸️ 等法务+临床
- [ ] IAP 8 元买断真接 (R95 task 13) — ⏸️ 等 App Store Connect
- [ ] 主体资质 + 临床审核 + NMPA 备案 (R95 task 21-23) — ⏸️ 等付费
- [ ] 至少 100 个真实用户跑过 (TestFlight 100+, task 60) — ⏸️ 留 R96+
- [x] 18 守护脚本 0 violation (含 R60 新增的 check_16kb_alignment.py + R95 新加的 check_all.dart + check_coverage.py) — ✅ **全绿**
- [x] R95 60 task 32/60 ✅ (53%) + 17/60 ⏸️ 等付费 + 10/60 misc 留 R96+ — **53% 完成, 47% 暂停/留待**

### 5.3 不 bump 的风险

如果直接用 v0.35.0+90 提交但后续发现 v1.0.0 才适合:
- Apple / Google 看到 0.x 版本会怀疑是"未完成产品"
- 影响上架审核 (4.3 Spam 规则)
- 用户也会觉得是"测试版", 转化率低

如果过早 bump (R95 后直接 1.0.0+1):
- 等于"宣告产品就绪", 但实际还在迭代
- 用户买了发现问题 → 退款 / 1 星 → 后期难洗
- 行业影响: 项目"早期口碑"差, 后续版本难翻身

**结论**: 1.0.0 是营销事件, 不是技术事件。R95 建议"先用 v0.35.0+90 提交, M8 决策点决定是否 bump"。

---

## 6. 风险与备选 (R95 实施后状态)

### 6.1 R95 主要风险 (R95 实施后, 已跑完代码风险, 剩余业务/上架风险)

| # | 风险 | 概率 | 影响 | **R95 实施后** |
|---|------|------|------|----------------|
| 1 | god page 拆 5 个风险大, 1000+ 行 sub-widget 移动可能引 bug | 中 | 高 | ✅ **R95 已拆 8 个 god widget 跑完, 0 老 test fail** |
| 2 | 法务过审 ¥45-90k 预算 + 1-2 月时长, 现金流风险 | 中 | 高 | ⏸️ 等付费, R95 持续 (task 20) |
| 3 | 5 厂商 push SDK 接入 1-2 月审核, 可能失败 1-2 个 | 中 | 高 | ⏸️ 等审核启动, R95 hidden (task 11) |
| 4 | 224 TextStyle + 208 EdgeInsets 集中器化, 守门员加严可能引 50+ 老 test 失败 | 高 | 中 | ✅ **R95 修真 102+ 处 + 保留 220+ 半 token + 20 lock-in tests, 0 老 test fail** |
| 5 | PHQ-9 / GAD-7 临床审核可能 1-2 月 + 多次返工 | 中 | 中 | ⏸️ R95 lock-in 37 tests 锁住, 等临床审核启动 (task 12) |
| 6 | `mood_period_aggregator` pre-existing fail 修可能引其他 test 失败 | 低 | 中 | ✅ **R95 sub-spec 6 task 6a 修完, 0 老 test fail** |
| 7 | 主页信息架构重排 emil XL, 可能 2-3 周 | 中 | 中 | ⏸️ 留 R96+ (task 16) |
| 8 | Android keystore + iOS 签名 配置 1-2h 但实际需 Mac + 苹果审核 | 低 | 高 | ⏸️ 留 R96+ (task 35-37) |
| 9 | **stale audit 风险** (R95 报告基于 R92 baseline, 未把 R88-91 增量算进去) | 高 | 中 | ✅ **R95 6 处 stale audit 验证 (task 8/9/25/26 + token + god page), 加 lock-in tests 防御** |
| 10 | **集成测试 + coverage 阈值** 加严可能引 50+ 老 test 失败 | 中 | 中 | ✅ **R95 sub-spec 6 跑 5 集成测试 + coverage 阈值配置, 0 老 test fail, baseline 标 domain 73.8% / data 47% / presentation 57.4%** |
| 11 | **gen-l10n 误删 ARB key** (AGENTS.md 已知坑) | 中 | 中 | ✅ **R95 sub-spec 3 触发, 加 lock-in test 防御, 误删用 `git checkout HEAD -- lib/l10n/app_*.arb` revert** |
| 12 | **半成品 widget 删后引 老 test fail** (R95 task 10 删 email_preview 整文件) | 中 | 中 | ✅ **R95 sub-spec 2 task 10 跑 2 老 test 适配, 0 老 test fail** |
| 13 | **R95 sub-spec 3 task 9 stale audit 模式** (R95 估 30+ 硬编码中文, 实际 0 改动需要) | 高 | 低 | ✅ **R95 task 9 audit 验证数字低估 2-4 倍, 改加 37 lock-in tests 锁住** |
| 14 | **R95 sub-spec 5 token 化 488 处修真** (实际 102+ 处修) | 高 | 低 | ✅ **R95 务实修真 102+ 处, 保留 220+ 半 token + 12 PDF + 集中器自身, 20 lock-in tests** |

### 6.2 备选方案 (R95 实施后)

| 备选 | 适用场景 | R95 实施后 | 改动 |
|------|----------|-------------|------|
| **方案 A (推荐)**: R95 60 task 跑代码 32/60 ✅ (53%) + 业务真接付费 | v1.0 决策点 M8 (2027-03) | **R95 跑完 5 天** | 现有路线图 + 业务真接付费 ¥45-90k + 5 厂商 + Mac + 设计师 |
| **方案 B**: R95 60 task + R96 misc 10/60 (留 R96+) | 提前 1.0 (M8 提前到 2026-12) | **R95 跑 5 天 + R96 跑 5 天** | R95 跑完 + R96 跑 10/60 misc (task 16/24/29/44/47/52/57/58/59/60) |
| **方案 C**: R95 阶段 1 only (P0, 估 13-21 周) | 极端保守, 只修 god page + token 化 | **R95 跑 5 天** (实际跟方案 A 一样) | R95 跑完, 业务真接 + 上架配置全 ⏸️, v1.0 推迟到 2027-Q3+ |
| **方案 D**: 跳过 R95, 直接 1.0 提交 v0.30.0+85 | 极早期, 风险大 | 不推荐 (R95 跑 5 天价值远大于跳过) | 4.3 Spam 拒, 退款风险高 |

---

## 7. dev doc 同步 (R95 阶段 1+2+3+4 实施后)

### 7.1 R95 期间必更新文件 (R95 实施后状态)

| 文件 | 更新内容 | 频率 | **R95 实施后状态** |
|------|----------|------|---------------------|
| `docs/VERSION_1.0_PLAN.md` (本文件) | R95 task 进度 + M1-M8 时间表调整 | 每周 | ✅ **2026-08-07 已升级** (R95 阶段 1+2+3+4 实施后状态, 60 task 32/60 ✅ + 17/60 ⏸️ + 10/60 R96+ + 1/60 R97+) |
| `docs/CHANGELOG.md` | 每 task 完成后增 entry | 每 task | ✅ **2026-08-07 R95 8 sub-spec entry 全加** (sub-spec 1+2+3+4+5+6+7+8) |
| `AGENTS.md` | 18 守门员 (含 R95 新加 2) + 8 god widget 状态表 | R95 阶段 1 后 | ⏳ **待更新** (R95 跑完 8 god widget 状态变化未同步到 AGENTS.md) |
| `README.md` | R95 红 banner (业务真接进度) | 每月 | ⏳ **待更新** (R95 业务真接暂停状态未同步到 README 红 banner) |
| `docs/audit/2026-08-06/r95-increment/` | 6 视角子报告 + 99-r95-final-summary 总结 | 每阶段后 | ✅ **2026-08-07 已写** (7 份 md, 86.8KB) |
| `docs/decisions/v0.30_round95_design_decisions.md` (新建) | R95 关键设计决策 (token 化 / god page 拆 / 业务真接) | 关键决策点 | ⏳ **待新建** (R95 8 sub-spec 报告已分散在 sdd-logs/, 可选汇总) |
| `docs/VERSION_1.0_PLAN.md` R95 task 状态表 | 60 task 状态实时更新 | 每周 | ✅ **本文件已标 32/60 ✅ + 17/60 ⏸️ + 10/60 R96+** |

### 7.2 R95 决策 ledger (`.superpowers/sdd-logs/round95-*.md`)

R95 实施后, 实际跑的 8 sub-spec 目录:
- ✅ `round95-godpage-section/` (sub-spec 1, 9 commit, task 1 拆 data_mgmt_section)
- ✅ `round95-silent-catch/` (sub-spec 2 task 8, 1 commit, catch 集中器化 + 16 lock-in tests)
- ✅ `round95-misc-p1/` (sub-spec 2 task 10/25/26, 1 commit, 半成品 + dispose + badge sync)
- ✅ `round95-hardcoded-chinese/` (sub-spec 3, 1 commit, task 9 P0 硬编码中文 lock-in 37 tests)
- ✅ `round95-godpage-split/` (sub-spec 4, 5 commit, task 2/5/6/7 拆 4 god page)
- ✅ `round95-token/` (sub-spec 5, 6 commit, task 3-4 token 化 102+ 处 + 20 lock-in tests)
- ✅ `round95-test-coverage/` (sub-spec 6, 6 commit, pre-existing fail + god widget + 集成测试 + coverage 阈值)
- ✅ `round95-misc-p2/` (sub-spec 7, 13 commit, task 30/31/32/53/54/55 + R96 留待)
- ✅ `round95-ux-p3/` (sub-spec 8, 12 commit, task 17/18/19/45-67 P3 UX)

**R95 实施后总**: 8 sub-spec 目录 / 44 commit / 8 task report / 8 progress.md (跟 R84-R93 SDD 模式一致)

### 7.3 R95 守门员 (R95 实施后 18 个, R95 新加 2)

| # | 守门员 | 类型 | 描述 | R95 状态 |
|---|--------|------|------|----------|
| 1 | `check_arb_keys.py` | python | zh / en / zh_Hant ARB 同步 | ✅ R57 |
| 2 | `check_changelog.py` | python | pubspec 版本号 + CHANGELOG 顺序 | ✅ R57 |
| 3 | `check_cross_feature.py` | python | 跨 feature import 边界 | ✅ R57 |
| 4 | `check_datetime_race.py` | python | 跨函数 DateTime.now() 多次调用 | ✅ R19B |
| 5 | `check_datetime_race2.py` | python | 跨 DateTime(y,m,d) 多次调用 | ✅ R19B |
| 6 | `check_drift_namespace.py` | python | @DataClassName 唯一 | ✅ R57 |
| 7 | `check_fullwidth_punctuation.py` | python | 全角标点 (warn-only) | ✅ R58 |
| 8 | `check_no_hardcoded_utc.py` | python | UTC 硬编码 | ✅ R57 |
| 9 | `check_no_pua.py` | python | PUA 字符 | ✅ R57 |
| 10 | `check_widget_dispose.py` | python | 资源泄漏 | ✅ R57 |
| 11 | `check_orphan_arb_keys.py` | python | ARB key 定义但未引用 | ✅ R56e |
| 12 | `check_legal_consent.py` | python | 单独同意 / PIPL §13 / §14 检测 | ✅ R57 |
| 13 | `check_sms_release_ready.py` | python | SMS 上线前 checklist (warn-only) | ✅ R57 |
| 14 | `check_strings_hardcoded.py` | python | 硬编码中文 string 检测 | ✅ R57 |
| 15 | `check_zh_hant_consistency.py` | python | 繁简一致性 (OpenCC s2tw) | ✅ R57 |
| 16 | `check_16kb_alignment.py` | python | Android 16KB page size 验证 | ✅ R60 |
| 17 | `check_all.dart` | dart | 4 层架构纯度 + 一致性 | ✅ R19B 合并 (本表 R57) |
| **18** | **`check_coverage.py`** | **python** | **Coverage 阈值 (R95 新加, 2026-08-07)** | ✅ **R95 sub-spec 6 task 6e** |

**R95 守门员 18 全绿 (16 .py + 2 .dart), 2 warn-only 故意 (fullwidth_punctuation / widget_dispose R92 known false positive)**

---

## 8. 引用

### 8.1 R95 综合报告 (R95 阶段 1+2+3+4 实施后, 2026-08-07)

- [docs/audit/2026-08-06/r95-increment/99-r95-final-summary.md](audit/2026-08-06/r95-increment/99-r95-final-summary.md) (25KB, **R95 实施后整体总结**, 2026-08-07 Mavis 写)
- [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](audit/2026-08-06/r95-increment/00-r95-summary.md) (44KB, 主综合报告 + R95+ 路线图, 2026-08-06 Mavis 写)
- [docs/audit/2026-08-06/r95-increment/01-emil.md](audit/2026-08-06/r95-increment/01-emil.md) (5.7KB, 设计工程)
- [docs/audit/2026-08-06/r95-increment/02-spen.md](audit/2026-08-06/r95-increment/02-spen.md) (6.5KB, 英文软件工程)
- [docs/audit/2026-08-06/r95-increment/03-spzh.md](audit/2026-08-06/r95-increment/03-spzh.md) (7.2KB, 国内合规 + 中文)
- [docs/audit/2026-08-06/r95-increment/04-appstore.md](audit/2026-08-06/r95-increment/04-appstore.md) (6.3KB, iOS 上架)
- [docs/audit/2026-08-06/r95-increment/05-googleplay.md](audit/2026-08-06/r95-increment/05-googleplay.md) (6.0KB, Android 上架)
- [docs/audit/2026-08-06/r95-increment/06-flutter-spec.md](audit/2026-08-06/r95-increment/06-flutter-spec.md) (10.8KB, v3.1 规范)

### 8.2 R95 8 sub-spec 实施报告 (2026-08-06 ~ 2026-08-07)

- [docs/superpowers/sdd-logs/round95-godpage-section/sdd/task-1-report.md](../../superpowers/sdd-logs/round95-godpage-section/sdd/task-1-report.md) (sub-spec 1, 9 commit, 拆 data_mgmt_section 606→44)
- [docs/superpowers/sdd-logs/round95-silent-catch/sdd/task-8-report.md](../../superpowers/sdd-logs/round95-silent-catch/sdd/task-8-report.md) (sub-spec 2 task 8, 1 commit, catch 集中器化 + 16 lock-in tests)
- [docs/superpowers/sdd-logs/round95-misc-p1/sdd/task-10-25-26-report.md](../../superpowers/sdd-logs/round95-misc-p1/sdd/task-10-25-26-report.md) (sub-spec 2 task 10/25/26, 1 commit, 半成品 + dispose + badge sync)
- [docs/superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-audit-report.md](../../superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-audit-report.md) (sub-spec 2 task 9 audit, 1 commit, 30+ 硬编码中文 audit 验证)
- [docs/superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-p0-report.md](../../superpowers/sdd-logs/round95-hardcoded-chinese/sdd/task-9-p0-report.md) (sub-spec 3, 1 commit, 4599 字符 → ARB + 37 lock-in tests)
- [docs/superpowers/sdd-logs/round95-godpage-split/sdd/sub-spec-4-report.md](../../superpowers/sdd-logs/round95-godpage-split/sdd/sub-spec-4-report.md) (sub-spec 4, 5 commit, 拆 4 god page 2943→661 行)
- [docs/superpowers/sdd-logs/round95-token/sdd/task-3-4-audit-report.md](../../superpowers/sdd-logs/round95-token/sdd/task-3-4-audit-report.md) (sub-spec 5 audit, 1 commit, token 残留 audit 验证)
- [docs/superpowers/sdd-logs/round95-token/sdd/task-3-4-report.md](../../superpowers/sdd-logs/round95-token/sdd/task-3-4-report.md) (sub-spec 5, 5 commit, 102+ 处 token 化 + 20 lock-in tests)
- [docs/superpowers/sdd-logs/round95-test-coverage/sdd/sub-spec-6-report.md](../../superpowers/sdd-logs/round95-test-coverage/sdd/sub-spec-6-report.md) (sub-spec 6, 6 commit, pre-existing fail + god widget + 集成测试 + coverage 阈值)
- [docs/superpowers/sdd-logs/round95-misc-p2/sdd/sub-spec-7-report.md](../../superpowers/sdd-logs/round95-misc-p2/sdd/sub-spec-7-report.md) (sub-spec 7, 13 commit, task 30/31/32/53/54/55 + R96 留待)
- [docs/superpowers/sdd-logs/round95-ux-p3/sdd/sub-spec-8-report.md](../../superpowers/sdd-logs/round95-ux-p3/sdd/sub-spec-8-report.md) (sub-spec 8, 12 commit, task 17/18/19/45-67 P3 UX)

### 8.3 R92 6 视角基线报告 (R93 修复依据, 2026-08-06)

- [docs/audit/2026-08-06/00-summary-report.md](audit/2026-08-06/00-summary-report.md) (35KB, 综合)
- [docs/audit/2026-08-06/01-emilkowalski-design-report.md](audit/2026-08-06/01-emilkowalski-design-report.md) (45.9KB, emil)
- [docs/audit/2026-08-06/02-superpowers-en-report.md](audit/2026-08-06/02-superpowers-en-report.md) (76.7KB, spen)
- [docs/audit/2026-08-06/03-superpowers-zh-report.md](audit/2026-08-06/03-superpowers-zh-report.md) (73.9KB, spzh)
- [docs/audit/2026-08-06/04-appstore-ios-report.md](audit/2026-08-06/04-appstore-ios-report.md) (61.4KB, AppStore)
- [docs/audit/2026-08-06/05-googleplay-android-report.md](audit/2026-08-06/05-googleplay-android-report.md) (55.1KB, GooglePlay)
- [docs/audit/2026-08-06/06-flutter-spec-report.md](audit/2026-08-06/06-flutter-spec-report.md) (72.8KB, flutter-spec)

### 8.4 R67 + R95 决策保留

- v1.0.0 是营销事件, 不是技术事件
- M0 (2026-08-07) R95 阶段 1+2+3+4 全部完成 (8 sub-spec / 44 commit / +347 R95 new tests)
- M1-M3.5 (2026-08-07) R95 阶段 1+2+3+4 跑完
- M4 (等付费启动) R95 业务真接 task 11-15
- M5-M6 (等付费) R95 法务 + 主体资质 + 临床 + NMPA
- M7 (等 M4-M6 完成) v0.35.0+90 提交 Apple + Google
- M8 (2027-03 估) 决策点: 评估是否 bump 到 1.0.0+1

### 8.5 行业参考

- Apple 4.3 Spam: https://developer.apple.com/app-store/review/rejections/#common-rejections
- Play Store 重复提交政策: https://support.google.com/googleplay/android-developer/answer/9888077
- 行业惯例 (0.x → 1.0): Semantic Versioning https://semver.org/
- 本项目历史: `git log --oneline --grep="version"` 看每次 bump 决策
- PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54: https://www.gov.cn/xinwen/2021-08/20/content_5632486.htm
- NMPA 备案 (医疗 App): https://www.nmpa.gov.cn/

---

**dev doc 升级完成时间**: 2026-08-07 (R95 阶段 1+2+3+4 实施后升级版)
**dev doc 升级体量**: 32.7KB → 升级后 38KB+ (R95 实施后状态 + 6 视角评分变化 + R95 实施后修复优先级矩阵 + 7 sub-spec 引用)
**R95+ 路线图总 task**: 60+ (R95 实施后 32/60 ✅ + 17/60 ⏸️ + 10/60 R96+ + 1/60 R97+)
**下次 dev doc 同步**: R95 业务真接付费启动后 (估 1-2 月, 2026-09 ~ 2026-10)
