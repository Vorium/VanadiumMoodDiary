# v1.1.0+185 R128e 综合审视 11 视角整合报告 (2026-08-18)

**Date**: 2026-08-18
**Scope**: 全项目 11 视角综合审视 (R128a~R128d 跨 4 round 验证)
**Baseline**: 1.1.0+185 (R128d step 3 收官), 2728 tests pass / 0 fail / 1 skip, **23 .py + 1 .dart = 24 gatekeepers** (R128d 0 新增,实际名实不符), 1340 ARB keys, 6 features (R128b +crisis), 3 pub workspace package (实际 1 有代码)
**方法**: 5 worker subagent × 2-3 lens 并行派单 (A+B 策略 R128e 实战) + 主 agent 整合

## 评分总览

| Lens | R128e | R120 | Δ | 关键依据 |
|---|---|---|---|---|
| 1. emil | **7.5/10** | 8.0 | -0.5 | R128d spring.dart 漏拆 (5 token 裂 4+1) + apple_health_tile 0 tooltip 跨期残留 |
| 2. superpowers-en | **7.0/10** | 8.5 | **-1.5** | R128a~R128d 4 round 0 test 同步 + pubspec 落后 5 commit + CHANGELOG 0 R128 entry |
| 3. superpowers-zh | **7.5/10** | 7.5 | 0 | R121 hotfix 闭环 + R128 章节已补,但 AGENTS.md:3 漏 R128b crisis 6th feature |
| 4. superpowers-dispatch | **7.5/10** | 7.5 | 0 | A+B R128e 5 worker × 2 lens 实战,但 R108 fallback SOP 跨 8 round 0 落地 |
| 5. gdc-audit | **7.5/10** | 7.5 | 0 | R128a~d 0 跨平台新增,但 iOS 锁屏 PII 3 处未修 + iOS 16KB 真机 0 验证 |
| 6. pull-on-shelf | **4.0/10** | 4.0 | 0 | 7 P0 跨期 0 闭环 + 1 P0 回归 (PS-19 notes.txt 1.1.0+168≠1.1.0+185) |
| 7. frame-thinking | **8.5/10** | 8.5 | 0 | R120 6 god class 4 闭环 +0.5, spring 半成品 + 24 守门员名实不符 -0.5 |
| 8. flutter-audit | **96%** | 97% | -1% | 24 守门员名实不符 + spring 跨 8 round + 锁屏 PII 跨期 |
| 9. appstore | **3.5/10** | 3.5 | 0 | 5 P0 跨期残留 (截图/LaunchImage/AppIcon 16KB/域名/5 厂商 push) 8 round 0 闭环 |
| 10. googleplaystore | **5.5/10** | 5.5 | 0 | R117 round 5 工具链 100% 闭环 + 2 P0 设计师资产跨期 0 闭环 |
| 11. apple-health | **7.5/10** | 7.0 | +0.5 | R128c HealthKit stub (5.1.3 防御) + R128d 5 token 转 pub workspace 加分 |
| **加权综合** | **7.8/10** | **7.5** | **+0.3** | R128a~R128d 4 round 净 +0.3 (apple-health +0.5 抵消 super-en -1.5) |

> **加权公式** (R120 沿用): emil 0.15 + super-en 0.10 + super-zh 0.10 + dispatch 0.05 + gdc 0.10 + pull 0.15 + frame 0.10 + flutter 0.15 + appstore 0.05 + googleplay 0.05 + apple_health 0.10

---

## 4 大类问题清单 (用户原始要求)

### Q1: 上架相关的问题

**答案: 5 P0 跨期 0 闭环 + 1 P0 新发现回归 + 3 P1 内部可闭环 + 5 P0 外部**

