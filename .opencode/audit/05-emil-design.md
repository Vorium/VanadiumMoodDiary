# 05 — emil Design-Engineering 动效审计 (2026-08-16)

**基线**: R113 修复战役之后的工作树 (未 commit)。审计范围: `lib/core/theme/` (8 文件) + `lib/presentation/widgets/` (45 文件) + `lib/presentation/pages/` 全部 12 feature 目录 + `lib/core/routing/`。
**方法**: emil-design-eng skill — 动画决策框架 (频度×动画) / Press 反馈 / 缓动与时长 / Spring / 动效细节 / 一致性。只读审计, 0 改动。

---

## 总分: 8.0 / 10

R113 Wave 2/7 的动效修复**全部实锤闭环**: `_EntrySpring` reduce-motion (`check_in_button.dart:279`)、medication 打卡 PressFeedback+Motion 包装 (`medication_page.dart:354-366`)、`homeEntryPlayedProvider` 首帧门控 (`home_page_state.dart:113-116, 212-223`)、EM-14 禁用态假反馈 (`press_feedback.dart:104` + 4 处 `enabled:` 传参)。token 集中度极好: 全 lib **0 硬编码 `Curves.`** (app_motion.dart 外)、全部 `Animated*` duration 走 `Motion.duration` 包装。剩余问题集中在"跨页一致性"和"高频路径 400ms 残留"两族。

---

## 1. 动画决策框架 (频度×动画匹配)

### F1. Tab 切换 3 类 transition 混用 — 同动作不同体感 [P2 | 底层 | 低]

4 个 shell tab 是同一动作 (tens/day 频度), 却用 3 种过渡, 其中树洞 tab 用全屏 modal 式 slide-up:

- `/` (心情) → `fadePage` 250ms fade — `app_route_main.dart:60-61`
- `/settings` → `fadePage` 250ms — `app_route_main.dart:63-69`
- `/trend` → `slideRightPage` 250ms slide+fade — `app_route_assessment.dart:24-25`
- `/vent` → `slideUpPage` **400ms** slide-up (全屏深页档) — `app_route_vent.dart:24-37`

| Before | After | Why |
| --- | --- | --- |
| 4 tab 混用 fade(250)/slideRight(250)/slideUp(400) | 4 tab 统一 fade 200ms (或全无) | 同动作必须同体感; slide-up 是"全屏 modal"语义, 点 tab 不该有 modal 感; tens/day 频度应降档 |
| `/vent` 在 shell tab 用 slideUpPage | `/vent` 改用 fadePage | vent 已升格为主 tab (1.1.0 round 5), 但路由仍带 setup 时代的 slide-up 残留 |

难度低: 改 `app_route_vent.dart:24/29/37` 三处 pageBuilder (但 `app_routes.dart:95` slideUpPage reverse 250<400 的出场不对称设计本身是对的, 保留给 /setup /crisis-hotline)。

### F2. FadeIn 默认 400ms (durSlow) 用在 tens/day 表面 [P2 | 底层 | 低]

`fade_in.dart:41` 默认 `duration = AppTokens.durSlow` (400ms) — 超过 emil "UI 动画 ≤300ms" 上限。实际落点:

- 树洞列表每项 400ms fade + stagger (`vent_list_page.dart:302`, tens/day)
- 用药日历每行 400ms (`medication_calendar_grid.dart:129`, tens/day)
- 主页 footer 2 项 400ms — **Wave 7 门控漏掉 footer**: `home_page_state.dart:354-362` 传 `HomeFooter` 不带 `entryDuration`, footer 内部 `home_footer.dart:32/44` 用默认 400ms, 每次 tab 切回主页都重播 400ms+30ms
- FAB 工具栏展开 4 按钮 400ms + 30/60/90ms stagger (`home_fab_toolbar.dart:69-179`)

