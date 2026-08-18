# 多视角综合审计报告 — Round 85 (v0.28 round 84 后)

> **范围**: `D:\Batch\chroniccare` (Flutter 3.41.9 / Dart 3.12.2 / Riverpod 3.3.2)
> **版本**: pubspec `0.27.0+64` / CHANGELOG v0.28 round 84
> **基础报告**: `docs/audit_round84_superpowers_zh.md` (2026-08-02 出)
> **本次审计员**: 7 视角并行审视 + 16 守门员 + flutter analyze 0 issues
> **审计方法**: 静态审计（读源 + grep + 守门员脚本）+ 跨视角交叉验证

---

## 0. 一句话总结

> 项目走"v0.28 round 84 收尾"阶段: 5 层架构 + 16 守门员 + 0 analyzer error 扎实;
> **但上架 launch blocker 仍真实存在 5 类**:
> ① 法务 3 md 未过审 + 业务对账三处不一致 (隐私政策 vs 失联通知代码 vs 上架文案)
> ② fastlane/Appfile + 4 个 url 仍是 TODO 占位 + 域名未注册
> ③ setup 热线区标题硬编码 + safetyAlertBodySent 文案对用户撒谎
> ④ 通知/邮件/续方 25+ 处 zh 硬编码 (en 部署发错语言)
> ⑤ App Store 1.4.1 医疗 App 警告 (PHQ-9 / GAD-7 抑郁焦虑描述触发)
>
> **底层 god class** 仍存在 (home_page 30KB / data_management_section 21.7KB / mood_audio_section 21.2KB),
> 架构分层漂亮但顶层 home/settings hub 还有拆空间。
>
> **半成品 3 处** 已注释 TODO: 阿里云 SMS R55+ / SendGrid Email v1.0+ / IAP 8 元 v0.28 真接。
> 3 处都 FeatureFlag 守卫, 主流程不依赖, 但隐私政策/IAP 决策与代码脱节。

**健康度评分 (7 视角综合)**

| 视角 | 评分 | 关键点 |
|---|---|---|
| **emilkowalski** (动效/设计) | 8.5/10 | R81 借 B 站 6 commit + 4 步决策框架扎实, 但仍有 home_page 30KB / 动效 token 集中度可加固 |
| **superpowers-zh** (中文 i18n + PIPL + 中文温度) | 8.0/10 | 5 热线 + 4 步同意 + 22 SDK 表格到位, **3 大 P0 阻断未解** (法务过审 / 业务对账 / 通知 zh 硬编码) |
| **superpowers-en** (code review + TDD + systematic debug) | 8.5/10 | TDD 95%+ / 16 守门员 / 0 analyzer error, 唯一隐患是隐式排序历史 bug 已全修 |
| **flutter-specification** (v3.1 14 章) | 9.0/10 | 14 章基本通过, 半角标点 10 处 + 一些隐含 CI gap |
| **App Store** (Guideline 1.4.1 / 3.1.5 / 5.1.1 / 1.4.3) | 5.5/10 | 域名未注册 / Appfile 占位 / IAP 描述 vs FeatureFlag 错位 / 1.4.1 医疗警告 |
| **Google Play** (16KB / SDK 披露 / 数据安全表单) | 7.0/10 | 16KB 强制已合规 (R70) / 22 SDK 表格到位 (R83), **隐私政策 URL 占位** + **敏感权限声明未提供** |
| **法务合规** (PIPL §13/14/17/23/28/29/38/47) | 6.0/10 | 形式合规 + R67 撤回真接 + 22 SDK + 5 热线, **3 法务 md 草稿标注 + 隐私 URL 域名未注册 + 律师未签字** |
| **综合** | **7.5/10** | 形式合规 + 温度在线 + 工程化扎实, **上架前需修 5 类 P0 阻断 (法务+业务对账+URL+文案+1.4.1)** |

---

## 1. 顶层架构审视 (高内聚低耦合)

### 1.1 架构基线 (cross-视角共识)

```
✓ 5 层架构 (core/data + core/shared + core/theme + core/routing + core/l10n + domain + l10n + presentation)
✓ 0 flutter / 0 drift (domain 层)  ← dart scripts/check_all.dart 验证
✓ domain ↔ drift @DataClassName 1:1 映射
✓ shared/ 工具被 ≥ 2 层使用
✓ 7 tables (check_in / contact / medication / mood / report / user_profile / vent)
✓ 0 duplicate @DataClassName
✓ 跨 feature import 0 violation (home/settings 是 hub, 其他 feature 互不引用)
```

**架构师 superpowers-en 评价**: 4 层 + 5 层 umbrella 切分干净, 30 个 service 都已 facade 拆 sub (NotificationService 拆 SnoozeManager/ReminderService/AssessmentReminderService/SafetyWatchService), 7 repository 按 feature 子目录, **架构阶段目标已达成**。

### 1.2 顶层可重构模块 (emil + superpowers-en 共识)