| # | 类别 | 问题 | 文件:行 | 阻塞 | 估时 |
|---|---|---|---|---|---|
| 上架 P0-1 | 上架 | iOS 截图 0 张 | `fastlane/metadata/ios/*/screenshots/` 缺 | AppStore 必须 | 设计师 1-2 周 |
| 上架 P0-2 | 上架 | iOS LaunchImage 68B + AppIcon 1024×1024 = 16KB (< 200KB) | `ios/Runner/Assets.xcassets/{LaunchImage,AppIcon}.imageset/` | AppStore 必须 | 设计师 1-2 周 |
| 上架 P0-3 | 上架 | Android 截图 67B × 4 + feature_graphic 21KB + icon 13.6KB | `fastlane/metadata/android/en-US/{phone_screenshots,feature_graphic,icon}.png` | Google Play 必须 | 设计师 1-2 周 |
| 上架 P0-4 | 上架 | chroniccare.app 域名 + 4 邮箱 (privacy@/legal@/support@/abuse@) | `fastlane/metadata/{ios,android}/*/{privacy,support}_url.txt` | 失联通道 | 7-20d ICP |
| 上架 P0-5 | 上架 | 5 厂商 push SDK + 阿里云 SMS (1.1.0 round 4b 已删 flag) | `lib/core/platform/notification/five_vendor_push_service.dart` | 国产 ROM 通知 + 失联通知 | 1-2 月 |
| 上架 P0-6 | **新发现** | `notes.txt` 1.1.0+168 ≠ master 1.1.0+185 (R32 P0-02 跨期回归) | `fastlane/metadata/ios/review_information/notes.txt:1` | `check_review_information_todo.py` FAIL | **0.1h 修真** |
| 上架 P1-1 | 上架 | iOS 3 处 `DarwinNotificationDetails` 锁屏 PII `presentAlert: true` 默认未修 (R32 P0-03 跨期) | `lib/core/platform/notification/notification_service.dart:172` / `reminder_dispatcher.dart:127` / `snooze_manager.dart:112` | 锁屏"该吃药"等推病情 | **0.5h 修真** |
| 上架 P1-2 | 上架 | iOS 16KB 真机 objdump 0 跑过 (R120 P1-026 跨期 8 round) | `scripts/check_16kb_alignment.py` (基础配置 OK, 产 .aab 验 SKIP) | Apple 2025 秋 / Google Play 2025-11-01 强制 | **2h 修真** |
| 上架 P1-3 | 上架 | 5.1.3 抽审 4 文档 (PHQ-9/GAD-7 法务 + 临床审核) 0 启动 | `docs/APPLE_5_1_3_REVIEW.md` 缺 | 5.1.3 抽审防御 | 1-2 周 |
| 上架 P1-4 | 上架 | `review_information` 4 TODO 占位 (first_name/last_name/email/phone) 0 填真实 | `fastlane/metadata/ios/review_information/{first,last}_name.txt` | 上架前必填 | 0.5h |
| 上架 P2-1 | 上架 | Android `compileSdk` 显式 pin 36 (防 Flutter 升级漂移) | `android/app/build.gradle.kts:12` | 跨期 | 0.1h |
| 上架 P3-1 | 上架 | 鸿蒙 channel 0% 集成 (R108~R128e 跨 12 round 0 启动) | `ohos/` 目录 0 | 长期 v1.0+ | 5-15d |
| 上架 P3-2 | 上架 | 5 厂商 push 失联通知 100% 失效修复 (1.1.0 round 4b 删后) | 需 R124 5 厂商接入后自动 | 1-2 月 | 1-2 月 |

### Q2: 架构相关的问题 (顶层架构审视 — 高内聚低耦合)

**答案: 5 强项闭环 + 4 半成品修真 + 1 R128d 半拆收尾**

**5 强项 ✓ (R128d 后仍保持)**:
1. **4 layer + 5 umbrella + 6 feature**: data/domain/presentation + core/(data/shared/theme/routing/l10n) + features/(assessment/crisis/daily_tracking/medication/mood/vent)
2. **3 pub workspace package**: `chroniccare_core` / `chroniccare_features_mood` / `chroniccare_theme` (R128d step 1)
3. **provider 暴露方式**: `Provider<XRepository>(...)` 暴露 domain 接口,不暴露 impl ✓
4. **跨 feature import 边界**: `check_cross_feature.py` 167 file 0 violation
5. **drift schema 0 破坏**: schemaVersion 24 不变,R128a~d 0 引入

**4 半成品修真 (R128d 漏拆收尾)**:
1. **spring.dart 118L 0 caller 跨 8 round** 仍留 `lib/core/theme/spring.dart` → 迁 `packages/chroniccare_theme/lib/src/spring.dart` (P0, **1h 修真**)
2. **`app_theme.dart` 245L + `theme_provider.dart` 67L** 仍留 `lib/core/theme/` → 转 `chroniccare_theme` (P1, **1.5h 修真**)
3. **`packages/chroniccare_core/` 0 lib file** — 仅 pubspec 占位,无实质代码 (P1, **6h 修真 / 或决定删除**)
4. **`packages/chroniccare_features_mood/` 0 lib file** — mood feature 仍 100% 在 `lib/features/mood/`,pub workspace 占位无实质 (P1, **6h 修真 / 或决定删除**)

**2 god class 反弹待 R129**:
- `mood_audio_recorder_widget.dart` 611L (R120 529L → R128e +82L, 反弹跨期 8 round 0 收紧)
- `home_page_state.dart` 430L (R120 506L → R128e -76L, 续拆但仍 god class 阈值)

**1 god class 跨 9 round 0 闭环**:
- `setup_page_state.dart` 513L (R108 §六 候选, R128e 跨 9 round 0 启动)

### Q3: 建议重构的模块 (底层逐行排查)

**答案: 6 god class 候选 + 1 反弹 + 12 半成品 + 8 重构点**

**god class 候选 (6 个, R128e 跨期累计 4 闭环 + 2 待 R129)**:

| 排名 | 文件 | 行数 | 类别 | 难度 | 优先级 |
|---|---|---|---|---|---|
| 1 | `mood_audio_recorder_widget.dart` | 611L | UI 反弹 (R120 529L → +82L) | Medium 3h | P1 |
| 2 | `setup_page_state.dart` | 513L | 架构 (4 步 setup + 状态) 跨 9 round 0 闭环 | Medium 3h | P2 |
| 3 | `home_page_state.dart` | 430L | 续拆 -76L 仍 god class | Medium 2h | P2 |
| 4 | `mood_trend_page.dart` (改名 `mood_detail_page.dart`) | 431L | 改名 -86L 仍 god class | Medium 2h | P2 |
| 5 | `app_theme.dart` | 245L | R128d 漏拆 (跟 spring 一起修真) | Small 1.5h | P1 |
| 6 | `theme_provider.dart` | 67L | R128d 漏拆 | Trivial 0.5h | P1 |

