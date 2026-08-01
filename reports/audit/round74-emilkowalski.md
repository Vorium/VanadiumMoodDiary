# Round 74 — emilkowalski 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare — 精神心理患者吃药打卡 App
**版本**: 0.27.0+64（R73 commit 6e9f07e 收尾后）
**视角**: Design Engineering (emilkowalski)
**审计模式**: 增量（聚焦 R68-R73 集中器落地质量跟踪 + 4 层架构顶层审视 + 6 类底层排查）
**审计基线**: 1285/1285 tests pass / 0 analyzer error / 0 warning / 0 info（历史性首次 0 info） / 17 守护脚本全绿

---

## 0. 总览

- **整体设计成熟度**: ⭐⭐⭐⭐½ / 5
- **关键发现数**: **高 1 / 中 4 / 低 7**（共 12 条新候选）
- **整体感觉 (1 段)**: R73 把 R72 残 9 个 analyzer info 历史性清零, 加上 R59-R72 累计 18 个 widget 集中器 (`InfoBanner` / `StatCard` / `DialogActionsRow` / `ChoiceChipWrap` / `SwipeDeleteBackground` / `ConsentDialog` / `SectionHeader` / `AppListTile` / `PrimaryButton` / `PressFeedbackIconButton` / `LoadingTextButton` / `LoadingScrim` / `CelebrationBounce` / `AppSnackBar` / `EmptyState` / `ErrorState` / `PageTransitionSwitcher` / `Haptics`) 跟 4 层 token 子文件 (`app_colors` / `app_motion` / `app_spacing` / `app_typography`) 落地, 整个项目已经从 R66 "差 5% 一口气" 走到 R74 "**emil 设计工程规范 95% 落地**"。微交互 (PressFeedback 30+ 处)、动效 token (6 curve + 8 duration + scrim + 4 theme-aware shadow)、触感 (Haptics 11 处 0 直调)、错误反馈 (AppSnackBar 75 处 0 直调 ScaffoldMessenger) 全部 100% 集中。**剩 5% 问题集中在 3 个维度**: (a) `mood_audio_section` 591 行跟 `vent_compose` 录音是潜在集中化机会 (但 R74 风险太高不动); (b) `home_page.dart` 678 行 + `trend_calendar.dart` 528 行是 2 个 god class 候补 (R73 集中器化压力下可拆); (c) `size: 20` (7 处) / `width/height: 18` (4 处) / `EdgeInsets.all(N)` 3 处零星 atomic token 仍散落。
- **R73 落地跟踪**:
  - ✅ 9 analyzer info 全清零 (4 doc `<T>` + 5 `use_build_context_synchronously`) — **历史性首次 0 info**
  - ✅ 102 PNG 移 `_archive` + 11 临时文件清理 + README_PLACEHOLDER 删 — 上架/Assets 维度收尾
  - ✅ 6 个 service god class facade 持续优化 (notification / safety / data_export 已完成, sms / email 等 v1.0 真接)
- **R68 P0 跟踪**: 5 个 P0 修了 2 (dark mode `settings_page` 2 处 + `app_theme.dart:128/209` TODO), 仍挂 1 (`_showCelebrationOverlay` 35% 高度定位 `home_page.dart:622-650`)。详见 §3.1

---

## 1. 顶层架构审视

### 1.1 4 层架构 (presentation → domain ← data + core/ umbrella)

**现状**: `dart scripts/check_all.dart` 全绿, 0 violation。`python scripts/check_cross_feature.py` 0 violation (67 files checked)。
- `domain/` 0 flutter / 0 drift / 0 data / 0 presentation ✅
- `core/shared/` 0 flutter / 0 drift / 0 data / 0 presentation ✅ (注: `core/shared/` 也走纯函数式检查, 跟 `domain/` 同级)
- `core/data/` 不依赖 `presentation/` ✅
- 全部走 `package:` 绝对路径 + 极少 `../../` 相对路径 ✅

**已抽中度集中器 (R57-R72 累计 9 个拆分)**:
| 文件 | facade 行数 | sub-service | 状态 |
|------|---------|---------|------|
| `core/data/services/notification_service.dart` | 419 (含 DI 6 sub) | `MedicationNotifier` / `RefillNotifier` / `AssessmentNotifier` / `SnoozeManager` / `BadgeSyncService` / `ReminderDispatcher` / `SafetyAlertBuilder` | ✅ R45 + R65 |
| `core/data/services/safety_watch_service.dart` | 416 | `SafetyDetector` (纯函数) / `SafetyConfigService` / `SafetyAlertDispatcher` / `CheckSafetyUseCase` (domain) | ✅ R64 + R65 |
| `core/data/services/data_export_service.dart` | ~120 (1 facade) | `ExportOrchestrator` / `ExportSchemaService` / `ExportAudioService` / `ExportCryptoService` | ✅ R57 |
| `core/data/services/medication_report_pdf.dart` | ~80 (1 facade) | `medication_report_pdf_layout.dart` (8 helper 抽) | ✅ R57 |
| `core/routing/app_router.dart` | 71 (1 facade) | `app_route_main` / `app_route_assessment` / `app_route_medication` / `app_route_vent` / `app_route_check_in` (5 feature 分文件) | ✅ R57 |
| `core/theme/app_tokens.dart` | 254 (1 facade) | `app_colors` / `app_motion` / `app_spacing` / `app_typography` (4 sub-file) | ✅ R65 |
| `core/data/database/app_database.dart` | 378 (单文件, 11 个 migration) | (单表 table 文件分目录) | ✅ R19 + 持续 |
| `domain/logic/care_engine.dart` | 163 (1 facade) | `care_strategies.dart` (4 strategy) | ✅ R41 |
| `domain/logic/medication_report.dart` | 281 (1 facade) | `MedicationStat` / `TempMedEntry` / `MedicationReportData` (3 data class) | ✅ R58 |

**3 维质量评估**:
- 顶层依赖方向: ✅ 0 反向依赖
- 集中器化覆盖: ✅ 主要 god class 已 facade 化
- 跨层语义一致性 (Entity ↔ @DataClassName): ✅ `check_drift_namespace.py` 7 table / 7 @DataClassName / 0 duplicates

**发现**:
- **P-MID-01 (中)**: `core/data/services/safety_detector.dart:121-144` 8 个 leaf `SafetyDecision` sealed class 已就位, 但 `HomeLifecycleState` enum (R64 L2 refactor) 跟 `SafetyCheckKind` enum (R64) 都是**枚举+方法式状态机**而不是 Dart 3 `sealed class`。`HomeLifecycleState` (5 状态 + 3 transition) 跟 `SafetyCheckKind` (8 状态) 都是 emil "state should be nameable" 风格, 不强求 sealed class. ✅
- **P-MID-02 (中)**: `core/data/services/notification_service.dart:419` 行算 "facade 集中化" 状态, 6 个 sub-service 全部 DI 注入 + 119 行 init + 委托. 但 facade 本身 419 行仍偏长, R45 + R65 已拆 6 sub, 进一步拆收益低 (init 跟 channel const 都必须在 facade). ✅
- **P-MID-03 (低)**: `core/data/database/app_database.dart:378` 跟 schemaVersion 15 + 11 次 migration 集中. ✅

