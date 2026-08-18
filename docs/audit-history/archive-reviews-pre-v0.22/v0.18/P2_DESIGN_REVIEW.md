# P2 设计审查报告 (emil 设计工程师视角)

**项目**:D:\Batch\chroniccare · 慢病管理 App
**审查时间**:HEAD 7ff087a (P1 全部 28 项 done 之后)
**审查人**:emil 设计审查 sub-agent
**代码基数**:143 个 Dart 实现文件 + 70 个测试文件

---

## TL;DR

P1 修了 28 项,但留下了 **3 个"P0/P1 修了但没落地"** 和 **若干"emil 框架未覆盖"** 的洞。本轮 P2 共 **42 项发现**:
- **P0 (8 项)** — 立刻修(已声明但未使用的关键 widget / a11y reduce-motion 大面积漏网 / 数据可见性 bug)
- **P1 (16 项)** — 重要(扩展 P0/P1 修法 + dark mode 残留 + 核心 micro-interaction 缺失)
- **P2 (12 项)** — 改善(动效 polish / 发现性 / 反馈一致性)
- **P3 (6 项)** — nice-to-have(探索性 / 大改造)

---

## P0 — 立刻修 (8 项)

> 同优先级内:架构问题先,具体 bug 后。

### P0-1 ⛔ PressFeedback widget 写了但 0 处使用

- **位置**:`lib/presentation/widgets/press_feedback.dart:35-87` (定义);`lib/presentation/` 全部 import 检查 → 0 处
- **问题**:P0-8 已声明 `PressFeedback` widget,提供 scale 0.97 + 160ms 反馈。但全 presentation 层 **0 个 widget 用它**。所有按钮(ElevatedButton / OutlinedButton / IconButton / ListTile) 都没有 scale 反馈,emil 决策框架"tens/day 微弱反馈"完全没落地
- **影响**:
  - 主页打卡 / 临时吃药 / snooze 5min / 情绪日记 / 树洞入口 5 个主按钮无 press 反馈
  - 设置页 20+ 列表项无 press 反馈
  - 用户体感"按了没反应" — 跟亚克力按钮(Android 12+ / iOS 15+) 业界标准差一档
- **修法**:
  ```dart
  // 在所有 IconButton/OutlinedButton/ElevatedButton/ListTile 外包 PressFeedback
  // 影响范围:50+ 处。优先:
  // 1) home_page 主按钮 3 个 (tens/day, 最高频)
  // 2) settings_page 20+ ListTile (tens/day)
  // 3) 详情页/dialog 按钮 (occasional)
  // 4) FAB / 列表项 swipe
  ```
- **工作量**:3-4 小时(批量改写,主要是机械替换)

### P0-2 ⛔ EmptyState widget 写了但 0 处使用,9+ 处重复空态

- **位置**:`lib/presentation/widgets/empty_state.dart:24-79` (定义);`lib/presentation/` 全部 `EmptyState(` 引用 → 0 处
- **问题**:P1-2 抽了统一 `EmptyState` widget(icon + title + subtitle + action),但现有 9+ 处的"if (xxx.isEmpty) return const Center(Text('还没有...'))" 模式**没迁移**:
  - `lib/presentation/pages/vent/vent_list_page.dart:52-94` `_EmptyState` (34 行)
  - `lib/presentation/pages/assessment/assessment_history_page.dart:80-117` `_EmptyState` (38 行)
  - `lib/presentation/pages/medication/medication_calendar_page.dart:117-138` (2 个 raw 提示)
  - `lib/presentation/pages/medication/widgets/medications_list_widget.dart:42, 70-78` (2 个 raw)
  - `lib/presentation/pages/medication/refill_manage_page.dart:154`
  - `lib/presentation/pages/contact/contacts_list_widget.dart:26-35`
  - `lib/presentation/pages/trend/trend_page.dart:422-450` (评估历史子空态)
  - `lib/presentation/pages/trend/trend_page.dart:701-726` (情绪历史子空态)
  - `lib/presentation/pages/settings/email_preview.dart:25-29` (没设置时)
  - `lib/presentation/pages/settings/widgets/report_history_dialog.dart:60-68`
- **影响**:
  - 9 处视觉不一致(有的有 icon、有的没有;icon 颜色硬编码;padding 各种数值)
  - 9 处文案分散,改文案要扫 9 个文件
  - 没用上 EmptyState 内的 `actionLabel + onAction`(大多数空态缺 CTA)
- **修法**:
  ```dart
  // 1) 删 vent_list / assessment_history 的 private _EmptyState
  // 2) 改用统一 EmptyState
  if (entries.isEmpty) {
    return EmptyState(
      icon: Icons.forest_outlined,
      title: '树洞还是空的',
      subtitle: '想说什么就说出来。文字、语音都可以。\n这些话只有你自己能看到。',
      actionLabel: '写第一句',
      onAction: () => context.push('/vent/compose'),
    );
  }
  // 3) 对 medical_calendar / contact / refill 等,所有"isEmpty → Text" 模式也替换
  ```
- **工作量**:2-3 小时(9 处,文案复用 + 加 CTA)

### P0-3 ⛔ prefers-reduced-motion 仅 4 个 widget 尊重,5 个 widget 完全忽略

