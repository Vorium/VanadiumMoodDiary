# emil-kowalski 视角审视报告（R32，2026-08-11）

> 视角：Material 3 / Apple HIG 资深设计系统工程师，token-first、动效克制、节奏感、ink/ripple 反馈到位。
> 上一轮 R31: 8.5/10。本轮独立打分，不被前轮影响。

## 0. 评分

**emil 视角总分: 8.2/10**（上轮 8.5，**-0.3**）

| 子维度 | 分数 | 变化 | 评语 |
|---|---|---|---|
| 颜色集中 | 8.5/10 | +0.5 | `app_colors.dart` iOS system color palette 极好，8 metric / 6 pill / tinted* 系列 4 视图 `Colors.transparent` 之外 0 硬编码 |
| 字体集中 | 8.0/10 | -0.5 | `AppTypography.textStyleMetric*` 4 个集中器完美，但 18+ 处 raw `FontWeight.w500/w600/w700` (settings + trend + home) 绕过 token |
| 动效 token | 9.5/10 | +0.5 | `app_motion.dart` 6 curve + 4 阴影 + 4 档 `MotionScheme` 集中完整。**全 lib 0 处 `Curves.` 硬编码**（除 `app_motion.dart` 自身），mood carousel 走 `curveSpring` 精准 |
| 节奏感 | 9.0/10 | +0.5 | stagger 8→3 闭环；durPress 160→100ms（spec §3.4.1 "必须感觉快"）；R9a 主页 stagger 仅 2 步（0/30/60ms）不超前庭敏感阈值 |
| inkwell 反馈 | 8.5/10 | -0.5 | `PressFeedbackIconButton` 集中器好，**仍 8 处 raw `IconButton`**（page_scaffold:42 / medication_page:87 / add_medication_page:135 / mood_detail_page:28 / crisis_hotline_page:185,192 / tracking_customize_page:144 / daily_tracking_page:77） |
| Apple Health 视觉还原 | 9.5/10 | +0.5 | 5 token 集中器 + 6 widget 集中器 + 5 page 重设 + 9 page follow。AppleListSection / AppleHealthTile / StatCard 4 variant 完美 |
| Material 3 规范 | 7.5/10 | -0.5 | 0 ElevatedButton 集中器（PrimaryButton 3 variant 替代 ok）；Haptics 集中器 4 处仍走；PressFeedback mode 1/2 双模式优秀 |

**加权 8.2 = (颜色 8.5 × 0.15 + 字体 8.0 × 0.10 + 动效 9.5 × 0.15 + 节奏 9.0 × 0.10 + inkwell 8.5 × 0.15 + AppleHealth 9.5 × 0.20 + M3 7.5 × 0.15) = 8.2**

**关键变化 (R31 → R32)**:
- **+**: iOS system color palette (`healthMetricsColors` 8 metric) 上线；AppleListSection 4 page 完成；mood 5 档圆形 button + spring 1.1 放大到位；stagger 8→3 闭环
- **-**: 主页 12 处硬编码中文（"今日指标"/"心情"/"更多"/"设置" / "树洞"/"查看过往记录" / "私密空间" / "提醒 / 隐私 / 数据导出" / "用药"/"记录"/"开始"/"倾诉"）— 上一轮 R31 已指 "持平抵消新引入 4 处硬编码"，本轮**累计已 12+ 处未补**；medication_page top 4 tile 4 处硬编码 ("待服"/"已服"/"需续方"/"查看")；`Spring` 145 行 0 caller 死代码；`mood_trend_page` 5/2 处硬编码 iOS color；QuickMoodCarousel 缺 Haptics.success 调用（注释说"触觉反馈"实际 0 处）

---

## 1. 上架/合规 P0

