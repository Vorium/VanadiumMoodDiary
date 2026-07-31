# v0.27 R68 6 视角全量审计 — 汇总报告

**审计时间**: 2026-07-31 → 2026-08-01
**项目**: chroniccare(精神心理患者吃药打卡 App)
**版本**: 0.27.0+64(`pubspec.yaml`)/ working tree 实际 R66+R67+R68 集中(**212 文件未 commit**)
**审计模式**: 6 视角并行 subagent 全量复盘(R67 收尾后,部分视角补完)
**baseline**: 1283 tests pass / **2 fail**(回归)/ 0 analyzer error / 5 warning / 181 info / 16 守护脚本全绿

---

## 0. 一览

| 视角 | 报告 | 评级 | P0 | P1 | P2 | 关键定位 |
|------|------|------|-----|-----|-----|----------|
| **emilkowalski** | `round68-emilkowalski.md` | ⭐⭐⭐⭐½ (vs R66 ⭐⭐⭐⭐) | 2 | 6 | 7 | 22 文件 12 维度,6 个新 widget 集中器 + dark mode 2 处漏 + 5% "差一口气"问题 |
| **superpowers-en** | `round68-superpowers-en.md` | A- (持平 R66) | 5 | 9 | 3 | R66 18 issues 修 6,5 类历史 bug 100% 合规,新发现 3 个 P0 |
| **superpowers-zh** | `round68-superpowers-zh.md` | ⭐⭐ (持平 R66) | 9 | 6 | 7 | 27 issues(R66 23 + R67 4 升级),隐私边界 5/5 守住,PIPL 2/5 |
| **AppStore** | `round68-appstore.md` | ⭐ (持平 R66) | 10 | 10 | 6 | R67 修了 8 项(iOS P0 11 → 3),剩 10 P0 是"非代码"环节(截图/邮箱/域名/律师) |
| **GooglePlay** | `round68-googleplay.md` | 3.0/10 (持平 R66) | 8+2 | 8 | 4 | R67 修了 0 P0,修了 3 P1,卡在 keystore / 域名 / 邮箱 / 律师 / Play Console 表单 |
| **flutter-specification** | `round68-flutter-specification.md` | ⭐⭐⭐⭐ 4.5/5 (持平 R66) | 5 | 5 | 5 | 88% 合规(89%→88%),C1.5 满分回归,T8/E10/G11 3 项流程性新挂 |
| **总问题数** | — | — | **39** | **44** | **32** | 115 (去重 ~40) |
| **去重 + 跨视角共识** | — | — | **10** | **8** | — | 共识 P0 单独列出 |

**核心判断**:
1. **5 视角共识 P0(最严重)**:`212 文件 working tree 未 commit` + `隐私政策撒谎 (CareEngine safety consent)` + `3 份法律 markdown 顶部 TODO 仍保留` + `setup 阶段 saveSetup 绕过 ConsentDialog` + `IAP 8 元买断 vs release 返 false`
2. **AppStore / GooglePlay 上架阻塞 21 项**(同源,2x 跨平台)— 11+10 大头是"声明跟实现不一致"(R67 改了部分但没改全)
3. **架构 / 半成品 / 重构机会**:
   - 4 层架构纯度 100%(check_all.dart 验证)
   - 16 守护脚本全绿
   - 抽象清晰
   - **仍有 4 个真架构问题**:CareEngine safety 撤回未真接 / setup ConsentDialog 缺 / mood_dialog 1204 行 18 月挂 / data_export_service 21K orchestrator
   - **5 个真重构机会**:R68 emil 抽 6 个新 widget 集中器(InfoBanner/StatCard/DialogActionsRow/ChoiceChipWrap/SwipeDeleteBackground/ConsentDialog),还可继续抽(OutlinedButtonWithPress/LoadingScrim/TrailingSpinner/ConsentCard)

**3 个用户重点关注**:
- ✅ **上架**:21 项 P0 阻塞(其中 5 项是流程性,16 项是技术性)— M1 最小上架 3-5 天 + 法务 1-2 周
- ✅ **架构**:4 层 + 5 子 umbrella 100% 纯;零跨层 import;可抽 7+ 集中器;4 个真架构问题需修
- ✅ **重构**:5 个强候选集中器(已在 R67 抽 6 个);5 个高内聚低耦合可拆(god class 2 个 + 业务编排 3 个)
- ✅ **半成品**:5 视角共识 10 项 P0 中 4 项是"半成品"(working tree / 3 法律 md / 隐私政策撒谎 / setup 绕过)

---

## 1. 跨视角共识 P0(最严重 — 多视角共同指出)

### 1.1 5 视角共识(5 项)

| # | 问题 | 位置 | 涉及视角 | 难度 | 类别 |
|---|------|------|----------|------|------|
| **CC-1** | setup 阶段 `saveSetup` 写联系人**绕过** ConsentDialog,PIPL §13 单独同意技术层面不成立 | `app_database.dart:307-315` + `setup_page._saveSetup` | spen / spzh / appstore / googleplay | **M** | 架构 |
| **CC-2** | **212 文件 working tree 未 commit** — master = R65,实际代码是 R66+R67+R68 集中;CI / 审计 / review 全部基于 R65 失效 | `git log --oneline -1` = `01c5c26` | spen / spzh / spec | **XS** | 流程 |
| **CC-3** | IAP 8 元买断 vs `buyLifetime()` 返 false + `FeatureFlags._prodIapEnabled=true` 默认开 | `user_agreement.md:25,28` vs `store_kit_service.dart:118-119` + `feature_flags.dart:36` | spen / spzh / appstore / googleplay | **S** | 底层 |
| **CC-4** | 3 份法律 markdown 顶部 "**TODO (上 store 前必须由专业律师过审)**" 仍保留 | `user_agreement.md:3` + `privacy_policy.md:3-4` + `sensitive_data_consent.md:3-4` | spen / spzh / appstore / googleplay | **L** | 底层 |
| **CC-5** | `pubspec.yaml:2` description 单语种中文,App Store / Google Play en 模式 UX 割裂 | `pubspec.yaml:2` | spen / spzh / appstore / googleplay | **M** | 底层 |

