# v0.27 R69 emilkowalski 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64(pubspec.yaml 确认)/ 实际 R66+R67+R68 集中落地 / working tree clean
**视角**: Design Engineering(emilkowalski)
**审计模式**: 全量复盘(从 R68 commit `d691551` 之后状态) — 重点 4 类(设计 token 散落 / 动效一致性 / 组件设计 / Dark mode + a11y)
**审计基线**: 1285 tests pass / **0 fail** / 0 analyzer error / 0 warning / 188 info / 16 守护脚本全绿

---

## §0 评级

⭐⭐⭐⭐ **4.5/5**(vs R68 ⭐⭐⭐⭐½ **4.5/5**)

> **持平 R68**。R68 集中修 3 个 P0(CC-1 / CC-3 / CC-6)但 emil 视角 P0/P1 **0 进展**。R69 整体设计成熟度维持 R68 水平,**没升级也没掉档**。剩 5% "差一口气"问题跨 4 round 仍未动(2 处 dark mode + 1 处 overlay 定位 + 1 处 scrim 锁死 + 1 处 TODO 挂 4 round)。

**一句话总结**:**emil 体系本身已是 v1.0 上 store 水平**(6 集中器 + 4 文件拆 + 4 shadow theme-aware + 6 curve + 4 档决策框架),但 R68 commit 没动 emil 视角的任何 P0/P1,**留 12 项"差一口气"问题挂到 R70**。

---

## §1 R68 → R69 增量

### §1.1 跨视角问题数量(去重前)

| 视角 | R68 P0 | R68 P1 | R68 P2 | R69 P0 | R69 P1 | R69 P2 | 变化 |
|------|--------|--------|--------|--------|--------|--------|------|
| **emilkowalski**(本文档) | 2 | 6 | 7 | **2** | **7** | **9** | 持平(emil P0 0 进展) |
| superpowers-en | 5 | 9 | 3 | 5 | 9 | 3 | 持平 |
| superpowers-zh | 9 | 6 | 7 | 9 | 6 | 7 | 持平 |
| AppStore | 10 | 10 | 6 | 10 | 10 | 6 | 持平 |
| GooglePlay | 8+2 | 8 | 4 | 8+2 | 8 | 4 | 持平 |
| flutter-specification | 5 | 5 | 5 | 5 | 5 | 5 | 持平 |
| **总问题数** | **39** | **44** | **32** | **39** | **45** | **34** | 持平 |

### §1.2 R68 commit d691551 修了什么(已落地)

| 修 | 类别 | 位置 | 影响 |
|----|------|------|------|
| **CC-3** IAP 临时关 | 跨视角 P0 | `core/data/feature_flags.dart:38` `_prodIapEnabled = false` | 隐藏 IAP 入口,避免 8 元买断 vs `buyLifetime()` 返 false 撞 Apple 2.1 |
| **CC-6** CareEngine safety 撤回真接 | 跨视角 P0 | `domain/usecases/fire_care_strategy.dart:155` 加 `isSafetyConsentWithdrawn` 字段 | 跟隐私政策 §4/§9/§12 表格"撤回后直接 return"对齐 |
| **CC-1** setup 阶段 ConsentDialog | 跨视角 P0 | `presentation/pages/setup/setup_page.dart:380-410` 每个填了的联系人弹 ConsentDialog | PIPL §13 单独同意技术层面成立 |
| 配套 | — | ARB 加 `setupConsentRejected` 3 语言 | — |

**emil 视角专属**:R68 commit **0 改动** — emil 12 项 P0/P1(2 漏 dark mode + 1 overlay 定位 + 1 scrim 锁死 + 4 setup TextStyle + 3 l10n 字符串 + 1 heatmap 触控目标)全数保留。

### §1.3 R69 关键数字(对比 R68)

| 指标 | R68 | R69 | 变化 |
|------|-----|-----|------|
| `flutter test` | 1283 + 2 fail 漂移 | **1285 全过** | ✅ 漂移修了 |
| `flutter analyze` error | 0 | 0 | 持平 |
| `flutter analyze` warning | 5 | 0 | ✅ 全清 |
| `flutter analyze` info | 181 | 188 | +7(4 个 test 新加) |
| 守护脚本 | 16 绿 | **16 绿** | 持平 |
| Working tree | 212 未 commit | **clean** | ✅ R68 commit 已落 |
| 文件变更(R66→R68 累计) | 291 / +20729/-11403 | — | 一次性集中提交 |
| 集中器总数 | 11 (R67 加 6) | 11 | 持平 |
| `AppColors` 集中器覆盖 dark mode | 35+ 处修 + 2 处漏 | **35+ 处修 + 2 处漏** | 持平 |
| `Motion.duration` / `Motion.curve` reduce-motion 包装 | 16 处 | 16 处 | 持平 |
| 散落 `Curves.x` (除注释外) | 0 | 0 | 持平 |
| 散落 `Color(0xFF...)` | 0 | 0 | 持平 |
| 散落 `Icon(color: ...)` const | 2 处 | **2 处** | 持平(R66 漏 2 处未动) |
| Atomic size token 散落(SizedBox 18/20/36/40/110) | 8+ 处 | 8+ 处 | 持平 |
| `Wrap(spacing: 8)` 散落 | 5+ 处 | 6 处 | +1(无恶化) |

---

## §2 顶层架构审视(用户重点)

### §2.1 设计 token 健康度 — emil token 化 vs 散落

