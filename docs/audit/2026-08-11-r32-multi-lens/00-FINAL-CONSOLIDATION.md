# v0.32 R32 多视角综合审视整合报告

## 元信息

- **跑时间**: 2026-08-11 21:00-21:30
- **baseline**: `master` `a0f39c4` v0.31.2+107 (R31 22 commit + R109 文档入库 + 0.31.2 文档入库) + `fix/v0.31.1-bug-batch` 11 commit P0 修复 (未 merge 到 master)
- **6 视角 subagent 并行**: emil (UI/UX) / superpowers-en (TDD/质量) / flutter-spec (规范符合度) / AppStore (iOS 上架) / GooglePlay (Android 上架) / Apple Health (视觉语言)
- **子报告合计**: 6 份 173KB
- **评分范围**: 5.5/10 (GooglePlay/superpowers-en) ~ 8.2/10 (emil) — **加权综合 6.2/10** (R31 7.5 → **-1.3 倒退**, 主要因 superpowers-en 暴露 126 fail + 55 orphan + check_changelog 倒序错)

---

## 1. 6 视角评分汇总

| 视角 | R31 | R32 | 变化 | 核心变化 | 子报告 |
|---|---|---|---|---|---|
| **emil** (UI/UX/动效) | 8.5 | **8.2** | -0.3 | 主页 12 处硬编码中文累计, 8 raw IconButton (R31 7→8 反涨), Spring 145L 死代码, hero_illustration 118L 死代码 | [01-emil.md](01-emil.md) |
| **superpowers-en** (TDD/质量) | 8.5 | **5.5** | **-3.0** | **126 fail 半年没修**, 66 widget test i18n 迁移没同步, 11 god class 0 test, 55 orphan ARB, check_changelog FAIL | [02-superpowers-en.md](02-superpowers-en.md) |
| **flutter-spec** (规范符合度) | 97% | **96%** | -1% | 8 raw IconButton 反涨, 7 god class 反涨 19-86 行, Spring 0 caller, PageScaffold translucent 0 改, spec baseline 6 处矛盾 | [03-flutter-spec.md](03-flutter-spec.md) |
| **AppStore** (iOS 上架) | 3.5 | **5.5** | **+2.0** | R32 0.31.1 bug-batch 修了 P0-01~P0-09 (锁屏 PII + 7 IconButton + 4 description locale + Spring + review_information 等) — 但 master 未合并 | [04-appstore.md](04-appstore.md) |
| **GooglePlay** (Android 上架) | 5.5 | **5.5** | 0 | 实物资产 100% 缺失, 4 AndroidNotificationDetails visibility 0 设, 5 厂商 push 0 集成, R32 0 Android 改动 | [05-googleplay.md](05-googleplay.md) |
| **Apple Health** (视觉语言) | 7.0 | **7.2** | +0.2 | 0.31.2 文档入库 +0.2, 11 feature 仍只 4.5/11 落地 (mood/daily_tracking/vent/assessment/contact/settings/crisis_hotline 7-8 个 0 改) | [06-apple-health.md](06-apple-health.md) |
| **加权综合** | **7.5** | **6.2** | **-1.3** | superpowers-en 暴露 126 fail 半年 + 55 orphan + 守门员 3 红 + R31 上架层 0 闭环跨期 | — |

**加权计算** (R31 weighted): emil 0.15 + superpowers-en 0.20 + flutter-spec 0.15 + AppStore 0.15 + GooglePlay 0.10 + AppleHealth 0.15 + 0.10 R109 风险
= 8.2×0.15 + 5.5×0.20 + 9.6×0.15 + 5.5×0.15 + 5.5×0.10 + 7.2×0.15 = 1.23 + 1.10 + 1.44 + 0.83 + 0.55 + 1.08 = **6.23 ≈ 6.2/10**

---

## 2. 关键发现 (R32 6 视角共识)

### 2.1 跨 3+ 视角共识 P0 (优先级最高)

