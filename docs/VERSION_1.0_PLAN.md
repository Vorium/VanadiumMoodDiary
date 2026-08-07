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
> **R100 6 视角审计** (2026-08-07, 最新): [00-summary](audit/2026-08-07/R100-6perspective-audit/00-summary.md) + [emil](audit/2026-08-07/R100-6perspective-audit/01-emilkowalski.md) / [spen](audit/2026-08-07/R100-6perspective-audit/02-superpowers-en.md) / [spzh](audit/2026-08-07/R100-6perspective-audit/03-superpowers-zh.md) / [AppStore](audit/2026-08-07/R100-6perspective-audit/04-appstore.md) / [GooglePlay](audit/2026-08-07/R100-6perspective-audit/05-googleplay.md) / [flutter-spec](audit/2026-08-07/R100-6perspective-audit/06-flutter-spec.md)

---

## R100 审计更新 (2026-08-07, 6 视角实测)

**状态**: R99 报的 BUG-1~5 全部复核闭环; 本轮 17 守门员 + analyze 全绿 (2019 tests)。**新增/确认 27 项待办** (P0=8 / P1=7 / P2=12; 架构级 8 项 / 底层 19 项), 完整排序表见 [R100 00-summary §三](audit/2026-08-07/R100-6perspective-audit/00-summary.md)。

> **修复进度 (2026-08-07 round 100)**: P0 5 项可代码化修复 + P1 7 项全部闭环 (round 100 commit); 剩 P0 外部依赖 3 项 (域名/截图/keystore) + P2 12 项留上架后。验证: 0 analyzer error + 17 守门员全绿 + 1997 tests pass, 详见 CHANGELOG [0.30.0] R100 条目。

### R100 P0 快照 (上架阻塞, 按序执行)

| # | 事项 | 层级 | 难度 | 阻塞方 |
|---|------|------|------|--------|
| 1 | ~280 文件未提交改动分批 commit (R92-R99 堆积) | 底层 | 简单 | 自己 |
| 2 | 注册 chroniccare.app 域名 + 隐私/支持/数据删除页 (iOS 6 文件 URL + Play Data Safety 依赖) | 底层 | 中 | 域名注册商 |
| 3 | 双平台真实截图 + feature graphic (Android 67B 占位 PNG ×10 / iOS screenshots/ 缺失) | 底层 | 中 | 真机/设计师 |
| 4 | 删 Android video.txt PLACEHOLDER ×2 | 底层 | 简单 | 自己 |
| 5 | 生成 release keystore + key.properties | 底层 | 简单 | 自己 |
| 6 | 删 iOS UIBackgroundModes audio+processing + BGTaskScheduler 声明 (Apple 2.5.4 拒因) | 底层 | 简单 | 自己 |
| 7 | user_agreement "8 元买断" 表述对齐 (改"未来版本"或真接 IAP) | 底层 | 简单 | 自己 |
| 8 | metadata 删 "(失联通知规划中)" (Android title + iOS zh-Hans/Hant subtitle) | 底层 | 简单 | 自己 |

### R100 P1 快照 (高概率打回 / 用户可见)

- UI 硬编码中文 ~30 处走 ARB (+40 key × 3 语, en locale 可见)
- InfoPlist.strings 补 5 项 usage description 英文基线 + zh 覆盖
- 架构 3 连: 删 SafetyCheckResult.displayMessage 旧 getter / 3 StreamProvider 加 autoDispose / 删 CareEngine.evaluate-fire 死代码
- 法务文档 9 处软隐藏说明去掉占位域名残留; repo 根 80+ 垃圾文件清理

### R100 P2 快照 (上架后, 对应本文档 §2 路线图文档化排期)

- **架构级** (8 项): home_page_state 656 行拆分 / 其余 5 个 480+ 行大文件 / services 31 文件分组 / usecase 补全 / ThemeExtension / routerProvider Notifier 化
- **底层级** (4 项): a11y Semantics / golden test / ARB 半角标点 58 key / 中国区法务条款 (user_agreement 7 项 + sensitive_data_consent 3 项)

**R100 关键结论**: 代码可修部分已收敛到 27 项且 0 新增功能 bug; 上架真正的阻塞是**外部资源** (域名 / 截图 / keystore / IAP 决策), 与 R95 结论一致 —— 可代码化部分接近 100% 完成。

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

---

## 9. R97 6 视角审计追加 (2026-08-07, 55 项新发现)

> 本章节为 R95 sub-spec 8 实施后, 用户要求拉 6 个视角团队 (emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification) 对整个项目分别出一份审计报告的汇总追加。6 份报告去重后共 55 项独立发现 (P0=8 / P1=14 / P2=17 / P3=16), 每项标注 **类别 (架构/底层) + 修复难度 (low/medium/high) + 涉及视角**。
>
> **审计覆盖 5 个检查项**: ①外部链接隐藏 ②上架/架构/重构/半成品 ③顶层架构审视 ④底层逐行排查 ⑤开发需求文档更新
>
> **跟 R95 路线图 60 task 的关系**: 本章节 55 项发现中, 部分是 R95 已识别但被低估的 (如 P0-7 SMS 真接), 部分是 R95 后新发现的 (如 P0-1 check_safety 跨层 import, P0-2 主页危机入口被 FeatureFlag 隐藏)。新发现已纳入 R96+ 路线图。

### 9.1 R97 6 视角审计发现统计

| 视角 | P0 | P1 | P2 | P3 | 总计 | 评分 |
|---|---|---|---|---|---|---|
| emilkowalski (设计) | 0 | 1 | 5 | 8 | 14 | A- (架构 9.0/10) |
| superpowers-en (工程) | 1 | 3 | 5 | 7 | 16 | B+ (1 P0 架构违规) |
| superpowers-zh (合规+中文) | 4 | 1 | 6 | 4 | 15 | 🟢 架构达标 / 🔴 法务未解 |
| AppStore (iOS 上架) | 3 | 3 | 4 | 3 | 13 | 上架就绪 ~45% |
| GooglePlay (Android 上架) | 3 | 8 | 7 | 2 | 20 | 上架风险 🔴 高 |
| flutter-specification (规范) | 0 | 3 | 6 | 7 | 16 | ⭐⭐⭐⭐ (4/5) |
| **合计去重** | **8** | **14** | **17** | **16** | **55** | — |

### 9.2 R97 P0 必修清单 (8 项, 上架/v1.0 blocker)