| 类别 | 集中器 | 使用处数 | 散落处数 | 健康度 |
|------|--------|---------|---------|--------|
| **颜色** | `app_colors.dart` 26 个集中器(11 个 dynamic theme-aware + 15 个 const) | 100+ 处 | 0(除了 R66 漏 2 处) | ⭐⭐⭐⭐½ |
| **动效曲线** | `app_motion.dart` 6 curve token + 4 MotionScheme 档 + Motion reduce-motion 包装 | 21 处 | 0 | ⭐⭐⭐⭐⭐ |
| **动效时长** | 8 duration + 3 snackBar duration | 全 codebase | 0 | ⭐⭐⭐⭐⭐ |
| **阴影** | 4 个 dynamic getter(`shadowCardOf(context)` 等)— R59 删 4 个 const 强制主题感知 | 全 codebase | 0 | ⭐⭐⭐⭐⭐ |
| **Scrim** | `scrimAlpha = 0.54` | 1 处用 | 0 | ⭐⭐⭐⭐⭐ |
| **圆角** | 6 radius token | 全 codebase | 0 | ⭐⭐⭐⭐⭐ |
| **间距** | `app_spacing.dart` 11 个 spacing token | 100+ 处 | Wrap(spacing: 8) 6 处 | ⭐⭐⭐⭐ |
| **字号** | `app_typography.dart` 7 textStyleXxx 集中器 | 100+ 处 | setup_step_done 4 处 + assessment_chart 2 处 | ⭐⭐⭐⭐ |
| **atomic 尺寸** | **0 集中器** | 0 | 8+ 处(SizedBox 18/20/36/40/110) | ⭐⭐½ |

**关键观察**:
- ✅ **R65 拆 sub-file + R59 删 const shadow + R67 抽 6 集中器** 三波集中化做得到位
- ✅ **`fgOnPrimary` / `fgOnSuccess` / `fgOnWarning` / `tintedPrimarySoft` / `tintedErrorSoft` / `tintedWarningSoft` / `tintedStatusSoft` / `tintChartLine`** — 命名化 7 类 alpha magic 全 token 化(emil "decisions should be nameable" 达成)
- ⚠️ **atomic 尺寸 0 集中器**:`iconSizeTrailing` 18 / `spinnerSizePdf` 20 / `legendDotSizeLg/Sm` 12/10 / `avatarSizeSm/Md` 36/40 / `buttonWidthNarrow` 110 / `buttonHeightCompact` 44 — 8+ 处 magic,R66 推荐未抽

### §2.2 组件库抽象 — 11 个集中器(2 轮抽到 95% DRY)

| 轮 | 集中器 | 位置 | 使用处 | 抽象成熟度 |
|----|-------|------|--------|-----------|
| R40 | `PressFeedback` | `widgets/press_feedback.dart` | 30+ 处 | ⭐⭐⭐⭐⭐(2 模式文档化 + reduced-motion 尊重) |
| R40 | `PressFeedbackIconButton` | `widgets/press_feedback_icon_button.dart` | 21+ 处 | ⭐⭐⭐⭐⭐(强制 tooltip 参数) |
| R40 | `AppListTile` (3 命名构造) | `widgets/app_list_tile.dart` | 8+ 处 | ⭐⭐⭐⭐½(3 构造 OK,destructive 模式空壳) |
| R40 | `AppSnackBar` (4 类 + 4 showX 工厂) | `widgets/app_snack_bar.dart` | 55+ 处 | ⭐⭐⭐⭐⭐ |
| R40 | `LoadingTextButton` | `widgets/loading_text_button.dart` | 4+ 处 | ⭐⭐⭐⭐⭐ |
| R40 | `ChipBadge` (4 tone) | `widgets/chip_badge.dart` | 8+ 处 | ⭐⭐⭐⭐⭐ |
| R40 | `SectionHeader` | `widgets/section_header.dart` | 12+ 处 | ⭐⭐⭐⭐⭐ |
| R40 | `EmptyState` / `ErrorState` | `widgets/{empty,error}_state.dart` | 10+ 处 | ⭐⭐⭐⭐⭐ |
| R40 | `AppSemantics` (3 kind) | `widgets/app_semantics.dart` | 5+ 处 | ⭐⭐⭐⭐⭐ |
| R22 | `FadeIn` / `SlideUp` / `PageTransitionSwitcher` / `CelebrationBounce` | `widgets/animations/` | 各 3+ 处 | ⭐⭐⭐⭐⭐ |
| **R67** | **`InfoBanner` (4 tone + muted)** | `widgets/info_banner.dart` | 3+ 处 | ⭐⭐⭐⭐⭐ |
| **R67** | **`StatCard`** | `widgets/stat_card.dart` | 8+ 处 | ⭐⭐⭐⭐⭐ |
| **R67** | **`DialogActionsRow`** | `widgets/dialog_actions_row.dart` | 4+ 处 | ⭐⭐⭐⭐½(2 个 dialog 仍 inline,见 P1-3) |
| **R67** | **`ChoiceChipWrap<T>` 泛型** | `widgets/choice_chip_wrap.dart` | 2+ 处 | ⭐⭐⭐⭐⭐ |
| **R67** | **`SwipeDeleteBackground` (rounded)** | `widgets/swipe_delete_background.dart` | 3+ 处 | ⭐⭐⭐⭐⭐ |
| **R67** | **`ConsentDialog`** | `widgets/consent_dialog.dart` | setup + contact | ⭐⭐⭐⭐⭐(PIPL §13 + §17 文档化) |

**R68 推荐但 R69 仍未抽的集中器**(4 个强候选):

| 重复模式 | 出现位置 | 建议集中器 | 难度 |
|---------|---------|-----------|------|
| 3 段重复 `ConsentCheckRow` | `setup_step_consent.dart:75-94` | `ConsentCard(title, checked, onTap, onView)` | S |
| `OutlinedButton.icon + PressFeedback` 3 模式不一致 | `medication_report_dialog.dart:110-156` | `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` | S |
| `scrim + 中心 Card(spinner + 文字)` | `medication_report_dialog.dart:166-194` | `LoadingScrim(message, isLoading)` + `AbsorbPointer` | XS |
| `InlineSpinnerInTrailing` 3 模式不一致 | `medication_row.dart:131` / `contacts_list_widget.dart:75-83` / `notification_status_card.dart:219-224` | `TrailingSpinner` 集中器 | XS |

