# emil (Emil Kowalski Design Engineering) 审视报告 — 2026-08-10 R108 Revisit

## 0. 元数据
- 视角: **emil** (Emil Kowalski 设计工程)
- 审视者: subagent-emil-design-engineering
- 审视时间: 2026-08-10
- baseline: HEAD=ac2be71 (R100), working tree=30+M 26D, R108 进行中
- 范围: `lib/core/theme/` (app_tokens / app_motion / app_spacing / app_typography) + `lib/presentation/widgets/` (30+ widget 全清单) + `lib/presentation/widgets/animations/` (5 个动效) + `lib/presentation/pages/home/` (主页 8 层 stagger P0-5 验证) + `lib/core/routing/app_routes.dart` (3 类 transition) + `lib/main.dart` + `lib/main/boot_apps.dart` + 14 个分散 page 抽样 (mood / trend / medication / vent / daily_tracking / setup 等)

## 1. 整体评分 (0-10)

**8.5/10** — 设计 token 体系成熟 (motion / press / haptic / loading / shadow / radius 全部集中器化, 6 curve + 4 MotionScheme), prefers-reduced-motion 7 处全覆盖, 4 类 page transition 频度分层, R108 P0-5 主页 stagger 8→3 层已闭环, EmptyState/ErrorState 集中器走 Apple Health 风。仍残留 7 处 raw `IconButton(` 漏 PressFeedback 包装 (P1 体感割裂), `FadeIn` 默认 500ms 在 occasional 频度偏长, 散落 `BorderRadius.circular(2/6)` magic 3 处, 主页 _StreakCounter 每 tick 调 setState 缺 RepaintBoundary (性能), boot_apps.dart 占位 widget 多处 magic SizedBox, TODO_R108 P0#11-#13 上架前必做 5 项仍未闭环。整体是 "成熟收尾 + 关键上架前 P0 未完成" 阶段。

## 2. 关键发现 (按 P0/P1/P2/P3 排序)

### P0 (必修, 阻塞上架/严重 bug)
- [架构] **[P0-001] TODO_R108.md 上架前 P0 必修 5 项仍未闭环** — 修复难度: M | 工作量: 1-2d
  - 位置: `TODO_R108.md` (工作树根, R108 进行中)
  - 现状: 截图脚本 + Data Safety 验证 + keystore bash 版本 + health apps 问卷脚本 + domain registration guide 4 HTML 模板 + 5 个 lock-in test 全部 `[ ]` 未做。仅 keystore PowerShell 复用 + data_safety_form.py 复用 2 项 `[x]`。总计 18 个子任务中 16 个未完成。
  - 建议: R108 截止前 (README.md 写 "1-2 周" 窗口) 必须闭环至少 5 个 P0: (1) iOS 截图脚本 + 真图生成, (2) Android keystore 真生成, (3) Data Safety Form 验证脚本, (4) health_apps_questionnaire.py, (5) domain registration 4 HTML 模板。每个配 lock-in test, 走 `python scripts/check_sms_release_ready.py` 模式。R109 上 store 之前**阻塞级**。
  - 外部链接检查: 不涉及 (内部脚本 + 文件模板)

- [底层] **[P0-002] `FadeIn` 默认 `duration = AppTokens.durSlow` (500ms) 在 occasional 频度偏长** — 修复难度: S | 工作量: 0.5h
  - 位置: `lib/presentation/widgets/animations/fade_in.dart:41`
  - 现状: 文档注释写 "频度参考 — occasional: FadeIn with curveStandard", 但 default duration = durSlow (500ms) = delight 频度。**Default 跟文档矛盾**。EMIL 频度决策: occasional 应 = durNormal (300ms), rare = durSlow (500ms)。50+ caller 没传 duration → 全部跑 500ms, 体感"拖泥带水"。
  - 建议: 把 `duration = AppTokens.durSlow` 改为 `duration = AppTokens.durNormal`, 同步更新 docstring。`withScale: true` 时仍可走 durSlow (R40 决策保留)。R108 #5 stagger clamp 之后, FadeIn 是主页最常见的入场, 修这 1 行影响最大。
  - 外部链接检查: 不涉及

### P1 (应修, 影响品质)

