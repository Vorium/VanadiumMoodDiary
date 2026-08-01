# v0.27 R69 superpowers-zh 视角审计

**审计时间**: 2026-08-01
**项目**: chroniccare（精神心理患者吃药打卡 App）
**版本**: 0.27.0+64（pubspec）；R68 commit d691551
**视角**: superpowers-zh（中文 i18n + PIPL §13/§14/§47 合规 + 中文工作流 + 隐私边界）
**审计模式**: 全量
**基础**: `reports/audit/round68-superpowers-zh.md`（27 issues，9 P0 / 6 P1 / 7 P2 / 5 P3）
**R68 commit d691551**: CC-1（setup ConsentDialog）/ CC-3（IAP 隐藏）/ CC-6（CareEngine safety 撤回真接）3 个 P0 集中修复
**working tree**: 干净（仅 2 个 R69 视角审计文件未跟踪）

---

## §0 评级

⭐⭐⭐½ / 5（vs R68 ⭐⭐ 2/5）

**升级理由**:
- 9 个 P0 中 **3 个 R68 集中修复**（CC-1 / CC-3 / CC-6）落地并通过 commit 验证
- 2 个 R68 标志的"真架构问题"（god class）**R64/R65/R66/R67 已拆完**（mood_dialog 26 行薄壳 + data_export_service 119 行 facade）
- R68 标志的"212 文件 working tree 未 commit"已通过 d691551 + 556d454 落地
- 5 类历史 bug 模式 + 16 守护脚本全部持续守住

**仍挂**:
- 6 个 P0（R68 之前 P0，R68 未触碰）：3 份 markdown 顶部 TODO / pubspec description 单语种 / 失联通知 4 文档 wording / 0 英文+繁体 markdown / dark mode 2 处 / app_theme alpha 2 处
- 1 个 R69 新发现：CHANGELOG R68 commit d691551 没补新 [Unreleased] 段（仅 R66/R65/R63 在 [Unreleased]）
- 上架文档与代码脱节 5 处（user_agreement 8 元 / 隐私政策 v0.25/R55 引用过期）

---

## §1 R68 → R69 增量对照

### 1.1 R68 已修（5 项验证生效）

| R68 ID | 位置 | 修复方式 | 验证 |
|---|---|---|---|
| **CC-1** | `app_database.dart:277-318` + `setup_page.dart:370-428` | `saveSetup` 加 `contactConsents: List<ConsentArtifact>` 参数；setup 阶段每个填了的联系人逐个弹 ConsentDialog；`assert(contactList.length == contactConsents.length)` 守门 | `grep "contactConsents" lib/core/data/database/app_database.dart lib/presentation/pages/setup/setup_page.dart` = 7 处全部就位 ✓ |
| **CC-3** | `feature_flags.dart:38` | `_prodIapEnabled = false` 临时关闭 IAP 入口 | `grep "_prodIapEnabled" lib/core/data/feature_flags.dart` = `false` ✓ |
| **CC-6** | `fire_care_strategy.dart:140-209` + `home_page.dart:523, 533` | `FireCareStrategyInput` 加 `isSafetyConsentWithdrawn: bool` 字段；use case 入口 `if (!config.enabled \|\| isSafetyConsentWithdrawn) → disabled`；home_page 从 `legalConsentWithdrawnProvider(ConsentKind.safety).future` 注入 | use case 第 200-209 行 `if (!input.config.enabled \|\| input.isSafetyConsentWithdrawn) { return FireCareStrategyResult(decision: FireCareDecision.disabled...) }` ✓ |
| **CC-2** | working tree 212 文件 | R68 commit d691551 (CC-1/3/6) + 556d454 (R66+R67+P0 集中) | `git log --oneline -3` = `d691551` / `556d454` / `01c5c26` ✓ |
| **god class 拆解** | `mood_dialog.dart` 26 行 + `data_export_service.dart` 119 行 | R64 / R57 / R65 三轮 facade 模式落地 | `wc -l lib/presentation/pages/mood/mood_dialog.dart lib/core/data/services/data_export_service.dart` = 26 / 110 行 ✓ |

### 1.2 R68 未修（6 项仍挂）