| Before | After | Why |
| --- | --- | --- |
| `FadeIn.duration` 默认 durSlow(400) | 默认 durNormal(250); 列表/日历/工具栏 caller 显式 durFast(200) | tens/day 列表入场应 150-250ms; 400ms fade 让每次进树洞/日历都"慢半拍" |
| HomeFooter 无 entryPlayed 门控, tab 切回重播 400ms | footer 接 `entryDuration` (跟 header/checkin/summary 同门控) | Wave 7 门控了 3 个区块漏了 footer, 一致性缺口 |

### F3. 100+/day 与键盘路径 — ✅ 干净

无键盘快捷键; 高频动作 (打卡/记录/筛选) 未发现无目的动画残留。`EncouragementText` 已走 `MotionScheme.none` (`encouragement_text.dart:11`), mood 评分/标签/短语选择器 0 动画 (`mood_score_chooser.dart` 等 grep 为空)。`MoodRecorderPage.show` 走 showDialog (`mood_recorder_page.dart:77-78`) — occasional 频度, 标准 modal 动画正确。

---

## 2. Press 反馈

### F4. :active scale 集中器覆盖率 — 高但 3 类缺口 [P2 | 底层 | 低]

正面: **全部 IconButton 已走 PressFeedbackIconButton** (20+ 处: page_scaffold / trend_calendar / vent_* / medication_row / notification_status_card…), 列表行已包 (vent_list:464 / mood_list_item:38), 主按钮集中器内建 (`primary_button.dart:194`), 禁用态 `enabled:` 传参已闭环 4 处 (check_in_button:110 / press_feedback_icon_button:110 / app_list_tile:141 / primary_button:194)。

缺口 (裸 InkWell/M3 按钮, 只有 ripple 无 scale 0.97):

- `daily_tracking_card.dart:47-48` — `Card > InkWell` (7 卡片 grid, tens/day)
- `assessment_center_card.dart:50-51` — `Card > InkWell`
- `trend_calendar.dart:236-248` — 日历日 cell InkWell (tens/day 点击)
- `worry_timeline_page.dart:131/200/204/242/246` — 1 FilledButton + 4 TextButton, 0 PressFeedback
- `mood_hero_card.dart:56/93` FilledButton + `:98/104` TextButton (主页, tens/day)
- `loading_text_button.dart:54` (vent 保存按钮走它)、`secondary_button.dart`、`dialog_actions_row.dart` — 集中器自身未内建 PressFeedback

| Before | After | Why |
| --- | --- | --- |
| 卡片 tile / 日历 cell / 对话框按钮只有 M3 ripple | 统一包 PressFeedback (或 AppListTile) | "同动作同体感" — 全 app 按钮标准是 scale 0.97 100ms + haptic; 这些高频 tile 缺一半体感 |
| mood_hero_card 4 个裸按钮 | 换 PrimaryButton / PressFeedback 包 | 主页双主卡是新门面, 入口按钮应该跟 CheckInButton 一样"被听见" |

### F5. 禁用态假反馈残留 — ✅ 已闭环

`press_feedback.dart:104` `if (!widget.enabled) return widget.child` + 全部 4 个内建按钮集中器传 `enabled:`。EM-14 修复实锤, 0 残留。

---

## 3. 缓动与时长

### F6. ease-in 残留 — ✅ 干净

全 lib 唯一 ease-in 系曲线 = `AppMotion.curveAccelerate` (`Curves.easeInCubic`), 仅用于 exit/dismiss (`app_motion.dart:96`, 用法 `check_in_button.dart:129` switchOut)。emil 规则"入场 ease-out / 出场 ease-in (果断)"——正确。

### F7. >300ms UI 动画残留 — 见 F2 (400ms FadeIn 族) [已计入]

无其他 >300ms 硬编码。`stat_card.dart:96` TweenNumber 默认 400ms — 数字递增在主页 4 StatCard, 仅值变化时触发, occasional, 可接受; 但 emil 建议数字 tween 150-250ms:

| Before | After | Why |
| --- | --- | --- |
| TweenNumber/StatCard 数字递增 400ms | 250ms (durNormal) | 数字状态指示应"快而准", 400ms 让更新显得迟滞 |