- [架构] **[P1-001] 7 处 raw `IconButton(` 漏 `PressFeedbackIconButton` 包装** — 修复难度: S | 工作量: 0.5h
  - 位置 (grep 结果):
    - `lib/presentation/pages/crisis_hotline_page.dart:185, 192` (2 处)
    - `lib/presentation/pages/daily_tracking/tracking_customize_page.dart:144`
    - `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:77`
    - `lib/presentation/pages/medication/add_medication_page.dart:125`
    - `lib/presentation/pages/medication/medication_page.dart:76`
    - `lib/presentation/widgets/page_scaffold.dart:43` (back button, 全 App 最高频)
  - 现状: R57 集中 17 处后, 仍有 7 处用 raw `IconButton(icon: Icon(...), onPressed: ...)` 没 scale 反馈。**最严重是 page_scaffold.dart:43 back button** — 用户每次按返回都无 tactile feedback, 跟其他 16 处集中器体感割裂。emil "consistency" 原则, 全 App IconButton 必须走 PressFeedbackIconButton (含 `onPressed: null` 模式也支持)。
  - 建议: 7 处批量替换为 `PressFeedbackIconButton(...)`。page_scaffold 是 highest impact (全 App 公共组件), 优先修。30 分钟全改完。
  - 外部链接检查: 不涉及

- [架构] **[P1-002] Stale dead 注释 in `home_celebration_controller.dart:73-74`** — 修复难度: S | 工作量: 5min
  - 位置: `lib/presentation/pages/home/controllers/home_celebration_controller.dart:73-74`
  - 现状: 注释 `// v0.24 round 48 (emil P1-2): 实际走 CelebrationBounce via typedef @Deprecated` + `// 未来 v0.25+ 全部迁移后, 可删 celebration_overlay.dart 整个文件`。`celebration_overlay.dart` 已不存在 (`Test-Path` 返回 False, 2026 R108 状态)。`typedef` 也无 grep 结果 (`typedef.*CelebrationBounce|CelebrationOverlay` 0 命中)。注释已经 dead, 但留下 "via typedef" 这种误导性描述。
  - 建议: 删注释, 或简化为 `// v0.24 round 48 (emil P1-2): 统一走 CelebrationBounce 集中器 (R24+ 全部迁移后, v0.30 R108 已删 celebration_overlay.dart)`。R108 工作量极小, 顺手清。
  - 外部链接检查: 不涉及

- [底层] **[P1-003] QuickMoodCarousel '记录失败，请重试' 硬编码中文 SnackBar 违反 i18n** — 修复难度: S | 工作量: 0.5h
  - 位置: `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:101-103`
  - 现状: `ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('记录失败，请重试'), ...))` — 中文硬编码, 完全没走 `AppLocalizations.of(context).moodRecorderSaveFailed` 模式。跟 R65/R78/R90 i18n 化 (4599 字符中文 → ARB) 方向冲突, 也违反 sp-zh P0 i18n 守门员。**en/zh_Hant 模式用户看到中文**。
  - 建议: 改用 `AppLocalizations.of(context).moodRecorderSaveFailed` (新增 ARB key) 或复用 `AppSnackBar.showError(context, action: '记录心情', error: e)` 集中器。R107 已有 50+ 处 `AppSnackBar.showX` 集中, 这处是漏网。
  - 外部链接检查: 不涉及

- [底层] **[P1-004] TODO_R108.md 字符编码损坏 (mojibake)** — 修复难度: S | 工作量: 5min
  - 位置: `TODO_R108.md` (R108 文件)
  - 现状: `Get-Content` 看到 "澶嶇敤 / 瑕嗙洊 / 楠岃瘉 / 鍐?/ 璇︾粏 / 鏈€缁堟姤鍛" 全部是 mojibake (UTF-8 字节被当 GBK 解读)。说明文件用 GBK 保存, 或 PowerShell default encoding 不匹配。
  - 建议: 重新 `Write-File` with `[System.IO.File]::WriteAllText($path, $content, [System.Text.Encoding]::UTF8)`, 修 R108 任务清单可读性。不修的话 R108 后续接手 agent 看不到任务。
  - 外部链接检查: 不涉及

### P2 (可修, 优化)