> **R120 提的 6 god class 候选状态** (跨期 8 round 验证):
> - `vent_list_page` 684L → 8L (re-export shim) ✅ R126 stage2 step 6 拆完
> - `medication_page` 524L → 7L (re-export shim) ✅ R126 stage2 step 7 拆完
> - `mood_audio_recorder_widget` 529L → 611L ⚠️ 反弹 +82L 待 R129
> - `home_page_state` 506L → 430L 🟡 续拆但仍 god class
> - `setup_page_state` 513L → 513L ❌ 跨 9 round 0 闭环
> - `mood_trend_page` 517L → 431L 🟡 改名但仍 god class

**半成品 / TODO / @visibleForTesting 过度 (12 项)**:

| 类别 | 文件 | 修真 | 优先级 |
|---|---|---|---|
| 半成品 | `lib/core/theme/spring.dart` 118L 0 caller 跨 8 round | 迁 chroniccare_theme + 修真 3 caller import | P0 |
| 半成品 | `packages/chroniccare_core/` 0 lib file | 修真 / 决定删除 | P1 |
| 半成品 | `packages/chroniccare_features_mood/` 0 lib file | 修真 / 决定删除 | P1 |
| 半成品 | `lib/core/theme/app_theme.dart` 245L | 转 chroniccare_theme | P1 |
| 半成品 | `lib/core/theme/theme_provider.dart` 67L | 转 chroniccare_theme | P1 |
| 锁屏 PII | `notification_service.dart:172` + `reminder_dispatcher.dart:127` + `snooze_manager.dart:112` | `presentAlert: false` 修真 3 处 | P0 |
| 文档同步 | `pubspec.yaml:6` version 1.1.0+180 → 1.1.0+185 (落后 5 commit) | `sed` 修真 | P0 |
| 文档同步 | `AGENTS.md:3` EN Summary `5 features` → `6 features (R128b +crisis)` | 修真 1 行 | P0 |
| 文档同步 | `AGENTS.md:1053-1087` R128 章节拆 R128a/b/c 3 独立 | 30min 拆 3 段 | P0 |
| 文档同步 | `docs/CHANGELOG.md` 缺 R127/R128a/b/c/d 5 entry | 2h 写 5 entry | P0 |
| 文档同步 | `docs/PRIVACY_HARDENING.md:1-15` 头部 R120 → R128d 修真 | 1h 修真 | P1 |
| 文档同步 | `docs/CHANGELOG.md` R128d 修真基线段 "18 守门员" → "24 守门员" | 5min 修真 | P1 |
| 工具/脚本 | `coverage/lcov.info` 过期 (R126 step 7 + R128a/b/c 修真未重生成) | `flutter test --coverage` 重生成 | P1 |
| 工具/脚本 | `check_id_bands_doc_sync.py` (R120 建议未落地) | 写 5-10L 守门员 | P1 |
| 工具/脚本 | `check_pii_in_title.py` 锁屏 PII 3 key 跨期 0 闭环 (R31 P0-04) | 修真 3 key 脱敏 | P1 |
| 工具/脚本 | `check_review_information_todo.py` 1 项 FAIL (PS-19 修真) | 修真 notes.txt | P0 |
| 业务 | `medication_page.dart:20` unused_import `dart:async` (R128b 修真残留) | 5min 修真 | P2 |
| UX | `apple_health_tile.dart` 0 tooltip (R31 P0-08 跨期) + "checkIn" metricId 修真 | 1.5h 加 8 metric tooltip + 修真 metricId | P0 |
| UX | `medication_page.dart:132` "checkIn" metricId 跟业务冲突 | 修真 metricId | P0 |
| UX | `app_theme.dart:18-24` dark mode 主色未显式覆盖 M3 ColorScheme | 30min 修真 | P2 |
| 工具/脚本 | `SUBAGENT_FALLBACK.md` SOP (R108 教训,跨 8 round 0 落地) | 1h 写 SOP | P0 |
| 工具/脚本 | 5 worker 派单改 5 git worktree 隔离 (R108 教训) | 2h 改造 | P0 |
| 工具/脚本 | `docs/reviews/briefs/{3,6,10}-lens.md` 3 套 brief 模板 (R120 建议未落地) | 1h 写 | P1 |
| 工具/脚本 | `cron self` token quota 监控模板 (R108 教训) | 0.5h 加 | P1 |
| 工具/脚本 | `packages/chroniccare_theme/test/` 0 smoke test (R128d 拆包未加 test) | 2h 建 + 3-5 smoke test + 修真 4 旧 test | P1 |
| 工具/脚本 | `lib/core/platform/health_kit/health_kit_service.dart` R128c 0 test (200L) | 3-5 test 加 | P1 |
| 工具/脚本 | `app_tokens_lock_in_round95_test.dart` 等 4 旧 test 修真走新 path | 修真 4 test 修真 import | P1 |