- **位置**(已尊重):`press_feedback.dart:69` `celebration_overlay.dart:66` `fade_in.dart:79` `slide_up.dart:75` (均用 `MediaQuery.of(context).disableAnimations` 或 `Motion.duration`)
- **位置**(未尊重):
  - `lib/presentation/widgets/loading_skeleton.dart:118-123` `_Shimmer._controller` — `..repeat(reverse: true)` 永久 1200ms 循环,完全忽略 reduce-motion
  - `lib/presentation/pages/check_in/check_in_button.dart:26-32` `AnimatedContainer(duration: AppTokens.durNormal)` — 主页最大按钮,100+/day 频度,反而没尊重
  - `lib/presentation/pages/settings/widgets/notification_status_card.dart:188` `AnimatedSize(duration: AppTokens.durNormal)` — 用户开 reduce-motion 后状态文字依然闪动
  - `lib/presentation/pages/setup/setup_page.dart:111` `AnimatedSwitcher(duration: MotionScheme.standard.duration)` — 用了 MotionScheme token 但**没 wrap** `Motion.duration(context, ...)` → reduce-motion 下还在滑
  - `lib/core/routing/app_router.dart:30, 45, 62` `_fadePage` / `_slideRightPage` / `_slideUpPage` — 路由切换动画也没 wrap Motion.duration
- **影响**:
  - 精神心理患者前庭敏感比例高于普通用户(emil 决策框架第 8 条)
  - 主页 1.2s 永久循环 shimmer + 主页按钮切换 + 状态文字跳变 = 三重前庭刺激叠加
  - 开 reduce-motion 的用户**完全无感** (Pass 不到 P0-7 修复的覆盖范围)
- **修法**:
  ```dart
  // 1) loading_skeleton.dart:118 - 加 MediaQuery 监听,开 reduce 直接 _controller.stop()
  class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
    late final AnimationController _controller;
    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      if (MediaQuery.of(context).disableAnimations) {
        _controller.stop();
        _controller.value = 1.0; // 跳到终态
      }
    }
  }
  // 2) check_in_button.dart:26 wrap Motion.duration
  duration: Motion.duration(context, AppTokens.durNormal)
  // 3) notification_status_card.dart:188 同上
  // 4) setup_page.dart:111 wrap + use curveAccel/curveStd
  // 5) app_router.dart:30-67 _fadePage/_slideRightPage/_slideUpPage 的
  //    transitionDuration 改 Motion.duration(context, AppTokens.durNormal)
  ```
- **工作量**:1.5-2 小时(5 处,每处 10-20 行)

### P0-4 ⛔ HomePage 7 处裸 SnackBar 跳过 AppSnackBar 集中器

- **位置**:`lib/presentation/pages/home/home_page.dart:127, 137, 156, 190, 323, 368, 376` (7 处裸 `SnackBar(...)`)
- **问题**:P1-7 抽了 `AppSnackBar` helper(集中 i18n 模板 + 2/4 秒时长),共 25+ 处使用。但**HomePage 是 App 内 SnackBar 用得最多的页面**(7 处),反而 0 处用 AppSnackBar:
  - 错误 snackbar 5 处 → 应该有 error 模板
  - 信息 snackbar 2 处(自动打卡成功 / snooze 5min) → 应该走 info 模板
- **影响**:
  - 文案不统一(有的用 `AppLocalizations.of(context).commonCheckinFailed`,有的直接拼字符串)
  - 时长不统一(2s / 5s / 6s 各写各的,AppSnackBar 有 2/4 标准)
  - P1-16 全角标点 + P1-10 i18n 改造只覆盖了**用 AppSnackBar 的地方**,HomePage 这 7 处的字符串永远不会被 i18n 抓走
- **修法**:
  ```dart
  // 全替换,7 处都是 ~5 行改 2 行:
  AppSnackBar.error(context, action: '打卡', error: next.error)
  AppSnackBar.info(context, AppLocalizations.of(context).snackbarCopied)
  // 加 l10n 字符串:safeAlertedTemplate / safetyPostCheckIn / snoozeFailed 等
  ```
- **工作量**:1-1.5 小时(7 处替换 + 4-5 个新 l10n 字符串)

### P0-5 ⛔ dark mode 30+ 处仍用 `AppTokens.textHint/Secondary/Primary` 静态常量

- **位置**: `grep "AppTokens\.textHint\b"` → **42 处**;`AppTokens.textSecondary\b` → **30 处**;`AppTokens.textPrimary\b` → ~15 处
- **问题**:P1-5 抽出 7 个 dynamic getter(`textHintColor(context)` 等),batch 1 替换 8 处。但 batch 2+ 还没做,42 + 30 + 15 = **87 处**仍是静态常量(在 dark mode 下 = light 模式硬编码值,视觉错位)
- **高频高亮**(用户每天必看的):
  - `setup_page.dart:184, 231, 262, 278, 399, 419, 427, 578, 624, 674, 765, 974` (12 处)
  - `assessment_page.dart:107, 260, 309, 414, 457, 475, 484, 491, 510, 526, 555, 606, 622, 634, 642` (15 处)
  - `medications_list_widget.dart:42, 71, 103, 261, 270, 368, 372` (7 处)
  - `assessment_history_page.dart:93, 106, 202, 218, 272, 501` (6 处)
  - `trend_page.dart:1319, 1331, 1356, 1381, 1426` (5 处)
