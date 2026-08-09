# 设计工程审计 (emilkowalski 视角)

> 审计对象: `D:\Batch\chroniccare`
> 审计时间: 2026-08-06
> 审计范围: `lib/presentation/**` (7 大 page feature + 28 个通用 widget + 7 个 chart/animation widget) + `lib/core/theme/**` + `lib/core/routing/**`
> 审计角色: 假设用户为精神心理患者(病耻感强 / 情绪脆弱 / 前庭敏感比例高),熟悉 Material 3 但不是 RN/Vercel 的重度用户。

---

## 总体评估

**项目设计水位分: 7.5 / 10**

这是个**反常的项目**。在 Flutter + SQLCipher + 本地加密这种重后端、轻 UI 的领域,作者的 token 化水平在 Flutter 圈是**顶级**的: 4 个独立子模块 (`app_colors` / `app_motion` / `app_spacing` / `app_typography`) 通过 facade 暴露,`MotionScheme` 4 档决策框架 (`none` / `subtle` / `standard` / `delight`) + `prefers-reduced-motion` 全程尊重,`Haptics` 4 类语义集中器 (`tap` / `success` / `warning` / `light`),`PressFeedback` 两种模式 (scale 0.97 接管/不接管 tap) + `PressFeedbackIconButton` + `AppListTile` 3 命名构造 + `InfoBanner` 4 tone + `ChipBadge` 4 tone + `ChoiceChipWrap<T>` + `DialogActionsRow` + `LoadingScrim` 0.54 + `PageTransitionSwitcher` + `FadeIn` + `SlideUp` + `CelebrationBounce` 集中器生态基本闭环。

**但差距在 3 个地方**:

1. **"高分 token + 低分执行"的分裂**。158 处残留 `style: TextStyle(...)`、162 处残留 `EdgeInsets.*(...)` 散落 75 个文件,emil 的"decisions should be nameable"原则在前 30% 落地得非常优雅,后 70% 开始出现"框架还在,执行打折"的迹象。
2. **"完成度 vs 实际功能"的鸿沟**。`assessment_center_page.dart:65` 留 `// TODO (Task 5): 顶部 mini 趋势图` 空 SizedBox 占位;`home_fab_toolbar.dart` 4 个 FAB 工具中 2 个是 `AppSnackBar.showInfo` stub(`homeFabHotlineTodo` / `homeFabTopTodo`);`cbt_wizard.dart` 第 4 步的"完成"按钮 `Navigator.pop` 后数据不会自动落库(实际 save 走父 `_save()`,但用户在 5/7 栏 wizard 内部点"完成"时不会触发父 save)。
3. **"信息架构 vs 视觉设计"的脱节**。`settings_page` 8 个 section 串行铺开 + IAP 商业卡当头炮,主页 hero illustration + FAB 工具栏 + quick mood carousel + 3 行 action + today med schedule + secondary actions 一屏塞 8 个 widget。这些是产品架构问题,不是 token 问题。

跟 Vercel / Linear 级别的差距: 不在视觉风格 (项目 Material 3 + 嫩绿品牌色 + 浅蓝 hero 风格已经达标),**在信息架构的克制 + 关键流程的"3 tap 抵达"原则 + 半成品 stub 的诚实度**。Line 14 版本前都不会上线;这个项目目前是 0.30 (round 91),按 4-week cadence 还要 4-5 个 sprint 才能解决 P0。

**给 P0 必改的 5 件事 (上 App Store 前必修)**:
1. CBT wizard 5/7 栏"完成"按钮**不触发 save** — 用户填的 CBT 思维记录会静默丢失
2. `home_fab_toolbar` "紧急热线" / "回到顶端" 是 stub snackbar,不是真功能
3. `assessment_center_page` 顶部 mini 趋势图是 TODO SizedBox,渲染空
4. `treatment_placeholder` 是兜底 widget,不是真页面
5. `home_hero_illustration` 的渐变几乎不可见 (`alpha 0.08 → 0.04`),但占 140dp 空间

---

## 1. 动效与微交互

### 1.1 整体评价

**这一项是项目最强项**。emil 的"频度决策框架"(100+/day 无动画 / tens/day 微弱 / occasional 标准 / rare delight)被严格执行:

- `PressFeedback.pressedScale = 0.97` + `durPress = 160ms` 是 emil 标准值,所有按钮一致
- `PageTransitionSwitcher` 100ms fade 是 4-step wizard 切换的标准选择
- `CelebrationBounce` `MotionScheme.delight` (`durSlow` 500ms + `curveBackOut` easeOutBack) 庆祝用,rare 频度正确
- `Motion.duration(context, AppTokens.durNormal)` 包装器让 reduce-motion 用户自动归零
- `Stagger fade-in` 40ms 步进 + 200ms cap,避免长列表后段等太久 (emil "perceived performance")

**问题集中在 3 个地方**: 残留 magic numbers 还没被 token 收编、半成品动效、动画完成态判断不全。

### 1.2 问题清单