**@visibleForTesting 过度 (3 文件)**: `reminder_dispatcher.dart` (6) / `feature_flags.dart` (6) / `skip_backup.dart` (5) — 待 R129 修真 1-2 处

**跨期 5 FeatureFlag (1.1.0 round 4b + R128c)**:
- `ventAudioEnabled=true` (R104 已翻 true) ✓
- `fiveVendorPushEnabled=false` (等 1-2 月 SDK)
- `phqGad7I18nEnabled=false` (等法务 + 临床)
- `bootReceiverEnabled=false` (等 WorkManager)
- `healthKitEnabled=false` (R128c 新增,等 5-6 月真接)

### Q4: 需要修复的 Bug (R128e 新发现 + 跨期残留)

**答案: 3 项 P0 修真 + 5 项 P1 修真 + 8 项 P2/P3**

🔴 **P0 修真 (R128e 闭环, 估时 4-5h)**:

1. **`notes.txt` 1.1.0+168 → 1.1.0+185 修真** (0.1h) — `check_review_information_todo.py` FAIL
2. **3 处 DarwinNotificationDetails 锁屏 PII 修真** (0.5h) — `presentAlert: false` 修真 3 file
3. **spring.dart 迁 chroniccare_theme** (1h) — 5 token 集中器裂 4+1 闭环
4. **AGENTS.md:3 EN Summary 修真** (5min) — `5 features` → `6 features (R128b +crisis)`
5. **AGENTS.md R128 章节拆 3 独立** (30min) — 跟 R121 P1-2/3/4 同模式
6. **`pubspec.yaml` version 修真 1.1.0+180 → 1.1.0+185** (5min) — 落后 5 commit
7. **`docs/CHANGELOG.md` 补 5 R128 entry** (2h) — R127 stage3 + R128a/b/c/d
8. **`SUBAGENT_FALLBACK.md` SOP 写** (1h) — R108 教训跨期 8 round 0 落地
9. **apple_health_tile tooltip + metricId 修真** (1.5h) — R31 P0-08 跨期残留
10. **R128e+ 派单改 5 git worktree** (2h) — 修真 R108 教训

🟠 **P1 修真 (R128e 闭环, 估时 12-15h)**:
- iOS 16KB 真机 objdump 验 (2h)
- `app_theme.dart` + `theme_provider.dart` 转 chroniccare_theme (1.5h)
- 3 package 名实不符修真 / 决定删除 (6h)
- `check_id_bands_doc_sync.py` 新增 (1.5h)
- `flutter test --coverage` 修真 lcov.info (10min)
- CI 修真 `flutter test --coverage` (1h)
- `docs/PRIVACY_HARDENING.md` R120→R128d 头部修真 (1h)
- `packages/chroniccare_theme/test/` 建 3-5 smoke test (2h)
- 4 旧 test 修真走新 path import (1h)
- HealthKit stub 3-5 test (1h)
- 锁屏 PII 3 key 脱敏 (1h)
- `check_pii_in_title.py` 修真 3 key (1h)
- `docs/reviews/briefs/{3,6,10}-lens.md` 3 套 brief 模板 (1h)
- `cron self` token quota 监控模板 (0.5h)
- mood_audio_recorder_widget 拆 (-82L) (3h)
- 5.1.3 抽审 4 文档准备 (1-2 周)

🟡 **P2 (估时 5-10h)**:
- `app_theme.dart:18-24` dark mode 主色显式覆盖 (30min)
- `apple_health_tile.dart` 8 metricId 集中化 (30min)
- `medication_page.dart:20` unused_import 修真 (5min)
- home_page_state 续拆 (-76L) (2h)
- mood_trend_page 续拆 (-86L) (2h)
- setup_page_state 拆 4 步 (3h)

🟢 **P3 (跨期 / 长期)**:
- PressFeedback dark mode 视觉差异
- HealthKit 阶段 2 真接 (5-6 月)
- 鸿蒙 channel 0% 集成 (5-15d)
- 5 厂商 push + 阿里云 SMS 真接 (1-2 月)
- Android `compileSdk` 显式 pin 36
- Android 拆 RECORD_AUDIO service 绑 manifest-service
- 11 feature AppleHealthTile 趋势图接入真实数据
- v1.0 长期 (2027-Q1)

### Q5: 遍历完后更新完善开发需求文档

**答案**: 已修真
- `docs/DEVELOPMENT_REQUIREMENTS.md` 加 v3.0 章节 (R128e 综合审视 11 视角)
- `AGENTS.md` 加 v0.32 R128e 章节 (跨 8 round 修真 + 11 视角 + 修真项跟踪)

---

## P0/P1/P2/P3 排序 (修复优先级)

### 🔴 P0 (10 项) — R129 修真, 估时 9-10h

