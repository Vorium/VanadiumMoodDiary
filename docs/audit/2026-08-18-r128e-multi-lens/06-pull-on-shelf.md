# Lens 6: pull-on-shelf (上架前 P0/P1 checklist + 业务完整性)

**Date**: 2026-08-18
**Scope**: AppStore + Google Play 上架前硬阻塞 + metadata + 5.1.3 抽审 + 业务收尾
**Baseline**: 1.1.0+185, 2728 tests pass, 24 gatekeepers (R128d pub workspace +3)

## 总体评分

**4.0/10** (R120 持平,**7 P0 跨期残留 0 闭环** + 1 项 P0 notes.txt 版本回归 [R128e 新发现] 拉分)

## 上架硬阻塞 (P0 跨期残留, 7 项 — 0 闭环)

| # | 项 | 阻塞 | 资源 | 预计 | 状态 |
|---|---|---|---|---|---|
| **PS-1** | iOS 截图 0 张 (`fastlane/metadata/ios/*/screenshots/` 目录不存在) | AppStore 必须 | 设计师 | - | 阻塞 6 round |
| **PS-2** | iOS LaunchImage 缺 3 张 (1024×1024 / 1242×2688 / 2688×1242),当前 `LaunchImage.imageset` 仅 3 张小尺寸占位 | AppStore 必须 | 设计师 | - | 阻塞 6 round |
| **PS-3** | Android 截图 67B × 4 + feature_graphic 28KB (R128e 实测:`-rw-r--r-- 28403 Aug 17`),icon 13KB 异常小 | Google Play 必须 | 设计师 | - | 阻塞 6 round |
| **PS-4** | chroniccare.app 域名 + 4 邮箱 (privacy@ / legal@ / support@ / abuse@) 0 注册,`check_domain_icp.py` 1 项 FAIL | 失联通道 | 域名商 | 7-20d | 阻塞 6 round |
| **PS-5** | AppIcon 1024×1024 = 16332B (16KB,R128e 实测),Apple 要求 ≥ 200KB;其余 15 个 icon 尺寸 282B-4248B 异常小 | AppStore 必须 | 设计师 | - | 阻塞 6 round |
| **PS-6** | 5 厂商 push SDK (米/华/OPP/vivo/魅族) 0 真接,R124 facade 后仍 NoOp (`FeatureFlags.fiveVendorPushEnabled=false`) | 国产 ROM 通知 | 5 厂商 | 1-2 月 | 阻塞 6 round |
| **PS-7** | 阿里云 SMS 0 接入 (1.1.0 round 4b 已删 `aliyunSmsEnabled` flag,失联通知 100% 失效) | 失联通知 | 阿里云 | 1-2 月 | 阻塞 6 round |

> **脚本就绪**: 5 个上架检查脚本在 `scripts/` (iOS 截图 / Android 截图 / LaunchImage / 域名 ICP / AppIcon),全 FAIL,等 PS-1~PS-5 资源到位直接跑

## P0 新发现 (R128e 实测, 1 项回归)

| # | 项 | 阻塞 | 修复 | 估时 |
|---|---|---|---|---|
| **PS-19** | **`fastlane/metadata/ios/review_information/notes.txt:1` 版本 `1.1.0+168` ≠ pubspec `1.1.0+180` ≠ master `1.1.0+185`** | `check_review_information_todo.py` 1 项 FAIL (R32 P0-02 回归) | 改 `notes.txt` 头部 `ChronicCare 1.1.0+185` | 0.1h |

## 5.1.3 抽审 (3 项, 1 项 P0 阻断)

| # | 项 | 状态 | 修复 |
|---|---|---|---|
| **PS-8** | `description.txt` 5.1.1 (敏感 App) 抽审 — en/zh-Hans/zh-Hant 三语中性化 (R111 AS-17) | ✅ 已闭环 | — |
| **PS-9** | `review_information` 4 TODO 占位 (first_name / last_name / email_address / phone_number) 走 placeholder 标记 | ⚠️ 守门员 PASS 但仍占位,上架前必填真实信息 | 域名注册后填 4 文件 + 跑 `check_review_information_todo.py` |
| **PS-10** | `notes.txt` 版本号同步 | **❌ 回归 R128e 新发现 PS-19** | 0.1h |

## 7 个上架守门员 FAIL 状态 (R128e 实测)