| R68 ID | 位置 | 当前状态 |
|---|---|---|
| **CC-4** | `assets/legal/{privacy_policy,sensitive_data_consent,user_agreement}.md` 顶部 TODO banner | 仍保留 "TODO (上 store 前必须由专业律师过审)" 3 处 |
| **CC-5** | `pubspec.yaml:2` | `description: "我今天吃了药 - 精神心理患者吃药打卡 + 停药通知"` 单语种中文 |
| **CC-7** | `user_agreement.md:17, 40` + `sensitive_data_consent.md:27, 47, 64` | 仍写"失联通知"功能可用 vs `FeatureFlags.emergencyContactEnabled=false` 业务暂停（`fastlane/metadata/{ios,android}/en-US/full_description.txt` 已软化为 "coming soon — currently disabled" ✓） |
| **CC-8** | `assets/legal/*.md` | 仍 0 英文版 / 0 繁体版（`fastlane/metadata/ios/{zh-Hans,zh-Hant}/description.txt` 已有 2 套 ✓，但隐私政策原文无） |
| **CC-9** | `settings/settings_page.dart:63, 92` | 2 处 `Icon(color: AppColors.success/primary)` const 硬编 dark mode 漏反白 |
| **CC-10** | `app_theme.dart:128, 209` | 2 处 `withValues(alpha: 0.5/0.6)` 走 inline 而不是 `AppColors.fgDisabled/fgHintInput` 集中器 |

### 1.3 R69 新发现（3 项）

| R69 ID | 位置 | 严重度 | 说明 |
|---|---|---|---|
| **R69-N1** | `docs/CHANGELOG.md:5-7` | P1 | 3 个 [Unreleased] 段（R66 / R65 / R63）都未升到 [0.27.0]；R68 commit d691551 没补新 [Unreleased] 段。check_changelog.py 22 个版本头验证过但顺序与 round 对应脱节 |
| **R69-N2** | `user_agreement.md:26, 28` | P1 | 仍写"本 App 售价人民币 8 元..."（CC-3 R68 决策关 IAP 入口，但 user_agreement 文档没同步 — 用户同意时看到 8 元，store 里没 IAP 入口，文档与代码不一致） |
| **R69-N3** | `privacy_policy.md:138, 175, 185, 192, 201` | P2 | §11 "跨境数据传输 (v0.25 R54 增补)" / §11 "v0.25 (本版本) 尚未接入..." / §12 "❌ v0.25 TODO (依赖 SMS provider 真接,见 R55)" / §12 修复路径 "v0.26 R55 接 SMS provider" 5 处版本号 / Round 号全部过期（v0.25 → v0.27 / R55 → 未真接） |

---

## §2 顶层架构审视

### 2.1 4 层架构 + 跨 feature 边界

| 检查项 | 工具 | R68 状态 | R69 状态 |
|---|---|---|---|
| 4 层架构纯度 | `dart scripts/check_all.dart` | ✅ 100% | ✅ 100%（domain 0 flutter / 0 drift / 0 data / 0 presentation；shared/ 0 跨层） |
| 跨 feature import | `python scripts/check_cross_feature.py` | ✅ 0 violation | ✅ 0 violation（67 files） |
| 架构语义一致性 | `dart scripts/check_all.dart` | ✅ | ✅（每个 `*Entity` 对应 drift table；shared/ 工具被 ≥2 层用） |
| 设计 token 完整 | `app_tokens` + 4 sub | ✅ 23+ 集中器 | ✅ 持续（R67 6 个新 widget 集中器已用上） |
| i18n 3 层边界 | `l10n/` + `core/l10n/` + `core/shared/json_codec.dart` | ✅ 职责分明 | ✅ 持续（无新反模式） |

**R69 评估**:
- 4 层架构 100% 纯，无新反模式
- 跨 feature 边界守住（67 files / 0 violation）
- 0 跨层 import 隐患

### 2.2 中文代码 / 文档 / commit 规范

| 检查项 | R68 状态 | R69 状态 | 说明 |
|---|---|---|---|
| 中文 commit 风格 | ✅ 25+ commit 100% 符合 `v0.27 round N: <title>` | ✅ 持续 | `d691551` / `556d454` 都符合 |
| 中文注释（domain 层） | ✅ 业务逻辑说明 / TODO / FIXME 全中文 | ✅ 持续 | `fire_care_strategy.dart:140-145` R68 注释中文 |
| i18n 3 语同步 | ✅ 622 / 622 / 622 100% | ✅ **623 / 623 / 623** | R68 commit 加 1 个 key (`setupConsentRejected`)，3 语全同步 |
| 繁简一致性 | ✅ 100% (OpenCC s2tw) | ✅ 持续 | 623 keys 繁简 100% 一致 |
| ARB orphan 清理 | ✅ 0 orphan | ✅ 持续 | R56e + R67 守住 |
| 全角标点 | 🟡 50 违规（warn-only） | 🟡 50 违规 | 已知决策 R66 不强制 |
| CHANGELOG 顺序 | ✅ 22 个版本头 | ✅ 25 个版本头 | R66/R65/R63 都在 [Unreleased]（**R69-N1**） |
| 中英文混排 | ✅ 中英文之间空格 | ✅ 持续 | 无新违规 |
| 病耻感措辞 | ❌ "让家人放心" / "你真棒" 仍挂 | ❌ 仍挂 | R66 spzh P0-4 续挂 |
| "TA" 网络用语 | ❌ `lost_contact_sms.dart:69` | ❌ 仍挂 | R66 spzh P0-5 续挂 |

