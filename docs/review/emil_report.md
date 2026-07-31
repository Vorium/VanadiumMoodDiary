# Emil Kowalski 设计工程 (Design Engineering) 审视报告

> 项目：`D:\Batch\chroniccare`（慢病管家 · 精神心理患者吃药打卡 App）
> 栈：Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2 / Drift 2.20.3 / go_router 14.6
> 视角：emil 设计工程方法论（Vercel / Linear 出身）
> 审视范围：`lib/presentation/` 全量 + `lib/core/theme/` + `lib/core/shared/` + `lib/core/routing/` + 关键 main/app
> 实际扫读文件数：~80（21 widgets + 5 animations + 9 page/feature + 6 routing + 4 theme + 6 shared + main/app + 多个子目录）

---

## 总评

**这是一个设计系统已经过 6 轮 emil 视角审计（v0.17~v0.27）的项目**。Token 集中度、动效分级、组件复用、PressFeedback 一致性都做到业内一流水准。AGENTS.md 里大量 comment 直接引用 emil 原则（"good defaults matter more than options"、"decisions should be nameable"、"cohesion"），是真懂 emil 的人在做。

但**还有可优化空间**，主要集中在 3 个方向：
1. **Formatters 集中器被绕过** — 8+ 个 widget 自己写 `_formatTime` / `_formatDateTime` / `_pad`，跟 `core/shared/formatters.dart` 已有的 `Formatters.date / time / dateTime` 重复
2. **少量 magic number 残留** — `EdgeInsets.symmetric(vertical: 2)`、`size: 20`、`padding: EdgeInsets.all(4)`、`const Duration(seconds: 5)` 等十几处硬编码
3. **1 个结构性 bug** — `assessment_widgets.dart:222-244` 的 `Wrap` 写到 `Column` 外面去了（见报告 2 头部 P0）

---

# 报告 1：顶层架构审视（设计系统角度）

## 1.1 设计 Token 体系：★★★★★

**`lib/core/theme/app_tokens.dart`（752 行）是教科书级别的 token 集中器**：

| 类别 | 数量 | 评价 |
|---|---|---|
| 颜色（静态 const + dynamic getter） | ~50+ | light/dark 全部用 `ColorScheme.fromSeed` 派生；dynamic getter 接受 `BuildContext` 自动适配 |
| 字号 | 12 档 | Title/Headline/Body/Label/Caption + Micro/XxxSmall/ScoreLg/ScoreXl/ScoreXxl 满足多场景 |
| 间距 | 9 档 + 5 边缘 | Xxs/Xxxs/Xs/Sm/Md/Lg/Xl + pageMarginH/V + chipGap 系列 |
| 圆角 | 6 档 | Button/Card/Input/Chip + Cell/CellLg（热力图专用） |
| 阴影 | 4 个 dynamic getter | theme-aware，强制不能用 const 版本（防 dark mode 隐形） |
| 动画曲线 | 6 档 | Standard/Subtle/Decelerate/Accelerate/Delight/BackOut |
| 动画时长 | 3 档 + 4 细 | Fast/Normal/Slow + Press/Shimmer/PageTransition/Refresh |
| 响应式断点 | 3 档 | Compact/Medium/Expanded（Material 3 window size class） |
| 字号 line-height | 5 档 | Tight/Normal/Loose/Snug/Relaxed |
| Tinted surface | 9 个 | Primary/Success/Warning/Error 各 0.08/0.1/0.15/0.85 alpha |
| 文本样式 | 14 个 | Title/Headline/BodyStrong/LabelStrong/CaptionStrong/Micro/Legal/Mono 等 |

**关键决策（emil "decisions should be nameable"）**：
- 5 行 token 命名规则都在源码注释里写明
- `tintedXxxSoft` / `tintedXxxDeep` / `tintedXxxMid` / `tintedXxxHigh` 通过 alpha 数值命名（0.08/0.1/0.15/0.85）而不是单纯 `tintedXxx1/2/3`
- `fgDisabled` / `fgHintInput` / `fgOnSuccess` / `fgOnWarning` / `fgOnPrimaryMuted` 全部抽出来，避免 18+ 处 `Colors.white` / `withValues(alpha: 0.85)` 硬编码

**MotionScheme 4 档动画强度枚举**（none/subtle/standard/delight）是 emil 决策框架的标准实现，每个 widget 调用前都先想好"频度 100+/day 还是 rare"。

**`Motion.duration(context, base)` + `Motion.curve(context, base)` wrapper** 是 a11y 亮点 — 精神心理患者前庭功能敏感比例高于普通用户，prefers-reduced-motion 自动归零是真的 non-negotiable。

## 1.2 组件库分层：★★★★★（接近完美）

**`lib/presentation/widgets/` 是分层清晰的组件库**：

### 原子层（atoms）
- `PressFeedback`（scale 0.97 + 160ms curveStandard）+ `PressFeedbackIconButton`（icon + tooltip + PressFeedback 集成）
- `Haptics`（tap/success/warning/light 4 档触感集中器）
- `AppSemantics.container/button/exclude`（3 模式 a11y 集中器）
- `ChipBadge`（4 tone: neutral/success/warning/error）
- `LoadingSpinner` + `LoadingSkeleton.fullScreen/card`
- `EmptyState` + `ErrorState`
- `AppSnackBar`（error/info/undo/withAction + showX 工厂）
- `SectionHeader`（leading + action 复合模式）

### 分子层（molecules）
- `AppListTile.standard/carded/destructive`（ListTile + PressFeedback 集成）
- `CheckInButton`（主打卡按钮 + AnimatedSwitcher 切换 + 内部 streak tween）
- `SecondaryButton`（OutlinedButton + isLoading spinner）
- `LoadingTextButton`（3 variant: filled/text/tonal + 可选 icon）
- `AppListTile`（5 处 ListTile 重复的集中化）