### P0-01 [lib/presentation/pages/medication/medication_page.dart:138-161] 4 处 hardcode 中文 + 1 个 TODO(Phase 5)
```dart
AppleHealthTile(metricId: 'medication', label: '待服', value: '${_pendingCount(slots)}'),
AppleHealthTile(metricId: 'medication', label: '已服', value: '${_takenCount(slots)}'),
AppleHealthTile(metricId: 'medication', label: '需续方', value: '${_refillAlertCount(meds)}', onTap: ...),
AppleHealthTile(metricId: 'medication', label: l10n.medsCalendarTitle, value: '查看', onTap: ...),
```
4 个 hardcode 中文 + 第 4 个 value 也 hardcode，TODO 注释说"Phase 5 用 ARB 替换" — Phase 5 已经过了，en 用户看 "待服" / "已服" 困惑。
**修复**: 加 ARB key `medPendingCount` / `medTakenCount` / `medNeedRefill` / `medViewAction`，在 4 处用 `l10n.xxx` 替换。l10n 文件 `lib/l10n/app_zh.arb` + `app_en.arb` 加 4 键。

### P0-02 [lib/presentation/pages/home/widgets/secondary_action_row.dart:46,52,61,68-69,75,77] 7 处 hardcode 中文
```dart
title: '更多',              // line 46
title: '心情',              // line 52
subtitle: '查看过往记录',   // line 61 (TODO 注释)
title: '树洞',              // line 68 (TODO)
subtitle: '私密空间 · 1 人可见', // line 69
title: '设置',              // line 76 (TODO)
subtitle: '提醒 / 隐私 / 数据导出', // line 77
```
**修复**: 加 ARB key `homeMoreSection` / `homeMoreMood` / `homeMoreMoodHistory` / `homeMoreVent` / `homeMoreVentDesc` / `homeMoreSettings` / `homeMoreSettingsDesc` 共 7 条；l10n.dart 已用 `l10n.moodRecordButton` 模式（line 53 已替换成功），其余 6 处照搬。

### P0-03 [lib/presentation/pages/home/widgets/primary_action_row.dart:67,68,76,77,90,98,99] 7 处 hardcode 中文
```dart
label: '用药', value: '查看',  // 4 处 tile 共 7 个 hardcode
label: '心情', value: '记录',
value: '倾诉',                // vent 的 value
label: '评估', value: '开始',
```
**修复**: 加 ARB key `homeQuickMed` / `homeQuickMedAction` / `homeQuickMood` / `homeQuickMoodAction` / `homeQuickVentAction` / `homeQuickAssessment` / `homeQuickAssessmentAction` 共 7 条。

### P0-04 [lib/presentation/pages/home/widgets/quick_mood_carousel.dart:84] hardcode 中文 SnackBar + 绕过 AppSnackBar 集中器
```dart
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(
    content: Text('记录失败，请重试'),   // hardcode 中文
    duration: AppTokens.snackBarDurationShort,
  ),
);
```
2 个问题：
1. 硬编码 "记录失败，请重试" → en 用户看 "记录失败，请重试"
2. **绕过 `AppSnackBar` 集中器**（其他 4 处都用 `AppSnackBar.showError`），跟 R22 P0-9 集中器策略冲突

**修复**: 替换为 `AppSnackBar.showError(context, error: e)`（e 来自 catch 参数，已经有）；同时加 ARB key `moodQuickSaveFailed`（可走 `l10n.moodQuickSaveFailed`）。

### P0-05 [lib/presentation/pages/home/widgets/quick_mood_carousel.dart:60-71] 缺 Haptics.success 调用
```dart
try {
  await ref.read(moodRepositoryProvider).add(draft: ...);
  if (!mounted) return;
  setState(() => _selected = score);
  // 触觉反馈 (emil "feedback" 原则: press 后即时确认)
  // PressFeedback scale 0.97 + 这里 Haptics 一起, 跟 checkIn 风格一致
  // <-- 这里实际 0 行代码 — 只有注释!
} catch ...
```
注释说"跟 checkIn 风格一致"但**实际没有 Haptics.success() 调用**。emil "feedback" 原则：1 tap 速记后必须给用户即时确认反馈，press scale 0.97 已经给了视觉反馈，但**触觉反馈缺失**，精神心理患者前庭/感官反馈需求高于普通用户。
**修复**: `setState(() => _selected = score)` 后加 `unawaited(Haptics.success())` + import `feedback.dart show Haptics`。**注意是 `unawaited`** 避免 fire-and-forget linter。