| 守门员 | 状态 | 详情 |
|---|---|---|
| `check_appstore_screenshots.py` | ❌ FAIL | iOS 截图目录不存在 (`fastlane/metadata/ios/screenshots`) |
| `check_ios_launchimage.py` | ❌ FAIL | 3 项缺失 (1024×1024 / 1242×2688 / 2688×1242) |
| `check_appicon_size.py` | ❌ FAIL | 2 项 (AppIcon 16KB < 200KB + 缺 `icon-1024.png`) |
| `check_appstore_metadata.py` | ❌ FAIL | 3 项 (`review_information.txt` / `notes.txt` / `description.txt` 缺失根目录副本) |
| `check_domain_icp.py` | ❌ FAIL | 4/4 邮箱缺失 |
| `check_16kb_alignment.py` | ⚠️ SKIP | pubspec + build.gradle OK,产物 .aab 验 SKIP (待 CI) |
| `check_review_information_todo.py` | ❌ FAIL | 1 项 (notes.txt 版本 1.1.0+168 ≠ 1.1.0+180) |

## 已闭环上架项 (8 项, R31 R108 R115 R128 累计)

| # | 项 | 状态 |
|---|---|---|
| PS-11 | 6 Android 权限白名单 | ✅ |
| PS-12 | 4 iOS usage description 白名单 | ✅ |
| PS-13 | 隐私政策 3 文档 `assets/legal/` | ✅ |
| PS-14 | PIPL §13 单独同意 (`check_legal_consent.py`) | ✅ |
| PS-15 | 24 守门员 24 全绿 (除 5 上架脚本 expected fail + 16KB SKIP) | ✅ |
| PS-16 | 0 网络外联 (`check_no_network_io.py` 0 violation + `check_release_no_network.py` 0) | ✅ |
| PS-17 | 锁屏 PII 净化 (`check_pii_in_title.py` 0 + `check_pii_in_assets.py` 0) | ✅ **G-1 iOS DarwinNotificationDetails `presentAlert: false` 漏 3 处待 G-Fix-1** |
| PS-18 | review_information TODO 守门员 (`check_review_information_todo.py`) | ⚠️ PS-19 notes.txt 1 项 FAIL |

## 业务收尾 (4 红线 100% 闭环 ✅)

| 红线 | 守门员 | 状态 |
|---|---|---|
| 树洞 (vent) 内容不进 trend / 评估 / 通知 / 关怀 | `check_cross_feature.py` 167 file 0 violation | ✅ |
| 情绪 (mood) 0 通知 | lib/ grep `mood.*Notification` 0 业务通知 | ✅ (R110 round 6 闭环) |
| 评估 (assessment) 0 外部通知 | lib/ grep `assessment.*RemotePush` 0 | ✅ |
| 打卡 (check-in) 0 评估 | lib/ grep `checkIn.*Assessment` 0 | ✅ |

## FeatureFlag 编译期锁定 (4 flag, 1.1.0 round 4b 后)

| Flag | 状态 | 影响范围 |
|---|---|---|
| `ventAudioEnabled=true` | ✅ prod true | vent_compose_page + mood_recorder_page mic 录音 |
| `fiveVendorPushEnabled=false` | ⏳ 等 1-2 月 SDK | NotificationStatusCard 隐藏"5 厂商自检" |
| `phqGad7I18nEnabled=false` | ⏳ 等法务 + 临床审核 | PHQ-9 / GAD-7 16 题 i18n fallback |
| `bootReceiverEnabled=false` | ⏳ 等 WorkManager 完善 | NotificationInitializer 跳过设备重启重排 |
| `healthKitEnabled=false` (R128c 新增) | ⏳ 5-6 月真接 | HealthKitService NoOp,0 副作用 |

## 跨 Lens 共识 (3 项)

- **跟 superpowers-zh**: PS-1~PS-7 7 P0 跨期残留 + PS-19 notes.txt 1 项回归 = "上架硬阻塞 0% 闭环" 跨 6 round 共识
- **跟 gdc-audit**: PS-1~PS-5 实物资产 = G-Redline-1 iOS 16KB 0 真机验证同根因(设计师资源 + CI 验证全缺)
- **跟 Apple Health**: PS-6~PS-7 5 厂商 push + 阿里云 SMS = Apple Health 0 集成跨期残留,v1.0 长期

## R128a~R128d 改动验证