### 动画层（animations/）
- `FadeIn`（delay + withScale 选项）
- `SlideUp`（distance 可调）
- `CelebrationBounce`（TweenSequence 5 段 + scale + opacity）
- `PageTransitionSwitcher`（default 100ms fade + 可换 transitionBuilder）

### 业务 widget 层
- `DimensionRow`（4 维度评分 1-5）
- `LastMedInfo`（最后吃药时间 + 下次提醒）
- `MoodQuickButton`（主页情绪快捷入口）

**复用率评估**：
- `AppListTile` 被 8+ page 使用（settings / refill / notification / medication / legal / contact / email preview）
- `PressFeedbackIconButton` 被 10+ 处使用（home header / medication row / setup / contact / vent list 等）
- `EmptyState` 被 5+ 处使用（vent / assessment / medication / contact / report history）
- `ErrorState` 被 7+ 处使用（trend / vent / assessment / medication / settings / email preview / contacts）
- `ChipBadge` 被 6+ 处使用（trend calendar / assessment history / refill / medication row / reminder hub / email preview）

**符合 emil "cohesion" 原则**：同一类 UI 全部走集中器，没有重复造轮子。

## 1.3 主题系统（light/dark/M3）：★★★★★

**`app_theme.dart` 的 `ColorScheme.fromSeed`**：
- seed = `AppTokens.primary` (0xFF6BCF7F 嫩绿)
- light/dark 走 M3 标准派生
- error 手动指定（isDark ? errorDark : error）防 dark mode 暗红看不清
- `useMaterial3: true` 完整 M3 组件库
- `splashFactory: InkSparkle.splashFactory` 替代老旧 InkRipple（v0.17 round 7 修订）
- AppBar 扁平（elevation=0 + scrolledUnderElevation=0）— 跟 M3 推荐一致
- NavigationRail extended 模式（宽屏 >= 840 显示侧栏）

**`theme_provider.dart` 持久化**：
- `FlutterSecureStorage` 复用（不引入 SharedPreferences 依赖）
- 单元测试用 `overrideWith(useStorage: false)` 避免 platform channel hang
- `set(mode)` + 异常走 `swallowError` 集中器

**App 切换淡入动画**：themeAnimationDuration=durNormal + curveStandard（v0.21 round 25 P3-1 修正过，原来是 curveDecelerate 偏慢）

## 1.4 路由（go_router page transition）：★★★★★

**`core/routing/` 拆 6 文件**（v0.26 R57 拆分 god class）：
- `app_router.dart` — 70 行 Provider 入口，`ref.read + cache` 性能优化（v0.26 R57 修正：之前 `ref.watch(userProfileProvider)` 每次 profile 变化重建整个 GoRouter 含 14 GoRoute）
- `app_routes.dart` — 3 transition helper + errorBuilder + facade
- `app_route_main.dart` — `/`, `/setup`, `/settings`, `/email-preview`
- `app_route_check_in.dart` — 2 个 redirect（deep link 自动打卡）
- `app_route_medication.dart` — 4 个 route
- `app_route_assessment.dart` — 3 个 route + 1 redirect
- `app_route_vent.dart` — 3 个 route

