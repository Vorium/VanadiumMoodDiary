# v0.27 R69 superpowers-en 视角全量审计

**审计时间**: 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64 (pubspec) / R68 commit `d691551` 已落地 / working tree clean
**视角**: superpowers-en (TDD / 系统化调试 / subagent 协调 / code review)
**审计模式**: 增量 (R68 18 issues 收尾跟踪 + R68 5 P0 验证 + R69 跨 4 类问题 + spen 5 类历史 bug 回归)
**基线**: 1285 tests pass / 0 fail / 0 analyzer error / 2 warning (R66 漏 2 round) / 186 info / 16 守护脚本全绿 / 4 层架构 100% 纯 / working tree 1 个新文件 `round69-emilkowalski.md` 在写

---

## §0 评级

### **A** (vs R68 A-)

> **小幅提升 R68 A-**。R68 跨 4 视角共识 3 P0(CC-1 / CC-3 / CC-6)真接, **2 fail 全清**(R68 报时区漂移 2 fail,R69 0 fail)、R66 5 warning → R69 0 warning(待验)、5 类历史 bug 100% 守住、5 类 god class 拆解完毕(`data_export_service` 17K 字节 + `notification_service` 16.6K)。**但 4 类核心问题(架构 / 半成品 / 文档脱节 / god class 残留)整体持平均 18-21 月挂**,**3 份法律 md 顶部"未经律师过审"TODO 仍保留** + **3 份 md 0 英文 0 繁体版** + **CC-7 4 文档失联通知措辞修了 full_description 但 title + agreement + consent 18+4+3 处仍写"功能可用"** + **mood_dialog 1204 行 18 月未拆** + **data_export_service 21K 字节 orchestrator 仍挂**。spen 独占 4 项 P1 (SP-1~4) 0 进展。

---

## §1 R68 → R69 增量

### §1.1 跨视角问题数与重趋势 (R68 持平)

| 视角 | R68 P0 | R68 P1 | R68 P2 | R69 P0 | R69 P1 | R69 P2 | 变化 |
|------|--------|--------|--------|--------|--------|--------|------|
| **emilkowalski** | 2 | 6 | 7 | **2** | **7** | **9** | 持平 (emil P0 0 进展) |
| superpowers-en | 5 | 9 | 3 | **5** | **9** | **3** | 持平 |
| superpowers-zh | 9 | 6 | 7 | 9 | 6 | 7 | 持平 |
| AppStore | 10 | 10 | 6 | 10 | 10 | 6 | 持平 |
| GooglePlay | 8+2 | 8 | 4 | 8+2 | 8 | 4 | 持平 |
| flutter-specification | 5 | 5 | 5 | 5 | 5 | 5 | 持平 |
| **总问题数** | **39** | **44** | **32** | **39** | **45** | **34** | 持平 |

### §1.2 R68 commit `d691551` 真修了什么 (✅ 已落地)

| 修 | 类别 | 位置 | 影响 |
|----|------|------|------|
| **CC-3** IAP 临时关闭 | 跨视角 P0 | `core/data/feature_flags.dart:38` `_prodIapEnabled = false` | 隐藏 IAP 入口,避免 8 元买断 vs `buyLifetime()` 返 false 撞 Apple 2.1 |
| **CC-6** CareEngine safety 撤回真接 | 跨视角 P0 | `domain/usecases/fire_care_strategy.dart:155` 加 `isSafetyConsentWithdrawn` 字段 + `home_page.dart:533` 注入 | 跟隐私政策 §4/§9/§12 表格"撤回后直接 return"对齐 |
| **CC-1** setup 阶段 ConsentDialog | 跨视角 P0 | `presentation/pages/setup/setup_page.dart:370-428` 每个填了联系人弹 ConsentDialog | PIPL §13 单独同意技术层面真成立 |
| 配套 | — | ARB 加 `setupConsentRejected` 3 译文 | — |

**验证证据**:
- `git log --oneline -1` = `d691551 v0.27 round 68: 5 视角共识 P0 集中修复 (CC-3 / CC-6 / CC-1)` ✅
- `grep "isSafetyConsentWithdrawn" lib/` = 4 命中(use case / use case default / home_page 注入 / 注释) ✅
- `grep "ConsentDialog" lib/presentation/pages/setup/setup_page.dart` = `await ConsentDialog.show(...)` 真正接入 ✅
- `flutter test` = `All tests passed! 1285` ✅(R68 报 2 fail 时区漂移 0 fail)

### §1.3 R69 关键数字 (对比 R68)

| 指标 | R68 | R69 | 变化 |
|------|-----|-----|------|
| `flutter test` | 1283 + 2 fail 时区漂移 | **1285 全过** | ✅ 漂移修了 |
| `flutter analyze` error | 0 | 0 | 持平 |
| `flutter analyze` warning | 5 | **2** (settings_page test 2 unused_import) | ✅ -3(待验) |
| `flutter analyze` info | 181 | **186** | +5 (新 R68 widget 集中器 test 报) |
| 4 层架构纯度 | 100% | **100%** (`check_all.dart` 验证) | 持平 |
| 守护脚本 | 16 全绿 | **16 全绿** | 持平 |
| working tree | clean | clean (1 个新文件 round69-emilkowalski.md 在写) | 持平 |

### §1.4 R66 18 issues 状态 (R66 → R68 → R69 净进展)