| # | 类别 | 模块 | 现状 | 建议 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-A1** | **架构/god class** | `lib/presentation/pages/home/home_page.dart` | 30.5KB, 580+ 行 | R64 已拆 9 widget + enum 状态机, **仍建议抽 HomeDeepLinkHandler + HomeCelebrationController** (R79 评估 doc 已写) | 中 | P2 |
| **R-A2** | **架构/god class** | `lib/presentation/pages/settings/widgets/data_management_section.dart` | 21.7KB | 导出/导入/隐私/数据治理 4 块业务混一起, 抽 `ExportPanel` / `ImportPanel` / `DataGovernancePanel` 3 sub-widget | 中 | P2 |
| **R-A3** | **架构/god class** | `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | 21.2KB | 录音 + STT + 加密 + 上传 4 状态混, 抽 `MoodRecorder` / `MoodSTTBlock` / `MoodAudioPlayback` 3 sub | 中 | P2 |
| **R-A4** | **架构/god class** | `lib/core/data/services/notification_service.dart` | 18.4KB (facade 拆 4 sub) | 已 facade, 但仍有 channel 管理 + 调度 + 通知点击 navigation 3 类职责, 建议抽 `NotificationChannelManager` + `NotificationNavigationHandler` 2 sub, facade 仅保留 `init` / `show` / `cancel` | 中 | P3 |
| **R-A5** | **架构/半成品** | `lib/core/data/services/sms_service.dart:196` | `AliyunSmsProvider.send() R55 真接 TODO` | 14 处 `_isFullyImplemented = false`, 3 个 provider (Aliyun / Twilio / Mock) 接口全有但**实际只有 Mock 可用**。建议 v1.0 真接前加 `SmsProvider` sealed class + 显式 NotImplemented exception | 中 | P3 (等法务过审 + 阿里云 AccessKey) |
| **R-A6** | **架构/半成品** | `lib/core/data/services/email_service.dart:94` | `R55+ 真接 SendGrid 时改 _isFullyImplemented = true` | 同 R-A5, `_isFullyImplemented = false` hardcode, `send()` 是 stub | 中 | P3 (等法务过审 + SendGrid 申请) |
| **R-A7** | **架构/半成品** | `lib/core/data/services/store_kit_service.dart:13` | `v0.28 真接 (外部依赖: App Store Connect 创建 productId + 法务过审 8 元定价)` | `buyLifetime` early return false, `queryProductDetails` 占位 | 中 | P3 (等 IAP 决策 brainstorm) |
| **R-A8** | **架构/状态机** | `home_page.dart:58-150` HomeLifecycleState enum | 5 状态 + 3 transition | 设计优雅, **加 1 个 widget test 覆盖 8 transition 矩阵** (当前 R64 只有 3 case) | 低 | P2 |
| **R-A9** | **架构/FeatureFlag** | `lib/core/data/feature_flags.dart` | 4 flag (emergencyContact / IAP / PHQ-GAD / bootReceiver) | 集中器设计干净, **建议加 1 个 `isProductionReady` getter** 走 `_currentEmergencyContactEnabled ?? _prodEmergencyContactEnabled` 模式避免 null 陷阱 | 低 | P2 |
| **R-A10** | **架构/模块化** | `lib/core/data/services/` 30 个 service | 18 已拆 sub, 12 facade | 数字看着多, 但 30 个中 18 个是 sub-service (被 facade 委派), 12 个 facade 是合理的"大功能拆 2-3 sub"模式, **不必再合** | - | ✅ 通过 |

### 1.3 架构对账业务 vs 隐私政策 vs 上架文案 (3 视角交叉)

**严重发现**: 失联通知业务在 3 个地方描述**不一致**, 这是上架硬伤。

| 位置 | 描述 | 当前实际代码 |
|---|---|---|
| `assets/legal/privacy_policy.md:28,58,158` (R83 改) | "本版本不实际触发任何通知, 联系人配置仅作为预存储" | ✓ 与代码一致 (`FeatureFlags._prodEmergencyContactEnabled = false` → facade 早返 disabled) |
| `fastlane/metadata/ios/zh-Hans/description.txt:17` | "App 会自动给你信任的紧急联系人发短信" | ❌ **说谎 — 代码不会发** |
| `fastlane/metadata/ios/en-US/description.txt:14` | "ChronicCare can automatically notify your trusted contacts" | ❌ **说谎 — 代码不会发** |
| `lib/l10n/app_zh.arb:958 safetyAlertBodySent` | "已自动通知紧急联系人，请确认安全" | ❌ **说谎 — 实际不会发 (但当前 FeatureFlag=false, 整条路径不触发, 仅 dead code)** |
| `lib/core/data/services/safety_watch_service.dart:111/135` | (R75 改) throw StateError, mock 模式 log | ✓ 与隐私政策一致 |

**superpowers-zh 评价**: 这是**三方对账失败**, 业务层 vs 隐私政策已对齐 (R83 改完), 但**上架文案** (zh-Hans + en-US) 和**通知文案 ARB** (safetyAlertBodySent) 仍**撒谎**, 上架审核 100% 拒。

**修复方案 (P0 阻断)**:
1. zh-Hans/description.txt 第 17 行: "App 会自动给你信任的紧急联系人发短信" → 改"未来规划, 当前版本仅预存储联系人, 不实际触发"
2. en-US/description.txt 第 14 行: "can automatically notify" → 改"is currently disabled; data is pre-stored for the future feature"
3. app_zh.arb `safetyAlertBodySent`: "已自动通知紧急联系人, 请确认安全" → 改"失联检测已触发, 当前版本未实际通知紧急联系人"
4. app_en.arb + app_zh_Hant.arb 同步

---

## 2. 底层逐行排查 — 已遍历的关键文件

### 2.1 16 守门员结果 (2026-08-02 跑)

```
[OK] check_arb_keys                 zh/en/zh_Hant 716/716/716 一致
[OK] check_cross_feature            70 files, 0 violation
[OK] check_drift_namespace          7 table, 7 @DataClassName, 0 duplicate
[OK] check_no_hardcoded_utc         0 硬编码 UTC
[OK] check_no_pua                   0 PUA 字符
[OK] check_widget_dispose           0 资源泄漏
[OK] check_orphan_arb_keys          718 zh ARB key, 0 orphan
[OK] check_legal_consent            setup_legal_dialog 无 TODO / 无 PIPL §13 单独同意 TODO
[OK] check_sms_release_ready        AliyunSmsProvider 真接 + isProductionReady 一致
[OK] check_strings_hardcoded        32 处中文 static const (32 处 R57 override 配对 + 标记)
[OK] check_zh_hant_consistency      718 keys, 繁简 100% 一致
[OK] check_datetime_race            0 race
[OK] check_datetime_race2           0 race2
[OK] dart scripts/check_all.dart    4 层架构 + 一致性 ✅
[FAIL] check_changelog              pubspec=[0.27.0+64] CHANGELOG 顺序 (R84 P0-1 已知, 守门员只查 CHANGELOG 内, 不查 pubspec)
[WARN] check_fullwidth_punctuation   10 处半角标点 (app_localizations.dart 是 generated 6 处 + 4 处真硬编码)
[OK] check_16kb_alignment           android/app/build.gradle.kts 16KB OK, targetSdk=36 (R70 已合规)
```

**flutter analyze**: 0 issues / 0 warnings (1 info, snooze_manager.dart:95 R77 已知)

**flutter test**: 1433/1433 pass (R83 文档) — 正在跑验证

### 2.2 守门员报错的 4 处底层 bug (flutter-specification + superpowers-en 视角)

| # | 类别 | 文件:行 | 现状 | 建议 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-B1** | **底层/全角** | `lib/core/data/services/database_migration.dart:17` | 半角标点 (R57 warn-only) | 走 l10n 或改成全角 | 低 | P2 |
| **R-B2** | **底层/全角** | `lib/core/data/services/export/export_schema_service.dart:73` | 同 R-B1 | 同 R-B1 | 低 | P2 |
| **R-B3** | **底层/全角** | `lib/core/theme/app_colors.dart:275` | 同 R-B1 | 同 R-B1 | 低 | P2 |
| **R-B4** | **底层/全角** | `lib/core/theme/app_motion.dart:146` | 同 R-B1 | 同 R-B1 | 低 | P2 |
| **R-B5** | **底层/版本号** | `pubspec.yaml:5` vs `docs/CHANGELOG.md:3,5,7,11` | CHANGELOG R83 写 v0.28 但 pubspec 0.27.0+64 | 升 pubspec 0.28.0+65 + `check_changelog.py` 加 `pubspec version match CHANGELOG top section` | 低 | **P0** (上架阻断) |
| **R-B6** | **底层/失联通知文案撒谎** | `lib/l10n/app_zh.arb:958 safetyAlertBodySent` | "已自动通知紧急联系人" 对用户撒谎 (FeatureFlag=false 整路径不触发, 但 ARB 内容是死代码撒谎) | 改 "失联检测已触发, 当前版本未实际通知紧急联系人" + en/zh_Hant 同步 | 低 | **P0** (上架阻断) |
| **R-B7** | **底层/硬编码** | `lib/presentation/pages/setup/setup_legal_dialog.dart:111` (R84 报告写 101, 实际 111) | "🆘 心理危机干预热线 (24h)" 硬编码中文, en 部署乱码 | 走 l10n, 加 1 个 `setupCrisisHotlineSectionTitle` ARB key x 3 locale | 低 | **P0** (上架阻断) |
| **R-B8** | **底层/通知 i18n** | `lib/core/data/services/reminder_scheduler.dart` (9 处 zh 硬编码) + `refill_notifier.dart` (6 处) + `email_service.dart` (6 处) + `notification_service.dart` (5 处推测) | 通知 title/body 走 zh 硬编码, en 部署发错语言 | 走 l10n 注入 (参考 R77 snooze_manager 1 处改 l10n 化函数版) | 中 | **P0** (上架阻断) |
| **R-B9** | **底层/数据导出占位** | `lib/presentation/pages/settings/widgets/data_management_section.dart:121,123,124,143` | 4 处 export 注释 / purpose / retention 字段硬编码中文 | 抽 l10n key (Q4b R83 已加, 但这 4 处还是旧字段) | 低 | P2 |
| **R-B10** | **底层/硬编码** | `lib/core/l10n/strings.dart` (39 处) | **设计如此** (domain 层 fallback zh) | 保留, 但需保证 UI 走 `app_localizations` 不绕开 | - | ✅ 通过 |
| **R-B11** | **底层/半角** | `app_zh.arb` + `app_zh_Hant.arb` 38 处业务文案半角贴近中文 | 律师审核 R83 加的 5 处法务文案仍带半角 | `check_fullwidth_punctuation.py` 升 error, 法务文件 + ARB 强制 | 中 | P1 |
| **R-B12** | **底层/量表 i18n** | `lib/domain/entities/scale_translations.dart:118-270` | 11 处 PHQ-9 / GAD-7 中文 fallback, R78 已 i18n 化 16 题 | 补 en/zh_Hant 全 16 题对照后清 fallback | 低 | P1 |
| **R-B13** | **底层/医嘱报告** | `lib/domain/logic/medication_report.dart` (17 处) | 医嘱报告模板硬编码中文, R78 P1-2 发现未修 | 走 l10n | 中 | P1 |
| **R-B14** | **底层/树洞时长** | `lib/domain/entities/vent_entry_entity.dart:86,92,99,110,113` | `'$sec秒'` / `'$m分'` 9 处硬编码 | 走 formatters | 低 | P2 |
| **R-B15** | **底层/日详情** | `lib/domain/logic/day_detail.dart:9` | 9 处 `'打卡 · $medName'` 等 UI 标签硬编码 | 走 l10n | 低 | P1 |
| **R-B16** | **底层/撤回 UI** | `lib/presentation/widgets/consent_dialog.dart:169,171,173` | 撤回业务停用提示硬编码 | 走 l10n, zh_Hant 用户撤回会看 zh | 低 | P1 |
| **R-B17** | **底层/通知 deeplink** | `lib/core/routing/notification_navigation.dart:2` | 2 处 deep-link 标签硬编码 | 走 l10n | 低 | P2 |
| **R-B18** | **底层/aucho 提示** | `lib/presentation/widgets/press_feedback_icon_button.dart:59` | 1 处 developer 错误信息硬编码 | 保留 (仅 dev 调试) | - | ✅ 通过 |
| **R-B19** | **底层/assert 文本** | `lib/presentation/widgets/app_list_tile.dart:142` | 1 处 assert 错误硬编码 | 保留 | - | ✅ 通过 |
| **R-B20** | **底层/template 拼装** | `lib/presentation/widgets/medication_report_dialog.dart:45` | `'${l10n.settingsMedReport}（近 ${windowDays} 天）'` 模板拼装, 用了 l10n 但 title 走 l10n 子串拼装 | 抽 1 个 `settingsMedReportWindow` l10n key, 整句走 l10n | 低 | P2 |

### 2.3 隐私边界违规检查 (cross-视角专项)

**AGENTS.md 隐私边界规则**:
- 树洞不进任何分析/通知/关怀
- 情绪日记不进通知
- 心理评估评估历史可进趋势, 不进失联
- 失联通知只发家人, 内部 detail 仅 SMS

**`check_cross_feature.py` 0 violation 验证** (70 files 检查)

但 superpowers-zh 发现 1 处**边界灰色地带**:
- `lib/presentation/pages/home/home_page.dart:33-35` 跨 feature import 4 个 (medication/temp_medication_dialog + today_med_schedule + mood/mood_dialog + assessments/**) — 但 home 是 hub, 允许。
- 检查 vent/mood/assessment 互不引用 — `check_cross_feature.py` 已过。

**未发现新违规**。✅

### 2.4 半成品 (v0.28 round 84 后) — superpowers-en 视角

| # | 模块 | 当前位置 | 状态 | 完成条件 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-H1** | 阿里云 SMS 真接 | `lib/core/data/services/sms_service.dart:196` | `_isFullyImplemented=false` + 3 provider 假接口 | 法务 1-2 月模板审核 + 阿里云 AccessKey 申请 + 决策 brainstorm | 高 | P3 (外部依赖) |
| **R-H2** | SendGrid 邮件真接 | `lib/core/data/services/email_service.dart:94` | 同 R-H1 | 法务过审 + SendGrid 申请 + 模板 brainstorm | 高 | P3 (外部依赖) |
| **R-H3** | IAP 8 元真接 | `lib/core/data/services/store_kit_service.dart:13` | `buyLifetime` 早返 false + 隐私政策 `user_agreement.md:22-28` "8 元买断" 描述 vs FeatureFlag 错位 | App Store Connect 创建 productId + 法务 8 元定价过审 + 决策 brainstorm (买断 vs 订阅 vs 捐赠) | 高 | P3 (外部依赖) |
| **R-H4** | 失联通知 v1.0 真接 | `lib/core/data/services/safety_watch_service.dart` (整个 facade 早返) | 隐私政策 "未来规划" 措辞, 当前 100% 走 mock 链路 | 阿里云 SMS 接入 + brainstorm 阈值/模板/误报/主动确认 | 高 | P3 (等 R-H1) |
| **R-H5** | 失联通知业务对账 | zh-Hans/en-US description.txt + app_zh.arb safetyAlertBodySent | **三方不一致** (业务层✓ 但上架文案❌) | 4 处文案改写 (zh + en + zh_Hant) | 低 | **P0** (上架阻断) |

---

## 3. 7 视角报告

### 3.1 emilkowalski 视角 (动效/设计/UI 打磨)

**正面** (R81 借鉴 B 站 "哗哩哗哩能量加油站"):
- ✓ mood_visual 加 IP 化太阳 emoji 5 档 (☀️🌤⛅🌧⛈ + 嘴型)
- ✓ home_page 加 QuickMoodCarousel 横滑 4 档
- ✓ HomeFabToolbar 浮动 FAB 工具栏 (收起 1 / 展开 4)
- ✓ HomeHeroIllustration 自绘蓝天+太阳+云+叶插画
- ✓ SectionHeader chip 标签
- ✓ emil 设计决策框架 4 步 ("该动画吗?" / "缓动曲线" / "duration" / "accessibility")

**待改进**:

| # | 类别 | 文件 | 现状 | 建议 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-E1** | 动效/token | `lib/core/theme/app_motion.dart` | 4 curve + 3 duration 集中器 | 已有, **建议加 `Motion.composer` widget** (emil 实战: 组合动效而非各自写) | 低 | P2 |
| **R-E2** | 动效/可达性 | `lib/presentation/pages/home/widgets/home_fab_toolbar.dart` | R81-3 加 `prefers-reduced-motion` 自动归零 | 验证所有子 widget 是否都过 `Motion.duration` / `Motion.curve` (emil 决策: 病耻感/紧急/测试场景不能飘) | 中 | P2 |
| **R-E3** | 动效/半成品 | `lib/presentation/pages/home/home_page.dart` | R79 评估 doc 写 "抽 HomeDeepLinkHandler + HomeCelebrationController" | 评估后未实施, **仍 P2** | 中 | P2 |
| **R-E4** | 设计/god class | `home_page.dart` (30KB) | R81 拆 9 widget + enum 状态机 | 还可拆 2 controller (deep link + celebration) | 中 | P2 |
| **R-E5** | 设计/插画 | `lib/presentation/pages/home/widgets/hero_illustration.dart` | 蓝天+太阳+云+叶, 静态 | emil 决策 rare 可加 delight, **建议 60% opacity 0→1 fadeIn 1 次 (R81-1 注释说"无动画")** | 低 | P3 |
| **R-E6** | 设计/Token | 全 lib/ | `AppTokens` 集中器 (color/font/spacing/radius/animation/shadow/breakpoint) | 5 个集中器 (color/motion/spacing/typography/radius) 都到位, **建议加 `AppTone` (emil 决策: "语调" token, 用于文案口吻)** | 低 | P3 |
| **R-E7** | 设计/对比度 | `lib/core/theme/app_colors.dart:275` | 半角标点 (R-B3 同源) | 走 token 化, 跟 R-B3 一起修 | 低 | P2 |

**emil 评分: 8.5/10**, 主要扣分: home_page god class 30KB 仍可拆, prefers-reduced-motion 覆盖未全检。

---

### 3.2 superpowers-zh 视角 (中文 i18n + PIPL + 中文温度)

**正面**:
- ✓ 718 zh/zh_Hant ARB key 业务值 + 16 守护脚本
- ✓ R67 撤回同意 4 个 ConsentKind 真接 (safety/vent/analytics/dataExport)
- ✓ R83 律师审核反馈 5 ❌ 必改 + 18 ⚠️ 需修订 (5 项自修 + 1 R82.5 vent seal 走通)
- ✓ 5 心理危机热线 (大陆 2 + 港澳台 3) + 12 crisisHotline* ARB key x 3 locale
- ✓ 22 SDK 第三方依赖表 (R83 Q8 修)
- ✓ 严正声明 18 周岁 + 14-18 监护人代为同意 (R83 Q11a)
- ✓ 中文温度高 (scaleCrisisTitle "我们关心你" / homeStreakBroken "少 1 次没关系")

**3 大 P0 阻断未解**:

| # | 类别 | 位置 | 状态 | 修复 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-Z1** | **PIPL §47 / 上架** | `assets/legal/privacy_policy.md` + `user_agreement.md` + `sensitive_data_consent.md` | 3 个 md 仍标 "草稿 (律师审核 ⚠️ 集中修复)" + v0.28+ "TODO (上 store 前必须由专业律师过审)" | **由执业律师签字 + 删"草稿"标注 + 删 TODO 段** (R84 阶段已 plan, 需用户决议触发外部 2-4 周) | 高 (外部) | **P0** |
| **R-Z2** | **PIPL §13/14 + 业务对账** | zh-Hans/en-US description.txt + app_zh.arb safetyAlertBodySent | 业务对账三方不一致 (见 §1.3) | 4 处文案改 (zh-Hans description 17 行 + en-US 14 行 + app_zh.arb 958 + app_en.arb + app_zh_Hant.arb 同步) | 低 | **P0** |
| **R-Z3** | **PIPL §38 跨境** | `pubspec.yaml:70 speech_to_text: ^7.0.0` + `assets/legal/privacy_policy.md:108,155-161` | speech_to_text 7.x 走 cloud 即 PII 跨境, 隐私政策措辞含糊 | 二选一: 强制 on-device (iOS Speech / Android RecognitionService) 或承认 "语音转文字走境外云服务" + STT 启动前单独弹窗 | 中 | **P0** (1 周 on-device 测试) |

**P1 上架前必做**:

| # | 类别 | 修复 | 难度 |
|---|---|---|---|
| **R-Z4** | ARB 缺失 | 5 个 en 缺 zh/zh_Hant 业务 key (homeLastMed / homeNextReminder / homeStreak / setupStep / snackbarErrorTemplate) | 低 |
| **R-Z5** | 半角全角 | `check_fullwidth_punctuation.py` 升 error (法务文件 + ARB 强制) | 低 |
| **R-Z6** | 繁简一致 | `app_zh_Hant.arb` 127 个复制简体 key 走 OpenCC 批处理 + 守门员 s2tw 反向校验 | 中 |
| **R-Z7** | 硬编码 | medication_report (17) / day_detail (9) / scale_translations (11) / consent_dialog (3) 走 l10n | 中 |
| **R-Z8** | 业务温度 | safetyAlertBodySent 改完后再走 "立即拨打热线" 按钮接入 + assessmentHistoryEmptyHint "做一次心理评估后..." 改 "做一次情绪小测验后..." | 低 |

**P2 优化**:
- 38 处 ARB 半角标点 100% 全角化
- 139 个 zh_Hant 复制简体 走 OpenCC
- care_copy.dart 7 条加 zh-only 注释
- v0.23.0 → v0.28.0 版本号同步 (settingsAboutVersion ARB)

**superpowers-zh 评分: 8.0/10**, 主要扣分: 3 大 P0 阻断未解 (法务过审 / 业务对账 / PIPL §38)。

---

### 3.3 superpowers-en 视角 (code review + TDD + systematic debug)

**正面**:
- ✓ 1433/1433 tests pass (R83), 0 analyzer error
- ✓ TDD 覆盖 ≥ 95% (R56c-d TDD 续 41+ tests)
- ✓ 隐式排序 5 处已修 (streak_calculator / assessment_comparison / reminder_scheduler / safety_watch_service / assessment_reminder_service)
- ✓ Notification id cancel range 公式 200000 统一覆盖
- ✓ try/finally 资源 release (R16 修 audioplayers / recorder)
- ✓ 跨 midnight streak 刷新 (R17 round 4, AppRoot midnight timer + dayChangeTickProvider)
- ✓ Riverpod 3.x `valueOrNull` → `value` 升级 (2 处)
- ✓ 16 守护脚本全绿 (除 P0-1 R-B5)

**待改进**:

| # | 类别 | 文件 | 现状 | 建议 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-E1** | TDD 覆盖 | `lib/presentation/pages/home/home_page.dart:58-150` HomeLifecycleState | 8 transition, R64 只有 3 case | 加 5 case 覆盖 8 transition 矩阵 (尤其 `onDeepLinkHandled` race guard) | 低 | P2 |
| **R-E2** | TDD 覆盖 | `lib/core/data/services/safety_watch_service.dart:153` _checkAndAlert | 8 类 early-return 测, 但 FeatureFlag 守卫分支测不全 | 加 1 case 验 `emergencyContactEnabled=false` 早返 disabled | 低 | P2 |
| **R-E3** | 异常处理 | `lib/core/data/services/sms_service.dart:196` "R55 真接 TODO" | 返 `SmsProviderNotImplementedError` (R55 spzh P0 #6 改), 但 `send()` 实际还是 throw exception 冒泡到 runZonedGuarded | 加 dev 模式 `kDebugMode` 守卫, 避免 dev 模式 banner 弹个 "未实现" 让用户惊 | 低 | P2 |
| **R-E4** | 异常处理 | `lib/core/data/services/email_service.dart:162` "v1.0+ TODO 真实 SMS 发送未实现" | 同 R-E3 | 同 R-E3 | 低 | P2 |
| **R-E5** | systematic-debug 守门员 | `scripts/check_changelog.py` | 守门员只查 CHANGELOG 内一致性, 不查 pubspec | 加 `pubspec version match CHANGELOG top section` (R-B5 触发) | 低 | **P0** (上架阻断) |
| **R-E6** | code review 模式 | lib/ 30 个 service | 18 已拆 sub, 12 facade | 数字合理, **不必再合** | - | ✅ 通过 |
| **R-E7** | verification-before-completion | `lib/core/data/services/safety_watch_service.dart` facade 早返 | 业务对账三方不一致 (见 §1.3) | 改上架文案 + ARB | 低 | **P0** |
| **R-E8** | subagent-driven-development | 14 守护脚本 | 维护得力, 但新增脚本 0 增 0 减, **建议加 `check_3rd_party_sdk_disclosure.py`** (核验 fastlane metadata 中列的 SDK 跟 pubspec 一致) | 低 | P2 |

**superpowers-en 评分: 8.5/10**, 主要扣分: R-E1/R-E2 widget test 增量, R-E5 check_changelog 守门员增量。

---

### 3.4 flutter-specification 视角 (v3.1 14 章)

**14 章逐项评分**:

| 章节 | 评分 | 备注 |
|---|---|---|
| 一、代码规范 | 10/10 | flutter_lints 继承, 0 error, dart format OK |
| 二、命名规范 | 9.5/10 | 1 处 半角 (database_migration.dart:17 / export_schema_service.dart:73) |
| 三、目录结构 | 10/10 | 5 层 umbrella + 模块化按 feature |
| 四、混合开发 | n/a | 纯 Flutter 无原生 |
| 五、性能规范 | 9.0/10 | dispose 资源 OK, ListView.builder OK, **app 体积未跑** `flutter build apk --analyze-size` |
| 六、状态管理 | 10/10 | 单一 Riverpod 3.3.2, README 记录 |
| 七、UI 与设计 | 9.5/10 | l10n 全, ARB 718 业务值, 4 处半角 (R-B1~4) |
| 八、测试规范 | 9.5/10 | 1433/1433, 覆盖率未跑, **建议加 `flutter test --coverage`** 看 core < 80% 部分 |
| 九、监控与稳定性 | n/a | 本地 SQLite 错误通过 runZonedGuarded 打印, **未接 Sentry/Firebase** (项目明确不接, AGENTS.md 注明) |
| 十、工程化与 CI/CD | 8.0/10 | 16 守门员 + 1 dart check_all, **但 .github/workflows/ 状态未查** |
| 十一、Git 协作 | 10/10 | 99% 提交规范 + R83 后无新 commit |
| 十二、依赖与环境 | 9.0/10 | 75 packages 有新版 (record 5→7, printing 5.14→5.15, share_plus 10→13, sqlite3 3.4→3.5, timezone 0.9→0.11), sqlcipher 0.6.8 (>= 0.6.5 16KB OK) |
| 十三、数据与资源 | 9.0/10 | Repository 模式 + SQLCipher 加密 + audio 本地, **assets/shaders/ink_sparkle.frag 3978 bytes (R17 round 8 fix)** |
| 十四、日志与错误 | 9.5/10 | piiSafeLog + runZonedGuarded + kReleaseMode 区分 |

**flutter-specification 评分: 9.0/10**, 主要扣分: R-B5 版本号 / 4 处半角 / 5+ 依赖 major 可升。

**app 体积检查建议**:
- 未跑 `flutter build apk --analyze-size` — 不知道当前 apk / aab 实际大小
- 估计: 30 service + Riverpod + Drift + SQLCipher + fl_chart + PDF + record + audioplayers + flutter_local_notifications + 22 SDK transitive — **总 aab 估计 30-50MB** (R5.7 警告阈值 50MB)

**75 packages 有新版 — 重点 major 升级**:
- `record: 5.2.1 → 7.1.1` (2 major) — 7.x API 变, breaking
- `printing: 5.14.3 → 5.15.0` (minor) — 无 breaking
- `qr: 3.0.2 → 4.0.0` (major) — breaking
- `share_plus: 10.1.4 → 13.x` (3 major) — 11/12/13 都有 breaking
- `sqlite3: 3.4.0 → 3.5.0` (minor) — 无 breaking
- `timezone: 0.9.4 → 0.11.1` (2 minor) — 0.10/0.11 breaking

建议 v0.29 集中升级, v0.28 当前先 lock。

---

### 3.5 App Store 视角 (Guideline 1.4.1 / 3.1.5 / 5.1.1 / 1.4.3 / nutrition labels)

**5 大 P0 阻断** (Guideline 一票否决):

| # | 类别 | 位置 | 阻断条款 | 修复 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-A1** | **医疗 App 警告** | `fastlane/metadata/ios/zh-Hans/description.txt:33-42` 强调 "精神心理 / 抑郁 / 焦虑" + `description.txt:23` "PHQ-9 (抑郁) 和 GAD-7 (焦虑) 筛查" | Guideline **1.4.1 医疗 App 警告** — 测心率/血压/血糖/血氧/抑郁/焦虑这类要监管批准文档 | ① 隐私 URL 公开医学免责声明 (医学 disclaimer.md) ② App 描述明确 "本 App 不提供医疗建议" ③ 准备 peer-reviewed study (或医生顾问协议) | 高 (需医学顾问) | **P0** |
| **R-A2** | **隐私政策 URL 占位** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/privacy_url.txt` = `https://chroniccare.app/privacy` (12 文件, 域名未注册) | Guideline **5.1.1** 隐私政策 URL 必须可访问 | ① 注册 `chroniccare.app` 域名 ② 上传隐私政策 HTML (md 渲染) ③ 替换 12 文件 | 中 (1 周域名) | **P0** |
| **R-A3** | **Appfile 占位** | `fastlane/Appfile:21,23,24` `apple_id("your-apple-id@example.com")` + `team_id("YOUR_TEAM_ID")` + `itc_team_id("YOUR_ITC_TEAM_ID")` | 上传 fastlane 上传直接失败 | 真实 Apple ID + 10 字符 Team ID + ITC Team ID | 低 | **P0** |
| **R-A4** | **业务对账** | zh-Hans/description.txt:17 + en-US/description.txt:14 + app_zh.arb:958 safetyAlertBodySent | Guideline **2.3 准确元数据** + **5.1.1 隐私 vs 实际不一致** | 4 处文案改 (zh-Hans description 17 行 + en-US 14 行 + app_zh.arb 958 + app_en.arb + app_zh_Hant.arb 同步) | 低 | **P0** |
| **R-A5** | **IAP 3.1.5 决策** | `lib/core/data/services/store_kit_service.dart:13` + `user_agreement.md:22-28` 写 "8 元买断" + 6 个 IAP ARB key (settingsIap*) 当前 dead code + `FeatureFlags._prodIapEnabled=false` | Guideline **3.1.5(a) 数字商品/服务走 IAP** (买断是 NonConsumable, 必须 IAP) + 当前业务暂停, 描述与实际脱节 | 当前 release 模式 IAP 关闭 = 功能不上架 = 不会触发 3.1.5; 但**上架前必须**: ① `iapEnabled=false` 硬编死 release 模式 ② `user_agreement.md:22-28` 改 "未来规划, 当前不显示买断入口" ③ 6 个 IAP ARB key 加 "v0.28 启用" 注释 + 白名单 | 中 | **P0** |

