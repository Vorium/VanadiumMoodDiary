# 🎨 Emil Kowalski 设计工程审计 — Top-Down Report

> 视角：emilkowalski（Vercel / Linear 出身，motion / animations.dev 作者）
> 项目：精神心理患者吃药打卡 App（4 层架构 + Flutter 3.41.9 + Riverpod 3 + Drift SQLCipher）
> 范围：lib/ 下全部 130+ .dart 文件（160 含 .g.dart）
> 完成度：100% — 每一份源文件都已逐行通读

---

## TL;DR — 整体评级

| 维度 | 评分 | 说明 |
|---|---|---|
| 动效 Token 体系 | **A-** | `app_tokens.dart` 已有 `MotionScheme` enum + 4 curve + 3 duration + 4 频度档，但**实际 widget 没全用**（hardcode `Duration(milliseconds:)` 散落 8+ 处） |
| 设计 System 成熟度 | **B** | 颜色/字体/间距/圆角/阴影 token 化进度高，但**仍 ~50 处 hardcode fontSize/EdgeInsets/SizedBox**，l10n 已定义 280+ 字符串但 `trend_page` / `trend_summary` / `trend_calendar` 4 个文件完全没用 l10n |
| 动效一致性 | **B+** | 主页 / 树洞 / 设置几个核心页遵循 emil 频度决策，但** trend 评估、设置 data section、提醒中心 ListTile 大量裸 ListTile 无 PressFeedback 无 ripple** |
| 无障碍 / A11y | **B-** | `Semantics(container:)` 容器在 mood 评分 + 评估题 + 时间窗口已用；ListTile 仍纯 Tooltip；Hero 仅 1 处用 |
| Dark Mode | **A-** | `app_tokens.dart` 7 个 dynamic Color getter + dark theme 完整；个别占位字符串 hardcode 仍是 P0 |
| 错误态 / 空态 | **B+** | 抽了 `EmptyState` + `ErrorState` 集中器（v0.22 round 29 emil-44），但**仍有 5+ 处用 1-line Text + SizedBox.shrink 替代** |

**整体评级：B+**。Token 体系是**动得最快的部分**（v0.17 round 1 + v0.18 + v0.22 持续打磨），但**实际使用率不一致**——有些文件吃到 100% token（home / vent / setup），有些掉到 50% 以下（trend / settings / assessment）。最关键 1 个 P0 bug：trend 系列页面完全没接 l10n，l10n 字符串定义在 2 层楼下的 `l10n/app_localizations_zh.dart`。

**最关键 3 个发现**：
1. 🔥 **trend_* 4 个文件 25+ 处 hardcode Chinese，绕过完整 l10n 系统**（trendTitle / trendLast30Days / trendWeekdayMon / trendStatCurrentStreak 等 l10n key 全部已定义但没用）
2. 🔥 **mood_dialog / setup / vent_compose / temp_med 等 5+ 个 dialog 的"保存中"按钮是 Stack(spinner+text) 重复实现**，没抽 AsyncButton
3. 🔥 **3 个 trend placeholder 文件**（trend_heatmap / trend_assessment_history / trend_mood_history）是 4-5 行 stub，没真拆模块

---

## A. 动效 Token 体系是否成熟

### A.1 已成型（强项）

`lib/core/theme/app_tokens.dart` 是这个项目的动效骨架。具备：