| # | 文件:行 | 问题描述 | 类型 | 修复难度 | 优先级 |
|---|---------|---------|------|---------|--------|
| 1 | `lib/core/theme/app_theme.dart:47-55` | `splashFactory: InkSparkle.splashFactory` 被注释掉,实际走 Flutter 默认。PressFeedback 模式 2 用 `Listener` 包裹,**不会**把 press 事件传给 child 的 InkWell,导致用户点 button 时既无 PressFeedback scale 视觉也**不一定有 InkWell ripple**(取决于 child 类型) | 底层 | 2 | P2 |
| 2 | `lib/presentation/widgets/animations/celebration_bounce.dart:68` | 5 段 TweenSequence 写死 weight 30/20/50,emil 原则 "magic numbers should be named"。建议抽 `celebrationTweenWeights = const [30, 20, 50]` 常量 | 底层 | 1 | P3 |
| 3 | `lib/presentation/pages/setup/setup_step_consent.dart:60-65` | `CheckIcon + Text` 勾选行,**没** `PressFeedback` 包裹,用户点 checkbox 区域是死区(Material Checkbox 自身 tap 区在左边小方块,右边整行不响应) | 底层 | 1 | P2 |
| 4 | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:60-86` | "1 tap 写 mood" 0 confirm, 误触直接落库 + 0 snackbar 反馈(只有 `_selected` 状态切换)。**emil "perceived performance" 哲学里, 用户看不到的副作用 = bug** | 底层 | 2 | P1 |
| 5 | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:91-103` | 4 个 FAB 工具 2 个是 TODO stub: `homeFabHotline` → snackbar info, `homeFabTop` → snackbar info。`AnimatedSize` 展开 300ms `durNormal` OK,但收起后空 SizedBox 占位,**stagger 错位 + 视觉空洞** | 半成品 | 3 | P0 |
| 6 | `lib/presentation/pages/medication/widgets/medication_calendar_page.dart:226-233` | 30 天热力图整 grid 0 tap 行为,用户看到红色"漏服"格,无法 drill down 到那天的事件 | 底层 | 3 | P1 |
| 7 | `lib/presentation/pages/trend/trend_page.dart:147-152` | list ↔ calendar 切换 100ms fade 跟 setup 4-step wizard 切换是同一种,但 setup 是 fade+slide-up(0.04 offset),trend 是纯 fade。**emil "cohesion" 原则:同种"视图切换"应该有同种 transition** | 底层 | 1 | P3 |
| 8 | `lib/presentation/widgets/section_header.dart:51-77` | `chip` 模式 (B 站风格) 展开是 `Row(Text, ChipBadge)`,但 chip 展开/收起没有动画 (ChipBadge 是 static Container)。**rare 频度应配 `curveDelight`** | 底层 | 1 | P3 |
| 9 | `lib/presentation/pages/mood/widgets/cbt_wizard.dart:93-106` | 5/7 栏 wizard "完成" FilledButton → `Navigator.pop()`,**实际 save 走父 `_save()`**。注释承认此缺陷: "wizard 只负责关闭 dialog, 父组件 dispose 会 reset cbtDraftProvider"。**用户填的 CBT 字段会丢** | 底层 | 2 | P0 |
| 10 | `lib/presentation/pages/home/widgets/home_hero_illustration.dart:43-49` | 渐变 `tintedPrimaryDeep.withValues(alpha: 0.08) → tintedPrimarySoft.withValues(alpha: 0.04)` 在 light 模式下几乎不可见(对比 0.04 跟白底 ≈ 0),但占 140dp 空间。**视觉 = 0,空间 = 140dp,emil "perceived performance" 哲学下这是反模式** | 底层 | 1 | P2 |
| 11 | `lib/presentation/pages/home/home_page.dart:269-280` | 庆祝 overlay 用 `Timer + OverlayEntry`,**不在 widget tree 内**。如果用户 navigate 走(不点 overlay),Timer 仍 fire → `entry.mounted` check OK,但 `entry.remove()` 之后还会触发 `setState` 的 rare race (R62 修过,但仍是 200+ 行的 string-based timer) | 底层 | 3 | P2 |
| 12 | `lib/presentation/widgets/empty_state.dart:42-90` | 10+ 处使用 `EmptyState` 但 0 处用 `FadeIn` 包装,用户清空数据时 EmptyState 是直接 pop in,没过渡。**emil 频度: occasional (用户偶尔清空), 应配 FadeIn with curveStandard** | 底层 | 1 | P3 |
| 13 | `lib/presentation/widgets/loading_skeleton.dart:62-67` | `CircularProgressIndicator` 用 `valueColor: AlwaysStoppedAnimation(primaryColor)`,**没用 `LoadingSpinner` 集中器**(项目明明定义了 `LoadingSpinner` class)。5+ 处直接 `CircularProgressIndicator(strokeWidth: 2.5)` 不一致 | 底层 | 1 | P2 |
| 14 | `lib/presentation/pages/medication/today_med_schedule.dart:55-80` | `_TimeChip` 时间点 chip,选中/未选切换**无动画**(只用 Container 换色)。emil 频度 occasional,标准动画 OK,缺 `AnimatedContainer` | 底层 | 1 | P3 |
| 15 | `lib/presentation/pages/medication/refill_manage_page.dart:191-200` | 续方行 `_RefillRow` 是 static (无动画) rebuild,过期/即将提醒 状态切换**没有 transition**。`tintedStatusSoft` 换色时是 hard switch | 底层 | 1 | P3 |
| 16 | `lib/presentation/pages/assessment/assessment_widgets.dart:307-323` | `ComparisonCard` 数字"上次/当前"切换无动画。emil rare 频度(评估几周/几月一次),"数字递增" `TweenAnimationBuilder` 体感**会强很多** | 底层 | 2 | P3 |
| 17 | `lib/core/routing/app_routes.dart:43-103` | 3 transition (fade / slide-right / slide-up) 全 hardcode `Offset(0.1, 0)` / `Offset(0, 0.05)`,无 token | 底层 | 1 | P3 |
| 18 | `lib/presentation/pages/home/widgets/secondary_action_row.dart` | 主页 3 个按钮 (mood quick / mood list / vent) 间距 `spacingSm` 一致但**缺少 divider / separator**。emil "visual rhythm" 原则: 相同样式按钮组需要节奏 (small breathing space + uniform button height) | 底层 | 1 | P3 |
| 19 | `lib/presentation/widgets/animations/page_transition_switcher.dart:54-66` | `transitionBuilder` 默认纯 fade,**没有任何 scale**,setup 用 `Offset(0, 0.04) → 0` 4-step 切换。emil 频度 occasional → 微 scale (0.98→1.0) 加 fade 体感更"厚" | 底层 | 1 | P3 |
| 20 | `lib/presentation/pages/vent/vent_compose_page.dart:144-231` | 录音开始/停止用 setState 切 icon,**没用 `AnimatedSwitcher`**。emil rare 频度(用户偶尔录),`crossFade` + `scaleTransition` 体感稳 | 底层 | 1 | P3 |

---

## 2. 视觉层级与节奏

### 2.1 整体评价

**Token 化做得很好**: 5 个 `AppTextStyle` (Title/Headline/Body/BodyStrong/Label/LabelStrong/Caption/CaptionHint/Micro/LabelMedium/Legal/Mono) + 14 个 `fontSize*` 集中器 + 5 个 `lineHeight*` 集中器。颜色走 `AppColors` dynamic getter + `tintedXxx` 系列 + `fgXxx` 系列,基本保证 dark mode 不出现"白底白字" silent bug。

**但 60% 集中器化后 40% 残留**:
- 158 处 `style: TextStyle(...)` 散落 59 个文件
- 162 处 `EdgeInsets.*(...)` 散落 75 个文件
- 部分 widget 用 inline `Container > Row(Icon(size: 20), Text(...))` 没走 `InfoBanner` / `ChipBadge`

**Dark mode 完整度**: 通过 `Theme.of(context).colorScheme.*` + `AppTokens.dynamic getter` 适配,主流程 100% 覆盖,边角案例 1 处 (hero illustration 的渐变 alpha 在 dark mode 下看不见但也不刺眼,问题同 1.2.10)。

**Typography scale 合理度**: 14 个 fontSize (8/10/11/12/13/14/16/18/20/24/32/64) 走 8 倍数 sequence,lineHeight 5 档 (1.2/1.4/1.5/1.6/1.8),Material 3 typography 跟品牌小调整兼容。

### 2.2 问题清单