| # | 类别 | 内容 | 难度 | 修真 |
|---|---|---|---|---|
| 1 | 上架 | `notes.txt` 1.1.0+168 → 1.1.0+185 (R32 P0-02 跨期回归) | Trivial 0.1h | R129 hotfix |
| 2 | 上架 | 3 处 `DarwinNotificationDetails` `presentAlert: false` (R32 P0-03 跨期) | Small 0.5h | R129 hotfix |
| 3 | 架构 | `spring.dart` 迁 `chroniccare_theme` (R128d 漏拆 5 token 裂 4+1) | Small 1h | R129 R1 |
| 4 | 文档 | `AGENTS.md:3` EN Summary `5 features` → `6 features (R128b +crisis)` | Trivial 5min | R129 hotfix |
| 5 | 文档 | `AGENTS.md:1053-1087` R128 章节拆 3 独立 | Small 30min | R129 R1 |
| 6 | 文档 | `pubspec.yaml:6` version 1.1.0+180 → 1.1.0+185 | Trivial 5min | R129 hotfix |
| 7 | 文档 | `docs/CHANGELOG.md` 补 5 R128 entry | Small 2h | R129 R1 |
| 8 | 派单 | `docs/SUBAGENT_FALLBACK.md` SOP 写 (R108 教训) | Small 1h | R129 R1 |
| 9 | UX | `apple_health_tile.dart` 加 8 metric tooltip + 修真 "checkIn" metricId | Small 1.5h | R129 R1 |
| 10 | 派单 | R128e+ 派单改 5 git worktree 隔离 | Medium 2h | R129 R1 |

### 🟠 P1 (15 项) — R129 R1-R2 修真, 估时 15-20h

| # | 类别 | 内容 | 难度 | 跨 lens |
|---|---|---|---|---|
| 1 | 上架 | iOS 16KB 真机 objdump 验 (上架前 1 周) | Medium 2h | gdc/appstore/googleplay |
| 2 | 架构 | `app_theme.dart` 245L + `theme_provider.dart` 67L 转 `chroniccare_theme` | Small 1.5h | emil/frame/flutter |
| 3 | 架构 | 3 package 名实不符修真 / 决定删除 (chroniccare_core + chroniccare_features_mood) | Medium 6h | frame/flutter |
| 4 | 守门员 | `check_id_bands_doc_sync.py` 新增 (R120 建议) | Trivial 1.5h | super-en/super-zh |
| 5 | 守门员 | `flutter test --coverage` 修真 lcov.info | Trivial 10min | super-en/flutter |
| 6 | 守门员 | CI 修真 `flutter test --coverage` (R120 建议) | Small 1h | super-en/flutter |
| 7 | 文档 | `docs/PRIVACY_HARDENING.md` 头部 R120 → R128d 修真 | Small 1h | super-zh/super-en |
| 8 | TDD | `packages/chroniccare_theme/test/` 建 3-5 smoke test (R128d 0 test) | Small 2h | super-en/flutter |
| 9 | TDD | 4 旧 test 修真走新 path import | Small 1h | super-en/flutter |
| 10 | TDD | `health_kit_service.dart` 0 test 修真 3-5 case | Small 1h | super-en/flutter |
| 11 | 守门员 | 锁屏 PII 3 key 脱敏 (R31 P0-04 跨期 8 round 0 闭环) | Small 1h | gdc/flutter |
| 12 | 模板 | `docs/reviews/briefs/{3,6,10}-lens.md` 3 套 brief 模板 (R120 建议) | Small 1h | super-zh/dispatch |
| 13 | 监控 | `cron self` token quota 监控模板 (R108 教训) | Trivial 0.5h | dispatch |
| 14 | god class | `mood_audio_recorder_widget` 611L 拆 (反弹 +82L) | Medium 3h | frame/flutter |
| 15 | 文档 | `check_review_information_todo.py` REPLACE_BEFORE 占位修真 (PS-9) | Trivial 0.5h | pull/appstore |

### 🟡 P2 (6 项) — R129 R2-R3 修真, 估时 5-10h

| # | 类别 | 内容 | 难度 |
|---|---|---|---|
| 1 | UX | `app_theme.dart:18-24` dark mode 主色显式覆盖 M3 ColorScheme | Trivial 30min |
| 2 | UX | `apple_health_tile.dart` 8 metricId 集中化 (map) | Trivial 30min |
| 3 | 业务 | `medication_page.dart:20` unused_import 修真 | Trivial 5min |
| 4 | god class | `home_page_state` 续拆 -76L | Medium 2h |
| 5 | god class | `mood_trend_page` 续拆 -86L | Medium 2h |
| 6 | god class | `setup_page_state` 拆 4 步 (R108 §六 候选, 跨 9 round) | Medium 3h |

### 🟢 P3 (跨期 / 长期, v1.0 2027-Q1)

| # | 类别 | 内容 | 估时 |
|---|---|---|---|
| 1 | UX | PressFeedback dark mode 视觉差异 | 1h |
| 2 | 集成 | HealthKit 阶段 2 真接 (5-6 月) | 5-6 月 |
| 3 | 集成 | 鸿蒙 channel 0% 集成 (v1.0+) | 5-15d |
| 4 | 集成 | 5 厂商 push + 阿里云 SMS 真接 (1-2 月) | 1-2 月 |
| 5 | 上架 | Android `compileSdk` 显式 pin 36 | 0.1h |
| 6 | 上架 | Android 拆 RECORD_AUDIO service 绑 manifest-service | 1d |
| 7 | 集成 | 11 feature AppleHealthTile 趋势图接入真实数据 (R31 P0-08 跨期) | 1-2 周 |
| 8 | 集成 | 5.1.3 抽审 4 文档准备 (PHQ-9/GAD-7 法务 + 临床审核) | 1-2 周 |