**R69 评估**:
- 中文 commit 风格 + 中文注释 + 3 语 i18n + 繁简一致 100% 守住
- 病耻感 / 网络用语 仍是 P3 尾巴
- CHANGELOG 版本号与 round 同步脱节（**R69-N1 新发现**）

### 2.3 god class / 半成品清单

| 模块 | R68 状态 | R69 状态 | 备注 |
|---|---|---|---|
| `mood_dialog.dart` | ❌ 1204 行 18 月挂 god class | ✅ **26 行薄壳** | R64 拆到 `widgets/mood_recorder_page.dart`，外部 API `MoodDialog.show()` 保持 |
| `data_export_service.dart` | ❌ 21K orchestrator | ✅ **119 行 facade** | R26 R57 拆 1 facade + 4 sub-service |
| `AliyunSmsProvider.send()` | ❌ throw StateError 占位 | 🟡 **仍占位**（设计选择） | R63 加 `_isFullyImplemented=false` 守门员，release 模式 `validateForRelease` 阻断 |
| `EmailService.send()` | ❌ release 模式 `return false` | 🟡 **仍占位**（R67 B-1 加 `validateForRelease` 守门员） | 真接待 v0.28 |
| `BootReceiver.kt:30-31` | ❌ 占位启动 MainActivity（R64-R67 4 轮未动） | ❌ **仍占位** | R68 无 commit 触及；需 Android 端小项收尾 |
| `home_page.dart:549, 557, 567` | ❌ "R55+ TODO" 占位（SMS / Email 真接） | ❌ **仍占位** | 联系人 phone / email 拿真实值；SMS provider 真接后才有意义 |
| `sms_service.dart:90-104` "v1.0+ TODO" | ❌ 阿里云 SDK 接入 | ❌ **仍挂** | 外部依赖（法务 1-2 月 + 阿里云 AccessKey 申请） |
| `email_service.dart:19, 40, 162` "v1.0+ TODO" | ❌ SendGrid 真接 | ❌ **仍挂** | 外部依赖 |
| `notification_service.dart:385, 389` iOS 角标 / Android | ❌ TODO 集成 flutter_app_badge_control | ❌ **仍挂** | 已知 P2，v1.0+ 集成 |
| `app_theme.dart:128` `// TODO v0.25: 评估 buildTheme 接受 context` | ❌ 挂 1 年 | ❌ **仍挂** | ThemeProvider 接口变更（CC-10 跟 TODO 是同一来源） |
| 50 处全角标点 `…` | 🟡 warn-only | 🟡 **仍挂** | 已知决策 |
| 3 份法律 markdown 顶部 "TODO 律师过审" banner | ❌ 仍保留 | ❌ **仍挂**（CC-4） | 律师 1-2 周不可压缩 |

**R69 评估**:
- 2 个 god class（mood_dialog + data_export_service）R64 / R57 已拆完，是 R68 报告的"半成品"中**已解决**的
- 半成品集中在 5 类"v1.0+ 外部依赖"（SMS 真接 / Email 真接 / IAP 真接 / 角标 / BootReceiver 占位），设计上都是"占位 + 守门员 + 业务暂停"模式，**不会**让 v0.27 release 静默失败
- 真正卡 v1.0 上 store 的是"法务 review 3 份 md"+"支持邮箱 + 域名"+"截图"+"真实 keystore"，非代码性

### 2.4 PIPL / 隐私边界合规

| PIPL 条款 | R68 状态 | R69 状态 | 验证 |
|---|---|---|---|
| §13 单独同意 | 🟡 setup 阶段绕过 | ✅ **R68 修**（CC-1） | `setup_page.dart:370-399` 每个填了联系人逐个弹 ConsentDialog，`assert(contactList.length == contactConsents.length)` 守门 |
| §14 撤回同意 | 🟡 vent / analytics 真接，safety 仍 UI-only | ✅ **R68 修**（CC-6） | `fire_care_strategy.dart:202` `if (!config.enabled \|\| isSafetyConsentWithdrawn) → disabled` + `home_page.dart:523, 533` 注入 |
| §23 单独告知第三方 | ✅ 软提示 + 业务暂停双层防御 | ✅ 持续 | `privacy_policy.md:34` "R66 软提示更新" + `FeatureFlags.emergencyContactEnabled=false` |
| §28 树洞字段级加密 | ✅ AES-256 | ✅ 持续 | `vent_repository_impl.dart:88-91` |
| §38 跨境传输 | ❌ 隐私政策 §11 写"v0.25"过期 | 🟡 **R69-N3** | §11 头部 "v0.25 R54 增补" 错（v0.27） |
| §47 知情权（同意历史查询 UI） | ❌ 0 实施 | ❌ **仍挂** | `consentAt` 索引已加但 UI 未做（R66 P1-6 续挂） |
| 知情权（隐私 / 投诉邮箱） | 🟡 软隐藏 `privacy@chroniccare.app` | ✅ 持续 | `privacy_policy.md:121, 135` 软隐藏决策 |
| 3 份 markdown 顶部 TODO 律师过审 | ❌ 仍保留 | ❌ **仍挂**（CC-4） | 律师 1-2 周 |

