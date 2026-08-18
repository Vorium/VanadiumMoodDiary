# Lens 10: Googleplaystore (Android 上架细节)

**Date**: 2026-08-18
**Scope**: Google Play Console metadata + AndroidManifest + 截图 + feature_graphic + 16KB alignment + 64-bit ABI + 5 厂商 push + R128a~R128d 跨期验证
**Baseline**: 1.1.0+180, 2728 tests pass / 0 fail / 1 skip, 24 gatekeepers, 1340 ARB keys, R128d step 3 收官

## 总体评分

**5.5/10** (持平 R120 baseline, R128a~R128d 0 闭环 Android 上架硬阻塞 2 P0, R117 round 5 工具链 +0.5 仍主导)

## 核心 Findings

### ✅ 优点 / 强项 (5 项)

| # | 项 | 状态 | 文件:行 |
|---|---|---|---|
| GP-01 | 6 Android 权限白名单 (INTERNET/POST_NOTIFICATIONS/SCHEDULE_EXACT_ALARM/WAKE_LOCK/VIBRATE/RECORD_AUDIO) | ✓ R97/R105 累计 | `android/app/src/main/AndroidManifest.xml:54-62` |
| GP-02 | targetSdk=36 pin (Google Play 2025-08 强制) | ✓ R63 pin | `android/app/build.gradle.kts:38` |
| GP-03 | 64-bit only ABI (arm64-v8a + x86_64) + NDK 28.2.13676358 pin | ✓ R70/R117 round 5 累计 | `android/app/build.gradle.kts:113-115` |
| GP-04 | Release signingConfig 切 release (key.properties 读真实 .jks) | ✓ R97 | `android/app/build.gradle.kts:94-98` |
| GP-05 | 5 厂商 push facade (5 通道抽象 + NoOp + 5 厂商占位) | ✓ R124 阶段 1 落地 | `lib/core/platform/notification/five_vendor_push_service.dart:9.7KB` |
| GP-06 | notification umbrella 抽 `core/platform/notification/` (8 文件, R128a) | ✓ 0 manifest 变化 | `lib/core/platform/notification/` |
| GP-07 | allowBackup=false (PIPL §28 精神心理数据禁止 backup) | ✓ R63 | `android/app/src/main/AndroidManifest.xml:73` |
| GP-08 | enableOnBackInvokedCallback=true (Android 13 预测式返回手势) | ✓ R63 | `android/app/src/main/AndroidManifest.xml:72` |
| GP-09 | 16KB alignment 守门员 (R70 配 R112 round 8 --so-path 硬验证) | ✓ 0 violation | `scripts/check_16kb_alignment.py:20-30` |
| GP-10 | INTERNET 权限保留 (R114 BUG 11, debug 走 src/debug/AndroidManifest.xml 独立声明) | ✓ | `android/app/src/main/AndroidManifest.xml:54` + `src/debug/AndroidManifest.xml` |

### ⚠️ 待优化 (6 项)

