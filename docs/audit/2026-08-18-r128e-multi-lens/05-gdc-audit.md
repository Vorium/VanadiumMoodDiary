# Lens 5: gdc-audit (iOS / Android / 鸿蒙 / 桌面 全平台合规)

**Date**: 2026-08-18
**Scope**: iOS / Android / 鸿蒙 / 桌面跨平台合规 + HealthKit / 5 厂商 push / 16KB / 锁屏 PII
**Baseline**: 1.1.0+185, 2728 tests pass, 24 gatekeepers (20 .py + 1 .dart + 3 R128d pub workspace)

## 总体评分

**7.5/10** (R120 持平, R128a~d 0 跨平台新增,R128c HealthKit stub 收官但 0 真接,**5 项上架硬阻塞跨期 6 round 0 闭环**拉分)

## 平台覆盖现状

| 平台 | 状态 | 关键文件 | 备注 |
|---|---|---|---|
| **iOS** | 95% | `ios/Runner/Info.plist` + `Runner.entitlements` + `PrivacyInfo.xcprivacy` | R128c HealthKit stub,**iOS 锁屏 PII 3 处未修** |
| **Android** | 95% | `android/app/src/main/AndroidManifest.xml` + `build.gradle.kts` | NDK 28.2.13676358 + 16KB 对齐 + minSdk 24 + targetSdk 36 |
| **Web** | 70% | `web/index.html` + `web/manifest.json` | drift worker 404 → production 模式 OK |
| **鸿蒙** | 0% | - | v1.0 长期,R128a~d 0 鸿蒙动作 |
| **macOS / Linux / Windows** | 0% | - | 未启用 |
| **HealthKit (iOS)** | 5% | `lib/core/platform/health_kit/health_kit_service.dart` (204L stub) | R128c stub,5-6 月真接 |
| **5 厂商 push (Android)** | 30% | `lib/core/platform/notification/five_vendor_push_service.dart` (316L) | R124 facade,NoOp 默认,1-2 月接入 |

## 核心 Findings

### ✅ 优点 / 强项 (5 项)

1. **NDK 28.2 + 16KB 对齐**: `android/app/build.gradle.kts:18` 显式 pin `ndkVersion = "28.2.13676358"`, `sqlcipher_flutter_libs: ^0.6.5` 满足 Google Play 2025-11-01 强制门槛。`check_16kb_alignment.py` 基础配置 ✅,产 .aab 验证 SKIP(待 CI)
2. **iOS 权限白名单严格**: `Info.plist` 4 usage description (Mic / Speech / Photo Add / Photo Library) + 1 防御性 InfoPlist.strings 多语 + `LSApplicationCategoryType=healthcare-fitness` (R66) + `ITSAppUsesNonExemptEncryption=false` (R62) + `UIBackgroundModes=audio` 注释清晰 (R108)
3. **Android 权限 6 + queries 1**: INTERNET / POST_NOTIFICATIONS / SCHEDULE_EXACT_ALARM / WAKE_LOCK / VIBRATE / RECORD_AUDIO + PROCESS_TEXT。`networkSecurityConfig` + `dataExtractionRules` + `fullBackupContent` (R61) + `enableOnBackInvokedCallback=true` (R63 Android 13) + `allowBackup=false` (PIPL §28) 全配齐
4. **PrivacyInfo.xcprivacy 干净**: 5 类 accessed API (UserDefaults / FileTimestamp / SystemBootTime / DiskSpace / ProcessInfo) + 2 类 collected data (AudioData / UserContent)。R108 删 HealthAndFitness + R112 删 ContactInfo,5.1.3 used-but-not-declared 0 风险 ✅
5. **R128a~d 跨 feature 共享**:`lib/core/platform/notification/` umbrella 7 file (1538L) + 旧 path re-export,**4 feature 解耦干净**;R128c HealthKit stub + R128b crisis 5/5 + R128d 5 token 集中器转 pub workspace — 平台抽象层就绪

### ⚠️ 待优化 (8 项)