### P0-06 [lib/presentation/pages/home/widgets/today_summary_card.dart:72] hardcode "今日指标"
```dart
return AppleListSection(
  title: '今日指标',   // hardcode 中文, 跟 widget 内其它 label 都走 l10n 矛盾
  margin: EdgeInsets.zero,
  ...
```
Widget 内部 4 个 `StatCard.label` 全部走 `l10n.todaySummaryCheckIn` / `todaySummaryStreak` / `todaySummaryMeds` / `todaySummaryMood`（lines 85/93/108/116），**只有 title 是 hardcode**。AppleListSection.title 在 widget 内部被 ALL CAPS 渲染（spec §4.5），中文 case-less 视觉等同 13pt w500 letterSpacing 0.6 textHint。
**修复**: title 改 `l10n.homeTodayMetrics` (需新增 ARB key)。

### P0-07 [lib/presentation/pages/home/widgets/primary_action_row.dart:54] 同款 hardcode "快捷操作" 实际已走 l10n
回看 R9a 注释：本 widget 4 个 tile 的 label/value 故意 hardcode（"暂不允许动 l10n 文件，见 plan §I"）。但 widget **外层 title** `l10n.medQuickActions` (line 54) **已走 l10n**。AppleListSection title 是用户最显眼入口，跟内部 4 个 tile label 同样重要。R9a 注释和 P0-03 是同一文件但矛盾：title 走 l10n 而 content 不走。
**修复**: 同 P0-03，l10n 化 7 处，移除 line 22-23 R9a 注释"Phase 5 不允许动 l10n"的 obsolete 解释（Phase 5 已完成）。

### P0-08 [lib/core/theme/spring.dart:1-145 全文] 死代码 — 0 caller, 145 行 0 import
```bash
$ grep -rn "import.*spring\|Spring\." lib/ | grep -v app_motion | head
lib/core/theme/spring.dart:48:/// final spring = Spring.standard;  // 或 Spring.of(context, SpringType.standard)
lib/core/theme/spring.dart:77:  static const Spring standard = Spring(
lib/core/theme/spring.dart:95:  static const Spring bouncy = Spring(
```
`lib/` 全代码库**无任何 `import 'package:chroniccare/core/theme/spring.dart'`**，仅 `app_motion.dart` 在 doc 注释里提到 `Spring.standard` 作为参考。R31 P0 半成品"P0-08: Spring 接 _EntrySpring" — 状态 0 进展。
emil "decisions should be nameable" — 145 行未使用代码 = 误导后续开发者以为"项目用 Spring 物理模型"，但实际只走 `curveSpring`（cubic-bezier 模拟）。
**修复**: 二选一：
- (A) 删除 `lib/core/theme/spring.dart` 全文（145 行），从 `app_motion.dart:36,113,114,17,24` 移除 Spring 引用。
- (B) 接 `_EntrySpring`（R31 计划），把 `check_in_button.dart:82 _EntrySpring` 改为用 `Spring.standard.toSimulation()`。后者让 Spring 集中器真正"被用"，但工作量大（R31 估计 ≤2.5h）。

**推荐 (A)** — 当前 QuickMoodCarousel 已用 `curveSpring` cubic-bezier 模拟 1.1 放大，效果到位；Spring 物理模型对短暂 UI 反馈（200-400ms）跟 cubic-bezier 视觉差异可忽略；emil "good defaults matter more than options"。

### P0-09 [lib/core/theme/app_colors.dart:48 注释 vs app_colors.dart:419-431] spec §3.1.3 "Apple Health" 关键词 lock-in 缺失（半成品）
R31 报告 P0-004 要求 "Apple Health 关键词 lock-in 扩 lib/ 注释"。当前 `app_colors.dart:48` 注释提到 "Apple Health "favorites" 标准绿"（1 处），`app_colors.dart:419-430` 8 metric palette 注释提到 spec §3.1.3 表 1:1（1 处），`app_motion.dart:107-123` 提到 3 Apple 自定义 cubic-bezier（3 处）。
**但** `app_typography.dart` 17 pt body / 13 pt caption / ultralight w200 大数字 0 处 Apple Health 关键词；`AppleListSection` / `AppleHealthTile` / `StatCard` 集中器 0 处 spec §4 引用（自身有 spec §4.5 / §4.4 但注释深度不够）。导致后续维护者改 token 时**不知道这是 iOS SF Pro Display / Apple system color**，可能误改为 Material 3 风格。
**修复**: 给 `app_typography.dart` / `app_spacing.dart` / 6 widget 集中器（apple_list_section / apple_health_tile / stat_card / primary_button / check_in_button / quick_mood_carousel）文件头注释加 1 行 `// Apple Health 风格 (spec §3.2 / §4.X): ...` 引用。