- [底层] **[P2-001] 主页 `_StreakCounter` 60fps setState 缺 RepaintBoundary** — 修复难度: S | 工作量: 0.5h
  - 位置: `lib/presentation/widgets/check_in_button.dart:108-180`
  - 现状: `_StreakCounter` 走 `AnimationController` + `addListener` + `setState({_currentAnimated = ...})` 60 次/秒 调 setState, 触发整个 CheckInButton rebuild。跟 InkWell ripple 叠加, 在 60fps streak 动画期间 ripple 重画, 老款 Android 设备可能 jank。R71 (P5.4 性能) 给 CelebrationBounce 加了 `RepaintBoundary`, 但 `_StreakCounter` 漏。
  - 建议: 把 `AnimatedBuilder(animation: _controller, builder: ...)` 替代 `addListener + setState` 模式, 外层包 `RepaintBoundary` 隔离 rebuild 范围。R109 性能 review 阶段可一起做。
  - 外部链接检查: 不涉及

- [底层] **[P2-002] boot_apps.dart 占位 widget 多处 magic SizedBox heights** — 修复难度: S | 工作量: 0.5h
  - 位置: `lib/main/boot_apps.dart:90, 98, 153, 160, 174`
  - 现状: 5 处 `const SizedBox(height: 16)` / `height: 12` 散落 `MigrationAbortedApp` / `MigrationFailedApp` 占位 widget。R65 alibaba B-9 magic alpha + R56b emil token 化 (46 处 SizedBox → spacingXxxs/Xxs/chipGap/Xs/Sm/Md/Lg/Xl) 精神不一致。占位 widget 用户首次启动必看, 视觉必须 token 化。
  - 建议: 全部改为 `AppTokens.spacingMd` / `AppTokens.spacingSm` / `AppTokens.spacingXs`。
  - 外部链接检查: 不涉及

- [底层] **[P2-003] 3 处 raw `BorderRadius.circular(N)` magic** — 修复难度: S | 工作量: 10min
  - 位置:
    - `lib/presentation/pages/medication/add_medication_page.dart:145` (`circular(2)`)
    - `lib/presentation/pages/medication/medication_detail_page.dart:311` (`circular(6)`)
    - `lib/presentation/pages/mood_list/widgets/mood_factor_analysis.dart:123` (`circular(2)`)
  - 现状: 3 处裸数字, 跟 R65 拆 4 个 token 文件精神不符 (radius token 已在 app_spacing.dart:151-156 集中)。`circular(2)` 跟 `radiusChip` 关系? `circular(6)` 跟 `radiusInput` (8) 关系? 用户改 token 这 3 处不响应。
  - 建议: 加新 token `radiusMicro` (2) / `radiusSmall` (6) 到 app_spacing.dart, 3 处替换。或判断是否就是 `radiusChip` (8) / `radiusInput` (8) — 调一下确认是 token 化目标。
  - 外部链接检查: 不涉及

- [底层] **[P2-004] trend_assessment_chart / today_summary_header / today_summary_card magic SizedBox heights** — 修复难度: S | 工作量: 10min
  - 位置:
    - `lib/presentation/pages/trend/widgets/trend_assessment_chart.dart:41, 46` (`height: 8` / `height: 4`)
    - `lib/presentation/pages/daily_tracking/widgets/today_summary_header.dart:79` (`height: 4`)
    - `lib/presentation/pages/home/widgets/today_summary_card.dart:129` (`height: 4`)
  - 现状: 4 处裸数字 `4` / `8`。`AppTokens.spacingXxs` (=2) / `spacingXs` (=4) 已有, `4` 跟 `spacingXs` 一致, `8` 跟 `spacingXs`(R65 = 4) 不匹配, 实际是 `spacingXxs + spacingXxs` (2+2=4?) 或 `spacingSm` (8)。
  - 建议: 4 处批量替换, 改 spacing token。
  - 外部链接检查: 不涉及

- [架构] **[P2-005] `PressFeedback` 集中器不调 Haptics, 3 处 caller 重复手动调** — 修复难度: M | 工作量: 1h
  - 位置: `lib/presentation/widgets/press_feedback.dart:60-66` (API) + `home_fab_toolbar.dart:50` + `check_in_button.dart` + `quick_mood_carousel.dart`
  - 现状: R48 决策 "API 设计 OK, 不加 inheritPress 参数" — 30+ 调用点的实际行为是 PressFeedback 不调 Haptics, 由 caller 自行 `Haptics.light()` / `success()`。emil 频度: tens/day (按按钮) → 集中 Haptics 体感一致更好。但 3 处手动调说明 "好的默认值" 跟 "DRY" 矛盾。
  - 建议: 评估加 `PressFeedback(hapticOnTap: HapticsKind.success, ...)` 参数, 让 widget 接管。**3 处 caller 中 2 处 (check_in + quick_mood) 是 success, 1 处 (fab_toggle) 是 light**, 加 enum 默认值可解。或保留现状 + 加 doc 注释 "PressFeedback 不调 Haptics, caller 需自己 Haptics.tap() / success() / warning()", 让新 caller 不会忘。
  - 外部链接检查: 不涉及

