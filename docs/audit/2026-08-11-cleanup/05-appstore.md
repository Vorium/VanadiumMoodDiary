# 视角 5 报告 · AppStore (iOS 上架 / 5.1.3 抽审)

## 元信息
- 跑时间: 2026-08-11
- baseline: master HEAD `01d8f4a` v0.31.0+107 (23 commit Apple Health 风格重设计)
- 关注: iOS 上架 / Apple Guideline 5.1.3 (HealthKit used-but-not-declared) / 锁屏 PII / Info.plist / PrivacyInfo / LaunchImage / AppIcon / 5 项上架硬阻塞
- 跑工具: Read / Glob / Grep / `check_apple_health_claim.py` / `check_changelog.py` / `check_strings_hardcoded.py` / `check_legal_consent.py`

## 23 commit 改动面 (git diff 1b851a8..01d8f4a)
- 66 文件 / +7447 / -3504 行
- **ios/ 目录 0 改动** (Info.plist / PrivacyInfo.xcprivacy / Runner.entitlements / LaunchImage / AppIcon 全部 1b851a8 状态)
- 改动集中在 `lib/core/theme/` (5 文件: app_colors/motion/spacing/tokens/typography + 新 spring.dart) + `lib/presentation/widgets/` (新增 apple_health_tile.dart + apple_list_section.dart + check_in_button / primary_button / section_header / stat_card 4 重写) + 9 feature 页面 (home/setup/medication/...) 跟新 token
- 新增 8 个 test 文件 (lock-in + sanity + 9 feature 视觉 smoke)

## 5 维度评估

### 1. 外部链接检查
- [OK] `https://chroniccare.app/privacy` 等 12 URL 在 fastlane privacy_url/support_url/3 locale (R108 决策 P0-006,**未注册**,不属本次 commit 范围)
- [OK] `ios/Runner/Info.plist` **无** `NSAppTransportSecurity` 配置 (项目零远程 API,纯本地,不需 ATS 例外)
- [OK] `ios/Runner/PrivacyInfo.xcprivacy` 维持 R108 状态:3 类数据 (AudioData / ContactInfo / UserContent) + 5 类 required-reason API (UserDefaults / FileTimestamp / SystemBootTime / DiskSpace / ProcessInfo) + **无** HealthAndFitness (R108 P0-020 删 + `check_apple_health_claim.py` 守门员)
- [OK] 整 `lib/` 0 `package:health_kit/` / `package:health/` import (Grep 0 命中)
- [OK] `pubspec.yaml` 0 health_kit / health_connect 依赖 (mental_health / chronic_disease 仅出现在 description 文案)

### 2. 上架 / 架构 / 重构 / 半成品 (对照 R108 §六 P0 13 项 + 43 项)
- [OK] **P0-001 锁屏 body 药名 PII** (R108 修) — `medication_notifier.dart:132-138` title/body 都走 `Strings.notifMedicationTitle()` / `Strings.notifMedicationBody()` 通用文案,无 dosage/unit/medName 参数注入。line 146 注释 `med.name 是 PII` 防御性 swallowError
- [OK] **P0-005 en-US description "hypertension/diabetes" 删** (R108 P0-006) — `description_no_health_claim_round108_test.dart` lock-in test 5 文件 (iOS 3 + Android 2) 扫描 10 关键词 (hypertension/diabetes/glucose/insulin/a1c/cardiovascular/heart disease/blood pressure/cholesterol/heart rate) 全过
- [OK] **P0-007 iCloud Backup 排除** (R108 P0-1) — `lib/core/data/utils/skip_backup.dart` 集中器覆盖 4 路径:DB 文件 (`database/connection/native.dart:25`)、app docs (`main.dart:128`)、录音目录 (`encrypted_audio_storage.dart:109`)、日志 (`swallow_log_sink.dart:60`)
- [OK] **P0-009 UIBackgroundModes audio 恢复** — `Info.plist:163-166` 数组含 `audio` 单一值 (R100 删 / R104 翻 ventAudioEnabled=true / R108 恢复完整闭环)
- [OK] **P0-020 HealthAndFitness 删 + 守门员** — `check_apple_health_claim.py` 4 规则扫描全过
- [ISSUE-R108残留] **P0-003 iOS LaunchImage 3 张 68B 占位** (`ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,.@2x,.@3x}.png` 全 68 字节) — Apple 拒因"LaunchImage 占位",23 commit 范围外
- [ISSUE-R108残留] **P0-004 review_information 3 TODO** — `first_name.txt` "TODO: 真实名字" + `email_address.txt` "TODO: 真实邮箱" + `phone_number.txt` "TODO: +86 真实手机号" + `last_name.txt` "TODO: 真实姓";`notes.txt` 写 `v0.30.0+85` **已过期**(当前 0.31.0+107)
- [ISSUE-R108残留] **P0-006 chroniccare.app 域名** — 12 URL 占位 (PIPL/Apple/Google Data Safety 拒因)
- [ISSUE-R108残留] **P0-011 store_kit productId 不一致** — `store_kit_service.dart:50` `com.chroniccare.app.lifetime` vs Info.plist 包名 `com.chroniccare.chroniccare` 冗余前缀
- [ISSUE-R108漏修] **P0-024 AndroidNotificationDetails.setLockscreenVisibility 0 命中** — 整 `lib/` 搜 `setLockscreenVisibility` / `VISIBILITY_SECRET` / `relevanceScore: 0` 全部 0 命中,5 个 DarwinNotificationDetails 也没设 `categoryIdentifier` 锁屏 PII 防护。R108 报告 P0-024 标但实际未闭环 (跨期漏跑 grep verify)
- [ISSUE-R108残留] **P1-026 iOS 16KB page size 验证未跑** — `pubspec.yaml:24` `sqlcipher_flutter_libs: ^0.6.5` 标"0.6.5+ 16KB 对齐最低版本"声明,但无 `check_16kb_alignment.py` 跑 (Google Play 2025-11-01 强制,iOS 17 SDK 同步)
- [ISSUE-R108残留] **P1-027 AppIcon 1024×1024 = 10932B** — Apple HIG 推荐 ≥ 200KB,当前 10KB 占位偏小
- [ISSUE-R108残留] **P1-028 Podfile Windows 占位** + 缺 `Podfile.lock` (R108 报告 iOS 上架 Mac 端)
- [ISSUE-R108残留] **P1-029 DEVELOPMENT_TEAM 未设** + 包名 `com.chroniccare.chroniccare` 冗余双 chroniccare

