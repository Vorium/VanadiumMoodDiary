# v0.30 R95+ 路线图 (原 VERSION_1.0_PLAN, R93 后升级版)

**创建时间**: 2026-07-31 (R67)
**升级时间**: 2026-08-06 (R93 后, Mavis 6 视角审视)
**目的**: 记录 v0.30.0+85 R93 后 R95+ 路线图 + v1.0 bump 决策
**当前**: pubspec.yaml `version: 0.30.0+85` (R93 完成, 28 commit / +36 R93 tests)
**上一版**: v0.27.0+64 (R67) → 0.30.0+85 (R93) 历经 19 commit, 4 个 sub-spec (R84/R87/R90/R91) + 2 阶段修复 (R92/R93)

> **R95+ 综合审视报告**: [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](audit/2026-08-06/r95-increment/00-r95-summary.md) (45KB)
> **6 视角子报告**: [emil](audit/2026-08-06/r95-increment/01-emil.md) / [spen](audit/2026-08-06/r95-increment/02-spen.md) / [spzh](audit/2026-08-06/r95-increment/03-spzh.md) / [AppStore](audit/2026-08-06/r95-increment/04-appstore.md) / [GooglePlay](audit/2026-08-06/r95-increment/05-googleplay.md) / [flutter-spec](audit/2026-08-06/r95-increment/06-flutter-spec.md)
> **R92 6 视角基线**: [docs/audit/2026-08-06/00-summary-report.md](audit/2026-08-06/00-summary-report.md) (35KB)

---

## 0. 背景 (R93 后状态)

### 0.1 R67 → R93 19 commit 摘要

| Round | 范围 | 关键产出 |
|-------|------|----------|
| R68 | Apple 2.1 拒审 / IAP 隐藏 | IAP FeatureFlag 关 + user_agreement §3 文字改 |
| R69 | 双语描述 | pubspec.yaml description 加英文 |
| R70-R76 | 5 厂商 push plan / 通知 reminder | PUSH_PROVIDERS.md + 通知状态卡 |
| R77 | iOS 16KB alignment | 守门员 + 修 |
| R78-R83 | 法律文档 + vent 加密 + sprint 1 | 3 法律 md + vent contentTextEnc + privacy |
| R84 | CBT thought record (sub-spec 1) | CBT 5 栏 + 评估 |
| R85 | CBT PDF export (sub-spec 2) | PDF 导出 + 翻译 |
| R86 | cleanup | minor fixes |
| R87 | mood list page (sub-spec 3) | mood 列表 |
| R88 | daily tracking (sub-spec 4) | daily tracking 主页 |
| R89 | AI 撤回 | feature flag 隐藏 AI |
| R90 | assessment center (sub-spec 5) | 8 量表 + 顶部 chart |
| R91 | treatment placeholder (sub-spec 6) | 治疗整合页 |
| R92 | 6 视角审计修复 (sub-spec 7) | 410KB 报告 + 6 task 修复 |
| R93 | 6 视角审计修复 (sub-spec 8) | 8 业务 FeatureFlag 守门 + 36 R93 tests |

### 0.2 R93 关键决策 (sub-spec 8)

- **8 业务 FeatureFlag 守门** (技术暂停): IAP / 失联 / 5 厂商 / Email / vent audio / PHQ-9 / GAD-7 / bootReceiver
- **UI 完全 hidden** (`SizeBox.shrink`, 非 disabled)
- **跳过所有外部资源** (签名 / 域名 / 法务 / 阿里云 / Mac / 5 厂商 push)
- **17 守门员全绿** (16 .py + 1 .dart, R60 漏列的 `check_16kb_alignment.py` 补)
- **CHANGELOG [0.30.0] 顶部列 R95+ 待办 7 项**

### 0.3 R92 6 视角基线评分

| 视角 | 评分 | 上架就绪 |
|------|------|----------|
| emilkowalski (设计) | 7.5/10 | — |
| superpowers-en (工程) | 8.0/10 | — |
| superpowers-zh (合规) | 工程 8.0 / 合规 3.5 / 资质 1.0 / 中文 7.5 / Git 6.0 | — |
| AppStore (iOS) | 6.0/10 | iOS 6.0/10 |
| GooglePlay (Android) | 38% | Android 38% |
| flutter-spec (v3.1) | 84% 合规 | — |

**R92 关键结论**: 代码 / 架构 / 工程自动化是国内中型项目天花板, 但中国 + Apple + Google 三 store 全链路未跑通。

---

## 1. R93 后现状摸底 (v0.30.0+85, 已实测)

### 1.1 规模

| 指标 | 数值 | R92 报告对比 |
|------|------|--------------|
| lib/ .dart 文件 (排除 .g.dart) | **350** | R92 报告 341 (+9) |
| lib/ 总代码行 | **57,060** | R92 估 40K+ (+17K) |
| test/ 1672 pass | baseline 1636 → 1672 (+36 R93) | R92 baseline 1596 |
| 600+ 行大文件 (真业务) | **6 个** | R92 估"3 个" (低估 2 倍) |