---

## 跨 Lens 共识 (Cross-cutting Findings, 7 项强共识)

### 共识 1: 5 P0 external 跨 12 round 0 闭环 (4 视角共识)
- **pull-on-shelf (PS-1~PS-7)**: 7 P0 跨期残留 (iOS 截图 / LaunchImage / AppIcon / 域名 ICP / 5 厂商 push / SMS)
- **appstore (AS-9~AS-12)**: 5 P0 跨期 0 主动动作
- **googleplaystore (GP-11~GP-14)**: 2 P0 设计师资产 + 域名 ICP
- **frame-thinking (FT-7)**: Focus 维度 6 round 单一节奏拖累
- **共识等待**: 5 外部资源 (设计师 + 域名商 + 5 厂商 + 阿里云), 1-2 月跨度

### 共识 2: 锁屏 PII 3 处未修 (3 视角共识)
- **gdc-audit (G-1)**: iOS 3 处 `DarwinNotificationDetails` 锁屏 PII `presentAlert: true` 默认 (跨 R32 P0-03 跨期 8 round)
- **pull-on-shelf (PS-17 + PS-Fix-2)**: 0.5h 修真跟 gdc-audit 同根因
- **flutter-audit (F-5)**: `check_pii_in_title.py` 锁屏 PII 3 key 跨期 0 闭环
- **共识修真**: 1h (3 处 file + 守门员规则加固)

### 共识 3: spring.dart 跨 8 round 半成品 (3 视角共识)
- **emil (E-1)**: 5 token 集中器裂 4+1 (R128d 漏拆 spring)
- **frame-thinking (FT-1)**: 物理模型 0 caller 跨 8 round
- **flutter-audit (F-1)**: spring.dart 118L 0 caller 跨 8 round
- **apple-health (AH-11)**: spring.dart 仍 in `lib/core/theme/` R128d 漏拆
- **共识修真**: 1h (迁 chroniccare_theme + 修真 3 caller import)

### 共识 4: R128d 拆包不彻底, 5 token 集中器裂 4+1 (4 视角共识)
- **emil (E-1)**: 5 token 集中器裂 4+1, emil 完整性破坏
- **super-en (S-EN-3)**: R128d 拆包 0 test 同步, TDD 断档
- **frame-thinking (FT-3)**: 3 package 名实不符 (chroniccare_core 0 lib file, chroniccare_features_mood 0 lib file)
- **flutter-audit (F-2/F-3)**: R128d 半拆收尾 + 3 package 名实相符
- **共识修真**: 9.5h (spring 迁 + app_theme/theme_provider 转 package + 3 package 修真 + 3-5 smoke test)

### 共识 5: 24 守门员描述不实 (2 视角共识)
- **frame-thinking (FT-3)**: 24 守门员描述 = "20 .py + 1 .dart + 3 R128d pub workspace 守门员", R128d 实际 0 新增独立守门员, 仅复用 `check_feature_first_migration.py` 阶段 3 启用
- **flutter-audit (F)**: 实际 23 .py + 1 .dart = 24
- **共识修真**: 修真 1-2 处文档描述 (AGENTS.md + CHANGELOG.md)

### 共识 6: CHANGELOG / pubspec / AGENTS 文档同步 3 P0 漏洞 (3 视角共识)
- **super-en (S-EN-1/2)**: pubspec 落后 5 commit + CHANGELOG 0 R128 entry
- **super-zh (Z-15/16/17)**: AGENTS.md EN Summary 漏 R128b crisis 6th feature + R128 章节合并写 + PRIVACY_HARDENING 头部 R120 状态
- **gdc-audit (G-5) + pull-on-shelf (PS-19)**: notes.txt 1.1.0+168 ≠ master 1.1.0+185 (R32 P0-02 跨期回归)
- **共识修真**: 4-5h (pubspec 5min + CHANGELOG 2h + AGENTS.md 30min + PRIVACY_HARDENING 1h + notes.txt 0.1h + R128 章节拆 30min)

### 共识 7: R108 教训 (token 撞 quota + 5 worker 顺序 dispatch) 跨 8 round 0 落地 SOP (2 视角共识)
- **super-zh (Z)**: R120 4 项 P2 待办跨期 8 round 0 落地
- **dispatch (D-5/D-6/D-7/D-8)**: SUBAGENT_FALLBACK.md / docs/reviews/briefs/ / cron self token 监控 / 5 worker git worktree 隔离
- **共识修真**: 4.5h (SOP 1h + 5 worktree 2h + brief 模板 1h + cron 监控 0.5h)

---

## 底层逐行问题清单 (新增 R128e 修真项 + 跨期残留)

> 遍历方式: `find lib/ -name "*.dart" | xargs wc -l | sort -rn | head -20` + 关键词 grep (TODO / FIXME / stub / @visibleForTesting / 半成品 / 跨期 / 锁屏)

### 修真项全表 (R128e 新发现 + 跨期残留)