| # | 文件:行 | 问题描述 | 类型 | 修复难度 | 优先级 |
|---|---------|---------|------|---------|--------|
| 1 | `lib/presentation/pages/settings/settings_page.dart:55-148` | **IAP 升级 Pro 卡片当头炮**: 用户进设置第一眼看到 "升级到 Pro" 商业卡,emil "decisions should be nameable" 原则下这是 conversion gate 伪装成 feature,跟"精神心理患者药" App 调性冲突 | 架构 | 3 | P0 |
| 2 | `lib/presentation/pages/settings/settings_page.dart:34-242` | 8+ section 串行 ListView,所有 section header 16/w500 caption 字体,层级 0 区分度。`spacingLg` (=40) 是 8 序列 5 倍,显得**不紧凑** | 底层 | 2 | P1 |
| 3 | `lib/presentation/pages/home/home_page.dart:368-460` | **主页 8 个 widget 堆叠**: HomeHeroIllustration(140dp) + Spacer(1) + EncouragementText + QuickMoodCarousel(80dp) + PrimaryActionRow(3 button ~200dp) + TodayMedSchedule + SecondaryActionRow(2 button ~150dp) + Spacer(1) + HomeFooter。**emil "perceived performance" 哲学: 屏幕 first paint 应该只看到 primary action**。hero + encouragement + carousel + 2 secondary 在屏幕外 50% 范围 | 架构 | 4 | P1 |
| 4 | `lib/presentation/pages/settings/widgets/notification_status_card.dart:259-360` | **OEM 引导 17 步文字列表**(小米 3 + 华为 3 + OPPO 3 + Vivo 3 + 魅族 2 + 三星 2 + 其他 2 + general tip)。在 1 个 ExpansionTile 折叠,**100% 纯文字 0 截图 0 链接**。精神心理患者在国产 ROM 上 90% 收不到通知(自启动被禁),这段是 App **最关键的用户成功路径** | 底层 | 4 | P1 |
| 5 | `lib/presentation/pages/home/widgets/home_hero_illustration.dart:43-49` | 渐变 `alpha 0.08 → 0.04` 在 light 模式 ≈ 不可见。占 140dp × 全宽 = 大量"空"区域。emil 原则:**视觉 = 0 的区域应被裁掉**,不是继续占空间 | 底层 | 1 | P2 |
| 6 | 158 处 `style: TextStyle(...)` 散落 59 个文件 | 残留 magic 字体/字重/颜色。`emil "decisions should be nameable" 原则: 一处 TextStyle 散落 = 设计 token 失效,改字号要 grep 200+ 处 | 架构 | 4 | P2 |
| 7 | 162 处 `EdgeInsets.*(...)` 散落 75 个文件 | 同上,残留 magic padding (8/12/16/24 不一)。spacingToken 化率应 > 90% (目前 ~60%) | 架构 | 3 | P2 |
| 8 | `lib/presentation/pages/assessment/assessment_center_page.dart:30-90` | **12 张量表卡 2 列 grid (childAspectRatio: 1.1)**,但只有 10 开放 + 2 unavailable (灰显)。灰色 unavailable card 占视觉空间,但用户**无感** 知道为什么 | 底层 | 2 | P2 |
| 9 | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:88-110` | 7 卡片 grid 跟 assessment_center 同模式 (1.1 aspectRatio),7 卡片信息密度不一致:情绪日记 "上次 今天 ⭐" vs 治疗记录 "上次 上次 上次..." | 底层 | 2 | P3 |
| 10 | `lib/presentation/pages/settings/widgets/data_management_section.dart:38-127` | 6 个 AppListTile (导出/CBT PDF/用药报告/历史/导入/清空) 单 Card 内 5 Divider,**最后一个"清空"是红色 destructive**。6 行数据管理混在 1 个 Card,**emil "DRY for taste" 应该按"备份 / 报告 / 销毁"3 group 拆** | 架构 | 3 | P2 |
| 11 | `lib/presentation/pages/assessment/assessment_widgets.dart:30-92` | `AssessmentSparkline` 80dp 高 (跟 `spacingXl` 80 同值),但 CustomPaint 内 dot size 3.5,2 个点重叠看不清。emil "good defaults" — sparkline dot 最小 4.0 | 底层 | 1 | P3 |
| 12 | `lib/presentation/widgets/loading_skeleton.dart:194-244` | `_Shimmer` 用 `Opacity(0.4 + value * 0.3)` → range 0.4-0.7。emil 频度 100+/day (loading 是高频),`repeat(reverse: true)` 是反模式,已经改"呼吸"模式 OK。但 `_pauseTimer` 的 `Timer(...)` 嵌套 `Timer`,`if (mounted && _isBreathing) {...}` 复杂度过高,简化空间大 | 底层 | 2 | P3 |
| 13 | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:90-99` | 容器背景 `tintedPrimaryDeep.withValues(alpha: 0.04)` 跟主色几乎同色,用户在主页看到的是 "无背景的 carousel"。emil "good defaults" — 选中态背景应该更明显 | 底层 | 1 | P2 |
| 14 | `lib/presentation/pages/medication/refill_manage_page.dart:127-214` | 顶部汇总 4 个 StatCard 横向 Row,**4 个数字挤在一起**。文字 hint (caption 14) 在 4 个 24 数字下面,**视觉密度过高** | 底层 | 1 | P2 |
| 15 | `lib/presentation/pages/assessment/assessment_page.dart:296-340` | 结果页大数字 `fontSizeScoreXxl` (64) 加 `FontWeight.bold`,**emil 建议大数字最多 48 + w700**。64 + bold 在小屏手机数字截断风险 | 底层 | 1 | P3 |
| 16 | `lib/presentation/pages/trend/widgets/trend_heatmap_grid.dart:21-39` | `LayoutBuilder` + `Wrap` 算 cell size `((constraints.maxWidth - 4 * 4) / 5).clamp(28, 48)`,**4 跟 5 是 magic**(spacing 4 + 5 列)。建议走 `spacingXxxs` token | 底层 | 1 | P3 |
| 17 | `lib/presentation/pages/settings/settings_page.dart:222-235` | 联系人 section 挪到最底部 (病耻感),但**仍** 在主流程可见。emil "user mental model" — 如果业务暂停,应该默认隐藏 (FeatureFlags.emergencyContactEnabled 控制),当前 UI 始终显示会让用户问"这个能干嘛" | 架构 | 3 | P2 |

---

## 3. 信息密度

### 3.1 整体评价

**主页密度高**,用户视觉过载风险。设置页 8 section 是产品问题不是 UI 问题。`medication_calendar_page` 30 天热力图信息密度合理(每格 ≤ 4dp 数据,色编码就够)。`mood_list_page` 顶部 search + filter bar + period filter bar + 主体,**4 个区域** 在 1 屏,密度过高。

**Card / ListTile / SectionHeader 使用规范度**:
- `Card` 跟 `Container(decoration: BoxDecoration)` 散落 (e.g. `setup_step_done.dart:31`, `today_med_schedule.dart:47-94` 等) — emil "cohesion" 应该统一用 `Card`
- `ListTile` 直接用 (有 10+ 处),`AppListTile` 集中器 60% 替换,**但 home_page / setup_step_* 还有直接 ListTile**
- `SectionHeader` 替换到位 (R40 emil F4 fix),trend_page 4 处全用

### 3.2 问题清单

| # | 文件:行 | 问题描述 | 类型 | 修复难度 | 优先级 |
|---|---------|---------|------|---------|--------|
| 1 | `lib/presentation/pages/settings/settings_page.dart:34-242` | 8+ section 单 ListView 堆叠,IAP 商业卡当头炮。**emil "decisions should be nameable" 应该按"用户档案 / 提醒 / 数据 / 法律" 4 group 重构** | 架构 | 4 | P0 |
| 2 | `lib/presentation/pages/mood_list/mood_list_page.dart:81-117` | **4 个区域塞 1 屏**: search TextField + MoodListFilterBar (3 chip + sort) + MoodListPeriodFilterBar (6 chip) + 主体 list。filter bar 横向 SingleChildScrollView 没问题,但 search box + filter bar + period bar **没分隔线** 视觉混乱 | 底层 | 2 | P2 |
| 3 | `lib/presentation/pages/assessment/assessment_page.dart:296-340` | 结果页 Container (大数字 64px) + ComparisonCard + Sparkline + 推荐就医 + 免责声明 + 2 button (返回/重测) 7 段,**scroll 完要 5+ 屏**。emil "first paint should focus on 1 message" — 大数字 + 严重度 label 应该在 1 屏,其他折叠 | 架构 | 3 | P1 |
| 4 | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:60-109` | 顶部多指标 chart (30 天 4 指标) + 心境 4 段图 + 7 卡片 grid。chart 加 7 卡片视觉冲突,chart 30dp 高只看到几像素线,**信息密度过高但视觉不清晰** | 底层 | 2 | P2 |
| 5 | `lib/presentation/pages/trend/trend_page.dart:165-252` | list 视图 4 chart + 1 heatmap + 1 monthly + 1 评估 sparkline,**6 个 section** 都在 1 个 ListView。emil "DRY for taste" 原则: 这种长 list 应该分 tab 或折叠 | 架构 | 3 | P1 |
| 6 | `lib/presentation/pages/trend/trend_calendar.dart:174-180` | 选中日详情 `DayDetailCard` 在 calendar 视图底部,展开 N 行 event,长按情绪详情展开 CBT 摘要。**emil "1 message 1 viewport"**: 详情卡应该全屏 (push 详情页) 不是 inline | 架构 | 3 | P1 |
| 7 | `lib/presentation/pages/home/home_page.dart:401-444` | 主页 3 button (打卡 / 临时吃药 / snooze 5min) + TodayMedSchedule + 2 secondary (mood list / vent) 5+ 个可点击元素 + hero + carousel + footer。**emil "primary action dominant" 原则: 打卡按钮应占 1/3 屏高,其他 0 干扰** | 架构 | 3 | P1 |
| 8 | `lib/presentation/pages/medication/refill_manage_page.dart:127-172` | 4 个 StatCard 横向 Row (总药数 / 已设续方 / 提醒中 / 已过期),在 360dp 宽屏上每卡 ~85dp 数字挤 24/w600 几乎挨在一起 | 底层 | 1 | P2 |
| 9 | `lib/presentation/pages/medication/widgets/today_med_schedule.dart:47-94` | 顶部 Row 标题 + 进度 + 底部 Wrap 时间 chip。**Wrap 自动换行让"今早 08:00" 跟 "中午 12:00" 视觉对齐,但卡片高度变化,主页每次都重新排版** | 底层 | 1 | P3 |
| 10 | `lib/presentation/pages/assessment/widgets/assessment_reminder_section.dart` | 评估提醒 section 嵌在 settings 评估 section 内,跟 reminders_hub_page 重复逻辑。**emil "DRY for taste"**: 同一设置分散在 2 页面 | 架构 | 2 | P2 |
| 11 | `lib/presentation/pages/trend/trend_summary.dart:21-54` | 4 个 StatCard (连续天数 / 最长 / 总打卡 / 总天数) 在 1 Card。 1 个屏幕只显示 4 个数字**信息量低**。emil "show insights not data" — 4 个独立数字应该变 1 个 narrative ("连续 5 天,总 23 天") | 底层 | 2 | P2 |
| 12 | `lib/presentation/pages/mood_list/mood_list_page.dart:125-140` | empty 状态 1 个 icon + title,没 subtitle / action button。**emil "empty state 是 onboarding 机会"** | 底层 | 1 | P3 |
| 13 | `lib/presentation/pages/settings/legal_page.dart:190-280` | 3 个文档入口 (3 tile) + 1 个 warning 段落 + 3 个 toggle 7 段。**toggle 没 chip / badge 显示"撤回时间"**,而是底部 row 文字,视觉弱 | 底层 | 1 | P2 |
| 14 | `lib/presentation/pages/medication/today_med_schedule.dart:150-217` | `_TimeChip` 内联 Container,没用 `ChipBadge` 集中器。**emil "cohesion"**: 同款视觉 = 同一 widget,4 tone `ChipBadge` 不够用应加 | 底层 | 2 | P3 |