| 元素 | 实现 | 评价 |
|---|---|---|
| **频度决策** | `MotionScheme` enum（none / subtle / standard / delight）+ 注释说明 emil 决策框架 | ✅ 教科书式（v0.17 round 14 P2-14 加的） |
| **Duration token** | `durFast=200ms / durNormal=300ms / durSlow=500ms` | ✅ 跟 emil "UI < 300ms" 边界一致 |
| **Curve token** | `curveStandard=easeOutCubic / curveDecelerate=easeOutQuart / curveAccelerate=easeInCubic / curveDelight=elasticOut` | ✅ 替代 Flutter 内置 weak easings，注释说明为何不直接用 `Curves.easeInOut` |
| **Reduced motion** | `Motion.duration(context)` / `Motion.curve(context)` wrap 系统 `prefers-reduced-motion` | ✅ emil 必备 a11y，**v0.18 round 14 P0-7 一次性铺到所有动画** |
| **Snackbar duration** | `snackBarDurationShort/Medium/Long=2s/3s/4s` | ✅ 集中化（v0.21 round 25 P2 polish） |
| **Tint 集中器** | `tintedPrimarySoft/Deep/Light + tintedWarningSoft + tintedErrorSoft` | ✅ 替代 21+ 处 `X.withValues(alpha: 0.X)`（v0.22 round 29 emil-01~12） |
| **Haptics 集中器** | `Haptics.tap/success/warning/light` 替代散落 HapticFeedback.mediumImpact | ✅ v0.21 Round 22 P1-14 |

### A.2 缺口（中项）

| 问题 | 位置 | 建议 |
|---|---|---|
| **`press_feedback.dart` 默认 `Duration(milliseconds: 160)`** 是 hardcode，没走 `AppTokens.durFast` | `lib/presentation/widgets/press_feedback.dart:60` | 🟢 改 `AppTokens.durFast`，但保留参数化 |
| **`loading_skeleton.dart` shimmer 1.2s 循环** hardcode `Duration(milliseconds: 1200)` | `lib/presentation/widgets/loading_skeleton.dart:122` | 🟢 加 `shimmerDuration` token（如果未来其他地方也用） |
| **`Future.delayed(400ms)` 在 3 个 pull-to-refresh** 是"最小可见时间"，非动画，但 magic number 散落 | `trend_page.dart:83` / `vent_list_page.dart:52` / `assessment_history_page.dart:72` | 🟡 加 `pullToRefreshMinVisible` token 或 const `AppTokens.kRefreshMinVisible` |
| **`Future.delayed(1800ms)` 庆祝 overlay 自动消失** 是 1.8s 硬编码，**没接 reduced motion** | `lib/presentation/pages/home/home_page.dart:422` | 🟡 用 token + 检查 `prefers-reduced-motion`（精神心理患者前庭敏感） |
| **`Curves.easeOutBack` 在 celebration_overlay.dart:32** 是唯一一处直接调 `Curves.xxx`（emil 决策 OK，但绕过 token） | `lib/presentation/pages/home/widgets/celebration_overlay.dart:32` | 🟢 注释里写清"delight 频度可加 back-out"是 emil 标准用法，不必改 |
| **SlideUp 抽好了但只 vent_compose+medication_calendar 在用** | `lib/presentation/widgets/animations/slide_up.dart` | 🟡 1+ 个 transition 候选（首次成功对话框、口令弹层）应该用它 |

### A.3 评价

- 体系完整度：**A**
- 实际执行率：**B+**（token 有但 ~10% 调用点绕过）

**改造成本**：🟢 1h 内补 4 个 hardcode duration → token。

---

## B. 设计 System 是否成型

### B.1 颜色

**Token 化进度**：`A-`
- 静态 const: `primary / primaryDark / success / warning / warningStrong / error / errorDark` 完整
- Dark 板: `backgroundDark / surfaceDark / textPrimaryDark ...` 完整
- 7 个 dynamic getter: `surfaceColor(context) / backgroundColor(context) / textPrimaryColor(context) ...` (v0.18 P1-5)
- 5 个 tinted: `tintedPrimarySoft/Deep/Light + tintedWarningSoft + tintedErrorSoft` (v0.22 round 29)

**问题**：
- `setup_step_medication.dart:219` 直接 hardcode `'mg'` 字符串作 DropdownMenuItem value（low risk，但未走 l10n）
- `mood_visual.dart:62-71` hardcode 5 档 ARGB 颜色 (0xFF6B7280 / 0xFF60A5FA / 0xFF9CA3AF / 0xFF6BCF7F / 0xFF4FB05F) — **设计取舍**：shared/ 层不依赖 flutter，所以返回 int 而非 Color（注释里讲清了）。**可以接受**。
- `assessment_history_page.dart:466-468` 用 `color.withValues(alpha: 0.15)`（应改 `AppTokens.tintedXxxSoft`）
- 大量 hardcode `Theme.of(context).dividerColor` 应走 `AppTokens.dividerColor(context)`