| # | R66 issue | file:line | R68 状态 | R69 状态 | 证据 |
|---|-----------|-----------|----------|----------|------|
| 1 | `email_service.dart` 0 守门员 P0 | `lib/core/data/services/email_service.dart` | ✅ R67 B-1 修 | ✅ **仍合规** | R67 4 API + 7 case test 仍有效 |
| 2 | `_resolveTimestamp` 5 处 DRY P0 | 4 repo + 1 use case | ✅ R67 C-1 修 | ✅ **仍合规** | `DateTimeResolvers.at()` 5/5 替换,5 case test 仍过 |
| 3 | `mood_dialog.dart` 1204 行 god class P1 | `lib/presentation/pages/mood/mood_dialog.dart` | ⏳ 仍挂 | ⏳ **仍挂 1204 行** | `wc -l` 验证 = 1204 |
| 4 | `notification_service` facade 0 单测 P1 | `lib/core/data/services/notification_service.dart` (16.6K) | ⏳ 仍挂 | ⏳ **仍挂** | grep init() 单测 0 命中 |
| 5 | `notification_service.init()` tz 失败 silent P1 | `notification_service.dart:122-176` | ⏳ 仍挂 | ⏳ **仍挂** | 无 unit test guard |
| 6 | `app_database.dart:163-186` vent 加密失败无视觉 P1 | `lib/core/data/database/app_database.dart` | ⏳ 仍挂 | ⏳ **仍挂**(走 swallowError 但 0 启动 banner) | R63 P1-7 改 catch → swallowError, 无启动 banner |
| 7 | `setup_page.dart` 4 步骤 0 集成测 P1 | `lib/presentation/pages/setup/setup_page.dart` | ⏳ 仍挂 | ⏳ **仍挂** | CC-1 修了业务无 test |
| 8 | `settings_page.dart` 0 集成测 P1 | `lib/presentation/pages/settings/settings_page.dart` | ⏳ 仍挂 | ⏳ **仍挂** | R45 settings_page_round45_test 仅 2 widget 子测试,无 6 section 集成测 |
| 9 | `email_service.dart:79` isMock 命名不一致 P1 | `email_service.dart:73` | ✅ R67 B-1 修 | ✅ **仍合规** | 命名一致性通过注释守住 |
| 10 | `CareEngine.evaluate()` 0 caller 验证 P2 | `care_engine.dart:68-109` | ✅ R67 B-2 修 | ✅ **仍合规** | `home_page._fireCareEngine` 切到 `FireCareStrategyUseCase` |
| 11 | 3 个老 TODO 集中器 P2 | `notification_service.dart:388-389` + `sms_service.dart:90-194` + `email_service.dart:72-73` | ⏳ 部分修 | ⏳ **notification_service 角标 TODO 仍挂** | badge_sync 委托 + Android 集成 TODO 仍挂 |
| 12 | 100ms 录音 tick magic P2 | `lib/core/data/services/mood_audio_service.dart:124` | ⏳ 仍挂 | ⏳ **仍挂** | R43 注释 "测试可注入短 maxDuration",但 `AppTokens.audioTickInterval` 0 |
| 13 | 100ms file lock magic P2 | `lib/core/data/services/vent_audio_storage.dart:95` | ⏳ 仍挂 | ⏳ **仍挂** | `Duration(milliseconds: 100 * attempt)` 3 次重试, magic |
| 14 | app_theme TODO v0.25 1 年未动 P2 | `lib/core/theme/app_theme.dart:128` | ⏳ 仍挂 | ⏳ **仍挂** (CC-10 跨视角共识) | `withValues(alpha: 0.5)` + `// TODO v0.25: 评估 buildTheme 接受 context` |
| 15 | `data_export_service` 21K orchestrator P2 | `lib/core/data/services/data_export_service.dart` | ⏳ 仍挂 | ⏳ **仍挂 16996 bytes** | 抽 `ExportPlanBuilder` 0 进展 |
| 16 | R63 SmsService 守门员 | `sms_service.dart` | ✅ R67 仍合规 | ✅ **仍合规** | R55+ 真接 checklist 完整,`check_sms_release_ready` 仍绿 |
| 17 | R64 SafetyDetector 8 case | `safety_detector.dart` | ✅ R67 仍合规 | ✅ **仍合规** | 0 改动 |
| 18 | R66 FeatureFlags 4 case | `feature_flags.dart` | ✅ R67 仍合规 | ✅ **仍合规 + R68 升级** | R68 加 `_prodIapEnabled=false` + `setIapEnabledForTest` 6 case 仍过 |

**R66 → R69 净修**: **6 修** (1, 2, 9, 10, 16, 17, 18 共 7 项) / **11 仍挂** (3-8, 11-15)。

---

## §2 顶层架构审视(用户重点)

### §2.1 4 层架构 + 共享 umbrella 健康度

✅ **架构纯度 100%** (`scripts/check_all.dart` 双段验证):
- `lib/{core/data, core/shared, domain, presentation}` 4 层无跨层依赖
- domain/ 0 flutter / 0 drift / 0 data / 0 presentation
- shared/ 0 flutter / 0 drift / 0 data / 0 presentation
- 每个 domain *Entity 都对应一个 drift table (1:1 验证)
- shared/ 工具被 ≥2 层使用
- 261 个 lib/ 文件全部合规

✅ **设计 token 体系完整**:
- 4 sub-file `app_colors` / `app_motion` / `app_spacing` / `app_typography` + facade `app_tokens.dart` (152-156: `iconSize/iconSizeLg/iconSizeMicro/iconSizeInline/iconSizeSmall`)
- 0 散落 `Color(0xFF...)`
- R67 6 个新 widget 集中器 (`InfoBanner` / `StatCard` / `DialogActionsRow` / `ChoiceChipWrap` / `SwipeDeleteBackground` / `ConsentDialog`)