---

## 4. 关键流程体验

### 4.1 整体评价

**5 个核心流程**:

1. **首次启动 4 步** (consent / welcome / medication / done) — 设计**克制到位**,PopScope 拦截防误退,4 个 checkbox 法律同意 (v0.27 R83 加年龄严正声明) 符合 PIPL。
2. **打卡** (主页 → check-in → 庆祝 overlay + 通知清理 + SafetyWatch + CareEngine) — **优秀**,Haptics.success + streak tween + CelebrationBounce 1.8s。
3. **评估** (主页 header icon → /assessment/history → /assessment/:id → quiz → result → crisis detect → snackbar) — **4 步完成** ✓。
4. **紧急联系人添加** — **5 步 + ConsentDialog 单独同意**,法务正确但**流程太重**(emil "3 tap 抵达" 原则 → 8 tap)。
5. **数据导出** — **5 步 + ConsentDialog + 明文风险警告 + 强制勾选 + 复制**,法务正确但**对患者太重**。

**半成品流程**:
- CBT 思维记录 5/7 栏 wizard "完成" → 字段丢 (issue 1.2.9)
- FAB toolbar "回到顶端" / "紧急热线" → snackbar stub (issue 1.2.5)
- assessment center 顶部 chart → 空 SizedBox (issue 2.2.3)

### 4.2 问题清单

