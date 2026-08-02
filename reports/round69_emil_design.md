# emil 设计工程视角审计 · 慢病管家 chroniccare v0.27 round 69

> 审计日期:2026-08(上 round 60 emil 报告后 9 round)
> 视角:Emil Kowalski《设计工程》— 动效 / 视觉层级 / 交互反馈 / a11y / token
> 范围:`lib/presentation/` + `lib/core/theme/` + `lib/core/routing/`
> 测基线:0 analyzer error / 1163+ tests / 16 守护脚本全绿

---

## 0. 总览

### 整体评分:**A-**(93/100,上架前可发布,1 P0 + 2 P1 必修)

**结论**:v0.27 round 60 emil 报告后,token 体系 / 集中器 / a11y 推到新水位。R81 三大块(QuickMoodCarousel / HomeFabToolbar / HomeHeroIllustration)+ R65 PrimaryButton 迁移 + R70 LoadingScrim + R59 theme-aware shadow 全替换都加分。

但**新代码"野生实现"**把 95% 收敛回拉 88% — 这是核心问题。

### 8 维度打分

| # | 维度 | 分 | 关键证据 |
|---|---|---|---|
| 1 | Duration 时长 | 5/5 | `app_motion.dart:33-46` 6 token 集中,grep 0 漏网 |
| 2 | Easing 曲线 | 5/5 | `app_motion.dart:58-86` 6 curve token,0 硬编码 `Curves.x` |
| 3 | Stagger / Choreography | 4/5 | home_footer / vent_list 良好;setup 4 step / mood 4 维度仍单页瞬切 |
| 4 | Interruptibility | 5/5 | R59 shadow + R62/R63 Timer cancel + shimmer Timer 集中器 |
| 5 | A11y | 4/5 | `AppSemantics` 3 工厂 + reduce-motion 全站;**ListTile 缺 Semantics 严重** |
| 6 | Physics correctness | 5/5 | `CelebrationBounce` 走 `curveBackOut` 单次过冲;tween 数字递增 |
| 7 | Delight | 5/5 | R81 太阳 emoji / 渐变 hero / FAB 展开 / streak 数字 / 4 档 celebration / haptics 5 类 |
| 8 | Restraint 克制 | 4/5 | 鼓励文案 100+/day 无动画;**FAB 工具栏 4 入口展开动画偏华丽** |

**总分:38/40**。

### 上架前 5 必修(按 ROI 降序)

1. **[P0][S]** `home_fab_toolbar.dart:124,174` 2 处 `Colors.black.withValues(alpha: 0.12)` 黑底阴影 — dark mode 完全不可见,走 `AppMotion.shadowOverlayOf(context)` 集中器
2. **[P1][S]** `home_fab_toolbar.dart:83,99` 2 处直接 `showSnackBar(SnackBar(content: Text(...)))` 绕开 `AppSnackBar` 集中器 — 2 个 TODO 提示裸中文,en 模式降级
3. **[P1][M]** `app_list_tile.dart:48-167` ListTile 集中器**完全没 Semantics 标签**,影响 20+ 调用点(settings/reminders/medication/assessment/contact/vent),TalkBack/VoiceOver 用户无法用
4. **[P1][S]** `hero_illustration.dart:67,82,96,106` + `quick_mood_carousel.dart:155` 共 5 处 hardcode `fontSize: 28/32/36/56` — 抽 4 个 emoji 专用 token
5. **[P2][M]** `home_fab_toolbar.dart:85,100` 2 处裸中文 TODO 提示 — 走 l10n key

---

## 1. 11 项检查结果(按 P0-P3 排序)

### 🔴 P0 必修(1 项)

#### P0-1 [S] 硬编码黑底阴影,dark mode 不可见
- **位置**:`lib/presentation/pages/home/widgets/home_fab_toolbar.dart:124, 174`
- **现状**:`boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 2))]`
- **风险**:R59 (emil EMIL-T29) 已禁 4 个 const shadow,要求全走 `AppMotion.shadowOverlayOf(context)`(theme-aware, dark mode 反白)。R81 新写的 FAB 没接,**dark mode FAB 完全"飘"无立体感**。
- **修复**:2 处都改 `boxShadow: AppMotion.shadowOverlayOf(context)`(blurRadius/offset 已含)。5 分钟。
- **ROI**:极高(dark mode 4/5 → 5/5)