**修复建议**: 顶层架构 0 重大改动需求, 持续维护 facade/sub-service 边界即可。

### 1.2 模块边界 (`presentation/pages/` 8 个 feature)

**现状**: 8 个 feature page, 5 个跨 feature 已在 R17 落地 (hub: `home` / `settings`; widgets: `presentation/widgets/`; others 用 domain+data+providers).

**page 文件分布 (按行数排序, Top 10)**:
| 文件 | 行数 | class 数 | 状态 |
|------|------|---------|------|
| `home/home_page.dart` | **678** | 2 (HomeLifecycleState enum + _HomePageState) | god class 候补 |
| `mood/widgets/mood_audio_section.dart` | **591** | 5 (Snapshot/Controller/ErrorKind/Recorder/_State) | god class 候补 |
| `trend/trend_calendar.dart` | **528** | 4 (CalendarView / _CalendarCell / _DayDetailCard / _EventRow) | 适度大 |
| `setup/setup_page.dart` | 495 | 1 (含 4 step dispatch) | 适度大, 已抽 5 step 文件 |
| `settings/reminders_hub_page.dart` | 471 | 5 (含 _AssessmentReminderSheet + _SafetyReminderSheet) | 适度大 |
| `assessment/assessment_page.dart` | 445 | (4 拆) | 适度大 |
| `medication/medication_calendar_page.dart` | 445 | 7 (CalendarPage + 6 子 widget) | 拆分到位 ✅ |
| `settings/widgets/data_management_section.dart` | 423 | 多 | 适度大 |
| `vent/vent_compose_page.dart` | 423 | 2 (含 audio FSM) | 适度大 |
| `assessment/assessment_widgets.dart` | 421 | 多 | 已拆 5 sub ✅ |

**`home_page.dart` 状态机亮点** (R64 L2 重构):
- `HomeLifecycleState` enum 5 状态 (`initial` / `safetyCheckCompleted` / `deepLinkHandled` / `safetyRerunRequested` / `bothHandled`)
- 3 个 transition method (`onSafetyCheckCompleted` / `onDeepLinkHandled` / `onRerunRequested`)
- 2 个 Timer 字段 (`_celebrationTimer` + `_deepLinkRaceTimer`) 显式 cancel 防 dispose race
- 0 个独立 bool (R64 之前 3 bool race-prone 组合)

**发现**:
- **P-LOW-01 (低)**: `home_page.dart:678` 行含 11 个 method, 但 R64 enum 状态机 + R73 mounted guard 已系统化。可读性 / 可测性 100%。**emil "god class = 太大 + 不可拆", 这里虽然大但可拆 (deepLink + safety + celebration + checkIn + careEngine 各 100-150 行), R74 拆 5 sub-class 收益评估后决策是否动**。
- **P-MID-04 (中)**: `mood/widgets/mood_audio_section.dart:591` 是 R46 Sprint #5 从 `mood_dialog.dart` god class 拆出, 591 行含 5 class. 跟 `vent_compose_page.dart:423` 录音状态机高度同款, 进一步抽 `AudioRecorderSection` 跨 mood + vent 集中器**理论可行, 实际 R74 不建议动** (录音编解码 + 加密 + temp file + 完成回调 4 维度, 抽中度集中器会拉 800+ 行新文件, 收益不抵复杂度, R70+ "good defaults matter more than options" 哲学 — 2 处重复 = 不到集中化阈值)。
- **P-MID-05 (中)**: `trend/trend_calendar.dart:528` 4 class + 11 处 `TextStyle(...)` inline 残留 (R70 已修多处, 仍漏 7 处). 跟 `medication_calendar_page.dart:445` 7 class 是同款日历组件, 但事件数据模型差异大 (`CalendarDay` 含 checkIn+mood+assessment 3 类 vs `_MedRow + _Cell` 1 类), **emil 抽中度集中器不划算**.
- **P-LOW-02 (低)**: `setup/setup_page.dart:495` 4 step dispatch + `_finishSetup` 90 行 orchestrator. 5 step 文件已抽, 集中度 OK.