### 1.2 4 视角共识(2 项)

| # | 问题 | 位置 | 涉及视角 | 难度 | 类别 |
|---|------|------|----------|------|------|
| **CC-6** | 隐私政策撒谎:§4 / §9 / §12 表格宣称 "CareEngine.fire 撤回后直接 return" — use case 0 检查 `ConsentKind.safety` | `privacy_policy.md:87, 121-123, 195` + `care_engine.dart:131` 仅回调签名 + `fire_care_strategy.dart` 0 调用 | spen / spzh / appstore / spec | **S** | 架构 |
| **CC-7** | 失联通知业务暂停 vs 4 文档写功能可用 (full_desc / title / agreement / consent) | `full_description.txt:14` (en-US "automatically notify") + `zh-CN/title.txt:1` "失联通知" + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64` | spzh / appstore / googleplay / spec | **S** | 底层 |

### 1.3 3 视角共识(1 项)

| # | 问题 | 位置 | 涉及视角 | 难度 | 类别 |
|---|------|------|----------|------|------|
| **CC-8** | 3 份法律 markdown 0 英文 + 0 繁体版 (`showLegalDocument` 不分 locale) | `assets/legal/{privacy,user_agreement,sensitive_data_consent}.md` + `setup_legal_dialog.dart:38` | spen / spzh / appstore | **L** | 架构 |

### 1.4 2 视角共识(2 项)

| # | 问题 | 位置 | 涉及视角 | 难度 | 类别 |
|---|------|------|----------|------|------|
| **CC-9** | `settings_page.dart:63, 92` 2 处 `AppColors.success` / `AppColors.primary` const 硬编 dark mode 漏反白 (R49 修 35+ 漏 2 round) | `lib/presentation/pages/settings/settings_page.dart:63, 92` | emil / spec | **XS** | 底层 |
| **CC-10** | `app_theme.dart:128, 209` 2 处 `withValues(alpha: 0.5/0.6)` 走 inline 而不是 `AppColors.fgDisabled/fgHintInput` 集中器 (TODO 挂 1 年) | `lib/core/theme/app_theme.dart:128, 209` | emil / spec | **XS** | 底层 |

**CC P0 总计**: 10 项 / 修复总工作量:**~10-12 工程师天** (按 1 人 8h/d)

---

## 2. 顶层架构审视(用户特别关注)

### 2.1 4 层架构 + 共享 umbrella 健康度

✅ **架构纯度 100%**(`scripts/check_all.dart` 验证):
- `lib/{core/data, core/shared, domain, presentation}` 4 层无跨层依赖
- 261 个 lib/ 文件全部合规
- domain 0 Flutter / 0 Drift / 0 data / 0 presentation 引用

✅ **设计 token 体系完整**:
- 23+ token 集中(`app_tokens` facade + 4 sub-file: `app_colors` / `app_motion` / `app_spacing` / `app_typography`)
- 0 散落 `Color(0xFF...)`
- R67 6 个新 widget 集中器(InfoBanner / StatCard / DialogActionsRow / ChoiceChipWrap / SwipeDeleteBackground / ConsentDialog)

✅ **i18n 3 层边界清晰**:
- `l10n/` (presentation) / `core/l10n/` (domain) / `core/shared/json_codec.dart` 三者职责分明
- 622 zh / 622 en / 622 zh_Hant 100% 同步(`check_arb_keys.py`)
- 0 orphan(`check_orphan_arb_keys.py`)
- 100% 繁简一致(`check_zh_hant_consistency.py` OpenCC s2tw)

✅ **测试 5 类历史 bug 100% 合规**:
- 隐式排序 / DateTime race / 静默 `catch(_)` / StreamSubscription cancel / BuildContext 跨 async gap / Resource acquire-release
- R67 C-1 修 5 处 `_resolveTimestamp` 重复 → 公开 `DateTimeResolvers.at()` 集中器
- `swallowError` 84 处调用 / 26 文件(R66 = 49/12)

✅ **16 守护脚本全绿**(v0.27 R60 修正 12→16,R56e 新增 check_orphan_arb_keys / R57 新增 3 项法律 / R58 warn-only)

### 2.2 是否可采用更优架构?

**结论:不需要重构架构,但有 4 个真架构问题需修**

| 现状 | 是否需改 |
|------|---------|
| 4 层 + 5 子 umbrella | ✅ 保留,符合 v0.18 设计意图 |
| Drift schemaVersion 12 | ✅ 渐进升级健康 |
| Riverpod 3.3.2 | ✅ 最佳实践 |
| go_router 14.6 | ✅ page transition 3 类集中(fade/slide-right/slide-up) |
| SQLCipher | ✅ 精神心理数据敏感 |
| Domain 0 Flutter 依赖 | ✅ 易测,纯 Dart |
| ProviderScope overrides 测试 | ✅ in-memory + override |

**4 个真架构问题**(都是 P0-P1):

1. **CareEngine safety consent 撤回未真接**(CC-6) — use case 不检查 consent,隐私政策撒谎
2. **setup 阶段 saveSetup 绕过 ConsentDialog**(CC-1) — PIPL §13 单独同意技术层面不成立
3. **`mood_dialog.dart` 1204 行 18 月未拆 god class** — R64 home_page 3 bool → enum 模式可 1:1 套
4. **`data_export_service.dart` 21K orchestrator** — 抽 `ExportPlanBuilder` + `ExportPreview` 跟 R64/R65 facade 模式

### 2.3 建议重构的模块(高内聚低耦合)

#### A. R68 已抽 6 个集中器(R67 落地,已用上)

| 重复模式 | 集中器 | 抽取位置 | 使用处数 |
|---------|-------|---------|---------|
| InfoBanner 5+ 处 | `InfoBanner` (4 tone) | `widgets/info_banner.dart` | 3 (meds_calendar / setup_med / reminders_hub) |
| Stat 数字卡 2 处 | `StatCard` (label, value, valueColor) | `widgets/stat_card.dart` | 8 (trend_summary 4 + refill_manage 4) |
| Dialog actions 4 处 | `DialogActionsRow` | `widgets/dialog_actions_row.dart` | 4 (choose_window / refill_days / edit_med / temp_med) |
| ChoiceChip Wrap 2 处 | `ChoiceChipWrap<T>` 泛型 | `widgets/choice_chip_wrap.dart` | reminders_hub 2+ 处 |
| Swipe-to-dismiss 红底 3 处 | `SwipeDeleteBackground` (rounded) | `widgets/swipe_delete_background.dart` | 3 (vent_list / contacts_list / medication_row) |
| Consent dialog | `ConsentDialog` | `widgets/consent_dialog.dart` | PIPL 同意弹窗 |

#### B. R68 推荐继续抽(强候选,5+ 处)

| 重复模式 | 出现位置 | 建议集中器 | 难度 |
|---------|---------|-----------|------|
| **3 段重复 ConsentCheckRow** | `setup_step_consent.dart:75-94` | `ConsentCard(title, checked, onTap, onView)` 串联 3 个 | S |
| **OutlinedButton.icon + PressFeedback** (3 模式不一致) | `medication_report_dialog.dart:110-156` | `OutlinedButtonWithPress(icon, label, onTap, isLoading?)` | S |
| **scrim + 中心 Card(spinner + 文字)** (PDF loading) | `medication_report_dialog.dart:166-194` | `LoadingScrim(message, isLoading)` 集中器 | S |
| **InlineSpinnerInTrailing** (3 模式不一致) | `medication_row.dart:131` / `contacts_list_widget.dart:75-83` / `notification_status_card.dart:219-224` | `TrailingSpinner` 集中器 | XS |
| **setup step title / subtitle** (4 段重复 TextStyle) | `setup_step_done.dart:43, 53, 62, 74` | `AppTokens.textStyleSetupTitle` / `textStyleSetupSubtitle` 集中器 | XS |
| **3 个 l10n 魔法字符串** | `medication_calendar_page.dart:398-400` | l10n key `medsCalendarLegendP50/100/100Full` | XS |

#### C. R68 推荐抽的 atomic size tokens(8+ 处散落)

| 散落处 | magic | 建议 token | 难度 |
|--------|-------|-----------|------|
| `medication_row.dart:131-132` / `loading_text_button.dart:102-103, 131-132` | `SizedBox(width: 18, height: 18)` × 3 处 | `AppTokens.iconSizeTrailing` (18) | XS |
| `medication_report_dialog.dart:180-183` | `SizedBox(width: 20, height: 20)` | `AppTokens.spinnerSizePdf` (20) | XS |
| `setup_step_medication.dart:103-104` | `SizedBox(width: 110, height: 44)` | `AppTokens.buttonWidthNarrow` (110) + `buttonHeightCompact` (44) | XS |
| `medication_calendar_page.dart:414-415` / `trend_assessment_chart.dart:257-258` | `width: 12, height: 12` / `width: 10, height: 10` | `AppTokens.legendDotSizeLg` (12) / `legendDotSizeSm` (10) | XS |
| `medication/refill_manage_page.dart:326-327` | `width: 36, height: 36` | `AppTokens.avatarSizeSm` (36) | XS |
| `setup/widgets/reminder_cards.dart:162-163` / `assessment_history_list.dart:92-93` | `width: 40, height: 40` (4+ 处) | `AppTokens.avatarSizeMd` (40) | XS |

#### D. god class 拆解(2 个挂 18+ 月)

| 模块 | 行数 | 建议拆法 | 难度 |
|------|------|---------|------|
| `mood_dialog.dart` | 1204 | 抽 `MoodDialogOrchestrator` 状态机(7 字段 → enum)+ 业务委派 `mood_usecases.dart` | M-L |
| `data_export_service.dart` | 21K | 抽 `ExportPlanBuilder` (version 1-4 计划) + `ExportPreview` (dry-run 输出) | M |

---

## 3. 底层逐行排查(用户特别关注)

### 3.1 所有可优化点(按严重度排序)

#### P0 阻断(21 项)

**架构(7 项)**:

| # | 位置 | 问题 | 难度 |
|---|------|------|------|
| 1 | `care_engine.dart:131` + `fire_care_strategy.dart` | `isSafetyConsentWithdrawn` 仅回调签名,use case 0 注入(CC-6) | S |
| 2 | `app_database.dart:307-315` + `setup_page._saveSetup` | setup 阶段联系人绕过 ConsentDialog(CC-1) | M |
| 3 | working tree 212 文件 | R66+R67+R68 全部工作未 commit(CC-2) | XS |
| 4 | `flutter test` 2 fail 时区漂移 | `sort_assumption_round19b_test.dart:125` + `safety_watch_service_round12_test.dart:260` 跨 00:00 触发 | S |
| 5 | `.github/workflows/ci.yml` | 缺 `dart format --set-exit-if-changed` 护栏(R66 挂 2 round) | XS |
| 6 | `flutter analyze` 5 warning | unused_import 5 处,1 行 `dart fix --apply` 清 | XS |
| 7 | `home_page.dart:622-650` `_showCelebrationOverlay` | 35% 高度定位 — 键盘弹起/横屏/全面屏撞顶 | XS |

**底层(14 项)**:

| # | 位置 | 问题 | 难度 |
|---|------|------|------|
| 8 | `user_agreement.md:25,28` + `store_kit_service.dart:118` + `feature_flags.dart:36` | IAP 8 元买断 vs `buyLifetime()` 返 false(CC-3) | S |
| 9 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent}.md` | 顶部 "TODO 律师过审" banner 仍保留(CC-4) | L |
| 10 | `pubspec.yaml:2` | description 单语种中文(CC-5) | M |
| 11 | `privacy_policy.md:87, 121-123, 195` | §4 / §9 / §12 表格"CareEngine 撤回后直接 return"表述需 walkthrough(CC-6 修后改) | S |
| 12 | `fastlane/metadata/ios/*` 33 张截图 | 67 字节透明占位(27 必填) | L |
| 13 | `fastlane/metadata/ios/*/app_icon.png` 3 个 | 67 字节占位 → 1024×1024 真图 | XS |
| 14 | `fastlane/metadata/android/*/phone_screenshots/*.png` 8 张 | 67 字节占位 | S |
| 15 | `fastlane/metadata/android/*/feature_graphic.png` 2 张 | 67 字节占位 → 1024×500 真图 | XS |
| 16 | `fastlane/metadata/android/*/icon.png` 2 张 | 1443 字节 / 192×192 → 512×512 | XS |
| 17 | `fastlane/metadata/{android,ios}/*/video.txt` 2 文件 | PLACEHOLDER URL 占位 | XS |
| 18 | `build.gradle.kts:80` + `android/key.properties` 不存在 | release 签名仍是 debug keystore | S |
| 19 | `assets/legal/*.md` 部署 | Privacy Policy URL 未托管到 HTTPS 公网 | M |
| 20 | `user_agreement.md:60-61` | `support@chroniccare.app` + `github.com/example` TODO 占位 | XS |
| 21 | `fastlane/{Fastfile,Appfile}` | Android 端 0(lane 缺失) | S |