### 1.2 600+ 行大文件清单 (R95+ 必拆)

| # | 文件 | 行数 | 类型 |
|---|------|------|------|
| 1 | `lib/domain/entities/scale_translations.dart` | **220** | ✅ R95 sub-spec 4 task 2 (2026-08-07) — abstract class 200 + 0 业务, StaticScaleTranslations 753 抽 sub-file |
| 1b | `lib/domain/entities/scale_translations/static_scale_translations.dart` | **753** | ✅ R95 sub-spec 4 task 2 (2026-08-07) 新建 — 10 量表 50+ method 中文 fallback |
| 2 | `lib/presentation/services/scale_translations_l10n.dart` | **708** | presentation i18n 适配器 (R95 sub-spec 4 task 2 配套, 可选 commit, 估 1-2 commit) |
| 3 | `lib/presentation/pages/home/home_page.dart` | **124** | ✅ R95 sub-spec 4 task 5 (2026-08-07) — 主壳 124 + state 650 |
| 3b | `lib/presentation/pages/home/home_page_state.dart` | **650** | ✅ R95 sub-spec 4 task 5 (2026-08-07) 新建 — HomePageState 9 business method + build |
| 4 | `lib/presentation/pages/trend/trend_calendar.dart` | **281** | ✅ R95 sub-spec 4 task 6 (2026-08-07) — 主壳 281 (CalendarView + _CalendarCell), DayDetailCard 335 抽 sub-file, EventRow 104 抽 sub-file |
| 4b | `lib/presentation/pages/trend/widgets/trend_day_detail_card.dart` | **335** | ✅ R95 sub-spec 4 task 6 (2026-08-07) 新建 — R84 CBT 5/7 栏摘要展开 |
| 4c | `lib/presentation/pages/trend/widgets/trend_event_row.dart` | **104** | ✅ R95 sub-spec 4 task 6 (2026-08-07) 新建 — EventRow 4 kind + kindVisuals 集中器 |
| 5 | `lib/presentation/pages/settings/widgets/data_management_section.dart` | **49** | ✅ R95 sub-spec 1 task 1 (2026-08-06) — 拆 6 sub-tile + 1 export_dialog, 0 业务变更 |
| 6 | `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | **36** | ✅ R95 sub-spec 4 task 7 (2026-08-07) — 主壳 36 re-export, types 68 抽 sub-file, recorder 535 抽 sub-file |
| 6b | `lib/presentation/pages/mood/widgets/mood_audio_types.dart` | **68** | ✅ R95 sub-spec 4 task 7 (2026-08-07) 新建 — Snapshot / Controller / ErrorKind |
| 6c | `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | **535** | ✅ R95 sub-spec 4 task 7 (2026-08-07) 新建 — MoodRecorder widget |

### 1.3 token 残留 (R92 数字低估 16%)

| 类型 | R92 报告 | **R93 后实测** | 差异 | 主要集中 |
|------|----------|----------------|------|----------|
| `TextStyle(...)` 字面量 | 158 | **224** | +66 (+42%) | `app_typography.dart` 18 + `app_theme.dart` 14 + `medication_report_pdf_layout.dart` 12 (PDF 特殊) |
| `EdgeInsets.*` 字面量 | 162 | **208** | +46 (+28%) | `medication_report_pdf_layout.dart` 12 (PDF 特殊) + `trend_calendar.dart` 10 |
| `Duration(...)` 字面量 | 50+ | **96** | +46 (+92%) | 17 个已 token, 79 个 magic 残留 |
| `Curves.*` 字面量 | 50+ | **9** | -41 (R93 大幅改善) | 全部在 token 层 ✅ |
| `catch (_) {` 静默吞错 | 11+ | **10** | -1 (R93 修 3 处) | `export_schema_service.dart` 3 + 7 个其他文件 |

### 1.4 硬编码中文文件 Top 10 (按字符数, 排除 l10n 生成文件)

| # | 文件 | 中文字符 | 行数 | R95+ 优先级 |
|---|------|----------|------|-----------|
| 1 | `lib/domain/entities/scale_translations.dart` | **1528** | 326 | **P0 必修** |
| 2 | `lib/presentation/pages/home/home_page.dart` | 580 | 204 | P1 |
| 3 | `lib/core/theme/app_colors.dart` | 538 | 176 | P3 (注释) |
| 4 | `lib/main.dart` | 532 | 137 | P2 (错误信息) |
| 5 | `lib/core/data/database/app_database.dart` | 502 | 163 | P3 (注释) |
| 6 | `lib/core/l10n/strings.dart` | 479 | 155 | **P0 必修 (跨层共享)** |
| 7 | `lib/core/data/services/notification_service.dart` | 448 | 124 | P3 (注释) |
| 8 | `lib/core/data/services/sms_service.dart` | 432 | 128 | P3 (注释) |
| 9 | `lib/presentation/services/scale_translations_l10n.dart` | ~400 | 708 | **P0 配 scale_translations** |
| 10 | `lib/core/data/services/email_service.dart` | ~350 | 200+ | P3 (注释) |

---