- **影响**:开 dark mode 后,主页、设置、趋势、评估 4 个核心页面多处"深底白字"/"深底深字"对比度破坏
- **修法**:
  ```dart
  // 1) 批量 sed 替换 (87 处):
  //    color: AppTokens.textHint   →   color: AppTokens.textHintColor(context)
  //    color: AppTokens.textSecondary  →   color: AppTokens.textSecondaryColor(context)
  // 2) 同步删 static const textHint/textSecondary/textPrimary (保留 enum / 旧文档)
  // 3) const TextStyle 变成 TextStyle (theme-aware 必须 non-const)
  // 4) 跑 flutter analyze 修新警告
  ```
- **工作量**:3-4 小时(机械 sed + 处理 const 变 dynamic 的链式影响)

### P0-6 ⛔ dark mode 边界 / 分割线 20+ 处仍用静态 divider / border

- **位置**: `grep "AppTokens\.divider\b"` → 12 处;`AppTokens\.border\b` → 8 处
- **问题**:跟 P0-5 同类。dark mode 下 `AppTokens.divider` (= light 浅灰) 在深色背景上**反而显眼**;`AppTokens.border` 视觉偏暗
- **示例**:
  - `trend_page.dart:1312, 1318-1331, 1356, 1381, 1426` (cal 热力图 / 详情卡 / 折线图)
  - `medication_calendar_page.dart:330, 356, 384` (图例)
  - `today_med_schedule.dart:74, 155, 157, 163, 193` (主页今日服药计划卡)
  - `reminders_hub_page.dart:321, 351, 361`
  - `settings_page.dart:268, 487`
- **影响**:dark mode 下视觉割裂感、对比错位
- **修法**:跟 P0-5 同一波,加 `dividerColor(context)` `borderColor(context)` getter 替换
- **工作量**:1.5-2 小时(12 + 8 = 20 处)

### P0-7 ⛔ raw `CircularProgressIndicator` 14 处,绕过 LoadingSpinner 的 strokeWidth=2.5

- **位置**:`grep "CircularProgressIndicator"` → 14 处直接使用,6+ 处是按钮内 spinner
- **问题**:P1-1 抽出 `LoadingSpinner` (统一 strokeWidth=2.5),但 14 处直接用:
  - `lib/presentation/pages/check_in/check_in_button.dart:83` (`color: Colors.white, strokeWidth: 2.5` — 接近正确)
  - `lib/presentation/pages/assessment/assessment_page.dart:69` (`CircularProgressIndicator()` — **默认 strokeWidth=4**)
  - `lib/presentation/pages/contact/contacts_list_widget.dart:52, 169` (strokeWidth=2)
  - `lib/presentation/pages/setup/setup_page.dart:479`
  - `lib/presentation/pages/vent/vent_compose_page.dart:382` (strokeWidth=2)
  - `lib/presentation/pages/medication/temp_medication_dialog.dart:130`
  - `lib/presentation/pages/mood/mood_dialog.dart:145`
  - `lib/presentation/pages/medication/widgets/medication_report_dialog.dart:111, 153`
  - `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart:354`
  - `lib/presentation/pages/settings/settings_page.dart:461`
  - `lib/presentation/pages/medication/widgets/medications_list_widget.dart:337`
  - `lib/presentation/pages/settings/widgets/notification_status_card.dart:199`
- **影响**:
  - 视觉不一致:大 spinner 4px 描边 vs 小 spinner 2.5px 描边混用
  - 默认 `CircularProgressIndicator()` 是 M3 primary,跟项目 `LoadingSpinner(AppTokens.primary)` 颜色一致,但 strokeWidth 偏粗 = 看起来更"工业"
- **修法**:
  ```dart
  // 1) 全部 14 处替换:
  const SizedBox(width: 18, height: 18, child: LoadingSpinner(size: 18, color: Colors.white))
  // LoadingSpinner 已存在,加 color 参数 OK (P0-7 实施时加)
  // 2) LoadingSpinner 已支持 color 参数(loading_skeleton.dart:88)
  ```
- **工作量**:30 分钟(纯替换,14 处)

### P0-8 ⛔ HapticFeedback 仅 3 处,所有"删 / 存 / 切选项"无触感

- **位置**:`grep "HapticFeedback"` → 3 处都在 home_page.dart (`:120`, `:287`, `:358`)
- **问题**:只有主页打卡成功 / snooze 5min 用了 `HapticFeedback.mediumImpact()` / `lightImpact()`。其他 N 处敏感操作无反馈:
  - 删除联系人 / 药物 / 报告 (`contact`, `medications_list_widget`, `report_history_dialog`)
  - 情绪日记 4 维度评分切换 (`mood_dialog`)
  - 评估量表题选项 (`assessment_page`)
  - 心理评估危机资源弹窗确认
  - 树洞条目删除 (`vent_list`)
- **影响**:
  - 慢病管理用户**很多是老年人** / **手部震颤** / **视障**,haptic 是"操作成功"的物理确认
  - 缺少 haptic → 用户**不知道按到没** → 重复点 → 误删 / 重复存
- **修法**:
  ```dart
  // 1) 抽 FeedbackHelper (类似 AppSnackBar):
  class Feedback {
    static Future<void> tap() => HapticFeedback.selectionClick();
    static Future<void> success() => HapticFeedback.mediumImpact();
    static Future<void> light() => HapticFeedback.lightImpact();
    static Future<void> warning() => HapticFeedback.heavyImpact();
  }
  // 2) 在 5 类操作前调用:
  //    - 删除:warning() (重触感,警示)
  //    - 保存成功:success() (中触感,确认)
  //    - 选项切换(情绪评分/评估题):tap() (轻触感,选中)
  //    - 取消 / 关闭:light() (轻触感,无负担)
  ```