### §2.3 动效决策框架(emil 4 档)应用率

| 档 | 用法 | 项目实例 | 应用率 |
|----|------|---------|--------|
| **none** 100+/day | 键盘 / 核心导航 / 日常按钮 | go_router 主导航无 transition | ⭐⭐⭐⭐½ |
| **subtle** tens/day | hover / press feedback | `PressFeedback` (durPress 160ms + curveStandard) | ⭐⭐⭐⭐⭐ |
| **standard** occasional | modal / drawer / snackbar / 状态切换 | `AppSnackBar` / `DialogActionsRow` / `PageTransitionSwitcher` | ⭐⭐⭐⭐⭐ |
| **delight** rare | onboarding 首次 / 庆祝 / 解锁 | `CelebrationBounce` (MotionScheme.delight + curveBackOut) | ⭐⭐⭐⭐⭐ |

**关键观察**:
- ✅ 4 档 `MotionScheme` enum + `Motion.duration/curve` 包装 reduce-motion — emil "频度档位可命名" 原则达成
- ✅ `PressFeedback` 30+ 处覆盖 + 2 模式文档化(R40 + R21 改进)
- ✅ 庆祝动效 3 段 TweenSequence + curveBackOut 一次过冲 + curveStandard 收尾 — emil "稳" vs "弹多次" 区分到位
- ⚠️ 1 个**关键 P0 反例**:`home_page._showCelebrationOverlay` 35% 高度定位 — emil "modal 应当 origin-aware" 违反
- ⚠️ 1 个**关键 P0 反例**:`medication_report_dialog:166-194` scrim 不锁死 — emil "modal 出现 = 用户 100% 锁死" 违反

### §2.4 Dark mode + a11y 一致性

| 维度 | 健康度 | 评语 |
|------|--------|------|
| M3 ColorScheme 主题感知 | ⭐⭐⭐⭐⭐ | 11 个 dynamic 集中器(`primaryColor(context)` / `errorColor(context)` / `disabledColor(context)` 等)全走 `Theme.of(context).colorScheme.*` |
| 散落 `Icon(color:)` | ⭐⭐⭐⭐ | 0 命中 — 全部走 `AppTokens.primaryColor(context)` 等 |
| 散落 `Color(0xFF...)` | ⭐⭐⭐⭐⭐ | 0 命中 — 全部在 `app_colors.dart` 集中声明 |
| `withValues(alpha:)` 散落 | ⭐⭐⭐⭐½ | **2 处**仍 inline(`app_theme.dart:123, 209`)+ 集中器 `tintedXxxSoft` 系列已 9 个 |
| Shadow dark mode | ⭐⭐⭐⭐⭐ | R59 删 4 个 const 强制 theme-aware 集中器 |
| a11y 语义标注 | ⭐⭐⭐ | `AppSemantics` 集中器 5+ 处用,heatmap / calendar / progress 3 处仍漏 |
| 触控目标 ≥ 44pt | ⭐⭐⭐ | heatmap cell 28pt < 44pt 仍漏 |
| Screen reader 字符串 l10n | ⭐⭐⭐½ | heatmap 仍用 hardcoded "✓" 字符串,calendar 3 处 l10n 漏 |

---

## §3 底层逐行排查(用户重点)

### §3.1 P0 阻断(emil 视角,2 项 — 跨 4 round 挂死)

| # | 位置 | 问题 | emil 框架 | 难度 | 类别 |
|---|------|------|-----------|------|------|
| **E-P0-1** | `lib/presentation/pages/settings/settings_page.dart:63, 92` | `Icon(Icons.workspace_premium, color: AppColors.success)` + `Icon(... color: AppColors.primary)` — **2 处 const 硬编 dark mode 不反白**。R49 修了 35+ 处,漏 2 处;R66/R67/R68 报告点名 3 round 未动。grep `color: AppColors\.primary\b\|color: AppColors\.success\b` = **仅剩这 2 处** | "decisions should be nameable" + "no hardcoded colors" | **XS** | 底层 |
| **E-P0-2** | `lib/presentation/widgets/medication_report_dialog.dart:166-194` | PDF scrim `Positioned.fill(child: ColoredBox(...))` 缺 `AbsorbPointer` — **user 仍能点底下 3 按钮**(复制/分享)。R66 报告点名 2 round 未动 | "modal 出现 = 用户 100% 锁死" | **XS** | 底层 |

**E-P0 修复总工作量:30 分钟**

### §3.2 P1 警告(emil 视角,7 项)