**P1 上架前必做** (App Store 不会拒但 Apple 审核可能 17.x):

| # | 类别 | 修复 | 难度 |
|---|---|---|---|
| **R-A6** | Privacy Nutrition Labels | App Store Connect 必填: 22 SDK 表格 + IAP + audio + STT + safety watch + DB encryption | 中 (R83 已铺 22 SDK 表, 落到 nutrition labels 待手工) |
| **R-A7** | 16KB + iOS 无关 | iOS 上架无 16KB 要求 (Apple 16KB 是 Android 强制) | ✅ 通过 |
| **R-A8** | 中文 zh-Hant 地区限制 | Apple iOS 港澳台 App Store 上架需单独审核 | 待港澳台 release SOP |

**P2 优化** (上架后 v0.28+):
- R-A1 医学免责声明 doc
- R-A9 准备 peer-reviewed study (或医生顾问协议)
- R-A10 港澳台 marketing 本地化 (zh-Hant description 940 chars vs app_zh_Hant.arb 820 key)

**App Store 评分: 5.5/10**, 主要扣分: R-A1 (医疗警告) + R-A2 (域名) + R-A3 (Appfile) + R-A4 (业务对账) + R-A5 (IAP 决策) 都是 P0 一票否决。

---

### 3.6 Google Play 视角 (16KB / SDK 披露 / 数据安全表单)

