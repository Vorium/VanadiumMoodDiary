# 开发需求文档 (v3.0, R128e 综合审视后)

**Date**: 2026-08-18
**Source**: [docs/audit/2026-08-18-r128e-multi-lens/00-FINAL-CONSOLIDATION.md](audit/2026-08-18-r128e-multi-lens/00-FINAL-CONSOLIDATION.md)
**Baseline**: 1.1.0+185 (R128a~R128d 跨 4 round 收官), 2728 tests pass / 0 fail / 1 skip, **24 gatekeepers** (23 .py + 1 .dart, R128d 0 新增独立守门员,实际名实不符), 1340 ARB keys, 6 features (R128b +crisis), 3 pub workspace package (chroniccare_theme 1 有代码 + 2 占位)
**Status**: 加权综合 **7.8/10** (R120 7.5 → +0.3, R128a~R128d 4 round 净 +0.3)

---

## 1. 项目核心定位

**emotion-first 精神心理自我关怀 App** (1.1.0 round 4b 后定版):
- **主**: vent (树洞) + mood (情绪日记) — 视觉/交互/路径优先
- **辅**: medication + assessment — 弱化 (2x2 tile → "更多" entry, R115)
- **禁**: SMS / Email / Contacts / IAP / SafetyWatch / 失联通知 (1.1.0 round 4b 全删)
- **零外联**: lib/ 0 网络 import, release 0 域名, 6 Android + 4 iOS 严格白名单

---

## 2. 架构硬约束 (4 层 + 5 umbrella, AGENTS.md 必读)

```
lib/
├── core/                # 基础设施 umbrella (data/shared/theme/routing/l10n)
├── domain/              # 0 Flutter 0 Drift
├── presentation/        # UI 层
└── l10n/                # presentation 层 flutter_localizations
```

**架构守门员** (`dart scripts/check_all.dart`):
- domain/shared 0 flutter / 0 drift / 0 data / 0 presentation
- data 不依赖 presentation
- shared/ 每个文件至少被 2 层用
- domain *Entity ↔ drift @DataClassName 1:1
- 违规 → exit 1, CI fail

**4 FeatureFlag 编译期锁定** (R93 阶段 2 + round 4b 收):
1. `ventAudioEnabled=true` (R104 翻 true)
2. `fiveVendorPushEnabled=false` (等 5 厂商 1-2 月)
3. `phqGad7I18nEnabled=false` (等法务 + 临床)
4. `bootReceiverEnabled=false` (等 WorkManager 完善)

---

## 3. 24 守门员 (CI 必跑, R128d 名实不符已发现)

**R128e 新发现**: baseline 写 "20 .py + 1 .dart + 3 R128d pub workspace 守门员" = 24, **R128d 实际 0 新增独立守门员**, 仅复用 `check_feature_first_migration.py` 阶段 3 启用。**实际 23 .py + 1 .dart = 24** (R128c 加 3 规则到 `check_apple_health_claim.py` 而非 3 个独立守门员)。

**R128e 修真项**: 修真 AGENTS.md / CHANGELOG.md "18 守门员 18 全绿" 描述 → "24 守门员 24 全绿" (5min, P1)。

23 Python + 1 Dart = 24 守门员 (R31 R108 R115 R117 R128c 累计) + 5 上架守门员 (R117 P0-1~P0-5, 资源到位即跑):