| # | 位置 | 问题 | emil 框架 | 难度 | 类别 |
|---|------|------|-----------|------|------|
| **E-P1-1** | `lib/presentation/pages/home/home_page.dart:633` | `_showCelebrationOverlay` `top: MediaQuery.of(ctx).size.height * 0.35` — **键盘弹起 / 横屏 / 全面屏 撞顶或飞出屏外**。R62 修了 Timer race 但**位置公式未改**。R66/R67/R68 报告点名 3 round 未动 | "popovers should origin-aware" + "responsive positioning" | **XS** | 底层 |
| **E-P1-2** | `lib/core/theme/app_theme.dart:123, 209` | `disabledForegroundColor: cs.onSurface.withValues(alpha: 0.5)` + `hintStyle: ... withValues(alpha: 0.6)` 走 inline — 集中器 `AppColors.fgDisabled(context)` / `fgHintInput(context)` 已有但未应用。**TODO `// v0.25: 评估 buildTheme 接受 context` 挂 4 round**(R48→R65→R67→R69) | "decisions should be nameable" + 集中器复用 | **XS** | 底层 |
| **E-P1-3** | `lib/presentation/pages/trend/widgets/trend_heatmap_grid.dart:28, 52-53` | (a) `clamp(28.0, 48.0)` **28pt < 44pt minimum**(精神心理患者手指控制能力下降,emil 必加);(b) `Tooltip(message: '${date.month}/${date.day} ${checked ? "✓" : ""}')` 走 hardcoded "✓" 不走 l10n;(c) 整 cell 无 `Semantics` 包装 | "触控目标下限" + "a11y 标注 non-negotiable" | **XS** | 底层 |
| **E-P1-4** | `lib/presentation/pages/assessment/assessment_page.dart:124-128` | `LinearProgressIndicator(value: _answered / scale.items.length)` — (a) 切 quiz→result 时从 100% 跳到 0 无 tween 动画;(b) 无 `Semantics(value: ...)` 包装,屏幕阅读器只读"线性进度指示器" | "transition 应该是 tween" + "a11y" | **XS** | 底层 |
| **E-P1-5** | `lib/presentation/pages/medication/medication_calendar_page.dart:351-378` `_CellBox` | (a) 不可点击 / 不可 hover / 不可 focus;(b) **无 Semantics**,屏幕阅读器只读"3/15 ✓"不可达;(c) 实际尺寸算出来 7 天视图 cell 仅 28pt < 44pt。R66 报告点名 2 round | "a11y 必备" + "触控目标下限" | **S** | 底层 |
| **E-P1-6** | `lib/presentation/widgets/medication_report_dialog.dart:110-156` | 底部 3 按钮 (复制 / PDF / 分享) **3 种不同模式**:`PressFeedback(onTap: _copy, child: OutlinedButton(onPressed: null))` / `PressFeedback(child: LoadingTextButton)` / `PressFeedback(child: OutlinedButton(onPressed: _share))` — emil "consistency" 违反 | "DRY for taste" | **S** | 架构(抽集中器) |
| **E-P1-7** | `lib/presentation/pages/setup/setup_step_consent.dart:75-94` | **3 段重复 inline** 调 `ConsentCheckRow(checked, label, onTap, onView)`。`ConsentCheckRow` 集中器已有但**没有更高级 `ConsentCard` 集中器**走 R40 风格 `tintedPrimarySoft` 背景串联 3 个 | "DRY for taste" | **S** | 架构(抽集中器) |

**E-P1 修复总工作量:1-1.5 个工程师天**

### §3.3 P2 建议(emil 视角,9 项)

| # | 位置 | 问题 | 难度 | 类别 |
|---|------|------|------|------|
| **E-P2-1** | `lib/presentation/pages/setup/setup_step_done.dart:42, 52, 61, 73` | 4 处 `TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.w600)` / `TextStyle(fontSize: fontSizeBody, fontWeight: FontWeight.w500)` inline 跟 setup_step_consent / setup_step_welcome 完全同款 | **XS** | 底层 |
| **E-P2-2** | `lib/presentation/pages/medication/today_med_schedule.dart:62-67, 194-199` | 标题 `TextStyle(fontSize: fontSizeBody, fontWeight: w600)` + 时间 chip 数字 `TextStyle(fontSize: fontSizeBodySm, fontWeight: w600)` 重复模式 | **XS** | 底层 |
| **E-P2-3** | `lib/presentation/pages/medication/medication_calendar_page.dart:398-400` | `_legendItem` 3 处 magic strings `'< 50%' / '< 100%' / '100%'` — en/zh/zh_Hant 用户都看到 magic 字符串 | **XS** | 底层 |
| **E-P2-4** | `lib/presentation/pages/setup/setup_step_medication.dart:238-239` + `today_med_schedule.dart:83-84` + `medication/widgets/edit_medication_dialog.dart:316-317` + `mood/widgets/mood_tags.dart:42-43` + `trend_heatmap_grid.dart:21-22` | **6 处 `Wrap(spacing: 8, runSpacing: 8, ...)`** 8 magic 散落,AppTokens.spacingXs (8.0) 已有未用 | **XS** | 底层 |
| **E-P2-5** | `lib/presentation/pages/medication/widgets/medication_row.dart:126-161` | 3 个 IconButton + 1 个 conditional spinner,spinner 出现时 3 个 button 全消失 → loading 完突现,**无 AnimatedSwitcher 切换**。R66 报告点名 2 round | **XS** | 底层 |
| **E-P2-6** | `lib/core/theme/app_spacing.dart:58` | `celebrationDisplayMs = 1800` — emil "rare/delight 频度上限 1000ms",R40 round 23 (P1-12) 把 MotionScheme.delight 改成 1000ms **但 celebrationDisplayMs 仍是 1800ms**(用户"等不到"新页面) | **XS** | 底层 |
| **E-P2-7** | `lib/presentation/pages/setup/setup_step_medication.dart:103-128` | "下一步" 按钮 26 行 `Stack(PrimaryButton + IgnorePointer(CircularProgressIndicator))` 是 R43 已抽的 `LoadingTextButton` 集中器的同款重复未应用 | **XS** | 底层 |
| **E-P2-8** | `lib/presentation/pages/medication/medication_calendar_page.dart:367` | 漏服 = `AppTokens.dividerColor(context)` 灰**几乎不可见**(divider 在 tinted background 上)。emil "重要状态应当明显"违反 | **XS** | 底层 |
| **E-P2-9** | 8+ 处 atomic size magic:`SizedBox(width: 18, height: 18)` × 3 处 / `SizedBox(width: 20, height: 20)` × 1 处 / `SizedBox(width: 36, height: 36)` × 1 处 / `SizedBox(width: 40, height: 40)` × 4 处 / `SizedBox(width: 110, height: 44)` × 1 处 | 抽 `AppTokens.iconSizeTrailing` 18 / `spinnerSizePdf` 20 / `legendDotSizeLg/Sm` 12/10 / `avatarSizeSm/Md` 36/40 / `buttonWidthNarrow` 110 / `buttonHeightCompact` 44 共 7 个 atomic token | **S** | 底层 |

**E-P2 修复总工作量:0.5-1 个工程师天**