#### P1 警告(44 项,跨 6 视角)

**架构(12 项)**:
- 跨视角 8 项 CC + 4 项 spen 独占(SP-1~4)+ 1 项 spec E10.6 CI 漏 11 守护
- `mood_dialog.dart` 1204 行 18 月挂 god class
- `data_export_service.dart` 21K orchestrator
- 3 份 markdown 0 英文/繁体版(CC-8)
- PHQ-9 / GAD-7 16 题题目未 i18n 化
- ...

**底层(32 项)**:
- 5 个 R67 子智能体遗留:dark mode 2 处 / app_theme alpha 2 处 / consent UI 5 vs 3 kind / care_copy 4 trigger / 文档时间漂移
- 4 处上架文档脱节(CC-7):`fastlane/metadata/android/en-US/full_description.txt:14` + `zh-CN/title.txt:1` + `user_agreement.md:17,40` + `sensitive_data_consent.md:27,47,64`
- 15+ 处 hardcoded 字符串:`medication_calendar legend` / `trend_heatmap ✓` / `setup_step_done` 4 处 TextStyle inline
- 30+ 处 `Strings.xxx` caller 不走 override(`medication_report_pdf_layout` 27 处 + `medication_report_pdf` 7 处)
- `notification_service.init()` 0 单测(tz 失败 silent)
- `app_database.dart:163-186` vent v8→v9 加密失败无用户视觉提示
- `setup_page.dart` 4 步骤 0 集成测 / `settings_page.dart` 0 集成测
- `BootReceiver.kt:32-37` 占位启动 MainActivity
- `vent_compose_page.dart:135-141` RECORD_AUDIO in-app rationale 缺
- `notification_status_card.dart` SCHEDULE_EXACT_ALARM 引导缺
- 100ms 录音 tick / file lock magic(`mood_audio_service.dart:124` / `vent_audio_storage.dart:95`)
- 8+ 处 atomic size magic(18/20/36/40/110/12/10)
- 50 处全角标点 warn-only
- `consentAt` 索引已加但 PIPL §47 查询 UI 未做
- 病耻感措辞 "让家人放心" / "你真棒"
- "TA" 网络用语(`lost_contact_sms.dart:69`)
- toJson 缺 `contactsMocked`(`safety_watch_service.dart:443-449`)
- 文档数字漂移(AGENTS.md 1163→1284 / README.md 1098→1284)
- 6 处 widget 集中器尚未抽(OutlinedButtonWithPress / LoadingScrim / TrailingSpinner / ConsentCard)
- ...