## 2. R95+ 综合路线图 (60 task, 按 P0 → P3 排)

### 2.1 阶段 1: P0 必做 (0-4 周, 估 13-21 commit, +90 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 1** | ✅ 拆 `data_management_section.dart` 606→49 行 → 6 sub-tile + 1 export_dialog (R95 sub-spec 1, 2026-08-06) | 底层 (god section) | L | 1-2 周 | — |
| **R95 task 2** | ✅ 拆 `scale_translations.dart` 953 → 2 文件 (abstract 200 + StaticScaleTranslations 753, R95 sub-spec 4, 2026-08-07) | 底层 (god service) + i18n | L | 2-3 周 | — |
| **R95 task 3** | 224 TextStyle 集中器化 (保留 PDF 字体 12 个) | 底层 (token 化) | L | 1-2 周 | — |
| **R95 task 4** | 208 EdgeInsets + 96 Duration 中 79 个 magic 集中器化 | 底层 (token 化) | L | 1-2 周 | — |
| **R95 task 5** | ✅ 拆 `home_page.dart` 731 → 2 文件 (主壳 124 + state 650, R95 sub-spec 4, 2026-08-07) | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 6** | ✅ 拆 `trend_calendar.dart` 668 → 3 文件 (CalendarView 281 + DayDetailCard 335 + EventRow 104, R95 sub-spec 4, 2026-08-07) | 底层 (god page) | XL | 1-2 周 | — |
| **R95 task 7** | ✅ 拆 `mood_audio_section.dart` 591 → 3 文件 (主壳 36 re-export + types 68 + recorder 535, R95 sub-spec 4, 2026-08-07) | 底层 (god widget) | L | 1-2 周 | — |
| **R95 task 8** | ✅ 9 处 catch (_) → `swallowError` 集中器 (R95 sub-spec 2, 2026-08-06, 实际 R23 P1-10 已修, 加 16 lock-in tests 防御) | 底层 (静默吞错) | M | 1 周 | — |
| **R95 task 9** | ✅ 2026-08-06 R95 sub-spec 3 完成 | 底层 (i18n) | L | — | task 2 |
| **R95 task 10** | ✅ 删 4 个半成品 widget (email_preview 整文件 + mood_dialog 薄壳 + refill 2x2 grid + setup_step_med PressFeedback, R95 sub-spec 2, 2026-08-06, 6 commit + 11 widget tests) | 底层 (半成品清理) | M | 1 周 | — |
| **R95 task 25** | ✅ `vent_compose dispose 异步未 await` (R95 sub-spec 2, 2026-08-06, 实际 R79 (cf3db24) 已修, 加 5 lock-in tests 防御) | 底层 (resource leak) | S | 2-3d | — |
| **R95 task 26** | ✅ `badge_sync_service catch (e) 加 swallowError` (R95 sub-spec 2, 2026-08-06, 实际 R79 (fec978f) 已修, 加 3 lock-in tests 防御) | 底层 (静默吞错) | S | 1-2d | — |
| **R95 task 30** | `assessment_dao._rowToEntry` 解析失败 PII 泄露 | 底层 (PII 泄露) | S | 2-3d | — |
| **R95 task 31** | audit log 明文 (PIPL §47 删除权) | 底层 (PIPL 合规) | M | 1 周 | — |
| **R95 task 5+** | `mood_period_aggregator` pre-existing fail 修 (R91 集成遗留) | 底层 (test fail) | M | 1-2d | — |

**阶段 1 总估时**: 13-21 周 (1 人), 15+ commit, +90 R95 tests, 风险低
**建议执行顺序**: task 1-4 (token 化练手) → task 8-10 (静默吞错/半成品清理) → task 5-7 (god page 拆)