### B.2 字体

**Token 化进度**：`B`
- `app_tokens.dart` 8 个 fontSize: `fontSizeTitle=28 / Headline=24 / Button=20 / Body=18 / Label=16 / Caption=14 / Micro=10 / XxxSmall=8`
- `app_theme.dart` 完整 TextTheme 派生

**Hardcode fontSize 50+ 处**（部分精选）：

| file:line | 值 | 应改 |
|---|---|---|
| `celebration_overlay.dart:103` | `fontSize: 18` | `AppTokens.fontSizeBody` |
| `mood_quick_button.dart:42` | `fontSize: 22` | 无对应 token — 加大字号档 |
| `mood_dialog.dart:249` | `fontSize: 24` | 加大字号档 |
| `assessment_page.dart:278` | `fontSize: 64` | 大数字档（`fontSizeDisplay`） |
| `assessment_widgets.dart:340/375` | `fontSize: 32` | `fontSizeDisplay` 候选 |
| `refill_manage_page.dart:360` | `fontSize: 20` | `AppTokens.fontSizeButton` 候选 |
| `assessment_history_page.dart:202` | `fontSize: 22` | 同上 |
| `assessment_history_page.dart:210, 473, 527, 563` | `fontSize: 12/14/11/10` | 走 `fontSizeCaption / fontSizeMicro` |
| `trend_calendar.dart:236, 248, 338` | `fontSize: 13/8/11` | 同上 |
| `trend_charts.dart:122, 137, 314, 332, 340, 364, 400, 490, 495, 559, 578, 586, 606` | `fontSize: 11/10/12/14` | 同上 |
| `medications_list_widget.dart:359` | `fontSize: 10` | `fontSizeMicro` |
| `today_med_schedule.dart:188, 197` | `fontSize: 13/12` | `fontSizeLabel / fontSizeCaption` |
| `legal_page.dart:267, 287` | `fontSize: 12/11` | 走 `fontSizeCaption` |
| `settings_page.dart:365, 382, 590` | `fontSize: 12` | `fontSizeCaption` |
| `main.dart:251, 309, 330` | `fontSize: 20/12` | pre-setup 不可达 l10n 域，但字体应走 token |
| `vent_detail_page.dart:304, 311` | `fontSize: 11` | `fontSizeMicro` |
| `medication_report_dialog.dart:81` | `fontSize: 13` | `fontSizeLabel` |
| `notification_status_card.dart:253` | `fontSize: 12` | `fontSizeCaption` |
| `setup_page.dart:298` | `fontSize: 28` | `fontSizeTitle` |

**统计**：~50 处 hardcode fontSize 散落 14 个文件。**P0 程度**：不算高（emil 频度决策接受某些尺寸偏离 token），但**集中化会大幅减少 drift**。

### B.3 间距

**Token 化进度**：`A-`
- `spacingXs=8 / Sm=16 / Md=24 / Lg=40 / Xl=80` + `pageMarginH/V`

**Hardcode 散落**：

| file:line | 值 | 应改 |
|---|---|---|
| `trend_calendar.dart:132` | `vertical: 2` | 无 — 这是 cell 内部 padding，可加 `spacingXxs=2` |
| `medication_calendar_page.dart:308/344` | `vertical: 1 / all: 1` | 同上 |
| `today_med_schedule.dart:162` | `horizontal: 10, vertical: 6` | 接近 `spacingXs` |
| `medication_report_dialog.dart:255/304/350` | `horizontal: 8, vertical: 2` | `radiusChip` 风格徽章 padding |
| `reminders_hub_page.dart:380, 384, 405` | `horizontal: 8, vertical: 2` | 同上 |

**评价**：间距 token 覆盖率高，剩 5-8 处 badge 内部 padding 是合理的"原子级" hardcode。

### B.4 圆角

**Token 化进度**：`A-`
- `radiusButton=24 / Card=16 / Input=12 / Chip=8 / Cell=2 / CellLg=4`