- **工作量**:1.5-2 小时(helper + 5 类操作接入)

---

## P1 — 重要但可延 (16 项)

### 动效 token 化 (4 项)

#### P1-1 BorderRadius 5+ 处硬编码,绕开 radius token

- **位置**:
  - `lib/presentation/pages/medication/medication_calendar_page.dart:322, 377` `BorderRadius.circular(2)` — 应是 `AppTokens.radiusCell`
  - `lib/presentation/pages/trend/trend_page.dart:325, 350` `circular(4)` — 应是 `AppTokens.radiusCellLg`
  - `lib/presentation/pages/home/widgets/celebration_overlay.dart:94` `circular(24)` — 应是 `AppTokens.radiusButton`
  - `lib/presentation/pages/setup/setup_page.dart:957` `circular(8)` ?(不查;待确认是否 token 化)
- **修法**:sed 替换,token 已有
- **工作量**:15 分钟

#### P1-2 Curves 6+ 处硬编码

- **位置**:
  - `lib/presentation/widgets/press_feedback.dart:81` `Curves.easeOut` — 应 `AppTokens.curveStandard`
  - `lib/presentation/pages/home/widgets/celebration_overlay.dart:32, 40, 54` `Curves.easeOutBack` / `easeOutCubic` / `easeOut` — 3 处
  - `lib/presentation/pages/assessment/assessment_page.dart` (内联动画)? 待查
- **修法**:有 token 的换 token,无 token 的(elastic)用 `AppTokens.curveDelight`
- **工作量**:30 分钟

#### P1-3 Duration 11 处硬编码 SnackBar 时长

- **位置**:
  - `lib/presentation/pages/home/home_page.dart:139, 161, 326, 370` (2s/6s/5s/2s) — 跟 P0-4 同波
  - `lib/presentation/pages/setup/setup_page.dart:735` (3s) — 模板载入提示
  - `lib/presentation/pages/medication/widgets/medications_list_widget.dart:144, 220` (2s/2s)
  - `lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart:61, 95` (2s/2s)
  - `lib/presentation/pages/settings/widgets/notification_status_card.dart:79` (2s)
- **问题**:AppSnackBar 有 2s / 4s 标准,但绕过 AppSnackBar 的 11 处时长任意
- **修法**:
  ```dart
  // 1) 扩 AppSnackBar 枚举:
  enum SnackBarDuration { short, medium, long }  // 2s / 4s / 6s
  // 2) 11 处替换:AppSnackBar.custom(context, msg, duration: SnackBarDuration.long)
  ```
- **工作量**:30 分钟

#### P1-4 stagger 动画只有 2 处,无统一 helper

- **位置**:
  - `lib/presentation/pages/vent/vent_list_page.dart:122` `Duration(milliseconds: (i * 40).clamp(0, 400))`
  - `lib/presentation/pages/medication/medication_calendar_page.dart:196` `Duration(milliseconds: i * 40)`
- **问题**:两处都写 `i * 40`,无统一 `StaggeredListItem(index: i, child: ...)` helper。如果第三处需要(趋势页 / 评估历史)又要再写一遍
- **修法**:
  ```dart
  // 在 animations/ 加 StaggeredFadeIn:
  class StaggeredFadeIn extends StatelessWidget {
    final int index;
    final int baseDelayMs;
    final int stepMs;
    final int capMs;
    final Widget child;
    // ...
  }
  ```
- **工作量**:1 小时(抽 helper + 改 2 处)

### Empty / Loading / Error 状态 (4 项)

#### P1-5 9+ 处空态文案分散,改 i18n 要扫 9 文件

- 见 P0-2 的位置列表
- **额外问题**:空态文案 6 处仍用 raw 中文(没走 ARB):
  - `medication_calendar_page.dart:122-123` '还没有在用药物'
  - `medication_calendar_page.dart:131-132` '在用药物未设置服用时间,无法生成依从性日历'
  - `medications_list_widget.dart:42` '还没添加常吃药'
  - `medications_list_widget.dart:70-78` '没有在用的药'
  - `refill_manage_page.dart:154` '还没有添加药物'
  - `contact/contacts_list_widget.dart:31` '还没有联系人,请先添加'
  - `trend_page.dart:435` '还没有评估记录'
  - `trend_page.dart:714` '还没有情绪记录'
  - `reminders_hub_page.dart:414` '还没有在用药物 · 添加后会自动启用'
- **修法**:9 个空态标题 / 副标题 / CTA 全部走 ARB key
- **工作量**:1.5-2 小时(9 字符串 + 9 import 改)

#### P1-6 错误态文案 6+ 处硬编码"加载失败: $e"

- **位置**:`grep "commonLoadFailed"` 调用,部分页面用,部分页面直接拼字符串:
  - `medication_calendar_page.dart:92, 96` "加载药物失败: $e" / "加载打卡失败: $e" — 直接拼中文
  - `assessment_page.dart` ? (待确认)
  - `setup_page.dart` ? (待确认)
- **修法**:用 `AppLocalizations.of(context).commonLoadFailed(e.toString())` 统一
- **工作量**:1 小时

#### P1-7 全屏加载场景下 LoadingSkeleton 仍写"正在加载" 文案?

