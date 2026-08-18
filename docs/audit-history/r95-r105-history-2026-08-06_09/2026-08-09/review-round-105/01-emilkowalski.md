# emilkowalski 视角报告 (Round 105) — 2026-08-09

**评分**: 7.5/10
**基线**: R104 (2026-08-09)
**范围**: 本轮 UNCOMMITTED 重构批 (medication 主页/向导/详情 + mood 详情/趋势/因素分析 + daily_tracking 自定义/卡片/汇总 + home 今日汇总卡 + settings 档案卡)
**注意**: 本报告不重复 R104 已修项 (textHint #595959、hero shadow/ExcludeSemantics、PageTransitionSwitcher reduce-motion 均已修)。每条标注【new】或【unchanged from R104】。

---

## 优点 (批内亮点)

- HomeFabToolbar 展开加了 FadeIn stagger (40/80/120ms) + `Haptics.light()` — 编排与触感都对
- 用药列表卡 / 快捷操作卡用 PressFeedback 0.97 + 160ms, 符合项目标准
- 打卡 checkbox 用 `AnimatedSwitcher` cross-fade + `Haptics.success()` — 微交互方向正确
- EmptyState 在 medication_calendar_grid 内用得很好
- 新增路由统一走 3 类 transition 分类 (fade/slide-right/slide-up), 遵守 R101 约定

## 问题

| 编号 | 问题 | 文件:行 | 架构/底层 | 难度 | 优先级 | 建议 |
|---|---|---|---|---|---|---|
| E101 | **mood_detail_page 整页 Column 不可滚动** — PageScaffold 的 child 无滚动容器, CBT 字段多时 (situation~behavior 8 段 + note + 录音卡) 超出屏 → RenderFlex overflow, release 下内容被裁掉 | mood_detail_page.dart:34 (Column mainAxisSize.min, 34-231 全内容) | 底层/UI | 简单 | P0 | 整页换 `ListView` 或包 `SingleChildScrollView`; 顺带把 CBT 卡子项用 `Column(mainAxisSize.min)` 压紧 |
| E102 | **MoodDetailPage / MoodFactorAnalysis 是孤岛 UI** — 无任何路由、无调用点 (grep 仅 2 处定义), mood_list_page itemBuilder 未传 onTap, factor analysis 未嵌任何页 | mood_detail_page.dart:17; mood_factor_analysis.dart:17; mood_list_page.dart:145 | 架构/功能 | 简单 | P1 | mood-list 条目接 `/mood/detail` (slideRight) + 把 MoodFactorAnalysis 嵌进 mood_trend 或 detail; 否则删 |
| E103 | **药丸图标白色首字对比度失败** — 白字压在 #FFCC00 (黄) / #8E8E93 (灰) / #34C759 (绿) / #FF3B30 (红) 上均 <4.5:1, 黄色仅 ~1.3:1 | medication_pill_icon.dart:59-72 | 底层/a11y | 简单 | P1 | 深色渐变底 + 浅色字, 或按 colorIndex 走白/黑字双方案; 至少保证 6 色里浅色系可读 |
| E104 | **颜色/剂型选择未落库 — 用户 Step1 选剂型、Step3 选颜色全部静默丢失** — `_save()` 没传 `colorIndex`/`form` (draft 默认 0/tablet), 列表与详情页又全部 `colorIndex: 0` (TODO) → 所有药永远绿色 | add_medication_page.dart:85-98; medication_page.dart:415; medication_detail_page.dart:67 | 底层/数据 | 简单 | P1 | `_save` 补 `colorIndex: _colorIndex, form: _form`; 消费端改用 `med.colorIndex`/`med.form` (删 TODO); 顺手给列表/详情统一 pill 色 |
| E105 | **打卡 checkbox 无 a11y 标签 + 触摸目标过小** — GestureDetector 裸包 28px icon, screen reader 听到 "radio_button_unchecked" 类名而非动作, 点按区远 <48dp | medication_page.dart:372-394 | 底层/a11y | 简单 | P1 | 包 `Semantics(button: true, label: '标记已服')` + `PressFeedback` + 整行可点 (Apple Health 全行 toggle) 或最少 minTapArea 包裹 |
| E106 | **新 AnimatedSwitcher 不尊重 prefers-reduced-motion** — R104 E1 同类问题蔓延: `AnimatedSwitcher(duration: AppTokens.durFast)` 直接裸用, 未走 `Motion.duration(context, ...)` | medication_page.dart:381; today_summary_card.dart:130 | 底层/a11y | 简单 | P1 | 统一 `Motion.duration(context, AppTokens.durFast)` + `Motion.curve(...)` |
| E107 | **mood_trend 3 张 fl_chart 隐式动画未关 reduce-motion** — LineChart/BarChart 默认 ~150ms 动画, 切时间范围/切 tab 都动; 且 SegmentedButton 切换无 choreography | mood_trend_page.dart:207, 333, 472 | 底层/a11y | 中 | P1 | 每张图 `duration: Motion.duration(context, AppMotion.durNormal)` 并在 disableAnimations 时设 0; 范围切换可选轻微 stagger |
| E108 | **空态不一致且缺 CTA** — medication_page 用自定义 `_EmptyMedicationsCard`/`_EmptyScheduleCard` (无 EmptyState、无"添加药物"按钮, 新用户无药时只能靠右上角 +); mood_trend 空态是裸 `Center(Text)` | medication_page.dart:502-575; mood_trend_page.dart:69-78 | 架构/UX | 简单 | P1 | 统一 `EmptyState`, medication 空态加 `actionLabel: '添加药物'` + `onAction: push('/medication/add')`; mood_trend 用 EmptyState(icon+subtitle) |
| E109 | **tracking_item_card record 按钮彩色文字 on 12% tint 对比度失败** — `#FF9500` 橙 / `#5AC8FA` 浅蓝等小号 caption 文字在近白底 ~2:1, 不满足 AA | tracking_item_card.dart:125-150 | 底层/a11y | 简单 | P1 | 前景统一走中性深色 (textPrimary) + 图标/左侧色块保留彩色; 或给每个 config.color 配 darker foreground |
| E110 | **设置页档案卡是死胡同** — `_UserProfileCard` 有 chevron_right 但无 onTap/InkWell, 看起来可点实为摆设 | profile_group.dart:203-257 | UX/UI | 简单 | P1 | 接一个真页面 (或滚动到档案编辑) 否则去掉 chevron + 加 PressFeedback |
| E111 | **today_summary_header 宣称"点击展开"但不可点** — 文件头注释写明"点击展开今日已追踪项列表", 实现无任何 tap 处理 | today_summary_header.dart:3-4, 30-96 | UX | 简单 | P1 | 实现展开 (AnimatedSize 已追踪列表) 或改注释去掉误导 affordance |
| E112 | **新页面 loading 全用裸 CircularProgressIndicator** — medication/detail/mood_trend 3 页 `loading: Center(CircularProgressIndicator)`; detail 页连 PageScaffold/AppBar 都丢了 (裸 Scaffold) | medication_page.dart:161; medication_detail_page.dart:199-201; mood_trend_page.dart:100 | 架构/一致性 | 简单 | P2 | 统一 `LoadingSkeleton.fullScreen()` (心理 App 标准, 项目已抽好) |
| E113 | **error 态裸 `Text('$e')` 无重试** — 3 个新页全部 `error: (e,_) => Center(Text('$e'))`, 违背 profile_group 已用 ErrorState+retry 的模式 | medication_page.dart:162; medication_detail_page.dart:202; mood_trend_page.dart:101 | 架构/一致性 | 简单 | P2 | 抽共用 ErrorState 或直接复用 presentation/widgets/error_state.dart |
| E114 | **主页今日汇总卡 4 列窄屏/大字溢出 + 占位不一致** — streak 无数据显示 `0天` 而其他三项显示 `—`; 4 个 Expanded 在 360dp + textScale 1.5+ 下 label 会换行挤压; 且 `✓`/`—` 无语义 | today_summary_card.dart:52-153 | 底层/a11y | 简单 | P1 | streak 无数据也显示 `—`; 外层 `Semantics` merge; label 用 maxLines+ellipsis |
| E115 | **颜色选择器无 a11y/无按反馈** — GestureDetector 圆形色块 (仅 46px) 无 Semantics (读屏不知道在选颜色、哪个被选中), 无 PressFeedback | add_medication_page.dart:402-424 | 底层/a11y | 简单 | P1 | 包 `Semantics(label: '颜色N', selected: selected, button: true)` + PressFeedback |
| E116 | **向导步骤切换无过渡 + 进度条不动画** — R104 改条件渲染后步骤直接 swap, 3 格进度条也是静态切色 | add_medication_page.dart:120-148 | 底层/动效 | 简单 | P2 | 步骤内容包 `FadeIn` (respects reduce-motion); 进度条用 `AnimatedContainer` + 按步数显示"第N/3步"文字 |
| E117 | **toggle 无触感** — tracking customize Switch、卡片长按菜单切换均无 `Haptics.tap()` | tracking_customize_page.dart:156-160 | 底层 | 简单 | P2 | Switch onChanged / bottom sheet 菜单项加 `Haptics.tap()` |
| E118 | **ReorderableListView 无障碍缺 label** — Switch 无 Semantics label (读屏只报 "Switch, on"), 拖拽手柄 icon-only 无 tooltip | tracking_customize_page.dart:144-168 | 底层/a11y | 简单 | P2 | `Semantics(label: name)` 包 Switch; 手柄给 Semantics(label: '拖拽排序') |
| E119 | **依从性统计数字彩色对比度不足** — warning `#FFB74D`/success `#66BB6A` 大字 on 8% tint ~2-2.9:1, 即使 large text (3:1) 也踩线; `_InfoChip` 同款 | medication_detail_page.dart:122-137, 216-231 | 底层/a11y | 简单 | P2 | 状态色只做强调 (图标/条), 数字走 textPrimary; 或加深前景 (如 warning 用 #E65100 系) |
| E120 | **mood_detail 顶部 48px emoji 无 ExcludeSemantics** — R104 E5 同类蔓延到新页, 读屏会朗读 emoji 名称 | mood_detail_page.dart:44-47 | 底层/a11y | 简单 | P2 | `ExcludeSemantics(child: Text(emoji))`, 分数数字本身已带语义 |
| E121 | **quick_mood_carousel 首次高亮缺失** — R104 改 `int? _selected` 后初始为 null, PageView 停在 index 2 (score 3) 但无选中态, 直到用户滑动才高亮 | quick_mood_carousel.dart:54, 153-156 | 底层/UI | 简单 | P2 | initState 设 `_selected = _scores[2]` |
| E122 | **PressFeedback 覆盖不一致 (批内)** — medication_page 打卡 checkbox、tracking_item_card、today_med_schedule 新增 InkWell 卡均无 scale 反馈, 只靠 ripple; _UserProfileCard 完全无反馈 | tracking_item_card.dart:40-51; today_med_schedule.dart:57 | 底层/一致性 | 简单 | P2 | 交互卡片统一包 `PressFeedback` (mode 2), 与批内 `_QuickActionCard` 对齐 |
| E123 | **medication_detail 编辑按钮空实现** — `onPressed: () {}` 是假按钮, 用户点了没反应 | medication_detail_page.dart:176-183 | UX | 简单 | P3 | 接 EditMedicationDialog 或先隐藏/禁用 |
| E124 | **时间段卡 header 只显示首剂量时间** — 早/晚 slot 含多剂量时只展示 `entries.first`, 用户看到的时间会误导 | medication_page.dart:300-307 | UX | 简单 | P3 | 展示 "HH:MM" 列表或 "N 次" |
| E125 | **R104 E7/E8 仍未修 (unchanged)** — HomeFabToolbar 展开/折叠无 Semantics 通知 (本轮加了 FadeIn 但没加); QuickMoodCarousel emoji 按钮仍无 Semantics label | home_fab_toolbar.dart; quick_mood_carousel.dart:151-190 | 底层/a11y | 简单 | P3 | FAB 展开加 `Semantics(liveRegion/hidden)`; carousel 每项 `Semantics(label: '心情 3/5')` |
| E126 | **mood_factor_analysis 硬编码 Apple 状态色 (unchanged)** — R104 F7 遗留, success/warning/error 三个 const 在 dark mode 无适配; 且整卡无 Semantics (纯色条+数字, 色弱用户靠文本尚可) | mood_factor_analysis.dart:107-111 | 底层/UI | 简单 | P3 | 状态色走 theme-aware 或加深; 卡片加 `Semantics(label: '因素 X 平均分')` |

---

## emilkowalski 视角总结

这一批重构的方向是对的 — 模块化、Apple Health 式卡片、PressFeedback/Haptics/FadeIn 编排都落到了新交互里，说明团队已经把动效和触感当默认项。但**新页面在"收尾"上集体失守**：

1. **a11y 是被新代码拉低的重灾区** — E101 页面直接 overflow、E103/E109/E119 三处对比度、E105/E115/E118 三处缺 Semantics/触摸目标。这批页面都是"主路径"页面 (用药打卡、情绪查看、日常追踪), 不能当 polish 拖。
2. **"看起来完成"的假按钮/假入口太多** — E110 chevron 死胡同、E111 "点击展开"不可点、E123 空实现编辑、E102 整页 UI 没接线。Apple Health 式设计最大的陷阱就是"只有壳没有功能"。
3. **E104 是最伤 delight 的一处** — 用户花三步选的颜色/剂型根本没存, 列表全是绿色。个性化是这类 App 留住用户的钩子, 静默丢掉等于自断。

建议修复顺序: 先 E101 (页面崩溃) + E104 (数据丢失) + E103/E105 (a11y 硬伤), 再 E102/E108/E110/E111 补全闭环, 最后动效与触感打磨 (E106/E107/E116/E117)。这批改完, 评分可回 8.5+。