---

## 2. 架构/重构 P0

### P0-10 [lib/presentation/widgets/page_scaffold.dart:42-45] raw IconButton (无 PressFeedback)
```dart
showLeading = leading ??
    (canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: () => context.pop(),
          )
        : null);
```
emil: 全 App 顶部返回按钮应该是 PressFeedbackIconButton 集中器，保持 scale 0.97 + haptic 一致。PageScaffold 是**所有页面**的入口（30+ 调用点），影响面最大。
**修复**: 改 `PressFeedbackIconButton(icon: Icons.arrow_back_rounded, tooltip: MaterialLocalizations.of(context).backButtonTooltip, onPressed: () => context.pop())`。

### P0-11 [lib/presentation/pages/medication/medication_page.dart:87-91] raw IconButton
```dart
PressFeedback(
  child: IconButton(
    icon: const Icon(Icons.add_rounded),
    tooltip: l10n.medAddTooltip,
    onPressed: () => context.push('/medication/add'),
  ),
),
```
**外层有 `PressFeedback` 包**（不是裸 `IconButton`），但风格不一致 — 应该用 `PressFeedbackIconButton` 集中器。R31 7 处 raw IconButton 中**这 1 处是已被 PressFeedback 包但没用集中器**，最容易被后续 review 漏掉。
**修复**: 替换为 `PressFeedbackIconButton(icon: Icons.add_rounded, tooltip: l10n.medAddTooltip, onPressed: () => context.push('/medication/add'))`。

### P0-12 [lib/presentation/pages/medication/medication_page.dart:101] hardcode `Colors.white`
```dart
foregroundColor: Colors.white,
```
FloatingActionButton 跟 systemRed 主题色（0xFFFF3B30）背景配，foreground 应该是 `AppColors.fgOnPrimary(context)` 走 M3 theme-aware；当前 `Colors.white` 在 light/dark 都白，**dark mode 不影响**（因为 FAB 本身是红底白字），但**违背"颜色集中"原则**。emil: 所有 color 应走 `AppColors.xxxColor(context)` 集中器。
**修复**: `foregroundColor: AppColors.fgOnPrimary(context)`（已经在 app_colors.dart:292）。

### P0-13 [lib/presentation/pages/medication/widgets/medication_pill_icon.dart:9-16,63,70] 6 pill 颜色硬编码 + 2 处 Colors.white
```dart
const List<Color> kMedPillColors = [
  Color(0xFF34C759), Color(0xFFFFCC00), Color(0xFFFF3B30),
  Color(0xFF007AFF), Color(0xFFAF52DE), Color(0xFF8E8E93),
];
...
color: Colors.white,   // line 63
color: Colors.white,   // line 70
```
**问题**：
1. `kMedPillColors` 是 widget 私有 palette，不在 `app_colors.dart` 集中器，跨 widget 复用难度大。
2. 跟 `AppColors.healthMetricsColors`（8 metric 同 hex 值）大量重复，2 个 source-of-truth 易错。
3. `Colors.white` 2 处应走 `AppColors.fgOnPrimary(context)`（跟 P0-12 同款）。

**修复**:
- 把 `kMedPillColors` 移到 `app_colors.dart` 作 `kMedicationPillColors`（6 元素，跟 `healthMetricsColors` 8 元素 1:1 重叠 4 个，注释解释"为啥独立"）。
- `Colors.white` 改 `AppColors.fgOnPrimary(context)`。

