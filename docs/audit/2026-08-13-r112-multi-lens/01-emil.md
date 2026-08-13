# emil 设计/UX 视角审视报告 — 2026-08-13 R112

## 0. 元数据
- 视角: emil (设计工程 / token 化 / a11y / Apple Health 落地度)
- 审视者: emil subagent (只读审计)
- 审视时间: 2026-08-13
- baseline: HEAD=6bbb308, working tree=127M 13?? (R112 进行中: export v5 / scale_name_l10n / mood_label 等)
- 范围: 全扫 `lib/core/theme/` (8 文件全读) + `lib/presentation/widgets/` 集中器 (press_feedback / primary_button / check_in_button / stat_card / apple_list_section / section_header / app_list_tile / chip_badge / mood_label / mood_quick_button / page_scaffold / press_feedback_icon_button / feedback / app_semantics / animations 全读) + `lib/presentation/pages/` 各 feature 主页抽查 (home / mood_list / mood / vent / assessment / contact / settings / daily_tracking / crisis_hotline / medication / trend / setup) + 新代码 `lib/presentation/services/scale_name_l10n.dart` + `lib/presentation/widgets/mood_label.dart` + 对应测试。R111 旧报告只当待验证清单, 结论全部来自本次实读。

## 1. 整体评分 (0-10)

**7.5/10** — R111 8 项残留中 5 项真闭环 (EM-14/16/17/18/21 + EM-05/06b/02b/15), token 集中器层继续 9/10 健康; 但落地层 Card 方言 (EM-02) 8 feature 仍 0 进展、EM-16 对比度只修了 warning 一档、且 R112 新代码引入 1 个 i18n 回归 (settings 量表列表 PHQ-9/GAD-7 subtitle 显示裸 id "phq9"/"gad7")。

## 2. 关键发现

### P0
无。本轮无阻塞上架 / 数据丢失级设计问题。

### P1

- [底层] **[R112-01] settings 量表列表 PHQ-9/GAD-7 subtitle 显示裸 id "phq9"/"gad7" (3 语全中, zh 也回归)** — 难度:S — 工作量:10min
  - 位置: `lib/presentation/services/scale_name_l10n.dart:30-40` (switch 缺 'phq9'/'gad7' case, `_ => id` 兜底) / 调用点 `lib/presentation/pages/settings/widgets/assessment_section.dart:61`
  - 现状: R111-02 修复把 `_scales[i].shortDescription` 换成 `scaleShortDescL10n(id, l10n)`, 但 switch 只有 8 个 case (isi/pss/whodas/level2×4/asrm), 漏了 10 量表中的 phq9 + gad7 → 兜底返回裸 id。改前 zh 显示"过去两周的抑郁倾向筛查", 改后**所有 locale 显示 "phq9"**。ARB 已有现成 key (`phq9ShortDescription` / `gad7ShortDescription`, app_zh.arb:1497/1514, app_en.arb:1458/1475), 加 2 个 case 即可。
  - 建议: 补 2 case + 修测试盲区: `test/presentation/services/scale_name_l10n_round8_test.dart:61` 用 `ids.sublist(2)` 恰好跳过这 2 个 id, 且 desc 断言只有 `isNotEmpty` 没有 `isNot(id)` (裸 id 非空 → 永远绿)。改成全 10 id + `isNot(id)`。