### P3 (建议, 长期)

- [架构] **[P3-001] mood_audio_recorder_widget.dart:559 周期 100ms Timer.periodic 无视 reduce-motion** — 修复难度: M | 工作量: 0.5d
  - 位置: `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart:557-560`
  - 现状: `Timer.periodic(const Duration(milliseconds: 100), (_) { if (mounted) setState(() {}); })` 录音秒表走 100ms tick。reduce-motion 用户每秒 setState 10 次, 录音 30 分钟 = 18000 次 rebuild。emil "loading should feel fast, not dance" 哲学, 但录音秒表不算 loading 范畴 (用户**需要**实时秒数)。
  - 建议: 评估 `setState` 是否真的必要 — 如果秒表显示靠 `AnimatedBuilder` + controller.value, 可避免整 widget rebuild。同时尊重 reduce-motion → 整秒刷新 (1Hz 即可)。R109 性能 review 一起看。
  - 外部链接检查: 不涉及

- [架构] **[P3-002] TODO_R108 5 项 (P1-005 ~ P1-009) 上架前 5 大必做 (R107 报告 P0) 未在 R108 进行中跑完** — 修复难度: L | 工作量: 1-2d
  - 位置: README.md "R107 P0 13 项" 列表 vs TODO_R108.md
  - 现状: R107 P0 #6 (chroniccare.app 域名 + 2 邮箱未注册) 在 TODO_R108.md 是 "R108 P0#13", 但 lock-in test + 4 HTML 模板都未做。其他 R107 P0 #3 (锁屏通知 body 药名 PII) / #11 (en-US description "hypertension, diabetes" Apple 5.1.3 抽审) / #12 (main.dart 裸 developer.log release 仍输出) 在 working tree 看 — #12 已修 (R108 注释 "3 处 developer.log 守卫"), #3/#11 没看到对应 PR。
  - 建议: 跟 superpowers-sp / appstore 视角交叉, 在 FINAL-CONSOLIDATION 阶段统一 list 剩余 P0。
  - 外部链接检查: chroniccare.app 域名 + 2 邮箱占位符 — 必须替换为真注册内容才能上架

## 3. 外部链接 / 域名 / 邮箱 / URL 隐藏检查

| 位置 | 内容 | 状态 | 备注 |
|---|---|---|---|
| `TODO_R108.md` | "chroniccare.app 域名 + 2 邮箱" 占位 | **未隐藏** | R108 P0#13 进行中, lock-in test 验证 12 URL 占位正确, 必做 |
| `README.md` | R107 报告 "6 URL 不可达" 12 处 | **未隐藏** | 占位符阶段, 上架前必注册 |
| `home_celebration_controller.dart:198` | `homeAutofireFallbackName` (兜底药名) | **i18n 化** | 走 l10n, 无 PII 风险 |
| `app_tokens.dart` | 全 token 集中器, 0 外部 URL | OK | — |
| `animations/*.dart` | 5 个 widget 全 token 化, 0 外部 URL | OK | — |
| `feedback.dart` Haptics | 系统 API, 0 外部 URL | OK | — |
| `app_routes.dart` 3 transition | 纯 widget, 0 外部 URL | OK | — |

**总计**: 14+ URL/邮箱/域名占位符 (TODO_R108 + README + R107 报告), 全部需要 R108 闭环 (P0-001)。

## 4. 上架 / 架构 / 重构 / 半成品问题