### 2.2 阶段 2: P1 重要 (4-12 周, 估 8-15 commit, +50 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 11** | 5 厂商 push SDK 接入 (米/华/OPP/vivo/魅族) | 业务真接 | XL | 4-8 周 | 法务 |
| **R95 task 12** | 8 量表 PHQ-9 / GAD-7 16 题 i18n 真接 (法务 + 临床审核) | 业务真接 | XL | 4-6 周 | task 2 |
| **R95 task 13** | IAP 8 元买断真接 productId (App Store Connect) | 业务真接 | M | 1-2 周 | 苹果审核 |
| **R95 task 14** | 阿里云 SMS 真接 (法务模板 + AccessKey 申请) | 业务真接 | XL | 1-2d + 2-4w 审核 | task 11 法务 |
| **R95 task 15** | EmailService 真接 SendGrid (法务模板 + API key) | 业务真接 | L | 1-2w | 法务 |
| **R95 task 16** | 主页信息架构重排 (emil "3 tap 抵达") | 架构 (UX) | XL | 1-2 周 | task 5 |
| **R95 task 17** | 设置页 8 section → 4 group 重构 (用户档案 / 提醒 / 数据 / 法律) | 架构 (UX) | L | 1-2 周 | — |
| **R95 task 18** | 紧急联系人 5 步 → 3 步 (emil "3 tap 抵达") | 架构 (UX) | L | 1 周 | — |
| **R95 task 19** | 数据导出 5 步 → 3 步 | 架构 (UX) | M | 1 周 | task 1 |
| **R95 task 20** | 法务过审 (¥45-90k, 1-2 月, 3 份 md 律师签字) | 业务真接 | XL | 4-8 周 | — |
| **R95 task 21** | 主体资质 (ICP / 公安备案 / 等保) | 业务真接 | XL | 4-8 周 | — |
| **R95 task 22** | 临床审核 (PHQ-9 / GAD-7 临床有效性) | 业务真接 | XL | 4-8 周 | task 12 |
| **R95 task 23** | NMPA 备案 (医疗 App 上架前, 1-2 月) | 业务真接 | XL | 4-8 周 | — |
| **R95 task 27** | 集成测试 1 → 3-5 个 | 架构 (测试覆盖) | L | 1-2 周 | — |
| **R95 task 28** | coverage 阈值 (≥ 70% domain / 50% data) + Codecov | 架构 (CI 守护) | M | 1-2 周 | — |
| **R95 task 29** | 18+ service 子类 sub-service 测试 (R56c 续修) | 底层 (测试覆盖) | L | 1-2 周 | — |
| **R95 task 32** | `app_router.dart` redirect 嵌套路径 startsWith 守卫 | 底层 (路由守卫) | M | 3-5d | — |
| **R95 task 37** | `setup_page` wizard 4 step 内部 state 化 (R76 P3-2 完整版) | 架构 (state 化) | M | 1-2 周 | — |

**阶段 2 总估时**: 4-12 周 (1 人, 业务真接并行), 8-15 commit, +50 R95 tests
**关键风险**:
- task 11 (5 厂商 push) 风险最大 (1-2 月审核), 应**提前启动**不阻塞其他
- task 12 (PHQ-9 i18n) 临床审核风险, 跟 task 2 配
- task 20 (法务) ¥45-90k 预算风险, 应**提前付费**

### 2.3 阶段 3: P2 建议 (12-24 周, 估 15-25 commit, +30 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 24** | `notification_service.dart` 450 行再拆 1 层 facade | 架构 (god service) | L | 1-2 周 | — |
| **R95 task 33** | iOS 18+ Dark Mode App Icon 4 套 (设计师 2-3d) | 业务 (上架) | M | 2-3d | 设计师 + Mac |
| **R95 task 34** | iOS 截图 + AppIcon 1024 真设计 (设计师 2-3d) | 业务 (上架) | L | 2-3d | 设计师 + Mac |
| **R95 task 35** | iOS Podfile 真生成 (Mac 跑 `pod install`) | 业务 (上架) | S | 0.5d | Mac |
| **R95 task 36** | iOS DEVELOPMENT_TEAM 填 + 签名 | 业务 (上架) | S | 1-2h | Mac |
| **R95 task 37** | Android keystore + Play App Signing | 业务 (上架) | S | 1-2h | 脚本 |
| **R95 task 38** | USE_EXACT_ALARM Play Console justification 100+ 字符 | 业务 (上架) | S | 1-2h | — |
| **R95 task 39** | Data Safety Form / Health Apps questionnaire | 业务 (上架) | M | 1-2d | — |
| **R95 task 40** | 域名 `chroniccare.app` 注册 + 隐私/删除 URL 部署 | 业务 (上架) | M | 1-2d + 3-5d 部署 | — |
| **R95 task 41** | 邮箱注册 (`support@` / `privacy@chroniccare.app`) | 业务 (上架) | S | 1-2h | task 40 |
| **R95 task 42** | iOS iCloud Backup 排除 (kCFURLIsExcludedFromBackupKey) | 业务 (上架) | S | 0.5d | Mac |
| **R95 task 43** | iOS description.txt 改文案 (删"会发短信") | 业务 (上架) | S | 0.5d | — |
| **R95 task 53** | `main.dart` 532 字符硬编码中文错误信息 → 走 ARB | 底层 (i18n) | M | 1-2d | — |
| **R95 task 54** | `app_database.dart` 502 字符硬编码中文注释 → 翻译文档 | 底层 (i18n) | XS | 1-2h | — |
| **R95 task 55** | 少量 hardcoded string 跟 ARB 重复清理 | 底层 (i18n) | S | 1-2d | — |

### 2.4 阶段 4: P3 nice-to-have (24+ 周, 估 10-20 commit, +20 R95 tests)