| # | 平台 | 问题 | 文件:行 | 优先级 | 估时 |
|---|---|---|---|---|---|
| **G-1** | iOS | **3 处 DarwinNotificationDetails 锁屏 PII 泄漏**:`notification_service.dart:172` / `reminder_dispatcher.dart:127` / `snooze_manager.dart:112` 默认 `presentAlert: true` (iOS 14+),锁屏会显示完整 title/body。`badge_sync_service.dart:73` 才有 `presentAlert: false`。精神心理用户锁屏"该吃药了"+"该续方了"+"心理评估时间到"可推断病情 | `lib/core/platform/notification/notification_service.dart:172`, `reminder_dispatcher.dart:127`, `snooze_manager.dart:112` | **P0** | 0.5h |
| **G-2** | iOS | `Runner.entitlements` 空 (R70 删 aps-environment),**HealthKit entitlement 5-6 月真接前**未加 `com.apple.developer.healthkit` 注释占位 | `ios/Runner/Runner.entitlements:1-9` | P1 | 0.2h |
| **G-3** | iOS | `Info.plist` 缺 `NSHealthShareUsageDescription` / `NSHealthUpdateUsageDescription`,HealthKit 5-6 月真接前必加 | `ios/Runner/Info.plist` (整文件) | P1 | 0.2h |
| **G-4** | iOS | iOS 16KB 真机验证 0 跑过(Android 16KB 仅基础配置,`unzip .aab` + `objdump segment >= 16384` 缺)。R120 / R31 / R108 跨期 6 round P1-026 残留 | `scripts/check_16kb_alignment.py` (脚本 SKIP 产 .aab) | **P0** (上架前 1 周必跑) | 2h |
| **G-5** | iOS | `notes.txt` 版本 `1.1.0+168` ≠ pubspec `1.1.0+180` (实际 master 1.1.0+185),`check_review_information_todo.py` 1 项 FAIL | `fastlane/metadata/ios/review_information/notes.txt:1` | **P0** | 0.1h |
| **G-6** | Android | `INTERNET` 权限保留(R114 注释"无实际网络出口,未来预留")。release build 冒烟 + 国内商店自检未跑 | `android/app/src/main/AndroidManifest.xml:42` | P1 | 1h |
| **G-7** | 鸿蒙 | R128a~d 0 鸿蒙动作,无 `ohos/` 目录、无 5 鸿蒙 SDK 占位、无 HMS Core / 华为推送 / 鸿蒙支付接入 | (无) | P3 (v1.0 长期) | 5-15d |
| **G-8** | Android | `RECORD_AUDIO` 1 个权限(vent + mood 录音共用),R108 §六 G-8 P3 拆 2 个 service 加 manifest-service 绑定跨期 0 闭环 | `AndroidManifest.xml:48` | P3 | 1d |

### 🚫 红线 (1 项)

- **G-Redline-1**: iOS 16KB page size 真机 0 验证 (跨期 P1-026 R108 6 round 残留)。Apple 2025 秋 / Google Play 2025-11-01 强制门槛。当前仅 `check_16kb_alignment.py` 验基础配置(.aab 验证 SKIP),上架前 1 周必跑 `flutter build aab --release` + `objdump` 验 16KB segment,**0 闭环 = 上架必拒**。

## 跨 Lens 共识 (2 项)

- **跟 pull-on-shelf**: G-1 锁屏 PII 3 处 + G-5 notes.txt 1.1.0+168 不一致 = pull-on-shelf PS-19 5.1.3 抽审准备 + AS-25 同步项都是上架前同步
- **跟 superpowers-zh**: G-2/G-3 HealthKit entitlement + NSHealthShareUsageDescription 跨 6 round 0 闭环 = "5-6 月真接" 长期承诺,**R128c stub 收官 ≠ 5.1.3 5 拒审防护闭环**,真接前需补

## R128a~R128d 改动验证