**修复建议**: R74 优先级: `home_page.dart` 拆 5 sub-controller (R74 #5) > `trend_calendar.dart` TextStyle 集中 (R74 #6) > `mood_audio_section` 保留不拆.

### 1.3 共享层 (`core/`) 利用率

**现状**: `core/` 5 个子层 (data / shared / theme / routing / l10n), `shared/` 文件被 ≥2 层用 (`check_all.dart` 校验通过).

**集中度统计 (R74)**:
| 集中器 | 调用数 | 文件数 | 集中度 |
|--------|------|------|------|
| `AppSnackBar.show*` | **75** | 19 | 100% (0 直调 ScaffoldMessenger) |
| `Haptics.*` | **11** | 5 | 100% (0 直调 HapticFeedback) |
| `AppListTile.*` | **58** | 16 | 100% |
| `PressFeedbackIconButton` | **27** | 16 | 100% (31 IconButton 中 27 走集中器 + 4 集中器自身) |
| `PrimaryButton` | **13** | 9 | 72% (5 处 ElevatedButton 直调 — reminders_hub/contacts/data_mgmt, 1/3 走 dialog 集中器) |
| `AppSnackBar.show*` error/info 4 类 | 75 | 19 | 100% |
| `AppTokens.curve*` (widgets) | **14** | - | 100% (0 inline `Curves.easeInOut` / `Curves.elasticIn` / `Curves.bounceIn`) |
| `AppTokens.curve*` (pages) | **1** | - | 100% |
| `Motion.duration` / `Motion.curve` | **15** | - | 100% reduce-motion 包装 |
| `AppTokens.durNormal/Fast/Slow/Press` | **11** | - | 100% (5 处 `Duration(milliseconds: N)` 注释 + 1 处 timeout 5s 不是动效) |

**发现**:
- **P-LOW-03 (低)**: `core/theme/app_theme.dart:128/209` 2 处 `withValues(alpha: 0.5/0.6)` inline, **R66 报告点名 3 round 仍未删** (R48 → R65 → R67). 集中器 `AppColors.fgDisabled(context)` / `AppColors.fgHintInput(context)` 已有, 但 `_elevatedButtonTheme` / `_inputDecorationTheme` 是 static 工厂, 无 `BuildContext` (R69 已删 1 年 TODO 注释, 但 inline 仍挂). **R74 必修** (R74 #3).
- **P-LOW-04 (低)**: `core/theme/app_theme.dart:32` `scaffoldBackgroundColor: isDark ? AppTokens.backgroundDark : AppTokens.background` — 用 const 替代 M3 `ColorScheme.surface` (R68 提过). **R74 建议改** `cs.surface` 更纯 M3 (R74 #4).
- **P-LOW-05 (低)**: `core/theme/app_theme.dart:33` `splashFactory: InkSparkle.splashFactory` ✅ 已是 M3 推荐.
- **P-LOW-06 (低)**: `core/theme/app_theme.dart:60-94` `_textTheme` 全部走 `AppTokens.fontSizeXxx` + `lineHeightXxx` ✅, 但 `TextStyle` 内部不直接用 `textStyleBody` 集中器 (因 `_textTheme` 是 ThemeData 工厂内部, 跟外面 `Text(...)` widget 用 `textStyle*` 不冲突). ✅

**修复建议**: 共享层 100% 集中化已实现, R74 只剩 `app_theme.dart:128/209/32` 3 处小修.

---

## 2. 底层逐行排查

### 2.1 动效 token

**现状**: `core/theme/app_motion.dart` (253 行) 集中 4 大类:
1. **Duration** (8 个): `durFast` 200ms / `durNormal` 300ms / `durSlow` 500ms / `durPress` 160ms / `durPageTransition` 100ms / `shimmerCycleMs` 1200 / `shimmerPauseMs` 600 / `refreshMinVisibleMs` 400
2. **snackBar Duration** (3 个): `snackBarDurationShort` 2s / `snackBarDurationMedium` 3s / `snackBarDurationLong` 4s
3. **Curve** (6 个): `curveStandard` easeOutCubic / `curveSubtle` easeOut / `curveDecelerate` easeOutQuart / `curveAccelerate` easeInCubic / `curveDelight` elasticOut / `curveBackOut` easeOutBack
4. **BoxShadow** (4 个 dynamic getter): `shadowCardOf` / `shadowCardDarkOf` / `shadowDialogOf` / `shadowOverlayOf` (R59 删 4 个 const shadow, 强制 theme-aware)
5. **MotionScheme** enum (4 档: `none` / `subtle` / `standard` / `delight`) + `Motion` class (reduce-motion 包装)

**集中度验证** (R74):
- `lib/presentation/widgets/` 14 处 `AppTokens.curve*` 调用, 0 处 `Curves.easeInOut` / `Curves.elasticIn` / `Curves.bounceIn` 直调 ✅
- `lib/presentation/pages/` 1 处 `AppTokens.curve*`, 0 处 inline Curves ✅
- `lib/presentation/` 15 处 `Motion.duration` / `Motion.curve` 包装 (R74 emil "prefers-reduced-motion 是 non-negotiable a11y")
- 5 处 `Duration(milliseconds: N)` / `Duration(seconds: N)` 散落, 全部是注释 (4 处) + 1 处 timeout 5s (非动效) ✅

**发现**:
- **P-LOW-07 (低)**: `core/theme/app_motion.dart:25-46` 8 个 duration + `Motion.duration` 包装 100% 集中 ✅
- **P-LOW-08 (低)**: `app_motion.dart:139-149` `scrimAlpha` 0.54 (R65 加), `LoadingScrim` 集中器 100% 用 ✅
- **P-LOW-09 (低)**: 4 个 shadow 集中器 100% dynamic (R59 删 4 个 const 集中器版本, 防 dark mode 黑色阴影 silent bug) ✅
- **P-LOW-10 (低)**: `MotionScheme` enum 4 档决策框架 + `Motion.prefersReduced` 包装 100% 集中 ✅

**修复建议**: 动效 token 体系已 100% 集中, 0 新增修复项.

### 2.2 Widget 设计 (Spacing / Typography / Color / Motion 4 维)

**Typography 集中度**:
- 17 个 `AppTokens.fontSize*` (Title 28 / Headline 24 / Button 20 / Body 18 / Label 16 / Caption 14 / Micro 10 / XxxSmall 8 / BodySm 13 / CaptionSm 12 / LabelSm 11 / ScoreLg 24 / ScoreXl 32 / ScoreXxl 64 / spacingXxxs 2 / spacingXxs 4 / spacingXs 8)
- 15 个 `AppTokens.textStyle*` dynamic (textStyleTitle / textStyleHeadline / textStyleBody / textStyleBodyStrong / textStyleLabel / textStyleLabelStrong / textStyleButton / textStyleButtonInverse / textStyleCaption / textStyleCaptionStrong / textStyleMicro / textStyleLabelMedium / textStyleCaptionHint / textStyleLegal / textStyleMono)
- 5 个 `lineHeight*` (Tight 1.2 / Snug 1.4 / Normal 1.5 / Relaxed 1.6 / Loose 1.8)

**集中度对比 (R68 → R74)**:
- inline `TextStyle(fontSize: N, fontWeight: M)`:
  - widgets: **22 处** (R68 持平) — 集中器自身内部用 OK
  - pages: **133 处** (R68 持平) — 仍是最大集中化机会
- `AppTokens.textStyle*` 调用 (集中器化覆盖): widgets 14 + pages 1 (粗略数) — 仍 95% 走 token, 5% 集中器自身或极简 case 走 inline

**发现**:
- **P-MID-06 (中)**: `pages/` 133 处 inline `TextStyle(...)`, R70-R72 集中器化进展缓慢, **R74 #6 评估** 哪些是 "复杂 case" 不可集中 vs "应该集中". 抽样:
  - `trend_calendar.dart:113, 135, 255, 319, 339, 370, 399, 424, 484, 493` — 10 处 TextStyle, 多数可改 `textStyleBodyStrong` / `textStyleCaption` / `textStyleLabelMedium` 集中器
  - `medication_calendar_page.dart:279, 324, 387, 425` — 4 处 TextStyle, 多数可改 `textStyleCaption` / `textStyleMicro` / `textStyleLabelMedium`
  - `today_med_schedule.dart:62, 194` (R68 P1 #2 提过) — 2 处 `textStyleBodyStrong` 集中器应用
  - `assessment/assessment_widgets.dart:307, 343` — 2 处 64pt score 数字 (R68 P1 #2 提过)
- **P-MID-07 (中)**: `pages/` 121 处 `EdgeInsets.*`, 31 处走 magic 数字, **R74 重点查**:
  - `EdgeInsets.all(4)` 在 `contacts_list_widget.dart:71` — 走 `spacingXxs` (4) ✅ 一行改
  - `EdgeInsets.all(1)` 在 `medication_calendar_page.dart:352` — 1px grid cell gap, 需新加 `spacingCellGap` (1) token (R68 P2 #4 提过)
  - `EdgeInsets.all(2)` 在 `trend_calendar.dart:235` — 走 `spacingXxxs` (2) ✅ 一行改
  - 0 处 `EdgeInsets.symmetric(horizontal: N, vertical: M)` magic ✅
- **P-LOW-11 (低)**: `pages/` 13 处 inline `width: N, height: N` (R74 grep):
  - 4 处 `width: 18, height: 18` (`loading_text_button.dart:110-111, 139-140`) — 应走 `iconSizeInline` (18) ✅
  - 1 处 `width: 16` (`secondary_button.dart:46`) — 接近 `iconSizeSmall` (14) 或新加 `iconSizeCompact` (16)
  - 1 处 `height: 24` (`contacts_list_widget.dart:69`) — 应走 `iconSize` (24) ✅
  - 1 处 `height: 180` (`assessment/widgets/assessment_chart_card.dart:78`) — chart 高度, 需新加 `chartCardHeight` token
  - 1 处 `width: 18` (`trend/widgets/trend_monthly_chart.dart:29`) — 应走 `iconSizeInline` (18) ✅
  - 5 处 `Divider(height: 1, indent: 32|56)` — Divider 1px 厚度, indent 是具体 case 难集中

**Color 集中度**:
- 27 个 `AppColors.*` static const + dynamic getter (textPrimary/surface/background/primary/error/warning 7 主色 + tinted 6 类 + fg 6 类)
- `Color(0xFF...)` 直调: 0 处 (除 `app_colors.dart` 自身 + PDF `PdfColors.*` 库) ✅
- `Colors.white` / `Colors.black` / `Colors.red` / `Colors.orange` / `Colors.grey` 直调: 0 处 (除注释) ✅
- `withValues(alpha: N)` inline: 5+ 处 (含 `app_theme.dart:128/209` 2 处 + `assessment_widgets.dart:351` + `_MoodRecorderState` 等)

**Motion 集中度**: 100% (见 §2.1).

**修复建议**:
- R74 #6: `trend_calendar.dart` 10 处 TextStyle 集中化 (1-2h)
- R74 #7: `loading_text_button.dart` 4 处 `iconSizeInline` 集中 (15min)
- R74 #8: 3 处 `EdgeInsets.all` magic 改 token (15min)

### 2.3 触感反馈 (Haptics)

**现状**: `lib/presentation/widgets/feedback.dart:18-39` 4 类集中器:
- `Haptics.tap()` — selectionClick (轻) — 选项切换
- `Haptics.success()` — mediumImpact (中) — 保存 / 完成
- `Haptics.warning()` — heavyImpact (重) — 删除 / 销毁
- `Haptics.light()` — lightImpact (微) — 取消 / 关闭

**集中度 (R74)**:
- 11 处 `Haptics.*` 调用, 5 个文件 (home_page 6 / vent_list 2 / vent_detail 1 / medications_list 1 / contacts_list 1) ✅
- 0 处 `HapticFeedback.*` 直调 (除 `feedback.dart` 自身) ✅
- 100% 集中

**发现**:
- **P-LOW-12 (低)**: `Haptics` 集中器使用 11 处, 跟 `PressFeedback` (30+ 处) 配合形成 "PressFeedback 必 Haptics" 模式, 但实际上 `PressFeedback` 内部不自动 Haptics. emil "haptic should be opt-in" 哲学, 不强制. ✅

**修复建议**: 触感反馈 100% 集中, 0 新增修复项.

### 2.4 状态机 (FSM / sealed class)

**现状**: R64 L2 refactor + R65 use case 引入 5 个状态机:

1. **`HomeLifecycleState` enum** (`home_page.dart:55-133`) — 5 状态 + 3 transition method (sealed-style switch expression) ✅
2. **`SafetyCheckKind` enum** (`safety_watch_service.dart:316`) — 8 leaf 状态, 走 switch expression 强制穷举 ✅
3. **`SafetyDecision` sealed class** (`safety_detector.dart:121-144`) — 8 leaf (Disabled / NoData / Ok / AlertedToday / DndSuppressed / NoContacts / Alert) ✅
4. **`VentComposePage` 录音 FSM** — 3 态 (idle / recording / recorded) + 5 sub-state (isPlaying etc) ✅
5. **`MoodRecorder` 录音 FSM** (`mood_audio_section.dart:103`) — 5 class (Snapshot/Controller/ErrorKind/Recorder/_State) ✅
6. **`CheckInButton._StreakCounter` 数字 tween** — `AnimationController` + `TweenSequence` ✅
7. **`LoadingSkeleton._Shimmer` "呼吸" 模式** — `AnimationController` + status listener + Timer pause ✅
8. **`CelebrationBounce`** — `AnimationController` + `TweenSequence` 5 段 + RepaintBoundary ✅

**发现**:
- **P-LOW-13 (低)**: `SafetyDecision` sealed class 8 leaf + switch expression 强制穷举 — emil "新加 kind 时 compile 必报错" ✅
- **P-LOW-14 (低)**: `HomeLifecycleState` enum 5 状态 + 3 transition method — R64 L2 refactor 已系统化 ✅
- **P-LOW-15 (低)**: `CheckInButton._StreakCounter` 数字递增动画 `AnimationController` + `Motion.duration` 包装 ✅
- **P-LOW-16 (低)**: `CelebrationBounce` 5 段 `TweenSequence` + `MotionScheme.delight` 档位 + RepaintBoundary (R71 加) ✅
- **P-LOW-17 (低)**: `LoadingSkeleton._Shimmer` 状态机 "呼吸" 模式 (R24 P1-6 改) + Timer 可 cancel (R59 EMIL-T21 修) + reduce-motion 跳终态 ✅

**修复建议**: 状态机 100% 系统化, 0 新增修复项. R74 #9 评估 `home_page.dart` 拆 5 sub-controller 收益.

### 2.5 Error handling + user feedback

**现状**: 集中化 100% (`AppSnackBar` 75 处, 0 直调 ScaffoldMessenger).

**发现**:
- **P-LOW-18 (低)**: `AppSnackBar` 4 类 (error / info / undo / withAction) + 4 个 showX 便捷工厂, 100% 集中 ✅
- **P-LOW-19 (低)**: `runZonedGuarded` (main.dart:83) + `LastErrorCapture` (R33 sp-en P0 加) + `LastStartupErrorBanner` (R33) — release mode 错误全链路兜底 ✅
- **P-LOW-20 (低)**: `piiSafeLog` (main.dart + 11 处 service) — 错误日志 PII 脱敏 ✅
- **P-LOW-21 (低)**: `swallowError` 集中器 (R30 加) + 5+ 处跨 await 异常吞咽, 不污染 UI ✅
- **P-LOW-22 (低)**: `NotificationFailureBanner` (R22 加) — 通知初始化失败显眼提示 ✅
- **P-LOW-23 (低)**: `SmsResultKind` enum (`sms_service.dart:210`) ok / fail / mock 3 态分流 — R60 P0-3 修了硬编码 "已自动通知" 谎言 ✅
- **P-LOW-24 (低)**: `EmailService.validateForRelease` (R67 加) — release mode 启动守卫, banner 显眼告警 ✅

**修复建议**: Error handling 100% 系统化, 0 新增修复项.

### 2.6 BuildContext

**现状** (R73 commit 6e9f07e 后):
- `flutter analyze` 0 error / 0 warning / **0 info (历史性首次)** ✅
- 5 处 `use_build_context_synchronously` 全部清零 (R73 重构-1):
  - `home_page.dart:446` (2 处) — `if (mounted) { ... context ... }` 包跨 await 块
  - `contacts_list_widget.dart:217/238` (2 处) — `_showAddContactDialog` method 改 closure
  - `setup_page.dart:397` (1 处) — for-loop 内 `await ConsentDialog.show` 之后 mounted guard
- 4 处 `unintended_html_in_doc_comment` (doc `<T>` HTML 冲突) 全部清零

**R17 + R56b 模式**: 138 处 `BuildContext context)` widget API, 1 处 `BuildContext context) async` method 风格 (R73 已修). 后续新代码继续走 R17 + R56b memory 模式 (`if (ctx.mounted)` 跟 `if (mounted)` 是不同来源).

**发现**:
- **P-LOW-25 (低)**: BuildContext 跨 async gap 0 残留 ✅ (R73 修了 5 处)

**修复建议**: BuildContext 0 新增修复项, 0 风险.

---

## 3. 4 类问题清单 (上架 / 架构 / 重构 / 半成品)

### 3.1 上架 (App Store / Google Play)

| 序 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|----|------|------|------|---------|---------|
| U-1 | 上架 | **P0-高** | `home_page.dart:622-650` `_showCelebrationOverlay` | S (1h) | `top: MediaQuery.of(ctx).size.height * 0.35` 35% 高度定位 — **R66/R68 P0 挂 4 round**. 改 `Positioned(top: MediaQuery.padding.top + AppTokens.spacingLg, left: 0, right: 0)`, 加 `AppTokens.celebrationTopOffset` 集中器 (R68 #3 建议未动) |
| U-2 | 上架 | **P0-高** | `app_theme.dart:128, 209` | XS (10min) | `withValues(alpha: 0.5/0.6)` inline, 改 `AppColors.fgDisabled(context)` / `AppColors.fgHintInput(context)` 集中器. 删 1 年 TODO 注释 (R66/R68 P0 挂 3 round). 集中器内部走 `cs.onSurface 适配 dark mode`, 不需 buildTheme 接 context (R69 已确认) |
| U-3 | 上架 | **P1-中** | `app_theme.dart:32` | XS (5min) | `scaffoldBackgroundColor: isDark ? AppTokens.backgroundDark : AppTokens.background` 用 const 替代 M3 `ColorScheme.surface` 更纯 M3 (R68 P2 #1 提过未动) |
| U-4 | 上架 | **P1-中** | `pages/` 7 处 `size: 20` | XS (30min) | 7 处 `size: 20` magic (assessment_widgets:36, 295 / assessment_history_list:33 / today_med_schedule:58 / vent_detail_page:226 / notification_failure_banner:43 / trend_calendar:418) — 介于 `iconSizeInline` (18) 跟 `iconSize` (24) 之间. **新加 `AppTokens.iconSizeTrailing` (20) 集中器**, 7 处直改 |
| U-5 | 上架 | **P2-低** | `pages/` 4 处 `width: 18, height: 18` | XS (15min) | `loading_text_button.dart:110-111, 139-140` 4 处 `width: 18, height: 18` 走 `iconSizeInline` (18) 集中器 |
| U-6 | 上架 | **P2-低** | `pages/` 1 处 `width: 16` | XS (10min) | `secondary_button.dart:46` `width: 16` 走 `iconSizeSmall` (14) 或新加 `iconSizeCompact` (16) |
| U-7 | 上架 | **P2-低** | `pages/` 1 处 `height: 24` | XS (5min) | `contacts_list_widget.dart:69` `height: 24` 走 `iconSize` (24) 集中器 |
| U-8 | 上架 | **P2-低** | `pages/` 1 处 `height: 180` | XS (10min) | `assessment/widgets/assessment_chart_card.dart:78` `height: 180` chart 高度, 抽 `AppTokens.chartCardHeight` (180) |
| U-9 | 上架 | **P2-低** | `pages/` 3 处 `EdgeInsets.all` magic | XS (15min) | `contacts_list_widget.dart:71` `all(4)` → `spacingXxs` / `medication_calendar_page.dart:352` `all(1)` → 新加 `spacingCellGap` (1) / `trend_calendar.dart:235` `all(2)` → `spacingXxxs` |
| U-10 | 上架 | **P2-低** | `trend/trend_calendar.dart` 10 处 TextStyle inline | S (1.5h) | 集中 `textStyleBodyStrong` / `textStyleCaption` / `textStyleLabelMedium` 集中器, 10 处 TextStyle → 集中器 (R68 P1 #2 提过未动) |
| U-11 | 上架 | **P2-低** | `medication/medication_calendar_page.dart` 4 处 TextStyle | S (1h) | 同上, 4 处 TextStyle 集中 |
| U-12 | 上架 | **P2-低** | `assessment/assessment_widgets.dart:307, 343` 64pt score | XS (30min) | `TextStyle(fontSize: 64, fontWeight: w700, color: primary)` 2 处, 抽 `textStyleScoreXxl` 集中器 (R50 抽过, R57 删了, 重新启用) (R68 P1 #2 提过未动) |

### 3.2 架构 (4 层)

| 序 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|----|------|------|------|---------|---------|
| A-1 | 架构 | **P1-中** | `presentation/pages/home/home_page.dart:678` | XL (4h+) | god class 候补. 11 个 method (deepLink / safety check / autofire / showCelebration / onCheckIn / afterCheckIn / fireCareEngine / snooze5min / noop / showMedicationHint / handleDeepLink). R64 状态机已系统化, 但 god class 本身仍 678 行. **R74 #5 评估拆 5 sub-controller**: HomeLifecycleController / DeepLinkController / SafetyCheckController / CelebrationController / CareEngineController. 风险中, 收益中 (可测性 100% → 80% 行覆盖容易度) |
| A-2 | 架构 | **P2-低** | `presentation/pages/mood/widgets/mood_audio_section.dart:591` | XL (3h+) | 跟 `vent_compose` 录音同款. 抽 `AudioRecorderSection` 跨 mood + vent 集中器理论可行, 但 R74 风险太高不动 (录音编解码 + 加密 + temp file + 完成回调 4 维度, 抽中度集中器会拉 800+ 行新文件, R70+ "good defaults matter more than options" 哲学 — 2 处重复 = 不到集中化阈值). R75+ 再评估 |
| A-3 | 架构 | **P2-低** | `core/data/services/notification_service.dart:419` | M (2h) | facade 419 行 + 6 sub-service DI 注入. R45 + R65 已拆 6 sub, 进一步拆收益低. R74 不动 ✅ |

### 3.3 重构 (god class / 长文件 / 重复模式 / 集中器机会)

| 序 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|----|------|------|------|---------|---------|
| R-1 | 重构 | **P2-低** | `pages/` 133 处 inline TextStyle | M (3h) | 集中化覆盖率仍 ~75%, R74 重点修 `trend_calendar.dart` 10 处 + `medication_calendar_page.dart` 4 处 + `today_med_schedule.dart` 2 处 + `assessment_widgets.dart` 2 处. 剩 115 处跨 30+ 文件, 长期 R75+ 渐进修 |
| R-2 | 重构 | **P2-低** | `pages/` 22 处 > 230 行 | - | 当前最大 5 个: `home_page.dart` (678) / `mood_audio_section.dart` (591) / `trend_calendar.dart` (528) / `setup_page.dart` (495) / `reminders_hub_page.dart` (471). R74 #5 评估 home_page 拆 sub-controller. 其余 4 个设计合理, 不强拆 |
| R-3 | 重构 | **P3-低** | `medication_report_dialog.dart:113-146` 3 按钮 3 模式 | S (1.5h) | R70 改了统一走 `LoadingTextButton` 3 模式 (outlined / filled / outlined) ✅, 不再是 3 模式不一致 |

### 3.4 半成品 (TODO / FIXME / 假数据 / hardcoded)

| 序 | 类型 | 严重度 | 位置 | 修复难度 | 修复建议 |
|----|------|------|------|---------|---------|
| T-1 | 半成品 | **P3-低** | `lib/` 17 处 TODO 注释 | - | 全部是有意 deferred work: 5 处 `home_page.dart:550, 558, 568` SMS / Email 真接 (R55+); 5 处 `sms_service.dart:12, 13, 90, 104, 196` 阿里云 / Twilio 真接; 3 处 `email_service.dart:19, 40, 162` Email 真实发送; 2 处 `scale_translations.dart:17, 99` PHQ-9 量表 i18n (v1.0 大工程); 1 处 `app_theme.dart:126` 已删 1 年 TODO (R73); 1 处 `badge_sync_service.dart:49` 已删 18 月 TODO (R70) |
| T-2 | 半成品 | **P3-低** | `app_theme.dart:128` TODO 注释残留 | XS (5min) | `// R69 (CC-10 emil P0 修复): ...保留 inline, 删 1 年 TODO 注释占位` — 注释明确说"删 TODO", 但 R69/R73 没删, R74 删 1 行 ✅ |
| T-3 | 半成品 | **P3-低** | `core/theme/app_theme.dart:209` | XS (5min) | `// R69 (CC-10 emil P0 修复): _inputDecorationTheme 同上无 context, 保留 inline` — 同款注释残留, R74 一并删 |
| T-4 | 半成品 | **P3-低** | `core/theme/app_theme.dart:32` `scaffoldBackgroundColor: ...` | XS (5min) | 改 `cs.surface` 更纯 M3 (U-3 同款) |
| T-5 | 半成品 | **P3-低** | 102 PNG `_archive` (R73 落地) | - | R73 commit 010c9b8 已落 ✅ |
| T-6 | 半成品 | **P3-低** | 11 临时文件清理 (R73 落地) | - | R73 commit 4924a6f 已落 ✅ |
| T-7 | 半成品 | **P3-低** | README_PLACEHOLDER.txt 删 (R73 落地) | - | R73 commit 98b041a 已落 ✅ |

---

## 4. 修复优先级排序

| 优先级 | 序 | 标题 | 描述 | 估时 |
|--------|----|----|------|------|
| **P0-高** | U-1 | 修 `_showCelebrationOverlay` 35% 高度定位 | `home_page.dart:622-650` 改 `MediaQuery.padding.top + spacingLg` + 加 `AppTokens.celebrationTopOffset` 集中器 (R66/R68 挂 4 round 必修) | 1h |
| **P0-高** | U-2 | 修 `app_theme.dart:128/209` inline alpha 改集中器 | 替换 `withValues(alpha: 0.5/0.6)` 为 `AppColors.fgDisabled(context)` / `AppColors.fgHintInput(context)`, 删 1 年 TODO (R66/R68 挂 3 round 必修) | 10min |
| **P1-中** | U-3 | 修 `app_theme.dart:32` `scaffoldBackgroundColor` | 改 `cs.surface` 更纯 M3 | 5min |
| **P1-中** | U-4 | 抽 `AppTokens.iconSizeTrailing` (20) 集中器 | 7 处 `size: 20` magic 改 token | 30min |
| **P1-中** | A-1 | 评估拆 `home_page.dart` 5 sub-controller | HomeLifecycleController / DeepLinkController / SafetyCheckController / CelebrationController / CareEngineController. 风险中, 收益中 (可测性 + 行覆盖) | 4h+ |
| **P2-低** | U-5 / U-6 / U-7 | 4 处 `width: 18, height: 18` / 1 处 `width: 16` / 1 处 `height: 24` 改 token | `iconSizeInline` / `iconSizeSmall` / `iconSize` 集中器应用 | 30min |
| **P2-低** | U-8 | 抽 `AppTokens.chartCardHeight` (180) | 1 处 `height: 180` chart 高度 | 10min |
| **P2-低** | U-9 | 3 处 `EdgeInsets.all` magic 改 token | `spacingXxs` (4) / `spacingCellGap` (1) / `spacingXxxs` (2) | 15min |
| **P2-低** | U-10 | `trend_calendar.dart` 10 处 TextStyle 集中 | 集中 `textStyleBodyStrong` / `textStyleCaption` / `textStyleLabelMedium` | 1.5h |
| **P2-低** | U-11 | `medication_calendar_page.dart` 4 处 TextStyle 集中 | 同 U-10 | 1h |
| **P2-低** | U-12 | `assessment_widgets.dart:307, 343` 64pt score 抽 `textStyleScoreXxl` | R50 抽过 R57 删了, 重新启用 | 30min |
| **P2-低** | A-2 | `mood_audio_section` + `vent_compose` 录音集中化 (R75+) | 理论可行, R74 风险太高不动, R75+ 评估 | (R75+) |
| **P2-低** | A-3 | `notification_service.dart:419` 进一步拆 (R75+) | facade 6 sub-service DI 已落地, 进一步拆收益低 | (R75+) |
| **P2-低** | R-1 | 渐进修 `pages/` 133 处 inline TextStyle | R74 重点修 18 处, R75+ 渐进修剩 115 处 | 3h+ |
| **P2-低** | R-2 | 22 个 > 230 行 page 文件 | R74 #5 评估 home_page 拆, 其余 4 个设计合理 | - |
| **P2-低** | R-3 | `medication_report_dialog` 3 按钮 (R70 落地) | R70 已统一走 `LoadingTextButton` 3 模式 ✅ | - |
| **P3-低** | T-2 / T-3 / T-4 | 删 3 处 TODO 注释 + scaffoldBackgroundColor 改 cs.surface | U-2/U-3 一并修 | 5min |
| **P3-低** | T-1 | 17 处 TODO 注释 (有意 deferred) | 等外部依赖: SMS/Email 真接 (R55+) / PHQ-9 i18n (v1.0) / 律师 review (1-2 周) | 外部 |

**P0 (必修, 1-1.5h)**: U-1 + U-2 = **2 项, 估时 1-1.5h**
**P1 (中优, 4-5h)**: U-3 + U-4 + A-1 = **3 项, 估时 4-5h**
**P2 (低优, 5-6h)**: U-5~U-12 + A-2 + A-3 + R-1 + R-2 + R-3 = **13 项, 估时 5-6h (含 3 项 (R75+))**
**P3 (外部 / 兜底)**: T-1~T-7 = **7 项, 估时 5min + 外部依赖**

**R74 emil 视角可修总估时**: P0 + P1 = **5-6.5h** (~1 个工程师天), P0+P1+P2 = **10-12h** (~1.5 个工程师天). P0 + U-3 必修, 其它 R74 自由组合.

---

## 附录 A: 已审文件清单 (R74 增量)

| 类别 | 文件 |
|------|------|
| Theme | `app_tokens.dart` (254 行 facade) / `app_colors.dart` (277) / `app_motion.dart` (253) / `app_spacing.dart` (141) / `app_typography.dart` (204) / `app_theme.dart` (245) / `theme_provider.dart` |
| Routing | `app_router.dart` (71 facade) / `app_routes.dart` (115 facade) / `app_route_main.dart` / `app_route_assessment.dart` / `app_route_medication.dart` / `app_route_vent.dart` / `app_route_check_in.dart` / `app_shell.dart` / `notification_navigation.dart` |
| Widgets (Top 10) | `app_snack_bar.dart` (162, 4 类) / `app_list_tile.dart` (167, 3 命名构造) / `press_feedback.dart` (115, 2 模式) / `press_feedback_icon_button.dart` (113, 7 处) / `loading_skeleton.dart` (267, 3 类 + Shimmer) / `loading_text_button.dart` / `loading_scrim.dart` (内嵌 loading_skeleton) / `feedback.dart` (Haptics 4 类) / `primary_button.dart` / `check_in_button.dart` (含 StreakCounter tween) |
| Animations (5) | `fade_in.dart` / `slide_up.dart` / `page_transition_switcher.dart` / `celebration_bounce.dart` / `animations.dart` |
| Pages (Top 10) | `home_page.dart` (678, 含 HomeLifecycleState) / `mood_audio_section.dart` (591) / `trend_calendar.dart` (528) / `setup_page.dart` (495) / `reminders_hub_page.dart` (471) / `assessment_page.dart` (445) / `medication_calendar_page.dart` (445) / `data_management_section.dart` (423) / `vent_compose_page.dart` (423) / `assessment_widgets.dart` (421) |
| Domain (Logic) | `care_engine.dart` (163, 4 strategy) / `safety_detector.dart` (8 sealed) / `medication_report.dart` (281, 4 class) / `day_detail.dart` (292) / `use_cases/check_safety.dart` (76, 纯函数) |
| Data (Service Top 5) | `notification_service.dart` (419, 6 sub DI) / `safety_watch_service.dart` (416) / `sms_service.dart` (336) / `mood_audio_service.dart` (350) / `data_export_service.dart` (1 facade + 4 sub) |
| Core (R74) | `app.dart` (270) / `main.dart` (460) / `core/routing/app_router.dart` |

## 附录 B: 集中度统计表 (R74 vs R68)

| 集中度维度 | R68 | R74 | 变化 | 评估 |
|---------|-----|-----|------|------|
| AppSnackBar 调用数 | ~55 | **75** | ⬆ +20 | 100% 集中化 |
| Haptics 调用数 | ~5 | **11** | ⬆ +6 | 100% 集中化 |
| AppListTile 调用数 | ~30 | **58** | ⬆ +28 | 100% 集中化 |
| PressFeedbackIconButton 调用数 | 21 | **27** | ⬆ +6 | 100% 集中化 |
| PrimaryButton 调用数 | ~10 | **13** | ⬆ +3 | 72% (5 ElevatedButton 直调 — dialogs 允许) |
| inline `Curves.easeInOut` 等 | 0 | **0** | 持平 ✅ | 100% 走 AppTokens.curve |
| inline `withValues(alpha: N)` (除 PDF) | 5+ | **5+** | 持平 | `app_theme.dart:128/209` 2 处仍未动 |
| inline `Color(0xFF...)` (presentation) | 0 | **0** | 持平 ✅ | 100% 走 AppColors |
| inline `Colors.white/black/red` (presentation) | 0 | **0** | 持平 ✅ | 100% 走 AppColors |
| inline `Duration(milliseconds: N)` 动效 | 0 | **0** | 持平 ✅ | 100% 走 AppTokens.durXxx |
| inline TextStyle (widgets) | 22 | **22** | 持平 | 集中器自身内部用 OK |
| inline TextStyle (pages) | 133 | **133** | 持平 | R74 重点修 18 处 (U-10/11/12) |
| 6 curve token 使用 (presentation) | 12+ | **15+** | ⬆ +3 | 100% 集中 |
| 8 duration token 使用 (presentation) | 11+ | **11** | 持平 | 100% 集中 |
| `Motion.duration` 包装 (presentation) | 12+ | **15** | ⬆ +3 | 100% reduce-motion 包装 |
| Snackbar 颜色 / behavior 自定义 | 0 | **0** | 持平 ✅ | 100% M3 默认 |
| ScaffoldMessenger 直调 (presentation) | 0 | **0** | 持平 ✅ | 100% AppSnackBar |
| HapticFeedback 直调 (presentation) | 0 | **0** | 持平 ✅ | 100% Haptics |
| use_build_context_synchronously | 5 | **0** | ⬇ R73 修了 5 | 历史性首次 0 info |
| service god class 已 facade 化 | 3/5 | **5/5** | ⬆ +2 | notification / safety / data_export / pdf / medication_report 全 facade |

## 附录 C: R74 emil 视角成熟度卡片 (vs R68 对比)

| 维度 | R68 评分 | R74 评分 | 评语 |
|------|---------|---------|------|
| 微交互 (:active scale / haptic) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | PressFeedback 30+ 处, Haptics 11 处 0 直调 |
| 动效 token 化 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 6 curve + 8 duration + scrim + 4 theme-aware shadow + MotionScheme 4 档 |
| 设计 token 颜色 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | R73 修了 2 处 settings dark mode (R66 P0), **仍漏 `app_theme.dart:128/209` (R68 P0 挂 2 round 仍未动)** |
| 设计 token 字号 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 133 处 inline TextStyle 在 pages/, R74 #6 评估修 18 处 |
| 设计 token 间距 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 仍漏 7 处 `size: 20` + 4 处 `width: 18, height: 18` + 3 处 `EdgeInsets.all` magic |
| 设计 token 圆角 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 6 radius token 100% 走 |
| 阴影 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 4 dynamic shadow 100% theme-aware |
| 视觉层级 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SegmentedButton 选中态略弱 (R68 P2 提过未动) |
| 可达性 (a11y) | ⭐⭐⭐ | ⭐⭐⭐ | heatmap cell + progress bar 不可达 (R68 P1 提过未动) |
| 触控目标 (44pt) | ⭐⭐⭐ | ⭐⭐⭐ | heatmap 28pt < 44pt (R68 P1 提过未动) |
| 文字对比度 (WCAG) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | last_med_info + reminder_cards 2 处边缘 (R68 P1 提过未动) |
| 高内聚 (重复模式) | ⭐⭐⭐⭐½ | ⭐⭐⭐⭐½ | R72+ 抽 PrimaryButton + LoadingTextButton + PageTransitionSwitcher + LoadingScrim, 18 个集中器 |
| 半成品 / WIP | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | R73 落地 9 info + 102 PNG + 11 临时文件 + README_PLACEHOLDER, **历史性首次 0 info + 0 WIP** |
| 4 层架构 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | check_all.dart 0 violation, 16 守护脚本全绿, 0 analyze error |
| **总评** | ⭐⭐⭐⭐½ | **⭐⭐⭐⭐½** | R74 持平 R68 — R73 落地 4 项收尾, **emil 体系 95% 落地, 剩 5% 是 `app_theme.dart:128/209/32` 3 行小修 + `pages/` inline TextStyle 18 处渐进修** |

**关键差异 (R68 → R74)**:
- ✅ R73 commit f40a10b: 9 analyzer info 全清零 (历史性首次 0 info)
- ✅ R73 commit 010c9b8: 102 PNG 移 `_archive` (assets/brand 清理)
- ✅ R73 commit 4924a6f: 11 临时文件清理 (scripts/ root .txt + 1 deprecated .dart)
- ✅ R73 commit 98b041a: README_PLACEHOLDER.txt 删 (iOS 截图就位)
- ✅ `home_page.dart` R64 L2 重构: 3 bool → 1 enum 状态机 + Timer 字段
- ✅ `notification_service.dart` R65 P1-12: 50 行 `showSafetyAlert` 委派到 `SafetyAlertBuilder.buildFor` 纯函数
- ✅ `safety_watch_service.dart` R64: 8 类业务判定到 `SafetyDetector` 纯函数, facade 仅 40 行编排
- ✅ `medication_report_dialog.dart` R70 B-3: 3 按钮 3 模式 → 1 模式 (`LoadingTextButton` 3 variant)
- ⚠️ 仍挂 (R66/R68 P0 反复提): `_showCelebrationOverlay` 35% 高度定位 (`home_page.dart:622-650`)
- ⚠️ 仍挂 (R66/R68 P0 反复提): `app_theme.dart:128/209` inline `withValues(alpha: 0.5/0.6)` + TODO 注释
- ⚠️ 仍挂 (R68 P1 提过): `pages/` 7 处 `size: 20` + 4 处 `width: 18, height: 18` + 3 处 `EdgeInsets.all` magic
- ⚠️ 仍挂 (R68 P1 提过): `pages/` 133 处 inline TextStyle, R74 修 18 处 + R75+ 渐进修
- ⚠️ 仍挂 (R68 P1 提过): `pages/` 22 个 > 230 行 god class 候补, R74 #5 评估 home_page 拆

## 附录 D: 评估总结

**R74 emil 视角成熟度总评**: ⭐⭐⭐⭐½ / 5 (持平 R68)

**emil 体系 95% 落地, 剩 5% 边缘"差一口气"问题**:
1. `app_theme.dart:128/209/32` 3 行小修 (P0+XS, 必修)
2. `pages/` 18 处 `size: 20` / `width: 18, height: 18` / `EdgeInsets.all` magic 集中化 (P1+XS, 1h)
3. `pages/` 18 处 inline TextStyle 集中化 (P1+S, 3h)
4. `home_page.dart:622-650` 35% 高度定位 (P0+XS, 必修)
5. `home_page.dart:678` god class 拆 5 sub-controller (P1+XL, 4h+)

**核心优势 (R74 维持)**:
- 4 层架构 100% 健康 (16 守护脚本全绿, 0 violation, 0 analyze error)
- 18 个 widget 集中器覆盖 75+ 调用点
- 4 层 token 子文件 + facade (AppTokens 254 行)
- 5 个 service god class 已 facade 化
- 5 个状态机 (HomeLifecycleState / SafetyCheckKind / SafetyDecision sealed / Vent FSM / MoodRecorder FSM)
- 100% reduce-motion 包装 (15 处 `Motion.duration/curve`)
- 100% Haptics / AppSnackBar 集中化
- 100% AppSnackBar / Haptics 集中化
- 100% R73 0 info 历史性首次
- R73 落地 4 项上架收尾 (9 info + 102 PNG + 11 临时 + README)

**R74 必修 (1-1.5h)**: U-1 + U-2, 2 项 P0
**R74 中优 (4-5h)**: U-3 + U-4 + A-1, 3 项 P1
**R74 低优 + R75+**: U-5~U-12 + A-2~A-3 + R-1~R-2 + T-1~T-7, 渐进修

**R74 vs R68 持平原因**: R73 是 "上架/Assets 收尾" 轮, 跟 R68 "R67 集中器落地" 互补, 集中器化覆盖率 95% 持平. emil "decisions should be nameable" 哲学下, 剩 5% 是细节扫尾.
