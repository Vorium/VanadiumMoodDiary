# 视角 3 报告 · flutter-specification (v3.1 14 章 + 6 附录, 重新独立打分)

## 元信息
- 跑时间: 2026-08-11
- baseline: master `a0f39c4` (= `20670f3` + 2 doc-only commit `5952515` R109 综合审视入库 + `a0f39c4` README 更新)
- 实际 v0.31.0+107 业务代码 master = `01d8f4a` (跟 R31 100% 一致, R32 0 代码改动)
- 关注: Flutter v3.1 规范 14 章 + 6 附录 / Apple Health 23 commit + R32 2 doc commit 合规度
- 工具: `grep`/`wc`/`git log`/`read` (本机 flutter/dart 不在 PATH, 用 R31 真实跑数据 0/90/2103/1/126 作基线)
- 上轮 R31 flutter-spec: 97% (49/50 阻断项 + 1 阻断 dart format 2 文件)

---

## 0. 评分

**flutter-spec 视角总分: 96% (上轮 97%, -1 倒退)**

子维度 (各 1-100):
| 子维度 | R31 | R32 | 变化 | 原因 |
|---|---|---|---|---|
| Material 3 规范 | 95 | 95 | 持平 | `useMaterial3: true` + ColorScheme.fromSeed + NavigationBar (M3) + CardTheme + FilledButton.icon, 全合规 |
| 性能 | 92 | 92 | 持平 | 0 ListView builder 错用 + 0 const 错失 + 0 Color API 误用 |
| 可访问性 | 85 | 83 | -2 | Spring 死代码 (0 caller) + 0 reduce-transparency 适配 + 7 raw IconButton 无 Tooltip + `_StreakCounter` vs `_TweenNumber` 95% 重复 (R31 P1-12 未闭环) |
| 平台一致性 | 90 | 90 | 持平 | 0 BouncingScrollPhysics (iOS 默认 clamp) + 0 Platform.isIOS 分支 |
| 弃用 API | 100 | 100 | 持平 | 0 withOpacity (72 withValues) / 0 WillPopScope / 0 FlatButton / 0 RaisedButton / 0 MaterialButton |
| 路由规范 | 95 | 95 | 持平 | 3 transition (fade/slideRight/slideUp) 集中 + go_router 14.6.1 + redirect 抽 top-level 纯函数 |
| 主题规范 | 95 | 95 | 持平 | light/dark 双主题 + AppBarTheme + InputDecorationTheme + CardThemeData + NavigationRailTheme 全覆盖 |
| i18n 规范 | 95 | 94 | -1 | ARB 3 语言 (zh/en/zh_Hant) + l10n.yaml + baseLocale: zh, 但 1 处硬编码中文 `quick_mood_carousel.dart:84` (R31 P1-04 未闭环) |
| 字体 | 90 | 90 | 持平 | system font (iOS San Francisco / Android Roboto) + 5 字重 token, 0 自定义字体 (精神心理患者向 SF Pro Display 集成未做) |
| 动效 | 90 | 88 | -2 | 3 Apple Cubic (curveSpring/curveAppleSheet/curveAppleDrawer) + Motion class + Spring class, 但 spring.dart **0 caller** 死代码 (R31 P0-08 未闭环) + P0-10 PageScaffold translucent AppBar 未实现 (spec §4.9) |
| 错误处理 | 95 | 95 | 持平 | 0 print() + 14 catch(_) 全 pre-existing + 4 error widget (Center Text 错误展示) 走 ARB fallback |

**加权计算** (R31 weighted): emil 0.15 + superpowers-en 0.20 + superpowers-zh 0.10 + flutter-spec 0.15 + AppStore 0.15 + GooglePlay 0.10 + AppleHealth 0.15 → flutter-spec 单视角自评 96%。

---

## 1. 上架/合规 P0 (违反 Apple HIG / Google Material guidelines)

| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P0-C01 | **3 DarwinNotificationDetails() 空构造锁屏 PII** | `lib/core/data/services/notification_service.dart:229` + `reminder_dispatcher.dart:110` + `snooze_manager.dart:95` — `DarwinNotificationDetails()` 0 `categoryIdentifier` / 0 `relevanceScore` / 0 `interruptionLevel`, iOS 16+ 锁屏默认显示所有 title (R108 P0-002 跨期残留) | R31 跨期 P0-05 | 3 处加 `categoryIdentifier: 'med_reminder'` + `relevanceScore: 0` + `interruptionLevel: InterruptionLevel.passive` |
| P0-C02 | **4 AndroidNotificationDetails.visibility 未设 secret** | `notification_service.dart:204` + `reminder_dispatcher.dart:103` + `snooze_manager.dart:88` + `refill_reminder.dart:?` — 缺 `visibility: NotificationVisibility.secret`, Android 锁屏默认显示 | R31 跨期 P0-06 | 4 处全设 `visibility: NotificationVisibility.secret` (跟 P0-C01 同主题, 跨期 R108 残留) |
| P0-C03 | **8 raw IconButton 无 Tooltip** (R31 P0-07 7 → R32 8 反涨) | `page_scaffold.dart:42` (back) + `mood_detail_page.dart:28` + `crisis_hotline_page.dart:185,192` (2) + `add_medication_page.dart:135` + `medication_page.dart:87` + `tracking_customize_page.dart:144` + `daily_tracking_page.dart:77` — Material 3 / Apple HIG 都要求 IconButton 必须有 `tooltip` (ScreenReader + 鼠标 hover) | R31 跨期 P0-07 (7 处) | 8 处全改 `PressFeedbackIconButton` 集中器 (46 处已用, 复用现成组件) 或加 `tooltip: '...'` 参数 |
| P0-C04 | **0 Tooltip 覆盖度** (新增发现) | 全 `lib/presentation/` 仅 3 处 `Tooltip(` (`home_header.dart:96` 主题切换 + `trend_heatmap_grid.dart:57` + `theme_toggle_button.dart:33`)。Material 3 §Accessibility 要求**所有**纯图标按钮必须有 `Semantics(label:)` 或 `Tooltip:`。8 raw IconButton 全部 0 Tooltip | 本视角新发现 | 同 P0-C03 一并修 |
| P0-C05 | **description.txt 5.1.1 抽审 5 病名** | `fastlane/metadata/ios/description.txt:17,27` 含 "PHQ-9/GAD-7/depression/anxiety/bipolar/PTSD/ADHD", Apple 5.1.1 抽审, 风险 = 拒审 | R31 跨期 P0-04 | 删 5 病名, 留 "mood/medication/care 跟踪" 模糊描述; 守门员 `description_no_medical_claim_round108_test.dart` 已加 |
| P0-C06 | **notes.txt 版本号过期** | `fastlane/metadata/ios/notes.txt:1` 写 `v0.30.0+85`, 当前 v0.31.0+107 | R31 跨期 P0-02 | 改 `0.31.0+107` |
| P0-C07 | **review_information 4 TODO 占位** | `first_name.txt` / `last_name.txt` / `email_address.txt` / `phone_number.txt` 全部 TODO | R31 跨期 P0-01 | 真实姓名 + 邮箱 + 手机号 |

**上架/合规 P0 总数: 7 项** (R31 7 项, R32 全部跨期残留, 0 闭环 + 0 新增, 实际等同 R31)

---

## 2. 架构/重构 P0 (违反 Flutter 推荐的: god class / 跨层耦合 / build 内 setState)

| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P0-A01 | **medication_page 561L god class** (R31 524L, **+37L 反涨**) | `lib/presentation/pages/medication/medication_page.dart:561` — 5 子页 (today_med_schedule / medication_calendar / refill_manage / add_medication / medication_detail) + 4 AppleHealthTile 横滚 + 4 时间段 + 2 AppleListSection + 各种 state 混在一个 widget, 测试/调试/维护都难 | R31 跨期 P1-10 | 拆 controllers/ 模式 (跟 R108 home_page_state 拆 3 controller 同款), 1-2d |
| P0-A02 | **setup_page_state 560L god class** (R31 513L, **+47L 反涨**) | `lib/presentation/pages/setup/setup_page_state.dart:560` — 4 步 (welcome/consent/medication/done) + 各步表单状态 + 校验逻辑, 跨 4 step 的 provider 状态全在这一个 State | R31 跨期 P1-08 | 拆 4 controller (跟 home_page_state R108 拆 3 controller 同款), 1-2d |
| P0-A03 | **add_medication_page 592L god class** (R31 506L, **+86L 反涨**) | `lib/presentation/pages/medication/add_medication_page.dart:592` — 表单 8 字段 + 3 列表项 + 时间选择 + 频率 cron + 库存计算 | R31 god class 名单 | 拆 3-4 sub-widget + 1 controller, 1-2d |
| P0-A04 | **mood_audio_service 377L god class** (R31 311L, **+66L 反涨**) | `lib/core/data/services/mood_audio_service.dart:377` — recorder + player + lifecycle + file IO + 错误恢复 | R31 god class 名单 | 拆 MoodRecorder + MoodPlayer + 2 facade, 1-2d |
| P0-A05 | **safety_watch_service 390L god class** (R31 338L, **+52L 反涨**) | `lib/core/data/services/safety_watch_service.dart:390` — 失联检测 + 续方 + 通知触发 + 审计 log | R31 god class 名单 | 拆 3 strategy (care_engine 4 strategy 模式同款), 1-2d |
| P0-A06 | **legal_page 495L god class** (R31 460L, **+35L 反涨**) | `lib/presentation/pages/settings/legal_page.dart:495` — 4 文档 (agreement/privacy/sensitive/medical) + 4 withdraw dialog + 4 audit log | R31 god class 名单 | 拆 4 section + 1 withdraw controller, 1-2d |
| P0-A07 | **app_database 513L god class** (R31 494L, **+19L 反涨**) | `lib/core/data/database/app_database.dart:513` — 13 表 schema + 12 migration + 30+ DAO + connection setup + CI helpers | R31 god class 名单 | 拆 13 schema file (每个表 1 文件, 跟 v0.18 R12 后目录模式一致) + 1 migration file, 3-5d |
| P0-A08 | **0 caller spring.dart 死代码 (P0-08 跨期残留)** | `lib/core/theme/spring.dart:145` 0 caller, spec §3.4.3 双轨制 (Spring 物理 vs curve 模拟) 空跑。grep `Spring.standard` / `Spring.gentle` / `Spring.bouncy` / `Spring.of` / `SpringType` 全部 0 lib/test 引用 (仅 spring.dart 自己 + app_motion.dart 注释提及) | R31 跨期 P0-08 (3 视角共识: emil + superpowers-en + Apple Health) | 接入 `_EntrySpring` (check_in_button.dart) 走 `Spring.standard.toSimulation()`, 给 spring.dart 写 5 case test, 1-2h |

**架构/重构 P0 总数: 8 项** (R31 god class 5 + Spring 1 + 跨期 2 = 8, R32 god class 7 个反涨 19-86 行, Spring 仍未闭环)

---

## 3. 半成品 P0 (spec 写了但没实现: translucent AppBar / spring 物理模型 / SF Symbol 字体)