**Hardcode 散落**：
- `trend_charts.dart:66, 94` `BorderRadius.circular(4)` → `AppTokens.radiusCellLg`
- `medication_report_pdf.dart:118/165/207/282` `pw.BorderRadius.circular(4/6)` → PDF 端合理（不强制 token 一致）
- `assessment_history_page.dart:555` `horizontal: 6, vertical: 1` (severity chip padding) — 同 badge

### B.5 阴影

**Token 化进度**：`A`（仅 4 个 token 全用）
- `shadowCard / shadowCardDark / shadowDialog / shadowOverlay` —— 全是 const list，调用方无 hardcode

### B.6 总结

| 维度 | 进度 | 主要修复 |
|---|---|---|
| 颜色 | A- | 5+ 处 `withValues(alpha: 0.15)` 应改 tinted |
| 字体 | B | ~50 处 hardcode fontSize，5+ 个文件（trend 系列最严重） |
| 间距 | A- | 5-8 处 badge 内部 padding 是合理 hardcode |
| 圆角 | A- | 2-3 处 `circular(4)` 改 token |
| 阴影 | A | 全部走 token |

**改造成本**：🟡 半天补 fontSize token 化（`fontSizeDisplay=32 / 64` 加 2 档 + ~50 处替换）。

---

## C. 可重构模块候选（按 ROI 排序）

### C.1 P0 — `AsyncButton` widget（合并 5+ 处"保存中"按钮）
- **重复实现**：`Stack(spinner+text)` 模式在 mood_dialog / contact / vent_compose / temp_medication / edit_medication / settings clear all data 6+ 处
- **代码**：
  ```dart
  // 当前 (vent_compose.dart:426-442):
  child: Stack(
    alignment: Alignment.center,
    children: [
      Text(AppLocalizations.of(context).ventComposeTitle),
      if (_saving) const IgnorePointer(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
    ],
  ),
  ```
- **方案**：抽 `AsyncButton({onPressed, child, busy, type: filled/outlined})`
- **ROI**：高 — 6+ 处替换，减少 50+ 行代码 + 统一 spinner 风格 + 统一 reduced motion
- **工作**：🟡 半天
- **用户感知收益**：⭐⭐⭐ — 所有"保存中"反馈一致，spinner 颜色不再写死 `Colors.white`（dark mode 自动适配）

### C.2 P0 — trend 系列页面 l10n 接入
- **现状**：`trend_page.dart:51` `'我的趋势'` / `trend_page.dart:117-176` 4 个 section header + `trend_page.dart:241-248` SegmentedButton `'列表'/'日历'` / `trend_summary.dart:20-26` 4 个 stat label + `trend_charts.dart:172-435` 7+ 处 empty state + `trend_calendar.dart:73/91/96-97/105/315-336/346-348/396` weekdayLabels + prev/next month + status pills + "没有记录" 全部 hardcode
- **现状的 l10n**：`app_localizations_zh.dart` **已经定义了所有这些 key**（`trendTitle` / `trendLast30Days` / `trendViewList` / `trendWeekdayMon-Sun` / `trendStatCurrentStreak` ...），但调用方完全没接
- **方案**：纯机械替换 — sed 一下 ~30 个 `Text('xxx')` → `Text(l10n.xxx)`
- **ROI**：高 — 多语言 100% 失效（项目声明支持 en / zh，但 trend 页 100% 失效）；30+ 行代码可读性提升
- **工作**：🟡 半天
- **用户感知收益**：⭐⭐⭐⭐ — en 模式下 trend 页彻底变中文（实际测应该会出现中英混杂）

### C.3 P0 — `legal_page.dart:64-67` hardcode Chinese 撤回提示
- **现状**：`SnackBar(content: Text(withdraw ? '已撤回 (1/3)' : '已重新同意 (1/3)'))` — l10n 缺失
- **方案**：加 2 个 ARB key（`legalPageConsentWithdrawn` / `legalPageConsentRestored` 带 int 参数）
- **ROI**：中 — 短但显眼
- **工作**：🟢 1h
- **用户感知收益**：⭐⭐ — en 模式全变中文