### P0-14 [lib/presentation/pages/mood_list/mood_trend_page.dart:311-317, 539-540] 7 处硬编码 iOS color（5 元素 + 2 ternary）
```dart
const colors = [
  Color(0xFFFF3B30), Color(0xFFFF9500), Color(0xFFFFCC00),
  Color(0xFF34C759), Color(0xFF007AFF),
];
...
final color = spot.y >= 0
    ? const Color(0xFF34C759)
    : const Color(0xFFFF3B30);
```
5 元素 5 个 hex = 5 mood score 1-5 颜色（红/橙/黄/绿/蓝），跟 `app_colors.dart:330-385` assessment palette / `app_colors.dart:422-431` healthMetricsColors **不重合**（mood score palette 是 5 元素，assessment 是 12，metric 是 8）。
emil "single source of truth" — 3 个 palette 散落，后续调色需 grep 3 处。
**修复**: 把 5 元素 mood palette 加到 `app_colors.dart` 作 `moodScoreColors` (5 元素) + `moodScoreColorFor(score)`（类似 `healthMetricsColorFor(metricId)`），跟 `mood_visual.dart:84 colorArgbFor` 复用同一 source。

### P0-15 [lib/presentation/pages/home/widgets/hero_illustration.dart:33-119] 死代码（118 行）
```bash
$ grep -rn "HomeHeroIllustration\|HeroIllustration" lib/presentation/pages/home/
lib/presentation/pages/home/home_page_state.dart:308:  // 移除 HeroIllustration (Apple Health 风格无大图, 用 section 列表代替).
```
R9a 已经移除 HeroIllustration widget 调用，但**没删 widget 文件本身**。118 行死代码（含 `Color.withValues(alpha: 0.04,0.5,0.6,0.7)` 4 处 + `BoxShadow` 1 处硬编码）。
**修复**: `mavis-trash lib/presentation/pages/home/widgets/hero_illustration.dart`。

### P0-16 [lib/presentation/pages/home/widgets/quick_mood_carousel.dart:180-186] `Colors.transparent` 硬编码
```dart
? color.withValues(
    alpha: Theme.of(context).brightness == Brightness.dark ? 0.18 : 0.12,
  )
: Colors.transparent,
```
`Colors.transparent` 在 `notification_status_card.dart:280` / `dimension_row.dart:65,76` / `mood_audio_recorder_widget.dart:384` 也有。`AppColors` 没有 `transparent` 集中器（`AppTokens.surfaceColor(context)` 返 0xFFFFFFFF 不可用）。
emil: 即使是 transparent，也应有命名常量 — `AppColors.transparent` 集中器。
**修复**: 在 `app_colors.dart` 加 `static const Color transparent = Color(0x00000000)`；4 处 `Colors.transparent` 替换为 `AppColors.transparent`。

---

## 3. 半成品 P0

### P0-17 [lib/presentation/widgets/page_scaffold.dart] scaffold `translucent AppBar` 缺（spec §4.9 R31 P0-09）
R31 P0-09 要求 `PageScaffold translucent AppBar (spec §4.9)`，当前 `appBar: AppBar(title: Text(title!), ...)` 用 M3 默认 opaque（surface 背景 + elevation）。Apple Health 风格 AppBar 是**透明 + scroll under content + 0 elevation**。
当前 30+ 调用点全走 M3 opaque，跟 Apple Health 不一致。视觉上 home 页面（page 1）用户感觉"标题栏占空间"，spec §4.9 要求"标题浮动在内容上方"。
**修复**: `AppBar(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, ...)`。可用 `AppColors.transparent` 集中器（P0-16）+ 加 `AppTokens.appBarElevation = 0.0` token。

### P0-18 [lib/presentation/widgets/check_in_button.dart:28-141] _EntrySpring 仍是 `curveSpring` 模拟（spec §3.4.3 物理模型半成品）
R31 报告 P0-08 "Spring 接 _EntrySpring" 状态 0 进展。当前 `_EntrySpring`（行 82）走 `Motion.curve(context, AppTokens.curveSpring)`（cubic-bezier 0.23, 1, 0.32, 1），不是真实物理 spring。
跟 P0-08 同款二选一：删 spring.dart 或接 `_EntrySpring`。
**修复**: 推荐 (A) 删 spring.dart（P0-08），保持现状（curve 模拟），更新 spec.md §3.4.3 注明"实际用 curveSpring cubic-bezier 模拟"。