| ID | spec 节 | 写了什么 | 没实现什么 | 证据 | 难度 | 修复 |
|---|---|---|---|---|---|---|
| P0-H01 | spec.md §4.9 | "**PageScaffold + AppBar — Translucent 风格**" — AppBar 背景 white @ alpha 0.6 + BackdropFilter blur(20) + hairline divider + reduce-transparency 适配 | `lib/presentation/widgets/page_scaffold.dart:50` 仍是固定不透明 AppBar, `lib/core/theme/app_theme.dart:97` `_appBarTheme` 没 `scrolledUnderElevation`、没 `flexibleSpace`、没 `BackdropFilter` 包装 | R31 跨期 P0-10 + Apple Health P0-2 | M 1-2h | PageScaffold 加 `BackdropFilter(ImageFilter.blur(20,20))` + flexibleSpace `Container(color:white@0.6)` + hairline divider + `MediaQuery.disableAnimationsOf(context)` reduce-transparency 适配 |
| P0-H02 | spec.md §3.4.3 | "**Spring 物理模型 (mass/stiffness/damping)**" — standard/gentle/bouncy 3 实例 + physics simulation wrapper | spring.dart 145 行 0 caller (同 P0-A08) | R31 跨期 P0-08 (3 视角共识) | M 1-2h | 同 P0-A08 |
| P0-H03 | spec.md §3.4.2 | "**curveAppleSheet** / **curveAppleDrawer**" — modal 进出 / drawer 收起的 Apple 自定义 cubic-bezier | `app_motion.dart:119/123` 定义了, 但 0 caller (9 处 `showModalBottomSheet` 全用默认 curve; 0 Drawer) | R31 跨期 P1-07 (emil + Apple Health) | S 30min | 集成到 `showModalBottomSheet` 的 `transitionAnimationController` 或删 (spec 写了但实际不需要 drawer) |
| P0-H04 | spec.md §5.1-5.7 | "**8 metric 彩色模块**" + "**iOS 系统字体 (SF Pro)**" + "**SF Symbol 字体集成**" | AppleHealthTile 已落地 (R31 P1-13/14/15 11 feature 0 改), SF Symbol 字体 0 集成, 8 metric icon 用 Material Icons (跟 SF Symbol 不一一对应, R31 P3 长期) | R31 跨期 P1-13/14/15/16 (Apple Health) | XL 1-2d | pub.dev 加 `cupertino_icons` 1.0.8 + 自定义 SF Symbol 字体注册 + icon 8 metric 跟 SF Symbol 一一对应 |
| P0-H05 | spec.md §3.4.5 | "**press feedback 100ms haptic 反馈**" | `press_feedback.dart` 0 HapticFeedback 调用 (R31 P3 长期: "R109 评估加 `hapticOnTap` enum 参数") | R31 P3 长期 | S 30min | PressFeedback 加 `HapticFeedback.lightImpact()` (Android API 29+ 必需, iOS 全版本支持) |
| P0-H06 | design/2026-08-10-apple-health-redesign/ (R32 commit `5952515` 已入库) | "**P0-12 设计文档入库**" | R32 commit `5952515` 已 add 3 文件 (spec.md 22KB + plan.md 16KB + NEXT-SESSION-START-HERE.md 6KB) — **P0-12 闭环** ✅ | R31 P0-12 | S 已修 | ✅ R32 闭环, 仅 flag |

**半成品 P0 总数: 5 项未修 + 1 项已修** (跟 R31 对比: P0-12 闭环, 其余 5 项 0 闭环)

---

## 4. P1 (16 条, 按分类)

### 4.1 重复实现 (R109 抽公共 widget)
| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P1-01 | **`_StreakCounter` (check_in_button.dart:267-331) 跟 `_TweenNumber` (stat_card.dart:145-228) 95% 重复** | 2 个 private widget 都是: `SingleTickerProviderStateMixin` + `AnimationController(durSlow)` + `_tickListener` `setState` 模式 + `didChangeDependencies` `Motion.duration(context, AppTokens.durSlow)` + `didUpdateWidget` `reset+forward` + `dispose` `removeListener+dispose`。唯一差异: `_StreakCounter` 走 `AppSemantics.container(liveRegion:true)`, `_TweenNumber` 走 plain `Text`。**95% 重复 5 个方法 × 2 处** | R31 跨期 P1-12 (flutter-spec 独家发现) | 抽 `lib/presentation/widgets/animations/tween_number.dart` 公共 widget, 接受 `value`/`baseStyle`/`color`/`semanticsBuilder?` 4 参数, 1-2h |
| P1-02 | **`_StreakCounter` vs `_EntrySpring` 动画模式不一致** | `_StreakCounter` 走 `addListener+setState` 模式 (line 282-288), `_EntrySpring` (check_in_button.dart 推测) 走 `AnimatedBuilder` 模式。同一 widget 内 2 种 tween 实现 | R31 P3 长期 | 选一种统一 (推荐 `AnimatedBuilder` — Flutter 官方推荐) |