### 3. 顶层架构审视
- **整体评价**:Apple Health 23 commit 是**纯 presentation 层视觉重设计**,严格遵守 R108 决策边界 (presentation 不动 ios/ 不动 Info.plist 不动 domain/data),符合"5 层 + 共享 umbrella"架构。"Apple Health 风格" = iOS system color + ultralight 大数字 + 13pt ALL CAPS section + 50pt button + 0 阴影 + spring 动效,跟 iOS HIG 17/18 一致
- **iOS 配置 vs 实际功能一致性 (8/10)**:
  - ✅ Info.plist NSUsageDescription 4 个 (Mic/SpeechRecognition/PhotoLibraryAdd/PhotoLibrary) 全部已声明,无 used-but-not-declared
  - ✅ LSApplicationCategoryType = `healthcare-fitness` 跟 App Store Connect 分类呼应
  - ✅ ITSAppUsesNonExemptEncryption = false (SQLCipher 标"标准库加密",合规)
  - ⚠️ LSApplicationCategoryType 跟 PrivacyInfo 不含 HealthAndFitness 一致性 OK (项目零 HealthKit 集成,Category 选 healthcare-fitness 仍合规,因为 mental health 不属 HealthKit 数据)
  - ⚠️ categoryIdentifier 0 设 (锁屏通知分组缺失,用户锁屏多通知时无法归类)
- **上架阻塞项清单 (5 项,按紧急度排序)**:
  1. P0-003 LaunchImage 实物 1-2d (设计师)
  2. P0-001 iOS 截图 6+ 张 1-2d (fastlane 脚本存在但未跑)
  3. P0-004 review_information 4 TODO 替换 30min (需真实姓名 + 邮箱 + 手机)
  4. P0-006 域名注册 7-20d (外部依赖 ICP,卡点)
  5. P0-024 setLockscreenVisibility 0.5h (lock-in test + 1 行 fix)