### P0-19 [lib/presentation/pages/medication/medication_page.dart:135, 138-163] "Phase 5" TODO 注释过期
```dart
// 今日待服 (medication 红, "待服" 计数)
// TODO(Phase 5): 用 ARB key 替换 hardcode
AppleHealthTile(metricId: 'medication', label: '待服', ...),
```
4 个 tile 共 4 个 TODO(Phase 5) 注释 + 4 个 hardcode。Phase 5 已经 R31 完成，本批 R32 仍残留。
**修复**: 跟 P0-01 一起 — 4 个 hardcode 改 l10n + 删 4 个 TODO 注释。

### P0-20 [lib/presentation/pages/home/widgets/secondary_action_row.dart:60,67,75] "Phase 5" TODO 注释过期 × 3
```dart
// TODO(Phase 5): 走 ARB
subtitle: '查看过往记录',
// TODO(Phase 5): 走 ARB
title: '树洞',
// TODO(Phase 5): 走 ARB
title: '设置',
```
**修复**: 跟 P0-02 一起 — 7 处 hardcode 改 l10n + 删 3 个 TODO 注释。

---

## 4. P1 (16 条)

### 上架/合规
- **P1-01** [lib/presentation/pages/medication/medication_page.dart:135,138,145,152,161] 5 处 `Phase 5` TODO 注释未清 → 跟 P0-19 合并修
- **P1-02** [lib/presentation/pages/medication/add_medication_page.dart:229,308,451,498] 4 处 "走 ARB" TODO 注释 + hardcode ("基本信息"/"用药时间"/"颜色"/"确认信息") → R9a 同样注释未清
- **P1-03** [lib/presentation/pages/medication/medication_detail_page.dart:73,132,187] 3 处 hardcode ("基本信息"/"用药历史"/"设置") + TODO 注释
- **P1-04** [lib/presentation/pages/medication/medication_calendar_page.dart:95,151,204] 3 处 hardcode ("时间窗口"/"依从性日历"/"图例") + TODO
- **P1-05** [lib/presentation/pages/medication/refill_manage_page.dart:146,210] 2 处 hardcode ("续方汇总"/"药物列表") + TODO

### 架构/重构
- **P1-06** [lib/presentation/pages/mood_list/mood_detail_page.dart:28] raw `IconButton` (5 处 raw IconButton 总集合) → 用 PressFeedbackIconButton 集中器
- **P1-07** [lib/presentation/pages/crisis_hotline_page.dart:185,192] 2 处 raw `IconButton` (crisis 页面 2 个箭头按钮) → 用 PressFeedbackIconButton
- **P1-08** [lib/presentation/pages/medication/add_medication_page.dart:135] 1 处 raw `IconButton` (返回按钮) → 用 PressFeedbackIconButton
- **P1-09** [lib/presentation/pages/daily_tracking/tracking_customize_page.dart:144] 1 处 raw `IconButton` (添加按钮)
- **P1-10** [lib/presentation/pages/daily_tracking/daily_tracking_page.dart:77] 1 处 raw `IconButton` (FAB 入口)
- **P1-11** [lib/presentation/pages/settings/reminders_hub_page.dart:289,306,418,442; legal_page.dart:299; export_dialog.dart:135; report_history_dialog.dart:41; notification_status_card.dart:394; reminder_cards.dart:186,210; profile_group.dart:82,115,235] **18+ 处 raw `FontWeight.w500/w600/w700`** 绕过 `AppTypography.textStyleLabelStrong / textStyleHeadline` 集中器。emil "token-first" — 整个 settings 页 0 处用 textStyle helper
- **P1-12** [lib/presentation/pages/trend/widgets/trend_day_detail_card.dart:74,96,114,249; trend_event_row.dart:41,56; trend_mood_chart.dart:222; trend_assessment_chart.dart:44,83] 9 处 raw `FontWeight.w500/w600` 绕过 token
- **P1-13** [lib/presentation/pages/trend/trend_calendar.dart:141,260] 2 处 raw `FontWeight.w500/w700` 绕过 token
- **P1-14** [lib/presentation/pages/mood_list/mood_detail_page.dart:60,95,121; mood_trend_page.dart:327,455,494,514] 7 处 raw `FontWeight.w500/w600/w700` 绕过 token
- **P1-15** [lib/presentation/pages/home/widgets/secondary_action_row.dart:121; encouragement_text.dart:28; home_fab_toolbar.dart:250] 3 处 raw `FontWeight.w500` 绕过 token