### F8. 曲线/时长集中度 — ✅ 优秀 (R31 后无回归)

- 全 lib `Curves.` 硬编码 = **0** (app_motion.dart 外, grep 证实 check_in_button.dart:225 只是注释)
- 全 lib `Animated*` duration 裸值 = **0** (grep `duration:` 全部走 Motion.duration / MotionScheme / widget 参数)
- 出场<入场已落实: fadePage reverse 200<250, slideUpPage reverse 250<400 (`app_routes.dart:54/70/96`)

### F9. 路由过渡细节

`slideRightPage` 用 `Offset(0.1, 0)` 10% 位移 (`app_routes.dart:75`) — 比 Material 默认 100% 微妙, 符合 Apple Health 轻过渡定位。curveStandard (easeOutCubic) 入场 — 正确。

---

## 4. Spring

### F10. gentle/bouncy 0 caller — 死代码 [P3 | 架构 | 低]

`spring.dart:71-84`: `Spring.standard` 有真 caller (`check_in_button.dart:268`), `gentle`/`bouncy` 仍 0 runtime caller (文件头注释自认)。R112-03 已删 enum+factory, 留下 2 个"spec §3.4.3 完整模型面"。

| Before | After | Why |
| --- | --- | --- |
| gentle/bouncy 0 caller 保留 | 接真 caller 或删 (守门员 `check_apple_health_claim` 已能防假声明) | emil: 死代码 = 债。`bouncy` 天然候选 = celebration overlay (替换 curveBackOut TweenSequence), 接了才构成"spec 双轨制"闭环 |
| celebration_bounce 用 curveBackOut 模拟弹跳 | celebration 用 `Spring.bouncy.toSimulation()` | 物理模型已有却不用, 曲线模拟过冲在 60fps 下形态死板 |

---

## 5. 动效细节

### F11. scale(0) 入场残留 — celebration_bounce [P2 | 底层 | 低]

R113 报告 P2 未修, **验证仍存在**: `celebration_bounce.dart:48` `Tween(begin: 0.0, end: 1.2)` — 从 scale 0 蹦出, 违反 emil "nothing appears from nothing"。

| Before | After | Why |
| --- | --- | --- |
| `Tween(begin: 0.0, end: 1.2)` 从无到有 | `Tween(begin: 0.6, end: 1.2)` (或 0.9) | 庆祝气泡应有"可见的瘪气形状"再膨胀; 0→1.2 是从虚空迸出 |

(对照: `fade_in.dart:102` 用 0.92 起 — 正确样板。)

### F12. stagger 纪律 — ✅ 达标

- 主页: 30/60ms 封顶 (`home_page_state.dart:220-223`), 注释明确"远低于前庭敏感阈值 250ms"
- 日历/树洞列表: `staggerStepMs * i .clamp(0, staggerCapMs=150)` — 有 cap (`app_spacing.dart:50/54`) ✅
- FAB 工具栏: 30/60/90ms 无 cap (4 项固定, 可接受) — 但见 F2 时长问题
- 无 >80ms 单步 (唯一 90ms = 第 4 个 FAB 按钮)

### F13. AnimatedSize 布局动画残留 [P3 | 底层 | 中]

`home_fab_toolbar.dart:63-66` AnimatedSize (展开/收起) — 逐帧触发布局, emil 性能规则 "only animate transform/opacity"。已知 P3 债, 验证仍在。`notification_status_card.dart:287` AnimatedSize (设置页 subtitle 切换, occasional) — 低风险但同类。

| Before | After | Why |
| --- | --- | --- |
| AnimatedSize 高度动画 (2 处) | FAB 展开改 ClipRect+SizeTransition(Align) 或直接 AnimatedSwitcher+FadeIn | 高度动画在 60fps 触发整页 layout; Apple 自家 FAB 展开也是 fade+scale 组合 |
| — | — | 难度中: 工具栏 4 按钮展开需保留布局位移, 建议 Transform+Fade 组合 |

### F14. 组入场协调 — ✅ 已闭环