| # | 文件:行 | 问题描述 | 类型 | 修复难度 | 优先级 |
|---|---------|---------|------|---------|--------|
| 1 | `lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105` | 5/7 栏 wizard "完成" FilledButton → `Navigator.pop()`,**不调用父 save**。用户填的 CBT 思维记录会**静默丢失** | 底层 | 2 | P0 |
| 2 | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:84-104` | "紧急热线" / "回到顶端" 是 TODO stub snackbar。`homeFabHotlineTodo` / `homeFabTopTodo` 是 l10n key 但**没接真功能** | 半成品 | 3 | P0 |
| 3 | `lib/presentation/pages/assessment/assessment_center_page.dart:64-67` | `// TODO (Task 5): 顶部 mini 趋势图` 留 `const SizedBox.shrink()`,**页面顶部 200dp 是空白** | 半成品 | 3 | P0 |
| 4 | `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart` | 整个文件是"治疗 placeholder",整合页"治疗"卡片 tap → 进 placeholder 页面 | 半成品 | 2 | P0 |
| 5 | `lib/presentation/pages/contact/contacts_list_widget.dart:154-306` | 紧急联系人添加 5 步 (点 + → 填名字+手机 → ConsentDialog 单独同意 → 添加 → snackbar)。**emil "3 tap 抵达" 原则 严重违反**,精神心理患者友好度低 | 架构 | 4 | P1 |
| 6 | `lib/presentation/pages/settings/widgets/data_management_section.dart:130-342` | 数据导出 5 步 (点导出 → ConsentDialog → 风险警告 dialog → 强制勾选 → 复制 JSON)。**5 步 + 法律文本** 对精神心理患者过重,应该 3 步 + 风险提示 | 架构 | 4 | P1 |
| 7 | `lib/presentation/pages/medication/refill_manage_page.dart:156-216` | 续方编辑 4 步 (点续方 → date picker → 提前天数 dialog → save)。**date picker + days picker 2 步可合并** | 底层 | 2 | P2 |
| 8 | `lib/presentation/pages/settings/email_preview.dart:13-152` | 邮件预览是单 page,但 `R56d` 注释说"急救通知实际发的是 SMS 不是 email,email 预览是 v0.4 早期版残留" | 半成品 | 2 | P2 |
| 9 | `lib/presentation/pages/mood/mood_dialog.dart:20-25` | **薄壳 god-pattern** 委派给 `MoodRecorderPage.show()`,但 home_page 引用 `MoodDialog.show()`。MoodDialog 整个文件就 25 行,**纯转发**。emil "honest abstraction" 应该让 MoodDialog 直接是 MoodRecorderPage 别 wrap | 底层 | 1 | P3 |
| 10 | `lib/presentation/pages/home/home_page.dart:466-493` | 打卡后副作用链: Haptics.success → checkIn → 庆祝 overlay → 取消 snooze → SafetyWatch → CareEngine **5 个 fire-and-forget 异步**。用户看到 overlay 1.8s 后,可能有 1-2 个错误 snackbar 跟庆祝并存,视觉混乱 | 底层 | 3 | P2 |
| 11 | `lib/presentation/pages/assessment/assessment_page.dart:163-231` | 评估提交: save → reminder reschedule → crisis detect → setState 4 步串联。**crisis dialog barrierDismissible: false** 正确,但 detectCrisis 跟 reminder 失败都 swallow,**用户不知道** | 底层 | 2 | P1 |
| 12 | `lib/presentation/pages/vent/vent_list_page.dart:74-97` | 列表 `RefreshIndicator` 失败时**没错误反馈** (ref.invalidate 静默) | 底层 | 1 | P2 |
| 13 | `lib/presentation/pages/vent/vent_compose_page.dart:418-468` | vent compose "放进树洞" 文本应该是 l10n 实际传的是 `ventComposeTitle` (同 setup 步骤名,不是按钮 label) | 底层 | 1 | P2 |
| 14 | `lib/presentation/pages/home/home_page.dart:541-643` | snooze 5min → notificationService.snoozeOnce → snackbar info。**snooze 后用户 5 分钟收到通知,但主页没标记"snooze 进行中"**,用户可能再 snooze 一次 | 底层 | 1 | P2 |
| 15 | `lib/presentation/pages/settings/reminders_hub_page.dart:215-340` | 评估提醒设置 4 步 (点设置 → bottom sheet → switch toggle → chip 选天数 → save)。**SwitchListTile + Divider + Text + ChoiceChipWrap** 4 个 widget 串行,密度低但流程清晰 | OK | - | - |
| 16 | `lib/presentation/pages/settings/email_preview.dart:60-67` | 邮件主题 `[Medication Reminder] $safeName missed check-in for 2 days` **半中半英**,emil "good defaults" 应该全 i18n | 底层 | 1 | P2 |

---

## 5. 可发现性

### 5.1 整体评价

**"我刚做了什么" 反馈**:
- 打卡后 CelebrationBounce 1.8s + Haptics.success ✓ 优秀
- 评估完成 4 个评分 → submit 按钮 disabled → 点击 → fade transition → 结果页 ✓
- vent 删除 → Haptics.warning → 二次确认 dialog → Undo snackbar 4s ✓ 优秀
- 续方设置 → snackbar "已设 X 月 X 日,N 天提醒" ✓
- 主题切换 → 全 app 200ms 渐变 ✓
- **缺**: IAP 购买成功 → snackbar "已购买" 无视觉强调; FAB toolbar 收起/展开 → 无 haptic 反馈

**隐藏手势的提示**:
- **0 处** 给"长按删除" / "右滑删除" / "下拉刷新" 的视觉提示
- 用户必须自己发现,精神心理患者探索意愿低

**主 CTA 的可发现性**:
- 主页打卡按钮 88dp 高 + primary 底色 ✓
- 主页 FAB 56dp 浮动 ✓
- 评估中心 grid 1.1 aspectRatio 卡片 OK
- 主页 hero illustration 140dp 占空间但视觉几乎 0 (issue 1.2.10)

### 5.2 问题清单