| 指标 | 期望 | 实际 | Δ |
|---|---|---|---|
| HealthKit stub + flag + 守门员修真 (R128c) | 5-6 月真接前 0 阻塞上架 | ✅ 204L 4 段式 stub + flag false + 守门员 3 规则 | 100% |
| crisis 5/5 收官 (R128b) | 5 region i18n (zh/en/zh-Hant × 11 key) | ✅ `crisisHotlineCn/Tw/Hk/Mo/...` 5 region × 3 ARB × 11 key = 165 entry | 100% |
| notification umbrella (R128a) | 跨 feature 共享平台抽象 | ✅ 7 file 1538L | 100% |
| 5 token 集中器转 pub workspace (R128d) | chroniccare_theme 4th member | ✅ 1.1.0+184 | 100% |
| PIPL §13 / §14 隐私边界 (R128c 副作用) | HealthKit 0 采集已声明 | ✅ R108 删 HealthAndFitness + R112 删 ContactInfo | 100% |
| **5 实物资产状态** (PS-1~PS-5) | 设计师出图 | ✗ 6 round 0 启动 | 0% |
| **5 厂商 push + 阿里云 SMS** (PS-6~PS-7) | 1-2 月真接 | ✗ 仍 NoOp | 0% |
| **慢性病.app 域名 + 4 邮箱** (PS-4) | 7-20d ICP | ✗ 0 启动 | 0% |
| **notes.txt 版本同步** (PS-19 R128e 新发现) | 1.1.0+185 | ✗ 1.1.0+168 (R32 P0-02 回归) | 0% |

**R128 路线图进度 (pull-on-shelf 维度)**: 4/9 (44%) — 平台抽象 + i18n + 守门员修真 100%,**7 P0 跨期 0 闭环 + 1 P0 回归 0%**。

## R129+ 建议 (按优先级, 7 项)

| # | 项 | 文件:行 | 估时 | 估评分影响 |
|---|---|---|---|---|
| **PS-Fix-1** | `notes.txt` 同步 master 版本 `1.1.0+185` (R128e 新发现 PS-19 回归) | `fastlane/metadata/ios/review_information/notes.txt:1` | 0.1h | +0.2 |
| **PS-Fix-2** | iOS 3 处 DarwinNotificationDetails 加 `presentAlert: false` (锁屏禁显示) | `lib/core/platform/notification/notification_service.dart:172` 等 3 处 | 0.5h | +0.3 (跨 gdc-audit) |
| **PS-Fix-3** | iOS 16KB 真机 build + objdump 验 segment ≥ 16384 (上架前 1 周必跑) | `scripts/check_16kb_alignment.py --aab <path>` (改 SKIP → FAIL 强校验) | 2h | +0.5 |
| **PS-Fix-4** | 设计师出图 PS-1~PS-5 (iOS 截图 / LaunchImage / AppIcon 1024×1024 ≥ 200KB + Android 截图 / feature_graphic) | `fastlane/metadata/{ios,android}/*/screenshots/`, `ios/Runner/Assets.xcassets/{AppIcon,LaunchImage}.imageset/` | 外部 | +1.0 |
| **PS-Fix-5** | chroniccare.app 域名注册 + 4 邮箱 (privacy@ / legal@ / support@ / abuse@) + DNS 配 4 路由 + 4 法务 md 文档顶部"正式 URL"标识 | `fastlane/metadata/{ios,android}/*/{privacy,support}_url.txt` (10 file) | 7-20d 外部 | +0.8 |
| **PS-Fix-6** | 5 厂商 push SDK 真接 (米/华/OPP/vivo/魅族) + 1.0 flip `fiveVendorPushEnabled=true` | `pubspec.yaml` 5 依赖 + `lib/core/platform/notification/five_vendor_push_service.dart` (NoOp → 真接 impl) | 1-2 月外部 | +0.5 |
| **PS-Fix-7** | 阿里云 SMS 真接 + flip `aliyunSmsEnabled=true` (1.1.0 round 4b 已删 flag,需先恢复) | `pubspec.yaml` aliyun_sms 依赖 + 1 flag 恢复 | 1-2 月外部 | +0.3 |

**R129 闭环后估分 (短平快部分)**:
- PS-Fix-1 + PS-Fix-2 + PS-Fix-3: 4.0 → 5.0/10 (+1.0, 全 0.1~2h 可闭环)
- + PS-Fix-4 + PS-Fix-5 (外部资源): 5.0 → 7.0/10 (+2.0, 设计师 + 域名商就绪即可)
- + PS-Fix-6 + PS-Fix-7 (1-2 月外部): 7.0 → 7.8/10 (+0.8)
- v1.0 长期闭环: 7.8 → 8.5/10 (HealthKit + 鸿蒙 + 5 厂商 push + 阿里云 SMS 全真接)