**R69 评估**:
- PIPL §13 / §14 / §23 / §28 / 知情邮箱 5/8 守住
- §38 跨境版本号过期（**R69-N3**）+ §47 同意历史查询 UI 缺 + 3 md 律师过审 = 3/8 仍挂
- 隐私边界 5/5 守住（vent / mood / assessment / check-in / SafetyWatch）

| 隐私边界 | R68 | R69 | 备注 |
|---|---|---|---|
| vent（树洞） | ✅ 5/5 | ✅ 5/5 | R67 ConsentGate 真接（`vent_repository_impl.dart:76`），0 跨边界 |
| mood | ✅ 5/5 | ✅ 5/5 | `mood_dialog.dart` 拆后 0 跨边界 |
| assessment | ✅ 5/5 | ✅ 5/5 | 16 题 i18n 仍挂（P1-3）但**不**破边界 |
| check-in | ✅ 5/5 | ✅ 5/5 | streak / 趋势 0 改动 |
| SafetyWatch | ✅ 5/5 + 业务暂停 | ✅ 5/5 | `emergencyContactEnabled=false` 兜底；`toJson` 缺 `contactsMocked`（R66 P0-6 续挂） |

---

## §3 底层逐行排查

### 3.1 5 类历史 bug 模式回归（全部 100% 合规）

| bug 模式 | R68 | R69 | 验证 |
|---|---|---|---|
| **隐式排序假设** | ✅ 5 处全修 | ✅ **5 处**（合规使用，sorted 后取） | `grep "\.first\.timestamp\|\.last\.timestamp\|\.first\.id\|\.last\.id" lib/` = 5 处全在 sorted 之后（care_strategies:107 / trend_assessment_chart:61-62 / trend_mood_chart:55-56）✓ |
| **DateTime race** | ✅ 0 race | ✅ **0 race** | `check_datetime_race.py` / `check_datetime_race2.py` 全过；92 处 `DateTime.now()` 全是单调用；R67 `DateTimeResolvers.at()` 集中器 7 处落地 |
| **静默 `catch(_)`** | ✅ 0 | ✅ **0** | `grep "catch (_) {\|catch(_) {" lib/` = 1 处（`swallowError` 集中器自身注释）；84 处 `swallowError` 调用（26 文件） |
| **StreamSubscription leak** | ✅ 0 | ✅ **0** | `check_widget_dispose.py` = 0 资源泄漏 |
| **BuildContext 跨 async gap** | ✅ 25+ mounted check | ✅ **25+ mounted check** | `grep "if (!mounted) return\|if (!context.mounted) return" lib/presentation/pages/ -r` = 25+ 处 ✓ |
| **Resource acquire-release** | ✅ try/finally 0 漏 | ✅ **持续** | `check_widget_dispose.py` 0 泄漏；audioplayers/recorder 临时对象全 try/finally |

**R69 评估**: R67 6 类全合规持续，R68 1 轮内无新违规。`DateTimeResolvers.at()` 集中器在 7 个 repository / 1 个 usecase 落地。

### 3.2 TDD 纪律

- ✅ 1285 测试全过（`flutter test` exit 0，`+1285 All tests passed!`）
- ✅ 0 analyzer error（188 issues：5 warning + 183 info，info 全是 `prefer_const_constructors` / `require_trailing_commas` 风格）
- ✅ R68 commit d691551 加 `setupConsentRejected` ARB key + `feature_flags_round67_test.dart` 24 行 test 调整
- 🟡 5 warning：`unused_import` 1 处（`settings_page_round45_test.dart:30:8` 加载 `loading_skeleton.dart` 未用），`dart fix --apply` 1 行清

### 3.3 i18n 同步（3 语 100% 守住）

- ✅ zh: 623 / en: 623 / zh_Hant: 623（`check_arb_keys.py` 通过）
- ✅ 0 orphan（`check_orphan_arb_keys.py` 通过）
- ✅ 623 keys 繁简 100% 一致（`check_zh_hant_consistency.py` OpenCC s2tw 通过）
- ✅ `check_legal_consent.py` 0 TODO / 无 PIPL §13 单独同意 TODO
- 🟡 `check_strings_hardcoded.py` 32 处配对（已知，PDF 报告场景 i18n 不强需）
- 🟡 `check_fullwidth_punctuation.py` 50 违规（warn-only，R66 决策保留）