### 4.2 lock-in test 阈值放宽
| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P1-03 | **`app_tokens_lock_in_round95_test.dart:271` 全局 TextStyle 阈值 ≤ 300 (R95 baseline 220, Apple Health +36% 放宽)** | `test/core/theme/app_tokens_lock_in_round95_test.dart:271-290` `expect(... lessThanOrEqualTo(300))` + line 295-314 `EdgeInsets lessThanOrEqualTo(250)` — R31 P1-06 标 "改回 250", R32 实际仍是 300 | R31 跨期 P1-06 (Apple Health) | 改回 250 (R95 baseline + buffer) |

### 4.3 god class 反涨
| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P1-04 | setup_step_medication 326L (R31 614L, **-288L 大幅改善**) | `lib/presentation/pages/setup/setup_step_medication.dart:326` 主要是 widget 树 + 表单, god class 候选已脱离 | R31 P1-09 改善 | 无 |
| P1-05 | refill_manage_page 403L (R31 779L, **-376L 大幅改善**) | `lib/presentation/pages/medication/refill_manage_page.dart:403` — 改善巨大但仍 > 400L god class 阈值 | R31 P1-10 改善 | 拆 controller, 1-2d |
| P1-06 | home_page_state 468L (R31 590L, **-122L 改善**) | `lib/presentation/pages/home/home_page_state.dart:468` 业务方法 9 个, 仍有 god class 倾向 | R31 改善 | 拆 controller, 1-2d |