- **位置**:`lib/presentation/widgets/loading_skeleton.dart:39-67` LoadingSkeleton.fullScreen 有 `message` 参数,**但**大多数调用方(20 处 `LoadingSkeleton.fullScreen()`) 都不传 message → 空文案
- **问题**:用户看到 spinner 但不知道在加载什么
- **修法**:
  ```dart
  // 1) message 改为必填:const LoadingSkeleton.fullScreen({required this.message})
  // 2) 20 处调用方传对应 message(走 ARB)
  // 3) 或 message 默认值 = null + UI 显示"加载中…"占位
  ```
- **工作量**:1-1.5 小时(20 处文案 + ARB key)

#### P1-8 route transition `AppTokens.durNormal` 无 Motion 包装

- **位置**:`lib/core/routing/app_router.dart:30, 45, 62` 三个 `_fadePage` / `_slideRightPage` / `_slideUpPage` 的 `transitionDuration` 硬写 `AppTokens.durNormal`
- **问题**:同 P0-3,用户开 reduce-motion 后路由切换还在 fade/slide
- **修法**:`transitionDuration: Motion.duration(context, AppTokens.durNormal)` 三个 helper
- **工作量**:15 分钟

### 发现性 / Onboarding (4 项)

#### P1-9 设置页无 tab 切分,492 行单页 ListView 滚到底

- **位置**:`lib/presentation/pages/settings/settings_page.dart` (整个 492 行)
- **问题**:设置页 4 大块(联系人 / 药物 / 数据 / 提醒 / 心理评估 / 邮件预览 / 关于 / 隐私),全塞一个 ListView 滚到底
  - 移动端 30+ 屏才能滚完
  - 用户找"提醒中心"得滚到第 3 屏
- **修法**:
  - 用 `TabBar + TabBarView` 拆 3 tab:「我的」「提醒」「数据」
  - 或保留 ListView 但加 quick-jump `NavigationRail`(宽屏) / `Drawer` (窄屏) anchor
- **工作量**:3-4 小时(大改)

#### P1-10 主页 0 处 Badge / 角标,用户看不到"待办" / "提醒 N 条"

- **位置**:全 App 搜 `Badge(` → 0 处
- **问题**:
  - 心理评估 30 天没做?没角标
  - 续方到期?没角标
  - 今日服药计划还有 3 个没打?没角标
  - 通知失败?有 banner(但无角标)
- **修法**:
  ```dart
  // 设置页「评估历史」入口加 Badge(逾期)
  // 「提醒中心」入口加 Badge(失败 N 条 / 续方到期 N 种)
  // 主页今日服药计划 chip 颜色:完成 0/3 → 红色,2/3 → 黄,3/3 → 绿
  // (today_med_schedule.dart 已有 "done/N" 数字,改个颜色梯度即可)
  ```
- **工作量**:2-3 小时

#### P1-11 树洞新功能 0 处 onboarding / coach mark

- **位置**:`lib/presentation/pages/vent/vent_list_page.dart` 树洞 list 第一次进没引导
- **问题**:v0.15 新加的树洞功能,主页"倾诉 🌲"按钮 + 全屏树洞页,**完全没引导**(不是 onboarding,只是 1-2 句"这里是树洞"的提示)
  - 用户可能不知道:可以语音、文字可混合、纯私密不分析
- **修法**:
  ```dart
  // 在 _EmptyState 加 1-2 句隐私承诺 + 「查看隐私说明」链接
  // 在 vent_list 顶部(非空态)首次进入显示 1 个 Dismissible banner
  //    "树洞 = 纯私密,不会进入趋势/分析。点 X 关闭"
  // (在 user_profile 存 dismissedFlags 持久化)
  ```
- **工作量**:2 小时(privacy notice 字符串 + 持久化 dismissed flag)

#### P1-12 心理评估 0 处强引导,主页看不到"该做评估了"

- **位置**:`lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart:128-167` 评估设置在设置页里,主页/趋势没显示"距上次 25 天,建议做一次"
- **问题**:Apple Health 思路是"主页 badge + 推送 + 设置入口三级",项目只做了"推送 + 设置入口",缺"主页 badge"
- **修法**:
  ```dart
  // trend_page 顶部 _SummaryCard 加 1 行 "下次评估: 3 天后"
  // 或 home_page 在 _NotificationFailureBanner 位置加 _AssessmentDueBanner
  ```
- **工作量**:1.5-2 小时

### 微交互 / 反馈 (2 项)

#### P1-13 SnackBar 0 处带 action 按钮("撤销删除" / "查看")

- **位置**:`grep "SnackBarAction"` → 0 处
- **问题**:
  - 删了联系人/药物/报告立刻无法撤销,要重打
  - 导出 JSON 完成后,没"打开分享"按钮(用户得自己去剪贴板)
  - 测试通知成功,没"查看详情"按钮
- **修法**:
  ```dart
  // 扩 AppSnackBar:
  AppSnackBar.withAction(
    context, message,
    actionLabel: '撤销',
    onAction: () => restoreDeleted(id),
  )
  // 优先场景:
  // 1) 删除联系人/药物/报告 → "撤销"
  // 2) 导出完成 → "分享"
  // 3) 自动打卡成功 → "查看"
  ```
- **工作量**:2-3 小时(helper + 3-5 处接入)

#### P1-14 0 处 pull-to-refresh,趋势页/树洞页数据更新靠实时 stream

- **位置**:`grep "RefreshIndicator"` → 0 处
- **问题**:
  - 用户在 vent_list 看历史,新写一条后,列表是实时 stream 但**没视觉提示**
  - 趋势页 / 评估历史也同理
  - pull-to-refresh 是 mobile 用户的肌肉记忆