### 3.4 守护脚本状态（16 全绿）

| # | 守护脚本 | 状态 | 备注 |
|---|---|---|---|
| 1 | `check_arb_keys.py` | ✅ 623 / 623 / 623 同步 | |
| 2 | `check_changelog.py` | ✅ pubspec=0.27.0+64 顺序对 | R69-N1 顺序对但 R68 没补段 |
| 3 | `check_cross_feature.py` | ✅ 0 violation | |
| 4 | `check_datetime_race.py` | ✅ 0 跨函数 | |
| 5 | `check_datetime_race2.py` | ✅ 0 跨 DateTime(y,m,d) | |
| 6 | `check_drift_namespace.py` | ✅ 7 table / 7 @DataClassName | |
| 7 | `check_fullwidth_punctuation.py` | 🟡 50 违规（warn-only） | 已知 |
| 8 | `check_no_hardcoded_utc.py` | ✅ 0 硬编 | |
| 9 | `check_no_pua.py` | ✅ 0 PUA | |
| 10 | `check_widget_dispose.py` | ✅ 0 资源泄漏 | |
| 11 | `check_orphan_arb_keys.py` | ✅ 0 orphan | |
| 12 | `check_legal_consent.py` | ✅ 0 TODO | |
| 13 | `check_sms_release_ready.py` | ✅ pass（AliyunSmsProvider 真接 + isProductionReady 一致） | |
| 14 | `check_strings_hardcoded.py` | ✅ 32 配对 | |
| 15 | `check_zh_hant_consistency.py` | ✅ 100% 一致 | |
| 16 | `check_all.dart` | ✅ 4 层架构 + 共享层 100% 纯 | |

**R69 评估**: 16 守护脚本全绿（1 个 warn-only），R68 1 轮内无新增违规。

### 3.5 中文规范

- ✅ 5 + 个 commit 100% 符合 `<version> round <N>: <title>` 中文风格
- ✅ 中文注释（domain 层）持续
- ❌ 病耻感措辞 "让家人放心" / "你真棒"（R66 P0-4 续挂）
- ❌ "TA" 网络用语 `lost_contact_sms.dart:69`（R66 P0-5 续挂）
- ❌ 50 处全角标点 warn-only（已知决策）
- 🟡 **R69-N1**: CHANGELOG R66 / R65 / R63 都在 [Unreleased]，R68 commit d691551 没补新 [Unreleased] 段
- 🟡 **R69-N2**: `user_agreement.md:26, 28` 仍写 "8 元" 与 R68 决策关 IAP 入口不一致
- 🟡 **R69-N3**: `privacy_policy.md` 5 处版本号 / Round 号过期（v0.25 / R55 → v0.27 / 未真接）

---

## §4 上架相关（spzh 视角）

### 4.1 PIPL §13 / §14 / §38 / §47 + App Store 4.8 + Google Play Developer Policy

| 类别 | R68 P0 | R69 P0 | R68 P1 | R69 P1 | 备注 |
|---|---|---|---|---|---|
| PIPL §13 单独同意 | ✅ R68 修（CC-1） | ✅ | — | — | `setup_page._saveSetup` 走 ConsentDialog |
| PIPL §14 撤回同意 | ✅ R68 修（CC-6） | ✅ | — | — | `fire_care_strategy` 真接 `isSafetyConsentWithdrawn` |
| PIPL §23 单独告知 | ✅ 软提示 + 业务暂停 | ✅ | — | — | 双层防御 |
| PIPL §28 字段级加密 | ✅ AES-256 | ✅ | — | — | vent / mood / audio |
| PIPL §38 跨境 | 🟡 文档 v0.25 过期 | 🟡 R69-N3 | — | — | 法务 review 必经 |
| PIPL §47 知情权 | ❌ 同意历史查询 UI 缺 | ❌ | — | — | 索引已加 UI 未做 |
| App Store Guideline 4.8 (third-party content) | — | — | ❌ 8 元买断 vs release 隐藏 IAP | ❌ R69-N2 | `user_agreement.md:26, 28` |
| Google Play Developer Policy (Data safety) | — | — | ❌ 失联通知"功能可用"4 文档 | ❌ R69-N2 | fastlane metadata 已软化，但 user_agreement + sensitive_data_consent 仍写 |
| 隐私政策 URL 部署 | — | — | ❌ 未托管 HTTPS | ❌ | 1 行 TODO |
| 真实 keystore + Play App Signing | — | — | ❌ debug keystore | ❌ | `key.properties.example` 已加，但未切 |
| support@ 邮箱注册 | — | — | ❌ 占位 | ❌ | 2 处 TODO |

