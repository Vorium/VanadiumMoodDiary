# App Store 上架视角审计 (2026-08-13, R111)

基线: R110 报告 `docs/audit/2026-08-13-multi-lens/05-appstore.md` (AS-01~14) + `docs/SUBMISSION_INFO.md` + `docs/STOREFRONT_RELEASE_SOP.md`。本次为纯只读验证, 逐项重跑 AS-01~14 + 找新风险。master `6bbb308` (0.32.0+140), working tree clean。

**结论: 代码面可提交, 整体仍不可提交**。R110 round 3 的 AS-07/08/14 三项代码 P0 全闭环验证通过; 锁屏 PII / PrivacyInfo / IAP / 权限文案 / 版本一致性全部干净。残留硬阻塞 100% 为外部依赖 (review 4 占位 / 0 截图 / 68B LaunchImage / 10.9KB Icon / chroniccare.app 域名未注册), 与 R110 报告一致, 无回归。

## Findings

| ID | 类别 | 标题 | 证据(file:line) | 难度 | 优先级 |
|---|---|---|---|---|---|
| AS-01 | 元数据 | review_information 4 文件仍占位符 `[REPLACE_BEFORE_APPLE_REVIEW:...]` (跨期残留) | fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt | ≤5min 填真实值 (等真实信息) | **P0** |
| AS-03 | 外部 | privacy/support URL 全指向未注册 chroniccare.app; Apple 5.1.1(v) 要求可访问 (跨期残留) | fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/{privacy_url,support_url}.txt ×6 | 7-20d (域名+ICP) | **P0** |
| AS-04 | 资产 | iOS 截图 0 张 (无 screenshots 目录; Fastfile skip_screenshots=false → 提交即失败) (跨期残留) | fastlane/metadata/ios/en-US/ + fastlane/Fastfile:61 | 设计师 1-2d (33 张 3 locale) | **P0** |
| AS-05 | 资产 | LaunchImage 3× 68B 1×1px 占位 (跨期残留; storyboard 已修 2377B) | ios/Runner/Assets.xcassets/LaunchImage.imageset/*.png | 设计师 | **P0** |
| AS-06 | 资产 | AppIcon 1024² 仅 10932B 近空白 + 其他 15 尺寸全 282-1674B 占位 (2.3.7 拒审风险) (跨期残留) | ios/Runner/Assets.xcassets/AppIcon.appiconset/*.png | 设计师 | **P0** |
| AS-02 | 元数据 | notes.txt 版本 0.32.0+130 vs 当前 0.32.0+140, 过期 10 builds; 虚假声明段已清 (R110 round 2 已修) | fastlane/metadata/ios/review_information/notes.txt:1 | 5min | P2 |
| AS-15 | 元数据 | notes.txt "No third-party SDKs" 措辞严格为假: 实际 15+ 第三方 package (sqlcipher_flutter_libs/drift/audioplayers/flutter_local_notifications/in_app_purchase...) — Apple 抽审若较真可指误导, 建议改 "No analytics, ad, or tracking SDKs" | notes.txt:4 | 5min | P2 |
| AS-16 | 守门员 | SUBMISSION_INFO.md:34 计划的 check_review_information_todo.py 防回退守门员未建 — AS-01 有回归风险 | scripts/ (仅 check_pii_in_title.py) | 30min | P2 |
| AS-17 | 合规 | description "two widely-recognized standardized questionnaires" + "Crisis resources are highlighted if your answers suggest extra support" — 5.1.3 医疗/健康抽审仍可能触发, 提交时必须填 Health Information Disclosure Questionnaire; 措辞可更中性 | fastlane/metadata/ios/en-US/description.txt:13-14 | 10min 措辞 + 提交时问卷 | P1 |
| AS-18 | 合规 | safety_alert Android `visibility: NotificationVisibility.public` — 锁屏完整显示失联天数/上次打卡日期 (title 已无 PII, 决策已文档化: 紧急 UX > PII); 待法务确认, 可 1 行改 private | lib/core/data/services/safety_alert_builder.dart:100 | 0 (维持) / 5min (改 private) | P3 |
| AS-19 | 资产 | Android 平行占位: 8× 67B 截图 + feature_graphic 67B + icon 1443B (GooglePlay 侧, 本报告附注; label 已修 @string/app_name) | fastlane/metadata/android/en-US/phone_screenshots/ + feature_graphic.png | 设计师 | P1 |

## R110 跨期残留验证 (AS-01~14 逐项)

**已闭环 (R110 round 3 + R32 修复后仍干净, 验证通过)**:

- **AS-07 紧急联系人可见性 — 闭环** ✅: setup 表单 `setup_step_welcome.dart:124` `if (FeatureFlags.emergencyContactEnabled) ...` gate; reminders_hub 安全卡 `reminders_hub_page.dart:139` 同 gate; settings 联系人 section `profile_group.dart:183` 同 gate; 生产默认 false → 全不可见
- **AS-08 Mock 文案 — 闭环** ✅: "isMockSms"/Mock 警告只在被 gate 的 SafetyReminderCard 内 (reminder_cards.dart:84-104), 生产不可达
- **AS-14 validateForRelease 启动抛错 — 闭环** ✅: main.dart:164 `if (FeatureFlags.emergencyContactEnabled)` 才调 SmsService.validateForRelease; email/iap 同 gate; 暂停业务不再触发 "上次启动出错" banner
- **AS-09 description 5.1.3 病名/screening — 闭环** ✅: en-US/zh-Hans/zh-Hant 全 metadata grep 0 病名 / 0 "screening" (AS-17 剩 questionnaires 措辞, P1)
- **AS-10 SOP productId — 闭环** ✅: SOP:76 与 store_kit_service.dart:50 均为 `com.chroniccare.chroniccare.lifetime`
- **AS-11 版本一致性 — 闭环** ✅: pubspec 0.32.0+140 = CHANGELOG [0.32.0+140] = README 0.32.0+140 (notes.txt 例外, 见 AS-02)
- **锁屏 PII — 闭环** ✅: 通知 title 全静态无药名 (strings.dart:93 '🌱 今天吃了药吗？' / :112 '💊 该吃药了' / :152 mood), medication_notifier.dart:133-137 title 去药名注释在; 5 处 DarwinNotificationDetails 均 categoryIdentifier + timeSensitive 空 title 构造; Android visibility secret ×4 (reminder_dispatcher:116 / notification_service:243 / snooze_manager:100 / badge_sync:69); check_pii_in_title.py 守门员在位 (规则 1/2/3 覆盖)
- **PrivacyInfo.xcprivacy — 闭环** ✅: HealthAndFitness 已删 (R108 P0-020), 剩 AudioData/ContactInfo/UserContent 3 类 + 5 类 AccessedAPI 全带 reason, 与零云端声明一致
- **IAP — 闭环** ✅: iapEnabled=false, buyLifetime 早返 false (store_kit_service.dart:105-109), main.dart:170-173 跳过 warmup
- **Info.plist — 闭环** ✅: NSMicrophone/NSSpeechRecognition/NSPhotoLibraryAdd/NSPhotoLibrary 4 项英文基线 + zh-Hans/zh-Hant InfoPlist.strings 覆盖齐全; ITSAppUsesNonExemptEncryption=false; LSApplicationCategoryType=healthcare-fitness; UIBackgroundModes=audio (与 ventAudioEnabled=true 匹配)
- **entitlements — 闭环** ✅: 空 (无 aps-environment / 无 HealthKit), 与 "无 APNs / 无 HealthKit" 声明一致
- **Appfile — 闭环** ✅: ENV 模式 (APPLE_ID/TEAM_ID/ITC_TEAM_ID 从 .env), 无凭据进 git
- **外部链接面 — 闭环** ✅: 仅 tel: 危机热线 (crisis_hotline_page.dart:242), 无 webview/mailto/http/SMS; demo_user.txt 正确
- **Apple Health 假声明 — 闭环** ✅: lib/ + fastlane/ grep 0 "Apple Health"/"HealthKit"

**未闭环 (R110 跨期残留, 全外部依赖)**: AS-01 / AS-03 / AS-04 / AS-05 / AS-06 (见 Findings 表, 与 R110 报告 100% 一致, 0 新代码残留)

## 上架检查清单状态

| 检查项 | 状态 |
|---|---|
| 代码面: 锁屏 PII / 权限文案 / PrivacyInfo / IAP 隐藏 / 紧急联系人 gate / 无假声明 | ✅ 全绿 |
| review_information 4 占位 | ❌ 等真实值 |
| notes.txt 版本 + 声明 | ⚠️ 声明已净, 版本过期 10 builds |
| privacy/support URL | ❌ 域名未注册 (7-20d) |
| iOS 截图 33 张 | ❌ 0 张 |
| LaunchImage / AppIcon | ❌ 68B / 10.9KB 占位 |
| Apple Health Information Disclosure Questionnaire | ⏳ 上架前 1 周填 |
| Appfile 真实凭据 (.env) | ⏳ 上架前 |
| Xcode DEVELOPMENT_TEAM / 首次 Archive | ⏳ 首次 Mac build |
| 法务 3 份 md 律师签字 | ⏳ 1-2 周 (外部) |
| Android keystore (key.properties 不存在) | ❌ 未生成 |

## 总结

1) **R110 round 3 三项代码 P0 (AS-07/08/14) 全闭环验证通过**, R32 的锁屏 PII / PrivacyInfo / productId / 权限文案修复全部仍干净, 代码面已达提交水准 (grep 级 0 病名 / 0 假声明 / 全 gate 验证); 2) **残留硬阻塞 6 项 100% 为外部依赖** (review 4 占位 / 0 截图 / 68B LaunchImage / 10.9KB Icon / 域名未注册), 与 R110 报告完全一致, 0 新代码残留; 3) 新发现 7 项均 P1-P3 低危: 最值得做的是 AS-16 (建 review_information 防回退守门员, 30min)、AS-02/AS-15 (notes.txt 版本 + SDK 措辞, 10min)、AS-17 (description questionnaires 措辞 + 提交时 Health Disclosure 准备); 4) **整体就绪度: 代码 9.5/10, 提交就绪 4/10 — 上架路径完全卡在外部闸门 (域名/设计师/法务), AI 可做的最后一项 = AS-16 守门员**。