### 4.1 上架相关 (必填, 影响 iOS/Android/Privacy)
1. **TODO_R108 P0#11-#13 (keystore / data safety / health apps / screenshots / domain) 5 大必做**: 18 个子任务中 16 个 `[ ]` 未完成 (P0-001)
2. **主页 stagger clamp** (`R108 P0-5`): **已闭环** ✅ — `home_page_state.dart:308-380` 把 8 层 FadeIn 改成 3 层 (header/summary/hero 保留 0/40/80ms 微 stagger), 5 层 (encouragement/carousel/primary/today/secondary) 改 `Duration.zero` 无动画。注释写 "前庭敏感用户 (约 35% 慢性病 / 精神心理患者) 报告不适" + "总累加 80ms 远低于前庭敏感阈值 (250ms)" — emil 决策跟 R107 文档完全对齐
3. **R108 P0#12 (main.dart 裸 developer.log release 仍输出)**: **已闭环** ✅ — `main.dart:82-94` 顶部 `FlutterError.onError` + `runZonedGuarded` 3 处加 `!kReleaseMode` 守卫, 走 LastErrorCapture 记录, 启动 banner 提示。lock-in test `test/main/log_release_guard_round108_test.dart`
4. **R108 P0#11a keystore bash 版本未做**: TODO_R108.md `[ ]`, **上架前必补**
5. **Data Safety Form / Health Apps questionnaire 脚本未做**: TODO_R108.md `[ ]`, 4 lock-in test 都没跑
6. **iOS 截图脚本 + 真图生成未做**: TODO_R108.md `[ ]`, R107 #8 "0 截图" 仍存在
7. **chroniccare.app 域名注册**: 4 HTML 模板 + lock-in test + 验证 12 URL 占位, 全部 `[ ]`

### 4.2 架构相关 (emil 视角)
- **app_motion.dart 集中器成熟** ✅: durFast(200) / durNormal(300) / durSlow(500) / durPress(160) / durPageTransition(100) + 6 curve (standard/subtle/decelerate/accelerate/delight/backOut) + 4 MotionScheme enum + Motion class (reduce-motion 包装) + 4 theme-aware shadow getter. R65 拆 4 文件 0 violation
- **PressFeedback 集中器成熟** ✅: scale 0.97 (emil 标准) + durPress 160ms + Motion.duration 包装, 30+ 调用点, 2 模式 (接管 tap / 不接管)
- **Haptics 集中器 4 档** ✅: tap/success/warning/light, 4 类操作触感
- **3 类 page transition 按频度分类** ✅: fadePage (主导航偶尔) / slideRightPage (子页 occasional) / slideUpPage (全屏深页 rare), 全部 Motion.duration 包装
- **prefers-reduced-motion 7 处覆盖** ✅: FadeIn / SlideUp / CelebrationBounce / PageTransitionSwitcher / PressFeedback / LoadingSkeleton Shimmer / app_routes transition, **精神心理患者前庭敏感标准, 这 7 处缺一不可**
- **R108 AudioLifecycleMixin** ✅: 抽 vent_compose + mood_audio_recorder 重复 50-65 行 state machine, 4 状态 enum + 4 抽象方法 + 共享 asyncDispose, vent_compose 495→~300 (-39%), mood_audio 530→~330 (-38%)

### 4.3 重构建议 (emil 视角)
- **R109 路线图保留 (AGENTS.md 提的 6 大 god class)**: R108 已拆 main.dart 488L + home_page_state 597L (3 controller) + AudioLifecycleMixin。**待拆**: medication_page (~480L) / home_page_state 减到 23K 字节还有减肥空间 / notification_service 426L / vent+mood_audio (2×500L, 已 mixin 化) / daily_tracking 7 widget
- **AppTokens 集中器 facade vs 4 子模块**: R65 拆 4 文件后, 老 caller 走 `AppTokens.xxx` facade 不变, 新 caller 走 `AppColors` / `AppTypography` / `AppSpacing` / `AppMotion` 子模块。R108 部分新代码已用 `app_colors.dart` 直接 import (medication_page.dart:16 `import 'package:chroniccare/core/theme/app_colors.dart';`), 模式正确
- **PressFeedbackIconButton 集中器覆盖度**: 23 处用 raw `IconButton(`, 16 处用 `PressFeedbackIconButton(`, 7 处漏 (P1-001)。R109 应作为清理目标
- **FAB toolbar stagger**: `home_fab_toolbar.dart:88-141` 4 工具按钮 stagger 0/40/80/120ms。**没 clamp** (`(i * AppTokens.staggerStepMs).clamp(0, AppTokens.staggerCapMs)` 模式没用)。3 项以下 OK, 4 项刚好在 120ms 不超 200ms cap, **当前 OK 但未来加第 5 个工具按钮会触发**, 加 clamp 防御