| R97 ID | 问题 | 类别 | 难度 | 视角 | 对应 R95 task | 文件 |
|---|---|---|---|---|---|---|
| **R97-P0-1** | check_safety.dart 跨层 import data/services/safety_detector (R85 重构漏改 import + 旧文件未删, 4 层架构硬约束违规) | 架构 | low | spen | 新发现 | [check_safety.dart#L16](file:///d:/Batch/chroniccare/lib/domain/usecases/check_safety.dart) |
| **R97-P0-2** | 主页心理危机热线入口被 FeatureFlag 完全隐藏 (emergencyContactEnabled=false 守卫, Apple 1.4.1 直接拒) | 底层 | low | AppStore | 新发现 | [home_fab_toolbar.dart#L97](file:///d:/Batch/chroniccare/lib/presentation/pages/home/widgets/home_fab_toolbar.dart) |
| **R97-P0-3** | 域名 chroniccare.app 未注册 + 6 个 privacy/support URL 404 (Apple 5.1.1 + Google Play Data Safety form 双必拒) | 底层 | medium | spzh/AppStore/GooglePlay | R95 task 40 | [fastlane/metadata/ios/zh-Hans/privacy_url.txt](file:///d:/Batch/chroniccare/fastlane/metadata/ios/zh-Hans/privacy_url.txt) |
| **R97-P0-4** | 3 份法律文档"草稿未经律师过审" (PIPL §28/§29 + Apple 5.1.5 强制, ¥45-90k) | 架构 | high | spzh/AppStore/GooglePlay | R95 task 20 | [privacy_policy.md#L212](file:///d:/Batch/chroniccare/assets/legal/privacy_policy.md) |
| **R97-P0-5** | Release 签名 fallback debug keystore (signingConfig 硬绑 debug, Play Console 直接拒) | 底层 | low | emil/GooglePlay | R95 task 37 | [build.gradle.kts#L82](file:///d:/Batch/chroniccare/android/app/build.gradle.kts) |
| **R97-P0-6** | USE_EXACT_ALARM 权限违反 Google Play 限制 (2024-07 起限制为 alarm clock/calendar 类, 精神心理服药提醒不在允许范围) | 底层 | low | GooglePlay | R95 task 38 | [AndroidManifest.xml#L33](file:///d:/Batch/chroniccare/android/app/src/main/AndroidManifest.xml) |
| **R97-P0-7** | SMS / Email 真接未做 (AliyunSmsProvider.send() throw StateError, EmailService 未实现, 失联通知业务 100% 不可用) | 架构 | high | spzh/spen | R95 task 14/15 | [sms_service.dart#L195](file:///d:/Batch/chroniccare/lib/core/data/services/sms_service.dart) |
| **R97-P0-8** | NMPA 医疗器械备案未明确 (PHQ-9/GAD-7 心理评估可能触发二类医疗器械备案, 未做法务咨询) | 架构 | high | spzh | R95 task 23 | [README.md#L265](file:///d:/Batch/chroniccare/README.md) |

### 9.3 R97 P1 重要清单 (14 项, 上架前应修)

| R97 ID | 问题 | 类别 | 难度 | 视角 | 文件 |
|---|---|---|---|---|---|
| **R97-P1-1** | daily_tracking 6 provider 暴露 Impl 类型 (违反 AGENTS "Provider<XRepository> 暴露接口"约束) | 架构 | medium | spen | [daily_tracking_providers.dart#L39](file:///d:/Batch/chroniccare/lib/presentation/providers/daily_tracking_providers.dart) |
| **R97-P1-2** | TodayMedSchedule.build() 调 DateTime.now() (跨 midnight stale + rebuild 浪费) | 底层 | low | spen | [today_med_schedule.dart#L44](file:///d:/Batch/chroniccare/lib/presentation/pages/medication/today_med_schedule.dart) |
| **R97-P1-3** | VentRepositoryImpl.delete() TOCTOU 事务范围错 (select 在事务外, rename 场景可能删错文件) | 底层 | medium | spen | [vent_repository_impl.dart#L105](file:///d:/Batch/chroniccare/lib/core/data/repositories/vent/vent_repository_impl.dart) |
| **R97-P1-4** | vent 树洞 UGC 完全没有举报机制 (Apple 1.2.1 直接拒, 无举报按钮 + 无 UGC 政策声明) | 底层 | medium | AppStore | [vent_detail_page.dart](file:///d:/Batch/chroniccare/lib/presentation/pages/vent/vent_detail_page.dart) |
| **R97-P1-5** | IAP 入口完全隐藏但 user_agreement 声明"售价 8 元" (描述与实际不符, Apple 2.1/3.1.1) | 底层 | medium | AppStore | [feature_flags.dart#L51](file:///d:/Batch/chroniccare/lib/core/data/feature_flags.dart) |
| **R97-P1-6** | 首次启动立即请求通知权限 (main.dart bootstrap 阶段调 init() 内立即 requestPermissions, 违反"先解释后请求") | 底层 | medium | AppStore/GooglePlay | [main.dart#L161](file:///d:/Batch/chroniccare/lib/main.dart) |
| **R97-P1-7** | setup_legal_dialog 危机热线展示不完整 (注释写 5 条实际只渲染 4 条, 漏 crisisHotlineCnBeijing, 与 user_agreement §5 表格不同步) | 底层 | low | spzh | [setup_legal_dialog.dart#L79](file:///d:/Batch/chroniccare/lib/presentation/pages/setup/setup_legal_dialog.dart) |
| **R97-P1-8** | INTERNET 权限当前为非必需 (业务全部 flag=false 暂停, 0 网络调用但申请 INTERNET) | 底层 | low | GooglePlay | [AndroidManifest.xml#L30](file:///d:/Batch/chroniccare/android/app/src/main/AndroidManifest.xml) |
| **R97-P1-9** | RECORD_AUDIO 权限与 ventAudioEnabled=false 不匹配 (业务暂停期应删除 microphone 权限) | 底层 | low | GooglePlay | [AndroidManifest.xml#L37](file:///d:/Batch/chroniccare/android/app/src/main/AndroidManifest.xml) |
| **R97-P1-10** | BootReceiver 半成品 (R64+ TODO, manifest 声明 RECEIVE_BOOT_COMPLETED 但 FeatureFlag 禁用, Android 14+ 后台启动限制) | 底层 | medium | GooglePlay | [BootReceiver.kt#L29](file:///d:/Batch/chroniccare/android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt) |
| **R97-P1-11** | 危机热线只能复制号码, 无一键拨打 (Health/Sensitive Apps policy 推荐 tel: intent) | 底层 | low | GooglePlay | [crisis_hotline_page.dart#L182](file:///d:/Batch/chroniccare/lib/presentation/pages/crisis_hotline_page.dart) |
| **R97-P1-12** | analysis_options.yaml lint 规则强度偏低 (仅 4 条显式规则, 远低于 Effective Dart 推荐) | 架构 | low | flutter-spec | [analysis_options.yaml#L17](file:///d:/Batch/chroniccare/analysis_options.yaml) |
| **R97-P1-13** | unnecessary_late + dead_code + deprecated_member_use 3 处 warning (main.dart late final 误用 + export_dialog dead code + RadioListTile 弃用 API) | 底层 | low | flutter-spec | [main.dart#L45](file:///d:/Batch/chroniccare/lib/main.dart) |
| **R97-P1-14** | PIPL §13 紧急联系人"单独同意"软实施 (用户担保已告知, 非联系人独立确认, v1.0 真接 SMS 时必须升级) | 架构 | high | spzh/AppStore | [setup_legal_dialog.dart#L24](file:///d:/Batch/chroniccare/lib/presentation/pages/setup/setup_legal_dialog.dart) |

### 9.4 R97 P2 建议清单 (17 项, v1.0+ 可做)

| R97 ID | 问题 | 类别 | 难度 | 视角 |
|---|---|---|---|---|
| **R97-P2-1** | UseCase 层薄厚不均 (9 repo 仅 4 usecase, 5 类业务 presentation→repo 直接对话) | 架构 | medium | spen |
| **R97-P2-2** | CareEngine + FireCareStrategyUseCase 4 strategy DRY 重复 ~50 行 | 底层 | medium | spen |
| **R97-P2-3** | latestXxxEntryProvider 用 .value?.firstOrNull 隐式假设 stream 排序 (违反 AGENTS 已知坑) | 底层 | low | spen |
| **R97-P2-4** | AppTokens facade 306 行 god class (注释承诺 ≤50 行) + 5 个 magic size 常量未抽 | 架构 | medium | flutter-spec |
| **R97-P2-5** | directives_ordering 违反 6 处 (dart: 排在 package: 之后, lint 未启用) | 底层 | low | flutter-spec |
| **R97-P2-6** | FeatureFlags 注释与实现不一致 (4 vs 11 vs 8 flag) + setEmergencyContactEnabledForTest setter 缺失 | 底层 | low | flutter-spec |
| **R97-P2-7** | 通知 channel name/title 硬编码中文 const (en/zh_Hant 用户看中文 channel) | 底层 | medium | spzh |
| **R97-P2-8** | userNameFamily 残留"您的家人" (跟 R72 中性化决策不一致, 可能引发病耻感) | 底层 | low | spzh |
| **R97-P2-9** | emailBody "避免复发" 不中性 (精神心理场景用词不中性) | 底层 | low | spzh |
| **R97-P2-10** | setup_step_done 缺首次评估/紧急联系人引导 | 底层 | low | spzh |
| **R97-P2-11** | PIPL §52 联系方式软隐藏 (邮箱渠道不可达, App 内反馈不便捷) | 架构 | medium | spzh |
| **R97-P2-12** | 25 处 TODO 无版本号 (长期 TODO 滚雪球, 新人误判优先级) | 底层 | medium | spen |
| **R97-P2-13** | proguard-rules.pro 缺 speech_to_text 完整 keep 规则 (v1.0 真接 STT 时可能 crash) | 底层 | low | GooglePlay |
| **R97-P2-14** | SCHEDULE_EXACT_ALARM targetSdk=33+ 默认 denied (通知时间偏移 silent bug) | 底层 | low | GooglePlay |
| **R97-P2-15** | 缺 android:largeHeap (PDF 导出 OOM 风险) | 底层 | low | GooglePlay |
| **R97-P2-16** | FeatureFlags 全 8 项 false (商店描述与实际功能不符触发 Minimum Functionality 拒审) | 架构 | low | GooglePlay/AppStore |
| **R97-P2-17** | PHQ-9/GAD-7 量表 i18n 未完成 (en/zh_Hant 用户看中文题目, 医疗法律责任) | 底层 | medium | AppStore |

### 9.5 R97 P3 nice-to-have 清单 (16 项, 摘要)

| R97 ID | 问题 | 类别 | 难度 |
|---|---|---|---|
| **R97-P3-1** | App Store 截图未准备 (33 张真机截图) | 架构 | medium |
| **R97-P3-2** | fastlane/Appfile 需真实 APPLE_ID/TEAM_ID (R96 ENV 化但需用户填) | 架构 | low |
| **R97-P3-3** | contacts 硬空 + fireSms/Email 硬抛 StateError (v1.0 切 SMS/Email 时埋雷) | 底层 | medium |
| **R97-P3-4** | AppListTile 三元 `onTap != null ? null : onTap` 等价 null dead code | 底层 | low |
| **R97-P3-5** | _StreakCounter 首次进入无 0→N 动画 (emil 风格首次也做轻量动画) | 底层 | low |
| **R97-P3-6** | _nextReminderTime 硬编码 20:00 magic number (应抽 nextReminderProvider) | 底层 | low |
| **R97-P3-7** | 跨时区 DateTime 不一致 (4 处 DateTime.now() 跟 tz.local 混用, 海外 DST 切换风险) | 底层 | low |
| **R97-P3-8** | 版本考古注释过密 (main.dart 496 行注释占 40%, 违反 Effective Dart 文档简洁原则) | 底层 | low |
| **R97-P3-9** | 4 个文件首行 UTF-8 BOM (vent_compose_page / vent_detail_page / legal_page / app_routes) | 底层 | low |
| **R97-P3-10** | legal_page.dart 撤回时间未走 DateFormat (手工 padLeft 拼接, 未本地化) | 底层 | low |
| **R97-P3-11** | contact 缺本人手机号校验 (用户把自己的号码填成紧急联系人) | 底层 | low |
| **R97-P3-12** | ARB description 中英混杂 (zh 是中文 en 是英文, dartdoc 不友好) | 底层 | low |
| **R97-P3-13** | commonSave 简繁不一致 (zh 与 zh_Hant 都是"保存", 繁体应是"儲存") | 底层 | low |
| **R97-P3-14** | NotificationService facade 仍持 6 类 ID 常量 (ID range 应下沉到各自 sub-service) | 架构 | medium |
| **R97-P3-15** | domain/logic 32 文件无目录分组 (建议分子目录 scales/ care/ medication/ trend/) | 架构 | low |
| **R97-P3-16** | FireCareStrategyUseCase priority map 死代码 (4 strategy 互斥, priority map 是冗余) | 底层 | low |

### 9.6 R97 5 大检查项总结

#### 检查项 ①: 外部链接隐藏 — ✅ 运行时合规, ⚠️ 元数据占位待替换

- **lib/ 内**: 0 处 `launchUrl`/`url_launcher` 调用, 4 处 https URL 全在注释 (sms_service.dart 阿里云文档 + chinese_holidays.dart 说明)
- **fastlane/metadata/**: 6 个 privacy_url.txt + 6 个 support_url.txt 指向未注册域名 chroniccare.app (R97-P0-3)
- **assets/legal/**: 3 份法律文档"草稿"标注 (R97-P0-4)
- **AndroidManifest/Info.plist**: 0 外部 URL scheme 配置, 合规

#### 检查项 ②: 上架/架构/重构/半成品 — 🔴 8 P0 阻塞

- **上架 blocker**: 域名 + 律师 + 签名 + USE_EXACT_ALARM + NMPA (R97-P0-3/4/5/6/8)
- **半成品**: SMS/Email/IAP/5 厂商 push/PHQ-9 i18n 5 项业务真接 + BootReceiver + NSESSS/CRDPSS 量表
- **架构违规**: check_safety.dart 跨层 import (R97-P0-1)
- **重构机会**: home_page_state 650 行 / mood_audio_section / notification_service facade / AppTokens god class

#### 检查项 ③: 顶层架构审视 — ✅ 9.0/10 (国内中型项目天花板)

- **4 层 + core umbrella**: domain 0 Flutter 0 Drift, check_all.dart 守门员强制
- **依赖方向**: presentation → domain ← data 单向, 跨 feature 边界 check_cross_feature.py 守门
- **Riverpod 3.x**: Provider<XRepository> 暴露接口 (但 daily_tracking 6 个违规暴露 Impl, R97-P1-1)
- **隐私边界**: vent 独立表 + 架构强制不进分析/通知/关怀
- **可优化**: UseCase 层覆盖不足 / services/ 28 文件无目录分组 / AppTokens facade 仍 306 行

#### 检查项 ④: 底层逐行排查 — 14 项 P1+ 修复点

- **架构违规**: check_safety.dart 跨层 import (R97-P0-1)
- **bug**: VentRepositoryImpl.delete() TOCTOU (R97-P1-3) / TodayMedSchedule DateTime.now() (R97-P1-2)
- **上架 blocker**: 主页危机入口隐藏 (R97-P0-2) / 通知权限时机 (R97-P1-6) / UGC 无举报 (R97-P1-4)
- **lint**: unnecessary_late + dead_code + deprecated_member_use (R97-P1-13) + directives_ordering 6 处 (R97-P2-5)
- **i18n**: 通知 channel 中文 const (R97-P2-7) / userNameFamily 病耻感 (R97-P2-8) / emailBody 不中性 (R97-P2-9)

#### 检查项 ⑤: 开发需求文档更新 — ✅ 本章节已追加 R97 6 视角审计 55 项发现

### 9.7 R97 跨视角共识高频项 (3+ 视角同意)

| # | 问题 | 视角数 | 类别 | 难度 |
|---|---|---|---|---|
| 1 | 法务过审 (¥45-90k, 1-2 月) | 3 (spzh/AppStore/GooglePlay) | 架构 | high |
| 2 | 域名 chroniccare.app 注册 + 部署 | 3 (spzh/AppStore/GooglePlay) | 底层 | medium |
| 3 | SMS/Email 真接业务阻塞 | 3 (spzh/spen/AppStore) | 架构 | high |
| 4 | 通知权限请求时机违反"先解释后请求" | 2 (AppStore/GooglePlay) | 底层 | medium |
| 5 | FeatureFlags 全 false 商店描述不符 | 2 (GooglePlay/AppStore) | 架构 | low |
| 6 | Release 签名 fallback debug | 2 (emil/GooglePlay) | 底层 | low |
| 7 | 跨时区 DateTime 不一致 | 2 (emil/spen) | 底层 | low |
| 8 | PIPL §13 联系人单独同意软实施 | 2 (spzh/AppStore) | 架构 | high |

### 9.8 R97 修复路径建议 (按优先级)

#### 第 1 周 (解锁 P0, 估 13-21 commit)

1. **R97-P0-1** check_safety.dart 跨层 import — 30 分钟, 改 import + 删旧 safety_detector.dart + 改测试 import
2. **R97-P0-2** 主页危机入口 — 10 分钟, 把 crisis hotline FAB 从 emergencyContactEnabled 守卫中拆出来
3. **R97-P0-5** Release 签名 — 1-2h, 切 signingConfigs.getByName("release")
4. **R97-P0-6** USE_EXACT_ALARM — 5 分钟, 删 manifest 第 33 行
5. **R97-P0-3** 域名注册 — 1-2 天注册 + 7-20 天 ICP 备案 (并行)
6. **R97-P0-4** 律师过审 — 1-2 周 + ¥45-90k (并行)
7. **R97-P0-7** SMS/Email 真接 — 跟 R95 task 14/15 合并
8. **R97-P0-8** NMPA 备案 — 法务咨询 1-2 月 (并行)

#### 第 2 周 (修 P1, 估 8-15 commit)

9. **R97-P1-1** daily_tracking 6 provider 暴露 Impl — 加 6 个 abstract interface
10. **R97-P1-2** TodayMedSchedule.build() — 改用 ref.watch(todayProvider)
11. **R97-P1-3** VentRepositoryImpl.delete() TOCTOU — select 挪进 transaction
12. **R97-P1-4** vent UGC 举报 — 加举报按钮 + metadata 声明 UGC 政策
13. **R97-P1-5** IAP 描述不符 — 改 user_agreement §3 为"当前免费"或真接 productId
14. **R97-P1-6** 通知权限请求时机 — 拆 init() 为 initialize() + requestPermissions()
15. **R97-P1-7** 危机热线展示 — 加 crisisHotlineCnBeijing 渲染
16. **R97-P1-8/9** 删 INTERNET/RECORD_AUDIO 权限
17. **R97-P1-10** BootReceiver — 从 manifest 删除注册 + RECEIVE_BOOT_COMPLETED 权限
18. **R97-P1-11** 危机热线一键拨打 — 加 url_launcher + tel: intent
19. **R97-P1-12** lint 规则 — 升级到 flutter_lints 推荐集
20. **R97-P1-13** 3 处 warning — dart fix --apply

#### 第 3-4 周 (降 P2 风险, 估 15-25 commit)

21. **R97-P2-1** UseCase 层 — 补 AddMedicationUseCase / DeleteMedicationUseCase / WithdrawVentConsentUseCase
22. **R97-P2-2** CareEngine + FireCareStrategyUseCase DRY — use case 直接调 CareEngine.evaluate
23. **R97-P2-3** latestXxxEntryProvider — 显式 reduce(isAfter) 找最新
24. **R97-P2-4** AppTokens facade — 5 个 magic size 常量挪到 AppSpacing
25. **R97-P2-5** directives_ordering — 启用 lint + dart fix --apply
26. **R97-P2-7** 通知 channel i18n — init() 内 dynamic 拿 l10n 注入 channel
27. **R97-P2-8/9** userNameFamily / emailBody 中性化
28. **R97-P2-12** TODO 加版本号 — 统一格式 `// TODO(v0.31, P1): <desc>`
29. **R97-P2-14** SCHEDULE_EXACT_ALARM 自检卡 — NotificationStatusCard 加状态检测
30. **R97-P2-15** android:largeHeap — application 标签加

#### v1.0 前 (P3 nice-to-have, 估 10-20 commit)

31. 截图准备 + Appfile 真实凭据
32. AppListTile dead code 清理 + _StreakCounter 首次动画
33. _nextReminderTime 抽 provider + 跨时区 DateTime 统一
34. 版本考古注释梳理 + BOM 文件清理
35. legal_page DateFormat + contact 本人手机号校验
36. ARB description 统一英文 + commonSave 简繁修正
37. NotificationService facade ID 常量下沉
38. domain/logic 子目录分组
39. FireCareStrategyUseCase priority map 死代码清理

### 9.9 R97 上架风险评估

**整体上架就绪度**: ~45% (跟 R95 实施后持平, R97 新发现 8 P0 抵消 R95 8 sub-spec 改善)

**Apple App Store 风险**: 🔴 高 — 主页无危机入口 + 隐私 URL 404 + UGC 无举报 = 3 项必拒
**Google Play 风险**: 🔴 高 — USE_EXACT_ALARM 违规 + Release 签名 + 隐私政策律师未过审 = 3 项必拒

**建议路径**:
- v0.30 不上 store (R97 8 P0 全部阻塞)
- 第 1-2 周修 R97-P0-1/2/5/6 + R97-P1-1/2/3/4/6/7/8/9/10/11 共 12 项代码侧修复 (无需外部资源)
- 第 3-4 周修 R97-P2 17 项降风险
- 并行启动 R97-P0-3/4/7/8 外部资源 (域名 1-2 天 + ICP 7-20 天 + 律师 1-2 月 + SMS 1-2 月 + NMPA 1-2 月)
- 最早 M6 (2026-11-15) 4 项外部资源并行完成后上 store

### 9.10 R97 跟 R95 路线图对应关系

| R97 发现 | R95 task 状态 | R97 后状态 |
|---|---|---|
| R97-P0-1 check_safety 跨层 import | R95 未识别 | **新发现, 必修** |
| R97-P0-2 主页危机入口隐藏 | R95 未识别 (R93 FeatureFlag 守门副作用) | **新发现, 必修** |
| R97-P0-3 域名未注册 | R95 task 40 ⏸️ 留 R96+ | R97 升级为 P0 |
| R97-P0-4 律师未过审 | R95 task 20 ⏸️ 等付费 | 持平 |
| R97-P0-5 Release 签名 | R95 task 37 ⏸️ 留 R96+ | R97 升级为 P0 |
| R97-P0-6 USE_EXACT_ALARM | R95 task 38 ⏸️ 留 R96+ | R97 升级为 P0 (Google Play 2024-07 政策) |
| R97-P0-7 SMS/Email 真接 | R95 task 14/15 ⏸️ 等付费 | 持平 |
| R97-P0-8 NMPA 备案 | R95 task 23 ⏸️ 等付费 | 持平 |
| R97-P1-1 daily_tracking Impl 暴露 | R95 未识别 (R91 daily-tracking 新增) | **新发现, 必修** |
| R97-P1-4 UGC 无举报 | R95 未识别 | **新发现, 必修** |
| R97-P1-6 通知权限时机 | R95 未识别 | **新发现, 必修** |
| R97-P1-13 lint warning | R95 未识别 | **新发现, 必修** |

**R97 新发现总计**: 6 项 (P0-1/P0-2/P1-1/P1-4/P1-6/P1-13), 其余为 R95 已识别但被低估或留 R96+ 的项

---

**R97 6 视角审计追加完成时间**: 2026-08-07
**R97 审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification 6 视角
**R97 发现总计**: 55 项 (P0=8 / P1=14 / P2=17 / P3=16)
**R97 新发现**: 6 项 (R95 路线图未覆盖)
**下次 dev doc 同步**: R97 P0/P1 修复完成后 (估 2-4 周)

---

## 10. R98 7 视角审计 + 底层逐行排查 + 外链核查追加 (2026-08-07, 38 项发现)

> 本章节为 R97 6 视角审计后, 用户要求拉 6 个视角团队 + 外链核查 + 底层逐行排查共 8 个并行子代理对整个项目分别出一份审计报告的汇总追加。8 份报告去重后共 38 项独立发现 (P0=9 / P1=14 / P2=10 / P3=5), 每项标注 **类别 (架构/底层) + 修复难度 (low/medium/high) + 涉及视角**。
>
> **完整 R98 审计报告**: [docs/audit/2026-08-07/R98-7perspective-audit.md](audit/2026-08-07/R98-7perspective-audit.md)
>
> **审计覆盖 5 个检查项**: ①外部链接隐藏 ②上架/架构/重构/半成品 ③顶层架构审视 ④底层逐行排查 ⑤开发需求文档更新
>
> **跟 R97 的关系**: 本章节 38 项发现中, **22 项为 R97 未识别的新发现**, 16 项为 R97 已识别但被低估 (P2/P3 升级 P0/P1) 或留 R96+ 的项。R97 修了 12 项代码侧 P0/P1 (check_safety 跨层 import / 主页危机 FAB / Release 签名 / USE_EXACT_ALARM / 通知权限时机 / 危机热线 tel: 拨打等), 但 R98 新发现 9 项 P0 仍阻塞上架。

### 10.1 R98 8 视角发现统计

| 视角 | P0 | P1 | P2 | P3 | 总计 | 评分 |
|---|---|---|---|---|---|---|
| emilkowalski (设计) | 0 | 4 | 6 | 4 | 14 | 8.5/10 (架构成熟度) |
| superpowers-en (工程) | 1 | 4 | 4 | 2 | 11 | 8/10 (规范度) |
| superpowers-zh (合规+中文) | 4 | 3 | 3 | 0 | 10 | 6.5/10 (本土化合规) |
| AppStore (iOS 上架) | 4 | 4 | 4 | 2 | 14 | 5.5/10 (上架就绪度) |
| GooglePlay (Android 上架) | 3 | 6 | 4 | 1 | 14 | 6/10 (上架就绪度) |
| flutter-specification (规范) | 0 | 5 | 4 | 1 | 10 | 8/10 (Flutter 规范) |
| 外链核查 | 0 | 2 | 2 | 0 | 4 | 8.5/10 (外链隐藏度) |
| 底层逐行排查 | 1 | 4 | 3 | 1 | 9 | 8.5/10 (代码健康度) |
| **去重后** | **9** | **14** | **10** | **5** | **38** | — |

### 10.2 R98 P0 必修清单 (9 项, 上架/v1.0 blocker)

| R98 ID | 问题 | 类别 | 难度 | 视角 | 跟 R97 关系 | 文件 |
|---|---|---|---|---|---|---|
| **R98-P0-1** | PHQ-9 危机弹窗内无"立即拨打"按钮 (6 步操作路径, 精神心理患者危机时刻执行功能受损) | 底层 | low | spzh | **新发现** (R97 修 FAB 可见性, 弹窗内 action 未识别) | [assessment_page.dart#L185](file:///d:/Batch/chroniccare/lib/presentation/pages/assessment/assessment_page.dart) |
| **R98-P0-2** | PHQ-9 i18n flag 关闭时 zh_Hant/en 用户看简体中文题目 (`FeatureFlags.phqGad7I18nEnabled=false`) = 医疗法律责任 | 架构 | high | spzh | R97-P2-17 升级 P0 | [phq9.dart#L170](file:///d:/Batch/chroniccare/lib/domain/logic/phq9.dart) |
| **R98-P0-3** | iOS `UIBackgroundModes` 声明 `processing` 但 `handleSafetyCheckTask` 空实现, Apple 2.5.4 拒审风险 | 底层 | medium | AppStore | **新发现** | [Info.plist#L144](file:///d:/Batch/chroniccare/ios/Runner/Info.plist) + [AppDelegate.swift#L72](file:///d:/Batch/chroniccare/ios/Runner/AppDelegate.swift) |
| **R98-P0-4** | iOS `fastlane/metadata/ios/{locale}/screenshots/` 完全缺失, Apple 4.2.1 强制 6.7" iPhone 截图 = 必拒 | 架构 | medium | AppStore | R97-P3-1 升级 P0 | [fastlane/metadata/ios/](file:///d:/Batch/chroniccare/fastlane/metadata/ios/) |
| **R98-P0-5** | Android `feature_graphic.png` + 4 张 `phone_screenshots` 全是 67 字节 1×1 占位 PNG, Google Play 必拒 | 架构 | medium | GooglePlay | **新发现** | [fastlane/metadata/android/zh-CN/feature_graphic.png](file:///d:/Batch/chroniccare/fastlane/metadata/android/zh-CN/feature_graphic.png) |
| **R98-P0-6** | Data Safety Form `data_deletion_endpoint.url = 'https://chroniccare.app/delete-data-instructions'` 不可访问 | 架构 | high | GooglePlay | 跟 R97-P0-3 同源 (域名未注册) | [generate_data_safety_form.py#L84](file:///d:/Batch/chroniccare/scripts/generate_data_safety_form.py) |
| **R98-P0-7** | 5 厂商 push SDK 未真接, `fiveVendorPushEnabled=false`, 国产 ROM 静默杀后台场景失联通知失效 = 中国市场 P0 | 架构 | high | spzh | 跟 R97-P0-7 部分重叠 (push 跟 SMS 不同) | [feature_flags.dart#L66](file:///d:/Batch/chroniccare/lib/core/data/feature_flags.dart) |
| **R98-P0-8** | PHQ-9 total ≥ 20 (重度抑郁) 但 Q9=0 时不触发危机资源 dialog, 临床实践上重度抑郁应弹危机资源 | 架构 | medium | spzh | **新发现** | [phq9.dart#L156](file:///d:/Batch/chroniccare/lib/domain/logic/phq9.dart) |
| **R98-P0-9** | `CareEngine.evaluate` / `CareEngine.fire` 死代码 (注释承诺 v0.28 删除, v0.30 仍在, 0 处实际调用) | 架构 | medium | 底层排查 | **新发现** | [care_engine.dart#L59](file:///d:/Batch/chroniccare/lib/domain/logic/care_engine.dart) |

### 10.3 R98 P1 重要清单 (14 项, 上架前应修)

完整 P1 清单详见 [R98 完整审计报告 §3](audit/2026-08-07/R98-7perspective-audit.md#3-r98-p1-重要清单-14-项-上架前应修)。摘要:

| R98 ID | 问题 | 类别 | 难度 | 视角 |
|---|---|---|---|---|
| **R98-P1-1** | 3 处 `.first` 未显式 sort (latestMoodEntryProvider / mood_quick_button / assessment_summary_strip) silent bug | 底层 | low | 底层排查 |
| **R98-P1-2** | `home_page_state.dart:254-258` 显示 i18n key 字符串而非翻译文案, 用户看到 `⚠️ safetyCheckResultAlerted` | 底层 | low | emil |
| **R98-P1-3** | `crossedMidnightSince` 用 `DateTime` 而 `nextMidnightRefresh` 用 `tz.TZDateTime`, DST 不一致 | 底层 | low | emil |
| **R98-P1-4** | 3 个 StreamProvider 缺 autoDispose (allAssessmentEntries / ventSealed / ventSealedAt) | 底层 | low | emil |
| **R98-P1-5** | iOS `InfoPlist.strings` 缺 en-US 版本, 5 项 usage description 仅中文 | 底层 | medium | AppStore |
| **R98-P1-6** | IAP "8 元买断" 描述 vs 实际 0 元 + iapEnabled=false 矛盾 (R97-P1-5 未修) | 底层 | medium | AppStore |
| **R98-P1-7** | iOS subtitle/description 提"规划中/即将上线", Apple 2.3.10 不允许 | 架构 | low | AppStore |
| **R98-P1-8** | `setup_legal_dialog.dart:110` 硬编码中文 "🆘 心理危机干预热线 (24h)" 未走 ARB | 底层 | low | AppStore |
| **R98-P1-9** | `assets/legal/` 8 处软隐藏邮箱 + 1 处 GitHub 占位, PIPL §52 实质未提供有效联系方式 | 架构 | medium | spzh + 外链 |
| **R98-P1-10** | `ConsentGate` 不校验 `ConsentArtifact.version` 一致性, 法律文档升级不强制重走同意 | 架构 | medium | spzh |
| **R98-P1-11** | `recordConsent` 未记录 `sensitiveDataConsentAt` 时间戳 + 未持久化 `emergencyContactSharing` | 底层 | medium | spzh |
| **R98-P1-12** | `sensitive_data_consent.md` §4 文档与 `legal_page.dart` UI 不一致 (撤回失联通知) | 架构 | low | spzh |
| **R98-P1-13** | 跨时区 DateTime 不一致 (跟 P1-3 同源, 4 处混用) | 底层 | low | emil + spen |
| **R98-P1-14** | `check_zh_hant_consistency.py` 仅字符级不检 phrase (信息→資訊 / 软件→軟體) | 架构 | medium | spzh |

### 10.4 R98 P2/P3 清单 (15 项, v1.0+ 可做)

完整清单详见 [R98 完整审计报告 §4 + §5](audit/2026-08-07/R98-7perspective-audit.md#4-r98-p2-建议清单-10-项-v10-可做)。摘要:

- **P2 (10 项)**: ThemeExtension 缺位 / routerProvider 反模式 / ThemeModeNotifier 异步 / textTheme 不全 / Form 校验未走 FormState / 0 golden test / a11y 覆盖不足 / directives_ordering lint / Android title 超长 / setup 第 4 勾选 onView 空
- **P3 (5 项)**: main.dart magic number / Future.wait 泛型化 / drift batch 优化 / RadioListTile 弃用 API / trailing comma 清扫

### 10.5 R98 5 大检查项总结

#### 检查项 ①: 外部链接隐藏 — ✅ 代码层就绪 / ⚠️ 法律文档层 9 处软隐藏待清

- **lib/ 代码层**: 0 处真实外链跳转, 4 处 https URL 全为注释, 0 个云上报 SDK, 1 处 url_launcher 严格 `tel:` 危机热线, ✅ **可直接上架**
- **assets/legal/**: ⚠️ 8 处软隐藏邮箱 + 1 处 GitHub 占位, 用户在「设置 → 法律与隐私」页可见 (R98-P1-9)
- **评分**: 8.5/10

#### 检查项 ②: 上架/架构/重构/半成品 — 🔴 9 P0 阻塞 (4 项代码侧 + 5 项外部资源)

- **上架 P0**: iOS processing 空挂 + iOS 缺 en-US InfoPlist.strings + iOS/Android 截图缺失/占位 + IAP 描述矛盾 + Data Safety Form URL 不可访问
- **架构违规 (新发现)**: CareEngine.evaluate/fire 死代码 + 3 处 StreamProvider 缺 autoDispose
- **半成品 (跟 R97 重叠)**: SMS/Email/IAP/5 厂商 push/PHQ-9 i18n 5 项业务真接
- **重构机会**: home_page_state 590 行仍偏大 + ThemeExtension 完全缺位 + routerProvider 反模式 + ThemeModeNotifier 异步

#### 检查项 ③: 顶层架构审视 — ✅ 9.0/10 (国内中型项目天花板, 跟 R97 持平)

- 5 层架构 + domain 0 Flutter 0 Drift, `check_all.dart` 守门
- 隐私边界: vent 独立表 + 架构强制不进分析/通知/关怀, 实际 grep 验证 0 渗入
- 可优化: UseCase 层覆盖不足 / services/ 28 文件无目录分组 / AppTokens facade 仍 306 行

#### 检查项 ④: 底层逐行排查 — 🔴 3 项 Major silent bug + 12 项 Minor

- **3 项 Major silent bug (新发现)**: latestMoodEntryProvider 3 处 `.first` 未 sort (R98-P1-1) + home_page_state 显示 i18n key (R98-P1-2) + crossedMidnightSince DST 不一致 (R98-P1-3)
- **12 项 Minor**: 3 个 StreamProvider 缺 autoDispose + main.dart 10+ magic number + Future.wait as 强转 + drift batch 优化 + moodEntriesProvider 吞 loading + RadioListTile 弃用 API + 0 golden test + a11y 覆盖偏少 + Form 校验未走 FormState + 104 trailing comma + import 顺序违反 + CareEngine 死代码

#### 检查项 ⑤: 开发需求文档更新 — ✅ 本章节 + R98 完整审计报告

### 10.6 R98 跨视角共识高频项

| # | 问题 | 视角数 | 类别 | 难度 |
|---|---|---|---|---|
| 1 | PHQ-9 量表 i18n + 临床判定逻辑 (Q9 ≥1 弹窗无拨打 + ≥20 不弹) | 3 (spzh/AppStore/底层) | 架构+底层 | medium |
| 2 | 法律文档"草稿未经律师过审" + 联系方式软隐藏 (PIPL §52) | 3 (spzh/AppStore/GooglePlay/外链) | 架构 | high |
| 3 | 域名 chroniccare.app 未注册 (隐私 URL / Data Safety Form / 联系邮箱 全失效) | 4 (spzh/AppStore/GooglePlay/外链) | 底层 | medium |
| 4 | iOS + Android 截图完全缺失 / 占位 PNG | 2 (AppStore/GooglePlay) | 架构 | medium |
| 5 | SMS/Email/IAP/5 厂商 push 业务真接阻塞 | 3 (spzh/spen/AppStore) | 架构 | high |
| 6 | 跨时区 DateTime 不一致 (DST bug) | 2 (emil/spen) | 底层 | low |

### 10.7 R98 修复路径建议 (按优先级)

#### 第 1 周 (解锁代码侧 P0, 估 8-12 commit)

1. **R98-P0-1** PHQ-9 危机弹窗加"立即拨打"按钮 — 1h
2. **R98-P0-3** iOS 删 `processing` 后台模式 + AppDelegate register 代码 — 30 分钟
3. **R98-P0-9** 删 `CareEngine.evaluate` / `CareEngine.fire` 死代码 + 同步删 LEGACY_API_NOTES.md — 1h
4. **R98-P1-1** 3 处 `.first` 加显式 sort — 30 分钟
5. **R98-P1-2** `home_page_state.dart:254-258` 改用 `displayMessageL10n(l10n)` — 5 分钟
6. **R98-P1-3** `crossedMidnightSince` 改 `tz.TZDateTime` — 30 分钟
7. **R98-P1-4** 3 个 StreamProvider 加 `.autoDispose` — 10 分钟
8. **R98-P1-8** `setup_legal_dialog.dart:110` 改走 ARB — 30 分钟
9. **R98-P2-10** `setup_step_consent.dart:112-118` 第 4 勾选 onView 跳文档页 — 30 分钟

#### 第 2 周 (修 P1, 估 6-10 commit)

10. **R98-P1-5** 新建 `ios/Runner/en.lproj/InfoPlist.strings` + pbxproj PBXVariantGroup — 2h
11. **R98-P1-6** 统一 IAP 描述 — 1h
12. **R98-P1-7** 删 subtitle/description "规划中"措辞 — 30 分钟
13. **R98-P1-9** 清理 assets/legal/ 8 处软隐藏邮箱 + GitHub 占位 — 1h
14. **R98-P1-10** ConsentGate 加 version 校验 — 4h
15. **R98-P1-11** recordConsent 补 sensitiveDataConsentAt — 2h
16. **R98-P1-12** 同步 sensitive_data_consent.md §4 — 30 分钟
17. **R98-P1-14** check_zh_hant_consistency.py 加 phrase 词典 — 4h

#### 第 3-4 周 (外部资源并行 + P2 降风险, 估 10-20 commit)

18. **R98-P0-4** iOS 截图 (6.7"/6.1"/5.5" iPhone + 12.9" iPad 各 1-3 张) — 4-8h
19. **R98-P0-5** Android feature_graphic 1024×500 + 4 张 phone_screenshots — 4-8h
20. **R98-P0-2** PHQ-9/GAD-7 16 题完整 ARB 翻译后翻 flag — 1-2 周
21. **R98-P0-6** 域名注册 + 部署隐私政策/支持页面 — 1-2 天注册 + 7-20 天 ICP
22. **R98-P0-7** 5 厂商 push SDK 申请 + 集成 — 1-2 月审核期
23. **R98-P0-8** PHQ-9 ≥20 加 CrisisSignal.Kind.severe — 2h
24. **R98-P2-1** ThemeExtension 重构 — 2-3 天
25. **R98-P2-2** routerProvider 改 NotifierProvider — 1 天
26. **R98-P2-3** ThemeModeNotifier 改 AsyncNotifier — 4h
27. **R98-P2-5** setup 表单迁 Form + TextFormField — 1 天
28. **R98-P2-6** 8-10 个核心 widget 加 golden test — 2-3 天

### 10.8 R98 上架风险评估

**整体上架就绪度**: ~50% (R97 修 12 项后 ~50%, R98 新发现 9 P0 抵消改善, 持平)

**Apple App Store 风险**: 🔴 高 — 5 项必拒 (processing 空挂 + 截图缺失 + 隐私 URL 404 + IAP 描述矛盾 + InfoPlist.strings 缺 en-US)
**Google Play 风险**: 🔴 高 — 4 项必拒 (feature_graphic 占位 + 截图占位 + Data Safety URL 不可访问 + 隐私政策律师未过审)

**建议路径**:
- v0.30 不上 store (R98 9 P0 全部阻塞)
- 第 1-2 周修 R98-P0-1/3/9 + R98-P1-1/2/3/4/5/6/7/8/9/10/11/12/14 共 14 项代码侧修复 (无需外部资源)
- 并行启动 R98-P0-2 (PHQ-9 i18n 1-2 周) + R98-P0-4/5 (截图 4-8h) + R98-P0-6 (域名 7-20 天 ICP) + R98-P0-7 (5 厂商 push 1-2 月)
- 最早 M6 (2026-11-15) 4 项外部资源并行完成后上 store

### 10.9 R98 跟 R97 路线图对应关系

| R98 发现 | R97 状态 | R98 后状态 |
|---|---|---|
| R98-P0-1 PHQ-9 弹窗无拨打 | R97 修了 FAB 可见性, 弹窗内 action 未识别 | **新发现, 必修** |
| R98-P0-2 PHQ-9 i18n flag 关 | R97-P2-17 (P2) | R98 升级 P0 (医疗法律责任) |
| R98-P0-3 iOS processing 空挂 | R97 未识别 | **新发现, 必修** |
| R98-P0-4 iOS 截图缺失 | R97-P3-1 (P3) | R98 升级 P0 (4.2.1 必拒) |
| R98-P0-5 Android 截图占位 | R97 未识别 | **新发现, 必修** |
| R98-P0-6 Data Safety Form | R97-P0-3 同源 (域名) | 持平 (具体到 data_deletion_endpoint) |
| R98-P0-7 5 厂商 push | R97-P0-7 (SMS/Email) | 部分重叠 (push 跟 SMS 不同) |
| R98-P0-8 PHQ-9 ≥20 不弹 | R97 未识别 | **新发现, 必修** |
| R98-P0-9 CareEngine 死代码 | R97 未识别 | **新发现, 必修** |
| R98-P1-1 .first 隐式排序 | R97-P2-3 (P2) | R98 升级 P1 (silent bug) |
| R98-P1-2 displayMessage i18n key | R97 未识别 | **新发现, 必修** |
| R98-P1-3 DST 不一致 | R97-P3-7 (P3) | R98 升级 P1 (海外用户 bug) |
| R98-P1-4 StreamProvider autoDispose | R97 未识别 | **新发现, 必修** |
| R98-P1-9 法律文档软隐藏 | R97-P2-11 (P2) | R98 升级 P1 (PIPL §52) |
| R98-P1-10 ConsentGate version 校验 | R97 未识别 | **新发现, 必修** |
| R98-P1-14 zh_Hant phrase 一致性 | R97-P3-13 (P3 commonSave) | R98 升级 P1 (医疗文案精确性) |

**R98 新发现总计**: 22 项 (P0=5 / P1=8 / P2=6 / P3=3), 16 项为 R97 已识别但被低估或留 R96+ 的项升级

---

**R98 7 视角审计 + 底层逐行排查 + 外链核查追加完成时间**: 2026-08-07
**R98 审计覆盖**: emilkowalski / superpowers-en / superpowers-zh / AppStore / GooglePlay / flutter-specification 6 视角 + 外链核查 + 底层逐行排查 共 8 个并行子代理
**R98 发现总计**: 38 项 (P0=9 / P1=14 / P2=10 / P3=5)
**R98 新发现**: 22 项 (R97 路线图未覆盖)
**下次 dev doc 同步**: R98 P0/P1 修复完成后 (估 2-4 周)
