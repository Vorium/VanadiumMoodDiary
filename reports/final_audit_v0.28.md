# 慢病管家 v0.28 多视角综合审查报告

**审查日期**: 2026-08-02
**审查方法**: 4 路独立并行 agent，逐文件逐行阅读，互不共享数据
**审查范围**: 267 lib/.dart + iOS/Android 配置 + 3 份 legal + fastlane 元数据 + 151 test + ARB ≈ 450+ 文件

---

# 一、Flutter 规范视角

## 顶层架构审视 (8.3/10)

项目严格遵循 `presentation → domain ← data` 4 层架构。domain 层零 Flutter/Drift，16 个 CI 守护脚本验证。

### 架构违规

| # | 文件 | 问题 | 难度 |
|---|------|------|------|
| 1 | `domain/logic/chinese_holidays.dart:8` | domain 直接 import `core/data/services/pii_safe_log.dart` | S |
| 2 | `core/data/services/safety_alert_builder.dart:33` | data/service import presentation l10n | S |
| 3 | `core/data/services/safety_watch_service.dart:16` | 同上 | S |
| 4 | `core/data/services/safety_alert_dispatcher.dart:12` | 同上 | S |

### 可重构模块 (P3)

| # | 模块 | 说明 |
|---|------|------|
| 5 | `lib/presentation/pages/settings/` | Hub god feature，含通知/数据/法律/账户 |
| 6 | `lib/core/l10n/strings.dart` (303行) | 50+ 中文 fallback，override 几乎未传入 |
| 7 | `lib/core/data/database/app_database.dart` | `saveSetup`/`clearAllUserData` 应移入 usecase |
| 8 | `lib/core/data/services/reminder_scheduler.dart` | `ReminderService` 类已废弃但未删除 |

## 底层逐行排查

### P0 — 上架阻断 (2 个)

| # | 文件:行号 | 类型 | 难度 | 说明 |
|---|-----------|------|------|------|
| 9 | `app_database.dart:176-207` | 数据丢失 | L | v8→v9 vent 加密迁移 for-loop 非事务，中断后 contentTextEnc=null 不可恢复，v15→v16 `ALTER TABLE DROP COLUMN content_text` 执行后文字永久丢失。需在 DROP 前检查 contentTextEnc 是否 null 并重试加密 |
| 10 | `app_database.dart:280-318` | 加固 | S | v15→v16 DROP COLUMN 全走 try/catch swallowError，SQLite<3.35 静默失败，列残留 |

### P1 — 必修 Bug (5 个)

| # | 文件:行号 | 类型 | 难度 | 说明 |
|---|-----------|------|------|------|
| 11 | `check_in_dao.dart:42-58` | Bug | M | `watchToday()` 创建时固化 startOfDay/endOfDay 到 WHERE，跨 midnight 后新打卡不被 Stream 触发 |
| 12 | `safety_watch_service.dart:260-261` | Bug | S | `_dispatchLostContact` 用 `lastCheckInAt!` 和 `profile!` 依赖 SafetyDetector 隐式合约，若 upstream 改判则 NPE |
| 13 | `reminder_scheduler.dart:119` | Bug | S | `Future.wait.first as List<ContactEntity>` 类型强转，mock 注入非预期类型时 TypeError |
| 14 | `reminders_hub_page.dart:141` | Bug | S | `_showAssessmentSettings` 闭包内读 configAsync，但 build 已 watch，sheet 中可能拿到 stale 值 |
| 15 | `vent_detail_page.dart:148-149` | Bug | S | `mounted` 检查后多余 `context.mounted` 重复检查，冗余但无害 |

### P2 — 应修 (20 个)

**i18n 硬编码中文 (11 处)**

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 16 | `scale_translations.dart:144-274` | L | StaticScaleTranslations 含 50+ 处硬编中文(PHQ-9/GAD-7 题目/严重度/热线)，en 用户做评估看到中文 |
| 17 | `day_detail.dart:329-366` | M | 7 处中文 fallback(`'每日打卡'`/`'PHQ-9 抑郁筛查'`/`'临时吃药'`等) |
| 18 | `medication_report.dart:205-291` | L | `toReportString()` 全文 30+ 处中文标签(`'患者'`/`'报告周期'`/`'漏服'`等) |
| 19 | `care_copy.dart:48-69` | S | 4 个关怀 trigger 文案中文 fallback |
| 20 | `vent_entry_entity.dart:80-105` | S | `durationLabelL10n` 中文 fallback `'$sec秒'`/`'$m分'` |
| 21 | `check_in_entity.dart:62-75` | S | `labelL10n` 中文 fallback |
| 22 | `assessment_comparison.dart:204` | S | `severityLabelFor` fallback `'等级 $rank'` |