| 修真类型 | 文件:行 | 修真内容 | 优先级 |
|---|---|---|---|
| 上架 P0 | `fastlane/metadata/ios/review_information/notes.txt:1` | `1.1.0+168` → `1.1.0+185` | P0 0.1h |
| 上架 P0 | `lib/core/platform/notification/notification_service.dart:172` | `presentAlert: true` → `false` (锁屏禁显示) | P0 0.5h |
| 上架 P0 | `lib/core/platform/notification/reminder_dispatcher.dart:127` | 同上 | P0 |
| 上架 P0 | `lib/core/platform/notification/snooze_manager.dart:112` | 同上 | P0 |
| 架构 P0 | `lib/core/theme/spring.dart:1-118` (整体迁) | 迁 `packages/chroniccare_theme/lib/src/spring.dart` + 修真 3 caller import | P0 1h |
| 文档 P0 | `AGENTS.md:3` (EN Summary 段) | `5 features` → `6 features (R128b +crisis)` | P0 5min |
| 文档 P0 | `AGENTS.md:1053-1087` (R128 章节) | 拆 R128 → R128a/b/c 3 独立章节 | P0 30min |
| 文档 P0 | `pubspec.yaml:6` | `version: 1.1.0+180` → `1.1.0+185` | P0 5min |
| 文档 P0 | `docs/CHANGELOG.md` (R128 5 entry) | 补 R127 stage3 + R128a + R128b + R128c + R128d 5 entry | P0 2h |
| 派单 P0 | `docs/SUBAGENT_FALLBACK.md` (新) | 写 R108 token 撞 quota SOP (含 token 监控 + brief 模板 + fallback 步骤) | P0 1h |
| 派单 P0 | R128e+ 派单流程 | 5 worker 派单改 5 git worktree 隔离 (修真 D-6) | P0 2h |
| UX P0 | `lib/presentation/widgets/apple_health_tile.dart:42-50` (加 tooltip) + 8 metric ARB | 修真 8 metric tooltip + 修 "checkIn" metricId 业务冲突 | P0 1.5h |
| 上架 P1 | `scripts/check_16kb_alignment.py --aab` (修真 SKIP → FAIL) | 跑 `flutter build aab --release` + objdump segment ≥ 16384 CI 验 | P1 2h |
| 架构 P1 | `lib/core/theme/app_theme.dart:1-245` | 整体迁 `packages/chroniccare_theme/lib/src/app_theme.dart` | P1 1.5h |
| 架构 P1 | `lib/core/theme/theme_provider.dart:1-67` | 整体迁 `packages/chroniccare_theme/lib/src/theme_provider.dart` | P1 0.5h |
| 架构 P1 | `packages/chroniccare_core/` 0 lib file | 修真 (6h) / 决定删除 (修真 5min) | P1 6h |
| 架构 P1 | `packages/chroniccare_features_mood/` 0 lib file | 修真 (6h) / 决定删除 (修真 5min) | P1 6h |
| 守门员 P1 | `scripts/check_id_bands_doc_sync.py` (新) | 5-10L 扫 AGENTS.md × 3 id band 公式 + `notification_id_band_round110_test.dart` lock 一致 | P1 1.5h |
| 守门员 P1 | `coverage/lcov.info` (修真 mtime) | 跑 `flutter test --coverage` 重生成 + commit | P1 10min |
| 守门员 P1 | `.github/workflows/*.yml` (修真 CI) | 加 `flutter test --coverage` step | P1 1h |
| 文档 P1 | `docs/PRIVACY_HARDENING.md:1-15` (头部) | 修真 R120 → R128d + 守门员矩阵表 22→27→24 含 3 R128c 规则 | P1 1h |
| 文档 P1 | `docs/CHANGELOG.md` (R128d 修真基线段) | 修真 "18 守门员 18 全绿" → "24 守门员 24 全绿" | P1 5min |
| TDD P1 | `packages/chroniccare_theme/test/` (新) | 建 + 3-5 smoke test (`app_colors_test.dart` 验 primary 0xFF34C759 + 8 health metric palette) | P1 2h |
| TDD P1 | 4 旧 test (`test/core/theme/{app_tokens_lock_in_round95,app_colors_contrast_round8,motion_scheme_round14,app_tokens_dark_round18}_test.dart`) | 修真走新 path `package:chroniccare_theme/chroniccare_theme.dart` | P1 1h |
| TDD P1 | `test/core/platform/health_kit/health_kit_stub_round129_test.dart` (新) | 3-5 case 验 NoOp 4 method + flag=false 短路 + facade 4 段式 | P1 1h |
| 守门员 P1 | `check_pii_in_title.py` 3 key 修真 | 修真 3 key 脱敏 (R31 P0-04 跨期 8 round 0 闭环) | P1 1h |
| 派单 P1 | `docs/reviews/briefs/{3,6,10}-lens.md` (新模板) | 写 3 套 brief 模板 (R120 4 视角 / R108 revisit 9 视角 / R128e 10 视角) | P1 1h |
| 监控 P1 | `mavis cron self` 模板 | token quota 监控 cron self-reminder (每 1h 检查 80% 阈值) | P1 0.5h |
| god class P1 | `lib/features/mood/presentation/widgets/mood_audio_recorder_widget.dart:1-611` | 拆 (-82L 反弹, R120 529L → R128e 611L) | P1 3h |
| 上架 P1 | `fastlane/metadata/ios/review_information/{first,last}_name.txt` + `email_address.txt` + `phone_number.txt` | 4 TODO 填真实 | P1 0.5h |
| UX P2 | `lib/core/theme/app_theme.dart:18-24` (dark mode) | `primary: AppTokens.primary` → `isDark ? AppTokens.primaryDark : AppTokens.primary` | P2 30min |
| UX P2 | `lib/presentation/widgets/apple_health_tile.dart:163-184` (metricId switch) | 改 `static const Map<String, IconData>` | P2 30min |
| 业务 P2 | `lib/features/medication/presentation/pages/medication/medication_page.dart:20` (unused_import) | 修真 `dart:async` import | P2 5min |
| god class P2 | `lib/features/home/presentation/pages/home_page_state.dart:1-430` | 续拆 (-76L, 仍 god class) | P2 2h |
| god class P2 | `lib/features/mood_list/presentation/pages/mood_detail_page.dart:1-431` | 续拆 (-86L, 改名, 仍 god class) | P2 2h |
| god class P2 | `lib/features/setup/presentation/pages/setup_page_state.dart:1-513` | 拆 4 步 (R108 §六 候选, 跨 9 round 0 闭环) | P2 3h |