### §3.4 详细数据(emil 视角独有)

**emil 决策框架应用率统计**(R69 实测):

| 类别 | 集中器覆盖 | 散落 | 覆盖率 |
|------|----------|------|--------|
| PressFeedback (button :active scale) | 30+ 处 | 0 | 100% ✅ |
| AppSnackBar (4 类) | 55+ 处 | 0 | 100% ✅ |
| `AppColors` 颜色(dynamic theme-aware) | 100+ 处 | 0 散落 + 2 const | 99% ⚠️ |
| `AppTokens.textStyleXxx` 字体集中器 | 100+ 处 | setup_step_done 4 处 + 评估分数 2 处 | 96% ⚠️ |
| `AppTokens.spacingXxx` 间距 | 100+ 处 | Wrap(spacing: 8) 6 处 | 95% ⚠️ |
| `AppTokens.radiusXxx` 圆角 | 100+ 处 | 0 | 100% ✅ |
| `AppTokens.shadowXxxOf(context)` 阴影 | 4 集中器全 codebase | 0 散落(const 4 个 R59 已删) | 100% ✅ |
| `AppTokens.curveXxx` 缓动 | 6 curve 集中器 | 0 散落(注释除外) | 100% ✅ |
| `Motion.duration/curve` reduce-motion 包装 | 16 处 | (key widget 都已包) | ~95% ✅ |
| 动画用 GPU-only(`transform` / `opacity`) | 0 违规 | 0 | 100% ✅ |
| a11y `Semantics` 标注 | 5+ 处 | heatmap / calendar / progress 3 处漏 | 70% ⚠️ |
| 触控目标 ≥ 44pt | 100+ 按钮 | heatmap 28pt / calendar 28pt | 95% ⚠️ |
| Atomic size token | **0 集中器** | 8+ 处 18/20/36/40/110 | 0% ❌ |

**emil 10 维度评分卡(R69)**:

| 维度 | R66 | R68 | R69 | 评语 |
|------|-----|-----|-----|------|
| 微交互(:active scale / haptic) | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | PressFeedback 30+ 处覆盖, Haptics 集中器 |
| 动效 token 化 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 6 curve + 8 duration + scrimAlpha + shadow 4 个全 theme-aware |
| 设计 token 颜色 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | R67 大幅改善,**仍漏 settings_page 2 处**(E-P0-1) |
| 设计 token 字号 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | R67 抽 StatCard,**仍漏 setup_step_done 4 处 + 评估分数 2 处**(E-P2-1, E-P2-2) |
| 设计 token 间距 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **仍漏 Wrap(spacing: 8) 6 处**(E-P2-4) |
| 设计 token 圆角 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | 6 radius token + 100% 走 token |
| 阴影 | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | R59 删 4 个 const 强制 theme-aware |
| 视觉层级 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | SegmentedButton 选中态略弱 + 漏服色太弱 |
| 可达性 (a11y) | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | heatmap / calendar / progress 3 处不可达(E-P1-3/4/5) |
| 触控目标 (44pt) | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐ | heatmap 28pt / calendar 28pt 双 bug 仍漏(E-P1-3/5) |
| 文字对比度 (WCAG) | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | 整体依赖 M3,3 处疑点(R68 报告) |
| 高内聚(重复模式) | ⭐⭐⭐ | ⭐⭐⭐⭐½ | ⭐⭐⭐⭐½ | R67 抽 6 个集中器,**仍漏 4 个强候选**(E-P1-6/7 + scrim + Spinner) |
| 半成品 / WIP | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | **1 个 TODO 挂 4 round 仍未删**(`app_theme.dart:128`) |
| **总评** | ⭐⭐⭐⭐ | ⭐⭐⭐⭐½ | **⭐⭐⭐⭐½** | **持平 R68**:R68 修 3 P0(emil 0 进展),剩余 12 项 P0/P1 跨 4 round 挂死 |

---

## §4 上架相关(emil 视角)

### §4.1 截图风格

| 平台 | 数量 | 状态 | 建议 |
|------|------|------|------|
| iOS `fastlane/metadata/ios/*/phone_screenshots/*.png` | 27 张必填 | **67 字节透明占位** | 需真截图(emil 视角要求:展示"用户感受"而非"功能罗列") |
| iOS `fastlane/metadata/ios/*/app_icon.png` | 3 个 | 67 字节占位 | 1024×1024 真图(M3 主色 0xFF6BCF7F 绿色 + 药丸 motif) |
| iOS `fastlane/metadata/ios/*/video.txt` | 1 文件 | PLACEHOLDER URL | 30 秒动效 demo(CelebrationBounce + FadeIn + PageTransitionSwitcher) |
| Android `fastlane/metadata/android/*/phone_screenshots/*.png` | 8 张必填 | 67 字节占位 | 同上 |
| Android `fastlane/metadata/android/*/feature_graphic.png` | 2 张 | 67 字节占位 | 1024×500 真图 |
| Android `fastlane/metadata/android/*/icon.png` | 2 个 | 1443 字节 / 192×192 | 512×512 |
| Android `fastlane/metadata/android/*/video.txt` | 1 文件 | PLACEHOLDER URL | 同 iOS |

**emil 视角建议**:
- 截图应**优先展示"庆祝弹跳 + 主页打卡"**(1-3 张)+ "趋势日历" + "情绪记录" + "用药报告"(PDF 缩略图)
- 充分利用 `CelebrationBounce` (R24 P1-2) + `FadeIn` (R17 P1-1) 动效在视频里展示 — emil "delight 频度档位可演示" 原则
- 1 套设计语言 + 3 色模式(light / dark / 高对比) — 适合 M3 ColorScheme 自动适配演示

### §4.2 元数据描述

**pubspec.yaml description**(CC-5 修中):

```yaml
description: "鎴戜粖澶╁悆浜嗚嵂 - 绮剧蹇冪悊鎮ｈ€呭悆鑽墦鍗?+ 鍋滆嵂閫氱煡"
```