- **修法**:
  ```dart
  // 在 vent_list / assessment_history / trend 加 RefreshIndicator:
  RefreshIndicator(
    onRefresh: () async {
      ref.invalidate(ventEntriesProvider);
      ref.invalidate(allMoodProvider);
      // 等 1 帧让 provider 重新拉
      await Future.delayed(Duration(milliseconds: 200));
    },
    child: ListView.separated(...),
  )
  ```
- **工作量**:1-1.5 小时(3-4 处接入)

### Bottom Sheet / 长按菜单 (1 项)

#### P1-15 列表项 0 处 swipe-to-dismiss,删除都靠 long-press 或 icon

- **位置**:`grep "Dismissible"` → 0 处
- **问题**:
  - 树洞列表(`vent_list_page.dart`) 用 long-press 弹 dialog 确认
  - 联系人 / 药物 / 报告 都用 IconButton(Icons.delete)
  - 移动用户习惯"左滑删"(Gmail / Outlook / Apple Mail)
- **修法**:
  ```dart
  // vent_list 用 Dismissible:
  Dismissible(
    key: ValueKey(entry.id),
    direction: DismissDirection.endToStart,
    background: Container(color: AppTokens.error, ...),  // 红底
    onDismissed: (_) => _deleteEntry(entry),
    child: ListTile(...),
  )
  // contact / medication list 同步改 swipe
  ```
- **工作量**:3-4 小时(3 个 list + 1 个 confirm snackbar)

### 国际化 (1 项)

#### P1-16 setup_page 7+ 处 `const Text('中文')` 硬编码,绕开 ARB

- **位置**:`lib/presentation/pages/setup/setup_page.dart` 多处:
  - `:309, 439, 519, 596, 797, 802, 888, 1050` 硬编码按钮文案
  - `:684` 表情 emoji `'🌱'` (但 emoji 不需要 i18n,可保留)
  - `:748` 表情 emoji `'🌱'` 同上
- **问题**:P1-10 batch 1+2 修了 16 个 string,但 setup_page 的 7-8 个按钮文案没扫到(可能是当时只跑了 grep 没覆盖 setup)
- **修法**:加 ARB key → setup_page.dart 全部 `AppLocalizations.of(context).setupXxx` 替换
- **工作量**:1.5-2 小时

---

## P2 — 改善 (12 项)

### Token polish (3 项)

#### P2-1 EdgeInsets 25+ 处含硬编码数字(2/4/6/8/16)

- **位置**:`grep "EdgeInsets\."` 部分结果有 `EdgeInsets.all(2)`, `EdgeInsets.only(top: 4)`, `EdgeInsets.symmetric(horizontal: 8, vertical: 2)`, `EdgeInsets.only(right: 4)`, `EdgeInsets.only(bottom: 2)`
- **示例**:`medication_calendar_page.dart` 大量 `EdgeInsets.all(1/2)`, `vent_list_page.dart:167` `top: 4`, `trend_page.dart:1111, 1194, 1288, 1307` 等
- **修法**:跟 AppTokens 4 档 spacing 对应 (`spacingXs=8`, `spacingSm=16`, `spacingMd=24`, `spacingLg=40`);4 / 2 之类的微调属于"设计 outlier",要么扩 token (加 `spacingXxs=4`) 要么改用 `spacingXs/2`
- **工作量**:2 小时(50+ 处,看哪些值得 token 化,哪些属于"内层 spacing 应跟随外层")

#### P2-2 fontSize 30+ 处硬编码 8/10/11/12/13/14/22/32/64

- **位置**: `grep "fontSize: \d+"` → 50+ 结果
- **问题**:AppTokens 有 6 档 fontSize(28/24/20/18/16/14),但代码里:
  - `8` 用 6+ 次(calendar cell / chart label)
  - `10` 用 8+ 次(legend / 列表项副文本)
  - `11` 用 5+ 次(chart label / 时间 chip)
  - `12` 用 7+ 次(注释 / caption 副文本)
  - `13` 用 4+ 次(单元标签)
  - `22` 用 2+ 次(情绪 emoji)
  - `32` 用 2+ 次(评估大字)
  - `64` 用 3+ 次(空态 emoji / 评估总分)
- **修法**:
  ```dart
  // 加 4 档 micro font token:
  static const double fontSizeMicro = 10.0;   // 替代 8/10
  static const double fontSizeSmall = 12.0;   // 替代 11/12/13
  static const double fontSizeEmoji = 22.0;   // 替代 22
  static const double fontSizeEmojiLg = 32.0; // 替代 32
  // 然后 sed 替换 30+ 处
  ```
- **工作量**:1.5-2 小时(扩 4 token + 30+ 处替换)

#### P2-3 card / icon / inkwell 颜色少量硬编码 `Color(0xFF...)`

- **位置**:`grep "Color\(0x[0-9A-Fa-f]{8}\)"` → 1 处:
  - `lib/presentation/pages/home/widgets/celebration_overlay.dart:97` `Color(0x33000000)` (黑色 20% 透明 — boxShadow)
- **修法**:加 `AppTokens.shadowOverlay` 或复用 `AppTokens.shadowCard`(已是 `Color(0x14000000)`)
- **工作量**:15 分钟

### 动效 polish (3 项)

#### P2-4 home_page PrimaryActionRow 切换 "打卡 ✓" 无动效过渡(streak 数字有,但文字没)