### 4.4 半成品 / TODO / 残缺功能 (必填, 跨 subagent 重点)
1. **TODO_R108.md 18 个子任务 16 个未完成** (P0-001)
2. **home_celebration_controller.dart:73-74 stale dead 注释** (P1-002)
3. **QuickMoodCarousel:101-103 硬编码中文 SnackBar** (P1-003)
4. **TODO_R108.md 字符编码损坏 mojibake** (P1-004)
5. **3 处 `BorderRadius.circular(2/6)` magic** (P2-003)
6. **5 处 boot_apps.dart magic SizedBox heights** (P2-002)
7. **4 处 chart / summary card magic SizedBox heights** (P2-004)
8. **PressFeedback 不调 Haptics 设计决策** (P2-005)
9. **mood_audio_recorder 100ms Timer.periodic 无视 reduce-motion** (P3-001)
10. **R107 P0#3 锁屏通知 body 药名 PII 未在 R108 找到对应修复** (P3-002 跨视角)

## 5. 总结 + 给整合者的建议

**emil 设计工程视角整体健康**, 4 层架构 + MotionScheme 4 档决策框架 + prefers-reduced-motion 7 处全覆盖, 跟 R95/R100/R107 cleanup 持续加固一致。**R108 进行中工作 90% 集中后台 (脚本/数据/服务层), 视觉层 90% 闭环**, 主页 8 层 stagger clamp 已完成, 主页 god class 拆 3 controller 已完成, AudioLifecycleMixin 抽完。

**给整合者 3 件事**:
1. **R108 截止前必须补 P0-001 (TODO_R108 5 大上架前必做)**: 这是 1-2 周窗口的硬截止, 不补就 R109 才能上 store。优先 keystore bash + iOS 截图脚本 + data safety 验证, 4 HTML 模板可后置
2. **emil P1 体感一致性 30 分钟就能闭环**: 7 处 raw `IconButton` → `PressFeedbackIconButton` + 1 处 stale 注释 + 1 处硬编码中文, **共 3-4 小时, ROI 极高** (全 App IconButton 体感一致, 跟 R57 已 17 处集中器模式闭环)
3. **R108 P0-5 主页 stagger clamp 已闭环 (8→3 层)**, 之前 R107 P0 列表可标 ✅。**但 R107 报告 P0-001 列表其他 12 项** (域名/邮箱/锁屏 PII/en-US 抽审等) 没在 TODO_R108.md 找到全部, 跟 superpowers-sp / appstore 视角交叉确认

**emil 视角评分 8.5/10**, 比 R95 9.0 略低 0.5: 不是质量下降, 是 R107 评分给了 "mature" 0.5 缓冲, R108 进行中状态没完成 5 大上架前 P0 应扣 0.5。R109 上 store 前 P0 闭环后回到 9.0+。

## 附录: 详细证据

### A. Motion token 体系 (`lib/core/theme/app_motion.dart`)

| Token | 值 | 用途 | 调用方 |
|---|---|---|---|
| `durFast` | 200ms | tens/day 微反馈 | PressFeedback, AppBar action |
| `durNormal` | 300ms | occasional 模态/切换 | PageTransitionSwitcher, check_in_button |
| `durSlow` | 500ms | rare 庆祝/深页 | CelebrationBounce, slideUpPage |
| `durPress` | 160ms | 按钮按下→回弹 | PressFeedback, PressFeedbackIconButton |
| `durPageTransition` | 100ms | 视图切换 (fade) | PageTransitionSwitcher |
| `shimmerCycleMs` | 1200 | LoadingSkeleton 呼吸周期 | _Shimmer controller |
| `snackBarDurationShort/Medium/Long` | 2/3/4s | AppSnackBar 3 档 | AppSnackBar.error/info/undo |
| `curveStandard` | easeOutCubic | 默认入场 | 6+ widget |
| `curveSubtle` | easeOut | tens/day 微弱 | MotionScheme.subtle |
| `curveDecelerate` | easeOutQuart | celebration / 大数字 | SlideUp 默认 |
| `curveAccelerate` | easeInCubic | exit / dismiss | check_in switchOut |
| `curveDelight` | elasticOut | onboarding 首次 | CelebrationBounce |
| `curveBackOut` | easeOutBack | 庆祝 overlay 主弹跳 | CelebrationBounce scale |
| `shadowCardOf` | theme-aware | 卡片阴影 (R49 silent bug 修) | 6+ widget |
| `shadowDialogOf` | theme-aware | 对话框阴影 | dialog |
| `shadowOverlayOf` | theme-aware | 浮层阴影 (FAB toolbar) | home_fab_toolbar |
| `scrimAlpha` | 0.54 | long-task modal 遮罩 | LoadingScrim |