(GBK 终端显示乱码,实际 UTF-8 中文)

**emil 视角建议**:
- description 需加 en / zh_Hant 3 语言版本(CC-5)
- 文案应避免病耻感措辞("让家人放心" / "你真棒")— 改中性鼓励("已坚持 5 天" / "本周完成 7/7")
- "失联通知" 业务暂停 vs 4 文档写功能可用(CC-7)— emil "声明跟实现不一致"

### §4.3 App Store preview

| 资产 | 状态 | 建议 |
|------|------|------|
| App preview video | 占位 | 30s 动效 demo |
| 截图文字 overlay | 占位 | 使用 `AppTokens.textStyleHeadline` + `primaryColor` 风格 |
| 截图内 UI 一致性 | — | 截图应跟 `app_theme.dart` 渲染一致(已 100%) |

**emil 视角上架 checklist**(无关 P0/P1,作为"上架前最后一公里"):

1. ☐ 截图必须 3 张以上,展示核心动效(庆祝 + FadeIn + PageTransitionSwitcher)
2. ☐ App preview video 30s 必填 iOS,iOS 17+ 支持 HEVC
3. ☐ 截图文字 overlay 用 `AppTokens.textStyleDisplayLarge` + `AppColors.fgOnPrimary` 风格统一
4. ☐ App icon 必须 1024×1024 + 4 套(@1x/@2x/@3x 衍生),主色 `#6BCF7F` + 药丸 motif
5. ☐ Feature graphic 必须 1024×500 Android,展示"已坚持 30 天"等 milestone

---

## §5 修复优先级总表

### §5.1 emil 视角 P0 必修(2 项,~30 min)

| 序 | 类别 | 位置 | 难度 | 关键 |
|----|------|------|------|------|
| 1 | 底层 | `lib/presentation/pages/settings/settings_page.dart:63, 92` 2 处 const `AppColors.success` / `AppColors.primary` → `AppColors.fgOnSuccess` / `AppColors.primaryColor(context)` | **XS** | E-P0-1,R66 挂 3 round |
| 2 | 底层 | `lib/presentation/widgets/medication_report_dialog.dart:166-194` scrim 外加 `AbsorbPointer` | **XS** | E-P0-2,modal 锁死 |

### §5.2 emil 视角 P1 应修(7 项,~1-1.5 天)

| 序 | 类别 | 位置 | 难度 | 关键 |
|----|------|------|------|------|
| 3 | 底层 | `lib/presentation/pages/home/home_page.dart:633` `top: MediaQuery.of(ctx).size.height * 0.35` → `top: MediaQuery.padding.top + AppTokens.spacingLg` | **XS** | E-P1-1,撞顶 |
| 4 | 底层 | `lib/core/theme/app_theme.dart:123, 209` 2 处 inline `withValues(alpha: 0.5/0.6)` → `AppColors.fgDisabled(context)` / `fgHintInput(context)`,删 TODO | **XS** | E-P1-2,删挂 4 round TODO |
| 5 | 底层 | `lib/presentation/pages/trend/widgets/trend_heatmap_grid.dart:28, 52-53` 改 28→44pt + Tooltip 走 l10n + 加 `AppSemantics.container` | **XS** | E-P1-3,触控目标 + a11y 双 bug |
| 6 | 底层 | `lib/presentation/pages/assessment/assessment_page.dart:124-128` `LinearProgressIndicator` 加 `TweenAnimationBuilder` + `Semantics` | **XS** | E-P1-4,tween + a11y |
| 7 | 底层 | `lib/presentation/pages/medication/medication_calendar_page.dart:351-378` `_CellBox` 加 `AppSemantics` + 改 28pt → 36pt+ | **S** | E-P1-5,a11y + 触控 |
| 8 | 架构(抽集中器) | `lib/presentation/widgets/medication_report_dialog.dart:110-156` 抽 `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` 集中器,3 处统一 | **S** | E-P1-6,consistency |
| 9 | 架构(抽集中器) | `lib/presentation/pages/setup/setup_step_consent.dart:75-94` 抽 `ConsentCard(title, checked, onTap, onView)` 串联 3 个 | **S** | E-P1-7,DRY |

### §5.3 emil 视角 P2 建议(9 项,~0.5-1 天)

| 序 | 类别 | 位置 | 难度 | 关键 |
|----|------|------|------|------|
| 10 | 底层 | `lib/presentation/pages/setup/setup_step_done.dart:42, 52, 61, 73` 抽 `AppTokens.textStyleSetupTitle` / `textStyleSetupSubtitle` 集中器 | **XS** | E-P2-1,4 处 inline |
| 11 | 底层 | `lib/presentation/pages/medication/today_med_schedule.dart:62-67, 194-199` 改 `AppTokens.textStyleBodyStrong(context)` + 抽 `textStyleChipTime` | **XS** | E-P2-2,标题/时间 chip |
| 12 | 底层 | `lib/presentation/pages/medication/medication_calendar_page.dart:398-400` 加 3 个 l10n key `medsCalendarLegendP50/P100/P100Full` | **XS** | E-P2-3,magic 字符串 |
| 13 | 底层 | 6 处 `Wrap(spacing: 8, runSpacing: 8, ...)` → `AppTokens.spacingXs` (8.0) | **XS** | E-P2-4,6 处 magic |
| 14 | 底层 | `lib/presentation/pages/medication/widgets/medication_row.dart:126-161` trailing 加 `AnimatedSwitcher(duration: durFast)` | **XS** | E-P2-5,button 切换 tween |
| 15 | 底层 | `lib/core/theme/app_spacing.dart:58` `celebrationDisplayMs = 1800` → 1000ms | **XS** | E-P2-6,emil rare 上限 1000ms |
| 16 | 底层 | `lib/presentation/pages/setup/setup_step_medication.dart:103-128` "下一步" 26 行 `Stack(IgnorePointer+spinner)` → `LoadingTextButton` 集中器 | **XS** | E-P2-7,DRY |
| 17 | 底层 | `lib/presentation/pages/medication/medication_calendar_page.dart:367` 漏服灰太弱 → `errorColor.withValues(alpha: 0.3)` 或新加 `adherenceMissed` token | **XS** | E-P2-8,重要状态应明显 |
| 18 | 底层 | 8+ 处 atomic size magic(18/20/36/40/110)抽 7 个 `AppTokens.iconSizeTrailing/spinnerSizePdf/legendDotSizeLg/Sm/avatarSizeSm/Md/buttonWidthNarrow/buttonHeightCompact` 集中器 | **S** | E-P2-9,8+ 处 magic 集中 |