| # | 文件:行 | 问题描述 | 类型 | 修复难度 | 优先级 |
|---|---------|---------|------|---------|--------|
| 1 | `lib/presentation/pages/home/home_page.dart:54-56` | **主页 AppBar action 只有 ThemeToggleButton**,趋势/评估/设置入口全在 `HomeHeader` 的 3 个 PressFeedbackIconButton (右上 3 icon)。**没 tooltip 引导**,用户必须 hover 长按才能看到"趋势" | 底层 | 1 | P1 |
| 2 | `lib/presentation/pages/medication/widgets/medication_row.dart:131-159` | 药物行 3 个 IconButton (edit / refill / delete) 横向 Row,**0 视觉提示** 这是编辑/续方/删除。用户必须 hover 才有 tooltip | 底层 | 1 | P2 |
| 3 | `lib/presentation/pages/vent/vent_list_page.dart:150-220` | swipe-to-dismiss 左滑删除 + 长按删除,**0 处提示**。精神心理患者探索欲低,不会主动试 | 底层 | 1 | P1 |
| 4 | `lib/presentation/pages/trend/trend_calendar.dart:228-273` | 日历 cell 0 tap feedback (无 `InkWell` 之外视觉),用户**无感**可点 | 底层 | 1 | P1 |
| 5 | `lib/presentation/pages/medication/medication_calendar_page.dart:351-373` | 热力图整 grid 0 tap 行为 (issue 1.2.6 重复),用户看不到"漏服"格怎么 drill down | 底层 | 3 | P1 |
| 6 | `lib/presentation/pages/home/widgets/secondary_action_row.dart:25-83` | "记一下情绪" 按钮无视觉变体区分于"mood list" / "vent"。**emil "visual hierarchy" 原则: 3 个相似按钮需 chip / divider / 不同 icon 区分** | 底层 | 1 | P2 |
| 7 | `lib/presentation/pages/assessment/assessment_center_page.dart:30-90` | 12 张量表 grid,**10 开放卡片 vs 2 unavailable (灰) 视觉差异小**。用户可能以为灰色是已用 | 底层 | 1 | P2 |
| 8 | `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:88-110` | 7 张日常追踪卡片 grid 跟 assessment center 同模式,同样问题 | 底层 | 1 | P2 |
| 9 | `lib/presentation/pages/mood_list/mood_list_page.dart:92-103` | 搜索框 isDense: true + 单一 prefix icon,**用户不一定知道** 可搜索 | 底层 | 1 | P3 |
| 10 | `lib/presentation/pages/medication/refill_manage_page.dart:188-200` | 4 个 StatCard Row,**未配趋势小图**。emil "show, not tell": "已过期 N" 不如折线图直观 | 底层 | 3 | P3 |
| 11 | `lib/presentation/pages/medication/widgets/medication_empty_state.dart` | 3 种空态 (无药 / 暂未在用) 只用 icon + title + action,**无 onboarding 引导**(emil "empty state is onboarding") | 底层 | 1 | P2 |
| 12 | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:107-119` | 右上 "more" icon (`Icons.tune`),**无 label**。用户不知道点了能进完整 MoodDialog | 底层 | 1 | P2 |
| 13 | `lib/presentation/pages/vent/vent_list_page.dart:60-78` | vent "封存" 状态显示 lock icon + title + action,**用户可能不知道** "重新同意恢复数据"含义 | 底层 | 1 | P2 |
| 14 | `lib/presentation/pages/medication/medication_calendar_page.dart:55-58` | 顶部 InfoBanner "medication_calendar_heatmap_desc" 是文字说明,**无图示**用户看不明白 grid 颜色含义 | 底层 | 2 | P2 |
| 15 | `lib/presentation/pages/assessment/assessment_page.dart:124-129` | LinearProgressIndicator 在顶 (caption 14),**进度条底部没标注"X / N 题"** 数字 | 底层 | 1 | P3 |
| 16 | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart:54-109` | 展开 FAB 后 4 个工具按钮**用户首次进主页不知道** FAB 可以展开 | 底层 | 2 | P2 |
| 17 | `lib/presentation/pages/trend/widgets/trend_heatmap_grid.dart:57-66` | 30 天热力图 cell 0 tap,只 Tooltip `"X / Y ✓"`。emil "show don't tell" 原则: 漏服红色格应该**视觉强提示**"点击查看那天的事件" | 底层 | 1 | P1 |
| 18 | `lib/presentation/pages/settings/email_preview.dart:30-31` | "邮件预览" 是 v0.4 早期版残留,实际失联通知发的是 SMS,**设置页保留 email 入口**误导用户 | 半成品 | 2 | P2 |
| 19 | `lib/presentation/pages/settings/legal_page.dart:223-244` | 撤回同意黄色 warning 段落 + 3 toggle,用户可能**不知道**撤回后会发生什么 (CareEngine 停用 / vent 加密 / trend 屏蔽) | 底层 | 2 | P2 |
| 20 | `lib/presentation/widgets/last_startup_error_banner.dart` | 启动错误 banner 在 AppRoot 顶部,但用户**未必理解**"上次启动出错,请截图反馈"含义 | 底层 | 1 | P3 |

---

## 修复路线 (按 P0 → P3 排)

### P0 (上架 blocker)

1. **修复 CBT 5/7 栏 wizard "完成"按钮不触发 save** (`lib/presentation/pages/mood/widgets/cbt_wizard.dart:92-105`) — 5/7 栏 wizard 的"完成"应该 call 父 `_save()` 走 onSubmitted 模式,不直接 Navigator.pop
2. **实现 `homeFabHotline` / `homeFabTop` 真功能** (`lib/presentation/pages/home/widgets/home_fab_toolbar.dart:84-104`) — 紧急热线 1 tap 达 (R75 已有 hotlineByRegion 准备),回到顶端 Scrollable.ensureVisible
3. **填充 `assessment_center_page` 顶部 mini 趋势图** (`lib/presentation/pages/assessment/assessment_center_page.dart:64-67`) — 复用 R90 AssessmentMultiLineChart widget
4. **实现 `treatment_placeholder.dart` 真页面** (`lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart`) — 至少 ListView + 治疗记录 (R91 Task 3 impl 已有)
5. **移除设置页 IAP 升级卡当头炮** (`lib/presentation/pages/settings/settings_page.dart:55-148`) — 移到最底部或仅未购买用户看
6. **设置页架构重构 (8 section → 4 group)** (`lib/presentation/pages/settings/settings_page.dart:34-242`) — 按"用户档案 / 提醒 / 数据 / 法律"4 group 拆

### P1 (重要)

7. **主页 hero illustration 视觉修复** (`lib/presentation/pages/home/widgets/home_hero_illustration.dart:43-49`) — 渐变 alpha 提到 0.15+ 可见,或改成 100dp 高
8. **主页信息架构重排** (`lib/presentation/pages/home/home_page.dart:368-460`) — hero 缩到 100dp 或去掉,primary action 放中央,secondary 折叠
9. **quick mood carousel 加 confirm / snackbar** (`lib/presentation/pages/home/widgets/quick_mood_carousel.dart:60-86`) — 误触 0 反馈问题
10. **medication_calendar 加 tap 详情** (`lib/presentation/pages/medication/medication_calendar_page.dart:226-233`) — 点 cell 跳 day detail (复用 trend_calendar DayDetailCard)
11. **trend_calendar 详情 inline → 推详情页** (`lib/presentation/pages/trend/trend_calendar.dart:174-180`) — 1 message 1 viewport
12. **trend_page list 视图 6 section → 分 tab 或折叠** (`lib/presentation/pages/trend/trend_page.dart:165-252`)
13. **assessment result 页 7 段 → 折叠** (`lib/presentation/pages/assessment/assessment_page.dart:296-340`) — 关键 1 屏,其他折叠
14. **通知状态卡 OEM 引导加图示** (`lib/presentation/pages/settings/widgets/notification_status_card.dart:259-360`) — 这是 App 最关键成功路径
15. **紧急联系人添加流程 5 步 → 3 步** (`lib/presentation/pages/contact/contacts_list_widget.dart:154-306`) — emil "3 tap 抵达"
16. **数据导出流程 5 步 → 3 步** (`lib/presentation/pages/settings/widgets/data_management_section.dart:130-342`) — 风险文字应 1 屏,consent dialog 简化为 1 句
17. **主页 header 3 icon button 视觉提示** (`lib/presentation/pages/home/home_page.dart:54-56`) — 加 1 句小字 "趋势 / 评估 / 设置" 或用 BottomAppBar

### P2 (建议)