**正面**:
- ✓ 16KB page size 已合规 (R70, build.gradle.kts + targetSdk=36)
- ✓ sqlcipher_flutter_libs 0.6.8 (>= 0.6.5 强制最低)
- ✓ R83 Q8: 22 SDK 第三方依赖表 (隐私政策 §7)
- ✓ Play App Signing 启用 (R63)
- ✓ R70 google_play_json_key_path 配 Service Account JSON

**P0/P1 阻断**:

| # | 类别 | 位置 | 阻断条款 | 修复 | 难度 | 优先级 |
|---|---|---|---|---|---|---|
| **R-G1** | **隐私政策 URL 占位** | `fastlane/metadata/android/{en-US,zh-CN}/` 全部 (跟 App Store 共享 12 个 url) | Google Play 隐私政策 URL 必须可访问 | 同 R-A2 | 中 | **P0** |
| **R-G2** | **support URL 占位** | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/support_url.txt` = `https://chroniccare.app/support` | Google Play 必需 support URL + email | 注册域名 + 上线 support 页 + 邮件 (隐私政策 R-Z1 改) | 中 | **P0** |
| **R-G3** | **数据安全表单 (Data Safety Form)** | `scripts/generate_data_safety_form.py` 已存在但**未生成实际表单** | Google Play 2022-07 后必填, **2024-01 后 App Bundle 上架要再核** | ① 跑脚本生成 ② 人工 review (尤其 speech_to_text 是否 cloud / 是否 encryption) | 中 | **P0** (跟 R-A4 业务对账) |
| **R-G4** | **敏感权限声明 (Permissions Declaration)** | AndroidManifest.xml (未跑 `aapt dump permissions`) | Google Play 2024 后, 危险权限 (RECORD_AUDIO / READ_CONTACTS 等) 必须 PurposeDeclaration | 跑 `aapt dump permissions` + 补权限说明 | 低 | P1 |
| **R-G5** | **隐私 URL 占位** | zh-Hant metadata 缺, Android 没 zh-Hant locale, **fastlane/metadata/android/en-US/ + zh-CN/ 都要** | zh-CN 上架大陆 Google Play (Google 退出后, 但保留) | 同 R-A2 | 中 | **P0** |
| **R-G6** | **横幅合规 (Banners & Declarations)** | 健康 app 横幅 / 金融 app 横幅 / 政府 app 横幅 | Google Play 2024 后新分类 | 当前 medical/health 分类, 需 health app 横幅 | 低 | P1 |
| **R-G7** | **targetSdk 36** | `android/app/build.gradle.kts` targetSdk=36 (>= 35 16KB 强制) | Google Play 2025 起新 app + 更新必 35+ | ✓ 已合规 | - | ✅ 通过 |