### 🟠 P1 应修(3 项)

#### P1-1 [S] snackBar 绕开集中器
- **位置**:`home_fab_toolbar.dart:83-87, 99-103`
- **现状**:`ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('紧急热线入口建设中 (R82+)'), duration: Duration(seconds: 2)))` 等 2 处
- **风险**:绕开 `AppSnackBar` 集中器 + 裸中文 + `Duration(seconds: 1)` 硬编码(应走 `snackBarDurationShort` token)。en 模式降级严重。
- **修复**:改 `AppSnackBar.showInfo(context, l10n.homeFabHotlineTodo)`,zh/en/zh_Hant 三 ARB 加 2 key。15 分钟。

#### P1-2 [M] ListTile 缺 Semantics 标签
- **位置**:`lib/presentation/widgets/app_list_tile.dart:48-167`(影响 20+ 调用点)
- **现状**:`ListTile(leading, title, subtitle, trailing, onTap)` — 集中器本身没 Semantics
- **风险**:`AppSemantics` 集中器只用在 `check_in_button` / `dimension_row` / `assessment_widgets:209` / `medication_calendar_page:69` 4 处,settings/medication/contact/vent 的 ListTile **0 个接 Semantics**。TalkBack 用户无法用。
- **修复**:`app_list_tile.dart` 加 `required String semanticsLabel` 参数,内部包 `AppSemantics.container(label: semanticsLabel, ...)`。30+ 调用方补 l10n key。2-3 小时。
- **ROI**:高(a11y 4/5 → 5/5,上架前无障碍评审基础线)

#### P1-3 [S] emoji 字号 magic 5 处
- **位置**:`hero_illustration.dart:67,82,96,106` + `quick_mood_carousel.dart:155`
- **现状**:`fontSize: 28/32/36/56` 4 个不同数字(注释说"emoji 渲染有 size cap")
- **风险**:未来调字号时 5 处不同字号语义不清
- **修复**:抽 4 个 token `iconSizeEmojiHeroLg=56 / Md=36 / Sm=28 / Moods=32`,放 `app_spacing.dart`。15 分钟。

### 🟡 P2 锦上添花(2 项)

#### P2-1 [S] FAB 工具栏 4 入口 TODO 文案硬编码
- **位置**:`home_fab_toolbar.dart:85,100`
- **现状**:`'紧急热线入口建设中 (R82+)'` / `'回到顶端 (R82+ 接管滚动)'`
- **修复**:跟 P1-1 一起走 l10n key + 简化掉技术细节。15 分钟。

#### P2-2 [M] dark mode LoadingScrim 体验
- **位置**:`lib/presentation/widgets/loading_skeleton.dart:108-170`
- **现状**:`Theme.of(context).colorScheme.scrim.withValues(alpha: AppTokens.scrimAlpha)` — R70 集中器
- **emil 评估**:0.54 alpha 对 long-task modal(M3 spec),`LoadingScrim` 集中器是 R70 后的设计系统补全,正确。**保留**。

### 🟢 P3 NIT(2 项)

#### P3-1 [S] `last_med_info` 手写日期格式化
- **位置**:`lib/presentation/widgets/last_med_info.dart:71-78`
- **现状**:`'${dt.year}-${_pad(dt.month)}-${_pad(dt.day)} ${_pad(dt.hour)}:${_pad(dt.minute)}'`
- **风险**:AGENTS.md 注 v0.25 R56d "formatters 走 intl DateFormat",**这处是漏网**。zh_Hant/en 模式都显示 ISO-ish 格式。
- **修复**:走 `core/shared/formatters.dart` 集中器。5 分钟。

#### P3-2 [S] `EdgeInsets` 数字 magic
- **位置**:`contacts_list_widget.dart:72` `EdgeInsets.all(4)` + `today_med_schedule.dart:180` `EdgeInsets.only(right: 4)`
- **修复**:用 `AppTokens.spacingXxs = 4` 替换。2 分钟。

---

## 2. 现状合理项(不改)