#### P2 建议(32 项)

设计工程、动效、token 散落、a11y、单元测覆盖、CFBundleDisplayName per-locale、abifilters、.gitignore、apk size 监控、启动埋点、PR 模板、零 APM 文档、.then() 残存、IAP SDK 升 7.x、PHQ-9 detectCrisis hotlineByRegion i18n、notification_service 角标 TODO、setup_legal_dialog 注释 v1.0、双层 feature flag 注释、medsCalendarLegendP50/100/100Full ARB key、...

### 3.2 需要修复的 Bug 清单(汇总)

#### Bug A. 回归 test fail(2 个)

| 位置 | 问题 | 根因 | 修复 |
|------|------|------|------|
| `test/data/sort_assumption_round19b_test.dart:125` | `daysSinceLast: Expected 0 Actual 1` | 跨 00:00 后 `difference.inDays = 1` | 入口 `final now = DateTime.now();` + 比较前 `DateUtils.dateOnly(...)` 对齐 day 边界 |
| `test/data/safety_watch_service_round12_test.dart:260` | `kind: Expected ok Actual alerted` | 同款时区漂移 | 同上 |

#### Bug B. 隐式排序回归(0 违规,R67 100% 合规,新增守护)

`grep "\.first.timestamp\|\.last.timestamp\|\.first.id\|\.last.id"` = 0 命中
- 之前 5 处已修:streak_calculator / assessment_comparison / reminder_scheduler / safety_watch_service / assessment_reminder_service
- R67 持续守住