| Task | 描述 | 类型 | 难度 | 估时 | 依赖 |
|------|------|------|------|------|------|
| **R95 task 44** | 主页 hero illustration 真组件 (替换 140dp 占位) | UX (emil) | M | 2-3d | 设计师 |
| **R95 task 45** | 主页 header 3 icon button 加 tooltip | UX (emil) | XS | 1-2h | — |
| **R95 task 46** | `legal_page` toggle 加 chip 标识撤回时间 | UX (emil) | XS | 1-2h | — |
| **R95 task 47** | 通知状态卡 17 步纯文字 0 截图 0 链接 → 加截图 | UX (emil) | M | 1-2d | 设计师 |
| **R95 task 48** | vent 长按/swipe 删除 0 视觉提示 | UX (emil) | XS | 1-2h | — |
| **R95 task 49** | `mood_dialog.dart` 25 行薄壳 → 直接 `MoodRecorderPage` | 架构 (UX) | XS | 1-2h | — |
| **R95 task 50** | `setup_step_medication.dart` PressFeedback + LoadingSpinner | UX (emil) | XS | 1-2h | — |
| **R95 task 51** | 趋势页 4 StatCard 数字挤一起 → 2x2 grid | UX (emil) | XS | 1-2h | task 6 |
| **R95 task 52** | 抽 `AudioController` 抽象, vent + mood 4 widget 共享 | 架构 (抽象) | L | 1-2 周 | task 7 |
| **R95 task 56** | `main.dart:41,54` 顶层 mutable static (S, 3 行) | 底层 (state) | S | 1-2h | — |
| **R95 task 57** | `FeatureFlags` 全局静态可变状态 (R67 trade-off 重评) | 底层 (state) | S | 1-2d | — |
| **R95 task 58** | `notification_navigation.dart` BGTaskScheduler iOS handler `setTaskCompleted` | 底层 (iOS) | S | 0.5d | Mac |
| **R95 task 59** | 5 厂商 + 鸿蒙/HarmonyOS NEXT 适配 | 业务 (国产) | XL | 4-8 周 | task 11 |
| **R95 task 60** | TestFlight 跑 100+ 真实用户 | 业务 (测试) | M | 2-4 周 | — |
| **R95 task 61-67** | 其它 P3 (Cursor / CODEOWNERS / format / AppDelegate / 跨 round 文档 / 8 量表决策 / legal_version 自动化) | 底层 / 工具 | XS-S | 1-2h each | — |

---

## 3. 修复优先级矩阵 (架构 vs 底层, 难度 × 优先级)

### 3.1 难度 × 优先级矩阵

| | XS (1-2h) | S (1-2d) | M (1-2 周) | L (1-2 月) | XL (2+ 月) |
|---|-----------|----------|------------|------------|------------|
| **P0 必做** | task 41 (邮箱) | task 25, 26, 30, 36-38, 42-43 | task 5+ (mood_period), 8, 10, 17, 18, 23, 31 | task 1, 2, 3, 4, 7, 9 | task 5, 6, 11, 12, 14, 20, 21, 22, 23 |
| **P1 重要** | — | — | task 16, 19, 27, 32, 39 | task 15, 17, 18, 27, 28, 29 | — |
| **P2 建议** | task 54 | task 35, 36, 41, 43, 55 | task 24, 33, 39, 42, 53 | task 34, 40 | — |
| **P3 nice** | task 45, 46, 48, 49, 50, 51, 54, 56, 61, 62-67 | task 21, 26, 35, 41, 43, 55, 58 | task 44, 47, 60 | task 52 | task 59 |

### 3.2 架构 vs 底层分类

| 类型 | R95+ task 数 | 占比 |
|------|---------------|------|
| **架构 (跨模块)** | 12 (task 5, 6, 11, 14, 16, 17, 19, 20, 21, 22, 23, 52, 59) | 20% |
| **底层 (单文件/单类)** | 48 (其余) | 80% |
| - god page 拆 (5) | 5 (task 1, 2, 5, 6, 7) | 8% |
| - token 化 (3) | 3 (task 3, 4) | 5% |
| - 静默吞错 (2) | 2 (task 8, 26) | 3% |
| - i18n (3) | 3 (task 9, 53, 54, 55) | 5% |
| - 上架配置 (8) | 8 (task 33-43) | 13% |
| - 业务真接 (5) | 5 (task 11, 12, 14, 15, 22) | 8% |
| - 测试覆盖 (4) | 4 (task 27, 28, 29) | 5% |
| - 半成品清理 (1) | 1 (task 10) | 2% |
| - UX 体验 (10) | 10 (task 44-51) | 17% |
| - P3 misc (5) | 5 (task 56-67) | 8% |

**架构 12 + 底层 48 = 60 R95+ task 估算**

### 3.3 估时汇总

| 阶段 | task 数 | commit 估 | tests 估 | 估时 | 难度占比 |
|------|---------|-----------|----------|------|----------|
| 阶段 1 (P0) | 15 | 13-21 | +90 | 13-21 周 | XL 30% / L 50% / M 15% / S 5% |
| 阶段 2 (P1) | 18 | 8-15 | +50 | 4-12 周 | XL 50% / L 35% / M 15% |
| 阶段 3 (P2) | 15 | 15-25 | +30 | 12-24 周 | L 40% / M 40% / S 20% |
| 阶段 4 (P3) | 15 | 10-20 | +20 | 24+ 周 | XL 20% / L 20% / M 30% / S 30% |
| **总** | **60+** | **46-81** | **+190** | **53+ 周** | — |

---

## 4. 6 视角整合建议 (跨视角去重 + 共识)

### 4.1 跨视角高频 P0 (3+ 视角同意)