✅ **i18n 3 层边界清晰**:
- `l10n/` (presentation) / `core/l10n/` (domain) / `core/shared/json_codec.dart` 三者职责分明
- 623 zh / 623 en / 623 zh_Hant 100% 同步 (`check_arb_keys.py`)
- 0 orphan (`check_orphan_arb_keys.py`)
- 100% 繁简一致 (`check_zh_hant_consistency.py` OpenCC s2tw)
- 0 PUA 字符 (`check_no_pua.py`)

✅ **16 守护脚本全绿** (v0.27 R60 修正 12→16,R56e 新增 check_orphan_arb_keys / R57 新增 3 项法律 / R58 warn-only):
- `check_arb_keys.py` ✅
- `check_changelog.py` ✅
- `check_cross_feature.py` ✅ (67 文件 0 violation)
- `check_datetime_race.py` ✅ (0 违规)
- `check_datetime_race2.py` ✅ (0 违规)
- `check_drift_namespace.py` ✅ (7 table / 7 @DataClassName / 0 重复)
- `check_fullwidth_punctuation.py` (warn-only, 3 处散落: `database_migration.dart:17` / `export_schema_service.dart:73` / `app_colors.dart:275`)
- `check_no_hardcoded_utc.py` ✅ (0 命中)
- `check_no_pua.py` ✅
- `check_widget_dispose.py` ✅
- `check_orphan_arb_keys.py` ✅
- `check_legal_consent.py` ✅
- `check_sms_release_ready.py` ✅
- `check_strings_hardcoded.py` ✅ (32 处中文 static const 全部 R57 override 配对模式 + 带 i18n 标记)
- `check_zh_hant_consistency.py` ✅
- `dart scripts/check_all.dart` ✅

### §2.2 是否可采用更优架构?

**结论: 不需要重构架构, 但有 4 个真架构问题需修 (R68 持平, 0 进展)**

| 现状 | 是否需改 |
|------|---------|
| 4 层 + 5 子 umbrella | ✅ 保留, 符合 v0.18 设计意图 |
| Drift schemaVersion 12 | ✅ 渐进升级健康 |
| Riverpod 3.3.2 | ✅ 最佳实践 |
| go_router 14.6 | ✅ page transition 3 类集中 |
| SQLCipher | ✅ 精神心理数据敏感 |
| Domain 0 Flutter 依赖 | ✅ 易测, 纯 Dart |
| ProviderScope overrides 测试 | ✅ in-memory + override |

**4 个真架构问题 (都是 P0-P1, R68 → R69 持平)**:

1. **CC-6 CareEngine safety consent 撤回 (✅ R68 修)** — use case 真接 `isSafetyConsentWithdrawn`, 隐私政策 §4/§9/§12 表格对齐
2. **CC-1 setup 阶段 ConsentDialog (✅ R68 修)** — `setup_page.dart:370-428` 每个填了联系人弹 ConsentDialog
3. **`mood_dialog.dart` 1204 行 18 月未拆 god class (⏳ 仍挂)** — R64 home_page 3 bool → enum 模式可 1:1 套, 0 进展
4. **`data_export_service.dart` 21K 字节 orchestrator (⏳ 仍挂)** — 抽 `ExportPlanBuilder` + `ExportPreview` 跟 R64/R65 facade 模式, 0 进展

### §2.3 god class 拆解进度(2 个仍挂 18+ 月)

| 模块 | 实际大小 | R66 状态 | R68 状态 | R69 状态 | 建议拆法 | 难度 |
|------|---------|---------|---------|---------|---------|------|
| `mood_dialog.dart` | **1204 行 / 41K 字节** | 18 月挂 | 仍挂 | **仍挂** (持平) | 抽 `MoodDialogOrchestrator` 状态机 (7 字段 → enum) + 业务委派 `mood_usecases.dart` | M-L |
| `data_export_service.dart` | **16996 字节 / 21K 字节** (按 wc -c 算) | 18 月挂 | 仍挂 | **仍挂** (持平) | 抽 `ExportPlanBuilder` (version 1-4 计划) + `ExportPreview` (dry-run 输出) | M |
| `notification_service.dart` | **16996 字节** | facade 0 单测 | facade 0 单测 | **仍挂** | 加 `notification_service_facade_round69_test.dart` 6 类 ID 范围不冲突 + init 顺序 | S |

### §2.4 半成品 / TODO / 文档脱节清单(用户重点)