#### Bug C. DateTime race(0 违规,R67 C-1 修)

- 之前 89 处 / 47 文件
- R67 5 处替换为 `DateTimeResolvers.at()` 集中器
- 当前 94 处 / 47 文件 / **0 race**(`date_time_resolver_round67_test.dart` 5 case ✅)

#### Bug D. dark mode 漏(2 处)

| 位置 | 问题 | 修复 |
|------|------|------|
| `settings/settings_page.dart:63` | `Icon(color: AppColors.success)` const 硬编,dark mode 漏反白 | 改 `AppColors.fgOnSuccess(context)` |
| `settings/settings_page.dart:92` | `Icon(color: AppColors.primary)` 同款 | 改 `AppColors.primaryColor(context)` |

#### Bug E. PIPL 撒谎(CC-6)

| 位置 | 问题 | 修复 |
|------|------|------|
| `privacy_policy.md:87, 121-123, 195` | §4 / §9 / §12 表格说"CareEngine 撤回后直接 return" — 实际**没接** | 修 `FireCareStrategyUseCase` 透传 `isSafetyConsentWithdrawn` + home_page 注入 + 文档 walkthrough |
| `app_database.dart:307-315` | setup 阶段 saveSetup 写联系人留空 4 consent 字段 | `saveSetup` 改走 `contactRepository.add(consentArtifact: ...)` 逐个弹 ConsentDialog |

#### Bug F. IAP 状态不一致(CC-3)

- `FeatureFlags._prodIapEnabled = true` 默认开 IAP
- `StoreKitService.buyLifetime()` release 模式 `return false`
- 用户在 release 看到 IAP 入口 → 永远失败
- 修复:选项 A 临时改 `_prodIapEnabled=false` / 选项 B 真接 productId

#### Bug G. 上架文档脱节(CC-7)

4 处文档写"失联通知"功能可用 vs `FeatureFlags.emergencyContactEnabled=false` 业务暂停:
- `fastlane/metadata/android/en-US/full_description.txt:14` "automatically notify" 措辞
- `fastlane/metadata/android/zh-CN/title.txt:1` "失联通知" 措辞
- `user_agreement.md:17, 40`
- `sensitive_data_consent.md:27, 47, 64`

---

## 4. 上架 / 架构 / 半成品 / 重构 — 4 大用户重点

### 4.1 上架相关(AppStore + GooglePlay 合并)

#### 4.1.1 P0 提交必拒(18 项,iOS + Android 跨平台)

**iOS(AppStore 10 P0)**:
- A-1: `fastlane/metadata/ios/` 截图 / app_icon 33 张占位
- A-2: `fastlane/Fastfile` + `Appfile` 4 处 TODO(apple_id / team_id / itc_team_id / app_identifier 改 `com.chroniccare.app`)
- A-3: 失联通知 SMS 业务整体暂停但 description 还说"automatically notify"
- A-4: IAP 8 元买断 release 模式 `buyLifetime()` 返 false
- A-5: App Store 截图 + 3 法律 md TODO
- A-6: `AppDelegate.swift` 0 注 `BGTaskScheduler`(`Info.plist` 已声明 `com.chroniccare.safety-check`)
- A-7: `AppDelegate.swift` 0 设 `UNUserNotificationCenter.current().delegate`(R67 Sprint 1 已修)
- A-8: `Info.plist` 缺 `NSPhotoLibraryUsageDescription`(R67 Sprint 1 已修)
- A-9: `PrivacyInfo.xcprivacy` `NSPrivacyCollectedDataTypes=[]` 与实际不符(R67 Sprint 1 已修)
- A-10: App Store Connect "App Privacy" 标签必填 4 类数据