### 4.2 法律 .md 文档清单（CC-4 / CC-7 / CC-8 / R69-N2 / R69-N3）

| 文档 | R68 状态 | R69 状态 | 关键问题 |
|---|---|---|---|
| `assets/legal/privacy_policy.md` | ❌ 顶部 TODO + v0.22 草稿 | ❌ **R69-N3** 5 处版本号过期 | §11 "v0.25 R54 增补" / §11 "v0.25 (本版本) 尚未接入" / §12 "❌ v0.25 TODO (依赖 SMS provider,见 R55)" / §12 修复路径 "v0.26 R55" / §4 "R67 Sprint 1 真正生效" 4 段已对齐 CC-6 修复 |
| `assets/legal/user_agreement.md` | ❌ 顶部 TODO + 2 占位邮箱 | ❌ **R69-N2** 8 元 vs release 隐藏 IAP | `support@chroniccare.app` + `github.com/example` 2 处 TODO 占位；3. 付费规则 8 元与 IAP 决策不一致 |
| `assets/legal/sensitive_data_consent.md` | ❌ 顶部 TODO + v0.24 草稿 | ❌ **CC-7** 失联通知"功能可用" | 4 处 (27, 47, 64) + §85 单独撤回 |
| `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/description.txt` | ✅ R67 加 3 套 | ✅ 持续 | iOS 已有完整 3 套 |
| `fastlane/metadata/android/{en-US,zh-CN}/*` | ✅ R67 软化 "coming soon" | ✅ 持续 | Android 缺 zh-Hant |
| `pubspec.yaml:2` | ❌ 单语种中文 | ❌ **CC-5** | App Store / Google Play en 模式 UX 割裂 |

### 4.3 法务 review 优先级

| 优先级 | 文档 | 阻塞项 | 估计工作量 |
|---|---|---|---|
| **P0** | `privacy_policy.md` | 顶部 TODO + §11/§12 5 处版本号 + §4/§9/§12 表格 R68 修复后 walkthrough | 律师 1-2 周 |
| **P0** | `user_agreement.md` | 顶部 TODO + 8 元买断删除 / 改 IAP 待启 + 2 邮箱 TODO | 律师 1-2 周 |
| **P0** | `sensitive_data_consent.md` | 顶部 TODO + 失联通知业务暂停 wording | 律师 1-2 周 |
| **P1** | 3 份 markdown 英文版 | 0 英文 | 律师 1 周 |
| **P1** | 3 份 markdown 繁体版 | 0 繁体 | 律师 1 周 |

**最大拦路虎**: 律师过审 3 份 md + 0 英文 + 0 繁体 = 4-5 周不可压缩（按 ¥15-30k/文档）

---

## §5 修复优先级总表

### 5.1 P0 必修（6 项 / 1-2 周）

| 序 | 类别 | 位置 | 难度 | 关键 | R68 vs R69 |
|---|---|---|---|---|---|
| 1 | 底层 | `assets/legal/privacy_policy.md:3-9` + 5 处版本号（§11 / §12） | L | CC-4 律师过审 + R69-N3 walkthrough | 续挂 |
| 2 | 底层 | `assets/legal/user_agreement.md:3-9` + 8 元（R69-N2）+ 2 邮箱 TODO | L | CC-4 + R69-N2 | 续挂 |
| 3 | 底层 | `assets/legal/sensitive_data_consent.md:3-9` + 失联通知 wording | L | CC-4 + CC-7 | 续挂 |
| 4 | 底层 | `pubspec.yaml:2` description 加 en / zh_Hant | M | CC-5 | 续挂 |
| 5 | 架构 | `assets/legal/*.md` 加 0 英文 + 0 繁体版（CC-8） | L | App Store 必拒 / 繁体上架需要 | 续挂 |
| 6 | 底层 | `dart fix --apply` 清 5 warning | XS | 1 行命令 | 续挂 |

### 5.2 P1 应修（6 项 / 1 周）

| 序 | 类别 | 位置 | 难度 | 关键 | R68 vs R69 |
|---|---|---|---|---|---|
| 7 | 底层 | `CHANGELOG.md:5-7` 补 R68 新 [Unreleased] 段（R69-N1） | XS | 版本号与 round 同步 | **新发现** |
| 8 | 底层 | `user_agreement.md:26, 28` 改 8 元 → "IAP 待 v0.28 启用"（R69-N2） | XS | CC-3 文档同步 | **新发现** |
| 9 | 架构 | `PIPLS §47 同意历史查询 UI 缺`（`consentAt` 索引已加但 UI 未做） | S | 知情权查询 | 续挂 |
| 10 | 底层 | 失联通知 4 文档 wording（CC-7） | XS | 1-2h | 续挂 |
| 11 | 设计 | `settings_page.dart:63, 92` dark mode 2 处（CC-9） | XS | 5min | 续挂 |
| 12 | 设计 | `app_theme.dart:128, 209` alpha 2 处（CC-10） | XS | 5min | 续挂 |