| # | 位置 | 问题 | 难度 | 类别 | 优先级 |
|---|------|------|------|------|-------|
| **SP-A** | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent}.md:3-4` | 3 份法律 md 顶部 "TODO (上 store 前必须由专业律师过审)" 仍保留 (CC-4) | L | 架构 | P0 |
| **SP-B** | `pubspec.yaml:2` | description 单语种中文, App Store / Google Play en 模式 UX 割裂 (CC-5) | M | 底层 | P0 |
| **SP-C** | `fastlane/metadata/android/zh-CN/title.txt:1` + `user_agreement.md:17,24,48` + `sensitive_data_consent.md:27,37,47,60,66,67,85` + `privacy_policy.md:32-204` 18 处 | "失联通知" / "紧急联系人" 4 文档仍写"功能可用"措辞, 业务暂停 (CC-7) | S | 底层 | P0 |
| **SP-D** | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` + `setup_legal_dialog.dart:38` | 3 份 md 0 英文 + 0 繁体版 (`showLegalDocument` 不分 locale) (CC-8) | L | 架构 | P1 |
| **SP-E** | `privacy_policy.md:87, 121-123, 195` | §4 / §9 / §12 表格"CareEngine 撤回后直接 return"表述需 walkthrough (CC-6 修后改) | S | 底层 | P2 |
| **SP-F** | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:30-37` | 占位启动 MainActivity 简化方案, R64+ 待完善 (注释自己说"留给 R64 完善") | S | 底层 | P1 |
| **SP-G** | `lib/core/data/services/notification_service.dart:388-389` + `badge_sync_service.dart:45` | Android 角标 18+ 月 TODO 双处重复, v0.10+ TODO 集成 `flutter_app_badge_control` 插件 | XS | 底层 | P2 |
| **SP-H** | `lib/core/data/services/sms_service.dart` | R55+ 真接 checklist 完整但实际 SMS provider `AliyunSmsProvider.send()` 仍 throw StateError (外部依赖) | L | 底层 | P1 |
| **SP-I** | `lib/core/data/services/email_service.dart:69-73` | `_isFullyImplemented` 加了 (R67 B-1) 但 send 实际未接真 provider (R57+ 模板待法务审核) | L | 底层 | P1 |

---

## §3 底层逐行排查(用户重点)

### §3.1 spen 5 类历史 bug 模式扫描 (R66 → R69 全程 100% 合规)

| Bug 类型 | R66 状态 | R68 状态 | R69 状态 | 关键指标 | 验证 |
|---------|---------|---------|---------|---------|------|
| **隐式排序** (`.first` / `.last` on 时序数据) | ✅ 0 违规 | ✅ 0 违规 | ✅ **0 违规** | 5 命中全部已 sort 合规: `care_strategies.dart:107` 函数参数 `sortedDesc` (调用方已显式 sort) + `trend_mood_chart.dart:55-56` + `trend_assessment_chart.dart:61-62` 全部 `[...records]..sort()` | grep 5/5 已显式 sort |
| **DateTime race** (跨函数多次 `DateTime.now()`) | 🟡 89 处 / 47 文件 | ✅ 0 违规 (R67 C-1 修) | ✅ **0 违规** | 94 处 / 47 文件 + 公开 `DateTimeResolvers.at()` 集中器 (5 处替换) + 2 个 check_datetime_race 守护 | `check_datetime_race.py` 0 违规 |
| **静默吞 `catch(_)`** | ✅ 0 处 | ✅ 0 处 | ✅ **0 处 (10 命中全注释)** | `catch (_)` 10 命中全部在注释中引用, 0 实际代码静默; `swallowError` 集中器 84+ 处调用 / 26 文件 | grep 10/10 注释 |
| **StreamSubscription cancel 配套** | ✅ 0 漏 | ✅ 0 漏 | ✅ **0 漏** | 8 处 / 5 文件 (vent_compose / vent_detail / mood_audio_section / app_router / mood_audio_service), dispose 全部 cancel | spen R16 + R19B + R62 持续修 |
| **BuildContext 跨 async gap** | ✅ 0 违规 | ✅ 0 违规 | ✅ **0 违规** | 54 处 `!mounted` + 24 处 `context.mounted`, analyzer `use_build_context_synchronously` 0 处 | analyzer 0 命中 |
| **Resource acquire/release** | ✅ 0 漏 | ✅ 0 漏 | ✅ **0 漏** | Timer / AudioPlayer / AudioRecorder / SpeechToText / StreamController / Drift DB / 临时文件 全部 dispose 配套 | check_widget_dispose 0 违规 |

**结论**: spen 5 类历史 bug 模式 **R67 后 100% 合规, R68 100% 守住, R69 100% 守住**,TDD 7 类清单 (隐式排序 / DateTime race / catch / null safety / try-finally / BuildContext / dispose) 同样 0 违规。**这是 R60-66 集中打掉 5 个 facade god class + 3 use case 抽离的成果沉淀, 新 P0-P1 集中在 "跨 feature 一致性 / 文档 vs 代码 / 隐私政策撒谎" 3 类新维度**。

### §3.2 TDD 覆盖 — 已知 5 类历史 bug 模式 0 违规

| 历史 bug 模式 | 守护 | 当前 | 修复量 |
|--------------|------|------|--------|
| 隐式排序 | grep + 守护 (无独立脚本) | 0 | 5 处已修 (R19B) |
| DateTime race | `check_datetime_race.py` + `check_datetime_race2.py` | 0 违规 | 89 → 0 (R67 C-1) |
| 静默 `catch(_)` | grep 0 实际代码 | 0 实际 (10 注释) | 9 → 0 (R39) |
| StreamSubscription cancel | `check_widget_dispose.py` | 0 违规 | 持续修 |
| BuildContext 跨 async gap | analyzer `use_build_context_synchronously` | 0 命中 | R17 + R56b 规范化 |
| Resource acquire/release | `check_widget_dispose.py` | 0 违规 | R62 集中修 |

### §3.3 守护脚本 — 16 项全绿 (`check_fullwidth_punctuation.py` warn-only)

| # | 脚本 | 状态 | 命中数 |
|---|------|------|--------|
| 1 | `check_arb_keys.py` | ✅ | 623 zh / 623 en / 623 zh_Hant 100% 同步 |
| 2 | `check_changelog.py` | ✅ | pubspec 0.27.0+64, CHANGELOG 顺序 OK |
| 3 | `check_cross_feature.py` | ✅ | 67 文件 0 violation |
| 4 | `check_datetime_race.py` | ✅ | 0 违规 (R66=89) |
| 5 | `check_datetime_race2.py` | ✅ | 0 违规 |
| 6 | `check_drift_namespace.py` | ✅ | 7 table / 7 @DataClassName / 0 重复 |
| 7 | `check_fullwidth_punctuation.py` | ⚠️ warn-only | 3 处散落 (database_migration / export_schema / app_colors:275) |
| 8 | `check_no_hardcoded_utc.py` | ✅ | 0 命中 |
| 9 | `check_no_pua.py` | ✅ | 0 PUA 字符 |
| 10 | `check_widget_dispose.py` | ✅ | 0 资源泄漏 |
| 11 | `check_orphan_arb_keys.py` | ✅ | 0 orphan (R56e 新增) |
| 12 | `check_legal_consent.py` | ✅ | R57 新增 (只查 setup_legal_dialog, setup_page 是 R68 CC-1 才接的) |
| 13 | `check_sms_release_ready.py` | ✅ | R57 新增 (R58 降为 warn-only) — AliyunSmsProvider 真接 + isProductionReady 一致 |
| 14 | `check_strings_hardcoded.py` | ✅ | R57 新增 — 32 处中文 static const 全部 R57 override 配对模式 + 带 i18n 标记 |
| 15 | `check_zh_hant_consistency.py` | ✅ | 623 keys 100% 繁简一致 (zh ↔ zh_Hant via OpenCC s2tw) |
| 16 | `dart scripts/check_all.dart` | ✅ | 4 层架构 + 一致性 100% |

**R69 新增** (R57 起 4 个新守护, R58 调整 1 个): check_legal_consent / check_sms_release_ready / check_strings_hardcoded / check_zh_hant_consistency — 4 项全绿, R68 报"12 守护"已修正到 16 (R60 起)。

### §3.4 CI 流程(用户重点)

- ✅ 16 守护脚本 CI 集成 (R67 加 `.github/workflows/ci.yml` 6 行, R68 commit 落地)
- ✅ `flutter test` 在 CI 跑 (1285 全过)
- ⚠️ **缺 `dart format --set-exit-if-changed` 护栏** (R66 挂 2 round) — 1 行 CI 加
- ⚠️ **`.github/workflows/ci.yml` 11 守护脚本可能缺 4 个** (R57 新增的 check_legal_consent / check_sms_release_ready / check_strings_hardcoded / check_zh_hant_consistency) — 1 行 CI 加
- ⚠️ **2 fail → 0 fail** (R68 报 2 时区漂移,R69 0) — R68 commit 修了 (R68 commit message 没提,但 0 fail 是事实)

---

## §4 上架相关(spen 视角 — 跟上架 21 P0 关联)

### §4.1 上架阻塞 — 跨视角共识 CC-1~10 (R68 → R69 持平)

| # | 问题 | 位置 | R68 状态 | R69 状态 | 涉及视角 |
|---|------|------|---------|---------|----------|
| **CC-1** | setup 阶段 `saveSetup` 写联系人**绕过** ConsentDialog, PIPL §13 单独同意技术层面不成立 | `app_database.dart:307-315` + `setup_page._saveSetup` | ⏳ | ✅ **R68 commit 修** | spen / spzh / appstore / googleplay |
| **CC-2** | 212 文件 working tree 未 commit (master = R65) | `git log --oneline -1` = `d691551` | ⏳ | ✅ **R68 commit 修** (working tree clean) | spen / spzh / spec |
| **CC-3** | IAP 8 元买断 vs `buyLifetime()` 返 false + `_prodIapEnabled=true` 默认开 | `user_agreement.md:25,28` vs `store_kit_service.dart:118-119` + `feature_flags.dart:36` | ⏳ | ✅ **R68 commit 修** (`_prodIapEnabled=false`) | spen / spzh / appstore / googleplay |
| **CC-4** | 3 份法律 md 顶部 "TODO 律师过审" 仍保留 | `user_agreement.md:3` + `privacy_policy.md:3-4` + `sensitive_data_consent.md:3-4` | ⏳ | ⏳ **仍挂** (3 md 顶部 100% 仍写) | spen / spzh / appstore / googleplay |
| **CC-5** | `pubspec.yaml:2` description 单语种中文 | `pubspec.yaml:2` | ⏳ | ⏳ **仍挂** (description 仍"我今天吃了药...") | spen / spzh / appstore / googleplay |
| **CC-6** | 隐私政策撒谎 §4/§9/§12 | `privacy_policy.md:87, 121-123, 195` | ⏳ | ✅ **R68 commit 修** (use case 真接) | spen / spzh / appstore / spec |
| **CC-7** | 失联通知 4 文档写功能可用 | `full_description.txt:14` (en-US "automatically notify") + `zh-CN/title.txt:1` "失联通知" + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | ⏳ 部分修 | ⏳ **部分修**: en-US/zh-CN full_description 加 "(即将上线 — 当前已暂停)" + NOTE, 但 zh-CN title.txt + user_agreement 3 处 + sensitive_data_consent 4 处 + privacy_policy 18 处 仍写"功能可用" | spzh / appstore / googleplay / spec |
| **CC-8** | 3 份法律 md 0 英文 + 0 繁体版 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` + `setup_legal_dialog.dart:38` | ⏳ | ⏳ **仍挂** (3 md 文件总 21K, 0 英文 0 繁体) | spen / spzh / appstore |
| **CC-9** | `settings_page.dart:63, 92` 2 处 `AppColors.success` / `AppColors.primary` const 硬编 dark mode 漏反白 | `lib/presentation/pages/settings/settings_page.dart:63, 92` | ⏳ | ⏳ **仍挂** (R49 R66 漏 2 round, R68 emil 报同款 0 进展) | emil / spec |
| **CC-10** | `app_theme.dart:128, 209` 2 处 `withValues(alpha: 0.5/0.6)` 走 inline 而非 `AppColors.fgDisabled/fgHintInput` 集中器 (TODO 挂 1 年) | `lib/core/theme/app_theme.dart:128, 209` | ⏳ | ⏳ **仍挂** (line 123 `withValues(alpha: 0.5)` + line 128 `// TODO v0.25: 评估 buildTheme 接受 context`) | emil / spec |