**Android(GooglePlay 8+2 P0)**:
- G-1: release keystore 仍是 debug + 未 Play App Signing
- G-2: Privacy Policy URL 未托管 HTTPS
- G-3: `fastlane/{Fastfile,Appfile}` Android 端 0 + 8 截图 / 2 feature_graphic / 2 icon 占位
- G-4: Data Safety Form / Health Apps questionnaire / Permissions Declaration Form / Data deletion 0 维护
- G-5: `USE_EXACT_ALARM` Play Console justification 100+ 字符未准备
- G-6: Data deletion endpoint URL 缺失
- G-7: SMS Provider throw StateError vs Privacy Policy 说"会发 SMS"
- G-8: IAP 8 元买断 vs Play Store 收费政策不一致
- G-9: `zh-CN/short_description.txt` 89 字符超 80 限制(R67 修了)
- G-10: description 文档与 R66 业务暂停状态不一致

**共识(2 项,跨 5 视角)**:
- CC-3: IAP 8 元买断 vs `buyLifetime()` 返 false + `FeatureFlags._prodIapEnabled=true` 默认开
- CC-4: 3 份法律 markdown 顶部 TODO 仍保留

#### 4.1.2 P1 警告(20 项)

**iOS(10 项)**:
- aps-environment 误导 / CFBundleDisplayName per-locale / NSUserNotificationUsageDescription 老 key / ITSAppUsesNonExemptEncryption vs SQLCipher / EXCLUDED_ARCHS arm64 / 失联通知业务暂停 / 隐私政策 §11 跨境 audit log / PHQ-9 16 题英译 / UIBackgroundModes audio 提示 / support@ 邮箱注册

**Android(8 项)**:
- BootReceiver 占位 / RECORD_AUDIO in-app rationale / IAP 8 元 vs 业务暂停 / SCHEDULE_EXACT_ALARM 引导 / short_description "chronic patients" 措辞 / video.txt PLACEHOLDER / 16KB page size 验 / abiFilters 显式

**共识(2 项,跨 2-3 视角)**:
- CC-7: 失联通知 4 文档"功能可用"措辞
- CC-8: 3 份 markdown 0 英文/繁体版

#### 4.1.3 P2 建议(10 项)

NSPrivacyAccessedAPICategoryProcessInfo / 第三方 plugin 自带 PrivacyInfo 核 / UISceneStoryboardFile 双 storyboard / LaunchImage 占位 / pubspec 版本号 < 1.0.0 / 失联通知 v0.27 暂停 App Store Connect 描述 / 64-bit ABI 显式 / DEPLOYMENT.md 重写 / Background isolation 注释 / in_app_purchase 升 7.x

#### 4.1.4 上架时间预估(按 1 人 8h/d)

| 阶段 | 内容 | 时间 |
|------|------|------|
| **M1 最小可上架** | 18 P0 提交必拒(代码侧) | 3-5 天 |
| M1 法务 review | 3 份 markdown + 隐私政策 4 段 walkthrough | 1-2 周 |
| **M2 完整 CI 化** | fastlane Android + CI 护栏 + P1 警告 + 16KB page size 验 | +3-5 天 |
| M3 v1.0 | 真接阿里云 SMS / 真接 SendGrid / 真接 IAP + 隐私 URL + NMPA "非医疗器械"备案 + 软件著作权登记 | +3-6 月 |

**最大拦路虎**:法务 review(1-2 周,¥15-30k/文档)

### 4.2 架构相关(4 层 + 高内聚低耦合)

✅ **架构纯度 100%**:`scripts/check_all.dart` 验证
✅ **设计 token 完整**:23+ 集中器,5 子模块
✅ **测试纪律 100%**:5 类历史 bug 模式全合规
✅ **i18n 3 层边界清晰**

❌ **4 个真架构问题**:
1. CareEngine safety consent 撤回未真接(CC-6) — `care_engine.dart:131` 仅回调签名,use case 0 注入
2. setup 阶段 saveSetup 绕过 ConsentDialog(CC-1) — `app_database.dart:307-315`
3. `mood_dialog.dart` 1204 行 18 月挂 god class — 可走 R64 home_page 3 bool → enum 模式
4. `data_export_service.dart` 21K orchestrator — 抽 `ExportPlanBuilder` + `ExportPreview`

**修复时间**:4 个问题 5-8 天工作量

### 4.3 建议重构的模块(高内聚低耦合)

详见 §2.3 表格:
- **6 个 R67 已抽集中器**(已用上)
- **5 个强候选集中器**(R68 推荐继续抽)
- **8+ 处 atomic size token 散落**
- **2 个 god class 拆解**(mood_dialog 1204 行 / data_export_service 21K)

**修复时间**:5+ 集中器 1 周 + 2 god class 1 周 + atomic token 半天 = **2-3 周**

### 4.4 半成品 / TODO / 未完成

**5 视角共识 10 项 P0 中 4 项是"半成品"**:
1. CC-2:212 文件 working tree 未 commit(流程性)
2. CC-4:3 份法律 markdown 顶部 TODO banner 仍保留(法律性)
3. CC-6:隐私政策撒谎 — §4 / §9 / §12 表格"已实现"实际未(文档与代码)
4. CC-7:失联通知 4 文档"功能可用"vs 业务暂停(文档与代码)