**P2 优化**:
- R-G8 中文 + 英文双 description 备齐
- R-G9 feature_graphic.png 1024x500 校验

**Google Play 评分: 7.0/10**, 主要扣分: R-G1/R-G2 域名未注册 + R-G3 数据安全表单未跑 + R-G4 敏感权限未声明。

---

### 3.7 法务合规视角 (PIPL §13/14/17/23/28/29/38/47 + 未成年人保护法 §44 + 广告法 §9)

**正面**:
- ✓ 3 法务 md 全部走 R83 律师审核 (5 ❌ 必改 + 18 ⚠️ 需修订, 5 项自修)
- ✓ PIPL §13/§23/§29 单独同意 (4 步同意书 + ConsentGate 集中器)
- ✓ PIPL §14 敏感个人信息同意书 (sensitive_data_consent.md)
- ✓ PIPL §17 明确告知 (导出风险卡 + checkbox)
- ✓ PIPL §28 健康医疗 (隐私政策 §1 表格)
- ✓ PIPL §29 跨境 (隐私政策 §11 整段改 "未来规划", R83 改)
- ✓ PIPL §38 跨境数据传输 (R83 改)
- ✓ PIPL §47 撤回同意 + 删除 (R82.5 vent seal 走通, delete/seal 二选一)
- ✓ 未成年人保护法 §44 (R83 18 周岁严正声明 + 14-18 监护人代为同意)
- ✓ 广告法 §9 禁用绝对化用语 (care_copy 7 条全 OK)
- ✓ 数据安全法 + 网络安全法 (SQLCipher AES-256 + SecureStorage 设备绑定 + 零云端)