### §5.4 修复总工作量估算

| 类别 | 项数 | 难度 | 工作量 |
|------|------|------|--------|
| P0 | 2 | XS × 2 | **30 min** |
| P1 | 7 | XS × 5 + S × 2 | **1-1.5 天** |
| P2 | 9 | XS × 8 + S × 1 | **0.5-1 天** |
| **总计** | **18** | — | **2-3 个工程师天** |

---

## §6 3-5 句精炼建议

1. **R68 commit 没动 emil 任何 P0 — 优先修 2 个 P0 跨 4 round 挂死项**:`settings_page.dart:63, 92` 2 处 const 硬编 dark mode 漏反白 + `medication_report_dialog:166-194` scrim 缺 `AbsorbPointer` 锁死底部按钮。30 分钟内 2 个 P0 同时清,跟 R68 修 CC-1/CC-3/CC-6 同样价值。

2. **emil 体系本身已是 v1.0 上 store 水平**:6 个 R67 集中器(InfoBanner / StatCard / DialogActionsRow / ChoiceChipWrap / SwipeDeleteBackground / ConsentDialog)+ 4 文件拆 sub-file(app_colors / app_motion / app_spacing / app_typography)+ 4 shadow theme-aware + 6 curve + 4 档 MotionScheme 决策框架 + Motion reduce-motion 包装 — 整体设计成熟度 ⭐⭐⭐⭐½ 维持 R68,**没掉档**。

3. **剩 5% 边缘"差一口气"问题集中在 3 类**:(1) **2 处 dark mode 漏**(E-P0-1, R49 修 35+ 处漏 2 处);(2) **3 处 a11y/触控目标不达标**(heatmap 28pt / calendar 28pt / progress 无 Semantics)— 精神心理 App 屏幕阅读器用户不少,emil "a11y 是 non-negotiable" 违反;(3) **5 处 magic strings + 6 处 Wrap(spacing: 8) + 8+ 处 atomic size** — 集中器已存在但未应用(emil "decisions should be nameable")。

4. **建议 R69 立即修 E-P0 2 项 + E-P1 5 项 XS 部分**(总 4-6h),把"跨 4 round 挂死"和"a11y 必备"全清;E-P1 抽 2 个集中器(OutlinedButtonWithPress / ConsentCard)+ E-P2 抽 7 个 atomic size token 跟 R67 集中器批量抽同等价值,合计 **2-3 个工程师天可清 18 项**(占 emil 18 项 100%)。

5. **上架(emil 视角)**:33 张 iOS 截图 + 8 张 Android 截图 + 3 个 app icon + 2 个 feature_graphic + 2 个 video.txt 全 67 字节占位 — **上架前最后 12% 不是代码,是 30 张真截图 + 1 个 30s App preview video**。emil "Beauty is leverage" 原则下,展示 `CelebrationBounce` + `FadeIn` + `PageTransitionSwitcher` 动效的 video 比 100 张静态截图更能传达"精神心理 App 也能有温度"。

---

## §7 附录

### §7.1 R66 → R68 emil 关键变化

| 类别 | R66 | R68 | R69 | 评语 |
|------|-----|-----|-----|------|
| **AppTokens god constant** | 644 行 8 大类 | 246 行 facade + 4 sub-file | 同 R68 | R65 拆到位 |
| **Widget 集中器** | 5 个(R40) | 11 个(R67 加 6) | 同 R68 | DRY 显著改善 |
| **shadow dark mode** | 4 个 const 散落 | 4 dynamic getter 强制 | 同 R68 | R59 删 const 修 silent bug |
| **scrimAlpha 集中器** | 0 | 1(0.54) | 同 R68 | R65 抽 |
| **reduce-motion 包装** | 16 处 | 16 处 | 同 R68 | 维持 |
| **emil P0** | 4 项 | 2 项 | **2 项** | R68 0 进展 |
| **emil P1** | 6 项 | 6 项 | **7 项** | +1 |

### §7.2 emil P0/P1 跨 round 挂死表

| 编号 | 位置 | R66 | R67 | R68 | R69 | 跨 round |
|------|------|-----|-----|-----|-----|---------|
| E-P0-1 | `settings_page.dart:63, 92` dark mode | 挂 | 挂 | 挂 | **挂** | 4 round |
| E-P0-2 | `medication_report_dialog:166-194` scrim AbsorbPointer | 挂 | 挂 | 挂 | **挂** | 3 round |
| E-P1-1 | `home_page.dart:633` 35% 高度 | 挂 | 挂 | 挂 | **挂** | 3 round |
| E-P1-2 | `app_theme.dart:128, 209` withValues inline + TODO | 挂(R48 起) | 挂 | 挂 | **挂** | 4 round(R48→R65→R67→R69) |
| E-P1-3 | `trend_heatmap_grid:28, 52-53` 28pt + ✓ 字符串 + Semantics | 挂 | 挂 | 挂 | **挂** | 3 round |
| E-P1-4 | `assessment_page:124-128` LinearProgress tween + Semantics | 挂 | 挂 | 挂 | **挂** | 3 round |
| E-P1-5 | `medication_calendar:351-378` _CellBox Semantics + 28pt | 挂 | 挂 | 挂 | **挂** | 3 round |
| E-P1-6 | `medication_report_dialog:110-156` 3 模式不一致 | 挂 | 挂 | 挂 | **挂** | 3 round |
| E-P1-7 | `setup_step_consent:75-94` ConsentCard 集中器 | 挂 | 挂 | 挂 | **挂** | 3 round |