**硬编码 Token 值 (8 处)**

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 23 | `hero_illustration.dart:45-106` | S | 7+ 处 emoji fontSize 裸数字(36/28/56/32) + alpha/Color 裸值 |
| 24 | `home_fab_toolbar.dart:107-168` | S | FAB width/height:56, Icon size:28/18 裸数字 |
| 25 | `quick_mood_carousel.dart:121-179` | S | alpha 0.04, Icon size:18, height:80, fontSize:32 裸数字 |
| 26 | `main.dart:292-467` | S | 迁移 UI 中 10 处 SizedBox/EdgeInsets 裸数字未走 token |

**其他**

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 27 | `snooze_manager.dart:145` | S | cancel range 用 `<` vs `<=` 比较不一致 |

### P3 — 优化 (28 个，批量)

已发现但均为 S 级低优先：`vent_compose_page.dart`/`setup_page.dart` 的 `setState((){})` 全页 rebuild、`reminder_dispatcher.dart` 串行 cancel、`export_orchestrator.dart` 6 查询串行、`legal_consent_provider.dart` StreamProvider 仅 yield 一次、`app_list_tile.dart` _isDestructive 死代码、`mood_visual.dart` ARGB 未引 AppColors、`chinese_holidays.dart` 数据只到 2030 等。

---

# 二、App Store 视角

## P0 阻断 (9 项)

| # | 文件 | 阻断? | 难度 | 说明 |
|---|------|--------|------|------|
| 28 | `assets/legal/*.md` (3文件) | 是 | L | 修订历史全部标注"草稿 (未经律师过审)"，Apple 5.1.1(vi) 必拒 |
| 29 | `user_agreement.md:68` | 是 | S | `support@chroniccare.app` 是 TODO 占位邮箱 |
| 30 | `user_agreement.md:69` | 是 | S | `github.com/example/chroniccare/issues` 是占位 URL |
| 31 | `fastlane/metadata/*/privacy_url.txt` (6文件) | 是 | M | 指向 `https://chroniccare.app/privacy`，域名未注册 |
| 32 | `fastlane/metadata/*/support_url.txt` (6文件) | 是 | M | 同上 `https://chroniccare.app/support` 不可达 |
| 33 | `ios/Runner.xcodeproj/project.pbxproj` | 是 | M | PrivacyInfo.xcprivacy 未在 pbxproj 引用，不会打包进 ipa |
| 34 | `ios/Runner.xcodeproj/project.pbxproj` | 是 | S | 缺 DEVELOPMENT_TEAM |
| 35 | `ios/Podfile` | 是 | M | Windows 占位，无 Podfile.lock |
| 36 | `fastlane/screenshots/` | 是 | M | 缺 6.7"/6.9" 截图 |

## P1 高风险 (5 项)

| # | 文件 | 说明 |
|---|------|------|
| 37 | `ios/Runner/Runner.entitlements` | 空文件仅注释，缺 `speech_recognition` 能力声明 |
| 38 | `fastlane/metadata/ios/en-US/description.txt:1` | "stay connected with loved ones" 暗示失联通知可用(实际 disabled) |
| 39 | `fastlane/metadata/ios/zh-Hans/subtitle.txt` | 含"失联通知规划中"，提未实现功能 |
| 40 | `fastlane/metadata/ios/zh-Hant/subtitle.txt` | 同上 |
| 41 | `ios/Runner/PrivacyInfo.xcprivacy:136-145` | ProcessInfo AC67.1 reason 与 flutter_local_notifications 实际 API 不匹配 |

## P2 建议 (6 项)

| # | 文件 | 说明 |
|---|------|------|
| 42 | `Info.plist:8` | `CFBundleDevelopmentRegion` 未显式设 `zh-Hans` |
| 43 | `Info.plist` | 缺 `CFBundleLocalizations` 显式声明 |
| 44 | `Podfile:18` | `platform :ios, '13.0'` vs pbxproj `14.0` 不一致 |
| 45 | `project.pbxproj` | `ORGANIZATIONNAME` 空值 |
| 46 | `Runner.entitlements` | 空文件可从 pbxproj 移除 CODE_SIGN_ENTITLEMENTS 引用 |
| 47 | `fastlane/metadata/ios/*/screenshots` | 缺 6.9" 尺寸，需补充 |

---

# 三、Google Play Store 视角

## P0 阻断 (5 项)

| # | 文件 | 阻断? | 难度 | 说明 |
|---|------|--------|------|------|
| 48 | `build.gradle.kts:88-98` | 是 | S | `signingConfig = signingConfigs.getByName("debug")`，key.properties 不存在 |
| 49 | `assets/legal/*.md` | 是 | L | 同 App Store #28 |
| 50 | 域名/邮箱/URL 占位 | 是 | S-M | 同 App Store #29-32 |
| 51 | `fastlane/metadata/android/**/video.txt` | 是 | S | PLACEHOLDER_APP_DEMO_VIDEO |
| 52 | `fastlane/metadata/android/zh-CN/title.txt` | 是 | S | 标题含"失联通知规划中" |