### 4. 底层逐行排查
- **已遍历**: 18 个 iOS / fastlane / pubspec / lib 关键文件 (Info.plist / PrivacyInfo.xcprivacy / Runner.entitlements / LaunchScreen.storyboard / 3 个 AppIcon 尺寸 / 3 个 LaunchImage / 5 个 NSUsageDescription / en-US/Review information 6 文件 / 5 份 iOS description / 5 个 notification DarwinNotificationDetails 调用点)
- **找到 bug**:
  - **[BUG-1, 难度 S, P0 上架硬阻塞]** `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` 全 TODO 占位 (P0-004)
  - **[BUG-2, 难度 S, P0]** `lib/core/data/services/notification_service.dart:229` + `reminder_dispatcher.dart:110` + `snooze_manager.dart:95` 3 个 `DarwinNotificationDetails()` 空构造,无 `categoryIdentifier`/`relevanceScore: 0`/`interruptionLevel` 锁屏 PII 防护 (P0-024 漏修)
  - **[BUG-3, 难度 S, P0]** `fastlane/metadata/ios/review_information/notes.txt:1` 版本号 `v0.30.0+85` **过期**,当前 v0.31.0+107 (P0-004 衍生)
  - **[BUG-4, 难度 M, P0]** `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage{,.@2x,.@3x}.png` 3 张 68 字节 (P0-003 占位)
  - **[BUG-5, 难度 S, P1]** `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` 10932B 偏小 (P1-027)
  - **[BUG-6, 难度 S, P0]** `fastlane/metadata/ios/en-US/description.txt:17` "PHQ-9 (depression) and GAD-7 (anxiety) screening" + line 27 "depression, anxiety, bipolar, PTSD, ADHD" — **5.1.1 Medical App 抽审风险**(非 5.1.3,因为关键词列表不含这些词)。R108 P0-005 修的是 hypertension/diabetes,精神疾病名漏
  - **[BUG-7, 难度 S, P0]** `lib/core/data/services/store_kit_service.dart:50` productId `com.chroniccare.app.lifetime` vs 包名 `com.chroniccare.chroniccare` 冗余 (P0-011)
- **优化点**:
  - `safety_alert_builder.dart:88-93` 已设 `interruptionLevel: InterruptionLevel.timeSensitive` (safety 用途锁屏必须显示),可作为 reminder_dispatcher/snooze_manager/notification_service 3 个空构造的参考模板
  - `description_no_health_claim_round108_test.dart` 守门员 5 文件扫描模式可复用 — 加 1 个 `description_no_medical_claim_round108_test.dart` 守 `[BUG-6]`,扫描 line 17/27 的 5 病名 + "medical" "diagnose" "treat" "cure" "disease" 关键词
  - `lib/core/data/utils/skip_backup.dart` 集中器模式好,可在 P1+ 加 `assertAllBackupExcluded()` 健康检查 (运行时验证 4 路径都已 opt-out)

### 5. dev doc 更新
- [没改] `AGENTS.md` — 23 commit 0 改动,无新章节,5 必读文件 + 18 守门员清单仍是当前
- [没改] `docs/CHANGELOG.md` — 23 commit 含 CHANGELOG 0.31.0 entry (`4ebec68`),`check_changelog.py` 验证 50 commit 顺序正确
- [建议] `ios/Runner/Runner.entitlements` 加一行注释标注 "v0.31 R108 决策:不接 APNs,只走 flutter_local_notifications 本地通知" 防未来误加 aps-environment
- [建议] `lib/core/data/services/notification_service.dart` 顶部加 1 段"iOS 锁屏 PII 防护决策"doc 注释 (跟 `medication_notifier.dart:132-134` 同模板),说明 categoryIdentifier 0 设的 trade-off (App Store Review 5.1.1 抽审 vs 用户锁屏 PII 暴露)

## 总结
**Apple Health 23 commit 严格遵守"presentation-only 重设计"边界**,0 ios/ 改动,0 HealthKit 集成,0 PII 引入 — R108 锁屏 PII 修复闭环 (title/body 通用文案) + HealthAndFitness 删除 + iCloud Backup 4 路径排除 + 4 个守门员 (check_apple_health_claim.py / description_no_health_claim_round108_test / check_changelog / check_legal_consent) 全过。

**但 5 项上架硬阻塞 100% 残留 (跨期 23 commit 范围外)**:P0-003 LaunchImage 68B / P0-004 review TODO 3 文件 + notes 版本过期 / P0-006 域名未注册 / P0-011 productId 冗余 / P0-024 setLockscreenVisibility 0 命中 (R108 报告漏标/未闭环,5 个 DarwinNotificationDetails 3 个空构造)。

**AppStore 评分维持 R108 3.5/10**: 实物资产 (截图/LaunchImage/Icon/域名/邮箱) 0 落地,上架可执行性 = 0;但代码层隐私边界 (PII 防护 + HealthKit 0 误声明 + iCloud Backup 排除) 已达到 Apple 5.1.3 抽审标准,等外部依赖 (域名 ICP + 设计师实物资产) 1-2 月可上架。

**bug 计数**:7 个新发现 (5 P0 + 1 P1 + 1 5.1.1 抽审风险) + 5 项 R108 残留硬阻塞,3 维度 (实物资产 / 守门员 / 决策边界) 健康。