主页首帧: HomeHeader(0) → CheckInButton(30ms) → TodaySummaryCard(60ms), MoodHero/VentHero/PrimaryActionRow/Footer Duration.zero (`home_page_state.dart:259-271` 注释与实现 1:1)。Hero 卡不参与 stagger (立即可交互), 符合"stagger 永不阻塞交互"。`_EntrySpring` spring 0.95→1 与 hero 卡静态形成主次节奏 — 协调良好。

---

## 6. 一致性

### F15. spacing/typography magic 残留 [P3 | 底层 | 低]

mood_hero_card 已知 4 处 P3 — **验证仍存在**:

| Before | After | Why |
| --- | --- | --- |
| `mood_hero_card.dart:80` `EdgeInsets.all(16)` | `AppTokens.edgeInsetsMd` | token 已有同值集中器, R95 后 120+ 处已清, 这 4 处是漏网 |
| `mood_hero_card.dart:85` `SizedBox(height: 4)` | `AppTokens.spacingXxs` | 同上 |
| `mood_hero_card.dart:90` `SizedBox(height: 8)` | `AppTokens.spacingSm` | 同上 |
| `check_in_button.dart:83-89` pill 64/32/20 硬编码 | 保留 (有决策注释) | 一次性 pill 专用值, 注释已论证不抽 token — 接受 |

### F16. 空态 / snackbar 风格一致 — ✅ 干净

- 空态统一走 `EmptyState` + FadeIn (vent_list:224 withScale 仅 rare 空态) ✅
- snackbar 时长全走 3 档 token (`app_snack_bar.dart:42/50/69/95`), undo 8s 窗口合理 ✅
- vent Hero 过渡 (list↔detail) occasional 频度, tag unique (`vent_list_page.dart:476`) ✅

### F17. 死代码 widget [P3 | 架构 | 低]

`mood_quick_button.dart` — QuickMoodCarousel 在 1.1.0 round 5b 删除后, MoodQuickButton **0 lib caller** (仅 `mood_label_round8_test.dart` 引用)。emil: 死组件留在共享 widgets/ 会稀释集中器权威性。

### F18. token 集中器内部一致性 [P3 | 架构 | 低]

`app_tokens.dart:220-228` 直接定义 atomic tokens (legendDotSizeLg/avatarSizeMd/buttonHeightCompact…) 而非转发 app_spacing.dart — facade 破"只转发"契约 (其余 40+ token 全转发)。不影响行为, 但 3 个文件 (app_colors/typography/spacing) 里只有 spacing 有这类泄漏。

---

## 修复优先级排序

| # | 发现 | 严重性 | 难度 | 证据 | 预估 |
| --- | --- | --- | --- | --- | --- |
| 1 | F1 Tab 切换 3 类 transition 混用 (vent 400ms slide-up) | P2 | 低 | app_route_vent.dart:24-37 | 0.5h |
| 2 | F2 FadeIn 默认 400ms 于 tens/day 表面 + footer 漏门控 | P2 | 低 | fade_in.dart:41 / home_footer.dart:32 | 1h |
| 3 | F4 裸 InkWell/按钮 7 处无 scale 反馈 | P2 | 低 | daily_tracking_card.dart:48 等 | 2h |
| 4 | F11 celebration scale(0) 入场 | P2 | 低 | celebration_bounce.dart:48 | 0.25h |
| 5 | F10 gentle/bouncy 死代码 + celebration 接 Spring.bouncy | P3 | 中 | spring.dart:71/80 | 1h |
| 6 | F15 mood_hero_card 4 处 magic | P3 | 低 | mood_hero_card.dart:80/85/90 | 0.25h |
| 7 | F13 AnimatedSize 布局动画 (FAB 工具栏) | P3 | 中 | home_fab_toolbar.dart:63 | 1.5h |
| 8 | F17/F18 死 widget + facade 泄漏 | P3 | 低 | mood_quick_button.dart / app_tokens.dart:220 | 0.5h |

**修完 P2 四项 → 预估 8.7/10。**