- **位置**:`lib/presentation/pages/check_in/check_in_button.dart:47-69` `AnimatedSwitcher` 已有,但 `transitionBuilder` 只用 FadeTransition + ScaleTransition,文字"我今天吃了药" ↔ "今天已打卡 ✓" 切换还是有点"硬"
- **修法**:
  ```dart
  // 1) 用 SizeTransition + FadeTransition 让布局也平滑过渡
  // 2) 切换瞬间给 streak 数字一个 _StreakCounter 已经 tween,保留
  // 3) 按钮 bg color 已经是 AnimatedContainer,保留
  ```
- **工作量**:30 分钟

#### P2-5 trend_page 7 处 `Theme.of(context).colorScheme.onSurfaceVariant` 内联,可抽 token

- **位置**:`lib/presentation/pages/trend/trend_page.dart:110, 121, 132, 161, 266, 431, 443, 475, 710, 722, 806` 等 10+ 处
- **问题**:跟 P0-5 / P0-6 一类。`onSurfaceVariant` 是 M3 theme 的语义色,本身 theme-aware,但在代码里散落 10+ 处调用
- **修法**:
  ```dart
  // 已经在 app_tokens.dart 有 onSurfaceVariant 的 getter 思路
  // 加 AppTokens.textTertiary(context) 包装,统一命名
  ```
- **工作量**:1 小时

#### P2-6 路由切换动画时 setup / vent 上下滑入有 0.04 / 0.05 偏移,emil 标准应 0.1

- **位置**:`lib/core/routing/app_router.dart:62` `Offset(0, 0.05)` — slide-up 偏移 5% 屏高
- **问题**:emil 标准 full-screen modal 偏移 8-12% 屏高更明显(让"页面在动"而不是"页面在闪")
- **修法**:`Offset(0, 0.08)` 调到 8%
- **工作量**:5 分钟

### 文案 / 一致性 (3 项)

#### P2-7 14 处 `Icon(Icons.chevron_right, color: AppTokens.textHint)` 重复

- **位置**:`lib/presentation/pages/medication/refill_manage_page.dart:271`, `lib/presentation/pages/medication/widgets/medications_list_widget.dart:53`(链入口)
- **问题**:chevron_right + textHint 是 ListTile trailing 的标准配置,每次手写
- **修法**:
  ```dart
  // 1) 抽 `listTileChevron(BuildContext context)` widget
  // 2) 或 M3 ListTile 本身就支持 trailing widget
  ```
- **工作量**:1 小时

#### P2-8 '已打卡' / '今天已打卡 ✓' / '已记录!' / '已写入' 文案不一致

- **位置**:`grep "已打卡|已记录|已写入"` → 多处
- **修法**:走 ARB,统一 1 个 key `snackbarCheckedIn`
- **工作量**:30 分钟

#### P2-9 设置页 5+ 个 section 标题 raw 字符串

- **位置**:`lib/presentation/pages/settings/settings_page.dart:43, 80, 145, 167, 195` 5 个 `_SectionHeader(title: '...')` 硬编码中文
- **修法**:5 个 ARB key
- **工作量**:30 分钟

### 反馈强化 (3 项)

#### P2-10 streak 数字 tween (P1-27) 在 isChecked=false → true 切换时无 flash

- **位置**:`lib/presentation/pages/check_in/check_in_button.dart:62` `_StreakCounter` 用 TweenAnimationBuilder,初始值 0 → 终值 N,但 isChecked 状态切换时数字才 tween,**初始显示 0**(哪怕用户已经连击 30 天)
- **问题**:用户首次进主页,streak 显示 0 而不是真实连击 30 天(短暂 0 → 30 跳变)
- **修法**:
  ```dart
  // _StreakCounter 首次 build 用真实值,isChecked 切换时才 tween
  // 当前:begin: 0 → end: value(永远从 0 开始)
  // 改:begin: value, end: value(切换瞬间 tween from old to new)
  ```
- **工作量**:30 分钟

#### P2-11 树洞详情页删除按钮 confirm dialog 缺 "撤销" 撤销窗口

- **位置**:`lib/presentation/pages/vent/vent_detail_page.dart:108-118` 删除走 `Navigator.pop(ctx, true)` → 直接 `repo.delete(id)`
- **问题**:删了无法恢复(树洞 audio + 文字都没了,树洞内容是情绪数据,删错代价高)
- **修法**:删除后弹 SnackBar + action "撤销"(5s 内可恢复)
- **工作量**:1.5 小时(类似 P1-13)

#### P2-12 主页 streak 数字 chip 颜色单调,无 "里程碑" 视觉

- **位置**:`lib/presentation/pages/home/widgets/encouragement_text.dart:9-18` 纯文字 "坚持 X 天"
- **问题**:milestone(7/30/100 天) 应该有视觉高亮(emil: rare 频度,值得 delight)
- **修法**:
  ```dart
  // streak == 7/30/100 时给 chip 加金色边框 + 一次微弱高亮
  if (streak == 7 || streak == 30 || streak == 100) {
    return Container(decoration: BoxDecoration(border: Border.all(color: warning, width: 2)))
  }
  ```
- **工作量**:1 小时

---

## P3 — nice-to-have (6 项)

#### P3-1 树洞录音波形图(显示录音音量峰值)

- **位置**:`lib/presentation/pages/vent/vent_compose_page.dart` 录音时无波形反馈
- **修法**:`record` 包有 amplitude stream → 自定义 CustomPainter 画 5-10 个音量条
- **工作量**:3-4 小时(自绘 + amplitude 监听)