- [架构] **[EM-16b] 对比度修复只覆盖 warning 一档 — success/error/warningStrong 仍作文字色 (2.3~3.0:1)** — 难度:S — 工作量:≤1h
  - 位置: `lib/presentation/pages/mood_list/widgets/mood_factor_analysis.dart:114-116` (textColor = success/error 裸用) / `lib/presentation/pages/mood/widgets/cbt_three_column_mode.dart:116-117` (score 1/2/4/5 走 `_scoreColor` 裸色) / 假 token `lib/core/theme/app_colors.dart:301` (`fgOnSuccess = success` 别名, 0 对比度修正)
  - 现状: R112 只修了 warning→fgOnWarning (#E65100)。实测余下: success #66BB6A on white ≈ **2.4:1**, warningStrong #FF8A65 ≈ **2.3:1**, error #E57373 ≈ **3.0:1**, 全低于 WCAG AA 4.5:1 (小号数字文字连 3:1 large-text 都不达标)。`fgOnSuccess` 直接 alias 浅绿 = "假 token" (emil: 语义假 API)。
  - 建议: `fgOnSuccess` 改深绿 (#2E7D32 档, 同 fgOnWarning 模式), 加 `fgOnError`/`fgOnWarningStrong`, 两个文件统一走 `_fgFor(score)` 映射; 补 contrast lock-in test。
- [架构] **[EM-02] Card 方言 8 feature 仍 0 AppleListSection 化 (R110 跨期残留, 唯一 0 进展项)** — 难度:L — 工作量:1-2d
  - 位置: 实测 0 AppleListSection/AppleHealthTile 的 feature 主页: `mood_list/mood_list_page.dart` / `daily_tracking/daily_tracking_page.dart` / `crisis_hotline_page.dart` / `contact/contacts_list_widget.dart` / `vent/vent_list_page.dart` / `assessment/assessment_center_page.dart` (grep 0 命中)。Card 数量: settings 41 / assessment 23 / trend 15 / medication 15 / daily_tracking 13 / reminders_hub 13 / mood_list 4 (detail_page:44,156,210,224) / vent 3。
  - 现状: R112 相比 R111 只新增了 setup + medication 的 ALS 化; 上轮点的 settings 4 组 (profile/reminders/data/legal) + vent + assessment + mood_detail + reminders_hub + contact + daily_tracking 全部原样 Card。
  - 建议: 按 R111 建议做 "Card 方言 → AppleListSection" 专项 (settings 4 组优先, 1d), 其余 feature 每页 ~2h。

### P2

- [底层] **[EM-14b] AppListTile 无 onTap 时仍包 PressFeedback → 不可点行有 scale + haptic 假反馈** — 难度:S — 工作量:0.5h
  - 位置: `lib/presentation/widgets/app_list_tile.dart:159-161` (无论 onTap 有无都包 PressFeedback, 不传 `enabled`) / 实锤调用点 `lib/presentation/pages/settings/widgets/assessment_section.dart:93` (关于行) + `:106` (免责声明行) — 均无 onTap 但按下有 scale + Haptics.light
  - 现状: EM-14 修了 PressFeedback/PrimaryButton/CheckInButton, 但 AppListTile 没把 `enabled: onTap != null` 传下去。视觉上"能按"、行为上"没反应" = 假 affordance (EM-17 同族)。
  - 建议: `PressFeedback(enabled: onTap != null, ...)`; 顺带把 mode 2 注释里"child.onTap 接管"的错误描述修掉 (实现里 ListTile.onTap 恒 null)。
- [底层] **[EM-07] fl_chart 3 处 Colors.white 残留 (dark mode 下轴线/圆点描边仍白)** — 难度:S — 工作量:20min
  - 位置: `lib/presentation/pages/mood_list/mood_trend_page.dart:268` (FlDotCirclePainter.strokeColor) / `:284` (LineTooltipItem 文字色) / `:541` (分布图 dot strokeColor)
  - 现状: 跨期 3/3 残留。:268/:541 在 dark mode 白描边刺眼; :284 是 tooltip 文字 (fl_chart 默认深底 tooltip, 白字可接受但应走 token 化注释)。
  - 建议: strokeColor 改 `AppTokens.surfaceColor(context)` 或 theme-aware; tooltip 白字保留但加注释 + token。
- [底层] **[EM-09b] _ChipBadge 三副本并存 — 公共 ChipBadge 存在但 2 个集中器不用** — 难度:S — 工作量:0.5h
  - 位置: 公共 `lib/presentation/widgets/chip_badge.dart` (v0.22 已抽) vs 私有副本 `lib/presentation/widgets/section_header.dart:136-160` + `lib/presentation/widgets/apple_list_section.dart:232-256` (注释自认"独立定义避免互依赖", 但公共版就在同目录 widgets/)
  - 现状: vent_list_page / mood_trend_page 的私有 _ChipBadge 已清 (R112 前完成), 剩这 2 个集中器自己各留一份, 3 份同视觉代码。
  - 建议: 2 个私有版换成公共 ChipBadge (无循环依赖风险, 同层 widgets/)。
- [底层] **[R112-02] quick_mood_carousel "more" icon 18pt 无 padding — tap target ~18-24px < 44pt** — 难度:S — 工作量:20min
  - 位置: `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:122-129` (PressFeedback 直接包 `Icon(Icons.tune, size: 18)`, 无 SizedBox/IconButton 最小区域)
  - 现状: 唯一 18pt 裸 icon 交互点 (其余 icon 全走 PressFeedbackIconButton = IconButton 48px 最小约束)。Apple HIG 44pt 不达标, 精神心理患者触控精度差时更明显。
  - 建议: 包 `SizedBox(width: 44, height: 44, child: Center(icon))` 或改 PressFeedbackIconButton。
- [架构] **[R112-03] Spring.of / SpringType 0 caller 死代码 (145 行物理模型只剩 1 个 caller)** — 难度:S — 工作量:0.5h
  - 位置: `lib/core/theme/spring.dart:125-144` (`Spring.of` context 工厂 + `SpringType` enum, `// ignore: unused_local_variable` hack) — 全库 grep 仅 `check_in_button.dart:245` 用 `Spring.standard.toSimulation`
  - 现状: R32 P0-08 接真了 standard 物理弹簧, 但 gentle/bouncy/of/SpringType 继续 0 caller。`Spring.of` 的 `_ = context` 占位是 3 视角共识死代码 (R109 起)。
  - 建议: 删 `Spring.of` + `SpringType` enum (保留 3 个 static const + toSimulation), 或第 2 处真接 (celebration overlay 用 bouncy)。
- [架构] **[R112-04] 量表名 i18n 三源变"3.5 源" — scale_name_l10n 新派发与 810L 死类平行** — 难度:M — 工作量:0.5-1d (跟 AR-17 合并)
  - 位置: `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` (810L, grep 全库 `AppLocalizationsScaleTranslations(` 构造 0 处运行时 caller, 仅测试引用) / 新 `lib/presentation/services/scale_name_l10n.dart:40` (40L, 3 caller) / `lib/domain/entities/scale_translations/static_scale_translations.dart` (781L)
  - 现状: R112 新增的 scale_name_l10n 注释自称"跟 AppLocalizationsScaleTranslations 平行, 单一 dispatch 源" — 自相矛盾: 平行 = 不单一。名字派发现在有 StaticScaleTranslations (zh fallback) + 810L 死类 + 新 40L 派发 3 个源, AR-17 没合一只变多。
  - 建议: 短期保留 scale_name_l10n (实用), 但 810L 死类与 domain StaticScaleTranslations 的合一进 R112 AR-17 专项; scale_name_l10n 加 `default:` 抛 assert 防未来新量表裸 id 上屏。
- [底层] **[EM-11] 72pt 快捷情绪按钮 spec 未落地 (跨期 3 轮)** — 难度:M — 工作量:2-3h
  - 位置: `lib/presentation/widgets/mood_quick_button.dart` 仍 SecondaryButton 行内 emoji+文字, 无 72pt 超大 pill 按钮 (R110 EM-11 原样)
  - 现状: spec §5 类 "quick mood 72pt" 设计从未实现; 当前形态可用但跟 CheckInButton 64pt pill 不对等 (主页 2 个 CTA 一重一轻)。
  - 建议: R112 后专项评估 — 若保留现形态则改 spec 删 72pt 条目 (防 spec 漂移), 否则实现 72pt 变体。

### P3

- **[EM-19] AppListTile.destructive 假 API** — `lib/presentation/widgets/app_list_tile.dart:95-108` `_isDestructive` 赋值后 build() 从不读 (仅 assert 互斥), 注释自认"当前实现跟 standard 一样"。删或实做 (红色 leading tint)。
- **[EM-20] AppleHealthTile 注释漂移** — `lib/presentation/widgets/apple_health_tile.dart:13,71` 仍写 "88pt" (实际 tileHeight=110, :72)。
- **[R112-05] apple_list_section 注释漂移 (新产生)** — `apple_list_section.dart:56-57,133-134` 注释仍称 "SectionHeader 是 11pt" — R112 已把 SectionHeader 升到 13pt (section_header.dart:78), 两处注释变陈旧且与事实矛盾。
- **[EM-08] 硬编码 fontSize 残留 6 处** — `mood_detail_page.dart:52` (48 emoji) / `cbt_three_column_mode.dart:44,56` (20 emoji) / `mood_trend_page.dart:384` (20 emoji 轴) / `add_medication_page.dart:393` (16 chip) / `medication_detail_page.dart:304` (10 日历数字)。多为装饰性 emoji/chip 字号, 可留但建议注释。
- **[R112-06] moodTodayLabel + moodLabel 字符串拼接** — `mood_quick_button.dart:51` `'${l10n.moodTodayLabel}${moodLabel(...)}'` 应改参数化 ARB key (placeholder), 未来非 CJK/en 语序会错。现 3 语可显示, 无 bug。
- **[R112-07] ARB moodLabel1-5 缺 @ metadata** — app_zh.arb:1307-1311 无 `@moodLabelN` 描述 (项目其他 key 惯例有)。
- **[R112-08] mood_label.dart 0 直接测试** — 新 helper 3 调用点但无专属 test (scale_name_l10n 有 test 它没有)。
- **[R112-09] PressFeedbackIconButton 禁用态残余 (理论)** — `press_feedback_icon_button.dart:104` 模式 2 分支不传 `enabled`, onPressed/onTap 双 null 时 Listener 仍 scale+haptic; 当前 0 调用点双 null, 纯理论风险。
- **[a11y] Semantics 覆盖薄** — AppSemantics 集中器 8 文件在用, 但 raw `Semantics(` 仅 3 个页面 (mood_detail / add_medication / medication_calendar); 自定义控件 (评分、图表、carousel) 大部分无 TalkBack 描述。长期专项。

## 3. 外部链接 / 域名 / 邮箱 / URL 检查 (lib/ + fastlane/ + docs/)

| 位置 | 内容 | 状态 |
|---|---|---|
| lib/presentation/pages/crisis_hotline_page.dart | 危机热线电话 (国家/地区号码) | 业务内容, 非外链 |
| lib/ 全库 | 无 http/https URL 硬编码 (grep 无命中) | 已隐藏/无 |
| fastlane/metadata/* | 版本号/描述文案 (R112 修改中) | 由 04/05 视角覆盖 |

设计视角无新增外链风险。

## 4. 四类问题

### 4.1 上架相关
- 设计侧无阻塞项。视觉资产 (截图/图标/LaunchImage) 全 0 是 AppStore/GooglePlay 视角硬阻塞, 与设计系统无关; 但注意: **上架截图需展示的页面当前有 Card 方言混杂** (settings/trend), 若 R112 出截图前未做 EM-02 专项, 截图会暴露两套视觉语言。

### 4.2 架构相关
- 设计系统架构健康: 5 token 集中器 + 8 widget 集中器 1:1 无回归, 唯一架构债是 **量表名 i18n 多源** (R112-04, 与 AR-17 同根)。
- `lib/presentation/services/` 新增 scale_name_l10n 位置合理 (presentation 层 helper), mood_label 放 widgets/ 也正确; 两者都 0 Flutter 违规、0 跨层 import。

### 4.3 重构建议
1. **R112 hotfix (≤1h)**: R112-01 补 2 case + 测试盲区; EM-16b 换 fgOnSuccess/fgOnError; EM-14b AppListTile enabled; EM-07 fl_chart white; R112-02 tap target。
2. **EM-02 专项 (1-2d)**: settings 4 组 → AppleListSection (profile_group/reminders_group/data_group/legal_group) 起步, 后 daily_tracking/vent/mood_detail/reminders_hub/contact/assessment。
3. **集中器自清 (0.5d)**: EM-09b ChipBadge 合一 + EM-19 destructive 实做/删 + R112-03 Spring.of 删 + R112-05/EM-20 注释同步。
4. **量表 i18n 三源合一** 进 R112 AR-17 专项 (2-3d, 顶层架构视角已有路线)。

### 4.4 半成品 / TODO / 残缺功能
- spring.dart: 145 行, 1/3 接真 (standard), gentle/bouncy/of/enum 死代码 (R112-03)。
- AppListTile.destructive: 假 API (EM-19)。
- 72pt quick mood: spec 有设计无实现 (EM-11)。
- AppLocalizationsScaleTranslations 810L: 0 runtime caller (R112-04)。
- AppleListSection 落地: 11 feature 中 home/trend_summary/setup/medication 4 组完成, 8 feature 0 (EM-02)。
- Apple Health spec §5 采纳度与 R111 持平 (4/11), 未变。

## 5. 总结 + 给整合者的建议

**R112 设计侧净变化**: R111 8 项残留闭环 5.5 项 (EM-14 核心/16 warning 档/17/18/21 + EM-05/06b/02b/15), 是近 3 轮中设计收敛最好的一轮; 但 R112 新 helper 引入 1 个真 i18n 回归 (R112-01, 10 分钟可修) 且测试盲区恰好把它放过 — 建议整合时把 "新 helper 必须全 id 覆盖 + isNot(id) 断言" 列为 R112 代码审查 checklist。

**下轮优先级 (设计侧)**:
1. P1×3 (R112-01 → EM-16b → EM-02 起步) 合计 ≤2d, 修完设计分可到 8.5/10。
2. EM-02 是唯一跨 4 轮 0 进展的落地债, 建议 R112 或 R113 给专项 1-2d 一次清 settings/vent/mood_detail/daily_tracking 四块最大的。
3. 截图前必须先做 EM-02 (见 4.1)。

**评分**: token/集中器层 9/10 · 落地层 6/10 · 新代码质量 7/10 (1 回归) · 加权 ≈ 7.5/10。

## 附录: 详细证据

- 硬编码 `Colors.` in presentation: 仅 `mood_trend_page.dart:268,284,541` 3 处 `Colors.white` 真残留 (其余全走 AppColors 集中器, 含 2026-08 新增的 moodScoreColor/healthMetricsColorFor/kMedicationPillColors)。
- `Color(0x` in presentation: 0 (仅 page_scaffold.dart:82 注释内)。
- 硬编码 fontSize: 7 处 (见 P3 EM-08), 硬编码 SizedBox 数值: ~15 处 (多为 2/4/8pt 微间距, P3 级)。
- 硬编码 Duration: 仅 `mood_audio_recorder_widget.dart:561` (100ms = durPress 档) + `setup_page_state.dart:434` (5s timeout 非动画); `Curves.` 裸用: 0。
- AppSnackBar 集中器: 104 调用点, raw showSnackBar 0 (仅注释)。
- reduce-motion: Motion.duration/curve 覆盖 press_feedback / routes / page_transition_switcher / tween_number / loading_skeleton shimmer / quick_mood_carousel (EM-18 闭环); celebration_bounce/fade_in/slide_up 走 disableAnimations 短路。
- reduce-transparency: page_scaffold.dart:63-103 真分支 (非 `false &&`), BackdropFilter blur(20) + alpha 0.6/0.4。
- Spring: `Spring.standard` 仅 check_in_button.dart:245; `Spring.of`/`SpringType` 0 caller。
- 触觉: Haptics 单源 (feedback.dart 5 类), presentation 0 处 raw `HapticFeedback.`。
- ChipBadge: 公共 1 + 私有 2 (section_header:136 / apple_list_section:232)。
- SectionHeader: 18 处调用, 字号已统一 13pt (跟 AppleListSection title 同), 双 header 问题闭环。

<!-- subagent: emil 完成时间: 2026-08-13T00:00:00Z -->