| # | 项 | 状态 | 文件:行 | 估时 |
|---|---|---|---|---|
| GP-11 | **Android 截图 67B** (4 张 placeholder, 缺 6 寸 + 7 寸 + 10 寸多分辨率) | 🔴 阻塞 Google Play 必须 | `fastlane/metadata/android/{zh-CN,en-US}/phone_screenshots/screenshot_{1-4}.png` 67B | 等设计师 |
| GP-12 | **feature_graphic 21KB** (1024×500, Google Play 推荐 ≥30KB 实际无硬性,但低质量易被审核标记) | 🟡 非阻塞但低质 | `fastlane/metadata/android/en-US/feature_graphic.png` 21.8KB | 等设计师 |
| GP-13 | **icon.png 13.6KB** (Google Play icon 推荐 ≥50KB, 当前 13.6KB 偏低) | 🟡 非阻塞 | `fastlane/metadata/android/en-US/icon.png` 13.6KB | 等设计师 |
| GP-14 | **4 邮箱 + 域名 ICP** 跨 iOS+Android 共享 (privacy_url [PENDING_DOMAIN]) | 🔴 阻塞 (跟 AS-12 同源) | `fastlane/metadata/android/en-US/privacy_url.txt:1` `[PENDING_DOMAIN]` | 7-20d |
| GP-15 | **5 厂商 push 真 SDK 接入 0** (R124 阶段 2, 1-2 月) | 🟡 业务暂停,失联通知 100% 失效 | `lib/core/platform/notification/five_vendor_push_service.dart` 5 厂商 impl throw UnimplementedError | 1-2 月 |
| GP-16 | **targetSdk=36 但 compileSdk=flutter.compileSdkVersion (隐式)** (R63 pin 目标 SDK 但未 pin 编译 SDK) | 🟡 Flutter 升级漂移风险 | `android/app/build.gradle.kts:12` | 0.1h |
| GP-17 | **鸿蒙 channel 0% 集成** (R128a~R128d 跨 4 round 0 鸿蒙动作) | 🟡 长期 (v1.0+ 才考虑) | 无文件 | 跨期 |

### 🚫 红线 (0 项)

本 lens 跨期 0 引入新红线。AndroidManifest 6 项权限 0 黑名单 (R97 累计), PIPL §28 防御 100% 闭环。

## 跨 Lens 共识 (3 项)

| # | 共识 | 跟谁 |
|---|---|---|
| GP-C1 | **5 P0 跨期残留 8+ round 0 主动动作** = googleplay 跟 appstore 共识 (设计师资产 + 域名 ICP + 5 厂商 push) | Lens 9 |
| GP-C2 | **Android 截图 67B = iOS 截图 0 张同根因** = googleplay 跟 appstore 共识 (设计师外包依赖) | Lens 9 |
| GP-C3 | **R124 5 厂商 push facade = googleplay 跟 notification umbrella 共识** (R128a 跨期 0 引入回归) | R128a cross-check |

## 4 FeatureFlag 状态 (R128d 跨期 0 变化)

| Flag | 当前 | 翻 true 条件 | 优先级 |
|---|---|---|---|
| `phqGad7I18nEnabled` | **false** | PHQ-9/GAD-7 16 题 i18n 走完 ARB | P2 |
| `bootReceiverEnabled` | **false** | WorkManager 完善 (R55 阶段) | P3 |
| `fiveVendorPushEnabled` | **false** | 5 厂商 push SDK 接入 (1-2 月) | P1 |
| `ventAudioEnabled` | **true** | R104 已翻 true | - |
| `healthKitEnabled` (R128c 新增) | **false** | HealthKit 5-6 月真接 (v1.0+) | P3 (iOS only) |

## R128a~R128d 改动验证

| Round | 期望 (Android 角度) | 实际 | 状态 |
|---|---|---|---|
| **R128a** notification umbrella | 8 文件抽 `core/platform/notification/`, Android 0 manifest 变化 | `notification_delegate.dart` + `notification_initializer.dart` + `notification_payload.dart` + `reminder_dispatcher.dart` + `snooze_manager.dart` + `notification_service.dart` + `five_vendor_push_service.dart` 完整, AndroidManifest 0 修改 | ✓ 0 引入 Android 回归 |
| **R128b** crisis 5/5 收官 | 5 region i18n 完整, Android 0 manifest 变化 | `lib/features/crisis/data/logic/hotline_regions.dart` 5 region 全 ARB, 0 manifest 变化 | ✓ |
| **R128c** HealthKit stub 骨架 | iOS only, Android 0 影响 | `lib/core/platform/health_kit/health_kit_service.dart` 7.5KB (iOS only, Android 走 web/asset), Android 0 集成 | ✓ |
| **R128d** 5 token 转 pub workspace | chroniccare_theme 公共 package, Android 0 变化 | `packages/chroniccare_theme/lib/chroniccare_theme.dart` 5 export, android/ 0 文件修改 | ✓ |