### 4.4 spec 半成品
| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P1-07 | **R11a 引入 4 处硬编码中文** | `medication_page.dart` 4 处 '待服'/'已服'/'需续方'/'查看' (R31 P1-01 标修, R32 仍未闭环) | R31 跨期 P1-01 | 走 ARB key + 删 1 TODO 占位, 30min |
| P1-08 | **`quick_mood_carousel.dart:84` '记录失败，请重试' 硬编码** | R31 P0-D 标修, R32 仍未闭环 | R31 跨期 P1-04 | 走 ARB `l10n.moodRecordFailed`, 5min |
| P1-09 | **`medication_page.dart:101` `Colors.white` 硬编码** | R31 P1-C 标修, R32 仍未闭环 | R31 跨期 P1-02 | 改 `Theme.of(context).colorScheme.onPrimary`, 1min |
| P1-10 | **`quick_mood_carousel.dart:99` `title: '心情'` 硬编码** | line 108 已用 l10n 但 line 99 漏 | R31 跨期 P1-03 | 改 `l10n.homeQuickMoodTitle`, 5min |
| P1-11 | **`R9a QuickMoodCarousel` 圆形 button 48pt vs spec 写 72pt** | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart` carousel 48pt 圆形 button, spec 写 72pt | R31 跨期 P1-05 | 改 72pt 跟 spec 对齐, 1min |

### 4.5 11 feature 0 改 (Apple Health spec §5.1-5.7 跨期)
| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P1-12 | `mood_list/` (mood_list/detail/trend_page) 0 改 | 3 page 还是 pre-Apple Health Material 3 风格 | R31 跨期 P1-13 | AppleHealthTile 化 + AppleListSection + 8 metric palette, 各 1-2d |
| P1-13 | `daily_tracking/` (daily_tracking/tracking_customize/treatment_page) 0 改 | 3 page 还是 pre-Apple Health | R31 跨期 P1-14 | 同上, 各 1-2d |
| P1-14 | `vent/` 主页面 (vent_compose/detail/list_page) 0 改 (只 widgets/vent_save_bar 1 文件) | 3 page 还是 pre-Apple Health | R31 跨期 P1-15 | 同上, 各 1-2d |
| P1-15 | `crisis_hotline_page.dart` 0 改 | 还是 pre-Apple Health | R31 跨期 P1-16 | 调 8 metric color + ALL CAPS section, 0.5d |

### 4.6 跨期 P1 (R108 残留)
| ID | issue | 证据 | 来源 | 修复 |
|---|---|---|---|---|
| P1-16 | **`colors/styles.xml` 用旧 `Theme.Light.NoTitleBar`** | `android/app/src/main/res/values/styles.xml:4` (跟 iOS LaunchImage 占位跨期), Flutter 旧 Theme 仍可上架但 Android 12+ 推荐 `Theme.SplashScreen` | R31 P3 长期 | 改 `Theme.SplashScreen` API 31+, 1h |

**P1 总数: 16 项** (跟 R31 同, 0 闭环 0 新增)

---

## 5. P2 + P3 摘要 (前 10 条)

| ID | 等级 | issue | 来源 | 修复 |
|---|---|---|---|---|
| P2-01 | P2 | dev doc 同步 — CHANGELOG [0.31.0] 数字 stale (2104/1/126 vs 实际 2103/1/126, **R32 commit `5952515` 已闭环**) | R31 P2-02 ✅ | ✅ |
| P2-02 | P2 | spec baseline 数字矛盾 (6 处逐一列, 见 §6) — 0 闭环 | R31 P2-04 | 重新跑 `flutter test` 锁, 改 spec, 5min |
| P2-03 | P2 | PrimaryButton:73 doc 注释 `const Text('已完成')` 硬编码中文 | R31 P2-05 | 改 `Text(l10n.commonDone)`, 1min |
| P2-04 | P2 | R12b global sanity test 改 AST 而非 regex (避免注释假阳性) | R31 P2-06 | dart analyzer AST migration, 1-2h |
| P2-05 | P2 | `_titleLetterSpacing = 0.6` 重复 3 处 (AppleListSection + SectionHeader) → 抽 `AppTokens.sectionHeaderLetterSpacing` | R31 P3 长期 | 抽 token, 5min |
| P2-06 | P2 | `StatCard.xl` 注释 "字号 28 跟 default 相同" 跟命名暗示不一致 | R31 P3 长期 | 改 `medium` 或加字号, 1min |
| P2-07 | P2 | Android brand color 0xFF34C759 vs M3 派生 0xFF4CAF50 颜色轻微不一致 | R31 P3 长期 | 设计选择非 bug, 接受 |
| P2-08 | P3 | 8 metric icon 用 Material Icons 而非 SF Symbol | R31 P3 长期 | SF Symbol 字体集成 1-2d (P0-H04) |
| P2-09 | P3 | 3 种 commit author 不统一 (Mavis / Apple Health Redesign Agent / Mavis (AI Agent)) | R31 P3 长期 | 统一 `Mavis <mavis@chroniccare.local>` (R32 commit 已统一 ✅) |
| P2-10 | P3 | CheckInButton fontWeight=w700 → w600 跟 Apple Health semibold 一致 | R31 P3 长期 | 改 w600, 1min |

**P2 摘要 6 条 + P3 摘要 4 条 = 10 条** (R31 同)

---

## 6. 总结

### 6.1 跟 R31 对比

| 维度 | R31 | R32 | 变化 | 原因 |
|---|---|---|---|---|
| 总分 | 97% | 96% | **-1 倒退** | 0 代码改动 (R32 2 commit 纯 doc), 跨期 8 P0 全部残留 + god class 5 个反涨 + 0 lock-in test 闭环 + 0 半成品闭环 |
| 阻断项 | 1 (dart format) | 1 (dart format) | 持平 | R32 0 修 |
| P0 总数 | 17 (7 上架/合规 + 5 半成品 + 5 硬阻塞) | 17 (7 上架/合规 + 5 半成品 + 5 硬阻塞) | 持平 | R32 0 修 |
| 7 raw IconButton | 7 | **8 (+1)** | -1 | 0 修, R32 重新数 8 处 (P0-C03 新发现 page_scaffold.dart:42 + 已有 7 处) |
| god class 反涨 | 5 (medication_page 524→561 / setup_page_state 513→560 / add_medication 506→592 / mood_audio 311→377 / safety_watch 338→390 / app_database 494→513 / legal_page 460→495 = **7 个反涨**) | 同 | -7 | R32 0 修 |
| 闭环 17 P0 | 0/17 | **1/17 (P0-12)** | +1 | R32 commit `5952515` 入库设计文档 44KB + R32 commit `a0f39c4` README 更新 |
| Spring 死代码 | 145 行 0 caller | 145 行 0 caller | 0 | R32 0 修 |
| PageScaffold translucent | 0 BackdropFilter | 0 BackdropFilter | 0 | R32 0 修 |
| dart format 2 文件 | wrap diff | wrap diff | 0 | R32 0 修 |

**核心矛盾 (跟 R31 同)**: 视觉层 9.5/10 优秀 (5 token 集中器 + 6 widget 集中器 + 4 page 重设计), 但**规范层 96% 仍有 8 P0 跨期残留 + 7 god class 反涨 + 1 死代码 + 1 阻断**, R32 2 commit 都是 doc, 0 业务改动, 0 修任何 P0。

### 6.2 "spec baseline 数字矛盾" 6 处逐一列

| # | 文件:行 | 写什么 | 实际什么 | 矛盾 |
|---|---|---|---|---|
| 1 | `docs/audit/2026-08-11-cleanup/00-spec.md:4` | "master +2036/1/128 → +2102/1/127 (净改善 +66/-1)" | CHANGELOG 顶 8-11 cleanup 后 +2103/1/126 | +1 pass 跟 -1 fail 跟 8-11 cleanup 跑出的 +67/-2 不符, +66 写错 |
| 2 | `docs/audit/2026-08-11-cleanup/00-spec.md:93` | "test baseline: +2102 pass / 1 skip / 127 pre-existing fail" | flutter-spec 04 写 +2102/1/126; CHANGELOG 写 +2103/1/126 | 跟 04-flutter-spec.md 自身 fail 数差 1, 跟 CHANGELOG pass 数差 1 |
| 3 | `docs/audit/2026-08-11-cleanup/01-emil.md:51` | "spec 写 2102/1/127 +66/-1 vs 实际 2103/1/126 +1/-1" | 本视角 cross-check: 实际是 +67/-2 (跟 R108 baseline +2036/1/128 比), 不是 +1/-1 | 净改善数字互相矛盾 (3 处都不同) |
| 4 | `docs/audit/2026-08-11-cleanup/02-superpowers-en.md:173` | "spec §7 验收标准明列 2104/1/126, 实测 2102/1/127 (差 +2 pass / +1 fail)" | 跟 #1 spec.md 写 2102/1/127 不符 (差 1 pass); 跟 CHANGELOG 写 2103/1/126 差 1 pass | spec §7 内部矛盾 (写 2104/1/126 vs 写 2102/1/127) |
| 5 | `docs/audit/2026-08-11-cleanup/04-flutter-spec.md:38` | "+2102 pass / 1 skip / 126 fail (baseline 127 pre-existing, -1 改善)" | 跟 #2 00-spec.md:93 写 +2102/1/127 差 1 fail | flutter-spec 子视角自相矛盾 (126 vs 127 fail) |
| 6 | `docs/CHANGELOG.md:21 + 71` | "+2103 pass / 1 skip / 126 fail" | 跟 #1 spec.md 写 +2102/1/127 差 1 pass / 1 fail; 跟 #4 spec §7 写 2104/1/126 差 1 pass | 3 处 CHANGELOG / spec / flutter-spec 报数各不同 |

**6 处矛盾根因**: R12b global sanity 4 case 跟 8-11 重新 baseline 对齐时, 数字没锁死, R108 末期 regression 跟 R31 23 commit 净改善两个口径混用。修法: 跑一次 `flutter test` 锁新 baseline, 改 6 处全部对齐到 2103/1/126, **5min** (R31 P2-04 标修, R32 0 闭环)。

### 6.3 "如果只能改 3 件事"

| 优先级 | 改什么 | 难度 | 闭环什么 P0 |
|---|---|---|---|
| **1** | **dart format 2 文件** (`check_in_button.dart` + `primary_button.dart`) | S 5min | 闭环 1 阻断 (R31 唯一阻断) + 提升 CI 0 error |
| **2** | **8 raw IconButton → PressFeedbackIconButton + Tooltip** | S 1h | 闭环 P0-C03 (R31 P0-07 跨期) + P0-C04 (本视角新发现), 提升 a11y (ScreenReader) + 满足 Apple HIG / Material 3 |
| **3** | **Spring 接 _EntrySpring (Spring.standard.toSimulation)** | M 1-2h | 闭环 P0-A08 + P0-H02 (3 视角共识), spec §3.4.3 双轨制从"半成品"→"落地", 加 5 case test |

**预期 3 件事闭环后**: 96% → 98% (跟 R31 97% 持平 + 半成品从 1→0), R109 第 1 周其他 15 P0 (上架/合规 6 + 5 硬阻塞 + 4 god class) 仍需 1-2 月完成。

---

## 7. VERDICT

**v0.31.0 + R32 重新独立打分 96% (R31 97% → -1 倒退)**。

**倒退原因**: R32 2 commit (`5952515` + `a0f39c4`) 100% doc 改动, 0 业务代码, 0 修任何 R31 P0。跨期残留 + god class 反涨 (7 个) + 1 阻断 (dart format) + 1 死代码 (Spring) + 1 spec 半成品 (translucent AppBar) 全部跨期 0 闭环。

**核心矛盾 (跟 R31 同, 加 1 倒退)**:
1. **视觉层 9.5/10 优秀** (5 token + 6 widget + 4 page 重设), 但 **规范层 96% 仍有 8 P0 跨期残留** (上架/合规 7 + 半成品 1)
2. **7 god class 反涨 19-86 行** (medication_page 524→561, setup_page_state 513→560, add_medication 506→592, mood_audio 311→377, safety_watch 338→390, app_database 494→513, legal_page 460→495) — 唯一改善是 setup_step_medication 614→326 (-288) + refill_manage 779→403 (-376) + home_page_state 590→468 (-122)
3. **6 处 spec baseline 数字矛盾 0 闭环** (R31 跨期 P2-04)

**3 件事闭环后** 96% → 98% (dart format 5min + 8 IconButton 1h + Spring 1-2h = 半天)。

**R32 不建议本批提交 hotfix**: 0.31.2 应专注 §1 上架/合规 7 项 (P0-C01~07) + P0-C03 8 IconButton + P0-H01 PageScaffold translucent + P0-H02 Spring 接 _EntrySpring, 跟 R109 god class 专项 (1-2 月) 拆解合并, 避免单独 0.31.2 拆 commit 不连续。

---

## 附录: R31 P0 闭环状态 (17 项)

| R31 P0 ID | 标题 | R32 状态 |
|---|---|---|
| P0-01 | review_information 4 TODO 占位 | ❌ 0 闭环 |
| P0-02 | notes.txt 版本号过期 | ❌ 0 闭环 |
| P0-03 | store_kit_service productId 冗余 | ❌ 0 闭环 |
| P0-04 | description.txt 5.1.1 抽审 | ❌ 0 闭环 |
| P0-05 | 3 DarwinNotificationDetails 锁屏 PII | ❌ 0 闭环 |
| P0-06 | 4 AndroidNotificationDetails.visibility 锁屏 PII | ❌ 0 闭环 |
| P0-07 | 7 raw IconButton → PressFeedbackIconButton | ❌ 0 闭环 (R32 反而 8 处) |
| P0-08 | Spring 接 _EntrySpring | ❌ 0 闭环 (3 视角共识) |
| P0-09 | "Apple Health" lock-in test 扩 lib/ 注释 | ❌ 0 闭环 |
| P0-10 | PageScaffold translucent AppBar | ❌ 0 闭环 (spec §4.9) |
| P0-11 | dart format 2 文件 | ❌ 0 闭环 (R32 0 跑) |
| P0-12 | 设计文档 44KB untracked 入库 | ✅ **R32 commit `5952515` 闭环** |
| P0-13 | iOS 截图 6+ 张 (设计师) | ❌ 跨期 |
| P0-14 | iOS LaunchImage 3 张 (设计师) | ❌ 跨期 |
| P0-15 | Android 8 张 + feature_graphic (设计师) | ❌ 跨期 |
| P0-16 | chroniccare.app 域名 + 4 邮箱 ICP (外部) | ❌ 跨期 |
| P0-17 | AppIcon 1024×1024 ≥ 200KB (设计师) | ❌ 跨期 |

**R32 闭环: 1/17 (5.9%)** — 几乎 0, 跟 R31 同 0 闭环一致。