1. **setup 4 step 单页瞬切**(`setup_page.dart:130-152`)— 1 次性引导(rare 频度),单焦点,无需 stagger
2. **`encouragement_text` 100+/day 无动画**(`encouragement_text.dart:11-12`)— streak 每日最多变 1 次,过度动画 = 感官超载
3. **树洞 / 紧急联系人 swipe-to-dismiss + `Haptics.warning`** — 删除是危险操作,重触感 = 警示"删了不可恢复",emil "delight 不滥用"
4. **CheckInButton streak 数字 tween 500ms**(`check_in_button.dart:97-170`)— 庆祝时刻体感"刚刚发生",`_currentAnimated.round()` 取整避免抖动
5. **`PageTransitionSwitcher` 默认 100ms fade**(`page_transition_switcher.dart:38`)— 比 Material 默认 300ms 快 3x,体感"快";3 类 transition 按频度分类合理
6. **dark mode 7 个 dynamic color getter**(`app_colors.dart`)— M3 spec 严格,色阶独立调暗模式不污染亮模式
7. **IAP 升级卡 Pro 绿色态**(`settings_page.dart:59-84`)— Pro 状态用 success 色对(绿系)而非 primary(蓝),语义"已购 = 成功态"清晰
8. **`PopScope` 防误退 setup**(`setup_page.dart:118-127`)— 用户误触系统返回键会丢失 consent 勾选
9. **空态用 `textHintColor` 软灰**(`empty_state.dart:54-66`)— emotional content 入口"软"一些,避免"满屏大字"刺激(精神心理 App 的克制)
10. **`LoadingScrim` 0.54 alpha**(`loading_skeleton.dart:108-170`)— M3 long-task modal spec,高于 dialog 0.32,低于 0.7 全黑

---

## 3. 总结

### 3.1 上架前必须(2 项,20 分钟)

```
[ 5 min]  P0-1  home_fab_toolbar.dart:124, 174 改 AppMotion.shadowOverlayOf(context)
[15 min]  P1-1  home_fab_toolbar.dart:83-87, 99-103 改 AppSnackBar.showInfo + 2 ARB key
        ──────
[20 min]  上架前 P0 + P1 全部修完,达 A 评 (95/100)
```

### 3.2 上架后下一批(2 项,2-3 小时)

```
[15 min]  P1-3  hero + quick_mood_carousel 抽 4 个 emojiSize token
[2-3 hr]  P1-2  app_list_tile 加 semanticsLabel + 30+ 调用方补 l10n
```

### 3.3 长期优化(2 项 NIT,7 分钟)

```
[ 5 min]  P3-1  last_med_info 走 intl.DateFormat
[ 2 min]  P3-2  contacts_list_widget + today_med_schedule 改 spacingXxs
```

### 3.4 与 R60 emil 报告对比

| 维度 | R60 | R69 | 变化 |
|---|---|---|---|
| Duration 集中 | 5/5 | 5/5 | 持平 |
| Easing 集中 | 5/5 | 5/5 | 持平 |
| Stagger | 4/5 | 4/5 | 持平(mood/assessment 未补) |
| Interruptibility | 5/5 | 5/5 | 持平 |
| A11y | 5/5(R60 偏乐观) | 4/5 | **-1**(ListTile 集中器空 Semantics) |
| Physics | 5/5 | 5/5 | 持平 |
| Delight | 5/5 | 5/5 | 持平 |
| Restraint | 5/5 | 4/5 | **-1**(FAB 工具栏 4 入口展开偏华丽) |

**整体:A+(R60) → A-(R69)** — 新代码绕过集中器拉低分(2 shadow + 2 snackbar + ListTile Semantics)。

### 3.5 上架前 1 票否决清单

| 维度 | 当前 |
|---|---|
| dark mode 视觉立体感 | ⚠️ 1 处 P0 |
| en/i18n 完整性 | ⚠️ 1 处 P1 |
| a11y TalkBack 可用 | ⚠️ 1 处 P1 |
| design token 一致性 | ⚠️ 2 处 P1/P2 |

**结论**:**20 分钟修 P0+P1** 即可达上架标准;完整修复 3-4 小时达 A+(97/100)。R81 新增的 QuickMoodCarousel / HomeFabToolbar / HomeHeroIllustration 视觉上"治愈系 IP 化"加分明显,但工程层面需收尾 4 处集中器绕开。