### Bug
- **P1-16** [lib/presentation/pages/home/widgets/quick_mood_carousel.dart:60-71] 注释与代码不一致（注释说"haptic 跟 checkIn 风格一致"但实际无 Haptics.success 调用）— 跟 P0-05 互补，p0 是缺调用，p1 是注释/代码错位

---

## 5. P2 + P3 摘要（前 10 条）

- **P2-01** [lib/presentation/pages/medication/medication_page.dart:344,394, 396] `kMedPillColors` 散落 + `AppTokens.disabledColor` 走 token 但 value 字符串 `'$medDone/$medTotal'` 可加 helper
- **P2-02** [lib/presentation/pages/home/widgets/home_header.dart:108-110] 日期硬格式 `'${d.year}年${d.month}月${d.day}日'` — 走 `intl.DateFormat.yMMMMd('zh')` 集中器
- **P2-03** [lib/presentation/pages/mood_list/mood_trend_page.dart:382] 5 个 emoji 硬编码 `['😢','😟','😐','🙂','😄']` — 应放 `AppColors.moodEmojisFor(score)` 集中器
- **P2-04** [lib/presentation/pages/home/widgets/hero_illustration.dart] 死代码（118 行）— 跟 P0-15 合并删
- **P2-05** [lib/presentation/pages/medication/widgets/medication_pill_icon.dart:50-55] `boxShadow: [BoxShadow(color: baseColor.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]` — 走 `AppMotion.shadowCardOf(context)` 集中器（但 spec §3.4.4 是 0 阴影，pill 阴影属半装饰，需另开 token）
- **P2-06** [lib/presentation/pages/home/widgets/hero_illustration.dart:53-57] `BoxShadow(color: shadow.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))` 硬编码 → 走 `AppMotion.shadowOverlayOf(context)` — 但已在 P0-15 删文件，撤销
- **P2-07** [lib/presentation/pages/home/widgets/quick_mood_carousel.dart:180-186] ternary alpha 0.18/0.12 跟 `AppleHealthTile:76` 同款（dark 0.18 / light 0.12）— 应抽 `AppMotion.bgAlphaForBrightness(context)` 集中器
- **P2-08** [lib/presentation/pages/daily_tracking/widgets/tracking_item_card.dart:47,80,114,131; tracking_customize_page.dart:104,113,114] 6 处 `theme.dividerColor.withValues(alpha: 0.3)` / `config.color.withValues(alpha: 0.12)` 硬编码 — 走 `AppColors.tintedStatusSoft / tintedMetricSoft` 集中器
- **P2-09** [lib/presentation/pages/assessment/widgets/assessment_unavailable_card.dart:27] `scheme.error.withValues(alpha: 0.5)` 硬编码 — 走 `AppColors.tintedErrorDeep(context)` 集中器
- **P2-10** [lib/presentation/pages/mood_list/mood_detail_page.dart:107] `color.withValues(alpha: 0.1)` 硬编码 — 走 `AppColors.tintedPrimarySoft(context)` 集中器

---

## 6. 总结

### 本轮新发现 vs R31 变化

**R31 → R32 增量**:
- ➕ 主页 5 widget (primary_action_row / secondary_action_row / quick_mood_carousel / today_summary_card / home_header) + medication_page 4 个 tile + mood_trend_page 5/2 处 = **12+ 处硬编码中文**（R31 已说"持平抵消 4 处新引入"，本轮**累计翻 3 倍**）
- ➕ 8 处 raw `IconButton`（R31 报告 7 处 — 本轮发现 1 处漏统计：`page_scaffold.dart:42`）
- ➕ 18+ 处 raw `FontWeight.w500/w600/w700`（R31 P1 emil token 化已部分做，settings / trend / mood_list 仍未动）
- ➕ QuickMoodCarousel 缺 Haptics.success 调用（R31 报 4 处 Haptics 集中器全覆盖，**本轮发现 1 处漏调用**）
- ➕ 145 行 `Spring` 死代码 0 caller（R31 P0 半成品 "Spring 接 _EntrySpring" 0 进展）
- ➕ `hero_illustration.dart` 118 行死代码（R9a 移除调用没删文件）