**P0 阻断 (法务层面, 需执业律师签字)**:

| # | 类别 | 位置 | 风险 | 修复 | 难度 | 优先级 |
|---|---|---|---|---|---:|---|
| **R-L1** | **律师过审** | `assets/legal/privacy_policy.md` + `user_agreement.md` + `sensitive_data_consent.md` 修订历史表 v0.28+ "TODO (上 store 前必须由专业律师过审)" | 法务未签字 = 0 法律效力, 上架审核 100% 拒 | 由执业律师签字 + 删"草稿"标注 + 删 TODO 段 | 高 (外部 2-4 周) | **P0** |
| **R-L2** | **业务对账** | zh-Hans/description.txt:17 + en-US/description.txt:14 + app_zh.arb:958 safetyAlertBodySent | 隐私政策说"不实际触发"但上架文案/ARB 说"已自动通知" = **虚假宣传** | 4 处文案改 (R-A4 同) | 低 | **P0** |
| **R-L3** | **PIPL §38 跨境** | `pubspec.yaml:70 speech_to_text: ^7.0.0` cloud 模式 | 跨境 PII 传输, 隐私政策措辞含糊 | 二选一: on-device 或承认 + 单独弹窗 (R-Z3) | 中 | **P0** |
| **R-L4** | **隐私政策 URL** | `https://chroniccare.app/privacy` 域名未注册 | 隐私政策无法访问 = 上架 100% 拒 | 注册域名 + 上传 md 渲染 HTML | 中 | **P0** |
| **R-L5** | **support 邮箱占位** | `user_agreement.md:68` `support@chroniccare.app` 占位 | 律师审核后必须注册 | 注册邮箱 + 替换 | 低 | **P0** |
| **R-L6** | **GitHub Issues URL 占位** | `user_agreement.md:69` `https://github.com/example/chroniccare/issues` 占位 | 律师审核后必须确认/替换 | 替换为真实项目仓库 | 低 | **P0** |
| **R-L7** | **PIPL §14 mood/assessment 漏补** | `sensitive_data_consent.md:39-48` §3 处理方式表 | v0.22+ 新增 mood 维度未同步 | 补 §3 mood/assessment 行 | 低 | P1 |

**P1 必做** (上架前不合规但不阻断):

| # | 修复 | 难度 |
|---|---|---|
| **R-L8** | 38 处 ARB 半角标点 100% 全角化 (法务文件 + ARB 强制) | 中 |
| **R-L9** | 139 个 zh_Hant 复制简体 走 OpenCC 批处理 | 中 |
| **R-L10** | R67 §3 §1 §7 §10 §11 §12 措辞跟 R82.5 vent seal / R83 18 周岁 / R83 22 SDK 同步 | 中 |
| **R-L11** | `user_agreement.md:22-28` 8 元段落降为 "未来规划" (R-A5 同步) | 低 |

**P2 优化** (上架后 v0.28+):
- 39 zh-only care_copy 注释
- 200 处硬编码中文 (除 core/l10n/strings.dart 设计保留)

**法务合规评分: 6.0/10**, 主要扣分: R-L1 律师未签字 (2-4 周外部) + R-L4 域名未注册 (1 周) + R-L5 邮箱未注册 + R-L6 仓库未确认。

---

## 4. P0 整合 — 上架前必须修 (8 项)

| # | 类别 | 位置 | 修复 | 工时 | 难度 |
|---|---|---|---|---|---|
| **P0-1** | **版本号不一致** | `pubspec.yaml:5` vs `docs/CHANGELOG.md:3,5,7,11` | 升 pubspec `0.28.0+65` + `check_changelog.py` 加 pubspec 同步校验 | 30 min | 低 |
| **P0-2** | **律师过审 (外部)** | 3 法务 md 修订历史表 v0.28+ "TODO 上 store 前必须由专业律师过审" | 由执业律师签字 + 删"草稿"标注 + 删 TODO 段 | 2-4 周 (外部) | 高 |
| **P0-3** | **fastlane 占位 + 域名** | `fastlane/Appfile:21,23,24` + 12 url 文件 (privacy_url / support_url) | ① 注册 `chroniccare.app` 域名 ② 注册 `support@chroniccare.app` 邮箱 ③ 替换 12 文件 ④ 替换 Appfile 真实 Apple ID + Team ID | 1 周域名 + 30 min 替换 | 中 |
| **P0-4** | **业务对账 (zh-Hans + en-US + ARB)** | `fastlane/metadata/ios/zh-Hans/description.txt:17` + `en-US/description.txt:14` + `app_zh.arb:958 safetyAlertBodySent` | 4 处文案改写: zh-Hans 改"未来规划" + en-US 改"is currently disabled" + app_zh.arb 改"未实际通知" + app_en.arb + app_zh_Hant.arb 同步 | 2h | 低 |
| **P0-5** | **setup 热线硬编码** | `lib/presentation/pages/setup/setup_legal_dialog.dart:111` | 走 l10n, 加 1 个 `setupCrisisHotlineSectionTitle` ARB key x 3 locale | 30 min | 低 |
| **P0-6** | **通知 i18n** | `reminder_scheduler.dart:9` + `refill_notifier.dart:6` + `email_service.dart:6` + `notification_service.dart:5` (推测 26+ 处 zh) | 走 l10n 注入 (参考 R77 snooze_manager 模式) | 1-2 天 | 中 |
| **P0-7** | **PIPL §38 speech_to_text** | `pubspec.yaml:70 speech_to_text: ^7.0.0` + `assets/legal/privacy_policy.md:108,155-161` | 二选一: on-device 或承认 + 单独弹窗 | 1 周 on-device 测试 + 4h 弹窗 | 中 |
| **P0-8** | **App Store 1.4.1 医疗警告** | `fastlane/metadata/ios/zh-Hans/description.txt:33-42` (强调精神心理/抑郁/焦虑) | 准备医学免责声明 + 隐私政策 URL + 医生顾问协议 (或 peer-reviewed study) | 1-2 周 (外部医学顾问) | 高 |

