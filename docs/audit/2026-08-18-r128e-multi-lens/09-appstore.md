# Lens 9: AppStore (iOS 上架细节)

**Date**: 2026-08-18
**Scope**: AppStore Connect metadata + 5.1.3 抽审 + Info.plist + 截图 + LaunchImage + 16KB 真机验证 + HealthKit entitlement + R128a~R128d 跨期验证
**Baseline**: 1.1.0+180, 2728 tests pass / 0 fail / 1 skip, 24 gatekeepers, 1340 ARB keys, R128d step 3 收官 (5 token 转 pub workspace)

## 总体评分

**3.5/10** (持平 R120 baseline, R128a~R128d 0 闭环 iOS 上架硬阻塞 5 P0, R128c HealthKit stub 0 真实集成)

## 核心 Findings

### ✅ 优点 / 强项 (3 项)

| # | 项 | 状态 | 文件 |
|---|---|---|---|
| AS-01 | Info.plist 6 项 permission usage 全在 + 英文基线 + per-locale (zh-Hans/Hant) | ✓ R100/R102/R105 累计 | `ios/Runner/Info.plist:53-73` |
| AS-02 | PrivacyInfo.xcprivacy 5 类必填齐全 + 0 HealthAndFitness (5.1.3 used-but-not-declared 防御) | ✓ R108 + R112 累计 | `ios/Runner/PrivacyInfo.xcprivacy:68-94` |
| AS-03 | Runner.entitlements 空 + 删 aps-environment (声明 0 APNs 远程推送) | ✓ R70 | `ios/Runner/Runner.entitlements:5-12` |
| AS-04 | 5 上架守门员 (check_appstore_screenshots/ios_launchimage/appicon_size/appstore_metadata/domain_icp) | ✓ R117 落地, 资源到位即跑 | `scripts/check_appstore_*.py` |
| AS-05 | LSApplicationCategoryType=healthcare-fitness (R66 + App Store 分类对应) | ✓ | `ios/Runner/Info.plist:151-152` |
| AS-06 | ITSAppUsesNonExemptEncryption=false (R62 标准库加密声明) | ✓ | `ios/Runner/Info.plist:118-119` |
| AS-07 | UIBackgroundModes=audio (R108 恢复, vent 录音后台继续) | ✓ | `ios/Runner/Info.plist:163-166` |
| AS-08 | UIRequiresFullScreen=false (R61 iPad Split View 多任务) | ✓ | `ios/Runner/Info.plist:89-90` |

### ⚠️ 待优化 (6 项)