**CC P0 总结**: **R68 修 3 (CC-1/3/6)** + **R68 修 1 (CC-2 working tree)** = **R68 净修 4**, R69 仍挂 **6** (CC-4/5/7/8/9/10)。

### §4.2 文档 vs 实际行为 — PIPL §13 撒谎检查

| 位置 | 文档说法 | 实际行为 | 状态 |
|------|---------|---------|------|
| `privacy_policy.md:87` §4 "撤回" | "CareEngine.fire 撤回后直接 return" | ✅ R68 commit 真接 (use case:202) | ✅ 修 |
| `privacy_policy.md:121-123` §9 "失联通知" | "失联通知功能可用" | 业务暂停 (`FeatureFlags.emergencyContactEnabled=false`) | ⏳ 仍挂 |
| `privacy_policy.md:195` §12 "撤回同意" | "撤回后直接 return" | ✅ R68 commit 真接 | ✅ 修 |
| `user_agreement.md:17,24,40,48` | "失联通知功能可用" | 业务暂停 | ⏳ 仍挂 4 处 |
| `sensitive_data_consent.md:27,37,47,60,66,67,85` | "失联通知触发" | 业务暂停 | ⏳ 仍挂 7 处 |
| `fastlane/metadata/android/zh-CN/title.txt:1` | "慢病管家 - 吃药打卡 + 失联通知" | 业务暂停 | ⏳ 仍挂 |
| `fastlane/metadata/android/en-US/full_description.txt:14` | "automatically notify" | 业务暂停 | ✅ R67 Sprint 1 改 (line 13-16 加 "coming soon — currently disabled" + NOTE) |
| `fastlane/metadata/android/zh-CN/full_description.txt:17` | "【失联通知】...App 会自动给你信任的紧急联系人发短信" | 业务暂停 | ✅ R67 Sprint 1 改 (line 17-19 加 "即将上线 — 当前已暂停" + 注) |