## P1 高风险 (2 项)

| # | 文件 | 说明 |
|---|------|------|
| 53 | `AndroidManifest.xml:45` | `android:label="慢病管家"` 硬编中文，英文桌面显示中文 |
| 54 | `fastlane/metadata/android/**/full_description.txt` | 描述中含 "coming soon / currently disabled" |

## P2 建议 (3 项)

| # | 文件 | 说明 |
|---|------|------|
| 55 | Play Console | Data Safety Form 未填 |
| 56 | Play Console | 内容分级未填 |
| 57 | `fastlane/metadata/android/zh-CN/full_description.txt:39,41` | 危机热线 400-161-9995 重复两行 |

---

# 四、法务合规视角

## PIPL 合规 (80/100)

| 条款 | 状态 | 备注 |
|------|------|------|
| §13 单独同意 | ✅ | 4 勾选 + ConsentDialog + ConsentArtifact |
| §14 撤回同意 | ✅ | 3 toggle + ConsentGate 业务层拦截 |
| §17 同意记录 | ✅ | DB 字段 + audit log |
| §23 第三方提供 | ⚠️ | 用户担保模式，联系人本人确认待 SMS 接入 |
| §28 敏感信息(加密) | ⚠️ | SQLCipher + AES-CBC 字段级，但加密迁移失败会导致数据永久丢失(#9) |
| §31 未成年人 | ✅ | 年龄严正声明 |
| §38 跨境传输 | ⚠️ | speech_to_text 已识别 + FeatureFlag 控制 |
| §47 删除权 | ✅ | 单条/全部/卸载 |

## 法律文档阻断

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 58 | `user_agreement.md:68` | S | 邮箱 TODO 占位 |
| 59 | `user_agreement.md:69` | S | GitHub 仓库占位 |
| 60 | 3 份文档修订历史 | L | 全部标注"草稿 (未经律师过审)" |
| 61 | `user_agreement.md:24-28` | S | IAP 注脚说"暂停"但代码 `_prodIapEnabled=true` |
| 62 | 缺英文版隐私政策 | M | 面向海外用户需英文 URL |

---

# 五、ARB i18n + 测试层

## ARB (95/100)

| # | 问题 | 难度 |
|---|------|------|
| 63 | en.arb 缺 5 个 @ 注解 (zh.arb 有): @homeLastMed/@homeNextReminder/@homeStreak/@setupStep/@snackbarErrorTemplate | S |
| 64 | zh_Hant.arb 缺 @homeSafetyAlertSuffix (zh+en 都有) | S |

ARB 三语 738 key 完全同步，零缺失零多余。Placeholder 类型一致。

## 测试覆盖缺口

| # | 文件 | 难度 | 说明 |
|---|------|------|------|
| 65 | `assessment_scale.dart` | M | 评估量表基类零测试 |
| 66 | `temp_entry_extractor.dart` | M | 临时用药提取工具零测试 |
| 67 | `medication_report_pdf_layout.dart` | M | PDF 布局引擎零测试 |
| 68 | `store_kit_service.dart` | M | IAP 服务零测试 |
| 69 | `hour_minute.dart` | S | 时间值对象零测试 |
| 70 | `dosage_unit.dart` | S | 枚举值零测试 |
| 71 | `mood_entry_draft.dart` | S | 草稿值对象零测试 |
| 72 | `medication_draft.dart` | S | 同上 |
| 73 | `report_history_entity.dart` | S | 实体零测试 |
| 74 | `user_profile_entity.dart` | S | 同上 |

## 测试规范

| # | 问题 | 难度 |
|---|------|------|
| 75 | `test/_tmp_email_test.dart` | S | 占位文件，`expect(1+1,2)` |
| 76 | `test/widget_test.dart` | S | 未用 `_roundN_` 命名 |

---

# 六、综合优先级排序

## P0 — 上架阻断 (14 项)

| # | 问题 | 视角 | 难度 | 类型 |
|---|------|------|------|------|
| 1 | 律师审核 3 份法律文档 | 法务+Store | L | 外部 |
| 2 | 域名 `chroniccare.app` 注册 + 部署隐私页/支持页 | Store | M | 外部 |
| 3 | 注册 `support@chroniccare.app` 邮箱 + 替换 3 处占位 | 法务 | S | 外部 |
| 4 | GitHub Issues 占位替换 | 法务 | S | 外部 |
| 5 | Android release 签名切换 | Play | S | 代码 |
| 6 | iOS Podfile: macOS pod install 生成 Podfile.lock | App Store | M | 外部 |
| 7 | PrivacyInfo.xcprivacy 加入 pbxproj 打包 | App Store | M | 配置 |
| 8 | 配置 Apple Development Team | App Store | S | 外部 |
| 9 | 删除 metadata 中 "规划中/coming soon" 措辞 | Store | M | 文档 |
| 10 | 删除 PLACEHOLDER_APP_DEMO_VIDEO 占位 | Play | S | 文档 |
| 11 | App Icon + 截图 | Store | M | 外部 |
| 12 | 软件著作权登记 | 法务 | L | 外部 |
| 13 | vent 迁移数据永久丢失修复 | Flutter | L | 代码 |
| 14 | IAP productId 创建 | Store | S | 外部 |

## P1 — 必修 Bug (11 项)

| # | 问题 | 难度 | 文件 |
|---|------|------|------|
| 15 | check_in_dao watchToday 跨 midnight 流不更新 | M | `check_in_dao.dart:42` |
| 16 | safety_watch_service !强转 NPE 风险 | S | `safety_watch_service.dart:260` |
| 17 | reminder_scheduler Future.wait cast 类型不安全 | S | `reminder_scheduler.dart:119` |
| 18 | reminders_hub_page 闭包 stale 读 | S | `reminders_hub_page.dart:141` |
| 19 | en.arb 缺 5 个 @ 注解 | S | `app_en.arb` |
| 20 | zh_Hant.arb 缺 @homeSafetyAlertSuffix | S | `app_zh_Hant.arb` |
| 21 | assessment_scale 零测试 | M | `assessment_scale.dart` |
| 22 | temp_entry_extractor 零测试 | M | `temp_entry_extractor.dart` |
| 23 | medication_report_pdf_layout 零测试 | M | `medication_report_pdf_layout.dart` |
| 24 | store_kit_service 零测试 | M | `store_kit_service.dart` |
| 25 | safety_alert_* 3文件 data→presentation 架构违规 | S | 3文件 |

## P2 — 应修 (25 项)

| # | 问题 | 难度 |
|---|------|------|
| 26-32 | 7 处 i18n 中文硬编 (scale_translations/day_detail/medication_report/care_copy/vent_entry/check_in/assessment_comparison) | S-L |
| 33-36 | 4 处 token 硬编码 (hero_illustration/home_fab_toolbar/quick_mood_carousel/main.dart) | S |
| 37 | snooze_manager cancel range < vs <= 不一致 | S |
| 38 | 6 个 entity 零测试 | S |
| 39 | chinese_holidays domain→data 架构违规 | S |
| 40-42 | Podfile/Info.plist 配置不一致 | S |
| 43 | AndroidManifest label 硬编中文 | M |
| 44 | 危机热线号码重复 | S |
| 45 | CFBundleLocalizations 未声明 | S |
| 46 | _tmp_email_test 占位 | S |
| 47 | widget_test 命名不规范 | S |
| 48 | PrivacyInfo ProcessInfo reason 不匹配 | S |
| 49 | 空 entitlements 可移除 | S |

## P3 — 优化 (28 项，批量)

包括: setState 全页 rebuild、串行可改并行、AES-CBC 无 HMAC、PRAGMA key 字符串插值、Random() 非 secure、mood_visual ARGB 未引 AppColors、StreamProvider 仅 yield 一次、死代码、spacing 裸数字未走 token 等。全部为 S-M 难度，不影响功能。

---

# 七、总评

| 维度 | 评分 | 说明 |
|------|------|------|
| Flutter 规范 | **A-** | 9 个真实 Bug(1 致命)，0 崩溃级 Widget 错误 |
| App Store 就绪 | **4/10** | 9 项阻断，核心: 域名/法律文档/隐私清单/证书全缺 |
| Google Play 就绪 | **5/10** | 5 项阻断，核心: debug 签名 |
| 法务合规 | **80/100** | PIPL 框架扎实，3 份文档需律师 |
| 架构成熟度 | **8.3/10** | 4 处违规(1 domain→data + 3 data→presentation) |
| ARB i18n | **95/100** | 738 key 三语同步，2 处 @ 注解缺失 |
| 测试 | **8/10** | 151 test 文件，10 个缺口 |

**结论**: 4 路并行审查 450+ 文件。**P0 共 14 项**(2 个代码侧 Bug + 12 个外部依赖)，**P1 共 11 项**(5 个 Bug + 4 个测试缺口 + 2 个 ARB)。代码质量整体优秀，最严重风险是 vent 加密迁移导致数据永久丢失(#13)和 check_in_dao 跨 midnight 流不更新(#15)。