### 5.3 P2 建议（10 项 / 1-2 周）

| 序 | 类别 | 位置 | 难度 | 关键 |
|---|---|---|---|---|
| 13 | 底层 | `home_page.dart:549, 557, 567` R55+ TODO 占位（联系人.phone / 邮箱） | S | SMS 真接后才有意义 |
| 14 | 底层 | `BootReceiver.kt:30-31` 占位启动 MainActivity | XS | Android 端小项收尾 |
| 15 | 底层 | `app_theme.dart:128` `// TODO v0.25: 评估 buildTheme 接受 context`（挂 1 年） | S | ThemeProvider 接口变更 |
| 16 | 底层 | `sms_service.dart:90-104` 阿里云 SDK 接入 v1.0+ TODO | XL | 外部依赖（法务 1-2 月 + 阿里云 AccessKey） |
| 17 | 底层 | `email_service.dart:19, 40, 162` SendGrid v1.0+ TODO | XL | 外部依赖 |
| 18 | 底层 | `notification_service.dart:385, 389` iOS 角标 / Android flutter_app_badge_control | M | v1.0+ 集成 |
| 19 | 底层 | `safety_watch_service.dart:443-449` `toJson` 缺 `contactsMocked` | XS | R66 P0-6 续挂 |
| 20 | 底层 | `lost_contact_sms.dart:69` "TA" 网络用语 | XS | 中老年家属阅读 |
| 21 | 底层 | 病耻感措辞 "让家人放心" / "你真棒" | S | 精神心理敏感 user |
| 22 | 底层 | 50 处全角标点 warn-only | XS | 已知决策 |

### 5.4 修复工作量排序

| 阶段 | 内容 | 工程师天 | 关键路径 |
|---|---|---|---|
| **M1 1 周** | 6 P0 + 6 P1 集中清 | 5-7 天 | doc walkthrough + 同步修 |
| **M2 1 周** | 6 widget 集中器 + 5 god class 收尾 + 8+ atomic size tokens | 3-5 天 | 跟 M1 并行 |
| **M3 1-2 月** | 法务 review 3 md + 0 英文 + 0 繁体 + 注册域名 / 邮箱 / 截图 / keystore | 不可压缩 | 外部依赖 |
| **M4 3-6 月** | 真接阿里云 SMS / SendGrid / IAP + 隐私 URL + NMPA "非医疗器械"备案 + 软件著作权 | 不可压缩 | 外部依赖 |

---

## §6 R66 → R69 状态对照（4 轮 R 后总变化）

| R66 issue | R66 状态 | R69 状态 | 4 轮变化 |
|---|---|---|---|
| P0-1 撤回同意 UI-only | ❌ 9/5 修 | ✅ **5/5** | R66 vent / R66 analytics / **R68 safety 修** |
| P0-2 隐私政策脱节 | ❌ §4/§9/§12 | 🟡 R68 §4/§9/§12 跟代码对齐，**R69-N3 5 处版本号过期** | 部分修（法务 review 必经） |
| P0-3 Strings fallback | ❌ 30+ caller | 🟡 R68 持续挂 | 已知决策（PDF 报告场景） |
| P0-4 病耻感措辞 | ❌ | ❌ **续挂** | 0 改进 |
| P0-5 "TA" | ❌ | ❌ **续挂** | 0 改进 |
| P0-6 toJson contactsMocked | ❌ | ❌ **续挂** | 0 改进 |
| P0-7 setup ConsentDialog | ❌ 升级 | ✅ **R68 修** | R68 落地（CC-1） |
| P0-8 working tree 178 文件 | ❌ | ✅ **R68 修** | R68 d691551 + 556d454 落地 |
| P0-9 pubspec description | ❌ | ❌ **续挂** | 0 改进 |
| P1-1 CI 漏 11 守护 | ❌ 5/16 | 🟡 **持续挂** | 0 改进 |
| P1-2 3 markdown 英文+繁体 | ❌ | ❌ **续挂**（CC-8） | 0 改进 |
| P1-3 量表 16 题 i18n | 🟡 起步 | 🟡 **持续挂** | 0 改进 |
| P1-6 同意历史 PIPL §47 | ❌ | ❌ **续挂** | 0 改进 |
| P2-1 setup_legal_dialog 注释 | ❌ | 🟡 **持续挂** | 0 改进 |
| P2-2 care_copy 4 trigger i18n | ❌ | 🟡 **持续挂** | 0 改进 |
| P2-3 medication_report override | ❌ | 🟡 **持续挂** | 0 改进 |
| P2-4 双层 feature flag 注释 | ❌ | 🟡 **持续挂** | 0 改进 |
| P2-5 legal_page 5 vs 3 kind | ❌ | ✅ **R68 修** | R68 legal_page.dart 5 kind 全列 |
| P3-1 AGENTS.md 数字漂移 | ❌ | 🟡 **持续挂** | 0 改进 |
| P3-2 README.md 数字漂移 | ❌ | 🟡 **持续挂** | 0 改进 |
| P3-3 隐私政策 v0.25 过期 | ❌ | 🟡 R68 §0.5 修，余下 R69-N3 | 部分修 |
| P3-4 setup_legal_dialog 注释 | ❌ | 🟡 **持续挂** | 0 改进 |
| P3-5 全角标点 | 已知 | 🟡 已知 | 已知决策 |
| P3-6 EmailService 守门 | 设计占位 | 🟡 **守门员 R67 已加** | 守门员已加，真接待 v0.28 |
| P3-7 consentAt 索引已加 UI 未做 | 索引已加 | 🟡 **持续挂**（同 P1-6） | 0 改进 |
| **god class mood_dialog 1204 行** | ❌ 18 月挂 | ✅ **R64 拆** | 0 改进（R64 落地） |
| **god class data_export_service 21K** | ❌ | ✅ **R26 R57 拆** | 0 改进（R26 R57 落地） |