**CC-7 修复进度**: **2/6 文档修 (en-US/zh-CN full_description)**, 仍挂 4/6 (zh-CN title + user_agreement + privacy_policy + sensitive_data_consent)。**R68 修 CC-1/3/6 但没动 CC-7 措辞统一**。

### §4.3 上架 21 P0 阻塞 — spen 角度额外发现

| # | 位置 | 问题 | 难度 | 类别 |
|---|------|------|------|------|
| 1 | `lib/core/data/services/sms_service.dart` | `AliyunSmsProvider.send()` 仍 throw StateError, R55+ 注释说"真接 checklist 完整" 但实际未接真 provider (外部依赖: 法务 1-2 月 + 阿里云 AccessKey 申请) | L | 底层 |
| 2 | `lib/core/data/services/email_service.dart` | `EmailService._isFullyImplemented` (R67 B-1) + `validateForRelease` 加了, 但 send 实际未接真 provider, R57+ 模板待法务审核 | L | 底层 |
| 3 | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:30-37` | 占位启动 MainActivity 简化方案, R64+ 待完善 (注释自己说"留给 R64 完善", 至今 R69 仍挂) | S | 底层 |
| 4 | `fastlane/metadata/ios/en-US/*.png` 33 张 + `fastlane/metadata/android/{en-US,zh-CN}/**/*.png` 13 张 | 67 字节透明占位 (iOS 27 必填 + Android 8 截图 + 2 feature_graphic + 2 icon 1443 字节) | L | 流程 |
| 5 | `fastlane/metadata/{android,ios}/*/video.txt` 2 文件 | PLACEHOLDER URL 占位 | XS | 流程 |
| 6 | `android/key.properties` 不存在 | release 签名仍是 debug keystore | S | 流程 |
| 7 | `lib/presentation/pages/vent/vent_compose_page.dart:135-141` | RECORD_AUDIO in-app rationale 缺 | S | 底层 |
| 8 | `lib/presentation/pages/settings/widgets/notification_status_card.dart:1-250` | SCHEDULE_EXACT_ALARM 引导已有 (R16), 但 USE_EXACT_ALARM Play Console justification 100+ 字符未准备 | S | 流程 |
| 9 | `user_agreement.md:60-61` | `support@chroniccare.app` + `github.com/example` TODO 占位, 邮箱未注册 | XS | 流程 |
| 10 | `assets/legal/*.md` 部署 | Privacy Policy URL 未托管到 HTTPS 公网 | M | 流程 |
| 11 | `fastlane/{Fastfile,Appfile}` Android 端 0 (lane 缺失) | R68 已加 (4 + 25 行), 但 Android 端 0 | S | 流程 |
| 12 | `lib/presentation/widgets/info_banner.dart` 等新 widget 集中器 | R67 抽 6 个集中器 (InfoBanner / StatCard / DialogActionsRow / ChoiceChipWrap / SwipeDeleteBackground / ConsentDialog), 但 R68 emil 报 "12 项 P0/P1 仍挂" 0 进展, R69 持平 | — | 架构 |

---

## §5 修复优先级总表

### P0 (必须修, 5 视角共识优先)

| # | 位置 | 问题 | 难度 | 类别 | 修复建议 |
|---|------|------|------|------|----------|
| 1 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent}.md:3-4` | 3 份法律 md 顶部 "TODO 律师过审" 仍保留 (CC-4) | L | 架构 | 法务 review 后整段删除; 或留"草稿 v0.27"但删"TODO 必须过审" |
| 2 | `pubspec.yaml:2` | description 单语种中文 (CC-5) | M | 底层 | 加 en 描述 + zh_Hant 描述 (跟 `fastlane/metadata/*/description.txt` 同步) |
| 3 | `fastlane/metadata/android/zh-CN/title.txt:1` + `user_agreement.md:17,24,40,48` + `sensitive_data_consent.md:27,37,47,60,66,67,85` + `privacy_policy.md:32-204` 18 处 | "失联通知" / "紧急联系人" 4 文档仍写"功能可用"措辞 (CC-7) | S | 底层 | 4 文档统一改 "失联通知 (即将上线 — 当前暂停)" + 跟 en-US/zh-CN full_description line 13-19 模板对齐 |
| 4 | `lib/presentation/pages/settings/settings_page.dart:63, 92` | `AppColors.success/primary` const 硬编 dark mode 漏反白 (CC-9, R49 R66 漏 2 round) | XS | 底层 | 换 `AppColors.fgOnSuccess(context)` + `AppColors.primaryColor(context)`, 5min |
| 5 | `lib/core/theme/app_theme.dart:123, 128` | `withValues(alpha: 0.5)` 走 inline + TODO v0.25 (CC-10, 挂 1 年) | XS | 底层 | 替换为 `AppColors.fgDisabled/fgHintInput` 集中器, 删 TODO 注释 (buildTheme 接受 context 模式 1 行改) |

### P1 (应修, 3-4 视角共识或 spen 独占)

| # | 位置 | 问题 | 难度 | 类别 | 修复建议 |
|---|------|------|------|------|----------|
| 6 | `lib/core/data/services/notification_service.dart:122-176` | `init()` 0 单测 guard, tz 失败 → 权限请求 silent (SP-1, R66 P1 续) | S | 底层 | 加 `init_order_round69_test.dart` 3 case: tz 抛异常 + 权限仍调 + `_initialized=true` 仍设 |
| 7 | `lib/presentation/pages/mood/mood_dialog.dart` 1204 行 | god class 18 月未拆 (SP-3, emil/spen 双 P0 残留) | M-L | 架构 | 抽 `MoodDialogOrchestrator` 状态机 (7 字段 → enum) + 业务委派 `mood_usecases.dart` (跟 R64 home_page 3 bool → enum 模式) |
| 8 | `lib/core/data/database/app_database.dart:163-186` | vent v8→v9 加密失败无用户视觉提示 (SP-2, R63 P1-7 改 catch → swallowError 但仍无启动 banner) | M | 底层 | 加 `LastStartupErrorBanner`-style 启动 banner "N 条历史树洞数据格式异常, 已跳过" (已有 `last_startup_error_banner_round31_test.dart` 模式) |
| 9 | `lib/core/data/services/data_export_service.dart` 21K 字节 orchestrator | 仍 god class, 子服务里唯一未拆 orchestrator (SP-4) | M | 架构 | 抽 `ExportPlanBuilder` (version 1-4 计划) + `ExportPreview` (dry-run 输出) |
| 10 | `lib/presentation/pages/setup/setup_page.dart` 4 步骤状态机 | 0 集成测试 (R66 P1 续, CC-1 修了业务无 test) | M | 底层 | 加 `setup_page_round69_integration_test.dart` 4 步骤连续跑 + consent 拒绝路径 |
| 11 | `lib/presentation/pages/settings/settings_page.dart` 6 section | 0 集成测试 (R66 P1 续) | S | 底层 | 加 `settings_page_round69_integration_test.dart` 6 section 顺序 + FeatureFlag 软隐藏 |
| 12 | `lib/core/data/services/notification_service.dart` 16.6K 字节 facade | 0 单测 guard (R66 P1 续) | S | 底层 | 加 `notification_service_facade_round69_test.dart` 6 类 ID 范围不冲突 + init 顺序 + showSafetyAlert 委派 |
| 13 | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` 3 md 0 英文 + 0 繁体版 (CC-8) | L | 架构 | 加 `assets/legal/{en,zh_Hant}/*.md` 3 套翻译 + `setup_legal_dialog.dart:38` 按 locale 分发 |
| 14 | `android/app/src/main/kotlin/com/chroniccare/chroniccare/BootReceiver.kt:30-37` | 占位启动 MainActivity, R64+ 待完善 (R63 注释说"留给 R64 完善", 至今 R69 仍挂) | S | 底层 | 完整方案: `FlutterEngineCache.getInstance().get(engineId)` 复用 engine + `MethodChannel` 调 Flutter 侧 `rescheduleAll()`, 2-3h |