| 指标 | 期望 (R128 路线图) | 实际 (R128e 实测) | Δ |
|---|---|---|---|
| HealthKit stub 骨架 (R128c) | abstract + NoOp + factory + facade 4 段式 | ✅ 204L 4 段式完整 (health_kit_service.dart:1-204) | 100% |
| HealthKit FeatureFlag (R128c) | `_prodHealthKitEnabled = false` 默认 | ✅ (`lib/core/data/feature_flags.dart:58`) | 100% |
| check_apple_health_claim.py 修真 (R128c) | 加 3 规则 + 注释 | ✅ (修真 4 规则 + R128c cross-ref) | 100% |
| notification umbrella 7 file (R128a) | 端到端抽 + 旧 path re-export | ✅ (lib/core/platform/notification/ 7 file 1538L) | 100% |
| crisis 5/5 收官 (R128b) | 迁 features/crisis/ + 5 region i18n | ✅ (1 commit 整包 + 55 crisisHotline key × 3 ARB) | 100% |
| 5 token 集中器转 pub workspace (R128d step 1) | chroniccare_theme 4th member | ✅ (`packages/chroniccare_theme`) | 100% |
| iOS 锁屏 PII 锁屏 title (R32 P0-03 跨期) | `presentAlert: false` 全通知 | ✗ 3 处未修 (G-1) | 0% |
| iOS 16KB 真机验证 (R120 / R31 / R108 跨期 P1-026) | `objdump segment >= 16384` CI 验 | ✗ 仍 SKIP (G-Redline-1) | 0% |
| 5 厂商 push SDK 真接 (R124 facade 后续) | 米/华/OPP/vivo/魅族 5 SDK | ✗ 仍 NoOp (1-2 月) | 0% |
| 鸿蒙 0% 集成 (R108 / R117 / R120 跨期) | ohos/ 目录 + HMS Core | ✗ (G-7) | 0% |

**R128 路线图进度**: 6/10 (60%) — 平台抽象层 100% 闭环 (R128a/b/c/d),**上架真接 + 锁屏 PII + 16KB 验 0% 闭环跨期残留**。

## R129+ 建议 (8 项,按优先级)

| # | 项 | 文件:行 | 估时 | 估评分影响 |
|---|---|---|---|---|
| **G-Fix-1** | iOS 3 处 DarwinNotificationDetails 加 `presentAlert: false` (锁屏禁显示通知详情) | `lib/core/platform/notification/notification_service.dart:172`, `reminder_dispatcher.dart:127`, `snooze_manager.dart:112` | 0.5h | +0.3 |
| **G-Fix-2** | `notes.txt` 同步 master 版本 `1.1.0+185` | `fastlane/metadata/ios/review_information/notes.txt:1` | 0.1h | +0.1 |
| **G-Fix-3** | iOS 16KB 真机 build + `unzip .aab` + `objdump segment >= 16384` CI gate | `scripts/check_16kb_alignment.py` (加 `--aab` 参数必填) | 2h | +0.5 (上架硬阻塞解除) |
| **G-Fix-4** | `Runner.entitlements` 加 HealthKit entitlement 占位注释 (R128c cross-ref) | `ios/Runner/Runner.entitlements:5` | 0.2h | +0.1 |
| **G-Fix-5** | `Info.plist` 加 `NSHealthShareUsageDescription` + `NSHealthUpdateUsageDescription` 占位注释 | `ios/Runner/Info.plist` (尾部) | 0.2h | +0.1 |
| **G-Fix-6** | Android `INTERNET` 权限 release build 冒烟验证 (跑 `flutter build apk --release` + 离线功能自检) | `android/app/src/main/AndroidManifest.xml:42` | 1h | +0.2 |
| **G-Fix-7** | Android 拆 RECORD_AUDIO service 绑 manifest-service (R108 §六 G-8) | `AndroidManifest.xml:48` + 新建 `vent_audio_service.xml` / `mood_audio_service.xml` | 1d | +0.2 |
| **G-Fix-8** | 鸿蒙 0% 启动 (ohos/ 目录 + HMS Core push 接入评估) | 新建 `ohos/` + `app.json5` | 5-15d (v1.0 长期) | +0.5 (v1.0 长期) |

**R129 闭环后估分**: 7.5 → 8.6/10 (G-Fix-1~6 短平快,G-Fix-7~8 长期)