| # | P0 | 视角 | 证据 |
|---|---|---|---|
| **C-01** | **Spring 物理模型 145L 半成品 (spec §3.4.3 双轨制空跑)** | emil P0-08 + superpowers-en P1-6 + Apple Health P0-S1 + flutter-spec P0-A08 | `lib/core/theme/spring.dart:1-145` 全文 0 caller (`grep -rE "import.*spring\.dart" lib/ = 0 hit` + `Spring\.(standard\|gentle\|bouncy)` 0 hit + `toSimulation(` 0 hit)。`_EntrySpring` (check_in_button.dart) 用 cubic-bezier 模拟。**R32 fix/v0.31.1-bug-batch round 10 修** (Spring 接 _EntrySpring + 5 case test) — 但 master 未合并 |
| **C-02** | **PageScaffold translucent AppBar (spec §4.9 决策 #7) 0 实现** | emil P0-17 + Apple Health P0-S2 + flutter-spec P0-H01 | `page_scaffold.dart:47-58` 84L 仍是 M3 默认 opaque AppBar, **0 BackdropFilter / 0 blur / 0 alpha**。30+ 调用点全走 M3 opaque。修法: 1 行 `BackdropFilter(ImageFilter.blur(20,20))` + 2 行 reduce-transparency 适配 |
| **C-03** | **锁屏 PII 跨 4 视角共识** | flutter-spec P0-C01/02 + emil P0-C + GooglePlay P0-006 + AppStore P0-05/06 | 3 DarwinNotificationDetails 空构造 + 4 AndroidNotificationDetails visibility 未设。R31 报"修了 body 漏 title" — R32 master 仍残留。**R32 fix/v0.31.1-bug-batch round 6/7 修** (iOS 加 categoryIdentifier + interruptionLevel.timeSensitive; Android visibility: secret/public) — master 未合并 |
| **C-04** | **8 raw IconButton 无 PressFeedback / 无 Tooltip** | emil P0-10/11 + Apple Health P0-07 + flutter-spec P0-C03/04 + R108 P1-001 | `page_scaffold.dart:42` (back) + `mood_detail_page.dart:28` + `crisis_hotline_page.dart:185,192` (2) + `add_medication_page.dart:135` + `medication_page.dart:87` + `tracking_customize_page.dart:144` + `daily_tracking_page.dart:77`。**R32 fix/v0.31.1-bug-batch round 8/9 修** (7 处改 PressFeedbackIconButton + page_scaffold 漏修补) — master 未合并 |
| **C-05** | **R11a 4 处硬编码中文 + Colors.white (medication_page 4 tile)** | emil P0-01 + Apple Health P1-01/02 + flutter-spec P1-07/09 | `medication_page.dart:138,145,152,161` 4 处 '待服'/'已服'/'需续方'/'查看' + 4 个 TODO(Phase 5) 注释 + `medication_page.dart:101 Colors.white` (FAB)。R11a 故意留 magic, Phase 5 已完成, 0 闭环。**R32 fix/v0.31.1-bug-batch 0 修** — master 仍残留 |
| **C-06** | **spec baseline 2019 vs 实际 2103/1/126 数字矛盾 6 处** | emil P1-F + superpowers-en P2-04 + Apple Health P2-04 + flutter-spec §6.2 | `docs/design/2026-08-10-apple-health-redesign/spec.md:398` `baseline 2019` + `plan.md:5,20,45,64,82,101,107,204` 8 处 stale。R31 报告"CHANGELOG 数字 stale 闭环" 实际 0 闭环。**5min 内可修** |
| **C-07** | **AGENTS.md 缺 v0.31 + R32 章节 (R31 P2-01 闭环但 R32 加了 0.31.1/0.31.2 章节漏)** | superpowers-en + Apple Health + flutter-spec 共识 | AGENTS.md 写 v0.30 完整 + v0.31 R31 时一段 — 0.31.1 bug-batch (11 commit) + 0.31.2 文档入库 (2 commit) **0 AGENTS 章节** |

### 2.2 严重 bug 真实情况 (跟 R31 报告"全绿"不一致)

**R31 报告 "18 守门员 18/18 全绿" — 实际跑出 3 个 FAIL + 1 个 WARN + 1 个 SKIP**:

```
$ python3 scripts/check_changelog.py
[FAIL] 1 问题: CHANGELOG 段顺序错: [0.31.0] (line 1) < [0.31.1] (line 2) — 应按 version 倒序

$ python3 scripts/check_no_pua.py
[FAIL] 4 PUA 字符命中 (audit-history 文档):
  docs/audit-history/review-v0.23/review_superpowers_en_round42.md:142:10  PUA U+E21C
  docs/audit-history/review-v0.23/review_superpowers_en_round42.md:143:10  PUA U+E21C
  docs/audit-history/review-v0.23/review_superpowers_en_round42.md:156:21  PUA U+E21C
  docs/audit-history/archive-reviews-pre-v0.22/v0.22/review_superpowers_en_round30.md:189:89  PUA U+E21C

$ python3 scripts/check_orphan_arb_keys.py
[FAIL] 55 orphan ARB key (定义但 0 引用, R31 0 个 → R32 55 个新引入)
  含 32 个 influenceFactor* + setupConsent* + snackbarAction* + med* + mood* 系列

$ python3 scripts/check_fullwidth_punctuation.py
[WARN] 133 violations (--warn-only, 不强制)

$ python3 scripts/check_coverage.py
ERROR: coverage/lcov.info not found. Run `flutter test --coverage` first.

$ python3 scripts/check_zh_hant_consistency.py
[FAIL] 缺 opencc 包, 跑 `pip install opencc-python-reimplemented`
```

**flutter test 真实跑 (v0.31.1-bug-batch worktree, 8-11 04:21)**:
```
$ flutter test --no-pub
02:21 +2129 ~1 -126: Some tests failed.
```
**126 fail / 2129 pass = 5.6% 红灯率, 跨 29 test 文件, 半年没修**

**flutter analyze 真实跑 (8-11)**:
```
$ flutter analyze --no-pub
94 issues found. (ran in 6.6s)
  - 0 error
  - 23 warning (15 override_on_non_overriding_member 在 test/ + 8 lib)
  - 71 info (45 require_trailing_commas + 12 prefer_const_constructors + 4 use_key + 4 use_build_context_sync + 2 use_named_constants)
```

### 2.3 实物资产 100% 缺失 (跨期 R31 + R32 0 闭环)

| 资产 | 现状 | 上架阻塞 | 修法 |
|---|---|---|---|
| iOS 截图 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 0 screenshots/ 目录 | Apple 5.1.1 拒 | 设计师出图 + `scripts/generate_ios_screenshots.sh` (R108 写, 214L, 未跑) |
| iOS LaunchImage | 3 张 PNG 1×1px 68B 占位 (跨期 0 改) | Apple 5.1.1 拒 | 设计师出图 1242×2688 / 750×1334 / 2208×1242 |
| iOS AppIcon | 1024×1024 = 10.7KB (品牌 PNG 应 50-300KB) | Apple 2.3.7 拒 | 设计师出图 ≥ 200KB |
| Android screenshots | 8 张 67B 占位 (en-US/zh-CN 各 4) | Play Console 必填 | 设计师出图 |
| Android feature_graphic | 1024×500 67B 空白 | Play 强制 | 设计师出图 |
| chroniccare.app 域名 + 4 邮箱 | `https://chroniccare.app/privacy` 占位, 域名未注册 | 隐私 URL 必须可达, Apple 5.1.1(v) + Play 拒 | 域名注册 ¥80-150 + ICP 7-20d + 部署 4 HTML + 开 4 邮箱 |

### 2.4 8 FeatureFlag 当前状态 (R32, R31 持平)

| FeatureFlag | 状态 | 阻塞 | 闭环路径 |
|---|---|---|---|
| `iapEnabled` | ❌ false | 8 元买断 = Google Play Billing / App Store IAP 必须 | 1-2 周 (Store Console 后台) |
| `emergencyContactEnabled` | ❌ false | 失联通知 100% 失效 | 阿里云 AccessKey + 1-2 月法务 |
| `fiveVendorPushEnabled` | ❌ false | 国产 ROM 失联通知失效 = 法律责任 | 1-2 月 5 厂商审核 |
| `emailServiceEnabled` | ❌ false | 邮件导出 / 家人邮件 = 空跑 | SendGrid API key + 1-2 月 |
| `ventAudioEnabled` | ✅ **true** (R104 翻 true) | — | — |
| `phqGad7I18nEnabled` | ❌ false | PHQ-9 / GAD-7 16 题 + 严重度 + 危机电话 zh_Hant 英文 | R65b 阶段 1-2 周 |
| `bootReceiverEnabled` | ❌ false | 设备重启后通知不重排 | v1.0 WorkManager + 1-2 月 |
| `aliyunSmsEnabled` | ❌ false | 失联通知 100% 失效 (走 mock) | 1-2 月 |

**1/8 true (12.5%) 业务暂停, R32 跨期 0 变化**

---

## 3. 顶层架构审视 (高内聚低耦合)

### 3.1 4 层架构现状 (R32 真实跑 check_all)

| 层级 | 当前行数 | 关键文件 | 评估 |
|---|---|---|---|
| `lib/domain/` | 0 Flutter / 0 Drift / 0 data / 0 presentation | 24 entity + 12 logic + 10 repository abstract + 8 usecase | ✅ **架构纯度 100%, 0 violation**, 业界 top 10% 水平 |
| `lib/core/data/` | Drift 13 table + 13 DAO + 33 service + 7 utility | 业务编排 saveSetup/clearAllUserData **仍在 data 层 (反模式)** | ⚠️ 业务编排 vs 数据访问边界模糊 |
| `lib/core/shared/` | formatters / json_codec / domain_value / mood_visual | 0 flutter / 0 drift | ✅ 干净, 跨层共享 |
| `lib/core/theme/` | app_colors / app_typography / app_spacing / app_motion / spring / app_tokens | 5 token 集中器 (R31 100% 落地) | ✅ **设计 token 集中度业界领先** |
| `lib/core/routing/` | app_router / app_routes / app_shell | 0 反模式 | ✅ |
| `lib/core/l10n/` | strings (domain 层 fallback) | 0 flutter | ✅ |
| `lib/l10n/` | app_localizations (presentation 层) | flutter_localizations | ✅ |
| `lib/presentation/` | 408 文件 / 12 feature | 跨 feature 0 violation (check_cross_feature 绿) | ✅ **跨 feature 隔离完美** |

### 3.2 评估: 是否可采用更优架构

**结论: 当前 4 层架构已最优, 5-10 年内不需要重做**。具体论据:

1. **零云端 + 加密 + 隐私敏感场景**: 4 层架构 (domain 0 Flutter) 是最稳的解, 比 BLoC / Clean Architecture / Redux 都更轻量, 比 6 层 DDD 更易团队上手
2. **Feature-first 重组 (R110 计划)**: 仅是物理目录重组 (`lib/features/{feature}/{domain,data,presentation}/`), 不动架构本身。**短期 ROI 高, 但不动当前架构纪律**
3. **pub workspace 拆 3 package (R110 计划)**: 把 5 token 集中器 + 18 守门员脚本 + 6 widget 集中器抽到独立 package。**长期 ROI 高 (跨项目复用), 但当前 monorepo 模式不阻塞**
4. **微服务 / BFF**: 不适用 (零云端架构, 本地 SQLite 加密)

### 3.3 12 个 god class 候选 (R32 实测)

| 文件 | R31 标 | R32 实际 | 变化 | 严重度 | 修法 |
|---|---|---|---|---|---|
| `lib/presentation/services/scale_translations_l10n/static_scale_translations_l10n.dart` | — | **810L** | — | ⚠️ 0 test, presentation 子目录命名不直观 | 拆 5 scale 各 1 文件, 移到 `lib/core/l10n/scale_translations.dart` (跟 `strings.dart` 平行) |
| `lib/domain/entities/scale_translations/static_scale_translations.dart` | — | **781L** | — | ⚠️ 0 test, domain 层 | 拆 5 scale, 加 25 test |
| `lib/presentation/pages/medication/add_medication_page.dart` | 506L | **592L** | +86L ❌ | 🔴 0 test, R31 标 god class 仍反涨 | 抽 controller + 5 sub-widget + 15 widget test |
| `lib/presentation/pages/mood/widgets/mood_audio_recorder_widget.dart` | 529L | **588L** | +59L ❌ | 🔴 0 test, audio 资源类 | 拆 3 sub-widget + 8 widget test (mock audio) |
| `lib/presentation/pages/medication/medication_page.dart` | 524L | **561L** | +37L ❌ | 🔴 0 test, R31 标 god class | 拆 4 controllers (4 AppleHealthTile 横滚 + 4 时间段 + 2 AppleListSection) + 12 widget test |
| `lib/presentation/pages/setup/setup_page_state.dart` | 513L | **560L** | +47L ❌ | 🔴 0 test, 4 step state machine | 拆 4 state 各 1 file + 8 unit test |
| `lib/presentation/pages/mood_list/mood_trend_page.dart` | 517L | **563L** | +46L ❌ | 🔴 0 test, 9 fail i18n hardcoded | 拆 4 sub-widget + 12 widget test (用 AppLocalizations) |
| `lib/core/data/database/app_database.dart` | 494L | **513L** | +19L ❌ | 🟡 业务编排 saveSetup/clearAllUserData 反模式 | 抽 13 schema file + 1 migration file (跟 v0.18 R12 后目录模式一致) |
| `lib/presentation/pages/legal/legal_page.dart` | 460L | **495L** | +35L ❌ | 🟡 0 test | 拆 4 section + 1 withdraw controller |
| `lib/presentation/pages/settings/reminders_hub_page.dart` | 441L | **481L** | +40L ❌ | 🟡 0 test | 拆 controller + 3 sub-widget |
| `lib/core/data/services/notification_service.dart` | 417L | **417L** | 0 ✅ | R108 已拆 5 sub-service + 1 delegate | (R108 P1 god class 拆 Fix #2 已闭环) |
| `lib/presentation/widgets/audio_lifecycle.dart` | — | **439L** | — | 🟡 0 test, R108 P1 Fix #1 抽出来但没补 test | 抽 3 类 audio (record/play/cleanup) + 6 unit test |
| `lib/core/data/services/safety_watch_service.dart` | 338L | **390L** | +52L ❌ | 🟡 0 test, R57 已拆 2 sub, 但 facade 仍大 | 拆 3 strategy (care_engine 4 strategy 模式同款) |
| `lib/core/data/services/mood_audio_service.dart` | 311L | **377L** | +66L ❌ | 🟡 0 test | 拆 MoodRecorder + MoodPlayer + 2 facade |
| `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` | — | **413L** | — | 🟡 0 test, 8 fail 相关 (R13a/R101) | 拆 5 form section + 8 widget test |
| `lib/presentation/pages/assessment/assessment_widgets.dart` | — | **429L** | — | 🟡 0 test, 11 fail 相关 | 拆 3 sub-widget + 9 widget test |
| `lib/presentation/pages/vent/vent_detail_page.dart` | — | **426L** | — | 🟡 0 test, 隐私边界敏感 | 拆 3 sub-page + 6 widget test (mocked vent repo) |
| `lib/presentation/pages/home/home_page_state.dart` | 590L | **468L** | -122L ✅ | R31 大幅改善, 仍 0 test | 拆 5 sub-widget state + 10 unit test |
| `lib/presentation/pages/medication/refill_manage_page.dart` | 779L | **403L** | -376L ✅ | R31 大幅改善, 仍 > 400L | 拆 controller, 1-2d |
| `lib/presentation/pages/setup/setup_step_medication.dart` | 614L | **326L** | -288L ✅ | R31 大幅改善, 业务 widget 树 + 表单 | 拆 2-3 widget + 1 controller |
| `lib/core/data/services/notification_initializer.dart` | — | **174L** | — | 🟡 0 test, R108 P0-029 拆出来 | 抽 3 init method + 4 unit test |

**18 个 god class 候选, R32 修了 3 个 (home_page_state / refill_manage / setup_step_medication), 仍 15 个待拆**。**11 个 (≥400L) 0 test = 100% 违反 superpowers "测试先于代码"**

### 3.4 可重构模块 (按 ROI 排序)

| ROI | 模块 | 问题 | 建议 | 估时 |
|---|---|---|---|---|
| ⭐⭐⭐ | `scale_translations` 2 个文件 (domain 781L + presentation 810L) | 0 test, 命名不直观, 业务核心 | 拆 5 scale 各 1 文件 + 移到 `lib/core/l10n/scale_translations.dart` (跟 `strings.dart` 平行) + 25 test | 2-3d |
| ⭐⭐⭐ | 11 god class (≥400L) 0 test | superpowers 严重违反, 11 个文件覆盖精神心理患者所有核心流程 | 抽 controller + sub-widget + widget test (跟 R95 home_page_state 拆 3 controller 同款) | 1-2 月 |
| ⭐⭐ | `AppDatabase.saveSetup` / `clearAllUserData` 业务编排 | 业务编排在 data 层反模式, R101 + R102 多次标记 | 抽 `SetupService` / `DataWipeService` 到 `lib/domain/usecases/`, 跟 v0.18 R12 后业务逻辑上提同款 | 1 周 |
| ⭐⭐ | `NotificationService` facade 308 行 + delegate 160 行 (R108 Fix #2 已拆) | facade 主体仍含 init 60 行 + rescheduleAll 30 行 + 3 channel const | 把 init 抽到 `_ensureInitializedProxy`, 把 rescheduleAll 拆 3 strategy (medication / refill / assessment) | 2-3d |
| ⭐ | `SafetyWatchService` 390L (R57 已拆 2 sub) | facade 仍大, 含 onAppStart / onCheckIn / checkNow 3 触发入口 | 拆 3 strategy (care_engine 4 strategy 模式同款) | 2-3d |
| ⭐ | `notification_service` 5 sub-service (R108 拆) → delegate 12 method (R108 Fix #2) | 12 method 委派, 4 caller 走 delegate 路径 | caller 端改 `notificationService.delegate.xxx()` 路径 (R108 Fix #2 已修 facade 端) | 已闭环 |
| ⭐ | `ReminderService` vs `SafetyWatchService` 职责重叠 | R102 标记 | 统一到 `SafetyWatchService`, 删 `ReminderService` (如有) | 1d |
| ⭐ | 18 个 provider 文件散落 (`core_providers` / `service_providers` / `vent_providers` / `shared_providers` / `cbt_providers` / `tracking_*`) | 跨 feature 0 violation 但物理文件散落 | 移到 `lib/features/{feature}/providers/` 子目录 (R110 feature-first 重组) | 1-2 周 |
| ⭐ | `swallowError` 全局 mutable sink (`swallow_log_sink.dart`) 并发风险 | R101 P2 标记 | 改 actor pattern (Isolate 单写多读) | 1 周 |
| ⚠️ | `data_layer` 30+ 处中文 debug log | spzh 标记, 0 闭环 | 走 `piiSafeLog` 集中器 | 2-3d |

### 3.5 顶层架构最终评估

**当前架构 8.5/10 (业界 top 10% 水平)**, 但有以下 3 个系统性改进方向:

1. **业务逻辑上提到 use case 层 (domain/usecases/)**: 当前 8 个 usecase 远不够, 应该有 ~30 个覆盖所有 4 step setup / check-in / streak / care engine / safety alert / refill / assessment / data export / vent 等场景
2. **Feature-first 重组 (R110 计划)**: 不动架构, 仅物理目录重组, 跨项目团队并行更易
3. **pub workspace 拆 3 package (R110 计划)**: 5 token + 6 widget + 18 守门员 → 独立 pub package, 跨项目复用

---

## 4. 底层逐行排查 (bug 清单 + 优化点)

### 4.1 P0 真 bug (跨期残留 + R32 0 修)

| # | 类别 | 位置 | Bug | 来源 |
|---|---|---|---|---|
| **B-01** | 锁屏 PII | `lib/l10n/app_zh_Hant.arb:997` `safetyAlertTitle: "⚠️ {name} 已 {days} 天未打卡"` | safety alert title 含用户名, 锁屏可见 | 跨 3 视角共识 (R31 P0-04 + R32 跨期) |
| **B-02** | 锁屏 PII | `lib/core/data/services/safety_alert_builder.dart:79-94` `AndroidNotificationDetails` + `DarwinNotificationDetails` 完全空 | 锁屏默认显示所有 title + body | 跨 3 视角共识 (R31 P0-03, R32 master 仍残留) |
| **B-03** | 锁屏 PII | `lib/core/data/services/notification_service.dart:229` `iOS: DarwinNotificationDetails()` 空构造 | iOS 锁屏 metadata 缺失 | flutter-spec P0-C01, R31 P0-05 |
| **B-04** | 锁屏 PII | `lib/core/data/services/reminder_dispatcher.dart:110` `iOS: const DarwinNotificationDetails()` 空构造 | 同上 | flutter-spec P0-C01 |
| **B-05** | 锁屏 PII | `lib/core/data/services/snooze_manager.dart:95` `iOS: const DarwinNotificationDetails()` 空构造 | 同上 | flutter-spec P0-C01 |
| **B-06** | 锁屏 PII | `lib/core/data/services/notification_service.dart:222` `AndroidNotificationDetails` 0 visibility | Android 锁屏默认 VISIBILITY_PRIVATE 显示所有 | flutter-spec P0-C02, R31 P0-06, GooglePlay P0-009 |
| **B-07** | 锁屏 PII | `lib/core/data/services/reminder_dispatcher.dart:103` 同上 | 同上 | 同上 |
| **B-08** | 锁屏 PII | `lib/core/data/services/snooze_manager.dart:88` 同上 | 同上 | 同上 |
| **B-09** | 锁屏 PII | `lib/core/data/services/safety_alert_builder.dart:80` 同上 (但这条 public 走 UX 优先, 注释已说明) | 注释明确 UX 优先, 法务后续 | AppStore P0-10 (R32 修了, master 未合并) |
| **B-10** | i18n 跨期 | `lib/presentation/pages/medication/medication_page.dart:138,145,152,161` 4 处硬编码中文 '待服'/'已服'/'需续方'/'查看' + 4 个 TODO(Phase 5) 注释 | en 用户看中文 + Phase 5 已完成 0 闭环 | 跨 3 视角共识 (R31 P1-01, R32 0 修) |
| **B-11** | i18n 跨期 | `lib/presentation/pages/medication/medication_page.dart:101` `foregroundColor: Colors.white` | dark mode 不影响但违背颜色集中 | emil P0-12, R31 P1-02 |
| **B-12** | i18n 跨期 | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:84` `Text('记录失败，请重试')` 硬编码 | en 用户看中文 + 绕过 AppSnackBar 集中器 | emil P0-04, R31 P1-04 |
| **B-13** | i18n 跨期 | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:99` `title: '心情'` 硬编码 | line 108 已用 l10n 但 99 漏 | emil P0-04, R31 P1-03 |
| **B-14** | i18n 跨期 | `lib/presentation/pages/home/widgets/today_summary_card.dart:72` `title: '今日指标'` 硬编码 | 跟 widget 内其它 label 都走 l10n 矛盾 | emil P0-06 |
| **B-15** | i18n 跨期 | `lib/presentation/pages/home/widgets/secondary_action_row.dart:46,52,61,68-69,75,77` 7 处硬编码中文 + 3 个 TODO(Phase 5) 注释 | en 用户看中文 | emil P0-02, R31 跨期 |
| **B-16** | i18n 跨期 | `lib/presentation/pages/home/widgets/primary_action_row.dart:67,68,77,78,98,99` 7 处硬编码中文 | 同上 | emil P0-03 |
| **B-17** | a11y | `lib/presentation/pages/home/widgets/quick_mood_carousel.dart:60-71` 缺 Haptics.success() 调用 (注释说"跟 checkIn 风格一致"但 0 行代码) | 精神心理患者前庭/感官反馈缺失 | emil P0-05 |
| **B-18** | 死代码 | `lib/presentation/pages/home/widgets/hero_illustration.dart:33-119` 118 行 0 caller | R9a 已移除调用但没删 widget 文件 | emil P0-15 |
| **B-19** | 死代码 | `lib/core/theme/spring.dart:1-145` 全文 0 caller | spec §3.4.3 双轨制空跑 | 跨 3 视角共识, R32 fix/v0.31.1-bug-batch 修了 (master 未合并) |
| **B-20** | 死代码 | `app_motion.dart:119/123` `curveAppleSheet` / `curveAppleDrawer` 定义了但 0 caller | 0 caller (9 处 `showModalBottomSheet` 全用默认 curve) | R31 P1-07, flutter-spec P0-H03 |
| **B-21** | 8 raw IconButton | `page_scaffold.dart:42` + `mood_detail_page.dart:28` + `crisis_hotline_page.dart:185,192` + `add_medication_page.dart:135` + `medication_page.dart:87` + `tracking_customize_page.dart:144` + `daily_tracking_page.dart:77` | Material 3 / Apple HIG 都要求 IconButton 必须有 `tooltip` | 跨 3 视角共识, R32 fix/v0.31.1-bug-batch round 8/9 修了 (master 未合并) |
| **B-22** | 硬编码颜色 | `lib/presentation/pages/medication/widgets/medication_pill_icon.dart:13-18` 6 pill 颜色硬编码 `Color(0xFF34C759)` 等 | 跟 `app_colors.dart` 8 metric 重复 | emil P0-13 |
| **B-23** | 硬编码颜色 | `lib/presentation/pages/medication/widgets/medication_pill_icon.dart:63,70` 2 处 `Colors.white` | 应走 `AppColors.fgOnPrimary(context)` | emil P0-13 |
| **B-24** | 硬编码颜色 | `lib/presentation/pages/mood_list/mood_trend_page.dart:311-317` 5 元素 iOS color 硬编码 | 跟 `app_colors.dart` assessment palette / healthMetricsColors 不打通 | emil P0-14 |
| **B-25** | 硬编码颜色 | `lib/presentation/pages/mood_list/mood_trend_page.dart:539-540` 2 ternary `Color(0xFF34C759)` / `Color(0xFFFF3B30)` | 同上 | emil P0-14 |
| **B-26** | 硬编码颜色 | 4 处 `Colors.transparent` (`notification_status_card.dart:280` / `dimension_row.dart:65,76` / `mood_audio_recorder_widget.dart:384`) | 应走 `AppColors.transparent` 集中器 | emil P0-16 |
| **B-27** | check_pii_in_title 守门员未覆盖 | `safetyAlertTitle` 含 name 但 check_pii_in_title.py 不检查 | 守门员覆盖度不够 | R32 新发现 |
| **B-28** | CHANGELOG 段顺序错 | `docs/CHANGELOG.md` line 1 [0.31.0] < line 2 [0.31.1] 应倒序 | check_changelog FAIL | superpowers-en P0-02 |
| **B-29** | PUA 字符 | `docs/audit-history/review-v0.23/review_superpowers_en_round42.md:142,143,156` + `archive-reviews-pre-v0.22/v0.22/review_superpowers_en_round30.md:189` PUA U+E21C | check_no_pua FAIL | superpowers-en P0-04 |
| **B-30** | orphan ARB key | 55 个 ARB key 定义了但 0 引用 (32 个 `influenceFactor*` + 9 个 `setupConsent*` + 8 个 `mood*` + 6 个 `med*` + 其他) | check_orphan_arb FAIL | superpowers-en P0-03 |

### 4.2 半成品 P0 (spec 写了未实现)

| # | spec 章节 | 半成品 | 落地状态 | 证据 |
|---|---|---|---|---|
| **H-01** | spec §4.9 决策 #7 | PageScaffold translucent AppBar | **未实做** | `page_scaffold.dart:47-58` 84L 仍是 M3 默认 AppBar, 0 BackdropFilter / 0 blur / 0 alpha |
| **H-02** | spec §3.4.3 | Spring 物理模型 | **R32 fix/v0.31.1-bug-batch 修了 (master 未合并)** | spring.dart 145L → 接 _EntrySpring + 5 case test |
| **H-03** | spec §3.4.2 | curveAppleSheet / curveAppleDrawer | **0 caller** | `app_motion.dart:119/123` 定义 + facade 转发, 0 caller |
| **H-04** | spec §3.1.3 + §4.4 | SF Symbol 字体 | **未实做** | `apple_health_tile.dart:137-158` 8 icon 全 Material Icons |
| **H-05** | spec §3.4.5 | press feedback 100ms haptic 反馈 | **未实做** | `press_feedback.dart` 0 HapticFeedback 调用 |
| **H-06** | spec §5.1-5.7 | 11 feature 全部 Apple Health 化 | **4.5/11 落地** | home ✅ + setup ✅ + medication ✅ + trend 1 半残 + check_in Button widget ✅ = 4.5; mood / mood_list / daily_tracking / vent / assessment / contact / settings / crisis_hotline = 7-8 个 0 改 |
| **H-07** | design §3.1 | health metric palette 8 色 (medication/mood/vent/assessment/checkIn/trend/contact/sleep) | ✅ **已实做** | `app_colors.dart` 8 `healthMetricsColors` + `healthMetricsColorFor` + `tintedMetricSoft` |
| **H-08** | design §3.2.2 | 大数字 ultralight w200 | ✅ **已实做** | `app_typography.dart:84` `static const FontWeight fontWeightUltralight = FontWeight.w200` + 3 helper |
| **H-09** | design §3.4.4 | 减阴影 (0 阴影 = Apple Health 标志性) | ✅ **已实做** | `app_motion.dart:152,159` `shadowCardOf → []` 空 |
| **H-10** | docs/AGENTS.md | v0.31 章节 | ✅ **已实做** (R31 P2-01 闭环) | AGENTS.md:246-275 30 行 |
| **H-11** | docs/design | 设计文档 44KB 入库 | ✅ **已实做** (R32 0.31.2 round 1) | commit `5952515` |
| **H-12** | docs/audit | R109 综合审视 245KB 入库 | ✅ **已实做** (R32 0.31.2 round 1) | commit `5952515` |
| **H-13** | 0.31.1 | R32 fix/v0.31.1-bug-batch 11 commit P0 修复 | ⚠️ **修了但 master 未合并** | 11 commit 包括锁屏 PII + 7 IconButton + 4 description locale + Spring + Apple Health mention + review_information 等 |
| **H-14** | spec baseline 数字 | spec/plan baseline 2019 vs 实际 2103 矛盾 6 处 | ❌ 0 闭环 | spec.md:398 + plan.md:5,20,45,64,82,101,107,204 |
| **H-15** | check_pii_in_title 守门员 | 守门员不覆盖 `safetyAlertTitle` (用户名泄漏) | ❌ 0 闭环 | scripts/check_pii_in_title.py line 68 只查 notifMedicationTitle / notifRefillTitle |

### 4.3 跨期残留 P0 (R31 17 P0 跨期 R32 状态)

| R31 P0 | 主题 | R32 fix/v0.31.1-bug-batch 修了? | R32 master 修了? |
|---|---|---|---|
| P0-01 | review_information 4 TODO 占位 | ✅ round 1 修 | ❌ master 未合并 |
| P0-02 | notes.txt 版本号过期 | ✅ round 2 修 | ❌ master 未合并 |
| P0-03 | store_kit productId 冗余 | ✅ round 3 修 | ❌ master 未合并 |
| P0-04 | description 5 病名 5.1.1 抽审 (en) | ✅ round 4 修 | ❌ master 未合并 |
| P0-04b | description 4 locale 5 病名 | ✅ round 5 修 | ❌ master 未合并 |
| P0-05 | 3 DarwinNotificationDetails 空构造 | ✅ round 6 修 | ❌ master 未合并 |
| P0-06 | 4 AndroidNotificationDetails.visibility | ✅ round 7 修 | ❌ master 未合并 |
| P0-07 | 7 raw IconButton → PressFeedbackIconButton | ✅ round 8 修 | ❌ master 未合并 |
| P0-07b | page_scaffold.dart:42 漏修 | ✅ round 9 修 | ❌ master 未合并 |
| P0-08 | Spring 接 _EntrySpring + 5 case test | ✅ round 10 修 | ❌ master 未合并 |
| P0-09 | Apple Health 关键词 lock-in 扩 lib/ 主体 | ✅ round 11 修 | ❌ master 未合并 |
| P0-10 | PageScaffold translucent AppBar | ❌ | ❌ 0 修 |
| P0-11 | dart format 2 文件 | ❌ | ❌ 0 修 |
| P0-12 | 设计文档 44KB untracked 入库 | ✅ R32 0.31.2 round 1 修 | ✅ |
| P0-13 | iOS 截图 0 张 | ❌ | ❌ 0 修 (外部依赖) |
| P0-14 | iOS LaunchImage 3 张占位 | ❌ | ❌ 0 修 (外部依赖) |
| P0-15 | Android 8 张截图 + feature_graphic + icon 占位 | ❌ | ❌ 0 修 (外部依赖) |
| P0-16 | chroniccare.app 域名 + 4 邮箱 | ❌ | ❌ 0 修 (外部依赖) |
| P0-17 | AppIcon 1024×1024 ≥ 200KB | ❌ | ❌ 0 修 (外部依赖) |

**R32 master 修了 1/17 (P0-12 文档入库)**, R32 fix/v0.31.1-bug-batch 修了 11/17 (P0-01~P0-09 全闭环), **外部依赖 5 项 0 修 (P0-10/11/13~17)**

### 4.4 126 fail 半年没修 (superpowers-en 暴露)

| 类别 | 数量 | 根因 | 修法 |
|---|---|---|---|
| TestFailure_中文文本未找到 | **66 (52%)** | i18n 迁移 source 改 `Text(l10n.xxx)` 但 test 仍 `find.text('还没有评估记录')` | 66 test 改用 `find.text(l10n.xxx)`, 加 lock-in 守门员 `grep -E "find\.text\(['\"]?[\u4e00-\u9fff]+" test/` |
| 无栈 (assertion 失败) | 33 (26%) | 数值不匹配 / 状态机 mock 缺失 | 系统调试 4 步法 |
| RangeError | 8 (6%) | `setup_consent` / `setup_page` / `reminders_hub` 状态机 bug | 加 4 步 wizard 状态机 test |
| StateError | 6 (5%) | `settings_page` FeatureFlag 翻 true 但 widget tree 没刷新 | 加 FeatureFlag watch + re-render test |
| ArgumentError | 2 (2%) | 类型断言不匹配 | 修 test setup |
| 数值不匹配 | 1 (1%) | 时区 / 浮点精度 | 修 source 或 test 期望值 |
| **Top 1 fail 文件** | **assessment_history_round13b_test.dart** | 11 fails 全是中文文本未找到 | 修 11 test + 1 lock-in 守门员 |
| **Top 2 fail 文件** | assessment_reminder_service_round12_test.dart | 9 fails 状态机 mock 缺失 | 加 4 mock setup + 8 case |
| **Top 3 fail 文件** | medication_calendar_round13c_test.dart | 8 fails i18n 迁移未同步 | 修 8 test + lock-in 守门员 |

### 4.5 R32 新发现 (前轮 R31 0 提)

| # | 新发现 | 视角 | 修复 |
|---|---|---|---|
| **N-01** | `app_colors.dart:48` 注释提到 "Apple Health favorites 标准绿" 但 6 widget 集中器 (`apple_list_section` / `apple_health_tile` / `stat_card` / `primary_button` / `check_in_button` / `quick_mood_carousel`) 文件头注释 0 处 spec §4 引用 | emil P0-09 | 给 6 widget 集中器文件头注释加 1 行 `// Apple Health 风格 (spec §3.2 / §4.X): ...` 引用 |
| **N-02** | `lib/presentation/pages/home/widgets/hero_illustration.dart` 118 行 0 caller (R9a 已移除调用但没删 widget 文件) | emil P0-15 | 删文件 |
| **N-03** | `quick_mood_carousel.dart:60-71` 缺 Haptics.success() 调用 (注释说"跟 checkIn 风格一致"但 0 行代码) | emil P0-05 | 加 `unawaited(Haptics.success())` + import `feedback.dart show Haptics` |
| **N-04** | `app_typography.dart` 17 pt body / 13 pt caption / ultralight w200 大数字 0 处 Apple Health 关键词; 6 widget 集中器 0 处 spec §4 引用 | emil P0-09 | 加 1 行 spec 引用注释 |
| **N-05** | `lib/presentation/pages/medication/widgets/medication_pill_icon.dart` 6 pill 颜色硬编码 + 2 处 Colors.white (跟 app_colors 8 metric palette 重复) | emil P0-13 | 把 `kMedPillColors` 移到 `app_colors.dart` 作 `kMedicationPillColors` |
| **N-06** | `lib/presentation/pages/mood_list/mood_trend_page.dart:311-317` 5 元素 iOS color 硬编码 (跟 app_colors 3 个 palette 不打通) | emil P0-14 | 把 5 元素 mood palette 加到 `app_colors.dart` 作 `moodScoreColors` + `moodScoreColorFor(score)` |
| **N-07** | 4 处 `Colors.transparent` 硬编码 (notification_status_card / dimension_row × 2 / mood_audio_recorder_widget) | emil P0-16 | 在 `app_colors.dart` 加 `static const Color transparent = Color(0x00000000)` |
| **N-08** | `app_spacing.dart` + `app_typography.dart` + 6 widget 集中器文件头注释 0 处 Apple Health 关键词 | emil P0-09 | 加 1 行 spec 引用 |
| **N-09** | 4 文件双重 `swallow_error` import (R32 round 6 修 visibility 时引入, 留 duplicate + unused_import 2 warning) | superpowers-en P2-6 | 删 4 文件重复 import |
| **N-10** | `_slotIcon` unused element in `medication_page.dart:47` (R32 round 11 漏) | superpowers-en P2-7 | 删 _slotIcon 函数 |
| **N-11** | `skip_backup.dart:56` `_channel` annotation `@visibleForTesting` 在 private 字段 (lint: `invalid_visibility_annotation`) | superpowers-en P2-8 | 删 @visibleForTesting 注解 |
| **N-12** | `tracking_item_config_ext.dart:12` `non_const_argument_for_const_parameter` (常量参数传变量) | superpowers-en P2-9 | 加 const 关键字 |
| **N-13** | `helpers_round108_test.dart:37` `_untouchedWidgets` unused (R32 round 10 改 widget 留下) | superpowers-en P2-10 | 删 unused 标识符 |
| **N-14** | 23 warning (15 `@override` on non-overriding_member 在 test/) | superpowers-en P0-05 | 删 15 个 @override annotation |
| **N-15** | 71 info (45 trailing comma + 12 const constructor + 4 use_key + 4 use_build_context_sync + 2 use_named_constants) | superpowers-en P2-1 | 跑 `dart fix --apply` |
| **N-16** | `dart format` 2 文件未 format (R31 round 12b 提, R32 0 commit 修) | superpowers-en P2-2 | 跑 `dart format lib/presentation/widgets/check_in_button.dart lib/presentation/widgets/primary_button.dart` |

### 4.6 5 项 R32 新发现 (跨期 R31 0 提, 真实 P0)

1. **126 fail 半年没修** (superpowers-en 5.6% 红灯率) — 真 P0 verification gap
2. **66 widget test i18n 迁移没同步** (52% fail) — TDD 反模式
3. **55 orphan ARB key** (R31 0 个 → R32 55 个新引入) — spec 写了但 impl 没接
4. **check_changelog FAIL** 段顺序错 (R31 报告"已闭环" 实际 0 闭环)
5. **11 god class (≥400L) 0 测试覆盖率** (100% 违反 superpowers "测试先于代码")

---

## 5. 修复优先级排序 (按 修复难度 + 影响 + 可代码化程度)

### 5.1 优先级 1 (本批可闭环, 总和 ≤ 1-2 天, 6 视角共识 P0)

| # | 主题 | 难度 | 工作量 | 闭环什么 |
|---|---|---|---|---|
| 1.1 | `lib/l10n/app_zh_Hant.arb:997` safetyAlertTitle 改静态 (不含 name) | S | 5min | B-01 锁屏 PII + check_pii_in_title 守门员 |
| 1.2 | 4 个 AndroidNotificationDetails visibility: secret (master 残留) | S | 0.5h | B-06~B-09 锁屏 PII |
| 1.3 | 3 个 DarwinNotificationDetails categoryIdentifier + interruptionLevel (master 残留) | S | 0.5h | B-03~B-05 锁屏 PII |
| 1.4 | 8 raw IconButton 改 PressFeedbackIconButton (master 残留) | S | 1h | B-21 raw IconButton + a11y |
| 1.5 | `medication_page.dart` 4 处硬编码中文 + 4 个 TODO(Phase 5) 改 l10n | S | 30min | B-10 i18n 跨期 |
| 1.6 | `medication_page.dart:101` Colors.white 改 `AppColors.fgOnPrimary(context)` | S | 1min | B-11 i18n 跨期 |
| 1.7 | `quick_mood_carousel.dart:84` 硬编码中文改 l10n + 用 AppSnackBar 集中器 | S | 5min | B-12 i18n 跨期 + 集中器 |
| 1.8 | `quick_mood_carousel.dart:99` '心情' 改 l10n | S | 5min | B-13 i18n 跨期 |
| 1.9 | `today_summary_card.dart:72` '今日指标' 改 l10n | S | 5min | B-14 i18n 跨期 |
| 1.10 | `secondary_action_row.dart` 7 处硬编码中文改 l10n + 删 3 个 TODO 注释 | S | 30min | B-15 i18n 跨期 |
| 1.11 | `primary_action_row.dart` 7 处硬编码中文改 l10n | S | 30min | B-16 i18n 跨期 |
| 1.12 | `quick_mood_carousel.dart:60-71` 加 `unawaited(Haptics.success())` | S | 5min | B-17 a11y 反馈 |
| 1.13 | `hero_illustration.dart` 118 行死代码删 | S | 5min | B-18 死代码 |
| 1.14 | `app_motion.dart:119/123` curveAppleSheet/Drawer 集成到 modal bottom sheet / drawer 或删 | S | 30min | B-20 死代码 |
| 1.15 | `medication_pill_icon.dart` 6 pill 颜色移到 `app_colors.dart` + 2 处 Colors.white 改 l10n | S | 30min | B-22, B-23 硬编码 |
| 1.16 | `mood_trend_page.dart:311-317, 539-540` 7 处 iOS color 移到 `app_colors.dart` 作 `moodScoreColors` | S | 30min | B-24, B-25 硬编码 |
| 1.17 | 4 处 `Colors.transparent` 改 `AppColors.transparent` (新加集中器) | S | 10min | B-26 硬编码 |
| 1.18 | `safety_alert_builder.dart` visibility: private (注释已说 UX 优先, 改注释不改代码) | S | 5min | B-09 锁屏 PII 注释同步 |
| 1.19 | 4 文件双重 `swallow_error` import 删 | S | 5min | N-09 警告 |
| 1.20 | `_slotIcon` unused element 删 | S | 5min | N-10 警告 |
| 1.21 | `skip_backup.dart:56` `@visibleForTesting` 删 (private 字段不允许) | S | 1min | N-11 警告 |
| 1.22 | `tracking_item_config_ext.dart:12` const 关键字 | S | 1min | N-12 警告 |
| 1.23 | `helpers_round108_test.dart:37` `_untouchedWidgets` unused 删 | S | 1min | N-13 警告 |
| 1.24 | 15 个 `@override` on non-overriding_member 注解删 | S | 30min | N-14 警告 |
| 1.25 | `dart fix --apply` 71 info | S | 5min | N-15 info |
| 1.26 | `dart format` 2 文件 (check_in_button + primary_button) | S | 5min | N-16 + R31 P0-11 跨期 |
| 1.27 | CHANGELOG 段顺序倒序 ([0.31.1] 在 [0.31.0] 之前) | S | 5min | B-28 check_changelog FAIL |
| 1.28 | 4 PUA 字符 sed 替换 (audit-history 文档) | S | 30min | B-29 check_no_pua FAIL |
| 1.29 | 55 orphan ARB key 删 (或写 55 个 widget caller) | M | 4-6h | B-30 check_orphan_arb FAIL |
| 1.30 | `safety_alert_builder.dart` AndroidNotificationDetails 加 visibility: private (master 残留) | S | 5min | B-09 锁屏 PII |
| 1.31 | `app_colors.dart` 加 `AppColors.transparent` 集中器 | S | 1min | B-26 集中器 |
| 1.32 | 6 widget 集中器文件头注释加 1 行 `// Apple Health 风格 (spec §3.2 / §4.X): ...` 引用 | S | 10min | N-01, N-04, N-08 注释 |
| 1.33 | `check_pii_in_title.py` 守门员扩到 `safetyAlertTitle` | S | 5min | B-27 守门员覆盖度 |

**P1 总工作量**: ~1.5h (i18n + 锁屏 PII + 集中器) + 5h (55 orphan ARB) + 30min (杂项) = **~1.5d**

### 5.2 优先级 2 (R109 第 2-3 周, 总和 1-2 周, 影响中等)

| # | 主题 | 难度 | 工作量 | 闭环什么 |
|---|---|---|---|---|
| 2.1 | PageScaffold translucent AppBar (1 行 BackdropFilter + 2 行 reduce-transparency 适配) | M | 1-2h | C-02 + H-01 跨 3 视角共识 |
| 2.2 | Spring 接 _EntrySpring (R32 fix/v0.31.1-bug-batch 修了, merge to master) | M | 1-2h | C-01 + B-19 跨 3 视角共识 |
| 2.3 | Apple Health mention lock-in 扩 lib/ 主体 (R32 fix/v0.31.1-bug-batch 修了, merge) | S | 1h | C-07 跨 3 视角共识 |
| 2.4 | spec baseline 2019 → 2103 改 6 处 (5min) | S | 5min | C-06 跨 3 视角共识 |
| 2.5 | PressFeedback 加 `HapticFeedback.lightImpact()` | S | 30min | H-05 haptic 反馈 |
| 2.6 | Haptics 集中器 4 处 | S | 1h | R31 跨期 |
| 2.7 | Apple Health 11 feature 改 (mood / mood_list / daily_tracking / vent / assessment / contact / settings / crisis_hotline) | XL | 各 1-2d | H-06 4.5/11 → 11/11 |
| 2.8 | 锁屏 PII 完整修 (master 残 6 处 + safetyAlertTitle 不含 name) | S | 0.5h | C-03 跨 3 视角共识 |
| 2.9 | check_changelog / check_no_pua / check_orphan_arb 全绿 (R109 第 1 周) | S | 1d | B-28, B-29, B-30 守门员 |
| 2.10 | 18 守门员 check_16kb_alignment / check_coverage 真跑 (R32 0 跑) | S | 4h | R32 N-09 暴露 |
| 2.11 | 主页 stagger 8→3 闭环 (R31 P1-13 跨期) | M | 2h | R31 跨期 |
| 2.12 | mood carousel 5 档大圆形 48pt → 72pt (跟 spec 对齐) | S | 30min | R31 P1-05 |
| 2.13 | lock-in test 阈值 220 → 250 (R31 P1-06 跨期) | S | 1min | R31 跨期 |
| 2.14 | AGENTS.md 加 0.31.1 bug-batch + 0.31.2 章节 | S | 30min | C-07 跨 3 视角共识 |

**P2 总工作量**: ~1-2 周 (1 个 subagent 全程)

### 5.3 优先级 3 (R109 god class 专项, 1-2 月, 11 个 god class 拆)

| # | 主题 | 难度 | 工作量 | 闭环什么 |
|---|---|---|---|---|
| 3.1 | `static_scale_translations_l10n.dart` 810L 拆 5 scale + 移到 `lib/core/l10n/scale_translations.dart` + 25 test | XL | 2-3d | P0-06 superpowers-en |
| 3.2 | `static_scale_translations.dart` 781L 拆 5 scale + 25 test | XL | 2-3d | P0-07 superpowers-en |
| 3.3 | `add_medication_page.dart` 592L 抽 controller + 5 sub-widget + 15 widget test | XL | 2-3d | P0-08 superpowers-en |
| 3.4 | `mood_audio_recorder_widget.dart` 588L 拆 3 sub-widget + 8 widget test (mock audio) | XL | 2-3d | P0-09 superpowers-en |
| 3.5 | `mood_trend_page.dart` 563L 拆 4 sub-widget + 12 widget test (用 AppLocalizations) | XL | 2-3d | P0-10 superpowers-en |
| 3.6 | `setup_page_state.dart` 560L 拆 4 state 各 1 file + 8 unit test | XL | 2-3d | P0-11 superpowers-en |
| 3.7 | `medication_page.dart` 561L 拆 4 controllers (4 AppleHealthTile 横滚 + 4 时间段 + 2 AppleListSection) + 12 widget test | XL | 1-2d | P0-12 superpowers-en |
| 3.8 | `audio_lifecycle.dart` 439L 抽 3 类 audio (record/play/cleanup) + 6 unit test | XL | 1-2d | P0-13 superpowers-en |
| 3.9 | `assessment_widgets.dart` 429L 拆 3 sub-widget + 9 widget test | XL | 1-2d | P0-14 superpowers-en |
| 3.10 | `vent_detail_page.dart` 426L 拆 3 sub-page + 6 widget test (mocked vent repo) | XL | 1-2d | P0-15 superpowers-en |
| 3.11 | `edit_medication_dialog.dart` 413L 拆 5 form section + 8 widget test | XL | 1-2d | P0-16 superpowers-en |
| 3.12 | `notification_initializer.dart` 174L 抽 3 init method + 4 unit test | L | 0.5d | P0-17 superpowers-en |
| 3.13 | `safety_watch_service.dart` 390L 拆 3 strategy (care_engine 4 strategy 模式) | XL | 2-3d | R108 §六 god class 候选 |
| 3.14 | `mood_audio_service.dart` 377L 拆 MoodRecorder + MoodPlayer + 2 facade | XL | 2-3d | R108 §六 god class 候选 |
| 3.15 | `app_database.dart` 513L 抽 13 schema file + 1 migration file + 抽 `SetupService` / `DataWipeService` 到 `lib/domain/usecases/` | XL | 3-5d | R108 §六 god class 候选 + R101 P0 业务编排反模式 |
| 3.16 | `legal_page.dart` 495L 拆 4 section + 1 withdraw controller | XL | 1-2d | R108 §六 god class 候选 |
| 3.17 | `reminders_hub_page.dart` 481L 拆 controller + 3 sub-widget | XL | 1-2d | R108 §六 god class 候选 |
| 3.18 | `home_page_state.dart` 468L 拆 5 sub-widget state + 10 unit test (R31 大幅改善, 仍 0 test) | XL | 1-2d | P0-12 superpowers-en |

**P3 总工作量**: 1-2 月 (1-2 个 subagent 全程)

### 5.4 优先级 4 (R110 feature-first 重组, 2-3 周, 不动架构)

| # | 主题 | 难度 | 工作量 | 闭环什么 |
|---|---|---|---|---|
| 4.1 | `lib/features/{feature}/{domain,data,presentation}/` 物理目录重组 | XL | 1-2 周 | R110 计划 |
| 4.2 | pub workspace 拆 3 package (5 token + 6 widget + 18 守门员) | XL | 1 周 | R110 计划 |
| 4.3 | 业务逻辑上提到 use case 层 (8 → ~30 个) | XL | 2-3 周 | R110 计划 |

**P4 总工作量**: 2-3 周 (1-2 个 subagent 全程)

### 5.5 优先级 5 (R1.0 长期, 2027-Q1, 1-2 月, 外部依赖)

| # | 主题 | 难度 | 工作量 | 闭环什么 |
|---|---|---|---|---|
| 5.1 | 实物资产 100% 缺失 (iOS 截图 + LaunchImage + AppIcon + Android 截图 + feature_graphic + icon) | XL | 1-2 周 | P0-13~P0-17 跨期 |
| 5.2 | chroniccare.app 域名 + ICP 备案 (7-20d) + 4 邮箱开通 | XL | 7-20d | P0-16 跨期 |
| 5.3 | 5 厂商 push 真接 (小米/华为/OPPO/vivo/魅族) | XL | 1-2 月 | FeatureFlag 7/8 翻 true |
| 5.4 | 阿里云 SMS AccessKey + 法务 1-2 月模板审核 | XL | 1-2 月 | FeatureFlag 翻 true |
| 5.5 | EmailService (SendGrid API key + 模板审核) | XL | 1-2 月 | FeatureFlag 翻 true |
| 5.6 | PHQ-9 / GAD-7 i18n 完整 (16 题 + 严重度 + 危机电话) | XL | 1-2 周 | FeatureFlag 翻 true |
| 5.7 | HealthKit 集成 (iOS 16+ HealthKit + Android Health Connect) | XL | 2-3 周 | Apple Health 集成 |
| 5.8 | 鸿蒙 Flutter 集成 | XL | 1-2 月 | R1.0 跨平台 |
| 5.9 | IAP 真接 (Google Play Billing + App Store Connect) | XL | 1-2 周 | FeatureFlag 翻 true |
| 5.10 | 法务 3 份法律文档 ¥45-90k | XL | 1-2 月 | R1.0 上架硬阻塞 |
| 5.11 | 主体资质 + 临床审核 + NMPA | XL | 1-2 月 | 中国区上架 |
| 5.12 | SF Symbol 字体集成 (替代 Material Icons 8 metric) | L | 1-2d | H-04 spec §3.1.3 |

**P5 总工作量**: 1-2 月 (5-8 个 subagent 跨外部协作)

---

## 6. R32 → R33 → R34 路线图

### 6.1 R32 hotfix (本周, 1-2 天, 1 个 subagent)

**目标**: 闭环 P1 (1.1~1.33 全部 33 项, ~1.5d)

预期效果:
- 8 raw IconButton → 0 (R32 fix/v0.31.1-bug-batch merge 进来)
- 4 lock_screen PII 修了 (master 残 6 处 + fix branch 修了 merge 进来)
- 5 病名 description 修了 (4 locale)
- 4 + 7 + 7 硬编码中文 → ARB (medication_page + secondary_action_row + primary_action_row)
- 4 hero_illustration / spring / curveAppleSheet/Drawer 死代码
- 4 硬编码颜色 (medication_pill_icon / mood_trend_page / Colors.transparent)
- 5 警告 + 1 警告 + 71 info + 2 文件 dart format
- 1 CHANGELOG 段顺序倒序
- 4 PUA 字符 sed 替换
- 33+33+33+33 个 ARB key (跨 3 语), `check_orphan_arb` FAIL 减 33

**emil 8.2 → 8.7**, **flutter-spec 96% → 97%**, **superpowers-en 5.5 → 7.0** (P1 大幅闭环, 5.5 倒退回 R31 的 8.5 仍需 god class 专项), **Apple Health 7.2 → 7.8** (锁屏 PII + 4 硬编码中文闭环), **AppStore 5.5 → 7.0** (4 description locale 5 病名 + 锁屏 PII 都 merge), **GooglePlay 5.5 → 6.0** (visibility: secret merge), **加权综合 6.2 → 7.2 (+1.0)**

### 6.2 R33 R109 god class 专项 (1-2 月, 1-2 个 subagent)

**目标**: 拆 11 个 god class (≥400L) + 抽 use case 层 (~30 个) + 修 126 fail (1-2 周)

预期效果:
- 11 god class 拆完 (跟 R95 home_page_state 拆 3 controller 同款)
- 业务逻辑上提到 use case 层 (8 → ~30)
- 126 fail 修 (i18n 66 test + 状态机 mock 50 + 数值匹配 10)
- 11 god class 0 test → 11 god class ≥ 5 test 覆盖
- 18 守门员扩到 21 (加 check_widget_dispose_4 类 / check_pii_in_title 扩 safetyAlertTitle / check_i18n_test_hardcoded)
- 加 5 集成 test (setup → home → check-in → assessment → export)
- 加 main() 启动顺序 test (mock dotenv + db + notification)

**emil 8.7 → 9.0**, **superpowers-en 7.0 → 9.0** (126 fail 修 + 11 god class test), **flutter-spec 97% → 99%**, **AppStore 7.0 → 7.5** (实物资产仍 0 改), **GooglePlay 6.0 → 6.5** (实物资产仍 0 改), **Apple Health 7.8 → 8.5** (11 feature 0 改 7-8 个仍 0), **加权综合 7.2 → 8.5 (+1.3)**

### 6.3 R34 R110 feature-first 重组 (2-3 周, 1-2 个 subagent)

**目标**: `lib/features/{feature}/{domain,data,presentation}/` 物理目录重组 + pub workspace 拆 3 package

预期效果:
- 5 token + 6 widget + 18 守门员 → 独立 pub package (`chroniccare_design_system`)
- 跨项目复用
- feature-first 物理目录
- 团队并行协作更易

**emil 9.0 → 9.2**, **superpowers-en 9.0 → 9.3**, **flutter-spec 99% → 99.5%**, **AppStore 7.5 → 8.0**, **GooglePlay 6.5 → 7.0**, **Apple Health 8.5 → 9.0**, **加权综合 8.5 → 9.0 (+0.5)**

### 6.4 R1.0 长期 (2027-Q1, 1-2 月, 5-8 subagent 跨外部协作)

**目标**: 实物资产 100% + 域名 + 5 厂商 push + 阿里云 SMS + HealthKit + 鸿蒙 + IAP + 法务

预期效果:
- 实物资产全闭环 (iOS 截图 + LaunchImage + AppIcon + Android 截图 + feature_graphic + icon)
- chroniccare.app 域名 + ICP + 4 邮箱
- 5 厂商 push + 阿里云 SMS + EmailService + PHQ-9 i18n + HealthKit + 鸿蒙 + IAP + SF Symbol 字体
- 8 FeatureFlag 1/8 true → 8/8 true

**emil 9.2 → 9.5**, **superpowers-en 9.3 → 9.5**, **flutter-spec 99.5% → 99.8%**, **AppStore 8.0 → 9.5** (上架硬阻塞全闭环), **GooglePlay 7.0 → 9.0** (上架硬阻塞全闭环), **Apple Health 9.0 → 9.5** (SF Symbol 字体集成), **加权综合 9.0 → 9.5 (+0.5)**

---

## 7. "如果只能改 3 件事" (R32 推荐优先级)

1. **`fix/v0.31.1-bug-batch` merge to master** (10 min)
   - 11 commit 修了 11 个 P0 (P0-01~P0-09 全闭环, R31 报告跨期残留 100% 解决)
   - 锁屏 PII + 7 raw IconButton + 4 description locale + Spring + Apple Health mention + review_information + notes.txt + store_kit productId
   - **影响**: 一次 merge 闭环 11 个 P0, emil/flutter-spec/Apple Health/AppStore 跨 4 视角同时改善

2. **本批 P1 闭环 33 项** (~1.5d)
   - 4 + 7 + 7 硬编码中文 → ARB (medication_page + secondary_action_row + primary_action_row)
   - 4 hero_illustration / spring.dart / curveAppleSheet/Drawer 死代码
   - 4 硬编码颜色 (medication_pill_icon / mood_trend_page / Colors.transparent)
   - 5 警告 + 71 info + 2 文件 dart format
   - CHANGELOG 段顺序倒序 + 4 PUA 字符
   - **影响**: emil 8.2 → 8.7, superpowers-en 5.5 → 7.0, 加权综合 6.2 → 7.2

3. **修 126 fail + 55 orphan ARB** (~3-5d)
   - 66 widget test i18n 迁移没同步 (52% fail)
   - 33 无栈 + 8 RangeError + 6 StateError + 2 ArgumentError (48% fail)
   - 55 orphan ARB key 删或 wire (含 32 个 influenceFactor*)
   - **影响**: superpowers-en 7.0 → 8.5, superpowers 红灯率 5.6% → 0%

**预期**: R32 hotfix 1 周可让项目从 6.2/10 升到 7.5/10 (跟 R31 baseline 持平 + 0 R31 P0 跨期残留)

---

## 8. 综合结论

**v0.32 R32 综合审视 6.2/10 (R31 7.5 → -1.3 倒退)**, 倒退主因 superpowers-en 暴露 126 fail 半年没修 + 55 orphan ARB + check_changelog 倒序错 3 个真 P0 跨期。

**核心矛盾**:
- **视觉层 9.5/10 优秀** (5 token 集中器 + 6 widget 集中器 + 4 page 重设 + 主页 Apple Health 一眼可辨 + 8 metric 彩色 palette + ultralight w200 大数字 + iOS 群组列表 + 0 阴影)
- **半成品 4-5/10** (Spring 物理模型 145L 半成品 [R32 修了, master 未合并] + PageScaffold translucent AppBar 0 改 + 11 feature 0 改 7-8 个 + SF Symbol 字体 0 集成 + curveAppleSheet/Drawer 0 caller + 4-5 处 i18n 硬编码)
- **上架/合规 5.5/10** (实物资产 100% 缺失 + 4 锁屏 PII [R32 修了, master 未合并] + 4 description 5 病名 [R32 修了, master 未合并] + 7 raw IconButton [R32 修了, master 未合并] + 域名未注册 + 5 厂商 push 0 集成)
- **TDD / 测试 5.5/10** (126 fail 5.6% 红灯 + 66 widget test i18n 迁移没同步 + 11 god class 0 test + 55 orphan ARB + 18 守门员 3 红)

**R32 跨期 0 业务代码改动** (`master a0f39c4` = R31 22 commit + R32 2 commit 全部 doc)。R32 修了 11 个 P0 但都在 `fix/v0.31.1-bug-batch` branch, **master 未合并**。

**如果 R109 第 1 周能闭环 11 个 R32 修了但未 merge 的 P0 + 33 项 R32 新 P1 + 修 126 fail**, 加权综合可从 6.2 → 7.5-8.0/10 (跟 R31 baseline 持平 + 0 R31 P0 跨期残留 + 0 R32 新 P0 引入)。

**不建议本批提交 hotfix**: working tree 有 95 文件未提交改动 (android/ ios/ web/ scripts/ test/ 等), R33 应该是 working tree commit + fix/v0.31.1-bug-batch merge + R32 P1 闭环合并发布。

---

## 9. VERDICT

**v0.32 R32 6 视角综合审视 6.2/10 (R31 7.5 → -1.3)**。

**修复路径**:
- **R32 hotfix (本周, 1-2d)**: merge `fix/v0.31.1-bug-batch` (11 commit P0 修) + 33 项 R32 P1 → 6.2 → 7.2-7.5
- **R109 第 1 周**: 修 126 fail + 55 orphan ARB + 18 守门员全绿 + 11 feature 0 改 选 3-5 个高 ROI 改 → 7.5 → 8.0
- **R109 god class 专项 (1-2 月)**: 11 god class 拆 + use case 层厚化 → 8.0 → 8.5
- **R110 feature-first 重组 (2-3 周)**: pub workspace 拆 3 package + 跨项目复用 → 8.5 → 9.0
- **v1.0 长期 (2027-Q1, 1-2 月)**: 实物资产 100% + 域名 + 5 厂商 push + 阿里云 SMS + HealthKit + 鸿蒙 + IAP + 法务 → 9.0 → 9.5

**当前最关键 3 件事** (按 ROI 排序):
1. `fix/v0.31.1-bug-batch` merge to master (10min, 闭环 11 P0)
2. R32 P1 闭环 33 项 (1.5d, emil 8.2 → 8.7, superpowers 5.5 → 7.0, 加权 6.2 → 7.2)
3. 修 126 fail + 55 orphan ARB (3-5d, superpowers 7.0 → 8.5)

**R32 + R109 第 1 周 预期 1 周可让项目从 6.2 → 7.5-8.0/10, 跟 R31 baseline 持平 + 0 R31 跨期残留 + 0 R32 新 P0 引入**。