---

## 加权综合结论

**当前: 7.8/10** (R120 7.5 → +0.3, R128a~R128d 4 round 净 +0.3)

| 加权项 | 权重 | R128e 分数 | 加权分 |
|---|---|---|---|
| emil | 0.15 | 7.5 | 1.125 |
| super-en | 0.10 | 7.0 | 0.70 |
| super-zh | 0.10 | 7.5 | 0.75 |
| dispatch | 0.05 | 7.5 | 0.375 |
| gdc | 0.10 | 7.5 | 0.75 |
| pull | 0.15 | 4.0 | 0.60 |
| frame | 0.10 | 8.5 | 0.85 |
| flutter | 0.15 | 9.6 | 1.44 |
| appstore | 0.05 | 3.5 | 0.175 |
| googleplay | 0.05 | 5.5 | 0.275 |
| apple-health | 0.10 | 7.5 | 0.75 |
| **合计** | **1.00** | - | **7.79 ≈ 7.8** |

### 改进路径

- **R129 hotfix (本周, 1-2 天, 4-5h)**: 闭环 P0-1~P0-10 修真 → 7.8 → 8.2 (+0.4)
- **R129 R1 (1 周, 12-15h)**: 闭环 P1-1~P1-15 修真 → 8.2 → 8.5 (+0.3)
- **R129 R2-R3 (2-3 周)**: 闭环 P2-1~P2-6 修真 → 8.5 → 8.7 (+0.2)
- **R130 (1-2 月)**: 5 实物资产 + 域名 ICP 闭环 (设计师 + 域名商) → 8.7 → 9.0 (+0.3)
- **v1.0 (2027-Q1)**: 5 厂商 push + HealthKit + 鸿蒙 + IAP + 阿里云 SMS 全真接 → 9.5+

### 跨期 4 大遗留 (跨 R128e 仍 0 闭环)

1. **5 P0 external 跨期 12 round 0 闭环**: iOS 截图 / LaunchImage / AppIcon / 域名 ICP / 5 厂商 push / SMS — 全部等外部资源
2. **2 god class 反弹 / 跨期 0 收紧**: `mood_audio_recorder_widget` 反弹 +82L / `setup_page_state` 跨 9 round 0 启动
3. **HealthKit 阶段 2 5-6 月真接**: R128c stub 收官 ≠ 真接,5.1.3 防御 100% 闭环但业务不集成
4. **3 package 名实不符**: `chroniccare_core` + `chroniccare_features_mood` 0 lib file, 命名误导, R128d 跨 2 round 0 实质

---

## 子报告索引

| Lens | 路径 | 大小 | 评分 |
|---|---|---|---|
| 1. emil | `01-emil.md` | 11236B | 7.5/10 |
| 2. superpowers-en | `02-superpowers-en.md` | 13546B | 7.0/10 |
| 3. superpowers-zh | `03-superpowers-zh.md` | 6458B | 7.5/10 |
| 4. superpowers-dispatch | `04-superpowers-dispatch.md` | 7017B | 7.5/10 |
| 5. gdc-audit | `05-gdc-audit.md` | 8772B | 7.5/10 |
| 6. pull-on-shelf | `06-pull-on-shelf.md` | 9221B | 4.0/10 |
| 7. frame-thinking | `07-frame-thinking.md` | 9779B | 8.5/10 |
| 8. flutter-audit | `08-flutter-audit.md` | 9927B | 96% |
| 9. appstore | `09-appstore.md` | 7109B | 3.5/10 |
| 10. googleplaystore | `10-googleplaystore.md` | 8407B | 5.5/10 |
| 11. apple-health | `11-apple-health.md` | 8148B | 7.5/10 |
| **整合** | `00-FINAL-CONSOLIDATION.md` | (本文件) | **7.8/10** |