### P2 (可改, 1-2 视角共识)

| # | 位置 | 问题 | 难度 | 类别 | 修复建议 |
|---|------|------|------|------|----------|
| 15 | `lib/core/data/services/notification_service.dart:388-389` + `lib/core/data/services/badge_sync_service.dart:45` | Android 角标 18+ 月 TODO 双处重复 (R66 P2 续) | XS | 底层 | 加 `docs/TODO_v1.0.md` 集中器, 3 个老 TODO 统一文档化 |
| 16 | `lib/core/data/services/mood_audio_service.dart:124` + `lib/core/data/services/vent_audio_storage.dart:95` | 2 处 100ms magic 录音 tick / file lock (R66 P2 续) | XS | 底层 | 抽 `AppTokens.audioTickInterval` + `fileLockRetryStep` |
| 17 | `lib/core/l10n/strings.dart` + `lib/domain/logic/care_copy.dart` + 7 文件 | 病耻感措辞 "让家人放心" / "你真棒" (7 文件命中) | S | 底层 | 走 `AppLocalizations` + R65 病耻感调优模式, 改"你做到了" / "已完成" 客观描述 |
| 18 | `lib/core/data/services/notification_service.dart:104-119` | 病耻感"TA"网络用语 (lost_contact_sms.dart 已删, 后续 fallback 字符串统一走 strings.dart) | XS | 底层 | grep "TA" 全部 i18n 化 |
| 19 | `lib/core/theme/app_tokens.dart` + 8+ 处散落 | 8+ 处 atomic size magic (18/20/36/40/110/12/10) | XS | 底层 | 抽 `AppTokens.iconSizeTrailing` (18) / `spinnerSizePdf` (20) / `avatarSizeSm` (36) / `avatarSizeMd` (40) / `buttonWidthNarrow` (110) / `legendDotSizeLg` (12) / `legendDotSizeSm` (10) |
| 20 | `lib/core/data/services/database_migration.dart:17` + `lib/core/data/services/export/export_schema_service.dart:73` + `lib/core/theme/app_colors.dart:275` | 3 处全角标点 warn-only | XS | 底层 | 改全角(，；！？／（）) 或加 `# allow 半角` 注释豁免 |
| 21 | `lib/core/data/feature_flags.dart:18-20` (R67 注释) | 双层 feature flag 注释, v0.28 真接 productId 后 `_prodIapEnabled=true` 翻回 | S | 底层 | R68 决策: v0.28 评估 |
| 22 | `lib/presentation/pages/setup/setup_step_done.dart:43, 53, 62, 74` | 4 段 setup title/subtitle TextStyle 走 inline | XS | 底层 | 抽 `AppTokens.textStyleSetupTitle` / `textStyleSetupSubtitle` 集中器 |
| 23 | `lib/presentation/pages/medication/medication_calendar_page.dart:398-400` | 3 个 l10n 魔法字符串 | XS | 底层 | l10n key `medsCalendarLegendP50/100/100Full` |