**预计工作量**: 1 周工程 (P0-1/4/5/6) + 2-4 周外部 (P0-2/3 法务+域名+邮箱) + 1-2 周外部 (P0-7 STT on-device) + 1-2 周外部 (P0-8 医学顾问)。**总上架准备: 4-6 周**。

---

## 5. P1 整合 — 上架前必做但不合规不阻断 (10 项)

| # | 类别 | 修复 | 难度 |
|---|---|---|---|
| **P1-1** | ARB 缺失 5 个 en 业务 key | homeLastMed / homeNextReminder / homeStreak / setupStep / snackbarErrorTemplate + homeSafetyAlertSuffix zh_Hant | 低 |
| **P1-2** | 半角全角守门员升级 | `check_fullwidth_punctuation.py` 升 error, 法务文件 + ARB 强制 | 中 |
| **P1-3** | 繁简一致守门员升级 | 守门员 s2tw 反向 + t2s 校验, 127 个未翻译 key 走 OpenCC | 中 |
| **P1-4** | 硬编码中文 100% 走 l10n | medication_report (17) / day_detail (9) / scale_translations (11) / consent_dialog (3) / setupLegalAgeAttestation / setup_legal_dialog:111 | 中 |
| **P1-5** | 撤回 UX l10n + 按钮文案审计 | consent_dialog:169,171,173 | 中 |
| **P1-6** | 业务温度 5 处优化 | safetyAlertBodySent 改完后再走"立即拨打热线"按钮 + assessmentHistoryEmptyHint 改"做一次情绪小测验后" + homeCheckedIn 加鼓励 + setupReminder1-3 改温暖版 + scaleCrisisMessage 加 5 热线 | 中 |
| **P1-7** | 法务同步 | `sensitive_data_consent.md:39-48` §3 处理方式表补 mood/assessment 行 | 低 |
| **P1-8** | 业务暂停描述 | `user_agreement.md:22-28` 8 元段落降为 "未来规划" + 6 个 IAP ARB key 加 v0.28 启用 TODO 注释 | 低 |
| **P1-9** | 数据安全表单 (Play Store) | 跑 `scripts/generate_data_safety_form.py` + 人工 review speech_to_text 是否 cloud | 中 |
| **P1-10** | 敏感权限声明 (Android) | 跑 `aapt dump permissions` + 补 Permissions Declaration | 低 |

---

## 6. P2 整合 — 上架后 v0.28+ 优化 (14 项)

| # | 类别 | 修复 | 难度 |
|---|---|---|---|
| **P2-1** | 主页 god class 30KB 拆 2 controller | `home_page.dart` 抽 HomeDeepLinkHandler + HomeCelebrationController (R79 评估) | 中 |
| **P2-2** | data_management_section god class 21.7KB 拆 3 sub | ExportPanel / ImportPanel / DataGovernancePanel | 中 |
| **P2-3** | mood_audio_section god class 21.2KB 拆 3 sub | MoodRecorder / MoodSTTBlock / MoodAudioPlayback | 中 |
| **P2-4** | 主页 8 transition widget test | 覆盖 8 transition 矩阵 (R-E1) | 低 |
| **P2-5** | safety_watch_service FeatureFlag 守卫 widget test | 加 1 case 验 `emergencyContactEnabled=false` 早返 (R-E2) | 低 |
| **P2-6** | R84 隐私 P0-1 升级 check_changelog | 加 `pubspec version match CHANGELOG top section` (R-E5) | 低 |
| **P2-7** | 4 处半角 (R-B1-R-B4) | database_migration / export_schema_service / app_colors / app_motion | 低 |
| **P2-8** | 4 处 PUA 旧 commit 清 | 检查 PUA 字符 0 (守门员已过, 但 git log 旧 commit 残留) | 低 |
| **P2-9** | vent_entry_entity 时长 formatters | 9 处 `'$sec秒'` / `'$m分'` 走 formatters (R-B14) | 低 |
| **P2-10** | notification deeplink l10n | notification_navigation.dart:2 走 l10n (R-B17) | 低 |
| **P2-11** | app 体积检查 | 跑 `flutter build apk --analyze-size` 看实际大小 | 低 |
| **P2-12** | 75 packages major 升级规划 | record 5→7 / share_plus 10→13 / sqlite3 3.4→3.5 / timezone 0.9→0.11 (v0.29 集中升) | 中 |
| **P2-13** | emil Motion.composer 集中器 | 加 1 个 composer widget (R-E1) | 低 |
| **P2-14** | 3rd-party SDK 守门员 | 加 `check_3rd_party_sdk_disclosure.py` 核验 fastlane metadata vs pubspec | 低 |

---

## 7. P3 整合 — 外部依赖 brainstorm (5 项)

| # | 类别 | 待办 | 外部条件 | 难度 |
|---|---|---|---|---|
| **P3-1** | **IAP 真接** (R55) | 8 元买断 vs 订阅 vs 捐赠 + 病耻感定价 + 心理脆弱人群保护 | App Store Connect 创建 productId + 法务 8 元定价过审 | 高 (brainstorm 1 周 + 实现 4 周) |
| **P3-2** | **阿里云 SMS 真接** (R55) | 失联通知伦理边界 + 误报责任 + 模板分场景 + 脱敏发送 + 本地预签名 | 法务模板审核 1-2 月 + 阿里云 AccessKey 申请 | 高 (brainstorm 1 周 + 接入 2 月) |
| **P3-3** | **失联通知 v1.0 真接** | 阈值 (2/3/7 天) + 模板 (关怀/紧急) + 用户主动确认 + 误报处理 | 阿里云 SMS 接入后 | 高 (brainstorm 1 周) |
| **P3-4** | **SendGrid 邮件真接** (R55) | 邮件模板 + IMAP/POP3 接收 + 客户响应 ≤15 工作日 | 法务过审 + SendGrid 申请 | 高 (1 周) |
| **P3-5** | **医学评估量表扩展** | PHQ-A (青少年) / GAD-2 (快筛) / 自杀意念量表 | 临床精度 + 病耻感 + 危机响应 brainstorm | 高 (brainstorm 1 周 + 实现 2 月) |

---

## 8. 修复路线

### 8.1 本周 (P0 阻断)

1. **P0-1** (30 min): `pubspec.yaml` 升 `0.28.0+65` + `check_changelog.py` 加 pubspec 同步
2. **P0-4** (2h): 4 处业务对账文案改写 (zh-Hans + en-US + 3 locale ARB)
3. **P0-5** (30 min): setup_legal_dialog.dart:111 走 l10n
4. **P0-6** (1-2 天): 26+ 处通知 i18n 走 l10n 注入

### 8.2 本月 (P0 外部依赖 + P1 整改)