**9 项跨 3-4 round 挂死 — emil 报告"已点名 N round 仍未动"清单**。

### §7.3 R68 emil 抽 6 集中器覆盖详情

| 集中器 | R68 报告使用数 | R69 实测 | 评价 |
|--------|---------------|---------|------|
| `InfoBanner` (4 tone + muted) | 3 处 | 3+ 处 | ✅ 抽到位 |
| `StatCard` | 8 处 | 8+ 处 | ✅ 抽到位 |
| `DialogActionsRow` | 4 处 | 4+ 处 | ✅ 抽到位 |
| `ChoiceChipWrap<T>` | 2+ 处 | 2+ 处 | ✅ 抽到位 |
| `SwipeDeleteBackground` (rounded) | 3 处 | 3+ 处 | ✅ 抽到位 |
| `ConsentDialog` (PIPL §13) | 1 处 | 2+ 处(R68 扩到 setup) | ✅ 抽到位 + 扩到 setup |

### §7.4 R68 推荐 R69 继续抽(4 个强候选 — R69 仍 0 进展)

| 重复模式 | 出现位置 | 建议集中器 | 难度 |
|---------|---------|-----------|------|
| 3 段重复 `ConsentCheckRow` | `setup_step_consent.dart:75-94` | `ConsentCard(title, checked, onTap, onView)` | S |
| `OutlinedButton.icon + PressFeedback` 3 模式 | `medication_report_dialog.dart:110-156` | `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` | S |
| `scrim + 中心 Card(spinner + 文字)` | `medication_report_dialog.dart:166-194` | `LoadingScrim(message, isLoading)` | XS |
| `InlineSpinnerInTrailing` 3 模式 | `medication_row.dart:131` / `contacts_list_widget.dart:75-83` / `notification_status_card.dart:219-224` | `TrailingSpinner` 集中器 | XS |

### §7.5 已审文件清单(增量于 R68)

| 类别 | 文件 |
|------|------|
| Theme | `app_tokens.dart` (246 行 facade) / `app_colors.dart` (278 行 26 集中器) / `app_motion.dart` (254 行 6 curve + 4 MotionScheme + Motion + 4 shadow) / `app_spacing.dart` / `app_typography.dart` / `app_theme.dart` |
| Animations | `fade_in.dart` (R17 P1-1, 2 档 withScale 区分 rare/occasional) / `slide_up.dart` / `page_transition_switcher.dart` (R63 durPageTransition token) / `celebration_bounce.dart` (R40 + R24 P1-2) / `animations.dart` |
| Widgets 集中器 | `press_feedback.dart` (R40 + R21 P0-9) / `press_feedback_icon_button.dart` (R23 P3-32) / `app_list_tile.dart` (R24 + R26 C-12) / `app_snack_bar.dart` (R37 4 类 + 4 showX 工厂) / `loading_skeleton.dart` (R59 Timer 修 dispose race) / `loading_text_button.dart` / `check_in_button.dart` (核心打卡 + streak tween) / `empty_state.dart` / `error_state.dart` / `app_semantics.dart` (R24 P1-18 3 kind 集中器) / `chip_badge.dart` (4 tone) / `section_header.dart` / `primary_button.dart` / `last_startup_error_banner.dart` (R27 R62 P1-15) / `last_med_info.dart` / `medication_report_dialog.dart` (E-P0-2 关键) / **`info_banner.dart`** (R67 C-2 4 tone) / **`stat_card.dart`** (R67 C-4) / **`dialog_actions_row.dart`** (R67 C-3) / **`choice_chip_wrap.dart`** / **`swipe_delete_background.dart`** (R67 C-6) / **`consent_dialog.dart`** (R27 R62 P0-2) |
| Pages 核心 | `home_page.dart` (E-P1-1 关键) / `settings_page.dart` (E-P0-1 关键) / `setup_page.dart` (R68 CC-1) / `medication_calendar_page.dart` (E-P1-5 / E-P2-3 / E-P2-8) / `trend_page.dart` / `vent_list_page.dart` / `assessment_page.dart` (E-P1-4) / `today_med_schedule.dart` (E-P2-2) / `medication_row.dart` (E-P2-5) / `refill_manage_page.dart` / `setup_step_consent.dart` (E-P1-7) / `setup_step_medication.dart` (E-P2-4 / E-P2-7) / `setup_step_done.dart` (E-P2-1) / `setup_widgets.dart` / `trend_heatmap_grid.dart` (E-P1-3) |
| R68 改文件 | `domain/usecases/fire_care_strategy.dart` (CC-6) / `core/data/feature_flags.dart` (CC-3) / `core/data/database/app_database.dart` (CC-1) / `core/theme/app_theme.dart` (R68 无改动) |

---

**报告完毕。** 跟 R68 报告(`round68-emilkowalski.md` 32KB / 360 行)对比,R69 总问题数持平 18(emil 视角 2 P0 + 7 P1 + 9 P2),但 **R68 commit 0 进展 emil 任何 P0/P1 — 9 项跨 3-4 round 挂死**(E-P0-1/2 + E-P1-1/2/3/4/5/6/7)。R70 建议立即修 2 P0 + 5 P1 XS 部分(4-6h),E-P1 抽 2 个集中器 + E-P2 抽 7 个 atomic token + 1 个 `OutlinedButtonWithPress` / `ConsentCard` / `TrailingSpinner` / `LoadingScrim` 集中器(2-3 天工作量)可清 18 项 100%。