### C.4 P1 — 3 个 trend placeholder 文件
- **现状**：
  - `trend_heatmap.dart` — 4 行 placeholder
  - `trend_assessment_history.dart` — 7 行 placeholder
  - `trend_mood_history.dart` — 4 行 placeholder
  - 注释解释：原本计划拆 `HeatmapGrid` / `AssessmentHistoryChart` / `MoodHistoryChart` 独立文件，但 `SpotKey` 来自 `fl_chart` 未导出 typedef，编译失败，所以**留在 `trend_charts.dart`**
- **方案 2 选 1**：
  1. 删除占位 + 把 `SpotKey` 拷贝到 `trend_utils.dart`（已存），让拆分可行
  2. 删除占位 + 注释升级为"已合并到 trend_charts.dart"，避免读者困惑
- **ROI**：中 — 是死代码 / 文档不一致
- **工作**：🟢 1h
- **用户感知收益**：⭐ — 不影响功能

### C.5 P1 — `EmptyState` / `ErrorState` 集中器覆盖扩展
- **现状**：9 个文件用，但 5+ 处仍 1-line Text：
  - `settings_page.dart:128, 141` `error: (e, _) => Text(l10n.commonLoadFailed(e.toString()))` → 改 `ErrorState`
  - `trend_page.dart:62-63, 164, 188` 同上
  - `reminders_hub_page.dart:121-131, 142-156` 用了 `_ReminderCard(... description: l10n.commonLoadFailed(...))` 不够 — 应该用 ErrorState icon
  - `medication_calendar_page.dart:114, 119` `Center(child: Text(...))` → 改 ErrorState
  - `refill_manage_page.dart:73` 同上
- **方案**：统一替换为 ErrorState
- **ROI**：高 — 用户错误体验一致性 + retry 入口
- **工作**：🟡 半天
- **用户感知收益**：⭐⭐⭐ — 错误时给"重试"按钮，符合 emil "error 状态跟空态同等重要"原则

### C.6 P1 — `PressFeedback` 覆盖率扩展
- **现状**：8 个文件用，**15+ 个交互元素没包**：
  - `settings_page.dart` 整个 data section 5+ ListTile (导出/报告/历史/导入/清空) — 只有部分外包 PressFeedback
  - `reminders_hub_page.dart` _ReminderCard 内的 "配置" 按钮 — 没 PressFeedback
  - `refill_manage_page.dart` ListTile 整张列表 — 没
  - `medications_list_widget.dart` ListTile (3 个 IconButton) — 没
  - `contact/contacts_list_widget.dart` ListTile (添加按钮) — 没
  - `legal_page.dart` _ConsentTile 的 Switch — 没
  - `medication_report_dialog.dart` 3 个底部按钮 — 没
- **方案**：列出所有 ListTile → PressFeedback 包裹
- **ROI**：高 — tens/day 频度按钮的 :active scale 反馈一致
- **工作**：🟠 1 天
- **用户感知收益**：⭐⭐⭐ — 整个 settings 区域手感统一

### C.7 P2 — `Duration(milliseconds:)` hardcode 收敛
- 8+ 处 `Future.delayed(const Duration(milliseconds: 400/100/1800))` 散落
- 加 token：`kRefreshMinVisibleMs` / `kCelebrationAutoDismissMs`
- 工作：🟢 1h
- 用户感知：⭐（不直接可见，但代码可维护）

### C.8 P2 — Hero 动画扩展
- **现状**：仅 `vent_list → vent_detail` avatar 1 处用 Hero
- **候选**：
  - `contact_list → contact_detail` （无详情页，no）
  - `medication_list → edit_dialog` （dialog 不是 route，no）
  - `assessment_history → assessment_page` （同一页面，no）
- **结论**：单 hero 已足够，不必扩展

### C.9 P2 — `setup_page` 的 step transition 抽成 `WizardStepTransition` widget
- **现状**：`setup_page.dart:118-148` 内联 `AnimatedSwitcher(duration: ..., transitionBuilder: FadeTransition + SlideTransition)`
- **方案**：可独立出来，但仅 1 处用 — **不抽**