**R68 新发现半成品**:
- `home_page.dart:551, 561` "R55+ TODO" 占位(SMS / Email 真接)
- `app_theme.dart:128` `// TODO v0.25: 评估 buildTheme 接受 context`(挂 1 年)
- `BootReceiver.kt:30-31` "留给 R64 完善" 注释(R64/R65/R66/R67 4 轮未动)
- `AliyunSmsProvider.send()` `throw StateError('R55+ 真接 TODO...')`(外部依赖,法务 1-2 月)
- `EmailService.send()` release 模式 `return false`(R67 B-1 加守门员,真接待 v0.28)
- 50 处全角标点 warn-only(已知决策)

---

## 5. 修复优先级总表(按 P0 / P1 / P2 + XS/S/M/L)

### 5.1 P0 必修(39 项)

| 序 | 类别 | 位置 | 难度 | 关键 |
|----|------|------|------|------|
| 1 | 流程 | working tree 212 文件 commit(CC-2) | XS | **先 commit 再修代码** |
| 2 | 架构 | `fire_care_strategy.dart` 注入 `isSafetyConsentWithdrawn`(CC-6) | S | 隐私政策撒谎 |
| 3 | 架构 | `setup_page._saveSetup` 走 ConsentDialog(CC-1) | M | PIPL §13 单独同意 |
| 4 | 底层 | IAP 8 元 vs `buyLifetime()` 返 false(CC-3) | S | 决策:关 / 真接 |
| 5 | 底层 | `pubspec.yaml:2` 加 en / zh_Hant 描述(CC-5) | M | App Store 元数据 |
| 6 | 底层 | 3 份法律 markdown 顶部 TODO(CC-4) | L | 律师 1-2 周 |
| 7 | 底层 | `privacy_policy.md` §4 / §9 / §11 / §12 walkthrough(CC-6 修后) | S | 法务过审 |
| 8 | 流程 | 修 2 个 test fail 时区漂移(`sort_assumption_round19b_test.dart:125` + `safety_watch_service_round12_test.dart:260`) | S | `DateUtils.dateOnly` 对齐 |
| 9 | 工程化 | CI 加 `dart format --set-exit-if-changed` 护栏(`.github/workflows/ci.yml`) | XS | 防 C1.5 复发 |
| 10 | 工程化 | `dart fix --apply` 清 5 warning | XS | 1 行命令 |
| 11 | 底层 | iOS 33 张截图 / 3 app_icon 替换 | L | 必填,真截图 |
| 12 | 底层 | Android 8 截图 / 2 feature_graphic / 2 icon 512×512 替换 | S | 必填,真截图 |
| 13 | 底层 | `build.gradle.kts:80` 切 `signingConfig=release` + `key.properties` + 真实 keystore | S | Play App Signing |
| 14 | 底层 | 注册 `chroniccare.app` 域名 + 部署 HTTPS 隐私 URL | M | 域名 + 部署 |
| 15 | 底层 | 注册 `support@chroniccare.app` 邮箱 + 替换 2 处 TODO | XS | 邮箱注册 |
| 16 | 底层 | Android 端 `fastlane/{Fastfile,Appfile}` 加 `platform :android` 块 | S | 半天 |
| 17 | 底层 | 填 Play Console 4 大表单(Data Safety / Health Apps / Permissions Declaration / Data Deletion) | M | 2-3h |
| 18 | 底层 | 改 4 处文档 wording 失联通知(CC-7) | XS | 1-2h |
| 19 | 设计 | `home_page.dart:622-650` `_showCelebrationOverlay` 35% 高度定位 → `MediaQuery.padding.top + spacingLg` | XS | 撞顶 |
| 20 | 设计 | `medication_report_dialog.dart:166-194` scrim 加 `AbsorbPointer` | XS | 锁死 |
| 21 | 设计 | `settings_page.dart:63, 92` 2 处 dark mode 漏(CC-9) | XS | 5min |

### 5.2 P1 应修(44 项,跨 6 视角)

| 类别 | 数量 | 代表项 |
|------|------|--------|
| 架构 | 12 | CC-7/CC-8/CC-10 + 4 god class + 6 widget 集中器尚未抽 |
| 底层 | 32 | 4 处上架文档脱节(CC-7) + 15+ hardcoded 字符串 + 30+ `Strings.xxx` caller + 100ms magic + 8+ atomic size + 5 R67 子智能体遗留 |

**代表 P1(节选)**:
- `mood_dialog.dart` 1204 行 18 月挂 god class(spen)
- `data_export_service.dart` 21K orchestrator(spen)
- 3 份 markdown 0 英文/繁体版(CC-8)
- PHQ-9 / GAD-7 16 题题目英译(appstore P1)
- `BootReceiver.kt:32-37` 占位启动 MainActivity(googleplay P1)
- `vent_compose_page.dart:135-141` RECORD_AUDIO in-app rationale 缺(googleplay P1)
- `notification_service.init()` 0 单测(spen)
- 6 处加 `RepaintBoundary`(spec P5.4)
- 2 处 `.then()` 残存(spec P5.4)
- `flutter test --coverage` + lcov 60% 门槛(spec T8.3)
- 50 处全角标点 warn-only(已知决策)
- 5 个 R67 子智能体遗留:dark mode 2 处 / app_theme alpha 2 处 / consent UI 5 vs 3 kind / care_copy 4 trigger / 文档时间漂移

### 5.3 P2 建议(32 项,跨 6 视角)