**评估**: 16 个 motion token + 4 MotionScheme + Motion class 完整, R65 拆 4 文件 0 violation. R95 后 R107 加 `Motion.duration(context, dur)` 包装全部, reduce-motion 无视。

### B. prefers-reduced-motion 覆盖 (7 文件)

| 文件 | 处理 | 备注 |
|---|---|---|
| `animations/fade_in.dart:74-84` | didChangeDependencies 检查 + 跳到 1.0 + cancel delay timer | ✅ |
| `animations/slide_up.dart:72-80` | didChangeDependencies 检查 + 跳到 1.0 + cancel delay timer | ✅ |
| `animations/celebration_bounce.dart:80-86` | didChangeDependencies 检查 + 跳到 1.0 | ✅ |
| `animations/page_transition_switcher.dart:54-57` | Motion.duration + Motion.curve 包装 (R103 fix) | ✅ |
| `widgets/press_feedback.dart:84` | Motion.duration 包装 | ✅ |
| `widgets/loading_skeleton.dart:230-243` | _Shimmer didChangeDependencies 检查 + 跳到 1.0 + cancel timer | ✅ |
| `core/routing/app_routes.dart:47-48, 63-64, 89-90` | 3 transition helper 走 Motion.duration | ✅ |

**评估**: 7/7 全部覆盖, 精神心理患者 a11y 标准。**0 缺口**。

### C. PressFeedback 集中器 (v0.18 round 14 P0-8)

| API | 用途 | 调用方数 |
|---|---|---|
| `PressFeedback(onTap: ..., child: ...)` | 接管 tap (模式 1) | ~15 |
| `PressFeedback(child: ListTile(...))` | 不接管 tap (模式 2, child 自带 onTap) | ~15 |
| `PressFeedbackIconButton(onPressed/onTap)` | IconButton 集中器 (R57 17 处统一) | 16 |
| 内部: `Motion.duration + AppTokens.curveStandard` | reduce-motion + token 化 | ✅ |
| 内部: scale 0.97 (emil 标准) | 按下→回弹 160ms | ✅ |

**评估**: 2 模式 + 集中器成熟, 30+ 调用点。**唯一问题**: 7 处 raw `IconButton(` 漏包装 (P1-001)。

### D. R108 P0-5 主页 stagger clamp 验证

`lib/presentation/pages/home/home_page_state.dart:308-380` 完整修改:
- **修前** (R107 baseline): 8 层 FadeIn delay 0/40/80/120/160/200/240/280ms 累加
- **修后** (R108):
  - 3 层保留微 stagger: `header` (0ms) / `TodaySummaryCard` (40ms = `staggerStepMs`) / `HomeHeroIllustration` (80ms = `2 * staggerStepMs`)
  - 5 层改无动画: `EncouragementText` / `QuickMoodCarousel` / `PrimaryActionRow` / `TodayMedSchedule` / `SecondaryActionRow` 走外层 FadeIn → **外层 FadeIn 删**, 5 widget 直接暴露
  - 注释: "总累加 80ms 远低于前庭敏感阈值 (250ms)"

**评估**: ✅ **已闭环**, 8 层 → 3 层微 stagger + 5 层无动画, 完全对齐 R107 P0#5 + R107 README 提的 "主页 100+/day 频度 → 无动画" 频度决策。

### E. 主页 8 层 stagger grep 验证 (确认 R108 修完)