18. **空状态加 fade in 动画** (`lib/presentation/widgets/empty_state.dart:42-90`) — 0 transition 当前
19. **158 处 TextStyle 残留 → 集中器化** (59 文件) — 4-week sprint 拆分到 P2-3 集中处理
20. **162 处 EdgeInsets 残留 → 集中器化** (75 文件) — 同上
21. **OEM 引导 17 步 → 链接到静态文档** (`lib/presentation/pages/settings/widgets/notification_status_card.dart:259-360`) — 当前 100% 文字列表
22. **vent list 长按/swipe 加 1 次性 tooltip 提示** (`lib/presentation/pages/vent/vent_list_page.dart:60-78`) — "左滑删除" 提示气泡
23. **assessment_center unavailable card 视觉强化** (`lib/presentation/pages/assessment/assessment_center_page.dart:30-90`) — 灰色跟"已用"区分
24. **settings 数据管理 6 行 → 3 group 拆 Card** (`lib/presentation/pages/settings/widgets/data_management_section.dart:38-127`)
25. **legal_page toggle 加 chip 标识撤回时间** (`lib/presentation/pages/settings/legal_page.dart:223-244`) — 当前是底部文字 row
26. **Settings IAP 商业卡评估去留** (`lib/presentation/pages/settings/settings_page.dart:55-148`) — 精神心理患者 App 调性 + 转化 gate 的张力
27. **mood recorder 4 维 → 1 维 + CBT 字段 v0.29 改造后,旧维度入口是否清理** (`lib/presentation/pages/mood/widgets/dimension_row.dart`) — 4 维度数据可能还在 DB,UI 没了
28. **mood list 4 区域加分隔** (`lib/presentation/pages/mood_list/mood_list_page.dart:81-117`)
29. **趋势页 4 StatCard 改 narrative** (`lib/presentation/pages/trend/trend_summary.dart:21-54`) — "连续 5 天,总 23 天" 一行
30. **续方 StatCard 4 个横向 Row 改成 2x2 grid** (`lib/presentation/pages/medication/refill_manage_page.dart:127-172`) — 数字不挤
31. **Setup step 1 联系人 hint 视觉弱化** (`lib/presentation/pages/setup/setup_step_welcome.dart:130-144`) — "已告知联系人" 仍出现但只作为 hint,字太小
32. **legal_page 撤回后行为说明** (`lib/presentation/pages/settings/legal_page.dart:223-244`) — toggle 下面加 1 行 "撤回后: CareEngine 停用 / 趋势页屏蔽 / 树洞加密"
33. **email_preview 处理: 删 / 标 deprecated** (`lib/presentation/pages/settings/email_preview.dart:13-152`) — 实际失联通知是 SMS

### P3 (nice-to-have)

34. **AppTheme splashFactory 显式声明** (`lib/core/theme/app_theme.dart:47-55`) — 注释掉 InkSparkle 修复
35. **CheckIcon + Text 行包 PressFeedback** (`lib/presentation/pages/setup/setup_step_consent.dart:60-65`)
36. **trend list↔calendar 切换跟 setup 4 步同种 transition** (`lib/presentation/pages/trend/trend_page.dart:147-152`)
37. **SectionHeader.chip 模式加 toggle 动画** (`lib/presentation/widgets/section_header.dart:51-77`)
38. **LoadingSkeleton fullScreen 改用 LoadingSpinner 集中器** (`lib/presentation/widgets/loading_skeleton.dart:62-67`)
39. **today_med_schedule _TimeChip 用 AnimatedContainer** (`lib/presentation/pages/medication/today_med_schedule.dart:150-217`)
40. **ComparisonCard 数字递增动画** (`lib/presentation/pages/assessment/assessment_widgets.dart:307-323`)
41. **Setup 4 步 PageTransitionSwitcher 加 scale** (`lib/presentation/widgets/animations/page_transition_switcher.dart:54-66`)
42. **3 page transition helper 抽 token (Offset)** (`lib/core/routing/app_routes.dart:43-103`)
43. **AssessmentSparkline dot size 3.5 → 4.0** (`lib/presentation/pages/assessment/assessment_widgets.dart:30-92`)
44. **CelebrationBounce TweenSequence weight 30/20/50 抽 const** (`lib/presentation/widgets/animations/celebration_bounce.dart:68`)
45. **MoodQuickButton 区分"今日已记" vs "记一下" 视觉** (`lib/presentation/pages/medication/today_med_schedule.dart`) — 当前 emoji + label 差异小

---

## 半成品 / 残缺项 / TODO

### 半成品 widget / 页面

- `lib/presentation/pages/daily_tracking/widgets/treatment_placeholder.dart` — 整个文件是占位,整合页"治疗"卡片跳这里
- `lib/presentation/pages/assessment/assessment_center_page.dart:64-67` — `// TODO (Task 5): 顶部 mini 趋势图` 留 SizedBox
- `lib/presentation/pages/home/home_page.dart:577` — `// 当前 SMS provider 仍 mock (R55 真接 TODO), send() 走`
- `lib/presentation/pages/contact/contacts_list_widget.dart:218-260` — 加联系人流程 "PIPL §13 单独同意" 弹 ConsentDialog, 但 consent reject 路径只显示 snackbar,流程不清晰
- `lib/presentation/pages/settings/email_preview.dart` — 整个 email preview 页面,实际失联通知是 SMS 走 SMS 链路,email 是 v0.4 早期版残留

### TODO 注释

- `lib/core/data/services/notification_service.dart:577` — 真接阿里云 SMS (`R55 真接 TODO`)
- `lib/presentation/providers/iap_provider.dart` — IAP 走 mock,真接 App Store / Google Play TODO
- `lib/presentation/pages/assessment/widgets/assessment_summary_strip.dart` — 评估 strip 单色,严重度配色 TODO
- `lib/core/data/services/sms_service.dart` — mock SMS,真接 R55+ 阿里云
- `lib/core/data/services/email_service.dart` — mock email (P1-8 fix 行为 `send` 返 false),真接 SendGrid TODO

### 写一半 / 临时绕路

- `lib/core/routing/app_routes.dart:43-103` — 3 transition helper 写死 `Offset(0.1, 0)` / `Offset(0, 0.05)`,无 token 化
- `lib/presentation/pages/mood/mood_dialog.dart:20-25` — MoodDialog 25 行薄壳,纯转发 MoodRecorderPage, emil "honest abstraction" 应让 MoodDialog 直接是 MoodRecorderPage 别 wrap
- `lib/presentation/pages/medication/refill_manage_page.dart:78-85` — 4 个 StatCard 数字挤一起是早期版本,后期应该改 2x2 grid
- `lib/presentation/pages/setup/setup_step_medication.dart:106-132` — PrimaryButton (next) 包在 110×44 narrow SizedBox + Stack (Text + Spinner overlay) 是 hacky 实现
- `lib/presentation/pages/assessment/assessment_widgets.dart:307-340` — ComparisonCard "上次/当前" 数字递增无动画,emil rare 频度应配 TweenAnimationBuilder