| # | 描述 | 视角 | 难度 | 估时 |
|---|------|------|------|------|
| 1 | 法务过审 (¥45-90k, 1-2 月) | spzh / AppStore / GooglePlay | XL | 4-8 周 |
| 2 | 5 厂商 push SDK 接入 (1-2 月) | spzh / GooglePlay | XL | 4-8 周 |
| 3 | PHQ-9 / GAD-7 16 题 i18n 真接 | spzh / flutter-spec | XL | 4-6 周 |
| 4 | 阿里云 SMS 真接 (法务 + AccessKey) | spzh / AppStore / GooglePlay | XL | 1-2d + 2-4w 审核 |
| 5 | EmailService 真接 SendGrid | spzh / AppStore / GooglePlay | L | 1-2 周 |
| 6 | 域名 + 邮箱注册 | spzh / AppStore / GooglePlay | S-M | 1-2d |
| 7 | IAP 8 元买断真接 | spzh / AppStore / GooglePlay | M | 1-2 周 |
| 8 | 拆 5 个 god page (data_mgmt / scale / home / trend / mood_audio) | emil / spen / flutter-spec | L-XL | 6-9 周 |
| 9 | 224 TextStyle + 208 EdgeInsets 集中器化 | emil / flutter-spec | L | 1-2 周 |
| 10 | 30+ 硬编码中文 → 走 ARB | spzh / flutter-spec | L | 1-2 周 |
| 11 | 10 处 catch (_) 静默吞错 → swallowError | spen / flutter-spec | M | 1 周 |
| 12 | Android keystore + Play App Signing | GooglePlay / flutter-spec | S | 1-2h |
| 13 | iOS 签名 + DEVELOPMENT_TEAM 填 + Podfile | AppStore / flutter-spec | S | 1h |
| 14 | iOS 截图 + AppIcon 1024 真设计 (R93 删 36 张占位但真截图未补) | AppStore | L | 2-3d |
| 15 | 删 4 个半成品 widget (email_preview / mood_dialog / refill / setup_step_med) | emil / spen | M | 1 周 |

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

## 5. v1.0 决策路径 (基于 R67 + R93 后更新)

### 5.1 v1.0 bump 7 个前置条件 (R67 原 5 + R93 后加 2)

| 条件 | 状态 | 来源 | 备注 |
|------|------|------|------|
| ✅ P0-A: Sprint 1 上架前 P0 全修 | ✅ R67 完成 | R67 | 16 守护脚本全绿 + 0 analyzer error |
| ⏳ P0-B: Sprint 2 iOS / Android 守护补齐 | ⏳ R95 task 35-39, 41-43 | R95+ | iOS Podfile / Android keystore / 5 厂商 / etc. |
| ⏳ P0-C: 法务过审 (R67 §1/§2/§3 法律文档) | ⏳ R95 task 20-23 | R95+ | ¥45-90k 法务, 1-2 月 |
| ⏳ P1: Sprint 3 P1 警告全清 (R66 标 12+12 项) | ⏳ R95 task 11-19 | R95+ | IAP / 阿里云 SMS / 5 厂商 / etc. |
| ⏳ P2: 重构机会 (R66 §4 重构清单) | ⏳ R95 task 1-9, 27-32 | R95+ | 拆 god page / token 化 / 集成测试 |
| 🆕 P0-D: 业务真接 (5 厂商 push + PHQ-9 i18n + IAP + 阿里云 SMS + Email) | 🆕 R95 task 11-15 | R93 后 | R67 时未识别, R93 后 FeatureFlag 守门, 业务真接后翻 true |
| 🆕 P0-E: 主体资质 + 临床审核 + NMPA 备案 | 🆕 R95 task 21-23 | R93 后 | R67 时未识别, 中国医疗 App 上架前必做 |

### 5.2 决策路径 (M1-M8, R67 原 M1-M7 + R93 后加 M8)

| 阶段 | 时间 | 动作 |
|------|------|------|
| M0 当前 | 2026-08-06 | v0.30.0+85 R93 完成, **R95 sub-spec 1 完成** (拆 data_management_section 606→49 行 + 16 R95 sub-spec 1 tests), 8 业务 FeatureFlag 守门 + 17 守门员全绿 |
| M1 R95 阶段 1 | 2026-08-13 (估) | R95 task 1-10 (P0 必做) 完成, 1672 → 1762 tests (+90 R95) |
| M2 R95 阶段 2 | 2026-09-15 (估) | R95 task 11-19 (P1 业务真接 + 上架配置) 完成, 1762 → 1812 tests (+50) |
| M3 R95 阶段 3 | 2026-11-15 (估) | R95 task 21-43 (P2 上架 + 测试覆盖) 完成, 1812 → 1842 tests (+30) |
| M4 R95 阶段 4 | 2027-01-15 (估) | R95 task 44-60 (P3 UX + nice-to-have) 完成, 1842 → 1862 tests (+20) |
| M5 法务过审 | 2026-09-15 (估, 并行 M2) | ¥45-90k 法务付费 + 3 份 md 律师签字 |
| M6 主体资质 | 2026-11-15 (估, 并行 M3) | ICP / 公安备案 / 等保 / NMPA 备案 |
| M7 提交审核 | 2026-12 (估) | v0.35.0+90 (R95 阶段 1+2+3) 提交 Apple + Google |
| M8 v1.0 决策 | 2027-03 (估) | **决策点**: 评估是否 bump 到 1.0.0+1 |