设计工程、动效、token 散落、a11y、单元测覆盖、CFBundleDisplayName per-locale、abifilters、.gitignore、apk size 监控、启动埋点、PR 模板、零 APM 文档、.then() 残存、IAP SDK 升 7.x、PHQ-9 detectCrisis hotlineByRegion i18n、notification_service 角标 TODO、setup_legal_dialog 注释 v1.0、双层 feature flag 注释、medsCalendarLegendP50/100/100Full ARB key、...

---

## 6. 上架时间预估(按 1 人 8h/d)

| 阶段 | 内容 | 工程师天 | 关键路径 |
|------|------|---------|---------|
| **M1 最小可上架**(代码侧) | 21 P0 提交必拒 + 5 视角共识 P0 10 项 + 修 2 test fail | 30-40h (~5 天) | 1+3+4+5+6+7+8+9+10+11-18 同步 |
| **M1 法务 review** | 3 份 markdown + 隐私政策 §11/§12 walkthrough | 1-2 周 | 不可压缩 |
| **M2 完整 CI 化** | fastlane Android + CI 护栏 + P1 警告 + 16KB page size 验 + 5 widget 集中器 + atomic size tokens | 3-5 天 | 跟 M1 并行 |
| **M3 v1.0** | 真接阿里云 SMS / SendGrid / IAP + 隐私 URL + NMPA "非医疗器械"备案 + 软件著作权登记 | 3-6 月 | 外部依赖 |

**M1 关键路径**:
- Day 1: commit 212 文件 + 修 2 test fail + 5 warning + CI 护栏 + 4 集中器 / atomic tokens
- Day 2: CareEngine safety + setup ConsentDialog + IAP 决策 + pubspec en / zh_Hant
- Day 3-4: iOS 33 截图 + Android 8 截图 / feature_graphic / icon 512 + 注册域名 / 邮箱 + Android fastlane + Play Console 4 表单
- Day 5: 4 文档 wording + 律师 review 启动(并行)

**最大拦路虎**:**法务 review**(1-2 周,¥15-30k/文档)— 不修则 Developer Policy 4.8 / Apple 4.8 违规

---

## 7. 3-5 句精炼建议

1. **先 commit 再修代码** — 212 文件 working tree 已是实质 R68 commit 形状(ConsentGate / EmailService 守门员 / 7 集中器 / 隐私政策软隐藏),**先** `git add -u && git commit -m "v0.27 round 68: P0 集中修复"`,否则 master 与实际代码不同步让 CI/审计/review 全失效(CC-2 / P0-1, 1h 闭环)。

2. **3 个 P0 一致性 bug 同 PR 修** — 隐私政策撒谎(CC-6, 1h) + setup 阶段 ConsentDialog(CC-1, 2h) + IAP 8 元买断(CC-3, 1h) 3 个 P0 都在"营销性宣称 ≠ 实际行为",5h 内 3 个 P0 同时清,合并 PR 避免又留 R69。

3. **架构 / 重构 / 半成品 4 项合做 5-8 天** — CareEngine safety 撤回(CC-6) + setup ConsentDialog(CC-1) + mood_dialog 1204 行 god class 拆 + data_export_service 21K orchestrator 拆,4 个全跟 R64/R65 facade 模式 1:1 套,5-8 天工作量,跟主 P0 修复同 PR 合并。

4. **v1.0 上 store 是"非代码"环节卡死** — 4 视角共识显示,真正卡上架的不是 14 章规范合规率(88% 已经是高水准),而是 律师过审 3 份 md + 注册域名 + 33 张 iOS 截图 + 真实 keystore + 真实 `support@` 邮箱(1-2 周 不可压缩),建议 R69 立即启动"法务 + 域名 + 截图"3 条工作流,跟代码 14 章合规分头推进。

5. **总体评级:⭐⭐⭐⭐ 4.5/5**(持平 R66)。R67 修了 3 个 P0-P1(EmailService 守门 / `_resolveTimestamp` / use case 抽离)+ 6 个新 widget 集中器 + C1.5 满分回归,工程质量**已达 v1.0 上 store 水平**(88% 规范合规 + 0 error + R67 守门员链完整 + 5 视角共识 10 条全识别),**流程**(commit / test 漂移 / CI 护栏 / 上架元数据) 是最后 12% 缺口。

---

## 8. 6 份视角报告路径

| 视角 | 报告 | 大小 |
|------|------|------|
| emilkowalski | `reports/audit/round68-emilkowalski.md` | 32 KB / 360 行 |
| superpowers-en | `reports/audit/round68-superpowers-en.md` | 19 KB / 193 行 |
| superpowers-zh | `reports/audit/round68-superpowers-zh.md` | 18 KB / 261 行 |
| AppStore | `reports/audit/round68-appstore.md` | 33 KB / 314 行 |
| GooglePlay | `reports/audit/round68-googleplay.md` | 39 KB / 472 行 |
| flutter-specification | `reports/audit/round68-flutter-specification.md` | 16 KB / 137 行 |
| **汇总(本文件)** | `reports/audit/round68-CONSOLIDATED.md` | — |

---

**报告完毕。** 跟 R66 报告(R66-CONSOLIDATED.md 36 P0 + 44 P1 + 36 P2)对比,R68 总问题数从 116 → 115(几乎持平),但**结构变化大**:R67 修了 6 个 P0-P1(EmailService 守门 / `_resolveTimestamp` / use case 抽离),新增 5 视角共识 10 项 P0(集中"营销性宣称 ≠ 实际行为"和"工作流未 commit"两类新维度),上架阻塞项**仍是 v1.0 最大拦路虎**(法务 1-2 周 不可压缩)。