**3 类 transition（emil 频度决策）**：
- `fadePage` — 主导航偶尔切（/, /settings）→ durNormal
- `slideRightPage` — 子页 occasional（/trend, /assessment/*, /settings/reminders）→ durNormal + curveStandard
- `slideUpPage` — 全屏深页 rare（/setup, /vent/*）→ durSlow + slide 距离 0.05

**reverse duration 优化**：`transitionDuration` vs `reverseTransitionDuration` 区分（forward 走 durNormal，back 走 durFast — 退出要"果断"）

**Motion.duration wrapper** 在 transition helper 里接入，prefers-reduced-motion 自动归零

## 1.5 4 层架构（domain ← data → presentation）：★★★★★

`check_all.dart` 自动检查 + 16 个守护脚本，0 跨层 import。presentation 拆 8 feature 目录严格走 `lib/presentation/pages/{feature}/` 子目录，跨 feature 通过 `presentation/widgets/` 通用组件解耦。

## 1.6 整体协调性评估

**emil 维度评语**：

| 维度 | 评分 | 评语 |
|---|---|---|
| Token 集中度 | ★★★★★ | 752 行 token 文件是该领域教科书 |
| 动效决策框架 | ★★★★★ | MotionScheme enum + 4 档 + reduce-motion wrapper |
| 组件复用 | ★★★★★ | AppListTile / PressFeedback / EmptyState 等都被 5+ 处复用 |
| 主题一致性 | ★★★★★ | ColorScheme.fromSeed + dynamic getter 自动适配 |
| a11y | ★★★★☆ | AppSemantics 集中器 + prefers-reduced-motion 走全栈 |
| 半透明阴影 vs 边框 | ★★★★☆ | shadowCardOf 等 dynamic，但 Border.all(0.54 alpha) 还有 5+ 处硬编码 |
| 间距/圆角/字号一致性 | ★★★★☆ | 95% 走 token，但有 10+ 处 magic number 残留 |
| Tab 反馈一致性 | ★★★★★ | PressFeedback 覆盖率非常高 |
| Loading/Empty/Error 状态 | ★★★★★ | 3 集中器覆盖全 app |
| Haptics 一致性 | ★★★★★ | 4 档集中器 + PressFeedback 集成 |

---

# 报告 2：底层逐行排查

> 格式：`[文件:行号] 问题描述 - 建议 - 修复难度 - 优先级`
> 优先级：P0 = 必须修（bug） / P1 = 影响一致性 / P2 = 可优化 / P3 = nice-to-have
> 难度：简单（<30 min） / 中等（30 min ~ 2h） / 困难（>2h）

## 🔴 P0 - 必须修（结构 / 视觉 bug）

### [lib/presentation/pages/assessment/assessment_widgets.dart:222-244] **结构 bug**：`Wrap` 写到 `Column` 外面去了

实际代码结构：
```dart
child: Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    Text('Q$index. ${item.text}', ...),       // 题文
    const SizedBox(height: AppTokens.spacingSm),
  ],                                          // <-- children list 提前关闭
),                                            // <-- Column 关闭
Wrap(                                         // <-- Wrap 跟 Column 是 sibling 而非 child!
  spacing: AppTokens.spacingXs,
  runSpacing: AppTokens.spacingXs,
  children: [
    for (final entry in options.entries)
      ChoiceChip(...)
  ],
),
```

视觉后果：题文 Text + SizedBox 组成一个 Column（高度 ~30px），然后 Wrap 4 个 ChoiceChip 是 Padding 的另一个子元素，两个并排放在 Padding 里，**不是上下排列**。在 PHQ-9 答题页，每个题卡看起来"题文和选项并排"或"题文在左、选项被挤到看不见的位置"，违背设计意图。

应该是：
```dart
child: Column(
  children: [
    Text('Q$index. ${item.text}', ...),
    const SizedBox(height: AppTokens.spacingSm),
    Wrap(...),                                // Wrap 在 children list 里
  ],
),
```

- 修法：删 `],` + `),`，把 Wrap 移到 SizedBox 后面
- 难度：简单
- 优先级：P0

### [lib/presentation/pages/home/home_page.dart:407-413] Celebration overlay `Future.delayed` 不可 cancel

```dart
Future.delayed(
  const Duration(milliseconds: AppTokens.celebrationDisplayMs),
  () {
    if (entry.mounted) entry.remove();
  },
);
```

- 问题：`Future.delayed` 返回的 Future 没存字段，dispose 时无法 cancel。如果用户在 1.8s 庆祝动画期间 pop 出主页（比如点 20:00 提醒或系统返回手势），timer 仍然会 fire 调用 `entry.remove()` — 当前有 `if (entry.mounted)` 兜底，但 `_showCelebrationOverlay` 应该是 `_HomePageState` 的 method（实际是 void method），无 dispose hook
- 修法：存 `Timer? _celebrationTimer` 字段，dispose 时 cancel；改用 `Timer(Duration(...), ...)` 替代 `Future.delayed`
- 难度：简单
- 优先级：P0（a11y 风险：timer leak + 关闭页面后错误回调）

### [lib/presentation/pages/home/home_page.dart:416-423] `_nextReminderTime()` 硬编码 20:00 跟实际 notification schedule 不一致

```dart
DateTime? _nextReminderTime() {
  final now = DateTime.now();
  var next = DateTime(now.year, now.month, now.day, 20, 0);
  ...
}
```

- 问题：显示给用户"下次提醒 20:00"，但如果用户改过 `notificationService.scheduleDailyReminder(hour: ..., minute: ...)`（setup 时或后续 settings 改动），LastMedInfo 显示的下次提醒时间跟实际推的时间不一致
- 修法：从 `notificationService` 或 `userProfile.checkInReminderHour/Minute` 拿实际配置值
- 难度：中等（要查 notificationService 有没有暴露该字段；可能要加到 userProfile entity）
- 优先级：P0（用户信任度问题：显示 20:00 但实际 19:30 响了）

## 🟠 P1 - 影响一致性

### [lib/main.dart:285, 346] 硬编码 `Colors.orange` / `Colors.red`

```dart
const Icon(Icons.pause_circle_outline, size: AppTokens.iconSizeEmpty,
  color: Colors.orange,),                    // line 285
const Icon(Icons.error_outline, size: AppTokens.iconSizeEmpty, color: Colors.red,),  // line 346
```

- 问题：dark mode 下 raw `Colors.orange` / `Colors.red` 不变，跟 M3 colorScheme.error / warning 完全脱节。Migration aborted UI 跟 main 主题割裂
- 修法：改用 `Theme.of(context).colorScheme.error`（或 `AppTokens.warningColor(context)` / `errorColor(context)`）
- 难度：简单
- 优先级：P1

### [lib/main.dart:278, 287, 295, 347, 359, 379] `_MigrationFailedApp` / `_MigrationAbortedApp` 全部用 magic 16/24

```dart
padding: const EdgeInsets.all(24),    // line 278
const SizedBox(height: 16),            // line 287
padding: const EdgeInsets.all(12),     // line 295
const SizedBox(height: 16),            // line 347
const SizedBox(height: 16),            // line 359
padding: const EdgeInsets.all(16),     // line 379
```

- 问题：跟其他 page 不一致。`PageScaffold.pageMarginV = AppTokens.spacingMd = 24.0`（OK match），但 `spacingSm = 16` 才是 token
- 修法：全替换为 `AppTokens.spacingMd` / `AppTokens.spacingSm` 等 token
- 难度：简单
- 优先级：P1

### [lib/presentation/widgets/last_med_info.dart:70-78] 自写 `_formatDateTime` / `_formatTime` / `_pad`，绕过 `Formatters`

```dart
String _formatDateTime(DateTime dt) {
  return '${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}';
}
String _formatTime(DateTime dt) {
  return '${_pad(dt.hour)}:${_pad(dt.minute)}';
}
String _pad(int n) => n.toString().padLeft(2, '0');
```

- 问题：`Formatters.dateTime(dt)` 和 `Formatters.time(dt)` 在 `lib/core/shared/formatters.dart` 已存在，行为完全一致。手动实现绕过集中器
- 修法：删 3 个 method，改用 `Formatters.dateTime(lastCheckIn!)` / `Formatters.time(nextReminder!)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/medication/today_med_schedule.dart:211] `_pad` 重复

```dart
String _pad(int n) => n.toString().padLeft(2, '0');
```

- 修法：用 `Formatters.time`（已经在 medication_row.dart 里用过）
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:401-405] `_formatTime` 重复

```dart
static String _formatTime(TimeOfDay t) {
  final h = t.hour.toString().padLeft(2, '0');
  final m = t.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
```

- 修法：用 `Formatters.time(DateTime(0, 0, 0, t.hour, t.minute))` 或在 Formatters 加 `timeOfDay` overload
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/setup/setup_step_medication.dart:304-308] `_formatTime` 重复

跟 edit_medication_dialog.dart 同款
- 修法：同上
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/vent/widgets/vent_audio_section.dart:111-115] `_formatSec` 重复 Formatters 逻辑

```dart
String _formatSec(BuildContext context, int sec) {
  final m = (sec ~/ 60).toString().padLeft(2, '0');
  final s = (sec % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
```

- 修法：扩展 `Formatters` 加 `durationSec(int sec)`，或用 `Formatters.time` 重组
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/vent/vent_list_page.dart:308-320] `_formatTime` 重复 + 用 padLeft 4 次

```dart
String _formatTime(BuildContext context, DateTime dt) {
  final now = DateTime.now();
  ...
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
```

- 修法：用 `Formatters.dateTime(dt)` + 前面加 today/yesterday 前缀
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/vent/vent_detail_page.dart:170-173, 353-357] `_formatTime` + `_formatDur` 重复

```dart
String _formatTime(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
}
String _formatDur(Duration d) {
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
```

- 修法：用 `Formatters.dateTime` 和 `Formatters.time`（扩展加 `duration` overload）
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/trend/trend_calendar.dart:299-300, 501-503, 411] 3 处手动 date/time 拼接

```dart
// line 299
'${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'
// line 502
'${e.time.hour.toString().padLeft(2, '0')}:${e.time.minute.toString().padLeft(2, '0')}'
// line 411
const SizedBox(width: 20, ...)              // 同时硬编码 20
```

- 修法：删手动拼接，走 `Formatters.date` / `Formatters.time`；size: 20 → `AppTokens.iconSizeSmall(14)` 之外的统一 token
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/assessment/assessment_widgets.dart:413-415] `_dateLabel` 重复

```dart
static String _dateLabel(DateTime t) {
  return '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')}';
}
```

- 修法：`Formatters.date(t)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/assessment/widgets/assessment_history_list.dart:175-178] `_formatDateTime` 重复

- 修法：`Formatters.dateTime(record.timestamp)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/medication/refill_manage_page.dart:298-299] 手动日期拼接

```dart
'${m.refillAt!.year}-${m.refillAt!.month.toString().padLeft(2, '0')}-${m.refillAt!.day.toString().padLeft(2, '0')}'
```

- 修法：`Formatters.date(m.refillAt!)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/medication/widgets/medication_row.dart:228] 手动时间拼接

```dart
'${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}'
```

- 修法：`Formatters.time(DateTime(0, 0, 0, t.hour, t.minute))` 或在 `Formatters` 加 `timeOfDay(HourMinute)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/settings/legal_page.dart:240-245] 手动 datetime 拼接（5 次 padLeft）

```dart
'${withdrawnAt!.year.toString().padLeft(4, '0')}-'
'${withdrawnAt!.month.toString().padLeft(2, '0')}-'
'${withdrawnAt!.day.toString().padLeft(2, '0')} '
'${withdrawnAt!.hour.toString().padLeft(2, '0')}:'
'${withdrawnAt!.minute.toString().padLeft(2, '0')}',
```

- 修法：`Formatters.dateTime(withdrawnAt!)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/mood/widgets/mood_recorder.dart:394-400] `_formatDuration(ms)` 重复

```dart
String _formatDuration(int? ms) {
  if (ms == null) return '0:00';
  final seconds = (ms / 1000).floor();
  final m = (seconds ~/ 60).toString();
  final s = (seconds % 60).toString().padLeft(2, '0');
  return '$m:$s';
}
```

- 修法：扩展 `Formatters` 加 `durationMs(int? ms)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/medication/widgets/medication_row.dart:210-219] `_daysUntilRefill` 跟 `refill_manage_page.dart:212-219` 复制

```dart
// 两处都是这样
static int _daysUntilRefill(MedicationEntity med, DateTime now) {
  if (med.refillAt == null) return 0;
  final today = DateTime(now.year, now.month, now.day);
  final refillDay = DateTime(med.refillAt!.year, med.refillAt!.month, med.refillAt!.day);
  return refillDay.difference(today).inDays;
}
```

- 修法：抽到 `domain/logic/medication_stat_calculator.dart` 或 `medication_entity.dart` 作为 entity method
- 难度：简单
- 优先级：P1（DRY 违反）

### [lib/presentation/pages/contact/contacts_list_widget.dart:222-234] 手动 `Stack([Text, LoadingSpinner])` 重复 `LoadingTextButton` 逻辑

```dart
child: Stack(
  alignment: Alignment.center,
  children: [
    Text(AppLocalizations.of(context).commonSave),
    if (saving)
      IgnorePointer(
        child: LoadingSpinner(
          size: AppTokens.iconSizeInline,
          color: AppTokens.fgOnPrimary(context),
        ),
      ),
  ],
),
```

- 修法：直接用 `LoadingTextButton(label: ..., isLoading: saving, onPressed: ...)`
- 难度：简单
- 优先级：P1

### [lib/presentation/pages/settings/email_preview.dart:60] 硬编码 fallback '您的家人'，绕过 `safeUserName` + l10n

```dart
final safeName = (profile.userName ?? '').trim().isEmpty
    ? '您的家人'                      // <-- 硬编码中文
    : profile.userName!.trim();
```

- 问题：`safeUserName` helper 在 `core/shared/user_name_helper.dart`，`fallback: '您'` 默认，但 `l10n.emailBodyI18n(safeName, 2)` 走 l10n 翻译。`safeUserName(profile.userName, fallback: l10n.legalPageContactFallback)` 才能 en 模式不出中文
- 修法：`safeUserName(profile.userName, fallback: l10n.xxx)`
- 难度：简单
- 优先级：P1（i18n 漏洞）

### [lib/presentation/pages/contact/contacts_list_widget.dart:203] 硬编码 fallback 'Contact'

```dart
name: nameController.text.trim().isEmpty
    ? 'Contact'                            // <-- 硬编码英文
    : nameController.text.trim(),
```

- 修法：用 l10n key（`contactDefaultName` 之类）
- 难度：简单
- 优先级：P1

## 🟡 P2 - 可优化（magic number / 局部一致性）

### [lib/presentation/pages/contact/contacts_list_widget.dart:77] `padding: EdgeInsets.all(4)` magic

- 修法：`EdgeInsets.all(AppTokens.spacingXxs)`（= 2.0 略小，但 4 是常用值，可以加 `AppTokens.spacingXxxs = 2.0` → 不行，刚好 4 没 token，需要新增 `spacingFour = 4` 或用 `spacingXs = 8` 然后 padding 调成 Padding 缩量）
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/contact/contacts_list_widget.dart:74-76] `width: AppTokens.spacingMd, height: 24` magic 24

```dart
SizedBox(
  width: AppTokens.spacingMd,
  height: 24,
  child: Padding(
    padding: EdgeInsets.all(4),
    child: LoadingSpinner(size: 16),
  ),
),
```

- 修法：height: 24 → `AppTokens.iconSize` (= 24)，但 `width: 24` 在 LoadingSpinner(size: 16) 外层多余 — `LoadingSpinner` 自带 SizedBox
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/trend/trend_calendar.dart:145, 231] `EdgeInsets.symmetric(vertical: 2)`, `EdgeInsets.all(2)`

- 修法：`AppTokens.spacingXxxs = 2.0`（已有）
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/trend/trend_calendar.dart:321-323, 343-345] `EdgeInsets.symmetric(horizontal: 6, vertical: 2)` magic 6

- 修法：6 没 token。加 `AppTokens.spacingChipPaddingInlineH = 6` 或用 `spacingXs = 8` 然后调
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/settings/widgets/reminder_cards.dart:191-193] `EdgeInsets.symmetric(horizontal: 8, vertical: 2)` 应该走 token

- 修法：`horizontal: AppTokens.spacingXs, vertical: AppTokens.spacingXxxs`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/settings/widgets/reminder_cards.dart:162-163] `width: 40, height: 40` magic 40

- 修法：加 `AppTokens.iconBoxMd = 40.0` token
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/setup/setup_step_medication.dart:309-310] `Wrap(spacing: 8, runSpacing: 8)` magic 8

- 修法：`spacing: AppTokens.spacingXs, runSpacing: AppTokens.spacingXs`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:309-310] 同上 `Wrap(spacing: 8, runSpacing: 8)`

- 修法：同上
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/trend/widgets/trend_heatmap_grid.dart:21-22, 28] `spacing: 4, runSpacing: 4` + `(constraints.maxWidth - 4 * 4) / 5` magic 4

```dart
Wrap(
  spacing: 4,
  runSpacing: 4,
  children: [
    for (final d in daily)
      _HeatCell(
        date: d.date,
        checked: d.checked,
        size: ((constraints.maxWidth - 4 * 4) / 5).clamp(28.0, 48.0),
      ),
  ],
),
```

- 修法：`4 * 4` = 16 = `AppTokens.spacingSm` (= 16.0)。但 `spacing: 4` 跟 token sequence (2/4/8/16) 关系不清，需要加 `AppTokens.spacingHeatmap = 4.0` 或承认就是 4 magic
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/setup/setup_page.dart:413] `const Duration(seconds: 5)` 硬编码 timeout

```dart
final medications = await ref
    .read(medicationRepositoryProvider)
    .watchAll()
    .first
    .timeout(const Duration(seconds: 5));
```

- 修法：加 `AppTokens.dbReadTimeout = const Duration(seconds: 5)` token
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/medication_report_dialog.dart:160] `colorScheme.scrim.withValues(alpha: 0.54)` magic 0.54

```dart
color: Theme.of(context).colorScheme.scrim.withValues(alpha: 0.54),
```

- 注释有解释（"M3 Modal barrier 0.32 太浅，PDF 5s+ 需更深"），但 0.54 是 magic
- 修法：加 `AppTokens.scrimHeavy = 0.54` const
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/assessment/assessment_widgets.dart:351] `trendColor.withValues(alpha: 0.6)` magic 0.6

```dart
color: trendColor.withValues(alpha: 0.6),
```

- 注释有 "emil deliberate don't tokenize"，但集中器都收一波更整齐
- 修法：加 `AppTokens.onSurfaceMid = 0.6`（已有 `fgDisabled = 0.5`、`tintedPrimarySoft = 0.1`）
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/assessment/assessment_page.dart:259-262] `EdgeInsets.only(left: 26, top: spacingXxxs, bottom: spacingXs)` magic 26

```dart
padding: const EdgeInsets.only(
  left: 26,  // 编号缩进对齐 (deliberate, 不抽 token)
  top: AppTokens.spacingXxxs,
  bottom: AppTokens.spacingXs,
),
```

- 注释说 deliberate（题号 1-9 编号缩进对齐），但 26 = 24 + 2 = spacingMd + spacingXxs = 视觉估算的"icon 16 + padding 8 + 2" ≈ 26，可以拆成两个 token 相加
- 难度：中等
- 优先级：P2

### [lib/presentation/pages/assessment/widgets/assessment_chart_card.dart:76] `height: 180` 跟 `chartPlaceholderHeight = 200` 不一致

```dart
SizedBox(
  height: 180,                  // <-- magic
  child: LineChart(...),
),
```

- 同 app 其它 3 个 chart 都走 `AppTokens.chartPlaceholderHeight = 200.0`（trend_assessment / trend_mood / trend_monthly）。assessment_chart 写 180
- 修法：`AppTokens.chartPlaceholderHeight`（统一）
- 难度：简单
- 优先级：P2（一致性）

### [lib/presentation/pages/setup/setup_page.dart:298-301] `EdgeInsets.fromLTRB(spacingMd, spacingMd, spacingMd, spacingSm)` 在 _MigrationFailedApp

- 没问题，走 token
- 优先级：OK

### [lib/presentation/pages/settings/widgets/notification_status_card.dart:218] `height: 16` magic

```dart
SizedBox(
  width: AppTokens.spacingSm,
  height: 16,
  child: LoadingSpinner(size: 16),
),
```

- `size: 16` = `AppTokens.iconSizeSmall(14)` 或 `iconSizeMicro(12)` 之外的 `iconSizeXs = 16`？可考虑加 token
- 修法：`height: AppTokens.iconSizeSmall + 2` 不直观，最好加 `AppTokens.loadingSpinnerSm = 16` 或直接用 `iconSizeInline + 0` 不 work
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/mood/widgets/mood_recorder.dart:488-491] `width: 12, height: 12` magic

- 巧合等于 `iconSizeMicro = 12.0`，但 hardcoded
- 修法：`AppTokens.iconSizeMicro`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/assessment/widgets/assessment_history_list.dart:156] `size: 12` magic

- 同上，等于 `iconSizeMicro`
- 修法：`AppTokens.iconSizeMicro`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/vent/widgets/vent_audio_section.dart:58] `size: 28` magic

- 28 没 token，介于 iconSizeLg(32) 和 iconSizeInline(18) 之间
- 修法：加 `AppTokens.iconSizeXl = 28.0` 或 `iconSizeRecordBtn = 28`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/vent/vent_detail_page.dart:270] `size: 32` magic

- 等于 `AppTokens.iconSizeLg = 32.0`，应走 token
- 修法：`AppTokens.iconSizeLg`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/vent_detail_page.dart:222, trend_calendar.dart:411, today_med_schedule.dart:58, assessment_widgets.dart:32,291] `size: 20` magic

- 5+ 处 `size: 20` 散落。20 不在 token sequence (12/14/18/24/32/64)
- 修法：加 `AppTokens.iconSizeEmpty = 64` 之外的 `iconSize20 = 20.0` token（如果统一用 20）或承认 magic
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/assessment/assessment_widgets.dart:304] `size: 28` magic

- 28 没 token
- 修法：加 token
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/medication/widgets/medication_row.dart:127-131] `width: 18, height: 18` magic + 内联 `CircularProgressIndicator(strokeWidth: 2)`

```dart
SizedBox(
  width: 18,
  height: 18,
  child: CircularProgressIndicator(strokeWidth: 2),
)
```

- 18 没 token，strokeWidth 2 跟 LoadingSpinner 一致（已经 token 化）
- 修法：抽一个 `LoadingSpinnerMini(size: 18)` 或承认 18 magic + 用 LoadingSpinner
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/setup/setup_step_medication.dart:120-144] "完成"按钮 Stack + CircularProgressIndicator 手动实现

```dart
SizedBox(
  width: 110,
  height: 44,
  child: Stack(
    alignment: Alignment.center,
    children: [
      ElevatedButton(...),
      if (saving)
        IgnorePointer(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: AppTokens.fgOnPrimary(context)),
          ),
        ),
    ],
  ),
),
```

- 110 / 44 magic button size，重复 `LoadingTextButton` 已有的 `saving` spinner 逻辑
- 修法：直接用 `LoadingTextButton(label: l10n.setupNext, isLoading: saving, onPressed: onFinish)`，删 110/44 SizedBox 限制
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/medication/today_med_schedule.dart:163-165, 177-187] `EdgeInsets.symmetric(horizontal: chipGap, vertical: chipGap)` + `padding: EdgeInsets.only(right: 4)` chip 内部 padding 重复

```dart
padding: const EdgeInsets.symmetric(
  horizontal: AppTokens.spacingChipGap,    // 6
  vertical: AppTokens.spacingChipGap,      // 6
),
...
padding: const EdgeInsets.only(right: 4),  // 4 magic
```

- chip 内部 padding 用 `spacingChipGap = 6`（垂直 + 水平都 6），但 4 没 token
- 修法：`AppTokens.spacingChipPaddingV = 6` 已有，用 token；4 magic 加 `AppTokens.spacingXxxs = 2`（数值不对应）
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/trend/widgets/trend_assessment_chart.dart:30, trend_mood_chart.dart:30] `size: 40` magic empty chart icon

- 40 没 token
- 修法：加 `AppTokens.iconSizeChartEmpty = 40.0`
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/settings/widgets/reminder_cards.dart:170] `size: 22` magic

- 22 没 token
- 修法：加 token 或用 `iconSizeInline(18)` + 手动调
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/medication/today_med_schedule.dart:170, 184, 188] `EdgeInsets.only(right: 4)` 4 magic

- 修法：加 token 或用 `spacingXxs = 2`（半值）
- 难度：简单
- 优先级：P2

### [lib/presentation/widgets/mood_quick_button.dart:46, 51] 内联 `TextStyle(fontSize: AppTokens.fontSizeBodySm)` 没走 textStyle token

- 修法：可以用 inline 形式（ListTile 内的 emoji 不需要 textStyle 集中器），但用 `fontSizeMicro` 之类小字号语义更准
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/setup/setup_page.dart:291] `style: const TextStyle(fontSize: AppTokens.fontSizeTitle)` 内联，emoji 渲染有 size cap

- 注释有解释，OK
- 优先级：OK

### [lib/presentation/pages/setup/setup_step_medication.dart:120-122] `width: 110, height: 44` magic button size

- 110/44 不在 token 序列（buttonHeight = 88, buttonHeightSmall = 56, minTapArea = 48）
- 修法：加 `AppTokens.buttonSizeMedium = const Size(110, 44)` 或承认 wizard 步骤按钮专属
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/contact/contacts_list_widget.dart:163, 167] `nameController, phoneController` 创建但 dispose 写在 `.then((_) { ... })` 里 — race condition

```dart
showDialog<void>(...).then((_) {
  nameController.dispose();
  phoneController.dispose();
});
```

- 问题：`.then` 在 dialog 关闭时跑，如果用户点 dialog 外部 barrier 关闭（不通过 TextButton.cancel / .save），`.then` 仍然 fire。理论 OK。但如果 widget 提前 unmounted（比如 widget tree 状态变化），controller 还在被 dialog 用 → race
- 实际不太会触发（dialog 关闭后 widget 不再用 controller），但 best practice 是用 StatefulWidget + dispose
- 修法：抽 `_AddContactDialog` StatefulWidget
- 难度：简单
- 优先级：P2

### [lib/presentation/pages/setup/setup_page.dart:65-102] `nameController` + 6 个 contact controller + MedDraft 状态机手写 dispose 链

- 复杂度高但目前能跑，未来增加 MedDraft 字段容易漏 dispose
- 修法：考虑用 `Listenable` 集中器
- 难度：中等
- 优先级：P2

## 🟢 P3 - nice-to-have

### [lib/presentation/widgets/loading_skeleton.dart:8] `import 'dart:async';` 在 `import 'package:flutter/material.dart';` 之后

- 修法：dart import 应该在 flutter 之前（lint `directives_ordering`）
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/vent/vent_compose_page.dart:78] `ref.read(ventAudioStorageProvider)` 在 dispose 里同步读 provider — 已 dispose 的 ref 会抛

```dart
if (_tempDecryptedPath != null) {
  try {
    ref.read(ventAudioStorageProvider).deleteTempFile(_tempDecryptedPath!);
  } catch (e, st) {
    swallowError(...);
  }
  _tempDecryptedPath = null;
}
```

- 问题：dispose 里 ref.read 已经被 Flutter 标记为 unsafe。`try/catch` 兜底 OK，但官方建议 dispose 不再用 ref
- 修法：把 temp file path 存到 state 变量，dispose 里直接 import VentAudioStorage 类（不走 provider）
- 难度：中等
- 优先级：P3

### [lib/presentation/pages/trend/trend_utils.dart:13-17] SpotKey magic 1e6 / 100

```dart
SpotKey(double x, double y)
    : x = (x * 1e6).round(),
      y = (y * 100).round();
```

- 修法：加注释说明"微秒级精度 / 2 位小数"，或命名常量
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/setup/setup_page.dart:23-26] 4 个 import 顺序（Dart 1 / flutter 7 / package 3 / project 11）

- 大体符合 `directives_ordering` 但 setup 内部有些混排
- 修法：跑 `dart fix --apply`
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/trend/trend_calendar.dart:233] `color: theme.colorScheme.surfaceContainerHighest` 跳过 AppTokens

- 走 `AppTokens.surfaceColor(context)` 的话 dark mode 默认 surface 太暗，surfaceContainerHighest 才是 M3 推荐的"卡片稍亮"色
- 修法：加 `AppTokens.surfaceContainerHighest(BuildContext ctx)` getter 显式命名
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/settings/legal_page.dart:282] `activeThumbColor: AppTokens.errorColor(context)` M2 Switch API

- `activeThumbColor` 在 Flutter 3.32+ 被 deprecated，改用 `thumbColor: WidgetStateProperty.resolveWith(...)`
- 修法：跟 ConsentCheckRow 同款 WidgetStateProperty
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/mood/widgets/mood_recorder.dart:479] `fontFeatures: const [FontFeature.tabularFigures()]` 内联

- 跟 `textStyleMono` 一样可以抽 token（tabularFigures / proportional）
- 修法：扩展 `AppTokens.textStyleMono` 加 tabularFigures 选项
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/settings/widgets/reminder_cards.dart:91] `Border.all(color: errorColor, width: 1)` 警示框边框

- 走 `AppTokens.tintedErrorBorder(context)` 类似 token（项目已有 `tintedWarningBorder`）
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/trend/trend_calendar.dart:237] `BorderSide(color: theme.colorScheme.primary, width: 1.5)` magic 1.5

- 加 token `AppTokens.borderEmphasis = 1.5`
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/setup/setup_widgets.dart:60] `width: 1.5` border magic

- 同上
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/medication/widgets/medication_row.dart:73-76] inline `TextStyle(decoration: lineThrough, color: textHint)` 缺省 w500

- 走 `AppTokens.textStyleBodyStrikethrough` 集中器
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/home/home_page.dart:153] `action: '⚠️ ${result.displayMessage}'` 前缀 emoji

- 跟 assessment 危机信号一致风格，但 snackbar action 文案应走 l10n
- 修法：`l10n.safetyAlertAction(result.displayMessage)` 或承认是安全相关不影响
- 难度：简单
- 优先级：P3

### [lib/presentation/widgets/animations/celebration_bounce.dart:46-58] 5 段 TweenSequence hardcoded weight 30/20/50

- 加注释解释 weight 含义
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/setup/setup_page.dart:80-100] 5 个 TextEditingController 在 initState 手动 attach listener

- 已在 dispose 释放（line 87-101），但 MedDraft.times 增删没通知 setState — 如果用户动态增删药单，`_onTextChanged` 不会被调，页面可能不更新
- 实际影响小（增加 MedDraft 是按按钮，不是输入）
- 难度：中等
- 优先级：P3

### [lib/presentation/pages/assessment/assessment_widgets.dart:48-58] `SparklinePainter` dot stroke 1.5 / line 2 magic

- 加 `AppTokens.chartLineWidth = 2.0` / `AppTokens.chartDotStroke = 1.5`
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/assessment/assessment_page.dart:373-394] "返回 / 再做一次" 2 按钮行没走 PressFeedback

- tens/day 频度，emil 应该有 :active 反馈
- 修法：包 `PressFeedback`
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/contact/contacts_list_widget.dart:42-44] `Card > Column` 视觉：每行 1 个 ListTile，Card 看起来多余

- 可以直接 ListView，不套 Card
- 修法：评估 Card 视觉价值（项目所有 list 都套 Card 保持一致，OK）
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/assessment/assessment_page.dart:151-156] 主提交按钮 ElevatedButton 没包 PressFeedback

- tens/day 频度，emil 应该有 scale
- 修法：`PressFeedback(onTap: _canSubmit ? _submit : null, child: ElevatedButton(...))`
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/setup/setup_step_welcome.dart:155-158] 提交按钮 ElevatedButton 没包 PressFeedback

- 同上
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/setup/setup_step_consent.dart:100-103] 同上

- 难度：简单
- 优先级：P3

### [lib/presentation/pages/settings/reminders_hub_page.dart:336-352, 472-487] Sheet 里 2 个 "取消 / 保存" 按钮行重复

- 可以抽 `SheetActions` widget 跟 `MoodDialogActions` / `VentSaveBar` 同款
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/settings/widgets/reminder_cards.dart:160-170] 状态 chip `padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2)` 内联

- 走 `ChipBadge` widget 集中器
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/assessment/assessment_page.dart:46-58] 路由给错 id 用 `addPostFrameCallback` 下一帧 pop

- 改用 `WidgetsBinding.instance.addPostFrameCallback` 时机 OK，但 `mounted` 守卫 pop 之后可能仍触发（已 dispose 后）
- 修法：检查 `mounted` 之前再 `context.pop()`
- 难度：简单
- 优先级：P3

### [lib/presentation/pages/medication/widgets/medication_row.dart:184-191] `refillTextColor` 静态方法接受 `BuildContext` 但 entity method `isRefillOverdue()` 不接受

- entity 应该暴露 `refillStatus()` enum，color 是 UI 关注点，逻辑 entity 关注点
- 已有 `domain/entities/medication_entity.dart` 的 `isInRefillWindow` / `isRefillOverdue`，可以加 `refillStatus(now)` enum
- 难度：中等
- 优先级：P3

### [lib/presentation/pages/setup/setup_page.dart:33] 协议版本号 `_kLegalVersion = 'v0.21-2026-07-20'` 硬编码

- 长期看应该跟 pubspec.yaml version 同步
- 难度：中等
- 优先级：P3

### [lib/presentation/pages/trend/trend_calendar.dart:411, 415, 425] `size: 20` 用 `Icons.inbox_outlined` 等等 magic

- 同前面 `size: 20` magic 修复

### [lib/presentation/pages/setup/setup_page.dart:108-114] `onPopInvokedWithResult` snackbar 文案硬编码

- snackbar 显示 info 应该走 l10n
- 修法：l10n key
- 难度：简单
- 优先级：P3

---

## 集中化建议（高 ROI 重构）

按"改一个 token 影响 5+ 文件"原则，最值得做的几个集中化（v0.28+ 可做）：

| 集中化 | 影响文件数 | 价值 |
|---|---|---|
| **`Formatters` 扩展**（加 `timeOfDay(HourMinute)` / `duration(int sec)` / `dateOfMonth` 等） | 8+ | 一行删 30+ 处 `padLeft(2, '0')` |
| **新 spacing token**（`spacingFour=4` / `spacingSix=6` / `spacingTwenty=20`） | 20+ | 消除 magic EdgeInsets |
| **新 icon size token**（`iconSizeRecord=28` / `iconSizeChartEmpty=40`） | 5+ | 统一图标尺寸 |
| **`AppListTile` 加 `onLongPress` / `subtitle 3 行` / `leading custom` 扩展** | 3+ | 让 `vent_list_page.dart:216-275` 的 `PressFeedback+Card+ListTile+Hero` 也能用集中器 |
| **`SheetActions` 抽出**（跟 `MoodDialogActions` 同款） | 2+ | reminders_hub 两个 sheet 复用 |
| **`LoadingSpinner` mini 变体**（`size: 12/16/18` 系列） | 5+ | 统一 strokeWidth=2.5 |
| **新增 widget 集中器**：`FormActionButton`（带"完成设置"等硬编码 action 文案） | 2+ | setup_page / refill dialog 等 |
| **`M3 Switch` API 修正**（`activeThumbColor` → `WidgetStateProperty`） | 2+ | 兼容 Flutter 3.32+ |

---

## 总结

**评估结论**：

| 维度 | 分数 | 评语 |
|---|---|---|
| Token 集中度 | 9.5 / 10 | 业内顶级水准 |
| 动效决策框架 | 9.8 / 10 | MotionScheme enum + reduce-motion + 4 档 + comment 写明 emil 决策依据 |
| 组件复用 | 9.2 / 10 | 8+ 集中器覆盖率高，但 `Formatters` 仍被 8+ 处绕过 |
| 主题一致性 | 9.5 / 10 | ColorScheme.fromSeed 完整 |
| 跨页设计一致性 | 9.0 / 10 | PressFeedback / EmptyState / ErrorState 几乎全用，但 Formatters 不统一 |
| 局部细节打磨 | 7.5 / 10 | 一些 magic number 残留（spacing 4/6, icon size 20/22/28/40, `width: 110, height: 44` 等） |
| a11y | 9.0 / 10 | AppSemantics + reduce-motion + Haptics 全面 |

**最该做的 3 件事**（高 ROI）：
1. **修正 1 个 P0 视觉 bug** — `assessment_widgets.dart:222-244` 的 Column 闭合问题
2. **统一 `Formatters`** — 8+ 处 widget 绕过集中器写自己的 padLeft
3. **加 5-6 个新 spacing/icon token** — 4/6/20/22/28/40 这几个 magic 数字

**整体评语**：这是一个在 emil 视角下已经做到 9+ 分的设计系统。剩下的 1 分主要是 Formatters 集中器不统一和少量 magic number 残留，都是低成本高 ROI 的清理。