**R31 → R32 减分**（emil 主线）:
- **0 减分**: Apple Health 5 token + 6 widget + 5 page 重设，**R31 设计的视觉产物已稳定**，本轮**没新视觉减分**
- **-0.5 字体集中**: 18+ raw FontWeight 漏接 token（settings/trend/mood_list 3 个 page）
- **-0.5 M3 规范**: 8 raw IconButton + 145 行死代码 = 工程规范降级
- **+0.5 颜色集中**: mood_trend_page 7 处硬编码 iOS color 仍存在但已识别（add 集中器即可）
- **+0.5 动效 / 节奏 / Apple Health**: R31 设计完整，无新发现

### 修复优先级排序

**优先级 1（必须 0 错误 0 warning 守住，可 1 天闭环）**:
1. P0-08 删 `spring.dart` 145 行（emil "decisions should be nameable"）
2. P0-15 删 `hero_illustration.dart` 118 行
3. P0-12/P0-13 修 `Colors.white` 4 处 → `AppColors.fgOnPrimary(context)`
4. P0-16 加 `AppColors.transparent` 集中器 + 4 处替换
5. P0-10 ~ P0-12 等 8 处 raw IconButton → `PressFeedbackIconButton`
6. P0-05 QuickMoodCarousel 补 Haptics.success

**优先级 2（1 周内闭环，en 用户能正常用）**:
1. P0-01 ~ P0-07 主页/medication 12+ 处 hardcode 中文 → l10n 化（zh + en + zh_Hant ARB 加 30+ key）
2. P0-04 QuickMoodCarousel SnackBar 改 `AppSnackBar.showError`
3. P0-19/P0-20 清 "Phase 5" TODO 注释 7 个
4. P0-14 mood_trend_page 5/2 处硬编码 iOS color → `AppColors.moodScoreColorFor`
5. P0-13 kMedPillColors 移到 `app_colors.dart`

**优先级 3（2 周内闭环，工程规范升级）**:
1. P1-11 ~ P1-15 18+ 处 raw `FontWeight.w500/w600/w700` 走 `AppTypography.textStyleLabelStrong / Headline`
2. P0-17 PageScaffold translucent AppBar
3. P0-09 给 token/widget 集中器加 Apple Health spec 引用
4. P2-07/08/09/10 8 处 `withValues(alpha:)` 硬编码走 tinted* 集中器

**优先级 4（1 月内闭环，iOS 风格深度还原）**:
1. P2-02 `home_header.dart` 日期格式走 intl.DateFormat
2. P2-03 mood emoji 5 个集中器
3. P2-05 medication_pill_icon shadow 集中器

### "如果只能改 3 件事" 建议

**只改 3 件**（emil 价值密度最高）:
1. **【清理死代码】删 `spring.dart` 145 行 + `hero_illustration.dart` 118 行 = 263 行 0 caller 代码**（emil "good defaults matter more than options" + 减少 grep 噪声 + 降低后续开发者误读"项目用物理 spring"风险）
2. **【l10n 化】主页 5 widget + medication_page 4 tile 12 处 hardcode 中文**（zh + en + zh_Hant ARB 加 30+ key；1 个集中器 + 1 个 grep 替换搞定；en 用户可正常用）
3. **【补反馈 + 集中器】QuickMoodCarousel 补 Haptics.success + 8 处 raw IconButton → PressFeedbackIconButton 集中器**（emil "feedback" 原则 + 集中器策略一致性，精神心理患者感官反馈需求高于普通用户）

**ROI 排序**:
- 清理死代码 = 5 分钟 + 263 行 0 风险删除
- l10n 化 = 4-6h（30+ ARB key 加 + 12 处 replace + widget test 更新）
- 集中器 + 反馈 = 2-3h（8 处 IconButton 替换 + 1 行 Haptics + 1 行 import）

总投入 ≤ 1 天，加权综合可从 8.2 升到 **8.8-9.0/10**。