| 类别 | 守门员 | 状态 |
|---|---|---|
| 架构 | `check_all.dart` (4 层 + 跨 feature import) | ✓ |
| 架构 | `check_cross_feature.py` | ✓ |
| 架构 | `check_drift_namespace.py` | ✓ |
| 架构 | `check_widget_dispose.py` | ✓ |
| 架构 | `check_usecase_layer.py` (R109) | ✓ |
| i18n | `check_arb_keys.py` (3 语同步) | ✓ |
| i18n | `check_orphan_arb_keys.py` (R56e) | ✓ |
| i18n | `check_zh_hant_consistency.py` (R57) | ✓ |
| i18n | `check_strings_hardcoded.py` (R57 + R110 inline) | ✓ |
| i18n | `check_fullwidth_punctuation.py` (warn-only) | ✓ |
| 隐私 | `check_no_pua.py` | ✓ |
| 隐私 | `check_no_hardcoded_utc.py` | ✓ |
| 隐私 | `check_pii_in_assets.py` (R115) | ✓ |
| 隐私 | `check_pii_in_title.py` (R32) | ✓ |
| 隐私 | `check_encryption_at_rest.py` (R115) | ✓ |
| 隐私 | `check_no_network_io.py` (R115) | ✓ |
| 隐私 | `check_release_no_network.py` (R115) | ✓ |
| 隐私 | `check_permissions_whitelist.py` (R115) | ✓ |
| 隐私 | `check_legal_consent.py` (R57, 1.1.0 round 4b 删 §13) | ✓ |
| 上架 | `check_apple_health_claim.py` (R31) | ✓ |
| 上架 | `check_review_information_todo.py` (R111) | ✓ |
| 上架 | `check_appstore_screenshots.py` (R117 P0-1, 资源到位即跑) | ⏳ |
| 上架 | `check_ios_launchimage.py` (R117 P0-2, 资源到位即跑) | ⏳ |
| 上架 | `check_appicon_size.py` (R117 P0-5, 资源到位即跑) | ⏳ |
| 上架 | `check_domain_icp.py` (R117 P0-4, 域名 ICP 到位即跑) | ⏳ |
| 上架 | `check_appstore_metadata.py` (R117 P0-5 配套, review_information / notes / description) | ⏳ |
| 测试 | `check_datetime_race.py` (R19B) | ✓ |
| 测试 | `check_datetime_race2.py` (R19B) | ✓ |
| 测试 | `check_changelog.py` | ✓ |
| 测试 | `check_coverage.py` (R95, 18 gatekeeper 阈值) | ✓ |
| 工具链 | `check_16kb_alignment.py` (R77) | ✓ |
| 视觉 | `check_home_quick_actions.py` (R115) | ✓ |

> 每次 `git commit` 前必跑 27 现有守门员 (5 上架脚本等资源到位才跑, 当前 expected fail)

---

## 4. P0/P1/P2/P3 修复需求清单

### 🔴 P0 (7 项) — 上架硬阻塞, 全部外部依赖