#### P3-2 主页 streak 数字 tween 改 HSL 色彩渐变(鼓励文)

- **位置**:`encouragement_text.dart`
- **修法**:streak 0-7 灰、7-30 绿、30-100 金、100+ 彩虹
- **工作量**:1.5 小时(色彩 token + 数字 tween)

#### P3-3 全局 theme transition 切换 dark/light 时淡入

- **位置**:`lib/core/theme/theme_provider.dart` 切换 ThemeMode 直接 setState
- **修法**:`AnimatedTheme(duration: AppTokens.durSlow, child: ...)` 包整个 MaterialApp
- **工作量**:30 分钟

#### P3-4 心理评估历史 sparkline 触摸 hover 显示 tooltip

- **位置**:`lib/presentation/pages/assessment/assessment_page.dart` sparkline 是 fl_chart,无 hover
- **修法**:加 `LineTouchData(handleBuiltIndicators: ...)` 显示"日期 + 分数"
- **工作量**:2 小时

#### P3-5 设置页加"导出全部设置" / "导入设置" 备份

- **位置**:`lib/presentation/pages/settings/settings_page.dart` 当前只导 data,不导 settings
- **修法**:扩 `dataExportService` 支持 settings 导出
- **工作量**:4 小时(大)

#### P3-6 加 1 个 "今天的目标" widget 在主页(打卡 / 评估 / 情绪 3 件套)

- **位置**:`lib/presentation/pages/home/widgets/` 新增
- **修法**:3 个 dot + 文字,完成态变 ✓,emil delight 频度
- **工作量**:3 小时(新 widget + 3 个数据源)

---

## 优先级实施建议

### 必须做(P0 全 8 项,共 ~15-19 小时)
1. **P0-3 reduce-motion** 1.5-2h(最严重 a11y,精神心理患者核心)
2. **P0-5 + P0-6 dark mode** 4-6h(用户已开 dark mode 视觉崩)
3. **P0-1 PressFeedback** 3-4h(emil 框架最基础)
4. **P0-2 EmptyState 迁移** 2-3h
5. **P0-4 HomePage SnackBar 集中** 1-1.5h
6. **P0-7 CircularProgressIndicator 统一** 0.5h(快)
7. **P0-8 HapticFeedback 扩 5 类** 1.5-2h(老年/视障用户)

### 1 个月内(P1 选 5-7 项,~10-15 小时)
- **P1-1, P1-2, P1-3, P1-4**(动效 token 化全做,~2.5h)
- **P1-5, P1-6, P1-7**(empty/loading/error 状态全做,~4h)
- **P1-8**(route transition Motion 包装,~0.25h)
- **P1-13**(SnackBar action 按钮,~2-3h)
- 选 **P1-10** 主页 badge(2-3h) 或 **P1-14** pull-to-refresh(1.5h)

### 2-3 个月内(P2 全 12 项 + P3 选 2-3 项,~15-20 小时)
- 按时间预算挑,优先 P2-1, P2-2(token 完整化)
- P2-10 streak 初始值 bug(30min 修,体感立刻好)
- P3-3 主题切换淡入(30min 立刻有感)

### 不做(P3 大项,~10h+)
- P3-1 录音波形,P3-5 设置备份,P3-6 今日目标 — 涉及新功能 / 大改,留 v1.0 之后

---

## emil 决策框架覆盖度总览

| 频度 | 期望 widget | 实际覆盖 | 缺口 |
|---|---|---|---|
| 100+/day (打卡按钮) | 几乎无动画 / PressFeedback | ❌ CheckInButton 有 AnimatedContainer,无 PressFeedback | P0-1, P0-3 |
| tens/day (列表项 tap) | 微弱反馈(ripple + 选 scale) | ❌ 全用 ListTile 默认 ripple,无 scale | P0-1, P1-15 |
| occasional (dialog / sheet / snackbar) | 标准 durNormal + curveStandard | ⚠️ 路由切换 / SnackBar / Dialog 用了 token 但**有 reduce-motion 漏** | P0-3, P1-8 |
| rare (庆祝 / onboarding / 删除) | 可加 delight(elasticOut) | ⚠️ celebration_overlay 已用 elastic,但 onboarding / milestone 视觉 0 处 | P2-12, P1-11, P1-12 |

**总评**:动效 token 化 + 频度决策框架**架构层已完整**(`MotionScheme` + `Motion.duration` + `AppTokens.curve*` + `AppTokens.dur*`),但**应用层覆盖度 ~40%**。补完 P0-3 + P0-1 + P0-2 即可达 80%。

---

## 改动文件预算 (P0 全做)

- 5 个新 helper 扩 AppSnackBar / Feedback / StaggeredFadeIn / SnackBarDuration enum
- 30+ widget 改 dark mode (P0-5/6)
- 14 处替换 CircularProgressIndicator → LoadingSpinner (P0-7)
- 5 处加 reduce-motion (P0-3)
- 9 处迁移 EmptyState (P0-2)
- 7 处 HomePage SnackBar → AppSnackBar (P0-4)
- 50+ 处 PressFeedback 包裹 (P0-1)
- 4-5 个 ARB 新 key (P1-5/7/16)
- 5 个新 widgets 抽公共组件 (P1-3, P1-7, P1-10, P2-7, P2-12)

**总计**:~15-19 小时单人工作量,建议拆 3 个 round (P0 / P1-动效 / P1-状态 + P2),每个 round 跑 `flutter analyze + test` 后 commit。