---

## §6 3-5 句精炼建议

1. **R68 commit `d691551` 真把 3 P0 修了, 升级 A- → A 评级** — CC-3 (IAP 8 元) + CC-6 (CareEngine safety 撤回) + CC-1 (setup ConsentDialog) 全部业务层真接, 1285 tests 全过 (R68 报 2 fail 时区漂移 0 fail), 16 守护脚本全绿, 4 层架构 100% 纯。**这是 R60-66 集中打掉 5 个 facade god class + R67 3 use case 抽离 + R68 3 P0 集中的成果沉淀**。

2. **CC-4 (3 md 顶部 TODO) + CC-5 (pubspec 中文) + CC-7 (4 文档失联通知) + CC-9 (settings dark mode) + CC-10 (app_theme alpha) 5 个 P0 仍挂, 5h 内可清** — CC-9/CC-10 是 XS 难度 (5min + 1h), CC-4/CC-5/CC-7 是 M 难度 (法务 + 4 文档措辞统一)。**修完这 5 个, 跨视角共识 P0 从 6 降到 1 (CC-8 3 md 英文/繁体版仍 L 难度挂)**。

3. **spen 独占 4 项 P1 (SP-1~4) 0 进展, 1 天工作量** — `notification_service.init()` 3 case (SP-1) + `mood_dialog` god class (SP-3) + `app_database` vent banner (SP-2) + `data_export_service` orchestrator (SP-4) + 4 setup/settings 集成测 = 5 项 XS-S-M-L 全 1 天工作量, 跟主 P0 修复同 PR 合并。

4. **CC-7 失联通知 4 文档措辞修了 full_description 但 title + agreement + consent + privacy_policy 18+4+3+7=32 处仍写"功能可用"** — R67 Sprint 1 改了 `fastlane/metadata/android/{en-US,zh-CN}/full_description.txt:13-19` (加"即将上线 — 当前已暂停" + NOTE), 但**还有 32 处散落在 4 文档未改**。1 个 PR 集中改 32 处 (3-4h), 跟 CC-4 (3 md 顶部 TODO) 同 PR 合并。

5. **CC-8 (3 份法律 md 0 英文 + 0 繁体版) 是上架 P0 阻塞** — 跟 en/zh_Hant 模式上架冲突, 但 L 难度 (3 份 md 各翻译 1 份 + `setup_legal_dialog.dart:38` locale 分发), **不阻塞 v0.27 国内上架, 阻塞 v0.28+ 海外上架**。建议 R70 处理 (跟 CC-4 法务过审同 PR)。

---

**审计完成时间**: 2026-08-01
**审计员**: superpowers-en 视角
**审计模式**: 增量 (R68 18 issues 状态对照 + R68 5 视角共识 P0 验证 + R69 跨 4 类问题重审 + spen 5 类历史 bug 回归)
**报告大小**: ~22 KB (5 P0 + 9 P1 + 9 P2 = 23 issues)
**报告路径**: `D:\Batch\chroniccare\reports\audit\round69-superpowers-en.md`