| # | 内容 | 资源 | 预计 | 状态 |
|---|---|---|---|---|
| P0-1 | iOS 截图 0 张 (6.7"/6.1"/5.5" 3 套 × 5 张) | 设计师 | - | 阻塞 |
| P0-2 | iOS LaunchImage 68B (缺多尺寸) | 设计师 | - | 阻塞 |
| P0-3 | Android 截图 67B + feature_graphic 67B (缺分辨率) | 设计师 | - | 阻塞 |
| P0-4 | chroniccare.app 域名 + 4 邮箱 ICP | 域名商 | 7-20d | 阻塞 |
| P0-5 | AppIcon 1024×1024 ≥ 200KB | 设计师 | - | 阻塞 |
| P0-6 | 5 厂商 push SDK (米/华/OPP/vivo/魅族) | 5 厂商 | 1-2 月 | 阻塞 |
| P0-7 | 阿里云 SMS | 阿里云 | 1-2 月 | 阻塞 |

> **5 上架脚本就绪**: 等 P0-1~P0-5 资源到位, 跑 `scripts/check_appstore_screenshots.py` / `check_ios_launchimage.py` / `check_appicon_size.py` / `check_domain_icp.py` / `check_appstore_metadata.py`

### 🟠 P1 (6 项) — 架构 + 续拆 (R117 R1-R2)

| # | 内容 | 难度 | 修复 |
|---|---|---|---|
| P1-1 | `app_database.dart` 564L 拆 4 (tables/migrations/DAOs/connection) | Medium 4h | R117 R1 |
| P1-2 | `notification_service.dart` 417L 拆 4 facade | Medium 4h | R117 R1 |
| P1-3 | `setup_page_state.dart` 513L 拆 4 步 | Medium 3h | R117 R2 |
| P1-4 | `spring.dart` 145L 0 caller, 接 `_EntrySpring` | Small 1.5h | R117 R1 |
| P1-5 | 5.1.3 抽审流程 (PS-12 / AS-12 / AH-8) | Medium 4h | R117 R2 |
| P1-6 | iOS 16KB 真机验证 | Small 1h | R117 R2 (上架前 1 周) |

### 🟡 P2 (9 项) — 单元 test + EN 摘要 + 半成品 (R117 R1-R2)

| # | 内容 | 难度 | 修复 |
|---|---|---|---|
| P2-1 | `medication_slot_entry_row.dart` widget test | Small 1h | R117 R1 |
| P2-2 | `feature_flags.dart` 4 个 `_currentXxx` 单元 test | Trivial 0.5h | R117 R1 |
| P2-3 | `encryption_service.dart` smoke test | Small 1h | R117 R1 |
| P2-4 | `docs/PRIVACY_HARDENING.md` EN 版 | Small 1.5h | R117 R2 |
| P2-5 | `docs/design/.../spec.md` 22KB EN 摘要 | Small 2h | R117 R2 |
| P2-6 | `scale_registry.dart` hybrid 决策 | Small 1h | R117 R2 |
| P2-7 | `static_scale_translations.dart` 785L 拆 12 子文件 | Medium 3h | R117 R2 |
| P2-8 | `vent_list_page.dart` 684L 拆 3 | Medium 3h | R117 R2 |
| P2-9 | AppleHealthTile 视觉 vs 数据 gap 加 tooltip | Small 1h | R117 R2 |

### 🟢 P3 (8 项) — 细节优化 + 长期 (R117 R3+)

| # | 内容 | 难度 | 修复 |
|---|---|---|---|
| P3-1 | `HomePageState` 简化 ConsumerWidget | Trivial 0.5h | R117 R3 |
| P3-2 | `loading_skeleton.dart` 3 variant enum 统一 | Trivial 0.5h | R117 R3 |
| P3-3 | vent 录音态 spring 进场 | Small 1h | R117 R3 |
| P3-4 | dark mode 主色对齐 iOS | Small 2h | R117 R3 |
| P3-5 | `audio_lifecycle.dart` 659L 拆 4 | Medium 4h | R117 R3+ |
| P3-6 | `assessment_center_page.dart` 12 量表加趋势图 | Medium 3h | R117 R3+ |
| P3-7 | `app_theme.dart` 1 TODO 主题细节 | Trivial 0.5h | R117 R3 |
| P3-8 | `AGENTS.md` / `CHANGELOG.md` EN 摘要 | Trivial 0.5h | R117 R3 |

---

## 4.5 R128e 综合审视 v3.0 修真项 (2026-08-18, 5 worker × 2-3 lens 派单)

**Source**: [docs/audit/2026-08-18-r128e-multi-lens/00-FINAL-CONSOLIDATION.md](audit/2026-08-18-r128e-multi-lens/00-FINAL-CONSOLIDATION.md) (29KB, 11 lens)
**Method**: 5 worker subagent × 2-3 lens 后台并行 (A+B 策略 R128e 实战) + 主 agent 整合
**关键发现**: 4 大类共 36 项修真 (10 P0 + 15 P1 + 6 P2 + 8 P3/跨期)

### 🔴 P0 (10 项, 估时 9-10h) — R129 hotfix 修真

| # | 类别 | 内容 | 文件:行 | 难度 | 跨 lens |
|---|---|---|---|---|---|
| **P0-1** | 上架 | `notes.txt` 1.1.0+168 → 1.1.0+185 (R32 P0-02 跨期回归) | `fastlane/metadata/ios/review_information/notes.txt:1` | Trivial 0.1h | pull/appstore/gdc |
| **P0-2** | 上架 | 3 处 `DarwinNotificationDetails` `presentAlert: false` (锁屏 PII 跨 R32 P0-03 8 round) | `lib/core/platform/notification/notification_service.dart:172` / `reminder_dispatcher.dart:127` / `snooze_manager.dart:112` | Small 0.5h | gdc/pull/flutter |
| **P0-3** | 架构 | `spring.dart` 118L 迁 `chroniccare_theme` (R128d 漏拆, 5 token 集中器裂 4+1) | `lib/core/theme/spring.dart:1-118` + 修真 3 caller import | Small 1h | emil/frame/flutter/apple-health |
| **P0-4** | 文档 | `AGENTS.md:3` EN Summary `5 features` → `6 features (R128b +crisis)` | `AGENTS.md:3` | Trivial 5min | super-zh/super-en |
| **P0-5** | 文档 | `AGENTS.md:1053-1087` R128 章节拆 3 独立 (R128a/b/c) | `AGENTS.md:1053-1087` | Small 30min | super-zh/super-en |
| **P0-6** | 文档 | `pubspec.yaml:6` version 1.1.0+180 → 1.1.0+185 (落后 5 commit) | `pubspec.yaml:6` | Trivial 5min | super-en/flutter |
| **P0-7** | 文档 | `docs/CHANGELOG.md` 补 5 R128 entry (R127 stage3 + R128a/b/c/d) | `docs/CHANGELOG.md` | Small 2h | super-en/super-zh |
| **P0-8** | 派单 | `docs/SUBAGENT_FALLBACK.md` SOP 写 (R108 6 subagent 撞 token 教训跨 8 round 0 落地) | `docs/SUBAGENT_FALLBACK.md` (新) | Small 1h | super-zh/dispatch |
| **P0-9** | 派单 | R128e+ 派单 5 worker 改 5 git worktree 隔离 (修真 D-6 顺序 dispatch → 并行) | 派单流程 | Medium 2h | dispatch |
| **P0-10** | UX | `apple_health_tile.dart` 加 8 metric tooltip + 修真 "checkIn" metricId 业务冲突 (R31 P0-08 跨期) | `lib/presentation/widgets/apple_health_tile.dart:42-50` | Small 1.5h | emil/apple-health |

### 🟠 P1 (15 项, 估时 15-20h) — R129 R1-R2 修真

| # | 类别 | 内容 | 估时 | 跨 lens |
|---|---|---|---|---|
| P1-1 | 上架 | iOS 16KB 真机 objdump 验 (上架前 1 周, R120 P1-026 跨期 8 round) | Medium 2h | gdc/appstore/googleplay |
| P1-2 | 架构 | `app_theme.dart` 245L + `theme_provider.dart` 67L 转 `chroniccare_theme` (R128d 漏拆) | Small 1.5h | emil/frame/flutter |
| P1-3 | 架构 | 3 package 名实不符修真 / 决定删除 (`chroniccare_core` + `chroniccare_features_mood` 0 lib file) | Medium 6h | frame/flutter |
| P1-4 | 守门员 | `check_id_bands_doc_sync.py` 新增 (R120 建议, 跨 8 round 0 落地) | Trivial 1.5h | super-en/super-zh |
| P1-5 | 守门员 | `flutter test --coverage` 修真 lcov.info 过期 (跨 R128a~d 修真未重生成) | Trivial 10min | super-en/flutter |
| P1-6 | 守门员 | CI 修真 `flutter test --coverage` step (R120 建议) | Small 1h | super-en/flutter |
| P1-7 | 文档 | `docs/PRIVACY_HARDENING.md:1-15` 头部 R120 → R128d 修真 (R128c 加 3 规则后 22→27→24) | Small 1h | super-zh/super-en |
| P1-8 | TDD | `packages/chroniccare_theme/test/` 建 3-5 smoke test (R128d 拆包 0 test 同步) | Small 2h | super-en/flutter |
| P1-9 | TDD | 4 旧 test 修真走新 path import (R95 lock-in test 修真) | Small 1h | super-en/flutter |
| P1-10 | TDD | `health_kit_service.dart` 0 test 修真 3-5 case (R128c stub 200L 0 test) | Small 1h | super-en/flutter |
| P1-11 | 守门员 | 锁屏 PII 3 key 脱敏修真 (`check_pii_in_title.py` R31 P0-04 跨 8 round 0 闭环) | Small 1h | gdc/flutter |
| P1-12 | 模板 | `docs/reviews/briefs/{3,6,10}-lens.md` 3 套 brief 模板 (R120 建议, 跨 8 round 0 落地) | Small 1h | super-zh/dispatch |
| P1-13 | 监控 | `mavis cron self` token quota 监控模板 (R108 教训, 每 1h 80% 阈值) | Trivial 0.5h | dispatch |
| P1-14 | god class | `mood_audio_recorder_widget` 611L 拆 (R120 529L → R128e +82L 反弹跨 8 round) | Medium 3h | frame/flutter |
| P1-15 | 上架 | `review_information` 4 TODO 占位填真实 (PS-9 上架前必填) | Trivial 0.5h | pull/appstore |

### 🟡 P2 (6 项, 估时 5-10h) — R129 R2-R3 修真

| # | 类别 | 内容 | 估时 |
|---|---|---|---|
| P2-1 | UX | `app_theme.dart:18-24` dark mode 主色显式覆盖 M3 ColorScheme (走 AppTokens.primaryDark) | 30min |
| P2-2 | UX | `apple_health_tile.dart` 8 metricId 集中化 (改 map) | 30min |
| P2-3 | 业务 | `medication_page.dart:20` unused_import `dart:async` 修真 (R128b crisis 迁 features/ 修真残留) | 5min |
| P2-4 | god class | `home_page_state` 续拆 -76L 仍 god class | Medium 2h |
| P2-5 | god class | `mood_trend_page` 续拆 -86L 改名仍 god class | Medium 2h |
| P2-6 | god class | `setup_page_state` 拆 4 步 (R108 §六 候选, 跨 9 round 0 闭环) | Medium 3h |

### 🟢 P3 (8 项, 跨期 / 长期 v1.0 2027-Q1)

| # | 类别 | 内容 | 估时 |
|---|---|---|---|
| P3-1 | UX | PressFeedback dark mode 视觉差异 (shadow + splash 统一) | 1h |
| P3-2 | 集成 | HealthKit 阶段 2 真接 (5-6 月, R128c stub 收官 ≠ 真接) | 5-6 月 |
| P3-3 | 集成 | 鸿蒙 channel 0% 集成 (v1.0+, R128a~R128e 跨 5 round 0 启动) | 5-15d |
| P3-4 | 集成 | 5 厂商 push + 阿里云 SMS 真接 (1-2 月, R124 facade 后续) | 1-2 月 |
| P3-5 | 上架 | Android `compileSdk` 显式 pin 36 (防 Flutter 升级漂移) | 0.1h |
| P3-6 | 上架 | Android 拆 RECORD_AUDIO service 绑 manifest-service (R108 §六 G-8) | 1d |
| P3-7 | 集成 | 11 feature AppleHealthTile 趋势图接入真实数据 (R31 P0-08 跨期) | 1-2 周 |
| P3-8 | 集成 | 5.1.3 抽审 4 文档准备 (PHQ-9/GAD-7 法务 + 临床审核) | 1-2 周 |

---

## 5. 路线图 (R129 → v1.0, R128e 综合审视修真)

| 阶段 | 时间 | 目标 | 评分 | 跨期 |
|---|---|---|---|---|
| **R129 hotfix** | 本周 (1-2 天) | 闭环 P0-1~P0-10 修真 (notes.txt + 锁屏 PII 3 处 + spring 迁 + 文档同步 3 P0) | 7.8 → 8.2 (+0.4) | 内部 4-5h |
| **R129 R1** | 1 周 | 闭环 P1-1~P1-15 修真 (iOS 16KB + 3 package 名实 + 4 doc sync + 4 test + 5 brief) | 8.2 → 8.5 (+0.3) | 内部 12-15h |
| **R129 R2-R3** | 2-3 周 | 闭环 P2-1~P2-6 修真 (3 god class 续拆 + dark mode + 业务) | 8.5 → 8.7 (+0.2) | 内部 5-10h |
| **R130** | 1-2 月 | 5 实物资产 + 域名 ICP 闭环 (设计师 + 域名商) | 8.7 → 9.0 (+0.3) | 外部资源 |
| **R131** | 2-3 月 | 5 厂商 push + HealthKit 阶段 2 + 鸿蒙 channel | 9.0 → 9.3 (+0.3) | 外部 1-2 月 |
| **v1.0** | 2027-Q1 | 5 厂商 push + HealthKit + 鸿蒙 + 阿里云 SMS + IAP 全真接 | 9.5+ | 全部外部 |

---

## 6. 已知坑 (从 AGENTS.md 累计)

### R31 R108 R115 闭环
- ❌ raw IconButton (7 处) → PressFeedbackIconButton
- ❌ hardcoded 中文 → ARB key
- ❌ 隐式排序 → 显式 sort
- ❌ 跨 midnight race → AppRoot midnight timer
- ❌ DateTime.now() 多次调用 → 函数入口固化
- ❌ Stream subscription leak → dispose() 取消
- ❌ BuildContext 跨 async gap → this.context
- ❌ schemaVersion 漏 migration → 守门员
- ❌ Material 3 ink_sparkle shader → 复制到 assets/shaders/

### R117 待清
- ⚠️ `spring.dart` 0 caller (P1-4)
- ⚠️ 6 god class 续拆 (P1-1~P1-3, P2-7, P2-8, P3-5)
- ⚠️ 4 半成品 TODO (P2-3, P2-6, P3-6, P3-7)
- ⚠️ EN 摘要 4 文档 (P2-4, P2-5, P3-8)
- ⚠️ 7 P0 跨期残留 (等外部)

---

## 7. 4 个跨期残留 FeatureFlag 详细

| Flag | 当前 | 翻 true 条件 | 阻塞 | 优先级 |
|---|---|---|---|---|
| `ventAudioEnabled` | **true** | R104 启用 | - | - |
| `fiveVendorPushEnabled` | **false** | 5 厂商 push SDK 接入 | 1-2 月 (P0-6) | P1 |
| `phqGad7I18nEnabled` | **false** | PHQ-9/GAD-7 16 题 i18n 走完 ARB | 法务 + 临床 | P2 |
| `bootReceiverEnabled` | **false** | WorkManager 完善 (R55 阶段) | R55 | P3 |

---

## 8. 文档索引 (按类型)

| 类型 | 文档 | 备注 |
|---|---|---|
| 入口 | `AGENTS.md` (32KB) | 项目必读, 4 层架构 + 21 守门员 + 已知坑 |
| 路线图 | `docs/VERSION_1.0_PLAN.md` (1879L) | v0.30 R95+ 阶段 1+2+3+4 实施后路线图 |
| **本文件** | `docs/DEVELOPMENT_REQUIREMENTS.md` | **R117 综合审视后需求文档** |
| 隐私 | `docs/PRIVACY_HARDENING.md` (R115) | 5 守门员 + 隐私硬化落地证据 |
| 设计 | `docs/design/2026-08-10-apple-health-redesign/spec.md` (22KB) | iOS 17/18 视觉语言 spec |
| 决策 | `docs/decisions/v0.{17,22,24,30}_*.md` (5 文件) | 架构决策记录 (ADR) |
| 评估 | `docs/evaluations/*_r79.md` (2 文件) | god class 评估 |
| 上架 | `docs/PLAYSTORE_SIGNING_GUIDE.md` (R67) | Play App Signing 5 步指南 |
| 上架 | `docs/SUBMISSION_INFO.md` (R67) | 上架元数据 |
| 上架 | `docs/STOREFRONT_RELEASE_SOP.md` (R67) | 上架 SOP |
| 部署 | `docs/DEPLOYMENT.md` (R67) | 部署指南 |
| 法务 | `assets/legal/{user_agreement,privacy_policy,sensitive_data_consent,medical_disclaimer}.md` | 4 法务文档 |
| 综合审视 | `docs/audit/2026-08-17-comprehensive/` (12 文件) | **R117 11 视角综合审视** |
| 综合审视 | `docs/audit/2026-08-17-round120/` (7 文件) | R120 4 视角 + 主 agent 自查 7.5/10 |
| **综合审视** | `docs/audit/2026-08-18-r128e-multi-lens/` (12 文件) | **R128e 11 视角综合审视 7.8/10** |

---

## 9. CI/CD 必跑命令

```bash
flutter analyze                   # 0 error / 0 warning (info-level 历史 require_trailing_commas OK)
flutter test                      # 2728 pass / 0 fail / 1 skip
flutter test --coverage           # 必带, coverage 守门员 (P1-5 修真 lcov.info 过期)
for s in scripts/check_*.py; do python "$s"; done   # 23 守门员 (R128e 修真 24 描述) + 5 上架新
dart scripts/check_all.dart       # 4 层架构守门员 (1 个)
flutter build apk --release       # Android release build (R117 round 5 适配 3.47)
flutter build aab --release       # Android 16KB alignment 验 (P1-1)
flutter build ios --release       # iOS 16KB alignment 验 (P1-1)
```

---

## 10. 跨期遗留 (1.1.0 round 4b 删除业务)

> 这些业务 1.1.0 round 4b 已全删, 不再实现:
- ❌ 紧急联系人 (含 SMS / 失联通知 / 5 厂商 push)
- ❌ 阿里云 SMS
- ❌ EmailService (SendGrid)
- ❌ 失联检测 + 关爱引擎 (CareEngine)
- ❌ IAP (内购, 永久免费)
- ❌ SafetyWatchService
- ❌ WorkManager boot receiver (待 R55 阶段)
- ❌ PHQ-9 / GAD-7 16 题 i18n (待法务 + 临床审核)

---

## 11. R128e 跨期残留 (4 大类, 等外部 / 修真)

### 11.1 5 P0 external 跨 R108→R128e 12 round 0 闭环 (等外部)

| # | 内容 | 资源 | 预计 |
|---|---|---|---|
| E-1 | iOS 截图 0 张 (6.7" / 6.1" / 5.5" 3 套) | 设计师 | 1-2 周 |
| E-2 | iOS LaunchImage 68B + AppIcon 1024×1024 = 16KB (< 200KB) | 设计师 | 1-2 周 |
| E-3 | Android 截图 67B + feature_graphic 21KB + icon 13.6KB | 设计师 | 1-2 周 |
| E-4 | chroniccare.app 域名 + 4 邮箱 ICP | 域名商 | 7-20d |
| E-5 | 5 厂商 push SDK + 阿里云 SMS (1.1.0 round 4b 删) | 5 厂商 + 阿里云 | 1-2 月 |

### 11.2 2 god class 反弹 / 跨 9 round 0 闭环

- `mood_audio_recorder_widget` 611L (R120 529L → R128e +82L 反弹, P1-14 修真)
- `setup_page_state` 513L (R108 §六 候选, 跨 9 round 0 启动, P2-6 修真)

### 11.3 HealthKit 5-6 月真接 (R128c stub 收官 ≠ 真接)

- R128c 阶段 1 stub (200L NoOp + flag=false) 100% 闭环
- 5.1.3 used-but-not-declared 防御 100% (PrivacyInfo 0 HealthAndFitness)
- 阶段 2 真接 (v1.0+): factory 改 + pub dep + iOS entitlement

### 11.4 3 package 名实不符 (R128d 跨 2 round 占位)

- `packages/chroniccare_core/` 仅 pubspec 占位, 0 lib file, 命名误导
- `packages/chroniccare_features_mood/` 仅 pubspec 占位, 0 lib file, mood feature 仍 100% 在 `lib/features/mood/`
- 仅 `packages/chroniccare_theme/` 有 1685L 5 集中器代码
- 修真选项: (a) 修真到实质 6h, (b) 决定删除 5min

---

**Maintainer**: Mavis (mavis agent)
**Last Updated**: 2026-08-18 (R128e 综合审视后)
**Next Review**: R129 hotfix 完成后 (本周内)