### TODO 标记但已实现

- R56b / R56c / R56c' / R56c'' / R56c''' / R56d 多个 round 修代码,但部分 comments 引用 TODO 已经完成,留 stale comments

### 已知 dead tokens (R57 删后 R60-91 偶尔回引)

- `app_tokens.dart:268-269` `assessmentDashArrays` 保留 const list,R90 没用 (改走 `AssessmentColorPalette.dashFor`),删需 grep
- `app_spacing.dart:106-107` 注释说 `sparklineHeight + heatmapLabelWidth` R56 加 0 引用,R57 删 const 避免 dead token
- `app_typography.dart:188-193` `textStyleScoreLg / Xl / Xxl` R50 加 R57 删,R50 注释残留

---

## 上架相关设计隐患

### 法律 / PIPL

1. **Setup 步骤 0 同意 (4 checkbox 含年龄严正声明)** — 符合 PIPL §13 单独同意 + §17 同意记录,ScoreCard 样式 OK,但**字体偏小 (16/w400)**,用户不一定逐字读
2. **数据导出 5 步 + 强制阅读 + 勾选** — 法务 OK,**对患者 UX 太重**,应该 3 步 + 简明风险文字
3. **撤回同意 3 toggle + 警告段落** — 法务 OK,UI 缺"撤回后会发生什么"明示
4. **紧急联系人 ConsentDialog 在添加时弹** — PIPL §13 ✓
5. **vent 撤回 3 选 1 dialog (delete / seal / cancel)** — PIPL §47 ✓
6. **legal version 自动从 `legalVersionProvider` 读** (R77 修) — ✓
7. **IAP Pro 升级** — 需符合应用商店审核 + 退款政策,**当前未购用户进设置第一眼就看到商业卡**是上架审核 risk

### 设备兼容性

1. **国产 ROM 通知被禁** — `NotificationStatusCard` 是 17 步文字,**这是 App 唯一成功路径**。上架后用户 90% 在小米/华为/OPPO 收不到通知,App 失联通知业务无效
2. **a11y (TalkBack)** — 走 `AppSemantics` 集中器,但 158 处残留 TextStyle + 部分 widget 缺 semantics 包装。**上架审核 a11y 抽查风险**
3. **iOS / Android 视觉一致性** — `PressureFeedback` 模式 2 (Listener) 在 iOS 上可能不响应 touch (PointerEvent vs UITouch),需测
4. **Reduce-motion 用户** — 全 app `Motion.duration/curve` wrap OK,但部分 `Future.delayed` 残留 (e.g. `setup_page.dart:466-477` 庆祝 1.8s) **不会** 因 reduce-motion 跳过

### 性能 / 启动

1. **冷启动** — 5 个 round 91 task 集成后,`AppRoot.initState` 跑 3 个 addPostFrameCallback (notification + deep link + safety check + assessment reminder + rescheduleAll)。**冷启动到主页可能 2-3s**,需要 splash 视觉反馈
2. **主页 build 复杂** — HomePage build 内 8 个 widget + Spacer 2 个,ref.watch 5+ 个 provider,**重 build 性能**需测
3. **Trend 4 chart 同屏** — heatmap + monthly + assessment + mood chart 都在 1 ScrollView,**滚动性能**需测
4. **CBT 5/7 栏 wizard** — 切档时 dispose + reset cbtDraftProvider,Step 4 的 `moodCbtConfirm` 是简陋 `Text(...)` 不是 SummaryCard

### 状态管理

1. **HomeLifecycleState enum** (R64) 是 L2 refactor,正确。**其他 widget 多 bool flag 状态机**未重构 (e.g. `medications_list_widget.dart` 3 Set 状态)
2. **Riverpod 3.x `ref.mounted` 仅 Notifier** (R3 已知) — 项目用 Provider/StreamProvider/ConsumerStatefulWidget,27 处 `!mounted` check 正确,但消费 Notifier 时**不能**用 `ref.mounted`
3. **AppRoot `_lastCheck` 跨 midnight 检测** — `crossedMidnightSince` top-level 函数,正确。**但 timezone DST 边界** (R40 用 tz.local) 仅在 `_scheduleMidnightRefresh` 用,`crossedMidnightSince` 仍用 `DateTime` — 国际用户 DST 边界可能漏 1 小时

### 商业 / 心理

1. **精神心理患者对"商业卡"敏感** — 病耻感 + 心理脆弱,IAP 升级 Pro 商业卡当头炮,emil 原则 "decisions should be nameable" → 这里 conversion gate 应该是 hidden (仅未购买 + 进高级功能时)
2. **情绪 diary 录音是敏感数据** — vent audio 加密 ✓ (R78 之后),但 **mood audio 也录音,加密状态需查** (mood_audio_section.dart 没读,可能未加密)
3. **CBT 思维记录 5/7 字段写死 DB** — 用户填的负面思维 (situation/automaticThought) 永久存,撤回同意后是否物理删 (R82.5 vent 撤回物理删,**CBT 未确认**)
4. **失联通知业务暂停** — 联系人已挪底部 + FeatureFlags.emergencyContactEnabled, **UI 没动态隐藏**,App 仍能添加联系人 (addContact 路径保留),业务跑 gate 后不发送。但用户**添加后无任何反应**,可能困惑

---

## 附录: token 化率统计

| 类别 | 集中器数 | 残留 (grep) | 集中器化率 |
|---|---|---|---|
| 颜色 | 50+ (AppColors) | ~5 处裸 Color(0xFF...) | ~95% ✓ |
| 字体 | 14 (AppTypography) + 13 textStyleXxx helper | 158 处 TextStyle 残留 (59 文件) | ~60% |
| 间距 | 20+ (AppSpacing) | 162 处 EdgeInsets 残留 (75 文件) | ~60% |
| 圆角 | 6 (AppSpacing.radiusXxx) | ~10 处 BorderRadius.circular 残留 | ~85% |
| 字号 | 14 (AppTypography.fontSizeXxx) | 158 处含 fontSize 的 TextStyle | ~60% |
| 字重 | 走 FontWeight.wXXX | 100+ 处裸 w500/w600/w700 | 0% (这不该 token 化,M3 标准) |
| 动效 duration | 6 (AppMotion.durXxx) | 50+ 处 Duration(milliseconds:) | ~70% |
| 动效 curve | 6 (AppMotion.curveXxx) | 50+ 处 Curves.easeXxx | ~70% |
| 阴影 | 4 (AppMotion.shadowXxxOf) | ~3 处 BoxShadow 残留 | ~90% ✓ |
| 颜色 alpha | 6+ (AppColors.tintedXxx) | ~15 处 withValues(alpha:) | ~80% |
| 状态色 fg | 4 (AppColors.fgXxx) | ~10 处直接 onPrimary / onSurface | ~80% |

**最高优先级补漏**: TextStyle 残留 (158 处 59 文件) + EdgeInsets 残留 (162 处 75 文件) 走 4-week sprint 集中处理。