**R128a~R128d 跨 Android lens 累计**: 4 round 0 引入 Android 上架硬阻塞解决, 0 引入 Android 回归。4 round 是"防御性架构" + "跨期残留 0 解决" 双轨 (跟 iOS lens 同模式)。

## R129+ 建议

| # | 优先级 | 项 | 文件:行 | 估时 | 评分影响 |
|---|---|---|---|---|---|
| 1 | **P0 (外部)** | GP-11 Android 截图 4 张 → 6+ 张 (6寸/7寸/10寸多分辨率) | `fastlane/metadata/android/{zh-CN,en-US}/phone_screenshots/screenshot_{1-4}.png` | 等设计师 1-2 周 | +0.3 (5.5→5.8) |
| 2 | **P0 (外部)** | GP-12 feature_graphic 21KB → 50KB+ (1024×500 提质) | `fastlane/metadata/android/{zh-CN,en-US}/feature_graphic.png` | 等设计师 1 周 | +0.2 (5.8→6.0) |
| 3 | **P0 (外部)** | GP-13 icon.png 13.6KB → 50KB+ (512×512 提质) | `fastlane/metadata/android/{zh-CN,en-US}/icon.png` | 等设计师 1 周 | +0.1 (6.0→6.1) |
| 4 | **P0 (外部)** | GP-14 chroniccare.app 域名 + 4 邮箱 ICP (跟 AS-12 同源) | `fastlane/metadata/android/en-US/privacy_url.txt:1` | 7-20d | +0.3 (6.1→6.4) |
| 5 | **P1 (内部)** | GP-15 5 厂商 push 真 SDK 接入 (R124 阶段 2) | `pubspec.yaml` + `AndroidManifest.xml` 5 厂商 service/receiver + 5 impl 不再 throw | 1-2 月 | +0.5 (6.4→6.9) |
| 6 | **P1 (内部)** | GP-16 compileSdk 显式 pin 36 (防 Flutter 升级漂移) | `android/app/build.gradle.kts:12` → `compileSdk = 36` | 0.1h | +0.1 (6.9→7.0) |
| 7 | **P2 (内部)** | Android 16KB 真机 objdump 验证 (R112 --so-path 跑 `flutter build appbundle`) | `scripts/check_16kb_alignment.py --aab <app-release.aab>` | 2h | +0.1 |
| 8 | **P2 (内部)** | 失联通知 100% 失效修复 (1.1.0 round 4b 删后无替代) | R124 5 厂商 push 接入后自动修复 | 1-2 月 | +0.3 |
| 9 | **P3 (跨期)** | 鸿蒙 channel (huawei harmony) 集成 (v1.0+) | R130+ 路线图 | 1-3 月 | +0.5 |

**R129 hotfix (1 周)**: P1-6 + P2-7 估时 2.1h, 评分 5.5 → 6.1 (+0.6)
**R129 + 设计师资产 (1-2 周)**: P0-1~P0-3 估时 0, 评分 6.1 → 6.7 (+0.6)
**R129 + 域名 ICP (7-20d)**: P0-4 估时 0, 评分 6.7 → 7.0 (+0.3)
**R1.0 (2027-Q1, 5 厂商 push + 鸿蒙 channel)**: 估时 1-3 月, 评分 7.0 → 7.5+ (+0.5)

> **Android 上架根本问题**: R117 round 5 工具链适配 (Gradle 8.14 + NDK 28.2 + newDsl=true) 是 Android 上架的技术基础, 已 100% 闭环。R124 5 厂商 push facade (阶段 1 落地) 是 Android 失联通知业务的基础设施, 阶段 2 真接 SDK 是 v1.0 关键路径。**真正根因 = 2 P0 设计师资产跨期残留 0 主动动作** (截图 67B + feature_graphic 低质 + icon.png 低质), 跟 iOS 上架同根因 (设计师外包依赖)。