**v1.0.0 决策的硬门槛** (任何一项没满足 = 不 bump):
- [ ] 7 个前置条件 (P0-A / P0-B / P0-C / P0-D / P0-E / P1 / P2) 全部 ✅
- [ ] 真接阿里云 SMS (R95 task 14) — 至少真接 1 个 SMS provider
- [ ] 真接 SendGrid 邮件 (R95 task 15)
- [ ] 法务过审完 (R95 task 20)
- [ ] 5 厂商 push SDK 接入 (R95 task 11)
- [ ] PHQ-9 / GAD-7 16 题 i18n 真接 (R95 task 12)
- [ ] IAP 8 元买断真接 (R95 task 13)
- [ ] 主体资质 + 临床审核 + NMPA 备案 (R95 task 21-23)
- [ ] 至少 100 个真实用户跑过 (TestFlight 100+)
- [ ] 17 守护脚本 0 violation (含 R60 新增的 check_16kb_alignment.py)
- [ ] R95 60 task 全部完成 (或 80%+)

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

## 6. 风险与备选

### 6.1 R95 主要风险

| # | 风险 | 概率 | 影响 | 应对 |
|---|------|------|------|------|
| 1 | god page 拆 5 个 (home / trend / data_mgmt / mood_audio / scale) 风险大, 1000+ 行 sub-widget 移动可能引 bug | 中 | 高 | task 1-4 练手 → task 5-7 主力, 每个 task 1 subagent 实施 + 1 subagent review |
| 2 | 法务过审 ¥45-90k 预算 + 1-2 月时长, 现金流风险 | 中 | 高 | 提前付费, 不阻塞其他 task |
| 3 | 5 厂商 push SDK 接入 1-2 月审核, 可能失败 1-2 个 | 中 | 高 | 并行接入, 失败 1-2 个不影响其他 |
| 4 | 224 TextStyle + 208 EdgeInsets 集中器化, 守门员加严可能引 50+ 老 test 失败 | 高 | 中 | 加严前先跑 1 轮 baseline, 估计失败数, 预留 1 周修老 test |
| 5 | PHQ-9 / GAD-7 临床审核可能 1-2 月 + 多次返工 | 中 | 中 | task 2 配 scale_translations 拆 + task 9 配硬编码中文 → 临床审核前先业务真接 |
| 6 | `mood_period_aggregator` pre-existing fail 修可能引其他 test 失败 | 低 | 中 | task 5+ 配 R91 集成时遗留, 单 task 修 |
| 7 | 主页信息架构重排 emil XL, 可能 2-3 周 | 中 | 中 | task 5 拆 home_page + task 16 配重排, 串行 |
| 8 | Android keystore + iOS 签名 配置 1-2h 但实际需 Mac + 苹果审核 | 低 | 高 | 跟 R95 task 35-37 配 |

### 6.2 备选方案

| 备选 | 适用场景 | 改动 |
|------|----------|------|
| **方案 A (推荐)**: R95 60 task 全做 (估 53+ 周) | v1.0 决策点 M8 (2027-03) | 现有路线图 |
| **方案 B**: R95 阶段 1+2 (P0+P1, 估 17-33 周) | 提前 1.0 (M8 提前到 2026-12) | 跳过 P2/P3, P2 留 R96+ |
| **方案 C**: R95 阶段 1 only (P0, 估 13-21 周) | 极端保守, 只修 god page + token 化 | 跳过所有业务真接 + 上架配置, v1.0 推迟到 2027-Q3+ |
| **方案 D**: 跳过 R95, 直接 1.0 提交 v0.30.0+85 | 极早期, 风险大 | 4.3 Spam 拒, 退款风险高 |

---

## 7. dev doc 同步 (R95 期间持续更新)

### 7.1 R95 期间必更新文件

| 文件 | 更新内容 | 频率 |
|------|----------|------|
| `docs/VERSION_1.0_PLAN.md` (本文件) | R95 task 进度 + M1-M8 时间表调整 | 每周 |
| `docs/CHANGELOG.md` | 每 task 完成后增 entry | 每 task |
| `AGENTS.md` | 17 守门员补 (R60 漏列 check_16kb_alignment.py) + 5 大文件状态表 | R95 阶段 1 后 |
| `README.md` | R95 红 banner (业务真接进度) | 每月 |
| `docs/audit/2026-08-06/r95-increment/` | 6 视角子报告随 R95 进展更新 | 每阶段后 |
| `docs/decisions/v0.30_round95_design_decisions.md` (新建) | R95 关键设计决策 (token 化 / god page 拆 / 业务真接) | 关键决策点 |

### 7.2 R95 决策 ledger (`.superpowers/sdd/round95-*.md`)