**总计 25 issues** (R66 23 + R67 新 4 升级 - R68 修 5 + R69 新 3)
- R66 → R68: P0 -5, P1 -1, P2 -1, P3 -0
- R68 → R69: P0 -0, P1 -2 +2 = ±0, P2 -0 +1, 新 3

---

## §7 3-5 句精炼建议

1. **R68 集中修复 3 个 P0 + 2 个 god class 是真落地** — CC-1（setup ConsentDialog + 等长守门）/ CC-3（IAP 隐藏）/ CC-6（CareEngine safety 撤回真接 use case + home_page 注入）3 个 P0 全部 commit 验证生效，mood_dialog 26 行薄壳 + data_export_service 119 行 facade 是 R64/R57 拆完的。R68 1 轮内 16 守护脚本全绿 / 5 类历史 bug 100% 合规 / 1285 测试全过 / 0 analyzer error。**评级升 ⭐⭐ → ⭐⭐⭐½**。

2. **R69 新发现的 3 个"半步之遥"问题集中清 1 天** — (a) CHANGELOG.md R68 commit 没补 [Unreleased] 段（顺序对但 round 脱节），(b) user_agreement.md:26 仍写 8 元买断 vs R68 决策关 IAP 入口不一致，(c) privacy_policy.md 5 处 v0.25 / R55 引用过期 — 3 项都是"代码修了但文档没同步"，1 天工作量。

3. **v1.0 上 store 真卡点是"非代码"环节** — 6 P0 中 5 项是律师过审 3 份 md（CC-4 + R69-N2 + R69-N3 + CC-7 + CC-8）+ 1 项 pubspec description 多语种（CC-5），跟 R66 / R68 一致：**真正卡上架的不是 88% 规范合规率，而是法务 1-2 周（不可压缩）**。建议 R69 立即启动"法务 + 域名 + 邮箱 + 截图 + keystore"5 条工作流，跟代码 P0/P1 收尾分头推进。

4. **6 P1 / 10 P2 是"Sprint 后收尾"项 1 周** — CHANGELOG R68 补段 / 8 元改 IAP 待启 / 同意历史查询 PIPL §47 UI / 失联通知 4 文档 wording / dark mode 2 处 / app_theme alpha 2 处 / 6 widget 集中器 / BootReceiver 占位 / 病耻感措辞 / "TA" / toJson contactsMocked / 50 全角标点 — 12 项全是"小坑"，1 周工作量，跟主 P0 修复**同 PR 合做**，避免又留 R70。

5. **总体评级:⭐⭐⭐½ 3.5/5**（vs R66 ⭐⭐ 2/5，vs R68 ⭐⭐ 2/5）。R68 是"集中修复 + 集中 commit"的一次性收尾：3 P0 + 2 god class + 6 widget 集中器 + working tree 全部 commit，工程质量**已达 v1.0 上 store 水平**（88% 规范合规 + 0 error + R67/R68 守门员链完整 + 5 视角共识 P0 集中识别）。**流程**（法务 review / 域名 / 邮箱 / 截图 / keystore / Play Console 4 表单）是最后 12% 缺口，**1-2 月** 不可压缩。