| # | 项 | 状态 | 文件:行 | 估时 |
|---|---|---|---|---|
| AS-09 | **iOS 截图 0 张** (6.7" + 6.1" + 5.5" 3 套 × 3-5 张) | 🔴 阻塞 AppStore 必须 | `fastlane/metadata/ios/{en-US,zh-Hans,zh-Hant}/` 缺 | 等设计师 |
| AS-10 | **iOS LaunchImage 68B** (缺 1024×1024 + 1242×2688 + 2688×1242) | 🔴 阻塞 AppStore 必须 | `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` 4.5KB | 等设计师 |
| AS-11 | **AppIcon 1024×1024 = 16KB** (< 200KB 守门员阈值 12.5x) | 🔴 阻塞 AppStore 必须 | `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | 等设计师 |
| AS-12 | **chroniccare.app 域名 + 4 邮箱 ICP** (privacy_url / support_url / review 4 TODO) | 🔴 阻塞 | `fastlane/metadata/ios/en-US/privacy_url.txt:1` `[PENDING_DOMAIN]` | 7-20d |
| AS-13 | **4 review_information TODO 占位** (REPLACE_BEFORE_APPLE_REVIEW marker 形式,sanctioned) | 🟡 守门员 warn-only | `fastlane/metadata/ios/review_information/{first_name,last_name,email_address,phone_number}.txt` | 1h (填真实) |
| AS-14 | **5.1.3 抽审 0 启动** (R120 P1-5 跨期 8 round 待) | 🟡 内部可走 | 无文件 | 1-2 周 |
| AS-15 | **pubspec 1.1.0+180 ≠ fastlane notes.txt 1.1.0+168** (落后 12 build) | 🟡 守门员未挂 | `fastlane/metadata/ios/review_information/notes.txt:1` | 0.1h |
| AS-16 | **iOS 16KB 真机验证 0 跑过** (R112 round 8 加 --so-path, 0 实际跑) | 🟡 守门员 [SKIP] | `scripts/check_16kb_alignment.py:20-30` | 2h |

### 🚫 红线 (0 项)

本 lens 跨期 0 引入新红线。emotion-first 0 HealthKit 集成 = 跟 5.1.3 抽审防御天然兼容。

## 跨 Lens 共识 (3 项)

| # | 共识 | 跟谁 |
|---|---|---|
| AS-C1 | **5 P0 跨期残留 8+ round 0 主动动作** = appstore + googleplay 共识 (设计师资产 + 域名 ICP + 5 厂商 push) | Lens 10 |
| AS-C2 | **pubspec vs fastlane 版本号漂移** (1.1.0+180 vs 1.1.0+168) = appstore 跟 superpowers-zh 文档同步漏洞共识 | superpowers-zh |
| AS-C3 | **HealthKit stub 0 真实集成** (R128c 阶段 1) = appstore 跟 apple-health 共识 (5.1.3 抽审防御统一战线) | Lens 11 |

## R128a~R128d 改动验证

| Round | 期望 (iOS 角度) | 实际 | 状态 |
|---|---|---|---|
| **R128a** notification umbrella | 5 厂商 push facade + NoOp 完整 | `lib/core/platform/notification/five_vendor_push_service.dart` 9.7KB, R124 已闭环, 0 回归 | ✓ 0 影响 iOS 上架 |
| **R128b** crisis 5/5 收官 | 5 region i18n 完整, Info.plist 0 变化 | `lib/features/crisis/data/logic/hotline_regions.dart:28-90` 5 region 全 ARB, 0 manifest 变化 | ✓ |
| **R128c** HealthKit stub 骨架 | abstract + NoOp + flag=false, **不**加 iOS entitlement (5.1.3 防御) | `lib/core/platform/health_kit/health_kit_service.dart` 7.5KB, Runner.entitlements 仍空, PrivacyInfo 仍 0 HealthAndFitness | ✓ 5.1.3 防御 100% 闭环 |
| **R128d** 5 token 转 pub workspace | chroniccare_theme 公共 package, iOS 0 变化 | `packages/chroniccare_theme/lib/chroniccare_theme.dart` 5 export, ios/ 0 文件修改 | ✓ |

**R128a~R128d 跨 iOS lens 累计**: 4 round 0 引入 iOS 上架硬阻塞解决, 0 引入 iOS 回归。4 round 是"防御性架构" + "跨期残留 0 解决" 双轨。

## R129+ 建议

| # | 优先级 | 项 | 文件:行 | 估时 | 评分影响 |
|---|---|---|---|---|---|
| 1 | **P0 (外部)** | AS-9~AS-11 设计师资产 (iOS 截图 + LaunchImage + AppIcon) | 等设计师 | 1-2 周 | +0.5 (3.5→4.0) |
| 2 | **P0 (外部)** | AS-12 chroniccare.app 域名 + 4 邮箱 ICP | 域名注册 7-20d | 7-20d | +0.5 (4.0→4.5) |
| 3 | **P1 (内部)** | AS-13 4 review_information 填真实 (上架前必填) | `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` | 0.5h | +0.3 (4.5→4.8) |
| 4 | **P1 (内部)** | AS-15 pubspec vs notes.txt 同步 (1.1.0+180 → notes.txt) | `fastlane/metadata/ios/review_information/notes.txt:1` | 0.1h | +0.1 |
| 5 | **P1 (内部)** | AS-16 iOS 16KB 真机 objdump 验证 (--so-path) | `scripts/check_16kb_alignment.py` 跑 `flutter build ios --release` + objdump | 2h | +0.2 |
| 6 | **P1 (内部)** | AS-14 5.1.3 抽审 4 文档准备 (PHQ-9/GAD-7 法务 + 临床审核) | 4 文档起草 (跟 R120 P1-5 一致) | 1-2 周 | +0.3 |
| 7 | **P2 (长期)** | iPad 12.9" 截图 + multitasking 验证 (R31 跨期 0 改) | 等 AS-9 资源 | 1-2 周 | +0.2 |
| 8 | **P2 (跨期)** | 5 厂商 push 真接 (R124 阶段 2, 1-2 月) + APNs entitlement | `pubspec.yaml` + `Runner.entitlements` | 1-2 月 | +0.5 |

**R129 hotfix (1 周)**: P1-3~P1-6 估时 4h, 评分 3.5 → 4.5 (+1.0)
**R129 + 设计师资产 (1-2 周)**: P0-1 估时 0, 评分 4.5 → 5.0 (+0.5)
**R129 + 域名 ICP (7-20d)**: P0-2 估时 0, 评分 5.0 → 5.5 (+0.5)
**R1.0 (2027-Q1, 5 厂商 push + HealthKit 真接)**: 估时 1-2 月, 评分 5.5 → 6.5+ (+1.0)

> **iOS 上架根本问题**: emotion-first 定位 (1.1.0 round 4b) 删 HealthKit/ResearchKit 是设计选择, 不是工程疏漏。R128c 阶段 1 stub 0 真实集成是"5-6 月后真接"的工程节奏, 不是上架硬阻塞根因。**真正根因 = 5 P0 跨期残留 0 主动动作** (设计师资产 + 域名 ICP + 5 厂商 push)。R120 路线图 5 P0 等外部, R128a~R128d 跨 4 round 0 主动推进, 是 R121 路线图 Focus 维度 7/10 单一节奏拖累的延续。