跟 R84-R93 SDD 模式一致, 每个 sub-spec (估 3-4 个):
- `round95-token-and-godpage/`: task 1-7 (god page 拆 + token 化)
- `round95-i18n-and-safety/`: task 8-10, 25-26, 30-31 (静默吞错 + 半成品清理 + 资源泄漏 + PII + audit log)
- `round95-business-onboard/`: task 11-23 (业务真接 + 法务 + 主体资质 + 临床审核 + NMPA)
- `round95-store-config/`: task 33-43 (iOS / Android 上架配置)

### 7.3 R95 守门员加严 (估 +5 个)

| # | 守门员 | 描述 |
|---|--------|------|
| 1 | `check_textstyle_residual.py` | 限制 TextStyle 字面量数 (R95 后 < 50) |
| 2 | `check_edgeinsets_residual.py` | 限制 EdgeInsets 字面量数 (R95 后 < 50) |
| 3 | `check_duration_residual.py` | 限制 Duration 字面量数 (R95 后 < 30) |
| 4 | `check_hardcoded_chinese.py` | 加严, 限制硬编码中文业务 hotspot (R95 后 < 100 字符) |
| 5 | `check_silent_catch.py` | 限制 catch (_) 数 (R95 后 < 3) |

---

## 8. 引用

### 8.1 R95+ 综合审视报告 (本次新写)

- [docs/audit/2026-08-06/r95-increment/00-r95-summary.md](audit/2026-08-06/r95-increment/00-r95-summary.md) (45KB, 主综合报告)
- [docs/audit/2026-08-06/r95-increment/01-emil.md](audit/2026-08-06/r95-increment/01-emil.md) (5.8KB, 设计工程)
- [docs/audit/2026-08-06/r95-increment/02-spen.md](audit/2026-08-06/r95-increment/02-spen.md) (6.7KB, 英文软件工程)
- [docs/audit/2026-08-06/r95-increment/03-spzh.md](audit/2026-08-06/r95-increment/03-spzh.md) (7.4KB, 国内合规 + 中文)
- [docs/audit/2026-08-06/r95-increment/04-appstore.md](audit/2026-08-06/r95-increment/04-appstore.md) (6.5KB, iOS 上架)
- [docs/audit/2026-08-06/r95-increment/05-googleplay.md](audit/2026-08-06/r95-increment/05-googleplay.md) (6.2KB, Android 上架)
- [docs/audit/2026-08-06/r95-increment/06-flutter-spec.md](audit/2026-08-06/r95-increment/06-flutter-spec.md) (11.1KB, v3.1 规范)

### 8.2 R92 6 视角基线报告 (R93 修复依据)

- [docs/audit/2026-08-06/00-summary-report.md](audit/2026-08-06/00-summary-report.md) (35KB, 综合)
- [docs/audit/2026-08-06/01-emilkowalski-design-report.md](audit/2026-08-06/01-emilkowalski-design-report.md) (45.9KB, emil)
- [docs/audit/2026-08-06/02-superpowers-en-report.md](audit/2026-08-06/02-superpowers-en-report.md) (76.7KB, spen)
- [docs/audit/2026-08-06/03-superpowers-zh-report.md](audit/2026-08-06/03-superpowers-zh-report.md) (73.9KB, spzh)
- [docs/audit/2026-08-06/04-appstore-ios-report.md](audit/2026-08-06/04-appstore-ios-report.md) (61.4KB, AppStore)
- [docs/audit/2026-08-06/05-googleplay-android-report.md](audit/2026-08-06/05-googleplay-android-report.md) (55.1KB, GooglePlay)
- [docs/audit/2026-08-06/06-flutter-spec-report.md](audit/2026-08-06/06-flutter-spec-report.md) (72.8KB, flutter-spec)

### 8.3 R67 决策保留

- v1.0.0 是营销事件, 不是技术事件
- M1 (2026-08-15) 用 v0.30.0+85 R95 修后版本提交
- M8 决策点决定是否 bump 到 1.0.0+1

### 8.4 行业参考

- Apple 4.3 Spam: https://developer.apple.com/app-store/review/rejections/#common-rejections
- Play Store 重复提交政策: https://support.google.com/googleplay/android-developer/answer/9888077
- 行业惯例 (0.x → 1.0): Semantic Versioning https://semver.org/
- 本项目历史: `git log --oneline --grep="version"` 看每次 bump 决策
- PIPL §13/§14/§17/§23/§28/§38/§47/§50/§54: https://www.gov.cn/xinwen/2021-08/20/content_5632486.htm
- NMPA 备案 (医疗 App): https://www.nmpa.gov.cn/

---

**dev doc 升级完成时间**: 2026-08-06
**dev doc 升级体量**: 12.5KB (R67 原 6KB → 升级版 12.5KB)
**R95+ 路线图总 task**: 60+ (估 13-21 周 P0 + 4-12 周 P1 + 12-24 周 P2 + 24+ 周 P3)
**下次 dev doc 同步**: R95 阶段 1 完成后 (估 4 周后, 2026-09-03 估)