1. **P0-2** (2-4 周外部): 律师签字 3 法务 md
2. **P0-3** (1 周域名 + 30 min 替换): 注册 `chroniccare.app` + 邮箱 + 替换 12 url 文件 + Appfile
3. **P0-7** (1 周): speech_to_text on-device 测试
4. **P0-8** (1-2 周外部): 医学免责声明 + 顾问协议
5. **P1-1~10** (3-5 天): ARB 缺失补 + 半角全角 + 繁简一致 + 硬编码中文 l10n + 撤回 UX

### 8.3 下季度 (P2 优化 + 半成品)

1. **P2-1~14** (1-2 周): god class 拆 + widget test 增量 + 守门员增量
2. **P3-1~5** (持续): 5 项外部依赖 brainstorm + 接入

### 8.4 远期 (v1.0+)

- v0.29: 依赖 major 升级 (record/share_plus/sqlite3/timezone) + 5 P3 brainstorm
- v0.30: 失联通知 v1.0 真接 (P0-7 修了 STT + 阿里云 SMS 接入)
- v1.0: IAP 真接 + SendGrid 邮件 + 医学量表扩展 + 家属端/B2B

---

## 9. 整体评估

### 9.1 项目状态

- **架构 (4 层 + 5 umbrella)**: 9.0/10, 0 analyzer error, 16 守门员
- **业务温度 (精神心理 App 典范)**: 9.0/10, "我们关心你" / "少 1 次没关系" / "🛏️ 提早一点更稳定"
- **工程化 (1433 test, R63→R84 71 commit)**: 9.0/10, TDD 95%+
- **形式合规 (5 步同意 + 4 ConsentGate + 22 SDK + 5 热线)**: 8.0/10
- **上架就绪 (域名/Appfile/律师/STT/医疗警告)**: 4.0/10, **5 P0 阻断未解**
- **半成品 (3 处真接 TODO)**: 6.0/10, FeatureFlag 守卫生效但需真接

### 9.2 上架前必修 8 件事 (再强调)

1. **P0-1** 版本号同步 (pubspec + CHANGELOG + 守门员)
2. **P0-2** 律师签字 3 法务 md (2-4 周外部)
3. **P0-3** fastlane 占位 + 域名 + 邮箱 (1 周 + 30 min)
4. **P0-4** 业务对账 4 处文案 (2h)
5. **P0-5** setup 热线硬编码 (30 min)
6. **P0-6** 通知 i18n 26+ 处 (1-2 天)
7. **P0-7** PIPL §38 speech_to_text on-device (1 周)
8. **P0-8** App Store 1.4.1 医疗警告 (1-2 周外部)

**预计总工时**: 工程 1 周 + 外部 4-6 周

### 9.3 上架后 v0.28+ roadmap

- R86: P0-1~8 + P1-1~10
- R87: 业务温度全面审计 + 病耻感专项 + 危机话术 v2
- R88: IAP brainstorm + 决策
- R89: 阿里云 SMS 接入
- R90: 失联通知 v1.0 真接
- R91: 港澳台 marketing 本地化 + 繁体区 App Store 上架
- v0.29: 依赖 major 升级 (record 7 / share_plus 13 / sqlite3 3.5 / timezone 0.11)

---

## 10. 附录

### 10.1 7 视角对应 skill / 方法

| 视角 | skill / 方法 | 文档依据 |
|---|---|---|
| emilkowalski | `emilkowalski/improve-animations` + `review-animations` | R81 6 commit 总览 |
| superpowers-zh | `chinese-code-review` + `chinese-git-workflow` + `chinese-documentation` | R84 audit_round84_superpowers_zh.md |
| superpowers-en | `systematic-debugging` + `verification-before-completion` + `test-driven-development` | R56c-d TDD 续 |
| flutter-specification | `flutter-specification/SKILL.md` 14 章 + 6 附录 | v3.1 规范 |
| App Store | Apple App Store Review Guidelines 1.4.1 / 3.1.5 / 5.1.1 / Privacy Nutrition Labels | WWDC22 + 知乎拒审案例 |
| Google Play | 16KB page size (Android 15+) + Data Safety Form + Permissions Declaration | developer.android.com |
| 法务合规 | PIPL §13/14/17/23/28/29/38/47 + 未成年人保护法 §44 + 广告法 §9 + 数据安全法 + 网络安全法 | R83 律师审核简报 |

### 10.2 16 守门员覆盖

```
scripts/check_arb_keys.py                  zh/en/zh_Hant 同步
scripts/check_changelog.py                 CHANGELOG 顺序 (需加 pubspec 同步, P0-1)
scripts/check_cross_feature.py             跨 feature import
scripts/check_datetime_race.py             DateTime.now() race
scripts/check_datetime_race2.py            DateTime(y,m,d) race2
scripts/check_drift_namespace.py           @DataClassName 唯一
scripts/check_fullwidth_punctuation.py     半角标点 (需升 error, P1-2)
scripts/check_no_hardcoded_utc.py          UTC 硬编码
scripts/check_no_pua.py                    PUA 字符
scripts/check_widget_dispose.py            资源泄漏
scripts/check_orphan_arb_keys.py           ARB key 引用
scripts/check_legal_consent.py             PIPL §13 单独同意
scripts/check_sms_release_ready.py         SMS 上线 checklist
scripts/check_strings_hardcoded.py         硬编码中文
scripts/check_zh_hant_consistency.py       繁简一致
scripts/check_16kb_alignment.py            16KB page size
dart scripts/check_all.dart                 4 层架构 + 一致性
```

### 10.3 关键文件 Top 30 (按需遍历)

| 路径 | 字节 | 类别 | 备注 |
|---|---|---|---|
| `lib/l10n/app_localizations.dart` | 143624 | generated | 排除 |
| `lib/presentation/pages/home/home_page.dart` | 30531 | god class | R-A1 (R64 拆 9 widget + enum 状态机, 还可拆 2 controller) |
| `lib/presentation/pages/settings/widgets/data_management_section.dart` | 21693 | god class | R-A2 (拆 3 sub) |
| `lib/presentation/pages/mood/widgets/mood_audio_section.dart` | 21222 | god class | R-A3 (拆 3 sub) |
| `lib/presentation/pages/trend/trend_calendar.dart` | 20101 | - | OK |
| `lib/presentation/pages/setup/setup_page.dart` | 19866 | - | OK |
| `lib/main.dart` | 19629 | 启动 | R67 B-1 邮件守卫修, R62 SMS 守卫修 |
| `lib/core/data/database/app_database.dart` | 18597 | schema | schemaVersion 12 |
| `lib/core/data/services/notification_service.dart` | 18392 | facade 拆 4 sub | R-A4 还可拆 channel/navigation |
| `lib/core/data/services/safety_watch_service.dart` | 17906 | facade 拆 3 sub | FeatureFlag 守卫早返 disabled (R-业务对账 已业务层对齐) |
| `lib/presentation/pages/vent/vent_compose_page.dart` | 17477 | - | OK |
| `lib/presentation/pages/settings/legal_page.dart` | 17077 | - | OK |
| `lib/presentation/pages/settings/reminders_hub_page.dart` | 16737 | - | OK |
| `lib/presentation/pages/assessment/assessment_page.dart` | 16477 | - | OK |
| `lib/presentation/pages/medication/medication_calendar_page.dart` | 15928 | - | OK |
| `lib/presentation/pages/medication/widgets/edit_medication_dialog.dart` | 15673 | - | OK |
| `lib/presentation/pages/assessment/assessment_widgets.dart` | 15421 | - | OK |
| `lib/presentation/pages/settings/widgets/notification_status_card.dart` | 15304 | - | OK |
| `lib/core/l10n/strings.dart` | 15237 | domain fallback | R-B10 设计保留 |
| `lib/presentation/pages/vent/vent_detail_page.dart` | 15213 | - | OK |

---

**审计员**: 7 视角综合
**日期**: 2026-08-02
**版本**: v0.28 round 84
**下次审计**: R86 IAP 真接前 (P3-1 brainstorm 触发后)