```
$ grep "FadeIn(" lib/presentation/pages/home/*.dart lib/presentation/pages/home/widgets/*.dart
.\home_page_state.dart:317:            FadeIn(    # header (0ms)
.\home_page_state.dart:324:            const FadeIn(    # TodaySummaryCard (40ms)
.\home_page_state.dart:334:            const FadeIn(    # HomeHeroIllustration (80ms)
.\widgets\home_fab_toolbar.dart:68:    FadeIn(    # 4 工具按钮 stagger 0/40/80/120ms
.\widgets\home_fab_toolbar.dart:88:    FadeIn(
.\widgets\home_fab_toolbar.dart:115:   FadeIn(
.\widgets\home_fab_toolbar.dart:139:   FadeIn(
.\widgets\home_footer.dart:32:         FadeIn(    # 2 项 (LastMedInfo + homeStillOnline) 0/40ms
.\widgets\home_footer.dart:44:         FadeIn(
.\widgets\notification_failure_banner.dart:31: return FadeIn(    # 错误时 banner, 0ms
```

**8 个 FadeIn 在 home 范围内, 全部走 staggerStepMs token 集中器**。主页 5 widget (encouragement/carousel/primary/today/secondary) **已无外层 FadeIn** ✅。

### F. Raw `IconButton(` 漏 `PressFeedbackIconButton` 包装 (P1-001 详细位置)

```
$ grep "IconButton(" lib/presentation -l | xargs -I {} sh -c 'echo "=== {} ==="; grep -c "PressFeedbackIconButton" {}; grep -c "IconButton(" {}'
```

7 处漏:
1. `lib/presentation/pages/crisis_hotline_page.dart:185, 192` (2 个 IconButton)
2. `lib/presentation/pages/daily_tracking/daily_tracking_page.dart:77` (1 个)
3. `lib/presentation/pages/daily_tracking/tracking_customize_page.dart:144` (1 个)
4. `lib/presentation/pages/medication/add_medication_page.dart:125` (1 个)
5. `lib/presentation/pages/medication/medication_page.dart:76` (1 个)
6. `lib/presentation/widgets/page_scaffold.dart:43` (1 个 back button — **全 App 最高频**)

### G. R108 P0#12 main.dart developer.log release 守卫验证 (已闭环 ✅)

```
$ grep -n "developer.log\|kReleaseMode" lib/main.dart
48:    // v0.30 R108 (P0#12, spen V-01): kReleaseMode 守卫避免 release 模式
...
87:    if (!kReleaseMode) {
88:      developer.log(
89:        'FlutterError',
90:        error: details.exception,
91:        stackTrace: details.stack,
92:      );
93:    }
```

3 处 developer.log 全在 `!kReleaseMode` 守卫内。boot_apps.dart 注释写 "总数仍 3 处 (全在 main.dart 顶层), 本文件不引入 flutter/foundation, 不需要 kReleaseMode 守卫" ✅

### H. magic SizedBox heights grep (P2-002 + P2-004)

```
$ grep -E "SizedBox\((width|height): (4|8|12|16|20|24|32|40)\)" lib/presentation -r
```

文件:
- `pages/home/widgets/today_summary_card.dart:129` (`height: 4`)
- `pages/daily_tracking/widgets/today_summary_header.dart:79` (`height: 4`)
- `pages/trend/widgets/trend_assessment_chart.dart:41, 46` (`height: 8`, `height: 4`)
- `lib/main/boot_apps.dart:90, 98, 153, 160, 174` (5 处 `height: 12` / `16` / `12` / `16` / `16`)

共 10 处 magic SizedBox heights, R56b (46 处 token 化) 后遗漏。

### I. `BorderRadius.circular(N)` magic 散落 (P2-003)

```
$ grep "BorderRadius\.circular(\d" lib/presentation -r
```

3 处: `add_medication_page.dart:145` (`circular(2)`) / `medication_detail_page.dart:311` (`circular(6)`) / `mood_factor_analysis.dart:123` (`circular(2)`)

### J. 测试 fail (R108 进行中预期)

`flutter test`: 124 fail + 1 skip + 1405 pass — **working tree 是 R108 进行中状态, 124 fail 是 R108 在做的工作** (按指令文件说明, 不算 P0)。emil 视角无 124 fail 相关的 P0/P1。

---

**emil 视角最终: 8.5/10 (持平 R107 9.0 微降 0.5, 因 R108 进行中状态 + 5 大上架前 P0 未闭环 + 7 处 IconButton 体感割裂 + 1 处硬编码中文 + 1 处 stale 注释, 上述全部 P0/P1 闭环后回到 9.0+)**

<!-- subagent: emil-design-engineering 完成时间: 2026-08-10T17:30:00+08:00 -->