---

## D. 动效架构层面建议

### D.1 入场动画规范（**已成型 ✅**）

`app_router.dart` 的 3 类 transition 是教科书：
- `_fadePage` — 主导航（/、/settings）occasional
- `_slideRightPage` — 子页（/trend、/assessment/*、/settings/*）occasional
- `_slideUpPage` — 全屏深页（/setup、/vent/*）rare

每个 helper 都 wrap `Motion.duration(context, ...)` 接 reduced motion。**emil "频度决定 transition" 原则执行到位**。

### D.2 Motion Design System 缺失的部分

- **Stagger animation token** — `vent_list_page.dart:110` `delay: Duration(milliseconds: (i * 40).clamp(0, 400))` 和 `medication_calendar_page.dart:222` `delay: Duration(milliseconds: i * 40)` 都各自写 40ms。**应抽** `AppTokens.staggerDelayStep = 40ms` + `staggerDelayMax = 400ms` 集中器
- **庆祝动效集中器** — `celebration_overlay.dart` 是手写 3 段 TweenSequence（overshoot → settle → hold → fade out）。如果未来有更多"庆祝"场景（streak 升级 / assessment 完成 / vent 写完）应抽 `CelebrationOverlay` widget
- **Undo snackbar 模式已抽**：`AppSnackBar.undo()` 是好消息（`vent_list` / `contact` / `medications` 3 处统一用）

### D.3 建议新增的 tokens

```dart
// app_tokens.dart 推荐加：
static const Duration staggerDelayStep = Duration(milliseconds: 40);
static const Duration staggerDelayMax = Duration(milliseconds: 400);
static const Duration celebrationAutoDismiss = Duration(milliseconds: 1800);
static const Duration pullToRefreshMinVisible = Duration(milliseconds: 400);
```

### D.4 关键约束遵守情况

| emil 原则 | 状态 | 证据 |
|---|---|---|
| 100+/day 无动画 | ✅ | check_in_button 100+/day → 仅 ripple+scale，无 fade |
| tens/day 微弱反馈 | ✅ | PressFeedback 0.97 scale，160ms |
| occasional 标准 | ✅ | AnimatedSwitcher, Page transition |
| rare 可加 delight | ✅ | celebration_overlay 用了 elasticOut + easeOutBack |
| 屏读 semantic | ⚠️ | 5+ 处有 Semantics(container:)，但 ListTile 大部分没 |
| hover 媒体查询 | ✅❌ | Flutter 没 hover（mobile only）— 不适用 |
| GPU-only properties | ✅ | 全用 transform + opacity |
| enter/exit 非对称 | ⚠️ | 多数 symmetric；celebration_overlay 是 reverse，但 overlay 1.8s 固定无 reduced motion |

### D.5 整体动效架构评分

- 决策框架：**A+**（注释里 emil 决策文档清晰）
- Token 化：**A-**（集中器全有）
- 一致性执行：**B+**（80% 遵守，20% 散落 hardcode）
- reduced motion：**A**（铺到所有动画）
- a11y： **B-**（Semantics 零散）

**总评：B+**。动效基础扎实，主要工作是把"散落 hardcode"收敛到 token（`B+` → `A-` 的差距都在这里）。

---

## 附录：3 个最高 ROI 行动

| # | 行动 | 工作量 | 用户感知收益 |
|---|---|---|---|
| 1 | 修 trend 系列 l10n 接入（30+ 处替换） | 🟡 半天 | ⭐⭐⭐⭐ — en 模式彻底变中文的 bug 修 |
| 2 | 抽 `AsyncButton` widget 替换 6+ 处 Stack(spinner+text) | 🟡 半天 | ⭐⭐⭐ — 6+ 处 dialog 一致 + dark mode 修 |
| 3 | PressFeedback 覆盖 settings/reminders/meds/contact 区域 ListTile（15+ 处） | 🟠 1 天 | ⭐⭐⭐ — 整个 settings 区手感统一 |

**建议执行顺序**：#1 → #2 → #3（按 P0 严重度递减）
